/// Build-time generator for the single source of truth on Quadrim's board:
/// the 76 winning lines, the per-cell line-degree table, and a corpus of
/// complete games with known outcomes (ticket 002, spec 9.3).
///
/// Nothing else in the system may enumerate lines independently. The engine,
/// the tests, the tutorial illustrations and (from 0.4) the server validator
/// all consume what this tool emits.
///
/// Deterministic: same input (none) -> byte-identical output. Randomness uses
/// a fixed seed; iteration orders are sorted.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// Canonical cell index: x + 4*y + 16*z, each coordinate 0..3 (idea-v1 2).
int cell(int x, int y, int z) => x + 4 * y + 16 * z;

/// The 76 winning lines, built exactly as idea-v1 2.1 constructs them:
/// 48 axis-aligned, 24 planar diagonals, 4 space diagonals.
List<List<int>> buildLines() {
  final lines = <List<int>>[];

  // Axis-aligned: vary one coordinate, fix the other two. 3 * 16 = 48.
  for (var a = 0; a < 4; a++) {
    for (var b = 0; b < 4; b++) {
      lines.add([for (var i = 0; i < 4; i++) cell(i, a, b)]); // along x
      lines.add([for (var i = 0; i < 4; i++) cell(a, i, b)]); // along y
      lines.add([for (var i = 0; i < 4; i++) cell(a, b, i)]); // along z
    }
  }

  // Planar diagonals: 2 per slice, 4 slices per orientation, 3 orientations = 24.
  for (var s = 0; s < 4; s++) {
    lines.add([for (var i = 0; i < 4; i++) cell(i, i, s)]); // xy plane
    lines.add([for (var i = 0; i < 4; i++) cell(i, 3 - i, s)]);
    lines.add([for (var i = 0; i < 4; i++) cell(i, s, i)]); // xz plane
    lines.add([for (var i = 0; i < 4; i++) cell(i, s, 3 - i)]);
    lines.add([for (var i = 0; i < 4; i++) cell(s, i, i)]); // yz plane
    lines.add([for (var i = 0; i < 4; i++) cell(s, i, 3 - i)]);
  }

  // Space diagonals: corner to opposite corner. 4.
  lines.add([for (var i = 0; i < 4; i++) cell(i, i, i)]);
  lines.add([for (var i = 0; i < 4; i++) cell(i, i, 3 - i)]);
  lines.add([for (var i = 0; i < 4; i++) cell(i, 3 - i, i)]);
  lines.add([for (var i = 0; i < 4; i++) cell(3 - i, i, i)]);

  // Canonical form: cells sorted within a line, lines sorted lexicographically.
  for (final l in lines) {
    l.sort();
  }
  lines.sort((a, b) {
    for (var i = 0; i < 4; i++) {
      final c = a[i].compareTo(b[i]);
      if (c != 0) return c;
    }
    return 0;
  });
  return lines;
}

/// Lines through each cell. The literature says 7 for the 8 corners and the
/// 8 inner cells, 4 for the other 48 (idea-v1 2.2) — verified by the tests.
List<int> buildDegrees(List<List<int>> lines) {
  final degrees = List<int>.filled(64, 0);
  for (final line in lines) {
    for (final c in line) {
      degrees[c]++;
    }
  }
  return degrees;
}

// --- Minimal board logic, private to this tool, driven by the built lines ---

class _Board {
  _Board(this.lines);
  final List<List<int>> lines;
  final List<int?> owner = List.filled(64, null); // seat 0/1 or null

  /// Returns the completed line if placing [c] for [seat] wins, else null.
  List<int>? place(int c, int seat) {
    assert(owner[c] == null, 'cell occupied');
    owner[c] = seat;
    for (final line in lines) {
      if (line.contains(c) && line.every((i) => owner[i] == seat)) {
        return line;
      }
    }
    return null;
  }
}

Map<String, Object?> _winGame(
  List<List<int>> lines,
  List<int> line,
  int winnerSeat,
  Random rng,
) {
  // The winner plays the line's four cells; the loser scatters. A loser with
  // at most four pieces can still complete a line, so loser cells are chosen
  // to never contain a full line and never to sit on the winner's line.
  final complement = [
    for (var c = 0; c < 64; c++)
      if (!line.contains(c)) c,
  ]..shuffle(rng);

  final loserCells = <int>[];
  for (final c in complement) {
    if (loserCells.length == 4) break;
    final candidate = {...loserCells, c};
    final completesALine =
        lines.any((l) => l.every(candidate.contains));
    if (!completesALine) loserCells.add(c);
  }

  final winnerCells = [...line]..shuffle(rng);
  final moves = <int>[];
  final board = _Board(lines);
  List<int>? completed;
  for (var i = 0; i < 8 && completed == null; i++) {
    final seat = i % 2;
    final movingSeatIsWinner = seat == winnerSeat;
    final c = movingSeatIsWinner
        ? winnerCells[i ~/ 2]
        : loserCells[i ~/ 2];
    moves.add(c);
    completed = board.place(c, seat);
  }
  assert(completed != null && _sameLine(completed, line));
  return {
    'moves': moves,
    'outcome': 'win',
    'winnerSeat': winnerSeat,
    'line': line,
  };
}

bool _sameLine(List<int> a, List<int> b) {
  for (var i = 0; i < 4; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// A full-board draw: a 32/32 colouring with no monochromatic line, found by
/// hill climbing from a random assignment, then emitted as alternating moves.
/// If no line is monochromatic in the final position, none was completed at
/// any earlier point either, so any move order of the colouring is a legal
/// drawn game.
Map<String, Object?> _drawGame(List<List<int>> lines, Random rng) {
  final colors = List<int>.generate(64, (i) => i % 2)..shuffle(rng);
  int violations(List<int> cs) => lines
      .where((l) => l.every((c) => cs[c] == cs[l[0]]))
      .length;

  var current = violations(colors);
  var guard = 0;
  while (current > 0) {
    if (++guard > 200000) {
      throw StateError('draw search failed to converge');
    }
    final a = rng.nextInt(64);
    final b = rng.nextInt(64);
    if (colors[a] == colors[b]) continue;
    final t = colors[a];
    colors[a] = colors[b];
    colors[b] = t;
    final next = violations(colors);
    if (next <= current) {
      current = next;
    } else {
      colors[b] = colors[a];
      colors[a] = t;
    }
  }

  final seat0 = [
    for (var c = 0; c < 64; c++)
      if (colors[c] == 0) c,
  ]..shuffle(rng);
  final seat1 = [
    for (var c = 0; c < 64; c++)
      if (colors[c] == 1) c,
  ]..shuffle(rng);
  final moves = <int>[];
  for (var i = 0; i < 32; i++) {
    moves.add(seat0[i]);
    moves.add(seat1[i]);
  }
  return {
    'moves': moves,
    'outcome': 'draw',
    'winnerSeat': null,
    'line': null,
  };
}

void run() {
  final lines = buildLines();
  final degrees = buildDegrees(lines);
  final rng = Random(20260727); // fixed seed: output must be reproducible

  // --- winning_lines.g.dart ---
  final dart = StringBuffer()
    ..writeln('// GENERATED by tools/linegen — DO NOT EDIT BY HAND.')
    ..writeln('// Regenerate with: dart run tools/linegen/bin/linegen.dart')
    ..writeln('// The single source of truth for the 76 winning lines and')
    ..writeln('// per-cell line degrees (spec 9.3). CI fails if stale.')
    ..writeln()
    ..writeln('/// The 76 winning lines of the 4x4x4 board, each as four cell')
    ..writeln('/// indices (x + 4y + 16z), sorted within the line, lines in')
    ..writeln('/// lexicographic order.')
    ..writeln('const List<List<int>> winningLines = [');
  for (final line in lines) {
    dart.writeln('  [${line.join(', ')}],');
  }
  dart
    ..writeln('];')
    ..writeln()
    ..writeln('/// How many winning lines pass through each cell: 7 for the 8')
    ..writeln('/// corners and 8 inner cells, 4 for the other 48.')
    ..writeln('const List<int> cellDegree = [');
  for (var z = 0; z < 4; z++) {
    final row = degrees.sublist(z * 16, (z + 1) * 16);
    dart.writeln('  ${row.join(', ')},');
  }
  dart.writeln('];');

  // --- corpus.json ---
  final games = <Map<String, Object?>>[];
  for (final line in lines) {
    games.add(_winGame(lines, line, 0, rng));
    games.add(_winGame(lines, line, 1, rng));
  }
  for (var i = 0; i < 3; i++) {
    games.add(_drawGame(lines, rng));
  }

  final someWin = games.first;
  final illegal = <Map<String, Object?>>[
    {
      'moves': [0, 1],
      'illegalNext': 0,
      'reason': 'occupied',
    },
    {
      'moves': someWin['moves'],
      'illegalNext': _firstEmptyAfter(someWin['moves']! as List<int>),
      'reason': 'gameOver',
    },
  ];

  final corpus = const JsonEncoder.withIndent(' ').convert({
    'schemaVersion': 1,
    'generator': 'tools/linegen',
    'games': games,
    'illegal': illegal,
  });

  final root = _repoRoot();
  File('$root/packages/quadrim_engine/lib/src/winning_lines.g.dart')
    ..createSync(recursive: true)
    ..writeAsStringSync(dart.toString());
  File('$root/packages/quadrim_engine/test/fixtures/corpus.json')
    ..createSync(recursive: true)
    ..writeAsStringSync('$corpus\n');

  stdout.writeln('linegen: ${lines.length} lines, '
      '${games.length} corpus games, ${illegal.length} illegal cases.');
}

int _firstEmptyAfter(List<int> moves) {
  final used = moves.toSet();
  for (var c = 0; c < 64; c++) {
    if (!used.contains(c)) return c;
  }
  throw StateError('board full');
}

String _repoRoot() {
  var dir = Directory.current;
  while (!File('${dir.path}/tool/check.sh').existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('run from inside the Quadrim repository');
    }
    dir = parent;
  }
  return dir.path;
}
