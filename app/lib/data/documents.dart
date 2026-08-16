/// The two persisted document shapes (spec §8.3 and §8.6).
///
/// Deliberately minimal: 0.1's data is never uploaded and 0.3 starts from an
/// empty database, so nothing here is shaped for a future cloud. In
/// particular there is **no device identifier** anywhere (spec §8.2, D90) and
/// no per-move authorship — whose move each was derives from list position
/// and [GameDocument.startingSeat].
library;

/// The version every document is written with. A document whose version is
/// greater than this is skipped by the reader; equal or lower is read and
/// upgraded (spec §8.7).
const int kSchemaVersion = 1;

enum GameMode { vsComputer, passAndPlay }

/// The lifecycle field, stored as `state`. Named [GameStatus] because the
/// engine already owns `GameState`, which is the board rather than the record.
enum GameStatus { active, complete }

enum GameOutcome { win, draw }

/// Why the game ended. Separate from the outcome because a clock-driven
/// ending cannot be derived from the moves. `timeout` and `abandonment` are
/// unreachable in 0.1 and present so the field's shape does not change when
/// they become reachable.
enum GameEndReason { line, fullBoard, resignation, timeout, abandonment }

enum StartReason { random, rematchAlternation }

/// The opponent value for the second seat in pass-and-play (spec §8.2).
const String kGuestOpponent = 'guest';

/// The opponent value for a computer opponent, e.g. `bot:onyx`.
String botOpponent(String botId) => 'bot:$botId';

/// The inverse of [botOpponent]: the catalogue id inside a stored `opponent`,
/// or null when the game was not against a computer opponent at all.
///
/// Lives beside the function it undoes so the prefix is written once on each
/// side. `bot:` is a stored format, and the two places that must agree about
/// it are here.
String? botIdOf(String opponent) =>
    opponent.startsWith('bot:') ? opponent.substring(4) : null;

T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

class GameResult {
  GameResult({
    required this.outcome,
    required this.reason,
    this.winnerSeat,
    List<int>? line,
  }) : line = line == null ? null : List.unmodifiable(line);

  final GameOutcome outcome;
  final GameEndReason reason;

  /// Null on a draw.
  final int? winnerSeat;

  /// The four cell indices of the completed line, so highlighting needs no
  /// recomputation. Null unless [reason] is [GameEndReason.line].
  final List<int>? line;

  Map<String, Object?> toJson() => {
        'outcome': outcome.name,
        'reason': reason.name,
        'winnerSeat': winnerSeat,
        'line': line,
      };

  static GameResult fromJson(Map<String, Object?> json) => GameResult(
        outcome: _enumByName(GameOutcome.values, json['outcome'], GameOutcome.draw),
        reason:
            _enumByName(GameEndReason.values, json['reason'], GameEndReason.fullBoard),
        winnerSeat: json['winnerSeat'] as int?,
        line: (json['line'] as List?)?.cast<int>(),
      );
}

class GameDocument {
  GameDocument({
    required this.id,
    required this.mode,
    required this.opponent,
    required this.opponentRating,
    required this.playerSeat,
    required this.startingSeat,
    required this.startReason,
    required List<int> moves,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.result,
    this.rematchOf,
    this.schemaVersion = kSchemaVersion,
  }) : moves = List.unmodifiable(moves);

  final String id;
  final int schemaVersion;
  final GameMode mode;

  /// `bot:<botId>` or [kGuestOpponent]. The only record of who was played.
  final String opponent;

  /// The anchor rating this game was actually played against, so recalibrating
  /// an opponent later is a deliberate re-fold rather than a silent rewrite of
  /// the player's history. Null for [kGuestOpponent], which has no rating.
  final int? opponentRating;

  final int playerSeat;
  final int startingSeat;
  final StartReason startReason;

  /// Cell indices 0..63, in play order. Append-only and complete, which is
  /// what makes replay a pure fold.
  final List<int> moves;

  final GameStatus status;

  /// The fold's ordering key, with [id] as tie-break.
  final DateTime? completedAt;
  final GameResult? result;
  final String? rematchOf;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Which seat plays the move at [index]. Turns strictly alternate, so this
  /// is derived rather than stored (spec §8.3).
  int seatForMove(int index) => (startingSeat + index) % 2;

  /// The seat whose turn it is now.
  int get seatToMove => seatForMove(moves.length);

  GameDocument copyWith({
    List<int>? moves,
    GameStatus? status,
    DateTime? completedAt,
    GameResult? result,
    DateTime? updatedAt,
  }) =>
      GameDocument(
        id: id,
        schemaVersion: schemaVersion,
        mode: mode,
        opponent: opponent,
        opponentRating: opponentRating,
        playerSeat: playerSeat,
        startingSeat: startingSeat,
        startReason: startReason,
        moves: moves ?? this.moves,
        status: status ?? this.status,
        completedAt: completedAt ?? this.completedAt,
        result: result ?? this.result,
        rematchOf: rematchOf,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'schemaVersion': schemaVersion,
        'mode': mode.name,
        'opponent': opponent,
        'opponentRating': opponentRating,
        'playerSeat': playerSeat,
        'startingSeat': startingSeat,
        'startReason': startReason.name,
        'moves': moves,
        'state': status.name,
        'completedAt': completedAt?.toUtc().toIso8601String(),
        'result': result?.toJson(),
        'rematchOf': rematchOf,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  /// Returns null when the document cannot be read: a schema version newer
  /// than this build understands, or a record damaged beyond parsing. Both
  /// are skipped rather than thrown, so one bad file cannot lock a player out
  /// of their history.
  static GameDocument? fromJson(Map<String, Object?> json) {
    final version = json['schemaVersion'];
    if (version is! int || version > kSchemaVersion) return null;
    final id = json['id'];
    final createdAt = DateTime.tryParse(json['createdAt'] as String? ?? '');
    final updatedAt = DateTime.tryParse(json['updatedAt'] as String? ?? '');
    if (id is! String || id.isEmpty || createdAt == null || updatedAt == null) {
      return null;
    }
    return GameDocument(
      id: id,
      schemaVersion: version,
      mode: _enumByName(GameMode.values, json['mode'], GameMode.passAndPlay),
      opponent: json['opponent'] as String? ?? kGuestOpponent,
      opponentRating: json['opponentRating'] as int?,
      playerSeat: json['playerSeat'] as int? ?? 0,
      startingSeat: json['startingSeat'] as int? ?? 0,
      startReason:
          _enumByName(StartReason.values, json['startReason'], StartReason.random),
      moves: (json['moves'] as List?)?.cast<int>() ?? const [],
      status: _enumByName(GameStatus.values, json['state'], GameStatus.active),
      completedAt: DateTime.tryParse(json['completedAt'] as String? ?? ''),
      result: json['result'] == null
          ? null
          : GameResult.fromJson((json['result'] as Map).cast<String, Object?>()),
      rematchOf: json['rematchOf'] as String?,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Where an unlock came from, so a refund can revoke exactly what it bought.
///
/// [purchase] is unreachable until 0.4 adds the one-time "unlock all
/// opponents" product, and is present now because the field's shape should not
/// change when it becomes reachable — the same reasoning that puts `timeout`
/// and `abandonment` in [GameEndReason].
enum UnlockSource { points, purchase }

/// An opponent bought with points (spec §8.8).
///
/// **The one thing in this app that is not reconstructible from game history.**
/// Points earned is a fold over the games; points *spent* is a decision, and a
/// decision is not in the move list. Everything else stays derived — there is
/// no stored balance, no stored streak length and no stored quest progress.
///
/// It is written under the same directory as games, so it is covered by the
/// backup allowlist committed in ticket 001 with no manifest change. That
/// matters from 0.1 rather than from whenever the cloud arrives: it is the only
/// thing here a player cannot regenerate by playing, and losing it on a device
/// change loses months of work.
class UnlockDocument {
  const UnlockDocument({
    required this.opponentId,
    required this.unlockedAt,
    required this.pricePaid,
    this.source = UnlockSource.points,
    this.schemaVersion = kSchemaVersion,
  });

  final int schemaVersion;

  /// The catalogue id, without the `bot:` prefix. **Also the document id**, so
  /// buying the same opponent twice overwrites one record rather than storing
  /// two and charging for both.
  final String opponentId;

  final DateTime unlockedAt;

  /// What was **actually** paid, not what the table says today.
  ///
  /// Stored for the same reason a game stores the opponent's anchor rating: the
  /// balance is earned minus the sum of these, so re-tuning a cost later can
  /// never retroactively bankrupt someone who already spent at the old price.
  final int pricePaid;

  final UnlockSource source;

  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'opponentId': opponentId,
        'unlockedAt': unlockedAt.toUtc().toIso8601String(),
        'pricePaid': pricePaid,
        'source': source.name,
      };

  /// Null when unreadable — see [GameDocument.fromJson]. A damaged unlock is
  /// skipped rather than thrown, but it is the one record whose loss actually
  /// costs the player something, which is why it is also the one that is
  /// written under the backup allowlist.
  static UnlockDocument? fromJson(Map<String, Object?> json) {
    final version = json['schemaVersion'];
    if (version is! int || version > kSchemaVersion) return null;
    final opponentId = json['opponentId'];
    final unlockedAt = DateTime.tryParse(json['unlockedAt'] as String? ?? '');
    final pricePaid = json['pricePaid'];
    if (opponentId is! String ||
        opponentId.isEmpty ||
        unlockedAt == null ||
        pricePaid is! int) {
      return null;
    }
    return UnlockDocument(
      schemaVersion: version,
      opponentId: opponentId,
      unlockedAt: unlockedAt,
      pricePaid: pricePaid,
      source: _enumByName(UnlockSource.values, json['source'], UnlockSource.points),
    );
  }
}

/// The only local document besides games and unlocks (spec §8.6). The computer
/// rating is deliberately absent: it is folded from completed games, so storing
/// it would create a second copy that can drift.
class SettingsDocument {
  const SettingsDocument({
    this.locale = 'system',
    this.theme = 'system',
    this.tutorialCompleted = false,
    this.tutorialOffered = false,
    this.freeMonthStartedAt,
    this.schemaVersion = kSchemaVersion,
  });

  final int schemaVersion;

  /// When this installation first launched, which is when the unmetered first
  /// month began (§4.2, ticket 045).
  ///
  /// **Not a preference, and this document is otherwise entirely preferences.**
  /// It is here rather than in a document of its own because it is one
  /// timestamp, and settings are already stored, already versioned, already
  /// inside the backup allowlist and already fall back to defaults when
  /// unreadable — all four of which a new document would have to be given
  /// (D312).
  ///
  /// It is also the **second** thing this app stores that game history cannot
  /// reconstruct, after the unlock records. A player who installs and does not
  /// play still has a month running, so there is no game to derive it from.
  ///
  /// Null until first launch stamps it. Null means *unmetered*, never expired:
  /// a missing record must fail towards letting the player play.
  final DateTime? freeMonthStartedAt;

  /// `en`, `nl` or `system`.
  final String locale;

  /// `light`, `dark` or `system`.
  final String theme;

  final bool tutorialCompleted;

  /// Whether the first-launch offer has been made. Separate from
  /// [tutorialCompleted] because declining is not the same as having learnt
  /// the game: one boolean would have to lie about one of the two, and the
  /// alternative — asking again every launch until the player gives in — is
  /// the behaviour nobody wants (D193).
  final bool tutorialOffered;

  SettingsDocument copyWith({
    String? locale,
    String? theme,
    bool? tutorialCompleted,
    bool? tutorialOffered,
    DateTime? freeMonthStartedAt,
  }) =>
      SettingsDocument(
        locale: locale ?? this.locale,
        theme: theme ?? this.theme,
        tutorialCompleted: tutorialCompleted ?? this.tutorialCompleted,
        tutorialOffered: tutorialOffered ?? this.tutorialOffered,
        // Never cleared through here. The free month is consumed once and
        // never begins again (§4.1), so a `copyWith` that could null it is a
        // way to hand someone a second one by passing the wrong argument.
        freeMonthStartedAt: freeMonthStartedAt ?? this.freeMonthStartedAt,
      );

  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'locale': locale,
        'theme': theme,
        'tutorialCompleted': tutorialCompleted,
        'tutorialOffered': tutorialOffered,
        'freeMonthStartedAt': freeMonthStartedAt?.toUtc().toIso8601String(),
      };

  /// Null when unreadable — see [GameDocument.fromJson]. The caller falls back
  /// to defaults rather than failing to start.
  static SettingsDocument? fromJson(Map<String, Object?> json) {
    final version = json['schemaVersion'];
    if (version is! int || version > kSchemaVersion) return null;
    return SettingsDocument(
      schemaVersion: version,
      locale: json['locale'] as String? ?? 'system',
      theme: json['theme'] as String? ?? 'system',
      tutorialCompleted: json['tutorialCompleted'] as bool? ?? false,
      // Absent in documents written before this field existed. Defaulting to
      // false re-offers the tutorial once to an existing player, which is the
      // safe direction: the cost is one dismissable dialog, where defaulting
      // true would silently deny it to everyone who upgrades.
      tutorialOffered: json['tutorialOffered'] as bool? ?? false,
      // Also absent in documents written before this field existed — every
      // document written by 0.1 and 0.2. Null there means the repository
      // stamps it at the next launch, so an existing player's free month
      // starts when they update rather than retroactively at whenever they
      // first installed. That is the rule §4.2 already states for players who
      // predate the meter, arriving here as the natural reading of a missing
      // field rather than as a migration.
      freeMonthStartedAt:
          DateTime.tryParse(json['freeMonthStartedAt'] as String? ?? ''),
    );
  }
}
