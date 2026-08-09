/// Quadrim game engine: board state, the 76 winning lines, legal moves,
/// win and threat detection, and the computer opponents.
///
/// This package is pure Dart. It must never import Flutter, Firebase,
/// `dart:io`, an ambient clock, or an ambient random source — tool/check.sh
/// enforces this.
library;

export 'src/bot.dart';
export 'src/engine.dart';
export 'src/search.dart';
export 'src/strategy_book.dart';
export 'src/symmetry.dart';
export 'src/transposition.dart';
export 'src/winning_lines.g.dart';
