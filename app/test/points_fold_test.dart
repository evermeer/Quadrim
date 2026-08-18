import 'package:flutter_test/flutter_test.dart';
import 'package:quadrim/data/documents.dart';
import 'package:quadrim/data/home_summary.dart';
import 'package:quadrim/data/points_fold.dart';
import 'package:quadrim_engine/quadrim_engine.dart';
import 'package:quadrim_progression/quadrim_progression.dart';

/// The package's arithmetic is proven exhaustively in
/// `packages/quadrim_progression/test/points_test.dart`. What is proven here is
/// the mapping — which stored games reach it at all, and with what index.

GameDocument _game({
  required String id,
  required String opponent,
  GameMode mode = GameMode.vsComputer,
  bool drawn = false,
  bool playerWon = true,
  int playerSeat = 0,
  int minute = 0,
}) {
  final outcome = drawn ? GameOutcome.draw : GameOutcome.win;
  final at = DateTime.utc(2026, 1, 1, 12, minute);
  return GameDocument(
    id: id,
    mode: mode,
    opponent: opponent,
    opponentRating: 1000,
    playerSeat: playerSeat,
    startingSeat: 0,
    startReason: StartReason.random,
    moves: const [0, 1, 2],
    status: GameStatus.complete,
    createdAt: at,
    updatedAt: at,
    completedAt: at,
    result: GameResult(
      outcome: outcome,
      reason: GameEndReason.line,
      winnerSeat:
          outcome == GameOutcome.draw ? null : (playerWon ? playerSeat : 1 - playerSeat),
      line: const [0, 1, 2, 3],
    ),
  );
}

String _idAt(int index) => opponentCatalogue[index].id;

void main() {
  test('no games earns nothing', () {
    expect(pointsFrom(const []), 0);
  });

  test('a win pays 2^i for the opponent it was against', () {
    for (var i = 0; i < opponentCatalogue.length; i++) {
      final game = _game(id: 'g$i', opponent: botOpponent(_idAt(i)));
      expect(pointsFrom([game]), 1 << i, reason: _idAt(i));
    }
  });

  test('a loss and a draw pay nothing', () {
    expect(
      pointsFrom([
        _game(id: 'a', opponent: botOpponent(_idAt(9)), playerWon: false),
        _game(id: 'b', opponent: botOpponent(_idAt(9)), drawn: true),
      ]),
      0,
    );
  });

  test('the win is judged from the player seat, not from seat zero', () {
    // A player sitting in seat 1 who wins is a `winnerSeat: 1` result. Reading
    // seat zero would score every such game as a loss and silently halve the
    // points of anyone who plays second — and which seat the player holds
    // alternates on rematch (§3.1), so it would be about half of them.
    final game = _game(
        id: 'seat1', opponent: botOpponent(_idAt(4)), playerSeat: 1);
    expect(pointsFrom([game]), winValue(4));
  });

  test('pass-and-play pays nothing, because the player holds both seats', () {
    final game = _game(
        id: 'pnp', opponent: kGuestOpponent, mode: GameMode.passAndPlay);
    expect(pointsFrom([game]), 0);
  });

  test('an opponent this build does not know pays nothing rather than throwing',
      () {
    final game = _game(id: 'ghost', opponent: botOpponent('deleted_bot'));
    expect(pointsFrom([game]), 0);
  });

  test('an unfinished game pays nothing', () {
    final at = DateTime.utc(2026, 1, 1, 12);
    final active = GameDocument(
      id: 'active',
      mode: GameMode.vsComputer,
      opponent: botOpponent(_idAt(9)),
      opponentRating: 1400,
      playerSeat: 0,
      startingSeat: 0,
      startReason: StartReason.random,
      moves: const [0, 1],
      status: GameStatus.active,
      createdAt: at,
      updatedAt: at,
    );
    expect(pointsFrom([active]), 0);
  });

  test('four wins against Bramble is exactly what Juniper costs', () {
    // Bramble is index 6 since the recut and Juniper 7 (D325). The claim is
    // the invariant, not the pair: four wins at any rung buys the next one.
    final games = [
      for (var i = 0; i < 4; i++)
        _game(id: 'w$i', opponent: botOpponent('bramble'), minute: i),
    ];
    expect(pointsFrom(games), unlockCost(7));
  });

  test('folding the same games twice gives the same answer, in any order', () {
    final games = [
      for (var i = 0; i < opponentCatalogue.length; i++)
        _game(
            id: 'g$i',
            opponent: botOpponent(_idAt(i)),
            playerWon: i.isEven,
            minute: i),
    ];
    expect(pointsFrom(games), pointsFrom(games));
    expect(pointsFrom(games), pointsFrom(games.reversed.toList()));
  });

  test('the summary folds points from the same list as everything else', () {
    final games = [
      _game(id: 'a', opponent: botOpponent('bramble')),
      _game(id: 'b', opponent: botOpponent('pebble'), minute: 1),
      _game(
          id: 'c',
          opponent: botOpponent('bramble'),
          playerWon: false,
          minute: 2),
    ];
    final summary = HomeSummary.from(games);
    expect(summary.points, winValue(6) + winValue(0));
    expect(summary.wins, 2);
    expect(summary.losses, 1);
  });

  test('the empty summary has no points', () {
    expect(HomeSummary.empty.points, 0);
  });
}
