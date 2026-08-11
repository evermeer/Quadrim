import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrim/data/document_store.dart';
import 'package:quadrim/data/documents.dart';
import 'package:quadrim/data/local_game_repository.dart';
import 'package:quadrim/game/board_view.dart';
import 'package:quadrim/game/game_screen.dart';
import 'package:quadrim/l10n/app_localizations.dart';
import 'package:quadrim/main.dart';
import 'package:quadrim_engine/quadrim_engine.dart';

void _phone(WidgetTester tester, {Size size = const Size(360, 844)}) {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// A pass-and-play game with [moves] played, on screen.
Future<LocalGameRepository> _game(
  WidgetTester tester,
  List<int> moves, {
  Locale? locale,
}) async {
  final repository = await LocalGameRepository.open(MemoryDocumentStore());
  addTearDown(repository.dispose);
  await repository.saveSettings(const SettingsDocument(tutorialOffered: true));
  await tester.pumpWidget(
      QuadrimApp(repository: repository, settings: repository, locale: locale));
  await tester.pumpAndSettle();
  await tester.tap(find.text(locale == null ? 'New game' : 'Nieuwe partij'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(locale == null ? 'Pass and play' : 'Samen op één toestel'));
  await tester.pumpAndSettle();
  for (final move in moves) {
    await tester.tap(find.byKey(ValueKey('cell-$move')), warnIfMissed: false);
    await tester.pumpAndSettle();
  }
  return repository;
}

BoardView _board(WidgetTester tester) =>
    tester.widget<BoardView>(find.byType(BoardView));

Future<void> _openReview(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.history));
  await tester.pumpAndSettle();
}

Future<void> _tapIcon(WidgetTester tester, IconData icon) async {
  await tester.tap(find.byIcon(icon));
  await tester.pumpAndSettle();
}

/// Light takes {0,1,2,3}; dark's four are scattered and form no line.
const _winMoves = [0, 32, 1, 47, 2, 53, 3];

void main() {
  testWidgets('steps back and forward one move at a time', (tester) async {
    _phone(tester);
    await _game(tester, [21, 22, 26]);
    await _openReview(tester);

    expect(find.text('Move 3 of 3'), findsOneWidget);
    expect(_board(tester).state.moves, [21, 22, 26]);

    await _tapIcon(tester, Icons.chevron_left);
    expect(find.text('Move 2 of 3'), findsOneWidget);
    expect(_board(tester).state.moves, [21, 22]);

    await _tapIcon(tester, Icons.chevron_left);
    expect(find.text('Move 1 of 3'), findsOneWidget);
    expect(_board(tester).state.moves, [21]);

    await _tapIcon(tester, Icons.chevron_right);
    expect(find.text('Move 2 of 3'), findsOneWidget);
    expect(_board(tester).state.moves, [21, 22]);
  });

  testWidgets('jumps to the start and to the latest move', (tester) async {
    _phone(tester);
    await _game(tester, [21, 22, 26]);
    await _openReview(tester);

    await _tapIcon(tester, Icons.first_page);
    expect(find.text('Move 0 of 3'), findsOneWidget);
    expect(_board(tester).state.moves, isEmpty, reason: 'the empty board');

    await _tapIcon(tester, Icons.last_page);
    expect(find.text('Move 3 of 3'), findsOneWidget);
    expect(_board(tester).state.moves, [21, 22, 26]);
  });

  testWidgets('the ends of the history are not steppable past',
      (tester) async {
    _phone(tester);
    await _game(tester, [21, 22]);
    await _openReview(tester);

    IconButton button(IconData icon) =>
        tester.widget<IconButton>(find.widgetWithIcon(IconButton, icon));

    expect(button(Icons.chevron_right).onPressed, isNull, reason: 'at the end');
    expect(button(Icons.last_page).onPressed, isNull);
    expect(button(Icons.chevron_left).onPressed, isNotNull);

    await _tapIcon(tester, Icons.first_page);
    expect(button(Icons.chevron_left).onPressed, isNull, reason: 'at the start');
    expect(button(Icons.first_page).onPressed, isNull);
    expect(button(Icons.chevron_right).onPressed, isNotNull);
  });

  testWidgets('no move can be made from a past position, and the game is '
      'unchanged by looking', (tester) async {
    _phone(tester);
    final repo = await _game(tester, [21, 22, 26]);
    await _openReview(tester);
    await _tapIcon(tester, Icons.chevron_left);

    expect(_board(tester).enabled, isFalse);
    // Cell 5 is empty in every position here, so a tap that got through would
    // be a fourth move appended to the stored game.
    await tester.tap(find.byKey(const ValueKey('cell-5')), warnIfMissed: false);
    await tester.pumpAndSettle();

    final stored = await repo.watchGame((await repo.watchActiveGames().first)
            .single
            .id)
        .first;
    expect(stored!.moves, [21, 22, 26], reason: 'reviewing stored nothing');
    expect(find.text('Move 2 of 3'), findsOneWidget, reason: 'and moved not');
  });

  testWidgets('leaving review resumes play exactly where it was',
      (tester) async {
    _phone(tester);
    final repo = await _game(tester, [21, 22, 26]);
    await _openReview(tester);
    await _tapIcon(tester, Icons.first_page);
    await _tapIcon(tester, Icons.close);

    // The banner is back, the live position is back, and the board is live.
    expect(find.text('Dark to move'), findsOneWidget);
    expect(_board(tester).state.moves, [21, 22, 26]);
    expect(_board(tester).enabled, isTrue);

    // And a move still lands, which is the part that says play resumed rather
    // than merely that the view did.
    await tester.tap(find.byKey(const ValueKey('cell-5')), warnIfMissed: false);
    await tester.pumpAndSettle();
    final game = (await repo.watchActiveGames().first).single;
    expect(game.moves, [21, 22, 26, 5]);
  });

  testWidgets('a finished game can be replayed the same way', (tester) async {
    _phone(tester);
    await _game(tester, _winMoves);
    expect(find.text('Light wins!'), findsOneWidget);

    await _openReview(tester);
    expect(find.text('Move 7 of 7'), findsOneWidget);
    await _tapIcon(tester, Icons.chevron_left);
    expect(_board(tester).state.moves, _winMoves.take(6));
    // The result panel is out of the way while reviewing — its Rematch button
    // starts a different game.
    expect(find.text('Rematch'), findsNothing);

    await _tapIcon(tester, Icons.close);
    expect(find.text('Rematch'), findsOneWidget);
    expect(find.text('Light wins!'), findsOneWidget);
  });

  testWidgets('the scrubber is reachable and the position is announced',
      (tester) async {
    _phone(tester);
    final handle = tester.ensureSemantics();
    await _game(tester, [21, 22, 26]);
    await _openReview(tester);

    // Every control names itself, as a button, in the semantics tree.
    //
    // Asserted on the `tooltip` field rather than `label`: Flutter puts an
    // IconButton's tooltip in a field of its own, so `find.bySemanticsLabel`
    // matches nothing here and a test written that way fails while the app is
    // perfectly usable. Checked against a dump of the tree rather than guessed
    // (D204).
    for (final name in [
      'Jump to the start',
      'Previous move',
      'Next move',
      'Jump to the latest move',
    ]) {
      final node = tester.getSemantics(find.byTooltip(name));
      expect(node.tooltip, name, reason: name);
      expect(node.flagsCollection.isButton, isTrue, reason: name);
    }

    // The announcement carries the move, not just the counter: cell 26 is
    // layer 2, row 3, column 3, and move 3 is light.
    expect(find.bySemanticsLabel('Move 3 of 3. Layer 2, row 3, column 3, light piece'),
        findsOneWidget);

    await _tapIcon(tester, Icons.chevron_left);
    expect(find.bySemanticsLabel('Move 2 of 3. Layer 2, row 2, column 3, dark piece'),
        findsOneWidget);

    await _tapIcon(tester, Icons.first_page);
    expect(find.bySemanticsLabel('Move 0 of 3. Before the first move'),
        findsOneWidget);
    handle.dispose();
  });

  testWidgets('fits the shortest supported screen', (tester) async {
    // The scrubber takes the turn banner's slot rather than adding a row,
    // because at 360x780 the board has about 6dp of vertical slack (D204).
    _phone(tester, size: const Size(360, 780));
    await _game(tester, [21, 22, 26]);
    final playing = tester.getSize(find.byKey(const ValueKey('cell-0')));
    expect(playing.width, greaterThanOrEqualTo(kMinCellSize),
        reason: 'the playing board still meets the touch floor');

    await _openReview(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Move 3 of 3'), findsOneWidget);
    // Reviewing may cost a fraction of a dp — nothing here is tappable, so the
    // floor that applies is legibility, not reach.
    final reviewing = tester.getSize(find.byKey(const ValueKey('cell-0')));
    expect(reviewing.width, greaterThan(24));
  });

  testWidgets('the game carries on underneath while the player reviews',
      (tester) async {
    _phone(tester);
    final repo = await LocalGameRepository.open(MemoryDocumentStore());
    addTearDown(repo.dispose);
    final game = await repo.createGame(
      mode: GameMode.vsComputer,
      opponent: botOpponent(pebble.id),
      opponentRating: pebble.rating,
    );
    await repo.appendMove(game.id, 21); // the player
    await repo.appendMove(game.id, 22); // the opponent
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: GameScreen(
        repository: repo,
        gameId: game.id,
        random: Random(1),
        opponentMove: chooseMoveInline,
      ),
    ));
    await tester.pumpAndSettle();

    await _openReview(tester);
    await _tapIcon(tester, Icons.first_page);
    expect(find.text('Move 0 of 2'), findsOneWidget);

    // A move lands from outside this screen, handing the turn to the opponent.
    await repo.appendMove(game.id, 40);
    // Pumped past kBotMoveDelay explicitly: a reviewed board is static, so no
    // frames are scheduled and pumpAndSettle alone would not advance the clock.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // The opponent replied — reviewing does not pause the game — and the view
    // did not move. Yanking the player to the present would make the scrubber
    // alter the thing it is meant to be a window onto (D204).
    final stored = (await repo.watchGame(game.id).first)!;
    expect(stored.moves.length, 4, reason: 'the opponent answered');
    expect(_board(tester).state.moves, isEmpty, reason: 'still at move 0');
    expect(find.text('Move 0 of 4'), findsOneWidget);
  });

  testWidgets('every scrubber string exists in Dutch', (tester) async {
    _phone(tester);
    await _game(tester, [21, 22, 26], locale: const Locale('nl'));
    await _openReview(tester);

    expect(find.text('Zet 3 van 3'), findsOneWidget);
    expect(find.text('Move 3 of 3'), findsNothing);
    await _tapIcon(tester, Icons.first_page);
    expect(find.text('Zet 0 van 3'), findsOneWidget);
  });
}
