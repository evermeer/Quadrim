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

/// Where every player starts on either ladder.
const int kSeedRating = 1200;

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
