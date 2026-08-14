import 'package:quadrim_engine/quadrim_engine.dart';

import 'points.dart';

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
/// Specified here and evaluated in ticket 034: the calendar arithmetic needs
/// an injected day boundary and a deliberate answer for time-zone changes,
/// which is a ticket of its own.
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

  // Won at all, and won from the second seat, per opponent.
  final beaten = <int>{};
  final beatenSecond = <int>{};
  for (final game in ordered) {
    if (!game.won) continue;
    beaten.add(game.rosterIndex);
    if (game.movedSecond) beatenSecond.add(game.rosterIndex);
  }

  final days = _byDay(ordered);

  return [
    for (final quest in questCatalogue)
      switch (quest.family) {
        QuestFamily.firstWin => _milestone(quest, beaten),
        QuestFamily.firstWinSecond => _milestone(quest, beatenSecond),
        QuestFamily.gamesInDay => _volume(quest, days),
        // Ticket 034. Reported as untouched rather than as absent, so the
        // rungs are visible from 0.1 and only the evaluator is missing.
        QuestFamily.consecutiveDays => QuestStatus(
          quest: quest,
          current: 0,
          achieved: false,
          award: 0,
        ),
      },
  ];
}

QuestStatus _milestone(Quest quest, Set<int> done) {
  final achieved = done.contains(quest.rosterIndex);
  return QuestStatus(
    quest: quest,
    current: achieved ? 1 : 0,
    achieved: achieved,
    // One win against the opponent it names — 2ⁱ, the same amount whenever it
    // is claimed, which is what makes deferring it worth nothing (spec P9).
    award: achieved ? _award(quest.multipleQuarters, quest.rosterIndex!) : 0,
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
      );
    }
  }
  return QuestStatus(quest: quest, current: best, achieved: false, award: 0);
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
