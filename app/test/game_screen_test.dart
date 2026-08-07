import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrim/game/board_view.dart';
import 'package:quadrim/main.dart';
import 'package:quadrim_engine/quadrim_engine.dart';

Future<void> _pumpGame(WidgetTester tester) async {
  await tester.pumpWidget(const QuadrimApp());
  await tester.tap(find.text('Pass and play'));
  await tester.pumpAndSettle();
}

Future<void> _tapCell(WidgetTester tester, int index) async {
  final finder = find.byKey(ValueKey('cell-$index'));
  await tester.ensureVisible(finder);
  await tester.tap(finder, warnIfMissed: false);
  await tester.pump();
}

void main() {
  // A phone-sized surface so the whole board lays out.
  TestWidgetsFlutterBinding.ensureInitialized();

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
  // it must hold across the whole supported width range, not just on the
  // device that happened to be tested first.
  for (final width in [kMinSupportedWidth, 390.0, 412.0]) {
    testWidgets('cells stay at or above the audited floor at ${width}dp',
        (tester) async {
      tester.view.physicalSize = Size(width * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await _pumpGame(tester);
      final size = tester.getSize(find.byKey(const ValueKey('cell-0')));
      expect(size.width, greaterThanOrEqualTo(kMinCellSize),
          reason: 'cell width below the audited floor at ${width}dp');
      expect(size.height, greaterThanOrEqualTo(kMinCellSize));
      // Square in hit-test space: the shear must not squash the target.
      expect(size.height, closeTo(size.width, 0.01));
    });
  }

  testWidgets('the whole board fits without scrolling at the narrowest width',
      (tester) async {
    tester.view.physicalSize = Size(kMinSupportedWidth * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await _pumpGame(tester);
    // U1: all four layers and all 64 cells visible at once.
    for (final i in [0, 16, 32, 63]) {
      final r = tester.getRect(find.byKey(ValueKey('cell-$i')));
      expect(r.top, greaterThanOrEqualTo(0.0), reason: 'cell $i above viewport');
      expect(r.bottom, lessThanOrEqualTo(844.0),
          reason: 'cell $i below the fold — board must not need scrolling');
      expect(r.left, greaterThanOrEqualTo(0.0));
      expect(r.right, lessThanOrEqualTo(kMinSupportedWidth));
    }
  });
}
