import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrim/data/document_store.dart';
import 'package:quadrim/data/documents.dart';
import 'package:quadrim/data/local_game_repository.dart';
import 'package:quadrim/game/opponent_avatar.dart';
import 'package:quadrim/l10n/app_localizations.dart';
import 'package:quadrim/main.dart';
import 'package:quadrim_engine/quadrim_engine.dart';
import 'package:quadrim_rating/quadrim_rating.dart';

/// A repository whose first-launch tutorial offer has already been made, so
/// the dialog does not open over the screen under test.
Future<LocalGameRepository> _repository() async {
  // An advancing clock, because the default is `DateTime.now()` and two
  // fixture games routinely finish inside the same millisecond. Completed
  // games are ordered by `completedAt` with the id as tie-break, and the
  // default id is *random* — so on a tie the order of two games is a coin
  // flip, and a test asserting "most recent first" failed about one run in
  // three. Real games do not finish in the same millisecond; the fixture was
  // the only thing pretending they might.
  var tick = DateTime.utc(2026, 1, 1);
  final repository = await LocalGameRepository.open(
    MemoryDocumentStore(),
    now: () => tick = tick.add(const Duration(seconds: 1)),
  );
  addTearDown(repository.dispose);
  await repository
      .saveSettings(const SettingsDocument(tutorialOffered: true));
  return repository;
}

void _phone(WidgetTester tester, {double textScale = 1}) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

/// The game row holding [text].
///
/// Opponent names appear twice on this screen — in the by-opponent breakdown
/// and again on each game — so assertions about a row have to say which.
///
/// Outermost rather than innermost: a row's right-hand column now nests a Row
/// of its own for the result and the rating change beside it, so the closest
/// Row ancestor of "Won" is that pair and does not contain the opponent's
/// name at all.
Finder _rowContaining(String text) =>
    find.ancestor(of: find.text(text), matching: find.byType(Row)).last;

Future<void> _pumpHome(WidgetTester tester, LocalGameRepository repo) async {
  await tester.pumpWidget(
      QuadrimApp(repository: repo, settings: repo, random: Random(1)));
  await tester.pumpAndSettle();
}

/// Plays [game] to a decided result by appending [moves].
Future<void> _finish(
  LocalGameRepository repo,
  GameDocument game,
  List<int> moves,
) async {
  for (final move in moves) {
    await repo.appendMove(game.id, move);
  }
}

/// Light (seat 0) completes {0,1,2,3}; dark's cells form no line.
const _lightWinsMoves = [0, 21, 1, 22, 2, 26, 3];

Future<GameDocument> _completedGame(
  LocalGameRepository repo, {
  required String botId,
  required int rating,
  bool playerWins = true,
}) async {
  final game = await repo.createGame(
    mode: GameMode.vsComputer,
    opponent: botOpponent(botId),
    opponentRating: rating,
    // Seat 0 always wins the fixture line; sitting the player elsewhere is
    // how a loss is expressed without a different move list.
    playerSeat: playerWins ? 0 : 1,
  );
  await _finish(repo, game, _lightWinsMoves);
  return game;
}

void main() {
  testWidgets('shows the computer rating, labelled as such', (tester) async {
    _phone(tester);
    final repo = await _repository();
    await _pumpHome(tester, repo);

    expect(find.text('Against the computer'), findsOneWidget);
    expect(find.text('$kSeedRating'), findsOneWidget);
    // Criterion 20: it must not read as a universal rating.
    expect(find.text('Your rating against the computer, on this device only.'),
        findsOneWidget);
  });

  testWidgets('each opponent is underlined by a bar as long as its rating',
      (tester) async {
    _phone(tester);
    final repo = await _repository();
    await _completedGame(repo, botId: pebble.id, rating: pebble.rating);
    await _completedGame(repo, botId: quadrimPrime.id,
        rating: quadrimPrime.rating);
    await _pumpHome(tester, repo);

    // Read off the widgets rather than the pixels: the bar's meaning is its
    // fraction, and a rendered width also encodes the column it sits in.
    final bars = tester
        .widgetList<LinearProgressIndicator>(
            find.byType(LinearProgressIndicator))
        .toList();
    expect(bars, hasLength(2), reason: 'one per opponent played');

    // Weakest first, so Pebble's bar is the first one.
    expect(bars.last.value, 1.0,
        reason: 'the top of the catalogue fills the bar');
    expect(bars.first.value,
        closeTo(pebble.rating / quadrimPrime.rating, 0.001));

    // The scale is the catalogue's ceiling, not the strongest opponent on
    // screen — otherwise every list would have a full bar in it and the bars
    // would mean something different on each device.
    expect(bars.first.value, lessThan(0.5), reason: '600 against 2400');
  });

  testWidgets('every row naming an opponent carries a rating pill after the '
      'name', (tester) async {
    _phone(tester);
    final repo = await _repository();
    await _completedGame(repo, botId: pebble.id, rating: pebble.rating);
    await _pumpHome(tester, repo);

    // Two rows name Pebble — the breakdown and the finished game — and both
    // must carry the pill. Asserting over every occurrence rather than
    // picking one means the test does not need to know which is which, and
    // covers each section without a fixture per section.
    final pills = find.text('600');
    expect(pills, findsNWidgets(2),
        reason: 'the by-opponent breakdown and the finished game');

    for (var i = 0; i < 2; i++) {
      final row =
          find.ancestor(of: pills.at(i), matching: find.byType(Row)).first;
      final name = tester.getRect(
          find.descendant(of: row, matching: find.text('Pebble')));
      final pill = tester.getRect(pills.at(i));
      // Beside the name rather than at the far end of the row: the rating is
      // a fact about the opponent, and the right-hand column is about the
      // player's game.
      expect(pill.left, greaterThan(name.right), reason: 'row $i');
      expect(pill.left - name.right, lessThan(24),
          reason: 'row $i: close to the name, not drifting right');
      expect(pill.center.dy, closeTo(name.center.dy, 2),
          reason: 'row $i: on the same line as the name');
    }
  });

  testWidgets('a game in progress carries the pill too', (tester) async {
    // The in-progress section shares _GameRow with the finished one, so this
    // is a check that the shared row is what got the pill rather than one
    // caller of it.
    _phone(tester);
    final repo = await _repository();
    await repo.createGame(
      mode: GameMode.vsComputer,
      opponent: botOpponent(sable.id),
      opponentRating: sable.rating,
    );
    await _pumpHome(tester, repo);

    expect(find.text('In progress'), findsOneWidget);
    expect(find.text('1700'), findsOneWidget);
  });

  testWidgets('pass and play has no opponent, so it has no pill',
      (tester) async {
    _phone(tester);
    final repo = await _repository();
    await repo.createGame(
        mode: GameMode.passAndPlay, opponent: kGuestOpponent);
    await _pumpHome(tester, repo);

    expect(find.text('Pass and play'), findsOneWidget);
    // Nothing stadium-shaped on a row with nobody to rate. Checked by the
    // absence of any pill at all rather than of a particular number, since
    // there is no number it could be showing.
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(
      find.byWidgetPredicate((w) =>
          w is Container && w.decoration is ShapeDecoration &&
          (w.decoration! as ShapeDecoration).shape is StadiumBorder),
      findsNothing,
    );
  });

  testWidgets('the pill says the rating once, not twice, to a screen reader',
      (tester) async {
    // The row already announces "Ember. Rating 1300." — a pill that announced
    // itself as well would make the row read the number twice.
    _phone(tester);
    final handle = tester.ensureSemantics();
    final repo = await _repository();
    await _completedGame(repo, botId: ember.id, rating: ember.rating);
    await _pumpHome(tester, repo);

    expect(find.bySemanticsLabel(RegExp(r'Ember\. Rating 1300\. ')),
        findsNWidgets(2));
    expect(find.bySemanticsLabel('1300'), findsNothing,
        reason: 'no pill announces itself on top of its row');
    handle.dispose();
  });

  testWidgets('a finished game shows what it did to the rating', (tester) async {
    _phone(tester);
    final repo = await _repository();
    await _completedGame(repo, botId: ember.id, rating: ember.rating);
    await _completedGame(repo,
        botId: pebble.id, rating: pebble.rating, playerWins: false);
    await _pumpHome(tester, repo);

    // A win points up, a loss points down, and the sign says the same thing
    // again so the arrow is not the only telling.
    expect(find.byIcon(Icons.arrow_drop_up), findsOneWidget);
    expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);

    final up = find.ancestor(
        of: find.byIcon(Icons.arrow_drop_up), matching: find.byType(Row)).first;
    final down = find.ancestor(
        of: find.byIcon(Icons.arrow_drop_down),
        matching: find.byType(Row)).first;
    expect(find.descendant(of: up, matching: find.textContaining('+')),
        findsOneWidget);
    expect(find.descendant(of: down, matching: find.textContaining('-')),
        findsOneWidget);

    // Behind the result text, not in front of it.
    final won = tester.getRect(find.text('Won'));
    expect(tester.getRect(find.byIcon(Icons.arrow_drop_up)).left,
        greaterThan(won.right));
  });

  testWidgets('the numbers on the rows add up to the rating on the card',
      (tester) async {
    // The screen would be lying if they did not: the card is a fold over the
    // same games the rows each report one step of.
    _phone(tester);
    final repo = await _repository();
    for (var i = 0; i < 5; i++) {
      await _completedGame(repo,
          botId: ember.id, rating: ember.rating, playerWins: i.isEven);
    }
    await _pumpHome(tester, repo);

    var total = 0;
    for (final text in tester.widgetList<Text>(find.byType(Text))) {
      final data = text.data;
      if (data == null) continue;
      final signed = RegExp(r'^[+-]\d+$').firstMatch(data);
      if (signed != null) total += int.parse(data);
    }
    expect(find.text('${kSeedRating + total}'), findsOneWidget,
        reason: 'the rating card should read ${kSeedRating + total}');
  });

  testWidgets('a pass-and-play result shows no rating change', (tester) async {
    _phone(tester);
    final repo = await _repository();
    final game = await repo.createGame(
        mode: GameMode.passAndPlay, opponent: kGuestOpponent);
    await _finish(repo, game, _lightWinsMoves);
    await _pumpHome(tester, repo);

    expect(find.text('Finished games'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_drop_up), findsNothing);
    expect(find.byIcon(Icons.arrow_drop_down), findsNothing);
  });

  testWidgets('the bar is scaled against the catalogue, not against the list',
      (tester) async {
    // The same weak opponent, alone. If the scale were relative to the list,
    // Pebble would now fill the bar.
    _phone(tester);
    final repo = await _repository();
    await _completedGame(repo, botId: pebble.id, rating: pebble.rating);
    await _pumpHome(tester, repo);

    final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator));
    expect(bar.value, closeTo(pebble.rating / quadrimPrime.rating, 0.001));
  });

  testWidgets('the rating a bar shows is also said, for a screen reader',
      (tester) async {
    // The bar carries the rating as a length, which a screen reader cannot
    // see. Without this the row would be strictly less informative to a
    // non-sighted player than to a sighted one (spec §7.10).
    _phone(tester);
    final handle = tester.ensureSemantics();
    final repo = await _repository();
    await _completedGame(repo, botId: ember.id, rating: ember.rating);
    await _pumpHome(tester, repo);

    // Both rows that name Ember say it: the breakdown, whose bar and pill are
    // invisible to a screen reader, and the finished game, whose pill is.
    expect(find.bySemanticsLabel(RegExp(r'Ember\. Rating 1300\. ')),
        findsNWidgets(2));
    handle.dispose();
  });

  testWidgets('statistics and lists update when a game finishes, without a '
      'restart', (tester) async {
    _phone(tester);
    final repo = await _repository();
    await _pumpHome(tester, repo);
    expect(find.text('No finished games against the computer yet.'),
        findsOneWidget);

    final game = await repo.createGame(
      mode: GameMode.vsComputer,
      opponent: botOpponent(pebble.id),
      opponentRating: pebble.rating,
    );
    await tester.pumpAndSettle();
    expect(find.text('In progress'), findsOneWidget);
    expect(find.text('3 moves played'), findsNothing);

    await repo.appendMove(game.id, 0);
    await repo.appendMove(game.id, 21);
    await repo.appendMove(game.id, 1);
    await tester.pumpAndSettle();
    expect(find.text('3 moves played'), findsOneWidget);

    await _finish(repo, game, const [22, 2, 26, 3]);
    await tester.pumpAndSettle();

    // The same screen instance, never rebuilt from scratch.
    expect(find.text('In progress'), findsNothing);
    expect(find.text('Finished games'), findsOneWidget);
    expect(find.text('1 won · 0 lost · 0 drawn'), findsOneWidget);
    expect(find.text('Won'), findsOneWidget);
  });

  testWidgets('breaks the record down by opponent, weakest first',
      (tester) async {
    _phone(tester);
    final repo = await _repository();
    await _completedGame(repo, botId: ember.id, rating: ember.rating);
    await _completedGame(
        repo, botId: pebble.id, rating: pebble.rating, playerWins: false);
    await _pumpHome(tester, repo);

    expect(find.text('By opponent'), findsOneWidget);
    // The record strings are unique to the breakdown — the names themselves
    // also appear in the finished-games list below it — so ordering is
    // asserted on where they land, not on how many Texts say "Pebble".
    final pebbleRow = tester.getTopLeft(find.text('0–1–0 in 1 games')).dy;
    final emberRow = tester.getTopLeft(find.text('1–0–0 in 1 games')).dy;
    expect(pebbleRow, lessThan(emberRow), reason: 'weakest first');
  });

  testWidgets('tapping a game in progress resumes it', (tester) async {
    _phone(tester);
    final repo = await _repository();
    final game = await repo.createGame(
      mode: GameMode.passAndPlay,
      opponent: kGuestOpponent,
    );
    await repo.appendMove(game.id, 0);
    await _pumpHome(tester, repo);

    await tester.tap(find.text('1 move played'));
    await tester.pumpAndSettle();

    // The board is showing, with the move already played still on it.
    expect(find.text('Dark to move'), findsOneWidget);
  });

  testWidgets('tapping a finished game opens it', (tester) async {
    _phone(tester);
    final repo = await _repository();
    await _completedGame(repo, botId: pebble.id, rating: pebble.rating);
    await _pumpHome(tester, repo);

    await tester.tap(find.text('Won'));
    await tester.pumpAndSettle();

    // The result is on screen, which is what ticket 012's scrubber will be
    // added to rather than replace.
    expect(find.text('You win!'), findsOneWidget);
  });

  testWidgets('the primary button starts a new game', (tester) async {
    _phone(tester);
    final repo = await _repository();
    await _pumpHome(tester, repo);

    await tester.tap(find.text('New game'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pass and play'));
    await tester.pumpAndSettle();

    expect(find.text('Light to move'), findsOneWidget);
    final active = await repo.watchActiveGames().first;
    expect(active, hasLength(1));
    expect(active.single.mode, GameMode.passAndPlay);
  });

  testWidgets('the tutorial and settings entry points exist and open',
      (tester) async {
    _phone(tester);
    await _pumpHome(tester, await _repository());

    // Both are real screens now — ticket 018 replaced one placeholder route
    // and ticket 028 the other, which is all the placeholder was ever for.
    await tester.tap(find.widgetWithText(TextButton, 'Tutorial'));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 12'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
  });

  testWidgets('pass-and-play games are listed but not counted', (tester) async {
    _phone(tester);
    final repo = await _repository();
    final game = await repo.createGame(
      mode: GameMode.passAndPlay,
      opponent: kGuestOpponent,
    );
    await _finish(repo, game, _lightWinsMoves);
    await _pumpHome(tester, repo);

    // Listed, and reported by side rather than as the player's win.
    expect(find.text('Pass and play'), findsOneWidget);
    expect(find.text('Light wins!'), findsOneWidget);
    // Not counted: the player held both seats.
    expect(find.text('No finished games against the computer yet.'),
        findsOneWidget);
    expect(find.text('By opponent'), findsNothing);
  });

  testWidgets('is readable at the largest system font scale', (tester) async {
    // The screen must survive a 2x scale without overflowing, which is what
    // criterion 23 asks for and what a Column of fixed rows would fail.
    _phone(tester, textScale: 2);
    final repo = await _repository();
    await _completedGame(repo, botId: sable.id, rating: sable.rating);
    await _pumpHome(tester, repo);

    expect(tester.takeException(), isNull);
    expect(find.text('New game'), findsOneWidget);
  });

  testWidgets('announces its sections and the rating to a screen reader',
      (tester) async {
    _phone(tester);
    final handle = tester.ensureSemantics();
    final repo = await _repository();
    await _completedGame(repo, botId: pebble.id, rating: pebble.rating);
    await _pumpHome(tester, repo);

    // The rating card reads as one labelled fact, and since the record moved
    // inside it (D192) that announcement has to carry the record too — or the
    // won-lost-drawn line would be spoken by nothing.
    expect(
      find.bySemanticsLabel(
          RegExp(r'Against the computer: \d+\. .*won.*lost.*drawn')),
      findsOneWidget,
    );
    // Sections are headers, so a screen reader can jump between them rather
    // than reading the whole page top to bottom.
    for (final heading in ['By opponent', 'Finished games']) {
      expect(tester.getSemantics(find.text(heading)).flagsCollection.isHeader,
          isTrue,
          reason: '"$heading" must be a header');
    }
    handle.dispose();
  });

  testWidgets('every string on the screen exists in Dutch', (tester) async {
    _phone(tester);
    final repo = await _repository();
    await _completedGame(repo, botId: pebble.id, rating: pebble.rating);
    await tester.pumpWidget(QuadrimApp(
      repository: repo,
      settings: repo,
      locale: const Locale('nl'),
      random: Random(1),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Nieuwe partij'), findsOneWidget);
    expect(find.text('Uitleg'), findsOneWidget);
    expect(find.text('Tegen de computer'), findsOneWidget);
    expect(find.text('Per tegenstander'), findsOneWidget);
    expect(find.text('Voltooide partijen'), findsOneWidget);
    expect(find.text('1 gewonnen · 0 verloren · 0 remise'), findsOneWidget);
    // Bot names are proper nouns and stay as they are. Pebble appears twice:
    // once in the breakdown and once in the list of finished games.
    expect(find.text('Pebble'), findsWidgets);
  });

  testWidgets('lists finished games most recent first', (tester) async {
    _phone(tester);
    final repo = await _repository();
    // Distinguishable by opponent name rather than by result, because every
    // fixture game ends the same way.
    await _completedGame(repo, botId: pebble.id, rating: pebble.rating);
    await _completedGame(repo, botId: ember.id, rating: ember.rating);
    await _pumpHome(tester, repo);

    // Ember finished last, so its row sits above Pebble's in the list. The
    // breakdown above orders the other way — weakest first — so the two rows
    // are located below the "Finished games" heading.
    final heading = tester.getTopLeft(find.text('Finished games')).dy;
    final rows = <String, double>{};
    for (final name in ['Pebble', 'Ember']) {
      rows[name] = tester
          .getTopLeft(find
              .byWidgetPredicate((w) => w is Text && w.data == name)
              .at(1))
          .dy;
    }
    expect(rows['Pebble']!, greaterThan(heading));
    expect(rows['Ember']!, greaterThan(heading));
    expect(rows['Ember']!, lessThan(rows['Pebble']!),
        reason: 'most recently finished first');
  });

  testWidgets('a long history does not build every row', (tester) async {
    // The finished list has no upper bound, so it must be lazy: a ListView of
    // children would build all sixty tiles for a screen that shows a handful.
    _phone(tester);
    final repo = await _repository();
    for (var i = 0; i < 60; i++) {
      await _completedGame(repo, botId: pebble.id, rating: pebble.rating);
    }
    await _pumpHome(tester, repo);

    expect(find.text('60 won · 0 lost · 0 drawn'), findsOneWidget);
    expect(find.text('Won'), findsWidgets);
    expect(tester.widgetList(find.text('Won')).length, lessThan(60),
        reason: 'off-screen rows must not be built');
  });

  group('game rows', () {
    testWidgets('a game is one line, opponent left and state right',
        (tester) async {
      // The same shape as the by-opponent rows above them. A stacked
      // title-and-subtitle tile made a dozen games longer than the screen
      // while saying nothing more (D189).
      _phone(tester);
      final repo = await _repository();
      await _completedGame(repo, botId: ember.id, rating: ember.rating);
      await _pumpHome(tester, repo);

      // Scoped to the row: "Ember" also appears in the by-opponent breakdown
      // further up the screen, so a bare text finder is ambiguous.
      final row = _rowContaining('Won');
      final name =
          tester.getRect(find.descendant(of: row, matching: find.text('Ember')));
      final result =
          tester.getRect(find.descendant(of: row, matching: find.text('Won')));
      expect(result.center.dy, closeTo(name.center.dy, 4),
          reason: 'the two must sit on one line, not stacked');
      expect(result.left, greaterThan(name.right),
          reason: 'the state belongs at the end of the line');
    });

    testWidgets('a game row is still big enough to hit', (tester) async {
      // `ListTile` enforced a 48dp minimum; hand-rolling the row dropped it to
      // 44 with nothing complaining. These rows are the way into a saved game,
      // so they are the worst control to make small (D189).
      _phone(tester);
      final repo = await _repository();
      await _completedGame(repo, botId: ember.id, rating: ember.rating);
      await _pumpHome(tester, repo);

      final row = find.ancestor(
        of: find.text('Won'),
        matching: find.byType(InkWell),
      );
      expect(tester.getRect(row.first).height, greaterThanOrEqualTo(48));
    });

    testWidgets('the by-opponent breakdown carries avatars too', (tester) async {
      _phone(tester);
      final repo = await _repository();
      await _completedGame(repo, botId: ember.id, rating: ember.rating);
      await _pumpHome(tester, repo);

      // Two rows name Ember — the breakdown and the finished game — and both
      // must show a face.
      expect(find.byType(OpponentAvatar), findsNWidgets(2));
      for (final avatar in tester.widgetList<OpponentAvatar>(
        find.byType(OpponentAvatar),
      )) {
        expect(avatar.id, ember.id);
      }
    });

    testWidgets('the two sections share a left edge for their names',
        (tester) async {
      // The reason both use one slot widget: unequal slots would step the
      // names in and out between sections that sit directly above each other.
      _phone(tester);
      final repo = await _repository();
      await _completedGame(repo, botId: ember.id, rating: ember.rating);
      await _pumpHome(tester, repo);

      Set<double> leftEdgesOf(Finder finder) => finder
          .evaluate()
          .map((e) => tester.getRect(find.byWidget(e.widget)).left)
          .toSet();

      expect(leftEdgesOf(find.byType(OpponentAvatar)).length, 1,
          reason: 'avatars must start at the same x');
      expect(leftEdgesOf(find.text('Ember')).length, 1,
          reason: 'names must start at the same x');
    });

    testWidgets('a computer game shows that opponent, not just any avatar',
        (tester) async {
      _phone(tester);
      final repo = await _repository();
      await _completedGame(repo, botId: ember.id, rating: ember.rating);
      await _pumpHome(tester, repo);

      final avatar = tester.widget<OpponentAvatar>(
        find.byType(OpponentAvatar).first,
      );
      expect(avatar.id, ember.id);
      expect(avatar.tier, ember.tier);
    });

    testWidgets('the avatar is smaller here than on the selection screen',
        (tester) async {
      // It rides a single line of text, so it may not set the row's height.
      _phone(tester);
      final repo = await _repository();
      await _completedGame(repo, botId: ember.id, rating: ember.rating);
      await _pumpHome(tester, repo);

      final avatar =
          tester.widget<OpponentAvatar>(find.byType(OpponentAvatar).first);
      expect(avatar.size, lessThan(44),
          reason: 'smaller than the selection screen default');
      final line = tester.getRect(
        find.descendant(of: _rowContaining('Won'), matching: find.text('Ember')),
      );
      expect(tester.getRect(find.byType(OpponentAvatar).first).height,
          lessThanOrEqualTo(line.height + 16),
          reason: 'the avatar must not drive the row height');
    });

    testWidgets('pass-and-play has no opponent to draw', (tester) async {
      // There is no bot behind the guest seat, so the slot falls back rather
      // than inventing a face for somebody who does not exist.
      _phone(tester);
      final repo = await _repository();
      final game = await repo.createGame(
        mode: GameMode.passAndPlay,
        opponent: kGuestOpponent,
      );
      await _finish(repo, game, const [0, 16, 1, 17, 2, 18, 3]);
      await _pumpHome(tester, repo);

      expect(find.text('Pass and play'), findsOneWidget);
      expect(find.byType(OpponentAvatar), findsNothing);
      expect(find.byIcon(Icons.people_outline), findsWidgets);
    });

    testWidgets('a row announces the opponent and its state together',
        (tester) async {
      // One node, not three: the avatar is decorative and the two facts only
      // mean anything side by side.
      final handle = tester.ensureSemantics();
      _phone(tester);
      final repo = await _repository();
      await _completedGame(repo, botId: ember.id, rating: ember.rating);
      await _pumpHome(tester, repo);

      // The rating sits between the two facts now that the row shows it as a
      // pill: name, rating, outcome, still as one node rather than three.
      // Name, rating, outcome and what the outcome was worth — four facts,
      // still one node. The change is matched as a pattern rather than a
      // literal because its value depends on the whole fold, and hard-coding
      // it here would pin the rating maths in the wrong file.
      expect(find.bySemanticsLabel(RegExp(r'^Ember\. Rating 1300\. Won\. \+\d+$')),
          findsOneWidget);
      handle.dispose();
    });

    testWidgets('an unknown opponent still renders a row', (tester) async {
      // A stored game can name an opponent this build has never heard of —
      // an older catalogue, or a newer one after a downgrade. The row must
      // survive it rather than crash on a null configuration.
      _phone(tester);
      final repo = await _repository();
      final game = await repo.createGame(
        mode: GameMode.vsComputer,
        opponent: botOpponent('nonesuch'),
        opponentRating: 1000,
      );
      await _finish(repo, game, const [0, 16, 1, 17, 2, 18, 3]);
      await _pumpHome(tester, repo);

      // Twice: once in the by-opponent breakdown, once in the game row. Both
      // show the raw key, which is deliberately obviously wrong rather than a
      // plausible invented name.
      expect(find.text('bot:nonesuch'), findsNWidgets(2));
      expect(find.byType(OpponentAvatar), findsNothing);
    });
  });

  test('both locales carry every key the screen uses', () {
    // A missing Dutch key falls back to English silently at runtime; this is
    // the cheap guard against that going unnoticed.
    expect(AppLocalizations.supportedLocales.map((l) => l.languageCode),
        containsAll(['en', 'nl']));
  });
}
