import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quadrim_engine/quadrim_engine.dart';

import '../l10n/app_localizations.dart';

/// The 4x4x4 board as four sheared 4x4 grids stacked in one column, aligned
/// to the right edge (D137).
///
/// Geometry follows D127: the touch target is the constraint and the board
/// derives from it. A horizontal shear (not a perspective rotation) carries
/// the depth illusion, because shear leaves cell height untouched — the
/// rendered hit area of every cell equals the cell itself. Layers read
/// z = 0..3 top to bottom, nearest first.
///
/// Stacked vertically, screen *height* is normally what limits the cell, so
/// the size is derived from both axes and the smaller wins.
class BoardView extends StatelessWidget {
  const BoardView({
    super.key,
    required this.state,
    required this.enabled,
    required this.onCellTap,
    this.highlight = const [],
  });

  final GameState state;

  /// Whether taps place a piece right now (it is a human's turn and the
  /// game is not over).
  final bool enabled;

  final void Function(Cell cell) onCellTap;

  /// Cell indices to emphasise — the winning line at the end of a game.
  final List<int> highlight;

  static const _shear = 0.15; // horizontal skew; depth cue (see D135)
  static const _cellGap = 2.0;
  static const _layerGap = 8.0;
  static const _captionHeight = 16.0;
  static const _captionGap = 2.0;

  /// Fixed chrome above each layer's grid, so the height budget below is
  /// exact rather than dependent on how tall the caption happens to render.
  static const _layerChrome = _captionHeight + _captionGap;

  /// Cells stop growing here so the board does not balloon on wide screens.
  static const _maxCellSize = 48.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Width holds one sheared grid; the shear consumes extra width.
        final byWidth =
            (constraints.maxWidth / (1 + _shear) - 3 * _cellGap) / 4;
        // Height holds four layers: 16 cell rows, 12 cell gaps, 3 layer gaps
        // and four captions.
        final byHeight = (constraints.maxHeight -
                4 * _layerChrome -
                12 * _cellGap -
                3 * _layerGap) /
            16;
        // math.max guards degenerate constraints; a negative size would throw
        // in the Container below rather than merely look wrong.
        final cellSize =
            math.max(1.0, math.min(math.min(byWidth, byHeight), _maxCellSize));
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var z = 0; z < 4; z++)
              Padding(
                padding: EdgeInsets.only(top: z == 0 ? 0 : _layerGap),
                child: _LayerView(
                  z: z,
                  state: state,
                  enabled: enabled,
                  onCellTap: onCellTap,
                  highlight: highlight,
                  cellSize: cellSize,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _LayerView extends StatelessWidget {
  const _LayerView({
    required this.z,
    required this.state,
    required this.enabled,
    required this.onCellTap,
    required this.highlight,
    required this.cellSize,
  });

  final int z;
  final GameState state;
  final bool enabled;
  final void Function(Cell cell) onCellTap;
  final List<int> highlight;
  final double cellSize;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gridSize = 4 * cellSize + 3 * BoardView._cellGap;
    return Semantics(
      container: true,
      label: l10n.layerLabel(z + 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(left: BoardView._shear * gridSize / 2),
            // The enclosing Semantics(container) already announces the layer;
            // exposing this Text too would read "Layer 1" twice.
            child: ExcludeSemantics(
              // Fixed height keeps the cell-size arithmetic exact; scaleDown
              // means a large system text scale shrinks the caption instead
              // of overflowing it.
              child: SizedBox(
                height: BoardView._captionHeight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.layerLabel(z + 1),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: BoardView._captionGap),
          // The shear: x' = x + k*(gridSize - y), so rows nearer the top
          // (deeper into the board) shift right, suggesting depth. The
          // SizedBox reserves that extra width INSIDE this layer's layout —
          // without it the sheared top rows would overlap the neighbouring
          // layer and steal its taps (caught by the widget tests).
          SizedBox(
            width: gridSize * (1 + BoardView._shear),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Transform(
                transform: Matrix4.identity()
                  ..setEntry(0, 1, -BoardView._shear),
                origin: Offset(0, gridSize),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var y = 0; y < 4; y++)
                      Padding(
                        padding: EdgeInsets.only(
                          top: y == 0 ? 0 : BoardView._cellGap,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var x = 0; x < 4; x++)
                              Padding(
                                padding: EdgeInsets.only(
                                  left: x == 0 ? 0 : BoardView._cellGap,
                                ),
                                child: _CellView(
                                  cell: Cell.xyz(x, y, z),
                                  state: state,
                                  enabled: enabled,
                                  onTap: onCellTap,
                                  highlighted: highlight.contains(
                                    Cell.xyz(x, y, z).index,
                                  ),
                                  size: cellSize,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CellView extends StatelessWidget {
  const _CellView({
    required this.cell,
    required this.state,
    required this.enabled,
    required this.onTap,
    required this.highlighted,
    required this.size,
  });

  final Cell cell;
  final GameState state;
  final bool enabled;
  final void Function(Cell cell) onTap;
  final bool highlighted;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final owner = state.owner(cell);
    final stateLabel = switch (owner) {
      null => l10n.cellEmpty,
      Player.first => l10n.cellLight,
      Player.second => l10n.cellDark,
    };
    final tappable = enabled && owner == null;

    return Semantics(
      // container: every cell is its own node even when not tappable, so an
      // occupied cell never merges its label into the layer's.
      container: true,
      button: tappable,
      label: l10n.cellSemantics(cell.z + 1, cell.y + 1, cell.x + 1, stateLabel),
      child: GestureDetector(
        key: ValueKey('cell-${cell.index}'),
        behavior: HitTestBehavior.opaque,
        onTap: tappable ? () => onTap(cell) : null,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: highlighted ? scheme.primary : scheme.outlineVariant,
              width: highlighted ? 2 : 1,
            ),
          ),
          child: owner == null
              ? null
              : Center(
                  child: _Pebble(
                    light: owner == Player.first,
                    diameter: size * 0.62,
                  ),
                ),
        ),
      ),
    );
  }
}

/// A piece. Light versus dark is a *lightness* distinction, deliberately not
/// a hue one (D124): it survives every form of colour vision deficiency.
class _Pebble extends StatelessWidget {
  const _Pebble({required this.light, required this.diameter});

  final bool light;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.45),
          colors: light
              ? const [Color(0xFFFFFFFF), Color(0xFFE4E4E6), Color(0xFFC3C3C8)]
              : const [Color(0xFF4A4A52), Color(0xFF1C1C22), Color(0xFF050507)],
          stops: const [0.0, 0.55, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
        border: light
            ? null
            : Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 0.8,
              ),
      ),
    );
  }
}

/// The audited floor (D135). 44dp is geometrically impossible for 64
/// always-visible cells on a phone; WCAG 2.5.8 AA permits dense adjacent-
/// target grids at >=24dp with spacing, and this board keeps a comfortable
/// margin above that. Ticket 021 verifies on real devices and the
/// closed-test survey asks about mis-taps.
const double kMinCellSize = 32;

/// The narrowest screen this board is supported on. Since D137 stacked the
/// layers vertically it is screen *height* that binds first, but the width
/// claim still bounds the sheared grid. Both bounds are pinned by widget
/// tests at [kMinSupportedHeight].
const double kMinSupportedWidth = 360;

/// The shortest screen this board is supported on. Four stacked layers need
/// 16 cell rows plus chrome; below this the cell falls under [kMinCellSize],
/// which is a known limitation for ticket 021's audit rather than a silent
/// degradation.
///
/// Raised from 760 by ticket 007: the caption naming who opens and why costs
/// about 20dp of chrome, and every dp above the board comes out of the cell
/// at sixteen rows to one. That trade is deliberate — a permanently reserved
/// line keeps the board from resizing mid-game, which is worth more than the
/// handful of very short screens it excludes.
const double kMinSupportedHeight = 780;
