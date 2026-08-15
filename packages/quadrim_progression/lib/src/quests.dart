import 'package:quadrim_engine/quadrim_engine.dart';

import 'points.dart';
import 'streaks.dart';

/// One achievement system, not three (spec §7.4).
///
/// Everything that pays points besides a plain win is a quest, including the
/// two per-opponent milestones that were once a feature of their own.
///
/// **Every quest is priced by the opponents it was earned against, never by
/// how high the player has climbed.** That is the whole content of D261 and
/// D270 and it is carried here by the type signatures: nothing in this file
/// accepts a rating or a rung, so no reward *can* be priced by one. Two
/// attempts to price by the player failed in opposite directions — the cheap
/// per-opponent quests became bankable until eight games against opponents
/// that move at random paid twice the cost of the whole roster, and a hundred
/// instant Pebble games in a day paid four Titan wins.
///
/// Nothing here is stored. Every quest's progress is a fold over games, for
/// the same reason the rating and the balance are (spec §8.8).

enum QuestFamily {
  /// First win against one opponent.
  firstWin,

  /// First win against one opponent **as the second player to move**.
  ///
  /// A genuinely harder rung — the first player has a real advantage in Qubic
  /// — and free to detect, because which seat opened is already on every game.
  firstWinSecond,

  /// Games finished on one local day: 5, 10, 20, 50, 100.
  gamesInDay,

  /// Consecutive local days played: 5, 10, 30, 90, 180, 360, 720, 1440.
  consecutiveDays,
}

/// One quest: what it asks for, and what multiple of a win it pays.
class Quest {
  const Quest({
    required this.id,
    required this.family,
    required this.target,
    required this.multipleQuarters,
    this.rosterIndex,
  });

  /// Stable across builds, because the interface ranks by it and the end of a
  /// game diffs two lists of it.
  final String id;

  final QuestFamily family;

  /// How many of the thing are needed. 1 for both per-opponent families.
  final int target;

  /// What it pays, in **quarters of a win**, because two of the five volume
  /// rungs pay a fraction of one (¼ and ½) and integers are the only thing
  /// that can be re-tuned without a rounding argument.
  ///
  /// Both per-opponent families pay 4 — exactly one win against the opponent
  /// they name.
  final int multipleQuarters;

  /// Which opponent, for the two per-opponent families. Null for the others,
  /// whose opponent is whatever the qualifying games averaged.
  final int? rosterIndex;
}

/// Games in one day, and what each rung pays in wins-worth: ¼, ½, 1, 2, 4.
const _volumeTargets = [5, 10, 20, 50, 100];
const _volumeQuarters = [1, 2, 4, 8, 16];

/// Consecutive days, paying 1, 2, 4, 8, 12, 16, 24 and 32 wins-worth.
///
/// The calendar arithmetic is in `streaks.dart` (ticket 034). 1440 days is
/// just under four years; it exists as a horizon rather than as a target, and
/// nothing depends on anyone reaching it.
const _streakTargets = [5, 10, 30, 90, 180, 360, 720, 1440];
const _streakQuarters = [4, 8, 16, 32, 48, 64, 96, 128];

/// All fifty-three: twenty, twenty, five and eight.
final List<Quest> questCatalogue = List.unmodifiable([
  for (var i = 0; i < opponentCatalogue.length; i++)
    Quest(
      id: 'first_win:${opponentCatalogue[i].id}',
      family: QuestFamily.firstWin,
      target: 1,
      multipleQuarters: 4,
      rosterIndex: i,
    ),
  for (var i = 0; i < opponentCatalogue.length; i++)
    Quest(
      id: 'first_win_second:${opponentCatalogue[i].id}',
      family: QuestFamily.firstWinSecond,
      target: 1,
      multipleQuarters: 4,
      rosterIndex: i,
    ),
  for (var i = 0; i < _volumeTargets.length; i++)
    Quest(
      id: 'games_in_day:${_volumeTargets[i]}',
      family: QuestFamily.gamesInDay,
      target: _volumeTargets[i],
      multipleQuarters: _volumeQuarters[i],
    ),
  for (var i = 0; i < _streakTargets.length; i++)
    Quest(
      id: 'days_in_row:${_streakTargets[i]}',
      family: QuestFamily.consecutiveDays,
      target: _streakTargets[i],
      multipleQuarters: _streakQuarters[i],
    ),
]);

/// Where one quest stands, folded from the games.
class QuestStatus {
  const QuestStatus({
    required this.quest,
    required this.current,
    required this.achieved,
    required this.award,
    this.achievedAt,
  });

  final Quest quest;

  /// Progress toward [Quest.target], never above it.
  final int current;

  final bool achieved;

  /// What it paid, or 0 while it has not been earned.
  ///
  /// Zero rather than a projection, because for the volume and streak families
  /// the answer depends on *which* games earn it and there is no honest number
  /// before they exist.
  final int award;

  /// When the game that completed it finished, in local time, or null while it
  /// is unearned — or if that game carries no completion time, which the older
  /// documents do not.
  ///
  /// Not a second source of truth: every branch below already had to know which
  /// game finished the quest in order to price it, so this is that game's
  /// timestamp rather than anything new. It is what lets the app show what was
  /// achieved *recently* without folding the history a second time.
  final DateTime? achievedAt;

  /// For ranking, and for the number beside the bar.
  double get fraction => current / quest.target;

  int get remaining => quest.target - current;
}

/// Every quest's standing, from the games and nothing else.
///
/// [games] must be **oldest first**, ordered by completion, because the volume
/// family awards on the day it first fired and needs to know which games got
/// there. `points_fold.dart` in the app is the one place that ordering is
/// established, the same way it is for the rating.
///
/// [today] is the day boundary the streak family is evaluated against. It is a
/// parameter and never a clock read, so a fixture can put the player on any
/// day it likes (spec P19). Ticket 033 does not use it: the streak evaluator
/// arrives with ticket 034 and this signature exists now so that ticket adds a
/// body rather than a parameter to every caller.
List<QuestStatus> questStatuses(
  Iterable<ScoredGame> games, {
  required DateTime today,
}) {
  final ordered = games.toList();

  // Won at all, and won from the second seat, per opponent — and *when*, which
  // is the first such win rather than the latest. `putIfAbsent` over a list in
  // completion order is what makes it the first.
  final beaten = <int, DateTime?>{};
  final beatenSecond = <int, DateTime?>{};
  for (final game in ordered) {
    if (!game.won) continue;
    beaten.putIfAbsent(game.rosterIndex, () => game.completedAt);
    if (game.movedSecond) {
      beatenSecond.putIfAbsent(game.rosterIndex, () => game.completedAt);
    }
  }

  final days = _byDay(ordered);
  final runs = streakRuns(ordered);
  final live = currentStreak(ordered, today: today);

  return [
    for (final quest in questCatalogue)
      switch (quest.family) {
        QuestFamily.firstWin => _milestone(quest, beaten),
        QuestFamily.firstWinSecond => _milestone(quest, beatenSecond),
        QuestFamily.gamesInDay => _volume(quest, days),
        QuestFamily.consecutiveDays => _streak(quest, runs, live),
      },
  ];
}

QuestStatus _milestone(Quest quest, Map<int, DateTime?> done) {
  final achieved = done.containsKey(quest.rosterIndex);
  return QuestStatus(
    quest: quest,
    current: achieved ? 1 : 0,
    achieved: achieved,
    // One win against the opponent it names — 2ⁱ, the same amount whenever it
    // is claimed, which is what makes deferring it worth nothing (spec P9).
    award: achieved ? _award(quest.multipleQuarters, quest.rosterIndex!) : 0,
    achievedAt: done[quest.rosterIndex],
  );
}

/// The volume family, awarded on the **earliest** day that reached the rung.
///
/// Progress is the best day ever rather than today's, because a quest fires
/// exactly once and a rung already cleared cannot un-clear itself when the
/// next day starts quietly.
QuestStatus _volume(Quest quest, List<List<ScoredGame>> days) {
  var best = 0;
  for (final day in days) {
    if (day.length > best) best = day.length;
    if (day.length >= quest.target) {
      // The games that earned it: the ones up to and including the Nth of that
      // day. A day of a hundred games does not price the five-game rung.
      return QuestStatus(
        quest: quest,
        current: quest.target,
        achieved: true,
        award: _award(
          quest.multipleQuarters,
          _meanIndex(day.take(quest.target)),
        ),
        // The Nth game of that day — the one that reached the rung, not the
        // last of a day that went on well past it.
        achievedAt: day.take(quest.target).last.completedAt,
      );
    }
  }
  return QuestStatus(quest: quest, current: best, achieved: false, award: 0);
}

/// The streak family, priced exactly as the volume family is.
///
/// **Achieved** from the earliest run that ever reached the rung, so a rung
/// cannot un-fire when a streak later breaks. **Progress** is the streak the
/// player is on right now, which is the number they are actually building —
/// unlike the volume family, where "the best day you ever had" is the only
/// reading that means anything, a streak that has lapsed is genuinely back at
/// zero and saying otherwise would be a lie about the thing being measured
/// (D282).
QuestStatus _streak(Quest quest, List<StreakRun> runs, int live) {
  for (final run in runs) {
    if (run.length >= quest.target) {
      return QuestStatus(
        quest: quest,
        current: quest.target,
        achieved: true,
        award: _award(quest.multipleQuarters,
            _meanIndex(qualifyingGames(run, quest.target))),
        achievedAt: qualifyingGames(run, quest.target).last.completedAt,
      );
    }
  }
  return QuestStatus(
    quest: quest,
    current: live < quest.target ? live : quest.target,
    achieved: false,
    award: 0,
  );
}

/// Completed games grouped by local calendar day, days in chronological order
/// and games within a day in completion order.
///
/// A game with no completion time belongs to no day. It still counts toward
/// the two per-opponent families, which ask what was beaten rather than when.
List<List<ScoredGame>> _byDay(List<ScoredGame> ordered) {
  final byDay = <int, List<ScoredGame>>{};
  for (final game in ordered) {
    final at = game.completedAt;
    if (at == null) continue;
    // Local, and the app is what converts it. The package may not read a clock
    // and it may not guess a zone either.
    final key = at.year * 10000 + at.month * 100 + at.day;
    byDay.putIfAbsent(key, () => []).add(game);
  }
  final keys = byDay.keys.toList()..sort();
  return [for (final key in keys) byDay[key]!];
}

/// The mean **roster index** of [games], rounded to the nearest opponent.
///
/// The index and not the payout, and that is the whole reason this function
/// exists. Payouts double, so an arithmetic mean of them is dominated by the
/// single strongest game in the set: nineteen Pebble games and one Titan game
/// average 6,555 points, pricing twenty games at roughly a Corvus win on the
/// strength of one of them. Averaging the index and then exponentiating — the
/// geometric mean — gives 2 points, which is what nineteen trivial games and
/// one real one are worth (spec P12).
///
/// Rounding to an integer index also keeps the answer nameable: the interface
/// can say *your twenty games averaged Kestrel*, where a fractional exponent
/// is not a sentence.
int _meanIndex(Iterable<ScoredGame> games) {
  var sum = 0;
  var count = 0;
  for (final game in games) {
    sum += game.rosterIndex;
    count++;
  }
  if (count == 0) return 0;
  return (sum / count).round();
}

/// [quarters] quarter-wins against opponent [rosterIndex].
///
/// At least one point. The ¼ rung against the weakest opponents rounds to
/// nothing, and a quest that announces itself and pays zero reads as a defect
/// rather than as an honest valuation (D280).
int _award(int quarters, int rosterIndex) {
  final exact = quarters * winValue(rosterIndex);
  return (exact ~/ 4).clamp(1, exact);
}

/// The four closest to completion, for the main screen.
///
/// Ranked by percentage complete, ties going to the smaller absolute
/// remainder — so of two quests both a fifth of the way there, the one needing
/// four more games outranks the one needing twenty. Achieved quests are not
/// candidates: a finished thing is not close to finishing.
List<QuestStatus> closestQuests(
  Iterable<QuestStatus> statuses, {
  int count = 4,
}) {
  final open =
      [
        for (final s in statuses)
          if (!s.achieved) s,
      ]..sort((a, b) {
        final byFraction = b.fraction.compareTo(a.fraction);
        if (byFraction != 0) return byFraction;
        final byRemainder = a.remaining.compareTo(b.remaining);
        if (byRemainder != 0) return byRemainder;
        // Weakest opponent first among what is left. On a fresh install every
        // quest is at zero and tied on both rules above, and ordering forty
        // identical rungs by id would show four opponents picked
        // alphabetically. Roster order is what answers the question the
        // section is asking.
        final byOpponent = _rank(a.quest).compareTo(_rank(b.quest));
        if (byOpponent != 0) return byOpponent;
        // Last resort, so the list does not reshuffle on every rebuild.
        return a.quest.id.compareTo(b.quest.id);
      });
  return open.take(count).toList();
}

/// The most recently achieved, newest first, for the main screen.
///
/// The mirror of [closestQuests]: that one answers "what next", this one
/// answers "what just happened". Only achieved quests are candidates, and they
/// are ordered by [QuestStatus.achievedAt].
///
/// **A quest whose completing game carries no timestamp sorts last, not first.**
/// Documents written before completion times were stored have none, and a null
/// treated as "now" would pin the oldest history permanently at the top of a
/// list about recency.
List<QuestStatus> recentlyAchieved(
  Iterable<QuestStatus> statuses, {
  int count = 4,
}) {
  final done =
      [
        for (final s in statuses)
          if (s.achieved) s,
      ]..sort((a, b) {
        final at = a.achievedAt;
        final bt = b.achievedAt;
        if (at == null && bt == null) return a.quest.id.compareTo(b.quest.id);
        if (at == null) return 1;
        if (bt == null) return -1;
        final byTime = bt.compareTo(at);
        if (byTime != 0) return byTime;
        // Two quests finished by the same game — the fifth game of a day can
        // complete a volume rung and a streak rung at once. The bigger award
        // leads, and the id settles it so the order does not wander.
        final byAward = b.award.compareTo(a.award);
        return byAward != 0 ? byAward : a.quest.id.compareTo(b.quest.id);
      });
  return done.take(count).toList();
}

/// Where a quest sits in roster order. The volume and streak families name no
/// opponent, so they sort after every one that does.
int _rank(Quest quest) => quest.rosterIndex ?? opponentCatalogue.length;

/// What [after] achieved that [before] had not — the acknowledgement one game
/// earns, derived by folding the history twice rather than by storing a thing.
List<QuestStatus> newlyAchieved(
  Iterable<QuestStatus> before,
  Iterable<QuestStatus> after,
) {
  final was = {
    for (final s in before)
      if (s.achieved) s.quest.id,
  };
  return [
    for (final s in after)
      if (s.achieved && !was.contains(s.quest.id)) s,
  ];
}
