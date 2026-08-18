import 'dart:math';

import 'package:quadrim_engine/quadrim_engine.dart';
import 'package:test/test.dart';

/// Plays [a] against [b] for [games] games, alternating who opens so the
/// first-player advantage does not decide the result. Returns a's score.
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
      final winnerOpened = result.winner == Player.first;
      if (winnerOpened == aOpens) {
        wins++;
      } else {
        losses++;
      }
    }
  }
  return (wins: wins, losses: losses, draws: draws);
}

void main() {
  group('catalogue', () {
    test('those shipped so far are ordered weakest first, ids unique', () {
      final ids = opponentCatalogue.map((b) => b.id).toSet();
      expect(ids.length, opponentCatalogue.length);
      final ratings = opponentCatalogue.map((b) => b.rating).toList();
      expect(ratings, orderedEquals(ratings.toList()..sort()));
      expect(ids, containsAll(['pebble', 'twig', 'mote', 'clover', 'bramble',
        'willow', 'vireo', 'finch', 'kestrel', 'marlin', 'ember', 'basalt',
        'onyx', 'sable']));
    });

    test('the configurations match the roster in idea-v3 6.4', () {
      expect(twig.rules, {StrategicRule.winNow});
      expect(mote.rules, {StrategicRule.winNow, StrategicRule.blockNow});
      expect(mote.blunderRate, 0.40);
      expect(clover.blunderRate, 0.20);
      expect(clover.cornerBias, greaterThan(0));
      expect(bramble.rules.length, 4);
      expect(bramble.centreBias, 0, reason: 'no positional sense');
      expect(bramble.cornerBias, 0);
      expect(willow.centreBias, greaterThan(0.5), reason: 'strong centre');
      expect(vireo.centreBias, greaterThan(vireo.cornerBias),
          reason: 'centre before corner since D336');
      expect(kestrel.blunderRate, 0.08);
      // Among opponents that both win and block, blunder rate falls as rating
      // rises. Twig is excluded deliberately: it never blunders, and its
      // weakness is that it only knows one rule.
      expect(twig.blunderRate, 0);
      //
      // **Non-increasing to within 0.01, not strictly non-increasing** (D340).
      // The roster is ordered by measured strength, and blunder rate is not
      // monotone in measured strength: four rungs of the Club tier are one
      // configuration whose blunder rate rises with the rating because that is
      // the direction they measured in. The tolerance is what keeps the rule
      // useful — it still catches an opponent handed a wildly wrong rate, and
      // it no longer forbids the catalogue from following its own instrument.
      final rated =
          opponentCatalogue.where((b) => b.rules.length >= 2).toList();
      for (var i = 1; i < rated.length; i++) {
        expect(rated[i].blunderRate,
            lessThanOrEqualTo(rated[i - 1].blunderRate + 0.01),
            reason: '${rated[i].id} blunders far more than ${rated[i - 1].id}');
      }
    });

    test('nothing from Bramble to Marlin ranks corners above the centre', () {
      // Juniper, Rowan and Vireo did until D336, and all six of the Casual and
      // Club inversions the first whole-roster run reported involved one of
      // those three. Which good squares an opponent prefers is a *style*, and
      // two styles beat each other in a ring — so alternating them up a ladder
      // builds a cycle rather than an order, no matter how the blunder rates
      // are set. Exactly the failure `aggression` produced one tier over
      // (D314), and this is the assertion that stops it coming back the same
      // way: one plausible-sounding personality at a time.
      final stretch = opponentCatalogue
          .skipWhile((b) => b.id != 'bramble')
          .takeWhile((b) => b.id != 'lynx')
          .toList();
      expect(stretch.map((b) => b.id), contains('marlin'),
          reason: 'the stretch must still end at Marlin');
      expect(stretch, hasLength(12));
      for (final bot in stretch) {
        expect(bot.cornerBias, lessThanOrEqualTo(bot.centreBias),
            reason: '${bot.id} prefers corners to the centre');
      }
    });

    test('no Casual opponent sets aggression', () {
      // Vireo built at 0.67 and Finch blocked at 0.30 until ticket 044. Both
      // read well and both are gone: `aggression` is a style axis rather than a
      // strength one, and using it to space rungs made the tier measurably
      // *non-transitive* (D314). This is the assertion that stops it coming
      // back one plausible-sounding personality at a time — the two lines it
      // replaces asserted the opposite, and were the design it broke.
      //
      // It says nothing about whether the tier is ordered. It is not, and
      // D315 is where that is recorded; removing aggression shrank the cycle
      // and did not close it.
      for (final bot in opponentCatalogue.where((b) => b.tier == BotTier.casual)) {
        expect(bot.aggression, 0.5, reason: '${bot.id} sets aggression');
      }
    });
  });

  group('rule 1 — take the win', () {
    test('a rule-enabled opponent completes the line', () {
      // Light holds 0, 1, 2; cell 3 completes the x-axis line.
      final state = GameState.fromMoves([0, 21, 1, 22, 2, 26]);
      expect(threats(state, Player.first).single.emptyCell.index, 3);
      for (final bot in [twig, mote, kestrel]) {
        // No blunder can hide it: run enough seeds that the rule must show.
        final taken = [
          for (var s = 0; s < 60; s++) chooseMove(state, bot, Random(s)).index,
        ].where((c) => c == 3).length;
        expect(taken, greaterThan(30), reason: '${bot.id} misses an offered win');
      }
    });

    test('Pebble, which throws most of them away, does not systematically '
        'find it', () {
      final state = GameState.fromMoves([0, 21, 1, 22, 2, 26]);
      final taken = [
        for (var s = 0; s < 60; s++) chooseMove(state, pebble, Random(s)).index,
      ].where((c) => c == 3).length;
      // Pebble has `winNow` since D341 and discards it 71% of the time, so it
      // sits between pure chance (~1 in 58) and every rule-follower above it
      // (more than 30 of 60). Both bounds carry weight: the lower one is what
      // makes this rung a 600 rather than a 200, the upper one is what still
      // separates it from Twig by the published hundred.
      expect(taken, greaterThan(5), reason: 'it does hold the rule');
      expect(taken, lessThan(30), reason: 'and throws most of it away');
    });
  });

  group('rule 2 — block the loss', () {
    test('an opponent with blockNow blocks; one without does not', () {
      // Dark (second player) holds 21, 22, 26 — no line. Light holds 0,1,2 and
      // dark must block cell 3. Build a position where it is dark to move and
      // light threatens.
      final state = GameState.fromMoves([0, 21, 1, 22, 2]);
      expect(state.sideToMove, Player.second);
      expect(threats(state, Player.first).single.emptyCell.index, 3);

      final blocks = [
        for (var s = 0; s < 60; s++) chooseMove(state, mote, Random(s)).index,
      ].where((c) => c == 3).length;
      // Mote blunders 40% of the time, so it blocks roughly 60%.
      expect(blocks, greaterThan(25));

      final twigBlocks = [
        for (var s = 0; s < 60; s++) chooseMove(state, twig, Random(s)).index,
      ].where((c) => c == 3).length;
      expect(twigBlocks, lessThan(10),
          reason: 'Twig only knows how to win, not how to block');
    });

    test('taking a win outranks blocking one', () {
      // Both sides are one move from winning; the side to move must take its
      // own rather than block.
      final state = GameState.fromMoves([0, 16, 1, 17, 2, 18]);
      expect(state.sideToMove, Player.first);
      expect(threats(state, Player.first).single.emptyCell.index, 3);
      expect(threats(state, Player.second).single.emptyCell.index, 19);
      final chosen = [
        for (var s = 0; s < 40; s++) chooseMove(state, kestrel, Random(s)).index,
      ];
      expect(chosen.where((c) => c == 3).length, greaterThan(30));
    });
  });

  group('rules 3 and 4 — double threats', () {
    test('an opponent with makeDoubleThreat plays a fork when one exists', () {
      // Find a position where a fork is available, then check the bots that
      // have the rule find it far more often than the ones that do not.
      final random = Random(4242);
      var found = 0;
      var withRule = 0;
      var withoutRule = 0;
      for (var trial = 0; trial < 400 && found < 40; trial++) {
        final state = _randomPosition(random);
        final me = state.sideToMove;
        // Only interesting when no immediate win or loss is on the board,
        // because rules 1 and 2 would fire first.
        if (threats(state, me).isNotEmpty) continue;
        if (threats(state, me.opponent).isNotEmpty) continue;
        final forks = _forkCells(state, me);
        if (forks.isEmpty) continue;
        found++;
        // bramble has the rule and no positional bias; twig does not.
        if (forks.contains(chooseMove(state, bramble, Random(trial)).index)) {
          withRule++;
        }
        if (forks.contains(chooseMove(state, twig, Random(trial)).index)) {
          withoutRule++;
        }
      }
      expect(found, greaterThan(10), reason: 'test found too few fork positions');
      expect(withRule, greaterThan(withoutRule * 2),
          reason: 'the rule must dominate chance ($withRule vs $withoutRule)');
    });

    test('a fork means two distinct follow-up wins, not two lines', () {
      // Two lines of three sharing their last empty cell are stopped by one
      // block, so they must not count as a fork.
      final random = Random(7);
      for (var i = 0; i < 200; i++) {
        final state = _randomPosition(random);
        for (final cell in _forkCells(state, state.sideToMove)) {
          final next = applyMove(state, Cell(cell));
          final wins = {
            for (final t in threats(next, state.sideToMove)) t.emptyCell.index,
          };
          expect(wins.length, greaterThanOrEqualTo(2),
              reason: 'cell $cell was called a fork but leaves one block');
        }
      }
    });
  });

  group('temperament', () {
    test('an aggressive opponent builds first, a defensive one denies first',
        () {
      // Look for positions offering both a fork for us and a fork for them,
      // at different cells, with no immediate win or block pending.
      final random = Random(99);
      var compared = 0;
      var aggressiveBuilt = 0;
      var defensiveDenied = 0;
      for (var trial = 0; trial < 3000 && compared < 30; trial++) {
        final state = _randomPosition(random);
        final me = state.sideToMove;
        if (threats(state, me).isNotEmpty) continue;
        if (threats(state, me.opponent).isNotEmpty) continue;
        final build = _forkCells(state, me).toSet();
        final deny = _forkCells(state, me.opponent).toSet();
        if (build.isEmpty || deny.isEmpty) continue;
        if (build.intersection(deny).isNotEmpty) continue; // ambiguous
        compared++;

        // Zero blunder rate variants, so only temperament is under test.
        const attacker = BotConfig(
          id: 'test-attacker',
          rating: 1200,
          rules: _all,
          aggression: 0.9,
        );
        const defender = BotConfig(
          id: 'test-defender',
          rating: 1200,
          rules: _all,
          aggression: 0.1,
        );
        if (build.contains(chooseMove(state, attacker, Random(trial)).index)) {
          aggressiveBuilt++;
        }
        if (deny.contains(chooseMove(state, defender, Random(trial)).index)) {
          defensiveDenied++;
        }
      }
      expect(compared, greaterThan(5), reason: 'too few comparable positions');
      expect(aggressiveBuilt, greaterThan(compared * 0.6));
      expect(defensiveDenied, greaterThan(compared * 0.6));
    });

    test('centre and corner preference are independent knobs', () {
      const centreLover =
          BotConfig(id: 'c', rating: 1, centreBias: 1);
      const cornerLover =
          BotConfig(id: 'k', rating: 1, cornerBias: 1);
      final empty = GameState.initial();
      for (var s = 0; s < 30; s++) {
        expect(isCentreCell(chooseMove(empty, centreLover, Random(s))), isTrue);
        expect(isCornerCell(chooseMove(empty, cornerLover, Random(s))), isTrue);
      }
      // And both at once is expressible, which one enum could not do.
      const both = BotConfig(id: 'b', rating: 1, centreBias: 1, cornerBias: 1);
      for (var s = 0; s < 30; s++) {
        final cell = chooseMove(empty, both, Random(s));
        expect(isCentreCell(cell) || isCornerCell(cell), isTrue);
      }
    });
  });

  group('blunder rate', () {
    test('is statistical, measured over many positions, not per move', () {
      // A position with exactly one winning cell: any other choice is the
      // blunder. Measured against the configured rate, not asserted per move.
      final state = GameState.fromMoves([0, 21, 1, 22, 2, 26]);
      expect(_immediateWinCells(state, state.sideToMove), [3]);

      for (final bot in [mote, clover, kestrel]) {
        const trials = 3000;
        var blundered = 0;
        final random = Random(11);
        for (var i = 0; i < trials; i++) {
          if (chooseMove(state, bot, random).index != 3) blundered++;
        }
        final observed = blundered / trials;
        expect(observed, closeTo(bot.blunderRate, 0.04),
            reason: '${bot.id} blundered $observed against ${bot.blunderRate}');
      }
    });

    test('a blunder replaces the move rather than merely re-rolling it', () {
      // With blunderRate 1 the considered move is never played.
      const alwaysWrong = BotConfig(
        id: 'test-always-wrong',
        rating: 1,
        rules: {StrategicRule.winNow},
        blunderRate: 1,
      );
      final state = GameState.fromMoves([0, 21, 1, 22, 2, 26]);
      for (var s = 0; s < 50; s++) {
        expect(chooseMove(state, alwaysWrong, Random(s)).index, isNot(3));
      }
    });
  });

  test('every opponent returns only legal moves over thousands of positions',
      () {
    // The opponents that decide in microseconds. The budgeted ones cost up to
    // seconds a move and are swept in deep_search_test.dart at a sample that
    // fits the suite's runtime.
    //
    // Filtered on *both* budgets: ticket 025 introduced `nodeBudget` as the
    // alternative to `searchDepth`, and an unfiltered sweep of the whole
    // catalogue at 400 positions each turned this file into roughly two hours
    // of work — six searching opponents times four hundred positions times
    // seconds a move (D177).
    final random = Random(20260811);
    for (final bot in opponentCatalogue
        .where((b) => b.searchDepth == 0 && b.nodeBudget == 0)) {
      for (var i = 0; i < 400; i++) {
        final state = _randomPosition(random);
        final move = chooseMove(state, bot, random);
        expect(legalMoves(state).map((c) => c.index), contains(move.index),
            reason: '${bot.id} chose an illegal move');
        applyMove(state, move);
      }
    }
  });

  test('the tiers are distinguishable in play, not merely in configuration',
      () {
    // The claim the roster makes is about strength, so it is tested by
    // playing rather than by inspecting configuration.
    final random = Random(2026);
    final kestrelVsPebble = _match(kestrel, pebble, 60, random);
    expect(kestrelVsPebble.wins, greaterThan(kestrelVsPebble.losses * 3),
        reason: 'Kestrel $kestrelVsPebble against Pebble');

    final kestrelVsMote = _match(kestrel, mote, 60, random);
    expect(kestrelVsMote.wins, greaterThan(kestrelVsMote.losses),
        reason: 'Kestrel $kestrelVsMote against Mote');

    final twigVsPebble = _match(twig, pebble, 60, random);
    expect(twigVsPebble.wins, greaterThan(twigVsPebble.losses),
        reason: 'Twig $twigVsPebble against Pebble');
  }, timeout: const Timeout(Duration(minutes: 2)));
}

const Set<StrategicRule> _all = {
  StrategicRule.winNow,
  StrategicRule.blockNow,
  StrategicRule.makeDoubleThreat,
  StrategicRule.blockDoubleThreat,
};

List<int> _immediateWinCells(GameState state, Player player) =>
    [for (final t in threats(state, player)) t.emptyCell.index]..sort();

/// Cells where [player] would gain two or more distinct follow-up wins.
List<int> _forkCells(GameState state, Player player) {
  final result = <int>[];
  for (final cell in legalMoves(state)) {
    final wins = <int>{};
    for (final line in winningLines) {
      if (!line.contains(cell.index)) continue;
      var owned = 0;
      var empty = -1;
      var dead = false;
      for (final c in line) {
        if (c == cell.index) continue;
        final owner = state.owner(Cell(c));
        if (owner == player) {
          owned++;
        } else if (owner == null) {
          if (empty != -1) {
            dead = true;
            break;
          }
          empty = c;
        } else {
          dead = true;
          break;
        }
      }
      if (!dead && owned == 2 && empty != -1) wins.add(empty);
    }
    if (wins.length >= 2) result.add(cell.index);
  }
  return result;
}

/// A reachable, still-playable position.
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
