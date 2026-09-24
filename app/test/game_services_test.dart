import 'package:flutter_test/flutter_test.dart';
import 'package:quadrim_engine/quadrim_engine.dart';
import 'package:quadrim_progression/quadrim_progression.dart';

import 'package:quadrim/services/achievements.dart';
import 'package:quadrim/services/games.dart';

/// Ticket 050: the leaderboard and the achievements.
///
/// Everything here runs against [FakeGameServices] rather than a store, for the
/// reason `shop_test.dart` gives about purchases: the part that can only be
/// exercised on a device is exactly the part that must not be the only thing
/// standing between a defect and a release.
class FakeGameServices implements GameServicesPlatform {
  FakeGameServices({this.signedIn = true, this.throws = false});

  bool signedIn;

  /// Every method fails. Models a store outage, a missing Play services, and a
  /// player who revoked consent — all of which look the same from here.
  bool throws;

  final List<int> scores = [];
  final List<String> unlockedAndroid = [];
  final List<String> unlockedIos = [];
  int signInCalls = 0;
  int leaderboardsShown = 0;
  int achievementsShown = 0;

  @override
  Future<bool> isSignedIn() async {
    if (throws) throw StateError('unavailable');
    return signedIn;
  }

  @override
  Future<void> signIn() async {
    signInCalls++;
    if (throws) throw StateError('unavailable');
    signedIn = true;
  }

  @override
  Future<void> submitScore({
    required String androidLeaderboardId,
    required String iosLeaderboardId,
    required int value,
  }) async {
    if (throws) throw StateError('unavailable');
    scores.add(value);
  }

  @override
  Future<void> unlock({
    required String androidId,
    required String iosId,
  }) async {
    if (throws) throw StateError('unavailable');
    unlockedAndroid.add(androidId);
    unlockedIos.add(iosId);
  }

  @override
  Future<void> showLeaderboard({
    required String androidLeaderboardId,
    required String iosLeaderboardId,
  }) async {
    if (throws) throw StateError('unavailable');
    leaderboardsShown++;
  }

  @override
  Future<void> showAchievements() async {
    if (throws) throw StateError('unavailable');
    achievementsShown++;
  }
}

void main() {
  group('the catalogue', () {
    test('is forty-six: one per opponent, five volume, nine streak, one draw',
        () {
      expect(achievementCatalogue, hasLength(46));
      expect(
        achievementCatalogue.where((a) => a.key.startsWith('beat:')),
        hasLength(opponentCatalogue.length),
      );
      expect(
        achievementCatalogue.where((a) => a.key.startsWith('games_in_day:')),
        hasLength(5),
      );
      expect(
        achievementCatalogue.where((a) => a.key.startsWith('days_in_row:')),
        hasLength(9),
      );
      // The forty-sixth, and the only one with no quest behind it (D386).
      expect(
        achievementCatalogue.where((a) => a.key == kDrawAchievementKey),
        hasLength(1),
      );
    });

    /// AC 5, and it is asserted in **both** directions on purpose. A table that
    /// names a quest which no longer exists reports an achievement nobody can
    /// earn; a quest family that quietly grows leaves achievements unmapped.
    /// Only one of those is visible without this test.
    test('every entry that names a quest names one that exists', () {
      final questIds = questCatalogue.map((q) => q.id).toSet();
      for (final a in achievementCatalogue) {
        if (a.questId == null) continue;
        expect(questIds, contains(a.questId),
            reason: '${a.key} maps to a quest that is not in the catalogue');
      }
    });

    /// **Exactly one**, and the assertion is on the count rather than on the
    /// draw entry alone. A null `questId` is an achievement nothing in the
    /// quest machinery will ever fire, so it has to be reported by hand from
    /// the place that knows -- and a second one appearing here without a
    /// caller would be an achievement that silently never unlocks (D386).
    test('exactly one achievement has no quest behind it', () {
      final questless =
          achievementCatalogue.where((a) => a.questId == null).toList();
      expect(questless, hasLength(1));
      expect(questless.single.key, kDrawAchievementKey);
    });

    /// The id was published before the code existed, and an achievement id is
    /// as permanent as a product id (D213, D365). This is what stops anyone
    /// renaming it to match the `draw` the rest of the code says.
    test('the draw achievement keeps the published tie id', () {
      expect(achievementByKey(kDrawAchievementKey).gameCenterId,
          'nl.evict.quadrim2.tie');
    });

    test('every quest except first_win_second maps to an achievement', () {
      final unmapped = questCatalogue
          .map((q) => q.id)
          .where((id) => achievementForQuest(id) == null)
          .toList();
      expect(
        unmapped.every((id) => id.startsWith('first_win_second:')),
        isTrue,
        reason: 'unmapped quests other than the merged family: '
            '${unmapped.where((i) => !i.startsWith("first_win_second:"))}',
      );
      // AC 4: all thirty-one of them, and no fewer -- if the merge ever stops
      // happening this is what says so.
      expect(unmapped, hasLength(opponentCatalogue.length));
    });

    test('keys and store ids are unique', () {
      expect(achievementCatalogue.map((a) => a.key).toSet(), hasLength(46));
      expect(
        achievementCatalogue.map((a) => a.gameCenterId).toSet(),
        hasLength(46),
      );
    });

    /// The Game Center ids follow the **iOS** bundle identifier, which is
    /// `nl.evict.quadrim2` and not the Android one (D359, D365).
    test('Game Center ids are built on the iOS bundle identifier', () {
      for (final a in achievementCatalogue) {
        expect(a.gameCenterId, startsWith('nl.evict.quadrim2.'));
      }
      expect(kRatingLeaderboardGameCenterId, startsWith('nl.evict.quadrim2.'));
    });

    /// Fails the day the console ids are pasted in, which is the point: it is
    /// the reminder that Android reporting is off until they are.
    test('the Play Games ids are still unset, so Android stays quiet', () {
      expect(playGamesConfigured, isFalse);
    });
  });

  group('launch', () {
    /// **The defect that made a returning player invisible** (D393).
    ///
    /// On iOS `isSignedIn` reads `GKLocalPlayer.isAuthenticated`, which stays
    /// false until something sets the authenticate handler — and only `signIn`
    /// does. Asking alone therefore answered "no" on every launch however long
    /// the player had been signed in, so their wins went unreported until they
    /// happened to tap a Game Center button in that same session.
    test('re-authenticates a player who already accepted', () async {
      // Signed out from this end's point of view, exactly as GameKit reports
      // an authenticated player before the handler is set.
      final fake = FakeGameServices(signedIn: false);
      final services = GameServices(platform: fake);
      await services.start(previouslyAccepted: true);

      expect(fake.signInCalls, 1);
      expect(services.available, isTrue);
    });

    /// D390 stands: the splash screen never asks anybody anything.
    test('asks nothing of a player who has not accepted', () async {
      final fake = FakeGameServices(signedIn: false);
      final services = GameServices(platform: fake);
      await services.start();

      expect(fake.signInCalls, 0,
          reason: 'a player who declined, or was never asked, is left alone');
      expect(services.available, isFalse);
    });

    test('a refusal at launch is silent and leaves the app signed out',
        () async {
      final fake = FakeGameServices(signedIn: false, throws: true);
      final services = GameServices(platform: fake);
      await expectLater(
          services.start(previouslyAccepted: true), completes);
      expect(services.available, isFalse);
    });
  });

  group('the backfill', () {
    /// **Not gated on the tap that signed the player in** (D393). It used to
    /// fire only on the signed-out → opened transition, which is the one moment
    /// it cannot fire once launch re-authenticates: a returning player is
    /// already available when the first tap arrives, so the transition never
    /// happens and their history was never sent.
    test('sends what was already earned to a player signed in at launch',
        () async {
      final fake = FakeGameServices();
      final services = GameServices(platform: fake);
      await services.start(previouslyAccepted: true);

      await services.backfill(['first_win:pebble', 'first_win:twig']);
      expect(fake.unlockedIos, hasLength(2));
    });

    test('runs once a session, however often it is called', () async {
      // The panel refolds after every finished game and calls this each time.
      final fake = FakeGameServices();
      final services = GameServices(platform: fake);
      await services.start();

      await services.backfill(['first_win:pebble']);
      await services.backfill(['first_win:pebble', 'first_win:twig']);
      expect(fake.unlockedIos, hasLength(1),
          reason: 'the second call must not send forty-six more unlocks');
    });

    test('sends nothing when there is no signed-in player', () async {
      final fake = FakeGameServices(signedIn: false);
      final services = GameServices(platform: fake);
      await services.start();

      await services.backfill(['first_win:pebble']);
      expect(fake.unlockedIos, isEmpty);
    });

    test('a signed-out backfill does not spend the one attempt', () async {
      // Otherwise the call the home screen makes before `start()` has
      // finished would burn the session's only backfill.
      final fake = FakeGameServices(signedIn: false);
      final services = GameServices(platform: fake);
      await services.start();
      await services.backfill(['first_win:pebble']);

      await services.start(previouslyAccepted: true);
      await services.backfill(['first_win:pebble']);
      expect(fake.unlockedIos, hasLength(1));
    });
  });

  group('the leaderboard', () {
    test('submits the rating when signed in', () async {
      final fake = FakeGameServices();
      final services = GameServices(platform: fake);
      await services.start();
      await services.submitRating(1234);
      expect(fake.scores, [1234]);
    });

    test('submits nothing when signed out', () async {
      final fake = FakeGameServices(signedIn: false);
      final services = GameServices(platform: fake);
      await services.start();
      await services.submitRating(1234);
      expect(fake.scores, isEmpty);
    });

    /// AC 6. The store is down and the game must not notice.
    test('submits nothing, and throws nothing, when the platform fails',
        () async {
      final fake = FakeGameServices(throws: true);
      final services = GameServices(platform: fake);
      await services.start();
      await services.submitRating(1234);
      expect(fake.scores, isEmpty);
      expect(services.available, isFalse);
    });
  });

  group('the achievements', () {
    test('a newly achieved quest reports its one achievement', () async {
      final fake = FakeGameServices();
      final services = GameServices(platform: fake);
      await services.start();
      await services.reportQuests(['first_win:pebble']);
      expect(fake.unlockedIos, ['nl.evict.quadrim2.beat.pebble']);
    });

    /// AC 4, at the level that matters: the merged family reports nothing of
    /// its own, so a player who wins from the second seat sees one badge and
    /// not two firing on the same game.
    test('first_win_second reports nothing', () async {
      final fake = FakeGameServices();
      final services = GameServices(platform: fake);
      await services.start();
      await services.reportQuests(['first_win_second:pebble']);
      expect(fake.unlockedIos, isEmpty);
    });

    test('a quest reported twice unlocks once', () async {
      final fake = FakeGameServices();
      final services = GameServices(platform: fake);
      await services.start();
      await services.reportQuests(['first_win:pebble']);
      await services.reportQuests(['first_win:pebble']);
      expect(fake.unlockedIos, hasLength(1));
    });

    test('a batch reports each of its mapped quests', () async {
      final fake = FakeGameServices();
      final services = GameServices(platform: fake);
      await services.start();
      await services.reportQuests([
        'first_win:pebble',
        'first_win_second:pebble',
        'games_in_day:5',
        'days_in_row:5',
      ]);
      expect(fake.unlockedIos, [
        'nl.evict.quadrim2.beat.pebble',
        'nl.evict.quadrim2.games_in_day.5',
        'nl.evict.quadrim2.days_in_row.5',
      ]);
    });

    /// A draw reaches the store through its own call because it is not a
    /// quest (D386): it pays no points and claims no rung, so it never appears
    /// in the `newlyAchieved` diff `reportQuests` is given.
    test('a draw reports the tie achievement', () async {
      final fake = FakeGameServices();
      final services = GameServices(platform: fake);
      await services.start();
      await services.reportDraw();
      expect(fake.unlockedIos, ['nl.evict.quadrim2.tie']);
    });

    test('a draw reported twice unlocks once', () async {
      final fake = FakeGameServices();
      final services = GameServices(platform: fake);
      await services.start();
      await services.reportDraw();
      await services.reportDraw();
      expect(fake.unlockedIos, hasLength(1));
    });

    test('a draw reports nothing when signed out', () async {
      final fake = FakeGameServices(signedIn: false);
      final services = GameServices(platform: fake);
      await services.start();
      await services.reportDraw();
      expect(fake.unlockedIos, isEmpty);
    });

    /// Reporting a quest must not consume the draw's slot in `_reported`, nor
    /// the other way round. They share one set, so a key collision would show
    /// up as an achievement that silently never unlocks.
    test('a draw and a quest in the same session both unlock', () async {
      final fake = FakeGameServices();
      final services = GameServices(platform: fake);
      await services.start();
      await services.reportQuests(['first_win:pebble']);
      await services.reportDraw();
      expect(fake.unlockedIos, [
        'nl.evict.quadrim2.beat.pebble',
        'nl.evict.quadrim2.tie',
      ]);
    });

    test('reports nothing when signed out', () async {
      final fake = FakeGameServices(signedIn: false);
      final services = GameServices(platform: fake);
      await services.start();
      await services.reportQuests(['first_win:pebble']);
      expect(fake.unlockedIos, isEmpty);
    });

    test('an unknown quest id is ignored rather than thrown at', () async {
      final fake = FakeGameServices();
      final services = GameServices(platform: fake);
      await services.start();
      await services.reportQuests(['no_such_quest:ever']);
      expect(fake.unlockedIos, isEmpty);
    });
  });

  group('Android before the console ids exist', () {
    /// The whole point of [kPlayGamesIdUnset]: an unset id must never reach
    /// Google Play services, where it fails as a log line nobody reads.
    test('does nothing at all until the Play ids are filled in', () async {
      final fake = FakeGameServices();
      final services =
          GameServices(platform: fake, isAndroid: true, androidConfigured: false);
      await services.start();
      await services.submitRating(1234);
      await services.reportQuests(['first_win:pebble']);
      expect(fake.scores, isEmpty);
      expect(fake.unlockedAndroid, isEmpty);
      expect(services.available, isFalse);
    });

    test('works once they are', () async {
      final fake = FakeGameServices();
      final services =
          GameServices(platform: fake, isAndroid: true, androidConfigured: true);
      await services.start();
      await services.submitRating(1234);
      expect(fake.scores, [1234]);
    });
  });

  group('opening the native views', () {
    test('a signed-in player goes straight to the leaderboard', () async {
      final fake = FakeGameServices();
      final services = GameServices(platform: fake);
      await services.start();

      final opened = await services.openLeaderboard();

      expect(fake.leaderboardsShown, 1);
      expect(fake.signInCalls, 0, reason: 'already signed in');
      expect(opened, isTrue);
    });

    /// **The tap is how a signed-out player signs in** (D390). Making them find
    /// a separate control first is a worse answer than doing it for them.
    test('a signed-out player is signed in by the tap, then shown', () async {
      final fake = FakeGameServices(signedIn: false);
      final services = GameServices(platform: fake);
      await services.start();
      expect(services.available, isFalse);

      final opened = await services.openAchievements();

      expect(fake.signInCalls, 1);
      expect(fake.achievementsShown, 1);
      expect(opened, isTrue);
    });

    /// Nothing to show and nothing to throw. A native view opened without a
    /// player is the failure this avoids.
    test('a refused sign-in shows nothing and says so', () async {
      final fake = FakeGameServices(signedIn: false, throws: true);
      final services = GameServices(platform: fake);
      await services.start();

      final opened = await services.openLeaderboard();

      expect(fake.leaderboardsShown, 0);
      // **Not recorded as a decline** (D391): the caller gets a fact about
      // whether a view opened, not an answer to store on the player's behalf.
      expect(opened, isFalse);
    });

    test('a throwing platform changes nothing and raises nothing', () async {
      final fake = FakeGameServices(throws: true);
      final services = GameServices(platform: fake);
      await services.start();

      await expectLater(services.openLeaderboard(), completes);
    });

    /// **The regression for "the buttons do nothing"** (D391). The caller has
    /// to be able to tell a view that opened from one that did not, or the only
    /// thing a refusing platform produces is silence.
    test('says whether a view actually opened', () async {
      final ok = GameServices(platform: FakeGameServices());
      await ok.start();
      expect(await ok.openLeaderboard(), isTrue);

      final bad = GameServices(platform: FakeGameServices(throws: true));
      await bad.start();
      expect(await bad.openAchievements(), isFalse,
          reason: 'a refusal must be reported, not swallowed into success');
    });

    test('an unconfigured Android build opens nothing and says so', () async {
      final services = GameServices(
        platform: FakeGameServices(),
        isAndroid: true,
        androidConfigured: false,
      );
      await services.start();

      expect(await services.openLeaderboard(), isFalse);
    });
  });

  /// D390. Reporting is a diff at the end of each game, so a player signed out
  /// until now has had nothing sent -- and neither store backfills itself.
  /// Without this the first thing a new signed-in player sees is an empty shelf
  /// behind a fortnight of play.
  group('backfill', () {
    test('reports everything already earned', () async {
      final fake = FakeGameServices();
      final services = GameServices(platform: fake);
      await services.start();

      await services.backfill(['first_win:pebble', 'games_in_day:5']);

      expect(fake.unlockedIos, [
        'nl.evict.quadrim2.beat.pebble',
        'nl.evict.quadrim2.games_in_day.5',
      ]);
    });

    /// Safe to call with the whole set every time: the session guard keeps a
    /// repeat to one unlock, and the store treats a second one as a no-op
    /// anyway.
    test('a second backfill in one session unlocks nothing twice', () async {
      final fake = FakeGameServices();
      final services = GameServices(platform: fake);
      await services.start();

      await services.backfill(['first_win:pebble']);
      await services.backfill(['first_win:pebble']);

      expect(fake.unlockedIos, hasLength(1));
    });

    test('quests with no achievement are skipped in silence', () async {
      final fake = FakeGameServices();
      final services = GameServices(platform: fake);
      await services.start();

      await services.backfill(['first_win_second:pebble', 'nonsense']);

      expect(fake.unlockedIos, isEmpty);
    });
  });

  group('sign-in', () {
    test('accepted when the platform signs the player in', () async {
      final fake = FakeGameServices(signedIn: false);
      final services = GameServices(platform: fake);
      await services.start();
      expect(await services.offerSignIn(), SignInOffer.accepted);
      expect(services.available, isTrue);
    });

    /// AC 8's other half. The *caller* is what never asks twice -- this only has
    /// to report the answer honestly so the caller can persist it.
    test('declined when the platform does not', () async {
      final fake = FakeGameServices(throws: true);
      final services = GameServices(platform: fake);
      expect(await services.offerSignIn(), SignInOffer.declined);
      expect(services.available, isFalse);
    });
  });
}
