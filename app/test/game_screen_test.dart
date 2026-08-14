import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrim/data/document_store.dart';
import 'package:quadrim/data/documents.dart';
import 'package:quadrim/data/local_game_repository.dart';
import 'package:quadrim/game/board_view.dart';
import 'package:quadrim/main.dart';
import 'package:quadrim_engine/quadrim_engine.dart';

/// Pumps the app over a throwaway store and opens the game screen.
///
/// The repository is the real one — it is the only path to stored data
/// (criterion S4), so faking it would test a path the app does not use. Only
/// the *store* is swapped: `testWidgets` runs in a fake-async zone that never
/// completes real file I/O, so the on-disk store is proven separately in
/// repository_test.dart's plain `test` bodies.
Future<LocalGameRepository> _pumpGame(WidgetTester tester) async {
  final repository = await LocalGameRepository.open(MemoryDocumentStore());
  addTearDown(repository.dispose);
  await repository
      .saveSettings(const SettingsDocument(tutorialOffered: true));
  await tester.pumpWidget(
      QuadrimApp(
          repository: repository, settings: repository, unlocks: repository));
  // The main screen's one primary button opens a chooser; ticket 011 replaces
  // the chooser with the opponent list, and this route stays the same.
  await tester.tap(find.text('New game'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Pass and play'));
  await tester.pumpAndSettle();
  return repository;
}

Future<void> _tapCell(WidgetTester tester, int index) async {
  final finder = find.byKey(ValueKey('cell-$index'));
  await tester.tap(finder, warnIfMissed: false);
  // The move round-trips through the repository, so settle rather than pump.
  await tester.pumpAndSettle();
}

void main() {
  // A phone-sized surface so the whole board lays out.
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the board is told to flash the last move of each side, then '
      'the whole winning line', (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await _pumpGame(tester);

    List<int> flashing() =>
        tester.widget<BoardView>(find.byType(BoardView)).flash;

    expect(flashing(), isEmpty, reason: 'nothing has been played yet');

    await _tapCell(tester, 21);
    expect(flashing(), [21], reason: 'only one move exists yet');
    await _tapCell(tester, 32);
    // Both, not just the reply: marking only the newest meant a player's own
    // piece stopped being marked the instant the opponent answered (D206).
    expect(flashing(), [21, 32]);

    // Light completes {0,1,2,3}. Dark's four are scattered on purpose: the
    // obvious fillers 40-43 are themselves a row, and dark wins with them
    // before light gets its fourth piece down.
    for (final move in [0, 47, 1, 53, 2, 58, 3]) {
      await _tapCell(tester, move);
    }
    expect(find.text('Light wins!'), findsOneWidget);
    // Not just the winning move: the whole line, so the player can see what
    // it was that completed.
    expect(flashing().toSet(), {0, 1, 2, 3});
  });

  testWidgets('a full pass-and-play game reaches a win with the line shown',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    await _pumpGame(tester);
    expect(find.text('Light to move'), findsOneWidget);

    // Light takes the first x-axis line (cells 0,1,2,3); dark scatters on a
    // set that forms no line (verified against winningLines below).
    const lightMoves = [0, 1, 2, 3];
    const darkMoves = [21, 22, 26];
    expect(
      winningLines.any((l) => l.every(darkMoves.contains)),
      isFalse,
      reason: 'test fixture: dark cells must not form a line',
    );

    for (var i = 0; i < 4; i++) {
      await _tapCell(tester, lightMoves[i]);
      if (i < 3) {
        expect(find.text('Dark to move'), findsOneWidget,
            reason: 'turn must flip after light moves');
        await _tapCell(tester, darkMoves[i]);
        expect(find.text('Light to move'), findsOneWidget);
      }
    }

    expect(find.text('Light wins!'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);
  });

  testWidgets('tapping an occupied cell does nothing', (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    await _pumpGame(tester);
    await _tapCell(tester, 5);
    expect(find.text('Dark to move'), findsOneWidget);
    await _tapCell(tester, 5); // occupied: must not advance the turn
    expect(find.text('Dark to move'), findsOneWidget);
  });

  testWidgets('a drawn game announces the draw', (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    // Use a known drawn game from the shared corpus rather than inventing one.
    final corpus = jsonDecode(
      File('../packages/quadrim_engine/test/fixtures/corpus.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    final draw = (corpus['games'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((g) => g['outcome'] == 'draw');
    final moves = (draw['moves'] as List).cast<int>();

    await _pumpGame(tester);
    for (final m in moves) {
      await _tapCell(tester, m);
    }
    expect(find.text("It's a draw — the board is full."), findsOneWidget);
  });

  testWidgets('every cell exposes a position-and-contents semantics label',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();

    await _pumpGame(tester);
    // Every cell must carry a position-and-contents label (spec 7.10).
    // getSemantics rather than bySemanticsLabel: the latter cannot see
    // labels merged into a gesture target's node.
    String labelOf(int index) =>
        tester.getSemantics(find.byKey(ValueKey('cell-$index'))).label;
    expect(labelOf(0), 'Layer 1, row 1, column 1, empty');
    expect(labelOf(63), 'Layer 4, row 4, column 4, empty');
    for (var i = 0; i < 64; i++) {
      expect(labelOf(i), matches(r'^Layer [1-4], row [1-4], column [1-4], '));
    }
    await _tapCell(tester, 0);
    expect(labelOf(0), 'Layer 1, row 1, column 1, light piece');
    semantics.dispose();
  });

  // D135: 44dp is geometrically impossible for 64 always-visible cells on a
  // phone. The audited floor is kMinCellSize (WCAG 2.5.8 AA plus margin) and
  // it must hold across the whole supported range, not just on the device
  // that happened to be tested first. Since D137 stacked the layers into one
  // column, height binds before width — so the corners of the supported
  // range are exercised on both axes.
  for (final size in [
    Size(kMinSupportedWidth, kMinSupportedHeight),
    const Size(390, 844),
    const Size(412, 915),
    Size(412, kMinSupportedHeight), // wide but short: height still binds
  ]) {
    testWidgets(
        'cells stay at or above the audited floor at '
        '${size.width}x${size.height}dp', (tester) async {
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await _pumpGame(tester);
      final cell = tester.getSize(find.byKey(const ValueKey('cell-0')));
      expect(cell.width, greaterThanOrEqualTo(kMinCellSize),
          reason: 'cell width below the audited floor at $size');
      expect(cell.height, greaterThanOrEqualTo(kMinCellSize));
      // Square in hit-test space: the shear must not squash the target.
      expect(cell.height, closeTo(cell.width, 0.01));
    });
  }

  testWidgets('the four layers stack vertically against the right edge',
      (tester) async {
    const width = 412.0;
    tester.view.physicalSize = const Size(width * 3, 915 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await _pumpGame(tester);

    // D137: one column, layer 1 through layer 4 top to bottom.
    var previousBottom = 0.0;
    for (final z in [0, 1, 2, 3]) {
      final top = tester.getRect(find.byKey(ValueKey('cell-${z * 16}')));
      expect(top.top, greaterThan(previousBottom),
          reason: 'layer ${z + 1} must sit below layer $z');
      previousBottom = tester
          .getRect(find.byKey(ValueKey('cell-${z * 16 + 15}')))
          .bottom;
    }

    // Right-aligned, leaving the left of the screen free. Measured on the
    // board rather than a cell: getRect transforms the corner points, so a
    // sheared cell's bottom-right lands one shear-step inside the edge.
    final board = tester.getRect(find.byType(BoardView));
    expect(width - board.right, lessThan(12.0),
        reason: 'board must hug the right edge');
    // Four stacked layers fill the height, so the board lands at roughly half
    // the width. The bound that matters is that a usable strip stays free on
    // the left for the move list and scrubber (ticket 012).
    expect(board.left, greaterThan(width * 0.3),
        reason: 'board must leave a usable column free on the left');
  });

  testWidgets('the whole board fits without scrolling at the smallest screen',
      (tester) async {
    tester.view.physicalSize =
        const Size(kMinSupportedWidth, kMinSupportedHeight) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await _pumpGame(tester);
    // U1: all four layers and all 64 cells visible at once.
    for (var i = 0; i < 64; i++) {
      final r = tester.getRect(find.byKey(ValueKey('cell-$i')));
      expect(r.top, greaterThanOrEqualTo(0.0), reason: 'cell $i above viewport');
      expect(r.bottom, lessThanOrEqualTo(kMinSupportedHeight),
          reason: 'cell $i below the fold — board must not need scrolling');
      expect(r.left, greaterThanOrEqualTo(0.0));
      expect(r.right, lessThanOrEqualTo(kMinSupportedWidth));
    }
  });
}
