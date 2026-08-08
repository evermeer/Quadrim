/// Computer opponents are **data, not classes** (spec §9.4): one
/// [chooseMove] serves all twenty, parameterised by a [BotConfig]. Adding an
/// opponent is a catalogue entry, and calibration is a matter of running
/// self-play across configurations rather than across code paths.
///
/// Randomness is injected rather than ambient — this package may not reach
/// for a global `Random` — so a given seed and position always produce the
/// same move. That is what makes bot behaviour reproducible in a test and in
/// the self-play harness that resolves calibration (OI-03).
library;

import 'dart:math';

import 'engine.dart';
import 'winning_lines.g.dart';

/// The four rules that make an opponent look like it is paying attention
/// (Idea-final §6.2). Evaluated in order; the first that matches decides.
enum StrategicRule {
  /// Complete a line when one is available.
  winNow,

  /// Block the opponent completing a line on their next move.
  blockNow,

  /// Prefer a move creating two threats at once, which cannot both be blocked.
  makeDoubleThreat,

  /// Deny the opponent a move that would create two threats at once.
  blockDoubleThreat,
}

/// One opponent. Everything that distinguishes the twenty is in here.
final class BotConfig {
  const BotConfig({
    required this.id,
    required this.rating,
    this.searchDepth = 0,
    this.rules = const <StrategicRule>{},
    this.blunderRate = 0,
    this.centreBias = 0,
    this.cornerBias = 0,
    this.edgeBias = 0,
    this.lineBias = 0,
    this.aggression = 0.5,
    this.tieBreakRandomness = 1,
  })  : assert(blunderRate >= 0 && blunderRate <= 1),
        assert(centreBias >= 0 && centreBias <= 1),
        assert(cornerBias >= 0 && cornerBias <= 1),
        assert(edgeBias >= 0 && edgeBias <= 1),
        assert(lineBias >= 0 && lineBias <= 1),
        assert(aggression >= 0 && aggression <= 1),
        assert(tieBreakRandomness >= 0 && tieBreakRandomness <= 1),
        assert(searchDepth >= 0);

  /// Stable identifier, stored in a game document as `bot:<id>`. Never
  /// translated, and never renamed once a game has referenced it.
  final String id;

  /// The anchor rating this opponent is calibrated to. **Fixed** — when
  /// measurement disagrees, the configuration below is what changes (D144).
  final int rating;

  /// Plies of adversarial search. 0 means the rules and bias decide alone.
  final int searchDepth;

  final Set<StrategicRule> rules;

  /// Probability of discarding the chosen move for a different legal one.
  /// This is what separates opponents that share a rule set.
  final double blunderRate;

  /// Pull towards the central 2x2x2 cube, towards the eight corners, and
  /// towards the forty-eight cells that are neither.
  ///
  /// Independent knobs rather than one enum (D147): the roster's personalities
  /// distinguish "drawn to corners" from "strong centre preference", and the
  /// two cell classes are in fact equivalent under the board's symmetries
  /// (Idea-final §6.3) — so weighting them separately is a flavour choice the
  /// configuration should be able to express. The three classes partition the
  /// board, so exactly one of these applies to any cell.
  final double centreBias;
  final double cornerBias;
  final double edgeBias;

  /// Pull towards cells lying on lines this opponent is already building: the
  /// third positional rule (ticket 009), scored as the fraction of the seven
  /// lines through a cell that already hold two or more own pieces and no
  /// opponent piece.
  ///
  /// Kept below the gap between the class weights above, an opponent orders
  /// the positional rules — centre, then corner, then building — while a
  /// larger weight lets a later opponent care more about its own structure
  /// than about where on the board that structure sits (D149).
  final double lineBias;

  /// 0 is fully defensive, 1 fully aggressive, 0.5 weighs both equally.
  ///
  /// Below 0.5 the opponent denies a double threat before building one; at or
  /// above, it builds first. Above 0.5 it also begins skipping the denial
  /// altogether, with probability `2 * aggression - 1` — which is how the
  /// roster's "ignores opponent double threats about a third of the time"
  /// is expressed as a number rather than as a special case.
  final double aggression;

  /// How much to randomise among moves the configuration rates equally. At 0
  /// the first equal-best move in cell order is taken, which is
  /// deterministic but makes an opponent feel mechanical.
  final double tieBreakRandomness;

  /// The probability this opponent lets a double threat go undenied.
  double get _denialSkipChance => max(0, 2 * aggression - 1);
}

const Set<StrategicRule> _allRules = {
  StrategicRule.winNow,
  StrategicRule.blockNow,
  StrategicRule.makeDoubleThreat,
  StrategicRule.blockDoubleThreat,
};

// ---------------------------------------------------------------------------
// The catalogue. Configurations realise the personalities in Idea-final §6.4;
// the ratings there are fixed and these parameters are what gets tuned when
// measured strength disagrees with them (D144).
// ---------------------------------------------------------------------------

/// Purely random legal moves. Never notices a threat.
const BotConfig pebble = BotConfig(id: 'pebble', rating: 600);

/// Random, but takes an immediate win when one is available.
const BotConfig twig = BotConfig(
  id: 'twig',
  rating: 700,
  rules: {StrategicRule.winNow},
);

/// Wins and blocks when it sees them — which is most of the time it does not.
const BotConfig mote = BotConfig(
  id: 'mote',
  rating: 800,
  rules: {StrategicRule.winNow, StrategicRule.blockNow},
  blunderRate: 0.40,
);

/// Wins and blocks, blunders a fifth of the time, drawn to corners.
const BotConfig clover = BotConfig(
  id: 'clover',
  rating: 900,
  rules: {StrategicRule.winNow, StrategicRule.blockNow},
  blunderRate: 0.20,
  cornerBias: 0.6,
);

/// All four rules, no positional sense at all.
const BotConfig bramble = BotConfig(
  id: 'bramble',
  rating: 1000,
  rules: _allRules,
  blunderRate: 0.15,
);

/// All four rules with a strong pull to the centre.
const BotConfig finch = BotConfig(
  id: 'finch',
  rating: 1100,
  rules: _allRules,
  blunderRate: 0.12,
  centreBias: 0.9,
);

/// Corner-hungry and aggressive: builds before it denies, and lets a third of
/// the opponent's double threats through.
const BotConfig kestrel = BotConfig(
  id: 'kestrel',
  rating: 1200,
  rules: _allRules,
  blunderRate: 0.11,
  cornerBias: 0.8,
  aggression: 0.67,
);

/// Defensive: denies before it builds.
const BotConfig willow = BotConfig(
  id: 'willow',
  rating: 1250,
  rules: _allRules,
  blunderRate: 0.10,
  aggression: 0.30,
);

/// All four rules cleanly applied, no positional heuristic.
const BotConfig ember = BotConfig(
  id: 'ember',
  rating: 1300,
  rules: _allRules,
  blunderRate: 0.08,
);

/// The first opponent with a plan: all four rules plus the full positional
/// ladder — centre, then corner, then the cell on the most lines it is
/// already building — and only a 6% blunder rate (Idea-final §6.4).
///
/// The weights realise the ladder as an order: any centre cell (1.00 … 1.25)
/// outscores any corner (0.50 … 0.75), which outscores any other cell
/// (0.00 … 0.25), and the building term decides within each class.
const BotConfig basalt = BotConfig(
  id: 'basalt',
  rating: 1400,
  rules: _allRules,
  blunderRate: 0.06,
  centreBias: 1,
  cornerBias: 0.5,
  lineBias: 0.25,
);

/// Every shipped opponent, weakest first.
const List<BotConfig> opponentCatalogue = [
  pebble,
  twig,
  mote,
  clover,
  bramble,
  finch,
  kestrel,
  willow,
  ember,
  basalt,
];

BotConfig? botById(String id) {
  for (final bot in opponentCatalogue) {
    if (bot.id == id) return bot;
  }
  return null;
}

// ---------------------------------------------------------------------------
// Move choice
// ---------------------------------------------------------------------------

/// Chooses [config]'s move in [state], drawing any randomness from [random].
///
/// Throws [StateError] if the game is already over — a caller asking a bot to
/// move in a finished game has a bug, and returning a sentinel would hide it.
Cell chooseMove(GameState state, BotConfig config, Random random) {
  final moves = legalMoves(state);
  if (moves.isEmpty) throw StateError('no legal move: the game is over');

  // Adversarial search is ticket 010. Throwing rather than quietly falling
  // through to the rules means a catalogue entry added ahead of its behaviour
  // fails loudly instead of shipping as a weaker opponent (D142).
  if (config.searchDepth > 0) {
    throw UnimplementedError(
      'bot ${config.id} asks for ${config.searchDepth}-ply search, '
      'which arrives with ticket 010',
    );
  }

  final me = state.sideToMove;
  final candidates = _ruleCandidates(state, config, random, me) ?? moves;
  final chosen = _positionalPick(config, random, state, me, candidates);

  // A blunder discards the considered move for a different legal one. It is a
  // probability of not thinking, not a guarantee of playing badly — the
  // replacement is merely unconsidered, and may happen to be reasonable.
  if (config.blunderRate > 0 && random.nextDouble() < config.blunderRate) {
    final alternatives = [
      for (final m in moves)
        if (m.index != chosen.index) m,
    ];
    if (alternatives.isNotEmpty) {
      return alternatives[random.nextInt(alternatives.length)];
    }
  }
  return chosen;
}

/// The cells the first matching enabled rule points at, or null when no rule
/// fires and the positional preference decides alone.
List<Cell>? _ruleCandidates(
  GameState state,
  BotConfig config,
  Random random,
  Player me,
) {
  if (config.rules.isEmpty) return null;
  final opponent = me.opponent;

  // Rules 1 and 2 are never reordered: taking an offered win is never wrong,
  // and missing an offered loss is what blunderRate is for.
  if (config.rules.contains(StrategicRule.winNow)) {
    final wins = _immediateWins(state, me);
    if (wins.isNotEmpty) return wins;
  }
  if (config.rules.contains(StrategicRule.blockNow)) {
    final losses = _immediateWins(state, opponent);
    if (losses.isNotEmpty) return losses;
  }

  // Rules 3 and 4 are where temperament shows.
  final buildFirst = config.aggression >= 0.5;
  final skipDenial = random.nextDouble() < config._denialSkipChance;

  List<Cell>? build() => config.rules.contains(StrategicRule.makeDoubleThreat)
      ? _doubleThreatCells(state, me)
      : null;
  List<Cell>? deny() =>
      config.rules.contains(StrategicRule.blockDoubleThreat) && !skipDenial
          ? _doubleThreatCells(state, opponent)
          : null;

  for (final rule in buildFirst ? [build, deny] : [deny, build]) {
    final cells = rule();
    if (cells != null && cells.isNotEmpty) return cells;
  }
  return null;
}

/// Cells where [player] completes a line right now.
List<Cell> _immediateWins(GameState state, Player player) {
  final cells = <int>{for (final t in threats(state, player)) t.emptyCell.index};
  return _sorted(cells);
}

/// Cells where [player] would end up with two or more *distinct* follow-up
/// winning cells — a double threat, which cannot be blocked by one move.
List<Cell> _doubleThreatCells(GameState state, Player player) {
  final result = <int>{};
  for (final cell in legalMoves(state)) {
    if (_followUpWins(state, player, cell.index).length >= 2) {
      result.add(cell.index);
    }
  }
  return _sorted(result);
}

/// The cells [player] could win on next turn, were they to play [cell] now.
///
/// Counting distinct *empty* cells rather than lines is the point: two lines
/// of three sharing their last empty cell are stopped by one block, so they
/// are not a double threat.
Set<int> _followUpWins(GameState state, Player player, int cell) {
  final wins = <int>{};
  for (final line in _linesThrough[cell]) {
    var owned = 0;
    var empty = -1;
    var dead = false;
    for (final c in line) {
      if (c == cell) continue;
      final owner = state.owner(Cell(c));
      if (owner == player) {
        owned++;
      } else if (owner == null) {
        if (empty != -1) {
          dead = true; // two empties left: still two moves away
          break;
        }
        empty = c;
      } else {
        dead = true; // opponent piece: this line is dead
        break;
      }
    }
    if (!dead && owned == 2 && empty != -1) wins.add(empty);
  }
  return wins;
}

/// Picks among equally-rule-worthy [candidates] by positional preference.
///
/// The same step decides both when no strategic rule fires — [candidates] is
/// then every legal move — and as the tie-break within a rule that points at
/// several cells.
Cell _positionalPick(
  BotConfig config,
  Random random,
  GameState state,
  Player me,
  List<Cell> candidates,
) {
  if (candidates.length == 1) return candidates.first;

  var best = <Cell>[];
  var bestScore = double.negativeInfinity;
  for (final cell in candidates) {
    final score = _positionalScore(config, state, me, cell);
    if (score > bestScore) {
      bestScore = score;
      best = [cell];
    } else if (score == bestScore) {
      best.add(cell);
    }
  }
  if (best.length == 1) return best.first;
  return random.nextDouble() < config.tieBreakRandomness
      ? best[random.nextInt(best.length)]
      : best.first;
}

/// The positional ladder as one number: the cell's class, plus how much of a
/// line it already continues. The three classes partition the board, so the
/// weights order the rules rather than accumulating.
double _positionalScore(
  BotConfig config,
  GameState state,
  Player me,
  Cell cell,
) {
  var score = isCentreCell(cell)
      ? config.centreBias
      : isCornerCell(cell)
          ? config.cornerBias
          : config.edgeBias;
  if (config.lineBias > 0) {
    score += config.lineBias *
        _buildingLines(state, me, cell.index) /
        _maxLinesThroughACell;
  }
  return score;
}

/// How many lines through [cell] already hold two or more of [player]'s pieces
/// and no opponent piece — the lines this move would be continuing.
int _buildingLines(GameState state, Player player, int cell) {
  var count = 0;
  for (final line in _linesThrough[cell]) {
    var owned = 0;
    var blocked = false;
    for (final c in line) {
      if (c == cell) continue;
      final owner = state.owner(Cell(c));
      if (owner == player) {
        owned++;
      } else if (owner != null) {
        blocked = true;
        break;
      }
    }
    if (!blocked && owned >= 2) count++;
  }
  return count;
}

/// Corners and centre cells lie on seven lines; every other cell on four.
const int _maxLinesThroughACell = 7;

/// The eight cells of the central 2x2x2 cube.
bool isCentreCell(Cell cell) =>
    _isInner(cell.x) && _isInner(cell.y) && _isInner(cell.z);

/// The eight cube corners.
bool isCornerCell(Cell cell) =>
    _isEdge(cell.x) && _isEdge(cell.y) && _isEdge(cell.z);

bool _isInner(int c) => c == 1 || c == 2;

bool _isEdge(int c) => c == 0 || c == 3;

List<Cell> _sorted(Set<int> cells) =>
    (cells.toList()..sort()).map(Cell.new).toList();

/// The winning lines through each cell, built once. Rules 3 and 4 ask about
/// every empty cell on every move, so walking all 76 lines each time would be
/// an order of magnitude of wasted work.
final List<List<List<int>>> _linesThrough = _buildLinesThrough();

List<List<List<int>>> _buildLinesThrough() {
  final byCell = List.generate(64, (_) => <List<int>>[]);
  for (final line in winningLines) {
    for (final cell in line) {
      byCell[cell].add(line);
    }
  }
  return byCell;
}
