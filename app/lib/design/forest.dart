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

/// How tall a section's carved heading sign is drawn.
const double kBannerHeight = 56;

/// A parchment card with a carved heading sign.
///
/// Every section on the main screen wears one now, not only Your Path: the
/// headings used to be a line of Cinzel and a wooden sign was a thing only one
/// of them had, which read as an accident rather than a hierarchy.
///
/// [overhang] hangs the sign off the card's top-left corner instead of sitting
/// it inside the padding — the top fifth of the picture rises above the card
/// and its left edge lines up with the card's own. `Transform.translate` moves
/// it without moving what it is measured as, so the column below still reserves
/// the four fifths that are actually inside the card.
class ParchmentSection extends StatelessWidget {
  const ParchmentSection({
    super.key,
    required this.heading,
    required this.child,
    this.trailing,
    this.overhang = false,
    this.padding = const EdgeInsets.fromLTRB(12, 12, 12, 12),
  });

  final String heading;
  final Widget child;
  final Widget? trailing;
  final bool overhang;
  final EdgeInsetsGeometry padding;

  /// How much of the sign rises above the card when it [overhang]s.
  static const double _kOverhang = 0.2;

  @override
  Widget build(BuildContext context) {
    final inset = padding.resolve(TextDirection.ltr);
    final art = SignArt.bannerFor(heading);
    // A heading, and a picture of one. The sign carries the words, so the
    // semantics node carries them too and the artwork itself is excluded —
    // otherwise a screen reader meets a heading with nothing in it.
    final sign = Semantics(
      header: true,
      label: heading,
      child: ExcludeSemantics(
        child: WoodenSign(
            art: art, caption: heading, height: kBannerHeight),
      ),
    );
    return Card(
      // Never clipped: an overhanging sign is drawn outside these bounds on
      // purpose, and the default would cut its top fifth off.
      clipBehavior: Clip.none,
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: overhang
                      ? SizedBox(
                          height: kBannerHeight * (1 - _kOverhang),
                          child: Transform.translate(
                            offset: Offset(
                                -inset.left, -inset.top - kBannerHeight * _kOverhang),
                            child: Align(
                                alignment: Alignment.topLeft, child: sign),
                          ),
                        )
                      : Align(alignment: Alignment.centerLeft, child: sign),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
