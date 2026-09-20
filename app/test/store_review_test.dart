import 'package:flutter_test/flutter_test.dart';
import 'package:quadrim/data/documents.dart';
import 'package:quadrim/services/review.dart';

/// D389: when the app asks the player to rate it.
///
/// **Every rule here is a rule about time or counting, and none of them can be
/// observed on a device.** The store sheet reports nothing back — not whether
/// it appeared, not what the player did — so there is no integration test that
/// could stand in for these. The decision function is deliberately pure so that
/// the rules are assertions rather than arguments.
class FakeReviewPlatform implements ReviewPlatform {
  FakeReviewPlatform({this.available = true, this.throws = false});

  final bool available;
  final bool throws;
  int requests = 0;

  @override
  Future<bool> isAvailable() async {
    if (throws) throw StateError('no store here');
    return available;
  }

  @override
  Future<void> request() async {
    if (throws) throw StateError('no store here');
    requests++;
  }
}

void main() {
  final day0 = DateTime.utc(2026, 1, 1);
  const fresh = SettingsDocument();

  SettingsDocument asked(DateTime when, {int count = 1}) =>
      SettingsDocument(reviewPromptedAt: when, reviewPromptCount: count);

  group('when to ask', () {
    test('not before seven games, even on a win', () {
      for (var played = 0; played < kReviewPromptMinGames; played++) {
        expect(
          shouldAskForReview(
              settings: fresh, won: true, playedCount: played, now: day0),
          isFalse,
          reason: 'asked after only $played games',
        );
      }
    });

    test('on the first win once seven are played', () {
      expect(
        shouldAskForReview(
            settings: fresh,
            won: true,
            playedCount: kReviewPromptMinGames,
            now: day0),
        isTrue,
      );
    });

    /// The half that would not fail on its own. Seven games played and a loss
    /// is the common case, and a rating sheet is the last thing that moment
    /// wants.
    test('never on a loss or a draw, however many games are played', () {
      expect(
        shouldAskForReview(
            settings: fresh, won: false, playedCount: 200, now: day0),
        isFalse,
      );
    });

    test('not again the day after', () {
      expect(
        shouldAskForReview(
          settings: asked(day0),
          won: true,
          playedCount: 50,
          now: day0.add(const Duration(days: 1)),
        ),
        isFalse,
      );
    });

    /// The boundary, from both sides. One day short is the case a `>` instead
    /// of a `>=` gets wrong, and it would take ninety days to notice.
    test('again once the interval has passed, and not a day before', () {
      final settings = asked(day0);
      final justShort = day0.add(kReviewPromptInterval - const Duration(days: 1));
      final exactly = day0.add(kReviewPromptInterval);

      expect(
        shouldAskForReview(
            settings: settings, won: true, playedCount: 50, now: justShort),
        isFalse,
      );
      expect(
        shouldAskForReview(
            settings: settings, won: true, playedCount: 50, now: exactly),
        isTrue,
      );
    });

    test('three times and never again', () {
      final settings = asked(day0, count: kMaxReviewPrompts);
      expect(
        shouldAskForReview(
          settings: settings,
          won: true,
          playedCount: 500,
          now: day0.add(const Duration(days: 3650)),
        ),
        isFalse,
        reason: 'a fourth prompt ten years later is still a fourth prompt',
      );
    });

    /// A device whose clock was wrong and then corrected reads as "the last
    /// prompt is in the future". The safe answer is silence: the alternative is
    /// asking on every single win until the clock catches up.
    test('says no when the clock has gone backwards', () {
      expect(
        shouldAskForReview(
          settings: asked(day0.add(const Duration(days: 400))),
          won: true,
          playedCount: 50,
          now: day0,
        ),
        isFalse,
      );
    });
  });

  group('asking', () {
    test('asks the platform and returns the settings to store', () async {
      final platform = FakeReviewPlatform();
      final updated = await ReviewPrompt(platform: platform).maybeAsk(
        settings: fresh,
        won: true,
        playedCount: 10,
        now: day0,
      );

      expect(platform.requests, 1);
      expect(updated, isNotNull);
      expect(updated!.reviewPromptCount, 1);
      expect(updated.reviewPromptedAt, day0);
    });

    test('returns null and asks nothing when it is not the moment', () async {
      final platform = FakeReviewPlatform();
      final updated = await ReviewPrompt(platform: platform).maybeAsk(
        settings: fresh,
        won: false,
        playedCount: 10,
        now: day0,
      );

      expect(platform.requests, 0);
      expect(updated, isNull, reason: 'nothing happened, so nothing to write');
    });

    /// **The one that stops a sideloaded build burning all three prompts.**
    /// `isAvailable` is false off-store, and if that returned null the counter
    /// would never move -- so every win would retry, and the day the player
    /// installed from the store they would get three sheets in three minutes.
    test('still records the attempt when the platform is unavailable',
        () async {
      final platform = FakeReviewPlatform(available: false);
      final updated = await ReviewPrompt(platform: platform).maybeAsk(
        settings: fresh,
        won: true,
        playedCount: 10,
        now: day0,
      );

      expect(platform.requests, 0);
      expect(updated?.reviewPromptCount, 1);
    });

    test('still records the attempt when the platform throws', () async {
      final platform = FakeReviewPlatform(throws: true);
      final updated = await ReviewPrompt(platform: platform).maybeAsk(
        settings: fresh,
        won: true,
        playedCount: 10,
        now: day0,
      );

      expect(updated?.reviewPromptCount, 1);
    });

    /// End to end over the rule set: three prompts ninety days apart, then
    /// silence forever. Written as a loop over real dates because the bug this
    /// catches -- a count that does not increment, an interval measured from
    /// the wrong end -- only shows up on the third pass.
    test('asks three times across a year and then stops', () async {
      final platform = FakeReviewPlatform();
      final prompt = ReviewPrompt(platform: platform);
      var settings = fresh;
      var day = day0;

      for (var i = 0; i < 8; i++) {
        final updated = await prompt.maybeAsk(
          settings: settings,
          won: true,
          playedCount: 50,
          now: day,
        );
        if (updated != null) settings = updated;
        day = day.add(const Duration(days: 60));
      }

      expect(platform.requests, kMaxReviewPrompts);
      expect(settings.reviewPromptCount, kMaxReviewPrompts);
    });
  });

  group('the stored fields', () {
    test('survive a round trip', () {
      final settings = asked(day0, count: 2);
      final back = SettingsDocument.fromJson(settings.toJson());

      expect(back!.reviewPromptCount, 2);
      expect(back.reviewPromptedAt, day0);
    });

    /// An existing player's settings document has neither field. They must read
    /// as "never asked" -- the opposite default to `tutorialOffered`'s, because
    /// defaulting to *already prompted* would silently deny the prompt to every
    /// player who upgrades, who are the people most likely to rate it.
    test('read as never-asked when absent', () {
      final old = {
        'schemaVersion': kSchemaVersion,
        'locale': 'system',
        'theme': 'system',
        'tutorialCompleted': true,
        'tutorialOffered': true,
      };
      final back = SettingsDocument.fromJson(old);

      expect(back!.reviewPromptCount, 0);
      expect(back.reviewPromptedAt, isNull);
      expect(
        shouldAskForReview(
            settings: back, won: true, playedCount: 50, now: day0),
        isTrue,
      );
    });

    /// `copyWith` must not be able to hand someone the prompt again from the
    /// beginning, the same rule `freeMonthStartedAt` follows.
    test('copyWith cannot clear them', () {
      final settings = asked(day0, count: 3);
      final same = settings.copyWith(locale: 'nl');

      expect(same.reviewPromptCount, 3);
      expect(same.reviewPromptedAt, day0);
    });
  });
}
