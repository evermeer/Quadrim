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

/// Width over height of the carved section signs. They are drawn from one
/// template, so one number covers them all.
const double kBannerAspect = 896 / 326;

/// A parchment card with a heading, which is what every list section on the
/// main screen is.
///
/// [banner] replaces the heading with artwork where there is artwork for it —
/// only Your Path has a carved sign. The text heading is still built when a
/// banner is given, hidden from sight and kept for the screen reader, because
/// the words on the sign are painted into a picture and a picture says nothing.
class ParchmentSection extends StatelessWidget {
  const ParchmentSection({
    super.key,
    required this.heading,
    required this.child,
    this.banner,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(12, 12, 12, 12),
  });

  final String heading;
  final Widget child;
  final String? banner;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: banner == null
                      ? Semantics(
                          header: true,
                          child: Text(heading,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(color: QuadrimPalette.ink)),
                        )
                      : Semantics(
                          header: true,
                          label: heading,
                          child: ExcludeSemantics(
                            // A fixed box, for the same reason the plaques have
                            // one: the picture's own size is not known until it
                            // decodes, and a heading that resizes a frame later
                            // shifts everything under it.
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                height: 46,
                                width: 46 * kBannerAspect,
                                child: Image.asset(banner!,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.medium),
                              ),
                            ),
                          ),
                        ),
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
