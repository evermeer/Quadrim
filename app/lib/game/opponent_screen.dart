import 'package:flutter/material.dart';
import 'package:quadrim_engine/quadrim_engine.dart';
import 'package:quadrim_progression/quadrim_progression.dart';
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
class OpponentScreen extends StatefulWidget {
  const OpponentScreen({
    super.key,
    required this.playerRating,
    this.unlocked = const {},
    this.points = 0,
    this.onUnlock,
  });

  /// The player's computer rating, so each opponent can be shown as a fair
  /// match or a mismatch relative to it (criterion 17).
  final int playerRating;

  /// Catalogue ids the player has bought. The free five are not in here - the
  /// rating rule in `isUnlocked` knows about them.
  final Set<String> unlocked;

  /// The spendable balance, shown against each locked opponent's price.
  final int points;

  /// Buys an opponent. Null in flows that cannot purchase, in which case
  /// locked rows still show their price and simply cannot be acted on.
  final Future<void> Function(BotConfig bot, int price)? onUnlock;

  @override
  State<OpponentScreen> createState() => _OpponentScreenState();
}

/// The tier a player of [rating] belongs beside: the tier of the catalogue
/// entry closest to them in strength.
///
/// Deliberately *not* a rating-band lookup. Tier is stored rather than derived
/// precisely so that a recalibration cannot reclassify an opponent
/// ([D179](doc/idea-v1-decisions.md)), and a band table here would reintroduce
/// exactly the coupling that decision removed — it would have to be kept in
/// step with twenty ratings by hand. Asking which opponent is nearest needs no
/// table and stays right by construction (D190).
BotTier tierNearest(int rating) {
  var best = opponentCatalogue.first;
  for (final bot in opponentCatalogue) {
    if ((bot.rating - rating).abs() < (best.rating - rating).abs()) best = bot;
  }
  return best.tier;
}

class _OpponentScreenState extends State<OpponentScreen> {
  late BotTier? _open = tierNearest(widget.playerRating);

  @override
  void didUpdateWidget(OpponentScreen old) {
    super.didUpdateWidget(old);
    // A `late` initialiser runs once, so without this the section stays where
    // the *first* rating put it when the same State is reused with a new one.
    // Today the screen is always pushed fresh and the rating cannot change
    // underneath it; this keeps the widget honest about its own input rather
    // than relying on that (D190).
    if (old.playerRating != widget.playerRating) {
      _open = tierNearest(widget.playerRating);
    }
  }

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
                l10n.yourRating(widget.playerRating),
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
              _TierHeading(
                tier: entry.key,
                count: entry.value.length,
                expanded: entry.key == _open,
                // Tapping the open section closes it, so the list can be
                // collapsed to five lines and scanned as a ladder.
                onTap: () => setState(
                  () => _open = entry.key == _open ? null : entry.key,
                ),
              ),
              if (entry.key == _open)
                for (final bot in entry.value)
                  Builder(builder: (context) {
                    final locked = !isUnlocked(bot.id, widget.unlocked);
                    final next = nextUnlockIndex(widget.unlocked);
                    final index = rosterIndexOf(bot.id);
                    return _OpponentTile(
                      bot: bot,
                      playerRating: widget.playerRating,
                      locked: locked,
                      price: locked && index != null ? unlockCost(index) : null,
                      points: widget.points,
                      // Only the next one in roster order may be bought, so
                      // only it offers the action. The rest show their price,
                      // because hiding the goal is what the ladder exists to
                      // avoid (D229).
                      onUnlock: locked &&
                              index != null &&
                              index == next &&
                              widget.onUnlock != null
                          ? () => widget.onUnlock!(bot, unlockCost(index))
                          : null,
                      // A locked opponent cannot be chosen to play. Tapping the
                      // row would otherwise start a game against somebody the
                      // player has not earned.
                      onTap: locked
                          ? null
                          : () => Navigator.of(context).pop(bot),
                    );
                  }),
            ],
          ],
        ),
      ),
    );
  }
}

/// One accordion header: the tier's name, how many it holds, and a chevron
/// that turns to face the way tapping will move it.
class _TierHeading extends StatelessWidget {
  const _TierHeading({
    required this.tier,
    required this.count,
    required this.expanded,
    required this.onTap,
  });

  final BotTier tier;
  final int count;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Semantics(
      header: true,
      button: true,
      // Announced so a screen reader user knows a collapsed section exists and
      // holds something, rather than meeting five words and no list.
      expanded: expanded,
      label: '${tierLabel(l10n, tier)}, $count',
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    tierLabel(l10n, tier),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(l10n.opponentCount(count),
                    style: theme.textTheme.labelMedium),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(Icons.expand_more,
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
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
    required this.locked,
    required this.price,
    required this.points,
    required this.onUnlock,
    required this.onTap,
  });

  final BotConfig bot;
  final int playerRating;
  final bool locked;

  /// What this opponent costs, or null when it is free.
  final int? price;

  final int points;

  /// Non-null only on the one opponent that may be bought right now.
  final VoidCallback? onUnlock;

  /// Null when the row cannot be chosen - that is, when it is locked.
  final VoidCallback? onTap;

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
      // A locked row says so, and says the price, in the same single label.
      // Grey alone is not a fact a screen reader can read (spec 8.13).
      label: locked && price != null
          ? '${l10n.opponentSemantics(botName(l10n, key), tierLabel(l10n, bot.tier), bot.rating, _balanceLabel(l10n, balance), blurb)} '
              '${l10n.lockedWithPrice(price!, points)}'
          : l10n.opponentSemantics(
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
              if (locked && price != null)
                _LockedRow(price: price!, points: points, onUnlock: onUnlock)
              else
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

/// A locked opponent's price, and - on the next one only - the way to buy it.
///
/// Locked opponents are shown in full rather than hidden. Hiding them would
/// hide the goal, which is the entire motivation for the ladder (spec 11.3).
class _LockedRow extends StatelessWidget {
  const _LockedRow({
    required this.price,
    required this.points,
    required this.onUnlock,
  });

  final int price;
  final int points;
  final VoidCallback? onUnlock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.lock_outline,
            size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            // The price, and the progress toward it - a number, not only a
            // bar, because a bar cannot be read off.
            onUnlock == null
                ? l10n.unlockCost(price)
                : l10n.unlockProgress(points, price),
            style: theme.textTheme.labelMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onUnlock != null) ...[
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: points >= price ? onUnlock : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(l10n.unlockAction),
          ),
        ],
      ],
    );
  }
}
