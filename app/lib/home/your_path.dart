import 'package:flutter/material.dart';
import 'package:quadrim_engine/quadrim_engine.dart';
import 'package:quadrim_progression/quadrim_progression.dart';

import '../data/documents.dart';
import '../data/home_summary.dart';
import '../game/opponent_avatar.dart';
import '../game/opponent_name.dart';
import '../l10n/app_localizations.dart';
import 'section_widgets.dart';

/// Where the player is on the ladder, and who is next.
///
/// Replaces the by-opponent breakdown, which listed all twenty weakest-first
/// and answered a question nobody was asking.
///
/// **The middle tile is the next unlock, not the next opponent above the
/// player's rating.** Those diverge exactly where it matters: a player seeded
/// at 800 would get a rating-centred window of Mote, Clover and Bramble —
/// three opponents they already own — while their next unlock sits at 1100
/// outside it, so the price ladder would be invisible on first launch (D262).
/// Where the player stands on the *rating* ladder is still available, in the
/// place a player goes looking for it: the tier accordion in opponent
/// selection opens at their own tier.
class YourPath extends StatelessWidget {
  const YourPath({
    super.key,
    required this.summary,
    required this.unlocked,
    required this.onUnlock,
  });

  final HomeSummary summary;

  /// Catalogue ids the player has bought. The free five are not in here and do
  /// not need to be — [isUnlocked] knows the rating rule.
  final Set<String> unlocked;

  /// Runs the purchase. Null while one is in flight, which is what stops a
  /// double tap buying twice.
  final Future<void> Function(BotConfig bot, int price)? onUnlock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final next = nextUnlockIndex(unlocked);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading(l10n.yourPath),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final index in pathWindow(next))
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _PathTile(
                    bot: opponentCatalogue[index],
                    record: summary.recordFor(opponentCatalogue[index].id),
                    locked: !isUnlocked(opponentCatalogue[index].id, unlocked),
                    isNext: index == next,
                    points: summary.points,
                    price: unlockCost(index),
                    onUnlock: onUnlock,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// One opponent, stacked vertically so three fit across a phone.
///
/// The whole tile is **one accessibility node**: name, rating, record, stars,
/// locked-or-not and price, announced once. An avatar is decorative and a star
/// row means nothing read as six separate images, so the visual parts are
/// excluded and the facts are said in the label (spec §8.13).
class _PathTile extends StatelessWidget {
  const _PathTile({
    required this.bot,
    required this.record,
    required this.locked,
    required this.isNext,
    required this.points,
    required this.price,
    required this.onUnlock,
  });

  final BotConfig bot;
  final OpponentRecord? record;
  final bool locked;
  final bool isNext;
  final int points;
  final int price;
  final Future<void> Function(BotConfig bot, int price)? onUnlock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final name = botName(l10n, botOpponent(bot.id));
    final played = record?.played ?? 0;
    final starCount = record == null
        ? 0
        : stars(wins: record!.wins, losses: record!.losses);

    // What the tile says about itself, spoken. Locked tiles lead with the
    // price, because that is the fact the section exists to deliver.
    final state = locked
        ? l10n.lockedWithPrice(price, points)
        : played == 0
            ? l10n.neverPlayed
            : '${l10n.opponentRecord(record!.wins, record!.losses, record!.draws, played)}. '
                '${l10n.starsLabel(starCount)}';

    return Semantics(
      container: true,
      label: l10n.pathTileSemantics(name, bot.rating, state),
      child: ExcludeSemantics(
        child: Card(
          margin: EdgeInsets.zero,
          color: isNext ? theme.colorScheme.primaryContainer : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Full tile width, so the avatar is the thing the eye lands on
                // and the ladder reads as a progression of faces.
                LayoutBuilder(
                  builder: (context, constraints) => Opacity(
                    opacity: locked ? 0.45 : 1,
                    child: OpponentAvatar(
                      id: bot.id,
                      tier: bot.tier,
                      size: constraints.maxWidth,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge),
                Text(l10n.ratingValue(bot.rating),
                    style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                if (locked)
                  _LockedFooter(
                    price: price,
                    points: points,
                    isNext: isNext,
                    onUnlock:
                        onUnlock == null ? null : () => onUnlock!(bot, price),
                  )
                else
                  _PlayedFooter(record: record, starCount: starCount),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayedFooter extends StatelessWidget {
  const _PlayedFooter({required this.record, required this.starCount});

  final OpponentRecord? record;

  /// Named to avoid shadowing the package's `stars()` inside this class.
  final int starCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    // No star row at all rather than three empty stars: unearned and failed
    // must not look the same (spec §11.3, U14).
    if (record == null || record!.played == 0) {
      return Text(l10n.neverPlayed,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: theme.textTheme.bodySmall);
    }
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 3; i++)
              Icon(i < starCount ? Icons.star : Icons.star_border,
                  size: 14, color: theme.colorScheme.primary),
          ],
        ),
        Text(
          l10n.opponentRecord(
              record!.wins, record!.losses, record!.draws, record!.played),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// A locked tile's price, and — on the next one only — the way to buy it.
///
/// Locked opponents appear **in full**, greyed, with their price and progress.
/// Hiding them would hide the goal, which is the entire motivation for the
/// ladder.
class _LockedFooter extends StatelessWidget {
  const _LockedFooter({
    required this.price,
    required this.points,
    required this.isNext,
    required this.onUnlock,
  });

  final int price;
  final int points;
  final bool isNext;
  final VoidCallback? onUnlock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final affordable = points >= price;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline,
                size: 12, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 2),
            Flexible(
              child: Text(l10n.unlockCost(price),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall),
            ),
          ],
        ),
        // Progress toward the price, and the numbers as well as the bar: a bar
        // is comparative and cannot be read off (spec §11.3, U16).
        if (isNext) ...[
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: price == 0 ? 1 : (points / price).clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(l10n.unlockProgress(points, price),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall),
          const SizedBox(height: 4),
          FilledButton.tonal(
            onPressed: affordable ? onUnlock : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(l10n.unlockAction,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ],
    );
  }
}
