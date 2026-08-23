import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quadrim/shop/products.dart';

/// Ticket 046: the StoreKit configuration and the Dart constants say the same
/// thing.
///
/// A product id lives in three places — `products.dart`, `Quadrim.storekit`,
/// and App Store Connect — and **cannot be changed in any of them once
/// published**, because neither store lets an id be reused after deletion. The
/// third is a web console this test cannot see. The first two it can, and a
/// mismatch there produces the least informative failure in the whole product:
/// a purchase screen that is simply empty, because `queryProductDetails`
/// returned the id in `notFoundIDs` and nothing said so.
///
/// This runs on the host rather than the device, so `dart:io` is fine — the
/// purity rule binds the engine packages, not the app's tests.
void main() {
  late Map<String, Object?> config;

  setUpAll(() {
    final file = File('ios/Runner/Quadrim.storekit');
    expect(file.existsSync(), isTrue,
        reason: 'the StoreKit configuration is what lets a purchase be tested '
            'with no App Store Connect products at all');
    config = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  });

  List<Map<String, Object?>> products() =>
      (config['products'] as List).cast<Map<String, Object?>>();

  List<Map<String, Object?>> groups() =>
      (config['subscriptionGroups'] as List).cast<Map<String, Object?>>();

  test('the one-time unlock is a non-consumable under the id the app asks for',
      () {
    final unlock = products().singleWhere(
        (p) => p['productID'] == kUnlockAllProductId,
        orElse: () => throw StateError(
            'no product with id $kUnlockAllProductId in Quadrim.storekit'));
    expect(unlock['type'], 'NonConsumable',
        reason: 'a consumable would be re-bought and would not restore');
  });

  test('the subscription sits inside a group holding exactly one base plan',
      () {
    // The shape D223 insists on. 3.0 adds tier 3 as a second plan in this same
    // group, which is the only mechanism by which the store cancels and
    // prorates the lower tier — and a group cannot be retro-fitted around a
    // product that already has subscribers.
    expect(groups(), hasLength(1));
    final subscriptions =
        (groups().single['subscriptions'] as List).cast<Map<String, Object?>>();
    expect(subscriptions, hasLength(1),
        reason: 'one base plan at 1.0; tier 3 joins this group at 3.0');
    expect(subscriptions.single['productID'], kUnlimitedProductId);
    expect(subscriptions.single['type'], 'RecurringSubscription');
    expect(subscriptions.single['recurringSubscriptionPeriod'], 'P1Y',
        reason: 'yearly (§4.1)');
  });

  test('every id the app asks the store about is defined, and nothing else is',
      () {
    final defined = {
      for (final product in products()) product['productID'] as String,
      for (final group in groups())
        for (final subscription
            in (group['subscriptions'] as List).cast<Map<String, Object?>>())
          subscription['productID'] as String,
    };
    expect(defined, kProductIds,
        reason: 'an id in one and not the other is an empty purchase screen '
            'with no error anywhere');
  });

  test('both ids are namespaced under the iOS bundle id', () {
    // They follow the *iOS* bundle id, not the Android application id, because
    // App Store Connect is what refused the old namespace (D365). D359 said
    // this prefix would never move; it moved, and the reason it could is that
    // no product had been created on either store yet. Once one exists this
    // becomes as immovable as D213 says -- a product id is never reusable
    // after deletion, on either store.
    for (final id in kProductIds) {
      expect(id, startsWith('nl.evict.quadrim2.'));
    }
  });

  test('the subscription id carries no tier number', () {
    // 3.0 adds a *plan* to this product rather than a second product, so an id
    // reading "tier2" would name a group that contains tier 3 (D223).
    //
    // Asserted on the last segment rather than the whole id: the namespace has
    // carried a digit since it followed the iOS bundle id (D365), and a bare
    // "no digits anywhere" check reads that `2` as a tier number. What D223
    // protects is the product's own name, which is this segment.
    final name = kUnlimitedProductId.split('.').last;
    expect(name, isNot(contains('tier')));
    expect(name, isNot(matches(RegExp(r'\d'))));
  });
}
