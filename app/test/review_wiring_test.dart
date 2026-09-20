import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrim/data/document_store.dart';
import 'package:quadrim/data/documents.dart';
import 'package:quadrim/data/local_game_repository.dart';
import 'package:quadrim/game/game_screen.dart';
import 'package:quadrim/l10n/app_localizations.dart';
import 'package:quadrim/services/review.dart';
import 'package:quadrim/theme.dart';
import 'package:quadrim_engine/quadrim_engine.dart';

import 'review_test.dart' show FakeReviewPlatform;

/// D389, the half `review_test.dart` cannot reach.
///
/// That file proves the rules are right. This one proves the game screen
/// actually applies them — a different claim, and the one that would have been
/// wrong if `_maybeAskForReview` had never been called from `_loadOutcome`. It
/// is the same split, and for the same reason, as
/// `game_services_wiring_test.dart`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Light takes the top row; dark answers off the line. The player holds the
  /// light pieces, so this is a win for them.
  const lightWins = [0, 16, 1, 17, 2, 18, 3];

  /// Dark takes a row instead, so the same fixture becomes a loss.
  const darkWins = [4, 0, 5, 1, 6, 2, 60, 3];

  /// A repository holding [count] finished games, all the same result.
  Future<LocalGameRepository> repositoryWith({
    required int count,
    required List<int> moves,
    SettingsDocument settings = const SettingsDocument(tutorialOffered: true),
  }) async {
    final repository = await LocalGameRepository.open(MemoryDocumentStore());
    addTearDown(repository.dispose);
    await repository.saveSettings(settings);
    for (var i = 0; i < count; i++) {
      final game = await repository.createGame(
        mode: GameMode.vsComputer,
        opponent: 'bot:${opponentCatalogue.first.id}',
      );
      for (final move in moves) {
        await repository.appendMove(game.id, move);
      }
    }
    return repository;
  }

  Future<void> pumpNewest(
    WidgetTester tester,
    LocalGameRepository repository,
    ReviewPrompt review, {
    DateTime? now,
  }) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    final games = await repository.loadCompletedGames();
    expect(games, isNotEmpty, reason: 'the fixture finished no games');
    await tester.pumpWidget(MaterialApp(
      theme: QuadrimTheme.forest,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: GameScreen(
        repository: repository,
        gameId: games.first.id,
        settings: repository,
        unlocks: repository,
        review: review,
        now: now == null ? null : () => now,
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('a seventh win asks for a review', (tester) async {
    final platform = FakeReviewPlatform();
    final repository = await repositoryWith(count: 7, moves: lightWins);
    await pumpNewest(tester, repository, ReviewPrompt(platform: platform));

    expect(platform.requests, 1,
        reason: 'never asked; is _maybeAskForReview wired to _loadOutcome?');
    final settings = await repository.loadSettings();
    expect(settings.reviewPromptCount, 1,
        reason: 'asked but never recorded, so it would ask again next win');
  });

  testWidgets('a sixth win does not', (tester) async {
    final platform = FakeReviewPlatform();
    final repository = await repositoryWith(count: 6, moves: lightWins);
    await pumpNewest(tester, repository, ReviewPrompt(platform: platform));

    expect(platform.requests, 0);
  });

  /// The one that would not fail on its own: seven *games* is not seven wins,
  /// and a loss is the more common seventh game.
  testWidgets('a seventh loss does not', (tester) async {
    final platform = FakeReviewPlatform();
    final repository = await repositoryWith(count: 7, moves: darkWins);
    await pumpNewest(tester, repository, ReviewPrompt(platform: platform));

    expect(platform.requests, 0, reason: 'asked after a loss');
  });

  testWidgets('a win inside the interval does not ask again', (tester) async {
    final day = DateTime.utc(2026, 6, 1);
    final platform = FakeReviewPlatform();
    final repository = await repositoryWith(
      count: 7,
      moves: lightWins,
      settings: SettingsDocument(
        tutorialOffered: true,
        reviewPromptedAt: day.subtract(const Duration(days: 10)),
        reviewPromptCount: 1,
      ),
    );
    await pumpNewest(tester, repository, ReviewPrompt(platform: platform),
        now: day);

    expect(platform.requests, 0);
  });

  testWidgets('a win past the interval asks again', (tester) async {
    final day = DateTime.utc(2026, 6, 1);
    final platform = FakeReviewPlatform();
    final repository = await repositoryWith(
      count: 7,
      moves: lightWins,
      settings: SettingsDocument(
        tutorialOffered: true,
        reviewPromptedAt: day.subtract(kReviewPromptInterval),
        reviewPromptCount: 1,
      ),
    );
    await pumpNewest(tester, repository, ReviewPrompt(platform: platform),
        now: day);

    expect(platform.requests, 1);
    final settings = await repository.loadSettings();
    expect(settings.reviewPromptCount, 2);
  });

  /// Null is what a build with no review service configured looks like, and it
  /// must be a normal game screen rather than a crash.
  testWidgets('no review service at all is a normal game screen',
      (tester) async {
    final repository = await repositoryWith(count: 7, moves: lightWins);
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
