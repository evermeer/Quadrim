import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrim/data/document_store.dart';
import 'package:quadrim/data/documents.dart';
import 'package:quadrim/data/local_game_repository.dart';
import 'package:quadrim/data/rating_fold.dart';
import 'package:quadrim/game/game_screen.dart';
import 'package:quadrim/home/history_screen.dart';
import 'package:quadrim/home/home_screen.dart';
import 'package:quadrim/home/trend_graph.dart';
import 'package:quadrim/l10n/app_localizations.dart';
import 'package:quadrim_engine/quadrim_engine.dart';
import 'package:quadrim_rating/quadrim_rating.dart';
import 'plaques.dart';
import 'package:quadrim/home/your_path.dart';

/// The last of the 0.1 interface (ticket 035): the trend graph, the finished
/// rows, the end-of-game panel and the portrait lock.

const _lightWinsMoves = [0, 21, 1, 22, 2, 26, 3];

final _today = DateTime(2026, 8, 14, 12);

class _Clock {
  _Clock(this.at);
  DateTime at;
  DateTime tick() => at = at.add(const Duration(seconds: 1));
  void skip(int days) => at = at.add(Duration(days: days));
}

Future<LocalGameRepository> _repository({_Clock? clock}) async {
  final ticking = clock ?? _Clock(_today.subtract(const Duration(hours: 2)));
  final repo = await LocalGameRepository.open(MemoryDocumentStore(),
      now: ticking.tick);
  addTearDown(repo.dispose);
  await repo.saveSettings(const SettingsDocument(tutorialOffered: true));
  return repo;
}

Future<GameDocument> _play(
  LocalGameRepository repo, {
  String botId = 'pebble',
  bool won = true,
}) async {
  final game = await repo.createGame(
    mode: GameMode.vsComputer,
    opponent: botOpponent(botId),
    opponentRating: botById(botId)!.rating,
    startingSeat: 0,
    playerSeat: won ? 0 : 1,
  );
  for (final move in _lightWinsMoves) {
    await repo.appendMove(game.id, move);
  }
  return game;
}

// 4400 rather than 3600, for the same reason home_screen_test.dart raised its
// own: the recently-completed panel (D298) is a seventh section, and the lazily
// built game rows below it have to stay built for a finder to reach them. The
// smallest-phone test below passes a real size explicitly and is untouched.
void _phone(WidgetTester tester,
    {double textScale = 1, Size size = const Size(1080, 4400)}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 2.5;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Widget _home(LocalGameRepository repo, {Locale? locale}) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: HomeScreen(
        repository: repo,
        settings: repo,
        unlocks: repo,
        random: Random(1),
        now: () => _today,
      ),
    );

Widget _game(LocalGameRepository repo, String id) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: GameScreen(
        repository: repo,
        gameId: id,
        random: Random(5),
        now: () => _today,
        unlocks: repo,
        opponentMove: chooseMoveInline,
      ),
    );

void main() {
  group('the trend graph', () {
    testWidgets('is absent below two completed games — not empty, absent',
        (tester) async {
      _phone(tester);
      final repo = await _repository();
      await tester.pumpWidget(_home(repo));
      await tester.pumpAndSettle();
      expect(find.byType(TrendGraph), findsNothing);

      await _play(repo);
      await tester.pumpAndSettle();
      expect(find.byType(TrendGraph), findsNothing,
          reason: 'one point is not a trend');
    });

    testWidgets('appears at two, with its change as a signed number',
        (tester) async {
      _phone(tester);
      final repo = await _repository();
      await _play(repo);
      await _play(repo);
      await tester.pumpWidget(_home(repo));
      await tester.pumpAndSettle();

      expect(find.text('Last 10 games'), findsOneWidget);
      expect(find.byType(TrendGraph), findsOneWidget);
      // The number, not the colour, is what carries the meaning: red against
      // green is the worst pair for the commonest colour vision deficiency,
      // and a line's shape says nothing to a screen reader.
      final signed = find.descendant(
          of: find.byType(TrendGraph), matching: find.textContaining('+'));
      expect(signed, findsOneWidget);
    });

    testWidgets('says its change out loud, once', (tester) async {
      _phone(tester);
      final handle = tester.ensureSemantics();
      final repo = await _repository();
      await _play(repo);
      await _play(repo);
      await tester.pumpWidget(_home(repo));
      await tester.pumpAndSettle();

      // Inside the rating card's single announcement, not a node of its own:
      // the card excludes its children and says its facts once.
      expect(find.bySemanticsLabel(RegExp(r'Last 10 games: \+\d+\.')),
          findsOneWidget);
      handle.dispose();
    });

    testWidgets('counts the first game, by measuring from the seed',
        (tester) async {
      // The bug this pins: `series` holds the rating *after* each game, so
      // measuring from its first entry drops the first game's own result. A
      // player who had won once was told their last ten games were worth
      // nothing (D289).
      _phone(tester);
      final repo = await _repository();
      await _play(repo);
      await _play(repo);
      final series = computerRatingSeries(await repo.loadCompletedGames());

      await tester.pumpWidget(_home(repo));
      await tester.pumpAndSettle();
      final expected = series.last - kSeedRating;
      expect(
          find.descendant(
              of: find.byType(TrendGraph), matching: find.text('+$expected')),
          findsOneWidget);
      // And the two are not the same number, or the test would pass either way.
      expect(series.last - series.first, lessThan(expected));
    });

    testWidgets('measures from the seed at exactly ten games too',
        (tester) async {
      // `>=` here instead of `>` was the same slip in a place nobody looks:
      // with exactly ten games there is no eleventh entry to reach back to.
      _phone(tester);
      final repo = await _repository();
      for (var i = 0; i < 10; i++) {
        await _play(repo);
      }
      final series = computerRatingSeries(await repo.loadCompletedGames());
      expect(series, hasLength(10));

      await tester.pumpWidget(_home(repo));
      await tester.pumpAndSettle();
      expect(
          find.descendant(
              of: find.byType(TrendGraph),
              matching: find.text('+${series.last - kSeedRating}')),
          findsOneWidget);
    });

    testWidgets('draws the point it measures from, so the line agrees with '
        'the number', (tester) async {
      _phone(tester);
      final repo = await _repository();
      for (var i = 0; i < 14; i++) {
        await _play(repo, botId: 'onyx', won: i.isEven);
      }
      final series = computerRatingSeries(await repo.loadCompletedGames());
      // Eleven plotted points for a ten-game window: the baseline, then one
      // per game. The baseline is a real earlier rating here rather than the
      // seed, because there are more than ten games on record.
      expect(TrendGraph.pointsOf(series), hasLength(11));
      expect(TrendGraph.pointsOf(series).first, series[series.length - 11]);
      expect(TrendGraph.changeIn(series),
          series.last - series[series.length - 11]);
    });

    testWidgets('covers the last ten and no more', (tester) async {
      _phone(tester);
      final repo = await _repository();
      // Twelve losses then two wins: over the whole history the rating fell,
      // but over the last ten games it is what those ten did.
      for (var i = 0; i < 12; i++) {
        await _play(repo, botId: 'onyx', won: false);
      }
      for (var i = 0; i < 2; i++) {
        await _play(repo, botId: 'onyx');
      }
      final series = computerRatingSeries(await repo.loadCompletedGames());
      expect(series, hasLength(14));

      await tester.pumpWidget(_home(repo));
      await tester.pumpAndSettle();
      final expected = series.last - series[series.length - 11];

      expect(
          find.descendant(
              of: find.byType(TrendGraph),
              matching: find.text(expected > 0 ? '+$expected' : '$expected')),
          findsOneWidget);
    });
  });

  group('the finished rows', () {
    testWidgets('date a game today, yesterday, and days ago', (tester) async {
      _phone(tester);
      final clock = _Clock(_today.subtract(const Duration(days: 3)));
      final repo = await _repository(clock: clock);
      await _play(repo); // three days ago
      clock.skip(2);
      await _play(repo); // yesterday
      clock.skip(1);
      await _play(repo); // today

      await tester.pumpWidget(_home(repo));
      await tester.pumpAndSettle();
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
      expect(find.text('3 days ago'), findsOneWidget);
    });

    testWidgets('falls back to the device format beyond a week',
        (tester) async {
      _phone(tester);
      final repo =
          await _repository(clock: _Clock(DateTime(2026, 5, 4, 12)));
      await _play(repo);
      await tester.pumpWidget(_home(repo));
      await tester.pumpAndSettle();

      expect(find.textContaining('days ago'), findsNothing);
      // MaterialLocalizations' own short date, which is already right in every
      // locale Flutter ships and needs no string of ours.
      expect(find.textContaining('May'), findsOneWidget);
    });

    testWidgets('the result label sits above the rating change',
        (tester) async {
      _phone(tester);
      final repo = await _repository();
      await _play(repo);
      await tester.pumpWidget(_home(repo));
      await tester.pumpAndSettle();

      final won = tester.getRect(find.text('Won'));
      final delta = tester.getRect(find.textContaining(RegExp(r'^\+\d+$')).last);
      expect(delta.top, greaterThan(won.top));
    });

    testWidgets('a challenge button starts a new game against that opponent',
        (tester) async {
      _phone(tester);
      final repo = await _repository();
      await _play(repo, botId: 'twig');
      await tester.pumpWidget(_home(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.replay));
      await tester.pumpAndSettle();

      final active = await repo.watchActiveGames().first;
      expect(active.single.opponent, botOpponent('twig'));
    });

    testWidgets('pass and play has nobody to challenge', (tester) async {
      _phone(tester);
      final repo = await _repository();
      final social = await repo.createGame(
          mode: GameMode.passAndPlay, opponent: kGuestOpponent);
      for (final move in _lightWinsMoves) {
        await repo.appendMove(social.id, move);
      }
      await tester.pumpWidget(_home(repo));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.replay), findsNothing);
    });

    testWidgets('a locked opponent has no challenge button either',
        (tester) async {
      // Not hypothetical: a stored game can name an opponent the player no
      // longer owns, and a button that starts an unplayable game is worse
      // than no button.
      _phone(tester);
      final repo = await _repository();
      await _play(repo, botId: 'onyx');
      await tester.pumpWidget(_home(repo));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.replay), findsNothing);
    });
  });

  group('show more', () {
    testWidgets('caps the main list and opens the rest on its own screen',
        (tester) async {
      _phone(tester);
      final repo = await _repository();
      for (var i = 0; i < 12; i++) {
        await _play(repo);
      }
      await tester.pumpWidget(_home(repo));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Show more'), 300,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('Show more'), findsOneWidget);
      // Scrolled *and* brought fully into view. `scrollUntilVisible` stops as
      // soon as the sliver builds the widget, which happens inside the cache
      // extent — below the fold — and the tap then lands on whatever is drawn
      // at those coordinates, which is now a carved plaque.
      await tester.ensureVisible(find.text('Show more'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show more'));
      await tester.pumpAndSettle();

      expect(find.byType(HistoryScreen), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      // A route, so there is a way back — which an expanded section does not
      // have.
      expect(find.byType(BackButton), findsOneWidget);
    });

    testWidgets('is absent while everything already fits', (tester) async {
      _phone(tester);
      final repo = await _repository();
      await _play(repo);
      await tester.pumpWidget(_home(repo));
      await tester.pumpAndSettle();
      expect(find.text('Show more'), findsNothing);
    });
  });

  group('the end of a game', () {
    testWidgets('shows what the game paid', (tester) async {
      _phone(tester);
      final repo = await _repository();
      final game = await _play(repo, botId: 'bramble');
      await tester.pumpWidget(_game(repo, game.id));
      await tester.pumpAndSettle();

      // Bramble is roster index 6, so a win pays 21 (D335's ladder).
      expect(find.text('+21 points'), findsOneWidget);
    });

    testWidgets('a loss pays nothing and says nothing about points',
        (tester) async {
      _phone(tester);
      final repo = await _repository();
      final game = await _play(repo, won: false);
      await tester.pumpWidget(_game(repo, game.id));
      await tester.pumpAndSettle();

      expect(find.textContaining('points'), findsNothing);
    });

    testWidgets('a pass-and-play result says both numbers are absent',
        (tester) async {
      _phone(tester);
      final repo = await _repository();
      final social = await repo.createGame(
          mode: GameMode.passAndPlay, opponent: kGuestOpponent);
      for (final move in _lightWinsMoves) {
        await repo.appendMove(social.id, move);
      }
      await tester.pumpWidget(_game(repo, social.id));
      await tester.pumpAndSettle();

      expect(find.text('No rating changes in pass and play.'), findsOneWidget);
      expect(find.text('Pass and play earns no points.'), findsOneWidget);
    });

    testWidgets('offers the next unlock when the win just paid for it',
        (tester) async {
      _phone(tester);
      final repo = await _repository();
      // Bramble costs 42: four Sorrel wins at thirteen each is 52, and
      // Sorrel is free, so this is a player buying their first opponent.
      for (var i = 0; i < 3; i++) {
        await _play(repo, botId: 'sorrel');
      }
      final last = await _play(repo, botId: 'sorrel');
      await tester.pumpWidget(_game(repo, last.id));
      await tester.pumpAndSettle();

      expect(find.text('You can now unlock Bramble.'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Unlock'));
      await tester.pumpAndSettle();
      expect(find.text('Unlock Bramble?'), findsOneWidget);
    });

    testWidgets('does not offer it again on the next win', (tester) async {
      _phone(tester);
      final repo = await _repository();
      for (var i = 0; i < 4; i++) {
        await _play(repo, botId: 'bramble');
      }
      final fifth = await _play(repo, botId: 'bramble');
      await tester.pumpWidget(_game(repo, fifth.id));
      await tester.pumpAndSettle();

      expect(find.textContaining('You can now unlock'), findsNothing,
          reason: 'an offer repeated after every win is an advertisement');
    });

    testWidgets('makes no offer from an older game opened out of history',
        (tester) async {
      _phone(tester);
      final repo = await _repository();
      for (var i = 0; i < 3; i++) {
        await _play(repo, botId: 'bramble');
      }
      final crossing = await _play(repo, botId: 'bramble');
      await _play(repo, botId: 'bramble');

      await tester.pumpWidget(_game(repo, crossing.id));
      await tester.pumpAndSettle();
      expect(find.textContaining('You can now unlock'), findsNothing,
          reason: 'true of a moment the player has left');
    });

    testWidgets('every new string exists in Dutch', (tester) async {
      _phone(tester);
      final repo = await _repository();
      await _play(repo);
      await _play(repo);
      await tester.pumpWidget(_home(repo, locale: const Locale('nl')));
      await tester.pumpAndSettle();

      expect(find.text('Laatste 10 partijen'), findsOneWidget);
      expect(find.text('Vandaag'), findsWidgets);
    });
  });

  group('the whole screen', () {
    testWidgets('reaches its last row at the largest font scale on the '
        'smallest supported phone, with all six sections present',
        (tester) async {
      // 360x640 dp, which is the floor this project supports, at 2x scale.
      _phone(tester, textScale: 2, size: const Size(1080, 1920));
      final repo = await _repository();
      await _play(repo, botId: 'bramble');
      // Two moves, not none: an untouched board is not listed in progress
      // (D321), and this fixture exists to put the section on the screen.
      final waiting = await repo.createGame(
        mode: GameMode.vsComputer,
        opponent: botOpponent('pebble'),
        opponentRating: 600,
      );
      await repo.appendMove(waiting.id, 0);
      await repo.appendMove(waiting.id, 21);
      await tester.pumpWidget(_home(repo));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Six scrolling sections, reached by scrolling — the seventh, the
      // primary button, is pinned below the scroll view and must be reachable
      // without it.
      //
      // **In layout order, top to bottom.** `scrollUntilVisible` only scrolls
      // one way, so a list in any other order asks it to find something it has
      // already scrolled past. That is what broke when the recently-completed
      // panel (D298) landed between the quests and the game lists — and again
      // when the in-progress list moved up to sit directly under Your Path
      // (D300). The order of this list is the order of the screen, and it has
      // to be edited whenever that changes.
      //
      // Your Path is found by type rather than by its heading, because its
      // heading is written on a carved sign that hangs off the card's corner
      // and `find.text` for it would also match the sign inside every other
      // section on a screen that has several.
      for (final section in <({String name, Finder finder})>[
        (name: 'Against the computer', finder: find.text('Against the computer')),
        (name: 'Your path', finder: find.byType(YourPath)),
        (name: 'In progress', finder: find.text('In progress')),
        (name: 'Quests', finder: find.text('Quests')),
        (name: 'Recently completed', finder: find.text('Recently completed')),
        (name: 'Finished games', finder: find.text('Finished games')),
      ]) {
        await tester.scrollUntilVisible(section.finder, 200,
            scrollable: find.byType(Scrollable).first);
        expect(section.finder, findsOneWidget, reason: section.name);
      }
      expect(plaqueLabelled('New game'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('portrait only', () {
    test('the manifest pins the orientation and refuses to be resized', () {
      // Asserted on the manifest rather than on the framework call, because
      // this is the half a freeform window manager and a foldable obey. The
      // `SystemChrome` call in main() is the half the framework obeys, and
      // neither is redundant (spec §5.2, ticket 035).
      final manifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(manifest, contains('android:screenOrientation="portrait"'));
      expect(manifest, contains('android:resizeableActivity="false"'));
    });

    test('and ticket 017, which would have built a landscape layout, is '
        'cancelled rather than pending', () {
      expect(
          Directory('../doc/tickets')
              .listSync()
              .map((e) => e.uri.pathSegments.last)
              .where((name) => name.startsWith('017')),
          isEmpty);
    });
  });

  group('the rating changes on the rows', () {
    test('are computed in one pass over the history', () async {
      // The trap ticket 035 names: the change is a property of the prefix
      // ending at each game, so the obvious per-row call re-folds the whole
      // prefix once per row and is quadratic. `ratingDeltas` walks the list
      // once and returns every row's answer, which is what makes a three
      // hundred game history the same cost as one.
      final repo = await _repository();
      for (var i = 0; i < 300; i++) {
        await _play(repo, won: i.isEven);
      }
      final completed = await repo.loadCompletedGames();
      final deltas = ratingDeltas(completed);
      expect(deltas, hasLength(300));

      // And it agrees, row for row, with the per-game fold it replaces —
      // which is the thing a one-pass rewrite is at risk of getting subtly
      // wrong. Ten samples rather than three hundred, because the check
      // itself is the quadratic one.
      for (final i in [0, 1, 7, 42, 150, 299]) {
        final game = completed[i];
        final around = computerRatingAround(completed, game.id);
        expect(deltas[game.id], around.after - around.before,
            reason: 'row $i');
      }
    });
  });
}
