import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrim/services/games.dart';

/// The adapter over `games_services`, against a mocked method channel.
///
/// **This file exists because its absence shipped a broken feature twice**
/// (D393). `game_services_test.dart` fakes [GameServicesPlatform] directly, so
/// it proves everything above the adapter and nothing about the adapter itself
/// — which is the only place the plugin's contract lives. That contract is the
/// whole defect: `games_services` returns a **string on success** and **throws
/// on failure**, and the code here once read a non-empty string as a refusal,
/// turning every successful sign-in and every native view that actually opened
/// into "Game Center is unavailable".
///
/// The strings below are the plugin's own, read out of `games_services` 5.3.0:
/// `Messages.success`, `Messages.alreadyAuthenticated` and
/// `Messages.authenticatedSuccessfully`. If a future version stops returning
/// them these tests keep passing — they pin *this app's reading* of the
/// contract, not the plugin — so the version is named here and in the pubspec.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('games_services');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  /// The calls the adapter made, in order.
  late List<MethodCall> calls;

  /// Answers every method with [reply], or throws [error] if one is given.
  void mock({Object? reply, PlatformException? error}) {
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (error != null) throw error;
      return reply;
    });
  }

  setUp(() => calls = <MethodCall>[]);
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  const adapter = GamesServicesPlatformAdapter();

  group('a success string is a success, not a refusal', () {
    test('"Success" from showLeaderboards does not throw', () async {
      // The exact defect: this string used to raise, `_guard` swallowed it, and
      // a leaderboard that had just opened was reported as unavailable.
      mock(reply: 'Success');
      await expectLater(
        adapter.showLeaderboard(
            androidLeaderboardId: 'android', iosLeaderboardId: 'ios'),
        completes,
      );
      expect(calls.single.method, 'showLeaderboards');
    });

    test('"Success" from showAchievements does not throw', () async {
      mock(reply: 'Success');
      await expectLater(adapter.showAchievements(), completes);
      expect(calls.single.method, 'showAchievements');
    });

    test('both of signIn\'s success strings are successes', () async {
      // Two, because GameKit answers differently depending on whether the
      // player had to be asked. Reading either as a failure is the bug.
      for (final reply in const [
        'Player authenticated successfully',
        'Player already authenticated',
      ]) {
        calls = <MethodCall>[];
        mock(reply: reply);
        await expectLater(adapter.signIn(), completes, reason: reply);
        expect(calls.single.method, 'signIn', reason: reply);
      }
    });

    test('a null reply is a success too', () async {
      // Android's half of the plugin returns nothing at all on success. A
      // reading that keyed on "non-empty means trouble" got this one right by
      // accident, which is how it survived review.
      mock(reply: null);
      await expectLater(adapter.showAchievements(), completes);
    });
  });

  group('a throw is the failure signal', () {
    test('showLeaderboards surfaces the platform exception', () async {
      // `error.flutterError(code:)` on the Swift side arrives here as this.
      // The caller's `_guard` is what turns it into "nothing opened" — so it
      // has to arrive as a throw, and the adapter must not swallow it.
      mock(error: PlatformException(code: 'leaderboard_not_found'));
      await expectLater(
        adapter.showLeaderboard(
            androidLeaderboardId: 'android', iosLeaderboardId: 'ios'),
        throwsA(isA<PlatformException>()),
      );
    });

    test('showAchievements surfaces the platform exception', () async {
      mock(error: PlatformException(code: 'failed_to_show_achievements'));
      await expectLater(
        adapter.showAchievements(),
        throwsA(isA<PlatformException>()),
      );
    });

    test('signIn surfaces the platform exception', () async {
      // `signInUnavailable` is what the plugin returns once its authenticate
      // handler has been set and the player is still not signed in — Game
      // Center switched off in Settings, which no retry in the app can fix.
      mock(error: PlatformException(code: 'sign_in_unavailable'));
      await expectLater(
        adapter.signIn(),
        throwsA(isA<PlatformException>()),
      );
    });
  });

  group('what the adapter sends', () {
    // **The plugin picks the platform's id in Dart, not in Swift or Kotlin**,
    // and sends one `leaderboardID` / `achievementID`. So what reaches the
    // channel is whichever of the two the host resolves to — which is what
    // makes these assertions catch a swapped pair rather than restate it: on
    // this test host `Platform.isAndroid` is false, so the Game Center id must
    // arrive and the Play Games one must not. That matters more here than in
    // most apps, because the Play Games ids are still `UNSET` (D390) and
    // sending one to Game Center would fail silently.
    String expectedId(String android, String ios) =>
        Platform.isAndroid ? android : ios;

    test('a score carries the platform id and the value', () async {
      mock(reply: 'Success');
      await adapter.submitScore(
        androidLeaderboardId: 'play.board',
        iosLeaderboardId: 'gc.board',
        value: 1234,
      );
      final sent = calls.single;
      expect(sent.method, 'submitScore');
      final args = sent.arguments as Map;
      expect(args['leaderboardID'], expectedId('play.board', 'gc.board'));
      expect(args['value'], 1234);
    });

    test('an unlock carries the platform id, complete rather than partial',
        () async {
      // 100% is what makes this an unlock rather than a progress report.
      // Nothing in Quadrim is incremental (D378), so a value below 100 here
      // would leave every achievement permanently half-earned.
      mock(reply: 'Success');
      await adapter.unlock(androidId: 'play.beat', iosId: 'gc.beat');
      final sent = calls.single;
      expect(sent.method, 'unlock');
      final args = sent.arguments as Map;
      expect(args['achievementID'], expectedId('play.beat', 'gc.beat'));
      expect(args['percentComplete'], 100);
    });

    test('a failed submission still throws rather than reporting success',
        () async {
      // These two never went through the inverted reading, so they were the
      // only calls that worked. They are pinned here so a later tidy-up that
      // gives them the same treatment cannot quietly repeat D391.
      mock(error: PlatformException(code: 'failed_to_send_score'));
      await expectLater(
        adapter.submitScore(
            androidLeaderboardId: 'a', iosLeaderboardId: 'i', value: 1),
        throwsA(isA<PlatformException>()),
      );
    });
  });
}
