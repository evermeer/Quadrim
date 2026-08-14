import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrim/data/document_store.dart';
import 'package:quadrim/data/documents.dart';
import 'package:quadrim/data/local_game_repository.dart';
import 'package:quadrim/data/rating_fold.dart';
import 'package:quadrim/game/game_screen.dart';
import 'package:quadrim/l10n/app_localizations.dart';
import 'package:quadrim_engine/quadrim_engine.dart';
import 'package:quadrim_rating/quadrim_rating.dart';

/// Cells 0..3 are an x-axis line; 21, 22, 26 form no line.
const _winForOpener = [0, 21, 1, 22, 2, 26, 3];

Future<LocalGameRepository> _repository() async {
  final repository = await LocalGameRepository.open(MemoryDocumentStore());
  addTearDown(repository.dispose);
  return repository;
}

Widget _harness(LocalGameRepository repo, String id, {Locale? locale}) =>
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: GameScreen(
        repository: repo,
        gameId: id,
        random: Random(5),
        opponentMove: chooseMoveInline,
      ),
    );

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2280);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
}

void main() {
  group('rating fold', () {
    test('only rated games count, oldest first, against stored anchors',
        () async {
      final repo = await _repository();
      // A pass-and-play game must not touch the computer ladder.
      final social = await repo.createGame(
          mode: GameMode.passAndPlay, opponent: kGuestOpponent);
      await repo.resign(social.id, seat: 1);

      final vsBot = await repo.createGame(
        mode: GameMode.vsComputer,
        opponent: botOpponent(pebble.id),
        opponentRating: 600,
      );
      for (final cell in _winForOpener) {
        await repo.appendMove(vsBot.id, cell);
      }

      final completed = await repo.loadCompletedGames();
      final rated = ratedGamesFrom(completed);
      expect(rated.length, 1, reason: 'pass-and-play is not on this ladder');
      expect(rated.single.opponentRating, 600);
      expect(rated.single.score, 1);
      // Beating a 600 from the 800 seed is worth little, but not nothing:
      // the gap is 200 rather than the 600 it used to be (D226).
      expect(computerRating(completed), greaterThan(kSeedRating));
      // Less than half of K, which is what an even match would pay: the
      // opponent is below the player, so the win is worth less than a fair
      // one. It is 8 at this gap rather than the 1 it was from 1200.
      expect(computerRating(completed) - kSeedRating, lessThan(16));
      await repo.dispose();
    });

    test('a resignation folds as a loss for the resigning seat', () async {
      final repo = await _repository();
      final game = await repo.createGame(
        mode: GameMode.vsComputer,
        opponent: botOpponent(pebble.id),
        opponentRating: 600,
      );
      await repo.resign(game.id, seat: 0);

      final completed = await repo.loadCompletedGames();
      expect(ratedGamesFrom(completed).single.score, 0);
      expect(computerRating(completed), lessThan(kSeedRating));
      await repo.dispose();
    });
  });

  testWidgets('a won game shows the line, the result and the rating change',
      (tester) async {
    _phone(tester);
    final repo = await _repository();
    final game = await repo.createGame(
      mode: GameMode.vsComputer,
      opponent: botOpponent(pebble.id),
      opponentRating: 600,
    );
    for (final cell in _winForOpener) {
      await repo.appendMove(game.id, cell);
    }
    await tester.pumpWidget(_harness(repo, game.id));
    await tester.pumpAndSettle();

    expect(find.text('You win!'), findsOneWidget);
    // The winning line stays highlighted: the result sits below the board,
    // not over it.
    expect(find.byKey(const ValueKey('cell-0')), findsOneWidget);

    final after = computerRating(await repo.loadCompletedGames());
    expect(
      find.textContaining('Computer rating $after (+'),
      findsOneWidget,
      reason: 'the change must be signed and shown with the new total',
    );
    expect(
      find.text('Your rating against the computer, on this device only.'),
      findsOneWidget,
      reason: 'must not be mistakable for a universal rating',
    );
    expect(find.text('Rematch'), findsOneWidget);
  });

  testWidgets('a pass-and-play result says plainly that no rating changed',
      (tester) async {
    _phone(tester);
    final repo = await _repository();
    final game = await repo.createGame(
        mode: GameMode.passAndPlay, opponent: kGuestOpponent);
    for (final cell in _winForOpener) {
      await repo.appendMove(game.id, cell);
    }
    await tester.pumpWidget(_harness(repo, game.id));
    await tester.pumpAndSettle();

    expect(find.text('Light wins!'), findsOneWidget);
    expect(find.text('No rating changes in pass and play.'), findsOneWidget);
    expect(find.textContaining('Computer rating'), findsNothing);
  });

  testWidgets('a rematch alternates the start and records what it followed',
      (tester) async {
    _phone(tester);
    final repo = await _repository();
    final first = await repo.createGame(
      mode: GameMode.vsComputer,
      opponent: botOpponent(pebble.id),
      opponentRating: 600,
      startingSeat: 0,
    );
    for (final cell in _winForOpener) {
      await repo.appendMove(first.id, cell);
    }
    await tester.pumpWidget(_harness(repo, first.id));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rematch'));
    await tester.pump(kBotMoveDelay);
    await tester.pumpAndSettle();

    final active = await repo.watchActiveGames().first;
    expect(active.length, 1);
    expect(active.single.startingSeat, 1,
        reason: 'the player who did not start last time starts this time');
    expect(active.single.rematchOf, first.id);
    expect(active.single.startReason, StartReason.rematchAlternation);
    expect(active.single.opponent, first.opponent);
  });

  testWidgets('the game says who moves first and why', (tester) async {
    _phone(tester);
    final repo = await _repository();
    final random = await repo.createGame(
      mode: GameMode.vsComputer,
      opponent: botOpponent(pebble.id),
      opponentRating: 600,
      startingSeat: 0,
    );
    await tester.pumpWidget(_harness(repo, random.id));
    await tester.pumpAndSettle();
    expect(find.text('Opening move: You — chosen at random'), findsOneWidget);

    final rematch = await repo.createGame(
      mode: GameMode.vsComputer,
      opponent: botOpponent(pebble.id),
      opponentRating: 600,
      startingSeat: 1,
      startReason: StartReason.rematchAlternation,
      rematchOf: random.id,
    );
    await tester.pumpWidget(_harness(repo, rematch.id));
    await tester.pump(kBotMoveDelay);
    await tester.pumpAndSettle();
    expect(
      find.text('Opening move: Pebble — the start alternates in a rematch'),
      findsOneWidget,
    );
  });

  testWidgets('resigning requires confirmation and ends the game as a loss',
      (tester) async {
    _phone(tester);
    final repo = await _repository();
    final game = await repo.createGame(
      mode: GameMode.vsComputer,
      opponent: botOpponent(pebble.id),
      opponentRating: 600,
    );
    await tester.pumpWidget(_harness(repo, game.id));
    await tester.pumpAndSettle();

    // Cancelling leaves the game running.
    await tester.tap(find.text('Resign'));
    await tester.pumpAndSettle();
    expect(find.text('Resign this game?'), findsOneWidget);
    expect(find.textContaining('There is no draw offer'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect((await repo.watchGame(game.id).first)!.status, GameStatus.active);

    // Confirming ends it as a loss, with its own reason.
    await tester.tap(find.text('Resign'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Resign'));
    await tester.pumpAndSettle();

    final done = (await repo.watchGame(game.id).first)!;
    expect(done.status, GameStatus.complete);
    expect(done.result!.reason, GameEndReason.resignation);
    expect(done.result!.winnerSeat, 1);
    expect(find.text('Pebble wins!'), findsOneWidget,
        reason: 'a resigned game is over even though the board is playable');
  });

  testWidgets('there is no draw offer anywhere on the screen', (tester) async {
    _phone(tester);
    final repo = await _repository();
    final game = await repo.createGame(
        mode: GameMode.passAndPlay, opponent: kGuestOpponent);
    await tester.pumpWidget(_harness(repo, game.id));
    await tester.pumpAndSettle();

    expect(find.textContaining('draw'), findsNothing);
    expect(find.textContaining('Draw'), findsNothing);
  });

  testWidgets('the result reaches a screen reader', (tester) async {
    _phone(tester);
    final semantics = tester.ensureSemantics();
    final repo = await _repository();
    final game = await repo.createGame(
        mode: GameMode.passAndPlay, opponent: kGuestOpponent);
    for (final cell in _winForOpener) {
      await repo.appendMove(game.id, cell);
    }
    await tester.pumpWidget(_harness(repo, game.id));
    await tester.pumpAndSettle();

    // The banner is a live region, so its text change is announced.
    final banner = tester.getSemantics(find.text('Light wins!'));
    expect(banner.label, 'Light wins!');
    expect(banner.flagsCollection.isLiveRegion, isTrue);
    semantics.dispose();
  });

  testWidgets('result strings are localized', (tester) async {
    _phone(tester);
    final repo = await _repository();
    final game = await repo.createGame(
      mode: GameMode.vsComputer,
      opponent: botOpponent(pebble.id),
      opponentRating: 600,
    );
    for (final cell in _winForOpener) {
      await repo.appendMove(game.id, cell);
    }
    await tester.pumpWidget(
        _harness(repo, game.id, locale: const Locale('nl')));
    await tester.pumpAndSettle();

    expect(find.text('Je wint!'), findsOneWidget);
    expect(find.text('Revanche'), findsOneWidget);
    expect(
      find.text('Je rating tegen de computer, alleen op dit toestel.'),
      findsOneWidget,
    );
  });
}
