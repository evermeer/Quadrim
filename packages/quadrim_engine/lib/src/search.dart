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
import 'transposition.dart';
import 'winning_lines.g.dart';

/// What bounds a deep search, and what it is allowed to spend.
///
/// The budget is in **nodes, never in milliseconds** (ticket 025). A
/// wall-clock budget makes an opponent play differently on a fast phone than a
/// slow one, differently in debug than in release, and differently in CI than
/// anywhere else — which would break the specification's E7, "identical state
/// and seed give an identical move", everywhere except the machine it was
/// written on. Nodes are the same number on every device; the wall clock it
/// corresponds to is measured and recorded separately (D162).
final class SearchLimits {
  const SearchLimits({
    required this.nodeBudget,
    required this.maxDepth,
    this.defence = 1,
    this.exactEmpties = 0,
    this.canonicalPlies = 0,
    this.tableSizeLog2 = 18,
    this.forkBonus = kForkBonus,
  })  : assert(nodeBudget > 0),
        assert(maxDepth >= 1),
        assert(exactEmpties >= 0),
        // Not a style limit but a termination one. Exact solving has no
        // horizon and no budget it will abandon — it plays every line to the
        // end. The value that motivated this assert was 64, meaning "always
        // solve exactly", which on a near-empty board means solving Qubic. It
        // hung the engine suite from ticket 025 onwards, and because the run
        // never reached the end nobody saw a result to be suspicious of
        // (D178).
        assert(exactEmpties <= 16,
            'exactEmpties above 16 cannot finish; the shipped opponents use '
            '10 and 12'),
        assert(canonicalPlies >= 0);

  /// Nodes this move choice may visit. An iteration that runs out is
  /// abandoned and its partial result discarded.
  final int nodeBudget;

  /// The deepest iteration to attempt, whatever the budget allows.
  final int maxDepth;

  final double defence;

  /// Below this many empty cells the search proves the result instead of
  /// estimating it. 0 disables exact solving.
  final int exactEmpties;

  /// How many plies from the root are keyed by canonical form rather than by
  /// the position as it stands. 0 disables symmetry entirely.
  final int canonicalPlies;

  /// The table holds `2^tableSizeLog2` entries at 16 bytes: 4 MB by default.
  final int tableSizeLog2;

  /// What an unanswerable second threat is worth. Zero reduces the evaluation
  /// to counting line ownership, which is what it did before ticket 026 — kept
  /// settable so the two can be played against each other rather than argued
  /// about (D167).
  final int forkBonus;
}

/// What a deep search found, and what it cost.
final class SearchOutcome {
  const SearchOutcome({
    required this.scores,
    required this.depthReached,
    required this.nodes,
    required this.tableHits,
    required this.tableProbes,
  });

  /// One score per candidate, in the order given.
  final List<int> scores;

  /// The deepest iteration that completed. Iterations abandoned mid-way are
  /// discarded rather than mixed in, because half an iteration is not a
  /// depth — it is whatever the move ordering happened to reach first.
  final int depthReached;

  final int nodes;
  final int tableHits;
  final int tableProbes;
}

/// The score of a won position. Far above anything the heuristic can reach:
/// 76 lines at the heaviest weight is under 4000, three orders of magnitude
/// below this, so no accumulation of position ever looks like a win.
const int kWinScore = 1000000;

/// Deeper than any search a 64-cell board allows, so the killer table is a
/// fixed allocation rather than a growing one.
const int _maxPly = 64;

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
int evaluatePosition(
  GameState state,
  Player me, {
  double defence = 1,
  int forkBonus = kForkBonus,
}) {
  var mine = 0;
  var theirs = 0;
  final myThreatCells = <int>{};
  final theirThreatCells = <int>{};
  for (final line in winningLines) {
    var own = 0;
    var opp = 0;
    var empty = -1;
    for (final c in line) {
      final owner = state.owner(Cell(c));
      if (owner == me) {
        own++;
      } else if (owner != null) {
        opp++;
      } else {
        empty = c;
      }
    }
    if (own > 0 && opp > 0) continue; // contested: dead for both
    mine += _lineWeight[own];
    theirs += _lineWeight[opp];
    if (empty < 0) continue;
    if (own == 3) myThreatCells.add(empty);
    if (opp == 3) theirThreatCells.add(empty);
  }
  mine += forkBonus * _forkTerm(myThreatCells.length);
  theirs += forkBonus * _forkTerm(theirThreatCells.length);
  return mine - (theirs * defence).round();
}

/// What a set of threats is worth beyond the lines that carry them.
///
/// One threat is answerable: the opponent blocks the cell and the line dies.
/// Two threats on **distinct** cells cannot both be blocked, so the position
/// is won barring a faster win for the other side. Counting lines cannot see
/// this — two lines of three sharing their last empty cell are one threat, not
/// two — which is why the count that matters is of cells (D167).
int _forkTerm(int distinctThreatCells) =>
    distinctThreatCells < 2 ? 0 : distinctThreatCells - 1;

/// Large enough that a fork outweighs any ordinary accumulation of position —
/// 76 lines of three would be needed to match one — and far below [kWinScore],
/// which is reserved for results the search has actually proved.
const int kForkBonus = 3000;

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

/// Searches [candidates] by iterative deepening under [limits].
///
/// Deepens one ply at a time, keeping the last iteration that finished within
/// the node budget. Deepening rather than fixing a depth is what makes a node
/// budget usable at all: a fixed eight-ply search either fits the budget or
/// returns nothing, whereas this returns the best answer that fitted.
///
/// The transposition table is created here and discarded on return, so two
/// calls with the same arguments give the same answer regardless of what was
/// searched between them.
SearchOutcome deepSearch(
  GameState state,
  Player me,
  List<Cell> candidates,
  SearchLimits limits,
) {
  if (state.sideToMove != me) {
    throw ArgumentError.value(me, 'me', 'must be the side to move');
  }
  final board = _Board.of(state, me)
    .._table = TranspositionTable(sizeLog2: limits.tableSizeLog2)
    .._exactEmpties = limits.exactEmpties
    .._canonicalPlies = limits.canonicalPlies
    .._fork = limits.forkBonus;
  board._plainHash = CanonicalHash.of(state, me).plainKey;
  if (limits.canonicalPlies > 0) {
    board._hash = CanonicalHash.of(state, me);
  }

  var scores = <int>[for (final _ in candidates) 0];
  var depthReached = 0;
  var spent = 0;

  /// Whether the first iteration already proves the result rather than
  /// estimating it. Checked once, from the root's own occupancy.
  final rootIsExact = limits.exactEmpties > 0 &&
      64 - state.moves.length <= limits.exactEmpties;

  for (var depth = 1; depth <= limits.maxDepth; depth++) {
    board
      .._budget = limits.nodeBudget - spent
      .._outOfBudget = false;
    if (board._budget <= 0) break;

    final iteration = _rootPass(board, candidates, depth, limits.defence);
    spent = limits.nodeBudget - board._budget;
    if (board._outOfBudget) break; // discarded: a partial iteration is noise
    scores = iteration;
    depthReached = depth;
    // Nothing deeper can change a proven win, and the shallowest proof is the
    // fastest one.
    if (scores.any((s) => s >= kWinScore - depth)) break;
    // Nor can anything deeper change a position that was *solved* rather than
    // estimated. Once the root is inside the exact window every iteration
    // plays the same subtree out to the same proven answer, so deepening buys
    // a second copy of a result already in hand — and the exact solver is the
    // most expensive thing in the engine to run twice (D177).
    if (rootIsExact) break;
  }

  final table = board._table!;
  return SearchOutcome(
    scores: scores,
    depthReached: depthReached,
    nodes: spent,
    tableHits: table.hits,
    tableProbes: table.probes,
  );
}

/// One full-width pass over the root candidates at a fixed depth.
List<int> _rootPass(
  _Board board,
  List<Cell> candidates,
  int depth,
  double defence,
) {
  final order = [for (var i = 0; i < candidates.length; i++) i];
  if (candidates.length > 1) {
    final shallow = [
      for (final cell in candidates) board.scoreAfter(cell.index, 1, defence),
    ];
    order.sort((a, b) => shallow[b].compareTo(shallow[a]));
  }
  final scores = List<int>.filled(candidates.length, -kWinScore - 1);
  var alpha = -kWinScore - 1;
  for (final i in order) {
    final score =
        board.scoreAfter(candidates[i].index, depth, defence, alpha: alpha - 1);
    scores[i] = score;
    if (score > alpha) alpha = score;
    if (board._outOfBudget) break;
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
/// Runs on the search's incremental board rather than on [GameState]. The
/// naive version copied a 64-cell board twice and rescanned all 76 lines four
/// times *per node*; this makes and unmakes in place and reads counters that
/// are already maintained, which is what lets the same node budget reach the
/// depth defence needs (D170). [threatSpaceWinNaively] is kept as the oracle
/// the two are held to agreement against.
Cell? threatSpaceWin(
  GameState state,
  Player me,
  int maxForcingMoves, {
  int nodeBudget = kForcingBudget,
}) {
  if (maxForcingMoves < 1 || state.sideToMove != me) return null;
  final board = _Board.of(state, me);
  final cell = board._forcingWin(maxForcingMoves, _Counter(nodeBudget));
  return cell < 0 ? null : Cell(cell);
}

/// The definition, written the obvious way: a fresh [GameState] per node and a
/// full scan for every question. Far too slow to play with — it exists so a
/// test can hold the fast version to it over thousands of positions.
Cell? threatSpaceWinNaively(
  GameState state,
  Player me,
  int maxForcingMoves, {
  int nodeBudget = kForcingBudget,
}) =>
    _threatSpaceWin(state, me, maxForcingMoves, _Counter(nodeBudget));

/// A forcing search is narrow but not bounded: its fan-out is the number of
/// cells that create a threat, which in a rich position is dozens, and eleven
/// forcing moves of that is minutes rather than milliseconds. Measured at over
/// five minutes for one move before this existed (D168).
const int kForcingBudget = 200000;

final class _Counter {
  _Counter(this.left);
  int left;
}

Cell? _threatSpaceWin(
  GameState state,
  Player me,
  int maxForcingMoves,
  _Counter budget,
) {
  if (maxForcingMoves < 1 || state.sideToMove != me) return null;
  for (final cell in _forcingCandidates(state, me)) {
    if (--budget.left <= 0) return null; // out of budget: claim nothing
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
    if (_threatSpaceWin(forced, me, maxForcingMoves - 1, budget) != null) {
      return cell;
    }
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
    final board = _Board._(
        cells, count, total, threat, state.sideToMove == me ? 0 : 1, placed);
    for (var l = 0; l < 76; l++) {
      for (var s = 0; s < 2; s++) {
        if (count[s][l] != 3 || count[1 - s][l] != 0) continue;
        for (final c in winningLines[l]) {
          if (cells[c] != -1) continue;
          if (board._cellThreat[s][c]++ == 0) board._distinctThreats[s]++;
          break;
        }
      }
    }
    return board;
  }

  final List<int> _cells; // -1 empty, 0 me, 1 them
  final List<List<int>> _count; // pieces per side per line
  final List<int> _total; // weighted line ownership per side
  final List<int> _threat; // lines one move from completing, per side

  /// How many of side s's threats pass through each cell, and how many cells
  /// carry at least one. The second is what a fork is counted in: two threats
  /// sharing a cell are one block away from nothing (D167).
  final List<List<int>> _cellThreat = [
    List<int>.filled(64, 0),
    List<int>.filled(64, 0),
  ];
  final List<int> _distinctThreats = [0, 0];
  int _toMove;
  int _placed;

  // ---- Expert-tier machinery. All null or zero for the Club tier, which
  // pays nothing for what it does not use. ----

  /// Set when this search caches positions. Created and discarded by the
  /// caller within one move choice, so the search stays a pure function.
  TranspositionTable? _table;

  /// The position's plain Zobrist hash: one XOR a move, maintained whenever
  /// there is a table to key.
  int _plainHash = 0;

  /// One Zobrist hash per automorphism. Maintained *only* for moves made above
  /// [_canonicalPlies], which is sound because a move made below that depth is
  /// always unmade before the search returns to a node that reads it.
  CanonicalHash? _hash;
  int _canonicalPlies = 0;

  /// Counts down; at zero the search abandons the current iteration.
  int _budget = 0;
  bool _outOfBudget = false;

  /// Below this many empty cells the search stops estimating and plays the
  /// position out exactly.
  int _exactEmpties = 0;

  /// The minimax score of playing [cell] now, looking [depth] plies in total.
  ///
  /// [alpha] is the best the root has already secured elsewhere. A candidate
  /// that cannot beat it returns a lower bound rather than an exact score,
  /// which is all the caller needs: it is choosing the maximum, and a move
  /// proven no better than one already in hand does not need a number.
  int scoreAfter(int cell, int depth, double defence, {int? alpha}) {
    final won = _place(cell, 0);
    final score = won
        ? kWinScore - 1
        : _search(depth - 1, alpha ?? -kWinScore, kWinScore, 1, defence);
    _lift(cell, 0);
    return score;
  }

  int _search(int remaining, int alpha, int beta, int ply, double defence) {
    if (_isFull) return 0;
    if (_budget > 0) {
      if (--_budget == 0) _outOfBudget = true;
    }

    // Exact play, once few enough cells remain that the whole subtree fits.
    // A proven result is never an estimate, so it is taken before the horizon
    // and before the table's heuristic entries (criterion: "a proven result is
    // never overridden by a heuristic estimate").
    if (_exactEmpties > 0 && 64 - _placed <= _exactEmpties) {
      return _solveExactly(alpha, beta, ply);
    }

    final table = _table;
    final key = table == null ? 0 : _tableKey(ply);
    var suggested = -1;
    if (table != null) {
      final entry = table.probe(key);
      if (entry != null) {
        // The move is useful for ordering even when the score is not usable
        // as an answer: a shallow entry still knows which move looked best.
        suggested = entry.bestMove;
        if (entry.depth >= remaining) {
          final score = _fromTable(entry.score, ply);
          switch (entry.kind) {
            case TranspositionKind.exact:
              return score;
            case TranspositionKind.lowerBound:
              if (score >= beta) return score;
            case TranspositionKind.upperBound:
              if (score <= alpha) return score;
          }
        }
      }
    }
    final originalAlpha = alpha;
    final originalBeta = beta;

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
    var bestMove = -1;
    for (final cell in _orderedMoves(suggested: suggested, ply: ply)) {
      final won = _place(cell, ply);
      final value = won
          ? (maximising ? kWinScore - ply : -kWinScore + ply)
          : _search(remaining - 1, alpha, beta, ply + 1, defence);
      _lift(cell, ply);

      if (maximising) {
        if (value > best) {
          best = value;
          bestMove = cell;
        }
        if (best > alpha) alpha = best;
      } else {
        if (value < best) {
          best = value;
          bestMove = cell;
        }
        if (best < beta) beta = best;
      }
      if (alpha >= beta) {
        // The move that caused the cutoff is worth trying first in sibling
        // positions at the same depth — they usually share the reason.
        _rememberKiller(ply, cell);
        break;
      }
      if (_outOfBudget) return best; // abandoned: never stored
    }

    if (table != null && !_outOfBudget) {
      table.store(
        key,
        remaining,
        _toTable(best, ply),
        best <= originalAlpha
            ? TranspositionKind.upperBound
            : best >= originalBeta
                ? TranspositionKind.lowerBound
                : TranspositionKind.exact,
        bestMove,
      );
    }
    return best;
  }

  /// Two killer moves per ply, most recent first.
  final List<int> _killers = List<int>.filled(2 * _maxPly, -1);

  void _rememberKiller(int ply, int cell) {
    if (ply >= _maxPly) return;
    final slot = ply * 2;
    if (_killers[slot] == cell) return;
    _killers[slot + 1] = _killers[slot];
    _killers[slot] = cell;
  }

  /// A win's score carries how far from the **root** it is, which is what
  /// makes the search prefer a faster win. The table is shared between
  /// positions reached at different distances, so a stored win must be
  /// rewritten as a distance from *this node* and read back the same way —
  /// otherwise a win found five plies down is reported as a win in two when
  /// the position turns up again by a shorter route.
  static int _toTable(int score, int ply) => score >= kWinScore - _mateWindow
      ? score + ply
      : score <= -kWinScore + _mateWindow
          ? score - ply
          : score;

  static int _fromTable(int score, int ply) => score >= kWinScore - _mateWindow
      ? score - ply
      : score <= -kWinScore + _mateWindow
          ? score + ply
          : score;

  /// No line can be longer than the board, so anything within this of the win
  /// score is a proven result rather than an estimate.
  static const int _mateWindow = 128;

  /// The key this position is stored under.
  ///
  /// Canonical — the smallest of the 192 symmetric images — only in the top
  /// [_canonicalPlies] plies. Maintaining 192 hashes costs about 540 ns a
  /// move against roughly 10 ns of node work, so paying it everywhere would
  /// cost two orders of magnitude more than the search itself. It is paid
  /// where it repays: near the root, where the opening's enormous symmetry
  /// collapses a few hundred boards into a handful of classes (D161).
  int _tableKey(int ply) =>
      ply < _canonicalPlies ? _hash!.key : _plainHash;

  /// Plays the position out to the end, returning a proven score.
  ///
  /// No evaluation and no horizon: every line runs to a win, a loss or a full
  /// board. [ply] discounts a win by how long it takes, so a proven win in two
  /// outranks the same win in six.
  ///
  /// The nodes are counted but the count is never acted on. A proof half made
  /// is worth nothing, so this never abandons — but leaving it uncounted made
  /// [SearchOutcome.nodes] under-report by the whole endgame, which is the
  /// number the calibration harness reads.
  int _solveExactly(int alpha, int beta, int ply) {
    if (_isFull) return 0;
    final maximising = _toMove == 0;
    var best = maximising ? -kWinScore - 1 : kWinScore + 1;
    for (final cell in _orderedMoves(ply: ply)) {
      // Decremented exactly as [_search] does, flag included: if this drained
      // the budget silently, the guard in [_search] would never fire again and
      // the iteration would run unbounded. Set here, acted on only there.
      if (_budget > 0 && --_budget == 0) _outOfBudget = true;
      final won = _place(cell, ply);
      final value = won
          ? (maximising ? kWinScore - ply : -kWinScore + ply)
          : _solveExactly(alpha, beta, ply + 1);
      _lift(cell, ply);
      if (maximising) {
        if (value > best) best = value;
        if (best > alpha) alpha = best;
      } else {
        if (value < best) best = value;
        if (best < beta) beta = best;
      }
      if (alpha >= beta) break;
    }
    return best;
  }

  /// The cell that begins a forced win for side 0, or -1.
  ///
  /// Same algorithm as [threatSpaceWinNaively], same order of tests, same
  /// answers — but every question it asks is a counter this board already
  /// maintains, so a node costs a make, an unmake and one scan instead of two
  /// board copies and four.
  int _forcingWin(int left, _Counter budget) {
    // A standalone forcing board, never one the main search is using: this
    // makes and unmakes at a fixed ply, which would corrupt a canonical hash
    // keyed by depth and would dereference a hash that was never built.
    assert(_table == null && _canonicalPlies == 0);
    if (left < 1 || _toMove != 0) return -1;
    for (final cell in _forcingCandidateCells()) {
      if (--budget.left <= 0) return -1; // out of budget: claim nothing
      if (_place(cell, 0)) {
        _lift(cell, 0);
        return cell;
      }
      // Checked before anything else: if the opponent completes a line on the
      // very next move they do, and nothing we have started is forcing — not
      // even a double threat, because they never have to answer it.
      if (_threat[1] > 0) {
        _lift(cell, 0);
        continue;
      }
      final mine = _distinctThreats[0];
      // Two distinct winning cells cannot both be blocked. None at all and the
      // move was not forcing: the opponent replies where they like.
      if (mine != 1) {
        _lift(cell, 0);
        if (mine >= 2) return cell;
        continue;
      }
      final block = _soleThreatCell(0);
      final blockWon = _place(block, 0);
      final forced =
          !blockWon && !_isFull && _forcingWin(left - 1, budget) >= 0;
      _lift(block, 0);
      _lift(cell, 0);
      if (forced) return cell;
    }
    return -1;
  }

  /// The only cells that can create a threat: a move makes three-in-a-line
  /// exactly when it lands on a line where side 0 already holds two and the
  /// opponent holds none.
  ///
  /// Not a heuristic narrowing but the definition, which is what keeps the
  /// fan-out of a deep forcing search in single figures rather than near
  /// sixty. Ascending order, so the sequence a position yields never depends
  /// on which line happened to be scanned first.
  List<int> _forcingCandidateCells() {
    final seen = List<bool>.filled(64, false);
    final cells = <int>[];
    for (var l = 0; l < 76; l++) {
      if (_count[0][l] < 2 || _count[1][l] != 0) continue;
      for (final c in winningLines[l]) {
        if (_cells[c] != -1 || seen[c]) continue;
        seen[c] = true;
        cells.add(c);
      }
    }
    return cells..sort();
  }

  /// Where [side]'s single threat lands. Only meaningful when
  /// `_distinctThreats[side] == 1`.
  int _soleThreatCell(int side) {
    final threats = _cellThreat[side];
    for (var c = 0; c < 64; c++) {
      if (threats[c] > 0) return c;
    }
    return -1;
  }

  int _fork = kForkBonus;

  int _evaluate(double defence) {
    final mine = _total[0] + _fork * _forkTerm(_distinctThreats[0]);
    final theirs = _total[1] + _fork * _forkTerm(_distinctThreats[1]);
    return mine - (theirs * defence).round();
  }

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
  bool _place(int cell, int ply) {
    final side = _toMove;
    final lines = _lineIdsThroughCell[cell];
    // Three passes rather than one, because [_adjust] reads both the counts
    // and the board to find where a threat lands: the two must describe the
    // same position at each call, and a single interleaved loop leaves the
    // cell occupied while its counts still say otherwise.
    for (final l in lines) {
      _adjust(l, -1);
    }
    _cells[cell] = side;
    _placed++;
    var won = false;
    for (final l in lines) {
      if (++_count[side][l] == 4) won = true;
    }
    for (final l in lines) {
      _adjust(l, 1);
    }
    _toMove = 1 - side;
    if (_table != null) _plainHash ^= zobrist[side][cell] ^ zobristTurn;
    if (ply < _canonicalPlies) {
      _hash!
        ..toggle(side, cell)
        ..flipTurn();
    }
    return won;
  }

  void _lift(int cell, int ply) {
    final side = 1 - _toMove;
    _toMove = side;
    if (ply < _canonicalPlies) {
      _hash!
        ..flipTurn()
        ..toggle(side, cell);
    }
    if (_table != null) _plainHash ^= zobrist[side][cell] ^ zobristTurn;
    final lines = _lineIdsThroughCell[cell];
    for (final l in lines) {
      _adjust(l, -1);
    }
    _cells[cell] = -1;
    _placed--;
    for (final l in lines) {
      _count[side][l]--;
    }
    for (final l in lines) {
      _adjust(l, 1);
    }
  }

  /// Adds or removes line [l]'s current contribution to both running totals.
  /// Called either side of a change to the line's counts, which is what keeps
  /// the evaluation exact without ever recomputing it.
  void _adjust(int l, int sign) {
    for (var s = 0; s < 2; s++) {
      _total[s] += sign * _contribution(s, l);
      if (_isThreat(s, l) == 0) continue;
      _threat[s] += sign;
      // The line has three of s and none of the other, so exactly one of its
      // cells is empty: that is where the threat lands.
      for (final c in winningLines[l]) {
        if (_cells[c] != -1) continue;
        final before = _cellThreat[s][c];
        final after = before + sign;
        _cellThreat[s][c] = after;
        if (before == 0 && after > 0) _distinctThreats[s]++;
        if (before > 0 && after == 0) _distinctThreats[s]--;
        break;
      }
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
  List<int> _orderedMoves({int suggested = -1, int ply = -1}) {
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
    // Four tiers, best guess first. Alpha-beta's whole yield depends on this
    // order, and each tier is a different kind of evidence: what the table saw
    // last time, what refuted a sibling, what the rules call forcing, and
    // finally everything else.
    final head = <int>[];
    if (suggested >= 0 && _cells[suggested] == -1) head.add(suggested);
    if (ply >= 0 && ply < _maxPly) {
      for (var k = 0; k < 2; k++) {
        final killer = _killers[ply * 2 + k];
        if (killer >= 0 && _cells[killer] == -1 && !head.contains(killer)) {
          head.add(killer);
        }
      }
    }
    final first = <int>[];
    final rest = <int>[];
    for (var i = 0; i < 64; i++) {
      if (_cells[i] != -1 || head.contains(i)) continue;
      (urgent.contains(i) ? first : rest).add(i);
    }
    return head
      ..addAll(first)
      ..addAll(rest);
  }
}
