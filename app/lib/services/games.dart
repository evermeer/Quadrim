/// Play Games Services and Game Center: the leaderboard and the achievements.
///
/// **The offline guarantee changed shape to let this exist** (D376). Spec F13
/// and S1 — no network call during a game against a computer opponent — are
/// still true and still in the specification; nothing here runs during a game.
/// What they lost is their enforcement, because `INTERNET` is granted to an
/// application rather than to a screen and Play Games Services cannot work
/// without it.
///
/// **The app stores no player identifier** (D377). Not the Play Games Player ID,
/// not Game Center's `gamePlayerID`, not a name and not an avatar. Everything
/// these services need is asked for at the moment it is used and thrown away,
/// which is what keeps the amendment to D2/S2 narrow enough not to reach the
/// backup allowlist, the document schema, or 2.0's account model.
library;

import 'dart:async';

import 'package:games_services/games_services.dart' as gs;

import 'achievements.dart';

/// The interface this app owns over the plugin.
///
/// Exists for the same reason [PurchasePlatform] does in `shop/shop.dart`: the
/// part that talks to a store has to be testable without a store in the room,
/// and every one of ticket 050's acceptance criteria is about behaviour on a
/// device nobody can put in a test.
abstract interface class GameServicesPlatform {
  Future<bool> isSignedIn();
  Future<void> signIn();
  Future<void> submitScore({
    required String androidLeaderboardId,
    required String iosLeaderboardId,
    required int value,
  });
  Future<void> unlock({required String androidId, required String iosId});
}

/// The real one. Deliberately thin — everything worth testing is above it.
class GamesServicesPlatformAdapter implements GameServicesPlatform {
  const GamesServicesPlatformAdapter();

  @override
  Future<bool> isSignedIn() => gs.GamesServices.isSignedIn;

  @override
  Future<void> signIn() => gs.GamesServices.signIn();

  @override
  Future<void> submitScore({
    required String androidLeaderboardId,
    required String iosLeaderboardId,
    required int value,
  }) =>
      gs.GamesServices.submitScore(
        score: gs.Score(
          androidLeaderboardID: androidLeaderboardId,
          iOSLeaderboardID: iosLeaderboardId,
          value: value,
        ),
      );

  @override
  Future<void> unlock({required String androidId, required String iosId}) =>
      gs.GamesServices.unlock(
        // `percentComplete: 100` is the default and is what makes this an
        // unlock rather than a progress report: nothing in Quadrim is
        // incremental (D378), so an achievement is true or it is absent.
        achievement: gs.Achievement(androidID: androidId, iOSID: iosId),
      );
}

/// Whether sign-in has been offered, and what the player said.
///
/// Persisted through `SettingsDocument`, because "offered once and never again"
/// is a promise across launches or it is nothing.
enum SignInOffer { notYetOffered, accepted, declined }

/// Reports the rating and the achievements, and never gets in the way.
///
/// **Every call here is best-effort and silent** (ticket 050 §7). No network,
/// no sign-in, a store outage, a player who declined — none of it may produce an
/// error to dismiss, block a game, or delay the end-of-game panel. Nothing in
/// this class may be awaited on a path that renders; the precedent is
/// `Shop.start()`, which is called and deliberately not awaited (D351).
class GameServices {
  /// Private initializing formals. A private named parameter takes its *public*
  /// name at the call site, so callers still write `platform:`,
  /// `androidConfigured:` and `isAndroid:` while the fields stay private.
  GameServices({
    required this._platform,
    this._androidConfigured = false,
    this._isAndroid = false,
  });

  final GameServicesPlatform _platform;

  /// Whether the Play Console has issued its ids yet.
  ///
  /// False on any build where [playGamesConfigured] is false, which is what
  /// stops Android reporting [kPlayGamesIdUnset] into Google Play services and
  /// getting back a failure nobody reads.
  final bool _androidConfigured;

  final bool _isAndroid;

  /// What has already been reported this session.
  ///
  /// The app reports a *diff* — `newlyAchieved` — so a repeat should not happen;
  /// this is the guard for the case where it does. Session-scoped rather than
  /// persisted, because the store is the durable record of what is unlocked and
  /// a second unlock of the same achievement is a no-op there anyway.
  final Set<String> _reported = <String>{};

  bool _available = false;

  /// True once sign-in has been confirmed. Everything else checks it first.
  bool get available => _available;

  /// Whether this build may talk to the platform at all.
  ///
  /// On Android, not until the console ids exist. On iOS the Game Center ids
  /// are ours and are in the catalogue, so there is nothing to wait for.
  bool get _configured => !_isAndroid || _androidConfigured;

  /// Establishes whether there is a signed-in player, without ever asking for
  /// one.
  ///
  /// Called at launch and **not awaited**. A player who has never been offered
  /// sign-in is left alone here; offering is [offerSignIn]'s job and belongs to
  /// a moment the player chose, not to the splash screen.
  Future<void> start() async {
    if (!_configured) return;
    _available = await _guard(() => _platform.isSignedIn()) ?? false;
  }

  /// Offers sign-in once. Returns what to persist.
  ///
  /// **Declining is permanent** (AC 8). The caller stores the answer and never
  /// calls this again, which is why the result is returned rather than kept
  /// here — a decision that must outlive the process belongs in the settings
  /// document, not in a field.
  Future<SignInOffer> offerSignIn() async {
    if (!_configured) return SignInOffer.notYetOffered;
    final ok = await _guard(() async {
      await _platform.signIn();
      return _platform.isSignedIn();
    });
    _available = ok ?? false;
    return _available ? SignInOffer.accepted : SignInOffer.declined;
  }

  /// Submits the computer rating.
  ///
  /// **Only for a game that moved the rating.** Pass-and-play never does (F12),
  /// so the caller does not call this for one — there is nothing to send and a
  /// resubmitted identical score is still a network call.
  Future<void> submitRating(int rating) async {
    if (!_available || !_configured) return;
    await _guard(() => _platform.submitScore(
          androidLeaderboardId: kRatingLeaderboardPlayGamesId,
          iosLeaderboardId: kRatingLeaderboardGameCenterId,
          value: rating,
        ));
  }

  /// Reports the achievements for quests that have just become achieved.
  ///
  /// Takes quest ids rather than `QuestStatus` because the caller already has
  /// the diff: `newlyAchieved` is what the end-of-game panel is built from, and
  /// re-deriving it here would be a second answer that can disagree with the
  /// one on screen.
  ///
  /// A quest with no achievement is skipped in silence — that is every
  /// `first_win_second:*`, all thirty-one of them, and it is D378 working
  /// rather than a gap.
  Future<void> reportQuests(Iterable<String> questIds) async {
    if (!_available || !_configured) return;
    for (final id in questIds) {
      final achievement = achievementForQuest(id);
      if (achievement == null) continue;
      await _unlock(achievement);
    }
  }

  /// Reports the drawn-game achievement.
  ///
  /// **Separate from [reportQuests] because a draw is not a quest** (D386). It
  /// pays no points and claims no rung, so there is no `QuestStatus` to arrive
  /// in the diff the end-of-game panel is built from — the caller decides from
  /// the board instead, which is the only place the fact exists.
  ///
  /// Idempotent within a session like everything else here, and a no-op when
  /// signed out.
  Future<void> reportDraw() async {
    if (!_available || !_configured) return;
    await _unlock(achievementByKey(kDrawAchievementKey));
  }

  /// Unlocks one achievement, at most once per session.
  ///
  /// The app reports a *diff*, so a repeat should not happen; [_reported] is
  /// the guard for the case where it does.
  Future<void> _unlock(Achievement achievement) async {
    if (!_reported.add(achievement.key)) return;
    await _guard(() => _platform.unlock(
          androidId: achievement.playGamesId,
          iosId: achievement.gameCenterId,
        ));
  }

  /// Swallows everything.
  ///
  /// A leaderboard that throws into a game loop would be a worse feature than
  /// no leaderboard, and there is no failure here a player can act on: they
  /// cannot fix a Play services outage and telling them about it only converts
  /// an invisible non-event into a dialog over the board.
  Future<T?> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (_) {
      return null;
    }
  }
}
