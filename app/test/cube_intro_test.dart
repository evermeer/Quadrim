import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrim/data/document_store.dart';
import 'package:quadrim/data/documents.dart';
import 'package:quadrim/data/local_game_repository.dart';
import 'package:quadrim/game/board_view.dart';
import 'package:quadrim/l10n/app_localizations.dart';
import 'package:quadrim/main.dart';
import 'package:quadrim_engine/quadrim_engine.dart';
import 'plaques.dart';

/// A board in a box of a fixed size, so two of them can be compared.
///
/// The size is what a phone gives the tutorial's board, not what the screen
/// gives a game: the intro only ever runs there.
Widget _host({Animation<double>? intro, bool cubeEdges = false}) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 340,
            height: 620,
            child: BoardView(
              state: GameState.fromMoves(const [0, 48]),
              enabled: false,
              onCellTap: (_) {},
              intro: intro,
              cubeEdges: cubeEdges,
            ),
          ),
        ),
      ),
    );

/// The top-left corner of one cell, wherever it has been painted.
Offset _cell(WidgetTester tester, int index) =>
    tester.getTopLeft(find.byKey(ValueKey('cell-$index')));

/// Every cell's rectangle, in order — the whole geometry of the board in one
/// value, so two boards can be compared without naming what might differ.
List<Rect> _geometry(WidgetTester tester) =>
    [for (var i = 0; i < 64; i++) tester.getRect(find.byKey(ValueKey('cell-$i')))];

void main() {
  group('the intro parameters', () {
    // The reason the intro interpolates parameters rather than matrices: each
    // one has to arrive at the value the resting board is drawn with, or the
    // last frame snaps and the player has seen two unrelated pictures (D366).
    test('all arrive exactly where the resting board is', () {
      expect(cubeIntroSpread(1), 1);
      expect(cubeIntroAngle(1), 0);
      expect(cubeIntroPerspective(1), 0);
    });

    test('the spread starts shut, holds, and only ever opens', () {
      expect(cubeIntroSpread(0), 0);
      // The hold: the cube has to be seen as a cube before it comes apart.
      expect(cubeIntroSpread(0.4), 0);
      var previous = 0.0;
      for (var i = 0; i <= 100; i++) {
        final s = cubeIntroSpread(i / 100);
        expect(s, inInclusiveRange(0, 1));
        expect(s, greaterThanOrEqualTo(previous));
        previous = s;
      }
    });

    // Past 90 degrees the layers are edge-on and the board is not there. The
    // swing is nowhere near it, and this is what says so.
    test('the swing stays well inside a quarter turn', () {
      for (var i = 0; i <= 100; i++) {
        expect(cubeIntroAngle(i / 100).abs(), lessThan(1.0)); // radians
      }
    });
  });

  group('the board it lands on', () {
    testWidgets('is the one a board without an intro draws', (tester) async {
      await tester.pumpWidget(_host());
      final resting = _geometry(tester);

      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: kCubeIntroDuration,
        value: 1,
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(_host(intro: controller));

      expect(_geometry(tester), resting);
    });

    testWidgets('is reached from a shut cube, not jumped to', (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: kCubeIntroDuration,
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(_host(intro: controller));
      // Cell 0 and cell 48 are the same corner of layer 1 and of layer 4.
      final shut = (_cell(tester, 48) - _cell(tester, 0)).dy;

      controller.value = 1;
      await tester.pump();
      final open = (_cell(tester, 48) - _cell(tester, 0)).dy;

      // Shut is a stack with thickness, not four layers on top of each other.
      expect(shut, greaterThan(0));
      // And it is a small fraction of the laid-out board, or nothing has moved.
      expect(shut, lessThan(open / 3));
    });
  });

  testWidgets('the corner posts are drawn only when asked for', (tester) async {
    bool hasPosts() => find
        .byWidgetPredicate((w) =>
            w is CustomPaint &&
            w.painter.runtimeType.toString().contains('CubeEdge'))
        .evaluate()
        .isNotEmpty;

    await tester.pumpWidget(_host());
    expect(hasPosts(), isFalse);

    await tester.pumpWidget(_host(cubeEdges: true));
    expect(hasPosts(), isTrue);
  });

  group('in the tutorial', () {
    Future<LocalGameRepository> repository() async {
      final repository = await LocalGameRepository.open(MemoryDocumentStore());
      addTearDown(repository.dispose);
      // Already offered, or the first-launch dialog is over the main screen and
      // the button underneath it cannot be pressed.
      await repository.saveSettings(const SettingsDocument(tutorialOffered: true));
      return repository;
    }

    Future<void> openTutorial(
      WidgetTester tester, {
      bool reduceMotion = false,
    }) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);
      final repo = await repository();
      await tester.pumpWidget(MediaQuery(
        // From the view, not a bare MediaQueryData: that one has no size, and
        // an app laid out in a zero-sized window has no buttons to tap.
        data: MediaQueryData.fromView(tester.view)
            .copyWith(disableAnimations: reduceMotion),
        child: QuadrimApp(
            repository: repo, settings: repo, unlocks: repo, locale: null),
      ));
      await tester.pumpAndSettle();
      await tester.tap(plaqueLabelled('Tutorial'));
      await tester.pumpAndSettle();
    }

    // Two seconds of animation on entry is two seconds a `pumpAndSettle` has
    // to sit through, which is fine, and two seconds a player has to sit
    // through, which is why it is bounded and why this checks it ends.
    testWidgets('the first step settles into the resting board',
        (tester) async {
      await openTutorial(tester);
      final settled = _geometry(tester);
      // Nothing left running: the intro is over and the board is static.
      await tester.pump(const Duration(seconds: 5));
      expect(_geometry(tester), settled);
    });

    testWidgets('reduce motion gets the resting board with no intro at all',
        (tester) async {
      await openTutorial(tester, reduceMotion: true);
      final immediate = _geometry(tester);
      await tester.pump(kCubeIntroDuration);
      // Unmoved, because it was never anywhere else.
      expect(_geometry(tester), immediate);
    });
  });
}
