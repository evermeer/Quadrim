import 'package:flutter/material.dart';

import '../theme.dart';
import 'art.dart';

/// The frame every screen sits in (ticket 038).
///
/// The forest is painted once, behind a transparent scaffold, and it does not
/// scroll — it is a place the app is in, not a thing on a page. `Scaffold`'s own
/// background is transparent in the theme, so this is the only thing that ever
/// paints it, and a screen that forgets to use it shows the canopy green rather
/// than white.
class ForestScaffold extends StatelessWidget {
  const ForestScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottom,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;

  /// Pinned under [body], outside the scroll. The main screen's plaques live
  /// here so the primary action never scrolls away.
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: QuadrimPalette.canopy,
        image: DecorationImage(
          image: AssetImage(Art.background),
          fit: BoxFit.cover,
          // The picture is a corridor of trees with a bright clearing at the
          // top; anchoring it there keeps the sky behind the app bar on a tall
          // phone rather than cropping to undergrowth.
          alignment: Alignment.topCenter,
          // The scrim, and it is not decoration (D296). Measured against the
          // shipped background, cream over the bare photograph runs from 3.4:1
          // down to 1.0:1 — invisible. 0x9E is 62%, the lightest value at which
          // cream clears 4.5:1 against the *brightest pixel in the picture*
          // rather than against its average; a gradient was tried first and
          // does not work, because the bright mist sits at 45% of the height
          // rather than at the top.
          colorFilter: ColorFilter.mode(Color(0x9E0B160E), BlendMode.srcOver),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar,
        // Not `extendBodyBehindAppBar`. The forest is painted by the
        // `DecoratedBox` *outside* the scaffold, so a transparent app bar
        // already shows it; extending the body underneath would only give
        // every screen a chance to slide its first line under the title.
        body: body,
        bottomNavigationBar: bottom,
      ),
    );
  }
}

/// A full-height parchment surface for the screens the mockup does not draw.
///
/// The main screen is a stack of small cards on the forest, which works because
/// every one of them is short. A settings list or a twenty-row opponent list is
/// not short, and ink text over a photograph of leaves is not readable at any
/// size. So the secondary screens put one sheet of parchment under everything
/// and the forest becomes a border rather than a backdrop.
class ParchmentSheet extends StatelessWidget {
  const ParchmentSheet({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        // A `Material`, not a `Container` with a colour. Every list on these
        // screens is made of `ListTile`s and `InkWell`s, and both paint their
        // background and their ripple onto the nearest `Material` ancestor — a
        // coloured box in between hides the ink. Flutter asserts on exactly
        // this, which is how the first version of this widget was caught.
        child: Material(
          color: QuadrimPalette.parchment,
          clipBehavior: Clip.antiAlias,
          elevation: 4,
          shadowColor: const Color(0xFF0B160E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: QuadrimPalette.edge, width: 1.5),
          ),
          child: Padding(
            padding: padding ?? EdgeInsets.zero,
            child: child,
          ),
        ),
      );
}

/// The mockup's dark-green card: the one panel that is not parchment.
///
/// Used for the rating, which is the screen's headline number and the only
/// thing on it that should read as lit from within rather than printed.
class DarkPanel extends StatelessWidget {
  const DarkPanel({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF4A6B45), width: 1.5),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [QuadrimPalette.panelRaised, QuadrimPalette.panel],
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x800B160E), blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        // Cream and gold for anything inside that does not say otherwise.
        //
        // **This cannot save a caller that passes `theme.textTheme.something`
        // explicitly**, and every line of the rating card does. A `TextStyle`
        // taken from the ambient theme already carries the ink colour, and a
        // `DefaultTextStyle` is only consulted for text that has none — nor
        // would a `Theme` override help, because the caller resolved
        // `Theme.of` above this widget, before the override exists. The record
        // line and the streak line shipped as ink on dark green until a
        // screenshot of the running app showed it. What this does cover is
        // everything added here later that does not name a style (D296).
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: QuadrimPalette.cream),
          child: IconTheme.merge(
            data: const IconThemeData(color: QuadrimPalette.gold),
            child: child,
          ),
        ),
      );
}

/// How tall the **wood** is on every carved heading sign.
///
/// One number for all of them, and it is the plank rather than the picture:
/// the two banner files carry very different amounts of transparent margin, so
/// equal file heights gave visibly unequal boards (D301). Each sign's width
/// follows from its own proportions.
const double kPlankHeight = 34;

/// How much of a heading sign rises above the card it labels.
const double _kOverhang = 0.52;

/// The gap between one section and the next.
///
/// Big enough that a heading sign hangs into *empty space* rather than into the
/// panel above it. A viewport paints its slivers back to front — the first one
/// last — so an overhang that reaches the previous section is drawn underneath
/// it, and the sign loses its top half to a panel it has nothing to do with.
/// That is not a z-order to fight; it is a gap to leave (D300).
const double kSectionGap = 40;

/// How far left of the card's edge it hangs.
const double _kOverhangLeft = 6;

/// A parchment card with a carved heading sign nailed to its top-left corner.
///
/// Every section on the main screen wears one, not only Your Path: the headings
/// used to be a line of Cinzel, and a wooden sign that one section had and the
/// others did not read as an accident rather than a hierarchy.
///
/// **The sign hangs off the card rather than sitting inside it.** Nearly half of
/// it rises above the top edge and it overlaps the left edge, which is what
/// makes it read as a label *on* the panel instead of a picture *in* it.
/// `Transform.translate` moves it without changing what it is measured as, so
/// the column below reserves only the part that is actually inside — and the
/// content sits that much higher up the card.
/// The one glyph both Game Center controls use.
///
/// **The same icon in both places, at the developer's request** (D391). They
/// open different views — a leaderboard and an achievements shelf — and what
/// tells them apart is the word beside the glyph, not the glyph. Two different
/// icons for one feature read as two unrelated features.
const IconData kGameCenterIcon = Icons.emoji_events_outlined;

class ParchmentSection extends StatelessWidget {
  const ParchmentSection({
    super.key,
    required this.heading,
    required this.child,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(12, 12, 12, 12),
  });

  final String heading;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final sign = SectionSign(heading);
    // **The sign is a sibling of the card, not a child of it.** `Material`
    // paints its shape's border *over* its children, so a heading inside the
    // card had the card's own top edge drawn as a line straight through the
    // lettering. The sliver-backed sections never showed it — their parchment
    // is a `DecoratedSliver`, which paints behind — which is exactly why one
    // section looked right and the rest did not (D301).
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Card(
          child: Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // A plain spacer for the part of the plank inside the card.
                    // The sign itself is placed by the `Positioned` below, so
                    // nothing here has to reason about where it is drawn.
                    Expanded(child: SizedBox(height: kSignReserve)),
                    ?trailing,
                  ],
                ),
                child,
              ],
            ),
          ),
        ),
        // Relative to the card, which fills this stack: the plank's top sits
        // `_kOverhang` of its own height above the card's top edge, and the
        // picture starts however far above that its transparent margin runs.
        Positioned(
          left: -_kOverhangLeft,
          top: -(kPlankHeight * _kOverhang + sign.marginAbovePlank),
          child: sign,
        ),
      ],
    );
  }
}

/// How much room a panel leaves for the part of the heading plank inside it.
///
/// The card's own top padding then becomes the gap between the wood and the
/// first row, which is what it is for — an earlier version subtracted that
/// padding back out to "tighten" the panel and left four pixels of reserve, so
/// every row sat under the sign.
const double kSignReserve = kPlankHeight * (1 - _kOverhang);

/// The carved sign itself: artwork, caption, and the heading a screen reader
/// meets. It sizes itself, so it can be positioned freely.
class SectionSign extends StatelessWidget {
  const SectionSign(this.text, {super.key});

  final String text;

  SignArt get art => SignArt.bannerFor(text);

  /// How far the picture's top edge is above the plank's, at [kPlankHeight].
  double get marginAbovePlank =>
      art.plankTop * (kPlankHeight / art.plankFraction);

  @override
  Widget build(BuildContext context) => Semantics(
        header: true,
        label: text,
        // A heading, and a picture of one. The sign carries the words, so the
        // semantics node carries them too and the artwork is excluded —
        // otherwise a screen reader meets a heading with nothing in it.
        child: ExcludeSemantics(
          child: WoodenSign(
              art: art, caption: text, plankHeight: kPlankHeight),
        ),
      );
}

/// A section's heading where the panel is a sliver rather than a card.
///
/// `gameSectionSlivers` cannot wrap its list in a `Stack` without giving up the
/// laziness that list exists for, so here the sign is laid out in the flow and
/// lifted into place. It needs no protection from a border painted over it:
/// that parchment is a `DecoratedSliver`, which paints behind its children.
class SectionHeading extends StatelessWidget {
  const SectionHeading(this.text, {super.key, this.inset = EdgeInsets.zero});

  final String text;

  /// The padding the sliver puts around its content, which the sign climbs
  /// back out of to reach the panel's own edge.
  final EdgeInsets inset;

  @override
  Widget build(BuildContext context) {
    final sign = SectionSign(text);
    return SizedBox(
      height: kSignReserve,
      child: Transform.translate(
        offset: Offset(-inset.left - _kOverhangLeft,
            -(inset.top + sign.marginAbovePlank + kPlankHeight * _kOverhang)),
        // **`OverflowBox`, not `Align`.** The box around this reserves only the
        // part of the sign that is inside the panel, and every ordinary widget
        // passes its own maximum height down — so the sign was clamped to the
        // few pixels reserved for it and drawn as a wide thin sliver, by a
        // different amount on each banner because each reserves a different
        // amount. Reserving space and constraining the child are the same
        // thing in Flutter unless you say otherwise. This says otherwise.
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: 0,
          maxWidth: double.infinity,
          minHeight: 0,
          maxHeight: double.infinity,
          child: sign,
        ),
      ),
    );
  }
}
