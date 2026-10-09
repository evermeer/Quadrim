import 'streaks.dart';

/// How many games against the computer may be **started** (spec §4.2, ticket
/// 045).
///
/// This file counts. It never refuses: the wall is the app's, and separating
/// them means the arithmetic can be wrong in a test rather than in front of a
/// player.
///
/// **Started, not finished — and that is the opposite of every other fold in
/// this package.** Points, quests and streaks all read completed games,
/// because they reward results. The meter reads starts, because a meter that
/// counted results would be defeated by starting a game and quitting (D310).
///
/// **No clock is read in this file.** `now` is a parameter, like the streak
/// evaluator's day boundary (P19).

/// Computer games startable in one calendar day.
const int kDailyLimit = 3;

/// Computer games startable in one calendar week.
///
/// Nine rather than twenty-one, so the weekly limit binds first from the fourth
/// playing day of any week and the daily limit is not the only thing shaping a
/// week (§4.2).
const int kWeeklyLimit = 9;

/// The day a week turns over. Monday, everywhere, in every locale.
///
/// A locale-dependent week start would be an ambient input to a pure package,
/// and it would mean two players in different countries hitting the same limit
/// on different days for reasons neither could see. The cost is that this
/// disagrees with the calendar in locales that draw weeks Sunday-first
/// (D311).
const int kWeekStartsOn = DateTime.monday;

/// One computer game that was **started**, at the local time it was started.
///
/// A named type over a bare `DateTime` for one reason: the whole correctness of
/// this file is started-not-completed, and a function taking `Iterable<DateTime>`
/// accepts a list of `completedAt` values without a murmur.
class StartedGame {
  const StartedGame({required this.startedAt});

  /// Local time, converted by the app — this package may not decide which day
  /// a UTC instant falls in, for the same reason [Day] exists.
  final DateTime startedAt;
}

/// Which limit refused a game.
enum MeterLimit {
  /// Nothing refused it.
  none,
  daily,
  weekly,
}

/// The unmetered period that begins at first launch and never begins again.
///
/// **Consumed once.** A lapsed subscription does not restart it, and neither
/// does anything else (§4.1). At 1.0 it is remembered on the device, so a
/// reinstall does restore it — a known limit rather than a defect, because
/// closing it needs either a device identifier, forbidden in every release, or
/// a server, which is 2.0 (D303, S19).
class FreeMonth {
  const FreeMonth({required this.startedAt});

  /// Local time of first launch.
  final DateTime startedAt;

  /// One calendar month later, clamped to the end of the target month.
  ///
  /// Clamped because 31 January plus one month has no honest answer and the
  /// unclamped one is 3 March — a player who installs on the 31st would get
  /// three extra days over a player who installs on the 1st.
  DateTime get endsAt {
    final year = startedAt.month == 12 ? startedAt.year + 1 : startedAt.year;
    final month = startedAt.month == 12 ? 1 : startedAt.month + 1;
    final lastOfMonth = DateTime(year, month + 1, 0).day;
    final day = startedAt.day < lastOfMonth ? startedAt.day : lastOfMonth;
    return DateTime(year, month, day, startedAt.hour, startedAt.minute,
        startedAt.second, startedAt.millisecond, startedAt.microsecond);
  }

  /// Whether [now] still falls inside it.
  ///
  /// A start in the future counts as covering now, and this one comparison is
  /// all that takes: [endsAt] is always after [startedAt], so a `now` before
  /// the start is before the end as well. That means a device whose clock has
  /// moved backwards gives the player their month rather than taking it away,
  /// which is the same direction the streak evaluator errs in and for the same
  /// reason: a clock is not the player's fault.
  bool covers(DateTime now) => now.isBefore(endsAt);
}

/// What the meter says right now.
class MeterState {
  const MeterState({
    required this.startedToday,
    required this.startedThisWeek,
    required this.inFreeMonth,
    required this.blocked,
    required this.availableAgain,
  });

  final int startedToday;
  final int startedThisWeek;

  /// True while the free month covers `now`, in which case nothing is blocked.
  final bool inFreeMonth;

  /// Which limit refuses a new computer game, or [MeterLimit.none].
  final MeterLimit blocked;

  /// The first day a new game may be started, or null when one may be started
  /// now. Tomorrow for a daily block, the next week start for a weekly one.
  final Day? availableAgain;

  bool get canStart => blocked == MeterLimit.none;

  /// How many remain today under whichever limit is closer. Never negative.
  ///
  /// The end-of-game panel shows this when it gets small (U19, ticket 047);
  /// it is the min of the two because a player with two daily and one weekly
  /// game left has one game left, not two.
  int get remainingToday {
    if (inFreeMonth) return kDailyLimit;
    final daily = kDailyLimit - startedToday;
    final weekly = kWeeklyLimit - startedThisWeek;
    final left = daily < weekly ? daily : weekly;
    return left < 0 ? 0 : left;
  }
}

/// Which week [day] falls in, counting from an arbitrary fixed point.
///
/// Built on [Day.ordinal] so week ends need no more special-casing than month
/// ends did. Ordinal 0 is a Thursday, which is where the offset comes from.
int weekOrdinal(Day day) {
  final shifted = day.ordinal + (DateTime.thursday - kWeekStartsOn) % 7;
  // Floor, not truncate. `~/` rounds toward zero, which for dates before 1970
  // puts a Sunday and the Monday after it in the same week — 1969-12-28 and
  // 1969-12-29 both land in week 0 — and hands out a second week's allowance
  // inside one week. Only a device clock set before the epoch reaches it; the
  // fix is a line, and a date function that is wrong for some dates invites
  // the question every time it is read.
  return shifted >= 0 ? shifted ~/ 7 : ((shifted + 1) ~/ 7) - 1;
}

/// The first day of the week [day] falls in.
Day weekStart(Day day) {
  final offset = (DateTime.thursday - kWeekStartsOn) % 7;
  final start = weekOrdinal(day) * 7 - offset;
  return Day.of(
      DateTime.fromMillisecondsSinceEpoch(start * Duration.millisecondsPerDay,
          isUtc: true));
}

/// The meter, as of [now].
///
/// [games] is every computer game **started**, in any order, with times already
/// local. Pass-and-play, the tutorial's practice game and replay are not games
/// against the computer and never appear here — the app filters, because this
/// package does not know what a game document is.
///
/// [unlimited] is the "unlimited play" subscription. It lifts both limits and
/// leaves [MeterState.inFreeMonth] telling the truth about the month (D396).
MeterState meterState({
  required Iterable<StartedGame> games,
  required DateTime now,
  required FreeMonth? freeMonth,
  bool unlimited = false,
}) {
  final today = Day.of(now);
  final thisWeek = weekOrdinal(today);

  var startedToday = 0;
  var startedThisWeek = 0;
  for (final game in games) {
    final day = Day.of(game.startedAt);
    if (weekOrdinal(day) != thisWeek) continue;
    startedThisWeek++;
    if (day == today) startedToday++;
  }

  // Absent means first launch has not been recorded, which the app does before
  // anything can be played. Treated as unmetered rather than as exhausted: the
  // failure direction of a missing record must be to let the player play.
  final free = freeMonth == null || freeMonth.covers(now);

  var blocked = MeterLimit.none;
  Day? availableAgain;
  if (!free && !unlimited) {
    // **Weekly first when both are exhausted.** A player at nine this week is
    // not helped by "come back tomorrow" — tomorrow is still in this week and
    // still refuses. Naming the limit that actually bit means naming the one
    // that keeps them out longest (D221).
    if (startedThisWeek >= kWeeklyLimit) {
      blocked = MeterLimit.weekly;
      availableAgain = _addDays(weekStart(today), 7);
    } else if (startedToday >= kDailyLimit) {
      blocked = MeterLimit.daily;
      availableAgain = _addDays(today, 1);
    }
  }

  return MeterState(
    startedToday: startedToday,
    startedThisWeek: startedThisWeek,
    inFreeMonth: free,
    blocked: blocked,
    availableAgain: availableAgain,
  );
}

Day _addDays(Day day, int days) => Day.of(DateTime.fromMillisecondsSinceEpoch(
    (day.ordinal + days) * Duration.millisecondsPerDay,
    isUtc: true));
