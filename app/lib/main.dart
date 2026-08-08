import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path_provider/path_provider.dart';

import 'data/document_store.dart';
import 'data/documents.dart';
import 'data/game_repository.dart';
import 'data/local_game_repository.dart';
import 'game/game_screen.dart';
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
  runApp(QuadrimApp(repository: repository));
}

class QuadrimApp extends StatelessWidget {
  const QuadrimApp({super.key, required this.repository, this.locale});

  final GameRepository repository;

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
      home: _PlaceholderHome(repository: repository),
    );
  }
}

class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome({required this.repository});

  final GameRepository repository;

  /// Resumes the unfinished pass-and-play game if there is one, otherwise
  /// starts a fresh one. The real main screen (ticket 013) lists games and
  /// makes resuming explicit; until then this is what makes an in-progress
  /// game survive a restart.
  Future<String> _resumeOrCreate() async {
    final active = await repository.watchActiveGames().first;
    for (final game in active) {
      if (game.mode == GameMode.passAndPlay) return game.id;
    }
    final created = await repository.createGame(
      mode: GameMode.passAndPlay,
      opponent: kGuestOpponent,
    );
    return created.id;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Text(l10n.appTitle,
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(l10n.placeholderTagline),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final id = await _resumeOrCreate();
                    if (!context.mounted) return;
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => GameScreen(
                          repository: repository,
                          gameId: id,
                        ),
                      ),
                    );
                  },
                  child: Text(l10n.passAndPlay),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
