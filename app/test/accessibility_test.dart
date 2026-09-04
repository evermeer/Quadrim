import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:math';

import 'package:quadrim/data/document_store.dart';
import 'package:quadrim/data/local_game_repository.dart';
import 'package:quadrim/home/your_path.dart';
import 'package:quadrim/main.dart';
import 'package:quadrim/l10n/app_localizations.dart';
import 'package:quadrim/shop/shop.dart';
import 'package:quadrim/shop/shop_screen.dart';
import 'package:quadrim/theme.dart';

import 'shop_test.dart' show FakeStore;

/// Ticket 021: the cross-screen accessibility sweep, for the surfaces 047 added.
///
/// **Every earlier ticket carried its own accessibility criteria, and this is
/// still not redundant with them**: what per-ticket checks cannot see is a
/// screen where each control is individually correct and the set of them is
/// ambiguous. The shop is exactly that shape — two products, two buttons, and
/// nothing in either button saying which product it buys.
///
/// The guideline matchers are used rather than hand-written assertions because
/// they encode the platform minima that this project would otherwise be
/// restating from memory, and they fail with the offending node's rectangle
/// rather than with a boolean.
void main() {
  Future<void> pumpShop(
    WidgetTester tester, {
    double textScale = 1,
    Size size = const Size(360, 640),
    FakeStore? store,
  }) async {
    tester.view.physicalSize = size * tester.view.devicePixelRatio;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);

    final repo = await LocalGameRepository.open(MemoryDocumentStore());
    final shop = Shop(platform: store ?? FakeStore(), unlocks: repo);
    await shop.start();
    addTearDown(shop.dispose);

    await tester.pumpWidget(MaterialApp(
      theme: QuadrimTheme.forest,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: ShopScreen(shop: shop),
    ));
    await tester.pumpAndSettle();
  }

  group('the shop meets the platform guidelines', () {
    testWidgets('tap targets are large enough on Android', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpShop(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('tap targets are large enough on iOS', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpShop(tester);
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('every tappable thing carries a label', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpShop(tester);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('text contrast meets the guideline', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpShop(tester);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  });

  /// **The finding this file was written for.** `labeledTapTargetGuideline`
  /// passes on two buttons both labelled "Buy": a label is present, so the
  /// guideline is satisfied and a screen-reader user still cannot tell which
  /// product they are about to pay for. A guideline is a floor, not the goal.
  testWidgets('each buy button names the product it buys', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpShop(tester);

    // Read straight off each button's merged node: that string is what a
    // screen reader speaks. Walking the raw semantics tree would say the same
    // thing through two deprecated APIs.
    final buttons = find.byType(FilledButton);
    expect(buttons, findsNWidgets(2), reason: 'expected one button per product');

    final labels = <String>[
      for (var i = 0; i < buttons.evaluate().length; i++)
        tester.getSemantics(buttons.at(i)).label,
    ];

    expect(labels.where((l) => l.isEmpty), isEmpty,
        reason: 'a button announces nothing at all');
    expect(labels.toSet(), hasLength(labels.length),
        reason: 'two controls announce the same thing: $labels. A '
            'screen-reader user cannot tell them apart.');
    handle.dispose();
  });

  testWidgets('the shop survives the largest system font scale', (tester) async {
    await pumpShop(tester, textScale: 2);
    expect(tester.takeException(), isNull,
        reason: 'something overflowed at 2x text');
  });

  /// The main screen, on the smallest supported phone, at the largest system
  /// font scale, with everything present.
  ///
  /// **The ticket singles this out rather than trusting a general sweep**, and
  /// it is right to: the three-tile Your Path row is the tightest thing in the
  /// release, and a sweep that pumps each screen at its natural size would
  /// never reach the row where the six sections stop fitting.
  group('the main screen at the largest font scale', () {
    Future<LocalGameRepository> repo() =>
        LocalGameRepository.open(MemoryDocumentStore());

    Future<void> pumpHome(WidgetTester tester,
        {double textScale = 1, Size size = const Size(320, 568)}) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);
      final r = await repo();
      final settings = await r.loadSettings();
      // Otherwise the first-run tutorial prompt opens over the screen.
      await r.saveSettings(settings.copyWith(tutorialOffered: true));
      await tester.pumpWidget(QuadrimApp(
          repository: r, settings: r, unlocks: r, random: Random(1)));
      await tester.pumpAndSettle();
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
    }

    testWidgets('nothing overflows at 2x on a 320pt phone', (tester) async {
      await pumpHome(tester, textScale: 2);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a Your Path tile is one node, not six', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpHome(tester);

      // Each tile carries avatar, name, rating, record, stars and price. The
      // tile owns one label and excludes its children; six separate readings
      // is the failure this asserts against (AC 10).
      //
      // Found by its label rather than by its type: the tile is private, and
      // widening a widget's visibility so a test can name it is how a test
      // starts dictating the shape of the code it tests. The label pattern
      // ", rated " comes from `pathTileSemantics` and is what a screen reader
      // actually hears.
      final tiles = find.descendant(
        of: find.byType(YourPath),
        matching: find.byWidgetPredicate((w) =>
            w is Semantics &&
            (w.properties.label ?? '').contains(', rated ')),
      );
      expect(tiles, findsWidgets, reason: 'Your Path rendered no labelled tiles');

      for (var i = 0; i < tiles.evaluate().length; i++) {
        final node = tester.getSemantics(tiles.at(i));
        expect(node.label, isNotEmpty,
            reason: 'tile $i announces nothing at all');
        var children = 0;
        node.visitChildren((_) {
          children++;
          return true;
        });
        expect(children, 0,
            reason: 'tile $i has $children child nodes; it should be one node '
                'with one label, not a list of its parts');
      }
      handle.dispose();
    });

    testWidgets('the main screen meets the tap-target guidelines',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pumpHome(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });

  /// **The rest of the app at the largest system font scale.**
  ///
  /// Ticket 021 carried this forward as a known gap: the shop and the main
  /// screen were swept at 2x and nothing else was. The gap mattered because U20
  /// is a per-*screen* promise and the two screens that had been checked are the
  /// two that were built most recently — the tutorial, the opponent list, the
  /// board and settings all predate the font-scale rule being tested at all.
  ///
  /// Each case drives the real app rather than pumping a screen in isolation,
  /// because the failure this is looking for is a `RenderFlex` overflow, and an
  /// overflow only happens against real constraints. `takeException()` is the
  /// assertion: Flutter reports an overflow as a thrown exception in a test, so
  /// a screen that fits leaves it null and a screen that does not names itself.
  group('every remaining screen at the largest font scale', () {
    Future<void> pumpAppAt2x(WidgetTester tester,
        {Size size = const Size(320, 568)}) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);
      final r = await LocalGameRepository.open(MemoryDocumentStore());
      final settings = await r.loadSettings();
      await r.saveSettings(settings.copyWith(tutorialOffered: true));
      await tester.pumpWidget(QuadrimApp(
          repository: r, settings: r, unlocks: r, random: Random(1)));
      await tester.pumpAndSettle();
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
    }

    /// Taps the first widget carrying [label] and settles.
    ///
    /// By text rather than by key: the label is what a player reads and what a
    /// screen reader announces, so a test that can no longer find it is telling
    /// us something either way.
    Future<void> tapText(WidgetTester tester, String label) async {
      final target = find.text(label);
      expect(target, findsWidgets, reason: 'no "$label" to tap');
      await tester.tap(target.first);
      await tester.pumpAndSettle();
    }

    testWidgets('the tutorial, every step of it', (tester) async {
      await pumpAppAt2x(tester);
      await tapText(tester, 'Tutorial');
      expect(tester.takeException(), isNull, reason: 'tutorial step 1');

      // Walk to the end rather than sampling: the steps have different shapes
      // -- prose, a board, an interactive practice game -- and the tallest one
      // is the one that overflows.
      for (var step = 2;; step++) {
        final next = find.text('Next');
        if (next.evaluate().isEmpty) break;
        await tester.tap(next.first);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'tutorial step $step');
      }
    });

    testWidgets('settings', (tester) async {
      await pumpAppAt2x(tester);
      // Settings is the app bar's icon button, not a labelled row.
      await tester.tap(find.byType(IconButton).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'settings');
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -800));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'settings, scrolled');
    });

    testWidgets('the new-game sheet, the opponent list and the board',
        (tester) async {
      await pumpAppAt2x(tester);
      await tapText(tester, 'New game');
      expect(tester.takeException(), isNull, reason: 'the new-game sheet');

      await tapText(tester, 'Play the computer');
      expect(tester.takeException(), isNull, reason: 'the opponent list');

      // Hazel is the weakest opponent a fresh install offers and the first in
      // the list -- which is what a new player is looking at here. It was
      // Pebble until D382 held the three rungs below Hazel back until a loss
      // asks for one, so they are not on this screen at all.
      await tester.tap(find.text('Hazel').first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'the board');
    });

    testWidgets('pass and play', (tester) async {
      await pumpAppAt2x(tester);
      await tapText(tester, 'New game');
      await tapText(tester, 'Pass and play');
      expect(tester.takeException(), isNull, reason: 'the pass-and-play board');
    });
  });
}
