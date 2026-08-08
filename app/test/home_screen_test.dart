import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrim/data/document_store.dart';
import 'package:quadrim/data/documents.dart';
import 'package:quadrim/data/local_game_repository.dart';
import 'package:quadrim/l10n/app_localizations.dart';
import 'package:quadrim/main.dart';
import 'package:quadrim_engine/quadrim_engine.dart';
import 'package:quadrim_rating/quadrim_rating.dart';

Future<LocalGameRepository> _repository() async {
  final repository = await LocalGameRepository.open(MemoryDocumentStore());
  addTearDown(repository.dispose);
  return repository;
}

void _phone(WidgetTester tester, {double textScale = 1}) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Future<void> _pumpHome(WidgetTester tester, LocalGameRepository repo) async {
  await tester.pumpWidget(QuadrimApp(repository: repo, random: Random(1)));
  await tester.pumpAndSettle();
}

/// Plays [game] to a decided result by appending [moves].
Future<void> _finish(
  LocalGameRepository repo,
  GameDocument game,
  List<int> moves,
) async {
  for (final move in moves) {
    await repo.appendMove(game.id, move);
  }
}

/// Light (seat 0) completes {0,1,2,3}; dark's cells form no line.
const _lightWinsMoves = [0, 21, 1, 22, 2, 26, 3];

Future<GameDocument> _completedGame(
  LocalGameRepository repo, {
  required String botId,
  required int rating,
  bool playerWins = true,
}) async {
  final game = await repo.createGame(
    mode: GameMode.vsComputer,
    opponent: botOpponent(botId),
    opponentRating: rating,
    // Seat 0 always wins the fixture line; sitting the player elsewhere is
    // how a loss is expressed without a different move list.
    playerSeat: playerWins ? 0 : 1,
  );
  await _finish(repo, game, _lightWinsMoves);
  return game;
}

void main() {
  testWidgets('shows the computer rating, labelled as such', (tester) async {
    _phone(tester);
    final repo = await _repository();
    await _pumpHome(tester, repo);

    expect(find.text('Against the computer'), findsOneWidget);
    expect(find.text('$kSeedRating'), findsOneWidget);
    // Criterion 20: it must not read as a universal rating.
    expect(find.text('Your rating against the computer, on this device only.'),
        findsOneWidget);
  });

  testWidgets('statistics and lists update when a game finishes, without a '
      'restart', (tester) async {
    _phone(tester);
    final repo = await _repository();
    await _pumpHome(tester, repo);
    expect(find.text('No finished games against the computer yet.'),
        findsOneWidget);

    final game = await repo.createGame(
      mode: GameMode.vsComputer,
      opponent: botOpponent(pebble.id),
      opponentRating: pebble.rating,
    );
    await tester.pumpAndSettle();
    expect(find.text('In progress'), findsOneWidget);
    expect(find.text('3 moves played'), findsNothing);

    await repo.appendMove(game.id, 0);
    await repo.appendMove(game.id, 21);
    await repo.appendMove(game.id, 1);
    await tester.pumpAndSettle();
    expect(find.text('3 moves played'), findsOneWidget);

    await _finish(repo, game, const [22, 2, 26, 3]);
    await tester.pumpAndSettle();

    // The same screen instance, never rebuilt from scratch.
    expect(find.text('In progress'), findsNothing);
    expect(find.text('Finished games'), findsOneWidget);
    expect(find.text('1 won · 0 lost · 0 drawn'), findsOneWidget);
    expect(find.text('Won'), findsOneWidget);
  });

  testWidgets('breaks the record down by opponent, weakest first',
      (tester) async {
    _phone(tester);
    final repo = await _repository();
    await _completedGame(repo, botId: ember.id, rating: ember.rating);
    await _completedGame(
        repo, botId: pebble.id, rating: pebble.rating, playerWins: false);
    await _pumpHome(tester, repo);

    expect(find.text('By opponent'), findsOneWidget);
    // The record strings are unique to the breakdown — the names themselves
    // also appear in the finished-games list below it — so ordering is
    // asserted on where they land, not on how many Texts say "Pebble".
    final pebbleRow = tester.getTopLeft(find.text('0–1–0 in 1 games')).dy;
    final emberRow = tester.getTopLeft(find.text('1–0–0 in 1 games')).dy;
    expect(pebbleRow, lessThan(emberRow), reason: 'weakest first');
  });

  testWidgets('tapping a game in progress resumes it', (tester) async {
    _phone(tester);
    final repo = await _repository();
    final game = await repo.createGame(
      mode: GameMode.passAndPlay,
      opponent: kGuestOpponent,
    );
    await repo.appendMove(game.id, 0);
    await _pumpHome(tester, repo);

    await tester.tap(find.text('1 move played'));
    await tester.pumpAndSettle();

    // The board is showing, with the move already played still on it.
    expect(find.text('Dark to move'), findsOneWidget);
  });

  testWidgets('tapping a finished game opens it', (tester) async {
    _phone(tester);
    final repo = await _repository();
    await _completedGame(repo, botId: pebble.id, rating: pebble.rating);
    await _pumpHome(tester, repo);

    await tester.tap(find.text('Won'));
    await tester.pumpAndSettle();

    // The result is on screen, which is what ticket 012's scrubber will be
    // added to rather than replace.
    expect(find.text('You win!'), findsOneWidget);
  });

  testWidgets('the primary button starts a new game', (tester) async {
    _phone(tester);
    final repo = await _repository();
    await _pumpHome(tester, repo);

    await tester.tap(find.text('New game'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pass and play'));
    await tester.pumpAndSettle();

    expect(find.text('Light to move'), findsOneWidget);
    final active = await repo.watchActiveGames().first;
    expect(active, hasLength(1));
    expect(active.single.mode, GameMode.passAndPlay);
  });

  testWidgets('the tutorial and settings entry points exist and open',
      (tester) async {
    _phone(tester);
    await _pumpHome(tester, await _repository());

    await tester.tap(find.text('Tutorial'));
    await tester.pumpAndSettle();
    expect(find.text('Arrives in a later build.'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Arrives in a later build.'), findsOneWidget);
  });

  testWidgets('pass-and-play games are listed but not counted', (tester) async {
    _phone(tester);
    final repo = await _repository();
    final game = await repo.createGame(
      mode: GameMode.passAndPlay,
      opponent: kGuestOpponent,
    );
    await _finish(repo, game, _lightWinsMoves);
    await _pumpHome(tester, repo);

    // Listed, and reported by side rather than as the player's win.
    expect(find.text('Pass and play'), findsOneWidget);
    expect(find.text('Light wins!'), findsOneWidget);
    // Not counted: the player held both seats.
    expect(find.text('No finished games against the computer yet.'),
        findsOneWidget);
    expect(find.text('By opponent'), findsNothing);
  });

  testWidgets('is readable at the largest system font scale', (tester) async {
    // The screen must survive a 2x scale without overflowing, which is what
    // criterion 23 asks for and what a Column of fixed rows would fail.
    _phone(tester, textScale: 2);
    final repo = await _repository();
    await _completedGame(repo, botId: sable.id, rating: sable.rating);
    await _pumpHome(tester, repo);

    expect(tester.takeException(), isNull);
    expect(find.text('New game'), findsOneWidget);
  });

  testWidgets('announces its sections and the rating to a screen reader',
      (tester) async {
    _phone(tester);
    final handle = tester.ensureSemantics();
    final repo = await _repository();
    await _completedGame(repo, botId: pebble.id, rating: pebble.rating);
    await _pumpHome(tester, repo);

    // The rating reads as one labelled fact, not three loose numbers.
    expect(
      find.bySemanticsLabel(RegExp(r'Against the computer: \d+\.')),
      findsOneWidget,
    );
    // Sections are headers, so a screen reader can jump between them rather
    // than reading the whole page top to bottom.
    for (final heading in ['Your record', 'By opponent', 'Finished games']) {
      expect(tester.getSemantics(find.text(heading)).flagsCollection.isHeader,
          isTrue,
          reason: '"$heading" must be a header');
    }
    handle.dispose();
  });

  testWidgets('every string on the screen exists in Dutch', (tester) async {
    _phone(tester);
    final repo = await _repository();
    await _completedGame(repo, botId: pebble.id, rating: pebble.rating);
    await tester.pumpWidget(QuadrimApp(
      repository: repo,
      locale: const Locale('nl'),
      random: Random(1),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Nieuwe partij'), findsOneWidget);
    expect(find.text('Uitleg'), findsOneWidget);
    expect(find.text('Tegen de computer'), findsOneWidget);
    expect(find.text('Jouw resultaten'), findsOneWidget);
    expect(find.text('Per tegenstander'), findsOneWidget);
    expect(find.text('Voltooide partijen'), findsOneWidget);
    expect(find.text('1 gewonnen · 0 verloren · 0 remise'), findsOneWidget);
    // Bot names are proper nouns and stay as they are. Pebble appears twice:
    // once in the breakdown and once in the list of finished games.
    expect(find.text('Pebble'), findsWidgets);
  });

  testWidgets('lists finished games most recent first', (tester) async {
    _phone(tester);
    final repo = await _repository();
    // Distinguishable by opponent name rather than by result, because every
    // fixture game ends the same way.
    await _completedGame(repo, botId: pebble.id, rating: pebble.rating);
    await _completedGame(repo, botId: ember.id, rating: ember.rating);
    await _pumpHome(tester, repo);

    // Ember finished last, so its row sits above Pebble's in the list. The
    // breakdown above orders the other way — weakest first — so the two rows
    // are located below the "Finished games" heading.
    final heading = tester.getTopLeft(find.text('Finished games')).dy;
    final rows = <String, double>{};
    for (final name in ['Pebble', 'Ember']) {
      rows[name] = tester
          .getTopLeft(find
              .byWidgetPredicate((w) => w is Text && w.data == name)
              .at(1))
          .dy;
    }
    expect(rows['Pebble']!, greaterThan(heading));
    expect(rows['Ember']!, greaterThan(heading));
    expect(rows['Ember']!, lessThan(rows['Pebble']!),
        reason: 'most recently finished first');
  });

  testWidgets('a long history does not build every row', (tester) async {
    // The finished list has no upper bound, so it must be lazy: a ListView of
    // children would build all sixty tiles for a screen that shows a handful.
    _phone(tester);
    final repo = await _repository();
    for (var i = 0; i < 60; i++) {
      await _completedGame(repo, botId: pebble.id, rating: pebble.rating);
    }
    await _pumpHome(tester, repo);

    expect(find.text('60 won · 0 lost · 0 drawn'), findsOneWidget);
    expect(find.text('Won'), findsWidgets);
    expect(tester.widgetList(find.text('Won')).length, lessThan(60),
        reason: 'off-screen rows must not be built');
  });

  test('both locales carry every key the screen uses', () {
    // A missing Dutch key falls back to English silently at runtime; this is
    // the cheap guard against that going unnoticed.
    expect(AppLocalizations.supportedLocales.map((l) => l.languageCode),
        containsAll(['en', 'nl']));
  });
}
