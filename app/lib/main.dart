import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path_provider/path_provider.dart';

import 'data/document_store.dart';
import 'data/documents.dart';
import 'data/game_repository.dart';
import 'data/local_game_repository.dart';
import 'home/home_screen.dart';
import 'l10n/app_localizations.dart';
import 'services/achievements.dart';
import 'services/games.dart';
import 'services/review.dart';
import 'shop/shop.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Portrait only, on every device (spec §5.2, ticket 035). No large-screen
  // layout exists, so none must be reachable by rotating a phone or by
  // resizing a window — ticket 017, which would have built one, is cancelled.
  //
  // Belt and braces on purpose, and neither half is redundant. The manifest's
  // `screenOrientation` and `resizeableActivity="false"` are what a freeform
  // window manager and a foldable obey; this call is what the framework obeys,
  // and it is the half a test can see.
  await SystemChrome.setPreferredOrientations(
      const [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  final support = await getApplicationSupportDirectory();
  // `quadrim/` under application support resolves to `files/quadrim/` on
  // Android, which is exactly the path the backup allowlist includes (D131).
  final store =
      await FileDocumentStore.open(Directory('${support.path}/quadrim'));
  final repository = await LocalGameRepository.open(store);

  // The store, and it is deliberately not awaited before `runApp`. `start()`
  // reaches the network, and a launch that blocks on it is a launch that hangs
  // on a bad connection — for a game whose whole point is that computer play
  // needs no network at all (D93, S1). What must happen early is the *stream
  // subscription*, which `start()` opens first thing, before any await.
  final shop = Shop(
    platform: InAppPurchasePlatformAdapter(),
    unlocks: repository,
  );
  unawaited(shop.start());

  // **Started, not awaited** -- the same shape as `Shop.start()` above and for
  // the same reason (D351). It still never *offers* sign-in, which belongs to a
  // moment the player chose rather than to the splash screen (ticket 050 §5);
  // what it now does is re-establish an answer they already gave.
  //
  // The settings document is read here rather than inside `GameServices`,
  // which owns no storage and should not learn about documents to answer one
  // question (D393). This read is awaited because it is a local file and the
  // answer decides what `start()` does; the network half stays unawaited.
  final stored = await repository.loadSettings();
  final services = GameServices(
    platform: const GamesServicesPlatformAdapter(),
    isAndroid: Platform.isAndroid,
    androidConfigured: playGamesConfigured,
  );
  unawaited(services.start(
      previouslyAccepted:
          stored.gameServicesOffer == kGameServicesAccepted));

  runApp(QuadrimApp(
    repository: repository,
    settings: repository,
    unlocks: repository,
    shop: shop,
    services: services,
    review: ReviewPrompt(platform: const StoreReviewPlatform()),
  ));
}

class QuadrimApp extends StatefulWidget {
  const QuadrimApp({
    super.key,
    required this.repository,
    required this.settings,
    required this.unlocks,
    this.locale,
    this.random,
    this.shop,
    this.services,
    this.review,
    this.now,
  });

  final GameRepository repository;
  final SettingsRepository settings;

  /// What the player has bought. A third contract satisfied by the same local
  /// implementation, kept separate so 0.3a can move one without the others.
  final UnlockRepository unlocks;

  /// Null in every widget test and in any build with no store attached. The
  /// shop is the one dependency here that reaches off the device, so it is
  /// optional by construction rather than faked into existence (ticket 046).
  final Shop? shop;

  /// Play Games Services and Game Center, or null in a test.
  ///
  /// Optional like [shop]: every widget test in this repository builds the app
  /// without one, and a leaderboard that a test had to stub in order to open
  /// the board would be a leaderboard that had escaped its own layer.
  final GameServices? services;

  /// The store review sheet, or null. Optional like [services] and for the
  /// same reason: a widget test that only cares about the board should not
  /// have to construct a platform service to get one (D389).
  final ReviewPrompt? review;

  /// Injected in tests, like [random]. The meter and the streak are both
  /// day-shaped, so a test that cannot move the clock cannot reach either.
  final DateTime Function()? now;

  /// Injected so a test can pin who opens a new game. Null means unseeded.
  final Random? random;

  /// Forces a locale instead of following the settings document. Used by tests
  /// to prove each shipped locale actually renders; null in production, where
  /// the settings screen is what chooses.
  final Locale? locale;

  @override
  State<QuadrimApp> createState() => _QuadrimAppState();
}

class _QuadrimAppState extends State<QuadrimApp> {
  StreamSubscription<SettingsDocument>? _subscription;
  SettingsDocument _settings = const SettingsDocument();

  @override
  void initState() {
    super.initState();
    // Watched at the root, which is what makes a language or theme change on
    // the settings screen take effect without a restart: the document changes,
    // this rebuilds, and every screen below is rebuilt with it (ticket 028).
    _subscription = widget.settings
        .watchSettings()
        .listen((settings) => setState(() => _settings = settings));
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  /// Null means follow the device, which is [MaterialApp]'s own default.
  Locale? get _locale => switch (_settings.locale) {
        'en' => const Locale('en'),
        'nl' => const Locale('nl'),
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // The injected locale wins: a test that forces Dutch is asserting that
      // the Dutch strings render, not exercising the settings document.
      locale: widget.locale ?? _locale,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      // The same theme for both brightnesses. The design is one painting and
      // there is no second one; handing `darkTheme` something different would
      // give a device set to dark a half-inverted version of a design that was
      // never inverted (D293). The stored `theme` field is left alone rather
      // than migrated away, so 0.2 can revive the choice without a data change.
      theme: QuadrimTheme.forest,
      darkTheme: QuadrimTheme.forest,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: HomeScreen(
        repository: widget.repository,
        settings: widget.settings,
        unlocks: widget.unlocks,
        random: widget.random,
        shop: widget.shop,
        services: widget.services,
        review: widget.review,
        now: widget.now,
      ),
    );
  }
}
