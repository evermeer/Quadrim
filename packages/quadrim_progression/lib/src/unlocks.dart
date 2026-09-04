import 'package:quadrim_engine/quadrim_engine.dart';

import 'points.dart';

/// What has been bought, what may be bought next, and how it is presented.
///
/// The arithmetic lives here rather than in the app for the same reason the
/// point values do: it is small, exact, and worth proving over the whole
/// catalogue rather than through a widget test.

/// The spendable balance: earned minus the prices **actually paid**, never
/// below zero.
///
/// Two properties, both load-bearing and both easy to lose.
///
/// The prices come from the stored unlock records rather than from
/// [unlockCost], so re-tuning the cost table can never retroactively bankrupt
/// someone who already spent at the old price (spec §8.8).
///
/// And it clamps. Quest rewards are derived rather than stored, so re-tuning
/// *that* table downward would reduce the earned total under unlocks already
/// bought and could drive this negative. Clamping costs the player future
/// purchasing power and takes nothing away; **no unlock is ever revoked**
/// (D264). The alternative was a second stored table, insuring against a
/// re-tune expected once, before real players exist, at the permanent cost of
/// the property that nothing but the unlock records is stored.
int balance({required int earned, required Iterable<int> pricesPaid}) {
  var spent = 0;
  for (final price in pricesPaid) {
    spent += price;
  }
  final left = earned - spent;
  return left < 0 ? 0 : left;
}

/// Whether [botId] can be played: free by rating, or already unlocked.
bool isUnlocked(String botId, Set<String> unlockedIds) {
  if (unlockedIds.contains(botId)) return true;
  final index = rosterIndexOf(botId);
  return index != null && isFree(opponentCatalogue[index]);
}

/// The roster index of the only opponent that may be purchased right now, or
/// null when everything is unlocked.
///
/// **Strictly the lowest-indexed locked one.** A player cannot save up and skip
/// ahead (D229), which is what makes "four wins buys the next opponent" a
/// promise about the *next* one rather than about some opponent somewhere.
///
/// A gap — an opponent unlocked out of order, which no code path here can
/// produce but a hand-edited document could — resolves to the lowest locked
/// index regardless, so the ladder repairs itself rather than jamming.
int? nextUnlockIndex(Set<String> unlockedIds) {
  // From the first rung that is *for sale*. The mercy opponents below it are
  // locked on a first launch but are not on the ladder: naming one here would
  // point the whole points economy at an opponent no amount of points can buy
  // (D382).
  for (var i = kMercyCount; i < opponentCatalogue.length; i++) {
    if (!isUnlocked(opponentCatalogue[i].id, unlockedIds)) return i;
  }
  return null;
}

/// The mercy opponents this player has earned back, by id.
///
/// Pebble, Twig and Mote are locked on a first launch (D382). Each opens when
/// the rung immediately above it has beaten the player at least once: a loss to
/// Hazel hands back Mote, a loss to Mote hands back Twig, a loss to Twig hands
/// back Pebble. Nobody is ever offered an easier opponent until the game has
/// shown them they might want one.
///
/// **Derived, never stored.** There is no unlock record and no new document
/// type — this is a fold over the game list, exactly like the points total, the
/// streak and the computer rating. That buys three properties for free: it is
/// idempotent, it needs no write path on the completion of a game, and a refund
/// of the "unlock every opponent" purchase cannot revoke it, because a game
/// that was lost stays lost.
///
/// [played] grandfathers the change. Anyone with a finished game against one of
/// the three keeps it: the reviews asked for a gentler *opening*, and taking an
/// opponent away from a player who has already used it would be a different and
/// worse change.
///
/// A draw is not a loss. The rule is about being beaten, and a player who draws
/// Hazel twenty times has not been beaten by it.
Set<String> mercyUnlocks({
  required Set<String> played,
  required Set<String> lostTo,
}) {
  assert(kMercyCount < opponentCatalogue.length,
      'every mercy rung needs the rung above it to exist');
  return {
    for (var i = 0; i < kMercyCount; i++)
      if (played.contains(opponentCatalogue[i].id) ||
          lostTo.contains(opponentCatalogue[i + 1].id))
        opponentCatalogue[i].id,
  };
}

/// The three roster indices Your Path shows, weakest first.
///
/// The middle one is the next unlock, which is the section's whole point: it
/// follows the **unlock** ladder, not the rating ladder. Centring on rating
/// puts a player seeded at 800 in front of three opponents they already own
/// while their next unlock sits at 1100 outside the window, so the price ladder
/// — the entire motivation for §7 — would be invisible on first launch (D262).
///
/// The window **slides rather than shrinking** at both ends. A player who has
/// unlocked nothing beyond the free five, or everything, still sees three
/// tiles; a two-tile row with a hole in it looks like a bug.
List<int> pathWindow(int? next, {int count = 0}) {
  final total = count > 0 ? count : opponentCatalogue.length;
  assert(total >= 3, 'a three-tile window needs at least three opponents');
  // Everything unlocked: show the top of the ladder, which is where such a
  // player is standing.
  final middle = next ?? total - 2;
  final start = middle <= 0 ? 0 : (middle >= total - 1 ? total - 3 : middle - 1);
  return [start, start + 1, start + 2];
}

/// How many stars an opponent's record earns, 0 to 3.
///
/// **Decisive games only, on both sides of every comparison.** Draws are
/// ignored rather than counted as half: a player who draws an opponent twenty
/// times has not beaten them, and a threshold that let draws carry weight would
/// award stars for not losing.
///
/// Zero means two different things — never played, and played without winning —
/// and the interface must not: an opponent never faced shows no star row at
/// all, rather than three empty ones (spec §11.3, U14).
int stars({required int wins, required int losses}) {
  if (wins == 0) return 0;
  final decisive = wins + losses;
  if (wins * 5 >= decisive * 4) return 3; // 80%, without floating point
  return wins >= losses ? 2 : 1;
}
