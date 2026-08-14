import 'points.dart';

/// Consecutive local days on which the player **finished** at least one game
/// against the computer (spec §7.5, ticket 034).
///
/// Finished, not started: a streak maintained by opening the app and quitting
/// measures nothing. That distinction costs nothing here, because only
/// completed games ever reach [ScoredGame].
///
/// **A missed day resets the streak to zero.** No forgiveness, no rest days,
/// no repair purchase. Every softening mechanism is another rule to explain,
/// another thing to store, and another surface for "I *did* play on Tuesday".
///
/// **No clock is read in this file.** The day boundary is a parameter — the
/// same purity rule that makes every opponent reproducible, applied to the one
/// piece of progression arithmetic that genuinely needs a calendar.

/// A calendar day, as the player's device renders it.
///
/// A plain triple rather than a `DateTime`, because a day is not an instant
/// and arithmetic on midnights invites exactly the daylight-saving bug this
/// type exists to keep out.
class Day implements Comparable<Day> {
  const Day(this.year, this.month, this.dayOfMonth);

  factory Day.of(DateTime local) => Day(local.year, local.month, local.day);

  final int year;
  final int month;
  final int dayOfMonth;

  /// Days since an arbitrary fixed point, so "the next day" is `+1` across
  /// month ends, year ends and leap days without a single special case.
  ///
  /// `DateTime.utc` does the calendar arithmetic; UTC rather than local
  /// because this is counting days, not instants, and a local midnight that
  /// daylight saving deleted would make one day of the year 23 hours long and
  /// this arithmetic wrong.
  int get ordinal =>
      DateTime.utc(year, month, dayOfMonth).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;

  @override
  int compareTo(Day other) => ordinal.compareTo(other.ordinal);

  @override
  bool operator ==(Object other) =>
      other is Day && other.ordinal == ordinal;

  @override
  int get hashCode => ordinal.hashCode;

  @override
  String toString() => '$year-$month-$dayOfMonth';
}

/// How far apart two games may sit in real time and still bridge a gap of one
/// calendar day.
///
/// The generous reading the ticket asks for, made precise. `toLocal()` renders
/// the **whole** history in the device's *current* zone, so moving zones
/// shifts every stored game by the same offset — up to about twenty-six hours
/// — and games near midnight cross into the neighbouring day while the rest do
/// not. The result is a history with a one-day hole in it that the player
/// never experienced.
///
/// Two games less than 48 hours apart cannot span a day the player was absent
/// for, so bridging that hole can never forgive a real miss. It also catches
/// the honest near-miss — Monday 23:30 and Wednesday 00:15 — which is the
/// other case where "you missed Tuesday" is technically true and wrong.
const Duration kAmbiguousDayWindow = Duration(hours: 48);

/// One unbroken run of days, and everything played during it.
class StreakRun {
  const StreakRun({
    required this.first,
    required this.last,
    required this.games,
  });

  final Day first;
  final Day last;

  /// Every game played during the run, oldest first. What prices the rung —
  /// showing up is what the streak measures, but what you showed up *to* is
  /// what the points measure (D270).
  final List<ScoredGame> games;

  /// Inclusive, so a single day is a run of one.
  int get length => last.ordinal - first.ordinal + 1;
}

/// Every unbroken run in [games], oldest first.
///
/// [games] must be oldest first with [ScoredGame.completedAt] already in local
/// time — the app converts, because this package may not decide which day a
/// UTC instant falls in.
List<StreakRun> streakRuns(Iterable<ScoredGame> games) {
  // Grouped rather than sorted: several games share a day, and the run
  // arithmetic is about days.
  final byDay = <int, List<ScoredGame>>{};
  final dayOf = <int, Day>{};
  for (final game in games) {
    final at = game.completedAt;
    if (at == null) continue;
    final day = Day.of(at);
    dayOf[day.ordinal] = day;
    byDay.putIfAbsent(day.ordinal, () => []).add(game);
  }
  final ordinals = byDay.keys.toList()..sort();
  if (ordinals.isEmpty) return const [];

  final runs = <StreakRun>[];
  var first = ordinals.first;
  var played = <ScoredGame>[...byDay[ordinals.first]!];

  for (var i = 1; i < ordinals.length; i++) {
    final gap = ordinals[i] - ordinals[i - 1];
    final continues = gap == 1 ||
        (gap == 2 && _within(byDay[ordinals[i - 1]]!, byDay[ordinals[i]]!));
    if (continues) {
      played.addAll(byDay[ordinals[i]]!);
    } else {
      runs.add(StreakRun(
        first: dayOf[first]!,
        last: dayOf[ordinals[i - 1]]!,
        games: List.unmodifiable(played),
      ));
      first = ordinals[i];
      played = [...byDay[ordinals[i]]!];
    }
  }
  runs.add(StreakRun(
    first: dayOf[first]!,
    last: dayOf[ordinals.last]!,
    games: List.unmodifiable(played),
  ));
  return runs;
}

/// Whether the last game of one day and the first of the next-but-one are
/// close enough in real time for the day between them to be an artefact.
bool _within(List<ScoredGame> earlier, List<ScoredGame> later) {
  final end = earlier.last.completedAt!;
  final start = later.first.completedAt!;
  return start.difference(end) < kAmbiguousDayWindow;
}

/// The streak the player is on, as of [today].
///
/// Alive while the last day played is today **or yesterday**: a player who has
/// not opened the app yet today has not missed anything, and telling them
/// their streak is zero until they play would be both wrong and the surest way
/// to make it true.
///
/// [today] is a parameter and never a clock read (spec P19).
int currentStreak(Iterable<ScoredGame> games, {required DateTime today}) {
  final runs = streakRuns(games);
  if (runs.isEmpty) return 0;
  final now = Day.of(today).ordinal;
  final last = runs.last;
  final since = now - last.last.ordinal;
  // Negative means the device's clock moved backwards, or a game is stamped in
  // the future. Neither is the player's fault, so the streak stands.
  if (since > 1) return 0;
  // Counted to the last day actually played, not to today: a streak is the
  // days you turned up for.
  return last.length;
}

/// The games of the first [days] calendar days of [run] — what earned the rung
/// rather than everything played since.
List<ScoredGame> qualifyingGames(StreakRun run, int days) {
  final cutoff = run.first.ordinal + days - 1;
  return [
    for (final game in run.games)
      if (Day.of(game.completedAt!).ordinal <= cutoff) game,
  ];
}
