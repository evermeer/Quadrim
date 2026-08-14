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
  const RatingCard({super.key, required this.summary});

  final HomeSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final record = summary.played == 0
        ? l10n.recordEmpty
        : l10n.recordLine(summary.wins, summary.losses, summary.draws);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Semantics(
          container: true,
          label: '${l10n.computerRatingHeading}: ${summary.computerRating}. '
              '$record. ${l10n.computerRatingNote}',
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.computerRatingHeading,
                    style: theme.textTheme.labelLarge),
                Text(l10n.ratingValue(summary.computerRating),
                    style: theme.textTheme.displaySmall),
                Text(record, style: theme.textTheme.bodyMedium),
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
