import 'dart:math';

import 'package:quadrim_engine/quadrim_engine.dart';
import 'package:test/test.dart';

/// A configuration with no strategic rules at all, so the positional ladder
/// alone decides. This is how the ladder is tested in isolation: with rules
/// enabled, any of the four could fire first and hide it.
const BotConfig _positionalOnly = BotConfig(
  id: 'test-positional',
  rating: 1,
  centreBias: 1,
  cornerBias: 0.5,
  lineBias: 0.25,
);

void main() {
  group('the positional ladder', () {
    test('rule 1 — a free cell in the central cube comes first', () {
      final empty = GameState.initial();
      for (var s = 0; s < 40; s++) {
        expect(isCentreCell(chooseMove(empty, _positionalOnly, Random(s))),
            isTrue);
      }
    });

    test('rule 2 — a corner, once the central cube is full', () {
      final centre = [
        for (var i = 0; i < 64; i++)
          if (isCentreCell(Cell(i))) i,
      ];
      expect(centre.length, 8);
      // No winning line fits inside the central cube, so filling it cannot
      // end the game.
      final state = GameState.fromMoves(centre);
      expect(outcome(state), isA<Ongoing>());
      for (var s = 0; s < 40; s++) {
        expect(isCornerCell(chooseMove(state, _positionalOnly, Random(s))),
            isTrue);
      }
    });

    test('rule 3 — the cell on the most lines it is already building', () {
      // Light holds 0 and 1. The only line with two of its pieces and none of
      // the opponent's is {0,1,2,3}, so 2 and 3 are the only building cells.
      final state = GameState.fromMoves([0, 16, 1, 17]);
      expect(state.sideToMove, Player.first);
      const builder = BotConfig(id: 'test-builder', rating: 1, lineBias: 1);
      for (var s = 0; s < 40; s++) {
        expect(chooseMove(state, builder, Random(s)).index, anyOf(2, 3));
      }
    });

    test('rule 4 — random, when nothing distinguishes the cells', () {
      const flat = BotConfig(id: 'test-flat', rating: 1);
      final empty = GameState.initial();
      final chosen = {
        for (var s = 0; s < 50; s++) chooseMove(empty, flat, Random(s)).index,
      };
      expect(chosen.length, greaterThan(10));
    });

    test('the classes are ordered, not accumulated', () {
      // The same position as rule 3: cells 2 and 3 build a line, but the
      // ladder still prefers an empty centre cell that builds nothing.
      final state = GameState.fromMoves([0, 16, 1, 17]);
      for (var s = 0; s < 40; s++) {
        final cell = chooseMove(state, _positionalOnly, Random(s));
        expect(isCentreCell(cell), isTrue,
            reason: 'building must not outrank the centre for these weights');
      }
    });

    test('centre, corner and edge are weightable independently', () {
      // A configuration that prefers the forty-eight cells that are neither
      // centre nor corner is expressible — which is the point of the third
      // knob, even though no shipped opponent uses it.
      const edgeLover = BotConfig(id: 'test-edge', rating: 1, edgeBias: 1);
      final empty = GameState.initial();
      for (var s = 0; s < 40; s++) {
        final cell = chooseMove(empty, edgeLover, Random(s));
        expect(isCentreCell(cell) || isCornerCell(cell), isFalse);
      }
    });
  });

  group('Marlin', () {
    test('has the configuration given in idea-v3 6.4', () {
      expect(marlin.id, 'marlin');
      expect(marlin.rating, 1400);
      expect(marlin.rules.length, 4);
      expect(marlin.blunderRate, 0.06);
      expect(marlin.searchDepth, 0, reason: 'search is ticket 010');
      expect(marlin.lineBias, greaterThan(0), reason: 'the third rule');
      expect(opponentCatalogue, contains(marlin));
      expect(botById('marlin'), same(marlin));
    });

    test('the ladder is an order for every opponent that uses it', () {
      // The order is a property of the weights, not of the code (D149), so a
      // later opponent copying Marlin and raising lineBias would silently
      // invert it. The building term tops out at lineBias, so each class gap
      // must exceed it.
      for (final bot in opponentCatalogue.where((b) => b.lineBias > 0)) {
        expect(bot.centreBias - bot.cornerBias, greaterThan(bot.lineBias),
            reason: '${bot.id}: building outranks the centre');
        expect(bot.cornerBias - bot.edgeBias, greaterThan(bot.lineBias),
            reason: '${bot.id}: building outranks a corner');
      }
    });

    test('opens in the central cube', () {
      final empty = GameState.initial();
      final centre = [
        for (var s = 0; s < 200; s++)
          if (isCentreCell(chooseMove(empty, marlin, Random(s)))) s,
      ].length;
      // It blunders 6% of the time, and a blundered move only lands in the
      // centre by chance, so the bar is the rate rather than every seed.
      expect(centre, greaterThan(170), reason: 'opened centrally $centre/200');
    });

    test('breaks a strategic tie positionally rather than at random', () {
      // Light can win at 21 (a centre cell) or at 3 (a corner). Rule 1 offers
      // both; only the positional tie-break separates them.
      final state = GameState.fromMoves(
          [5, 16, 37, 22, 53, 41, 0, 58, 1, 12, 2, 27]);
      expect(outcome(state), isA<Ongoing>());
      expect(state.sideToMove, Player.first);
      expect(
        {for (final t in threats(state, Player.first)) t.emptyCell.index},
        {3, 21},
      );
      expect(threats(state, Player.second), isEmpty);
      expect(isCentreCell(const Cell(21)), isTrue);
      expect(isCornerCell(const Cell(3)), isTrue);

      final marlinCentre = [
        for (var s = 0; s < 100; s++) chooseMove(state, marlin, Random(s)).index,
      ].where((c) => c == 21).length;
      expect(marlinCentre, greaterThan(85),
          reason: 'Marlin took the centre win $marlinCentre/100');

      // Bramble has the same rule and no positional sense at all, so it
      // splits. It is the control rather than Kestrel because the roster test
      // pins its two biases at zero, where Kestrel only had them at zero by
      // accident — and D210 gave Kestrel the centre preference spec 8.4 gives
      // the whole Casual tier, which silently turned this control into a
      // second copy of the assertion above it.
      final brambleCentre = [
        for (var s = 0; s < 100; s++)
          chooseMove(state, bramble, Random(s)).index,
      ].where((c) => c == 21).length;
      expect(brambleCentre, lessThan(70),
          reason: 'Bramble should be choosing at random, '
              'got $brambleCentre/100');
    });

    test('beats Kestrel over a significant number of self-play games', () {
      final result = _match(marlin, kestrel, 120, Random(20260812));
      expect(result.wins, greaterThan(result.losses),
          reason: 'Marlin $result against Kestrel');
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('returns only legal moves across thousands of positions', () {
      final random = Random(909);
      for (var i = 0; i < 3000; i++) {
        final state = _randomPosition(random);
        final move = chooseMove(state, marlin, random);
        expect(legalMoves(state).map((c) => c.index), contains(move.index));
        applyMove(state, move);
      }
    });
  });
}

/// Plays [a] against [b] for [games] games, alternating who opens. Returns
/// a's score.
({int wins, int losses, int draws}) _match(
  BotConfig a,
  BotConfig b,
  int games,
  Random random,
) {
  var wins = 0, losses = 0, draws = 0;
  for (var g = 0; g < games; g++) {
    final aOpens = g.isEven;
    var state = GameState.initial();
    while (outcome(state) is Ongoing) {
      final aToMove = (state.moves.length.isEven) == aOpens;
      state = applyMove(state, chooseMove(state, aToMove ? a : b, random));
    }
    final result = outcome(state);
    if (result is Draw) {
      draws++;
    } else if (result is Win) {
      if ((result.winner == Player.first) == aOpens) {
        wins++;
      } else {
        losses++;
      }
    }
  }
  return (wins: wins, losses: losses, draws: draws);
}

/// A reachable, still-playable position.
GameState _randomPosition(Random random) {
  var state = GameState.initial();
  final plies = random.nextInt(40);
  for (var i = 0; i < plies; i++) {
    if (outcome(state) is! Ongoing) break;
    final moves = legalMoves(state);
    state = applyMove(state, moves[random.nextInt(moves.length)]);
  }
  if (outcome(state) is! Ongoing) return _randomPosition(random);
  return state;
}
