import 'package:flutter/material.dart';

/// The forest palette, read off `doc/designs/Design-alt0.png` (ticket 038).
///
/// **One theme, not two.** The Nocturne dark/light pair this replaces was a
/// seeded Material scheme with no design behind it. What replaces it is a
/// painting: a sunlit forest behind dark-green panels and parchment cards, and
/// there is no second painting to be the other mode. `MaterialApp` is handed
/// the same [ThemeData] for both brightnesses so that a device set to dark does
/// not get a half-inverted version of a design that was never inverted (D293).
///
/// The names are the design's, not Material's. Material's slots are filled from
/// them at the bottom of this file, so existing call sites that ask for
/// `colorScheme.primary` land somewhere sensible instead of every one of them
/// needing to know about bark and parchment.
abstract final class QuadrimPalette {
  /// Behind everything, and visible only where the background image is not —
  /// the instant before it decodes, and under a system bar.
  static const canopy = Color(0xFF12261A);

  /// The dark card: the rating panel in the mockup.
  static const panel = Color(0xFF1C3220);
  static const panelRaised = Color(0xFF2B462C);

  /// The light card: Your Path, the game lists, the quests.
  static const parchment = Color(0xFFE9DCBD);
  static const parchmentDeep = Color(0xFFDCCBA4);

  /// Card borders and dividers on parchment.
  static const edge = Color(0xFFC7B78E);

  /// Text on parchment.
  static const ink = Color(0xFF2A2314);
  static const inkSoft = Color(0xFF5E5238);

  /// Text on [panel] and on the background image.
  static const cream = Color(0xFFF4EFDC);
  static const creamSoft = Color(0xFFC3C79A);

  /// The accent. [gold] is the lettering on the plaques; [goldDeep] is the same
  /// hue taken down until it reads as text on parchment, which the bright one
  /// does not.
  static const gold = Color(0xFFE3C65B);
  static const goldDeep = Color(0xFF6B4E12);

  /// Carved wood, for the warm buttons.
  static const bark = Color(0xFF905813);

  /// The lettering on the wooden signs, and its rim. Measured off the word the
  /// tutorial sign used to carry, so the drawn captions match the art they sit
  /// on rather than approximating it (D297).
  static const carvedGold = Color(0xFFFDDE7C);
  static const carvedRim = Color(0xFF5C300C);

  /// The rating pill's green. Dark enough to carry [cream] at label size.
  static const moss = Color(0xFF3F5222);

  static const win = Color(0xFF2F5115);
  static const loss = Color(0xFF8C2A18);
}

/// Fonts are bundled, never fetched: the release manifest declares no INTERNET
/// permission (D212), so a font that resolved over the network would not be a
/// slow font, it would be no font.
abstract final class QuadrimFonts {
  /// The flared display serif of the mockup's lettering. Headlines, the rating,
  /// section headings.
  static const display = 'Cinzel';

  /// The body serif. Everything that is read rather than glanced at.
  static const body = 'EBGaramond';
}

abstract final class QuadrimTheme {
  static const _scheme = ColorScheme(
    brightness: Brightness.light,
    primary: QuadrimPalette.goldDeep,
    onPrimary: QuadrimPalette.cream,
    primaryContainer: QuadrimPalette.gold,
    onPrimaryContainer: QuadrimPalette.ink,
    secondary: QuadrimPalette.moss,
    onSecondary: QuadrimPalette.cream,
    secondaryContainer: QuadrimPalette.moss,
    onSecondaryContainer: QuadrimPalette.cream,
    tertiary: QuadrimPalette.bark,
    onTertiary: QuadrimPalette.cream,
    tertiaryContainer: QuadrimPalette.panel,
    onTertiaryContainer: QuadrimPalette.cream,
    error: QuadrimPalette.loss,
    onError: QuadrimPalette.cream,
    errorContainer: QuadrimPalette.loss,
    onErrorContainer: QuadrimPalette.cream,
    surface: QuadrimPalette.parchment,
    onSurface: QuadrimPalette.ink,
    surfaceContainerHighest: QuadrimPalette.parchmentDeep,
    onSurfaceVariant: QuadrimPalette.inkSoft,
    outline: Color(0xFF8C7C52),
    outlineVariant: QuadrimPalette.edge,
    // The scrim and the inverse pair are the dark green rather than Material's
    // computed near-black, so a dialog barrier reads as the forest going dim.
    scrim: Color(0xCC0B160E),
    inverseSurface: QuadrimPalette.panel,
    onInverseSurface: QuadrimPalette.cream,
    inversePrimary: QuadrimPalette.gold,
    shadow: Color(0xFF0B160E),
  );

  static final ThemeData forest = ThemeData(
    useMaterial3: true,
    colorScheme: _scheme,
    fontFamily: QuadrimFonts.body,
    // Transparent, not the canopy: every screen sits on `ForestBackground`,
    // and a coloured scaffold would paint over the picture.
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: Colors.transparent,
    textTheme: _textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      foregroundColor: QuadrimPalette.cream,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: QuadrimFonts.display,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: QuadrimPalette.cream,
      ),
      iconTheme: IconThemeData(color: QuadrimPalette.cream),
    ),
    cardTheme: CardThemeData(
      color: QuadrimPalette.parchment,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      shadowColor: const Color(0x660B160E),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: QuadrimPalette.edge, width: 1.5),
      ),
    ),
    dividerTheme: const DividerThemeData(color: QuadrimPalette.edge),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: QuadrimPalette.bark,
        foregroundColor: QuadrimPalette.cream,
        disabledBackgroundColor: QuadrimPalette.parchmentDeep,
        disabledForegroundColor: QuadrimPalette.inkSoft,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(
          fontFamily: QuadrimFonts.display,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF5C3A0C), width: 1.5),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: QuadrimPalette.goldDeep),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: QuadrimPalette.goldDeep,
        side: const BorderSide(color: QuadrimPalette.edge, width: 1.5),
      ),
    ),
    iconButtonTheme: const IconButtonThemeData(
      style: ButtonStyle(
        iconColor: WidgetStatePropertyAll(QuadrimPalette.cream),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: QuadrimPalette.goldDeep,
      textColor: QuadrimPalette.ink,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: QuadrimPalette.parchment,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: QuadrimPalette.edge, width: 1.5),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: QuadrimPalette.parchment,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: QuadrimPalette.panel,
      contentTextStyle: TextStyle(
        fontFamily: QuadrimFonts.body,
        color: QuadrimPalette.cream,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: QuadrimPalette.moss,
      linearTrackColor: QuadrimPalette.parchmentDeep,
    ),
  );

  /// Display faces carry the display serif; everything read in sentences
  /// carries the body one. Cinzel is all-caps by design and unreadable in a
  /// paragraph, which is the whole reason there are two families and not one.
  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(
        fontFamily: QuadrimFonts.display, fontWeight: FontWeight.w700),
    displayMedium: TextStyle(
        fontFamily: QuadrimFonts.display, fontWeight: FontWeight.w700),
    displaySmall: TextStyle(
        fontFamily: QuadrimFonts.display, fontWeight: FontWeight.w700),
    headlineLarge: TextStyle(
        fontFamily: QuadrimFonts.display, fontWeight: FontWeight.w700),
    headlineMedium: TextStyle(
        fontFamily: QuadrimFonts.display, fontWeight: FontWeight.w700),
    headlineSmall: TextStyle(
        fontFamily: QuadrimFonts.display, fontWeight: FontWeight.w700),
    titleLarge: TextStyle(
        fontFamily: QuadrimFonts.display,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6),
    titleMedium: TextStyle(
        fontFamily: QuadrimFonts.display,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5),
    labelLarge: TextStyle(
        fontFamily: QuadrimFonts.display,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8),
    labelMedium: TextStyle(
        fontFamily: QuadrimFonts.display, fontWeight: FontWeight.w700),
    labelSmall: TextStyle(
        fontFamily: QuadrimFonts.display,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4),
    titleSmall: TextStyle(
        fontFamily: QuadrimFonts.body, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontFamily: QuadrimFonts.body),
    bodyMedium: TextStyle(fontFamily: QuadrimFonts.body),
    bodySmall: TextStyle(fontFamily: QuadrimFonts.body),
  );
}
