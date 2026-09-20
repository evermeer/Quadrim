import 'package:flutter/material.dart';

import '../design/forest.dart';
import '../l10n/app_localizations.dart';
import '../links.dart';
import 'products.dart';
import 'shop.dart';

/// What is for sale, and what it does not do.
///
/// Reachable from the paywall and from settings. Two products, described
/// plainly, and **the one-time unlock's caveat is given the same weight as its
/// description** — it sells impatience, not capability (§4.1), and a buyer who
/// discovers afterwards that they still play three games a day has been misled.
///
/// **This is the subscription's purchase flow, so guideline 3.1.2(c) applies to
/// it directly** (D384). Each product says whether it recurs, the subscription
/// says how long it runs and what it costs per year, and the privacy policy and
/// the EULA are linked from the foot of the screen — the same links settings
/// carries, because a reviewer opening the paywall must not have to go looking.
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
                    term: l10n.shopUnlimitedTerm,
                    body: l10n.shopUnlimitedBody,
                    caveat: l10n.shopSubscriptionNote,
                    price: shop.products.value[kUnlimitedProductId]?.price,
                    // The only recurring product, so the only one whose price
                    // is shown per unit of time (3.1.2(c)).
                    recurring: true,
                    owned: owned.unlimited,
                    onBuy: shop.buyUnlimited,
                  ),
                  const Divider(),
                  _Product(
                    name: l10n.shopUnlockAllName,
                    term: l10n.shopUnlockAllTerm,
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
                  const Divider(),
                  // Required here, not only in settings: 3.1.2(c) asks for them
                  // in the purchase flow, and this screen is it (D384).
                  LinkTile(
                    icon: Icons.privacy_tip_outlined,
                    title: l10n.settingsPrivacyPolicy,
                    url: kPrivacyPolicyUrl,
                  ),
                  LinkTile(
                    icon: Icons.description_outlined,
                    title: l10n.settingsTerms,
                    url: kTermsUrl,
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

/// **Stateful only to hold "a purchase is in flight"** (tester feedback).
///
/// The store sheet takes a noticeable moment to appear, and a button that still
/// looks pressable during it invites a second tap — which opens the sheet again
/// after the first purchase completes. The flag is local rather than on [Shop]
/// because it is about this button's appearance, not about what is owned.
class _Product extends StatefulWidget {
  const _Product({
    required this.name,
    required this.term,
    required this.body,
    required this.price,
    required this.owned,
    required this.onBuy,
    this.caveat,
    this.recurring = false,
  });

  final String name;

  /// One time, or every year. **Guideline 3.1.2(c) asks the app itself for the
  /// subscription's title, length and price**, and a buyer should not have to
  /// infer which of two products will charge them again.
  final String term;

  final String body;

  /// The caveat, when the product has one that a buyer must see *before*
  /// paying rather than after.
  final String? caveat;

  /// Formatted by the store, in the player's own currency and conventions.
  /// **Never built by concatenating a symbol** — that is one of the two places
  /// where an app reads as a scam, the other being machine-translated copy.
  final String? price;

  /// Whether [price] is per year rather than once.
  final bool recurring;

  final bool owned;
  final Future<void> Function() onBuy;

  @override
  State<_Product> createState() => _ProductState();
}

class _ProductState extends State<_Product> {
  bool _busy = false;

  Future<void> _buy() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onBuy();
    } finally {
      // The sheet may outlive this screen if the player navigates away, so the
      // mounted check is the difference between a released state and a throw.
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final name = widget.name;
    final body = widget.body;
    final caveat = widget.caveat;
    final price = widget.price;
    final owned = widget.owned;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: theme.textTheme.titleMedium),
          const SizedBox(height: 2),
          Text(
            widget.term,
            style: theme.textTheme.labelMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Text(body, style: theme.textTheme.bodyMedium),
          if (caveat != null) ...[
            const SizedBox(height: 8),
            Text(
              caveat,
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
              else if (price == null)
                // **Not a disabled button carrying a sentence** (ticket 021).
                // "The store is not available right now" is a status, and a
                // button is a promise of an action; the two read as each other
                // only on screen. By ear both products then announced the same
                // long sentence as their only control.
                Text(l10n.shopUnavailable, style: theme.textTheme.bodySmall)
              else ...[
                Text(
                    widget.recurring ? l10n.shopPricePerYear(price) : price,
                    style: theme.textTheme.titleSmall),
                FilledButton(
                  onPressed: _busy ? null : _buy,
                  // **The visible word stays "Buy" and the announced one names
                  // the product** (ticket 021). Two products means two buttons
                  // reading "Buy, button", which `labeledTapTargetGuideline`
                  // passes — a label is present — while leaving a screen-reader
                  // user unable to tell what they are about to pay for. The
                  // guideline is a floor, not the goal.
                  child: _busy
                      // Same footprint as the word it replaces, so the row does
                      // not jump while the store is opening.
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.shopBuy,
                          semanticsLabel: l10n.shopBuyProduct(name)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
