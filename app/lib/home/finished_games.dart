import 'package:flutter/material.dart';

import '../data/documents.dart';
import '../l10n/app_localizations.dart';
import 'game_row.dart';

/// One finished game: who it was against, when, how it ended, what it did to
/// the rating, and a way to play them again.
///
/// The challenge button sits **outside** [GameRow] rather than inside it. The
/// row excludes its children's semantics and re-says every fact once in a
/// single label, which is right for facts and wrong for a button — a button
/// swallowed by that exclusion would be invisible to a screen reader and
/// unreachable by keyboard. Outside it, the button is its own node and its own
/// tap target, so tapping it cannot also open the game underneath.
class FinishedGameTile extends StatelessWidget {
  const FinishedGameTile({
    super.key,
    required this.game,
    required this.onTap,
    required this.now,
    this.delta,
    this.onChallenge,
  });

  final GameDocument game;

  /// What this game did to the computer rating, or null if it was not on that
  /// ladder at all.
  final int? delta;

  final VoidCallback onTap;

  /// Starts a new game against the same opponent. Null where there is nobody
  /// to challenge — pass and play, or an opponent this build does not know.
  final VoidCallback? onChallenge;

  /// Local now, injected so the relative date is testable. The row cannot read
  /// a clock for the same reason the streak fold cannot.
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final completedAt = game.completedAt?.toLocal();
    return Row(
      children: [
        Expanded(
          child: GameRow(
            game: game,
            trailing: resultLabel(l10n, game),
            delta: delta,
            subtitle: completedAt == null
                ? null
                : relativeDate(context, completedAt, now),
            onTap: onTap,
          ),
        ),
        if (onChallenge != null)
          IconButton(
            icon: const Icon(Icons.replay),
            tooltip: l10n.challengeAgain,
            onPressed: onChallenge,
          ),
      ],
    );
  }
}

/// `Today`, `Yesterday`, `2 days ago` … `7 days ago`, then the device's own
/// date format.
///
/// Seven days is where relative stops being more useful than absolute: past a
/// week nobody counts, and "23 days ago" is a number the reader has to convert
/// back into a date anyway. Beyond it, [MaterialLocalizations] formats the date
/// the way the device does — which needs no new string and no new dependency,
/// and is already right in every locale Flutter ships.
///
/// Counted in **calendar days**, not in elapsed hours: a game finished at
/// 23:50 last night is "yesterday" at 00:10, and calling it "today" because
/// twenty minutes have passed would be wrong in the way that is hardest to
/// argue with.
String relativeDate(BuildContext context, DateTime when, DateTime now) {
  final l10n = AppLocalizations.of(context)!;
  final days = DateTime(now.year, now.month, now.day)
      .difference(DateTime(when.year, when.month, when.day))
      .inDays;
  if (days <= 0) return l10n.relativeToday;
  if (days == 1) return l10n.relativeYesterday;
  if (days <= 7) return l10n.relativeDaysAgo(days);
  return MaterialLocalizations.of(context).formatShortDate(when);
}
