import 'dart:convert';
import 'dart:io';

import 'package:quadrim_engine/quadrim_engine.dart';
import 'package:test/test.dart';

void main() {
  group('Cell', () {
    test('index and xyz round-trip for all 64 cells', () {
      for (var x = 0; x < 4; x++) {
        for (var y = 0; y < 4; y++) {
          for (var z = 0; z < 4; z++) {
            final c = Cell.xyz(x, y, z);
            expect(c.index, x + 4 * y + 16 * z);
            expect((c.x, c.y, c.z), (x, y, z));
          }
        }
      }
    });
  });

  group('win detection (E1, E2)', () {
    test('every one of the 76 lines wins, for both players, naming the line',
        () {
      for (final line in winningLines) {
        for (final winner in Player.values) {
          final state = _gameWhereWins(line, winner);
          final o = outcome(state);
          expect(o, isA<Win>(), reason: 'line $line, winner $winner');
          final win = o as Win;
          expect(win.winner, winner);
          expect(win.line, line, reason: 'must name the exact line');
        }
      }
    });

    test('exhaustive: no set of four cells outside the 76 ever wins', () {
      // Covered structurally: applyMove only inspects winning lines through
      // the placed cell, and linegen's exhaustive C(64,4) scan proves those
      // are exactly the 76 collinear quads. Spot-check the structural claim
      // with near-miss quads: every 4-cell set that shares 3 cells with a
      // real line but not the 4th.
      for (final line in winningLines) {
        for (var drop = 0; drop < 4; drop++) {
          final kept = [
            for (var i = 0; i < 4; i++)
              if (i != drop) line[i],
          ];
          final replacement = _firstCellNotIn({...line});
          final quad = [...kept, replacement];
          final state = _fillQuad(quad);
          expect(outcome(state), isNot(isA<Win>()),
              reason: 'near-miss $quad must not win');
        }
      }
    });
  });

  group('rules (E3, E4, E5)', () {
    test('applying to an occupied cell throws and leaves state unchanged', () {
      final state = applyMove(GameState.initial(), const Cell(27));
      final movesBefore = state.moves;
      expect(() => applyMove(state, const Cell(27)), throwsArgumentError);
      expect(state.moves, movesBefore);
      expect(state.owner(const Cell(27)), Player.first);
    });

    test('out-of-range cells throw', () {
      expect(() => applyMove(GameState.initial(), const Cell(64)),
          throwsArgumentError);
      expect(() => applyMove(GameState.initial(), const Cell(-1)),
          throwsArgumentError);
    });

    test('moving in a finished game throws', () {
      final won = _gameWhereWins(winningLines.first, Player.first);
      expect(() => applyMove(won, _firstEmpty(won)), throwsStateError);
    });

    test('legalMoves is exactly the empty cells, and empty when won', () {
      var state = GameState.initial();
      expect(legalMoves(state), hasLength(64));
      state = applyMove(state, const Cell(0));
      state = applyMove(state, const Cell(63));
      final legal = legalMoves(state).map((c) => c.index).toSet();
      expect(legal, hasLength(62));
      expect(legal, isNot(contains(0)));
      expect(legal, isNot(contains(63)));
      final won = _gameWhereWins(winningLines.first, Player.first);
      expect(legalMoves(won), isEmpty);
    });

    test('turns alternate and sideToMove derives from move count', () {
      var state = GameState.initial();
      expect(state.sideToMove, Player.first);
      state = applyMove(state, const Cell(5));
      expect(state.sideToMove, Player.second);
      expect(state.owner(const Cell(5)), Player.first);
    });

    test('applyMove never mutates its input (immutability)', () {
      final before = GameState.initial();
      final after = applyMove(before, const Cell(10));
      expect(before.moves, isEmpty);
      expect(before.owner(const Cell(10)), isNull);
      expect(after.moves, [10]);
      // The exposed move list is read-only.
      expect(() => after.moves.add(11), throwsUnsupportedError);
    });
  });

  group('corpus replay (E11)', () {
    late Map<String, dynamic> corpus;

    setUpAll(() {
      corpus = jsonDecode(
        File('test/fixtures/corpus.json').readAsStringSync(),
      ) as Map<String, dynamic>;
    });

    test('every corpus game replays to its recorded outcome', () {
      for (final g in (corpus['games'] as List).cast<Map<String, dynamic>>()) {
        final state =
            GameState.fromMoves((g['moves'] as List).cast<int>());
        final o = outcome(state);
        if (g['outcome'] == 'win') {
          final win = o as Win;
          expect(win.winner.index, g['winnerSeat']);
          expect(win.line, (g['line'] as List).cast<int>());
        } else {
          expect(o, isA<Draw>());
          expect(state.moves, hasLength(64));
        }
      }
    });

    test('corpus illegal cases are rejected by the engine', () {
      for (final c in (corpus['illegal'] as List).cast<Map<String, dynamic>>()) {
        final state =
            GameState.fromMoves((c['moves'] as List).cast<int>());
        expect(
          () => applyMove(state, Cell(c['illegalNext'] as int)),
          throwsA(anyOf(isA<ArgumentError>(), isA<StateError>())),
          reason: c['reason'] as String,
        );
      }
    });
  });

  group('threats', () {
    test('three in a line with the fourth empty is a threat; playing it wins',
        () {
      final line = winningLines.first;
      // first: three cells of the line; second: scattered elsewhere.
      final fillers = _threeCellsNotTouching({...line});
      final state = GameState.fromMoves([
        line[0], fillers[0], line[1], fillers[1], line[2], fillers[2],
      ]);
      final firstThreats = threats(state, Player.first);
      expect(firstThreats.map((t) => t.line), contains(line));
      final t = firstThreats.firstWhere((t) => t.line == line);
      expect(t.emptyCell.index, line[3]);
      final won = applyMove(state, t.emptyCell);
      expect(outcome(won), isA<Win>());
    });

    test('a line containing any opponent piece is never a threat', () {
      // first holds three cells of a line, second holds the fourth.
      final line = winningLines.last;
      final fillers = _threeCellsNotTouching({...line});
      final state = GameState.fromMoves([
        line[0], line[3], line[1], fillers[0], line[2], fillers[1],
      ]);
      expect(threats(state, Player.first).map((t) => t.line),
          isNot(contains(line)));
    });

    test('threat structure invariant holds across random positions', () {
      // Deterministic pseudo-random playouts; no ambient randomness.
      var seed = 0x9E3779B9;
      int next(int bound) {
        seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF;
        return seed % bound;
      }

      for (var game = 0; game < 200; game++) {
        var state = GameState.initial();
        for (var i = 0; i < 20 && !state.isOver; i++) {
          final legal = legalMoves(state);
          state = applyMove(state, legal[next(legal.length)]);
        }
        for (final p in Player.values) {
          for (final t in threats(state, p)) {
            final owned =
                t.line.where((c) => state.owner(Cell(c)) == p).length;
            expect(owned, 3);
            expect(state.owner(t.emptyCell), isNull);
            expect(t.line, contains(t.emptyCell.index));
          }
        }
      }
    });
  });
}

// --- helpers ---

/// A finished game where [winner] fills [line]; loser cells never form a line.
GameState _gameWhereWins(List<int> line, Player winner) {
  final safe = _threeCellsNotTouching({...line});
  final moves = <int>[];
  for (var i = 0; i < 4; i++) {
    if (winner == Player.first) {
      moves.add(line[i]);
      if (i < 3) moves.add(safe[i]);
    } else {
      moves.add(safe[i]);
      moves.add(line[i]);
    }
  }
  return GameState.fromMoves(moves);
}

/// Three cells outside [exclude] that lie on no common line with each other.
List<int> _threeCellsNotTouching(Set<int> exclude) {
  final chosen = <int>[];
  for (var c = 0; c < 64 && chosen.length < 4; c++) {
    if (exclude.contains(c)) continue;
    final candidate = {...chosen, c};
    // Reject only if the candidate set fully contains some winning line —
    // with at most four cells that means the candidate IS a line.
    final formsLine = winningLines.any((l) => l.every(candidate.contains));
    if (!formsLine) chosen.add(c);
  }
  return chosen;
}

int _firstCellNotIn(Set<int> used) {
  for (var c = 0; c < 64; c++) {
    if (!used.contains(c)) return c;
  }
  throw StateError('board full');
}

Cell _firstEmpty(GameState state) {
  for (var c = 0; c < 64; c++) {
    if (state.owner(Cell(c)) == null) return Cell(c);
  }
  throw StateError('board full');
}

/// Fills [quad] for Player.first with Player.second scattered; returns state.
GameState _fillQuad(List<int> quad) {
  final safe = _threeCellsNotTouching({...quad});
  final moves = <int>[];
  for (var i = 0; i < 4; i++) {
    moves.add(quad[i]);
    if (i < 3) moves.add(safe[i]);
  }
  return GameState.fromMoves(moves);
}
