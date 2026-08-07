import 'package:flutter/material.dart';

/// Nocturne-derived theme tokens (doc/design_system/styles.css).
/// Light theme is not designed yet (FirstRunHandoff §3); it uses the same
/// seed so it exists and follows the system, and gets real attention in
/// ticket 021's audit.
abstract final class QuadrimTheme {
  static const _accent = Color(0xFF9184D9);
  static const _darkBg = Color(0xFF161826);
  static const _darkSurface = Color(0xFF232532);
  static const _darkText = Color(0xFFE9E9ED);

  static final ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _accent,
      brightness: Brightness.dark,
      surface: _darkSurface,
    ),
    scaffoldBackgroundColor: _darkBg,
    textTheme: Typography.whiteMountainView.apply(
      bodyColor: _darkText,
      displayColor: _darkText,
    ),
  );

  static final ThemeData light = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(seedColor: _accent),
  );
}
