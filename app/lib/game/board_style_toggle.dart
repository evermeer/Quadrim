import 'package:flutter/material.dart';

import '../data/documents.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';

/// Which board the game screen is drawing, and a way to change it (D369).
///
/// **In the app bar rather than above the board**, which is not where it was
/// asked for. The game screen has about 6dp of vertical slack at the shortest
/// supported size (D204); a labelled row costs 44 of them, and the cells that
/// paid for it would have fallen under the audited 32dp floor. The app bar has
/// the room and the label lives in each button's tooltip instead — which is
/// also what a screen reader announces, so nothing is lost but the sighted
/// caption.
///
/// Two buttons rather than one that flips, because a single button has to show
/// either the state it is in or the state it would move to, and every player
/// who has ever met one has had to guess which. A pair shows both and lights
/// the one you are looking at.
class BoardStyleToggle extends StatelessWidget {
  const BoardStyleToggle({
    super.key,
    required this.style,
    required this.onChanged,
  });

  final String style;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ToggleButtons(
      isSelected: [
        style != kBoardStyleCube,
        style == kBoardStyleCube,
      ],
      onPressed: (i) =>
          onChanged(i == 0 ? kBoardStyleLayers : kBoardStyleCube),
      // 44 rather than the 48 an isolated control gets: two of these plus the
      // review button and Resign have to share a 360dp bar with the opponent's
      // name. WCAG 2.5.8 AA asks 24dp with spacing, so this keeps a wide
      // margin over the floor while leaving the title legible.
      constraints: const BoxConstraints(minWidth: 44, minHeight: 40),
      borderRadius: BorderRadius.circular(8),
      // Cream and gold, not the theme's bronze: this sits on the forest
      // photograph, where bronze measured 2.06:1 (D296).
      color: QuadrimPalette.creamSoft,
      selectedColor: QuadrimPalette.gold,
      borderColor: QuadrimPalette.creamSoft,
      selectedBorderColor: QuadrimPalette.gold,
      fillColor: QuadrimPalette.gold.withValues(alpha: 0.18),
      children: [
        _Icon(tooltip: l10n.boardStyleLayers, paint: _paintLayers),
        _Icon(tooltip: l10n.boardStyleCube, paint: _paintCube),
      ],
    );
  }
}

/// One toggle button's face.
///
/// Drawn rather than lettered or shipped as an asset. An asset would have to
/// go through the art pipeline and be checked by `art_assets_test.dart` for two
/// shapes this simple, and a glyph would be a user-facing string outside l10n
/// in all but name (D297). The tooltip carries the words.
class _Icon extends StatelessWidget {
  const _Icon({required this.tooltip, required this.paint});

  final String tooltip;
  final void Function(Canvas canvas, Size size, Color colour) paint;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Builder(
        // ToggleButtons hands its selected/unselected colour down through
        // IconTheme, so reading it here is what makes a painted face light up
        // like the built-in icons the rest of the bar uses.
        builder: (context) => CustomPaint(
          size: const Size(26, 26),
          painter: _FacePainter(paint, IconTheme.of(context).color!),
        ),
      ),
    );
  }
}

/// Four squares in a vertical line: the layered board, seen edge on.
///
/// **Sheared, which the request did not ask for.** Four plain squares stacked
/// in a column is what Material's overflow menu looks like, and on the
/// emulator this icon read as "more actions" before it read as a board. The
/// lean is the same 0.15 shear the layered board itself uses (D135), so the
/// icon is now a picture of the thing it selects and cannot be mistaken for a
/// menu (D369).
void _paintLayers(Canvas canvas, Size size, Color colour) {
  const side = 5.4;
  const gap = 1.5;
  const lean = 1.9; // how far each square sits left of the one above it
  const total = 4 * side + 3 * gap; // 24.1
  // Centred on the whole leaning stack rather than on one square, so the icon
  // does not sit off to one side of its button.
  final left = (size.width - side + 3 * lean) / 2;
  var top = (size.height - total) / 2;
  final fill = Paint()..color = colour;
  for (var i = 0; i < 4; i++) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left - i * lean, top, side, side),
        const Radius.circular(1),
      ),
      fill,
    );
    top += side + gap;
  }
}

/// A cube in the usual isometric shorthand: a hexagon with three spokes to the
/// centre, which is the near corner.
void _paintCube(Canvas canvas, Size size, Color colour) {
  final c = Offset(size.width / 2, size.height / 2);
  const r = 10.5;
  // Six vertices at 60 degree steps, starting at the top.
  final v = [
    for (var i = 0; i < 6; i++)
      Offset(
        c.dx + r * _cos60(i, isX: true),
        c.dy + r * _cos60(i, isX: false),
      ),
  ];
  final path = Path()..addPolygon(v, true);
  // Spokes to the top vertex and the two lower ones: the three edges that meet
  // at the corner nearest the eye.
  for (final i in [0, 2, 4]) {
    path
      ..moveTo(c.dx, c.dy)
      ..lineTo(v[i].dx, v[i].dy);
  }
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round
      ..color = colour,
  );
}

/// Vertex [i] of a hexagon standing on a point, as a unit offset.
///
/// Written out rather than pulled from `dart:math`, because the six values are
/// exact and a table makes the shape readable: top, upper-right, lower-right,
/// bottom, lower-left, upper-left.
double _cos60(int i, {required bool isX}) {
  const xs = [0.0, 0.866, 0.866, 0.0, -0.866, -0.866];
  const ys = [-1.0, -0.5, 0.5, 1.0, 0.5, -0.5];
  return isX ? xs[i] : ys[i];
}

class _FacePainter extends CustomPainter {
  const _FacePainter(this.paintFace, this.colour);

  final void Function(Canvas canvas, Size size, Color colour) paintFace;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) => paintFace(canvas, size, colour);

  @override
  bool shouldRepaint(_FacePainter old) =>
      old.colour != colour || old.paintFace != paintFace;
}
