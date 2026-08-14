import 'package:quadrim_progression/quadrim_progression.dart';

import 'documents.dart';

/// Maps stored games onto the progression package's input, the same way
/// `rating_fold.dart` maps them onto the rating package's.
///
/// Points earned is **derived, never stored** (spec §8.8): a fold over the
/// games already on disk, so it cannot drift from them. Unlike the rating, it
/// does not need each game's stored anchor — a win pays by the opponent's
/// position in the roster, which is an ordinal that no recalibration moves.
///
/// It reads **no unlock record**, and that is a property to protect rather than
/// an accident: it holds only because §7.4 prices every quest by the opponents
/// it was earned against rather than by how high the player has climbed. Under
/// the rejected rule this fold would have had to interleave games with unlock
/// records in time order (D270).

/// The games that pay, reduced to what progression cares about.
///
/// Three exclusions, all deliberate. Pass-and-play pays nothing because the
/// player holds both seats, so a win there is also a loss (D157 — the same
/// reason it is outside the record). The tutorial's practice game pays nothing
/// because it is never stored at all. And a game naming an opponent this build
/// does not know pays nothing rather than throwing: a history that cannot be
/// folded is worse than one whose oldest games are worth zero.
List<ScoredGame> scoredGamesFrom(List<GameDocument> completed) {
  final scored = <ScoredGame>[];
  // Oldest first. Points do not care, but the quest fold does: the volume
  // family awards on the day it first fired and needs to know which games got
  // there. `loadCompletedGames` returns most recent first, the same inversion
  // `rating_fold.dart` makes for the same reason.
  for (final game in completed.reversed) {
    if (game.mode != GameMode.vsComputer) continue;
    final result = game.result;
    if (result == null) continue;
    final botId = botIdOf(game.opponent);
    if (botId == null) continue;
    final index = rosterIndexOf(botId);
    if (index == null) continue;
    scored.add(ScoredGame(
      rosterIndex: index,
      won: result.outcome != GameOutcome.draw &&
          result.winnerSeat == game.playerSeat,
      movedSecond: game.playerSeat != game.startingSeat,
      // Local, because the quest that counts games in a day means the
      // player's day. The package is not allowed to decide which day a UTC
      // instant falls in, and it is right not to be.
      completedAt: game.completedAt?.toLocal(),
    ));
  }
  return scored;
}

/// Every quest's standing, folded from the same list as everything else.
///
/// [today] is passed through rather than read here for the same reason it is a
/// parameter of the package: a fixture must be able to put the player on any
/// day it likes.
List<QuestStatus> questsFrom(List<GameDocument> completed, DateTime today) =>
    questStatuses(scoredGamesFrom(completed), today: today);

/// The player's points, folded from the same list everything else on the main
/// screen is folded from.
int pointsFrom(List<GameDocument> completed) =>
    pointsEarned(scoredGamesFrom(completed));
