import 'package:flutter/material.dart';

import '../theme.dart';

/// The shipped artwork, and the two widgets that draw it (ticket 038).
///
/// Every path is built here rather than spelled at each call site, so a missing
/// file is one broken constant instead of twenty broken screens — and so
/// `art_assets_test.dart` can walk the roster and assert that each of the
/// twenty opponents actually has a picture. `pubspec.yaml` declares the two
/// directories wholesale, which means adding an opponent's art is dropping a
/// file in, but it also means nothing would complain if the file were missing.
/// The test is what complains.
abstract final class Art {
  static const background = 'assets/art/background.webp';
  static const logo = 'assets/art/logo.webp';
  static const cube = 'assets/art/cube.webp';
  static const newGame = 'assets/art/new_game.webp';
  static const yourPath = 'assets/art/your-path.webp';
  static const tutorial = 'assets/art/tutorial.webp';

  /// One opponent's portrait, by catalogue id. The files are cut to a circle by
  /// `tools/artgen`, so nothing here has to clip.
  static String opponent(String id) => 'assets/art/opponents/$id.webp';
}

/// How much of the panel green is laid over a locked portrait.
///
/// Not 1.0, and that is the whole point (D291). A constant-colour matrix — which
/// is what this was first — replaces every pixel and leaves a flat dark disc,
/// because these portraits are full-bleed circular *scenes* rather than subjects
/// cut out on transparency. There is no outline in the file to silhouette. At
/// 0.86 the creature is still there as a shape in the gloom, which is what the
/// mockup draws and what a flat disc reads as a rendering fault instead of.
const double _lockedVeil = 0.86;

/// One opponent's portrait, or their shadow if they are still locked.
///
/// Replaces the drawn identicon of ticket 029, which existed to be replaced:
/// it said so in its own doc comment, and its whole job was to give twenty
/// opponents twenty distinguishable faces with no binary assets to commission.
/// The assets have been commissioned.
///
/// Decorative in every case. The name, rating and tier sit beside it as real
/// text wherever it is drawn, so there is nothing here a screen reader could
/// announce that its row does not already say.
class OpponentArt extends StatelessWidget {
  const OpponentArt({
    super.key,
    required this.id,
    this.size = 44,
    this.locked = false,
  });

  /// The catalogue id, without the `bot:` prefix.
  final String id;

  final double size;

  /// Draws the portrait as a silhouette instead. What the player has not bought
  /// they have not met, and a face they can already see is a poor advertisement
  /// for paying to see it.
  final bool locked;

  @override
  Widget build(BuildContext context) {
    Widget portrait = Image.asset(
      Art.opponent(id),
      width: size,
      height: size,
      fit: BoxFit.cover,
      // Decoded at the size it is drawn. Twenty 512px portraits held at full
      // resolution for a 56px row is the difference between a few megabytes of
      // image cache and a few dozen.
      cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
      filterQuality: FilterQuality.medium,
    );
    if (locked) {
      portrait = Stack(
        alignment: Alignment.center,
        children: [
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              QuadrimPalette.panel.withValues(alpha: _lockedVeil),
              BlendMode.srcATop,
            ),
            child: portrait,
          ),
          // The padlock the mockup draws. Without it the veil alone is
          // ambiguous — "dark" is not a word, and a dimmed picture could as
          // easily be a picture that failed to load. The state is also carried
          // in words: every row and tile that draws a locked portrait says so
          // in its own semantics label, which is why this is decorative.
          Icon(Icons.lock,
              size: size * 0.32, color: QuadrimPalette.parchmentDeep),
        ],
      );
    }
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          // The ring is the frame the mockup draws around every portrait, and
          // it is also what stops a dark avatar from dissolving into a dark
          // panel behind it.
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: locked ? QuadrimPalette.edge : QuadrimPalette.gold,
              width: size < 60 ? 1.5 : 2.5,
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x400B160E), blurRadius: 6, spreadRadius: 1),
            ],
          ),
          child: ClipOval(child: portrait),
        ),
      ),
    );
  }
}

/// A carved-wood plaque used as a button.
///
/// The artwork carries its own lettering, in English, in every locale. That was
/// chosen with its cost understood (D292): the plaques are the design, and
/// re-lettering wood grain convincingly is not something this pipeline can do.
/// [label] is therefore not drawn — it is the accessible name, so a Dutch
/// screen reader still says "Nieuwe partij" over a plank that reads NEW GAME.
class Plaque extends StatelessWidget {
  const Plaque({
    super.key,
    required this.asset,
    required this.label,
    required this.onPressed,
    required this.height,
    this.width,
  });

  final String asset;

  /// What this button is called, in the player's language.
  final String label;

  final VoidCallback? onPressed;

  /// Required, unlike [width]. A `SizedBox` with neither dimension sizes to its
  /// child, and an undecoded `Image` reports zero — so an optional height let
  /// this widget express the exact 316x0 untappable button it exists to
  /// prevent. The type now refuses it (D295).
  final double height;

  /// Null means "take the width you are given", which is what the New Game
  /// plaque does inside an `Expanded`.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            // Sized by the box, never by the picture. An `Image` with no
            // height reports zero until it has decoded, so a plaque that let
            // the artwork set its own size would be a zero-height button on
            // the first frame — and permanently so in a widget test, where
            // nothing ever decodes. That is how this was caught.
            child: SizedBox(
              height: height,
              width: width,
              child: Image.asset(
                asset,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
