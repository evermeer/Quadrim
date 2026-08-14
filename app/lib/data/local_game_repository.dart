import 'dart:async';
import 'dart:math';

import 'package:quadrim_engine/quadrim_engine.dart' as engine;
import 'package:quadrim_progression/quadrim_progression.dart' as progression;

import 'document_store.dart';
import 'documents.dart';
import 'game_repository.dart';

/// The 0.1 implementation of [GameRepository], over a pluggable
/// [DocumentStore].
///
/// Documents are held in memory after the initial load. Local history is small
/// and never behind a network, and this is what lets the main screen fold one
/// list four ways instead of sweeping storage four times (spec §9.5).
class LocalGameRepository
    implements GameRepository, SettingsRepository, UnlockRepository {
  LocalGameRepository._(
    this._store,
    this._now,
    this._newId,
    this._games,
    this._unlocks,
    this._settings,
  );

  final DocumentStore _store;
  final DateTime Function() _now;
  final String Function() _newId;

  final Map<String, GameDocument> _games;

  /// Keyed by opponent id, which is also the document id — so buying the same
  /// opponent twice overwrites one record rather than charging twice.
  final Map<String, UnlockDocument> _unlocks;

  SettingsDocument _settings;

  final StreamController<void> _changes = StreamController<void>.broadcast();

  /// Loads every readable document from [store]. [now] and [newId] are
  /// injected so tests are deterministic; production uses the wall clock and a
  /// random id.
  static Future<LocalGameRepository> open(
    DocumentStore store, {
    DateTime Function()? now,
    String Function()? newId,
  }) async {
    final games = <String, GameDocument>{};
    for (final json in (await store.readGames()).values) {
      final doc = GameDocument.fromJson(json);
      if (doc != null) games[doc.id] = doc;
    }
    final unlocks = <String, UnlockDocument>{};
    for (final json in (await store.readUnlocks()).values) {
      final doc = UnlockDocument.fromJson(json);
      if (doc != null) unlocks[doc.opponentId] = doc;
    }
    final settings = SettingsDocument.fromJson(await store.readSettings() ?? {});
    return LocalGameRepository._(
      store,
      now ?? () => DateTime.now().toUtc(),
      newId ?? _randomId,
      games,
      unlocks,
      settings ?? const SettingsDocument(),
    );
  }

  static final Random _random = Random();

  /// Microsecond timestamp plus randomness: unique within a run and stable
  /// across restarts, with no device identifier involved (D2/S2).
  static String _randomId() {
    final stamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final suffix = _random.nextInt(1 << 32).toRadixString(36).padLeft(7, '0');
    return '$stamp-$suffix';
  }

  Future<GameDocument> _save(GameDocument game) async {
    await _store.writeGame(game.id, game.toJson());
    _games[game.id] = game;
    _emit();
    return game;
  }

  void _emit() {
    if (!_changes.isClosed) _changes.add(null);
  }

  /// Emits the current value now and again after every change, so `watch`
  /// streams give a subscriber the present state without waiting for a write.
  ///
  /// The subscription is taken *before* the current value is pushed. Yielding
  /// first and subscribing after leaves a microtask-wide gap in which a write
  /// emits to a broadcast controller nobody is listening to, and the
  /// subscriber then shows stale state until the next write.
  /// [Stream.multi] gives each listener its own controller, so the change
  /// subscription is in place *before* the current value is delivered. An
  /// async* generator that yields first and subscribes after leaves a
  /// microtask-wide gap in which a write emits to a broadcast controller
  /// nobody is listening to, and the subscriber then shows stale state until
  /// the next write.
  ///
  /// onCancel deliberately does not return the inner cancel future. Awaiting
  /// a broadcast subscription's cancel never completes inside `testWidgets`'
  /// fake-async zone, which would hang `.first` — and there is nothing useful
  /// to wait for, since cancelling a broadcast subscription cannot fail.
  Stream<T> _watch<T>(T Function() value) => Stream<T>.multi((controller) {
        final subscription =
            _changes.stream.listen((_) => controller.add(value()));
        controller.add(value());
        controller.onCancel = () {
          subscription.cancel();
        };
      });

  List<GameDocument> _active() =>
      _games.values.where((g) => g.status == GameStatus.active).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  /// Ordered by [GameDocument.completedAt] with the id as tie-break — the
  /// ordering the rating fold requires (spec §8.3).
  List<GameDocument> _completed() =>
      _games.values.where((g) => g.status == GameStatus.complete).toList()
        ..sort((a, b) {
          final byTime = (b.completedAt ?? b.updatedAt)
              .compareTo(a.completedAt ?? a.updatedAt);
          return byTime != 0 ? byTime : b.id.compareTo(a.id);
        });

  @override
  Stream<GameDocument?> watchGame(String id) => _watch(() => _games[id]);

  @override
  Stream<List<GameDocument>> watchActiveGames() => _watch(_active);

  @override
  Stream<List<GameDocument>> watchCompletedGames() => _watch(_completed);

  @override
  Future<List<GameDocument>> loadCompletedGames() async => _completed();

  @override
  Future<GameDocument> createGame({
    required GameMode mode,
    required String opponent,
    int? opponentRating,
    int playerSeat = 0,
    int startingSeat = 0,
    StartReason startReason = StartReason.random,
    String? rematchOf,
  }) {
    final at = _now();
    return _save(GameDocument(
      id: _newId(),
      mode: mode,
      opponent: opponent,
      opponentRating: opponentRating,
      playerSeat: playerSeat,
      startingSeat: startingSeat,
      startReason: startReason,
      moves: const [],
      status: GameStatus.active,
      createdAt: at,
      updatedAt: at,
      rematchOf: rematchOf,
    ));
  }

  @override
  // async so validation failures surface through the returned Future rather
  // than throwing synchronously out of a Future-returning call.
  Future<GameDocument> appendMove(String id, int cell) async {
    final game = _requireActive(id);
    final moves = [...game.moves, cell];
    // Replaying validates the move: fromMoves rejects an occupied or
    // out-of-range cell, so an illegal append cannot reach storage.
    final outcome = engine.outcome(engine.GameState.fromMoves(moves));
    final at = _now();
    return _save(switch (outcome) {
      engine.Ongoing() => game.copyWith(moves: moves, updatedAt: at),
      // The winner is whoever played the completing move, so the seat comes
      // from the move index rather than from mapping the engine's Player back
      // through startingSeat.
      engine.Win(line: final line) => game.copyWith(
          moves: moves,
          status: GameStatus.complete,
          completedAt: at,
          updatedAt: at,
          result: GameResult(
            outcome: GameOutcome.win,
            reason: GameEndReason.line,
            winnerSeat: game.seatForMove(moves.length - 1),
            line: line,
          ),
        ),
      engine.Draw() => game.copyWith(
          moves: moves,
          status: GameStatus.complete,
          completedAt: at,
          updatedAt: at,
          result: GameResult(
            outcome: GameOutcome.draw,
            reason: GameEndReason.fullBoard,
          ),
        ),
    });
  }

  @override
  Future<GameDocument> resign(String id, {required int seat}) async {
    final game = _requireActive(id);
    final at = _now();
    return _save(game.copyWith(
      status: GameStatus.complete,
      completedAt: at,
      updatedAt: at,
      result: GameResult(
        outcome: GameOutcome.win,
        reason: GameEndReason.resignation,
        winnerSeat: (seat + 1) % 2,
      ),
    ));
  }

  @override
  Future<void> deleteGame(String id) async {
    await _store.deleteGame(id);
    _games.remove(id);
    _emit();
  }

  GameDocument _requireActive(String id) {
    final game = _games[id];
    if (game == null) throw ArgumentError.value(id, 'id', 'no such game');
    if (game.status != GameStatus.active) {
      throw StateError('game $id is already complete');
    }
    return game;
  }

  /// Oldest first, so the list reads as the ladder the player climbed.
  List<UnlockDocument> _unlockList() => _unlocks.values.toList()
    ..sort((a, b) {
      final byTime = a.unlockedAt.compareTo(b.unlockedAt);
      return byTime != 0 ? byTime : a.opponentId.compareTo(b.opponentId);
    });

  @override
  Stream<List<UnlockDocument>> watchUnlocks() => _watch(_unlockList);

  @override
  Future<List<UnlockDocument>> loadUnlocks() async => _unlockList();

  @override
  Future<UnlockDocument> purchase(
    String opponentId, {
    required int pricePaid,
    UnlockSource source = UnlockSource.points,
  }) async {
    final owned = _unlocks.keys.toSet();
    if (progression.isUnlocked(opponentId, owned)) {
      throw StateError('$opponentId is already unlocked');
    }
    // Sequential, always. Checked here rather than only in the UI because this
    // is the only writer, and "four wins buys the *next* opponent" stops being
    // a promise the moment some other path can skip ahead (D229).
    final next = progression.nextUnlockIndex(owned);
    if (next == null || engine.opponentCatalogue[next].id != opponentId) {
      throw ArgumentError.value(
          opponentId, 'opponentId', 'not the next opponent in roster order');
    }
    final unlock = UnlockDocument(
      opponentId: opponentId,
      unlockedAt: _now(),
      pricePaid: pricePaid,
      source: source,
    );
    await _store.writeUnlock(opponentId, unlock.toJson());
    _unlocks[opponentId] = unlock;
    _emit();
    return unlock;
  }

  @override
  Stream<SettingsDocument> watchSettings() => _watch(() => _settings);

  @override
  Future<SettingsDocument> loadSettings() async => _settings;

  @override
  Future<SettingsDocument> saveSettings(SettingsDocument settings) async {
    await _store.writeSettings(settings.toJson());
    _settings = settings;
    _emit();
    return settings;
  }

  Future<void> dispose() => _changes.close();
}
