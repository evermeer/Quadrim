import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quadrim_engine/quadrim_engine.dart';

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

  /// Resumes the unfinished game of this [mode] if there is one, otherwise
  /// starts a fresh one. The real main screen (ticket 013) lists games and
  /// makes resuming explicit; until then this is what makes an in-progress
  /// game survive a restart (D141).
  Future<String> _resumeOrCreate(GameMode mode, {String? opponent}) async {
    final active = await repository.watchActiveGames().first;
    for (final game in active) {
      if (game.mode == mode) return game.id;
    }
    final created = await repository.createGame(
      mode: mode,
      opponent: opponent ?? kGuestOpponent,
      opponentRating: opponent == null ? null : pebble.rating,
      // Who opens alternates by chance until ticket 007 introduces rematch
      // alternation; against the computer that means the player sometimes
      // arrives to find a piece already on the board.
      startingSeat: Random().nextInt(2),
    );
    return created.id;
  }

  Future<void> _open(
    BuildContext context,
    GameMode mode, {
    String? opponent,
  }) async {
    final id = await _resumeOrCreate(mode, opponent: opponent);
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(repository: repository, gameId: id),
      ),
    );
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
              // Choosing an opponent is ticket 011's screen; until then the
              // two modes are two buttons.
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _open(
                    context,
                    GameMode.vsComputer,
                    opponent: botOpponent(pebble.id),
                  ),
                  child: Text(l10n.playTheComputer),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: () => _open(context, GameMode.passAndPlay),
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
