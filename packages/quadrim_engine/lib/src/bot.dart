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

/// The four rules that make an opponent look like it is paying attention.
/// Declared in full here because [BotConfig] is the shape every later tier
/// configures; the rules themselves arrive with tickets 008 and 009.
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

/// Which cells an opponent gravitates towards when nothing else decides.
/// The central 2x2x2 and the corners are the eight-and-eight cells that lie
/// on seven lines each (Idea-final §2.2).
enum PositionalBias { none, centre, corners }

/// One opponent. Everything that distinguishes the twenty is in here.
final class BotConfig {
  const BotConfig({
    required this.id,
    required this.rating,
    this.searchDepth = 0,
    this.rules = const <StrategicRule>{},
    this.blunderRate = 0,
    this.positionalBias = PositionalBias.none,
    this.aggression = 0.5,
    this.tieBreakRandomness = 1,
  })  : assert(blunderRate >= 0 && blunderRate <= 1),
        assert(aggression >= 0 && aggression <= 1),
        assert(tieBreakRandomness >= 0 && tieBreakRandomness <= 1),
        assert(searchDepth >= 0);

  /// Stable identifier, stored in a game document as `bot:<id>`. Never
  /// translated, and never renamed once a game has referenced it.
  final String id;

  /// The anchor rating this opponent is calibrated to. Provisional until
  /// ticket 014's harness runs (OI-03).
  final int rating;

  /// Plies of adversarial search. 0 means the rules and bias decide alone.
  final int searchDepth;

  final Set<StrategicRule> rules;

  /// Probability of deliberately discarding the chosen move for a random
  /// legal one. This is what separates opponents that share a rule set.
  final double blunderRate;

  final PositionalBias positionalBias;

  /// 0 is fully defensive (block before building), 1 fully aggressive
  /// (build before blocking). 0.5 weighs them equally.
  final double aggression;

  /// How much to randomise among moves the configuration rates equally. At 0
  /// the first equal-best move in cell order is taken, which is
  /// deterministic but makes an opponent feel mechanical.
  final double tieBreakRandomness;
}

/// The opponent catalogue. Pebble is the whole of it until ticket 008.
const BotConfig pebble = BotConfig(id: 'pebble', rating: 600);

/// Every shipped opponent, weakest first.
const List<BotConfig> opponentCatalogue = [pebble];

BotConfig? botById(String id) {
  for (final bot in opponentCatalogue) {
    if (bot.id == id) return bot;
  }
  return null;
}

/// Chooses [config]'s move in [state], drawing any randomness from [random].
///
/// Throws [StateError] if the game is already over — a caller asking a bot to
/// move in a finished game has a bug, and returning a sentinel would hide it.
Cell chooseMove(GameState state, BotConfig config, Random random) {
  final moves = legalMoves(state);
  if (moves.isEmpty) throw StateError('no legal move: the game is over');

  // Deliberation — the strategic rules (ticket 008), the positional rules
  // (009) and the search (010) — is not written yet. Throwing rather than
  // quietly falling through to random means a catalogue entry added ahead of
  // its behaviour fails loudly instead of shipping as a second Pebble.
  if (config.rules.isNotEmpty ||
      config.searchDepth > 0 ||
      config.positionalBias != PositionalBias.none) {
    throw UnimplementedError(
      'bot ${config.id} asks for rules, search or positional bias, '
      'which arrive with tickets 008-010',
    );
  }

  // Pebble: a uniformly random legal move. That is the whole of its
  // behaviour, not a placeholder for it.
  return moves[random.nextInt(moves.length)];
}
