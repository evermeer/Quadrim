import 'dart:convert';
import 'dart:io';

/// Where documents physically live. Separating this from the repository keeps
/// the rules of the game — completion, validation, ordering — in one place
/// while the bytes can land in a directory, in memory, or (at 0.3a) in
/// Firestore.
///
/// It also makes widget tests possible at all: `testWidgets` runs its body in
/// a fake-async zone that never completes real file I/O, so a widget test over
/// [FileDocumentStore] hangs. Widget tests use [MemoryDocumentStore] and the
/// file store is proven by the same contract suite in plain `test` bodies.
abstract interface class DocumentStore {
  /// Every readable game document, keyed by id. Unreadable records are the
  /// store's problem to skip, not the caller's.
  Future<Map<String, Map<String, Object?>>> readGames();

  Future<void> writeGame(String id, Map<String, Object?> json);

  Future<void> deleteGame(String id);

  /// Every readable unlock document, keyed by opponent id.
  ///
  /// Under the same root as games, so the backup allowlist committed in ticket
  /// 001 covers it with no manifest change (spec §8.7). This is the only record
  /// a player cannot regenerate by playing.
  Future<Map<String, Map<String, Object?>>> readUnlocks();

  Future<void> writeUnlock(String opponentId, Map<String, Object?> json);

  /// Null when settings have never been written or cannot be read.
  Future<Map<String, Object?>?> readSettings();

  Future<void> writeSettings(Map<String, Object?> json);
}

/// One JSON document per record, keyed by id, under the application-support
/// directory (spec §8.7). That resolves to `files/quadrim/` on Android, which
/// is exactly the path the backup allowlist committed in ticket 001 includes.
///
/// Writes are atomic — write a temporary file, then rename — so a process kill
/// mid-write leaves the previous record intact rather than a truncated one.
class FileDocumentStore implements DocumentStore {
  FileDocumentStore(this._root);

  final Directory _root;

  Directory get _gamesDir => Directory('${_root.path}/games');
  Directory get _unlocksDir => Directory('${_root.path}/unlocks');
  File get _settingsFile => File('${_root.path}/settings.json');
  File _gameFile(String id) => File('${_gamesDir.path}/$id.json');
  File _unlockFile(String id) => File('${_unlocksDir.path}/$id.json');

  static Future<FileDocumentStore> open(Directory root) async {
    final store = FileDocumentStore(root);
    await store._gamesDir.create(recursive: true);
    await store._unlocksDir.create(recursive: true);
    return store;
  }

  @override
  Future<Map<String, Map<String, Object?>>> readGames() async {
    final games = <String, Map<String, Object?>>{};
    await for (final entity in _gamesDir.list()) {
      // Anything that is not a completed .json write is ignored, which covers
      // the .tmp file a kill mid-write can leave behind.
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      final json = await _read(entity);
      final id = json?['id'];
      if (json != null && id is String && id.isNotEmpty) games[id] = json;
    }
    return games;
  }

  @override
  Future<void> writeGame(String id, Map<String, Object?> json) =>
      _writeAtomically(_gameFile(id), json);

  @override
  Future<void> deleteGame(String id) async {
    final file = _gameFile(id);
    if (file.existsSync()) await file.delete();
  }

  @override
  Future<Map<String, Map<String, Object?>>> readUnlocks() async {
    final unlocks = <String, Map<String, Object?>>{};
    if (!_unlocksDir.existsSync()) return unlocks;
    await for (final entity in _unlocksDir.list()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      final json = await _read(entity);
      final id = json?['opponentId'];
      if (json != null && id is String && id.isNotEmpty) unlocks[id] = json;
    }
    return unlocks;
  }

  @override
  Future<void> writeUnlock(String opponentId, Map<String, Object?> json) =>
      _writeAtomically(_unlockFile(opponentId), json);

  @override
  Future<Map<String, Object?>?> readSettings() async =>
      _settingsFile.existsSync() ? _read(_settingsFile) : null;

  @override
  Future<void> writeSettings(Map<String, Object?> json) =>
      _writeAtomically(_settingsFile, json);

  /// Null when the file is missing or not parseable JSON. A damaged record is
  /// skipped rather than thrown so one bad file cannot lock a player out of
  /// their whole history.
  Future<Map<String, Object?>?> _read(File file) async {
    try {
      final decoded = jsonDecode(await file.readAsString());
      return decoded is Map ? decoded.cast<String, Object?>() : null;
    } on FormatException {
      return null;
    } on FileSystemException {
      return null;
    }
  }

  Future<void> _writeAtomically(File file, Map<String, Object?> json) async {
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(jsonEncode(json), flush: true);
    await temp.rename(file.path);
  }
}

/// Storage that does not outlive the process. Used by widget tests, and by
/// anything that must observably leave no trace.
class MemoryDocumentStore implements DocumentStore {
  final Map<String, Map<String, Object?>> _games = {};
  final Map<String, Map<String, Object?>> _unlocks = {};
  Map<String, Object?>? _settings;

  @override
  Future<Map<String, Map<String, Object?>>> readGames() async =>
      Map.of(_games);

  @override
  Future<void> writeGame(String id, Map<String, Object?> json) async =>
      _games[id] = Map.of(json);

  @override
  Future<void> deleteGame(String id) async => _games.remove(id);

  @override
  Future<Map<String, Map<String, Object?>>> readUnlocks() async =>
      Map.of(_unlocks);

  @override
  Future<void> writeUnlock(String opponentId, Map<String, Object?> json) async =>
      _unlocks[opponentId] = Map.of(json);

  @override
  Future<Map<String, Object?>?> readSettings() async => _settings;

  @override
  Future<void> writeSettings(Map<String, Object?> json) async =>
      _settings = Map.of(json);
}
