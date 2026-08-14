// How long one exact endgame solve actually costs, and how that scales with
// the number of empty cells. Used to find out why the endgame tests dominate
// the suite's runtime.
import 'dart:math';

import 'package:quadrim_engine/quadrim_engine.dart';

void main() {
  final random = Random(808);
  for (final empties in [6, 8, 9, 10, 11, 12]) {
    final states = _endgames(empties, 3, random);
    if (states.isEmpty) {
      print('$empties empties: no positions found');
      continue;
    }
    final started = DateTime.now();
    var nodes = 0;
    for (final state in states) {
      final out = deepSearch(
        state,
        state.sideToMove,
        legalMoves(state),
        SearchLimits(
            nodeBudget: 1000000000, maxDepth: 4, exactEmpties: empties + 2),
      );
      nodes += out.nodes;
    }
    final ms = DateTime.now().difference(started).inMilliseconds;
    print('$empties empties: ${states.length} positions, '
        '${ms}ms total, ${(ms / states.length).round()}ms each, '
        '${(nodes / states.length).round()} nodes each');
  }
}

List<GameState> _endgames(int empties, int want, Random random) {
  final found = <GameState>[];
  var attempts = 0;
  while (found.length < want && attempts++ < 60) {
    var state = GameState.initial();
    while (outcome(state) is Ongoing) {
      if (64 - state.moves.length == empties) {
        found.add(state);
        break;
      }
      state = applyMove(state, chooseMove(state, kestrel, random));
    }
  }
  return found;
}
