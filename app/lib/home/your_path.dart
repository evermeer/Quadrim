import 'package:flutter/material.dart';
import 'package:quadrim_engine/quadrim_engine.dart';
import 'package:quadrim_progression/quadrim_progression.dart';

import '../data/documents.dart';
import '../data/home_summary.dart';
import '../design/art.dart';
import '../design/forest.dart';
import '../game/opponent_name.dart';
import '../l10n/app_localizations.dart';

/// Where the player is on the ladder, and who is next.
///
/// Replaces the by-opponent breakdown, which listed all twenty weakest-first
/// and answered a question nobody was asking.
///
/// **A scrollable row over the whole roster, resting on the rating ladder.**
/// Three tiles are visible; the row starts scrolled so the middle one is the
/// lowest-rated opponent rated *strictly above* the player's rating, and the
/// player can scroll left through everyone weaker and right through everyone
/// stronger.
///
/// This reverses D262, which centred a **fixed** window on the next unlock, and
/// the reversal is about the fixedness rather than the ladder (D287). With
/// three tiles and nothing beyond them, whatever the window is centred on is
/// the only thing that exists, so centring on rating really did hide the price
/// ladder on first launch. A scrollable row does not have that property: the
/// unlock ladder is one swipe right, from every point on the roster rather than
/// only where the two ladders happen to coincide.

class YourPath extends StatefulWidget {
  const YourPath({
    super.key,
    required this.summary,
    required this.balance,
    required this.unlocked,
    required this.onUnlock,
    required this.onOpen,
  });

  final HomeSummary summary;

  /// Earned minus spent, clamped at zero — **not** [HomeSummary.points], which
  /// is the earned total and keeps rising as unlocks are bought (spec §8.8).
  ///
  /// This section read `summary.points` until it was reported from a device:
  /// a player with 256 earned, 192 of it already spent on Willow and Vireo, and
  /// 64 left was shown "256 of 256" toward a 256-point unlock — a full bar and
  /// a button that did nothing. Every other surface took the balance; this one
  /// was never handed it (D316).
  final int balance;

  /// Catalogue ids the player has bought. The free five are not in here and do
  /// not need to be — [isUnlocked] knows the rating rule.
  final Set<String> unlocked;

  /// Runs the purchase. Null while one is in flight, which is what stops a
  /// double tap buying twice.
  final Future<void> Function(BotConfig bot, int price)? onUnlock;

  /// Opens one opponent's detail page.
  final void Function(BotConfig bot) onOpen;

  @override
  State<YourPath> createState() => _YourPathState();
}

/// How many tiles are on screen at once. Three is what fits a phone with an
/// avatar big enough to be a face rather than a bullet.
const int _kVisibleTiles = 3;
const double _kGap = 8;

/// Everything between the screen edge and the scrolling row, per side. It has
/// to match what actually surrounds this widget, because the tile width is
/// derived from the screen width rather than measured: `home_screen.dart`'s
/// SliverPadding (16), the parchment card's border (1.5) and the
/// `ParchmentSection` padding this widget asks for (8).
const double _kSectionInset = 16 + 1.5 + 8;

/// The tile card's own horizontal padding, subtracted to get the avatar's
/// width. Passed down rather than measured, because a `LayoutBuilder` inside
/// the row would break the intrinsic-height pass that sizes it.
const double _kCardPadding = 6;

class _YourPathState extends State<YourPath> {
  ScrollController? _controller;

  /// The index the row was last rested on, so a rating change moves it and a
  /// rebuild for any other reason does not. Without this the row would snap
  /// back to the resting tile every time a game finished elsewhere on the
  /// screen, undoing whatever the player had scrolled to.
  int _restedOn = -1;
  double _step = 0;

  double _offsetFor(int index, double width) {
    // The resting tile is the middle of three, so the row starts one tile
    // before it.
    final maxOffset = _step * opponentCatalogue.length - width;
    final wanted = (index - 1) * _step;
    return wanted.clamp(0, maxOffset < 0 ? 0 : maxOffset).toDouble();
  }

  void _settle(double width) {
    final resting = restingIndex(widget.summary.computerRating);
    if (_controller != null && resting == _restedOn) return;
    _restedOn = resting;
    final offset = _offsetFor(resting, width);
    if (_controller == null) {
      _controller = ScrollController(initialScrollOffset: offset);
      return;
    }
    // A rating change moves the row, after the frame that reported it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _controller!.hasClients) {
        _controller!.animateTo(offset,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final next = nextUnlockIndex(widget.unlocked);
    // The carved sign carries the heading, written on it by the app rather
    // than painted into it, so it reads "Jouw pad" in Dutch (D297). It hangs
    // off the card's top-left corner, which is what makes it read as a sign
    // nailed to the panel rather than a picture inside it.
    return ParchmentSection(
      heading: l10n.yourPath,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Builder(
          builder: (context) {
            // The width comes from the screen rather than from a LayoutBuilder:
            // a LayoutBuilder cannot report intrinsic dimensions, and the row
            // below is sized by the intrinsic height of its tallest tile.
            final width =
                MediaQuery.sizeOf(context).width - _kSectionInset * 2;
            final tile = (width - _kGap * (_kVisibleTiles - 1)) / _kVisibleTiles;
            _step = tile + _kGap;
            _settle(width);
            // Sized by the tallest tile rather than by a number. Two guesses at
            // a fixed height were both wrong — 18 pixels short at the largest
            // font scale, then 28 — because the avatar is sized by the tile and
            // does not grow with the font while everything under it does.
            // `IntrinsicHeight` measures instead of predicting.
            //
            // Eager rather than lazy, and that is affordable here: the roster is
            // exactly twenty and cannot grow without a code change, so this is a
            // bounded list, unlike the finished-games list beneath it.
            return SingleChildScrollView(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              // Lands on a tile boundary, so the row always shows three whole
              // faces rather than two and two halves.
              physics: _SnapToTile(_step),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var index = 0;
                        index < opponentCatalogue.length;
                        index++)
                      SizedBox(
                        width: _step,
                        child: Padding(
                          padding: const EdgeInsets.only(right: _kGap),
                          child: _PathTile(
                            bot: opponentCatalogue[index],
                            record: widget.summary
                                .recordFor(opponentCatalogue[index].id),
                            locked: !isUnlocked(
                                opponentCatalogue[index].id, widget.unlocked),
                            isNext: index == next,
                            balance: widget.balance,
                            price: unlockCost(index),
                            onUnlock: widget.onUnlock,
                            avatarSize: tile - _kCardPadding * 2,
                            onOpen: () =>
                                widget.onOpen(opponentCatalogue[index]),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
      ),
    );
  }
}

/// Scroll physics that come to rest on a tile boundary.
///
/// The row is exactly three tiles wide, so any resting offset that is not a
/// multiple of the tile pitch shows two whole faces and two halves — which
/// looks like a list that has been left half-scrolled rather than a ladder.
///
/// It wraps the platform physics rather than replacing them: the fling still
/// decelerates the way the platform does, and this only changes *where* it is
/// allowed to stop. Snapping by rewriting the simulation, rather than by
/// animating after the fling ends, is what keeps it from fighting a user who
/// is still dragging.
class _SnapToTile extends ScrollPhysics {
  const _SnapToTile(this.pitch, {super.parent});

  final double pitch;

  @override
  _SnapToTile applyTo(ScrollPhysics? ancestor) =>
      _SnapToTile(pitch, parent: buildParent(ancestor));

  double _nearest(double offset, ScrollMetrics position) =>
      ((offset / pitch).roundToDouble() * pitch)
          .clamp(position.minScrollExtent, position.maxScrollExtent);

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    // Out of range: let the parent spring it back, or the row would snap to a
    // tile while still overscrolled.
    if ((velocity <= 0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    // Where the fling would have ended, rounded to the nearest boundary. A
    // flick that barely moves still commits to the next tile, which is what
    // makes a small deliberate swipe do something.
    final simulation = super.createBallisticSimulation(position, velocity);
    final natural = simulation?.x(double.infinity) ?? position.pixels;
    final limits = toleranceFor(position);
    final target = _nearest(
        velocity.abs() > limits.velocity &&
                (natural - position.pixels).abs() < pitch / 2
            ? position.pixels + pitch * velocity.sign
            : natural,
        position);
    if ((target - position.pixels).abs() < limits.distance) return null;
    return ScrollSpringSimulation(spring, position.pixels, target, velocity,
        tolerance: limits);
  }

  @override
  bool get allowImplicitScrolling => false;
}

/// The opponent the row rests on: the lowest-rated one rated **strictly
/// above** [playerRating].
///
/// Strictly above, so the centre is always a step up. Mote is rated exactly
/// 800 and a player seeded at 800 rests on Clover at 900, with Mote one tile to
/// the left — an even match is not "next", and the even-match marker already
/// says what Mote is (D287).
///
/// It lives here rather than in `quadrim_progression`, and that is deliberate:
/// that package's library doc promises **no function takes the player's rating
/// or their current rung**, and a test asserts it. The promise is what makes it
/// impossible to price a reward by how high the player has climbed (D261,
/// D270). A presentation rule that reads the rating is not a reward, but the
/// invariant is worth more than the convenience — so this sits beside
/// `tierNearest`, which is the app's other rating-to-catalogue question.
///
/// A player above the whole roster rests at the last opponent.
int restingIndex(int playerRating) {
  for (var i = 0; i < opponentCatalogue.length; i++) {
    if (opponentCatalogue[i].rating > playerRating) return i;
  }
  return opponentCatalogue.length - 1;
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
    required this.balance,
    required this.price,
    required this.onUnlock,
    required this.avatarSize,
    required this.onOpen,
  });

  final BotConfig bot;
  final OpponentRecord? record;
  final bool locked;
  final bool isNext;

  /// The spendable balance, not the earned total (D316).
  final int balance;
  final int price;
  final Future<void> Function(BotConfig bot, int price)? onUnlock;

  /// Handed down rather than measured: a `LayoutBuilder` here would sit inside
  /// the row's intrinsic-height pass, and a LayoutBuilder cannot report
  /// intrinsic dimensions.
  final double avatarSize;

  /// Opens this opponent's page. The tile is a summary; the page is the whole
  /// of what is known about them (D288).
  final VoidCallback onOpen;

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
        ? l10n.lockedWithPrice(price, balance)
        : played == 0
            ? l10n.neverPlayed
            : '${l10n.opponentRecord(record!.wins, record!.losses, record!.draws, played)}. '
                '${l10n.starsLabel(starCount)}';

    return Semantics(
      container: true,
      button: true,
      label: l10n.pathTileSemantics(name, bot.rating, state),
      child: ExcludeSemantics(
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          color: isNext ? theme.colorScheme.primaryContainer : null,
          child: InkWell(
            onTap: onOpen,
            child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Full tile width, so the avatar is the thing the eye lands on
                // and the ladder reads as a progression of faces.
                OpponentArt(id: bot.id, size: avatarSize, locked: locked),
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
                    balance: balance,
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
    required this.balance,
    required this.isNext,
    required this.onUnlock,
  });

  final int price;

  /// The spendable balance, not the earned total (D316).
  final int balance;
  final bool isNext;
  final VoidCallback? onUnlock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final affordable = balance >= price;
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
              value: price == 0 ? 1 : (balance / price).clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(l10n.unlockProgress(balance, price),
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
