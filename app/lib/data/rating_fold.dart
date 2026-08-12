import 'package:quadrim_rating/quadrim_rating.dart';

import 'documents.dart';

/// Maps stored games onto the rating package's input.
///
/// The computer rating is derived, never stored (spec §7.2): this fold is the
/// only place it comes from, so it cannot drift from the games it summarises.
/// Two things make it reproducible and both live in the data — each game
/// carries the anchor it was **actually** played against, and completion time
/// is an explicit field rather than an assumption about arrival order.

/// Completed games on the computer ladder, oldest first.
///
/// `loadCompletedGames` returns most recent first; the fold needs the reverse.
List<GameDocument> _ladder(List<GameDocument> completed) => [
      for (final game in completed.reversed)
        if (game.mode == GameMode.vsComputer &&
            game.opponentRating != null &&
            game.result != null)
          game,
    ];

List<RatedGame> ratedGamesFrom(List<GameDocument> completed) => [
      for (final game in _ladder(completed))
        RatedGame(
          opponentRating: game.opponentRating!,
          score: _scoreFor(game, game.playerSeat),
        ),
    ];

/// 1 for a win, 0.5 for a draw, 0 for a loss. A resignation is already a win
/// for the other seat by the time it is stored, so it needs no special case.
double _scoreFor(GameDocument game, int seat) {
  final result = game.result!;
  if (result.outcome == GameOutcome.draw) return 0.5;
  return result.winnerSeat == seat ? 1 : 0;
}

/// The player's live computer rating: a fold over every completed game
/// against a computer opponent.
int computerRating(List<GameDocument> completed) =>
    ratingFrom(ratedGamesFrom(completed));

/// The change each ladder game caused, by game id.
///
/// One pass for the whole list. [computerRatingAround] re-folds the prefix for
/// a single game, which is right for the one game a result screen shows and
/// quadratic for a list showing every game.
///
/// Games not on this ladder — pass and play, and anything stored without an
/// anchor — are absent rather than zero. A caller drawing an arrow needs to
/// tell "no change" from "no rating".
Map<String, int> ratingDeltas(List<GameDocument> completed) {
  final ladder = _ladder(completed);
  final steps = ratingSteps(ratedGamesFrom(completed));
  return {
    // Both walk `_ladder`, in its order, so the two line up by construction.
    for (var i = 0; i < ladder.length; i++) ladder[i].id: steps[i],
  };
}

/// The rating either side of [gameId], for a result screen showing the change
/// that game caused.
///
/// Folds the prefix **ending at that game** rather than the whole history.
/// Taking the last completed game would be right only while the game just
/// finished is also the most recent one ever finished, which is an assumption
/// about navigation rather than about the data.
///
/// Returns the seed for both when the game is not on this ladder.
({int before, int after}) computerRatingAround(
  List<GameDocument> completed,
  String gameId,
) {
  final ladder = _ladder(completed);
  final index = ladder.indexWhere((g) => g.id == gameId);
  if (index < 0) return (before: kSeedRating, after: kSeedRating);
  return ratingAround([
    for (final game in ladder.take(index + 1))
      RatedGame(
        opponentRating: game.opponentRating!,
        score: _scoreFor(game, game.playerSeat),
      ),
  ]);
}
