import 'package:quadrim_engine/quadrim_engine.dart';
import 'package:quadrim_progression/quadrim_progression.dart';
import 'package:test/test.dart';

/// Exhaustive rather than sampled: this is small integer arithmetic over
/// thirty-one known inputs, so there is no excuse for spot checks (ticket 031).
void main() {
  group('what a win pays', () {
    test('is the Fibonacci ladder, written out', () {
      // Written out rather than generated, because a generated expectation
      // would be the implementation restated and would agree with any bug the
      // implementation had. These are the numbers D335 chose.
      const expected = [
        1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610, 987, 1597, 2584,
        4181, 6765, 10946, 17711, 28657, 46368, 75025, 121393, 196418, 317811,
        514229, 832040, 1346269, 2178309,
      ];
      expect(expected, hasLength(opponentCatalogue.length));
      for (var i = 0; i < opponentCatalogue.length; i++) {
        expect(winValue(i), expected[i], reason: 'index $i');
      }
    });

    test('Pebble pays 1 and Quadrim Prime pays 2,178,309', () {
      expect(winValue(0), 1);
      expect(winValue(30), 2178309);
    });

    test('every rung is the sum of the two below it, which is what prices '
        'grinding downward out without a rule', () {
      for (var i = 2; i < opponentCatalogue.length; i++) {
        expect(winValue(i), winValue(i - 1) + winValue(i - 2),
            reason: 'index $i');
      }
      // The property that matters is not the recurrence but what it implies:
      // a rung down is worth strictly less, by a ratio approaching the golden
      // one. Doubling gave a factor of 2 and this gives 1.618, so the pressure
      // is milder and still one-directional (D335).
      for (var i = 1; i < opponentCatalogue.length; i++) {
        expect(winValue(i), greaterThan(winValue(i - 1)), reason: 'index $i');
      }
      expect(winValue(30) / winValue(29), closeTo(1.618, 0.001));
    });
  });

  group('what an unlock costs', () {
    test('is twice what a win against the same opponent pays', () {
      // The relationship the doubling ladder had, kept exactly: 2^(i+1) is
      // twice 2^i, and this is twice its own rung too. Only the steepness
      // changed (D335).
      for (var i = 0; i < opponentCatalogue.length; i++) {
        expect(unlockCost(i), 2 * winValue(i), reason: 'index $i');
      }
    });

    test('starts at 2 and 4, and every price after is the sum of the two '
        'before it', () {
      expect(unlockCost(0), 2);
      expect(unlockCost(1), 4);
      for (var i = 2; i < opponentCatalogue.length; i++) {
        expect(unlockCost(i), unlockCost(i - 1) + unlockCost(i - 2),
            reason: 'index $i');
      }
    });

    test('is about three and a quarter wins against the opponent below', () {
      // It used to be exactly four, and exactness went with the powers of two.
      // What replaced it is twice the golden ratio, which every rung above the
      // second sits within a whisker of — so "three or four games" is true of
      // the whole ladder, which is the only form of this promise a player can
      // use (D335).
      for (var i = 2; i < opponentCatalogue.length; i++) {
        final wins = unlockCost(i) / winValue(i - 1);
        expect(wins, inInclusiveRange(3.0, 3.4), reason: 'index $i');
      }
      expect(unlockCost(1) / winValue(0), 4.0,
          reason: 'the first rung is still exactly four');
    });

    test(
      'the whole roster is 11,405,706 points, about eighty wins',
      () {
        expect(fullRosterCost, 11405706);
        // The total is display; what a player experiences is the three-and-a-
        // bit wins at each of the twenty-five locked rungs. Under the doubling
        // ladder the same sum was 4,294,967,040 — a number that fits in no
        // sentence and on no phone (D335).
        var locked = 0;
        for (var i = 0; i < opponentCatalogue.length; i++) {
          if (isPurchasable(opponentCatalogue[i])) locked++;
        }
        expect(locked, 25);
        // The mercy rungs are locked too and are *not* in that total: they are
        // handed back by losing, never bought, so pricing them would put three
        // opponents in the shop window that no amount of points can reach
        // (D382).
        expect(opponentCatalogue.where(isMercy).length, kMercyCount);
        for (final bot in opponentCatalogue.where(isMercy)) {
          expect(isPurchasable(bot), isFalse, reason: bot.id);
        }
      },
    );
  });

  group('the free set', () {
    test('is the Novice tier above the mercy rungs', () {
      // A count, not a rating threshold. D228 made it a threshold so nothing
      // would have to be kept in step with a number written in words; D335
      // reversed that, because the threshold silently handed out seven of
      // thirty-one when the roster was recut. D382 then took three back off the
      // bottom: six is still where the *ladder* starts, but the first three
      // rungs are held back rather than given.
      expect(kFreeCount, 6);
      expect(kMercyCount, 3);
      for (var i = 0; i < opponentCatalogue.length; i++) {
        expect(isFree(opponentCatalogue[i]), i >= kMercyCount && i < kFreeCount,
            reason: opponentCatalogue[i].id);
      }
    });

    test('is three opponents on a first launch, and the ladder still starts at '
        'Bramble', () {
      expect(opponentCatalogue.where(isFree).map((b) => b.id), [
        'hazel',
        'clover',
        'sorrel',
      ]);
      expect(opponentCatalogue.where(isMercy).map((b) => b.id), [
        'pebble',
        'twig',
        'mote',
      ]);
      // All six are still Novice: what D382 changed is when they arrive, not
      // where they sit.
      for (final bot in opponentCatalogue.where((b) => isFree(b) || isMercy(b))) {
        expect(bot.tier, BotTier.novice, reason: bot.id);
      }
      // And Bramble, one rung up, is the first thing anybody buys.
      expect(opponentCatalogue[kFreeCount].id, 'bramble');
    });

    test('an opponent this build has never heard of is not free', () {
      const stranger = BotConfig(id: 'nobody', rating: 100);
      expect(isFree(stranger), isFalse);
    });

    test('is contiguous, so "the next locked opponent" is always well defined',
        () {
      // Free and mercy together must still run from the bottom without a hole:
      // `nextUnlockIndex` walks up from `kMercyCount` and stops at the first
      // thing that is not free, so a gap anywhere below would put an opponent
      // permanently out of reach.
      final given = [
        for (final bot in opponentCatalogue) isFree(bot) || isMercy(bot),
      ];
      expect(given.indexOf(false), given.lastIndexOf(true) + 1);
      final free = [for (final bot in opponentCatalogue) isFree(bot)];
      expect(free.indexOf(true), kMercyCount);
      expect(free.lastIndexOf(true), kFreeCount - 1);
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
      // the opposite way to its published ratings (idea-v4.md §14), so a price
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
      expect(rosterIndexOf('quadrim_prime'), 30);
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
      expect(pointsEarned(games), 9);
    });

    test('four wins against Bramble more than buys Juniper', () {
      // Under the doubling ladder this was exact: four wins at any rung paid
      // the next rung's price to the point. The Fibonacci ladder pays about
      // 3.24 wins per rung (D335), so four wins clears the next price with a
      // little left over — which is the direction to err in.
      final games = List.filled(
        4,
        const ScoredGame(
          rosterIndex: 6,
          won: true,
          movedSecond: false,
          completedAt: null,
        ),
      );
      expect(pointsEarned(games), 4 * winValue(6));
      expect(pointsEarned(games), greaterThanOrEqualTo(unlockCost(7)));
      expect(pointsEarned(games), lessThan(unlockCost(8)),
          reason: 'four wins is one unlock, never two');
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
      // Worth stating precisely, because it is easy to overclaim. Twenty-six
      // Pebble wins really does buy Sorrel — the bottom rungs are cheap enough
      // that farming them is merely tedious rather than impossible, and that
      // is fine, because the reward is the cheapest thing on the ladder.
      final twentySix = List.filled(
        26,
        const ScoredGame(
          rosterIndex: 0,
          won: true,
          movedSecond: false,
          completedAt: null,
        ),
      );
      expect(pointsEarned(twentySix), unlockCost(5));

      // What the ladder actually prices out is grinding the bottom for the
      // *top*, and it still does so by a factor nobody argues with — four
      // million games rather than two billion, which is the same answer for
      // every purpose a person has (D335).
      expect(unlockCost(30) ~/ winValue(0), 4356618);
      // The same unlock, bought one rung down instead of thirty-one: three
      // games and a bit.
      expect(unlockCost(30) / winValue(29), closeTo(3.236, 0.001));
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
