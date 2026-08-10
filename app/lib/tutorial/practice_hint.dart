import 'package:quadrim_engine/quadrim_engine.dart';

import 'tutorial_steps.dart';

/// Why a hint is pointing where it is pointing.
///
/// The order is the order the ladder is checked in, and it is deliberately the
/// same order the opponents' rules run in (`StrategicRule`): take a win, stop
/// a loss, build a fork, otherwise play the best square. A hint that advised
/// something the opponents do not reward would be teaching a different game
/// from the one being played (D199).
enum HintKind { win, block, fork, build }

class Hint {
  const Hint(this.kind, this.cell);

  final HintKind kind;
  final Cell cell;
}

/// What the player should be looking at, computed from the position.
///
/// Nothing here is scripted. The same [threats] function the opponents use is
/// asked about the board in front of the player, so a hint is right — or
/// wrong — for the same reasons their moves are. Returns null once the game is
/// over, when there is nothing left to advise.
Hint? hintFor(GameState state, Player player) {
  if (state.isOver) return null;

  final mine = threats(state, player);
  if (mine.isNotEmpty) return Hint(HintKind.win, mine.first.emptyCell);

  final opponent = player == Player.first ? Player.second : Player.first;
  final theirs = threats(state, opponent);
  if (theirs.isNotEmpty) return Hint(HintKind.block, theirs.first.emptyCell);

  // The move the tutorial spent a whole step on: one placement leaving two
  // lines that each need one more piece. Checked by playing it rather than by
  // pattern-matching, so it cannot disagree with what the board then shows.
  for (final move in legalMoves(state)) {
    if (threats(applyMove(state, move), player).length >= 2) {
      return Hint(HintKind.fork, move);
    }
  }

  return Hint(HintKind.build, _bestSquare(state));
}

/// The free cell on the most winning lines, centre before corner on a tie.
///
/// That ordering is the one the strategy steps taught and the one the
/// opponents' positional ladder uses — any centre cell outscores any corner,
/// which outscores everything else. The index tie-break at the end is only
/// there so the same position always produces the same hint.
Cell _bestSquare(GameState state) {
  // Never empty: hintFor has already returned null for a finished game, and a
  // full board is a finished game.
  final free = legalMoves(state);
  var best = free.first;
  var bestScore = _score(best);
  for (final cell in free) {
    final score = _score(cell);
    if (score > bestScore) {
      best = cell;
      bestScore = score;
    }
  }
  return best;
}

/// Lines through the cell, plus a fraction of a point for being central, which
/// separates the eight centre cells from the eight corners without disturbing
/// the ordering against everything else — both sit on seven lines.
double _score(Cell cell) {
  final lines = winningLines.where((l) => l.contains(cell.index)).length;
  return lines + (kCentreCells.contains(cell.index) ? 0.5 : 0);
}
