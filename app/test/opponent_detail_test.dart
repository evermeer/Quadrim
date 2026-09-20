import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrim/data/document_store.dart';
import 'package:quadrim/data/documents.dart';
import 'package:quadrim/data/local_game_repository.dart';
import 'package:quadrim/home/home_screen.dart';
import 'package:quadrim/home/opponent_detail.dart';
import 'package:quadrim/home/your_path.dart';
import 'package:quadrim/l10n/app_localizations.dart';
import 'package:quadrim_engine/quadrim_engine.dart';
import 'package:quadrim_rating/quadrim_rating.dart';
import 'plaques.dart';

/// Ticket 037: the row scrolls and rests on the rating, and every opponent has
/// a page.

const _lightWinsMoves = [0, 21, 1, 22, 2, 26, 3];

Future<LocalGameRepository> _repository() async {
  var tick = DateTime(2026, 8, 14, 12);
  final repo = await LocalGameRepository.open(MemoryDocumentStore(),
      now: () => tick = tick.add(const Duration(seconds: 1)));
  addTearDown(repo.dispose);
  await repo.saveSettings(const SettingsDocument(tutorialOffered: true));
  return repo;
}

Future<void> _play(LocalGameRepository repo,
    {String botId = 'pebble', bool won = true}) async {
  final game = await repo.createGame(
    mode: GameMode.vsComputer,
    opponent: botOpponent(botId),
    opponentRating: botById(botId)!.rating,
    startingSeat: 0,
    playerSeat: won ? 0 : 1,
  );
  for (final move in _lightWinsMoves) {
    await repo.appendMove(game.id, move);
  }
}

void _phone(WidgetTester tester, {double textScale = 1}) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Widget _home(LocalGameRepository repo, {Locale? locale}) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: HomeScreen(
        repository: repo,
        settings: repo,
        unlocks: repo,
        random: Random(1),
        now: () => DateTime(2026, 8, 14, 12),
      ),
    );

/// The horizontal roster row is the second scrollable on the screen; the first
/// is the main vertical one.
Future<void> _scrollTo(WidgetTester tester, String name) async {
  await tester.ensureVisible(tileFor(name));
  await tester.pumpAndSettle();
}

/// [name]'s tile, scoped to the row. An opponent's name also appears on every
/// game row against them, so a bare text finder is ambiguous the moment the
/// player has played anyone twice.
Finder tileFor(String name) =>
    find.descendant(of: find.byType(YourPath), matching: find.text(name));

void main() {
  group('where the row rests', () {
    test('is the lowest-rated opponent rated strictly above the player', () {
      // Mote is rated exactly 800 and a player seeded at 800 rests on Hazel:
      // an even match is not "next" (D287). Hazel is 850, which the recut put
      // between Mote and Clover (D333).
      expect(kSeedRating, 800);
      expect(opponentCatalogue[restingIndex(800)].id, 'hazel');
      expect(opponentCatalogue[restingIndex(799)].id, 'mote');
      expect(opponentCatalogue[restingIndex(900)].id, 'sorrel');
    });

    test('a player below the whole roster rests at the first opponent', () {
      expect(restingIndex(0), 0);
      expect(restingIndex(599), 0);
    });

    test('a player above the whole roster rests at the last', () {
      final top = opponentCatalogue.last.rating;
      expect(restingIndex(top), opponentCatalogue.length - 1);
      expect(restingIndex(top + 500), opponentCatalogue.length - 1);
    });

    test('every rating in range lands on an opponent that really is above it, '
        'and on the lowest such', () {
      for (var rating = 500; rating <= 2500; rating += 25) {
        final i = restingIndex(rating);
        final bot = opponentCatalogue[i];
        if (bot.rating <= rating) {
          // Only legitimate at the very top, where nobody is above.
          expect(i, opponentCatalogue.length - 1, reason: 'rating $rating');
          continue;
        }
        for (var j = 0; j < i; j++) {
          expect(opponentCatalogue[j].rating, lessThanOrEqualTo(rating),
              reason: 'rating $rating skipped ${opponentCatalogue[j].id}');
        }
      }
    });
  });

  group('the row', () {
    testWidgets('rests on Clover for a fresh player and scrolls both ways',
        (tester) async {
      _phone(tester);
      final repo = await _repository();
      await tester.pumpWidget(_home(repo));
      await tester.pumpAndSettle();

      // Hazel rather than Mote at the weak end: the row does not show the mercy
      // rungs to a player who has not earned them back (D382).
      for (final name in ['Hazel', 'Clover', 'Bramble']) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
      // Left, to the weakest the row shows. Since D382 that is Hazel: Pebble,
      // Twig and Mote are held back from a new player, and a row that showed
      // them locked would print a price no amount of points can pay.
      await _scrollTo(tester, 'Hazel');
      expect(tileFor('Hazel'), findsOneWidget);
      // And right, all the way to the top of the ladder. The tile writes the
      // strongest opponent short — "Quadrim Prime" ellipsises to nonsense at a
      // third of a phone's width — while still announcing the whole name
      // (D320).
      await _scrollTo(tester, 'Q. Prime');
      expect(tileFor('Q. Prime'), findsOneWidget);
    });

    testWidgets('does not snap back when the screen rebuilds for another '
        'reason', (tester) async {
      _phone(tester);
      final repo = await _repository();
      await tester.pumpWidget(_home(repo));
      await tester.pumpAndSettle();

      await _scrollTo(tester, 'Q. Prime');
      // A finished game rebuilds the whole screen — the rating card, the
      // quests, the lists. The row must not undo what the player scrolled to.
      await _play(repo);
      await tester.pumpAndSettle();
      expect(tileFor('Q. Prime'), findsOneWidget,
          reason: 'the row kept its position through an unrelated rebuild');
    });
  });

  group('the detail page', () {
    Future<void> open(WidgetTester tester, LocalGameRepository repo,
        String name, {Locale? locale}) async {
      await tester.pumpWidget(_home(repo, locale: locale));
      await tester.pumpAndSettle();
      await _scrollTo(tester, name);
      await tester.tap(tileFor(name));
      await tester.pumpAndSettle();
    }

    testWidgets('opens from a tile and shows what is known', (tester) async {
      _phone(tester);
      final repo = await _repository();
      await _play(repo, botId: 'clover');
      await _play(repo, botId: 'clover', won: false);
      await open(tester, repo, 'Clover');

      expect(find.byType(OpponentDetail), findsOneWidget);
      expect(find.text('900 · Novice'), findsOneWidget);
      // No trailing zero: a record with no draws does not mention them (D385).
      expect(find.text('1–1 in 2 games'), findsOneWidget);
      // Clover is roster index 4, so a win pays eight (D335's ladder).
      expect(find.text('A win pays 8 points'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Start a game'), findsOneWidget);
    });

    testWidgets('an opponent never faced shows no star row', (tester) async {
      _phone(tester);
      final repo = await _repository();
      await open(tester, repo, 'Bramble');

      expect(find.text('Not played yet'), findsOneWidget);
      expect(find.byIcon(Icons.star_border), findsNothing);
      expect(find.byIcon(Icons.star), findsNothing);
    });

    testWidgets('starting a game from it opens that game', (tester) async {
      _phone(tester);
      final repo = await _repository();
      await open(tester, repo, 'Hazel');
      await tester.tap(find.widgetWithText(FilledButton, 'Start a game'));
      await tester.pumpAndSettle();

      final active = await repo.watchActiveGames().first;
      expect(active.single.opponent, botOpponent('hazel'));
      // And the page is gone, so backing out of the game lands on the main
      // screen rather than on the page that started it.
      expect(find.byType(OpponentDetail), findsNothing);
    });

    testWidgets('a locked opponent offers the price, the progress and an '
        'unlock button', (tester) async {
      _phone(tester);
      final repo = await _repository();
      await open(tester, repo, 'Bramble');

      expect(find.text('42 points'), findsOneWidget);
      expect(find.text('0 of 42'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Start a game'), findsNothing);
      // Pressable even on nothing, so it can say how short the balance is and
      // offer the way past it. What matters is the outcome, not the flag.
      final button = tester.widget<ButtonStyleButton>(
          find.widgetWithText(FilledButton, 'Unlock'));
      expect(button.onPressed, isNotNull);

      await tester.tap(find.widgetWithText(FilledButton, 'Unlock'));
      await tester.pumpAndSettle();
      expect(find.text('You need 42 more points.'), findsOneWidget);
      expect(await repo.loadUnlocks(), isEmpty, reason: 'nothing was bought');
    });

    testWidgets('and once affordable it reaches the same confirmation',
        (tester) async {
      _phone(tester);
      final repo = await _repository();
      // Fourteen Mote wins at three points each is Bramble's price to the
      // point — the Fibonacci ladder has no exact four-win rung (D335).
      for (var i = 0; i < 14; i++) {
        await _play(repo, botId: 'mote');
      }
      await open(tester, repo, 'Bramble');

      expect(find.text('42 of 42'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Unlock'));
      await tester.pumpAndSettle();
      expect(find.text('Unlock Bramble?'), findsOneWidget);
    });

    testWidgets('the two Master opponents say so on the page itself, not only '
        'in the confirmation', (tester) async {
      _phone(tester);
      final repo = await _repository();
      await open(tester, repo, 'Oracle');

      expect(
        find.textContaining('unbeatable when it moves first'),
        findsOneWidget,
        reason: 'a player deciding whether to spend should not have to press '
            'Unlock to be told (D181)',
      );
    });

    testWidgets('says how the pairing sits against the player', (tester) async {
      _phone(tester);
      final repo = await _repository();
      // Bought outright, which is the only way to reach Pebble without first
      // playing a game — and a game would move the rating this test names
      // (D382). It is also the path the store purchase takes.
      await repo.grantAllPurchased();
      await open(tester, repo, 'Pebble');
      // Pebble is 600 against a seeded 800.
      expect(find.text('Below your level'), findsOneWidget);
    });

    testWidgets('announces name, rating and tier once, together',
        (tester) async {
      _phone(tester);
      final handle = tester.ensureSemantics();
      final repo = await _repository();
      await open(tester, repo, 'Clover');

      expect(find.bySemanticsLabel('Clover. Rating 900. Novice.'),
          findsOneWidget);
      handle.dispose();
    });

    testWidgets('survives the largest font scale on a phone', (tester) async {
      _phone(tester, textScale: 2);
      final repo = await _repository();
      await open(tester, repo, 'Clover');
      expect(tester.takeException(), isNull);
      expect(find.byType(OpponentDetail), findsOneWidget);
    });

    testWidgets('every new string exists in Dutch', (tester) async {
      _phone(tester);
      final repo = await _repository();
      await open(tester, repo, 'Clover', locale: const Locale('nl'));

      expect(find.widgetWithText(FilledButton, 'Start een partij'),
          findsOneWidget);
      expect(find.textContaining('Winst levert'), findsOneWidget);
    });
  });

  group('opponent selection is untouched', () {
    testWidgets('tapping there still starts a game rather than opening a page',
        (tester) async {
      _phone(tester);
      final repo = await _repository();
      await tester.pumpWidget(_home(repo));
      await tester.pumpAndSettle();

      await tester.tap(plaqueLabelled('New game'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Play the computer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hazel'));
      await tester.pumpAndSettle();

      expect(find.byType(OpponentDetail), findsNothing,
          reason: 'this screen is behind the new-game button, so the player '
              'has already decided (D288)');
      final active = await repo.watchActiveGames().first;
      expect(active.single.opponent, botOpponent('hazel'));
    });
  });
}
