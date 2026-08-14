import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrim/data/document_store.dart';
import 'package:quadrim/data/documents.dart';
import 'package:quadrim/data/local_game_repository.dart';
import 'package:quadrim/game/board_view.dart';
import 'package:quadrim/l10n/app_localizations_en.dart';
import 'package:quadrim/main.dart';
import 'package:quadrim/tutorial/tutorial_steps.dart';
import 'package:quadrim_engine/quadrim_engine.dart';

Future<LocalGameRepository> _repository({
  bool offered = false,
  bool completed = false,
  DocumentStore? store,
}) async {
  final repository =
      await LocalGameRepository.open(store ?? MemoryDocumentStore());
  addTearDown(repository.dispose);
  if (offered || completed) {
    await repository.saveSettings(SettingsDocument(
      tutorialOffered: offered,
      tutorialCompleted: completed,
    ));
  }
  return repository;
}

void _phone(WidgetTester tester, {double textScale = 1}) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Future<void> _pumpApp(
  WidgetTester tester,
  LocalGameRepository repo, {
  Locale? locale,
}) async {
  await tester.pumpWidget(
      QuadrimApp(
          repository: repo, settings: repo, unlocks: repo, locale: locale));
  await tester.pumpAndSettle();
}

/// Opens the tutorial from the main screen's own button.
Future<void> _openFromHome(
    WidgetTester tester, LocalGameRepository repo) async {
  await _pumpApp(tester, repo);
  await tester.tap(find.widgetWithText(TextButton, 'Tutorial'));
  await tester.pumpAndSettle();
}

/// Walks to the last step by pressing Next until Done appears.
Future<void> _toLastStep(WidgetTester tester) async {
  while (find.text('Next').evaluate().isNotEmpty) {
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
  }
}

void main() {
  group('the demonstration positions', () {
    // The whole value of drawing on the real board is that the position is a
    // real one. A hand-typed cell index that is off by one still renders — it
    // just teaches a line that does not exist.
    test('every highlighted line is one of the 76', () {
      const lines = [
        kGoalLine,
        kThroughLayersLine,
        kLayerDiagonalLine,
        kSliceDiagonalLine,
        kCubeDiagonalLine,
      ];
      for (final line in lines) {
        expect(
          winningLines.any((w) => w.toSet().containsAll(line)),
          isTrue,
          reason: '$line is not a winning line',
        );
      }
    });

    test('each family is represented, and they are distinct', () {
      final lines = {
        kGoalLine,
        kThroughLayersLine,
        kLayerDiagonalLine,
        kSliceDiagonalLine,
        kCubeDiagonalLine,
      };
      expect(lines.length, 5);

      // A line lies within one layer iff every cell shares a z; within one
      // slice iff they share a y or an x. Asserting the shape rather than the
      // indices is what makes this catch a "diagonal" that is really a row.
      int z(int c) => c ~/ 16;
      int y(int c) => (c % 16) ~/ 4;
      int x(int c) => c % 4;

      // Along an axis, inside layer 1: z and y fixed, x varies.
      expect(kGoalLine.map(z).toSet(), {0});
      expect(kGoalLine.map(y).toSet().length, 1);
      expect(kGoalLine.map(x).toSet().length, 4);

      // Through the layers: z varies, x and y fixed.
      expect(kThroughLayersLine.map(z).toSet().length, 4);
      expect(kThroughLayersLine.map(x).toSet().length, 1);
      expect(kThroughLayersLine.map(y).toSet().length, 1);

      // Diagonal within one layer: z fixed, both x and y vary.
      expect(kLayerDiagonalLine.map(z).toSet().length, 1);
      expect(kLayerDiagonalLine.map(x).toSet().length, 4);
      expect(kLayerDiagonalLine.map(y).toSet().length, 4);

      // Diagonal through a vertical slice: one of x/y fixed, the other varies
      // with z.
      expect(kSliceDiagonalLine.map(y).toSet().length, 1);
      expect(kSliceDiagonalLine.map(z).toSet().length, 4);
      expect(kSliceDiagonalLine.map(x).toSet().length, 4);

      // Corner to corner: all three vary together.
      expect(kCubeDiagonalLine.map(x).toSet().length, 4);
      expect(kCubeDiagonalLine.map(y).toSet().length, 4);
      expect(kCubeDiagonalLine.map(z).toSet().length, 4);
    });

    test('demoMoves ends with the first player completing the line', () {
      for (final line in [
        kGoalLine,
        kThroughLayersLine,
        kLayerDiagonalLine,
        kSliceDiagonalLine,
        kCubeDiagonalLine,
      ]) {
        final moves = demoMoves(line);
        expect(moves.length, 7, reason: 'four light moves, three dark');
        // Filler must never land on the line it is meant to stay clear of.
        for (var i = 1; i < moves.length; i += 2) {
          expect(line, isNot(contains(moves[i])));
        }
        final result = outcome(GameState.fromMoves(moves));
        expect(result, isA<Win>());
        expect((result as Win).winner, Player.first);
        expect(result.line.toSet(), line.toSet());
      }
    });

    test('the double threat really is one, and really cannot be blocked', () {
      final state = GameState.fromMoves(kDoubleThreatMoves);
      // The step's whole claim. Two threats, two different answers, and the
      // opponent has one move: if the engine found one threat or three, the
      // caption would be teaching something the board does not show.
      final light = threats(state, Player.first);
      expect(light.length, 2);
      expect(light.map((t) => t.emptyCell.index).toSet(),
          kDoubleThreatCells.toSet());
      // Not already won, or there would be nothing left to demonstrate.
      expect(outcome(state), isA<Ongoing>());
      // And the second player has no threat of their own to muddy it.
      expect(threats(state, Player.second), isEmpty);
    });

    test('the blocking position has exactly one threat, and it is dark\'s', () {
      final state = GameState.fromMoves(kBlockingMoves);
      final dark = threats(state, Player.second);
      expect(dark.length, 1);
      expect(dark.single.emptyCell.index, kBlockingCell.single);
      // Light must have nothing better to do. A light win available here would
      // make "light has to take it now" false — taking the win beats blocking.
      expect(threats(state, Player.first), isEmpty);
      expect(outcome(state), isA<Ongoing>());
      // Six moves played, so it is light's turn to make the block.
      expect(state.moves.length.isEven, isTrue);
    });

    test('the highlighted squares are the ones on seven lines', () {
      // The centre and corner steps claim these eight cells each sit on seven
      // lines while most sit on four. That is a fact about the generated line
      // table, so it is checked against the table rather than restated.
      int linesThrough(int cell) =>
          winningLines.where((l) => l.contains(cell)).length;

      for (final cell in [...kCentreCells, ...kCornerCells]) {
        expect(linesThrough(cell), 7, reason: 'cell $cell');
      }
      expect(kCentreCells.length, 8);
      expect(kCornerCells.length, 8);
      // Exactly sixteen such cells exist, so the two steps between them show
      // every one — no third family is being quietly left out.
      final onSeven = [
        for (var c = 0; c < 64; c++)
          if (linesThrough(c) == 7) c
      ];
      expect(onSeven.toSet(), {...kCentreCells, ...kCornerCells});
    });

    test('the taught strategy is what the opponents actually do', () {
      // Ticket 019 requires what is taught to transfer to real games. Each
      // lesson is pinned to the mechanism in the catalogue that realises it,
      // so deleting a rule or zeroing the biases fails here rather than
      // silently turning the tutorial into fiction.
      for (final rule in StrategicRule.values) {
        expect(opponentCatalogue.any((b) => b.rules.contains(rule)), isTrue,
            reason: '$rule is taught but no opponent uses it');
      }
      expect(opponentCatalogue.any((b) => b.centreBias > 0), isTrue);
      expect(opponentCatalogue.any((b) => b.cornerBias > 0), isTrue);
    });

    test('the placing position is mid-game, with light to move', () {
      final state = GameState.fromMoves(kPlacingMoves);
      expect(outcome(state), isA<Ongoing>());
      // An even number of moves played means the first player is on again.
      expect(state.moves.length.isEven, isTrue);
    });
  });

  group('the first-launch offer', () {
    testWidgets('is made to a player who has never been asked', (tester) async {
      _phone(tester);
      await _pumpApp(tester, await _repository());
      expect(find.text('New to Quadrim?'), findsOneWidget);
    });

    testWidgets('is not made twice', (tester) async {
      _phone(tester);
      await _pumpApp(tester, await _repository(offered: true));
      expect(find.text('New to Quadrim?'), findsNothing);
    });

    testWidgets('is not made to a player who has already finished it',
        (tester) async {
      _phone(tester);
      await _pumpApp(tester, await _repository(completed: true));
      expect(find.text('New to Quadrim?'), findsNothing);
    });

    testWidgets('is recorded even when declined, so it is never repeated',
        (tester) async {
      _phone(tester);
      final repo = await _repository();
      await _pumpApp(tester, repo);
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();

      final settings = await repo.loadSettings();
      expect(settings.tutorialOffered, isTrue);
      // Declining is not learning. The distinction is the whole reason there
      // are two booleans rather than one.
      expect(settings.tutorialCompleted, isFalse);
    });

    testWidgets('accepting opens the tutorial', (tester) async {
      _phone(tester);
      await _pumpApp(tester, await _repository());
      await tester.tap(find.text('Show me'));
      await tester.pumpAndSettle();
      expect(find.text('The goal'), findsOneWidget);
    });
  });

  group('the tutorial', () {
    testWidgets('can be restarted from the main screen', (tester) async {
      _phone(tester);
      await _openFromHome(tester, await _repository(offered: true));
      expect(find.text('The goal'), findsOneWidget);
      expect(find.text('Step 1 of 12'), findsOneWidget);
    });

    testWidgets('advances, goes back, and reports where it is', (tester) async {
      _phone(tester);
      await _openFromHome(tester, await _repository(offered: true));

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Step 2 of 12'), findsOneWidget);
      expect(find.text('Four layers, one cube'), findsOneWidget);

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Step 1 of 12'), findsOneWidget);
      expect(find.text('The goal'), findsOneWidget);
    });

    testWidgets('cannot go back from the first step', (tester) async {
      _phone(tester);
      await _openFromHome(tester, await _repository(offered: true));
      final back = tester.widget<TextButton>(
          find.widgetWithText(TextButton, 'Back'));
      expect(back.onPressed, isNull);
    });

    testWidgets('shows every family of winning line on a real board',
        (tester) async {
      _phone(tester);
      await _openFromHome(tester, await _repository(offered: true));

      // Each family in turn, checked by what the board is actually
      // highlighting rather than by the caption above it.
      const expected = [
        kGoalLine,
        kThroughLayersLine,
        null, // placing a piece: a position, but nothing highlighted
        kLayerDiagonalLine,
        kSliceDiagonalLine,
        kCubeDiagonalLine,
      ];
      for (var step = 0; step < expected.length; step++) {
        final board = tester.widget<BoardView>(find.byType(BoardView));
        expect(board.highlight, expected[step] ?? isEmpty,
            reason: 'step ${step + 1}');
        expect(board.enabled, isFalse, reason: 'step ${step + 1}');
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
      // Step 7 is the section boundary, and carries no board.
      expect(find.byType(BoardView), findsNothing);
    });

    testWidgets('the board sits where a game puts it, against the right edge',
        (tester) async {
      // D194's claim is that the tutorial board is pixel for pixel the one the
      // player will see in a game, and D137 puts that one against the right
      // edge. Without a width the box shrank to the board's own narrow width
      // and the enclosing Column dropped it against the left — which shipped
      // through every other test in this file and was only caught on a device.
      _phone(tester);
      await _openFromHome(tester, await _repository(offered: true));
      final page = tester.getRect(find.byType(Scaffold).last);
      // The rendered cells, not the BoardView box: the box is full width by
      // design and right-aligns its layers inside itself. Cell 3 is the top
      // row of layer 1, which the shear pushes furthest right of anything.
      // Not an exact match: each layer reserves the width the shear needs, so
      // the rightmost cell sits a few pixels inside the box it is aligned in.
      // The regression this guards is gross — before the fix this cell's right
      // edge was at 92 on a 432dp page, because the layers were at the far left.
      final rightmost = tester.getRect(find.byKey(const ValueKey('cell-3')));
      expect(rightmost.right, greaterThan(page.left + page.width * 0.6),
          reason: 'layers against the right edge, not the left');
      expect(rightmost.right, lessThanOrEqualTo(page.right - 16),
          reason: 'and inside the page padding');
    });

    testWidgets('shows the strategy on real positions too', (tester) async {
      _phone(tester);
      await _openFromHome(tester, await _repository(offered: true));
      for (var i = 0; i < 7; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
      const expected = [
        kCentreCells,
        kCornerCells,
        kDoubleThreatCells,
        kBlockingCell,
      ];
      for (var step = 0; step < expected.length; step++) {
        final board = tester.widget<BoardView>(find.byType(BoardView));
        expect(board.highlight, expected[step], reason: 'strategy step $step');
        expect(board.enabled, isFalse);
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
      expect(find.text('That is how they play'), findsOneWidget);
    });

    testWidgets('the strategy half can be skipped, and that still counts as '
        'finishing', (tester) async {
      _phone(tester);
      final repo = await _repository(offered: true);
      await _openFromHome(tester, repo);
      for (var i = 0; i < 6; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
      expect(find.text('That is the whole game'), findsOneWidget);

      await tester.tap(find.text('Finish here'));
      await tester.pumpAndSettle();
      expect(find.text('New game'), findsOneWidget, reason: 'back on home');
      // A player who only wanted the rules has finished what they came for,
      // so they are not asked again (ticket 019).
      expect((await repo.loadSettings()).tutorialCompleted, isTrue);
    });

    testWidgets('offers to finish only at the section boundary',
        (tester) async {
      _phone(tester);
      await _openFromHome(tester, await _repository(offered: true));
      for (var step = 0; step < 12; step++) {
        expect(find.text('Finish here'), step == 6 ? findsOneWidget : findsNothing,
            reason: 'step ${step + 1}');
        if (step < 11) {
          await tester.tap(find.text('Next'));
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('leaving early does not mark it complete', (tester) async {
      _phone(tester);
      final repo = await _repository(offered: true);
      await _openFromHome(tester, repo);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('New game'), findsOneWidget, reason: 'back on home');
      expect((await repo.loadSettings()).tutorialCompleted, isFalse);
    });

    testWidgets('reaching the end marks it complete and survives a restart',
        (tester) async {
      _phone(tester);
      final store = MemoryDocumentStore();
      final repo = await _repository(offered: true, store: store);
      await _openFromHome(tester, repo);
      await _toLastStep(tester);
      expect(find.text('Step 12 of 12'), findsOneWidget);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect((await repo.loadSettings()).tutorialCompleted, isTrue);

      // A second repository over the same bytes: completion has to have
      // reached the document, not merely the object that wrote it. Reading it
      // back off the repository that just saved it would pass either way.
      final reopened = await LocalGameRepository.open(store);
      addTearDown(reopened.dispose);
      expect((await reopened.loadSettings()).tutorialCompleted, isTrue);
      expect((await reopened.loadSettings()).tutorialOffered, isTrue);
    });
  });

  group('accessibility', () {
    testWidgets('each step is a header, a paragraph and one described board',
        (tester) async {
      _phone(tester);
      final handle = tester.ensureSemantics();
      await _openFromHome(tester, await _repository(offered: true));

      // The board is 64 cells; a demonstration of four of them is described
      // in one sentence instead. If the cells were still exposed, the label
      // below would be buried under sixty-four "Layer 1, row 1, ..." nodes.
      expect(find.bySemanticsLabel(RegExp('Layer 1, row 1, column 1')),
          findsNothing);
      expect(
        find.bySemanticsLabel(RegExp(r'four light pieces filling the row')),
        findsOneWidget,
      );
      // The number and the title together: a live region that says only
      // "Step 8 of 12" reports that something changed without saying what.
      expect(find.bySemanticsLabel('Step 1 of 12. The goal'), findsOneWidget);

      final title = tester.getSemantics(find.text('The goal')).flagsCollection;
      expect(title.isHeader, isTrue);
      handle.dispose();
    });

    testWidgets('announces the step it has moved to, not just the number',
        (tester) async {
      _phone(tester);
      final handle = tester.ensureSemantics();
      await _openFromHome(tester, await _repository(offered: true));
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Step 2 of 12. Four layers, one cube'),
          findsOneWidget);
      handle.dispose();
    });

    testWidgets('survives the largest font setting', (tester) async {
      _phone(tester, textScale: 2);
      await _openFromHome(tester, await _repository(offered: true));
      expect(tester.takeException(), isNull);
      expect(find.text('The goal'), findsOneWidget);
    });

    testWidgets('the section boundary survives it too, on the shortest screen',
        (tester) async {
      // The step with the most chrome — progress, board, a skip button and the
      // Back/Next row — on the smallest screen the board is supported at
      // (kMinSupportedHeight) and the largest font setting. If any step
      // overflows, it is this one, and the general test above only sees step 1.
      tester.view.physicalSize = const Size(1080, 2340); // 360x780dp
      tester.view.devicePixelRatio = 3.0;
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await _openFromHome(tester, await _repository(offered: true));
      for (var i = 0; i < 6; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Finish here'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('every tutorial string exists in Dutch', (tester) async {
    _phone(tester);
    final repo = await _repository(offered: true);
    await _pumpApp(tester, repo, locale: const Locale('nl'));
    await tester.tap(find.widgetWithText(TextButton, 'Uitleg'));
    await tester.pumpAndSettle();

    expect(find.text('Het doel'), findsOneWidget);
    expect(find.text('Stap 1 van 12'), findsOneWidget);
    expect(find.text('Verder'), findsOneWidget);
    expect(find.text('The goal'), findsNothing);

    // Including the strategy half, which is where the newest strings are.
    for (var i = 0; i < 9; i++) {
      await tester.tap(find.text('Verder'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Twee dreigingen tegelijk'), findsOneWidget);
  });

  test('the catalogue is twelve steps, ten of which show a board', () {
    final steps = tutorialSteps(AppLocalizationsEn());
    expect(steps.length, 12);
    expect(steps.where((s) => s.hasBoard).length, 10);
    // Exactly one place to stop early, and it is not the last step — a
    // section end on the final step would render "Finish here" above "Done".
    final sectionEnds = [
      for (var i = 0; i < steps.length; i++)
        if (steps[i].endsSection) i
    ];
    expect(sectionEnds, [6]);
    // A step with a board and no description would be silent to a screen
    // reader, which is the failure the whole boardLabel field exists to stop.
    for (final step in steps.where((s) => s.hasBoard)) {
      expect(step.boardLabel, isNotEmpty, reason: step.title);
    }
  });
}
