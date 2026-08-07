import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrim/l10n/app_localizations.dart';
import 'package:quadrim/main.dart';

void main() {
  testWidgets('placeholder home renders localized strings', (tester) async {
    await tester.pumpWidget(const QuadrimApp());
    expect(find.text('Quadrim'), findsOneWidget);
    expect(find.text('Four in a row, stacked in a cube.'), findsOneWidget);
  });

  testWidgets('Dutch locale renders Dutch strings, not the English fallback',
      (tester) async {
    await tester.pumpWidget(const QuadrimApp(locale: Locale('nl')));
    expect(find.text('Vier op een rij, gestapeld in een kubus.'), findsOneWidget);
    expect(find.text('Four in a row, stacked in a cube.'), findsNothing);
  });

  test('both locales are wired', () {
    expect(
      AppLocalizations.supportedLocales.map((l) => l.languageCode),
      containsAll(['en', 'nl']),
    );
  });
}
