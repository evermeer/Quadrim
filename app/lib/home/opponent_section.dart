import 'package:flutter/material.dart';

import '../data/home_summary.dart';
import '../game/opponent_name.dart';
import '../l10n/app_localizations.dart';
import 'game_row.dart';
import 'section_widgets.dart';

/// The by-opponent breakdown: every opponent ever played, weakest first.
///
/// **Replaced in ticket 032 by Your Path**, which answers "where am I, and who
/// is next" instead of listing all twenty. It is extracted here rather than
/// deleted because Your Path does not exist yet, and removing this would leave
/// the main screen with a hole for two tickets (D277). `HomeSummary.byOpponent`
/// outlives it — Your Path's tiles need exactly these records.
class OpponentSection extends StatelessWidget {
  const OpponentSection({super.key, required this.records});

  final List<OpponentRecord> records;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading(l10n.byOpponent),
        for (final record in records)
          Builder(builder: (context) {
            final name = botName(l10n, record.opponent);
            final tally = l10n.opponentRecord(
                record.wins, record.losses, record.draws, record.played);
            final rating = record.rating;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Semantics(
                container: true,
                // The bar below carries the rating as a length, which a screen
                // reader cannot read. Saying it here is what keeps the two
                // presentations equivalent rather than one of them decorative.
                label: rating == null
                    ? '$name. $tally'
                    : l10n.opponentRowSemantics(name, rating, tally),
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // The same slot the game rows use, so the two
                          // sections share a left edge for their names rather
                          // than stepping in and out.
                          OpponentAvatarSlot(opponent: record.opponent),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Row(
                              children: [
                                // Flexible, so a long name gives way to the
                                // pill rather than pushing it off the row.
                                Flexible(
                                  child: Text(name,
                                      overflow: TextOverflow.ellipsis),
                                ),
                                if (rating != null) ...[
                                  const SizedBox(width: 6),
                                  RatingPill(rating: rating),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              tally,
                              textAlign: TextAlign.end,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      // Absent rather than empty when the rating is unknown: a
                      // zero-length bar would read as "very weak", and an
                      // unknown number is not a low one — the same reasoning
                      // that sorts these rows last.
                      if (rating != null) ...[
                        const SizedBox(height: 6),
                        RatingBar(rating: rating),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}
