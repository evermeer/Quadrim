import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrim/data/document_store.dart';
import 'package:quadrim/data/documents.dart';
import 'package:quadrim/data/local_game_repository.dart';
import 'package:quadrim/game/game_screen.dart';
import 'package:quadrim/l10n/app_localizations.dart';
import 'package:quadrim/services/games.dart';
import 'package:quadrim/theme.dart';
import 'package:quadrim_engine/quadrim_engine.dart';

import 'game_services_test.dart' show FakeGameServices;

/// Ticket 050, the half `game_services_test.dart` cannot reach.
///
/// That file proves `GameServices` does the right thing when it is called. This
/// one proves the game screen actually calls it — which is a different claim,
/// and the one that would have been wrong if `_report` had never been wired to
/// `_loadOutcome`.
///
/// The repository is the real one over a memory store, for the reason
/// `game_screen_test.dart` gives: it is the only path to stored data (S4), so
/// faking it would exercise a path the app does not have.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// A finished game, written straight to the repository.
  ///
  /// Playing one out through the UI would work and would make this a test of
  /// the board instead of a test of the wiring.
  Future<LocalGameRepository> repositoryWith({
    required GameMode mode,
    required List<int> moves,
  }) async {
    final repository = await LocalGameRepository.open(MemoryDocumentStore());
    addTearDown(repository.dispose);
    await repository.saveSettings(const SettingsDocument(tutorialOffered: true));
    // `bot:` prefixed, which is what `botIdOf` reads and therefore what makes
    // the game *scoreable*. A bare id stores fine and folds to nothing, which
    // is a fixture that silently tests the empty case.
    final game = await repository.createGame(
      mode: mode,
      opponent: 'bot:${opponentCatalogue.first.id}',
    );
    for (final move in moves) {
      await repository.appendMove(game.id, move);
    }
    return repository;
  }

  Future<void> pumpResult(
    WidgetTester tester,
    LocalGameRepository repository,
    GameServices services,
  ) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    final games = await repository.loadCompletedGames();
    expect(games, isNotEmpty, reason: 'the fixture did not finish a game');
    await tester.pumpWidget(MaterialApp(
      theme: QuadrimTheme.forest,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: GameScreen(
        repository: repository,
        gameId: games.first.id,
        settings: repository,
        unlocks: repository,
        services: services,
      ),
    ));
    await tester.pumpAndSettle();
  }

  /// Light takes the top row: 0, 1, 2, 3, with dark answering off the line.
  const lightWins = [0, 16, 1, 17, 2, 18, 3];

  testWidgets('a finished computer game submits the rating', (tester) async {
    final fake = FakeGameServices();
    final services = GameServices(platform: fake);
    await services.start();
    final repository =
        await repositoryWith(mode: GameMode.vsComputer, moves: lightWins);
    await pumpResult(tester, repository, services);

    expect(fake.scores, hasLength(1),
        reason: 'the rating was never submitted; is _report wired?');
  });

  /// AC 2. Pass and play does not move the rating (F12), so submitting one
  /// would put a number on the leaderboard that no game produced.
  testWidgets('a finished pass-and-play game submits no rating',
      (tester) async {
    final fake = FakeGameServices();
    final services = GameServices(platform: fake);
    await services.start();
    final repository =
        await repositoryWith(mode: GameMode.passAndPlay, moves: lightWins);
    await pumpResult(tester, repository, services);

    expect(fake.scores, isEmpty);
  });

  /// AC 3. Beating the first opponent completes `first_win:<id>`, which is one
  /// of the forty-four.
  testWidgets('a first win against an opponent reports its achievement',
      (tester) async {
    final fake = FakeGameServices();
    final services = GameServices(platform: fake);
    await services.start();
    final repository =
        await repositoryWith(mode: GameMode.vsComputer, moves: lightWins);
    await pumpResult(tester, repository, services);

    expect(
      fake.unlockedIos,
      contains('nl.evict.quadrim2.beat.${opponentCatalogue.first.id}'),
    );
  });

  /// A real drawn game: sixty-four moves, every cell filled, no line for
  /// either side. Lifted from the engine's own corpus
  /// (`packages/quadrim_engine/test/fixtures/corpus.json`), which the linegen
  /// suite asserts replays to the outcome it records — so this fixture is a
  /// draw because the engine says so, not because it looks like one.
  const drawn = [
    14, 4, 11, 7, 58, 17, 30, 35, 16, 26, 48, 13, 51, 46, 42, 60, //
    22, 29, 31, 50, 56, 43, 40, 1, 44, 8, 63, 57, 37, 24, 49, 0, //
    20, 62, 2, 59, 19, 18, 32, 15, 27, 3, 12, 9, 10, 52, 21, 23, //
    61, 38, 5, 36, 34, 53, 41, 25, 39, 47, 55, 33, 28, 6, 45, 54, //
  ];

  /// D386. The one achievement with no quest behind it, so this is the only
  /// thing that proves it ever fires.
  testWidgets('a drawn computer game reports the tie achievement',
      (tester) async {
    final fake = FakeGameServices();
    final services = GameServices(platform: fake);
    await services.start();
    final repository =
        await repositoryWith(mode: GameMode.vsComputer, moves: drawn);
    await pumpResult(tester, repository, services);

    expect(fake.unlockedIos, contains('nl.evict.quadrim2.tie'),
        reason: 'the draw was never reported; is reportDraw wired?');
  });

  /// The other half, and the half that would not fail on its own. A game that
  /// is *complete* is not a game that was drawn — a win is complete, and so is
  /// a resignation, which leaves a position the board would still play. Asking
  /// `status` instead of `outcome` would unlock this for everybody.
  testWidgets('a won computer game reports no tie', (tester) async {
    final fake = FakeGameServices();
    final services = GameServices(platform: fake);
    await services.start();
    final repository =
        await repositoryWith(mode: GameMode.vsComputer, moves: lightWins);
    await pumpResult(tester, repository, services);

    expect(fake.unlockedIos, isNot(contains('nl.evict.quadrim2.tie')));
  });

  /// "Against a computer opponent" is part of the achievement, and pass and
  /// play is two people at one phone agreeing to fill the board.
  testWidgets('a drawn pass-and-play game reports no tie', (tester) async {
    final fake = FakeGameServices();
    final services = GameServices(platform: fake);
    await services.start();
    final repository =
        await repositoryWith(mode: GameMode.passAndPlay, moves: drawn);
    await pumpResult(tester, repository, services);

    expect(fake.unlockedIos, isEmpty);
  });

  /// AC 6, at the level that matters: the panel renders and the game is
  /// playable with the platform throwing on every call.
  testWidgets('a failing platform changes nothing on screen', (tester) async {
    final fake = FakeGameServices(throws: true);
    final services = GameServices(platform: fake);
    await services.start();
    final repository =
        await repositoryWith(mode: GameMode.vsComputer, moves: lightWins);
    await pumpResult(tester, repository, services);

    expect(tester.takeException(), isNull);
    expect(find.byType(GameScreen), findsOneWidget);
  });

  /// The null case, which is every other widget test in this repository and
  /// also a player who declined sign-in.
  testWidgets('no services at all is a normal game screen', (tester) async {
    final repository =
        await repositoryWith(mode: GameMode.vsComputer, moves: lightWins);
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    final games = await repository.loadCompletedGames();
    await tester.pumpWidget(MaterialApp(
      theme: QuadrimTheme.forest,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: GameScreen(
        repository: repository,
        gameId: games.first.id,
        settings: repository,
        unlocks: repository,
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
