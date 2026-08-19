import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrim/data/document_store.dart';
import 'package:quadrim/data/documents.dart';
import 'package:quadrim/data/local_game_repository.dart';
import 'package:quadrim/main.dart';
import 'package:quadrim/home/quests_section.dart';
import 'package:quadrim/l10n/app_localizations.dart';
import 'package:quadrim_engine/quadrim_engine.dart';
import 'package:quadrim_progression/quadrim_progression.dart';

/// Ticket 047: the wall, and what it refuses.
///
/// The two things that can go wrong here are both about honesty rather than
/// arithmetic — the arithmetic is `quadrim_progression`'s and is proven there.
/// This is about **naming the limit that actually bit** (D221, F16), and about
/// not refusing the three things §4.2 says are never refused.
void main() {
  /// The repository's clock, moved by the fixtures so games land on the days
  /// the meter is being asked about.
  late DateTime clock;

  /// A repository whose free month has already expired, so the meter bites.
  ///
  /// `LocalGameRepository.open` stamps `freeMonthStartedAt` at first launch
  /// (D312), and while that month covers `now` nothing is ever blocked — so a
  /// paywall test on a fresh fixture would test nothing at all.
  Future<LocalGameRepository> repository({DateTime? now}) async {
    clock = now ?? DateTime(2026, 6, 1);
    final repo = await LocalGameRepository.open(
      MemoryDocumentStore(),
      now: () => clock,
    );
    final settings = await repo.loadSettings();
    await repo.saveSettings(settings.copyWith(
      freeMonthStartedAt: DateTime.utc(2026, 1, 1),
      // Otherwise the first-run tutorial prompt opens over the screen and
      // swallows the tap this whole file depends on.
      tutorialOffered: true,
    ));
    return repo;
  }

  void phone(WidgetTester tester, {double textScale = 1}) {
    tester.view.physicalSize = const Size(1080, 4400);
    tester.view.devicePixelRatio = 2.5;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  /// [count] computer games started on [day], left unfinished.
  ///
  /// Unfinished on purpose: the meter counts games *started*, and a player who
  /// opens three and finishes none has still used three.
  ///
  /// `createGame` takes no timestamp — the repository stamps it from its own
  /// clock — so the clock is moved instead, which is also closer to what
  /// actually happens.
  Future<void> startGames(
    LocalGameRepository repo,
    int count, {
    required DateTime day,
  }) async {
    clock = day;
    for (var i = 0; i < count; i++) {
      clock = day.add(Duration(minutes: i));
      await repo.createGame(
        mode: GameMode.vsComputer,
        opponent: botOpponent(opponentCatalogue.first.id),
        opponentRating: opponentCatalogue.first.rating,
      );
    }
  }

  Future<void> pumpApp(WidgetTester tester, LocalGameRepository repo,
      {DateTime? now}) async {
    await tester.pumpWidget(QuadrimApp(
      repository: repo,
      settings: repo,
      unlocks: repo,
      random: Random(1),
      now: now == null ? null : () => now,
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('the daily wall names the day, not the week', (tester) async {
    phone(tester);
    final now = DateTime(2026, 6, 10, 12);
    final repo = await repository();
    // Three today: the daily cap, with the weekly one untouched.
    await startGames(repo, 3, day: now.subtract(const Duration(hours: 2)));
    await pumpApp(tester, repo, now: now);

    await tester.tap(find.text('New game'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Play the computer'));
    await tester.pumpAndSettle();

    expect(find.text("That's today's three games"), findsOneWidget);
    expect(find.text("That's this week's nine games"), findsNothing);
  });

  testWidgets('the weekly wall names the week, on a day with room left',
      (tester) async {
    phone(tester);
    // Wednesday. Nine games already this week, none of them today — so the
    // daily limit has room and only the weekly one refuses. Saying "come back
    // tomorrow" here would be false.
    final now = DateTime(2026, 6, 10, 12);
    final repo = await repository();
    await startGames(repo, 3, day: DateTime(2026, 6, 8, 9));
    await startGames(repo, 3, day: DateTime(2026, 6, 9, 9));
    await startGames(repo, 3, day: DateTime(2026, 6, 9, 15));
    await pumpApp(tester, repo, now: now);

    await tester.tap(find.text('New game'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Play the computer'));
    await tester.pumpAndSettle();

    expect(find.text("That's this week's nine games"), findsOneWidget);
    expect(find.text("That's today's three games"), findsNothing);
  });

  testWidgets('pass and play is never refused', (tester) async {
    phone(tester);
    final now = DateTime(2026, 6, 10, 12);
    final repo = await repository();
    await startGames(repo, 9, day: DateTime(2026, 6, 8, 9));
    await startGames(repo, 3, day: now.subtract(const Duration(hours: 2)));
    await pumpApp(tester, repo, now: now);

    await tester.tap(find.text('New game'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pass and play'));
    await tester.pumpAndSettle();

    // No wall, and a board instead.
    expect(find.text("That's today's three games"), findsNothing);
    expect(find.text("That's this week's nine games"), findsNothing);
  });

  testWidgets('the wall says what it is not refusing', (tester) async {
    phone(tester);
    final now = DateTime(2026, 6, 10, 12);
    final repo = await repository();
    await startGames(repo, 3, day: now.subtract(const Duration(hours: 2)));
    await pumpApp(tester, repo, now: now);

    await tester.tap(find.text('New game'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Play the computer'));
    await tester.pumpAndSettle();

    expect(
        find.textContaining('already started can always be finished'),
        findsOneWidget);
  });

  testWidgets('inside the free month nothing is refused', (tester) async {
    phone(tester);
    final now = DateTime(2026, 1, 10, 12);
    // Default fixture: the free month was stamped at first launch and covers
    // now, so the cap does not apply however many games have been started.
    clock = DateTime(2026, 1, 1);
    final repo = await LocalGameRepository.open(
      MemoryDocumentStore(),
      now: () => clock,
    );
    final settings = await repo.loadSettings();
    await repo.saveSettings(settings.copyWith(tutorialOffered: true));
    await startGames(repo, 5, day: now.subtract(const Duration(hours: 2)));
    await pumpApp(tester, repo, now: now);

    await tester.tap(find.text('New game'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Play the computer'));
    await tester.pumpAndSettle();

    expect(find.text("That's today's three games"), findsNothing);
  });

  group('the volume quests a free player cannot reach', () {
    /// The tile on its own, rather than the four the home screen happens to
    /// rank highest — on a fresh fixture those are all per-opponent quests, so
    /// a volume tile never renders and the assertion would pass vacuously.
    Future<void> pumpTile(
      WidgetTester tester, {
      required QuestFamily family,
      required bool capped,
    }) async {
      final quest = questCatalogue.firstWhere((q) => q.family == family);
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: QuestTile(
            status: QuestStatus(
                quest: quest, current: 0, achieved: false, award: 0),
            capped: capped,
          ),
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('a volume rung says what would change it', (tester) async {
      // Five games in a day against a cap of three: unreachable by arithmetic
      // rather than by a rule (§7.4).
      await pumpTile(tester, family: QuestFamily.gamesInDay, capped: true);
      expect(find.text('Needs unlimited play'), findsOneWidget);
    });

    testWidgets('and says nothing of the sort when the cap does not apply',
        (tester) async {
      await pumpTile(tester, family: QuestFamily.gamesInDay, capped: false);
      expect(find.text('Needs unlimited play'), findsNothing);
    });

    testWidgets('a quest the cap does not block is left alone', (tester) async {
      // Every per-opponent and streak rung is completable on three games a
      // day, so marking them would be false.
      await pumpTile(tester, family: QuestFamily.firstWin, capped: true);
      expect(find.text('Needs unlimited play'), findsNothing);
    });
  });

  group('the wall at the layout extremes (U20)', () {
    for (final (name, size, scale) in <(String, Size, double)>[
      ('smallest supported phone', Size(1080, 1920), 1.0),
      ('smallest at the largest font scale', Size(1080, 1920), 2.0),
      ('largest phone at the largest font scale', Size(1290, 2796), 2.0),
    ]) {
      testWidgets(name, (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 3;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        final now = DateTime(2026, 6, 10, 12);
        final repo = await repository();
        await startGames(repo, 3, day: now.subtract(const Duration(hours: 2)));
        await pumpApp(tester, repo, now: now);

        await tester.tap(find.text('New game'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Play the computer'));
        await tester.pumpAndSettle();

        // The paywall is new and has never been through this. Overflow is
        // reported as an exception rather than as a visual, so this is the
        // whole assertion.
        expect(tester.takeException(), isNull);
        expect(find.text("That's today's three games"), findsOneWidget);
      });
    }
  });
}
