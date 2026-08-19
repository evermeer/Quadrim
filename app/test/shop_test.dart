import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:quadrim/data/document_store.dart';
import 'package:quadrim/data/documents.dart';
import 'package:quadrim/data/local_game_repository.dart';
import 'package:quadrim/shop/products.dart';
import 'package:quadrim/shop/shop.dart';
import 'package:quadrim_engine/quadrim_engine.dart';
import 'package:quadrim_progression/quadrim_progression.dart';

/// Ticket 046: the shop, tested against a fake store.
///
/// Everything here is the part that can lose money — an entitlement granted
/// that was not bought, an unlock revoked that was earned, or a purchase left
/// uncompleted so the store retries it forever and the player is charged for
/// something they never received. None of it is reachable through
/// `InAppPurchase.instance`, which is a singleton over platform channels, so
/// the shop takes a [PurchasePlatform] and this is the fake.
class FakeStore implements PurchasePlatform {
  FakeStore({this.available = true, List<ProductDetails>? catalogue})
      : catalogue = catalogue ?? _defaultCatalogue();

  final bool available;
  final List<ProductDetails> catalogue;

  final StreamController<List<PurchaseDetails>> controller =
      StreamController<List<PurchaseDetails>>.broadcast();

  /// What [restorePurchases] will re-deliver — the store's current answer about
  /// what is owned, which is the only authority at 1.0.
  List<PurchaseDetails> owned = <PurchaseDetails>[];

  final List<String> completed = <String>[];
  final List<String> bought = <String>[];
  int restoreCalls = 0;

  /// How late the store answers. Real ones are not instant, and the restore
  /// row's message depends on it.
  Duration restoreDelay = Duration.zero;

  static List<ProductDetails> _defaultCatalogue() => [
        ProductDetails(
            id: kUnlockAllProductId,
            title: 'Unlock all opponents',
            description: '',
            price: '4.99',
            rawPrice: 4.99,
            currencyCode: 'EUR'),
        ProductDetails(
            id: kUnlimitedProductId,
            title: 'Unlimited play',
            description: '',
            price: '1.99',
            rawPrice: 1.99,
            currencyCode: 'EUR'),
      ];

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => controller.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async =>
      ProductDetailsResponse(
        productDetails:
            catalogue.where((product) => ids.contains(product.id)).toList(),
        notFoundIDs: ids
            .where((id) => !catalogue.any((product) => product.id == id))
            .toList(),
      );

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    bought.add(purchaseParam.productDetails.id);
    return true;
  }

  @override
  Future<void> restorePurchases() async {
    restoreCalls++;
    if (owned.isEmpty) return;
    if (restoreDelay == Duration.zero) {
      controller.add(owned);
      return;
    }
    Future<void>.delayed(restoreDelay, () => controller.add(owned));
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async =>
      completed.add(purchase.productID);
}

PurchaseDetails purchaseDetails(
  String id,
  PurchaseStatus status, {
  bool needsCompletion = true,
  IAPError? error,
}) =>
    PurchaseDetails(
      productID: id,
      verificationData: PurchaseVerificationData(
          localVerificationData: '', serverVerificationData: '', source: 'test'),
      transactionDate: null,
      status: status,
    )
      ..pendingCompletePurchase = needsCompletion
      ..error = error;

void main() {
  late LocalGameRepository repo;

  Future<LocalGameRepository> repository() async =>
      LocalGameRepository.open(MemoryDocumentStore());

  setUp(() async => repo = await repository());

  /// Lets the shop's stream handler run.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  group('entitlement', () {
    test('starts at nothing owned', () async {
      final shop = Shop(platform: FakeStore(), unlocks: repo);
      expect(shop.entitlement.value, Entitlement.none);
    });

    test('a purchased unlock-all grants every opponent, sourced to the purchase',
        () async {
      final store = FakeStore();
      final shop = Shop(platform: store, unlocks: repo);
      await shop.start();

      store.controller
          .add([purchaseDetails(kUnlockAllProductId, PurchaseStatus.purchased)]);
      await settle();

      expect(shop.entitlement.value.unlockAll, isTrue);
      final unlocks = await repo.loadUnlocks();
      expect(unlocks, hasLength(opponentCatalogue.length));
      expect(unlocks.every((u) => u.source == UnlockSource.purchase), isTrue);
      // Paid the store, not the points balance. A non-zero price here would
      // bankrupt a player for buying the unlock (§8.8).
      expect(unlocks.every((u) => u.pricePaid == 0), isTrue);
    });

    test('the subscription grants unmetered play and writes no unlocks',
        () async {
      final store = FakeStore();
      final shop = Shop(platform: store, unlocks: repo);
      await shop.start();

      store.controller
          .add([purchaseDetails(kUnlimitedProductId, PurchaseStatus.purchased)]);
      await settle();

      expect(shop.entitlement.value.unlimited, isTrue);
      expect(shop.entitlement.value.unlockAll, isFalse);
      expect(await repo.loadUnlocks(), isEmpty);
    });
  });

  group('completion', () {
    test('every delivered purchase is completed', () async {
      final store = FakeStore();
      final shop = Shop(platform: store, unlocks: repo);
      await shop.start();

      store.controller
          .add([purchaseDetails(kUnlockAllProductId, PurchaseStatus.purchased)]);
      await settle();

      expect(store.completed, [kUnlockAllProductId]);
    });

    test('an errored purchase is completed too, or the store retries forever',
        () async {
      final store = FakeStore();
      final shop = Shop(platform: store, unlocks: repo);
      await shop.start();

      store.controller.add([
        purchaseDetails(kUnlockAllProductId, PurchaseStatus.error,
            error: IAPError(source: 'test', code: 'x', message: 'nope'))
      ]);
      await settle();

      expect(store.completed, [kUnlockAllProductId]);
      expect(shop.entitlement.value.unlockAll, isFalse);
      expect(await repo.loadUnlocks(), isEmpty);
    });

    test('a cancelled purchase grants nothing and is still completed',
        () async {
      final store = FakeStore();
      final shop = Shop(platform: store, unlocks: repo);
      await shop.start();

      store.controller
          .add([purchaseDetails(kUnlockAllProductId, PurchaseStatus.canceled)]);
      await settle();

      expect(store.completed, [kUnlockAllProductId]);
      expect(shop.entitlement.value, Entitlement.none);
    });

    test('a purchase the plugin says needs no completion is left alone',
        () async {
      final store = FakeStore();
      final shop = Shop(platform: store, unlocks: repo);
      await shop.start();

      store.controller.add([
        purchaseDetails(kUnlockAllProductId, PurchaseStatus.purchased,
            needsCompletion: false)
      ]);
      await settle();

      expect(store.completed, isEmpty);
      expect(shop.entitlement.value.unlockAll, isTrue);
    });

    test('a pending purchase owns nothing and completes nothing yet', () async {
      final store = FakeStore();
      final shop = Shop(platform: store, unlocks: repo);
      await shop.start();

      store.controller.add([
        purchaseDetails(kUnlockAllProductId, PurchaseStatus.pending,
            needsCompletion: false)
      ]);
      await settle();

      expect(shop.entitlement.value, Entitlement.none);
      expect(store.completed, isEmpty);
      expect(shop.busy.value, isTrue);
    });
  });

  group('restore', () {
    test('start() restores, which is what populates entitlement at launch',
        () async {
      final store = FakeStore()
        ..owned = [purchaseDetails(kUnlockAllProductId, PurchaseStatus.restored)];
      final shop = Shop(platform: store, unlocks: repo);

      await shop.start();
      await settle();

      expect(store.restoreCalls, 1);
      expect(shop.entitlement.value.unlockAll, isTrue);
      expect(await repo.loadUnlocks(), hasLength(opponentCatalogue.length));
    });

    test('a reinstall restores both products without re-paying', () async {
      final store = FakeStore()
        ..owned = [
          purchaseDetails(kUnlockAllProductId, PurchaseStatus.restored),
          purchaseDetails(kUnlimitedProductId, PurchaseStatus.restored),
        ];
      final shop = Shop(platform: store, unlocks: repo);

      await shop.start();
      await settle();

      expect(shop.entitlement.value.unlockAll, isTrue);
      expect(shop.entitlement.value.unlimited, isTrue);
      expect(store.bought, isEmpty, reason: 'restore must never re-purchase');
    });

    test('an explicit restore is available as its own action', () async {
      final store = FakeStore();
      final shop = Shop(platform: store, unlocks: repo);
      await shop.start();

      store.owned = [purchaseDetails(kUnlockAllProductId, PurchaseStatus.restored)];
      await shop.restore();
      await settle();

      expect(store.restoreCalls, 2);
      expect(shop.entitlement.value.unlockAll, isTrue);
    });
  });

  group('what a billing event may and may not touch', () {
    test('a lapsed subscription leaves every unlock intact', () async {
      final store = FakeStore();
      final shop = Shop(platform: store, unlocks: repo);
      await shop.start();

      store.controller.add([
        purchaseDetails(kUnlockAllProductId, PurchaseStatus.purchased),
        purchaseDetails(kUnlimitedProductId, PurchaseStatus.purchased),
      ]);
      await settle();
      final before = await repo.loadUnlocks();
      expect(before, isNotEmpty);

      // The lapse: a fresh launch, and the store no longer re-delivers the
      // subscription. Entitlement is not persisted, so this is the whole of it.
      final next = Shop(platform: store, unlocks: repo);
      store.owned = [purchaseDetails(kUnlockAllProductId, PurchaseStatus.restored)];
      await next.start();
      await settle();

      expect(next.entitlement.value.unlimited, isFalse);
      expect(next.entitlement.value.unlockAll, isTrue);
      expect(await repo.loadUnlocks(), hasLength(before.length));
    });

    test('a refund of the unlock revokes only what it bought', () async {
      // One opponent earned with points, the rest bought. It must be the
      // *next locked* one: the opening opponents are free, and D229 allows
      // only the lowest-indexed locked one to be bought.
      final first = opponentCatalogue[nextUnlockIndex(const {})!].id;
      await repo.purchase(first, pricePaid: 400);

      final store = FakeStore();
      final shop = Shop(platform: store, unlocks: repo);
      await shop.start();
      store.controller
          .add([purchaseDetails(kUnlockAllProductId, PurchaseStatus.purchased)]);
      await settle();
      expect(await repo.loadUnlocks(), hasLength(opponentCatalogue.length));

      final revoked = await repo.revokePurchasedUnlocks();

      final left = await repo.loadUnlocks();
      expect(left, hasLength(1));
      expect(left.single.opponentId, first);
      expect(left.single.source, UnlockSource.points);
      expect(left.single.pricePaid, 400,
          reason: 'what was earned keeps what it cost');
      expect(revoked, hasLength(opponentCatalogue.length - 1));
      expect(revoked, isNot(contains(first)));
    });

    test('granting is idempotent and never overwrites an earned unlock',
        () async {
      final first = opponentCatalogue[nextUnlockIndex(const {})!].id;
      await repo.purchase(first, pricePaid: 400);

      await repo.grantAllPurchased();
      await repo.grantAllPurchased();

      final unlocks = await repo.loadUnlocks();
      expect(unlocks, hasLength(opponentCatalogue.length));
      final earned = unlocks.firstWhere((u) => u.opponentId == first);
      expect(earned.source, UnlockSource.points);
      expect(earned.pricePaid, 400);
    });
  });

  group('the store being unreachable', () {
    test('start() gives up quietly and owns nothing', () async {
      final store = FakeStore(available: false);
      final shop = Shop(platform: store, unlocks: repo);

      await shop.start();

      expect(shop.storeAvailable, isFalse);
      expect(shop.products.value, isEmpty);
      expect(shop.entitlement.value, Entitlement.none);
      expect(store.restoreCalls, 0);
    });

    test('buying a product the store never returned reports rather than throws',
        () async {
      final store = FakeStore(catalogue: const []);
      final shop = Shop(platform: store, unlocks: repo);
      await shop.start();

      await shop.buyUnlockAll();

      expect(store.bought, isEmpty);
      expect(shop.lastError.value?.code, 'product_unavailable');
    });
  });
}
