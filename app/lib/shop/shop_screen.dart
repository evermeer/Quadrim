import 'package:flutter/material.dart';

import '../design/forest.dart';
import '../l10n/app_localizations.dart';
import 'products.dart';
import 'shop.dart';

/// What is for sale, and what it does not do.
///
/// Reachable from the paywall and from settings. Two products, described
/// plainly, and **the one-time unlock's caveat is given the same weight as its
/// description** — it sells impatience, not capability (§4.1), and a buyer who
/// discovers afterwards that they still play three games a day has been misled.
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key, required this.shop});

  final Shop shop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ForestScaffold(
      appBar: AppBar(title: Text(l10n.shopTitle)),
      body: SafeArea(
        child: ParchmentSheet(
          child: ListenableBuilder(
            // Both, because a purchase changes what is owned and the button
            // must stop offering to sell it again.
            listenable: Listenable.merge([shop.entitlement, shop.products]),
            builder: (context, _) {
              final owned = shop.entitlement.value;
              return ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _Product(
                    name: l10n.shopUnlimitedName,
                    body: l10n.shopUnlimitedBody,
                    price: shop.products.value[kUnlimitedProductId]?.price,
                    owned: owned.unlimited,
                    onBuy: shop.buyUnlimited,
                  ),
                  const Divider(),
                  _Product(
                    name: l10n.shopUnlockAllName,
                    body: l10n.shopUnlockAllBody,
                    caveat: l10n.shopUnlockAllCaveat,
                    price: shop.products.value[kUnlockAllProductId]?.price,
                    owned: owned.unlockAll,
                    onBuy: shop.buyUnlockAll,
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text(
                      // S19: the meter is device-local at 1.0 and a reinstall
                      // clears it. Nothing here may imply otherwise.
                      l10n.shopMeterNote,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.restore_outlined),
                    title: Text(l10n.settingsRestorePurchases),
                    subtitle: Text(l10n.settingsRestoreExplanation),
                    onTap: () => _restore(context),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _restore(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    if (!shop.storeAvailable) {
      messenger
          .showSnackBar(SnackBar(content: Text(l10n.settingsRestoreUnavailable)));
      return;
    }
    await shop.restore();
    messenger.showSnackBar(SnackBar(content: Text(l10n.settingsRestoreDone)));
  }
}

class _Product extends StatelessWidget {
  const _Product({
    required this.name,
    required this.body,
    required this.price,
    required this.owned,
    required this.onBuy,
    this.caveat,
  });

  final String name;
  final String body;

  /// The caveat, when the product has one that a buyer must see *before*
  /// paying rather than after.
  final String? caveat;

  /// Formatted by the store, in the player's own currency and conventions.
  /// **Never built by concatenating a symbol** — that is one of the two places
  /// where an app reads as a scam, the other being machine-translated copy.
  final String? price;

  final bool owned;
  final Future<void> Function() onBuy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(body, style: theme.textTheme.bodyMedium),
          if (caveat != null) ...[
            const SizedBox(height: 8),
            Text(
              caveat!,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 12),
          // Wrap, not Row: at the largest font scale a price and a button do
          // not fit side by side on the narrowest phone (U20).
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (owned)
                Text(l10n.shopOwned, style: theme.textTheme.titleSmall)
              else ...[
                if (price != null)
                  Text(price!, style: theme.textTheme.titleSmall),
                FilledButton(
                  onPressed: price == null ? null : onBuy,
                  child: Text(price == null ? l10n.shopUnavailable : l10n.shopBuy),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
