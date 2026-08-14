import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrim/data/document_store.dart';
import 'package:quadrim/data/documents.dart';
import 'package:quadrim/data/local_game_repository.dart';
import 'package:quadrim/data/points_fold.dart';
import 'package:quadrim/game/game_screen.dart';
import 'package:quadrim/home/home_screen.dart';
import 'package:quadrim/home/quests_section.dart';
import 'package:quadrim/l10n/app_localizations.dart';
import 'package:quadrim_engine/quadrim_engine.dart';

/// The arithmetic is proven in `packages/quadrim_progression`. What is proven
/// here is the mapping from stored games onto it, and what the two screens do
/// with the answer.

const _lightWinsMoves = [0, 21, 1, 22, 2, 26, 3];

/// Cells 21, 22, 26 plus 27 form no line for the opener; 0..3 wins for the
/// second player to move.
const _darkWinsMoves = [21, 0, 22, 1, 26, 2, 27, 3];

final _today = DateTime(2026, 8, 14, 12);

Future<LocalGameRepository> _repository({DateTime? from}) async {
  var tick = from ?? DateTime.utc(2026, 1, 1);
  final repo = await LocalGameRepository.open(
    MemoryDocumentStore(),
    now: () => tick = tick.add(const Duration(seconds: 1)),
  );
  addTearDown(repo.dispose);
  await repo.saveSettings(const SettingsDocument(tutorialOffered: true));
  return repo;
}

/// One finished computer game against [botId]. [playerOpens] false puts the
/// player in the second seat, which is what one quest family asks about.
Future<GameDocument> _play(
  LocalGameRepository repo, {
  required String botId,
  bool playerOpens = true,
  bool playerWins = true,
}) async {
  final game = await repo.createGame(
    mode: GameMode.vsComputer,
    opponent: botOpponent(botId),
    opponentRating: botById(botId)!.rating,
    startingSeat: 0,
    playerSeat: playerOpens ? 0 : 1,
  );
  for (final move in playerWins == playerOpens
      ? _lightWinsMoves
      : _darkWinsMoves) {
    await repo.appendMove(game.id, move);
  }
  return game;
}

void _phone(WidgetTester tester, {double textScale = 1}) {
  tester.view.physicalSize = const Size(1080, 3600);
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
        now: () => _today,
      ),
    );

void main() {
  group('the fold from stored games', () {
    test('reads the second seat off the game rather than being told', () async {
      final repo = await _repository();
      await _play(repo, botId: pebble.id, playerOpens: false);
      final scored = scoredGamesFrom(await repo.loadCompletedGames());
      expect(scored.single.movedSecond, isTrue);
      expect(scored.single.won, isTrue);
    });

    test('a game the player opened is not a second-seat win', () async {
      final repo = await _repository();
      await _play(repo, botId: pebble.id);
      expect(scoredGamesFrom(await repo.loadCompletedGames()).single.movedSecond,
          isFalse);
    });

    test('games reach the fold oldest first, which is what the volume family '
        'needs', () async {
      final repo = await _repository();
      await _play(repo, botId: pebble.id);
      await _play(repo, botId: twig.id);
      final scored = scoredGamesFrom(await repo.loadCompletedGames());
      expect([for (final g in scored) g.rosterIndex], [0, 1]);
    });

    test('pass-and-play counts toward no quest', () async {
      final repo = await _repository();
      final social = await repo.createGame(
          mode: GameMode.passAndPlay, opponent: kGuestOpponent);
      for (final move in _lightWinsMoves) {
        await repo.appendMove(social.id, move);
      }
      final quests = questsFrom(await repo.loadCompletedGames(), _today);
      expect(quests.where((q) => q.achieved), isEmpty);
    });

    test('a real win achieves both per-opponent quests when it was played '
        'from the second seat', () async {
      final repo = await _repository();
      await _play(repo, botId: mote.id, playerOpens: false);
      final achieved = [
        for (final q in questsFrom(await repo.loadCompletedGames(), _today))
          if (q.achieved) q.quest.id,
      ];
      expect(achieved,
          unorderedEquals(['first_win:mote', 'first_win_second:mote']));
    });
  });

  group('the quests section', () {
    testWidgets('shows the four closest, each with a bar and a number',
        (tester) async {
      _phone(tester);
      final repo = await _repository();
      await _play(repo, botId: pebble.id);
      await tester.pumpWidget(_home(repo));
      await tester.pumpAndSettle();

      expect(find.text('Quests'), findsOneWidget);
      expect(find.byType(QuestTile), findsNWidgets(4));
      // The bar's meaning is also a number, because a bar is a shape and a
      // shape is unreadable to a screen reader and at the largest font scale.
      expect(
          find.descendant(
              of: find.byType(QuestTile),
              matching: find.byType(LinearProgressIndicator)),
          findsNWidgets(4));
      // One finished game puts the volume family a fifth of the way to its
      // first rung, which outranks forty per-opponent quests still at zero.
      // That is the ticket's rule working, not a quirk: percentage complete,
      // ties to the smaller remainder.
      expect(find.text('1 of 5'), findsOneWidget);
      expect(find.text('5 games in one day'), findsOneWidget);
    });

    testWidgets('does not offer a quest already achieved', (tester) async {
      _phone(tester);
      final repo = await _repository();
      await _play(repo, botId: pebble.id);
      await tester.pumpWidget(_home(repo));
      await tester.pumpAndSettle();

      expect(find.text('First win against Pebble'), findsNothing);
      // Not by luck of the ranking: nothing on offer is finished.
      for (final tile in tester.widgetList<QuestTile>(find.byType(QuestTile))) {
        expect(tile.status.achieved, isFalse, reason: tile.status.quest.id);
      }
    });

    testWidgets('is absent before the first finished game', (tester) async {
      _phone(tester);
      final repo = await _repository();
      await tester.pumpWidget(_home(repo));
      await tester.pumpAndSettle();

      expect(find.text('Quests'), findsNothing);
      expect(find.text('No games yet.'), findsOneWidget);
    });

    testWidgets('announces each quest as state with progress', (tester) async {
      _phone(tester);
      final handle = tester.ensureSemantics();
      final repo = await _repository();
      await _play(repo, botId: pebble.id);
      await tester.pumpWidget(_home(repo));
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('5 games in one day. 1 of 5.'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('every quest string exists in Dutch', (tester) async {
      _phone(tester);
      final repo = await _repository();
      await _play(repo, botId: pebble.id);
      await tester.pumpWidget(_home(repo, locale: const Locale('nl')));
      await tester.pumpAndSettle();

      expect(find.text('Opdrachten'), findsOneWidget);
      expect(find.text('5 partijen op één dag'), findsOneWidget);
      expect(find.text('1 van 5'), findsOneWidget);
    });
  });

  group('what a finished game achieved', () {
    Widget game(LocalGameRepository repo, String id, {Locale? locale}) =>
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GameScreen(
            repository: repo,
            gameId: id,
            random: Random(5),
            now: () => _today,
            opponentMove: chooseMoveInline,
          ),
        );

    testWidgets('is acknowledged when the game ends, with what it paid',
        (tester) async {
      _phone(tester);
      final repo = await _repository();
      final played = await _play(repo, botId: twig.id);
      await tester.pumpWidget(game(repo, played.id));
      await tester.pumpAndSettle();

      expect(find.text('Achieved'), findsOneWidget);
      expect(find.text('First win against Twig'), findsOneWidget);
      // Twig is roster index 1, so the quest pays two points — the same two it
      // would pay a player who had already beaten Quadrim Prime.
      expect(find.text('+2'), findsOneWidget);
    });

    testWidgets('says nothing when the game achieved nothing new',
        (tester) async {
      _phone(tester);
      final repo = await _repository();
      await _play(repo, botId: twig.id);
      final second = await _play(repo, botId: twig.id);
      await tester.pumpWidget(game(repo, second.id));
      await tester.pumpAndSettle();

      expect(find.text('Achieved'), findsNothing);
    });

    testWidgets('the acknowledgement is announced as one node', (tester) async {
      _phone(tester);
      final handle = tester.ensureSemantics();
      final repo = await _repository();
      final played = await _play(repo, botId: twig.id);
      await tester.pumpWidget(game(repo, played.id));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('First win against Twig. Achieved, 2 '
          'points.'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('only the game that completed a rung claims it', (tester) async {
      // Five games in one day earn the five-game rung. Asking "would this
      // quest still stand without you" would let all five claim it, because
      // removing any one of them drops the day to four. The prefix ending at
      // each game credits the fifth alone.
      _phone(tester);
      final repo = await _repository();
      final day = [
        for (var i = 0; i < 5; i++) await _play(repo, botId: pebble.id),
      ];

      await tester.pumpWidget(game(repo, day[2].id));
      await tester.pumpAndSettle();
      expect(find.text('5 games in one day'), findsNothing,
          reason: 'the third game did not complete the rung');

      await tester.pumpWidget(game(repo, day.last.id));
      await tester.pumpAndSettle();
      expect(find.text('5 games in one day'), findsOneWidget);
      expect(find.text('+1'), findsOneWidget,
          reason: 'a quarter of a Pebble win, clamped up to one point (D279)');
    });

    testWidgets('a pass-and-play game acknowledges nothing', (tester) async {
      _phone(tester);
      final repo = await _repository();
      final social = await repo.createGame(
          mode: GameMode.passAndPlay, opponent: kGuestOpponent);
      for (final move in _lightWinsMoves) {
        await repo.appendMove(social.id, move);
      }
      await tester.pumpWidget(game(repo, social.id));
      await tester.pumpAndSettle();

      expect(find.text('Achieved'), findsNothing);
    });

    testWidgets('the acknowledgement exists in Dutch', (tester) async {
      _phone(tester);
      final repo = await _repository();
      final played = await _play(repo, botId: twig.id);
      await tester.pumpWidget(game(repo, played.id, locale: const Locale('nl')));
      await tester.pumpAndSettle();

      expect(find.text('Behaald'), findsOneWidget);
      expect(find.text('Eerste winst tegen Twig'), findsOneWidget);
    });
  });
}
