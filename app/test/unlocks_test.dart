import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrim/data/document_store.dart';
import 'package:quadrim/data/documents.dart';
import 'package:quadrim/data/local_game_repository.dart';
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

void main() {
  group('the record', () {
    test('round-trips through JSON', () {
      final unlock = UnlockDocument(
        opponentId: 'willow',
        unlockedAt: DateTime.utc(2026, 8, 14, 9, 12, 31),
        pricePaid: 64,
      );
      final back = UnlockDocument.fromJson(unlock.toJson())!;
      expect(back.opponentId, 'willow');
      expect(back.pricePaid, 64);
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
            'opponentId': 'willow',
            'unlockedAt': 'not a date',
            'pricePaid': 64,
          }),
          isNull);
    });
  });

  group('the repository', () {
    test('records what was paid, not what the table says', () async {
      final repo = await _repository();
      // Deliberately not unlockCost(5): the stored price is what was actually
      // charged, so a later re-tune cannot rewrite it (spec §8.8).
      final unlock = await repo.purchase('willow', pricePaid: 40);
      expect(unlock.pricePaid, 40);
      expect((await repo.loadUnlocks()).single.pricePaid, 40);
    });

    test('only the next opponent in roster order may be bought', () async {
      final repo = await _repository();
      // Willow is index 5 and the first locked one. Vireo is 6.
      expect(() => repo.purchase('vireo', pricePaid: 128),
          throwsA(isA<ArgumentError>()));
      await repo.purchase('willow', pricePaid: 64);
      await repo.purchase('vireo', pricePaid: 128);
      expect((await repo.loadUnlocks()).map((u) => u.opponentId),
          ['willow', 'vireo']);
    });

    test('a free opponent cannot be bought at all', () async {
      final repo = await _repository();
      expect(() => repo.purchase('pebble', pricePaid: 1),
          throwsA(isA<StateError>()));
    });

    test('buying the same opponent twice is refused', () async {
      final repo = await _repository();
      await repo.purchase('willow', pricePaid: 64);
      expect(() => repo.purchase('willow', pricePaid: 64),
          throwsA(isA<StateError>()));
      expect(await repo.loadUnlocks(), hasLength(1));
    });

    test('survives a restart, which is what the backup allowlist protects',
        () async {
      // The store is the same object, standing in for the same directory. The
      // unlock is the one thing here a player cannot regenerate by playing.
      final store = MemoryDocumentStore();
      final first = await _repository(store);
      await first.purchase('willow', pricePaid: 64);

      final reopened = await _repository(store);
      final unlocks = await reopened.loadUnlocks();
      expect(unlocks.single.opponentId, 'willow');
      expect(unlocks.single.pricePaid, 64);
    });

    test('the balance survives a re-tune of the cost table', () async {
      final repo = await _repository();
      await _win(repo, 'bramble', 4); // 4 * 16 = 64
      await repo.purchase('willow', pricePaid: 64);
      final unlocks = await repo.loadUnlocks();
      final prices = [for (final u in unlocks) u.pricePaid];

      expect(balance(earned: 64, pricesPaid: prices), 0);
      // If the table later said 96, the player is not retroactively 32 in debt.
      expect(balance(earned: 64, pricesPaid: prices), isNonNegative);
    });
  });

  group('Your Path', () {
    testWidgets('shows three tiles, the middle one the next unlock',
        (tester) async {
      _phone(tester);
      final repo = await _repository();
      await tester.pumpWidget(QuadrimApp(
          repository: repo, settings: repo, unlocks: repo, random: Random(1)));
      await tester.pumpAndSettle();

      expect(find.text('Your path'), findsOneWidget);
      // The window around the next unlock, which on a fresh install is Willow.
      for (final name in ['Bramble', 'Willow', 'Vireo']) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
      // And *not* the rating-centred window a player seeded at 800 would get,
      // which would have been three opponents they already own (D262).
      expect(find.text('Mote'), findsNothing);
    });

    testWidgets('a locked tile shows its price and the progress toward it',
        (tester) async {
      _phone(tester);
      final repo = await _repository();
      await tester.pumpWidget(QuadrimApp(
          repository: repo, settings: repo, unlocks: repo, random: Random(1)));
      await tester.pumpAndSettle();

      expect(find.text('64 points'), findsOneWidget, reason: "Willow's price");
      expect(find.text('0 of 64'), findsOneWidget);
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

      expect(find.text('64 of 64'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Unlock'));
      await tester.pumpAndSettle();

      // The confirmation says what it costs and what is left.
      expect(find.text('Unlock Willow?'), findsOneWidget);
      expect(find.text('This costs 64 points and leaves you 0.'),
          findsOneWidget);
      // Scoped to the dialog: the tile behind it still carries an Unlock
      // button of its own, so a bare finder matches two.
      await tester.tap(find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(FilledButton, 'Unlock')));
      await tester.pumpAndSettle();

      expect((await repo.loadUnlocks()).single.opponentId, 'willow');
      // The window slid: Willow is now owned and Vireo is next.
      expect(find.text('128 points'), findsOneWidget, reason: "Vireo's price");
    });

    testWidgets('cancelling the confirmation buys nothing', (tester) async {
      _phone(tester);
      final repo = await _repository();
      await _win(repo, 'bramble', 4);
      await tester.pumpWidget(QuadrimApp(
          repository: repo, settings: repo, unlocks: repo, random: Random(1)));
      await tester.pumpAndSettle();

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
      await _win(repo, 'bramble', 5); // 80 earned
      await repo.purchase('willow', pricePaid: 64);
      await tester.pumpWidget(QuadrimApp(
          repository: repo, settings: repo, unlocks: repo, random: Random(1)));
      await tester.pumpAndSettle();

      expect(find.text('16'), findsOneWidget, reason: '80 earned, 64 spent');
    });

    testWidgets('an opponent never faced shows no star row', (tester) async {
      _phone(tester);
      final repo = await _repository();
      await tester.pumpWidget(QuadrimApp(
          repository: repo, settings: repo, unlocks: repo, random: Random(1)));
      await tester.pumpAndSettle();

      // Bramble is unlocked and unplayed: it says so rather than drawing three
      // empty stars, because unearned and failed must not look the same.
      expect(find.text('Not played yet'), findsOneWidget);
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
      expect(
        find.bySemanticsLabel(
            RegExp(r'Willow, rated 1100\. Locked\. 64 points, you have 0\.')),
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
      // Buy the whole ladder up to Oracle, then earn its price.
      for (var i = 5; i < 18; i++) {
        await repo.purchase(opponentCatalogue[i].id, pricePaid: 0);
      }
      await _win(repo, 'titan', 4); // 4 * 2^17 = Oracle's price
      await tester.pumpWidget(QuadrimApp(
          repository: repo, settings: repo, unlocks: repo, random: Random(1)));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Unlock'));
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
