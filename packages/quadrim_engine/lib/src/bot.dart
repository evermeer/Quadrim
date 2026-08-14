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
import 'search.dart';
import 'strategy_book.dart';
import 'winning_lines.g.dart';

/// The four rules that make an opponent look like it is paying attention
/// (idea-v1 §6.2). Evaluated in order; the first that matches decides.
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

/// Which band of the ladder an opponent belongs to (spec §8.5).
///
/// Stored rather than derived from [BotConfig.rating], even though the five
/// tiers happen to occupy contiguous rating bands today. A tier is what an
/// opponent *is* and a rating is how strong it measured; tying them together
/// would mean a recalibration silently reclassified an opponent, and would
/// take away the ability to show a tier for one whose number is not yet
/// trustworthy — which is exactly what ticket 011 asks for (D179).
enum BotTier { novice, casual, club, expert, master }

/// One opponent. Everything that distinguishes the twenty is in here.
final class BotConfig {
  const BotConfig({
    required this.id,
    required this.rating,
    this.tier = BotTier.club,
    this.searchDepth = 0,
    this.threatSearchDepth = 0,
    this.defenceSearchDepth = 0,
    this.usesBook = false,
    this.nodeBudget = 0,
    this.maxSearchDepth = 0,
    this.exactEmpties = 0,
    this.canonicalPlies = 0,
    this.forcingBudget = kForcingBudget,
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
        assert(searchDepth >= 0),
        assert(threatSearchDepth >= 0),
        assert(defenceSearchDepth >= 0),
        assert(nodeBudget >= 0),
        assert(maxSearchDepth >= 0),
        assert(exactEmpties >= 0),
        assert(canonicalPlies >= 0);

  /// Stable identifier, stored in a game document as `bot:<id>`. Never
  /// translated, and never renamed once a game has referenced it.
  final String id;

  /// The anchor rating this opponent is calibrated to. **Fixed** — when
  /// measurement disagrees, the configuration below is what changes (D144).
  final int rating;

  /// Which band of the ladder this opponent sits in. Independent of [rating]
  /// on purpose — see [BotTier].
  ///
  /// Defaulted rather than required because a tier is catalogue metadata that
  /// nothing in this package reads: the synthetic configurations tests and
  /// `tool/` build are not on the ladder, and `required` would only force them
  /// to name a band, not to name the right one. What pins the twenty that do
  /// matter is a test over the catalogue itself (D179).
  final BotTier tier;

  /// Plies of adversarial search, counting this opponent's own move. 0 means
  /// the rules and the positional ladder decide alone.
  final int searchDepth;

  /// How many of its *own* forcing moves this opponent will follow when
  /// hunting a forced win. 0 disables threat-space search.
  ///
  /// Separate from [searchDepth] because the two look at different things: a
  /// depth-limited search sees every reply and so cannot go far, while this
  /// sees only replies the opponent has no choice about and so goes much
  /// further for much less work (D151).
  final int threatSearchDepth;

  /// How many of the *opponent's* forcing moves this opponent will follow when
  /// checking that a move it is about to play does not hand over a forced win.
  /// 0 means it never looks, and walks into forced wins it could have seen.
  ///
  /// A separate number from [threatSearchDepth] rather than the same one,
  /// because seeing your own wins and seeing your opponent's are different
  /// skills that improve at different times — a club player spots their own
  /// combination long before they stop losing to someone else's. Splitting
  /// them gives the ladder a dimension that raising the node budget did not
  /// (D169).
  final int defenceSearchDepth;

  /// Whether this opponent plays from Patashnik's strategy dictionary.
  ///
  /// The book is a proof that Qubic is a first-player win, so an opponent that
  /// consults it **cannot be beaten when it opens** — no search, no depth, no
  /// budget, just the move the proof names. It says nothing about playing
  /// second, where such an opponent falls back to searching like any other
  /// (D172).
  final bool usesBook;

  /// Nodes this opponent may visit choosing one move. Above zero it searches
  /// by iterative deepening under that budget instead of to [searchDepth].
  ///
  /// A budget in **nodes rather than milliseconds** is what keeps an opponent
  /// the same opponent on a fast phone and a slow one, in debug and in
  /// release, in CI and on a device (ticket 025). The wall clock each budget
  /// buys is measured and recorded in D162, not compiled in.
  ///
  /// The ceiling these are sized against is twenty seconds a move on a device
  /// (D164), spent as a ladder: the tiers below this one answer in
  /// milliseconds, and only the Master tier goes near the ceiling.
  final int nodeBudget;

  /// The deepest iteration a budgeted search will attempt.
  final int maxSearchDepth;

  /// Nodes the forcing search may visit. Bounded for the same reason the main
  /// search is: without it a deep forcing search is minutes rather than
  /// milliseconds on the positions where it fans out (D168).
  final int forcingBudget;

  /// Below this many empty cells the opponent stops estimating and proves the
  /// result. 0 leaves the endgame to the heuristic like everything else.
  final int exactEmpties;

  /// How many plies from the root are cached by canonical form rather than by
  /// the position as it stands. Worth it only near an empty board — see D161.
  final int canonicalPlies;

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
  /// (idea-v1 §6.3) — so weighting them separately is a flavour choice the
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

  /// What the opponent's line ownership counts for, relative to its own, in
  /// the search's heuristic evaluation. 1 weighs both equally; above 1 the
  /// opponent's structure worries it more than its own pleases it.
  ///
  /// Derived from [aggression] rather than configured separately (D150), so
  /// Ember and Basalt differ in temperament by one number, in the rule order
  /// and in the evaluation at once — which is what "opposing temperaments"
  /// has to mean if the two are to be distinguishable in play.
  double get defence => 2 * (1 - aggression);
}

const Set<StrategicRule> _allRules = {
  StrategicRule.winNow,
  StrategicRule.blockNow,
  StrategicRule.makeDoubleThreat,
  StrategicRule.blockDoubleThreat,
};

// ---------------------------------------------------------------------------
// The catalogue. Configurations realise the personalities in idea-v3 §6.4;
// the ratings there are fixed and these parameters are what gets tuned when
// measured strength disagrees with them (D144).
// ---------------------------------------------------------------------------

/// Purely random legal moves. Never notices a threat.
const BotConfig pebble = BotConfig(id: 'pebble', tier: BotTier.novice, rating: 600);

/// Random, but takes an immediate win when one is available.
const BotConfig twig = BotConfig(
  id: 'twig',
  tier: BotTier.novice,
  rating: 700,
  rules: {StrategicRule.winNow},
);

/// Wins and blocks when it sees them — which is most of the time it does not.
const BotConfig mote = BotConfig(
  id: 'mote',
  tier: BotTier.novice,
  rating: 800,
  rules: {StrategicRule.winNow, StrategicRule.blockNow},
  blunderRate: 0.40,
);

/// Wins and blocks, blunders a fifth of the time, drawn to corners.
const BotConfig clover = BotConfig(
  id: 'clover',
  tier: BotTier.novice,
  rating: 900,
  rules: {StrategicRule.winNow, StrategicRule.blockNow},
  blunderRate: 0.20,
  cornerBias: 0.6,
);

/// All four rules, no positional sense at all.
const BotConfig bramble = BotConfig(
  id: 'bramble',
  tier: BotTier.casual,
  rating: 1000,
  rules: _allRules,
  blunderRate: 0.15,
);

// What orders the Casual tier is how many of the sixteen seven-line cells an
// opponent prefers, not its blunder rate (D210).
//
// The eight corners and the eight cells of the inner 2x2x2 each lie on seven
// of the 76 lines; every other cell lies on four. Preferring one of those two
// groups is worth far more than the percentage point of blunder rate that
// separates neighbours here — and the blunder rates *cannot* spread, because
// they must fall as rating rises and the tier is bracketed by Bramble at 0.15
// and Kestrel at 0.08. So the ladder is: Bramble prefers none of the sixteen,
// Willow and Vireo prefer eight each, and Finch and Kestrel prefer all
// sixteen. Spec 8.4 gives the whole tier a centre preference, so this is the
// tier conforming to it rather than departing from it.
//
// Only the *order* of the bias weights reaches the board. With no lineBias
// there is nothing to compare their magnitudes against, so an opponent that
// ranks corners above centres above everything else plays identically at
// (0.55, 0.35) and at (0.8, 0.6) — measured, byte for byte, when a first
// attempt at this tried to weaken Vireo by lowering both.

/// All four rules and a strong pull to the middle of the cube.
const BotConfig willow = BotConfig(
  id: 'willow',
  tier: BotTier.casual,
  rating: 1100,
  rules: _allRules,
  blunderRate: 0.13,
  centreBias: 0.6,
);

/// Corner-hungry and aggressive: builds before it denies, and lets a third of
/// the opponent's double threats through.
///
/// It sees the centre too, and ranks it below the corners — the extra eight
/// good cells are what pay for a third of its denials going missing.
const BotConfig vireo = BotConfig(
  id: 'vireo',
  tier: BotTier.casual,
  rating: 1200,
  rules: _allRules,
  blunderRate: 0.11,
  centreBias: 0.5,
  cornerBias: 0.7,
  aggression: 0.67,
);

/// Defensive: denies before it builds, and takes good squares while it does.
const BotConfig finch = BotConfig(
  id: 'finch',
  tier: BotTier.casual,
  rating: 1250,
  rules: _allRules,
  blunderRate: 0.10,
  centreBias: 0.7,
  cornerBias: 0.5,
  aggression: 0.30,
);

/// The tier's ceiling: all four rules cleanly applied, the full sixteen good
/// squares, and nothing given away.
///
/// What Marlin adds on top is the building term — the cell on the most lines
/// it is already working — which is a lever this one does not have at all.
const BotConfig kestrel = BotConfig(
  id: 'kestrel',
  tier: BotTier.casual,
  rating: 1300,
  rules: _allRules,
  blunderRate: 0.08,
  centreBias: 0.8,
  cornerBias: 0.6,
);

/// The first opponent with a plan: all four rules plus the full positional
/// ladder — centre, then corner, then the cell on the most lines it is
/// already building — and only a 6% blunder rate (idea-v3 §6.4).
///
/// The weights realise the ladder as an order: any centre cell (1.00 … 1.25)
/// outscores any corner (0.50 … 0.75), which outscores any other cell
/// (0.00 … 0.25), and the building term decides within each class.
const BotConfig marlin = BotConfig(
  id: 'marlin',
  tier: BotTier.club,
  rating: 1400,
  rules: _allRules,
  blunderRate: 0.06,
  centreBias: 1,
  cornerBias: 0.5,
  lineBias: 0.25,
);

// The Club tier's searching opponents. All four are Marlin's rules and
// positional ladder plus a look ahead; what separates them is how far they
// look, at what, and with which temperament.

/// Two plies, weighted towards its own structure.
const BotConfig ember = BotConfig(
  id: 'ember',
  tier: BotTier.club,
  rating: 1500,
  searchDepth: 2,
  rules: _allRules,
  blunderRate: 0.05,
  centreBias: 1,
  cornerBias: 0.5,
  lineBias: 0.25,
  aggression: 0.6,
);

/// Three plies and a short look for forced wins, weighted towards what the
/// opponent is building.
///
/// Deeper than Ember, and looking two forcing moves ahead, because
/// temperament alone does not separate them: measured over 400 games at equal
/// depth the two are level, and defensive weighting turns out to be worth
/// nothing at all in a game of 76 competing lines (D154).
const BotConfig basalt = BotConfig(
  id: 'basalt',
  tier: BotTier.club,
  rating: 1550,
  searchDepth: 3,
  threatSearchDepth: 3,
  rules: _allRules,
  blunderRate: 0.04,
  centreBias: 1,
  cornerBias: 0.5,
  lineBias: 0.25,
  aggression: 0.4,
);

/// Three plies and a five-move forcing search, even-handed. The first
/// opponent that will beat a competent human more often than not.
///
/// Its edge over Basalt is entirely the forcing search. Depth is the weakest
/// of the three levers this engine has, and past three plies it does not
/// separate opponents at all (D154, D156).
const BotConfig onyx = BotConfig(
  id: 'onyx',
  tier: BotTier.club,
  rating: 1650,
  searchDepth: 3,
  threatSearchDepth: 6,
  rules: _allRules,
  blunderRate: 0.03,
  centreBias: 1,
  cornerBias: 0.5,
  lineBias: 0.25,
);

/// Four plies plus threat-space search, so it also sees forced wins far
/// beyond that horizon.
const BotConfig sable = BotConfig(
  id: 'sable',
  tier: BotTier.club,
  rating: 1700,
  searchDepth: 4,
  threatSearchDepth: 9,
  rules: _allRules,
  blunderRate: 0.02,
  centreBias: 1,
  cornerBias: 0.5,
  lineBias: 0.25,
);

// ---------------------------------------------------------------------------
// The Expert tier. The first opponents whose budget is expressed in nodes
// rather than plies, because how deep a budget reaches depends on the
// position and iterative deepening takes whatever it can finish.
// ---------------------------------------------------------------------------

/// Iterative deepening under a transposition table.
const BotConfig corvus = BotConfig(
  id: 'corvus',
  tier: BotTier.expert,
  rating: 1800,
  nodeBudget: 500000,
  maxSearchDepth: 8,
  threatSearchDepth: 9,
  rules: _allRules,
  blunderRate: 0.015,
  centreBias: 1,
  cornerBias: 0.5,
  lineBias: 0.25,
);

/// Corvus with a longer look, and the first opponent that checks what its own
/// move hands over (D169).
const BotConfig lyra = BotConfig(
  id: 'lyra',
  tier: BotTier.expert,
  rating: 1900,
  nodeBudget: 900000,
  maxSearchDepth: 8,
  threatSearchDepth: 11,
  defenceSearchDepth: 5,
  rules: _allRules,
  blunderRate: 0.01,
  centreBias: 1,
  cornerBias: 0.5,
  lineBias: 0.25,
);

/// A budget large enough to reach the middle of the ticket's depth range, and
/// two more moves of defence than Lyra.
const BotConfig quartz = BotConfig(
  id: 'quartz',
  tier: BotTier.expert,
  rating: 2000,
  nodeBudget: 1800000,
  maxSearchDepth: 10,
  threatSearchDepth: 13,
  defenceSearchDepth: 7,
  rules: _allRules,
  blunderRate: 0.005,
  centreBias: 1,
  cornerBias: 0.5,
  lineBias: 0.25,
);

/// Quartz plus exact endgame solving, defence as deep as it repays, and no
/// deliberate blunders at all.
///
/// Once ten cells remain it stops estimating: the result it returns is proved,
/// not judged, and no heuristic overrides it. The forcing budget is five times
/// the default because it is shared out among the candidates being checked,
/// and an unstarved defence measured 36-24 against a starved one (D170).
const BotConfig titan = BotConfig(
  id: 'titan',
  tier: BotTier.expert,
  rating: 2100,
  nodeBudget: 2500000,
  maxSearchDepth: 10,
  threatSearchDepth: 15,
  defenceSearchDepth: 9,
  forcingBudget: 1000000,
  exactEmpties: 10,
  rules: _allRules,
  centreBias: 1,
  cornerBias: 0.5,
  lineBias: 0.25,
);

// ---------------------------------------------------------------------------
// The Master tier. The first opponents that stop estimating and start knowing:
// they play Patashnik's proof from the opening, and search only once it runs
// out. Unbeatable when they open, merely very strong when they do not (D172).
// ---------------------------------------------------------------------------

/// Unbeatable when it opens; ordinary-strong when it does not.
///
/// Oracle and Quadrim Prime play the identical book, so in the games they open
/// they are the same opponent and neither can be beaten. Everything that
/// separates them lives in the **second seat**, where there is no proof to play
/// and both fall back on searching (D173) — Oracle with the Expert tier's
/// machinery, Prime with the largest configuration in the catalogue.
///
/// This is the honest place to put the difference, and it was arrived at by
/// eliminating the alternatives rather than by design. A blunder rate was tried
/// and rejected: it would have made a higher-rated opponent blunder more than
/// the one below it, which the catalogue forbids and a player would notice. A
/// shallower forcing search was tried and **measured as no difference at all** —
/// byte-identical results over 200 games — because the forced wins that follow
/// the book are short enough that eleven moves of search find them as reliably
/// as twenty (D176).
const BotConfig oracle = BotConfig(
  id: 'oracle',
  tier: BotTier.master,
  rating: 2300,
  usesBook: true,
  nodeBudget: 1800000,
  maxSearchDepth: 10,
  threatSearchDepth: 13,
  defenceSearchDepth: 5,
  forcingBudget: 500000,
  rules: _allRules,
  centreBias: 1,
  cornerBias: 0.5,
  lineBias: 0.25,
);

/// The proof, played straight.
///
/// No blunder rate, the deepest forcing search in the catalogue, and the book
/// from move one. When Quadrim Prime opens, the game is decided before it is
/// played: Patashnik proved in 1980 that the first player wins, and this is
/// that proof with a board attached. Beating it requires it to move second.
const BotConfig quadrimPrime = BotConfig(
  id: 'quadrim_prime',
  tier: BotTier.master,
  rating: 2400,
  usesBook: true,
  nodeBudget: 3000000,
  maxSearchDepth: 12,
  threatSearchDepth: 20,
  defenceSearchDepth: 9,
  forcingBudget: 2000000,
  exactEmpties: 12,
  rules: _allRules,
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
  willow,
  vireo,
  finch,
  kestrel,
  marlin,
  ember,
  basalt,
  onyx,
  sable,
  corvus,
  lyra,
  quartz,
  titan,
  oracle,
  quadrimPrime,
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

  final me = state.sideToMove;
  var candidates = _bookMove(state, config, me) ??
      _forcedWin(state, config, me) ??
      _ruleCandidates(state, config, random, me) ??
      moves;

  // Before anything else weighs the candidates: drop the ones that lose. A
  // move that hands the opponent a forced win is not a move worth scoring, and
  // no amount of positional merit redeems it.
  candidates = _safeCandidates(state, config, me, candidates);

  // Search narrows the candidates to those it cannot separate; the positional
  // ladder then decides among them exactly as it does without search. Two
  // moves the evaluation scores alike are genuinely alike to this opponent,
  // and picking the more central of them is better than picking at random.
  if (candidates.length > 1 &&
      (config.searchDepth > 0 || config.nodeBudget > 0)) {
    candidates = _searchBest(state, config, me, candidates);
  }

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

/// The strategic move Patashnik's dictionary gives for this position, when
/// this opponent consults it and the position is in it.
///
/// The dictionary's own header prescribes the order this sits in: win
/// immediately if you can, otherwise block, otherwise play the book move,
/// otherwise execute a forced win. The first two are already inside
/// [_ruleCandidates], so the gate here is the same one [_forcedWin] uses —
/// neither side one move from completing a line.
List<Cell>? _bookMove(GameState state, BotConfig config, Player me) {
  if (!config.usesBook) return null;
  if (_immediateWins(state, me).isNotEmpty) return null;
  if (_immediateWins(state, me.opponent).isNotEmpty) return null;
  final move = bookMove(state, me);
  return move == null ? null : [move];
}

/// The single move that begins a forced win, when this opponent looks for
/// one and one exists.
///
/// Gated on neither side having an immediate win: if this opponent has one,
/// rule 1 takes it and nothing is faster; if the opponent has one, no forcing
/// sequence of ours survives their taking it, and rule 2 must block.
List<Cell>? _forcedWin(GameState state, BotConfig config, Player me) {
  if (config.threatSearchDepth == 0) return null;
  if (_immediateWins(state, me).isNotEmpty) return null;
  if (_immediateWins(state, me.opponent).isNotEmpty) return null;
  final move = threatSpaceWin(state, me, config.threatSearchDepth,
      nodeBudget: config.forcingBudget);
  return move == null ? null : [move];
}

/// [candidates] with the losing ones removed: those after which the opponent
/// can force a win.
///
/// This is the same threat-space search [_forcedWin] runs, pointed the other
/// way. Pointing it the other way is most of what it is worth: finding your
/// own forced win only pays in the positions where you have one, while seeing
/// the opponent's pays in every position where you were about to allow one
/// — and in Qubic one allowed forcing sequence is the whole game.
///
/// Returns [candidates] unchanged when every move loses. A lost position is
/// still played out: resigning is the human's move to make, not the
/// opponent's, and a losing move played on is how the opponent finds out
/// whether this one can actually finish it.
List<Cell> _safeCandidates(
  GameState state,
  BotConfig config,
  Player me,
  List<Cell> candidates,
) {
  if (config.defenceSearchDepth == 0 || candidates.length < 2) {
    return candidates;
  }
  // The budget is shared out, not handed to each in turn, so that checking
  // thirty candidates costs what checking one costs — the ceiling is per
  // move (D164), not per question asked about it.
  final each = config.forcingBudget ~/ candidates.length;
  if (each < 1) return candidates;

  final safe = <Cell>[];
  for (final cell in candidates) {
    final after = applyMove(state, cell);
    // A move that wins outright is not open to refutation.
    if (outcome(after) is Win) return [cell];
    final reply = threatSpaceWin(
      after,
      me.opponent,
      config.defenceSearchDepth,
      nodeBudget: each,
    );
    if (reply == null) safe.add(cell);
  }
  return safe.isEmpty ? candidates : safe;
}

/// The candidates the search cannot separate: those scoring the maximum.
List<Cell> _searchBest(
  GameState state,
  BotConfig config,
  Player me,
  List<Cell> candidates,
) {
  final scores = config.nodeBudget > 0
      ? deepSearch(
          state,
          me,
          candidates,
          SearchLimits(
            nodeBudget: config.nodeBudget,
            maxDepth: config.maxSearchDepth,
            defence: config.defence,
            exactEmpties: config.exactEmpties,
            canonicalPlies: config.canonicalPlies,
          ),
        ).scores
      : searchScores(state, me, candidates, config.searchDepth,
          defence: config.defence);
  final best = scores.reduce(max);
  return [
    for (var i = 0; i < candidates.length; i++)
      if (scores[i] == best) candidates[i],
  ];
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
