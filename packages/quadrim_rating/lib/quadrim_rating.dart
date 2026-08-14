/// Quadrim rating: ELO maths shared by the on-device computer ladder and,
/// later, the server-side human ladder.
///
/// This package is pure Dart and depends on nothing but the core library —
/// tool/check.sh enforces this.
///
/// The computer rating is **derived, never stored** (spec §7.2): it is a fold
/// over the games already on disk, so it cannot drift from them and needs no
/// second copy to keep in step. Two details make the fold reproducible and
/// both live in the data rather than here — it folds against the anchor
/// stored on each game rather than the current catalogue value, and it orders
/// by an explicit field.
library;

import 'dart:math' as math;

/// Where a player starts on the **computer** ladder.
///
/// 800 rather than 1200 (D226). Against a roster that starts at 600, a player
/// seeded at 1200 spends their first week watching a number fall, which is the
/// opposite of the story the ladder is telling. At 800 they sit just below
/// Clover, above the two weakest opponents, with somewhere obvious to climb.
///
/// **Moving this re-derives every existing rating**, because the rating is a
/// fold with nothing stored — which is the property that keeps it from ever
/// drifting from the games that produced it, and the reason any future change
/// to this number is a silent rewrite of everyone's history (D227). It was
/// affordable exactly once, before anyone had a rating worth keeping.
///
/// The human ladder seeds at 1000 and brings its own constant at 0.4. It does
/// not share this one: human Elo is not separable per player, so recomputing it
/// is a global chronological replay across every account rather than the
/// per-player fold below (spec §7.2).
const int kSeedRating = 800;

/// No rating falls below this, however long a losing run goes on.
const int kRatingFloor = 100;

/// Games below which a player is provisional on a ladder and moves faster.
const int kProvisionalGames = 20;

/// The probability [own] scores against [opponent], by the standard ELO
/// logistic: `1 / (1 + 10^((opponent - own) / 400))`.
double expectedScore(int own, int opponent) =>
    1 / (1 + math.pow(10, (opponent - own) / 400));

/// 32 while provisional on that ladder, 16 from the twentieth game on.
///
/// [gamesPlayed] counts games already folded on **this** ladder. The two
/// ladders are counted separately and never mix (spec §5).
int kFactor(int gamesPlayed) =>
    gamesPlayed < kProvisionalGames ? 32 : 16;

/// The new rating after one game, rounded and floored at [kRatingFloor].
int updatedRating(int current, int k, double score, double expected) =>
    math.max(kRatingFloor, (current + k * (score - expected)).round());

/// The rating gap an observed [score] implies, from the scoring side's view.
///
/// The exact inverse of [expectedScore]: a side that scores 0.75 over a long
/// run measures about 190 points above what it played. Positive means stronger.
///
/// This is what turns a duel result into a number the calibration harness can
/// compare against a published anchor (ticket 014). It says nothing about how
/// *certain* that number is — thirty games leave roughly 70 points of sampling
/// noise around it — so a caller reporting one should report the sample size
/// beside it.
///
/// Null at 0 and 1, where the answer is unbounded. A clean sweep establishes
/// only "at least this much", and what turns that into a number is the number
/// of games it took, which this function is not told.
double? impliedRatingDifference(double score) {
  if (score <= 0 || score >= 1) return null;
  return 400 * math.log(score / (1 - score)) / math.ln10;
}

/// One finished game, reduced to what the fold needs.
///
/// Deliberately not the app's game document: this package may not know about
/// storage. The caller maps its own records onto this, in the order the fold
/// requires — `completedAt`, with the game id as tie-break (spec §8.3).
final class RatedGame {
  const RatedGame({required this.opponentRating, required this.score})
      : assert(score == 0 || score == 0.5 || score == 1);

  /// The anchor this game was **actually played against**, read from the
  /// stored game rather than from the current catalogue. Without that, a
  /// later change to an opponent would silently rewrite the player's whole
  /// history.
  final int opponentRating;

  /// 1 for a win, 0.5 for a draw, 0 for a loss.
  final double score;
}

/// Folds [games], already in order, from [kSeedRating].
int ratingFrom(Iterable<RatedGame> games) {
  var rating = kSeedRating;
  var played = 0;
  for (final game in games) {
    rating = updatedRating(
      rating,
      kFactor(played),
      game.score,
      expectedScore(rating, game.opponentRating),
    );
    played++;
  }
  return rating;
}

/// The change each game in [games] caused, in the same order.
///
/// One pass for a whole history, where [ratingAround] re-folds the prefix for
/// one game. That is the right shape for a result screen showing a single
/// game and quadratic for a list showing every game.
///
/// Sums to `ratingFrom(games) - kSeedRating`, which is what a test pins: two
/// functions walking the same fold is a place for them to drift apart.
List<int> ratingSteps(Iterable<RatedGame> games) {
  final steps = <int>[];
  var rating = kSeedRating;
  var played = 0;
  for (final game in games) {
    final next = updatedRating(
      rating,
      kFactor(played),
      game.score,
      expectedScore(rating, game.opponentRating),
    );
    steps.add(next - rating);
    rating = next;
    played++;
  }
  return steps;
}

/// The rating before and after [games]' final entry — what a result screen
/// needs to show a change without folding twice.
///
/// Returns the seed for both when [games] is empty.
({int before, int after}) ratingAround(List<RatedGame> games) {
  if (games.isEmpty) {
    return (before: kSeedRating, after: kSeedRating);
  }
  final before = ratingFrom(games.take(games.length - 1));
  final after = updatedRating(
    before,
    kFactor(games.length - 1),
    games.last.score,
    expectedScore(before, games.last.opponentRating),
  );
  return (before: before, after: after);
}

/// How lopsided a pairing is, from the player's side.
///
/// Ticket 011 asks that opponents far above or below the player be
/// distinguishable from a fair match. That is a rating question, not a
/// presentation one, so it is answered here where it can be tested without a
/// widget — and answered in terms of [expectedScore] rather than a rating gap,
/// so the bands mean the same thing at 600 as at 2400 (D185).
enum MatchBalance {
  /// Neither side is heavily favoured; both results are plausible.
  even,

  /// The opponent is far enough ahead that the player is not expected to win.
  opponentStronger,

  /// The player is far enough ahead that the game is not much of a test.
  opponentWeaker,
}

/// Below this expected score the opponent counts as far stronger, and above
/// its mirror image as far weaker.
///
/// A quarter is about 190 rating points, which is nearly two rungs of this
/// ladder — comfortably past "a hard game" and into "a different league".
/// Tighter bands would mark most of the roster as a mismatch and tell the
/// player nothing.
const double kLopsidedExpectedScore = 0.25;

MatchBalance matchBalance({required int own, required int opponent}) {
  final expected = expectedScore(own, opponent);
  if (expected <= kLopsidedExpectedScore) return MatchBalance.opponentStronger;
  if (expected >= 1 - kLopsidedExpectedScore) return MatchBalance.opponentWeaker;
  return MatchBalance.even;
}
