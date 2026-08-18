// Measures the whole ladder against itself and reports where the catalogue
// disagrees with the published anchors (ticket 014).
//
// The published ratings are fixed and do not move (D144): they are what every
// player's computer rating is earned against, so changing one silently
// rewrites the meaning of every result already recorded against it. This tool
// therefore only ever *reports*. When measurement disagrees with an anchor,
// the defect is in that opponent's configuration and the fix is a change to
// its parameters, never to its rating.
//
//   dart run tool/calibrate.dart                    # the whole ladder
//   dart run tool/calibrate.dart --games 40
//   dart run tool/calibrate.dart --only oracle      # one opponent, resettled
//                                                   # against its whole tier
//
// Not part of the shipped package: `tool` is outside the purity gate's `lib`
// scan, and this is one of the two places the engine is allowed a clock.
import 'dart:math';

import 'package:quadrim_engine/quadrim_engine.dart';
import 'package:quadrim_rating/quadrim_rating.dart';

/// Games per pair. Fifty leaves roughly 50 rating points of sampling noise
/// around an even result, which is why [kTolerance] sits where it does.
///
/// Raised from thirty in D339, together with [kReach]. Thirty left ~64 points of
/// noise on a ladder whose rungs are forty apart, so a single pair could not
/// tell a correct rung from an inverted one; the run that motivated the change
/// reported nine inversions and several of them were within a game or two of
/// even. Fifty games is a third less noise for two thirds more time, and the
/// time was affordable because the whole run was twenty minutes rather than the
/// hour it was budgeted at.
const int kDefaultGames = 50;

/// How far up the roster each opponent is measured against.
///
/// Every opponent plays the [kReach] rungs above it, which on a roster of
/// thirty-one is 140 pairs: 30 adjacent, then 29, 28, 27 and 26 at reaches two
/// to five.
///
/// **A window rather than a chain plus a few braces** (D339). The scheme this
/// replaces played adjacent pairs, every pair inside a tier, and one brace
/// between tier middles — which measured each tier well and the *joins between
/// them* through a single pair. The bottom two tiers touched at exactly one
/// pairing, so Sorrel's rating and Bramble's were estimated against disjoint
/// opponent sets and came out 259 points apart while the two of them measured
/// level head to head. A fixed reach removes the idea of a tier from the
/// sampling entirely: every rung is tied to the five above it whether or not
/// they share a band, so the scale is pinned continuously from Pebble to
/// Quadrim Prime.
///
/// What it gives up is the long brace. Nothing now plays anything more than
/// five rungs away, so the run no longer reports Hazel against Quartz. Those
/// pairs were swept almost without exception and yielded a bound rather than a
/// value, so little is lost — but if the ladder ever needs its *absolute* span
/// checked rather than its ordering, that check is gone and has to come back.
const int kReach = 5;

/// What the node and forcing budgets are multiplied by while calibrating.
///
/// A full-budget chain is hours; a tenth of it is minutes, and the ordering
/// question this tool answers survives the reduction because every opponent is
/// reduced by the same factor (D208).
const double kDefaultBudgetScale = 0.1;

/// How far a measured rating may sit from its published anchor before it is
/// reported as a configuration defect.
///
/// Comfortably above the ~70 points of sampling noise in a thirty-game pair,
/// so a report means a real disagreement rather than a run of luck.
const int kTolerance = 150;

void main(List<String> args) {
  final options = _Options.parse(args);
  if (options == null) {
    print('usage: dart run tool/calibrate.dart [--games N] [--budget F] '
        '[--only ID]');
    print('  --games   games per pair (default $kDefaultGames)');
    print('  --budget  fraction of each node budget to use '
        '(default $kDefaultBudgetScale)');
    print('  --only    measure one opponent against the settled rest');
    return;
  }

  final pairs =
      options.only == null ? _ladderPairs() : _pairsFor(options.only!);
  if (pairs.isEmpty) {
    print('no such opponent: ${options.only}');
    return;
  }

  print('calibrating ${pairs.length} pairs, ${options.games} games each, '
      'budgets at ${(options.budgetScale * 100).round()}%');
  print('');

  final started = DateTime.now();
  final results = <_PairResult>[];
  for (final pair in pairs) {
    final result = _duel(pair.$1, pair.$2, options);
    results.add(result);
    print(result.line());
  }
  final elapsed = DateTime.now().difference(started);

  print('');
  _reportMeasured(results, options);
  print('');
  _reportDefects(results, options);
  print('');
  print('ran ${pairs.length} pairs in ${_duration(elapsed)}');
}

// ---------------------------------------------------------------------------
// Which pairs get played
// ---------------------------------------------------------------------------

/// The chain: every opponent against the next one up.
///
/// Nineteen pairs rather than a round-robin's 190. Adjacent pairs are what
/// establish the ordering and the size of each gap, and they are also the
/// cheapest — the expensive configurations meet only their own neighbours.
/// Every opponent against the [kReach] rungs above it.
///
/// Ordered by reach rather than by opponent, so the run prints all thirty
/// adjacent pairs before any pair at reach two. That ordering is deliberate:
/// the adjacent pairs are the ones an inversion is read from, and a run that is
/// interrupted half way has still measured every one of them.
List<(BotConfig, BotConfig)> _ladderPairs() => [
      for (var reach = 1; reach <= kReach; reach++)
        for (var i = 0; i + reach < opponentCatalogue.length; i++)
          (opponentCatalogue[i], opponentCatalogue[i + reach]),
    ];

/// One opponent against the [kReach] rungs above it and the [kReach] below.
///
/// The same window the full run uses, centred on the subject: up to ten pairs,
/// and exactly the pairs the full run would have measured it from. `--only`
/// used to sample by tier, and that is the sample that hid the Casual cycle —
/// Willow's two neighbours were the two opponents it beats, so it measured 159
/// points above its anchor while losing to the two members of its own tier it
/// never met (D313). A symmetric window cannot produce that, because it never
/// leaves out a nearer opponent to include a further one.
List<(BotConfig, BotConfig)> _pairsFor(String id) {
  final index = opponentCatalogue.indexWhere((b) => b.id == id);
  if (index < 0) return const [];
  final subject = opponentCatalogue[index];
  return [
    for (var reach = 1; reach <= kReach; reach++) ...[
      if (index - reach >= 0) (opponentCatalogue[index - reach], subject),
      if (index + reach < opponentCatalogue.length)
        (subject, opponentCatalogue[index + reach]),
    ],
  ];
}
_PairResult _duel(BotConfig a, BotConfig b, _Options options) {
  final left = _scaled(a, options.budgetScale);
  final right = _scaled(b, options.budgetScale);
  var wins = 0;
  var losses = 0;
  var draws = 0;

  for (var g = 0; g < options.games; g++) {
    // Both seats, alternately: Qubic is a first-player win with perfect play,
    // so a pairing played from one seat measures the seat.
    final opener = g.isEven ? left : right;
    final second = g.isEven ? right : left;
    final winner = _play(opener, second, Random(options.seed + g));
    if (winner == null) {
      draws++;
    } else if (identical(winner, left)) {
      wins++;
    } else {
      losses++;
    }
  }

  return _PairResult(
    a: a,
    b: b,
    wins: wins,
    losses: losses,
    draws: draws,
    budgetScale: options.budgetScale,
  );
}

/// Returns the winning config, or null for a draw.
BotConfig? _play(BotConfig opener, BotConfig second, Random random) {
  var state = GameState.initial();
  while (outcome(state) is Ongoing) {
    final config = state.sideToMove == Player.first ? opener : second;
    state = applyMove(state, chooseMove(state, config, random));
  }
  final result = outcome(state);
  if (result is! Win) return null;
  return result.winner == Player.first ? opener : second;
}

/// The same opponent with its search budgets multiplied by [scale].
///
/// Only the budgets move. Depths, rules, biases and blunder rate are what make
/// an opponent that opponent; a budget is how long it is allowed to think, and
/// scaling it uniformly leaves the ordering intact while making the run
/// finishable. Zero budgets stay zero — that is "unused", not "very small" —
/// and a non-zero one never *becomes* zero, which is the same rule read the
/// other way round and matters more: `chooseMove` switches on
/// `nodeBudget > 0`, so a budget rounded away does not make an opponent think
/// briefly, it stops it searching at all and turns it into a different
/// opponent while the report still carries its name.
BotConfig _scaled(BotConfig config, double scale) => BotConfig(
      id: config.id,
      rating: config.rating,
      tier: config.tier,
      searchDepth: config.searchDepth,
      threatSearchDepth: config.threatSearchDepth,
      defenceSearchDepth: config.defenceSearchDepth,
      usesBook: config.usesBook,
      nodeBudget: _scaleBudget(config.nodeBudget, scale),
      maxSearchDepth: config.maxSearchDepth,
      exactEmpties: config.exactEmpties,
      canonicalPlies: config.canonicalPlies,
      forcingBudget: _scaleBudget(config.forcingBudget, scale),
      rules: config.rules,
      blunderRate: config.blunderRate,
      centreBias: config.centreBias,
      cornerBias: config.cornerBias,
      edgeBias: config.edgeBias,
      lineBias: config.lineBias,
      aggression: config.aggression,
      tieBreakRandomness: config.tieBreakRandomness,
    );

/// [budget] scaled, never crossing from "some" to "none".
int _scaleBudget(int budget, double scale) =>
    budget == 0 ? 0 : max(1, (budget * scale).round());

// ---------------------------------------------------------------------------
// What came out
// ---------------------------------------------------------------------------

final class _PairResult {
  _PairResult({
    required this.a,
    required this.b,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.budgetScale,
  });

  final BotConfig a;
  final BotConfig b;

  /// What the budgets were multiplied by. At 1 nothing was reduced, so the
  /// ply-versus-nodes asymmetry below cannot arise.
  final double budgetScale;

  /// From [a]'s side.
  final int wins;
  final int losses;
  final int draws;

  int get games => wins + losses + draws;

  /// [a]'s score, held half a game away from the ends.
  ///
  /// A clean sweep has no finite implied difference. Half a game is the
  /// smallest correction that keeps one, and it reads honestly: "at least
  /// this far apart, and the sample cannot say how much further".
  double get score {
    final raw = (wins + draws / 2) / games;
    final margin = 0.5 / games;
    return raw.clamp(margin, 1 - margin);
  }

  bool get isSwept => wins == games || losses == games;

  /// What the result says the gap is, from [a]'s side.
  double get measuredGap => impliedRatingDifference(score)!;

  /// What the catalogue says it is.
  int get publishedGap => a.rating - b.rating;

  /// Both sides play the book, so both win every game they open and the
  /// alternation decides the result. Such a pair measures the seat.
  bool get isSeatDetermined => a.usesBook && b.usesBook;

  /// The reduced budget hits these two by different amounts.
  ///
  /// Not every opponent spends both budgets. The lower tiers have no search at
  /// all, the Club tier's searchers bound their main search in *plies* and
  /// spend nodes only on the forcing search, and the Expert and Master tiers
  /// bound both in nodes. Scaling therefore leaves a rules-only opponent
  /// untouched, trims a ply-limited one, and takes nine tenths off a
  /// node-limited one — so across those boundaries the run is not a fair fight
  /// and its result is a property of this tool rather than of the catalogue
  /// (D208).
  bool get isBudgetAsymmetric =>
      budgetScale != 1 && _signature(a) != _signature(b);

  /// Which budgets this opponent actually spends, as a comparable pair.
  static (bool, bool) _signature(BotConfig c) => (
        c.nodeBudget > 0,
        c.threatSearchDepth > 0 || c.defenceSearchDepth > 0,
      );

  String line() {
    final label = '${a.id} vs ${b.id}';
    final tail = isSeatDetermined
        ? '  (both play the book: this measures the seat, not the strength)'
        : isBudgetAsymmetric
            ? '  (one side is ply-limited: the budget cut hits only the other)'
            : isSwept
                ? '  (swept: the gap is at least this)'
                : '';
    return '${label.padRight(30)} '
        '${'$wins-$losses-$draws'.padLeft(9)}  '
        'measured ${_signed(measuredGap.round()).padLeft(5)}  '
        'published ${_signed(publishedGap).padLeft(5)}$tail';
  }
}

/// Each opponent's rating as the rest of the roster measures it.
///
/// Every pair yields one estimate per side: the *other* side's published
/// anchor plus the measured gap. Averaging those is deliberate — it answers
/// "does this opponent play at its anchor against the roster as published",
/// which is the question D144 leaves open, rather than fitting a fresh scale
/// that would quietly move every anchor at once.
void _reportMeasured(List<_PairResult> results, _Options options) {
  final estimates = <String, List<_Estimate>>{};
  for (final result in results) {
    if (result.isSeatDetermined || result.isBudgetAsymmetric) continue;
    // A swept pair gives a bound, not a value: its gap is clamped half a game
    // off the end, so it understates whichever side did the sweeping. Carried
    // through so the summary can say which of its numbers are floors.
    final swept = result.isSwept;
    estimates.putIfAbsent(result.a.id, () => []).add(_Estimate(
          result.b.rating + result.measuredGap,
          bound: !swept
              ? _Bound.exact
              : result.wins > result.losses
                  ? _Bound.atLeast
                  : _Bound.atMost,
        ));
    estimates.putIfAbsent(result.b.id, () => []).add(_Estimate(
          result.a.rating - result.measuredGap,
          bound: !swept
              ? _Bound.exact
              : result.losses > result.wins
                  ? _Bound.atLeast
                  : _Bound.atMost,
        ));
  }

  print('measured against published, ${options.games} games per pair');
  for (final bot in opponentCatalogue) {
    // In --only mode every other opponent played exactly one pair — against
    // the subject. Those are not measurements of them, and printing them as
    // if they were is how a one-opponent run turns into nineteen wrong claims.
    if (options.only != null && bot.id != options.only) continue;
    final mine = estimates[bot.id];
    if (mine == null || mine.isEmpty) continue;
    // **The median, not the mean** (D341). Every estimate in `mine` is another
    // opponent's *published* rating plus a measured gap, so it inherits that
    // opponent's anchor error in full. One badly wrong anchor therefore poisons
    // every rung within [kReach] of it: Pebble plays some 400 points below its
    // published 600, and the mean duly reported Sorrel above three rungs that
    // beat it 34-16, 35-15 and 33-17 on the board. A median over ten pairs
    // cannot be moved far by one of them, which is the property wanted — the
    // report exists to find anchors that are wrong, so it must not assume they
    // are right.
    final values = mine.map((e) => e.value).toList()..sort();
    final middle = values.length ~/ 2;
    final measured = (values.length.isOdd
            ? values[middle]
            : (values[middle - 1] + values[middle]) / 2)
        .round();
    final error = measured - bot.rating;
    final bounds = mine.map((e) => e.bound).toSet();
    final marker = bounds.contains(_Bound.atLeast) &&
            bounds.contains(_Bound.atMost)
        ? '~'
        : bounds.contains(_Bound.atLeast)
            ? '>'
            : bounds.contains(_Bound.atMost)
                ? '<'
                : ' ';
    final flag = error.abs() > kTolerance ? '  <-- outside tolerance' : '';
    print('  ${bot.id.padRight(16)} published ${bot.rating.toString().padLeft(5)}'
        '   measured $marker${measured.toString().padLeft(5)}'
        '   ${_signed(error).padLeft(5)}'
        '   from ${mine.length} pair${mine.length == 1 ? '' : 's'}$flag');
  }
  print('  > floor, < ceiling: some contributing pair was swept, so the gap '
      'it reports is a bound.');
}

enum _Bound { exact, atLeast, atMost }

final class _Estimate {
  const _Estimate(this.value, {required this.bound});
  final double value;
  final _Bound bound;
}

/// Everything the run says is wrong, in one place.
void _reportDefects(List<_PairResult> results, _Options options) {
  final defects = <String>[];
  final unreadable = <String>[];

  for (final result in results) {
    if (result.isSeatDetermined) continue;
    // An inversion: the roster says one of these is stronger and the board
    // says the other is. Never accepted as noise, because the catalogue's
    // ordering is a promise to the player, not an estimate.
    final publishedOrder = result.publishedGap.sign;
    final measuredOrder = result.measuredGap.sign;
    final inverted = publishedOrder != 0 &&
        measuredOrder != 0 &&
        publishedOrder != measuredOrder;
    if (!inverted) continue;
    // Named from the measurement, not from the catalogue. Assuming the
    // higher-published side is the one on the right prints every inversion
    // backwards, which is exactly what an inversion means it is not.
    final wonOnBoard = measuredOrder > 0 ? result.a : result.b;
    final wonOnPaper = publishedOrder > 0 ? result.a : result.b;
    final score = measuredOrder > 0
        ? '${result.wins}-${result.losses}-${result.draws}'
        : '${result.losses}-${result.wins}-${result.draws}';
    final description = '${wonOnBoard.id} (${wonOnBoard.rating}) beats '
        '${wonOnPaper.id} (${wonOnPaper.rating}) — $score';
    // Across the ply/nodes boundary the reduced budget hits one side only, so
    // an inversion there is as likely to be this tool's doing as the
    // catalogue's. Reported, but never as a defect on this evidence.
    if (result.isBudgetAsymmetric) {
      unreadable.add(description);
    } else {
      defects.add('inversion: $description');
    }
  }

  if (defects.isEmpty) {
    print('no ordering inversions.');
  } else {
    print('configuration defects — fix the opponent, never the rating (D144):');
    for (final defect in defects) {
      print('  $defect');
    }
  }
  if (unreadable.isNotEmpty) {
    print('not readable at this budget — re-run these at --budget 1 before '
        'believing them:');
    for (final pair in unreadable) {
      print('  $pair');
    }
  }
  print('tolerance $kTolerance points; sampling noise at ${options.games} '
      'games is roughly ${_noise(options.games)} points near an even result.');
}

/// The rating equivalent of one standard error on the score.
int _noise(int games) {
  final standardError = 0.5 / sqrt(games);
  return (impliedRatingDifference(0.5 + standardError)!).round();
}

String _signed(int value) => value > 0 ? '+$value' : '$value';

String _duration(Duration d) => d.inMinutes >= 1
    ? '${d.inMinutes}m ${d.inSeconds % 60}s'
    : '${d.inSeconds}s';

// ---------------------------------------------------------------------------
// Arguments
// ---------------------------------------------------------------------------

final class _Options {
  _Options({
    required this.games,
    required this.budgetScale,
    required this.seed,
    required this.only,
  });

  final int games;
  final double budgetScale;
  final int seed;
  final String? only;

  /// Null when the arguments do not parse — the caller prints usage.
  static _Options? parse(List<String> args) {
    var games = kDefaultGames;
    var budgetScale = kDefaultBudgetScale;
    var seed = 0;
    String? only;
    for (var i = 0; i < args.length; i += 2) {
      if (i + 1 >= args.length) return null;
      final value = args[i + 1];
      switch (args[i]) {
        case '--games':
          games = int.tryParse(value) ?? 0;
          if (games <= 0) return null;
        case '--budget':
          budgetScale = double.tryParse(value) ?? 0;
          if (budgetScale <= 0) return null;
        case '--seed':
          // Rejected rather than defaulted, like the two above it: a seed that
          // silently became 0 would make two runs the caller believes are
          // independent identical.
          final parsed = int.tryParse(value);
          if (parsed == null) return null;
          seed = parsed;
        case '--only':
          only = value;
        default:
          return null;
      }
    }
    return _Options(
      games: games,
      budgetScale: budgetScale,
      seed: seed,
      only: only,
    );
  }
}
