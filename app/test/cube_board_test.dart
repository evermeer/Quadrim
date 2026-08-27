import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrim/data/document_store.dart';
import 'package:quadrim/data/documents.dart';
import 'package:quadrim/data/local_game_repository.dart';
import 'package:quadrim/game/board_style_toggle.dart';
import 'package:quadrim/game/board_view.dart';
import 'package:quadrim/game/cube_board_view.dart';
import 'package:quadrim/l10n/app_localizations.dart';
import 'package:quadrim/main.dart';
import 'package:quadrim_engine/quadrim_engine.dart';
import 'plaques.dart';

/// The board area a phone gives the cube: the screen minus the app bar, the
/// turn banner and its padding.
const _area = Size(344, 560);

/// The rectangle the cube actually occupies on screen.
///
/// Cell centres grown by the half-diagonal of their own box, which is what the
/// silhouette of a projected cube reaches. Approximate by a hair and always in
/// the safe direction — it can only ever claim the cube is bigger than it is.
Rect _drawn(CubeProjection p) {
  var r = Rect.fromCenter(
    center: p.centreOf(const Cell(0)),
    width: p.edgeOf(const Cell(0)) * 1.74,
    height: p.edgeOf(const Cell(0)) * 1.74,
  );
  for (var i = 1; i < 64; i++) {
    final cell = Cell(i);
    final e = p.edgeOf(cell) * 1.74;
    r = r.expandToInclude(
      Rect.fromCenter(center: p.centreOf(cell), width: e, height: e),
    );
  }
  return r;
}

CubeProjection _resting({double zoom = 1}) => CubeProjection(
  size: _area,
  yaw: kCubeRestYaw,
  pitch: kCubeRestPitch,
  zoom: zoom,
);

Widget _host({
  required void Function(Cell) onCellTap,
  GameState? state,
  bool enabled = true,
}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: _area.width,
        height: _area.height,
        child: CubeBoardView(
          state: state ?? GameState.fromMoves(const []),
          enabled: enabled,
          onCellTap: onCellTap,
        ),
      ),
    ),
  ),
);

void main() {
  group('the projection', () {
    // The load-bearing property of a 3D board. Every other bug in this file
    // looks wrong; this one plays a legal move in a cell the player never saw,
    // and a game record cannot tell you it happened afterwards.
    //
    // Not every cell hits itself, and that is correct: a cell hidden behind
    // another cannot be tapped until the cube is turned. What must never
    // happen is a tap reaching *past* what is in front of it.
    test('never lets a farther cell take a tap from a nearer one', () {
      final p = _resting();
      for (var i = 0; i < 64; i++) {
        final cell = Cell(i);
        final hit = p.cellAt(p.centreOf(cell));
        expect(hit, isNotNull, reason: 'cell $i is under nothing at all');
        if (hit!.index == i) continue;
        expect(
          p.depthOf(hit),
          lessThan(p.depthOf(cell)),
          reason: 'cell $i was taken by ${hit.index}, which is behind it',
        );
      }
    });

    // A regression guard on the two numbers that decide it — the resting
    // angle and the hit radius, both of which were picked by measuring this.
    // Nine cells sit in the middle of the cube and need a turn to reach; if
    // this drops, one of those two constants was changed on taste.
    test('leaves 55 of the 64 cells tappable without turning the cube', () {
      final p = _resting();
      final reachable = [
        for (var i = 0; i < 64; i++)
          if (p.cellAt(p.centreOf(Cell(i)))?.index == i) i,
      ];
      expect(reachable, hasLength(greaterThanOrEqualTo(55)));
    });

    // The promise the rotation gesture has to keep. A cell that no rotation
    // reaches is a cell that cannot be played, on a board where the rules say
    // it can — the game would be unwinnable along four of its 76 lines.
    test('reaches every one of the 64 cells from some angle', () {
      final unreachable = <int>[];
      for (var i = 0; i < 64; i++) {
        final reached = [
          for (var yaw = 0.0; yaw < 6.2; yaw += 0.2)
            for (var pitch = -1.2; pitch <= 1.2; pitch += 0.2)
              CubeProjection(size: _area, yaw: yaw, pitch: pitch, zoom: 1),
        ].any((p) => p.cellAt(p.centreOf(Cell(i)))?.index == i);
        if (!reached) unreachable.add(i);
      }
      expect(unreachable, isEmpty);
    });

    // Zoomed all the way out, the whole cube is visible however it is turned.
    // That is the promise; at zoom 1 and above it is allowed to reach the
    // edges, which is what zooming in means.
    //
    // The first version scaled by the cube's face-on width and so drew it a
    // third too large: at rest it overflowed on both sides and ran off the
    // bottom, and the clip turned it into a lattice of tall columns. A test
    // that checked only cell centres, and only at one angle, let that through.
    test('fits the area it is given at every rotation, zoomed out', () {
      for (var yaw = 0.0; yaw < 6.2; yaw += 0.3) {
        for (var pitch = -1.3; pitch <= 1.3; pitch += 0.3) {
          final box = _drawn(
            CubeProjection(
              size: _area,
              yaw: yaw,
              pitch: pitch,
              zoom: kCubeMinZoom,
            ),
          );
          expect(
            box.left >= 0 &&
                box.top >= 0 &&
                box.right <= _area.width &&
                box.bottom <= _area.height,
            isTrue,
            reason:
                'the cube sticks out at yaw ${yaw.toStringAsFixed(1)} '
                'pitch ${pitch.toStringAsFixed(1)}: $box in $_area',
          );
        }
      }
    });

    // Measured on what is drawn, not on the scale factor that produces it —
    // the first version of this test asserted `unit * kCubeSpan / width ==
    // zoom`, which is the definition of `unit` and therefore true whatever the
    // cube looked like.
    test('zooms out to fit and in past the edges of the screen', () {
      // At the resting angle the two ends are the numbers the player was
      // given: four fifths of the width, and half again as wide as it.
      final out = _drawn(_resting(zoom: kCubeMinZoom)).width / _area.width;
      expect(out, closeTo(kCubeMinZoom, 0.03));

      final into = _drawn(_resting(zoom: kCubeMaxZoom)).width / _area.width;
      expect(into, closeTo(kCubeMaxZoom, 0.05));
    });

    test('separates the four layers vertically, layer 1 on top', () {
      final p = _resting();
      // Same row and column, all four layers: they must come down the screen
      // in order, which is the picture the layered board's captions draw.
      final ys = [for (var z = 0; z < 4; z++) p.centreOf(Cell.xyz(1, 1, z)).dy];
      expect(ys, orderedEquals(([...ys]..sort())));
      expect(ys.first, lessThan(ys.last));
    });
  });

  group('the cube board', () {
    testWidgets('plays the cell whose ball was tapped', (tester) async {
      Cell? played;
      await tester.pumpWidget(_host(onCellTap: (c) => played = c));

      // A cell well inside the cube rather than a corner, so the test would
      // fail on an axis mix-up rather than accidentally passing on symmetry.
      const target = 25; // x 1, y 2, z 1
      final origin = tester.getTopLeft(find.byType(CubeBoardView));
      await tester.tapAt(origin + _resting().centreOf(const Cell(target)));
      await tester.pump();

      expect(played?.index, target);
    });

    testWidgets('ignores a tap on a cell that is already played', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          state: GameState.fromMoves(const [25]),
          onCellTap: (_) => taps++,
        ),
      );
      final origin = tester.getTopLeft(find.byType(CubeBoardView));
      await tester.tapAt(origin + _resting().centreOf(const Cell(25)));
      await tester.pump();

      expect(taps, 0);
    });

    testWidgets('ignores every tap while it is not the human\'s turn', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(enabled: false, onCellTap: (_) => taps++),
      );
      final origin = tester.getTopLeft(find.byType(CubeBoardView));
      await tester.tapAt(origin + _resting().centreOf(const Cell(25)));
      await tester.pump();

      expect(taps, 0);
    });

    // Observed through the hit test rather than through the private angle,
    // and without restating the drag-to-radians constant here — a test that
    // recomputed the sensitivity would only ever agree with itself.
    testWidgets('turns on a drag, and its cells turn with it', (tester) async {
      Cell? played;
      await tester.pumpWidget(_host(onCellTap: (c) => played = c));
      final origin = tester.getTopLeft(find.byType(CubeBoardView));
      // Cell 25 rather than a corner: it is reachable at the resting angle,
      // and far enough inside the cube that an axis mix-up would move it.
      final restingCentre = _resting().centreOf(const Cell(25));

      await tester.tapAt(origin + restingCentre);
      await tester.pump();
      expect(played?.index, 25, reason: 'before the drag');

      played = null;
      // Eighty logical pixels across a 344 board is about forty degrees of
      // yaw — far more than the half cell the hit test allows.
      await tester.drag(find.byType(CubeBoardView), const Offset(80, 0));
      await tester.pump();
      await tester.tapAt(origin + restingCentre);
      await tester.pump();

      expect(played?.index, isNot(25), reason: 'the cube did not turn');
    });
  });

  group('the preference', () {
    test('defaults to the layered board', () {
      expect(const SettingsDocument().boardStyle, kBoardStyleLayers);
    });

    test('survives a round trip through json', () {
      final stored = const SettingsDocument()
          .copyWith(boardStyle: kBoardStyleCube)
          .toJson();
      expect(SettingsDocument.fromJson(stored)?.boardStyle, kBoardStyleCube);
    });

    // Written by a build that had never heard of this preference, and by one
    // that knows a style this build does not. Both must land on a board that
    // draws, not on an empty screen.
    test('falls back to the layered board on anything unrecognised', () {
      for (final value in [null, '', 'hologram', 42]) {
        final json = {'schemaVersion': kSchemaVersion, 'boardStyle': value};
        expect(
          SettingsDocument.fromJson(json)?.boardStyle,
          kBoardStyleLayers,
          reason: 'stored value: $value',
        );
      }
    });
  });

  group('the display toggle', () {
    /// A pass-and-play game on screen, on a phone, with [style] already
    /// stored. The game screen is the only place the toggle exists.
    Future<LocalGameRepository> open(
      WidgetTester tester, {
      String style = kBoardStyleLayers,
      Size size = const Size(360, 844),
    }) async {
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final repository = await LocalGameRepository.open(MemoryDocumentStore());
      addTearDown(repository.dispose);
      await repository.saveSettings(
        SettingsDocument(tutorialOffered: true, boardStyle: style),
      );
      await tester.pumpWidget(
        QuadrimApp(
          repository: repository,
          settings: repository,
          unlocks: repository,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(plaqueLabelled('New game'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pass and play'));
      await tester.pumpAndSettle();
      return repository;
    }

    testWidgets('opens on the layered board and switches to the cube', (
      tester,
    ) async {
      final repository = await open(tester);
      expect(find.byType(BoardView), findsOneWidget);
      expect(find.byType(CubeBoardView), findsNothing);

      await tester.tap(find.byTooltip('Cube board'));
      await tester.pumpAndSettle();

      expect(find.byType(CubeBoardView), findsOneWidget);
      expect(find.byType(BoardView), findsNothing);
      // The point of the toggle: the next game opens the same way.
      expect((await repository.loadSettings()).boardStyle, kBoardStyleCube);
    });

    testWidgets('opens on the cube when that is what was stored', (
      tester,
    ) async {
      await open(tester, style: kBoardStyleCube);
      expect(find.byType(CubeBoardView), findsOneWidget);

      await tester.tap(find.byTooltip('Layered board'));
      await tester.pumpAndSettle();
      expect(find.byType(BoardView), findsOneWidget);
    });

    // Reviewing is a reading task, and the scrubber needs a board that shows
    // every cell and does not move (D369). The toggle goes with it, rather
    // than staying on screen doing nothing.
    testWidgets('falls back to the layered board while reviewing', (
      tester,
    ) async {
      await open(tester, style: kBoardStyleCube);
      // One move, so there is a history to review.
      await tester.tapAt(
        tester.getTopLeft(find.byType(CubeBoardView)) +
            CubeProjection(
              size: tester.getSize(find.byType(CubeBoardView)),
              yaw: kCubeRestYaw,
              pitch: kCubeRestPitch,
              zoom: 1,
            ).centreOf(const Cell(25)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      expect(find.byType(BoardView), findsOneWidget);
      expect(find.byType(CubeBoardView), findsNothing);
      expect(find.byType(BoardStyleToggle), findsNothing);
    });

    // The app bar it was put in is the tightest row on the screen: the
    // opponent's name, this pair, the review button and Resign all share it.
    testWidgets('fits the app bar at the narrowest supported width', (
      tester,
    ) async {
      await open(tester, size: const Size(360, 780));
      expect(tester.takeException(), isNull);
      final toggle = tester.getRect(find.byType(BoardStyleToggle));
      expect(toggle.width, lessThan(100));
      expect(toggle.right, lessThanOrEqualTo(360));
    });
  });
}
