import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrim/game/opponent_avatar.dart';
import 'package:quadrim/game/opponent_screen.dart';
import 'package:quadrim/l10n/app_localizations.dart';
import 'package:quadrim_engine/quadrim_engine.dart';
import 'package:quadrim_rating/quadrim_rating.dart';

Widget _app({int playerRating = kSeedRating, Locale? locale}) => MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: OpponentScreen(playerRating: playerRating),
    );

/// Pumps the screen into a viewport tall enough to build all twenty rows.
///
/// A `ListView` only builds what is visible, so on a phone-sized surface any
/// assertion about the seventh opponent is really an assertion about scrolling.
/// Making the surface tall keeps these tests about the list's *content*;
/// scrolling behaviour is Flutter's, and not this ticket's to prove.
Future<void> _pumpTall(
  WidgetTester tester, {
  int playerRating = kSeedRating,
  Locale? locale,
}) async {
  tester.view.physicalSize = const Size(1200, 6000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(playerRating: playerRating, locale: locale));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('every one of the twenty is listed', (tester) async {
    await _pumpTall(tester);
    for (final bot in opponentCatalogue) {
      expect(find.text(_expectedName(bot.id)), findsOneWidget,
          reason: '${bot.id} is missing from the list');
    }
  });

  testWidgets('each opponent shows an avatar, a rating and a blurb',
      (tester) async {
    await tester.pumpWidget(_app());
    // Pebble is first, so it is on screen without scrolling.
    expect(find.text('Pebble'), findsOneWidget);
    expect(find.text('600'), findsOneWidget);
    expect(find.textContaining('Has never noticed a threat'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(OpponentScreen),
        matching: find.byType(OpponentAvatar),
      ),
      findsWidgets,
    );
  });

  testWidgets('opponents are grouped under their tier headings',
      (tester) async {
    await tester.pumpWidget(_app());
    for (final label in ['Novice', 'Casual']) {
      expect(find.text(label), findsOneWidget, reason: '$label heading');
    }
    // Novice must come before Casual on screen, or the ladder reads backwards.
    final novice = tester.getTopLeft(find.text('Novice')).dy;
    final casual = tester.getTopLeft(find.text('Casual')).dy;
    expect(novice, lessThan(casual));
  });

  testWidgets('the player sees their own rating on this screen',
      (tester) async {
    await tester.pumpWidget(_app(playerRating: 1179));
    expect(find.textContaining('1179'), findsOneWidget);
  });

  testWidgets('a mismatch is distinguishable from a fair match',
      (tester) async {
    // A seeded player at 1200 meets all three bands in one roster: Pebble at
    // 600 is far below, Finch at 1100 is even, Quadrim Prime at 2400 is far
    // above. All three cues must appear, and differ.
    await _pumpTall(tester, playerRating: kSeedRating);
    expect(find.text('Below your level'), findsWidgets);
    expect(find.text('Even match'), findsWidgets);
    expect(find.text('Above your level'), findsWidgets);
    expect(find.byIcon(Icons.trending_down), findsWidgets);
    expect(find.byIcon(Icons.balance), findsWidgets);
    expect(find.byIcon(Icons.trending_up), findsWidgets);
  });

  testWidgets('the cue does not depend on colour alone', (tester) async {
    await tester.pumpWidget(_app());
    // Every balance cue carries an icon and a word beside its colour. Finding
    // the words is what proves a colour-blind player is not left guessing.
    final words = find.byWidgetPredicate(
      (w) =>
          w is Text &&
          const {'Even match', 'Above your level', 'Below your level'}
              .contains(w.data),
    );
    expect(words, findsWidgets);
  });

  testWidgets('tapping an opponent returns its configuration', (tester) async {
    BotConfig? chosen;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                chosen = await Navigator.of(context).push<BotConfig>(
                  MaterialPageRoute<BotConfig>(
                    builder: (_) =>
                        const OpponentScreen(playerRating: kSeedRating),
                  ),
                );
              },
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Twig'));
    await tester.pumpAndSettle();
    expect(chosen?.id, 'twig');
    expect(chosen?.rating, 700);
  });

  testWidgets('backing out chooses nobody', (tester) async {
    // The flow must cancel rather than fall back to a default opponent: a game
    // against somebody the player did not pick is worse than no game.
    var returned = 'unset';
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                final bot = await Navigator.of(context).push<BotConfig>(
                  MaterialPageRoute<BotConfig>(
                    builder: (_) =>
                        const OpponentScreen(playerRating: kSeedRating),
                  ),
                );
                returned = bot?.id ?? 'null';
              },
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(returned, 'null');
  });

  testWidgets('each opponent announces name, tier and strength as one unit',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_app(playerRating: kSeedRating));
    // One node per opponent carrying all four facts, rather than four nodes a
    // screen reader user must swipe through separately.
    expect(
      find.bySemanticsLabel(RegExp(r'Pebble\. Novice\. Rating 600\.')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp(r'Pebble\..*Below your level')),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('the heading survives the largest font setting', (tester) async {
    // Android's font slider reaches 200%. With a fixed-height strip under the
    // title, the AppBar grows upward to fit the larger text and pushes the
    // title off the top of the screen — measured at top = -1, overlapping the
    // rating line. Nothing errors, because neither is a flex; they just paint
    // over each other. Checked by measurement for that reason (D188).
    for (final scale in [1.0, 1.5, 2.0]) {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: const OpponentScreen(playerRating: 1182),
          ),
        ),
      );
      await tester.pump();
      final title = tester.getRect(find.text('Choose an opponent'));
      final rating = tester.getRect(find.text('Your rating: 1182'));
      expect(title.top, greaterThanOrEqualTo(0.0),
          reason: 'title clipped off the top at scale $scale');
      expect(title.bottom, lessThanOrEqualTo(rating.top),
          reason: 'title overlaps the rating line at scale $scale');
    }
  });

  testWidgets('the screen renders in Dutch', (tester) async {
    await tester.pumpWidget(_app(locale: const Locale('nl')));
    expect(find.text('Kies een tegenstander'), findsOneWidget);
    expect(find.text('Beginner'), findsOneWidget);
    // Names are never translated.
    expect(find.text('Pebble'), findsOneWidget);
  });
}

/// Opponent names are proper nouns and identical in both locales, so the
/// English catalogue id maps to the displayed name by capitalisation alone —
/// except Quadrim Prime, whose id carries an underscore.
String _expectedName(String id) => switch (id) {
      'quadrim_prime' => 'Quadrim Prime',
      _ => id[0].toUpperCase() + id.substring(1),
    };
