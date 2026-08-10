import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrim/data/document_store.dart';
import 'package:quadrim/data/documents.dart';
import 'package:quadrim/data/local_game_repository.dart';
import 'package:quadrim/l10n/app_localizations.dart';
import 'package:quadrim/main.dart';

/// A repository whose first-launch tutorial offer has already been made.
///
/// Every screen test that is not about the offer has to say so: a fresh
/// settings document means a fresh player, and a fresh player is shown the
/// dialog over whatever the test came to look at.
Future<LocalGameRepository> _repository() async {
  final repository = await LocalGameRepository.open(MemoryDocumentStore());
  addTearDown(repository.dispose);
  await repository
      .saveSettings(const SettingsDocument(tutorialOffered: true));
  return repository;
}

void main() {
  testWidgets('the main screen renders localized strings', (tester) async {
    final repo = await _repository();
    await tester.pumpWidget(QuadrimApp(repository: repo, settings: repo));
    await tester.pumpAndSettle();
    expect(find.text('Quadrim'), findsOneWidget);
    expect(find.text('New game'), findsOneWidget);
  });

  testWidgets('Dutch locale renders Dutch strings, not the English fallback',
      (tester) async {
    final repo = await _repository();
    await tester.pumpWidget(QuadrimApp(
        repository: repo, settings: repo, locale: const Locale('nl')));
    await tester.pumpAndSettle();
    expect(find.text('Nieuwe partij'), findsOneWidget);
    expect(find.text('New game'), findsNothing);
  });

  test('both locales are wired', () {
    expect(
      AppLocalizations.supportedLocales.map((l) => l.languageCode),
      containsAll(['en', 'nl']),
    );
  });
}
