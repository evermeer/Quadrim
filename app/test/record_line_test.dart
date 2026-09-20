import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrim/data/home_summary.dart';
import 'package:quadrim/home/rating_card.dart';
import 'package:quadrim/home/section_widgets.dart';
import 'package:quadrim/l10n/app_localizations.dart';
import 'package:quadrim/theme.dart';

/// D385: a record with no draws in it does not say so.
///
/// **The app has been live for weeks and the draw count has been zero on
/// essentially every device**, because filling all sixty-four cells against an
/// opponent that is trying to win is very hard. So "0 drawn" was not an edge
/// case the layout had to survive — it was what the line said, permanently, to
/// almost everybody.
///
/// Both branches are asserted in both languages. A conditional string is two
/// strings, and the one that is wrong is always the branch nobody looked at.
void main() {
  Future<AppLocalizations> l10nFor(String locale) =>
      AppLocalizations.delegate.load(Locale(locale));

  OpponentRecord record({required int wins, required int losses, int draws = 0}) =>
      OpponentRecord(
        opponent: 'bot:pebble',
        rating: 600,
        wins: wins,
        losses: losses,
        draws: draws,
      );

  group('an opponent record', () {
    for (final locale in ['en', 'nl']) {
      test('drops the draws when there are none ($locale)', () async {
        final l10n = await l10nFor(locale);
        final line = opponentRecordLine(l10n, record(wins: 3, losses: 2));

        expect(line, contains('3'));
        expect(line, contains('2'));
        // Five games, no third number. Asserted as the *shape* rather than as
        // the exact string so the separator and the word order stay the
        // translator's business.
        expect(RegExp(r'\d+').allMatches(line).map((m) => m.group(0)),
            ['3', '2', '5'],
            reason: 'a zero draw count is still being rendered: $line');
      });

      test('keeps the draws when there are some ($locale)', () async {
        final l10n = await l10nFor(locale);
        final line = opponentRecordLine(l10n, record(wins: 3, losses: 2, draws: 1));

        expect(RegExp(r'\d+').allMatches(line).map((m) => m.group(0)),
            ['3', '2', '1', '6'],
            reason: 'the draw is missing from a record that has one: $line');
      });

      /// **One game is "1 game", not "1 games".** The count had no plural form
      /// until D385's change made the line short enough for the error to be the
      /// conspicuous thing on it — it read "0–1 in 1 games" on a first loss,
      /// which is the most common record a new player has.
      test('says one game in the singular ($locale)', () async {
        final l10n = await l10nFor(locale);
        final line = opponentRecordLine(l10n, record(wins: 0, losses: 1));

        expect(line, isNot(contains(locale == 'nl' ? '1 partijen' : '1 games')),
            reason: 'the game count has no plural form: $line');
        expect(line, contains(locale == 'nl' ? '1 partij' : '1 game'));
      });

      /// The other side of the plural, so a form that hard-codes the singular
      /// fails too.
      test('says several games in the plural ($locale)', () async {
        final l10n = await l10nFor(locale);
        final line = opponentRecordLine(l10n, record(wins: 1, losses: 1));

        expect(line, contains(locale == 'nl' ? '2 partijen' : '2 games'));
      });
    }
  });

  group('the rating card', () {
    Future<void> pump(WidgetTester tester, {required int draws}) async {
      tester.view.physicalSize = const Size(1080, 2280);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        theme: QuadrimTheme.forest,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: RatingCard(
            summary: HomeSummary(
              wins: 4,
              losses: 1,
              draws: draws,
              computerRating: 812,
              points: 0,
              byOpponent: const [],
            ),
            balance: 0,
            streak: 0,
            series: const [],
          ),
        ),
      ));
      await tester.pumpAndSettle();
    }

    /// The card builds its own line rather than going through
    /// [opponentRecordLine] — it has three numbers and no game count, so it is
    /// a different string. Which means it is a second place to get this wrong.
    testWidgets('says nothing about draws when there are none', (tester) async {
      await pump(tester, draws: 0);
      expect(find.textContaining('drawn'), findsNothing);
      // The whole line, exactly. `textContaining('0')` was tried here and is
      // the wrong assertion: the card also draws a points balance and a streak,
      // both of which are legitimately zero.
      expect(find.text('4 won · 1 lost'), findsOneWidget);
    });

    testWidgets('says how many there were when there are some', (tester) async {
      await pump(tester, draws: 2);
      expect(find.textContaining('drawn'), findsOneWidget);
    });
  });
}
