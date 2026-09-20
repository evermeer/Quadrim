/// Asking the player to rate the game, at most three times, ever.
///
/// **The platform will not tell you whether they rated** (D389). Apple's
/// `SKStoreReviewController` and Google's In-App Review API both return no
/// success signal, no callback and no way to query rating state — deliberately,
/// so that an app cannot nag or reward based on the answer. Both also *silently
/// do nothing* when over quota: Apple allows roughly three sheets per user per
/// 365 days, and a request past that returns normally having shown nothing.
///
/// So this file never reasons about whether the player rated. It reasons about
/// **when the app last asked**, which is the only fact it has, and it is why
/// "ask again if they did not rate" is implemented as "ask again, three times,
/// then stop".
library;

import 'package:in_app_review/in_app_review.dart' as store;

import '../data/documents.dart';

/// How many times the sheet is ever asked for.
///
/// Three, matching Apple's own annual quota. Past that the platform would drop
/// the request anyway, so a fourth prompt would be state kept to trigger
/// something that does nothing (D389).
const int kMaxReviewPrompts = 3;

/// How long before asking again.
///
/// Ninety days rather than "three months" because months are not a unit a
/// [Duration] has, and the difference between the two readings is at most two
/// days on a prompt that is already deliberately imprecise.
const Duration kReviewPromptInterval = Duration(days: 90);

/// How many finished games before the first ask.
///
/// Seven, so the player has met the ladder rather than the tutorial. The prompt
/// then waits for a win on top of that.
const int kReviewPromptMinGames = 7;

/// The interface this app owns over the plugin.
///
/// Exists for the same reason [PurchasePlatform] and [GameServicesPlatform] do:
/// the decision about when to ask is the part worth testing, and it cannot be
/// tested with a real store sheet in the room.
abstract interface class ReviewPlatform {
  /// Whether the platform is in a position to show the sheet at all. False on
  /// a build that did not come from the store, and on desktop.
  Future<bool> isAvailable();

  /// Asks for the sheet. Returns having told you nothing about what happened.
  Future<void> request();
}

/// The real one.
class StoreReviewPlatform implements ReviewPlatform {
  const StoreReviewPlatform();

  @override
  Future<bool> isAvailable() => store.InAppReview.instance.isAvailable();

  @override
  Future<void> request() => store.InAppReview.instance.requestReview();
}

/// Whether this finished game is the moment to ask.
///
/// A pure function of the stored settings, the game count and the clock, so
/// every rule below is a test rather than an argument. It deliberately takes
/// `now` rather than reading a clock: an ambient one would make the three-month
/// rule untestable, which is the rule most likely to be wrong.
///
/// The caller supplies `won` and `playedCount`; this does not fold the history
/// itself, because the end-of-game path has already folded it and a second fold
/// is a second answer that can disagree with the first.
bool shouldAskForReview({
  required SettingsDocument settings,
  required bool won,
  required int playedCount,
  required DateTime now,
}) {
  // **Only after a win, including the repeats.** The request says "the first
  // win after seven games" for the first prompt and is silent about the later
  // ones, and a rating sheet immediately after a loss is the worst moment the
  // app has to offer. Waiting for the next win costs nothing: the interval is
  // ninety days and a player who never wins again was not going to rate it
  // five stars.
  if (!won) return false;
  if (playedCount < kReviewPromptMinGames) return false;
  if (settings.reviewPromptCount >= kMaxReviewPrompts) return false;

  final last = settings.reviewPromptedAt;
  if (last == null) return true;

  // `isBefore` on the threshold rather than a subtraction, so a clock that has
  // gone backwards -- a device whose time was wrong and got corrected -- simply
  // does not ask, rather than asking every game until the clock catches up.
  return !now.isBefore(last.add(kReviewPromptInterval));
}

/// Asks, and records that it asked.
///
/// **Records the attempt, not the outcome**, and records it even if the
/// platform says it is unavailable or throws. The alternative is a build where
/// the sheet never appears -- a sideloaded one, say -- retrying on every
/// single win forever, and then firing three real prompts in three minutes the
/// day the player installs from the store.
class ReviewPrompt {
  /// A private initializing formal: the call site still writes `platform:`
  /// while the field stays private, which is the same shape [GameServices]
  /// uses.
  ReviewPrompt({required this._platform});

  final ReviewPlatform _platform;


  /// Asks if this is the moment. Returns the settings to persist, or null if
  /// nothing happened and there is nothing to write.
  ///
  /// Never awaited on a path that renders: the precedent is `Shop.start()`
  /// (D351) and `GameServices` (ticket 050 §7). A store sheet is the platform's
  /// to draw and its own to dismiss; this only decides when to ask for one.
  Future<SettingsDocument?> maybeAsk({
    required SettingsDocument settings,
    required bool won,
    required int playedCount,
    required DateTime now,
  }) async {
    if (!shouldAskForReview(
      settings: settings,
      won: won,
      playedCount: playedCount,
      now: now,
    )) {
      return null;
    }

    // Swallows everything, like `GameServices._guard`. There is no failure here
    // a player can act on, and a rating sheet that throws into the end of a
    // game they just won would be a worse feature than no rating sheet.
    try {
      if (await _platform.isAvailable()) {
        await _platform.request();
      }
    } catch (_) {
      // Deliberately empty: see above, and see the note on recording the
      // attempt regardless.
    }

    return settings.copyWith(
      reviewPromptedAt: now,
      reviewPromptCount: settings.reviewPromptCount + 1,
    );
  }
}
