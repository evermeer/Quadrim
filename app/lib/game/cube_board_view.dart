import 'dart:math' as math;

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:flutter/material.dart';
import 'package:quadrim_engine/quadrim_engine.dart';

import '../l10n/app_localizations.dart';
import '../theme.dart';
import 'board_view.dart';

/// How wide the cube may be drawn, as a fraction of the board area's width.
///
/// The board area is the screen minus the app bar, the turn banner and 8dp of
/// padding either side, so "screen width" is approximate by about 16dp — the
/// number a player can act on is the one that grows and stops (D369).
///
/// The fraction is of [kCubeSpan], the width of the cube at the rotation that
/// makes it widest. So 1.0 is "fits however it is turned", 1.5 is half again
/// as wide and deliberately clipped at the edges, and 0.8 is comfortably
/// inside. Fitting the *current* silhouette instead would honour the number
/// more literally at the cost of the cube changing size as it turned, and a
/// board that resizes while you look at it is worse than one that is 15%
/// smaller than advertised at some angles.
const double kCubeMinZoom = 0.8;
const double kCubeMaxZoom = 1.5;

/// The gap between neighbouring glass cells, as a fraction of a cell edge.
///
/// A fifth of a cell, which is what makes the object read as sixty-four
/// separate cells rather than as one block with a grid drawn on it. It is also
/// what lets you see into the middle: with no gap the outer shell hides the
/// eight interior cells at every angle, and four of the 76 lines run entirely
/// through cells you could never see.
const double _gap = 0.2;

/// Centre-to-centre distance between neighbouring cells, in cell edges.
const double _pitch = 1 + _gap;

/// How wide the cube can ever be drawn, in cell edges.
///
/// **Not the cube's own width, which is 4.6.** A turned cube is wider on
/// screen than a square-on one, and perspective widens it again — the near
/// corner is drawn larger than the far one. Swept over every rotation, the
/// widest a corner ever lands from the centre is 4.10 cell edges, so the
/// silhouette can reach 8.2 across.
///
/// Scaling by the 4.6 was the first version and it drew the cube a third too
/// large: at rest it overflowed the board area on both sides and ran off the
/// bottom, and because the overflow is clipped it read as a lattice of tall
/// columns rather than as an object. Deriving the figure analytically was the
/// second, and it missed the perspective term and still clipped at full tilt.
/// This one is measured.
///
/// **7.28 is the span at the resting angle**, and scaling by that is what
/// makes the zoom numbers mean what they say: at zoom 1 the cube is exactly as
/// wide as the board area, at [kCubeMinZoom] four fifths of it, at
/// [kCubeMaxZoom] half again as wide and clipped. Scaling by the 8.2 instead
/// guarantees no clipping at any rotation and any zoom, at the cost of drawing
/// the cube at 71% when the player asked for 80 — a promise kept in the code
/// and broken on the screen.
///
/// Turning the cube can therefore make it up to 13% wider than at rest. That
/// still fits when zoomed out, which is the promise that matters: **at
/// [kCubeMinZoom] the whole cube is visible however it is turned** (90% of the
/// width at worst), and `cube_board_test.dart` checks exactly that.
const double kCubeSpan = 7.28;

/// How far the eye sits from the cube's centre, in cell edges.
///
/// Eleven. The cube's half body-diagonal is `kCubeSpan * sqrt(3) / 2`, about 3.98,
/// so the nearest possible vertex sits 7.0 from the eye and the farthest 15.0.
/// **The divisor in [CubeProjection._view] can therefore never approach zero**,
/// which is the one way a hand-rolled perspective divide fails catastrophically
/// rather than merely looking wrong.
///
/// Nearer than this and the near face swells enough to hide the layer behind
/// it; further and the perspective flattens until the cube reads as a diagram
/// rather than as an object you are looking at.
const double _camera = 11;

/// Ball diameters as a fraction of a cell edge.
///
/// An empty cell is a small marker inside a large glass box; a played one is a
/// ball that fills half of it. The step between them is what makes occupancy
/// readable from across the cube at any rotation — at the specified 20% for
/// both, a played piece was a dot 15 logical pixels wide and counting a line
/// of four meant leaning in (D369).
const double _emptyBall = 0.20;
const double _playedBall = 0.50;

/// How far the cube may be tilted, in radians — about 75 degrees.
///
/// Short of a right angle deliberately. Straight down the vertical axis all
/// four layers project onto each other exactly, so sixteen cells hide sixty-
/// four; stopping short of it means there is no rotation from which the cube
/// is unreadable.
const double _maxPitch = 1.3;

/// How much of a cell counts as a tap on it, as a fraction of its edge.
///
/// **Chosen by measurement, not by taste** — it is the one number that trades
/// how easy a cell is to hit against how many cells can be hit at all. A near
/// cell's disc covers whatever is behind it, so a generous radius quietly
/// makes the middle of the cube unreachable: at half a cell only 39 of the 64
/// could be tapped without turning the board first, and at 0.4 only 48.
///
/// Three tenths reaches 55 and leaves the *farthest* cell a 35dp target at the
/// resting angle, which clears the audited 32dp floor (`kMinCellSize`) that
/// the layered board is held to. Every tenth below this buys three or four
/// more cells and spends the floor, which is not a trade this project makes.
///
/// The nine it does not reach are the middle of the cube, and they are what
/// the rotation gesture is for (D369).
const double _hitRadius = 0.3;

/// The cube's opening angle: turned enough to show three faces, tilted enough
/// to show the top. A player must not have to discover the rotation gesture
/// before the object reads as three-dimensional.
///
/// Thirty-five degrees and twenty. Also measured rather than eyeballed: a
/// sweep of both angles against [_hitRadius] puts the reachable count between
/// 46 and 55, and this is one of the two pairs at the top of it. **Forty-five
/// degrees of yaw is the trap** — the classic isometric view is where the
/// horizontal and depth axes project onto the same screen direction, so cells
/// one step apart in x and one step apart in y land on each other and the cube
/// reads as a flat lattice.
const double kCubeRestYaw = 0.61;
const double kCubeRestPitch = 0.35;

/// One rotatable 4x4x4 cube of glass cells, each holding a ball (D369).
///
/// The alternative to [BoardView], not a replacement for it: the same game,
/// the same move list, the same flash and the same winning line, drawn as one
/// object instead of as four layers. Which one a player sees is a preference
/// (`SettingsDocument.boardStyle`), and switching mid-game is free because
/// neither board holds any state the other would need.
///
/// **This is a canvas, not sixty-four widgets**, which is the one real
/// difference and the reason it is [ExcludeSemantics]. A rotating projection
/// has no stable per-cell hit rectangle for touch exploration to land on, so
/// the layered board stays the accessible one and this says so out loud rather
/// than presenting sixty-four unreachable buttons.
class CubeBoardView extends StatefulWidget {
  const CubeBoardView({
    super.key,
    required this.state,
    required this.enabled,
    required this.onCellTap,
    this.highlight = const [],
    this.flash = const [],
  });

  final GameState state;

  /// Whether taps place a piece right now. Rotation and zoom do not ask: a
  /// player waiting for the computer must still be able to look round the
  /// position they are waiting on.
  final bool enabled;

  final void Function(Cell cell) onCellTap;

  /// Cell indices to emphasise — the winning line at the end of a game.
  final List<int> highlight;

  /// Cell indices whose balls flash green, exactly as on the layered board.
  final List<int> flash;

  @override
  State<CubeBoardView> createState() => _CubeBoardViewState();
}

class _CubeBoardViewState extends State<CubeBoardView>
    with SingleTickerProviderStateMixin, BoardFlash<CubeBoardView> {
  @override
  List<int> get flashing => widget.flash;

  @override
  GameState get flashPosition => widget.state;

  double _yaw = kCubeRestYaw;
  double _pitch = kCubeRestPitch;
  double _zoom = 1;

  /// The zoom the current pinch started from. A pinch reports cumulative
  /// scale, so applying it to the live value compounds it.
  double _zoomAtGestureStart = 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    syncFlash();
  }

  @override
  void didUpdateWidget(CubeBoardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncFlash();
  }

  void _onScaleStart(ScaleStartDetails details) {
    _zoomAtGestureStart = _zoom;
  }

  void _onScaleUpdate(ScaleUpdateDetails details, Size size) {
    setState(() {
      if (details.pointerCount >= 2) {
        // Zoom only while two fingers are down. A pinch also reports a focal
        // point that wanders as the fingers move, and feeding that to the
        // rotation makes the cube lurch every time the player zooms.
        _zoom = (_zoomAtGestureStart * details.scale).clamp(
          kCubeMinZoom,
          kCubeMaxZoom,
        );
        return;
      }
      // A drag across the full width turns the cube half a revolution, which
      // is the trackball convention: the face you push moves with your finger.
      _yaw -= details.focalPointDelta.dx / size.width * math.pi;
      _pitch = (_pitch + details.focalPointDelta.dy / size.width * math.pi)
          .clamp(-_maxPitch, _maxPitch);
    });
  }

  /// How many fingers are on the board, and where a single one went down.
  ///
  /// Null once a press stops being a candidate for a tap — because a second
  /// finger joined it, or because it was cancelled.
  int _pointers = 0;
  Offset? _pressedAt;

  void _onPointerDown(PointerDownEvent event) {
    _pointers++;
    // A second finger means a pinch. Whatever the first one was doing, it is
    // not a tap any more.
    _pressedAt = _pointers == 1 ? event.localPosition : null;
  }

  void _onPointerUp(PointerUpEvent event, Size size) {
    _pointers = math.max(0, _pointers - 1);
    final from = _pressedAt;
    _pressedAt = null;
    if (from == null) return;
    // `kTouchSlop` rather than a number of this file's own: it is what the
    // framework calls a tap everywhere else in the app, so a press that would
    // have been a tap on the layered board is one here.
    if ((event.localPosition - from).distance > kTouchSlop) return;
    _play(event.localPosition, size);
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _pointers = math.max(0, _pointers - 1);
    _pressedAt = null;
  }

  void _play(Offset at, Size size) {
    if (!widget.enabled) return;
    final cell = CubeProjection(
      size: size,
      yaw: _yaw,
      pitch: _pitch,
      zoom: _zoom,
    ).cellAt(at);
    // Occupied cells are ignored rather than passed over. Playing the empty
    // cell *behind* the ball a player just tapped would be the worst kind of
    // wrong: a legal move, on a board where they never saw the cell.
    if (cell == null || widget.state.owner(cell) != null) return;
    widget.onCellTap(cell);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Semantics(
          label: l10n.cubeBoardSemantics,
          child: ExcludeSemantics(
            // **The tap is a `Listener`, not `onTap` on the detector below**,
            // and that is not a style choice. A `TapGestureRecognizer` in the
            // same arena as a `ScaleGestureRecognizer` starves the pinch: with
            // both on one detector a two-finger zoom delivered exactly one
            // update and then stopped, reaching a scale of 1.017 where the
            // fingers had asked for 1.5. Nesting them, either way round, does
            // the same thing — measured all three ways (D369).
            //
            // A `Listener` never enters the arena, so the scale recogniser
            // keeps the pointers and the press is judged here instead: one
            // finger, moved less than `kTouchSlop`, is a tap.
            child: Listener(
              onPointerDown: _onPointerDown,
              onPointerUp: (e) => _onPointerUp(e, size),
              onPointerCancel: _onPointerCancel,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: _onScaleStart,
                onScaleUpdate: (d) => _onScaleUpdate(d, size),
                // At maximum zoom the cube is wider than the space it is
                // given. That is what zooming in means; clipping is what keeps
                // it off the turn banner above and the result panel below.
                child: ClipRect(
                  child: AnimatedBuilder(
                    animation: flashController,
                    builder: (_, _) => CustomPaint(
                      size: size,
                      painter: _CubePainter(
                        state: widget.state,
                        highlight: widget.highlight.toSet(),
                        flashing: widget.flash.toSet(),
                        elapsed: flashController.value,
                        reduceMotion: MediaQuery.disableAnimationsOf(context),
                        yaw: _yaw,
                        pitch: _pitch,
                        zoom: _zoom,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Where each cell lands on screen this frame, and in what order to draw them.
///
/// Built by both the painter and the hit test from the same three numbers, so
/// what a player taps is by construction what they can see. A second copy of
/// this arithmetic living in the gesture handler is how a 3D board comes to
/// play a different cell from the one under the finger.
class CubeProjection {
  CubeProjection({
    required this.size,
    required double yaw,
    required double pitch,
    this.zoom = 1,
  }) : _cosYaw = math.cos(yaw),
       _sinYaw = math.sin(yaw),
       _cosPitch = math.cos(pitch),
       _sinPitch = math.sin(pitch) {
    unit = size.width * zoom / kCubeSpan;
    _centre = Offset(size.width / 2, size.height / 2);
    _cells = [for (var i = 0; i < 64; i++) _project(Cell(i))]
      // Painter's algorithm: farthest first, so nearer glass is laid over what
      // is behind it. Sixty-four boxes is small enough that a full sort per
      // frame is cheaper than any structure that would avoid one.
      ..sort((a, b) => b.depth.compareTo(a.depth));
  }

  final Size size;
  final double zoom;
  final double _cosYaw;
  final double _sinYaw;
  final double _cosPitch;
  final double _sinPitch;

  /// Logical pixels per cell edge at the cube's centre plane.
  late final double unit;

  late final Offset _centre;

  /// Every cell, farthest from the eye first. Private: the drawing order is
  /// the painter's business, and the two things a caller outside it can want —
  /// where a cell is and what is under a point — are [centreOf] and [cellAt].
  late final List<_Cell3D> _cells;

  /// Where [cell]'s ball is drawn. The same arithmetic [cellAt] inverts, which
  /// is what makes "the ball you tapped is the cell that was played" a property
  /// a test can check rather than a claim (D369).
  Offset centreOf(Cell cell) => _of(cell).centre;

  /// How far [cell] sits beyond the cube's centre plane; larger is farther
  /// from the eye. Exposed alongside [centreOf] so a test can check the rule
  /// [cellAt] is supposed to follow — the frontmost cell wins — rather than
  /// only that it returns something (D369).
  double depthOf(Cell cell) => _of(cell).depth;

  /// [cell]'s edge length in logical pixels at its own depth — how big the
  /// glass box around it is drawn. With [centreOf] this is enough to say
  /// whether the whole cube fits in the space it was given, which is the
  /// check that catches scaling it by the wrong span (D369).
  double edgeOf(Cell cell) => _of(cell).edge;

  _Cell3D _of(Cell cell) =>
      _cells.firstWhere((c) => c.cell.index == cell.index);

  /// The eight corner offsets of a unit cell, in model space.
  static const _corners = [
    (-0.5, -0.5, -0.5),
    (0.5, -0.5, -0.5),
    (0.5, 0.5, -0.5),
    (-0.5, 0.5, -0.5),
    (-0.5, -0.5, 0.5),
    (0.5, -0.5, 0.5),
    (0.5, 0.5, 0.5),
    (-0.5, 0.5, 0.5),
  ];

  /// The twelve edges of a cell, as pairs of [_corners] indices: the near
  /// square, the far square, and the four struts between them.
  static const edges = [
    (0, 1), (1, 2), (2, 3), (3, 0), //
    (4, 5), (5, 6), (6, 7), (7, 4), //
    (0, 4), (1, 5), (2, 6), (3, 7), //
  ];

  _Cell3D _project(Cell cell) {
    // The layer index is the *vertical* axis: layer 1 sits on top of layer 4,
    // which is the picture the layered board's caption column already draws
    // top to bottom, and the one the tutorial's opening turn assembles. Rows
    // run into the screen and columns across it.
    final mx = (cell.x - 1.5) * _pitch;
    final my = (cell.z - 1.5) * _pitch;
    final mz = (cell.y - 1.5) * _pitch;
    final centre = _view(mx, my, mz);
    return _Cell3D(
      cell: cell,
      centre: centre.$1,
      edge: unit * centre.$3,
      depth: centre.$2,
      corners: [
        for (final (cx, cy, cz) in _corners)
          _view(mx + cx, my + cy, mz + cz).$1,
      ],
    );
  }

  /// A model-space point as (screen position, depth, perspective factor).
  ///
  /// Yaw turns about the vertical axis, pitch about the horizontal one, and
  /// the divide is the whole of the perspective. Depth grows away from the
  /// eye; see [_camera] for why the divisor is always comfortably positive.
  (Offset, double, double) _view(double mx, double my, double mz) {
    final x = mx * _cosYaw + mz * _sinYaw;
    final z = -mx * _sinYaw + mz * _cosYaw;
    final y = my * _cosPitch - z * _sinPitch;
    final depth = my * _sinPitch + z * _cosPitch;
    final k = _camera / (_camera + depth);
    return (
      Offset(_centre.dx + x * unit * k, _centre.dy + y * unit * k),
      depth,
      k,
    );
  }

  /// The frontmost cell under [point], or null.
  ///
  /// **The hit area is a disc around the ball, not the ball itself.** The ball
  /// is what a player aims at, but at [_emptyBall] of a cell it is about
  /// fifteen logical pixels across — far under any touch-target floor, which
  /// is why the affordance and the target differ here. How far the target
  /// spreads beyond it is [_hitRadius], and that number is a measured
  /// compromise rather than a free choice.
  ///
  /// Frontmost wins, which is what makes a tap land on what the player can
  /// see. The cost is that a cell hidden behind another cannot be tapped at
  /// all until the cube is turned — correct, and the alternative is playing a
  /// move in a cell nobody could see.
  Cell? cellAt(Offset point) {
    for (final c in _cells.reversed) {
      final r = c.edge * _hitRadius;
      if ((point - c.centre).distanceSquared <= r * r) return c.cell;
    }
    return null;
  }
}

/// One cell's projection for this frame.
class _Cell3D {
  const _Cell3D({
    required this.cell,
    required this.centre,
    required this.edge,
    required this.depth,
    required this.corners,
  });

  final Cell cell;

  /// Screen position of the cell's centre.
  final Offset centre;

  /// The cell's edge length in logical pixels at its own depth.
  final double edge;

  /// Distance beyond the cube's centre plane; larger is farther away.
  final double depth;

  /// The eight corners, in [CubeProjection._corners] order.
  final List<Offset> corners;
}

class _CubePainter extends CustomPainter {
  _CubePainter({
    required this.state,
    required this.highlight,
    required this.flashing,
    required this.elapsed,
    required this.reduceMotion,
    required this.yaw,
    required this.pitch,
    this.zoom = 1,
  }) : sustained = outcome(state) is Win;

  final GameState state;
  final Set<int> highlight;
  final Set<int> flashing;

  /// The flash controller's value: elapsed fraction, not strength.
  final double elapsed;
  final bool reduceMotion;
  final bool sustained;
  final double yaw;
  final double pitch;
  final double zoom;

  /// The glass. Pale and very faint, because sixty-four of these stack up: at
  /// anything heavier the far half of the cube disappears behind the near half
  /// even though every box is transparent.
  static const _glassFillAlpha = 0.04;
  static const _glassEdgeAlpha = 0.15;

  /// What a cell of the winning line is drawn in instead.
  static const _wonFillAlpha = 0.16;
  static const _wonEdgeAlpha = 0.85;

  /// An empty cell's marker. Grey rather than a tint of either side, so it
  /// cannot be misread as a piece at a glance, and light enough to hold its
  /// own: at 0xFF8B8B93 it disappeared into the forest photograph behind the
  /// glass, which is the same 2.9:1 problem D296 found for ink on that picture.
  /// The rim is what keeps it from vanishing where the background is pale.
  static const _emptyBallColour = Color(0xFFB4B4BC);
  static const _emptyBallRim = Color(0x99202024);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final p = CubeProjection(size: size, yaw: yaw, pitch: pitch, zoom: zoom);

    // Far cells are drawn dimmer as well as smaller. Perspective alone is a
    // weak depth cue at this camera distance, and without the fade the near
    // and far halves of the cube read as one flat lattice.
    final near = p._cells.last.edge;
    final far = p._cells.first.edge;
    final spread = near - far;

    for (final c in p._cells) {
        // Down to a third at the back rather than to a half. Sixty-four boxes
      // is 768 edges, and at an even fade the far ones read as a thicket in
      // front of the near ones rather than behind them.
      final lit = spread <= 0 ? 1.0 : 0.33 + 0.67 * (c.edge - far) / spread;
      _paintGlass(canvas, c, lit);
      _paintBall(canvas, c, lit);
    }
  }

  void _paintGlass(Canvas canvas, _Cell3D c, double lit) {
    final won = highlight.contains(c.cell.index);
    final path = Path();
    for (final (a, b) in CubeProjection.edges) {
      path.moveTo(c.corners[a].dx, c.corners[a].dy);
      path.lineTo(c.corners[b].dx, c.corners[b].dy);
    }
    final tint = won ? QuadrimPalette.gold : const Color(0xFFFFFFFF);
    canvas.drawPath(
      _silhouette(c.corners),
      Paint()
        ..color = tint.withValues(
          alpha: (won ? _wonFillAlpha : _glassFillAlpha) * lit,
        ),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = won ? 1.8 : 1.0
        ..color = tint.withValues(
          alpha: (won ? _wonEdgeAlpha : _glassEdgeAlpha) * lit,
        ),
    );
  }

  void _paintBall(Canvas canvas, _Cell3D c, double lit) {
    final owner = state.owner(c.cell);
    if (owner == null) {
      final r = c.edge * _emptyBall / 2;
      canvas.drawCircle(
        c.centre,
        r,
        Paint()..color = _emptyBallColour.withValues(alpha: lit),
      );
      canvas.drawCircle(
        c.centre,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9
          ..color = _emptyBallRim.withValues(alpha: 0.6 * lit),
      );
      return;
    }

    final r = c.edge * _playedBall / 2;
    final light = owner == Player.first;
    final from = light ? kPieceLight : kPieceDark;
    final to = light ? kPieceLightFlash : kPieceDarkFlash;
    final strength = _strength(c.cell);
    canvas.drawCircle(
      c.centre,
      r,
      Paint()
        ..shader = RadialGradient(
          center: kPieceHighlight,
          colors: [
            for (var i = 0; i < from.length; i++)
              Color.lerp(from[i], to[i], strength)!.withValues(alpha: lit),
          ],
          stops: kPieceStops,
        ).createShader(Rect.fromCircle(center: c.centre, radius: r)),
    );
    // The rim the layered board gives a dark piece, for the same reason: on a
    // dark ground an unrimmed dark ball has no edge at all.
    if (!light) {
      canvas.drawCircle(
        c.centre,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = Colors.white.withValues(alpha: 0.25 * lit),
      );
    }
  }

  /// How green [cell]'s ball is, by the same rules the layered board follows.
  double _strength(Cell cell) {
    if (!flashing.contains(cell.index)) return 0;
    if (reduceMotion) {
      // No pulse: the winning line is simply lit, and a played piece is lit
      // until its controller runs out. Same two states [_Pebble] settles on.
      return sustained ? 1 : (elapsed >= 1 ? 0 : 1);
    }
    return sustained ? winPulseStrength(elapsed) : flashStrength(elapsed);
  }

  /// The outline of a projected cell — six of its eight corners, or four when
  /// it is seen square on.
  ///
  /// A convex hull rather than the three camera-facing quads. The quads want a
  /// per-face normal test and paint three overlapping translucent layers where
  /// the silhouette paints one, which on sixty-four cells is both slower and
  /// three times as opaque as intended.
  Path _silhouette(List<Offset> points) {
    final sorted = [...points]..sort(
      (a, b) => a.dx == b.dx ? a.dy.compareTo(b.dy) : a.dx.compareTo(b.dx),
    );
    // Andrew's monotone chain: lower hull then upper, dropping any point that
    // does not turn the same way as the one before it.
    List<Offset> half(Iterable<Offset> ps) {
      final out = <Offset>[];
      for (final p in ps) {
        while (out.length >= 2 && _cross(out[out.length - 2], out.last, p) <= 0) {
          out.removeLast();
        }
        out.add(p);
      }
      out.removeLast();
      return out;
    }

    final hull = [...half(sorted), ...half(sorted.reversed)];
    final path = Path()..moveTo(hull.first.dx, hull.first.dy);
    for (final p in hull.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  static double _cross(Offset o, Offset a, Offset b) =>
      (a.dx - o.dx) * (b.dy - o.dy) - (a.dy - o.dy) * (b.dx - o.dx);

  @override
  bool shouldRepaint(_CubePainter old) =>
      old.yaw != yaw ||
      old.pitch != pitch ||
      old.zoom != zoom ||
      old.elapsed != elapsed ||
      old.reduceMotion != reduceMotion ||
      !identical(old.state, state) ||
      !setEquals(old.highlight, highlight) ||
      !setEquals(old.flashing, flashing);
}
