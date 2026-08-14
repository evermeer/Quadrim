import 'package:flutter_test/flutter_test.dart';
import 'package:quadrim/data/documents.dart';
import 'package:quadrim/data/home_summary.dart';
import 'package:quadrim_rating/quadrim_rating.dart';

/// A completed game, most of whose fields the summary never reads.
GameDocument _game({
  required String id,
  required String opponent,
  int? opponentRating,
  GameMode mode = GameMode.vsComputer,
  GameOutcome outcome = GameOutcome.win,
  int winnerSeat = 0,
  int playerSeat = 0,
}) {
  final at = DateTime.utc(2026, 1, 1);
  return GameDocument(
    id: id,
    mode: mode,
    opponent: opponent,
    opponentRating: opponentRating,
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
      winnerSeat: outcome == GameOutcome.draw ? null : winnerSeat,
      line: const [0, 1, 2, 3],
    ),
  );
}

void main() {
  group('overall statistics', () {
    test('no games leaves every total at zero and the rating at the seed', () {
      final summary = HomeSummary.empty;
      expect(summary.wins, 0);
      expect(summary.losses, 0);
      expect(summary.draws, 0);
      expect(summary.played, 0);
      expect(summary.byOpponent, isEmpty);
      expect(summary.computerRating, kSeedRating);
    });

    test('counts wins, losses and draws from the player\'s seat', () {
      final summary = HomeSummary.from([
        _game(id: 'a', opponent: 'bot:pebble', opponentRating: 600),
        _game(
            id: 'b',
            opponent: 'bot:pebble',
            opponentRating: 600,
            winnerSeat: 1),
        _game(
            id: 'c',
            opponent: 'bot:pebble',
            opponentRating: 600,
            outcome: GameOutcome.draw),
        // Same result, but the player sat in seat 1: a win, not a loss.
        _game(
            id: 'd',
            opponent: 'bot:pebble',
            opponentRating: 600,
            playerSeat: 1,
            winnerSeat: 1),
      ]);
      expect(summary.wins, 2);
      expect(summary.losses, 1);
      expect(summary.draws, 1);
      expect(summary.played, 4);
    });

    test('pass-and-play is excluded, because the player holds both seats', () {
      final summary = HomeSummary.from([
        _game(id: 'a', opponent: 'bot:pebble', opponentRating: 600),
        _game(id: 'b', opponent: kGuestOpponent, mode: GameMode.passAndPlay),
        _game(
            id: 'c',
            opponent: kGuestOpponent,
            mode: GameMode.passAndPlay,
            winnerSeat: 1),
      ]);
      expect(summary.played, 1, reason: 'only the game against Pebble counts');
      expect(summary.byOpponent.map((r) => r.opponent), ['bot:pebble']);
    });

    test('the totals equal the sum of the per-opponent records', () {
      final summary = HomeSummary.from([
        _game(id: 'a', opponent: 'bot:pebble', opponentRating: 600),
        _game(id: 'b', opponent: 'bot:kestrel', opponentRating: 1300),
        _game(
            id: 'c', opponent: 'bot:kestrel', opponentRating: 1300, winnerSeat: 1),
        _game(
            id: 'd',
            opponent: 'bot:marlin',
            opponentRating: 1400,
            outcome: GameOutcome.draw),
      ]);
      var wins = 0, losses = 0, draws = 0;
      for (final record in summary.byOpponent) {
        wins += record.wins;
        losses += record.losses;
        draws += record.draws;
      }
      expect(wins, summary.wins);
      expect(losses, summary.losses);
      expect(draws, summary.draws);
    });
  });

  group('per-opponent breakdown', () {
    test('one row per opponent, weakest first', () {
      final summary = HomeSummary.from([
        _game(id: 'a', opponent: 'bot:marlin', opponentRating: 1400),
        _game(id: 'b', opponent: 'bot:pebble', opponentRating: 600),
        _game(id: 'c', opponent: 'bot:kestrel', opponentRating: 1300),
        _game(id: 'd', opponent: 'bot:pebble', opponentRating: 600),
      ]);
      expect(summary.byOpponent.map((r) => r.opponent),
          ['bot:pebble', 'bot:kestrel', 'bot:marlin']);
      expect(summary.byOpponent.first.played, 2);
    });

    test('an opponent whose rating changed stays one row', () {
      // Recalibration (D144) moves an opponent's anchor. The player's history
      // against it must not split in two.
      final summary = HomeSummary.from([
        _game(id: 'a', opponent: 'bot:vireo', opponentRating: 1200),
        _game(id: 'b', opponent: 'bot:vireo', opponentRating: 1250),
      ]);
      expect(summary.byOpponent.length, 1);
      expect(summary.byOpponent.single.played, 2);
    });

    test('everBeaten is what a milestone will hang on', () {
      final summary = HomeSummary.from([
        _game(id: 'a', opponent: 'bot:pebble', opponentRating: 600),
        _game(
            id: 'b', opponent: 'bot:kestrel', opponentRating: 1300, winnerSeat: 1),
      ]);
      final byId = {for (final r in summary.byOpponent) r.opponent: r};
      expect(byId['bot:pebble']!.everBeaten, isTrue);
      expect(byId['bot:kestrel']!.everBeaten, isFalse);
    });

    test('an opponent with no stored rating sorts last, not first', () {
      // An unknown number is not a weak one.
      final summary = HomeSummary.from([
        _game(id: 'a', opponent: 'bot:mystery'),
        _game(id: 'b', opponent: 'bot:pebble', opponentRating: 600),
      ]);
      expect(summary.byOpponent.map((r) => r.opponent),
          ['bot:pebble', 'bot:mystery']);
    });
  });

  test('the computer rating is the same fold the result screen uses', () {
    final games = [
      _game(id: 'a', opponent: 'bot:pebble', opponentRating: 600),
      _game(id: 'b', opponent: 'bot:kestrel', opponentRating: 1300),
    ];
    expect(HomeSummary.from(games).computerRating, greaterThan(kSeedRating));
  });
}
