import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quadrim_engine/quadrim_engine.dart';
import 'package:quadrim_progression/quadrim_progression.dart';

import '../data/documents.dart';
import '../data/home_summary.dart';
import '../design/art.dart';
import '../design/forest.dart';
import '../game/opponent_name.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import 'section_widgets.dart';

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

/// The margin between the screen edge and the panel, which every other section
/// gets from `home_screen.dart`'s SliverPadding and this one applies itself.
///
/// This section is laid out at the full width of the screen, because the two
/// arrows hang off the outside of its panel and **a widget cannot be pressed
/// outside its parent's box** — `RenderBox.hitTest` checks that first, so a
/// child positioned beyond the edge is painted and not touchable (D319).
const double _kScreenMargin = 16;

/// Everything between the screen edge and the scrolling row, per side. It has
/// to match what actually surrounds this widget, because the tile width is
/// derived from the screen width rather than measured: the margin above, the
/// parchment card's border (1.5) and the `ParchmentSection` padding this widget
/// asks for (8).
const double _kSectionInset = _kScreenMargin + 1.5 + 8;

/// The tile card's own horizontal padding, subtracted to get the avatar's
/// width. Passed down rather than measured, because a `LayoutBuilder` inside
/// the row would break the intrinsic-height pass that sizes it.
const double _kCardPadding = 6;

/// How big the two carved arrows are drawn, and how big the thing you press
/// is. The target is the 48dp minimum, which is the number that matters and is
/// not the same number (spec §8.13).
const double _kArrowSize = 40;
const double _kArrowTap = 48;

/// How see-through an arrow is. They sit on top of a face, and a solid disc
/// over one is a hole in the ladder rather than a control on it.
const double _kArrowOpacity = 0.5;

/// How far each arrow hangs off the panel, as a fraction of its own width.
/// Straddling the border is what makes it read as a handle on the edge of the
/// panel rather than a button dropped inside it.
const double _kArrowOverhang = 0.30;

/// Where an arrow's target starts, measured from the **screen** edge, since
/// that is what this section is laid out against.
///
/// It comes out at exactly zero for the sizes above, and that is what decides
/// them: the picture is as large as it can be with 30% of it outside the panel
/// and a full 48dp target still on the screen. Making the arrow smaller pushes
/// the target off the left edge, where the outer part of it stops being
/// pressable for the same reason the overhang would have (D319).
const double _kArrowOutset = _kScreenMargin -
    _kArrowOverhang * _kArrowSize -
    (_kArrowTap - _kArrowSize) / 2;

class _YourPathState extends State<YourPath> {
  ScrollController? _controller;

  /// The furthest the row can be scrolled, and whether it is at either end.
  ///
  /// Kept as booleans rather than read off the controller during build: an
  /// arrow that dimmed on every scrolled pixel would rebuild twenty tiles a
  /// frame, and only the two ends change anything on screen.
  double _maxOffset = 0;
  bool _atStart = false;
  bool _atEnd = false;

  /// The index the row was last rested on, so a rating change moves it and a
  /// rebuild for any other reason does not. Without this the row would snap
  /// back to the resting tile every time a game finished elsewhere on the
  /// screen, undoing whatever the player had scrolled to.
  int _restedOn = -1;

  /// How many tiles the row held when it last settled. A mercy rung arriving
  /// (D382) shifts every tile right, and the resting position must follow it.
  int _restedCount = -1;

  /// The roster as this row shows it: everything except the mercy rungs the
  /// player has not earned back (D382).
  ///
  /// They are hidden rather than shown locked because a locked tile announces
  /// its price, and these have none — no amount of points buys one, so the
  /// figure would be one the player can never spend. Set at the top of build,
  /// because both the scroll extent and the resting position are counted in
  /// tiles rather than in roster indices.
  List<BotConfig> _visible = const [];
  double _step = 0;

  double _offsetFor(int index) {
    // The resting tile is the middle of three, so the row starts one tile
    // before it.
    return ((index - 1) * _step).clamp(0, _maxOffset).toDouble();
  }

  /// Notices when the row reaches or leaves an end, and nothing else.
  void _onScroll() {
    final offset = _controller!.offset;
    // A tolerance rather than equality: the snap spring settles within a
    // fraction of a pixel of the boundary, not on it.
    final start = offset <= 0.5;
    final end = offset >= _maxOffset - 0.5;
    if (start != _atStart || end != _atEnd) {
      setState(() {
        _atStart = start;
        _atEnd = end;
      });
    }
  }

  /// Steps the row one tile. [direction] is -1 for the left arrow.
  ///
  /// From the nearest boundary rather than from wherever the row happens to
  /// be, so a tap after a half-finished drag lands on a tile like every other
  /// tap does.
  void _step1(int direction) {
    final from = (_controller!.offset / _step).round();
    _controller!.animateTo(
        ((from + direction) * _step).clamp(0.0, _maxOffset),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut);
  }

  /// Where the row comes to rest, as a position in [_visible] rather than a
  /// roster index — the two differ by however many mercy rungs are hidden.
  int _restingPosition() {
    final bot = opponentCatalogue[restingIndex(widget.summary.computerRating)];
    final at = _visible.indexWhere((other) => other.id == bot.id);
    // Hidden: the player is rated below everything they can currently play, so
    // the row rests at its left end.
    return at < 0 ? 0 : at;
  }

  void _settle() {
    final resting = _restingPosition();
    if (_controller != null &&
        resting == _restedOn &&
        _visible.length == _restedCount) {
      return;
    }
    _restedOn = resting;
    _restedCount = _visible.length;
    final offset = _offsetFor(resting);
    _atStart = offset <= 0.5;
    _atEnd = offset >= _maxOffset - 0.5;
    if (_controller == null) {
      _controller = ScrollController(initialScrollOffset: offset)
        ..addListener(_onScroll);
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
    // The width comes from the screen rather than from a LayoutBuilder: a
    // LayoutBuilder cannot report intrinsic dimensions, and the row below is
    // sized by the intrinsic height of its tallest tile.
    final width = MediaQuery.sizeOf(context).width - _kSectionInset * 2;
    final tile = (width - _kGap * (_kVisibleTiles - 1)) / _kVisibleTiles;
    _step = tile + _kGap;
    _visible = [
      for (final bot in opponentCatalogue)
        if (!isMercy(bot) || isUnlocked(bot.id, widget.unlocked)) bot,
    ];
    _maxOffset = math.max(0, _step * _visible.length - width);
    _settle();
    // A rotation changes the width and therefore both of these, and no scroll
    // happens to report it — so they are refreshed here as well as by the
    // listener.
    if (_controller!.hasClients) {
      _atStart = _controller!.offset <= 0.5;
      _atEnd = _controller!.offset >= _maxOffset - 0.5;
    }

    // The row scrolls, and on a phone that is only discoverable by trying it:
    // three tiles fill the width exactly, so there is no half-visible fourth to
    // hint at the other seventeen. The two carved arrows say so, and stepping
    // one tile is also the only way to move the row precisely — a drag lands
    // wherever the snap rounds it to (D318).
    //
    // They are siblings of the panel rather than children of it, because they
    // hang off its border and nothing outside a box can be pressed (D319).
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _kScreenMargin),
          // The carved sign carries the heading, written on it by the app
          // rather than painted into it, so it reads "Jouw pad" in Dutch
          // (D297). It hangs off the card's top-left corner, which is what
          // makes it read as a sign nailed to the panel rather than a picture
          // inside it.
          child: ParchmentSection(
            heading: l10n.yourPath,
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
            // Sized by the tallest tile rather than by a number. Two guesses at
            // a fixed height were both wrong — 18 pixels short at the largest
            // font scale, then 28 — because the avatar is sized by the tile and
            // does not grow with the font while everything under it does.
            // `IntrinsicHeight` measures instead of predicting.
            //
            // Eager rather than lazy, and that is affordable here: the roster is
            // exactly twenty and cannot grow without a code change, so this is a
            // bounded list, unlike the finished-games list beneath it.
            child: SingleChildScrollView(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              // Lands on a tile boundary, so the row always shows three whole
              // faces rather than two and two halves.
              physics: _SnapToTile(_step),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final bot in _visible)
                      Builder(builder: (context) {
                        // The roster index, not the position in the row: it is
                        // what prices the tile and what `next` is counted in.
                        final index = rosterIndexOf(bot.id)!;
                        return SizedBox(
                          width: _step,
                          child: Padding(
                            padding: const EdgeInsets.only(right: _kGap),
                            child: _PathTile(
                              bot: bot,
                              record: widget.summary.recordFor(bot.id),
                              locked: !isUnlocked(bot.id, widget.unlocked),
                              isNext: index == next,
                              balance: widget.balance,
                              price: unlockCost(index),
                              onUnlock: widget.onUnlock,
                              avatarSize: tile - _kCardPadding * 2,
                              onOpen: () => widget.onOpen(bot),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Halfway down the panel and straddling its border, so neither arrow
        // sits over the middle of a face and both read as handles on the edge
        // of the panel.
        for (final (asset, label, direction, hidden) in [
          (Art.arrowLeft, l10n.pathScrollLeft, -1, _atStart),
          (Art.arrowRight, l10n.pathScrollRight, 1, _atEnd),
        ])
          Positioned(
            left: direction < 0 ? _kArrowOutset : null,
            right: direction < 0 ? null : _kArrowOutset,
            top: 0,
            bottom: 0,
            child: Center(
              child: _ScrollArrow(
                asset: asset,
                label: label,
                // Faded rather than removed at the ends: a control that
                // vanishes takes its own explanation with it, and the row would
                // then have nothing saying it scrolls at all once a player
                // reached the far end of the roster.
                hidden: hidden,
                onPressed: () => _step1(direction),
              ),
            ),
          ),
      ],
    );
  }
}

/// One of the two carved buttons that step the row a tile.
///
/// A picture rather than an `Icon`, so it belongs to the same wood-and-stone
/// set as the signs and the panels. Decorative in itself — everything it means
/// is in the [label] the button announces.
class _ScrollArrow extends StatelessWidget {
  const _ScrollArrow({
    required this.asset,
    required this.label,
    required this.hidden,
    required this.onPressed,
  });

  final String asset;
  final String label;

  /// At the end it can no longer reach. Still laid out, so nothing moves.
  final bool hidden;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: hidden,
      child: AnimatedOpacity(
        opacity: hidden ? 0 : _kArrowOpacity,
        duration: const Duration(milliseconds: 150),
        child: Semantics(
          button: true,
          enabled: !hidden,
          label: label,
          excludeSemantics: true,
          child: Material(
            type: MaterialType.transparency,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: _kArrowTap,
                height: _kArrowTap,
                child: Center(
                  child: Image.asset(
                    asset,
                    // Both dimensions, before the bytes arrive (D295).
                    width: _kArrowSize,
                    height: _kArrowSize,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),
            ),
          ),
        ),
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
    // Spoken in full and written short: the tile is a third of the screen and
    // a screen reader has no width at all (D320).
    final name = botName(l10n, botOpponent(bot.id));
    final written = botShortName(l10n, botOpponent(bot.id));
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
            : '${opponentRecordLine(l10n, record!)}. '
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
                Text(written,
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
          opponentRecordLine(l10n, record!),
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
            // **Enabled even when it cannot be afforded** (tester feedback).
            // Greyed out, it answered nothing: not how many points are short,
            // and not that the shortfall can be bought past. `runUnlock` says
            // both.
            //
            // It still *reads* as out of reach — muted lettering rather than a
            // dead control — because losing that signal would trade one
            // confusion for another.
            //
            // **Muted has to mean a dimmer light, not a darker one.** This read
            // `onSurfaceVariant`, which is `inkSoft` — text sized for
            // parchment, printed on the bark brown this button is filled with.
            // That measured 1.31:1 and was simply unreadable. Parchment is the
            // panel's own beige at 4.30:1, still visibly softer than the cream
            // an affordable button gets at 5.08:1, so the signal survives at a
            // legible contrast (D383).
            onPressed: onUnlock,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: affordable ? null : QuadrimPalette.parchment,
            ),
            child: Text(l10n.unlockAction,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ],
    );
  }
}
