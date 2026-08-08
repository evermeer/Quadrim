import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quadrim/data/document_store.dart';
import 'package:quadrim/data/documents.dart';
import 'package:quadrim/data/local_game_repository.dart';
import 'package:quadrim_engine/quadrim_engine.dart';

/// A fixed clock and id sequence, so ordering assertions are about the code
/// rather than about how fast the test machine happens to be.
class Fixtures {
  var _tick = 0;
  var _ids = 0;
  DateTime now() => DateTime.utc(2026, 8, 8, 12).add(Duration(minutes: _tick++));
  String nextId() => 'g${(_ids++).toString().padLeft(3, '0')}';
}

void main() {
  // The contract is what 0.3a's Firestore implementation must satisfy, so it
  // is stated once and run against every store.
  group('file store', () {
    late Directory root;
    setUp(() async {
      root = await Directory.systemTemp.createTemp('quadrim_test');
    });
    tearDown(() async {
      if (root.existsSync()) await root.delete(recursive: true);
    });
    contractTests((f) async =>
        LocalGameRepository.open(await FileDocumentStore.open(root),
            now: f.now, newId: f.nextId));
  });

  group('memory store', () {
    contractTests((f) async => LocalGameRepository.open(MemoryDocumentStore(),
        now: f.now, newId: f.nextId));
  });

  group('on disk', fileStoreTests);
}

/// Runs the whole [GameRepository] contract against one store.
void contractTests(Future<LocalGameRepository> Function(Fixtures) open) {
  late Fixtures fixtures;
  late LocalGameRepository repo;

  setUp(() async {
    fixtures = Fixtures();
    repo = await open(fixtures);
  });
  tearDown(() => repo.dispose());

  Future<GameDocument> newGame({int startingSeat = 0}) => repo.createGame(
        mode: GameMode.passAndPlay,
        opponent: kGuestOpponent,
        startingSeat: startingSeat,
      );

  test('a created game is stored, active and empty, with a unique id',
      () async {
    final a = await newGame();
    final b = await repo.createGame(
        mode: GameMode.vsComputer,
        opponent: botOpponent('pebble'),
        opponentRating: 800);

    expect(a.id, isNot(b.id));
    expect(a.status, GameStatus.active);
    expect(a.moves, isEmpty);
    expect(b.opponent, 'bot:pebble');
    expect(b.opponentRating, 800,
        reason: 'the anchor a game was actually played against is recorded');
  });

  test('whose move each was derives from position and the starting seat',
      () async {
    final game = await newGame(startingSeat: 1);
    final played = await repo.appendMove(game.id, 0);

    expect(played.seatForMove(0), 1, reason: 'seat 1 started');
    expect(played.seatForMove(1), 0);
    expect(played.seatToMove, 0);
    // Nothing about authorship is stored — only the ordered cell list.
    expect(played.toJson()['moves'], [0]);
  });

  test('a winning move completes the game with outcome, reason and line',
      () async {
    final game = await newGame();
    // Seat 0 takes cells 0..3, an x-axis line; seat 1 scatters harmlessly.
    for (final cell in [0, 21, 1, 22, 2, 26]) {
      await repo.appendMove(game.id, cell);
    }
    final done = await repo.appendMove(game.id, 3);

    expect(done.status, GameStatus.complete);
    expect(done.result!.outcome, GameOutcome.win);
    expect(done.result!.reason, GameEndReason.line);
    expect(done.result!.winnerSeat, 0);
    expect(done.result!.line, [0, 1, 2, 3]);
    expect(done.completedAt, isNotNull);
    expect(() => repo.appendMove(game.id, 4), throwsA(isA<StateError>()),
        reason: 'a complete game must not accept further moves');
  });

  test('a full board completes as a draw with reason fullBoard', () async {
    final game = await newGame();
    GameDocument? last;
    for (final cell in _drawnGame()) {
      last = await repo.appendMove(game.id, cell);
    }
    expect(last!.status, GameStatus.complete);
    expect(last.result!.outcome, GameOutcome.draw);
    expect(last.result!.reason, GameEndReason.fullBoard);
    expect(last.result!.winnerSeat, isNull);
  });

  test('resignation records the other seat as winner, with its own reason',
      () async {
    final game = await newGame();
    await repo.appendMove(game.id, 0);
    final done = await repo.resign(game.id, seat: 1);

    expect(done.status, GameStatus.complete);
    expect(done.result!.outcome, GameOutcome.win);
    expect(done.result!.reason, GameEndReason.resignation);
    expect(done.result!.winnerSeat, 0);
    // The reason cannot be inferred from the moves, which is why it is stored.
    expect(outcome(GameState.fromMoves(done.moves)), isA<Ongoing>());
    expect(() => repo.resign(done.id, seat: 0), throwsA(isA<StateError>()));
  });

  test('an illegal move is rejected and never reaches storage', () async {
    final game = await newGame();
    await repo.appendMove(game.id, 5);

    expect(() => repo.appendMove(game.id, 5), throwsA(isA<ArgumentError>()),
        reason: 'occupied');
    expect(() => repo.appendMove(game.id, 64), throwsA(isA<ArgumentError>()),
        reason: 'out of range');
    expect(() => repo.appendMove('nope', 0), throwsA(isA<ArgumentError>()));
    expect((await repo.watchGame(game.id).first)!.moves, [5]);
  });

  test('active and completed lists separate, completed ordered for the fold',
      () async {
    final first = await newGame();
    final second = await repo.createGame(
        mode: GameMode.vsComputer, opponent: botOpponent('pebble'));
    final ongoing = await newGame();

    await repo.resign(first.id, seat: 0);
    await repo.resign(second.id, seat: 0);

    expect((await repo.watchActiveGames().first).map((g) => g.id), [ongoing.id]);

    final completed = await repo.loadCompletedGames();
    expect(completed.map((g) => g.id), [second.id, first.id],
        reason: 'completedAt orders the fold, most recent first');
    expect(completed.map((g) => g.id),
        (await repo.watchCompletedGames().first).map((g) => g.id));
  });

  test('watch streams emit the current value and again on every change',
      () async {
    final game = await newGame();
    final seen = <int>[];
    final sub =
        repo.watchGame(game.id).listen((g) => seen.add(g?.moves.length ?? -1));

    await pumpEventQueue();
    await repo.appendMove(game.id, 0);
    await pumpEventQueue();
    await repo.appendMove(game.id, 1);
    await pumpEventQueue();

    expect(seen, [0, 1, 2], reason: 'current value first, then each write');
    await sub.cancel();
  });

  test('a write immediately after subscribing is not lost', () async {
    // The watch stream must subscribe to changes before handing over the
    // current value. Yielding first and subscribing after drops any write
    // that lands in between — which is exactly what a bot replying the moment
    // the screen opens does.
    final game = await newGame();
    final seen = <int>[];
    final sub = repo.watchGame(game.id).listen((g) => seen.add(g!.moves.length));
    final write = repo.appendMove(game.id, 0); // no await: same microtask
    await write;
    await pumpEventQueue();

    expect(seen, containsAllInOrder([0, 1]));
    await sub.cancel();
  });

  test('a stored document cannot be mutated by its holder', () async {
    // Same standard the engine holds itself to (ticket 003): handing out a
    // live view of the move list would let a caller corrupt stored state.
    final game = await repo.appendMove((await newGame()).id, 0);
    expect(() => game.moves.add(1), throwsUnsupportedError);

    final done = await repo.resign(game.id, seat: 1);
    expect(done.result!.line, isNull);
    final won = await newGame();
    for (final cell in [0, 21, 1, 22, 2, 26, 3]) {
      await repo.appendMove(won.id, cell);
    }
    final line = (await repo.watchGame(won.id).first)!.result!.line!;
    expect(() => line.add(9), throwsUnsupportedError);
  });

  test('a deleted game disappears', () async {
    final game = await newGame();
    await repo.deleteGame(game.id);

    expect(await repo.watchGame(game.id).first, isNull);
    expect(await repo.watchActiveGames().first, isEmpty);
  });

  test('settings round-trip and default when never written', () async {
    expect((await repo.loadSettings()).tutorialCompleted, isFalse);
    expect((await repo.loadSettings()).locale, 'system');

    final saved = await repo.saveSettings(const SettingsDocument(
        locale: 'nl', theme: 'dark', tutorialCompleted: true));
    expect(saved.tutorialCompleted, isTrue);
    expect((await repo.watchSettings().first).locale, 'nl');
  });

  test('statistics are derivable by folding completed games', () async {
    // No stored aggregate exists to drift: the fold is the only source.
    final won = await repo.createGame(
        mode: GameMode.vsComputer,
        opponent: botOpponent('pebble'),
        opponentRating: 800);
    for (final cell in [0, 21, 1, 22, 2, 26, 3]) {
      await repo.appendMove(won.id, cell);
    }
    final lost = await repo.createGame(
        mode: GameMode.vsComputer,
        opponent: botOpponent('pebble'),
        opponentRating: 800);
    await repo.resign(lost.id, seat: 0);

    final completed = await repo.loadCompletedGames();
    final wins = completed
        .where((g) => g.result?.winnerSeat == g.playerSeat)
        .length;
    expect(completed.length, 2);
    expect(wins, 1);
  });
}

/// Behaviour that only the on-disk store can have: surviving a restart, and
/// surviving damage.
void fileStoreTests() {
  late Directory root;
  late Fixtures fixtures;

  Future<LocalGameRepository> open() async => LocalGameRepository.open(
      await FileDocumentStore.open(root),
      now: fixtures.now,
      newId: fixtures.nextId);

  setUp(() async {
    root = await Directory.systemTemp.createTemp('quadrim_disk_test');
    fixtures = Fixtures();
  });
  tearDown(() async {
    if (root.existsSync()) await root.delete(recursive: true);
  });

  test('an in-progress game survives a restart with its moves intact',
      () async {
    final repo = await open();
    final game = await repo.createGame(
        mode: GameMode.passAndPlay, opponent: kGuestOpponent);
    for (final cell in [0, 21, 1, 22, 2]) {
      await repo.appendMove(game.id, cell);
    }
    await repo.dispose();

    // A fresh instance over the same directory: this is the restart.
    final reopened = await open();
    final restored = await reopened.watchGame(game.id).first;
    expect(restored, isNotNull);
    expect(restored!.moves, [0, 21, 1, 22, 2]);
    expect(restored.status, GameStatus.active);
    await reopened.dispose();
  });

  test('a deleted game is gone from disk too', () async {
    final repo = await open();
    final game = await repo.createGame(
        mode: GameMode.passAndPlay, opponent: kGuestOpponent);
    await repo.deleteGame(game.id);
    expect(File('${root.path}/games/${game.id}.json').existsSync(), isFalse);
    await repo.dispose();
  });

  test('a document from a newer schema is skipped, not misread', () async {
    final repo = await open();
    final good = await repo.createGame(
        mode: GameMode.passAndPlay, opponent: kGuestOpponent);
    await repo.dispose();

    final future = Map<String, Object?>.from(good.toJson())
      ..['id'] = 'from-the-future'
      ..['schemaVersion'] = kSchemaVersion + 1;
    File('${root.path}/games/from-the-future.json')
        .writeAsStringSync(jsonEncode(future));

    final reopened = await open();
    expect((await reopened.watchActiveGames().first).map((g) => g.id),
        [good.id],
        reason: 'newer than this build understands must be skipped');
    await reopened.dispose();
  });

  test('a kill mid-write leaves no corrupted record', () async {
    final repo = await open();
    final game = await repo.createGame(
        mode: GameMode.passAndPlay, opponent: kGuestOpponent);
    await repo.appendMove(game.id, 7);
    await repo.dispose();

    // Writes go to .tmp and are renamed into place, so an interrupted write
    // can only ever leave a partial .tmp beside an intact record.
    File('${root.path}/games/${game.id}.json.tmp')
        .writeAsStringSync('{"id":"${game.id}","schemaV');
    // Belt and braces: a truncated .json too, which is what a non-atomic
    // implementation would have produced.
    File('${root.path}/games/truncated.json').writeAsStringSync('{"id":');

    final reopened = await open();
    final active = await reopened.watchActiveGames().first;
    expect(active.length, 1);
    expect(active.single.moves, [7], reason: 'the intact record still reads');
    await reopened.dispose();
  });

  test('stored games carry a schema version and no device identifier',
      () async {
    final repo = await open();
    final game = await repo.createGame(
        mode: GameMode.vsComputer,
        opponent: botOpponent('pebble'),
        opponentRating: 800);
    await repo.dispose();

    final raw = jsonDecode(
      File('${root.path}/games/${game.id}.json').readAsStringSync(),
    ) as Map<String, Object?>;

    expect(raw['schemaVersion'], kSchemaVersion);
    // D2/S2: the document is exactly the spec's §8.3 field set, so a device
    // identifier cannot be smuggled in unnoticed.
    expect(raw.keys.toSet(), {
      'id', 'schemaVersion', 'mode', 'opponent', 'opponentRating',
      'playerSeat', 'startingSeat', 'startReason', 'moves', 'state',
      'completedAt', 'result', 'rematchOf', 'createdAt', 'updatedAt',
    });
    expect(raw['createdAt'], endsWith('Z'), reason: 'ISO-8601 UTC');
  });

  test('settings persist across a restart', () async {
    final repo = await open();
    await repo.saveSettings(const SettingsDocument(
        locale: 'nl', theme: 'dark', tutorialCompleted: true));
    await repo.dispose();

    final reopened = await open();
    final settings = await reopened.loadSettings();
    expect(settings.locale, 'nl');
    expect(settings.theme, 'dark');
    expect(settings.tutorialCompleted, isTrue);
    await reopened.dispose();
  });
}

/// A drawn game taken from the shared corpus rather than invented here.
List<int> _drawnGame() {
  final corpus = jsonDecode(
    File('../packages/quadrim_engine/test/fixtures/corpus.json')
        .readAsStringSync(),
  ) as Map<String, dynamic>;
  final draw = (corpus['games'] as List)
      .cast<Map<String, dynamic>>()
      .firstWhere((g) => g['outcome'] == 'draw');
  return (draw['moves'] as List).cast<int>();
}
