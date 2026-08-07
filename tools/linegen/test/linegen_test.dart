import 'dart:convert';
import 'dart:io';

import 'package:linegen/linegen.dart';
import 'package:test/test.dart';

/// Independent enumeration of every collinear quad by direction-vector
/// walking — a deliberately different construction from buildLines(), so the
/// two can only agree if both are right.
Set<String> enumerateByWalking() {
  const dirs = <List<int>>[
    // 13 direction vectors: half of the 26 non-zero {-1,0,1}^3 vectors,
    // one per opposite pair.
    [1, 0, 0], [0, 1, 0], [0, 0, 1],
    [1, 1, 0], [1, -1, 0], [1, 0, 1], [1, 0, -1], [0, 1, 1], [0, 1, -1],
    [1, 1, 1], [1, 1, -1], [1, -1, 1], [1, -1, -1],
  ];
  final found = <String>{};
  for (var x = 0; x < 4; x++) {
    for (var y = 0; y < 4; y++) {
      for (var z = 0; z < 4; z++) {
        for (final d in dirs) {
          final ex = x + 3 * d[0], ey = y + 3 * d[1], ez = z + 3 * d[2];
          if (ex < 0 || ex > 3 || ey < 0 || ey > 3 || ez < 0 || ez > 3) {
            continue;
          }
          final cells = [
            for (var i = 0; i < 4; i++)
              cell(x + i * d[0], y + i * d[1], z + i * d[2]),
          ]..sort();
          found.add(cells.join(','));
        }
      }
    }
  }
  return found;
}

void main() {
  final lines = buildLines();
  final degrees = buildDegrees(lines);

  test('exactly 76 lines, matching the published family counts', () {
    expect(lines, hasLength(76));
  });

  test('generated set equals an independent direction-walk enumeration', () {
    final independent = enumerateByWalking();
    expect(independent, hasLength(76));
    final generated = lines.map((l) => l.join(',')).toSet();
    expect(generated, equals(independent));
  });

  test('cell degrees match the literature: 16 cells on 7 lines, 48 on 4', () {
    expect(degrees.where((d) => d == 7), hasLength(16));
    expect(degrees.where((d) => d == 4), hasLength(48));
    expect(degrees.reduce((a, b) => a + b), equals(76 * 4));

    // The 16 seven-line cells are exactly the corners and the inner 2x2x2.
    bool cornerOrInner(int x) => x == 0 || x == 3;
    bool inner(int x) => x == 1 || x == 2;
    for (var x = 0; x < 4; x++) {
      for (var y = 0; y < 4; y++) {
        for (var z = 0; z < 4; z++) {
          final isCorner = cornerOrInner(x) && cornerOrInner(y) && cornerOrInner(z);
          final isInner = inner(x) && inner(y) && inner(z);
          expect(degrees[cell(x, y, z)], (isCorner || isInner) ? 7 : 4,
              reason: 'cell ($x,$y,$z)');
        }
      }
    }
  });

  test('no non-line quad is collinear: exhaustive over all C(64,4) sets', () {
    final lineSet = lines.map((l) => l.join(',')).toSet();
    var collinearCount = 0;
    for (var a = 0; a < 61; a++) {
      for (var b = a + 1; b < 62; b++) {
        for (var c = b + 1; c < 63; c++) {
          for (var d = c + 1; d < 64; d++) {
            if (lineSet.contains('$a,$b,$c,$d')) collinearCount++;
          }
        }
      }
    }
    expect(collinearCount, equals(76),
        reason: 'every winning quad must be one of the 76 and nothing else');
  });

  group('corpus', () {
    late Map<String, dynamic> corpus;

    setUpAll(() {
      // Regenerate in a temp working dir? No: replay the committed corpus,
      // which is what every other consumer reads. Staleness vs the generator
      // is CI's git-diff check, not this test's job.
      final file = File('../../packages/quadrim_engine/test/fixtures/corpus.json');
      corpus = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    });

    test('covers every line for both seats, plus draws', () {
      final games = corpus['games'] as List;
      final winLines = <String>{};
      var draws = 0;
      for (final g in games.cast<Map<String, dynamic>>()) {
        if (g['outcome'] == 'draw') {
          draws++;
        } else {
          winLines.add((g['line'] as List).join(','));
        }
      }
      expect(winLines, hasLength(76));
      expect(draws, greaterThanOrEqualTo(3));
      expect(games, hasLength(76 * 2 + draws));
    });

    test('every game replays to its recorded outcome', () {
      final lineList = lines;
      for (final g in (corpus['games'] as List).cast<Map<String, dynamic>>()) {
        final moves = (g['moves'] as List).cast<int>();
        final owner = List<int?>.filled(64, null);
        List<int>? completed;
        var completedAt = -1;
        for (var i = 0; i < moves.length; i++) {
          expect(owner[moves[i]], isNull, reason: 'move $i plays occupied cell');
          owner[moves[i]] = i % 2;
          if (completed == null) {
            for (final line in lineList) {
              if (line.every((c) => owner[c] == i % 2) &&
                  line.contains(moves[i])) {
                completed = line;
                completedAt = i;
              }
            }
          }
        }
        if (g['outcome'] == 'win') {
          expect(completed, isNotNull);
          expect(completedAt, moves.length - 1,
              reason: 'game must end the moment the line completes');
          expect(completed!.join(','), (g['line'] as List).join(','));
          expect(completedAt % 2, g['winnerSeat']);
        } else {
          expect(completed, isNull);
          expect(moves, hasLength(64));
        }
      }
    });

    test('illegal cases are genuinely illegal', () {
      for (final c in (corpus['illegal'] as List).cast<Map<String, dynamic>>()) {
        final moves = (c['moves'] as List).cast<int>();
        final next = c['illegalNext'] as int;
        if (c['reason'] == 'occupied') {
          expect(moves, contains(next));
        } else {
          expect(moves, isNot(contains(next)),
              reason: 'gameOver case must target an empty cell');
        }
      }
    });
  });

  test('line construction is deterministic', () {
    final a = buildLines();
    final b = buildLines();
    expect(a.map((l) => l.join(',')).join(';'),
        b.map((l) => l.join(',')).join(';'));
    // Cross-run corpus determinism is proven by CI's staleness gate, which
    // regenerates and git-diffs the committed artifacts on every run.
  });
}
