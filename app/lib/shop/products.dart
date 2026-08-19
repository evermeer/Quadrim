/// The two product identifiers, and the shape of what owning them means.
///
/// **These ids can never be reused after deletion on either store**, which puts
/// them in the same category as the application id (D213): free to choose
/// carefully now, impossible to change later. They are written here once and
/// referred to by name everywhere else.
library;

/// The one-time, non-consumable "unlock all opponents" purchase (§4.1).
const String kUnlockAllProductId = 'nl.evict.quadrim.unlock_all';

/// The auto-renewing subscription — "unlimited play", yearly at 1.0.
///
/// **The id carries no tier number on purpose.** 3.0 adds tier 3 as a second
/// *base plan inside the same subscription group*, not as a second product,
/// because a plan change is the only mechanism by which the store cancels and
/// prorates the lower tier. An id reading `tier2` would then be the name of a
/// group that contains tier 3. A group cannot be retro-fitted around a product
/// that already has subscribers, and getting it wrong produces double-billed
/// users and a refund queue (D223).
const String kUnlimitedProductId = 'nl.evict.quadrim.unlimited';

/// Every id this app asks the store about.
const Set<String> kProductIds = {kUnlockAllProductId, kUnlimitedProductId};

/// What the player currently owns, as far as the store will say.
///
/// **Not persisted.** At 1.0 the store's own signed transaction is the
/// authority and it is read on the device (D303, spec S9); a cached copy on
/// disk would be a second answer that can disagree with the first, and the one
/// that disagrees is always the one a refund has not reached yet. 2.0 replaces
/// this with a server-written entitlement and deletes the local path rather
/// than keeping it as a fallback.
class Entitlement {
  const Entitlement({this.unlockAll = false, this.unlimited = false});

  /// Owns the one-time unlock of every opponent.
  final bool unlockAll;

  /// Has an active "unlimited play" subscription.
  ///
  /// False the moment the store stops reporting it — a lapse, a refund, a
  /// chargeback. **This must never touch unlocks** (§4.1): losing the
  /// subscription loses unmetered play and nothing else.
  final bool unlimited;

  static const Entitlement none = Entitlement();

  Entitlement copyWith({bool? unlockAll, bool? unlimited}) => Entitlement(
        unlockAll: unlockAll ?? this.unlockAll,
        unlimited: unlimited ?? this.unlimited,
      );

  @override
  bool operator ==(Object other) =>
      other is Entitlement &&
      other.unlockAll == unlockAll &&
      other.unlimited == unlimited;

  @override
  int get hashCode => Object.hash(unlockAll, unlimited);

  @override
  String toString() => 'Entitlement(unlockAll: $unlockAll, unlimited: $unlimited)';
}
