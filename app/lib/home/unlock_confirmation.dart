import 'package:flutter/material.dart';
import 'package:quadrim_engine/quadrim_engine.dart';
import 'package:quadrim_progression/quadrim_progression.dart';

import '../data/documents.dart';
import '../game/opponent_name.dart';
import '../l10n/app_localizations.dart';

/// Confirms spending points on an opponent, and says what is being bought.
///
/// Reached from two places — a Your Path tile and the opponent list — and both
/// lead here rather than to two dialogs, because the sentence the two Master
/// opponents require is the kind of thing that gets written once and forgotten
/// in the second copy.
///
/// **For Oracle and Quadrim Prime it repeats "unbeatable when it moves
/// first".** The two most expensive unlocks buy opponents that cannot be beaten
/// half the time. A player who spends a million points on an opponent that
/// opens with a proven strategy and wins will feel cheated unless the app said
/// so first, and saying it only in a store listing does not reach the player
/// who earned it (spec §6.6, D181).
Future<bool> showUnlockConfirmation(
  BuildContext context, {
  required BotConfig bot,
  required int price,
  required int points,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final name = botName(l10n, botOpponent(bot.id));
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.unlockConfirmTitle(name)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.unlockConfirmBody(price, points - price)),
          if (bot.usesBook) ...[
            const SizedBox(height: 12),
            // Keyed on the configuration rather than on a list of two ids, so
            // a third book opponent could never ship without the warning.
            Text(l10n.unlockConfirmBook(name),
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.unlockAction),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// The whole purchase, from confirmation to the message afterwards.
///
/// Lives here rather than in either caller so that the two entry points cannot
/// drift — and so the affordability check, the confirmation and the write stay
/// in one order.
Future<bool> runUnlock(
  BuildContext context, {
  required BotConfig bot,
  required int price,
  required int points,
  required Future<void> Function(String opponentId, int price) purchase,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  if (points < price) {
    messenger.showSnackBar(
        SnackBar(content: Text(l10n.unlockNotAffordable(price - points))));
    return false;
  }
  if (!await showUnlockConfirmation(
      context, bot: bot, price: price, points: points)) {
    return false;
  }
  await purchase(bot.id, price);
  messenger.showSnackBar(
      SnackBar(content: Text(l10n.unlockDone(botName(l10n, botOpponent(bot.id))))));
  return true;
}

/// The price of an opponent, or null if it is free and has none.
int? priceOf(String botId) {
  final index = rosterIndexOf(botId);
  if (index == null || isFree(opponentCatalogue[index])) return null;
  return unlockCost(index);
}
