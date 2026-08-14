import 'dart:math';

import 'package:quadrim_engine/quadrim_engine.dart';
import 'package:test/test.dart';

void main() {
  group('the heuristic evaluation', () {
    test('an empty board is worth nothing to anyone', () {
      expect(evaluatePosition(GameState.initial(), Player.first), 0);
      expect(evaluatePosition(GameState.initial(), Player.second), 0);
    });

    test('a line the opponent has entered is dead for both sides', () {
      // Light holds 0, 1 and 2 — one cell from completing {0,1,2,3}. With
      // cell 3 empty that line is worth the full three-in-a-line weight;
      // with a dark piece on it, nothing to anyone.
      final open = GameState.fromMoves([0, 40, 1, 45, 2, 58]);
      final closed = GameState.fromMoves([0, 40, 1, 45, 2, 3]);
      expect(
        evaluatePosition(open, Player.first) -
            evaluatePosition(closed, Player.first),
        greaterThanOrEqualTo(40),
        reason: 'killing the line must cost light its whole weight',
      );
    });

    test('is superlinear: three on a line beats three scattered', () {
      final line = GameState.fromMoves([0, 63, 1, 62, 2]);
      final scattered = GameState.fromMoves([0, 63, 22, 62, 41]);
      expect(evaluatePosition(line, Player.first),
          greaterThan(evaluatePosition(scattered, Player.first)));
    });

    test('is antisymmetric between the two points of view', () {
      final random = Random(5);
      for (var i = 0; i < 200; i++) {
        final state = _randomPosition(random);
        expect(evaluatePosition(state, Player.first),
            -evaluatePosition(state, Player.second));
      }
    });

    test('defence above 1 makes the opponent count for more', () {
      // Dark holds two on a line; light holds one elsewhere.
      final state = GameState.fromMoves([0, 16, 63, 17]);
      final even = evaluatePosition(state, Player.first);
      final defensive = evaluatePosition(state, Player.first, defence: 2);
      expect(defensive, lessThan(even));
    });

    test('the search maintains the same number incrementally', () {
      // The search keeps its own board and updates the evaluation move by
      // move; a one-ply search must therefore reproduce the definition
      // exactly, at every position of many complete games.
      final random = Random(4242);
      for (var g = 0; g < 60; g++) {
        var state = GameState.initial();
        while (outcome(state) is Ongoing) {
          final me = state.sideToMove;
          final candidates = legalMoves(state);
          final scores = searchScores(state, me, candidates, 1);
          for (var i = 0; i < candidates.length; i++) {
            final after = applyMove(state, candidates[i]);
            // Two things intercept the evaluation before it is reached: the
            // move itself winning, and the one move of quiescence that keeps
            // the search from calling a lost position quiet (D156).
            final int expected;
            if (outcome(after) is Win) {
              expected = kWinScore - 1;
            } else if (threats(after, me.opponent).isNotEmpty) {
              expected = -kWinScore + 2;
            } else {
              expected = evaluatePosition(after, me);
            }
            expect(scores[i], expected,
                reason: 'cell ${candidates[i].index} in ${state.moves}');
          }
          state = applyMove(state, candidates[random.nextInt(candidates.length)]);
        }
      }
    });
  });

  group('alpha-beta search', () {
    test('rejects a depth below one and a mover who is not to move', () {
      final state = GameState.initial();
      expect(() => searchScores(state, Player.first, legalMoves(state), 0),
          throwsArgumentError);
      expect(() => searchScores(state, Player.second, legalMoves(state), 2),
          throwsArgumentError);
    });

    test('finds a win one move away', () {
      // Light holds 0, 1, 2; cell 3 completes the line.
      final state = GameState.fromMoves([0, 21, 1, 22, 2, 26]);
      final scores = searchScores(state, Player.first, legalMoves(state), 4);
      final best = _argmax(scores);
      expect(legalMoves(state)[best].index, 3);
      expect(scores[best], kWinScore - 1);
    });

    test('finds a win it must set up first, within the horizon', () {
      // Light holds 0 and 1 with 2 and 3 free, and dark cannot answer both.
      // Depth 3 is enough: play, they reply, win.
      final state = GameState.fromMoves([0, 40, 1, 41]);
      final candidates = legalMoves(state);
      final scores = searchScores(state, Player.first, candidates, 3);
      expect(scores.reduce(max), greaterThan(0),
          reason: 'a position two moves from winning must evaluate positively');
    });

    test('prefers the faster of two wins', () {
      // Both cell 3 (immediate) and a slower line are winning; the score for
      // the immediate one is strictly higher, because a win is discounted by
      // how many plies it takes.
      final state = GameState.fromMoves([0, 21, 1, 22, 2, 26]);
      final candidates = legalMoves(state);
      final scores = searchScores(state, Player.first, candidates, 4);
      final immediate = candidates.indexWhere((c) => c.index == 3);
      for (var i = 0; i < candidates.length; i++) {
        if (i == immediate) continue;
        expect(scores[i], lessThan(scores[immediate]));
      }
    });

    test('sees a loss coming and prefers the line that delays it', () {
      // Dark threatens at 3 and it is light to move with nothing better than
      // blocking: every non-blocking move must score as a loss, and blocking
      // must not.
      final state = _darkThreatensAtThree;
      expect(state.sideToMove, Player.first);
      expect({for (final t in threats(state, Player.second)) t.emptyCell.index},
          {3});
      final candidates = legalMoves(state);
      final scores = searchScores(state, Player.first, candidates, 3);
      final block = candidates.indexWhere((c) => c.index == 3);
      expect(scores[block], greaterThan(-kWinScore + 10),
          reason: 'blocking is not an immediate loss');
      for (var i = 0; i < candidates.length; i++) {
        if (i == block) continue;
        expect(scores[i], lessThan(-kWinScore + 10),
            reason: 'leaving cell 3 open loses at once');
      }
    });

    test('does not call a position quiet when the mover wins next', () {
      // Dark holds 0, 1 and 2 and wins at cell 3. An even-depth search stops
      // after dark's reply, so without quiescence it would evaluate the
      // resulting position as merely uncomfortable rather than lost (D156).
      final state = _darkThreatensAtThree;
      final candidates = legalMoves(state);
      final scores = searchScores(state, Player.first, candidates, 2);
      for (var i = 0; i < candidates.length; i++) {
        if (candidates[i].index == 3) continue;
        expect(scores[i], lessThan(-kWinScore + 10),
            reason: 'cell ${candidates[i].index} leaves dark winning at once');
      }
    });

    test('is reproducible for a given state and depth', () {
      final random = Random(1234);
      for (var i = 0; i < 40; i++) {
        final state = _randomPosition(random);
        final candidates = legalMoves(state);
        final a = searchScores(state, state.sideToMove, candidates, 3);
        final b = searchScores(state, state.sideToMove, candidates, 3);
        expect(a, orderedEquals(b));
      }
    });

    test('narrowing the window never changes which move wins', () {
      // The root shares alpha between candidates, so a candidate proven no
      // better than one already in hand returns a bound rather than a score.
      // What must not change is the maximum.
      final random = Random(77);
      for (var i = 0; i < 30; i++) {
        final state = _randomPosition(random);
        final candidates = legalMoves(state);
        final windowed = searchScores(state, state.sideToMove, candidates, 3);
        final exact = [
          for (final c in candidates)
            searchScores(state, state.sideToMove, [c], 3).single,
        ];
        expect(windowed.reduce(max), exact.reduce(max),
            reason: 'position ${state.moves}');
        // And no candidate may *reach* the maximum on a bound rather than on
        // its own merit: the tie set is what the positional ladder then picks
        // from, so a move the search rated worse must not appear in it.
        final best = windowed.reduce(max);
        for (var j = 0; j < candidates.length; j++) {
          if (windowed[j] != best) continue;
          expect(exact[j], best,
              reason: 'cell ${candidates[j].index} tied on a bound, not a '
                  'score, in ${state.moves}');
        }
      }
    });
  });

  group('threat-space search', () {
    test('finds a forced win a four-ply search cannot reach', () {
      // Sweep for a position where the forcing search sees a win and the
      // plain depth-limited search at the same nominal depth does not.
      final random = Random(808);
      var found = 0;
      for (var trial = 0; trial < 3000 && found < 5; trial++) {
        final state = _randomPosition(random);
        final me = state.sideToMove;
        if (threats(state, me).isNotEmpty) continue;
        if (threats(state, me.opponent).isNotEmpty) continue;
        if (threatSpaceWin(state, me, 6) == null) continue;
        final horizon =
            searchScores(state, me, legalMoves(state), 4).reduce(max);
        if (horizon >= kWinScore - 10) continue; // depth 4 already saw it
        found++;
      }
      expect(found, 5,
          reason: 'forcing sequences beyond the horizon must exist and be '
              'found — that is the whole reason Sable differs from Onyx');
    });

    test('every short forced win it claims really is forced', () {
      // Verified exhaustively over the sequences short enough to check: after
      // the claimed move, no reply saves the opponent.
      final random = Random(2718);
      var checked = 0;
      for (var trial = 0; trial < 600 && checked < 60; trial++) {
        final state = _randomPosition(random);
        final me = state.sideToMove;
        final move = threatSpaceWin(state, me, 2);
        if (move == null) continue;
        checked++;
        final after = applyMove(state, move);
        if (outcome(after) is Win) continue;
        for (final reply in legalMoves(after)) {
          final next = applyMove(after, reply);
          final result = outcome(next);
          if (result is Win) {
            expect(result.winner, me, reason: 'the reply won instead');
            continue;
          }
          expect(threatSpaceWin(next, me, 2), isNotNull,
              reason: 'reply ${reply.index} escaped a claimed forced win from '
                  '${state.moves} via ${move.index}');
        }
      }
      expect(checked, greaterThan(20), reason: 'too few claims to test');
    });

    test('claims nothing when the opponent can simply win first', () {
      // Dark threatens at 3 and it is light to move. Whatever light starts,
      // dark never has to answer it.
      expect(threatSpaceWin(_darkThreatensAtThree, Player.first, 6), isNull);
    });

    test('returns null when asked for the side that is not to move', () {
      final state = GameState.initial();
      expect(threatSpaceWin(state, Player.second, 6), isNull);
      expect(threatSpaceWin(state, Player.first, 0), isNull);
    });

    test('the fast version answers exactly what the naive one does', () {
      // The fast version reads counters the board maintains rather than
      // rescanning; the naive one is the definition written out. Same move,
      // not merely the same verdict — the ladder picks among tied candidates,
      // so a different first move is a different opponent.
      final random = Random(77);
      var claims = 0;
      for (var i = 0; i < 1500; i++) {
        final state = _randomPosition(random);
        final me = state.sideToMove;
        for (final depth in const [1, 2, 5]) {
          final fast = threatSpaceWin(state, me, depth);
          final naive = threatSpaceWinNaively(state, me, depth);
          expect(fast?.index, naive?.index,
              reason: 'depth $depth disagreed on ${state.moves}');
          if (fast != null) claims++;
        }
      }
      expect(claims, greaterThan(50), reason: 'too few forced wins sampled');
    });
  });

  group('the same search pointed at the opponent', () {
    // No rules, no search, no blunders: with everything else switched off,
    // any move this config avoids is one the defensive forcing search
    // rejected, and nothing else can be taking the credit.
    //
    // The budget is deliberately 64× the default: it is shared out among the
    // candidates, so this guarantees every one of them gets at least the
    // [kForcingBudget] the check below spends on it. A shipped opponent runs
    // starved by comparison and misses wins this finds — see D170.
    const defender = BotConfig(
      id: 'test-defender',
      rating: 1500,
      defenceSearchDepth: 6,
      forcingBudget: 64 * kForcingBudget,
    );

    test('never plays into a forced win when a safe move exists', () {
      final random = Random(31337);
      var exercised = 0;
      for (var trial = 0; trial < 400 && exercised < 40; trial++) {
        final state = _randomPosition(random);
        final me = state.sideToMove;

        final safe = [
          for (final move in legalMoves(state))
            if (_survives(state, move, me)) move,
        ];
        if (safe.isEmpty) continue; // every move loses: nothing to get right
        if (safe.length == legalMoves(state).length) continue; // nothing to dodge
        exercised++;

        final chosen = chooseMove(state, defender, random);
        expect(safe.map((c) => c.index), contains(chosen.index),
            reason: 'walked into a forced win from ${state.moves}');
      }
      expect(exercised, greaterThan(10),
          reason: 'too few positions where the choice mattered');
    });

    test('still plays on when every move loses', () {
      // A lost position is played out. The alternative — no move — would make
      // the caller handle a null it can do nothing with.
      final random = Random(11);
      final state = _darkThreatensAtThree;
      expect(() => chooseMove(state, defender, random), returnsNormally);
    });
  });

  group('the Club tier', () {
    test('the four exist with the configurations calibration settled on', () {
      expect([ember.id, basalt.id, onyx.id, sable.id],
          ['ember', 'basalt', 'onyx', 'sable']);
      expect([ember.rating, basalt.rating, onyx.rating, sable.rating],
          [1500, 1550, 1650, 1700]);
      expect([ember.blunderRate, basalt.blunderRate, onyx.blunderRate,
        sable.blunderRate], [0.05, 0.04, 0.03, 0.02]);
      // Depths are what calibration settled on, not what idea-v3 6.4's
      // prose says (D154): forcing depth is the lever that works, and past
      // three plies ordinary depth separates nothing (D156).
      expect(ember.searchDepth, 2);
      expect(basalt.searchDepth, 3);
      expect(onyx.searchDepth, 3);
      expect(sable.searchDepth, 4);
      expect(ember.threatSearchDepth, 0);
      expect([basalt, onyx, sable].map((b) => b.threatSearchDepth),
          orderedEquals([3, 6, 9]),
          reason: 'the forcing search deepens with every rung');
      // Opposing temperaments, expressed in one number each.
      expect(ember.aggression, greaterThan(0.5));
      expect(basalt.aggression, lessThan(0.5));
      expect(ember.defence, lessThan(basalt.defence));
    });

    test('a search opponent still answers within the recorded budget', () {
      // The budget is 250 ms mean and 1 s worst on a mid-range phone (D152).
      // This machine is not that phone, so the assertion is loose by an order
      // of magnitude on purpose: it is a guard against a change that makes
      // the search catastrophically slower, not a device measurement.
      final random = Random(3);
      for (final bot in [ember, basalt, onyx, sable]) {
        var state = GameState.initial();
        var worst = 0;
        while (outcome(state) is Ongoing) {
          final watch = Stopwatch()..start();
          final move = chooseMove(state, bot, random);
          watch.stop();
          worst = max(worst, watch.elapsedMilliseconds);
          state = applyMove(state, move);
        }
        expect(worst, lessThan(1000), reason: '${bot.id} worst move $worst ms');
      }
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('each beats the one below it over a significant number of games', () {
      // The ladder these numbers produced is in D154; it is the reason Basalt
      // searches three plies and Onyx has a threat search at all.
      final random = Random(31);
      // Sample sizes follow the measured margins: Ember over Marlin and
      // Basalt over Ember are around 58% and need games to show, while Onyx
      // and Sable win their rungs by two to four to one.
      for (final pair in [(ember, marlin), (basalt, ember)]) {
        final r = _match(pair.$1, pair.$2, 200, random);
        expect(r.wins, greaterThan(r.losses),
            reason: '${pair.$1.id} $r against ${pair.$2.id}');
      }
      for (final pair in [(onyx, basalt), (sable, onyx)]) {
        final r = _match(pair.$1, pair.$2, 40, random);
        expect(r.wins, greaterThan(r.losses),
            reason: '${pair.$1.id} $r against ${pair.$2.id}');
      }
    }, timeout: const Timeout(Duration(minutes: 10)));

    test('every searching opponent returns only legal moves', () {
      // Fewer positions than the ruleless sweep in bot_test.dart: a four-ply
      // look costs milliseconds where a rule costs microseconds, and this
      // claim is about legality, which does not need thousands of samples to
      // hold. The catalogue-wide sweeps cover the cheap opponents.
      final random = Random(6060);
      for (final bot in [ember, basalt, onyx, sable]) {
        for (var i = 0; i < 150; i++) {
          final state = _randomPosition(random);
          final move = chooseMove(state, bot, random);
          expect(legalMoves(state).map((c) => c.index), contains(move.index),
              reason: '${bot.id} chose an illegal move');
          applyMove(state, move);
        }
      }
    }, timeout: const Timeout(Duration(minutes: 5)));
  });
}

/// Light to move; dark holds 0, 1 and 2 and wins next move at cell 3. Light's
/// own three cells lie on no shared line, so it has nothing better to do.
final GameState _darkThreatensAtThree =
    GameState.fromMoves([16, 0, 22, 1, 41, 2]);

int _argmax(List<int> values) {
  var best = 0;
  for (var i = 1; i < values.length; i++) {
    if (values[i] > values[best]) best = i;
  }
  return best;
}

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

/// Whether [me] playing [move] leaves the opponent without a forced win,
/// measured at the same depth the defender searches.
bool _survives(GameState state, Cell move, Player me) {
  final after = applyMove(state, move);
  if (outcome(after) is! Ongoing) return true;
  return threatSpaceWin(after, me.opponent, 6) == null;
}
