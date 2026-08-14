import 'package:flutter_test/flutter_test.dart';
import 'package:quadrim/data/documents.dart';
import 'package:quadrim/data/rating_fold.dart';
import 'package:quadrim_engine/quadrim_engine.dart';
import 'package:quadrim_rating/quadrim_rating.dart';

/// One completed game, as the fold receives it.
///
/// [completedAt] carries minutes rather than a fixed instant because the
/// ordering the fold depends on is by completion time — a fixture where every
/// game finished at once could not tell a correct fold from a lucky one.
GameDocument _game({
  required String id,
  required int opponentRating,
  GameMode mode = GameMode.vsComputer,
  bool drawn = false,
  bool playerWon = true,
  int playerSeat = 0,
  int minute = 0,
}) {
  // A loss is a win for the other seat — GameOutcome has no `loss`, because
  // which seat won is the fact and whose loss that is depends on where the
  // player was sitting.
  final outcome = drawn ? GameOutcome.draw : GameOutcome.win;
  final winnerSeat = playerWon ? playerSeat : 1 - playerSeat;
  final at = DateTime.utc(2026, 1, 1, 12, minute);
  return GameDocument(
    id: id,
    mode: mode,
    opponent: 'bot:whoever',
    opponentRating: mode == GameMode.vsComputer ? opponentRating : null,
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

/// The order `loadCompletedGames` delivers: most recent first.
List<GameDocument> _newestFirst(List<GameDocument> games) =>
    games.reversed.toList();

void main() {
  group('the computer rating', () {
    test('a player with no history sits on the seed', () {
      expect(computerRating(const []), kSeedRating);
      expect(computerRating(const []), kSeedRating);
    });

    test('is the same answer every time it is computed', () {
      // Criterion: computing it twice over the same games agrees. The fold is
      // pure, so the risk is not arithmetic drift but an accidental dependence
      // on iteration order or on a mutable input — hence the same list twice,
      // then a fresh list of equal documents.
      final games = _newestFirst([
        for (var i = 0; i < 12; i++)
          _game(
            id: 'g$i',
            opponentRating: 900 + i * 50,
            playerWon: i.isEven,
            minute: i,
          ),
      ]);
      final once = computerRating(games);
      expect(computerRating(games), once);
      expect(computerRating(List.of(games)), once);
      expect(once, isNot(kSeedRating), reason: 'the fixture must move it');
    });

    test('folds against the anchor stored on the game, not the catalogue', () {
      // The whole point of storing the anchor (spec §8.3): recalibrating an
      // opponent must be a deliberate re-fold, never a silent rewrite of a
      // rating the player was already shown. A stored 2400 against an opponent
      // the catalogue now rates 600 must still pay like a 2400.
      final asStored = computerRating(_newestFirst([
        _game(id: 'a', opponentRating: 2400),
      ]));
      final asWeak = computerRating(_newestFirst([
        _game(id: 'a', opponentRating: pebble.rating),
      ]));
      expect(asStored, greaterThan(asWeak));
      // And it is exactly what the rating package makes of that anchor, with
      // no catalogue lookup anywhere in between.
      expect(asStored,
          ratingFrom(const [RatedGame(opponentRating: 2400, score: 1)]));
    });

    test('K is 32 for the first twenty games on this ladder and 16 after', () {
      // Measured as a step rather than asserted from the constant: the
      // twenty-first win against the same opponent from the same rating must
      // move the rating by about half what the twentieth did.
      List<GameDocument> wins(int n) => _newestFirst([
            for (var i = 0; i < n; i++)
              _game(id: 'w$i', opponentRating: 2000, minute: i),
          ]);
      final at19 = computerRating(wins(19));
      final at20 = computerRating(wins(20));
      final at21 = computerRating(wins(21));
      final provisional = at20 - at19;
      final settled = at21 - at20;
      expect(provisional, greaterThan(settled),
          reason: 'the twentieth game is still provisional');
      expect(settled, closeTo(provisional / 2, 2),
          reason: 'K halves from 32 to 16: $provisional then $settled');
    });

    test('a draw scores half: between a win and a loss, and not either', () {
      final drawn = computerRating(_newestFirst([
        _game(id: 'a', opponentRating: 2000, drawn: true),
      ]));
      final won = computerRating(_newestFirst([
        _game(id: 'a', opponentRating: 2000),
      ]));
      final lost = computerRating(_newestFirst([
        _game(id: 'a', opponentRating: 2000, playerWon: false),
      ]));
      expect(drawn, lessThan(won));
      expect(drawn, greaterThan(lost));
      // Against someone far stronger a draw is worth points, not merely fewer
      // losses — which is the half-score doing its job.
      expect(drawn, greaterThan(kSeedRating));
    });

    test('never falls below the floor, however long the losing run', () {
      final battered = computerRating(_newestFirst([
        for (var i = 0; i < 300; i++)
          _game(id: 'l$i', opponentRating: 600, playerWon: false, minute: i),
      ]));
      expect(battered, kRatingFloor);
      expect(battered, 100);
    });

    test('reads the result from the player\'s seat, not from seat zero', () {
      // Playing dark is a seat, not a handicap. A game the player won from
      // seat 1 must pay exactly as one won from seat 0.
      final asLight = computerRating(_newestFirst([
        _game(id: 'a', opponentRating: 1500),
      ]));
      final asDark = computerRating(_newestFirst([
        _game(id: 'a', opponentRating: 1500, playerSeat: 1),
      ]));
      expect(asDark, asLight);
    });

    test('ignores pass-and-play, and games with no anchor', () {
      final ladderOnly = computerRating(_newestFirst([
        _game(id: 'a', opponentRating: 1500),
      ]));
      final withNoise = computerRating(_newestFirst([
        _game(id: 'a', opponentRating: 1500),
        _game(id: 'p', opponentRating: 0, mode: GameMode.passAndPlay,
            minute: 1),
      ]));
      expect(withNoise, ladderOnly,
          reason: 'a pass-and-play game is not on this ladder');
    });

    test('folds oldest first, so the order it is given decides the answer',
        () {
      // The fold reverses its input rather than sorting it, which is correct
      // only because `loadCompletedGames` delivers newest-first by completedAt
      // with the id as tie-break. That contract is pinned in
      // repository_test.dart; what is pinned here is that the fold *depends*
      // on it — a fold that ignored order would pass with either fixture.
      final oldLossNewWin = _newestFirst([
        _game(id: 'first', opponentRating: 600, playerWon: false, minute: 1),
        _game(id: 'second', opponentRating: 2000, minute: 5),
      ]);

      expect(
        computerRating(oldLossNewWin),
        ratingFrom(const [
          RatedGame(opponentRating: 600, score: 0),
          RatedGame(opponentRating: 2000, score: 1),
        ]),
      );

      // A control, because the assertion above would also pass on a fold that
      // ignored order entirely. It needs a fixture where order genuinely
      // changes the answer, and the two games above are not one: reversed they
      // also give 1201, because a loss to 600 and a win over 2000 very nearly
      // cancel whichever way round they fall. What does not cancel is the K
      // change — twenty-one games put one result on the far side of it, and
      // which result that is depends on the order.
      final lossThenWins = [
        for (var i = 0; i < 20; i++)
          _game(id: 'w$i', opponentRating: 2400, minute: i + 1),
        _game(id: 'l', opponentRating: 600, playerWon: false, minute: 0),
      ];
      final winsThenLoss = [
        _game(id: 'l', opponentRating: 600, playerWon: false, minute: 21),
        for (var i = 0; i < 20; i++)
          _game(id: 'w$i', opponentRating: 2400, minute: i + 1),
      ];
      expect(computerRating(winsThenLoss),
          isNot(computerRating(lossThenWins)));
    });
  });

  group('the change every game caused', () {
    test('sums to the rating the whole fold arrives at', () {
      // The invariant the finished-games list leans on: what the rows add up
      // to has to be what the card at the top of the screen says.
      final games = _newestFirst([
        for (var i = 0; i < 25; i++)
          _game(
            id: 'g$i',
            opponentRating: 700 + (i % 6) * 250,
            playerWon: i % 3 != 1,
            drawn: i % 7 == 0,
            minute: i,
          ),
      ]);
      final total =
          ratingDeltas(games).values.fold(0, (a, b) => a + b);
      expect(kSeedRating + total, computerRating(games));
    });

    test('agrees with the single-game fold, game for game', () {
      // computerRatingAround re-folds the prefix for one game and is what the
      // result screen uses; these two are the same fact on two screens.
      final games = _newestFirst([
        for (var i = 0; i < 8; i++)
          _game(id: 'g$i', opponentRating: 1000 + i * 100,
              playerWon: i.isEven, minute: i),
      ]);
      final deltas = ratingDeltas(games);
      for (final game in games) {
        final around = computerRatingAround(games, game.id);
        expect(deltas[game.id], around.after - around.before,
            reason: game.id);
      }
    });

    test('leaves out games that are not on this ladder', () {
      // Absent, not zero: a caller drawing an arrow has to tell "no change"
      // from "no rating", and pass-and-play is the second.
      final games = _newestFirst([
        _game(id: 'ladder', opponentRating: 1500),
        _game(id: 'guest', opponentRating: 0, mode: GameMode.passAndPlay,
            minute: 1),
      ]);
      final deltas = ratingDeltas(games);
      expect(deltas.keys, ['ladder']);
      expect(deltas.containsKey('guest'), isFalse);
    });

    test('a win pays and a loss costs, in the order they were played', () {
      final games = _newestFirst([
        _game(id: 'won', opponentRating: 1500, minute: 1),
        _game(id: 'lost', opponentRating: 1500, playerWon: false, minute: 2),
      ]);
      final deltas = ratingDeltas(games);
      expect(deltas['won']!, greaterThan(0));
      expect(deltas['lost']!, lessThan(0));
    });
  });

  group('the change one game caused', () {
    test('is the step that game made, not the step the newest game made', () {
      final games = _newestFirst([
        _game(id: 'a', opponentRating: 1500, minute: 1),
        _game(id: 'b', opponentRating: 1500, minute: 2),
        _game(id: 'c', opponentRating: 1500, minute: 3),
      ]);
      final middle = computerRatingAround(games, 'b');
      expect(middle.before, computerRating(_newestFirst([
        _game(id: 'a', opponentRating: 1500, minute: 1),
      ])));
      expect(middle.after, computerRating(_newestFirst([
        _game(id: 'a', opponentRating: 1500, minute: 1),
        _game(id: 'b', opponentRating: 1500, minute: 2),
      ])));
      // And it is genuinely not the last game's step, or this test would pass
      // on an implementation that always folded the whole history.
      expect(middle.after, isNot(computerRating(games)));
    });

    test('a game not on this ladder reports no change at all', () {
      final games = _newestFirst([_game(id: 'a', opponentRating: 1500)]);
      final absent = computerRatingAround(games, 'nonexistent');
      expect(absent.before, kSeedRating);
      expect(absent.after, kSeedRating);
    });
  });
}
