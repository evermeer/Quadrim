/// The board's symmetry group, and canonical forms built from it.
///
/// Quadrim's 4x4x4 board has **192 automorphisms** — permutations of the 64
/// cells that map the set of 76 winning lines onto itself (Silver, 1967;
/// Idea-final §2.3). Two positions related by one of them are the same
/// position in every way that matters, so collapsing them to a single
/// representative is what makes a transposition table affordable: up to 192
/// entries become one.
///
/// The group is *constructed* here rather than hardcoded, and the engine's
/// tests verify it exhaustively — that it has exactly 192 members, that it is
/// closed under composition and inverses, and that every member preserves the
/// line table. A hand-written table of 192 permutations would be 12,288
/// numbers nobody could check by reading.
library;

import 'engine.dart';
import 'winning_lines.g.dart';

/// The 192 cell permutations, each a list where `permutation[cell]` is where
/// that cell goes. Built once.
final List<List<int>> boardAutomorphisms = _buildAutomorphisms();

/// Reversing a coordinate: 0<->3, 1<->2. The one non-trivial map that acts on
/// a single axis and still sends lines to lines.
const List<int> _reverse = [3, 2, 1, 0];

/// The coordinate maps that may be applied to the **x** axis.
///
/// A permutation of `{0,1,2,3}` can be applied to every axis at once and still
/// send lines to lines exactly when it commutes with [_reverse]. The reason is
/// the anti-diagonals: a plane's anti-diagonal is the cells `(t, 3-t)`, and
/// its image is a line only if `t -> 3-t` survives the map. Eight of the
/// twenty-four permutations qualify.
List<List<int>> _axisMaps() => [
      for (final p in _permutationsOfFour())
        if (_commutesWithReverse(p)) p,
    ];

bool _commutesWithReverse(List<int> p) {
  for (var i = 0; i < 4; i++) {
    if (p[_reverse[i]] != _reverse[p[i]]) return false;
  }
  return true;
}

List<List<int>> _permutationsOfFour() {
  final result = <List<int>>[];
  void permute(List<int> chosen, List<int> left) {
    if (left.isEmpty) {
      result.add(chosen);
      return;
    }
    for (var i = 0; i < left.length; i++) {
      permute([...chosen, left[i]], [...left]..removeAt(i));
    }
  }

  permute(const [], [0, 1, 2, 3]);
  return result;
}

/// Every automorphism, as a coordinate recipe.
///
/// One map is chosen for the x axis; the y and z maps must then differ from it
/// by at most a reversal, because a plane's diagonal `(t, t)` is a line only
/// when its two coordinates move together. Finally the three axes may be
/// permuted among themselves. 8 x 2 x 2 x 6 = 192, and the test asserts the
/// count rather than trusting the arithmetic.
List<List<int>> _buildAutomorphisms() {
  final seen = <String, List<int>>{};
  for (final axes in _permutationsOfThree()) {
    for (final tau in _axisMaps()) {
      for (final flipY in const [false, true]) {
        for (final flipZ in const [false, true]) {
          final maps = [
            tau,
            flipY ? _compose(_reverse, tau) : tau,
            flipZ ? _compose(_reverse, tau) : tau,
          ];
          final permutation = List<int>.filled(64, 0);
          for (var i = 0; i < 64; i++) {
            final cell = Cell(i);
            final moved = [
              maps[0][cell.x],
              maps[1][cell.y],
              maps[2][cell.z],
            ];
            permutation[i] =
                Cell.xyz(moved[axes[0]], moved[axes[1]], moved[axes[2]]).index;
          }
          seen[permutation.join(',')] = permutation;
        }
      }
    }
  }
  return [for (final p in seen.values) List<int>.unmodifiable(p)];
}

List<List<int>> _permutationsOfThree() => const [
      [0, 1, 2],
      [0, 2, 1],
      [1, 0, 2],
      [1, 2, 0],
      [2, 0, 1],
      [2, 1, 0],
    ];

/// `(outer after inner)(i)` — inner first.
List<int> _compose(List<int> outer, List<int> inner) =>
    [for (final v in inner) outer[v]];

/// Composes two cell permutations: apply [first], then [second].
List<int> composeAutomorphisms(List<int> first, List<int> second) =>
    [for (var i = 0; i < 64; i++) second[first[i]]];

/// True when [permutation] sends every winning line to a winning line.
///
/// The definition of an automorphism, written out so a test can assert it of
/// all 192 rather than trusting the construction that produced them.
bool preservesLines(List<int> permutation) {
  final lines = {for (final line in winningLines) _lineKey(line)};
  for (final line in winningLines) {
    if (!lines.contains(_lineKey([for (final c in line) permutation[c]]))) {
      return false;
    }
  }
  return true;
}

String _lineKey(List<int> line) => (line.toList()..sort()).join(',');

// ---------------------------------------------------------------------------
// Canonical form
// ---------------------------------------------------------------------------

/// A position's representative under the symmetry group: the smallest of the
/// 192 images of its board.
///
/// Encoded from the **side to move's** point of view rather than by colour, so
/// that a position and its mirror-with-colours-swapped share one entry. That
/// is what a transposition table wants: the value of a position depends on
/// whose turn it is, not on which colour happens to be light.
///
/// This walks all 192 permutations over all 64 cells, so it costs about twelve
/// thousand operations. That is fine for a test or a one-off lookup and far
/// too slow for a search node; the search maintains the same key incrementally
/// instead (see `transposition.dart`).
String canonicalKey(GameState state) => canonicalise(state).key;

/// A position's canonical form, together with the automorphism that produced
/// it.
///
/// The permutation is what makes a table of canonical positions *answerable*.
/// A key alone tells you a stored position is the same as yours; it cannot tell
/// you which of your cells the stored move refers to, because the entry was
/// written in whichever of the 192 orientations happened to be canonical. Carry
/// the permutation and the move comes back with [cellFromCanonical].
final class CanonicalForm {
  const CanonicalForm(this.key, this.permutation);

  /// The smallest of the 192 images, as [canonicalKey] describes.
  final String key;

  /// Where each cell of the real board lands in the canonical one:
  /// `permutation[cell]` is the canonical cell.
  final List<int> permutation;

  /// The real-board cell that [canonicalCell] refers to.
  ///
  /// The inverse of [permutation], searched rather than tabulated: it is called
  /// once per move at most, against a table that is built 192 times per lookup.
  Cell cellFromCanonical(int canonicalCell) {
    for (var i = 0; i < 64; i++) {
      if (permutation[i] == canonicalCell) return Cell(i);
    }
    throw ArgumentError.value(canonicalCell, 'canonicalCell', 'not a cell');
  }
}

/// [state]'s canonical form and the automorphism that reaches it.
///
/// When several automorphisms give the same smallest image the first is
/// returned, and the choice does not matter: they differ by a symmetry of the
/// position itself, so the cells they disagree about are interchangeable.
CanonicalForm canonicalise(GameState state) {
  final mover = state.sideToMove;
  final board = [
    for (var i = 0; i < 64; i++)
      switch (state.owner(Cell(i))) {
        null => 0,
        final owner => owner == mover ? 1 : 2,
      },
  ];
  String? best;
  List<int>? bestPermutation;
  final buffer = List<int>.filled(64, 0);
  for (final permutation in boardAutomorphisms) {
    for (var i = 0; i < 64; i++) {
      buffer[permutation[i]] = board[i];
    }
    final key = String.fromCharCodes(buffer.map((v) => 48 + v));
    if (best == null || key.compareTo(best) < 0) {
      best = key;
      bestPermutation = permutation;
    }
  }
  return CanonicalForm(best!, bestPermutation!);
}
