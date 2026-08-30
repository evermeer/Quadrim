import 'package:quadrim_engine/quadrim_engine.dart';
import 'package:quadrim_progression/quadrim_progression.dart';
import 'package:test/test.dart';

/// The economy's most fragile rule has a whole file, because it has already
/// been got wrong twice in opposite directions (D261, D270): **a quest is
/// priced by the opponents it was earned against, never by how high the player
/// has climbed.**

final _today = DateTime(2026, 8, 14);

ScoredGame _game(
  int index, {
  bool won = true,
  bool second = false,
  DateTime? at,
}) => ScoredGame(
  rosterIndex: index,
  won: won,
  movedSecond: second,
  completedAt: at,
);

/// [count] games against [index], all on one day, in completion order.
List<ScoredGame> _day(DateTime day, int count, {int index = 0}) => [
  for (var i = 0; i < count; i++)
    _game(index, at: day.add(Duration(minutes: i))),
];

QuestStatus _status(List<ScoredGame> games, String id) =>
    questStatuses(games, today: _today).firstWhere((s) => s.quest.id == id);

void main() {
  group('the catalogue', () {
    test('is seventy-six quests across four families', () {
      expect(questCatalogue, hasLength(76));
      int count(QuestFamily f) =>
          questCatalogue.where((q) => q.family == f).length;
      expect(count(QuestFamily.firstWin), 31);
      expect(count(QuestFamily.firstWinSecond), 31);
      expect(count(QuestFamily.gamesInDay), 5);
      expect(count(QuestFamily.consecutiveDays), 9);
    });

    test(
      'every id is distinct, because progress is ranked and diffed by it',
      () {
        expect(questCatalogue.map((q) => q.id).toSet(), hasLength(76));
      },
    );

    test('the per-opponent families name every opponent exactly once', () {
      for (final family in [QuestFamily.firstWin, QuestFamily.firstWinSecond]) {
        final named = [
          for (final q in questCatalogue)
            if (q.family == family) q.rosterIndex,
        ];
        expect(named, [for (var i = 0; i < opponentCatalogue.length; i++) i]);
      }
    });

    test('the volume and streak rungs are the ones the spec lists', () {
      List<int> targets(QuestFamily f) => [
        for (final q in questCatalogue)
          if (q.family == f) q.target,
      ];
      expect(targets(QuestFamily.gamesInDay), [5, 10, 20, 50, 100]);
      expect(targets(QuestFamily.consecutiveDays), [
        5,
        10,
        30,
        90,
        180,
        360,
        720,
        1080,
        1440,
      ]);
    });
  });

  group('a per-opponent quest', () {
    test('pays one win against the opponent it names', () {
      for (var i = 0; i < opponentCatalogue.length; i++) {
        final id = opponentCatalogue[i].id;
        final status = _status([_game(i)], 'first_win:$id');
        expect(status.achieved, isTrue, reason: id);
        expect(status.award, winValue(i), reason: id);
      }
    });

    test(
      'pays the same whenever it is claimed, so deferring it earns nothing',
      () {
        // The failure D261 records: under a current-rung rule these eight games
        // against the weakest opponents, banked to rung 19, paid 4,194,304 —
        // twice the cost of the entire roster.
        final early = _status([_game(0)], 'first_win:pebble').award;
        final afterClimbing = _status([
          _game(0),
          for (var i = 1; i < 20; i++) _game(i),
        ], 'first_win:pebble').award;
        expect(early, 1);
        expect(afterClimbing, early);

        final banked = [
          for (var i = 0; i < 4; i++)
            _status(
              [_game(i)],
              'first_win:'
              '${opponentCatalogue[i].id}',
            ).award,
        ].fold(0, (a, b) => a + b);
        expect(banked, 11, reason: 'the four cheapest, worth 1+2+3+5');
        expect(banked, lessThan(fullRosterCost));
      },
    );

    test('a loss against an opponent achieves nothing', () {
      expect(
        _status([_game(3, won: false)], 'first_win:clover').achieved,
        isFalse,
      );
    });

    test('fires exactly once however often it is repeated', () {
      final many = [for (var i = 0; i < 50; i++) _game(2)];
      final status = _status(many, 'first_win:mote');
      expect(status.current, 1);
      expect(status.award, winValue(2));
      expect(
        newlyAchieved(
          questStatuses(many, today: _today),
          questStatuses([...many, _game(2)], today: _today),
        ),
        isEmpty,
      );
    });
  });

  group('the second-player family', () {
    test('needs a win from the second seat, which the first-win family does '
        'not', () {
      // Index 6 is Bramble since the roster was recut; it was Vireo (D333).
      // The quest ids are built from the catalogue, so the name has to follow
      // the index rather than the other way round.
      final first = [_game(6, second: false)];
      expect(_status(first, 'first_win:bramble').achieved, isTrue);
      expect(_status(first, 'first_win_second:bramble').achieved, isFalse);

      final second = [_game(6, second: true)];
      expect(_status(second, 'first_win_second:bramble').achieved, isTrue);
      expect(_status(second, 'first_win_second:bramble').award, winValue(6));
    });

    test('a loss from the second seat achieves nothing', () {
      expect(
        _status([
          _game(6, second: true, won: false),
        ], 'first_win_second:vireo').achieved,
        isFalse,
      );
    });
  });

  group('the volume family', () {
    test('a hundred Pebble games in one day pays four points', () {
      final games = _day(DateTime(2026, 5, 1), 100);
      expect(_status(games, 'games_in_day:100').award, 4);
    });

    test('and pays the same four to a player who has beaten Titan', () {
      // The failure D270 records: priced at the player's rung this afternoon
      // of tapping paid 524,288 — four Titan wins.
      final richer = [
        for (var i = 0; i < 20; i++) _game(i, at: DateTime(2026, 4, 1, i)),
        ..._day(DateTime(2026, 5, 1), 100),
      ];
      expect(_status(richer, 'games_in_day:100').award, 4);
    });

    test('averages the roster index and not the payouts', () {
      // Nineteen Pebble games and one game at index 17. The mean index is
      // 0.85, which rounds to Twig, so the set is worth 2 points. Averaging
      // the payouts would have given (19 * 1 + 4181) / 20 = 210 — pricing
      // twenty games at roughly a Kestrel win on the strength of one of them.
      // The arithmetic is less lurid under the Fibonacci ladder than under the
      // doubling one, where the same set came to 6,554; the mistake is
      // identical and a hundred times smaller (D335).
      final day = DateTime(2026, 5, 2);
      final games = [
        ..._day(day, 19),
        _game(17, at: day.add(const Duration(minutes: 19))),
      ];
      expect(_status(games, 'games_in_day:20').award, 2);

      final meanPayout = (19 * winValue(0) + winValue(17)) ~/ 20;
      expect(
        meanPayout,
        210,
        reason: 'recorded so the rejected arithmetic stays visible',
      );
    });

    test('a day of a hundred games does not price the five-game rung by its '
        'best games', () {
      // The first five of that day are what earned the five-game rung.
      final day = DateTime(2026, 5, 3);
      final games = [
        ..._day(day, 5),
        for (var i = 0; i < 95; i++)
          _game(19, at: day.add(Duration(minutes: 5 + i))),
      ];
      expect(_status(games, 'games_in_day:5').award, 1);
      // Where the hundred-game rung, earned by the whole day, is worth the
      // mean of all hundred.
      expect(_status(games, 'games_in_day:100').award, greaterThan(1));
    });

    test('counts games rather than wins', () {
      final games = _day(DateTime(2026, 5, 4), 10, index: 8)
          .map(
            (g) => ScoredGame(
              rosterIndex: g.rosterIndex,
              won: false,
              movedSecond: g.movedSecond,
              completedAt: g.completedAt,
            ),
          )
          .toList();
      expect(_status(games, 'games_in_day:10').achieved, isTrue);
    });

    test('does not add days together', () {
      final games = [
        ..._day(_today.subtract(const Duration(days: 1)), 4),
        ..._day(_today, 4),
      ];
      final status = _status(games, 'games_in_day:5');
      expect(status.achieved, isFalse);
      expect(status.current, 4, reason: "today's four, not eight");
    });

    test('a new day resets an unachieved rung to zero', () {
      // Reported from a device: sixteen games yesterday and none today still
      // read "16 of 20", which says four more games would do it when in fact
      // twenty would. Progress toward a target that says *in one day* cannot
      // be carried across the day boundary (D317).
      final games = _day(_today.subtract(const Duration(days: 1)), 16);
      final status = _status(games, 'games_in_day:20');
      expect(status.achieved, isFalse);
      expect(status.current, 0);
      expect(status.remaining, 20, reason: 'the whole rung, not four of it');
    });

    test('today counts even when a better day came before it', () {
      // The mirror of the above: progress is today's, not the best ever, and
      // that cuts both ways.
      final games = [
        ..._day(_today.subtract(const Duration(days: 3)), 9),
        ..._day(_today, 2),
      ];
      expect(_status(games, 'games_in_day:10').current, 2);
    });

    test('a day already cleared stays cleared when a quiet day follows', () {
      final games = [
        ..._day(DateTime(2026, 5, 7), 20),
        ..._day(DateTime(2026, 5, 8), 1),
      ];
      expect(_status(games, 'games_in_day:20').achieved, isTrue);
    });

    test('a game with no completion time belongs to no day', () {
      final games = [for (var i = 0; i < 10; i++) _game(0)];
      expect(_status(games, 'games_in_day:5').current, 0);
      // It still counts toward what was beaten, which asks what and not when.
      expect(_status(games, 'first_win:pebble').achieved, isTrue);
    });

    test('never pays nothing, however weak the opposition', () {
      // Five Pebble games are worth a quarter of a point. Rounding it to zero
      // and announcing the achievement anyway reads as a defect (D280).
      expect(_status(_day(DateTime(2026, 5, 9), 5), 'games_in_day:5').award, 1);
    });
  });

  group('the streak family', () {
    test(
      'is present and unevaluated, which is ticket 034 and not a defect',
      () {
        final streaks = questStatuses(
          [],
          today: _today,
        ).where((s) => s.quest.family == QuestFamily.consecutiveDays);
        expect(streaks, hasLength(9));
        expect(streaks.every((s) => !s.achieved), isTrue);
      },
    );
  });

  group('the four closest', () {
    test('rank by percentage complete', () {
      // Today's nine, because a volume rung's progress is today's (D317) and
      // nine games two months ago would rank it at zero.
      final games = _day(_today, 9);
      final closest = closestQuests(questStatuses(games, today: _today));
      expect(closest, hasLength(4));
      // Nine games in a day is 90% of the ten-game rung and 45% of the
      // twenty-game one, so the ten-game rung leads.
      expect(closest.first.quest.id, 'games_in_day:10');
      for (var i = 1; i < closest.length; i++) {
        expect(closest[i].fraction, lessThanOrEqualTo(closest[i - 1].fraction));
      }
    });

    test('ties go to the smaller absolute remainder, then to roster order', () {
      // Nothing played: every quest is at zero. Of those, the ones needing one
      // more thing outrank the ones needing five — and among forty rungs that
      // are all tied on both rules, the weakest opponents come first. Ordering
      // by id instead would open the section with four opponents chosen
      // alphabetically, which answers nobody's question (D281).
      final closest = closestQuests(questStatuses([], today: _today));
      expect(closest.every((s) => s.quest.target == 1), isTrue);
      expect(closest.map((s) => s.quest.id),
          ['first_win:pebble', 'first_win_second:pebble', 'first_win:twig',
           'first_win_second:twig']);
    });

    test('an achieved quest is not a candidate', () {
      final games = [_game(0), _game(1)];
      final closest = closestQuests(questStatuses(games, today: _today));
      expect(
        closest.map((s) => s.quest.id),
        isNot(contains('first_win:pebble')),
      );
      expect(closest.every((s) => !s.achieved), isTrue);
    });

    test('is stable between two identical folds', () {
      final games = _day(DateTime(2026, 6, 2), 3);
      final a = closestQuests(questStatuses(games, today: _today));
      final b = closestQuests(questStatuses(games, today: _today));
      expect(a.map((s) => s.quest.id), b.map((s) => s.quest.id));
    });
  });

  group('what one game achieved', () {
    test('is the difference between the fold with it and without it', () {
      final before = [_game(0, at: DateTime(2026, 7, 1))];
      final after = [
        ...before,
        _game(1, second: true, at: DateTime(2026, 7, 1)),
      ];
      final fresh = newlyAchieved(
        questStatuses(before, today: _today),
        questStatuses(after, today: _today),
      );
      expect(
        fresh.map((s) => s.quest.id),
        unorderedEquals(['first_win:twig', 'first_win_second:twig']),
      );
      expect(fresh.fold(0, (sum, s) => sum + s.award), 2 * winValue(1));
    });

    test('is empty when a game achieves nothing new', () {
      final before = [_game(0), _game(0)];
      final after = [...before, _game(0)];
      expect(
        newlyAchieved(
          questStatuses(before, today: _today),
          questStatuses(after, today: _today),
        ),
        isEmpty,
      );
    });
  });

  group('no reward anywhere is priced by the player', () {
    test('no signature accepts a rating or a rung', () {
      // Carried by the types: the only inputs are a quest, a list of games and
      // a day boundary. There is nowhere to pass the player's height even by
      // mistake, which is the point of D261 and D270.
      expect(questStatuses(const [], today: _today), hasLength(76));
      expect(closestQuests(const []), isEmpty);
      expect(newlyAchieved(const [], const []), isEmpty);
    });
  });

  group('recentlyAchieved', () {
    ScoredGame game(int index, int day, {bool won = true}) => ScoredGame(
          rosterIndex: index,
          won: won,
          movedSecond: false,
          completedAt: DateTime(2026, 3, day, 12),
        );

    test('is the mirror of closestQuests: only finished, newest first', () {
      final statuses = questStatuses(
        [game(0, 1), game(1, 2), game(2, 3)],
        today: DateTime(2026, 3, 3),
      );
      final recent = recentlyAchieved(statuses);
      expect(recent, hasLength(3), reason: 'three first wins');
      expect(recent.every((s) => s.achieved), isTrue);
      // Newest first: Mote was beaten on the 3rd, Pebble on the 1st.
      expect(recent.first.quest.rosterIndex, 2);
      expect(recent.last.quest.rosterIndex, 0);
    });

    test('takes four at most, newest first, whatever family they are', () {
      // Six wins on six consecutive days finishes six per-opponent quests and
      // the five-day streak as well — and the streak is *not* a special case
      // to be filtered out. Asserted as a property rather than as a
      // hand-written list of roster indices, which is what the first version
      // of this test did and which quietly assumed only one family could fire.
      final statuses = questStatuses(
        [for (var i = 0; i < 6; i++) game(i, i + 1)],
        today: DateTime(2026, 3, 7),
      );
      final recent = recentlyAchieved(statuses);
      expect(recent, hasLength(4));
      expect(recent.every((s) => s.achieved), isTrue);
      for (var i = 1; i < recent.length; i++) {
        expect(recent[i].achievedAt!.isAfter(recent[i - 1].achievedAt!), isFalse,
            reason: 'entry $i is not newer than the one before it');
      }
      // The newest is the sixth day's win, and nothing older than the third
      // day survives the cut.
      expect(recent.first.achievedAt, DateTime(2026, 3, 6, 12));
      expect(recent.last.achievedAt!.day, greaterThanOrEqualTo(3));
      expect(
          questStatuses([for (var i = 0; i < 6; i++) game(i, i + 1)],
                  today: DateTime(2026, 3, 7))
              .where((s) => s.achieved)
              .length,
          greaterThan(4),
          reason: 'more were finished than the four shown');
    });

    test('a quest earned by a game with no completion time sorts last', () {
      // Documents written before completion times were stored have none. A
      // null read as "now" would pin the oldest history at the top of a list
      // about recency, which is the one thing it must not do.
      final statuses = questStatuses(
        [
          const ScoredGame(
              rosterIndex: 0, won: true, movedSecond: false, completedAt: null),
          game(1, 1),
        ],
        today: DateTime(2026, 3, 2),
      );
      final recent = recentlyAchieved(statuses);
      expect(recent.first.quest.rosterIndex, 1);
      expect(recent.last.quest.rosterIndex, 0);
      expect(recent.last.achievedAt, isNull);
    });

    test('the volume family is timed by the game that reached the rung, not '
        'the last of the day', () {
      // Ten games on one day: the five-game rung was completed by the fifth,
      // and a day that carried on to ten does not make it more recent.
      final day = [
        for (var i = 0; i < 10; i++)
          ScoredGame(
            rosterIndex: 0,
            won: true,
            movedSecond: false,
            completedAt: DateTime(2026, 3, 1, 9, i),
          ),
      ];
      final five = questStatuses(day, today: DateTime(2026, 3, 1))
          .firstWhere((s) =>
              s.quest.family == QuestFamily.gamesInDay && s.quest.target == 5);
      expect(five.achieved, isTrue);
      expect(five.achievedAt, DateTime(2026, 3, 1, 9, 4));
    });
  });
}
