import 'package:flutter/material.dart';
import 'package:quadrim_progression/quadrim_progression.dart';

import '../l10n/app_localizations.dart';
import 'shop.dart';
import 'shop_screen.dart';

/// The refusal, and it names the limit that actually bit.
///
/// **"This week's nine games" and "come back tomorrow" are different sentences
/// and only one of them is true on a Thursday** (D221, F16). Showing the wrong
/// one teaches the player that the app does not know its own rules, which is a
/// worse loss than the sale.
///
/// It also says what is *not* refused. A wall that looks total when it is not
/// reads as broken, and three of the four things a player might be trying to do
/// are still available: finishing a game already started, pass and play, and
/// the tutorial's practice game (§4.2).
Future<void> showPaywall(
  BuildContext context, {
  required MeterLimit limit,
  required Shop? shop,
}) {
  final l10n = AppLocalizations.of(context)!;
  final daily = limit == MeterLimit.daily;
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(daily ? l10n.paywallDailyTitle : l10n.paywallWeeklyTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(daily ? l10n.paywallDailyBody : l10n.paywallWeeklyBody),
            const SizedBox(height: 12),
            Text(
              l10n.paywallFooter,
              style: Theme.of(dialogContext).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(l10n.paywallNotNow),
        ),
        if (shop != null)
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => ShopScreen(shop: shop),
              ));
            },
            child: Text(l10n.paywallSeeOptions),
          ),
      ],
    ),
  );
}
