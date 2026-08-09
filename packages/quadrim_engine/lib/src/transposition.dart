/// A bounded transposition table, keyed by a position's canonical form.
///
/// Two things make this worth having. Positions repeat: the same board arrives
/// by many move orders, and a search that has already evaluated one should not
/// do it again. And positions repeat *up to symmetry*: the board has 192
/// automorphisms (see `symmetry.dart`), so a table keyed by canonical form
/// answers for up to 192 boards per entry.
///
/// The table is created and discarded inside a single move choice. Nothing
/// carries over between moves, which is what keeps `chooseMove` a pure
/// function of its arguments — a table that survived would make the same
/// position return different answers depending on what had been searched
/// before it (ticket 025).
library;

import 'dart:typed_data';

import 'engine.dart';
import 'symmetry.dart';

/// What a stored score is worth relative to the window it was found in.
///
/// A score found inside its window is the true value. One that caused a cutoff
/// is only a bound, and using it as a value would be wrong — this is the
/// distinction that makes an alpha-beta table sound rather than merely fast.
enum TranspositionKind { exact, lowerBound, upperBound }

/// One position's stored result.
final class TranspositionEntry {
  const TranspositionEntry(this.depth, this.score, this.kind, this.bestMove);

  /// How many plies were searched below the position. A shallower stored
  /// result cannot answer a deeper question.
  final int depth;
  final int score;
  final TranspositionKind kind;

  /// The move that was best here last time, or -1. Useless as an answer — the
  /// entry may be too shallow to trust — but the best guess available for
  /// *ordering*, which is where alpha-beta's pruning comes from.
  final int bestMove;
}

/// Fixed-size, open-addressed by index, replace-on-collision.
///
/// Memory is `2^sizeLog2` entries at 16 bytes each: 4 MB at the default
/// 2^18. Bounded by construction rather than by eviction policy, because an
/// unbounded table on a phone is a crash rather than a slowdown.
final class TranspositionTable {
  TranspositionTable({int sizeLog2 = 18})
      : assert(sizeLog2 >= 1 && sizeLog2 <= 24),
        _mask = (1 << sizeLog2) - 1,
        _keys = Int64List(1 << sizeLog2),
        _scores = Int32List(1 << sizeLog2),
        _meta = Int32List(1 << sizeLog2);

  final int _mask;
  final Int64List _keys;
  final Int32List _scores;

  /// Depth in bits 0-15, kind in 16-17, best move plus one in 18-24. Packed so
  /// an entry costs one 32-bit slot rather than three objects and a pointer.
  final Int32List _meta;

  int _stored = 0;
  int _hits = 0;
  int _probes = 0;

  /// How many entries hold something. Reported by the calibration harness
  /// rather than used by the search.
  int get stored => _stored;
  int get probes => _probes;
  int get hits => _hits;

  /// The entry for [key], or null. A zero key means "never written", so a
  /// position whose hash is genuinely zero is simply never cached — one lost
  /// entry in 2^64 is cheaper than a second occupancy array.
  TranspositionEntry? probe(int key) {
    _probes++;
    final slot = key & _mask;
    if (_keys[slot] != key || key == 0) return null;
    _hits++;
    final meta = _meta[slot];
    return TranspositionEntry(
      meta & 0xFFFF,
      _scores[slot],
      TranspositionKind.values[(meta >> 16) & 0x3],
      ((meta >> 18) & 0x7F) - 1,
    );
  }

  /// Stores unconditionally, except that a deeper result already in the slot
  /// is kept. Depth-preferred replacement: a deep entry cost more to compute
  /// and answers more questions than the shallow one competing for its slot.
  void store(
    int key,
    int depth,
    int score,
    TranspositionKind kind,
    int bestMove,
  ) {
    if (key == 0) return;
    final slot = key & _mask;
    if (_keys[slot] == key && (_meta[slot] & 0xFFFF) > depth) return;
    if (_keys[slot] == 0) _stored++;
    _keys[slot] = key;
    _scores[slot] = score;
    _meta[slot] =
        (depth & 0xFFFF) | (kind.index << 16) | (((bestMove + 1) & 0x7F) << 18);
  }
}

// ---------------------------------------------------------------------------
// Zobrist hashing, and the canonical hash built from it
// ---------------------------------------------------------------------------

/// `zobrist[side][cell]`, plus [zobristTurn] for the side to move.
///
/// Deterministic by construction — the engine may not reach for an ambient
/// random source, and a table that differed between runs would make the same
/// search return different answers. SplitMix64 from a fixed seed gives
/// well-spread constants that anyone can regenerate.
final List<Int64List> zobrist = _buildZobrist();

/// XORed in when it is side 1's turn, so a position and the same board with
/// the other side to move never share an entry.
final int zobristTurn = _splitMix64(0x9E3779B97F4A7C15 * 129);

List<Int64List> _buildZobrist() {
  final table = [Int64List(64), Int64List(64)];
  var seed = 0x243F6A8885A308D3; // the first hex digits of pi, as tradition
  for (var side = 0; side < 2; side++) {
    for (var cell = 0; cell < 64; cell++) {
      seed += 0x9E3779B97F4A7C15;
      table[side][cell] = _splitMix64(seed);
    }
  }
  return table;
}

int _splitMix64(int z) {
  var x = z;
  x = (x ^ (x >>> 30)) * 0xBF58476D1CE4E5B9;
  x = (x ^ (x >>> 27)) * 0x94D049BB133111EB;
  return x ^ (x >>> 31);
}

/// Maintains one Zobrist hash per automorphism, so a position's canonical key
/// is a minimum over 192 numbers rather than a walk over 192 boards.
///
/// Placing a piece touches every one of the 192 hashes, which is the price of
/// the collapse. It buys a table entry that answers for up to 192 boards; the
/// measured trade is recorded in D161.
final class CanonicalHash {
  CanonicalHash() : _hashes = Int64List(boardAutomorphisms.length);

  /// Seeded from an existing position, with [me] as side 0 — the same
  /// convention the search's board uses, so the two agree about which side a
  /// piece belongs to.
  factory CanonicalHash.of(GameState state, Player me) {
    final hash = CanonicalHash();
    for (var i = 0; i < 64; i++) {
      final owner = state.owner(Cell(i));
      if (owner == null) continue;
      hash.toggle(owner == me ? 0 : 1, i);
    }
    if (state.sideToMove != me) hash.flipTurn();
    return hash;
  }

  static final List<List<int>> _images = boardAutomorphisms;

  final Int64List _hashes;
  bool _turn = false;

  /// Adds or removes [side]'s piece on [cell] — XOR is its own inverse, so
  /// one method serves make and unmake.
  void toggle(int side, int cell) {
    final row = zobrist[side];
    for (var k = 0; k < _hashes.length; k++) {
      _hashes[k] ^= row[_images[k][cell]];
    }
  }

  void flipTurn() {
    _turn = !_turn;
    for (var k = 0; k < _hashes.length; k++) {
      _hashes[k] ^= zobristTurn;
    }
  }

  /// The smallest of the 192 hashes.
  ///
  /// Symmetric positions have the *same set* of images — the group is closed,
  /// so transforming one permutes the set rather than changing it — and
  /// therefore the same minimum.
  int get key {
    var best = _hashes[0];
    for (var k = 1; k < _hashes.length; k++) {
      final h = _hashes[k];
      if (h < best) best = h;
    }
    return best;
  }

  /// The untransformed hash, for a search that is not paying for symmetry.
  int get plainKey => _hashes[_identity];

  static final int _identity = () {
    for (var k = 0; k < boardAutomorphisms.length; k++) {
      var isIdentity = true;
      for (var i = 0; i < 64 && isIdentity; i++) {
        isIdentity = boardAutomorphisms[k][i] == i;
      }
      if (isIdentity) return k;
    }
    throw StateError('the symmetry group has no identity');
  }();
}
