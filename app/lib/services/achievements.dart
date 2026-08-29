/// The forty-four achievements, and what each one is called on each store.
///
/// **Forty-four of seventy-five quests, and the narrowing is deliberate**
/// (D378). Eight streak rungs, five volume rungs, and one per opponent — with
/// [QuestFamily.firstWin] and [QuestFamily.firstWinSecond] collapsed into a
/// single "you have beaten this opponent", because the second is a strict
/// subset of the first: a win from the second seat is a win, so the two would
/// unlock in the same instant on the same game and read as a bug.
///
/// Game Center allows 100 achievements per app, so 44 leaves sixteen spare.
/// **A roster past about forty-seven breaks that cap**, and an achievement
/// cannot be deleted after publication on either store any more than a product
/// id can (D213, D365).
library;

import 'package:quadrim_engine/quadrim_engine.dart';
import 'package:quadrim_progression/quadrim_progression.dart';

/// One achievement, and the two ids the stores know it by.
class Achievement {
  const Achievement({
    required this.key,
    required this.questId,
    required this.gameCenterId,
    required this.playGamesId,
  });

  /// Stable within Quadrim, and the only id anything outside this file uses.
  ///
  /// The two store ids are data that belongs to the stores; code that reports
  /// an achievement names it by [key] and lets the platform adapter translate.
  final String key;

  /// The quest whose achievement fires this, by [Quest.id].
  ///
  /// One quest, never a set: the merge in D378 works because the *harder* of
  /// the two per-opponent quests is dropped rather than or-ed in, so there is
  /// no rule here about which of several sources counts.
  final String questId;

  /// Ours to choose, and permanent once published. Reverse-DNS on the iOS
  /// bundle identifier, which is `nl.evict.quadrim2` and not the Android one
  /// (D359) — the same divergence the StoreKit product ids follow (D365).
  final String gameCenterId;

  /// **Issued by the Play Console and not knowable from here.** Every entry
  /// below carries [kPlayGamesIdUnset] until the achievements are created and
  /// the ids pasted in; [playGamesConfigured] is what the app asks before it
  /// reports anything on Android.
  final String playGamesId;
}

/// What a Play Games id says while the console has not issued one.
///
/// A sentinel rather than an empty string or a null: an empty id would be
/// reported to the plugin and fail somewhere inside Google Play services, and
/// the failure would arrive as a log line nobody reads. This fails in Dart, at
/// a place with a name.
const String kPlayGamesIdUnset = 'UNSET';

/// The leaderboard, on each store. One board: the computer rating.
///
/// Not verifiable, and nothing may describe it as a ranking of skill — the
/// rating is a fold computed on the device with no server anywhere in the
/// design, so a modified build can submit any number (ticket 050 §3).
const String kRatingLeaderboardGameCenterId = 'nl.evict.quadrim2.rating';
const String kRatingLeaderboardPlayGamesId = kPlayGamesIdUnset;

String _gc(String suffix) => 'nl.evict.quadrim2.$suffix';

/// Every achievement, built from the same catalogues the quests are built from.
///
/// **Derived rather than typed out**, so the roster and the rungs cannot drift
/// from the quest catalogue they mirror. What is hand-written is only the part
/// that is genuinely external: the store ids.
final List<Achievement> achievementCatalogue = [
  for (final bot in opponentCatalogue)
    Achievement(
      key: 'beat:${bot.id}',
      questId: 'first_win:${bot.id}',
      gameCenterId: _gc('beat.${bot.id}'),
      playGamesId: kPlayGamesIdUnset,
    ),
  for (final target in kVolumeAchievementTargets)
    Achievement(
      key: 'games_in_day:$target',
      questId: 'games_in_day:$target',
      gameCenterId: _gc('games_in_day.$target'),
      playGamesId: kPlayGamesIdUnset,
    ),
  for (final target in kStreakAchievementTargets)
    Achievement(
      key: 'days_in_row:$target',
      questId: 'days_in_row:$target',
      gameCenterId: _gc('days_in_row.$target'),
      playGamesId: kPlayGamesIdUnset,
    ),
];

/// The volume rungs, as ticket 033 set them: 5, 10, 20, 50, 100 games in a day.
///
/// Repeated here rather than imported because `quadrim_progression` does not
/// export them, and a mismatch is caught by the completeness test rather than
/// by trust — every entry above must name a quest that exists.
const List<int> kVolumeAchievementTargets = [5, 10, 20, 50, 100];

/// The streak rungs, as ticket 034 set them.
const List<int> kStreakAchievementTargets = [5, 10, 30, 90, 180, 360, 720, 1440];

/// The achievement a quest maps to, or null if that quest has none.
///
/// Null is the normal answer for `first_win_second:*` — all thirty-one of them
/// — and that is D378 working rather than a gap.
Achievement? achievementForQuest(String questId) {
  for (final a in achievementCatalogue) {
    if (a.questId == questId) return a;
  }
  return null;
}

/// Whether the Play Console's ids have been filled in.
///
/// False on any build where they have not, which is what stops Android from
/// reporting a sentinel to Google Play services.
bool get playGamesConfigured =>
    kRatingLeaderboardPlayGamesId != kPlayGamesIdUnset &&
    achievementCatalogue.every((a) => a.playGamesId != kPlayGamesIdUnset);
