import 'dart:math';

import 'package:quadrim_engine/quadrim_engine.dart';
import 'package:test/test.dart';

void main() {
  group('catalogue', () {
    test('every entry has a unique id and a rating', () {
      final ids = opponentCatalogue.map((b) => b.id).toSet();
      expect(ids.length, opponentCatalogue.length, reason: 'ids must be unique');
      for (final bot in opponentCatalogue) {
        expect(bot.id, isNotEmpty);
        expect(bot.rating, greaterThan(0));
        expect(botById(bot.id), same(bot));
      }
    });

    test('the catalogue is ordered weakest first', () {
      final ratings = opponentCatalogue.map((b) => b.rating).toList();
      expect(ratings, orderedEquals(ratings.toList()..sort()));
    });

    test('Pebble is the weakest entry and plays no rules', () {
      expect(opponentCatalogue.first.id, 'pebble');
      expect(pebble.rating, 600);
      expect(pebble.rules, isEmpty);
      expect(pebble.searchDepth, 0);
      expect(pebble.centreBias, 0);
      expect(pebble.cornerBias, 0);
      expect(pebble.blunderRate, 0);
    });

    test('botById returns null for an unknown id', () {
      expect(botById('nobody'), isNull);
    });
  });

  group('chooseMove', () {
    test('is deterministic for a given seed and position', () {
      final state = GameState.fromMoves([0, 21, 5, 33]);
      for (var seed = 0; seed < 20; seed++) {
        final a = chooseMove(state, pebble, Random(seed));
        final b = chooseMove(state, pebble, Random(seed));
        expect(a.index, b.index,
            reason: 'same seed and state must give the same move');
      }
    });

    test('different seeds explore different moves', () {
      final state = GameState.initial();
      final chosen = {
        for (var seed = 0; seed < 50; seed++)
          chooseMove(state, pebble, Random(seed)).index,
      };
      expect(chosen.length, greaterThan(1),
          reason: 'a random opponent that always picks one cell is not random');
    });

    test('the chosen move is always legal, over thousands of positions', () {
      // Every catalogue entry that decides in microseconds, over randomly
      // generated reachable positions. The searching opponents cost
      // milliseconds a move and are swept separately, at a sample size that
      // fits the suite's runtime (search_test.dart, deep_search_test.dart).
      //
      // Both budgets, not just `searchDepth`: ticket 025 introduced
      // `nodeBudget` as the *alternative* way to spend a search, so the
      // Expert tier reads as `searchDepth == 0` and this sweep silently
      // started running four iterative-deepening opponents three thousand
      // times each.
      final random = Random(20260811);
      for (final bot in opponentCatalogue
          .where((b) => b.searchDepth == 0 && b.nodeBudget == 0)) {
        for (var i = 0; i < 3000; i++) {
          final state = _randomPosition(random);
          final move = chooseMove(state, bot, random);
          expect(legalMoves(state).map((c) => c.index), contains(move.index),
              reason: '${bot.id} chose an illegal move in position '
                  '${state.moves}');
          // Legality is also what applyMove enforces, so this must not throw.
          applyMove(state, move);
        }
      }
    });

    test('asking a finished game for a move is an error, not a sentinel', () {
      // Cells 0..3 complete an x-axis line for the first player.
      final won = GameState.fromMoves([0, 21, 1, 22, 2, 26, 3]);
      expect(outcome(won), isA<Win>());
      expect(() => chooseMove(won, pebble, Random(1)), throwsStateError);
    });

    test('a configuration asking for search now gets it', () {
      // Ticket 006 made this throw, so a catalogue entry could not quietly
      // ship as a weaker opponent than its rating claimed (D142). Ticket 010
      // implements the search, so the guard has done its job and goes.
      const searcher = BotConfig(id: 'test-searcher', rating: 1, searchDepth: 4);
      final move = chooseMove(GameState.initial(), searcher, Random(1));
      expect(legalMoves(GameState.initial()).map((c) => c.index),
          contains(move.index));
    });
  });
}

/// A reachable, still-playable position: a random number of random legal
/// moves, stopping if the game ends.
GameState _randomPosition(Random random) {
  var state = GameState.initial();
  final plies = random.nextInt(60);
  for (var i = 0; i < plies; i++) {
    if (outcome(state) is! Ongoing) break;
    final moves = legalMoves(state);
    state = applyMove(state, moves[random.nextInt(moves.length)]);
  }
  if (outcome(state) is! Ongoing) return _randomPosition(random);
  return state;
}
