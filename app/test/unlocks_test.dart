import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrim/data/document_store.dart';
import 'package:quadrim/data/documents.dart';
import 'package:quadrim/data/local_game_repository.dart';
import 'package:quadrim/home/your_path.dart';
import 'package:quadrim/main.dart';
import 'package:quadrim_engine/quadrim_engine.dart';
import 'package:quadrim_progression/quadrim_progression.dart';

/// The package's arithmetic is proven in `packages/quadrim_progression`. What
/// is proven here is the record, the rule the repository enforces, and what
/// the screen does with both.

Future<LocalGameRepository> _repository([DocumentStore? store]) async {
  var tick = DateTime.utc(2026, 1, 1);
  final repo = await LocalGameRepository.open(
    store ?? MemoryDocumentStore(),
    now: () => tick = tick.add(const Duration(seconds: 1)),
  );
  addTearDown(repo.dispose);
  await repo.saveSettings(const SettingsDocument(tutorialOffered: true));
  return repo;
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
}

const _lightWinsMoves = [0, 21, 1, 22, 2, 26, 3];

/// Wins [count] games against [botId], which is how points get earned.
Future<void> _win(LocalGameRepository repo, String botId, int count) async {
  for (var i = 0; i < count; i++) {
    final game = await repo.createGame(
      mode: GameMode.vsComputer,
      opponent: botOpponent(botId),
      opponentRating: 1000,
    );
    for (final move in _lightWinsMoves) {
      await repo.appendMove(game.id, move);
    }
  }
}

/// Scrolls Your Path until [name]'s tile is on screen.
///
/// The row carries all thirty-one opponents now, so a tile outside the resting
/// window is built but off screen and cannot be tapped until the row is
/// scrolled — the way a player reaches it (D287).
Future<void> scrollTo(WidgetTester tester, String name) async {
  await tester.ensureVisible(tileFor(name));
  await tester.pumpAndSettle();
}

/// [name]'s tile, scoped to the row. An opponent's name also appears on every
/// game row against them, so a bare text finder is ambiguous the moment the
/// player has played anyone twice.
Finder tileFor(String name) =>
    find.descendant(of: find.byType(YourPath), matching: find.text(name));

void main() {
  group('the record', () {
    test('round-trips through JSON', () {
      final unlock = UnlockDocument(
        opponentId: 'juniper',
        unlockedAt: DateTime.utc(2026, 8, 14, 9, 12, 31),
        pricePaid: 256,
      );
      final back = UnlockDocument.fromJson(unlock.toJson())!;
      expect(back.opponentId, 'juniper');
      expect(back.pricePaid, 256);
      expect(back.source, UnlockSource.points);
      expect(back.unlockedAt, unlock.unlockedAt);
    });

    test('a version newer than this build understands is skipped', () {
      final json = UnlockDocument(
        opponentId: 'willow',
        unlockedAt: DateTime.utc(2026),
        pricePaid: 64,
      ).toJson()
        ..['schemaVersion'] = kSchemaVersion + 1;
      expect(UnlockDocument.fromJson(json), isNull);
    });

    test('a damaged record is skipped rather than thrown', () {
      expect(UnlockDocument.fromJson({'schemaVersion': 1}), isNull);
      expect(
          UnlockDocument.fromJson({
            'schemaVersion': 1,
            'opponentId': 'juniper',
            'unlockedAt': 'not a date',
            'pricePaid': 256,
          }),
          isNull);
    });
  });

  group('the repository', () {
    test('records what was paid, not what the table says', () async {
      final repo = await _repository();
      // Deliberately not unlockCost(7): the stored price is what was actually
      // charged, so a later re-tune cannot rewrite it (spec §8.8).
      final unlock = await repo.purchase('juniper', pricePaid: 40);
      expect(unlock.pricePaid, 40);
      expect((await repo.loadUnlocks()).single.pricePaid, 40);
    });

    test('only the next opponent in roster order may be bought', () async {
      final repo = await _repository();
      // Juniper is index 7 and the first locked one. Bracken is 8 (D325).
      expect(() => repo.purchase('bracken', pricePaid: 512),
          throwsA(isA<ArgumentError>()));
      await repo.purchase('juniper', pricePaid: 256);
      await repo.purchase('bracken', pricePaid: 512);
      expect((await repo.loadUnlocks()).map((u) => u.opponentId),
          ['juniper', 'bracken']);
    });

    test('a free opponent cannot be bought at all', () async {
      final repo = await _repository();
      expect(() => repo.purchase('pebble', pricePaid: 1),
          throwsA(isA<StateError>()));
    });

    test('buying the same opponent twice is refused', () async {
      final repo = await _repository();
      await repo.purchase('juniper', pricePaid: 256);
      expect(() => repo.purchase('juniper', pricePaid: 256),
          throwsA(isA<StateError>()));
      expect(await repo.loadUnlocks(), hasLength(1));
    });

    test('survives a restart, which is what the backup allowlist protects',
        () async {
      // The store is the same object, standing in for the same directory. The
      // unlock is the one thing here a player cannot regenerate by playing.
      final store = MemoryDocumentStore();
      final first = await _repository(store);
      await first.purchase('juniper', pricePaid: 256);

      final reopened = await _repository(store);
      final unlocks = await reopened.loadUnlocks();
      expect(unlocks.single.opponentId, 'juniper');
      expect(unlocks.single.pricePaid, 256);
    });

    test('the balance survives a re-tune of the cost table', () async {
      final repo = await _repository();
      await _win(repo, 'bramble', 4); // 4 * 64 = 256
      await repo.purchase('juniper', pricePaid: 256);
      final unlocks = await repo.loadUnlocks();
      final prices = [for (final u in unlocks) u.pricePaid];

      expect(balance(earned: 256, pricesPaid: prices), 0);
      // If the table later said 96, the player is not retroactively 32 in debt.
      expect(balance(earned: 256, pricesPaid: prices), isNonNegative);
    });
  });

  group('Your Path', () {
    testWidgets('rests on the first opponent rated above the player',
        (tester) async {
      _phone(tester);
      final repo = await _repository();
      await tester.pumpWidget(QuadrimApp(
          repository: repo, settings: repo, unlocks: repo, random: Random(1)));
      await tester.pumpAndSettle();

      expect(find.byType(YourPath), findsOneWidget);
      // This was the D262 test, inverted. A player seeded at 800 now rests on
      // Hazel — the lowest-rated opponent rated *strictly above* 800, since the
      // recut put one at 850 (D325) — with Mote one tile left and Clover one
      // right. D262 refused this because a fixed window would have hidden the
      // price ladder; the row scrolls now, so the ladder is one swipe right
      // instead of invisible (D287).
      for (final name in ['Mote', 'Hazel', 'Clover']) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
      // Mote is rated exactly 800 and sits to the left, not in the middle: an
      // even match is not "next".
      expect(tester.getRect(find.text('Mote')).left,
          lessThan(tester.getRect(find.text('Hazel')).left));
      // Juniper, the next unlock, is built but off screen until the player
      // scrolls — the row holds all thirty-one, so it exists without being
      // visible.
      // The scrolling row, not the whole section: `YourPath` is laid out at the
      // full width of the screen so its arrows can hang off the panel, and its
      // rect therefore runs past the row on both sides (D319).
      final viewport = tester.getRect(find.descendant(
          of: find.byType(YourPath), matching: find.byType(Scrollable)));
      expect(tester.getRect(find.text('Juniper')).left,
          greaterThan(viewport.right),
          reason: 'off the right-hand edge until scrolled to');
      await scrollTo(tester, 'Juniper');
      expect(tester.getRect(find.text('Juniper')).left,
          lessThan(viewport.right));
    });

    testWidgets('a locked tile shows its price and the progress toward it',
        (tester) async {
      _phone(tester);
      final repo = await _repository();
      await tester.pumpWidget(QuadrimApp(
          repository: repo, settings: repo, unlocks: repo, random: Random(1)));
      await tester.pumpAndSettle();

      await scrollTo(tester, 'Juniper');
      expect(find.text('256 points'), findsOneWidget,
          reason: "Juniper's price");
      expect(find.text('0 of 256'), findsOneWidget);
      // The unlock button exists but cannot be pressed on nothing.
      final button = tester.widget<ButtonStyleButton>(
          find.widgetWithText(FilledButton, 'Unlock'));
      expect(button.onPressed, isNull, reason: 'nothing earned yet');
    });

    testWidgets('earning the price makes the unlock available, and buying it '
        'advances the window', (tester) async {
      _phone(tester);
      final repo = await _repository();
      await _win(repo, 'bramble', 4);
      await tester.pumpWidget(QuadrimApp(
          repository: repo, settings: repo, unlocks: repo, random: Random(1)));
      await tester.pumpAndSettle();

      await scrollTo(tester, 'Juniper');
      expect(find.text('256 of 256'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Unlock'));
      await tester.pumpAndSettle();

      // The confirmation says what it costs and what is left.
      expect(find.text('Unlock Juniper?'), findsOneWidget);
      expect(find.text('This costs 256 points and leaves you 0.'),
          findsOneWidget);
      // Scoped to the dialog: the tile behind it still carries an Unlock
      // button of its own, so a bare finder matches two.
      await tester.tap(find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(FilledButton, 'Unlock')));
      await tester.pumpAndSettle();

      expect((await repo.loadUnlocks()).single.opponentId, 'juniper');
      // The window slid: Juniper is now owned and Bracken is next.
      expect(find.text('512 points'), findsOneWidget,
          reason: "Bracken's price");
    });

    testWidgets('progress is the balance, not the earned total', (tester) async {
      // Reported from a device against the shipped build: Your Path showed
      // "256 of 256" toward Finch to a player holding 64 points, with a full
      // bar and a button that did nothing. It read `summary.points` — the
      // *earned* total, which keeps rising as unlocks are bought — where every
      // other surface took the balance (D316).
      //
      // Every earlier test here spends nothing, so earned and balance are the
      // same number and the defect is invisible. This one spends.
      _phone(tester);
      final repo = await _repository();
      await _win(repo, 'bramble', 16); // 16 x 64 = 1024 earned
      await repo.purchase('juniper', pricePaid: 256);
      await repo.purchase('bracken', pricePaid: 512); // 768 spent, 256 left
      await tester.pumpWidget(QuadrimApp(
          repository: repo, settings: repo, unlocks: repo, random: Random(1)));
      await tester.pumpAndSettle();

      await scrollTo(tester, 'Willow');
      expect(find.text('256 of 1,024'), findsOneWidget,
          reason: 'the spendable balance');
      expect(find.text('1,024 of 1,024'), findsNothing,
          reason: 'the earned total, which is what the bug displayed');

      final button = tester.widget<ButtonStyleButton>(
          find.widgetWithText(FilledButton, 'Unlock'));
      expect(button.onPressed, isNull,
          reason: '256 does not buy a 1,024-point unlock');
    });

    testWidgets('the arrows step the row one tile and fade at the ends',
        (tester) async {
      // The row fits exactly three tiles, so nothing on screen says there are
      // twenty-eight more. The arrows are what says it, and one tap is one tile
      // (D318).
      _phone(tester);
      final repo = await _repository();
      await tester.pumpWidget(QuadrimApp(
          repository: repo, settings: repo, unlocks: repo, random: Random(1)));
      await tester.pumpAndSettle();

      final left = find.bySemanticsLabel('Show weaker opponents');
      final right = find.bySemanticsLabel('Show stronger opponents');
      // The pitch, measured off two adjacent cards rather than recomputed from
      // the tile arithmetic — a test that repeated that sum would pass whatever
      // the sum came out as. Off the *cards*, not the names on them: a name is
      // centred in its tile, so two names are a tile apart plus half the
      // difference in how long they are.
      // `.first` is the tile's own card; the section's parchment panel is a
      // Card too and is the other ancestor.
      Rect card(String name) => tester.getRect(
          find.ancestor(of: find.text(name), matching: find.byType(Card)).first);
      // Mote and Hazel, which are adjacent: Clover is two tiles from Mote
      // since the recut put Hazel between them (D325).
      final pitch = card('Hazel').left - card('Mote').left;
      final before = tester.getRect(find.text('Hazel')).left;

      await tester.tap(right);
      await tester.pumpAndSettle();
      expect(tester.getRect(find.text('Hazel')).left,
          closeTo(before - pitch, 0.5));

      await tester.tap(left);
      await tester.pumpAndSettle();
      expect(tester.getRect(find.text('Hazel')).left, closeTo(before, 0.5));

      // Two more lefts reach Pebble, the weakest, and there the left arrow has
      // nowhere to go.
      await tester.tap(left);
      await tester.pumpAndSettle();
      await tester.tap(left);
      await tester.pumpAndSettle();
      expect(card('Pebble').left, closeTo(card('Twig').left - pitch, 0.5),
          reason: 'the weakest opponent, at the left edge');

      // Faded out, and not merely invisible: an arrow that still took the tap
      // would swallow a press meant for the tile it is sitting on.
      final arrows = find.descendant(
          of: find.byType(YourPath), matching: find.byType(AnimatedOpacity));
      expect(tester.widget<AnimatedOpacity>(arrows.first).opacity, 0);
      expect(
          tester
              .widget<IgnorePointer>(find
                  .ancestor(
                      of: arrows.first, matching: find.byType(IgnorePointer))
                  .first)
              .ignoring,
          isTrue);
      // The right one is still live, because there are seventeen tiles that
      // way.
      expect(tester.widget<AnimatedOpacity>(arrows.last).opacity, greaterThan(0),
          reason: 'translucent, but not faded out');
    });

    testWidgets('cancelling the confirmation buys nothing', (tester) async {
      _phone(tester);
      final repo = await _repository();
      await _win(repo, 'bramble', 4);
      await tester.pumpWidget(QuadrimApp(
          repository: repo, settings: repo, unlocks: repo, random: Random(1)));
      await tester.pumpAndSettle();

      await scrollTo(tester, 'Juniper');
      await tester.tap(find.widgetWithText(FilledButton, 'Unlock'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(await repo.loadUnlocks(), isEmpty);
    });

    testWidgets('the balance on the card is earned minus spent',
        (tester) async {
      _phone(tester);
      final repo = await _repository();
      await _win(repo, 'bramble', 5); // 320 earned
      await repo.purchase('juniper', pricePaid: 256);
      await tester.pumpWidget(QuadrimApp(
          repository: repo, settings: repo, unlocks: repo, random: Random(1)));
      await tester.pumpAndSettle();

      expect(find.text('64'), findsOneWidget,
          reason: '320 earned, 256 spent');
    });

    testWidgets('an opponent never faced shows no star row', (tester) async {
      _phone(tester);
      final repo = await _repository();
      await tester.pumpWidget(QuadrimApp(
          repository: repo, settings: repo, unlocks: repo, random: Random(1)));
      await tester.pumpAndSettle();

      // The three resting tiles are all unlocked and unplayed: each says so
      // rather than drawing three empty stars, because unearned and failed
      // must not look the same.
      // Seven: the free set, all unlocked and none played. The row builds
      // every tile, so this counts the roster rather than what is on screen —
      // and the recut put two more opponents under the 1000 ceiling (D325).
      expect(find.text('Not played yet'), findsNWidgets(7));
      expect(find.byIcon(Icons.star_border), findsNothing);
    });

    testWidgets('a tile is one announced node carrying its locked state',
        (tester) async {
      _phone(tester);
      final handle = tester.ensureSemantics();
      final repo = await _repository();
      await tester.pumpWidget(QuadrimApp(
          repository: repo, settings: repo, unlocks: repo, random: Random(1)));
      await tester.pumpAndSettle();

      // Grey alone is not a fact a screen reader can read, so the tile says it.
      await scrollTo(tester, 'Juniper');
      expect(
        find.bySemanticsLabel(
            RegExp(r'Juniper, rated 1020\. Locked\. 256 points, you have 0\.')),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('the two Master opponents', () {
    testWidgets('their confirmation repeats "unbeatable when it moves first"',
        (tester) async {
      _phone(tester);
      final repo = await _repository();
      // Buy the whole ladder up to Oracle, then earn its price. Oracle is
      // index 29 since the recut, and the free set reaches index 6 (D325).
      for (var i = 7; i < 29; i++) {
        await repo.purchase(opponentCatalogue[i].id, pricePaid: 0);
      }
      await _win(repo, 'titan', 4); // 4 * 2^28 = Oracle's price
      await tester.pumpWidget(QuadrimApp(
          repository: repo, settings: repo, unlocks: repo, random: Random(1)));
      await tester.pumpAndSettle();

      await scrollTo(tester, 'Oracle');
      // Only the next unlock carries a button, so there is exactly one on the
      // row however many locked tiles are in view.
      final button = find.widgetWithText(FilledButton, 'Unlock');
      expect(button, findsOneWidget);
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.text('Unlock Oracle?'), findsOneWidget);
      expect(
        find.textContaining('unbeatable when it moves first'),
        findsOneWidget,
        reason: 'spec §6.6 and D181: the player must be told before spending, '
            'not only in a store listing',
      );
    });
  });
}
