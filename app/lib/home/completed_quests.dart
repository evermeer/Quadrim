import 'package:flutter/material.dart';
import 'package:quadrim_progression/quadrim_progression.dart';

import '../design/forest.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import 'quests_section.dart' show questIcon, questName;

/// The four quests finished most recently.
///
/// The mirror of [QuestsSection], and deliberately a second panel rather than a
/// second tab or a filter on the first: "what should I do next" and "what have I
/// just done" are different questions, and answering them in one list means
/// answering neither — the closest-to-completion ranking has no room for
/// finished work, because a finished thing is not close to finishing.
///
/// **Absent until there is something in it.** A heading over an empty list is a
/// heading for nothing, and on a fresh install it would push the sections that
/// do have content off the first screen.
///
/// Nothing here is stored. `achievedAt` comes from the game that completed the
/// quest, which the fold already had to identify in order to price it.
class CompletedQuestsSection extends StatelessWidget {
  const CompletedQuestsSection({super.key, required this.quests});

  final List<QuestStatus> quests;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ParchmentSection(
      heading: l10n.questsCompleted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final status in quests) _CompletedTile(status: status),
        ],
      ),
    );
  }
}

/// One finished quest: a tick, its name, and what it paid.
///
/// The award is the point of the row. A quest the player has already finished
/// is not asking for anything, so the only thing left to say about it is what
/// it was worth — and it is the one number the closest-to-completion section
/// deliberately cannot show, because until a quest fires there is no honest
/// figure for the volume and streak families (spec §7.4).
class _CompletedTile extends StatelessWidget {
  const _CompletedTile({required this.status});

  final QuestStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final name = questName(l10n, status.quest);
    final award = l10n.questAwardValue(status.award);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Semantics(
        container: true,
        // One node, both facts. The tick is a shape and says nothing; the
        // heading above already establishes that everything here is done, so
        // the label is the name and the payment.
        label: '$name. $award',
        child: ExcludeSemantics(
          child: Row(
            children: [
              Icon(questIcon(status.quest.family),
                  size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(child: Text(name, style: theme.textTheme.bodyMedium)),
              const SizedBox(width: 8),
              Text(
                award,
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: QuadrimPalette.goldDeep),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
