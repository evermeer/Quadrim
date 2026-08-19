import 'package:flutter/material.dart';
import 'package:quadrim_engine/quadrim_engine.dart';
import 'package:quadrim_progression/quadrim_progression.dart';

import '../data/documents.dart';
import '../design/forest.dart';
import '../game/opponent_name.dart';
import '../l10n/app_localizations.dart';

/// The four quests closest to completion.
///
/// Four rather than fifty-three, because the point of the section is *what to
/// do next* and a list of everything answers a different question. Ranked by
/// percentage complete with ties going to the smaller remainder, which is the
/// package's rule and tested there.
///
/// It shows no reward. The two per-opponent families would have an honest
/// number to show, but the volume and streak families do not until the games
/// that earn them exist, and four tiles where two carry a figure and two carry
/// a blank reads as a bug rather than as a distinction.
class QuestsSection extends StatelessWidget {
  const QuestsSection({
    super.key,
    required this.quests,
    this.capped = false,
  });

  final List<QuestStatus> quests;

  /// True when the daily cap applies to this player — not subscribed and not
  /// inside the free month.
  ///
  /// **Five games in a day exceeds a free cap of three**, so no free player can
  /// complete even the first rung of the volume ladder: it is subscriber-only
  /// by arithmetic rather than by a rule (§7.4). The tile says so, because a
  /// permanently unreachable goal shown without explanation reads as a bug.
  final bool capped;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ParchmentSection(
      heading: l10n.quests,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final status in quests)
            QuestTile(status: status, capped: capped),
        ],
      ),
    );
  }
}

/// One quest: an icon, its name, and a bar whose meaning is also a number.
///
/// The number is not decoration. A bar is a shape, and a shape is unreadable
/// to a screen reader and hard to read at the largest font scale; the pair is
/// what makes the progress available two ways (criterion U-series, ticket 021).
class QuestTile extends StatelessWidget {
  const QuestTile({super.key, required this.status, this.capped = false});

  final QuestStatus status;

  /// See [QuestsSection.capped].
  final bool capped;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final name = questName(l10n, status.quest);
    // Only the volume family is unreachable under the cap. The per-opponent
    // and streak families are all completable on three games a day.
    final unreachable =
        capped && status.quest.family == QuestFamily.gamesInDay;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Semantics(
        container: true,
        // State with progress, not decoration: a bar conveys nothing to a
        // screen reader, so the tile says where it stands in words.
        label: unreachable
            ? '${l10n.questSemantics(name, status.current, status.quest.target)}. '
                '${l10n.questVolumeLocked}'
            : l10n.questSemantics(name, status.current, status.quest.target),
        child: ExcludeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(questIcon(status.quest.family),
                  size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: status.fraction,
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.questProgressValue(
                              status.current, status.quest.target),
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                    if (unreachable) ...[
                      const SizedBox(height: 4),
                      Text(
                        l10n.questVolumeLocked,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: theme.colorScheme.primary),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One icon per family rather than one per quest.
///
/// Fifty-three icons would be fifty-three decisions and the tile already
/// carries the name; what the icon has to do is make the four tiles
/// distinguishable at a glance, and the family is what distinguishes them.
IconData questIcon(QuestFamily family) => switch (family) {
      QuestFamily.firstWin => Icons.emoji_events_outlined,
      QuestFamily.firstWinSecond => Icons.shield_outlined,
      QuestFamily.gamesInDay => Icons.today_outlined,
      QuestFamily.consecutiveDays => Icons.local_fire_department_outlined,
    };

/// A quest's name, through l10n like every other user-facing string.
///
/// Four messages rather than fifty-three: the per-opponent families take the
/// opponent's name as a placeholder and the other two take their number, so a
/// roster change or a re-tuned rung needs no new string.
String questName(AppLocalizations l10n, Quest quest) {
  final index = quest.rosterIndex;
  final name = index == null
      ? ''
      : botName(l10n, botOpponent(opponentCatalogue[index].id));
  return switch (quest.family) {
    QuestFamily.firstWin => l10n.questFirstWin(name),
    QuestFamily.firstWinSecond => l10n.questFirstWinSecond(name),
    QuestFamily.gamesInDay => l10n.questGamesInDay(quest.target),
    QuestFamily.consecutiveDays => l10n.questDaysInRow(quest.target),
  };
}
