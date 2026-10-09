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

/// One opponent. Everything that distinguishes the thirty-one is in here.
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
    this.ruleChance = const <StrategicRule, double>{},
    this.blunderRate = 0,
    this.centreBias = 0,
    this.cornerBias = 0,
    this.edgeBias = 0,
    this.lineBias = 0,
    this.positionChance = 1,
    this.aggression = 0.5,
    this.tieBreakRandomness = 1,
  })  : assert(blunderRate >= 0 && blunderRate <= 1),
        assert(centreBias >= 0 && centreBias <= 1),
        assert(cornerBias >= 0 && cornerBias <= 1),
        assert(edgeBias >= 0 && edgeBias <= 1),
        assert(lineBias >= 0 && lineBias <= 1),
        assert(positionChance >= 0 && positionChance <= 1),
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

  /// How often each rule in [rules] actually fires, as a probability. A rule
  /// absent from this map fires every time, which is what every rule did
  /// before D343.
  ///
  /// **The rules are cliffs and the ladder needs steps.** Measured in
  /// isolation on this board, `makeDoubleThreat` is worth about 100 rating
  /// points, `blockDoubleThreat` about 128 and a positional preference about
  /// 162 — against rungs that are forty to fifty points apart. So a rung that
  /// introduces a rule overshoots by three or four rungs' worth, and one that
  /// does not is left with the blunder rate, worth about six points per
  /// hundredth. That is why Hazel to Juniper asked for 170 points and its
  /// configurations delivered 618.
  ///
  /// A probability turns each of those cliffs into a dial: `makeDoubleThreat`
  /// at 0.35 is worth roughly a third of 100. It also describes something real
  /// — a player who has learnt about traps and spots them sometimes — rather
  /// than a knob with no meaning at the board.
  ///
  /// A chance of 1 draws no random number at all, so adding this field moved
  /// no existing opponent's play by a single move.
  final Map<StrategicRule, double> ruleChance;

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

  /// How often the positional preference is consulted at all. Below 1 the
  /// opponent sometimes ignores where it likes to play and takes any of the
  /// moves in front of it.
  ///
  /// **The last cliff on the ladder** (D343). A preference for the sixteen
  /// seven-line cells measures 162 rating points against rungs forty points
  /// apart, and unlike a rule it cannot be dialled by [ruleChance] because it
  /// is not a rule — it is how every remaining move is ranked once the rules
  /// have had their say. Without this, Juniper's `centreBias` lands 162 points
  /// on a forty-point rung and no arrangement of the other levers absorbs it:
  /// its rule chances would have to go below zero.
  ///
  /// At 1 — the default, and what every opponent had before — no random number
  /// is drawn and the ranking is used exactly as it always was.
  final double positionChance;

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
// The catalogue. Configurations realise the personalities in idea-v4 §6.4;
// the ratings there are fixed and these parameters are what gets tuned when
// measured strength disagrees with them (D144).
// ---------------------------------------------------------------------------

/// Random legal moves, except that it sometimes takes a win it is handed.
///
/// **It was purely random until D341, and purely random is not 600.** Measured
/// against the roster it played some 400 points below its anchor and lost 1-49
/// to Twig, whose only advantage is `winNow` — so on this board that one rule
/// is worth nearly seven hundred points, and no gap of a hundred can be built
/// across it by leaving one side without it. Pebble therefore has the rule too
/// and misses most of what it offers.
///
/// The blunder rate is what the rung is tuned with, and it is the only lever
/// here: with no rules at all there is nothing for a blunder to discard, which
/// is why the previous configuration could not be moved at any price.
const BotConfig pebble = BotConfig(
  id: 'pebble',
  tier: BotTier.novice,
  rating: 600,
  rules: {StrategicRule.winNow},
  blunderRate: 0.71,
);

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

/// Mote, paying attention rather more often.
///
/// Fills what used to be a hundred rating points of nothing between Mote and
/// Clover, which is the stretch a player is on during their first evening
/// (D334).
const BotConfig hazel = BotConfig(
  id: 'hazel',
  tier: BotTier.novice,
  rating: 850,
  rules: {StrategicRule.winNow, StrategicRule.blockNow},
  blunderRate: 0.30,
);

/// Wins and blocks, and slips about a quarter of the time.
///
/// Lost its corner preference in D343: a preference for the sixteen seven-line
/// cells is worth 162 rating points and this rung is fifty, so it arrived as a
/// cliff. Board sense now starts at Juniper and arrives gradually.
const BotConfig clover = BotConfig(
  id: 'clover',
  tier: BotTier.novice,
  rating: 900,
  rules: {StrategicRule.winNow, StrategicRule.blockNow},
  blunderRate: 0.23,
);

/// The first opponent that sets a trap — occasionally.
///
/// It knows `makeDoubleThreat` and plays it one time in twenty. Knowing the
/// rule outright is worth about a hundred points against a forty-point rung,
/// so what this rung introduces is not the rule but the first glimpse of it
/// (D343).
const BotConfig sorrel = BotConfig(
  id: 'sorrel',
  tier: BotTier.novice,
  rating: 940,
  rules: {
    StrategicRule.winNow,
    StrategicRule.blockNow,
    StrategicRule.makeDoubleThreat,
  },
  blunderRate: 0.21,
  ruleChance: {
    StrategicRule.makeDoubleThreat: 0.05,
  },
);

/// All four rules, and almost never the two that matter.
///
/// Builds a fork one time in ten and denies one three times in a hundred. It is
/// the last rung with no feel for the board at all.
const BotConfig bramble = BotConfig(
  id: 'bramble',
  tier: BotTier.casual,
  rating: 980,
  rules: _allRules,
  blunderRate: 0.19,
  ruleChance: {
    StrategicRule.makeDoubleThreat: 0.1,
    StrategicRule.blockDoubleThreat: 0.03,
  },
);

// **This stretch is a ramp, not a set of steps** (D343).
//
// Measured in isolation, the levers here are enormous against the rungs they
// have to fill: `makeDoubleThreat` is worth about 100 rating points,
// `blockDoubleThreat` about 128, and a preference for the sixteen seven-line
// cells about 162 — against rungs forty to fifty points apart. Introducing any
// of them outright overshoots by three or four rungs, which is why Hazel to
// Juniper once asked for 170 points and delivered 618.
//
// So none of them is introduced outright. `ruleChance` and `positionChance`
// bring each in as a probability that rises rung by rung, and the blunder rate
// falls underneath. What a player meets is an opponent that has heard of forks
// before it reliably spots them, and notices the middle of the cube before it
// always plays there — which is how people learn this game anyway.
//
// **No opponent in this stretch sets `aggression`** (D314), and **none ranks
// the corners above the centre** (D336). Both were tried as spacing levers and
// both produced cycles rather than orders.

/// Where board sense begins: a pull to the middle, felt one move in eleven.
///
/// `positionChance` is what makes this a rung rather than a cliff (D343). The
/// preference itself is unchanged from the one Willow used to hold; what is new
/// is that it only sometimes gets consulted.
const BotConfig juniper = BotConfig(
  id: 'juniper',
  tier: BotTier.casual,
  rating: 1020,
  rules: _allRules,
  blunderRate: 0.185,
  centreBias: 0.6,
  positionChance: 0.09,
  ruleChance: {
    StrategicRule.makeDoubleThreat: 0.16,
    StrategicRule.blockDoubleThreat: 0.06,
  },
);

/// The same middle, twice as often, and a little sharper on forks.
const BotConfig bracken = BotConfig(
  id: 'bracken',
  tier: BotTier.casual,
  rating: 1060,
  rules: _allRules,
  blunderRate: 0.18,
  centreBias: 0.6,
  positionChance: 0.16,
  ruleChance: {
    StrategicRule.makeDoubleThreat: 0.24,
    StrategicRule.blockDoubleThreat: 0.11,
  },
);

/// A quarter of its moves are chosen for position now, and it denies a fork
/// one time in six.
const BotConfig willow = BotConfig(
  id: 'willow',
  tier: BotTier.casual,
  rating: 1100,
  rules: _allRules,
  blunderRate: 0.175,
  centreBias: 0.6,
  positionChance: 0.26,
  ruleChance: {
    StrategicRule.makeDoubleThreat: 0.33,
    StrategicRule.blockDoubleThreat: 0.17,
  },
);

/// The first to want all sixteen good squares rather than the middle eight.
///
/// The wider preference is worth about 190 points on its own, so `positionChance`
/// steps *back* here to pay for it — the rung gains reach and loses a little
/// consistency, which nets the forty points the roster asks for (D343).
const BotConfig rowan = BotConfig(
  id: 'rowan',
  tier: BotTier.casual,
  rating: 1140,
  rules: _allRules,
  blunderRate: 0.17,
  centreBias: 0.7,
  cornerBias: 0.5,
  positionChance: 0.29,
  ruleChance: {
    StrategicRule.makeDoubleThreat: 0.43,
    StrategicRule.blockDoubleThreat: 0.24,
  },
);

/// The same sixteen, consulted a third of the time, and forks about half seen.
const BotConfig aspen = BotConfig(
  id: 'aspen',
  tier: BotTier.casual,
  rating: 1180,
  rules: _allRules,
  blunderRate: 0.165,
  centreBias: 0.7,
  cornerBias: 0.5,
  positionChance: 0.36,
  ruleChance: {
    StrategicRule.makeDoubleThreat: 0.52,
    StrategicRule.blockDoubleThreat: 0.31,
  },
);

// The Club tier. Sixteen good squares throughout, a tightening blunder rate,
// and at its top the building term — the cell lying on the most lines this
// opponent is already working — which is the lever that separates it from
// Casual rather than another point of accuracy.

/// The tier's first rung: position on four moves in nine, and most forks built.
const BotConfig vireo = BotConfig(
  id: 'vireo',
  tier: BotTier.club,
  rating: 1220,
  rules: _allRules,
  blunderRate: 0.16,
  centreBias: 0.7,
  cornerBias: 0.5,
  positionChance: 0.44,
  ruleChance: {
    StrategicRule.makeDoubleThreat: 0.6,
    StrategicRule.blockDoubleThreat: 0.38,
  },
);

/// Half its moves positional, and the first with a sense of what it is
/// already building — `lineBias` arrives here, small.
const BotConfig finch = BotConfig(
  id: 'finch',
  tier: BotTier.club,
  rating: 1260,
  rules: _allRules,
  blunderRate: 0.15,
  centreBias: 0.7,
  cornerBias: 0.5,
  lineBias: 0.05,
  positionChance: 0.48,
  ruleChance: {
    StrategicRule.makeDoubleThreat: 0.64,
    StrategicRule.blockDoubleThreat: 0.44,
  },
);

/// Solid on the fundamentals, and it rarely gives anything away.
const BotConfig kestrel = BotConfig(
  id: 'kestrel',
  tier: BotTier.club,
  rating: 1300,
  rules: _allRules,
  blunderRate: 0.13,
  centreBias: 0.8,
  cornerBias: 0.6,
  lineBias: 0.1,
  positionChance: 0.62,
  ruleChance: {
    StrategicRule.makeDoubleThreat: 0.74,
    StrategicRule.blockDoubleThreat: 0.58,
  },
);

/// Plays on the lines it is already building, not merely on good squares.
const BotConfig osprey = BotConfig(
  id: 'osprey',
  tier: BotTier.club,
  rating: 1340,
  rules: _allRules,
  blunderRate: 0.11,
  centreBias: 0.9,
  cornerBias: 0.6,
  lineBias: 0.17,
  positionChance: 0.8,
  ruleChance: {
    StrategicRule.makeDoubleThreat: 0.86,
    StrategicRule.blockDoubleThreat: 0.78,
  },
);

/// Builds patiently, denies nearly everything, and waits for a line to open.
const BotConfig heron = BotConfig(
  id: 'heron',
  tier: BotTier.club,
  rating: 1380,
  rules: _allRules,
  blunderRate: 0.082,
  centreBias: 1,
  cornerBias: 0.5,
  lineBias: 0.22,
  positionChance: 0.93,
  ruleChance: {
    StrategicRule.makeDoubleThreat: 0.96,
    StrategicRule.blockDoubleThreat: 0.94,
  },
);

/// The tier's ceiling: the full positional game, every rule at full strength,
/// and hardly a wasted move. The first real test.
const BotConfig marlin = BotConfig(
  id: 'marlin',
  tier: BotTier.club,
  rating: 1420,
  rules: _allRules,
  blunderRate: 0.07,
  centreBias: 1,
  cornerBias: 0.5,
  lineBias: 0.25,
  positionChance: 0.97,
);

// The Expert tier's searching opponents. All six are Marlin's rules and
// positional ladder plus a look ahead; what separates them is how far they
// look, at what, and with which temperament.

/// The first opponent that looks ahead at all, and it looks only for its own
/// forced wins.
///
/// Two forcing moves is not far. It is still the first rung where a threat you
/// leave open is punished on purpose rather than by luck, which is a different
/// experience from anything below it and costs almost nothing to compute.
const BotConfig lynx = BotConfig(
  id: 'lynx',
  tier: BotTier.expert,
  rating: 1460,
  threatSearchDepth: 2,
  rules: _allRules,
  blunderRate: 0.055,
  centreBias: 1,
  cornerBias: 0.5,
  lineBias: 0.25,
);

/// Two plies, weighted towards its own structure, and a short look for its own
/// forced wins.
///
/// **The forcing search is here so that Sable can be measured at all** (D337).
/// `calibrate.dart` discards any pair whose two sides spend different budgets,
/// because the reduced budget a calibration run uses would then hit one side
/// and not the other. Sable took this configuration from Ember in the recut
/// (D333), and Ember had spent neither the node budget nor the forcing one — so
/// every one of Sable's five pairs was discarded and it was the only opponent
/// on the roster with no measured rating whatsoever. Two moves of threat-space
/// search is the smallest thing that puts it back on the same footing as Lynx
/// below it and Ember above it; it is also, on its own terms, the right rung
/// for it.
const BotConfig sable = BotConfig(
  id: 'sable',
  tier: BotTier.expert,
  rating: 1500,
  searchDepth: 2,
  threatSearchDepth: 2,
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
/// Deeper than Sable, and looking three forcing moves ahead, because
/// temperament alone does not separate them: measured over 400 games at equal
/// depth two such opponents are level, and defensive weighting turns out to be
/// worth nothing at all in a game of 76 competing lines (D154).
const BotConfig ember = BotConfig(
  id: 'ember',
  tier: BotTier.expert,
  rating: 1540,
  searchDepth: 3,
  threatSearchDepth: 3,
  rules: _allRules,
  blunderRate: 0.04,
  centreBias: 1,
  cornerBias: 0.5,
  lineBias: 0.25,
  aggression: 0.4,
);

/// The same three plies, even-handed, and a forcing search a move longer.
const BotConfig lyra = BotConfig(
  id: 'lyra',
  tier: BotTier.expert,
  rating: 1580,
  searchDepth: 3,
  threatSearchDepth: 4,
  rules: _allRules,
  blunderRate: 0.035,
  centreBias: 1,
  cornerBias: 0.5,
  lineBias: 0.25,
);

/// Three plies and a six-move forcing search. The first opponent that will
/// beat a competent human more often than not.
///
/// Its edge over Lyra is entirely the forcing search. Depth is the weakest of
/// the three levers this engine has, and past three plies it does not separate
/// opponents at all (D154, D156).
const BotConfig onyx = BotConfig(
  id: 'onyx',
  tier: BotTier.expert,
  rating: 1640,
  searchDepth: 3,
  threatSearchDepth: 6,
  rules: _allRules,
  blunderRate: 0.03,
  centreBias: 1,
  cornerBias: 0.5,
  lineBias: 0.25,
);

/// Four plies plus threat-space search, so it also sees forced wins far beyond
/// that horizon.
const BotConfig corvus = BotConfig(
  id: 'corvus',
  tier: BotTier.expert,
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
// The Master tier. The first opponents whose budget is expressed in nodes
// rather than plies, because how deep a budget reaches depends on the position
// and iterative deepening takes whatever it can finish — and, at its top, the
// two that stop estimating and start knowing.
// ---------------------------------------------------------------------------

/// Iterative deepening under a transposition table.
const BotConfig basalt = BotConfig(
  id: 'basalt',
  tier: BotTier.master,
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

/// Basalt with a longer look, and the first opponent that checks what its own
/// move hands over (D169).
const BotConfig cairn = BotConfig(
  id: 'cairn',
  tier: BotTier.master,
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
/// two more moves of defence than Cairn.
const BotConfig flint = BotConfig(
  id: 'flint',
  tier: BotTier.master,
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

/// Flint plus exact endgame solving, defence as deep as it repays, and no
/// deliberate blunders at all.
///
/// Once ten cells remain it stops estimating: the result it returns is proved,
/// not judged, and no heuristic overrides it. The forcing budget is five times
/// the default because it is shared out among the candidates being checked,
/// and an unstarved defence measured 36-24 against a starved one (D170).
const BotConfig quartz = BotConfig(
  id: 'quartz',
  tier: BotTier.master,
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

/// The strongest opponent that plays no book at all.
///
/// Everything Quartz has and more of it: a bigger budget, two more moves of
/// forcing search, one more empty cell of exact solve. It is the last rung a
/// player reaches by out-searching rather than by out-lasting a proof, which is
/// what makes it the right place for the roster's new top-of-search rung
/// (D333).
///
/// **"More of everything" was not enough, and that is the point** (D338). On
/// those terms Titan already beat Quartz on every lever except one, and lost to
/// it 10-17 — and to Flint, two rungs below, 11-19. The levers it led on are the
/// saturated ones: depth stops separating opponents past three plies (D154,
/// D156) and a forcing search past eleven moves finds the same wins as one past
/// twenty (D176), so a bigger budget spent on either buys nothing measurable.
/// The one lever it did *not* lead on is the one D169 measured at ~300 Elo, and
/// Quartz matched it there at 9. Two more moves of defence is what actually puts
/// this rung above the one below it.
const BotConfig titan = BotConfig(
  id: 'titan',
  tier: BotTier.master,
  rating: 2200,
  nodeBudget: 3000000,
  maxSearchDepth: 11,
  threatSearchDepth: 17,
  defenceSearchDepth: 11,
  forcingBudget: 1500000,
  exactEmpties: 11,
  rules: _allRules,
  centreBias: 1,
  cornerBias: 0.5,
  lineBias: 0.25,
);

// The two that play Patashnik's proof from the opening and search only once it
// runs out. Unbeatable when they open, merely very strong when they do not
// (D172).

/// Unbeatable when it opens; ordinary-strong when it does not.
///
/// Oracle and Quadrim Prime play the identical book, so in the games they open
/// they are the same opponent and neither can be beaten. Everything that
/// separates them lives in the **second seat**, where there is no proof to play
/// and both fall back on searching (D173) — Oracle with the searching machinery
/// of the rungs below, Prime with the largest configuration in the catalogue.
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
  hazel,
  clover,
  sorrel,
  bramble,
  juniper,
  bracken,
  willow,
  rowan,
  aspen,
  vireo,
  finch,
  kestrel,
  osprey,
  heron,
  marlin,
  lynx,
  sable,
  ember,
  lyra,
  onyx,
  corvus,
  basalt,
  cairn,
  flint,
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

  /// Whether [rule] fires this move: it must be enabled, and it must survive
  /// its [BotConfig.ruleChance] if it has one (D343).
  ///
  /// The `>= 1` short-circuit is load-bearing rather than an optimisation. A
  /// rule at full chance draws nothing, so the random stream of every opponent
  /// that predates this field is untouched and their play is identical to the
  /// move — which is what let this ship without re-measuring the roster.
  bool applies(StrategicRule rule) {
    if (!config.rules.contains(rule)) return false;
    final chance = config.ruleChance[rule] ?? 1;
    return chance >= 1 || random.nextDouble() < chance;
  }

  // Rules 1 and 2 are never reordered: taking an offered win is never wrong,
  // and missing an offered loss is what blunderRate is for.
  if (applies(StrategicRule.winNow)) {
    final wins = _immediateWins(state, me);
    if (wins.isNotEmpty) return wins;
  }
  if (applies(StrategicRule.blockNow)) {
    final losses = _immediateWins(state, opponent);
    if (losses.isNotEmpty) return losses;
  }

  // Rules 3 and 4 are where temperament shows.
  final buildFirst = config.aggression >= 0.5;
  final skipDenial = random.nextDouble() < config._denialSkipChance;

  List<Cell>? build() => applies(StrategicRule.makeDoubleThreat)
      ? _doubleThreatCells(state, me)
      : null;
  List<Cell>? deny() =>
      applies(StrategicRule.blockDoubleThreat) && !skipDenial
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

  // The preference does not always get consulted (D343). Short-circuited at 1
  // so that an opponent without the dial draws nothing here and plays exactly
  // as it did before the field existed.
  if (config.positionChance < 1 &&
      random.nextDouble() >= config.positionChance) {
    return candidates[random.nextInt(candidates.length)];
  }

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
