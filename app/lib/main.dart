import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path_provider/path_provider.dart';

import 'data/document_store.dart';
import 'data/documents.dart';
import 'data/game_repository.dart';
import 'data/local_game_repository.dart';
import 'home/home_screen.dart';
import 'l10n/app_localizations.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final support = await getApplicationSupportDirectory();
  // `quadrim/` under application support resolves to `files/quadrim/` on
  // Android, which is exactly the path the backup allowlist includes (D131).
  final store =
      await FileDocumentStore.open(Directory('${support.path}/quadrim'));
  final repository = await LocalGameRepository.open(store);
  runApp(QuadrimApp(repository: repository, settings: repository));
}

class QuadrimApp extends StatefulWidget {
  const QuadrimApp({
    super.key,
    required this.repository,
    required this.settings,
    this.locale,
    this.random,
  });

  final GameRepository repository;
  final SettingsRepository settings;

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

  ThemeMode get _themeMode => switch (_settings.theme) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // The injected locale wins: a test that forces Dutch is asserting that
      // the Dutch strings render, not exercising the settings document.
      locale: widget.locale ?? _locale,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: QuadrimTheme.light,
      darkTheme: QuadrimTheme.dark,
      themeMode: _themeMode,
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
        random: widget.random,
      ),
    );
  }
}
