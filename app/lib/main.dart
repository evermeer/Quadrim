import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path_provider/path_provider.dart';

import 'data/document_store.dart';
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

class QuadrimApp extends StatelessWidget {
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

  /// Forces a locale instead of following the system. Used by tests to prove
  /// each shipped locale actually renders; null in production.
  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: locale,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: QuadrimTheme.light,
      darkTheme: QuadrimTheme.dark,
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: HomeScreen(
        repository: repository,
        settings: settings,
        random: random,
      ),
    );
  }
}
