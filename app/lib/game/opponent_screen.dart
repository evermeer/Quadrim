import 'package:flutter/material.dart';
import 'package:quadrim_engine/quadrim_engine.dart';
import 'package:quadrim_rating/quadrim_rating.dart';

import '../data/documents.dart';
import '../l10n/app_localizations.dart';
import 'opponent_avatar.dart';
import 'opponent_name.dart';

/// The twenty computer opponents, grouped by tier, weakest first.
///
/// Pops the chosen [BotConfig], or null if the player backs out. Returning the
/// configuration rather than an id keeps the caller from having to look it up
/// again, and means this screen is the only place that knows the catalogue is
/// a list.
///
/// Nothing here enumerates opponents itself: the sections come from
/// [opponentCatalogue] in tier order, so adding an opponent or moving one
/// between tiers is a data change and this file does not move (criterion 21).
class OpponentScreen extends StatelessWidget {
  const OpponentScreen({super.key, required this.playerRating});

  /// The player's computer rating, so each opponent can be shown as a fair
  /// match or a mismatch relative to it (criterion 17).
  final int playerRating;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // One pass, grouping by tier. The grouping itself does not care how the
    // catalogue is ordered; what the ordering decides is the order the
    // *sections* come out in, since each is created when its tier is first
    // seen. `catalogue_test.dart` pins the catalogue weakest-first with tiers
    // contiguous, which is what makes that first-appearance order the ladder's
    // order — so a rating change or a new opponent moves this screen without
    // touching it.
    final sections = <BotTier, List<BotConfig>>{};
    for (final bot in opponentCatalogue) {
      sections.putIfAbsent(bot.tier, () => <BotConfig>[]).add(bot);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.chooseOpponent),
        bottom: PreferredSize(
          // Scaled with the text rather than fixed: at the 200% the Android
          // font slider reaches, a constant 28 leaves the strip too short, the
          // AppBar grows upward to fit, and the title's top edge lands off the
          // screen. Nothing errors — neither is a flex, so they simply paint
          // over one another (D188).
          preferredSize: Size.fromHeight(MediaQuery.textScalerOf(context).scale(28)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                l10n.yourRating(playerRating),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            for (final entry in sections.entries) ...[
              _TierHeading(tier: entry.key),
              for (final bot in entry.value)
                _OpponentTile(
                  bot: bot,
                  playerRating: playerRating,
                  onTap: () => Navigator.of(context).pop(bot),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TierHeading extends StatelessWidget {
  const _TierHeading({required this.tier});

  final BotTier tier;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Semantics(
        header: true,
        child: Text(
          tierLabel(l10n, tier),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}

/// One opponent: avatar, name, tier, rating, blurb, and how the pairing sits
/// against the player's own strength.
class _OpponentTile extends StatelessWidget {
  const _OpponentTile({
    required this.bot,
    required this.playerRating,
    required this.onTap,
  });

  final BotConfig bot;
  final int playerRating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final key = botOpponent(bot.id);
    // Belt and braces: `opponent_content_test.dart` already fails if any
    // catalogue member lacks a blurb in either language, so this fallback
    // guards a case that cannot currently arise. It stays because a row with
    // no description is a better failure than a crash on a build where the
    // catalogue has moved ahead of the strings.
    final blurb = botBlurb(l10n, key) ?? '';
    final balance = matchBalance(own: playerRating, opponent: bot.rating);

    return Semantics(
      button: true,
      // Announced as one unit. Four separate nodes would make a screen reader
      // user swipe four times per opponent — eighty swipes to read the list —
      // and the pieces only mean anything together (criterion 22).
      label: l10n.opponentSemantics(
        botName(l10n, key),
        tierLabel(l10n, bot.tier),
        bot.rating,
        _balanceLabel(l10n, balance),
        blurb,
      ),
      child: ExcludeSemantics(
        child: ListTile(
          onTap: onTap,
          leading: OpponentAvatar(id: bot.id, tier: bot.tier),
          title: Row(
            children: [
              Expanded(child: Text(botName(l10n, key))),
              // Tier and rating are rendered from separate fields and shown as
              // separate things, so an opponent whose number is not yet
              // trustworthy can be given a tier alone without touching this
              // file (criterion 22, D179).
              Text(
                l10n.ratingValue(bot.rating),
                style: theme.textTheme.labelLarge,
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (blurb.isNotEmpty) Text(blurb),
              const SizedBox(height: 4),
              _BalanceChip(balance: balance),
            ],
          ),
          isThreeLine: true,
        ),
      ),
    );
  }
}

/// The match-quality cue.
///
/// An icon **and** a word, never a colour alone: the criterion asks that a
/// mismatch be distinguishable from a fair match, and roughly one man in twelve
/// would not see a red-versus-green distinction at all (D185).
class _BalanceChip extends StatelessWidget {
  const _BalanceChip({required this.balance});

  final MatchBalance balance;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final (icon, colour) = switch (balance) {
      MatchBalance.even => (Icons.balance, theme.colorScheme.primary),
      MatchBalance.opponentStronger => (
          Icons.trending_up,
          theme.colorScheme.error,
        ),
      MatchBalance.opponentWeaker => (
          Icons.trending_down,
          theme.colorScheme.outline,
        ),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colour),
        const SizedBox(width: 4),
        Text(
          _balanceLabel(l10n, balance),
          style: theme.textTheme.labelMedium?.copyWith(color: colour),
        ),
      ],
    );
  }
}

String _balanceLabel(AppLocalizations l10n, MatchBalance balance) =>
    switch (balance) {
      MatchBalance.even => l10n.matchEven,
      MatchBalance.opponentStronger => l10n.matchStronger,
      MatchBalance.opponentWeaker => l10n.matchWeaker,
    };
