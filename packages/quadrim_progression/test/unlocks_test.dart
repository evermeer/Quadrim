import 'package:quadrim_engine/quadrim_engine.dart';
import 'package:quadrim_progression/quadrim_progression.dart';
import 'package:test/test.dart';

String _idAt(int i) => opponentCatalogue[i].id;
Set<String> _unlockedUpTo(int highest) =>
    {for (var i = 0; i <= highest; i++) _idAt(i)};

void main() {
  group('the balance', () {
    test('is earned when nothing has been spent', () {
      expect(balance(earned: 500, pricesPaid: const []), 500);
    });

    test('is earned minus the prices actually paid', () {
      expect(balance(earned: 500, pricesPaid: const [64, 128]), 308);
    });

    test('uses the stored price, not the current table', () {
      // The whole reason pricePaid is stored (spec §8.8): re-tuning a cost must
      // never retroactively bankrupt someone who spent at the old price.
      final atOldPrice = balance(earned: 100, pricesPaid: const [40]);
      expect(atOldPrice, 60);
      // The table saying 64 today changes nothing about what was paid.
      expect(unlockCost(5), 26);
      expect(atOldPrice, 60);
    });

    test('clamps at zero rather than going negative', () {
      expect(balance(earned: 10, pricesPaid: const [64]), 0);
      expect(balance(earned: 0, pricesPaid: const [4356618]), 0);
    });
  });

  group('what may be bought next', () {
    test('is the first opponent past the free set, on a fresh install', () {
      // Six free, so index 6 (D335). It was seven while the free set was a
      // rating threshold rather than a count.
      final next = nextUnlockIndex(const {});
      expect(next, kFreeCount);
      expect(opponentCatalogue[next!].id, 'bramble');
    });

    test('advances by exactly one as each is bought', () {
      for (var i = kFreeCount; i < opponentCatalogue.length; i++) {
        expect(nextUnlockIndex(_unlockedUpTo(i - 1)), i, reason: 'after $i');
      }
    });

    test('is null once everything is unlocked', () {
      expect(nextUnlockIndex(_unlockedUpTo(opponentCatalogue.length - 1)),
          isNull);
    });

    test('the free set needs no unlock record to be playable', () {
      for (final bot in opponentCatalogue.where(isFree)) {
        expect(isUnlocked(bot.id, const {}), isTrue, reason: bot.id);
      }
    });

    test('everything above the ceiling is locked until bought', () {
      for (final bot in opponentCatalogue.where((b) => !isFree(b))) {
        expect(isUnlocked(bot.id, const {}), isFalse, reason: bot.id);
        expect(isUnlocked(bot.id, {bot.id}), isTrue, reason: bot.id);
      }
    });

    test('a record for an opponent this build does not know is ignored', () {
      expect(isUnlocked('deleted_bot', const {'deleted_bot'}), isTrue);
      expect(nextUnlockIndex(const {'deleted_bot'}), kFreeCount);
    });

    test('a hand-edited gap resolves to the lowest locked index rather than '
        'jamming the ladder', () {
      // No code path produces this; a hand-edited document could.
      expect(nextUnlockIndex({_idAt(9), _idAt(12)}), kFreeCount);
    });
  });

  group('the mercy rungs', () {
    // Index 3 is the first free opponent, so it is the rung that hands back
    // index 2, and so on down. Named by index rather than by id so that recutting
    // the roster moves this test with it.
    String above(int i) => _idAt(i + 1);

    test('are locked on a first launch, and are not free', () {
      for (var i = 0; i < kMercyCount; i++) {
        expect(isUnlocked(_idAt(i), const {}), isFalse, reason: _idAt(i));
        expect(isFree(opponentCatalogue[i]), isFalse, reason: _idAt(i));
      }
      expect(mercyUnlocks(played: const {}, lostTo: const {}), isEmpty);
    });

    test('a loss to the rung above hands back exactly one opponent', () {
      for (var i = 0; i < kMercyCount; i++) {
        expect(
          mercyUnlocks(played: const {}, lostTo: {above(i)}),
          {_idAt(i)},
          reason: 'losing to ${above(i)} should hand back ${_idAt(i)}',
        );
      }
    });

    test('do not cascade: losing to the top of the chain opens one step only',
        () {
      // Losing to Hazel gives Mote back and nothing else. Twig arrives only
      // once Mote has actually beaten the player, which is the whole point —
      // each step down is earned by a fresh loss, not implied by the first.
      final afterHazel = mercyUnlocks(played: const {}, lostTo: {_idAt(3)});
      expect(afterHazel, {_idAt(2)});
      expect(afterHazel, isNot(contains(_idAt(1))));
      expect(afterHazel, isNot(contains(_idAt(0))));
    });

    test('open all three once every rung in the chain has won once', () {
      expect(
        mercyUnlocks(played: const {}, lostTo: {_idAt(3), _idAt(2), _idAt(1)}),
        {_idAt(0), _idAt(1), _idAt(2)},
      );
    });

    test('a loss to an opponent outside the chain hands back nothing', () {
      // Clover is free and Bramble is bought; neither sits directly above a
      // mercy rung, so neither opens one.
      expect(mercyUnlocks(played: const {}, lostTo: {_idAt(4)}), isEmpty);
      expect(mercyUnlocks(played: const {}, lostTo: {_idAt(6)}), isEmpty);
    });

    test('playing the rung above without losing to it hands back nothing', () {
      // The distinction the rule rests on: a draw is not a loss, and neither is
      // a win. There is nowhere in this signature to pass a draw, which is the
      // proof rather than the comment.
      expect(mercyUnlocks(played: {_idAt(3)}, lostTo: const {}), isEmpty);
    });

    test('grandfather anyone who has already played them', () {
      // The reviews asked for a gentler opening, not for an opponent to be
      // taken away from somebody already using it (D382).
      expect(mercyUnlocks(played: {_idAt(0)}, lostTo: const {}), {_idAt(0)});
      expect(
        mercyUnlocks(
            played: {_idAt(0), _idAt(1), _idAt(2)}, lostTo: const {}),
        {_idAt(0), _idAt(1), _idAt(2)},
      );
    });

    test('never name anything outside the first rungs, whatever is passed', () {
      final everything = {for (final bot in opponentCatalogue) bot.id};
      final earned = mercyUnlocks(played: everything, lostTo: everything);
      expect(earned.length, kMercyCount);
      for (final id in earned) {
        expect(rosterIndexOf(id)! < kMercyCount, isTrue, reason: id);
      }
    });

    test('are never what the points ladder offers next, at any state', () {
      // The economy must never point at an opponent no amount of points can
      // buy. Checked over every prefix of the roster rather than at the start
      // only, because a hand-edited document can produce any of them.
      for (var highest = -1; highest < opponentCatalogue.length; highest++) {
        final owned =
            highest < 0 ? <String>{} : _unlockedUpTo(highest);
        final next = nextUnlockIndex(owned);
        if (next == null) continue;
        expect(next >= kMercyCount, isTrue, reason: 'owned up to $highest');
      }
    });
  });

  group('the Your Path window', () {
    test('is always three tiles wide, at every position', () {
      for (var next = kFreeCount; next < opponentCatalogue.length; next++) {
        expect(pathWindow(next).length, 3, reason: 'next=$next');
      }
      expect(pathWindow(null).length, 3);
    });

    test('puts the next unlock in the middle', () {
      for (var next = 5; next < opponentCatalogue.length - 1; next++) {
        expect(pathWindow(next)[1], next, reason: 'next=$next');
      }
    });

    test('stays inside the catalogue at both ends', () {
      for (var next = 7; next < opponentCatalogue.length; next++) {
        for (final i in pathWindow(next)) {
          expect(i, inInclusiveRange(0, opponentCatalogue.length - 1));
        }
      }
      for (final i in pathWindow(null)) {
        expect(i, inInclusiveRange(0, opponentCatalogue.length - 1));
      }
    });

    test('slides rather than shrinking at the top', () {
      final last = opponentCatalogue.length - 1;
      expect(pathWindow(last), [last - 2, last - 1, last]);
      expect(pathWindow(null), [last - 2, last - 1, last]);
    });

    test('on a fresh install shows Sorrel, Bramble and Juniper', () {
      // The first locked rung is index 6: the free set is the first six
      // opponents, which is the Novice tier exactly (D335).
      expect([for (final i in pathWindow(kFreeCount)) _idAt(i)],
          ['sorrel', 'bramble', 'juniper']);
    });

    test('is never centred on the rating ladder — a player seeded at 800 sees '
        'a locked opponent and its price, not three they already own', () {
      // The rating-centred window would have been Mote/Clover/Bramble, all
      // free. This is D262 stated as a test rather than as a comment.
      final window = pathWindow(nextUnlockIndex(const {}));
      expect(window.any((i) => !isFree(opponentCatalogue[i])), isTrue);
    });

    test('always contains three distinct, ascending indices', () {
      for (var next = 7; next < opponentCatalogue.length; next++) {
        final w = pathWindow(next);
        expect(w[1], w[0] + 1);
        expect(w[2], w[1] + 1);
      }
    });
  });

  group('stars', () {
    test('none for a record with no wins, however many games', () {
      expect(stars(wins: 0, losses: 0), 0);
      expect(stars(wins: 0, losses: 50), 0);
    });

    test('one when losses outnumber wins', () {
      expect(stars(wins: 1, losses: 5), 1);
      expect(stars(wins: 4, losses: 5), 1);
    });

    test('two when wins are at least level', () {
      expect(stars(wins: 5, losses: 5), 2);
      expect(stars(wins: 6, losses: 5), 2);
    });

    test('three at eighty per cent of decisive games', () {
      expect(stars(wins: 4, losses: 1), 3);
      expect(stars(wins: 8, losses: 2), 3);
      expect(stars(wins: 79, losses: 21), 2);
      expect(stars(wins: 80, losses: 20), 3);
    });

    test('a single win is three stars, and that is deliberate', () {
      // One win and no losses is 100% of decisive games. Beating an opponent
      // once and never losing to them has earned the row.
      expect(stars(wins: 1, losses: 0), 3);
    });

    test('draws are ignored on both sides, so they can never earn a star', () {
      // The signature is the proof: there is nowhere to pass a draw. A version
      // taking `draws` and counting it as half would award stars for not
      // losing, which is not what the row claims.
      expect(stars(wins: 3, losses: 3), 2);
    });
  });
}
