import 'package:quadrim_rating/quadrim_rating.dart';
import 'package:test/test.dart';

void main() {
  group('expectedScore', () {
    test('equal ratings are an even match', () {
      expect(expectedScore(1200, 1200), closeTo(0.5, 1e-12));
    });

    test('400 points is the standard 10:1 ratio', () {
      expect(expectedScore(1600, 1200), closeTo(10 / 11, 1e-12));
      expect(expectedScore(1200, 1600), closeTo(1 / 11, 1e-12));
    });

    test('the two directions always sum to one', () {
      for (var gap = -800; gap <= 800; gap += 50) {
        final a = expectedScore(1200, 1200 + gap);
        final b = expectedScore(1200 + gap, 1200);
        expect(a + b, closeTo(1, 1e-12));
      }
    });
  });

  group('kFactor', () {
    test('32 while provisional, 16 from the twentieth game', () {
      expect(kFactor(0), 32);
      expect(kFactor(19), 32);
      expect(kFactor(20), 16);
      expect(kFactor(500), 16);
    });
  });

  group('updatedRating', () {
    test('an even-match win at K=32 gains 16', () {
      expect(updatedRating(1200, 32, 1, 0.5), 1216);
    });

    test('an even-match loss at K=32 drops 16', () {
      expect(updatedRating(1200, 32, 0, 0.5), 1184);
    });

    test('an even-match draw changes nothing', () {
      expect(updatedRating(1200, 32, 0.5, 0.5), 1200);
    });

    test('beating a much stronger opponent gains nearly the whole K', () {
      final expected = expectedScore(1200, 2000);
      expect(updatedRating(1200, 32, 1, expected), greaterThan(1229));
    });

    test('losing to a much weaker opponent costs nearly the whole K', () {
      final expected = expectedScore(2000, 1200);
      expect(updatedRating(2000, 32, 0, expected), lessThan(1971));
    });

    test('the floor holds however long the losing run', () {
      var rating = 200;
      for (var i = 0; i < 50; i++) {
        rating = updatedRating(rating, 32, 0, expectedScore(rating, 2600));
      }
      expect(rating, greaterThanOrEqualTo(kRatingFloor));
    });
  });

  group('ratingFrom', () {
    test('no games leaves the player on the seed', () {
      expect(ratingFrom(const []), kSeedRating);
    });

    test('a worked provisional sequence', () {
      // Three wins against an even opponent while provisional: K stays 32.
      const games = [
        RatedGame(opponentRating: 1200, score: 1),
        RatedGame(opponentRating: 1200, score: 1),
        RatedGame(opponentRating: 1200, score: 1),
      ];
      // 1200 -> 1216 -> ~1231 -> ~1245, each step recomputing expectation.
      var rating = kSeedRating;
      for (final g in games) {
        rating = updatedRating(
            rating, 32, g.score, expectedScore(rating, g.opponentRating));
      }
      expect(ratingFrom(games), rating);
      expect(ratingFrom(games), greaterThan(1240));
    });

    test('K drops to 16 after the twentieth game, slowing later movement', () {
      List<RatedGame> wins(int n) => List.generate(
          n, (_) => const RatedGame(opponentRating: 1200, score: 1));

      // The 21st game moves the rating less than the 1st did, at a comparable
      // gap, because K has halved.
      final firstStep = ratingFrom(wins(1)) - kSeedRating;
      final at20 = ratingFrom(wins(20));
      final at21 = ratingFrom(wins(21));
      expect(kFactor(20), 16);
      expect(at21 - at20, lessThan(firstStep));
    });

    test('draws score one half', () {
      const drawn = [RatedGame(opponentRating: 2000, score: 0.5)];
      // A draw against a much stronger opponent is a gain.
      expect(ratingFrom(drawn), greaterThan(kSeedRating));
    });

    test('folds against each game\'s stored anchor, not a single value', () {
      // Same results, different anchors: the fold must not treat them alike.
      const weak = [
        RatedGame(opponentRating: 600, score: 1),
        RatedGame(opponentRating: 600, score: 1),
      ];
      const strong = [
        RatedGame(opponentRating: 2000, score: 1),
        RatedGame(opponentRating: 2000, score: 1),
      ];
      expect(ratingFrom(strong), greaterThan(ratingFrom(weak)));
    });

    test('the K boundary makes the fold order-sensitive, which is why the '
        'ordering key is a stored field', () {
      // With a constant K, ELO is very nearly order-independent — the same
      // results in a different order land within a point of each other. The
      // order dependence that actually bites is the provisional boundary: the
      // same win is worth 32 before the twentieth game and 16 after it.
      const upset = RatedGame(opponentRating: 2400, score: 1);
      final quiet = List.filled(
          20, const RatedGame(opponentRating: 1200, score: 0.5));

      final upsetFirst = ratingFrom([upset, ...quiet]);
      final upsetLast = ratingFrom([...quiet, upset]);
      expect(upsetFirst, isNot(upsetLast),
          reason: 'same games, different order, different rating');
      // Not asserting which is larger: two effects pull opposite ways. The
      // early upset is worth more (K=32 rather than 16), but every later draw
      // against a 1200 anchor then erodes it, because a player above 1200 is
      // expected to beat 1200 rather than draw it.
    });
  });

  group('ratingAround', () {
    test('reports the step the last game caused', () {
      const games = [
        RatedGame(opponentRating: 1200, score: 1),
        RatedGame(opponentRating: 1200, score: 1),
      ];
      final around = ratingAround(games);
      expect(around.before, ratingFrom(games.take(1)));
      expect(around.after, ratingFrom(games));
      expect(around.after, greaterThan(around.before));
    });

    test('an empty history sits on the seed, unchanged', () {
      final around = ratingAround(const []);
      expect(around.before, kSeedRating);
      expect(around.after, kSeedRating);
    });

    test('agrees with a full fold for every prefix', () {
      final games = [
        for (var i = 0; i < 30; i++)
          RatedGame(
            opponentRating: 600 + i * 50,
            score: i % 3 == 0 ? 1 : (i % 3 == 1 ? 0.5 : 0),
          ),
      ];
      for (var n = 1; n <= games.length; n++) {
        final prefix = games.take(n).toList();
        expect(ratingAround(prefix).after, ratingFrom(prefix),
            reason: 'disagreement at $n games');
      }
    });
  });

  group('matchBalance', () {
    test('equal ratings are an even match', () {
      expect(matchBalance(own: 1200, opponent: 1200), MatchBalance.even);
    });

    test('the bands are symmetric', () {
      // Whatever gap makes an opponent far stronger must make the mirror of it
      // far weaker, or the screen would call a pairing fair from one side and
      // lopsided from the other.
      for (var gap = 0; gap <= 600; gap += 25) {
        final up = matchBalance(own: 1200, opponent: 1200 + gap);
        final down = matchBalance(own: 1200, opponent: 1200 - gap);
        if (up == MatchBalance.opponentStronger) {
          expect(down, MatchBalance.opponentWeaker, reason: 'gap $gap');
        } else {
          expect(down, MatchBalance.even, reason: 'gap $gap');
        }
      }
    });

    test('the band means the same thing at both ends of the ladder', () {
      // Expressed as an expected score rather than a rating gap, so the same
      // pairing shape reads identically for a beginner and an expert.
      expect(
        matchBalance(own: 600, opponent: 800),
        matchBalance(own: 2200, opponent: 2400),
      );
      expect(
        matchBalance(own: 600, opponent: 1000),
        matchBalance(own: 2000, opponent: 2400),
      );
    });

    test('a quarter expected score is where lopsided begins', () {
      // 190 points is the documented boundary; either side of it must differ,
      // or the constant is not doing what its comment claims.
      expect(matchBalance(own: 1200, opponent: 1200 + 191),
          MatchBalance.opponentStronger);
      expect(matchBalance(own: 1200, opponent: 1200 + 180), MatchBalance.even);
    });

    test('the whole catalogue range resolves for a seeded player', () {
      // A new player sits on the seed. Pebble at 600 and Prime at 2400 must
      // land in the outer bands, and something near the seed must not.
      expect(matchBalance(own: kSeedRating, opponent: 600),
          MatchBalance.opponentWeaker);
      expect(matchBalance(own: kSeedRating, opponent: 2400),
          MatchBalance.opponentStronger);
      expect(matchBalance(own: kSeedRating, opponent: 1250), MatchBalance.even);
    });
  });
}
