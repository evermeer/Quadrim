import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrim/data/home_summary.dart';
import 'package:quadrim/home/rating_card.dart';
import 'package:quadrim/l10n/app_localizations.dart';
import 'package:quadrim/theme.dart';

/// Whether the rating and the leaderboard button both survive the font slider.
///
/// **The rating clips rather than ellipsises**, which is why this is measured
/// rather than eyeballed: a `Text` with `maxLines: 1` and no `overflow` in a
/// `Flexible` too narrow for it paints as many glyphs as fit and simply stops.
/// A rating of 2400 does not become "240…", it becomes **240** — a smaller
/// number, confidently displayed, with nothing on screen saying it is wrong.
/// That is worse than an overflow stripe, which at least announces itself.
///
/// So the assertion is on painted width against the width the same string
/// wants: if the box is narrower than the glyphs, a digit has been lost (D394).
void main() {
  /// What [text] needs at [style], unconstrained.
  double intrinsicWidth(String text, TextStyle style, double scale) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.linear(scale),
    )..layout();
    return painter.width;
  }

  Future<void> pump(
    WidgetTester tester, {
    required int rating,
    required double scale,
    required double widthPx,
    bool withButton = true,
  }) async {
    tester.view.physicalSize = Size(widthPx, 2280);
    tester.view.devicePixelRatio = 2.5;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(MaterialApp(
      theme: QuadrimTheme.forest,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: RatingCard(
          summary: HomeSummary(
            wins: 4,
            losses: 1,
            draws: 0,
            computerRating: rating,
            points: 0,
            byOpponent: const [],
          ),
          balance: 0,
          streak: 0,
          series: const [],
          onLeaderboard: withButton ? () {} : null,
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  /// The rating's own box, and what the digits want in it.
  ///
  /// Reads the style off the widget rather than restating `displaySmall`, so a
  /// theme change moves the measurement with it instead of silently comparing
  /// against a size nothing uses.
  ({double painted, double wanted}) ratingFit(
      WidgetTester tester, int rating, double scale) {
    final finder = find.text('$rating');
    final widget = tester.widget<Text>(finder);
    final style = widget.style ?? const TextStyle();
    return (
      painted: tester.getSize(finder).width,
      wanted: intrinsicWidth('$rating', style, scale),
    );
  }

  group('the rating always shows every digit', () {
    // 2400 is the top of the ladder: Quadrim Prime is measured at ~2176 and
    // Oracle at 2323, so four digits is not a hypothetical (CLAUDE.md).
    for (final scale in const [1.0, 1.3, 1.6, 2.0]) {
      testWidgets('a four-digit rating is not clipped at ${scale}x',
          (tester) async {
        await pump(tester, rating: 2400, scale: scale, widthPx: 1080);
        final fit = ratingFit(tester, 2400, scale);
        expect(
          fit.painted,
          greaterThanOrEqualTo(fit.wanted - 0.5),
          reason: 'painted ${fit.painted} < wanted ${fit.wanted}: a digit of '
              '2400 is missing, and what is left reads as a real rating',
        );
      });
    }

    testWidgets('and not on the narrowest supported phone either',
        (tester) async {
      // 320dp at 2.5x device pixel ratio. The smallest screen ticket 021
      // audits, and the one D392 overflowed by 21 pixels.
      await pump(tester, rating: 2400, scale: 2.0, widthPx: 800);
      final fit = ratingFit(tester, 2400, 2.0);
      expect(fit.painted, greaterThanOrEqualTo(fit.wanted - 0.5));
      expect(tester.takeException(), isNull);
    });
  });

  group('the leaderboard label is not ellipsised', () {
    for (final scale in const [1.0, 1.3, 1.6, 2.0]) {
      testWidgets('"Leaderboard" fits whole at ${scale}x', (tester) async {
        await pump(tester, rating: 2400, scale: scale, widthPx: 1080);
        final finder = find.text('Leaderboard');
        final widget = tester.widget<Text>(finder);
        // The button supplies the style through `styleFrom`, so read it off
        // the rendered paragraph rather than off the widget, which carries
        // none of its own.
        final painted = tester.renderObject<RenderParagraph>(finder);
        expect(
          painted.didExceedMaxLines,
          isFalse,
          reason: 'the label ellipsised to "Leaderbo..." at ${scale}x',
        );
        expect(widget.maxLines, 1);
      });
    }
  });

  group('nothing overflows', () {
    for (final scale in const [1.0, 1.3, 1.6, 2.0, 2.5]) {
      testWidgets('at ${scale}x on the narrowest phone', (tester) async {
        await pump(tester, rating: 2400, scale: scale, widthPx: 800);
        expect(tester.takeException(), isNull, reason: '${scale}x');
      });
    }
  });
}
