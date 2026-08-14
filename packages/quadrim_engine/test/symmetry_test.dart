import 'dart:math';

import 'package:quadrim_engine/quadrim_engine.dart';
import 'package:test/test.dart';

void main() {
  group('the symmetry group', () {
    test('has exactly 192 members, as the literature says', () {
      // Silver (1967). If the construction produced 96 or 576 it would still
      // look plausible in play and quietly halve or wreck the table.
      expect(boardAutomorphisms, hasLength(192));
    });

    test('every member is a permutation of all 64 cells', () {
      for (final permutation in boardAutomorphisms) {
        expect(permutation, hasLength(64));
        expect(permutation.toSet(), hasLength(64),
            reason: 'a repeated image is not a permutation');
        expect(permutation.every((c) => c >= 0 && c < 64), isTrue);
      }
    });

    test('every member maps the 76 lines onto the 76 lines', () {
      // The definition, asserted rather than assumed.
      for (final permutation in boardAutomorphisms) {
        expect(preservesLines(permutation), isTrue);
      }
    });

    test('it is a group: identity, closure and inverses', () {
      final keys = {for (final p in boardAutomorphisms) p.join(',')};
      final identity = [for (var i = 0; i < 64; i++) i];
      expect(keys, contains(identity.join(',')));

      // Closure over all 192 x 192 products.
      for (final a in boardAutomorphisms) {
        for (final b in boardAutomorphisms) {
          expect(keys, contains(composeAutomorphisms(a, b).join(',')),
              reason: 'the group is not closed under composition');
        }
      }

      // Inverses: a finite closed set containing the identity has them, but
      // asserting it directly catches a construction that silently dropped a
      // member and happened to stay closed.
      for (final a in boardAutomorphisms) {
        final inverse = List<int>.filled(64, 0);
        for (var i = 0; i < 64; i++) {
          inverse[a[i]] = i;
        }
        expect(keys, contains(inverse.join(',')));
      }
    });

    test('it preserves how many lines each cell sits on', () {
      // Corners and centre cells lie on 7 lines, the other 48 on 4. A map that
      // sent a corner to an edge cell could not preserve the line set, so this
      // is a cheap independent check on the same claim.
      final degree = List<int>.filled(64, 0);
      for (final line in winningLines) {
        for (final c in line) {
          degree[c]++;
        }
      }
      for (final permutation in boardAutomorphisms) {
        for (var i = 0; i < 64; i++) {
          expect(degree[permutation[i]], degree[i]);
        }
      }
    });

    test('it acts transitively on the two kinds of cell, and no further', () {
      // The 16 seven-line cells form one orbit and the 48 four-line cells the
      // other. This is the fact that makes "an empty board has two distinct
      // opening moves, not 64" true (idea-v1 §2.3).
      final orbits = <Set<int>>[];
      final assigned = <int>{};
      for (var start = 0; start < 64; start++) {
        if (assigned.contains(start)) continue;
        final orbit = {for (final p in boardAutomorphisms) p[start]};
        assigned.addAll(orbit);
        orbits.add(orbit);
      }
      expect(orbits.map((o) => o.length).toList()..sort(), [16, 48]);
    });
  });

  group('canonical form', () {
    test('positions related by a symmetry share it', () {
      final random = Random(1509);
      for (var trial = 0; trial < 200; trial++) {
        final state = _randomPosition(random);
        final permutation =
            boardAutomorphisms[random.nextInt(boardAutomorphisms.length)];
        final image = GameState.fromMoves(
            [for (final m in state.moves) permutation[m]]);
        expect(canonicalKey(image), canonicalKey(state),
            reason: 'position ${state.moves} and its image disagree');
      }
    });

    test('a position and its image evaluate alike', () {
      // Sharing a table entry is only sound if the two really are worth the
      // same. The evaluation is independent of the symmetry group's existence,
      // so this is a genuine cross-check rather than a restatement.
      final random = Random(64);
      for (var trial = 0; trial < 200; trial++) {
        final state = _randomPosition(random);
        final permutation =
            boardAutomorphisms[random.nextInt(boardAutomorphisms.length)];
        final image = GameState.fromMoves(
            [for (final m in state.moves) permutation[m]]);
        expect(evaluatePosition(image, image.sideToMove),
            evaluatePosition(state, state.sideToMove));
        expect(threats(image, image.sideToMove).length,
            threats(state, state.sideToMove).length);
      }
    });

    test('unrelated positions do not share it', () {
      // A canonical form that collapsed everything would also "pass" the test
      // above, and would make the table return nonsense.
      final random = Random(7);
      final keys = <String, List<int>>{};
      var distinct = 0;
      for (var trial = 0; trial < 300; trial++) {
        final state = _randomPosition(random);
        final key = canonicalKey(state);
        final seen = keys[key];
        if (seen == null) {
          keys[key] = state.moves;
          distinct++;
        } else {
          // Same key: the two must genuinely be related by a symmetry.
          expect(_relatedBySymmetry(GameState.fromMoves(seen), state), isTrue,
              reason: 'unrelated positions $seen and ${state.moves} collided');
        }
      }
      expect(distinct, greaterThan(250), reason: 'the form collapses too much');
    });

    test('the empty board has one class, and one piece has two', () {
      expect(canonicalKey(GameState.initial()), isNotEmpty);
      final openings = {
        for (var i = 0; i < 64; i++) canonicalKey(GameState.fromMoves([i])),
      };
      expect(openings, hasLength(2),
          reason: 'an opening move is either a 7-line cell or a 4-line one');
    });

    test('it distinguishes whose turn it is, not which colour is which', () {
      // Encoded from the side to move's point of view: the same shape with the
      // colours swapped and the turn swapped is the same position to a search.
      final a = GameState.fromMoves([0, 21]);
      final b = GameState.fromMoves([21, 0]);
      expect(canonicalKey(a), canonicalKey(b));
    });
  });
}

bool _relatedBySymmetry(GameState a, GameState b) {
  if (a.moves.length != b.moves.length) return false;
  for (final permutation in boardAutomorphisms) {
    var ok = true;
    for (var i = 0; i < 64 && ok; i++) {
      final owner = a.owner(Cell(i));
      final image = b.owner(Cell(permutation[i]));
      // Compared by side-to-move role, which is what the key encodes.
      final left = owner == null ? 0 : (owner == a.sideToMove ? 1 : 2);
      final right = image == null ? 0 : (image == b.sideToMove ? 1 : 2);
      ok = left == right;
    }
    if (ok) return true;
  }
  return false;
}

GameState _randomPosition(Random random) {
  var state = GameState.initial();
  final plies = random.nextInt(20);
  for (var i = 0; i < plies; i++) {
    if (outcome(state) is! Ongoing) break;
    final moves = legalMoves(state);
    state = applyMove(state, moves[random.nextInt(moves.length)]);
  }
  if (outcome(state) is! Ongoing) return _randomPosition(random);
  return state;
}
