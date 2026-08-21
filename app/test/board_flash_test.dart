import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrim/game/board_view.dart';
import 'package:quadrim/l10n/app_localizations.dart';
import 'package:quadrim_engine/quadrim_engine.dart';

Widget _host(
  GameState state, {
  List<int> flash = const [],
  bool reduceMotion = false,
}) =>
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: BoardView(
            state: state,
            enabled: false,
            onCellTap: (_) {},
            flash: flash,
          ),
        ),
      ),
    );

/// The gradient a piece is painted with.
///
/// The cell's own `Container` comes first in tree order and the piece's
/// second, so the piece is the last one under that cell.
List<Color> _piece(WidgetTester tester, int cell) {
  final containers = tester.widgetList<Container>(
    find.descendant(
      of: find.byKey(ValueKey('cell-$cell')),
      matching: find.byType(Container),
    ),
  );
  final decoration = containers.last.decoration! as BoxDecoration;
  return (decoration.gradient! as RadialGradient).colors;
}

void main() {
  group('flashStrength', () {
    test('starts full, ends at nothing, and stays in range', () {
      // Full at once: the move has to be marked the instant it lands, not
      // half a pulse later.
      expect(flashStrength(0), 1);
      expect(flashStrength(1), 0);
      expect(flashStrength(2), 0);
      for (var i = 0; i <= 100; i++) {
        final v = flashStrength(i / 100);
        expect(v, inInclusiveRange(0, 1), reason: 't = ${i / 100}');
      }
    });

    test('fades rather than being cut off mid-pulse', () {
      // The envelope has to have taken it most of the way down before the
      // controller stops, or the piece snaps from bright green to grey.
      expect(flashStrength(0.95), lessThan(0.2));
    });

    test('pulses well under the three-per-second seizure limit', () {
      // Counted rather than asserted from the constant: peaks in the sampled
      // curve, converted to flashes per second over the real duration.
      var peaks = 0;
      double at(int i) => flashStrength(i / 1000);
      for (var i = 1; i < 1000; i++) {
        if (at(i) > at(i - 1) && at(i) >= at(i + 1)) peaks++;
      }
      final perSecond = peaks / (kFlashDuration.inMilliseconds / 1000);
      expect(perSecond, lessThan(3.0), reason: 'WCAG 2.3.1');
      expect(peaks, greaterThan(0), reason: 'it should actually pulse');
    });
  });

  group('flashCells', () {
    test('nothing on an empty board', () {
      expect(flashCells(GameState.initial()), isEmpty);
    });

    test('the last move of each side, while the game is running', () {
      // Both, not just the most recent. Turns alternate, so the last two are
      // one apiece — and a player whose own piece stopped being marked the
      // instant the opponent answered never saw their own move flash (D206).
      expect(flashCells(GameState.fromMoves([21, 22, 26])), [22, 26]);
      expect(flashCells(GameState.fromMoves([21, 22, 26, 42])), [26, 42]);
    });

    test('one move is all there is to flash after the opening', () {
      expect(flashCells(GameState.fromMoves([21])), [21]);
    });

    test('the whole line once one is completed', () {
      // Light takes {0,1,2,3}; the dark cells form no line.
      final state = GameState.fromMoves([0, 21, 1, 22, 2, 26, 3]);
      expect(outcome(state), isA<Win>());
      expect(flashCells(state).toSet(), {0, 1, 2, 3});
    });
  });

  group('a flashing piece', () {
    testWidgets('is green at the start and back to normal at the end',
        (tester) async {
      // Light holds 0 and 2, dark holds 1. Only 0 flashes, so 2 is the same
      // colour of piece left alone — the comparison is against the board's own
      // resting palette rather than against colours copied into this test.
      final state = GameState.fromMoves([0, 1, 2]);
      await tester.pumpWidget(_host(state, flash: const [0]));

      final flashing = _piece(tester, 0);
      final resting = _piece(tester, 2);
      expect(flashing, isNot(resting), reason: 'at the start of the flash');

      // Green, not merely different: the middle stop carries the colour.
      final mid = flashing[1];
      expect(mid.g, greaterThan(mid.r));
      expect(mid.g, greaterThan(mid.b));

      await tester.pump(kFlashDuration);
      expect(_piece(tester, 0), resting, reason: 'once the flash is over');
    });

    testWidgets('keeps light and dark told apart by lightness', (tester) async {
      // D124: the two sides differ in lightness, never in hue, so that the
      // distinction survives every colour vision deficiency. Going green must
      // not quietly turn that into a hue distinction while both are lit.
      final state = GameState.fromMoves([0, 1]);
      await tester.pumpWidget(_host(state, flash: const [0, 1]));

      final light = _piece(tester, 0)[1];
      final dark = _piece(tester, 1)[1];
      expect(light.g, greaterThan(light.r), reason: 'light piece is green');
      expect(dark.g, greaterThan(dark.r), reason: 'dark piece is green');
      expect(light.computeLuminance(),
          greaterThan(dark.computeLuminance() + 0.2));
    });

    testWidgets('is far enough from its own resting colour to be seen',
        (tester) async {
      // The first version failed here rather than in the test above: both
      // pieces went green, but the dark one landed almost exactly as dark as
      // an untouched dark piece and the light one almost exactly as light, so
      // on a phone neither read as a flash (D207). What the eye picks up is
      // the change against the piece's own resting state — so that gap is
      // what is pinned, not the greenness.
      // Light holds 0 and 2, dark holds 1 and 3; 0 and 1 flash, 2 and 3 rest.
      final state = GameState.fromMoves([0, 1, 2, 3]);
      await tester.pumpWidget(_host(state, flash: const [0, 1]));

      double lumaOf(int cell) => _piece(tester, cell)[1].computeLuminance();

      // The light piece goes *darker*, the dark piece *lighter* — each away
      // from where it sits at rest, which is the only direction with room.
      expect(lumaOf(0), lessThan(lumaOf(2) - 0.15),
          reason: 'a flashing light piece must be visibly darker than a '
              'resting one');
      expect(lumaOf(1), greaterThan(lumaOf(3) + 0.10),
          reason: 'a flashing dark piece must be visibly lighter than a '
              'resting one');
    });

    testWidgets('restarts when a different cell is played', (tester) async {
      final first = GameState.fromMoves([0, 1, 2]);
      await tester.pumpWidget(_host(first, flash: const [0]));
      await tester.pump(kFlashDuration);
      expect(_piece(tester, 0), _piece(tester, 2), reason: 'flash finished');

      // A new move arrives: the controller has to run again, not stay done.
      await tester.pumpWidget(_host(first, flash: const [2]));
      await tester.pump();
      expect(_piece(tester, 2), isNot(_piece(tester, 0)));
    });

    testWidgets('does not restart when the board rebuilds for another reason',
        (tester) async {
      final state = GameState.fromMoves([0, 1, 2]);
      await tester.pumpWidget(_host(state, flash: const [0]));
      await tester.pump(kFlashDuration);

      // Same flash list, new list instance — a reference comparison would
      // restart here and the piece would pulse on every unrelated rebuild.
      await tester.pumpWidget(_host(state, flash: [0]));
      await tester.pump();
      expect(_piece(tester, 0), _piece(tester, 2));
    });

    testWidgets('holds steady instead of pulsing when motion is reduced',
        (tester) async {
      final state = GameState.fromMoves([0, 1, 2]);
      await tester.pumpWidget(
          _host(state, flash: const [0], reduceMotion: true));

      final resting = _piece(tester, 2);
      final atStart = _piece(tester, 0);
      expect(atStart, isNot(resting));

      // Mid-flash it is exactly as green as it was at the start: the cell is
      // still marked, but nothing on screen is moving.
      await tester.pump(kFlashDuration ~/ 2);
      expect(_piece(tester, 0), atStart);

      await tester.pump(kFlashDuration);
      expect(_piece(tester, 0), resting);
    });

    testWidgets('leaves an empty cell alone', (tester) async {
      // flashCells never names one, but a board asked to flash an empty cell
      // should do nothing rather than throw looking for a piece.
      await tester.pumpWidget(_host(GameState.initial(), flash: const [0]));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('cell-0')),
          matching: find.byType(Container),
        ),
        findsOneWidget,
        reason: 'the cell, and no piece inside it',
      );
    });
  });

  group('the winning line', () {
    /// Light takes {0,1,2,3}; the dark cells form no line.
    GameState won() => GameState.fromMoves([0, 21, 1, 22, 2, 26, 3]);

    test('winPulseStrength ends held at full brightness, not at nothing', () {
      // Unlike flashStrength, which fades out. The hold *is* the steady state,
      // and cos is 1 at both ends of every cycle, so the last pulse runs into
      // it without a seam.
      expect(winPulseStrength(0), closeTo(1, 1e-9));
      expect(winPulseStrength(1), 1);
      expect(winPulseStrength(2), 1, reason: 'past the end it stays lit');
      expect(winPulseStrength(0.5 / kWinPulses), closeTo(0, 1e-9));
      for (var i = 0; i <= 200; i++) {
        expect(winPulseStrength(i / 100), inInclusiveRange(0, 1));
      }
    });

    test('pulses well under the three-per-second seizure limit', () {
      // WCAG 2.3.1 draws the line at three flashes per second (D203). Thirty
      // cycles over thirty seconds is 1 Hz, the same rate as a played piece.
      final hz = kWinPulses / kWinPulseDuration.inSeconds;
      expect(hz, lessThan(3));
      expect(hz, closeTo(1, 1e-9));
    });

    testWidgets('still pulsing long after a played piece has stopped',
        (tester) async {
      final state = won();
      await tester.pumpWidget(_host(state, flash: flashCells(state)));

      final resting = _piece(tester, 26);
      expect(_piece(tester, 0), isNot(resting), reason: 'not lit at the start');

      // Past the point a played piece has faded to nothing, and still moving.
      await tester.pump(kFlashDuration + const Duration(seconds: 5));
      final bright = _piece(tester, 0);
      await tester.pump(const Duration(milliseconds: 500));
      final dim = _piece(tester, 0);

      expect(bright, isNot(dim), reason: 'the line stopped moving too early');
      expect([bright, dim], isNot(contains(resting)),
          reason: 'the line went back to its resting colour');
    });

    testWidgets('settles into a steady light rather than going out',
        (tester) async {
      final state = won();
      await tester.pumpWidget(_host(state, flash: flashCells(state)));
      final resting = _piece(tester, 26);

      await tester.pump(kWinPulseDuration);
      final held = _piece(tester, 0);
      expect(held, isNot(resting), reason: 'the winning line went out');

      // Still there, still not moving — an hour later there is nothing to
      // repaint and the answer is still on screen.
      await tester.pump(const Duration(milliseconds: 500));
      expect(_piece(tester, 0), held);
      await tester.pump(kWinPulseDuration * 10);
      expect(_piece(tester, 0), held);
    });

    testWidgets('goes straight to the steady light when motion is reduced',
        (tester) async {
      final state = won();
      await tester.pumpWidget(
          _host(state, flash: flashCells(state), reduceMotion: true));

      final resting = _piece(tester, 26);
      final lit = _piece(tester, 0);
      expect(lit, isNot(resting));

      // Marked from the first frame and never moving, which is the same place
      // the pulse arrives at — reduce motion skips the journey, not the answer.
      await tester.pump(const Duration(milliseconds: 500));
      expect(_piece(tester, 0), lit);
      await tester.pump(kWinPulseDuration * 2);
      expect(_piece(tester, 0), lit);
    });
  });

  testWidgets('a played piece stops early when the next move lands',
      (tester) async {
    // Four moves in, so cells 2 and 3 are lit and 0 and 1 are already at rest.
    // Cell 0 is the baseline: light, like cell 2, and not flashing. Taking it
    // from a cell that is itself flashing is the trap this test fell into.
    var state = GameState.fromMoves([0, 1, 2, 3]);
    await tester.pumpWidget(_host(state, flash: flashCells(state)));
    final resting = _piece(tester, 0);
    expect(_piece(tester, 2), isNot(resting), reason: 'cell 2 should be lit');

    // A quarter of the way through cell 2's ten seconds, light plays again.
    // `flashCells` keeps only the last move of each side, so cell 2 drops out
    // and stops immediately rather than serving out its remaining seconds.
    await tester.pump(kFlashDuration ~/ 4);
    state = GameState.fromMoves([0, 1, 2, 3, 4]);
    await tester.pumpWidget(_host(state, flash: flashCells(state)));
    await tester.pump();

    expect(flashCells(state), isNot(contains(2)));
    expect(_piece(tester, 2), resting,
        reason: 'the superseded move kept flashing');
  });
}
