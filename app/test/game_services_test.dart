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
}

void main() {
  group('the catalogue', () {
    test('is forty-four: one per opponent, five volume rungs, eight streak', () {
      expect(achievementCatalogue, hasLength(44));
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
        hasLength(8),
      );
    });

    /// AC 5, and it is asserted in **both** directions on purpose. A table that
    /// names a quest which no longer exists reports an achievement nobody can
    /// earn; a quest family that quietly grows leaves achievements unmapped.
    /// Only one of those is visible without this test.
    test('every entry names a quest that exists', () {
      final questIds = questCatalogue.map((q) => q.id).toSet();
      for (final a in achievementCatalogue) {
        expect(questIds, contains(a.questId),
            reason: '${a.key} maps to a quest that is not in the catalogue');
      }
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
      expect(achievementCatalogue.map((a) => a.key).toSet(), hasLength(44));
      expect(
        achievementCatalogue.map((a) => a.gameCenterId).toSet(),
        hasLength(44),
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
