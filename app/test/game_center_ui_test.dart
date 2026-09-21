import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrim/data/document_store.dart';
import 'package:quadrim/data/documents.dart';
import 'package:quadrim/data/local_game_repository.dart';
import 'package:quadrim/main.dart';
import 'package:quadrim/services/games.dart';
import 'package:quadrim_engine/quadrim_engine.dart';

import 'game_services_test.dart' show FakeGameServices;

/// D390: the two ways into Game Center from the main screen.
///
/// **The whole feature was invisible before this** — `offerSignIn` existed with
/// no caller and the platform interface had no viewer at all, so ticket 050
/// shipped a leaderboard nobody could reach. These tests are what say the
/// controls exist and go somewhere.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Light takes the top row. One finished computer game, which is what puts a
  /// quests panel on screen at all.
  const lightWins = [0, 16, 1, 17, 2, 18, 3];

  Future<LocalGameRepository> repositoryWithAGame({
    SettingsDocument settings = const SettingsDocument(
      tutorialOffered: true,
      // Already answered, so the unprompted offer stays out of the way of the
      // tests that are about the buttons.
      gameServicesOffer: kGameServicesDeclined,
    ),
  }) async {
    final repository = await LocalGameRepository.open(MemoryDocumentStore());
    addTearDown(repository.dispose);
    await repository.saveSettings(settings);
    final game = await repository.createGame(
      mode: GameMode.vsComputer,
      opponent: 'bot:${opponentCatalogue.first.id}',
    );
    for (final move in lightWins) {
      await repository.appendMove(game.id, move);
    }
    return repository;
  }

  Future<void> pumpHome(
    WidgetTester tester,
    LocalGameRepository repository, {
    GameServices? services,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(QuadrimApp(
      repository: repository,
      settings: repository,
      unlocks: repository,
      services: services,
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('the leaderboard button opens the leaderboard', (tester) async {
    final fake = FakeGameServices();
    final services = GameServices(platform: fake);
    await services.start();
    await pumpHome(tester, await repositoryWithAGame(), services: services);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Leaderboard'));
    await tester.pumpAndSettle();

    expect(fake.leaderboardsShown, 1);
  });

  testWidgets('the quests panel button opens the achievements',
      (tester) async {
    final fake = FakeGameServices();
    final services = GameServices(platform: fake);
    await services.start();
    await pumpHome(tester, await repositoryWithAGame(), services: services);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Achievements'));
    await tester.pumpAndSettle();

    expect(fake.achievementsShown, 1);
  });

  /// **A control that does nothing is worse than an absent one.**
  testWidgets('neither button is drawn without game services', (tester) async {
    await pumpHome(tester, await repositoryWithAGame());

    expect(find.widgetWithText(OutlinedButton, 'Leaderboard'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Achievements'), findsNothing);
  });

  /// The case above is the easy one. **This is the one that was wrong**: on
  /// Android `services` is not null, it is merely unable to do anything until
  /// the Play Console ids exist -- so a null check drew both buttons over a
  /// platform that would refuse them (D390).
  testWidgets('neither button is drawn on an unconfigured Android build',
      (tester) async {
    final services = GameServices(
      platform: FakeGameServices(),
      isAndroid: true,
      androidConfigured: false,
    );
    await services.start();
    await pumpHome(tester, await repositoryWithAGame(), services: services);

    expect(find.widgetWithText(OutlinedButton, 'Leaderboard'), findsNothing,
        reason: 'a button that Play Games will refuse is worse than none');
    expect(find.widgetWithText(OutlinedButton, 'Achievements'), findsNothing);
  });

  testWidgets('both are drawn once Android is configured', (tester) async {
    final services = GameServices(
      platform: FakeGameServices(),
      isAndroid: true,
      androidConfigured: true,
    );
    await services.start();
    await pumpHome(tester, await repositoryWithAGame(), services: services);

    expect(find.widgetWithText(OutlinedButton, 'Leaderboard'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Achievements'), findsOneWidget);
  });

  /// The rating card is deliberately one accessibility node so its four facts
  /// are announced as one stop rather than four (ticket 021). Adding a button
  /// inside the `ExcludeSemantics` that guaranteed that would have hidden the
  /// control from exactly the readers who need it announced.
  testWidgets('the leaderboard button is visible to a screen reader',
      (tester) async {
    final fake = FakeGameServices();
    final services = GameServices(platform: fake);
    await services.start();
    final handle = tester.ensureSemantics();
    await pumpHome(tester, await repositoryWithAGame(), services: services);

    final node = tester.getSemantics(
        find.widgetWithText(OutlinedButton, 'Leaderboard'));
    expect(node.label, 'Leaderboard');
    expect(node.flagsCollection.isButton, isTrue,
        reason: 'it must announce as a button, not as text');

    // And the card still says its four facts in one breath rather than
    // fragmenting now that the exclusion is applied piece by piece.
    expect(
      find.bySemanticsLabel(RegExp(r'Against the computer: \d+\..*won')),
      findsOneWidget,
    );
    handle.dispose();
  });

  /// **The main screen is the tightest thing in the release** (ticket 021), and
  /// this adds two controls to it. The sweep that found three overflows at 2x
  /// on a 320pt phone (D374) never saw these, because it pumps the app without
  /// game services and the buttons are absent then.
  testWidgets('both buttons fit at the largest font scale on the smallest '
      'phone', (tester) async {
    final fake = FakeGameServices();
    final services = GameServices(platform: fake);
    await services.start();
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(QuadrimApp(
      repository: await repositoryWithAGame(),
      settings: await repositoryWithAGame(),
      unlocks: await repositoryWithAGame(),
      services: services,
    ));
    await tester.pumpAndSettle();
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull,
        reason: 'something overflowed at 2x with the buttons present');
  });

  /// **A platform that refuses is not a player who declined** (D391). Storing
  /// it as one is what retired the unprompted offer forever on a build whose
  /// Game Center was simply not configured -- so the app both did nothing and
  /// stopped asking.
  testWidgets('a refused open does not record a decline, and says something',
      (tester) async {
    final services = GameServices(platform: FakeGameServices(throws: true));
    await services.start();
    final repository = await repositoryWithAGame(
      settings: const SettingsDocument(
        tutorialOffered: true,
        gameServicesOffer: kGameServicesAccepted,
      ),
    );
    await pumpHome(tester, repository, services: services);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Leaderboard'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget,
        reason: 'silence was the whole symptom');
    final settings = await repository.loadSettings();
    expect(settings.gameServicesOffer, kGameServicesAccepted,
        reason: 'a platform failure must not be stored as the player declining');
  });

  group('the one-time offer', () {
    testWidgets('is made once a game is finished, and remembered',
        (tester) async {
      final fake = FakeGameServices(signedIn: false);
      final services = GameServices(platform: fake);
      await services.start();
      final repository = await repositoryWithAGame(
        settings: const SettingsDocument(tutorialOffered: true),
      );
      await pumpHome(tester, repository, services: services);

      expect(find.text('Keep your rating and achievements?'), findsOneWidget);

      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();

      final settings = await repository.loadSettings();
      expect(settings.gameServicesOffer, kGameServicesDeclined,
          reason: 'declining must be permanent or it is nagging');
      expect(fake.signInCalls, 0);
    });

    testWidgets('never arrives again once answered', (tester) async {
      final fake = FakeGameServices(signedIn: false);
      final services = GameServices(platform: fake);
      await services.start();
      await pumpHome(tester, await repositoryWithAGame(), services: services);

      expect(find.text('Keep your rating and achievements?'), findsNothing);
    });

    /// Not at launch: there is nothing to sync and nothing to explain, and the
    /// first-run tutorial prompt already owns that moment (D193).
    testWidgets('is not made before any game is finished', (tester) async {
      final fake = FakeGameServices(signedIn: false);
      final services = GameServices(platform: fake);
      await services.start();
      final repository = await LocalGameRepository.open(MemoryDocumentStore());
      addTearDown(repository.dispose);
      await repository
          .saveSettings(const SettingsDocument(tutorialOffered: true));
      await pumpHome(tester, repository, services: services);

      expect(find.text('Keep your rating and achievements?'), findsNothing);
    });
  });
}
