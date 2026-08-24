import 'dart:math' as math;

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
  static const tutorial = 'assets/art/tutorial.webp';

  /// The two carved signs a section heading is written on. Which one is used
  /// depends on how long the heading is, not on which section it is.
  static const bannerShort = 'assets/art/banner_short.webp';
  static const bannerLong = 'assets/art/banner_long.webp';

  /// The two carved buttons that step the `Your path` row one tile. Cut to
  /// their disc and drawn in a square box, like every other picture (D295).
  static const arrowLeft = 'assets/art/arrow_left.webp';
  static const arrowRight = 'assets/art/arrow_right.webp';

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

/// Where the lettering goes on one piece of carved artwork.
///
/// The signs ship **blank** and the app writes on them (D297), which is what
/// makes them localisable — ticket 038 shipped the words baked into the wood
/// and D292 recorded that as a ceiling. This is that ceiling removed.
///
/// Every measurement is a fraction of the picture rather than a pixel, so the
/// same numbers hold at any size the sign is drawn. They were read off the art
/// itself: [tiltDegrees] for the tutorial board is 8.2, which is the angle the
/// original lettering was painted at, measured by fitting a line through its
/// glyphs rather than guessed.
class SignArt {
  const SignArt({
    required this.asset,
    required this.aspect,
    required this.centre,
    required this.tiltDegrees,
    required this.widthFraction,
    required this.fontFraction,
    required this.plankTop,
    required this.plankFraction,
  });

  final String asset;

  /// Width over height of the file. The sign is always drawn to this, because
  /// [centre] and the rest are fractions of it.
  final double aspect;

  /// Where the wood starts and how much of the picture it is, as fractions of
  /// the file's height.
  ///
  /// **These are what make one height mean one height.** The four signs carry
  /// very different amounts of transparent margin and leaf: the short banner's
  /// plank is 0.555 of its file and the long banner's is 0.385, so drawing both
  /// at the same *file* height gave the long one two thirds of the wood — which
  /// is what "the headers are different sizes" meant. Sizing by the plank makes
  /// the boards match and lets the transparent margin be whatever it is (D301).
  final double plankTop;
  final double plankFraction;

  /// Where the caption's middle sits, in `Alignment` coordinates (-1 to 1).
  final Alignment centre;

  /// How far the plank is rotated. Positive turns clockwise, which is the way
  /// the tutorial board leans.
  final double tiltDegrees;

  /// How much of the sign's width the caption may occupy before it is shrunk.
  final double widthFraction;

  /// The caption's nominal font size, as a fraction of the **plank's** height
  /// rather than the file's — so the same number means the same lettering on
  /// every sign. Text that would not fit shrinks; text that fits is left at
  /// this size.
  final double fontFraction;


  static const tutorial = SignArt(
    asset: Art.tutorial,
    aspect: 768 / 512,
    // Low and slightly right of centre — the open book takes the top third.
    centre: Alignment(0.02, 0.24),
    // The one sign that is not level. 8.2 was measured off the lettering the
    // artwork used to carry — but that lettering is gone (D297) and the plank
    // it has to match leans further than the old glyphs did, which is what
    // testers saw. 9.5 is a judgement against the plank, not a measurement.
    tiltDegrees: 9.5,
    widthFraction: 0.62,
    fontFraction: 0.44,
    plankTop: 186 / 512,
    plankFraction: 0.482,
  );

  static const newGame = SignArt(
    asset: Art.newGame,
    aspect: 1024 / 383,
    // The plank runs from 0.232 to 0.720 of the file, so its middle is at
    // Alignment y -0.047. The caption used to sit at -0.13, eight hundredths
    // high, which testers read as "not properly centred" — derived from the
    // plank rather than nudged by eye.
    centre: Alignment(0.01, -0.047),
    tiltDegrees: 0,
    widthFraction: 0.58,
    fontFraction: 0.52,
    plankTop: 89 / 383,
    plankFraction: 0.488,
  );

  /// The heading sign for a short caption.
  static const bannerShort = SignArt(
    asset: Art.bannerShort,
    aspect: 896 / 299,
    centre: Alignment(-0.004, -0.01),
    // Both banners droop a little; the numbers are small and they are what
    // keeps the words sitting on the plank rather than across its edge.
    tiltDegrees: -1.3,
    widthFraction: 0.64,
    fontFraction: 0.52,
    plankTop: 62 / 299,
    plankFraction: 0.555,
  );

  /// The heading sign for a long one. A plainer, longer plank.
  static const bannerLong = SignArt(
    asset: Art.bannerLong,
    aspect: 896 / 358,
    centre: Alignment(0.008, -0.06),
    tiltDegrees: -0.6,
    widthFraction: 0.74,
    fontFraction: 0.52,
    plankTop: 97 / 358,
    plankFraction: 0.385,
  );

  /// Which banner a heading of [characters] is written on.
  ///
  /// By length, not by section: "Finished games" needs the long plank in
  /// English and "Voltooide partijen" needs it more in Dutch, while "Quests"
  /// and "Bezig" would rattle around on it.
  static SignArt bannerFor(String caption) =>
      caption.length > 12 ? bannerLong : bannerShort;
}

/// A piece of carved artwork with words written on it.
///
/// The words are drawn rather than painted in, so they are localised, and the
/// wood is a picture, so they are not scaled by the system font slider — a
/// caption that grew to 200% would run off a plank that cannot grow with it.
/// That is not an accessibility regression: every sign is either a button with
/// an accessible name or a heading with a semantic label, and the text on it
/// is the same string either way (D297).
class WoodenSign extends StatelessWidget {
  const WoodenSign({
    super.key,
    required this.art,
    required this.caption,
    required this.plankHeight,
    this.width,
  });

  final SignArt art;

  /// What is written on it, in the player's language.
  final String caption;

  /// **How tall the wood is**, not how tall the file is — the picture is drawn
  /// larger than this, by whatever transparent margin and leaf the artist put
  /// around the plank. That is the whole point: one number here means one size
  /// of board on every sign (D301).
  ///
  /// Required, like the old `height` was and for the same reason: an `Image`
  /// reports no size until it has decoded, so a sign that took its height from
  /// the picture would be a zero-height sign on the first frame (D295).
  final double plankHeight;

  /// Overrides the width the aspect would give. Given only where a row has
  /// already decided how wide the sign may be.
  final double? width;

  /// The whole picture's height, plank plus margin.
  double get imageHeight => plankHeight / art.plankFraction;

  /// How far the top of the picture sits above the top of the plank.
  double get marginAbovePlank => art.plankTop * imageHeight;

  @override
  Widget build(BuildContext context) {
    final h = imageHeight;
    final w = width ?? h * art.aspect;
    final fontSize = plankHeight * art.fontFraction;
    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(art.asset,
              fit: BoxFit.fill, filterQuality: FilterQuality.medium),
          Align(
            alignment: art.centre,
            child: Transform.rotate(
              angle: art.tiltDegrees * math.pi / 180,
              // Rotated *outside* the box that measures the text, so the
              // shrink-to-fit below is computed on the unrotated line. Inside,
              // a tilted line would report a taller, wider box and shrink
              // itself for a reason that has nothing to do with the plank.
              child: SizedBox(
                width: w * art.widthFraction,
                height: fontSize * 1.3,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _CarvedText(caption, fontSize: fontSize),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The lettering's metrics, shared by what measures it and what draws it — a
/// second copy here would let the sign be sized for one font and painted in
/// another.
TextStyle _style(double fontSize) => TextStyle(
      fontFamily: QuadrimFonts.display,
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: fontSize * 0.02,
      height: 1.1,
    );

class _CarvedText extends StatelessWidget {
  const _CarvedText(this.text,
      {required this.fontSize});

  final String text;
  final double fontSize;


  @override
  Widget build(BuildContext context) {
    final rim = fontSize * 0.055;
    return MediaQuery.withNoTextScaling(
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        style: _style(fontSize).copyWith(
          color: QuadrimPalette.carvedGold,
          shadows: [
            for (final dx in [-rim, 0.0, rim])
              for (final dy in [-rim, 0.0, rim])
                if (dx != 0 || dy != 0)
                  Shadow(
                      color: QuadrimPalette.carvedRim,
                      offset: Offset(dx, dy),
                      blurRadius: rim * 0.6),
          ],
        ),
      ),
    );
  }
}

/// A [WoodenSign] that is a button.
///
/// Replaces `Plaque`, which drew artwork whose lettering was part of the
/// picture and could only be English (D292). The accessible name is still the
/// caption, so nothing about how it is announced has changed — what changed is
/// that a Dutch player now reads the same word the screen reader says.
class SignButton extends StatelessWidget {
  const SignButton({
    super.key,
    required this.art,
    required this.caption,
    required this.onPressed,
    required this.plankHeight,
    this.width,
  });

  final SignArt art;
  final String caption;
  final VoidCallback? onPressed;
  final double plankHeight;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: caption,
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: WoodenSign(
                art: art,
                caption: caption,
                plankHeight: plankHeight,
                width: width),
          ),
        ),
      ),
    );
  }
}
