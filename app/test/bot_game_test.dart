import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrim/data/document_store.dart';
import 'package:quadrim/data/documents.dart';
import 'package:quadrim/data/local_game_repository.dart';
import 'package:quadrim/game/game_screen.dart';
import 'package:quadrim/l10n/app_localizations.dart';
import 'package:quadrim/main.dart';
import 'package:quadrim_engine/quadrim_engine.dart';

Future<LocalGameRepository> _repository() async {
  final repository = await LocalGameRepository.open(MemoryDocumentStore());
  addTearDown(repository.dispose);
  // Not a fresh player: the first-launch tutorial offer would open over the
  // main screen this test is about to drive.
  await repository
      .saveSettings(const SettingsDocument(tutorialOffered: true));
  return repository;
}

Widget _harness(LocalGameRepository repo, String id, Random random) =>
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: GameScreen(
        repository: repo,
        gameId: id,
        random: random,
        opponentMove: chooseMoveInline,
      ),
    );

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2280);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('the home screen offers a computer opponent as well as a second '
      'human', (tester) async {
    _phone(tester);
    final repo = await _repository();
    // A seeded source so the opening seat is fixed rather than a coin flip.
    await tester.pumpWidget(
        QuadrimApp(repository: repo, settings: repo, random: Random(1)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('New game'));
    await tester.pumpAndSettle();
    expect(find.text('Play the computer'), findsOneWidget);
    expect(find.text('Pass and play'), findsOneWidget);

    await tester.tap(find.text('Play the computer'));
    await tester.pumpAndSettle();

    // Since ticket 011 the mode sheet leads to the opponent list rather than
    // straight into a game against a default opponent, so nothing is stored
    // until somebody is chosen.
    expect(find.text('Choose an opponent'), findsOneWidget);
    expect(await repo.watchActiveGames().first, isEmpty,
        reason: 'no game exists until an opponent is picked');

    // The list is an accordion opened on the tier nearest the player, and a
    // player with no games sits on the seed — so Novice is shut and has to be
    // opened to reach Pebble.
    await tester.tap(find.text('Novice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pebble'));
    // Bounded pumps rather than pumpAndSettle: when the opponent opens, the
    // thinking indicator animates indefinitely and the frame scheduler never
    // goes idle (D166). Long enough to clear the opponent's visible pause.
    await tester.pump();
    await tester.pump(kBotMoveDelay + const Duration(milliseconds: 50));

    final games = await repo.watchActiveGames().first;
    expect(games.single.mode, GameMode.vsComputer);
    expect(games.single.opponent, 'bot:pebble');
    expect(games.single.opponentRating, 600,
        reason: 'the anchor played against is recorded on the game');
  });

  testWidgets('the opponent takes a visible moment over its move',
      (tester) async {
    _phone(tester);
    final repo = await _repository();
    final game = await repo.createGame(
      mode: GameMode.vsComputer,
      opponent: botOpponent(pebble.id),
      opponentRating: pebble.rating,
    );
    await tester.pumpWidget(_harness(repo, game.id, Random(7)));
    await tester.pumpAndSettle();

    expect(find.text('Your turn'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('cell-0')));
    await tester.pump();

    // Mid-think: the opponent is announced and the board is closed to taps.
    expect(find.text('Pebble is thinking…'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('cell-1')));
    await tester.pump();
    expect((await repo.watchGame(game.id).first)!.moves, [0],
        reason: 'the player must not be able to move for the opponent');

    await tester.pump(kBotMoveDelay);
    await tester.pumpAndSettle();
    expect(find.text('Your turn'), findsOneWidget);
    expect((await repo.watchGame(game.id).first)!.moves.length, 2);
  });

  testWidgets('the opponent opens when it holds the starting seat',
      (tester) async {
    _phone(tester);
    final repo = await _repository();
    // startingSeat 1 with the player on seat 0: the board must not be empty
    // once the screen settles. This is the case that used to be lost to the
    // watch-stream race (D140).
    final game = await repo.createGame(
      mode: GameMode.vsComputer,
      opponent: botOpponent(pebble.id),
      opponentRating: pebble.rating,
      startingSeat: 1,
    );
    await tester.pumpWidget(_harness(repo, game.id, Random(3)));
    // pumpAndSettle does not advance the clock when no frame is scheduled, so
    // the opponent's deliberate pause has to be pumped explicitly.
    await tester.pump(kBotMoveDelay);
    await tester.pumpAndSettle();

    expect((await repo.watchGame(game.id).first)!.moves.length, 1);
    expect(find.text('Your turn'), findsOneWidget);
  });

  testWidgets('a second tap before the first is stored cannot move for the '
      'opponent', (tester) async {
    _phone(tester);
    final repo = await _repository();
    final game = await repo.createGame(
      mode: GameMode.vsComputer,
      opponent: botOpponent(pebble.id),
      opponentRating: pebble.rating,
    );
    await tester.pumpWidget(_harness(repo, game.id, Random(7)));
    await tester.pumpAndSettle();

    // Two taps inside one frame. The board is still enabled for the second,
    // because the first has not round-tripped through the repository yet —
    // so without a guard the player takes the opponent's turn as well.
    await tester.tap(find.byKey(const ValueKey('cell-0')));
    await tester.tap(find.byKey(const ValueKey('cell-1')));
    await tester.pump();

    expect((await repo.watchGame(game.id).first)!.moves, [0]);

    // Drain the opponent's pending pause so the test does not end with a
    // timer still running.
    await tester.pump(kBotMoveDelay);
    await tester.pumpAndSettle();
    expect((await repo.watchGame(game.id).first)!.moves.length, 2,
        reason: 'the opponent still gets its own turn');
  });

  testWidgets('a full game against the computer reaches a stored result',
      (tester) async {
    _phone(tester);
    final repo = await _repository();
    final game = await repo.createGame(
      mode: GameMode.vsComputer,
      opponent: botOpponent(pebble.id),
      opponentRating: pebble.rating,
    );
    await tester.pumpWidget(_harness(repo, game.id, Random(11)));
    await tester.pumpAndSettle();

    // Play the lowest-index empty cell every turn. Terminates either by
    // completing a line or by filling the board.
    for (var turn = 0; turn < 64; turn++) {
      final current = (await repo.watchGame(game.id).first)!;
      if (current.status == GameStatus.complete) break;
      if (current.seatToMove != current.playerSeat) {
        await tester.pump(kBotMoveDelay);
        await tester.pumpAndSettle();
        continue;
      }
      final state = GameState.fromMoves(current.moves);
      await tester.tap(find.byKey(ValueKey('cell-${legalMoves(state).first.index}')));
      await tester.pumpAndSettle();
    }

    final done = (await repo.watchGame(game.id).first)!;
    expect(done.status, GameStatus.complete);
    expect(done.result, isNotNull);
    expect(done.completedAt, isNotNull);
    // Whoever won, the screen names it in the player's terms and offers a
    // way back.
    expect(
      find.byWidgetPredicate((w) =>
          w is Text &&
          (w.data == 'You win!' ||
              w.data == 'Pebble wins!' ||
              w.data == "It's a draw — the board is full.")),
      findsOneWidget,
    );
    expect(find.text('Back'), findsOneWidget);
  });

  testWidgets('the opponent name and its thinking state are localized',
      (tester) async {
    _phone(tester);
    final repo = await _repository();
    final game = await repo.createGame(
      mode: GameMode.vsComputer,
      opponent: botOpponent(pebble.id),
      opponentRating: pebble.rating,
      startingSeat: 1,
    );
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('nl'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: GameScreen(
        repository: repo,
        gameId: game.id,
        random: Random(3),
        opponentMove: chooseMoveInline,
      ),
    ));
    await tester.pump();

    expect(find.text('Pebble denkt na…'), findsOneWidget);
    await tester.pump(kBotMoveDelay);
    await tester.pumpAndSettle();
    expect(find.text('Jij bent aan zet'), findsOneWidget);
  });

  testWidgets('the app path runs the search in a background isolate', (
    tester,
  ) async {
    // The screen's default is chooseMoveInBackground, which every other test
    // replaces because a real isolate never completes inside the fake-async
    // zone testWidgets runs in (D153). runAsync steps outside that zone, so
    // this one test exercises the path the app actually takes — with Onyx,
    // whose four-ply search is the reason the isolate exists.
    final move = await tester.runAsync(() =>
        chooseMoveInBackground(const [0, 21, 5], onyx, Random(11)));
    final state = GameState.fromMoves(const [0, 21, 5]);
    expect(legalMoves(state).map((c) => c.index), contains(move));
  });

  testWidgets('resigning while the opponent is thinking does not crash', (
    tester,
  ) async {
    _phone(tester);
    final repo = await _repository();
    // Seat 1 opens, so the opponent moves first and the screen is busy from
    // the moment it appears.
    final game = await repo.createGame(
      mode: GameMode.vsComputer,
      opponent: botOpponent(pebble.id),
      opponentRating: pebble.rating,
      startingSeat: 1,
    );
    await tester.pumpWidget(_harness(repo, game.id, Random(3)));
    await tester.pump();

    // The player resigns inside the opponent's thinking time. Its move is
    // then computed for a game that no longer accepts moves; appending it
    // would throw StateError out of an unawaited future.
    await repo.resign(game.id, seat: game.playerSeat);
    await tester.pump();
    await tester.pump(kBotMoveDelay);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final stored = await repo.watchGame(game.id).first;
    expect(stored!.status, GameStatus.complete);
    expect(stored.moves, isEmpty, reason: 'the stale move must be dropped');
  });

  testWidgets('a thinking opponent shows a moving indicator, not just text', (
    tester,
  ) async {
    _phone(tester);
    final repo = await _repository();
    // Seat 1 opens, so the opponent is thinking from the first frame.
    final game = await repo.createGame(
      mode: GameMode.vsComputer,
      opponent: botOpponent(pebble.id),
      opponentRating: pebble.rating,
      startingSeat: 1,
    );
    await tester.pumpWidget(_harness(repo, game.id, Random(3)));
    await tester.pump();

    // A move may take twenty seconds on a device (D164); static text alone
    // would be indistinguishable from a frozen app (D166).
    expect(find.text('Pebble is thinking…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(kBotMoveDelay);
    await tester.pumpAndSettle();

    // And it goes away once the turn is the player's again.
    expect(find.text('Your turn'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

}
