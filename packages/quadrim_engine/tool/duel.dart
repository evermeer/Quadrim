// Plays two opponent configurations against each other and reports the
// result. The instrument the ladder is tuned with: every claim about one
// opponent being stronger than another should come from a run of this rather
// than from an argument about the code.
//
// Not part of the shipped package — `bin`/`tool` is excluded from the purity
// gate's `lib` scan, and this is the one place the engine is allowed a clock,
// because timing is the whole point of it.
//
//   dart run tool/duel.dart sable sable+d9 120
//
// A name may be a catalogue id, optionally with `+dN` to give it a defensive
// forcing search N moves deep, or `+tN` to change its own forcing depth.
import 'dart:math';

import 'package:quadrim_engine/quadrim_engine.dart';

void main(List<String> args) {
  if (args.length < 2) {
    print('usage: dart run tool/duel.dart <a> <b> [games]');
    print('  name = <catalogue id>[+dN][+tN]');
    return;
  }
  final a = _parse(args[0]);
  final b = _parse(args[1]);
  final games = args.length > 2 ? int.parse(args[2]) : 60;

  var aWins = 0;
  var bWins = 0;
  var draws = 0;
  final times = <String, List<int>>{a.id: [], b.id: []};

  for (var g = 0; g < games; g++) {
    // Each pairing is played from both seats, so an opening advantage counts
    // for neither side.
    final opener = g.isEven ? a : b;
    final second = g.isEven ? b : a;
    final winner = _play(opener, second, Random(g), times);
    if (winner == null) {
      draws++;
    } else if (identical(winner, a)) {
      aWins++;
    } else {
      bWins++;
    }
  }

  print('${a.id} $aWins - $bWins ${b.id}  (draws $draws, games $games)');
  if (a.usesBook || b.usesBook) {
    print('  note: a book player wins every game it opens, so an alternating '
        'pairing of two of them measures the seat, not the strength.');
  }
  for (final entry in times.entries) {
    final ms = entry.value..sort();
    if (ms.isEmpty) continue;
    final mean = ms.reduce((x, y) => x + y) ~/ ms.length;
    print('  ${entry.key}: worst ${ms.last} ms, median ${ms[ms.length ~/ 2]} '
        'ms, mean $mean ms, moves ${ms.length}');
  }
}

/// Returns the winning config, or null for a draw.
BotConfig? _play(
  BotConfig opener,
  BotConfig second,
  Random random,
  Map<String, List<int>> times,
) {
  var state = GameState.initial();
  while (outcome(state) is Ongoing) {
    final config = state.sideToMove == Player.first ? opener : second;
    final started = DateTime.now();
    final move = chooseMove(state, config, random);
    times[config.id]?.add(DateTime.now().difference(started).inMilliseconds);
    state = applyMove(state, move);
  }
  final result = outcome(state);
  if (result is! Win) return null;
  return result.winner == Player.first ? opener : second;
}

/// `sable`, `sable+d9`, `sable+d9+t15`.
BotConfig _parse(String name) {
  final parts = name.split('+');
  final base = botById(parts.first);
  if (base == null) throw ArgumentError('no such opponent: ${parts.first}');
  var defence = base.defenceSearchDepth;
  var threat = base.threatSearchDepth;
  var budget = base.forcingBudget;
  for (final modifier in parts.skip(1)) {
    final n = int.parse(modifier.substring(1));
    switch (modifier[0]) {
      case 'd':
        defence = n;
      case 't':
        threat = n;
      case 'b':
        budget = n * 1000; // thousands of nodes
      default:
        throw ArgumentError('unknown modifier: $modifier');
    }
  }
  return BotConfig(
    id: name,
    rating: base.rating,
    searchDepth: base.searchDepth,
    threatSearchDepth: threat,
    defenceSearchDepth: defence,
    usesBook: base.usesBook,
    nodeBudget: base.nodeBudget,
    maxSearchDepth: base.maxSearchDepth,
    exactEmpties: base.exactEmpties,
    canonicalPlies: base.canonicalPlies,
    forcingBudget: budget,
    rules: base.rules,
    blunderRate: base.blunderRate,
    centreBias: base.centreBias,
    cornerBias: base.cornerBias,
    edgeBias: base.edgeBias,
    lineBias: base.lineBias,
    aggression: base.aggression,
    tieBreakRandomness: base.tieBreakRandomness,
  );
}
