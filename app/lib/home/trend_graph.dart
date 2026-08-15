import 'package:flutter/material.dart';

import 'package:quadrim_rating/quadrim_rating.dart';

import '../l10n/app_localizations.dart';
import 'game_row.dart' show signedDelta;

/// How many games the trend covers.
const int kTrendGames = 10;

/// Below this many rated games there is no line to draw — **no graph at all**,
/// rather than an empty one. A single point is not a trend and an axis with
/// nothing on it is furniture.
const int kTrendMinimum = 2;

/// The rating over the last ten games: a line, a dot per game, and the signed
/// change stated beside it.
///
/// **The number is not decoration.** Colour here is *information* rather than
/// confirmation — the line's shape is the only other telling, and shape is
/// unavailable to a screen reader and hard to read at a glance. Red against
/// green is also the worst possible pair for the commonest colour vision
/// deficiency, so without the number a red-green colourblind player would
/// learn nothing at all from this element (ticket 035).
class TrendGraph extends StatelessWidget {
  const TrendGraph({super.key, required this.series});

  /// The rating after each ladder game, oldest first. The widget takes the
  /// last [kTrendGames] of it.
  final List<int> series;

  /// Whether there is enough history to draw anything.
  static bool worthDrawing(List<int> series) => series.length >= kTrendMinimum;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final points = pointsOf(series);
    final change = changeIn(series);
    final rising = change >= 0;
    final colour = change == 0
        ? theme.colorScheme.onSurfaceVariant
        : rising
            ? (theme.brightness == Brightness.dark
                ? const Color(0xFF7CD98C)
                : const Color(0xFF2E7D32))
            : theme.colorScheme.error;

    // No semantics of its own. The rating card wraps its whole body in an
    // ExcludeSemantics and says its four facts once in a single label, so a
    // node declared here would be swallowed rather than spoken — the change
    // joins the card's label instead, which is where the rest of the card's
    // facts already are.
    return ExcludeSemantics(
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: SizedBox(
                height: 32,
                child: CustomPaint(
                  painter: _TrendPainter(
                    series: points,
                    colour: colour,
                    track: theme.colorScheme.outlineVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.trendChange(signedDelta(change)),
              style: theme.textTheme.titleSmall
                  ?.copyWith(color: colour, fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }

  static List<int> _window(List<int> series) => series.length <= kTrendGames
      ? series
      : series.sublist(series.length - kTrendGames);

  /// Where the change is measured from: the rating the player held **before**
  /// the window, or the seed when the window reaches back to the start of
  /// their history.
  ///
  /// The seed case is not an edge case, it is every new player. `series` holds
  /// the rating *after* each game, so its first entry already contains the
  /// first game's result; measuring from there silently drops that game from
  /// the total. A player who has won once would be told their last ten games
  /// were worth nothing.
  ///
  /// The same slip applies at exactly ten games, where there is no eleventh
  /// entry to reach back to — which is why the test is `length > kTrendGames`
  /// and not `>=`.
  static int baselineOf(List<int> series) => series.length > kTrendGames
      ? series[series.length - kTrendGames - 1]
      : kSeedRating;

  /// What the line plots: the baseline, then one point per game in the window.
  ///
  /// The baseline is drawn rather than merely subtracted, so the rise the eye
  /// measures off the line is the number printed beside it. Without it the two
  /// disagree by exactly the first game in the window, in the direction that
  /// makes a good run look flat.
  static List<int> pointsOf(List<int> series) =>
      [baselineOf(series), ..._window(series)];

  /// The signed change over the window — what the card announces, and the
  /// number drawn beside the line.
  static int changeIn(List<int> series) => series.last - baselineOf(series);
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.series,
    required this.colour,
    required this.track,
  });

  final List<int> series;
  final Color colour;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final lowest = series.reduce((a, b) => a < b ? a : b);
    final highest = series.reduce((a, b) => a > b ? a : b);
    // A flat run has no range to scale against, so it is drawn down the middle
    // rather than divided by zero.
    final span = highest - lowest;
    const dot = 2.5;
    final usable = size.height - dot * 2;

    Offset at(int i) {
      final x = series.length == 1
          ? size.width / 2
          : dot + (size.width - dot * 2) * i / (series.length - 1);
      final y = span == 0
          ? size.height / 2
          : dot + usable * (1 - (series[i] - lowest) / span);
      return Offset(x, y);
    }

    // The track first, so the line sits on something and a flat run is still
    // visibly a graph rather than a stray mark.
    canvas.drawLine(
      Offset(0, size.height - 0.5),
      Offset(size.width, size.height - 0.5),
      Paint()..color = track..strokeWidth = 1,
    );

    final path = Path();
    for (var i = 0; i < series.length; i++) {
      final point = at(i);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = colour
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final fill = Paint()..color = colour;
    for (var i = 0; i < series.length; i++) {
      canvas.drawCircle(at(i), dot, fill);
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.colour != colour ||
      old.track != track ||
      old.series.length != series.length ||
      !_same(old.series, series);

  static bool _same(List<int> a, List<int> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
