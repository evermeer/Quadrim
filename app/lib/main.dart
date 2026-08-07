import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'game/game_screen.dart';
import 'l10n/app_localizations.dart';
import 'theme.dart';

void main() {
  runApp(const QuadrimApp());
}

class QuadrimApp extends StatelessWidget {
  const QuadrimApp({super.key, this.locale});

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
      home: const _PlaceholderHome(),
    );
  }
}

class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

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
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => const GameScreen()),
                  ),
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
