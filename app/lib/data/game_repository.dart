import 'documents.dart';

/// The single boundary all stored data crosses (spec §9.5, criterion S4).
///
/// Stream-based rather than future-based even though 0.1's storage is a local
/// directory with no push: release 0.3a's Firestore implementation is
/// push-based and must satisfy this same contract by passing the same tests,
/// and a future-shaped API would force a UI rewrite at that point (spec §9.6).
///
/// Every `watch` stream emits the current value on subscription and again on
/// every change, so a caller can also read the present state with `.first`.
abstract interface class GameRepository {
  /// Emits null if the game does not exist or is deleted while watched.
  Stream<GameDocument?> watchGame(String id);

  Stream<List<GameDocument>> watchActiveGames();

  /// Most recently completed first.
  Stream<List<GameDocument>> watchCompletedGames();

  /// One-shot read of every completed game, so the main screen can fold the
  /// same in-memory list four ways (statistics, per-opponent breakdown,
  /// computer rating, milestones) rather than sweeping storage four times.
  Future<List<GameDocument>> loadCompletedGames();

  Future<GameDocument> createGame({
    required GameMode mode,
    required String opponent,
    int? opponentRating,
    int playerSeat = 0,
    int startingSeat = 0,
    StartReason startReason = StartReason.random,
    String? rematchOf,
  });

  /// Appends [cell] and, when that move ends the game, records the result.
  ///
  /// Completion lives here rather than in each caller because it is a pure
  /// function of the move list: any caller that forgot would leave a finished
  /// game stored as active forever.
  ///
  /// Throws [StateError] if the game is already complete, and [ArgumentError]
  /// if the move is not legal.
  Future<GameDocument> appendMove(String id, int cell);

  /// Ends the game with [seat] resigning; the other seat wins.
  Future<GameDocument> resign(String id, {required int seat});

  Future<void> deleteGame(String id);
}

/// Settings use the same storage mechanism as games (spec §8.6).
abstract interface class SettingsRepository {
  Stream<SettingsDocument> watchSettings();
  Future<SettingsDocument> loadSettings();
  Future<SettingsDocument> saveSettings(SettingsDocument settings);
}

/// What the player has bought, and the one action that buys it.
///
/// Separate from [GameRepository] because they are separate contracts, even
/// though 0.1's one implementation satisfies both — the same relationship
/// [SettingsRepository] already has.
///
/// **Client-written and local, deliberately.** Points are earned against
/// deterministic opponents on the player's own hardware, exactly like the
/// computer rating, so editing them cheats nobody but yourself. Moving this to
/// a server would mean sending computer-game results to a server, which spec
/// §4 forbids categorically (spec §7.6).
abstract interface class UnlockRepository {
  /// Emits the current set on subscription and again on every purchase.
  Stream<List<UnlockDocument>> watchUnlocks();

  Future<List<UnlockDocument>> loadUnlocks();

  /// Records [opponentId] as bought at [pricePaid].
  ///
  /// The price is passed in rather than looked up, because what must be stored
  /// is what was actually charged — a cost table that moves later must not
  /// rewrite what a player already spent (spec §8.8).
  ///
  /// Throws [StateError] if the opponent is already unlocked, and
  /// [ArgumentError] if it is not the next one in roster order: only the
  /// lowest-indexed locked opponent may ever be purchased (D229).
  Future<UnlockDocument> purchase(
    String opponentId, {
    required int pricePaid,
    UnlockSource source,
  });
}

