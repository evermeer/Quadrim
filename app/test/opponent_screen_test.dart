import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrim/game/opponent_avatar.dart';
import 'package:quadrim/game/opponent_screen.dart';
import 'package:quadrim/l10n/app_localizations.dart';
import 'package:quadrim_engine/quadrim_engine.dart';
import 'package:quadrim_rating/quadrim_rating.dart';

const _delegates = <LocalizationsDelegate<Object>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

Widget _app({int playerRating = kSeedRating, Locale? locale}) => MaterialApp(
      locale: locale,
      localizationsDelegates: _delegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: OpponentScreen(playerRating: playerRating),
    );

/// Pumps the screen into a viewport tall enough to build an open section in
/// full. A `ListView` only builds what is visible, so on a phone-sized surface
/// an assertion about the fifth opponent in a section is really an assertion
/// about scrolling — which is Flutter's behaviour, not this ticket's.
Future<void> _pumpTall(
  WidgetTester tester, {
  int playerRating = kSeedRating,
  Locale? locale,
}) async {
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(playerRating: playerRating, locale: locale));
  await tester.pumpAndSettle();
}

String _name(String id) => switch (id) {
      'quadrim_prime' => 'Quadrim Prime',
      _ => id[0].toUpperCase() + id.substring(1),
    };

const _tierLabels = {
  BotTier.novice: 'Novice',
  BotTier.casual: 'Casual',
  BotTier.club: 'Club',
  BotTier.expert: 'Expert',
  BotTier.master: 'Master',
};

Future<void> _openTier(WidgetTester tester, BotTier tier) async {
  await tester.tap(find.text(_tierLabels[tier]!));
  await tester.pumpAndSettle();
}

void main() {
  group('the accordion', () {
    testWidgets('opens the tier nearest the player and no other',
        (tester) async {
      // A seeded player at 1200 sits on Vireo exactly, so Casual opens.
      await _pumpTall(tester, playerRating: kSeedRating);
      expect(find.text('Vireo'), findsOneWidget);
      expect(find.text('Pebble'), findsNothing, reason: 'Novice must be shut');
      expect(find.text('Titan'), findsNothing, reason: 'Expert must be shut');
    });

    testWidgets('every tier heading is present even when shut', (tester) async {
      // The five headings are the ladder. Collapsing a section must not hide
      // that it exists, or a beginner never learns there is anything above.
      await _pumpTall(tester);
      for (final label in _tierLabels.values) {
        expect(find.text(label), findsOneWidget, reason: '$label heading');
      }
    });

    testWidgets('a weak player opens on Novice, a strong one on Master',
        (tester) async {
      await _pumpTall(tester, playerRating: 620);
      expect(find.text('Pebble'), findsOneWidget);
      expect(find.text('Quadrim Prime'), findsNothing);

      await _pumpTall(tester, playerRating: 2400);
      expect(find.text('Quadrim Prime'), findsOneWidget);
      expect(find.text('Pebble'), findsNothing);
    });

    testWidgets('opening one closes the one that was open', (tester) async {
      await _pumpTall(tester);
      expect(find.text('Vireo'), findsOneWidget);

      await _openTier(tester, BotTier.master);
      expect(find.text('Oracle'), findsOneWidget);
      expect(find.text('Vireo'), findsNothing,
          reason: 'Casual should have closed when Master opened');

      await _openTier(tester, BotTier.novice);
      expect(find.text('Pebble'), findsOneWidget);
      expect(find.text('Oracle'), findsNothing);
    });

    testWidgets('tapping the open tier closes it', (tester) async {
      await _pumpTall(tester);
      expect(find.text('Vireo'), findsOneWidget);
      await _openTier(tester, BotTier.casual);
      expect(find.text('Vireo'), findsNothing);
      // All five headings survive with nothing open.
      for (final label in _tierLabels.values) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('each heading says how many it holds', (tester) async {
      // 4 / 5 / 5 / 4 / 2 — so a shut section still tells you its size.
      await _pumpTall(tester);
      for (final tier in BotTier.values) {
        final count = opponentCatalogue.where((b) => b.tier == tier).length;
        expect(
          find.descendant(
            of: find.ancestor(
              of: find.text(_tierLabels[tier]!),
              matching: find.byType(Row),
            ),
            matching: find.text('$count'),
          ),
          findsWidgets,
          reason: '${_tierLabels[tier]} should show $count',
        );
      }
    });
  });

  testWidgets('every one of the twenty is reachable', (tester) async {
    await _pumpTall(tester);
    for (final tier in BotTier.values) {
      await _openTier(tester, tier);
      for (final bot in opponentCatalogue.where((b) => b.tier == tier)) {
        expect(find.text(_name(bot.id)), findsOneWidget,
            reason: '${bot.id} is missing from ${_tierLabels[tier]}');
      }
    }
  });

  testWidgets('each opponent shows an avatar, a rating and a blurb',
      (tester) async {
    await _pumpTall(tester, playerRating: 620);
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

  testWidgets('the player sees their own rating on this screen',
      (tester) async {
    await _pumpTall(tester, playerRating: 1179);
    expect(find.textContaining('1179'), findsOneWidget);
  });

  testWidgets('a mismatch is distinguishable from a fair match',
      (tester) async {
    // One tier is open at a time, so the three bands are checked where each
    // actually occurs for a seeded player: Novice is far below, Casual is
    // even, Master is far above.
    await _pumpTall(tester, playerRating: kSeedRating);
    expect(find.text('Even match'), findsWidgets);
    expect(find.byIcon(Icons.balance), findsWidgets);

    await _openTier(tester, BotTier.novice);
    expect(find.text('Below your level'), findsWidgets);
    expect(find.byIcon(Icons.trending_down), findsWidgets);

    await _openTier(tester, BotTier.master);
    expect(find.text('Above your level'), findsWidgets);
    expect(find.byIcon(Icons.trending_up), findsWidgets);
  });

  testWidgets('the cue does not depend on colour alone', (tester) async {
    await _pumpTall(tester);
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
        localizationsDelegates: _delegates,
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
    // Vireo is in the tier that opens for a seeded player.
    await tester.tap(find.text('Vireo'));
    await tester.pumpAndSettle();
    expect(chosen?.id, 'vireo');
    expect(chosen?.rating, 1200);
  });

  testWidgets('backing out chooses nobody', (tester) async {
    var returned = 'unset';
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: _delegates,
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
    await _pumpTall(tester, playerRating: 620);
    expect(
      find.bySemanticsLabel(RegExp(r'Pebble\. Novice\. Rating 600\.')),
      findsOneWidget,
    );
    // At 620 the player is level with Pebble, so the announcement says so —
    // the band is a real comparison, not a decoration that always reads
    // "below" for the weakest opponent.
    expect(
      find.bySemanticsLabel(RegExp(r'Pebble\..*Even match')),
      findsOneWidget,
    );

    // The same opponent, announced to a seeded player, is far below them.
    await _pumpTall(tester, playerRating: kSeedRating);
    await _openTier(tester, BotTier.novice);
    expect(
      find.bySemanticsLabel(RegExp(r'Pebble\..*Below your level')),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('a shut tier announces itself as collapsed', (tester) async {
    // Otherwise a screen reader user meets five words and no way to know a
    // list is behind them.
    final handle = tester.ensureSemantics();
    await _pumpTall(tester, playerRating: kSeedRating);
    // Tristate, not a bool: `none` would mean the header claims no expandable
    // state at all, which is the failure worth catching — a screen reader user
    // would then meet five words with no hint that lists are behind them.
    final expert = tester.getSemantics(find.text('Expert')).flagsCollection;
    expect(expert.isExpanded, Tristate.isFalse);
    final casual = tester.getSemantics(find.text('Casual')).flagsCollection;
    expect(casual.isExpanded, Tristate.isTrue);
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
          localizationsDelegates: _delegates,
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
    await _pumpTall(tester, locale: const Locale('nl'));
    expect(find.text('Kies een tegenstander'), findsOneWidget);
    expect(find.text('Beginner'), findsOneWidget);
    expect(find.text('Vireo'), findsOneWidget);
  });

  group('tierNearest', () {
    test('picks the tier of the closest opponent, not a rating band', () {
      // Not a band table: tier is stored precisely so a recalibration cannot
      // reclassify anybody (D179), and a band here would reintroduce that
      // coupling. Asking who is nearest needs no table.
      expect(tierNearest(600), BotTier.novice);
      expect(tierNearest(1200), BotTier.casual);
      expect(tierNearest(1650), BotTier.club);
      expect(tierNearest(2100), BotTier.expert);
      expect(tierNearest(2400), BotTier.master);
    });

    test('a rating outside the catalogue clamps to an end', () {
      // The rating floor is 100 and nothing stops a player climbing past
      // Prime, so both ends must resolve rather than throw.
      expect(tierNearest(kRatingFloor), BotTier.novice);
      expect(tierNearest(0), BotTier.novice);
      expect(tierNearest(9999), BotTier.master);
    });

    test('the midpoint between two tiers resolves without throwing', () {
      // 1350 is exactly between Kestrel (1300) and Marlin (1400). Whichever it
      // picks, it must pick one — the first wins on a tie, which is Casual.
      expect(tierNearest(1350), BotTier.casual);
    });
  });
}
