import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrim/data/document_store.dart';
import 'package:quadrim/data/documents.dart';
import 'package:quadrim/data/local_game_repository.dart';
import 'package:quadrim/game/board_view.dart';
import 'package:quadrim/main.dart';
import 'package:quadrim/tutorial/practice_hint.dart';
import 'package:quadrim/tutorial/practice_screen.dart';
import 'package:quadrim/tutorial/tutorial_steps.dart';
import 'package:quadrim_engine/quadrim_engine.dart';

Future<LocalGameRepository> _repository() async {
  final repository = await LocalGameRepository.open(MemoryDocumentStore());
  addTearDown(repository.dispose);
  await repository.saveSettings(const SettingsDocument(tutorialOffered: true));
  return repository;
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
}

/// Opens the tutorial, walks to the last step, and starts the practice game.
Future<void> _openPractice(
    WidgetTester tester, LocalGameRepository repo) async {
  await tester.pumpWidget(QuadrimApp(repository: repo, settings: repo));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(TextButton, 'Tutorial'));
  await tester.pumpAndSettle();
  while (find.text('Next').evaluate().isNotEmpty) {
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.text('Play a practice game'));
  await tester.pumpAndSettle();
}

Finder _cell(int index) => find.byKey(ValueKey('cell-$index'));

Future<void> _tapCell(WidgetTester tester, int index) async {
  await tester.tap(_cell(index));
  await tester.pumpAndSettle();
}

/// Where the board is currently pointing.
List<int> _highlight(WidgetTester tester) =>
    tester.widget<BoardView>(find.byType(BoardView)).highlight;

/// The labels of every live region on screen, in tree order.
///
/// Walked rather than found by label, because the bug this guards against is
/// a live region with *no* label — which no `find.bySemanticsLabel` can see.
List<String> _liveRegions(WidgetTester tester) {
  final labels = <String>[];
  void walk(SemanticsNode node) {
    if (node.getSemanticsData().flagsCollection.isLiveRegion) {
      labels.add(node.label);
    }
    node.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  // Since Flutter's multi-view work the semantics owner hangs off a *child*
  // of the root pipeline owner, not the root itself, so it has to be found
  // rather than read. `tester.binding.pipelineOwner` still reaches it and is
  // deprecated, which check.sh would reject.
  SemanticsNode? root;
  void findRoot(PipelineOwner owner) {
    root ??= owner.semanticsOwner?.rootSemanticsNode;
    owner.visitChildren(findRoot);
  }

  findRoot(tester.binding.rootPipelineOwner);
  walk(root!);
  return labels;
}

void main() {
  group('hints come from the position, not a script', () {
    test('an available win outranks everything', () {
      // Light holds three of a row; the fourth is free.
      final state = GameState.fromMoves([0, 32, 1, 47, 2]);
      final hint = hintFor(state, Player.first)!;
      expect(hint.kind, HintKind.win);
      expect(hint.cell.index, 3);
    });

    test('a threat against the player is named as a block', () {
      final state = GameState.fromMoves(kBlockingMoves);
      final hint = hintFor(state, Player.first)!;
      expect(hint.kind, HintKind.block);
      expect(hint.cell.index, kBlockingCell.single);
    });

    test('a win is taken in preference to a block', () {
      // Both sides are one move from a line. The player is to move, so the
      // win is the answer — blocking here loses the game it was trying to save.
      final state = GameState.fromMoves([0, 16, 1, 17, 2, 18]);
      expect(threats(state, Player.first).length, 1);
      expect(threats(state, Player.second).length, 1);
      final hint = hintFor(state, Player.first)!;
      expect(hint.kind, HintKind.win);
      expect(hint.cell.index, 3);
    });

    test('a fork is found by playing it, and really is a fork', () {
      // Light holds 1, 2, 4 and 8 with no threat yet; 0 makes two at once.
      final state = GameState.fromMoves([1, 32, 2, 47, 4, 53, 8, 58]);
      expect(threats(state, Player.first), isEmpty);
      final hint = hintFor(state, Player.first)!;
      expect(hint.kind, HintKind.fork);
      // The claim is checked the same way the hint made it: play the move.
      final after = applyMove(state, hint.cell);
      expect(threats(after, Player.first).length, greaterThanOrEqualTo(2));
    });

    test('with nothing to do it names the square on the most lines', () {
      final hint = hintFor(GameState.initial(), Player.first)!;
      expect(hint.kind, HintKind.build);
      // Seven lines, and central rather than a corner — the order the strategy
      // steps taught and the opponents' positional ladder uses.
      expect(winningLines.where((l) => l.contains(hint.cell.index)).length, 7);
      expect(kCentreCells, contains(hint.cell.index));
    });

    test('there is no hint once the game is over', () {
      final state = GameState.fromMoves(demoMoves(kGoalLine));
      expect(outcome(state), isA<Win>());
      expect(hintFor(state, Player.first), isNull);
    });

    test('every hint points at a square that is actually free', () {
      // Walked over a real game rather than a handful of fixtures: a hint that
      // names an occupied cell is advice the player cannot follow.
      var state = GameState.initial();
      final random = Random(7);
      while (!state.isOver) {
        final hint = hintFor(state, state.sideToMove);
        expect(hint, isNotNull);
        expect(state.owner(hint!.cell), isNull);
        state = applyMove(state, chooseMove(state, mote, random));
      }
    });
  });

  group('the practice game', () {
    test('is a real opponent configuration, not a script', () {
      // The ticket asks for a BotConfig with a fixed seed rather than a second
      // code path. Asserting it is a catalogue member is what stops a
      // "practice" clone being quietly forked off later.
      expect(opponentCatalogue, contains(kPracticeOpponent));
      expect(kPracticeOpponent.id, mote.id);
      // Deliberately beatable: it takes a win and blocks one, and blunders
      // often. A opponent with the full rule set would not be a first game.
      expect(kPracticeOpponent.blunderRate, greaterThan(0));
      expect(kPracticeOpponent.tier, BotTier.novice);
    });

    testWidgets('opens from the last tutorial step', (tester) async {
      _phone(tester);
      await _openPractice(tester, await _repository());
      expect(find.text('Practice game'), findsOneWidget);
      expect(find.text('Your turn'), findsOneWidget);
    });

    testWidgets('shows nothing until a hint is asked for', (tester) async {
      _phone(tester);
      await _openPractice(tester, await _repository());
      // Declining hints entirely means never pressing the button, and the
      // board must look the same as if the feature did not exist.
      expect(_highlight(tester), isEmpty);

      await tester.tap(find.text('Hint'));
      await tester.pumpAndSettle();
      expect(_highlight(tester), hasLength(1));
      expect(find.textContaining('sits on more lines'), findsOneWidget);
    });

    testWidgets('a move the hint discouraged is allowed, and play continues',
        (tester) async {
      _phone(tester);
      await _openPractice(tester, await _repository());
      await tester.tap(find.text('Hint'));
      await tester.pumpAndSettle();
      final suggested = _highlight(tester).single;

      // Deliberately somewhere else.
      final elsewhere = suggested == 63 ? 0 : 63;
      await _tapCell(tester, elsewhere);

      final board = tester.widget<BoardView>(find.byType(BoardView));
      expect(board.state.owner(Cell(elsewhere)), Player.first);
      // The advice went with the position it described.
      expect(board.highlight, isEmpty);
      // And the opponent answered, so the game is still going.
      expect(board.state.moves.length, 2);
      expect(find.text('Your turn'), findsOneWidget);
    });

    testWidgets('the opponent replies, and the same seed gives the same game',
        (tester) async {
      _phone(tester);
      await _openPractice(tester, await _repository());
      await _tapCell(tester, 21);
      final first =
          tester.widget<BoardView>(find.byType(BoardView)).state.moves;
      expect(first, hasLength(2));

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Play a practice game'));
      await tester.pumpAndSettle();
      await _tapCell(tester, 21);
      expect(tester.widget<BoardView>(find.byType(BoardView)).state.moves,
          first);
    });

    testWidgets('leaving it does not finish the tutorial, and does not block '
        'finishing', (tester) async {
      _phone(tester);
      final repo = await _repository();
      await _openPractice(tester, await Future.value(repo));
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('That is how they play'), findsOneWidget,
          reason: 'back on the last step');
      expect((await repo.loadSettings()).tutorialCompleted, isFalse);

      // Done is still there, so abandoning the game did not trap the player.
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect((await repo.loadSettings()).tutorialCompleted, isTrue);
    });

    testWidgets('playing it out finishes the tutorial', (tester) async {
      _phone(tester);
      final repo = await _repository();
      await _openPractice(tester, repo);

      // Played by following the hints, which is both the fastest way to a
      // finished game and a check that the advice is followable move after
      // move — not just on the opening position.
      while (find.text('Finish the tutorial').evaluate().isEmpty) {
        await tester.tap(find.text('Hint'));
        await tester.pumpAndSettle();
        await _tapCell(tester, _highlight(tester).single);
      }
      // Following the advice must actually beat the opponent the tutorial
      // chose, or the closing lesson is that the lessons do not work.
      expect(find.text('You win!'), findsOneWidget);

      await tester.tap(find.text('Finish the tutorial'));
      await tester.pumpAndSettle();

      expect(find.text('New game'), findsOneWidget, reason: 'back on home');
      expect((await repo.loadSettings()).tutorialCompleted, isTrue);
    });

    testWidgets('never reaches the repository', (tester) async {
      _phone(tester);
      final repo = await _repository();
      await _openPractice(tester, repo);
      while (find.text('Finish the tutorial').evaluate().isEmpty) {
        await tester.tap(find.text('Hint'));
        await tester.pumpAndSettle();
        await _tapCell(tester, _highlight(tester).single);
      }
      await tester.tap(find.text('Finish the tutorial'));
      await tester.pumpAndSettle();

      // A whole game played, and storage has never heard of it: no active
      // game, no completed game, and therefore nothing in the statistics or
      // the rating that the main screen folds out of them (D200).
      expect(await repo.loadCompletedGames(), isEmpty);
      expect(await repo.watchActiveGames().first, isEmpty);
      expect(await repo.watchCompletedGames().first, isEmpty);
      expect(find.text('No games yet.'), findsOneWidget);
    });

    testWidgets('the reserved hint line is silent until it has something to say',
        (tester) async {
      _phone(tester);
      final handle = tester.ensureSemantics();
      await _openPractice(tester, await _repository());

      // The hint line holds its height whether or not there is a hint, so the
      // board does not jump. Wrapping the empty placeholder in the live region
      // as well put an unlabelled focus stop between the status and the board
      // — a screen reader lands on it and reads nothing (D201).
      expect(_liveRegions(tester), ['Your turn']);

      await tester.tap(find.text('Hint'));
      await tester.pumpAndSettle();
      expect(_liveRegions(tester), hasLength(2));
      expect(_liveRegions(tester), everyElement(isNotEmpty));
      handle.dispose();
    });

    testWidgets('hints are announced, and say where they point',
        (tester) async {
      _phone(tester);
      final handle = tester.ensureSemantics();
      await _openPractice(tester, await _repository());
      await tester.tap(find.text('Hint'));
      await tester.pumpAndSettle();

      // The hint names its square in the same words the board's own cell
      // labels use, so a screen reader user can go and find it.
      expect(
        find.bySemanticsLabel(RegExp(r'layer \d, row \d, column \d')),
        findsWidgets,
      );
      handle.dispose();
    });

    testWidgets('every practice string exists in Dutch', (tester) async {
      _phone(tester);
      final repo = await _repository();
      await tester.pumpWidget(
          QuadrimApp(repository: repo, settings: repo, locale: const Locale('nl')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Uitleg'));
      await tester.pumpAndSettle();
      while (find.text('Verder').evaluate().isNotEmpty) {
        await tester.tap(find.text('Verder'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Speel een oefenpartij'));
      await tester.pumpAndSettle();

      expect(find.text('Oefenpartij'), findsOneWidget);
      await tester.tap(find.text('Tip'));
      await tester.pumpAndSettle();
      expect(find.textContaining('ligt op meer lijnen'), findsOneWidget);
      expect(find.textContaining('sits on more lines'), findsNothing);
    });
  });
}
