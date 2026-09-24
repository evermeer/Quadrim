import 'package:flutter_test/flutter_test.dart';
import 'package:quadrim/data/documents.dart';
import 'package:quadrim/data/points_fold.dart' as points_fold;
import 'package:quadrim/services/achievements.dart';
import 'package:quadrim/services/games.dart';
import 'package:quadrim_engine/quadrim_engine.dart';

import 'game_services_test.dart' show FakeGameServices;

/// Does the backfill reach the volume and streak families, or only the
/// opponents?
///
/// Device report: after signing in, the opponent achievements arrived and
/// "games in a day" and "days in a row" did not. Three things have to hold for
/// one of those to unlock, and only the first two are this app's to get right:
/// the quest must report itself achieved, the catalogue must map its id to a
/// store id, and the achievement must exist and be live in the store. This
/// file settles the first two so the third is what is left.
void main() {
  /// A finished game against [botId], completed on [day].
  ///
  /// Built as documents and folded through the app's own `questsFrom`, so what
  /// is exercised is the path the home screen actually calls rather than the
  /// package underneath it.
  GameDocument game(String botId, DateTime day, int n) => GameDocument(
        id: '$botId-${day.toIso8601String()}-$n',
        mode: GameMode.vsComputer,
        opponent: botOpponent(botId),
        opponentRating: botById(botId)!.rating,
        startingSeat: 0,
        playerSeat: 0,
        startReason: StartReason.random,
        moves: const [0, 21, 1, 22, 2, 26, 3],
        status: GameStatus.complete,
        createdAt: day,
        updatedAt: day.add(Duration(minutes: n)),
        completedAt: day.add(Duration(minutes: n)),
        result: GameResult(
          outcome: GameOutcome.win,
          reason: GameEndReason.line,
          winnerSeat: 0,
        ),
      );

  final today = DateTime(2026, 9, 24, 20);

  /// Five finished games on one day: the lowest volume rung.
  List<GameDocument> fiveInADay() =>
      [for (var n = 0; n < 5; n++) game('pebble', today, n)];

  /// One game a day for five consecutive days: the lowest streak rung.
  List<GameDocument> fiveDaysRunning() => [
        for (var d = 4; d >= 0; d--)
          game('pebble', today.subtract(Duration(days: d)), 0),
      ];

  Set<String> achievedIds(List<GameDocument> games) => {
        for (final q in points_fold.questsFrom(games, today))
          if (q.achieved) q.quest.id,
      };

  group('the fold reports the rungs as achieved', () {
    test('five games in one day clears games_in_day:5', () {
      expect(achievedIds(fiveInADay()), contains('games_in_day:5'));
    });

    test('five days running clears days_in_row:5', () {
      expect(achievedIds(fiveDaysRunning()), contains('days_in_row:5'));
    });

    /// The property that makes a backfill possible at all: a rung earned
    /// weeks ago must still read as achieved today, or there is nothing to
    /// send when the player finally signs in.
    test('a streak rung stays achieved after the streak breaks', () {
      final long = [
        for (var d = 40; d >= 36; d--)
          game('pebble', today.subtract(Duration(days: d)), 0),
      ];
      expect(achievedIds(long), contains('days_in_row:5'),
          reason: 'the run ended five weeks ago and the rung is permanent');
    });
  });

  group('the catalogue maps both families to a store id', () {
    test('every volume rung has one', () {
      for (final target in kVolumeAchievementTargets) {
        final found = achievementForQuest('games_in_day:$target');
        expect(found, isNotNull, reason: 'games_in_day:$target');
        expect(found!.gameCenterId, 'nl.evict.quadrim2.beat.games_in_day.$target');
      }
    });

    test('every streak rung has one', () {
      for (final target in kStreakAchievementTargets) {
        final found = achievementForQuest('days_in_row:$target');
        expect(found, isNotNull, reason: 'days_in_row:$target');
        expect(found!.gameCenterId, 'nl.evict.quadrim2.beat.days_in_row.$target');
      }
    });
  });

  group('the backfill sends them', () {
    test('a volume rung reaches the platform', () async {
      final fake = FakeGameServices();
      final services = GameServices(platform: fake);
      await services.start();

      await services.backfill(achievedIds(fiveInADay()));
      expect(fake.unlockedIos,
          contains('nl.evict.quadrim2.beat.games_in_day.5'));
    });

    test('a streak rung reaches the platform', () async {
      final fake = FakeGameServices();
      final services = GameServices(platform: fake);
      await services.start();

      await services.backfill(achievedIds(fiveDaysRunning()));
      expect(fake.unlockedIos, contains('nl.evict.quadrim2.beat.days_in_row.5'));
    });

    /// The shape the device was actually in: opponents earned, and one rung of
    /// each of the other two families. If only the opponents arrive, the defect
    /// is here; if all three do, it is in the store's configuration.
    test('opponents, volume and streak all arrive together', () async {
      final fake = FakeGameServices();
      final services = GameServices(platform: fake);
      await services.start();

      await services.backfill(achievedIds([
        ...fiveInADay(),
        ...fiveDaysRunning(),
      ]));

      expect(fake.unlockedIos, contains('nl.evict.quadrim2.beat.pebble'));
      expect(fake.unlockedIos, contains('nl.evict.quadrim2.beat.games_in_day.5'));
      expect(fake.unlockedIos, contains('nl.evict.quadrim2.beat.days_in_row.5'));
    });
  });
}
