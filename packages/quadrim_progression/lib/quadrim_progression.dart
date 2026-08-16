/// Quadrim progression: points, unlock costs, quests and streaks — and, from
/// ticket 045, the meter.
///
/// The meter is commerce rather than progression and the name of this package
/// is now slightly wrong. It lives here because it is a fold over games with an
/// injected day boundary, which is precisely what `streaks.dart` already is; a
/// fourth package would earn its own purity scan, pubspec and CI entry for a
/// hundred lines of arithmetic (D308).
///
/// Pure Dart. No Flutter, no Firebase, no `dart:io`, **no ambient clock and no
/// ambient random source**; `tool/check.sh` enforces all of it. The clock
/// matters here more than in the other two packages, because streak evaluation
/// genuinely needs a calendar: the day boundary is passed in, never read
/// (spec §9.2, §10.3).
///
/// Not part of `quadrim_engine`, by the engine's own rule. Spec §7.1 says the
/// catalogue carries no `locked` field, because the strength harness plays all
/// twenty opponents against each other and has no business holding an
/// entitlement. Arithmetic about what a player owns and what it cost sits on
/// the other side of that line (D263).
///
/// **No function here takes the player's rating or their current rung**, and
/// that is the type system carrying a product rule rather than a comment doing
/// it. Pricing a reward by how high the player has climbed broke the economy
/// twice, in opposite directions: it let the cheap per-opponent quests be
/// banked until they paid twice the cost of the whole roster, and it made a
/// hundred instant Pebble games in a day pay four Titan wins (D261, D270).
library;

export 'src/meter.dart';
export 'src/points.dart';
export 'src/quests.dart';
export 'src/streaks.dart';
export 'src/unlocks.dart';
