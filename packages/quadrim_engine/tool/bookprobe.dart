// What actually carries a Quadrim Prime game: the book, the forcing search, or
// the ordinary search it falls back to?
//
//   dart run tool/bookprobe.dart [games]
//
// "Never loses" is the claim; this says *why*, which is the difference between
// a proof that holds and forty games that happened to go well.
import 'dart:math';

import 'package:quadrim_engine/quadrim_engine.dart';

void main(List<String> args) {
  final bot = args.isEmpty ? quadrimPrime : botById(args.first)!;
  final games = args.length > 1 ? int.parse(args[1]) : 200;
  final random = Random(20260809);

  var wins = 0, draws = 0, losses = 0;
  var book = 0, forced = 0, immediate = 0, fellThrough = 0;
  var reachedBookPly = 0;
  final fallthroughs = <String>[];

  for (var g = 0; g < games; g++) {
    var state = GameState.initial();
    while (outcome(state) is Ongoing) {
      if (state.sideToMove == Player.first) {
        final ply = state.moves.length;
        // Classify before choosing, in the order chooseMove applies them.
        if (_immediateWin(state, Player.first) != null ||
            _immediateWin(state, Player.second) != null) {
          immediate++;
        } else if (bookMove(state, Player.first) != null) {
          book++;
          if (ply > reachedBookPly) reachedBookPly = ply;
        } else if (threatSpaceWin(state, Player.first,
                bot.threatSearchDepth,
                nodeBudget: bot.forcingBudget) !=
            null) {
          forced++;
        } else {
          fellThrough++;
          if (fallthroughs.length < 5) fallthroughs.add('${state.moves}');
        }
        state = applyMove(state, chooseMove(state, bot, random));
      } else {
        final moves = legalMoves(state);
        state = applyMove(state, moves[random.nextInt(moves.length)]);
      }
    }
    final result = outcome(state);
    if (result is Win) {
      result.winner == Player.first ? wins++ : losses++;
    } else {
      draws++;
    }
  }

  print('$games games, ${bot.id} opening against random replies');
  print('  won $wins, drawn $draws, lost $losses');
  print('  moves decided by: book $book, forcing search $forced, '
      'immediate win/block $immediate');
  print('  fell through to the ordinary search: $fellThrough');
  print('  deepest position still in the book: ply $reachedBookPly');
  if (fallthroughs.isNotEmpty) {
    print('  first few fall-through positions:');
    for (final f in fallthroughs) {
      print('    $f');
    }
  }
}

Cell? _immediateWin(GameState state, Player player) {
  for (final t in threats(state, player)) {
    return t.emptyCell;
  }
  return null;
}
