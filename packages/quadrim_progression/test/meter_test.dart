import 'package:quadrim_progression/quadrim_progression.dart';
import 'package:test/test.dart';

/// The meter (ticket 045, spec §4.2, F16, F17, S19).

StartedGame at(int y, int m, int d, [int hour = 12]) =>
    StartedGame(startedAt: DateTime(y, m, d, hour));

/// A free month that ended long ago, so the limits apply.
final expired = FreeMonth(startedAt: DateTime(2020, 1, 1));

MeterState stateOn(DateTime now, List<StartedGame> games,
        {FreeMonth? freeMonth}) =>
    meterState(games: games, now: now, freeMonth: freeMonth ?? expired);

void main() {
  group('daily limit', () {
    test('three started games exhaust the day and the fourth is refused', () {
      final games = [
        at(2026, 8, 12),
        at(2026, 8, 12, 13),
        at(2026, 8, 12, 14),
      ];
      final state = stateOn(DateTime(2026, 8, 12, 15), games);
      expect(state.startedToday, 3);
      expect(state.canStart, isFalse);
      expect(state.blocked, MeterLimit.daily);
      expect(state.availableAgain, const Day(2026, 8, 13));
    });

    test('two started games leave one', () {
      final state = stateOn(DateTime(2026, 8, 12, 15), [
        at(2026, 8, 12),
        at(2026, 8, 12, 13),
      ]);
      expect(state.canStart, isTrue);
      expect(state.remainingToday, 1);
    });

    test('yesterday does not count against today', () {
      final state = stateOn(DateTime(2026, 8, 12), [
        at(2026, 8, 11),
        at(2026, 8, 11, 13),
        at(2026, 8, 11, 14),
      ]);
      expect(state.startedToday, 0);
      expect(state.canStart, isTrue);
    });
  });

  group('weekly limit', () {
    test('nine in a week refuse a tenth even when today is empty', () {
      // Monday 10th through Wednesday 12th, three a day: nine used, and no
      // single day exceeded the daily limit.
      final games = [
        for (final day in [10, 11, 12])
          for (final hour in [10, 12, 14]) at(2026, 8, day, hour),
      ];
      // Thursday: the daily count is zero and the week is spent.
      final state = stateOn(DateTime(2026, 8, 13), games);
      expect(state.startedToday, 0);
      expect(state.startedThisWeek, 9);
      expect(state.canStart, isFalse);
      expect(state.blocked, MeterLimit.weekly,
          reason: 'the daily limit has not been reached, so it cannot be the '
              'one that bit');
      expect(state.availableAgain, const Day(2026, 8, 17), reason: 'next Monday');
    });

    test('the weekly limit is named when both are exhausted', () {
      // Nine this week and three today: "come back tomorrow" would be false,
      // because tomorrow is still in this week.
      final games = [
        for (final hour in [9, 10, 11]) at(2026, 8, 10, hour),
        for (final hour in [9, 10, 11]) at(2026, 8, 11, hour),
        for (final hour in [9, 10, 11]) at(2026, 8, 12, hour),
      ];
      final state = stateOn(DateTime(2026, 8, 12, 15), games);
      expect(state.startedToday, 3);
      expect(state.startedThisWeek, 9);
      expect(state.blocked, MeterLimit.weekly);
    });

    test('last week does not count against this week', () {
      final games = [
        for (final day in [3, 4, 5])
          for (final hour in [10, 12, 14]) at(2026, 8, day, hour),
      ];
      final state = stateOn(DateTime(2026, 8, 10), games);
      expect(state.startedThisWeek, 0);
      expect(state.canStart, isTrue);
    });

    test('the week turns over on Monday, not on Sunday', () {
      // 2026-08-16 is a Sunday and 2026-08-17 the Monday after it.
      expect(DateTime(2026, 8, 16).weekday, DateTime.sunday);
      expect(weekOrdinal(const Day(2026, 8, 16)),
          weekOrdinal(const Day(2026, 8, 10)),
          reason: 'Sunday closes the week that began on Monday the 10th');
      expect(weekOrdinal(const Day(2026, 8, 17)),
          isNot(weekOrdinal(const Day(2026, 8, 16))));
      expect(weekStart(const Day(2026, 8, 16)), const Day(2026, 8, 10));
    });

    test('a week spanning a month end is one week', () {
      expect(weekOrdinal(const Day(2026, 8, 31)),
          weekOrdinal(const Day(2026, 9, 1)));
      expect(weekStart(const Day(2026, 9, 1)), const Day(2026, 8, 31));
    });

    test('a week spanning a year end is one week', () {
      // 2026-12-31 is a Thursday, so its week runs into January.
      expect(weekOrdinal(const Day(2026, 12, 31)),
          weekOrdinal(const Day(2027, 1, 1)));
    });
  });

  group('what counts', () {
    test('an abandoned game counts, because it was started', () {
      // Nothing distinguishes an abandoned game here: the app hands over
      // starts, so a game that was begun and walked away from is present and
      // a game that was finished is present, identically (F17).
      final state = stateOn(DateTime(2026, 8, 12, 20), [
        at(2026, 8, 12, 9),
        at(2026, 8, 12, 10),
        at(2026, 8, 12, 11),
      ]);
      expect(state.blocked, MeterLimit.daily);
    });

    test('no games means nothing is blocked', () {
      final state = stateOn(DateTime(2026, 8, 12), const []);
      expect(state.canStart, isTrue);
      expect(state.remainingToday, kDailyLimit);
    });
  });

  group('the free month', () {
    test('nothing is metered while it covers now', () {
      final games = [
        for (final hour in [9, 10, 11, 13, 14]) at(2026, 8, 12, hour),
      ];
      final state = stateOn(DateTime(2026, 8, 12, 15), games,
          freeMonth: FreeMonth(startedAt: DateTime(2026, 8, 1)));
      expect(state.inFreeMonth, isTrue);
      expect(state.canStart, isTrue);
      expect(state.startedToday, 5, reason: 'still counted, just not enforced');
    });

    test('the limits apply the moment it ends', () {
      final free = FreeMonth(startedAt: DateTime(2026, 7, 12, 9));
      final games = [
        for (final hour in [9, 10, 11]) at(2026, 8, 12, hour),
      ];
      expect(stateOn(DateTime(2026, 8, 12, 8), games, freeMonth: free).canStart,
          isTrue,
          reason: 'an hour before it ends');
      expect(stateOn(DateTime(2026, 8, 12, 10), games, freeMonth: free).canStart,
          isFalse,
          reason: 'an hour after it ends');
    });

    test('one calendar month, clamped at a short month', () {
      expect(FreeMonth(startedAt: DateTime(2026, 1, 31)).endsAt,
          DateTime(2026, 2, 28),
          reason: '31 January plus a month is not 3 March');
      expect(FreeMonth(startedAt: DateTime(2028, 1, 31)).endsAt,
          DateTime(2028, 2, 29),
          reason: 'a leap year has one more day to clamp to');
      expect(FreeMonth(startedAt: DateTime(2026, 12, 15)).endsAt,
          DateTime(2027, 1, 15),
          reason: 'December rolls the year');
    });

    test('a clock that moved backwards gives the month rather than taking it',
        () {
      final free = FreeMonth(startedAt: DateTime(2026, 8, 1));
      expect(free.covers(DateTime(2026, 7, 1)), isTrue);
    });

    test('an absent record is unmetered, not exhausted', () {
      // The app records first launch before anything can be played, so this is
      // a corrupt-or-missing document. It must fail towards letting the player
      // play.
      final games = [
        for (final hour in [9, 10, 11]) at(2026, 8, 12, hour),
      ];
      final state =
          meterState(games: games, now: DateTime(2026, 8, 12, 15), freeMonth: null);
      expect(state.canStart, isTrue);
    });
  });

  test('a subscriber is never refused, after the free month too (D396)', () {
    final games = [
      for (final day in [10, 11, 12])
        for (final hour in [10, 12, 14]) at(2026, 8, day, hour),
    ];
    final state = meterState(
        games: games,
        now: DateTime(2026, 8, 12, 15),
        freeMonth: expired,
        unlimited: true);
    expect(state.canStart, isTrue);
    expect(state.inFreeMonth, isFalse, reason: 'the month really is over');
  });

  group('remainingToday', () {
    test('is the tighter of the two limits', () {
      // Eight used this week, none today: the weekly limit leaves one, the
      // daily leaves three, and the player has one.
      final games = [
        for (final day in [10, 11]) for (final h in [9, 10, 11]) at(2026, 8, day, h),
        at(2026, 8, 12, 9),
        at(2026, 8, 12, 10),
      ];
      final state = stateOn(DateTime(2026, 8, 12, 15), games);
      expect(state.startedThisWeek, 8);
      expect(state.remainingToday, 1);
    });

    test('never goes negative', () {
      final games = [
        for (final day in [10, 11, 12, 13])
          for (final h in [9, 10, 11]) at(2026, 8, day, h),
      ];
      final state = stateOn(DateTime(2026, 8, 13, 15), games);
      expect(state.startedThisWeek, 12);
      expect(state.remainingToday, 0);
    });
  });
}
