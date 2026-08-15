import 'package:flutter/material.dart';
import 'package:quadrim_engine/quadrim_engine.dart';
import 'package:quadrim_progression/quadrim_progression.dart';
import 'package:quadrim_rating/quadrim_rating.dart';

import '../data/documents.dart';
import '../data/home_summary.dart';
import '../design/art.dart';
import '../design/forest.dart';
import '../game/opponent_name.dart';
import '../l10n/app_localizations.dart';

/// One opponent, in full (spec §8.15).
///
/// Reached by tapping a Your Path tile, and not from opponent selection —
/// that screen sits behind the *new game* button, so the player has already
/// said what they want to do and a page in front of it would tax the commonest
/// path in the app (D288).
///
/// **It stores nothing and derives everything.** The catalogue supplies the
/// facts, [HomeSummary] the record, and the balance comes from the same fold as
/// the main screen. What the page adds is a place to put what is already known,
/// at a size worth looking at.
class OpponentDetail extends StatelessWidget {
  const OpponentDetail({
    super.key,
    required this.bot,
    required this.record,
    required this.playerRating,
    required this.locked,
    required this.price,
    required this.points,
    required this.onStart,
    required this.onUnlock,
  });

  final BotConfig bot;

  /// Null when this opponent has never been faced, which is a different thing
  /// from having been faced and never beaten.
  final OpponentRecord? record;

  final int playerRating;
  final bool locked;

  /// What unlocking costs. Meaningless while [locked] is false, and not read.
  final int price;

  /// The spendable balance, for the progress toward [price].
  final int points;

  /// Starts a game against this opponent. Null while they are locked.
  final VoidCallback? onStart;

  /// Buys them. Null while they are unlocked, or while a purchase is in flight.
  final VoidCallback? onUnlock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final name = botName(l10n, botOpponent(bot.id));
    final played = record?.played ?? 0;
    final starCount = record == null
        ? 0
        : stars(wins: record!.wins, losses: record!.losses);
    final balance = matchBalance(own: playerRating, opponent: bot.rating);

    return ForestScaffold(
      appBar: AppBar(title: Text(name)),
      body: SafeArea(
        child: ParchmentSheet(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
            // The avatar leads, at the largest size it is drawn anywhere.
            // These are twenty characters with names and faces and the roster
            // is the thing the player is working through; a page about one of
            // them that leads with a table is a page about a number.
            // Decorative: the name is said just below it, and a portrait
            // announced as well would say it twice. A locked opponent is drawn
            // as a silhouette rather than dimmed — what has not been bought has
            // not been met, and this is the page where the player decides
            // whether to buy it.
            Center(child: OpponentArt(id: bot.id, size: 200, locked: locked)),
            const SizedBox(height: 16),
            // Name, rating and tier as one announcement: three facts that only
            // mean anything together, and the page title already says the name
            // once, so this is the only other place it is spoken.
            Semantics(
              container: true,
              label: l10n.opponentHeadline(
                  name, bot.rating, tierLabel(l10n, bot.tier)),
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: theme.textTheme.headlineSmall),
                    Text(
                      '${l10n.ratingValue(bot.rating)} · '
                      '${tierLabel(l10n, bot.tier)}',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(botBlurb(l10n, botOpponent(bot.id)) ?? '',
                style: theme.textTheme.bodyLarge),
            const SizedBox(height: 12),
            _Fact(
              icon: switch (balance) {
                MatchBalance.even => Icons.balance,
                MatchBalance.opponentStronger => Icons.trending_up,
                MatchBalance.opponentWeaker => Icons.trending_down,
              },
              text: switch (balance) {
                MatchBalance.even => l10n.matchEven,
                MatchBalance.opponentStronger => l10n.matchStronger,
                MatchBalance.opponentWeaker => l10n.matchWeaker,
              },
            ),
            _Fact(
              icon: Icons.stars_outlined,
              // What a win pays, which is the fact that makes the roster a
              // ladder rather than a list (spec §7.2).
              text: l10n.winPays(winValue(rosterIndexOf(bot.id) ?? 0)),
            ),
            const SizedBox(height: 12),
            if (played == 0)
              Text(l10n.neverPlayed, style: theme.textTheme.bodyMedium)
            else
              Semantics(
                container: true,
                label: '${l10n.opponentRecord(record!.wins, record!.losses, record!.draws, played)}. '
                    '${l10n.starsLabel(starCount)}',
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.opponentRecord(record!.wins, record!.losses,
                            record!.draws, played),
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          for (var i = 0; i < 3; i++)
                            Icon(
                              i < starCount ? Icons.star : Icons.star_border,
                              size: 22,
                              color: theme.colorScheme.primary,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            // Said on the page rather than only in the confirmation. A player
            // deciding whether to spend on Oracle should not have to press
            // Unlock to be told it cannot be beaten when it opens (D181).
            if (bot.usesBook) ...[
              const SizedBox(height: 12),
              _Fact(
                icon: Icons.warning_amber_outlined,
                text: l10n.unlockConfirmBook(name),
              ),
            ],
            const SizedBox(height: 24),
            // One action, never none. A page a player can reach and do nothing
            // on is a dead end, and the locked opponents are exactly the ones
            // they came to look at.
            if (locked) ...[
              Text(l10n.unlockCost(price), style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(l10n.unlockProgress(points, price),
                  style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: points >= price ? onUnlock : null,
                  child: Text(l10n.unlockAction),
                ),
              ),
            ] else
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onStart,
                  child: Text(l10n.playThisOpponent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An icon and a line of text, announced as the text alone — the icon repeats
/// what the words say and a screen reader that met both would hear it twice.
class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(icon, size: 20, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
