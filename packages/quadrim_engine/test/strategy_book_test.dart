import 'dart:math';

import 'package:quadrim_engine/quadrim_engine.dart';
// The raw table, reached directly rather than widened into the package's API:
// one test checks it against the constant the lookup trusts, and nothing else
// outside the book has business reading it.
import 'package:quadrim_engine/src/strategy_book.g.dart';
import 'package:test/test.dart';

void main() {
  group('the strategy book', () {
    test('holds every one of Patashnik\'s 2929 strategic moves', () {
      // The dictionary's own header states the count. One entry per symmetry
      // class: the generator refuses to build if two lines that are the same
      // position up to symmetry disagree about the move.
      expect(bookSize, 2929);
    });

    test('knows how deep it goes', () {
      // `bookMove` skips the whole 192-automorphism walk past this ply. If a
      // refreshed dictionary went deeper and the constant did not, the book
      // would quietly stop answering for its deepest entries.
      var deepest = 0;
      for (var i = 0; i < bookSize; i++) {
        final board =
            bookBoards.substring(i * bookBoardLength, (i + 1) * bookBoardLength);
        final pieces = bookBoardLength - '0'.allMatches(board).length;
        if (pieces > deepest) deepest = pieces;
      }
      expect(deepestBookPly, deepest);
    });

    test('opens on a corner', () {
      // The first line of the dictionary is the first move of the game. Every
      // automorphism sends a corner to a corner, so whichever image the
      // canonical form picked, the move must come back as one.
      final move = bookMove(GameState.initial(), Player.first);
      expect(move, isNotNull);
      expect(isCornerCell(move!), isTrue,
          reason: 'cell ${move.index} is not a corner');
    });

    test('answers the same position however it is turned', () {
      // The whole point of storing canonical forms: a position and its 192
      // images are one entry, and the move must come back turned to match the
      // board it was asked about.
      //
      // "The same move" here means the same *resulting position*, not the
      // literally corresponding cell. When a position has a non-trivial
      // stabiliser — an automorphism that fixes it — the canonical form is
      // reached by more than one route, and the routes can disagree about
      // which of several interchangeable empty cells the stored move names.
      // They are the same move in every way the game can tell.
      final random = Random(808);
      var checked = 0;
      for (var trial = 0; trial < 300 && checked < 40; trial++) {
        final state = _reachable(random, plies: 2 * (1 + random.nextInt(4)));
        final direct = bookMove(state, Player.first);
        if (direct == null) continue;
        checked++;

        final permutation =
            boardAutomorphisms[random.nextInt(boardAutomorphisms.length)];
        final turned = GameState.fromMoves(
            [for (final m in state.moves) permutation[m]]);
        final fromTurned = bookMove(turned, Player.first);
        expect(fromTurned, isNotNull,
            reason: 'the turned position fell out of the book');
        expect(canonicalKey(applyMove(turned, fromTurned!)),
            canonicalKey(applyMove(state, direct)),
            reason: 'the two answers reached different positions');
      }
      expect(checked, greaterThan(20), reason: 'too few book positions sampled');
    });

    test('declines to answer for the second player', () {
      // There is no perfect second-player play in Qubic, and a book move read
      // for the wrong side would be worse than no move at all.
      final afterOne = GameState.fromMoves([0]);
      expect(afterOne.sideToMove, Player.second);
      expect(bookMove(afterOne, Player.second), isNull);
    });

    test('declines to answer once the game is over', () {
      final won = GameState.fromMoves([0, 16, 1, 17, 2, 18, 3]);
      expect(outcome(won), isA<Win>());
      expect(bookMove(won, Player.first), isNull);
    });
  });

  group('Quadrim Prime', () {
    test('never loses a game it opens, against random play', () {
      // The claim the whole tier rests on. Random replies wander far more
      // widely than a strong opponent does, which is what makes them the
      // harder test of a book that must cover every reply.
      final random = Random(4);
      for (var game = 0; game < 40; game++) {
        final result = _play(quadrimPrime, null, random);
        expect(result, isNot(Player.second),
            reason: 'Prime lost a game it opened');
      }
    });

    test('never loses a game it opens, against the strongest search', () {
      // Fewer games, because Titan costs seconds a move. Different failure
      // mode from random play: a strong opponent steers into the sharp lines.
      final random = Random(5);
      for (var game = 0; game < 4; game++) {
        final result = _play(quadrimPrime, titan, random);
        expect(result, isNot(Player.second),
            reason: 'Prime lost a game it opened, to Titan');
      }
    }, timeout: const Timeout(Duration(minutes: 20)));

    test('is in the catalogue above Oracle, and both play the book', () {
      expect(oracle.usesBook, isTrue);
      expect(quadrimPrime.usesBook, isTrue);
      expect(quadrimPrime.rating, greaterThan(oracle.rating));
      expect(opponentCatalogue.last.id, quadrimPrime.id);
      // Neither blunders — a blunder rate above Titan's zero would break the
      // catalogue's rule that it never rises with rating, which is how the
      // first attempt at separating these two was caught (D176). What
      // separates them is the second seat, the one place the book does not
      // reach, and there Prime searches harder.
      expect(oracle.blunderRate, 0);
      expect(quadrimPrime.blunderRate, 0);
      expect(quadrimPrime.defenceSearchDepth,
          greaterThan(oracle.defenceSearchDepth));
      expect(quadrimPrime.nodeBudget, greaterThan(oracle.nodeBudget));
    });
  });
}

/// Plays a full game with [opener] moving first. A null opponent plays at
/// random. Returns the winner, or null for a draw.
Player? _play(BotConfig opener, BotConfig? second, Random random) {
  var state = GameState.initial();
  while (outcome(state) is Ongoing) {
    final moves = legalMoves(state);
    final Cell move;
    if (state.sideToMove == Player.first) {
      move = chooseMove(state, opener, random);
    } else if (second == null) {
      move = moves[random.nextInt(moves.length)];
    } else {
      move = chooseMove(state, second, random);
    }
    state = applyMove(state, move);
  }
  final result = outcome(state);
  return result is Win ? result.winner : null;
}

/// A position [plies] deep where the first player followed the book and the
/// second replied at random, so it is a position the book is meant to cover.
GameState _reachable(Random random, {required int plies}) {
  var state = GameState.initial();
  for (var i = 0; i < plies && outcome(state) is Ongoing; i++) {
    if (state.sideToMove == Player.first) {
      final move = bookMove(state, Player.first);
      if (move == null) break;
      state = applyMove(state, move);
    } else {
      final moves = legalMoves(state);
      state = applyMove(state, moves[random.nextInt(moves.length)]);
    }
  }
  return state;
}
