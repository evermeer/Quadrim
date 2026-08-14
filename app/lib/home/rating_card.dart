import 'package:flutter/material.dart';

import '../data/home_summary.dart';
import '../l10n/app_localizations.dart';

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
  });

  final HomeSummary summary;

  /// Earned minus spent, clamped at zero — not [HomeSummary.points], which is
  /// the earned total and keeps rising as unlocks are bought (spec §8.8).
  final int balance;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final record = summary.played == 0
        ? l10n.recordEmpty
        : l10n.recordLine(summary.wins, summary.losses, summary.draws);
    final points = l10n.pointsValue(balance);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Semantics(
          container: true,
          // One node, said once. The card shows four facts and a screen reader
          // meets them as a single announcement rather than as four stops —
          // and the points are in it, because a number drawn on screen that is
          // never spoken is worse than one that is never drawn (spec §8.13).
          label: '${l10n.computerRatingHeading}: ${summary.computerRating}. '
              '$record. ${l10n.pointsHeading}: $points. '
              '${l10n.computerRatingNote}',
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.computerRatingHeading,
                    style: theme.textTheme.labelLarge),
                Text(l10n.ratingValue(summary.computerRating),
                    style: theme.textTheme.displaySmall),
                Text(record, style: theme.textTheme.bodyMedium),
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
                        style: theme.textTheme.labelLarge),
                    const SizedBox(width: 8),
                    Text(points,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
                const SizedBox(height: 4),
                Text(l10n.computerRatingNote, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
