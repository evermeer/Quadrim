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
      QuadrimApp(repository: repo, settings: repo, locale: locale));
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
      expect(find.text('Step 1 of 7'), findsOneWidget);
    });

    testWidgets('advances, goes back, and reports where it is', (tester) async {
      _phone(tester);
      await _openFromHome(tester, await _repository(offered: true));

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Step 2 of 7'), findsOneWidget);
      expect(find.text('Four layers, one cube'), findsOneWidget);

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Step 1 of 7'), findsOneWidget);
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
      // The last step is the summary, and carries no board.
      expect(find.byType(BoardView), findsNothing);
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
      expect(find.text('Step 7 of 7'), findsOneWidget);

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
      expect(find.bySemanticsLabel('Step 1 of 7'), findsOneWidget);

      final title = tester.getSemantics(find.text('The goal')).flagsCollection;
      expect(title.isHeader, isTrue);
      handle.dispose();
    });

    testWidgets('survives the largest font setting', (tester) async {
      _phone(tester, textScale: 2);
      await _openFromHome(tester, await _repository(offered: true));
      expect(tester.takeException(), isNull);
      expect(find.text('The goal'), findsOneWidget);
    });
  });

  testWidgets('every tutorial string exists in Dutch', (tester) async {
    _phone(tester);
    final repo = await _repository(offered: true);
    await _pumpApp(tester, repo, locale: const Locale('nl'));
    await tester.tap(find.widgetWithText(TextButton, 'Uitleg'));
    await tester.pumpAndSettle();

    expect(find.text('Het doel'), findsOneWidget);
    expect(find.text('Stap 1 van 7'), findsOneWidget);
    expect(find.text('Verder'), findsOneWidget);
    expect(find.text('The goal'), findsNothing);
  });

  test('the catalogue is seven steps, six of which show a board', () {
    final steps = tutorialSteps(AppLocalizationsEn());
    expect(steps.length, 7);
    expect(steps.where((s) => s.hasBoard).length, 6);
    // A step with a board and no description would be silent to a screen
    // reader, which is the failure the whole boardLabel field exists to stop.
    for (final step in steps.where((s) => s.hasBoard)) {
      expect(step.boardLabel, isNotEmpty, reason: step.title);
    }
  });
}
