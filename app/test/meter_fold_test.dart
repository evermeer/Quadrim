import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quadrim/data/document_store.dart';
import 'package:quadrim/data/documents.dart';
import 'package:quadrim/data/local_game_repository.dart';
import 'package:quadrim/data/meter_fold.dart';
import 'package:quadrim_progression/quadrim_progression.dart';

/// The app half of the meter (ticket 045): which games reach it, and where the
/// free month is remembered.

GameDocument game({
  required GameMode mode,
  required DateTime createdAt,
  GameStatus status = GameStatus.complete,
  String opponent = 'bot:pebble',
}) =>
    GameDocument(
      id: 'g${createdAt.microsecondsSinceEpoch}$opponent',
      mode: mode,
      opponent: opponent,
      opponentRating: 600,
      playerSeat: 0,
      startingSeat: 0,
      startReason: StartReason.random,
      moves: const [],
      status: status,
      createdAt: createdAt,
      updatedAt: createdAt,
    );

/// A store whose settings write always fails, standing in for a full disk or a
/// read-only volume.
class _UnwritableSettingsStore extends MemoryDocumentStore {
  @override
  Future<void> writeSettings(Map<String, Object?> json) async =>
      throw const FileSystemException('no space left on device');
}

void main() {
  group('startedGamesFrom', () {
    test('counts an unfinished computer game, because it was started', () {
      final started = startedGamesFrom([
        game(
          mode: GameMode.vsComputer,
          createdAt: DateTime.utc(2026, 8, 12, 10),
          status: GameStatus.active,
        ),
      ]);
      expect(started, hasLength(1), reason: 'F17 — a game counts when started');
    });

    test('excludes pass-and-play', () {
      final started = startedGamesFrom([
        game(
          mode: GameMode.passAndPlay,
          createdAt: DateTime.utc(2026, 8, 12, 10),
          opponent: kGuestOpponent,
        ),
        game(mode: GameMode.vsComputer, createdAt: DateTime.utc(2026, 8, 12, 11)),
      ]);
      expect(started, hasLength(1));
    });

    test('uses local time, so the day is the player\'s day', () {
      final at = DateTime.utc(2026, 8, 12, 23, 30);
      final started =
          startedGamesFrom([game(mode: GameMode.vsComputer, createdAt: at)]);
      expect(started.single.startedAt, at.toLocal());
      expect(started.single.startedAt.isUtc, isFalse);
    });

    test('three started games block a fourth, end to end', () {
      // Injected, not `DateTime.now()`. An earlier version of this test read
      // the wall clock and subtracted minutes, which fails in the first three
      // minutes of every day: the games land on yesterday and today's count
      // is zero. A suite about day boundaries must not depend on which side
      // of one it runs.
      final now = DateTime(2026, 8, 12, 15);
      final games = [
        for (var i = 0; i < 3; i++)
          game(
            mode: GameMode.vsComputer,
            createdAt: now.subtract(Duration(minutes: i + 1)).toUtc(),
          ),
      ];
      final state = meterState(
        games: startedGamesFrom(games),
        now: now,
        freeMonth: FreeMonth(startedAt: DateTime(2020, 1, 1)),
      );
      expect(state.blocked, MeterLimit.daily);
      expect(state.remainingToday, 0);
    });
  });

  group('the free month record', () {
    test('is stamped at first launch', () async {
      final store = MemoryDocumentStore();
      final launched = DateTime.utc(2026, 8, 12, 9);
      final repo = await LocalGameRepository.open(store, now: () => launched);

      final settings = await repo.loadSettings();
      expect(settings.freeMonthStartedAt, launched);
      expect(freeMonthFrom(settings)!.covers(DateTime(2026, 8, 20)), isTrue);
    });

    test('is not restarted on a later launch', () async {
      final store = MemoryDocumentStore();
      final first = DateTime.utc(2026, 8, 12, 9);
      await LocalGameRepository.open(store, now: () => first);

      // Same store, a month later: re-opening must not hand out a second
      // month (§4.1 — consumed once, and never again).
      final later = DateTime.utc(2026, 9, 30, 9);
      final reopened = await LocalGameRepository.open(store, now: () => later);
      final settings = await reopened.loadSettings();

      expect(settings.freeMonthStartedAt, first);
      expect(freeMonthFrom(settings)!.covers(later), isFalse);
    });

    test('survives a write of other settings', () async {
      final store = MemoryDocumentStore();
      final launched = DateTime.utc(2026, 8, 12, 9);
      final repo = await LocalGameRepository.open(store, now: () => launched);

      await repo.saveSettings(
          (await repo.loadSettings()).copyWith(theme: 'dark'));
      final reopened = await LocalGameRepository.open(store, now: () => launched);

      expect((await reopened.loadSettings()).freeMonthStartedAt, launched);
    });

    test('a document written before this field existed is stamped on update',
        () async {
      // Every settings document 0.1 and 0.2 wrote looks like this. The month
      // must start at the update, not retroactively at first install (§4.2).
      final store = MemoryDocumentStore();
      await store.writeSettings(const {
        'schemaVersion': kSchemaVersion,
        'locale': 'nl',
        'theme': 'system',
        'tutorialCompleted': true,
        'tutorialOffered': true,
      });

      final updatedAt = DateTime.utc(2026, 8, 16, 12);
      final repo = await LocalGameRepository.open(store, now: () => updatedAt);
      final settings = await repo.loadSettings();

      expect(settings.freeMonthStartedAt, updatedAt);
      expect(settings.locale, 'nl', reason: 'the rest of the document survives');
      expect(settings.tutorialCompleted, isTrue);
    });

    test('a document from a newer build is left alone, not stamped', () async {
      // Spec §8.7: a document whose schemaVersion is greater than this build
      // understands is *skipped by the reader*, and skipped has always meant
      // it survives on disk. `fromJson` returns null for this exactly as it
      // does for an absent document, so stamping without distinguishing the
      // two writes defaults over a downgraded player's settings.
      final store = MemoryDocumentStore();
      final fromTheFuture = <String, Object?>{
        'schemaVersion': kSchemaVersion + 1,
        'locale': 'nl',
        'theme': 'dark',
        'somethingNewer': 42,
      };
      await store.writeSettings(fromTheFuture);

      await LocalGameRepository.open(store, now: () => DateTime.utc(2026, 8, 16));

      expect(await store.readSettings(), fromTheFuture,
          reason: 'the newer document is still on disk, untouched');
    });

    test('a store that cannot be written still opens', () async {
      // `open` performed no writes before the free month existed, and
      // `main.dart` does not catch. A full disk must not become "the app does
      // not start".
      final store = _UnwritableSettingsStore();
      final launched = DateTime.utc(2026, 8, 12, 9);

      final repo = await LocalGameRepository.open(store, now: () => launched);

      expect((await repo.loadSettings()).freeMonthStartedAt, launched,
          reason: 'the stamp stands for this session even though it was lost');
    });

    test('round-trips through JSON', () {
      const original = SettingsDocument(locale: 'en');
      final stamped =
          original.copyWith(freeMonthStartedAt: DateTime.utc(2026, 8, 12, 9));
      final restored = SettingsDocument.fromJson(stamped.toJson());
      expect(restored!.freeMonthStartedAt, DateTime.utc(2026, 8, 12, 9));
    });

    test('copyWith cannot clear it', () {
      final stamped = const SettingsDocument()
          .copyWith(freeMonthStartedAt: DateTime.utc(2026, 8, 12));
      expect(stamped.copyWith(theme: 'dark').freeMonthStartedAt,
          DateTime.utc(2026, 8, 12));
    });
  });
}
