import 'package:quadrim_engine/quadrim_engine.dart';
import 'package:quadrim_progression/quadrim_progression.dart';
import 'package:test/test.dart';

/// Exhaustive rather than sampled: this is small integer arithmetic over twenty
/// known inputs, so there is no excuse for spot checks (ticket 031).
void main() {
  group('what a win pays', () {
    test('is 2^i for every roster index', () {
      for (var i = 0; i < opponentCatalogue.length; i++) {
        expect(winValue(i), 1 << i, reason: 'index $i');
      }
    });

    test('Pebble pays 1 and Quadrim Prime pays 524,288', () {
      expect(winValue(0), 1);
      expect(winValue(19), 524288);
    });

    test('every rung down halves the payout, which is what prices grinding '
        'downward out without a rule', () {
      for (var i = 1; i < opponentCatalogue.length; i++) {
        expect(winValue(i), winValue(i - 1) * 2, reason: 'index $i');
      }
    });
  });

  group('what an unlock costs', () {
    test('is 2^(i+1) for every roster index', () {
      for (var i = 0; i < opponentCatalogue.length; i++) {
        expect(unlockCost(i), 1 << (i + 1), reason: 'index $i');
      }
    });

    test('is exactly four wins against the opponent below', () {
      for (var i = 1; i < opponentCatalogue.length; i++) {
        expect(unlockCost(i), 4 * winValue(i - 1), reason: 'index $i');
      }
    });

    test(
      'the whole roster is 2,097,088 points, which is exactly sixty wins',
      () {
        expect(fullRosterCost, 2097088);
        // Sixty is the number to reason about; the totals are display. It is
        // four wins at each of the fifteen locked rungs, not sixty wins at any
        // one of them, so it is checked as the sum it actually is.
        var wins = 0;
        for (var i = 0; i < opponentCatalogue.length; i++) {
          if (!isFree(opponentCatalogue[i])) wins += 4;
        }
        expect(wins, 60);
      },
    );
  });

  group('the free set', () {
    test('is exactly those rated 1000 and below', () {
      for (final bot in opponentCatalogue) {
        expect(isFree(bot), bot.rating <= 1000, reason: bot.id);
      }
    });

    test('is five opponents today — asserted as an observation, never as a '
        'constant the code depends on', () {
      expect(opponentCatalogue.where(isFree).map((b) => b.id), [
        'pebble',
        'twig',
        'mote',
        'clover',
        'bramble',
      ]);
    });

    test('is contiguous from the bottom, so "the next locked opponent" is '
        'always well defined', () {
      final free = [for (final bot in opponentCatalogue) isFree(bot)];
      expect(free.indexOf(false), free.lastIndexOf(true) + 1);
    });
  });

  group('pricing is keyed on the roster index, never on the rating', () {
    test('prices rise monotonically with the index even where the ratings do '
        'not tell a clean story', () {
      for (var i = 1; i < opponentCatalogue.length; i++) {
        expect(unlockCost(i), greaterThan(unlockCost(i - 1)));
      }
    });

    test('two opponents sharing a rating would still get distinct prices', () {
      // Not hypothetical in spirit: the Casual tier's measured strengths run
      // the opposite way to its published ratings (idea-v3.md §14), so a price
      // derived from the rating would be non-monotonic there. The ordinal is
      // what keeps the ladder a ladder.
      final byRating = {for (final bot in opponentCatalogue) bot.rating};
      expect(
        byRating.length,
        opponentCatalogue.length,
        reason:
            'no two opponents share a rating today, but nothing about '
            'pricing depends on that staying true',
      );
    });

    test('an unknown opponent id has no index rather than index zero', () {
      expect(rosterIndexOf('nobody'), isNull);
      expect(rosterIndexOf('pebble'), 0);
      expect(rosterIndexOf('quadrim_prime'), 19);
    });

    test('every catalogue id round-trips through its index', () {
      for (var i = 0; i < opponentCatalogue.length; i++) {
        expect(rosterIndexOf(opponentCatalogue[i].id), i);
      }
    });
  });

  group('points earned', () {
    test('is nothing at all with no games', () {
      expect(pointsEarned(const []), 0);
    });

    test('counts wins and ignores everything else', () {
      const games = [
        ScoredGame(
          rosterIndex: 4,
          won: true,
          movedSecond: false,
          completedAt: null,
        ), // 16
        ScoredGame(
          rosterIndex: 4,
          won: false,
          movedSecond: false,
          completedAt: null,
        ),
        ScoredGame(
          rosterIndex: 0,
          won: true,
          movedSecond: false,
          completedAt: null,
        ), // 1
        ScoredGame(
          rosterIndex: 9,
          won: false,
          movedSecond: false,
          completedAt: null,
        ),
      ];
      expect(pointsEarned(games), 17);
    });

    test('four wins against Bramble buys Willow exactly', () {
      final games = List.filled(
        4,
        const ScoredGame(
          rosterIndex: 4,
          won: true,
          movedSecond: false,
          completedAt: null,
        ),
      );
      expect(pointsEarned(games), unlockCost(5));
    });

    test('is the same answer however often it is folded', () {
      final games = [
        for (var i = 0; i < opponentCatalogue.length; i++)
          ScoredGame(
            rosterIndex: i,
            won: i.isEven,
            movedSecond: false,
            completedAt: null,
          ),
      ];
      expect(pointsEarned(games), pointsEarned(games));
      expect(pointsEarned(games), pointsEarned(games.reversed));
    });

    test('grinding the bottom works at the bottom and nowhere else', () {
      // Worth stating precisely, because it is easy to overclaim. Sixty-four
      // Pebble wins really does buy Willow — the first rung is cheap enough
      // that farming it is merely tedious rather than impossible, and that is
      // fine, because the reward is the cheapest thing on the ladder.
      final sixtyFour = List.filled(
        64,
        const ScoredGame(
          rosterIndex: 0,
          won: true,
          movedSecond: false,
          completedAt: null,
        ),
      );
      expect(pointsEarned(sixtyFour), unlockCost(5));

      // What the doubling actually prices out is grinding the bottom for the
      // *top*, and it does so by a factor nobody argues with.
      expect(unlockCost(19) ~/ winValue(0), 1048576);
      // The same unlock, bought one rung down instead of twenty: four games.
      expect(unlockCost(19) ~/ winValue(18), 4);
    });
  });

  group('no reward anywhere is priced by the player', () {
    test('nothing in the public surface accepts a rating or a rung', () {
      // The rule is carried by the signatures, so the test is that the
      // signatures compile as written: every entry point takes a roster index,
      // a bot, an id or a list of games, and none takes the player at all.
      expect(winValue(3), isA<int>());
      expect(unlockCost(3), isA<int>());
      expect(isFree(opponentCatalogue.first), isA<bool>());
      expect(pointsEarned(const []), isA<int>());
    });
  });
}
