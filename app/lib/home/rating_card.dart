import 'package:flutter/material.dart';

import '../data/home_summary.dart';
import '../design/art.dart';
import '../design/forest.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import 'game_row.dart' show signedDelta;
import 'trend_graph.dart';

/// The computer rating and the record that produced it, in a card of its own.
///
/// Its own card because a second rating — against people — arrives at 0.3b,
/// and the two must never read as one number (criterion 21). A labelled card
/// takes a sibling; a bare number in a row of statistics does not.
///
/// The record sits inside the card rather than under a heading of its own: it
/// is the same fold over the same games that produced the number above it, and
/// a "Your record" heading over a single line was a heading for nothing (D192).
class RatingCard extends StatelessWidget {
  const RatingCard({
    super.key,
    required this.summary,
    required this.balance,
    required this.streak,
    required this.series,
  });

  final HomeSummary summary;

  /// Earned minus spent, clamped at zero — not [HomeSummary.points], which is
  /// the earned total and keeps rising as unlocks are bought (spec §8.8).
  final int balance;

  /// Consecutive local days with a finished computer game, as of now.
  ///
  /// Passed in rather than read from [summary] because it is the one fold that
  /// needs a calendar, and the calendar is injected all the way down (ticket
  /// 034).
  final int streak;

  /// The rating after each ladder game, oldest first. Below two entries no
  /// graph is drawn at all — not an empty one (ticket 035).
  final List<int> series;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final record = summary.played == 0
        ? l10n.recordEmpty
        : l10n.recordLine(summary.wins, summary.losses, summary.draws);
    final points = l10n.pointsValue(balance);
    final days = l10n.streakValue(streak);
    final trend = TrendGraph.worthDrawing(series)
        ? l10n.trendSemantics(signedDelta(TrendGraph.changeIn(series)))
        : null;
    return DarkPanel(
      child: Semantics(
          container: true,
          // One node, said once. The card shows four facts and a screen reader
          // meets them as a single announcement rather than as four stops —
          // and the points are in it, because a number drawn on screen that is
          // never spoken is worse than one that is never drawn (spec §8.13).
          label: '${l10n.computerRatingHeading}: ${summary.computerRating}. '
              '$record. ${l10n.pointsHeading}: $points. '
              '${l10n.streakHeading}: $days. '
              // A line is a shape, and a shape says nothing out loud. The
              // change in words is the only reading of the graph that works
              // without sight — and the same number the sighted reader sees
              // beside it, so neither is told something the other is not.
              '${trend == null ? '' : '$trend '}'
              '${l10n.computerRatingHeading}',
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                // The heading, the number and the record on the left; the cube
                // on the right, as in the mockup. The cube's edges are faded by
                // `artgen` so it sits in the panel without a seam — it is the
                // only picture in the app that has no border of its own.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.computerRatingHeading,
                              style: theme.textTheme.labelLarge
                                  ?.copyWith(color: QuadrimPalette.creamSoft)),
                          Text(l10n.ratingValue(summary.computerRating),
                              style: theme.textTheme.displaySmall
                                  ?.copyWith(color: QuadrimPalette.cream)),
                          // Explicitly cream. `bodyMedium` carries the ink
                          // colour meant for parchment, and this panel is not
                          // parchment (D296).
                          Text(record,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: QuadrimPalette.cream)),
                        ],
                      ),
                    ),
                    // Decoration yields to text. The cube costs 96dp of width
                    // at every font scale, and at the 200% the Android slider
                    // reaches that is what pushes "Against the computer" onto
                    // three lines and the card past the height of the screen —
                    // taking Your Path off a lazily built sliver list with it.
                    if (MediaQuery.textScalerOf(context).scale(16) <= 22)
                      Image.asset(Art.cube,
                          width: 96,
                          height: 96,
                          filterQuality: FilterQuality.medium),
                  ],
                ),
                if (TrendGraph.worthDrawing(series)) ...[
                  const SizedBox(height: 8),
                  Text(l10n.trendHeading,
                      style: theme.textTheme.labelLarge
                          ?.copyWith(color: QuadrimPalette.creamSoft)),
                  const SizedBox(height: 4),
                  TrendGraph(series: series),
                ],
                const SizedBox(height: 8),
                // Its own labelled line rather than a fourth fact on the
                // record row: points are spendable and the rating is not, and
                // §7.1 keeps the two apart on purpose — a rating you could
                // spend would be a score, and a score people spend is a score
                // people farm.
                Row(
                  children: [
                    // The gap is layout, not a trailing space inside the
                    // string. A space there would have to be translated, and
                    // interpolating a localised value into a quoted literal
                    // reads to the build gate's grep exactly like a hardcoded
                    // one — correctly, since it cannot tell the two apart.
                    Text(l10n.pointsHeading,
                        style: theme.textTheme.labelLarge
                            ?.copyWith(color: QuadrimPalette.creamSoft)),
                    const SizedBox(width: 8),
                    // Gold, not `colorScheme.primary`: primary is the deep
                    // bronze that reads on parchment, and on this panel it is
                    // very nearly the background.
                    // Flexible, because the balance is now ten digits at the
                    // top of the ladder and was six. The doubling is per rung,
                    // so eleven new rungs multiplied it by two thousand
                    // (D333) — and at a 2x font scale a balance the width of
                    // this panel overflowed the row by 43 pixels rather than
                    // shrinking. The number is the fact here, so it shrinks to
                    // fit rather than ellipsising away its own leading digits.
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(points,
                            maxLines: 1,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: QuadrimPalette.gold,
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Beside the points rather than under a heading of its own:
                // it is a third fact about the same fold, and a card with
                // three headings would be a list.
                Row(
                  children: [
                    const Icon(Icons.local_fire_department_outlined,
                        size: 18, color: QuadrimPalette.gold),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(days,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: QuadrimPalette.cream))),
                  ],
                ),
                // The "on this device only" note is gone from this panel. It
                // is still said where it is actually needed — the end-of-game
                // result, where a rating change has just happened and the
                // question "does this go anywhere?" is live.
              ],
            ),
          ),
        ),
    );
  }
}
