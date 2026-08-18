import 'dart:math';

import 'package:quadrim_engine/quadrim_engine.dart';
import 'package:test/test.dart';

const _unbounded = 1000000000;

void main() {
  group('the transposition table', () {
    test('returns what it stored, and nothing it did not', () {
      final table = TranspositionTable(sizeLog2: 8);
      expect(table.probe(12345), isNull);
      table.store(12345, 4, 77, TranspositionKind.exact, 21);
      final entry = table.probe(12345)!;
      expect(entry.depth, 4);
      expect(entry.score, 77);
      expect(entry.kind, TranspositionKind.exact);
      expect(entry.bestMove, 21);
    });

    test('keeps the deeper of two results for one position', () {
      final table = TranspositionTable(sizeLog2: 8);
      table.store(7, 6, 100, TranspositionKind.exact, 1);
      table.store(7, 2, -100, TranspositionKind.exact, 2);
      expect(table.probe(7)!.score, 100, reason: 'the deep result cost more');
    });

    test('a position with no best move round-trips as -1', () {
      final table = TranspositionTable(sizeLog2: 8);
      table.store(9, 1, 0, TranspositionKind.upperBound, -1);
      expect(table.probe(9)!.bestMove, -1);
    });

    test('is bounded: entries beyond its size displace earlier ones', () {
      // 2^4 slots. Storing far more must not grow it.
      final table = TranspositionTable(sizeLog2: 4);
      for (var i = 1; i <= 1000; i++) {
        table.store(i, 1, i, TranspositionKind.exact, 0);
      }
      expect(table.stored, lessThanOrEqualTo(16));
    });
  });

  group('the canonical hash', () {
    test('agrees with the slow canonical form over whole games', () {
      // The search maintains this incrementally; symmetry.dart computes it by
      // walking 192 boards. Neither is derived from the other.
      final random = Random(31415);
      final byForm = <String, int>{};
      var checked = 0;
      for (var game = 0; game < 40; game++) {
        var state = GameState.initial();
        final hash = CanonicalHash();
        while (outcome(state) is Ongoing && state.moves.length < 14) {
          final moves = legalMoves(state);
          final cell = moves[random.nextInt(moves.length)];
          hash
            ..toggle(state.moves.length % 2, cell.index)
            ..flipTurn();
          state = applyMove(state, cell);
          final form = canonicalKey(state);
          final seen = byForm[form];
          if (seen == null) {
            byForm[form] = hash.key;
          } else {
            expect(hash.key, seen,
                reason: 'same canonical form, different incremental key');
          }
          checked++;
        }
      }
      expect(checked, greaterThan(300));
    });

    test('seeding from a position matches toggling into it', () {
      final random = Random(2);
      for (var i = 0; i < 50; i++) {
        final state = _randomPosition(random);
        final me = state.sideToMove;
        final seeded = CanonicalHash.of(state, me);

        // Side 0 is *me*, not whoever opened, and a fresh hash starts with
        // side 0 to move — so building from an empty board has to correct for
        // the opener when me is not the opener. Getting this wrong is what the
        // production seeding would get wrong too, which is why the test builds
        // the position the long way rather than restating `CanonicalHash.of`.
        final built = CanonicalHash();
        if (me != Player.first) built.flipTurn();
        for (var m = 0; m < state.moves.length; m++) {
          final mover = m.isEven ? Player.first : Player.second;
          built
            ..toggle(mover == me ? 0 : 1, state.moves[m])
            ..flipTurn();
        }
        expect(seeded.key, built.key);
        expect(seeded.plainKey, built.plainKey);
      }
    });
  });

  group('iterative deepening', () {
    test('agrees with a plain fixed-depth search, table and all', () {
      // The table is the part most likely to be quietly wrong: a bad bound
      // returns a plausible number rather than an obvious error.
      final random = Random(9);
      for (var i = 0; i < 40; i++) {
        final state = _randomPosition(random, minPlies: 8);
        final candidates = legalMoves(state);
        final plain =
            searchScores(state, state.sideToMove, candidates, 4).reduce(max);
        for (final canonical in const [0, 3]) {
          final deep = deepSearch(
            state,
            state.sideToMove,
            candidates,
            SearchLimits(
              nodeBudget: _unbounded,
              maxDepth: 4,
              canonicalPlies: canonical,
            ),
          );
          expect(deep.scores.reduce(max), plain,
              reason: 'canonicalPlies $canonical changed the answer');
        }
      }
    });

    test('is reproducible for a given state and budget', () {
      final state = _randomPosition(Random(3), minPlies: 10);
      const limits = SearchLimits(
          nodeBudget: 60000, maxDepth: 12, canonicalPlies: 2);
      final a = deepSearch(state, state.sideToMove, legalMoves(state), limits);
      final b = deepSearch(state, state.sideToMove, legalMoves(state), limits);
      expect(a.scores, orderedEquals(b.scores));
      expect(a.nodes, b.nodes);
      expect(a.depthReached, b.depthReached);
    });

    test('a bigger budget never reaches a shallower depth', () {
      final state = _randomPosition(Random(12), minPlies: 6);
      var previous = 0;
      for (final budget in const [5000, 20000, 80000]) {
        final result = deepSearch(
          state,
          state.sideToMove,
          legalMoves(state),
          SearchLimits(nodeBudget: budget, maxDepth: 12),
        );
        expect(result.depthReached, greaterThanOrEqualTo(previous));
        expect(result.nodes, lessThanOrEqualTo(budget));
        previous = result.depthReached;
      }
    });

    test('the budget is honoured, and is in nodes rather than time', () {
      // The same budget on the same position must spend the same nodes
      // whatever the machine is doing — that is the whole point of counting
      // nodes rather than milliseconds.
      final state = _randomPosition(Random(5), minPlies: 8);
      final result = deepSearch(
        state,
        state.sideToMove,
        legalMoves(state),
        const SearchLimits(nodeBudget: 25000, maxDepth: 16),
      );
      expect(result.nodes, lessThanOrEqualTo(25000));
      expect(result.depthReached, greaterThan(0));
    });

    test('the table is discarded between calls, so a search is a pure '
        'function of its arguments', () {
      final warm = _randomPosition(Random(6), minPlies: 4);
      final state = _randomPosition(Random(7), minPlies: 12);
      const limits = SearchLimits(nodeBudget: 40000, maxDepth: 8);
      final cold = deepSearch(state, state.sideToMove, legalMoves(state), limits);
      // Search something else first; the answer must not move.
      deepSearch(warm, warm.sideToMove, legalMoves(warm),
          const SearchLimits(nodeBudget: 200000, maxDepth: 10));
      final after = deepSearch(state, state.sideToMove, legalMoves(state), limits);
      expect(after.scores, orderedEquals(cold.scores));
      expect(after.nodes, cold.nodes);
    });

    test('rejects a search for the side that is not to move', () {
      final state = GameState.initial();
      expect(
        () => deepSearch(state, Player.second, legalMoves(state),
            const SearchLimits(nodeBudget: 1000, maxDepth: 2)),
        throwsArgumentError,
      );
    });
  });

  group('exact endgame solving', () {
    test('proves a result an estimate would only guess at', () {
      // Exact solving is only meaningful where it can finish, so this asks it
      // for positions near the end rather than near the start. The original
      // version of this test asked for `exactEmpties: 64` — "always solve
      // exactly" — from a six-move position with 58 cells empty, which is a
      // request to solve Qubic and hung the suite (D178).
      final random = Random(4242);
      var checked = 0;
      for (final state in _endgames(10, 6, random)) {
        final result = deepSearch(
          state,
          state.sideToMove,
          legalMoves(state),
          const SearchLimits(
              nodeBudget: _unbounded, maxDepth: 4, exactEmpties: 12),
        );
        checked++;
        final best = result.scores.reduce(max);

        // Proven, not estimated: every score is a win, a loss or a draw, and
        // none is a heuristic number in between.
        expect(best.abs() >= kWinScore - 128 || best == 0, isTrue,
            reason: 'score $best is an estimate, not a proof');
        expect(best.sign, _solve(state, state.sideToMove).sign,
            reason: 'disagreed with an independent solver on ${state.moves}');

        // And it stops as soon as it has the proof. Deepening past an exact
        // result re-proves the same thing, which is what made this the most
        // expensive test in the suite (D177).
        expect(result.depthReached, 1,
            reason: 'kept deepening after the answer was already proven');
      }
      expect(checked, greaterThan(0), reason: 'no endgames sampled');
    });

    test('a proven result is never overridden by an estimate', () {
      // Exact solving is consulted before the horizon and before the table's
      // heuristic entries, so turning the depth down cannot change a proof.
      final random = Random(808);
      var proofs = 0;
      for (final state in _endgames(10, 12, random)) {
        final candidates = legalMoves(state);
        final shallow = deepSearch(
            state,
            state.sideToMove,
            candidates,
            const SearchLimits(
                nodeBudget: _unbounded, maxDepth: 1, exactEmpties: 12));
        final deeper = deepSearch(
            state,
            state.sideToMove,
            candidates,
            const SearchLimits(
                nodeBudget: _unbounded, maxDepth: 4, exactEmpties: 12));
        final a = shallow.scores.reduce(max);
        if (a.abs() < kWinScore - 128) continue;
        proofs++;
        expect(deeper.scores.reduce(max).sign, a.sign,
            reason: 'a proof changed sign when the horizon moved');
      }
      expect(proofs, greaterThan(0), reason: 'no proved positions sampled');
    });

    test('counts the nodes the exact solver spends', () {
      // The calibration harness reads SearchOutcome.nodes. While the exact
      // solver ran outside the counter it under-reported by the whole endgame,
      // and the budget stopped bounding the opponents that use it.
      final random = Random(5150);
      var compared = 0;
      for (final state in _endgames(10, 6, random)) {
        final candidates = legalMoves(state);
        const shared = SearchLimits(nodeBudget: _unbounded, maxDepth: 1);
        final estimated =
            deepSearch(state, state.sideToMove, candidates, shared);
        final proved = deepSearch(state, state.sideToMove, candidates,
            const SearchLimits(
                nodeBudget: _unbounded, maxDepth: 1, exactEmpties: 12));
        compared++;
        expect(proved.nodes, greaterThan(estimated.nodes),
            reason: 'playing the endgame out cost nothing, which cannot be so');
      }
      expect(compared, greaterThan(0), reason: 'no endgames sampled');
    });

    test('agrees with an independent solver written a different way', () {
      // A plain negamax to the end, no table, no evaluation, no ordering. If
      // the two agree on who wins, the machinery above is not inventing
      // results.
      final random = Random(4242);
      var compared = 0;
      for (final state in _endgames(8, 10, random)) {
        compared++;
        final result = deepSearch(
            state,
            state.sideToMove,
            legalMoves(state),
            const SearchLimits(
                nodeBudget: _unbounded, maxDepth: 1, exactEmpties: 16));
        final best = result.scores.reduce(max);
        final theirs = _solve(state, state.sideToMove);
        final ours = best > kWinScore - 128
            ? 1
            : best < -kWinScore + 128
                ? -1
                : 0;
        expect(ours, theirs, reason: 'position ${state.moves}');
      }
      expect(compared, greaterThan(4));
    });
  });

  group('the budgeted opponents', () {
    // Iterative deepening under a node budget, which is what the top of the
    // ladder is made of. They were the Expert tier and are now the bottom of
    // Master, one name lower each: the configurations moved with the rungs
    // rather than with the names (D333).
    test('they exist, with budgets in nodes and rising strength', () {
      expect([basalt.id, cairn.id, flint.id, quartz.id, titan.id],
          ['basalt', 'cairn', 'flint', 'quartz', 'titan']);
      expect([basalt.rating, cairn.rating, flint.rating, quartz.rating,
        titan.rating], [1800, 1900, 2000, 2100, 2200]);
      for (final bot in [basalt, cairn, flint, quartz, titan]) {
        expect(bot.nodeBudget, greaterThan(0),
            reason: '${bot.id} must be budgeted in nodes, never in time');
        expect(bot.searchDepth, 0,
            reason: '${bot.id} deepens iteratively rather than fixing a depth');
        expect(bot.maxSearchDepth, greaterThan(0));
      }
      // Budget and forcing depth both rise with the rating.
      expect(
          [basalt, cairn, flint, quartz, titan]
              .map((b) => b.nodeBudget)
              .toList(),
          _ascending);
      expect(
          [basalt, cairn, flint, quartz, titan]
              .map((b) => b.threatSearchDepth)
              .toList(),
          _ascending);
      // Defence is the dial that separates them: raising the node budget
      // alone left it flat, and this did not (D169).
      expect(
          [basalt, cairn, flint, quartz, titan]
              .map((b) => b.defenceSearchDepth)
              .toList(),
          _ascending);
      expect(basalt.defenceSearchDepth, 0,
          reason: 'the bottom of the group is the baseline the rest are '
              'measured against');
      // Only the top two prove the endgame, and only they never blunder.
      expect(quartz.exactEmpties, greaterThan(0));
      expect(titan.exactEmpties, greaterThan(quartz.exactEmpties));
      expect(quartz.blunderRate, 0);
      expect(titan.blunderRate, 0);
      expect(basalt.blunderRate, 0.015);
      expect(cairn.blunderRate, 0.01);
      expect(flint.blunderRate, 0.005);
    });

    test('every one returns only legal moves', () {
      // Fewer positions than the cheap opponents get: a budgeted search costs
      // tens of milliseconds a move, and legality does not need thousands of
      // samples to hold.
      // Derived from the catalogue rather than listed, so an opponent added
      // later cannot quietly escape the sweep — which is how the whole
      // catalogue ended up in the cheap sweep instead (D177).
      final random = Random(1111);
      final budgeted =
          opponentCatalogue.where((b) => b.nodeBudget > 0).toList();
      expect(budgeted.length, greaterThanOrEqualTo(5));
      for (final bot in budgeted) {
        for (var i = 0; i < 6; i++) {
          final state = _randomPosition(random, minPlies: 6);
          final move = chooseMove(state, bot, random);
          expect(legalMoves(state).map((c) => c.index), contains(move.index),
              reason: '${bot.id} chose an illegal move');
          applyMove(state, move);
        }
      }
    }, timeout: const Timeout(Duration(minutes: 5)));

    test('Titan never loses a position exact solving proves is not lost',
        () {
      // The criterion, tested where it can be checked exhaustively: from
      // positions with few empty cells whose value is proved, Titan plays on
      // and must reach at least that value.
      final random = Random(64064);
      var checked = 0;
      for (final state in _endgames(8, 6, random)) {
        final proved = _solve(state, state.sideToMove);
        if (proved < 0) continue; // a lost position is lost however it is played
        checked++;
        var play = state;
        final mover = state.sideToMove;
        while (outcome(play) is Ongoing) {
          final bot = play.sideToMove == mover ? titan : sable;
          play = applyMove(play, chooseMove(play, bot, random));
        }
        final result = outcome(play);
        final got = result is Draw
            ? 0
            : (result as Win).winner == mover
                ? 1
                : -1;
        expect(got, greaterThanOrEqualTo(proved),
            reason: 'Titan threw away a proved $proved from ${state.moves}');
      }
      expect(checked, greaterThan(1), reason: 'too few proved positions');
    }, timeout: const Timeout(Duration(minutes: 5)));
  });
}

final Matcher _ascending = predicate<List<int>>(
  (values) {
    for (var i = 1; i < values.length; i++) {
      if (values[i] < values[i - 1]) return false;
    }
    return true;
  },
  'rises with the rating',
);

/// Positions with exactly [empties] cells left.
///
/// Reached by having a strong opponent play both sides, not by random moves:
/// a random game is over long before the endgame, so sampling for deep
/// positions by chance finds none at all.
List<GameState> _endgames(int empties, int want, Random random) {
  final found = <GameState>[];
  var attempts = 0;
  // A deep endgame is rare on purpose: a position with ten cells left and no
  // completed line means neither side won for fifty-four plies, and Kestrel
  // usually finishes sooner. Sixty attempts yielded one or two positions where
  // the callers want five or more, which read as assertion failures about the
  // solver rather than about the fixture. Each attempt is one fast self-play
  // game, so the cap is cheap to raise (D178).
  while (found.length < want && attempts++ < 1500) {
    var state = GameState.initial();
    while (outcome(state) is Ongoing) {
      if (64 - state.moves.length == empties) {
        found.add(state);
        break;
      }
      state = applyMove(state, chooseMove(state, kestrel, random));
    }
  }
  return found;
}

/// Plain negamax to the end: 1 if [me] wins with best play, -1 if it loses,
/// 0 for a draw. No table, no evaluation, no ordering — deliberately nothing
/// in common with the implementation it checks.
int _solve(GameState state, Player me) {
  final result = outcome(state);
  if (result is Win) return result.winner == me ? 1 : -1;
  if (result is Draw) return 0;
  final mover = state.sideToMove;
  var best = mover == me ? -2 : 2;
  for (final move in legalMoves(state)) {
    final value = _solve(applyMove(state, move), me);
    if (mover == me) {
      if (value > best) best = value;
      if (best == 1) break;
    } else {
      if (value < best) best = value;
      if (best == -1) break;
    }
  }
  return best;
}

GameState _randomPosition(Random random, {int minPlies = 0}) {
  var state = GameState.initial();
  final plies = minPlies + random.nextInt(20);
  for (var i = 0; i < plies; i++) {
    if (outcome(state) is! Ongoing) break;
    final moves = legalMoves(state);
    state = applyMove(state, moves[random.nextInt(moves.length)]);
  }
  if (outcome(state) is! Ongoing) return _randomPosition(random, minPlies: minPlies);
  return state;
}
