import 'package:quadrim_progression/quadrim_progression.dart';
import 'package:test/test.dart';

/// Streaks are the one piece of progression arithmetic that genuinely needs a
/// calendar, which is why the day boundary is a parameter and why this file
/// spends most of its length on boundaries: months, years, leap days and a
/// device that has changed time zone under a history that cannot move.

ScoredGame _at(DateTime when, {int index = 0, bool won = true}) =>
    ScoredGame(
      rosterIndex: index,
      won: won,
      movedSecond: false,
      completedAt: when,
    );

/// One game a day at 12:00, for [days] days starting at [from].
List<ScoredGame> _daily(DateTime from, int days, {int index = 0}) => [
      for (var i = 0; i < days; i++)
        _at(DateTime(from.year, from.month, from.day + i, 12), index: index),
    ];

QuestStatus _rung(List<ScoredGame> games, int days, DateTime today) =>
    questStatuses(games, today: today)
        .firstWhere((s) => s.quest.id == 'days_in_row:$days');

void main() {
  group('what keeps a day alive', () {
    test('no games is no streak', () {
      expect(currentStreak(const [], today: DateTime(2026, 8, 14)), 0);
    });

    test('one game today is a streak of one', () {
      expect(
          currentStreak([_at(DateTime(2026, 8, 14, 9))],
              today: DateTime(2026, 8, 14, 21)),
          1);
    });

    test('several games on one day are still one day', () {
      final games = [
        for (var h = 9; h < 20; h++) _at(DateTime(2026, 8, 14, h)),
      ];
      expect(currentStreak(games, today: DateTime(2026, 8, 14, 22)), 1);
    });

    test('a game with no completion time keeps nothing alive', () {
      expect(
          currentStreak([
            ScoredGame(
                rosterIndex: 0,
                won: true,
                movedSecond: false,
                completedAt: null),
          ], today: DateTime(2026, 8, 14)),
          0);
    });
  });

  group('staying alive and lapsing', () {
    test('yesterday still counts, because today is not over', () {
      // Telling a player their streak is zero before they have had a chance to
      // play is both wrong and the surest way to make it true.
      final games = _daily(DateTime(2026, 8, 10), 4); // 10th–13th
      expect(currentStreak(games, today: DateTime(2026, 8, 14, 8)), 4);
    });

    test('the day before yesterday does not', () {
      final games = _daily(DateTime(2026, 8, 10), 4);
      expect(currentStreak(games, today: DateTime(2026, 8, 15, 8)), 0);
    });

    test('a missed day resets to zero and the count starts again', () {
      final games = [
        ..._daily(DateTime(2026, 8, 1), 6), // 1st–6th
        ..._daily(DateTime(2026, 8, 9), 2), // 9th–10th, a clear break
      ];
      expect(currentStreak(games, today: DateTime(2026, 8, 10, 20)), 2);
      expect(streakRuns(games).map((r) => r.length), [6, 2]);
    });

    test('a clock that has moved backwards does not break a streak', () {
      final games = _daily(DateTime(2026, 8, 10), 4);
      // "Today" earlier than the last game played: the device is wrong, not
      // the player.
      expect(currentStreak(games, today: DateTime(2026, 8, 1)), 4);
    });
  });

  group('calendar boundaries', () {
    test('crosses a month boundary', () {
      final games = _daily(DateTime(2026, 1, 29), 5); // 29 Jan – 2 Feb
      expect(currentStreak(games, today: DateTime(2026, 2, 2, 23)), 5);
      expect(streakRuns(games).single.length, 5);
    });

    test('crosses a year boundary', () {
      final games = _daily(DateTime(2026, 12, 29), 6); // 29 Dec – 3 Jan
      expect(currentStreak(games, today: DateTime(2027, 1, 3, 23)), 6);
    });

    test('crosses a leap day', () {
      // 2028 is a leap year: 27 Feb, 28 Feb, 29 Feb, 1 Mar.
      final games = _daily(DateTime(2028, 2, 27), 4);
      expect([for (final g in games) g.completedAt!.day], [27, 28, 29, 1]);
      expect(currentStreak(games, today: DateTime(2028, 3, 1, 23)), 4);
    });

    test('and knows a non-leap year has no 29 February', () {
      final games = _daily(DateTime(2027, 2, 27), 3);
      expect([for (final g in games) g.completedAt!.day], [27, 28, 1]);
      expect(currentStreak(games, today: DateTime(2027, 3, 1, 23)), 3);
    });
  });

  group('a time-zone change', () {
    test('bridges a one-day hole the player never experienced', () {
      // The whole history renders in the device's *current* zone, so moving
      // zones shifts every stored game by the same offset. A game near
      // midnight crosses into the neighbouring day while the rest do not,
      // leaving a hole in a history the player lived without a gap.
      final games = [
        ..._daily(DateTime(2026, 8, 1), 3), // 1st–3rd at noon
        _at(DateTime(2026, 8, 3, 23, 30)),
        _at(DateTime(2026, 8, 5, 0, 15)), // 4th is missing; 24h45m later
      ];
      expect(streakRuns(games), hasLength(1),
          reason: 'never break a streak that any reasonable reading kept');
      expect(currentStreak(games, today: DateTime(2026, 8, 5, 12)), 5,
          reason: 'the bridged day counts, generously');
    });

    test('and cannot bridge a day the player really was absent for', () {
      final games = [
        _at(DateTime(2026, 8, 3, 9)),
        _at(DateTime(2026, 8, 5, 21)), // 60 hours later: a real miss
      ];
      expect(streakRuns(games), hasLength(2));
      expect(currentStreak(games, today: DateTime(2026, 8, 5, 23)), 1);
    });

    test('never bridges two days, whatever the clocks say', () {
      final games = [
        _at(DateTime(2026, 8, 3, 23, 59)),
        _at(DateTime(2026, 8, 6, 0, 1)), // two days missing, 48h02m
      ];
      expect(streakRuns(games), hasLength(2));
    });
  });

  group('the nine rungs', () {
    final today = DateTime(2026, 12, 31);

    test('pay the multiples the table gives', () {
      // Index 2 keeps the arithmetic exact: a win against Mote is 4 points, so
      // each rung pays its multiple of 4 with nothing rounded away.
      const rungs = {5: 1, 10: 2, 30: 4, 90: 8, 180: 12, 360: 16};
      rungs.forEach((days, multiple) {
        final games = _daily(DateTime(2026, 1, 1), days, index: 2);
        expect(_rung(games, days, today).award, multiple * winValue(2),
            reason: '$days days');
      });
    });

    test('a streak kept alive with one Pebble game a day pays Pebble money',
        () {
      // Ninety days of turning up, worth eight points. Stated explicitly so
      // nobody later reads it as a bug: showing up is what the streak
      // measures, but what you showed up *to* is what the points measure.
      final games = _daily(DateTime(2026, 1, 1), 90);
      expect(_rung(games, 90, today).award, 8);
      // The same ninety days against Kestrel is worth two unlocks and more.
      final real = _daily(DateTime(2026, 1, 1), 90, index: 8);
      expect(_rung(real, 90, today).award, 8 * winValue(8));
    });

    test('are priced by the games of the days that earned them, not by '
        'everything played since', () {
      final games = [
        ..._daily(DateTime(2026, 1, 1), 5), // Pebble, days 1–5
        ..._daily(DateTime(2026, 1, 6), 25, index: 19), // then the top rung
      ];
      // The five-day rung was earned by five Pebble games and is worth a
      // Pebble win, whatever happened on day six.
      expect(_rung(games, 5, today).award, 1);
      // The thirty-day rung, earned by all thirty, averages them.
      expect(_rung(games, 30, today).award, greaterThan(winValue(15)));
    });

    test('fire exactly once, and stay fired when the streak later breaks', () {
      final games = [
        ..._daily(DateTime(2026, 1, 1), 10),
        ..._daily(DateTime(2026, 6, 1), 2),
      ];
      final ten = _rung(games, 10, today);
      expect(ten.achieved, isTrue);
      expect(ten.award, 2, reason: 'ten Pebble days, two wins-worth of Pebble');
      // And a later, longer run does not re-price it.
      final more = [...games, ..._daily(DateTime(2026, 9, 1), 12, index: 19)];
      expect(_rung(more, 10, today).award, 2);
    });

    test('an unachieved rung shows the streak the player is on now', () {
      final games = _daily(DateTime(2026, 12, 28), 3); // 28th–30th
      final rung = _rung(games, 5, DateTime(2026, 12, 31, 9));
      expect(rung.achieved, isFalse);
      expect(rung.current, 3);
      // And a lapsed streak really is back at zero, which is the difference
      // between this family and the volume family's best-day-ever (D282).
      expect(_rung(games, 5, DateTime(2027, 1, 5)).current, 0);
    });
  });

  group('nothing is stored', () {
    test('the streak and every rung come from the games and a boundary alone',
        () {
      final games = _daily(DateTime(2026, 3, 1), 31, index: 4);
      final today = DateTime(2026, 3, 31, 20);
      // Folded twice from the same inputs, and folded again from a copy that
      // shares no list with the first.
      final once = questStatuses(games, today: today);
      final twice = questStatuses(games.toList(), today: today);
      for (var i = 0; i < once.length; i++) {
        expect(twice[i].achieved, once[i].achieved, reason: once[i].quest.id);
        expect(twice[i].award, once[i].award, reason: once[i].quest.id);
        expect(twice[i].current, once[i].current, reason: once[i].quest.id);
      }
      expect(currentStreak(games, today: today), 31);
      expect(_rung(games, 30, today).achieved, isTrue);
      expect(_rung(games, 90, today).achieved, isFalse);
    });
  });
}
