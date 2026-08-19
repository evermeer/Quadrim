import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../data/game_repository.dart';
import 'products.dart';

/// The store, behind an interface this app owns.
///
/// `InAppPurchase.instance` is a singleton over platform channels, so a test
/// that touched it would need a real store or a channel mock. Everything the
/// shop needs is six methods, and naming them here means the purchase logic —
/// which is the part that can lose money — is testable against a fake with no
/// platform in the room.
abstract interface class PurchasePlatform {
  Stream<List<PurchaseDetails>> get purchaseStream;
  Future<bool> isAvailable();
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers);
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam});
  Future<void> restorePurchases();
  Future<void> completePurchase(PurchaseDetails purchase);
}

/// The real one.
class InAppPurchasePlatformAdapter implements PurchasePlatform {
  InAppPurchasePlatformAdapter([InAppPurchase? instance])
      : _iap = instance ?? InAppPurchase.instance;

  final InAppPurchase _iap;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  @override
  Future<bool> isAvailable() => _iap.isAvailable();

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) =>
      _iap.queryProductDetails(identifiers);

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) =>
      _iap.buyNonConsumable(purchaseParam: purchaseParam);

  @override
  Future<void> restorePurchases() => _iap.restorePurchases();

  @override
  Future<void> completePurchase(PurchaseDetails purchase) =>
      _iap.completePurchase(purchase);
}

/// Products, purchases and what the player owns.
///
/// **The store's signed transaction is the authority and it is read on the
/// device** (D303, spec S9 at its 1.0 strength). There is no server and no
/// receipt validation of our own, and the [Entitlement] is deliberately not
/// persisted — a cached copy on disk is a second answer that disagrees with the
/// store exactly when a refund has landed and the cache has not.
///
/// **Entitlement is therefore rebuilt each launch rather than accumulated
/// forever.** [start] restores, the store re-delivers what is currently owned,
/// and anything refunded or lapsed simply does not arrive. That is what makes
/// revocation follow the store's next refresh rather than being immediate,
/// which is the documented 1.0 behaviour and not an oversight.
class Shop {
  /// Named for the caller, positional inside: a named parameter cannot be a
  /// private initialising formal in Dart, and both arguments are interfaces
  /// whose positional order would be a coin flip at every call site. The same
  /// split `LocalGameRepository` uses.
  factory Shop({
    required PurchasePlatform platform,
    required UnlockRepository unlocks,
  }) =>
      Shop._(platform, unlocks);

  Shop._(this._platform, this._unlocks);

  final PurchasePlatform _platform;

  final UnlockRepository _unlocks;

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  /// What the store says is owned, this launch.
  final ValueNotifier<Entitlement> entitlement =
      ValueNotifier<Entitlement>(Entitlement.none);

  /// Product details, once queried. Empty when the store is unreachable.
  final ValueNotifier<Map<String, ProductDetails>> products =
      ValueNotifier<Map<String, ProductDetails>>(const {});

  /// True while a purchase is in flight or awaiting approval.
  final ValueNotifier<bool> busy = ValueNotifier<bool>(false);

  /// The last store error, for a screen to show. Cleared by the next attempt.
  final ValueNotifier<IAPError?> lastError = ValueNotifier<IAPError?>(null);

  bool _available = false;
  bool get storeAvailable => _available;

  /// Subscribes to the purchase stream, queries products, and restores.
  ///
  /// **The subscription is opened before anything else.** The plugin delivers
  /// purchases interrupted by a crash, a lost connection or an "Ask to Buy"
  /// approval on the *first* stream event after launch, and a listener attached
  /// later misses them — which leaves the store retrying forever and the player
  /// charged for something they never received.
  Future<void> start() async {
    _subscription ??= _platform.purchaseStream.listen(
      _onPurchases,
      onError: (Object error) => lastError.value = error is IAPError
          ? error
          : IAPError(source: 'shop', code: 'stream', message: '$error'),
    );

    _available = await _platform.isAvailable();
    if (!_available) return;

    final response = await _platform.queryProductDetails(kProductIds);
    products.value = {
      for (final product in response.productDetails) product.id: product,
    };

    // Not just for the player's benefit. This is also what populates the
    // entitlement at launch, because nothing about it is stored.
    await _platform.restorePurchases();
  }

  /// The explicit restore action (§4.1). Apple requires one and a player who
  /// reinstalls needs it, so it is a button in settings rather than only the
  /// silent call [start] makes.
  Future<void> restore() async {
    lastError.value = null;
    await _platform.restorePurchases();
  }

  Future<void> buyUnlockAll() => _buy(kUnlockAllProductId);

  Future<void> buyUnlimited() => _buy(kUnlimitedProductId);

  /// Both products are bought as non-consumables.
  ///
  /// `buyNonConsumable` is correct for the subscription too: the plugin's
  /// `buyConsumable` exists for products that are used up and re-bought, which
  /// an auto-renewing subscription is not.
  Future<void> _buy(String id) async {
    final product = products.value[id];
    if (product == null) {
      lastError.value = IAPError(
        source: 'shop',
        code: 'product_unavailable',
        message: 'the store did not return $id',
      );
      return;
    }
    lastError.value = null;
    busy.value = true;
    try {
      await _platform.buyNonConsumable(
          purchaseParam: PurchaseParam(productDetails: product));
    } catch (_) {
      busy.value = false;
      rethrow;
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          // Awaiting approval — "Ask to Buy", or a slow payment method. Nothing
          // is owned yet and nothing is completed yet.
          busy.value = true;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _grant(purchase.productID);
          busy.value = false;

        case PurchaseStatus.error:
          lastError.value = purchase.error;
          busy.value = false;

        case PurchaseStatus.canceled:
          busy.value = false;
      }

      // **Unconditional, and outside the switch on purpose.** A purchase that
      // is not completed is redelivered by the store on every launch forever,
      // including one that errored or was cancelled. The plugin sets this flag
      // on exactly the ones that need it.
      if (purchase.pendingCompletePurchase) {
        await _platform.completePurchase(purchase);
      }
    }
  }

  /// Turns an owned product into what the rest of the app reads.
  Future<void> _grant(String productId) async {
    switch (productId) {
      case kUnlockAllProductId:
        entitlement.value = entitlement.value.copyWith(unlockAll: true);
        // Materialised into unlock records rather than left as a flag, so every
        // screen that already reads unlocks needs no knowledge of the shop, and
        // so a refund can revoke precisely what was bought (§8.8).
        await _unlocks.grantAllPurchased();

      case kUnlimitedProductId:
        // No records to write: the subscription buys unmetered play, and the
        // meter is 047's business. It must never touch unlocks (§4.1).
        entitlement.value = entitlement.value.copyWith(unlimited: true);
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    entitlement.dispose();
    products.dispose();
    busy.dispose();
    lastError.dispose();
  }
}
