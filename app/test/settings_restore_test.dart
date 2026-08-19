import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:quadrim/data/document_store.dart';
import 'package:quadrim/data/local_game_repository.dart';
import 'package:quadrim/l10n/app_localizations.dart';
import 'package:quadrim/settings/settings_screen.dart';
import 'package:quadrim/shop/products.dart';
import 'package:quadrim/shop/shop.dart';

import 'shop_test.dart' show FakeStore, purchaseDetails;

/// Ticket 046: the restore action Apple requires, and the message it gives.
///
/// The message is the point. A player who has paid and reinstalled taps this;
/// telling them "nothing to restore" because the store was slow reads as a lost
/// purchase, and is the failure this screen is most likely to produce.
void main() {
  Future<void> pump(WidgetTester tester, Shop shop) async {
    final repo = await LocalGameRepository.open(MemoryDocumentStore());
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: SettingsScreen(settings: repo, shop: shop),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('the row is absent when no store is attached', (tester) async {
    final repo = await LocalGameRepository.open(MemoryDocumentStore());
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: SettingsScreen(settings: repo),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Restore purchases'), findsNothing);
  });

  testWidgets('a slow store is waited for rather than reported as empty',
      (tester) async {
    final repo = await LocalGameRepository.open(MemoryDocumentStore());
    final store = FakeStore();
    final shop = Shop(platform: store, unlocks: repo);
    await shop.start();
    await pump(tester, shop);

    // The store will answer, but late — later than any fixed delay would wait.
    store.owned = [
      purchaseDetails(kUnlockAllProductId, PurchaseStatus.restored),
    ];
    store.restoreDelay = const Duration(seconds: 3);

    await tester.tap(find.text('Restore purchases'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.text('Purchases restored.'), findsOneWidget);
    expect(find.text('Nothing to restore on this account.'), findsNothing);
  });

  testWidgets('an account that owns nothing is told so', (tester) async {
    final repo = await LocalGameRepository.open(MemoryDocumentStore());
    final store = FakeStore();
    final shop = Shop(platform: store, unlocks: repo);
    await shop.start();
    await pump(tester, shop);

    await tester.tap(find.text('Restore purchases'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 9));
    await tester.pumpAndSettle();

    expect(find.text('Nothing to restore on this account.'), findsOneWidget);
  });

  testWidgets('an unreachable store says so instead of finding nothing',
      (tester) async {
    final repo = await LocalGameRepository.open(MemoryDocumentStore());
    final shop = Shop(platform: FakeStore(available: false), unlocks: repo);
    await shop.start();
    await pump(tester, shop);

    await tester.tap(find.text('Restore purchases'));
    await tester.pumpAndSettle();

    expect(find.text('The store is not available right now.'), findsOneWidget);
  });
}
