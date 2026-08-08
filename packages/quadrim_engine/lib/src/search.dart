/// Adversarial search: the heuristic evaluation, alpha-beta minimax over it,
/// and threat-space search for forced wins beyond the fixed horizon.
///
/// Kept apart from `chooseMove` so the search is testable on its own terms —
/// a position has a best move whether or not a bot is asking — and so a bot
/// remains a configuration rather than a subclass (spec §9.4).
///
/// Everything here is pure and deterministic: the same state, depth and
/// weighting always produce the same scores, which is what lets a search bot
/// be reproducible from a seed alone.
library;

import 'engine.dart';
import 'winning_lines.g.dart';

/// The score of a won position. Far above anything the heuristic can reach:
/// 76 lines at the heaviest weight is under 4000, three orders of magnitude
/// below this, so no accumulation of position ever looks like a win.
const int kWinScore = 1000000;

// Line-ownership weights. Superlinear, because three-in-a-line is not three
// times as good as one — it is a move from winning.
const List<int> _lineWeight = [0, 1, 6, 40, 0];

/// The heuristic value of [state] to [me]: what it owns of the board's lines,
/// less what the opponent owns, weighted by [defence].
///
/// A line holding pieces of both sides is dead for both and scores nothing,
/// which is the whole of Quadrim's structure — 76 lines competing to stay
/// alive. [defence] above 1 makes the opponent's lines count for more than
/// one's own, which is how a temperament becomes an evaluation (D150).
///
/// This is the *definition*; the search maintains the same number
/// incrementally and a test holds the two to agreement over random games.
/// Terminal positions are not this function's business — a win's value
/// depends on how soon it arrives, which only the search knows.
int evaluatePosition(GameState state, Player me, {double defence = 1}) {
  var mine = 0;
  var theirs = 0;
  for (final line in winningLines) {
    var own = 0;
    var opp = 0;
    for (final c in line) {
      final owner = state.owner(Cell(c));
      if (owner == me) {
        own++;
      } else if (owner != null) {
        opp++;
      }
    }
    if (own > 0 && opp > 0) continue; // contested: dead for both
    mine += _lineWeight[own];
    theirs += _lineWeight[opp];
  }
  return mine - (theirs * defence).round();
}

/// Scores each of [candidates] by alpha-beta minimax to [depth] plies,
/// evaluating throughout from [me]'s point of view.
///
/// Returns one score per candidate, in the order given. A score near
/// [kWinScore] is a forced win and its shortfall is the number of plies to
/// reach it, so taking the highest score takes the fastest win and, when
/// every line loses, the slowest loss.
///
/// [depth] counts plies including the candidate move itself, so depth 2 is
/// "my move and their reply". [me] must be the side to move.
List<int> searchScores(
  GameState state,
  Player me,
  List<Cell> candidates,
  int depth, {
  double defence = 1,
}) {
  if (depth < 1) throw ArgumentError.value(depth, 'depth', 'at least 1');
  if (state.sideToMove != me) {
    throw ArgumentError.value(me, 'me', 'must be the side to move');
  }
  final board = _Board.of(state, me);
  if (depth == 1 || candidates.length == 1) {
    return [
      for (final cell in candidates) board.scoreAfter(cell.index, depth, defence)
    ];
  }

  // A one-ply pass costs almost nothing and puts the promising candidates
  // first, which is what lets the window below stay narrow. Without it a
  // four-ply look at an early position takes seconds rather than tens of
  // milliseconds — the pruning is only as good as the ordering.
  final shallow = [
    for (final cell in candidates) board.scoreAfter(cell.index, 1, defence),
  ];
  final order = [for (var i = 0; i < candidates.length; i++) i]
    ..sort((a, b) => shallow[b].compareTo(shallow[a]));

  final scores = List<int>.filled(candidates.length, 0);
  var alpha = -kWinScore - 1;
  for (final i in order) {
    // The window opens one below the best already in hand, not at it. With
    // the window at alpha, a candidate that fails low can return exactly
    // alpha — an upper bound indistinguishable from a genuine tie, and the
    // caller uses ties to choose. One point lower, a bound always lands
    // strictly below the maximum and only exact scores can equal it.
    final score =
        board.scoreAfter(candidates[i].index, depth, defence, alpha: alpha - 1);
    scores[i] = score;
    if (score > alpha) alpha = score;
  }
  return scores;
}

/// Looks for a win [me] can force through moves the opponent must answer,
/// following up to [maxForcingMoves] of them. Returns the move that starts
/// the sequence, or null if none was found.
///
/// A depth-limited search sees every reply, so a forced win eight plies deep
/// is beyond any horizon that fits in a phone's time budget. This search sees
/// only forcing moves — the opponent's reply is compelled, so there is
/// nothing to branch on — and reaches far deeper for far less work. It is
/// what separates Sable from Onyx at the same nominal depth.
Cell? threatSpaceWin(GameState state, Player me, int maxForcingMoves) {
  if (maxForcingMoves < 1 || state.sideToMove != me) return null;
  for (final cell in _forcingCandidates(state, me)) {
    final after = applyMove(state, cell);
    if (outcome(after) is Win) return cell;

    // Checked before anything else: if the opponent can complete a line on
    // the very next move, they do, and nothing we have started is forcing —
    // not even a double threat, because they never have to answer it.
    if (threats(after, me.opponent).isNotEmpty) continue;

    // Two distinct winning cells cannot both be blocked.
    final mine = {for (final t in threats(after, me)) t.emptyCell.index};
    if (mine.length >= 2) return cell;
    if (mine.isEmpty) continue; // not forcing: the opponent replies freely

    final forced = applyMove(after, Cell(mine.single));
    if (outcome(forced) is! Ongoing) continue; // the block won, or drew
    if (threatSpaceWin(forced, me, maxForcingMoves - 1) != null) return cell;
  }
  return null;
}

/// The only cells that can create a threat: a move makes three-in-a-line
/// exactly when it lands on a line where [me] already holds two and the
/// opponent holds none.
///
/// Every other cell is unforcing by construction, so this is not a heuristic
/// narrowing — it is the definition, and it is what keeps the fan-out of a
/// six-move forcing search in single figures rather than near sixty.
List<Cell> _forcingCandidates(GameState state, Player me) {
  final cells = <int>{};
  for (final line in winningLines) {
    var own = 0;
    var opp = 0;
    final empties = <int>[];
    for (final c in line) {
      final owner = state.owner(Cell(c));
      if (owner == me) {
        own++;
      } else if (owner != null) {
        opp++;
      } else {
        empties.add(c);
      }
    }
    if (opp == 0 && own >= 2) cells.addAll(empties);
  }
  return (cells.toList()..sort()).map(Cell.new).toList();
}

// ---------------------------------------------------------------------------
// The search's own board
// ---------------------------------------------------------------------------

/// Which of the 76 lines pass through each cell, by line index. The engine's
/// own table maps a cell to the lines' *contents*; the search needs their
/// identities, because that is what its per-line counters are keyed by.
final List<List<int>> _lineIdsThroughCell = () {
  final byCell = List.generate(64, (_) => <int>[]);
  for (var l = 0; l < winningLines.length; l++) {
    for (final c in winningLines[l]) {
      byCell[c].add(l);
    }
  }
  return [for (final ids in byCell) List<int>.unmodifiable(ids)];
}();

/// A mutable board with make/unmake and incrementally maintained line counts.
///
/// The search visits hundreds of thousands of nodes for a four-ply look, and
/// [GameState] copies a 64-cell board on every move by design. Rebuilding the
/// evaluation from scratch at every leaf costs another 304 lookups. Both are
/// right for the rest of the engine and wrong here, so the search keeps its
/// own representation: a move touches at most seven lines, and the evaluation
/// is then a subtraction.
final class _Board {
  _Board._(this._cells, this._count, this._total, this._threat, this._toMove,
      this._placed);

  /// [me] is side 0 throughout, so a score is always from one point of view.
  factory _Board.of(GameState state, Player me) {
    final cells = List<int>.filled(64, -1);
    final count = [List<int>.filled(76, 0), List<int>.filled(76, 0)];
    var placed = 0;
    for (var i = 0; i < 64; i++) {
      final owner = state.owner(Cell(i));
      if (owner == null) continue;
      final side = owner == me ? 0 : 1;
      cells[i] = side;
      placed++;
      for (final l in _lineIdsThroughCell[i]) {
        count[side][l]++;
      }
    }
    final total = [0, 0];
    final threat = [0, 0];
    for (var l = 0; l < 76; l++) {
      if (count[0][l] > 0 && count[1][l] > 0) continue;
      total[0] += _lineWeight[count[0][l]];
      total[1] += _lineWeight[count[1][l]];
      if (count[0][l] == 3) threat[0]++;
      if (count[1][l] == 3) threat[1]++;
    }
    return _Board._(
        cells, count, total, threat, state.sideToMove == me ? 0 : 1, placed);
  }

  final List<int> _cells; // -1 empty, 0 me, 1 them
  final List<List<int>> _count; // pieces per side per line
  final List<int> _total; // weighted line ownership per side
  final List<int> _threat; // lines one move from completing, per side
  int _toMove;
  int _placed;

  /// The minimax score of playing [cell] now, looking [depth] plies in total.
  ///
  /// [alpha] is the best the root has already secured elsewhere. A candidate
  /// that cannot beat it returns a lower bound rather than an exact score,
  /// which is all the caller needs: it is choosing the maximum, and a move
  /// proven no better than one already in hand does not need a number.
  int scoreAfter(int cell, int depth, double defence, {int? alpha}) {
    final won = _place(cell);
    final score = won
        ? kWinScore - 1
        : _search(depth - 1, alpha ?? -kWinScore, kWinScore, 1, defence);
    _lift(cell);
    return score;
  }

  int _search(int remaining, int alpha, int beta, int ply, double defence) {
    if (_isFull) return 0;
    if (remaining == 0) {
      // One move of quiescence. Without it an even-depth search stops after
      // the opponent's reply and calls a position quiet when in fact the side
      // to move completes a line next — and the resulting horizon bias is
      // large enough to make a four-ply opponent *lose* to a three-ply one
      // (D156). The counter is maintained incrementally, so the check is a
      // comparison rather than a scan.
      if (_threat[_toMove] > 0) {
        return _toMove == 0 ? kWinScore - ply - 1 : -kWinScore + ply + 1;
      }
      return _evaluate(defence);
    }

    final maximising = _toMove == 0;
    var best = maximising ? -kWinScore - 1 : kWinScore + 1;
    for (final cell in _orderedMoves()) {
      final won = _place(cell);
      final value = won
          ? (maximising ? kWinScore - ply : -kWinScore + ply)
          : _search(remaining - 1, alpha, beta, ply + 1, defence);
      _lift(cell);

      if (maximising) {
        if (value > best) best = value;
        if (best > alpha) alpha = best;
      } else {
        if (value < best) best = value;
        if (best < beta) beta = best;
      }
      if (alpha >= beta) break; // the other side would never allow this line
    }
    return best;
  }

  int _evaluate(double defence) =>
      _total[0] - (_total[1] * defence).round();

  bool get _isFull => _placed == 64;

  /// What line [l] is currently worth to side [s]: nothing once the other
  /// side has a piece on it, because neither can complete it any more.
  int _contribution(int s, int l) =>
      _count[1 - s][l] == 0 ? _lineWeight[_count[s][l]] : 0;

  /// 1 when side [s] completes line [l] with its next move.
  int _isThreat(int s, int l) =>
      _count[s][l] == 3 && _count[1 - s][l] == 0 ? 1 : 0;

  /// Places the side to move on [cell]; returns whether that completed a
  /// line. Every counter is updated in place and [_lift] reverses it exactly.
  bool _place(int cell) {
    final side = _toMove;
    _cells[cell] = side;
    _placed++;
    var won = false;
    for (final l in _lineIdsThroughCell[cell]) {
      _adjust(l, -1);
      _count[side][l]++;
      _adjust(l, 1);
      if (_count[side][l] == 4) won = true;
    }
    _toMove = 1 - side;
    return won;
  }

  void _lift(int cell) {
    final side = 1 - _toMove;
    _toMove = side;
    _cells[cell] = -1;
    _placed--;
    for (final l in _lineIdsThroughCell[cell]) {
      _adjust(l, -1);
      _count[side][l]--;
      _adjust(l, 1);
    }
  }

  /// Adds or removes line [l]'s current contribution to both running totals.
  /// Called either side of a change to the line's counts, which is what keeps
  /// the evaluation exact without ever recomputing it.
  void _adjust(int l, int sign) {
    for (var s = 0; s < 2; s++) {
      _total[s] += sign * _contribution(s, l);
      _threat[s] += sign * _isThreat(s, l);
    }
  }

  /// Empty cells with the forcing ones first.
  ///
  /// Alpha-beta prunes in proportion to how early the best move is tried, so
  /// this ordering is not a nicety: it is most of the difference between a
  /// four-ply search that returns in milliseconds and one that does not.
  /// Completing a line and denying the opponent completing theirs are the two
  /// moves most likely to be best, and the per-line counters already know
  /// where both are.
  List<int> _orderedMoves() {
    final urgent = <int>{};
    for (var l = 0; l < 76; l++) {
      for (var side = 0; side < 2; side++) {
        if (_count[side][l] == 3 && _count[1 - side][l] == 0) {
          for (final c in winningLines[l]) {
            if (_cells[c] == -1) urgent.add(c);
          }
        }
      }
    }
    final first = <int>[];
    final rest = <int>[];
    for (var i = 0; i < 64; i++) {
      if (_cells[i] != -1) continue;
      (urgent.contains(i) ? first : rest).add(i);
    }
    return first..addAll(rest);
  }
}
