import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:quadrim_engine/quadrim_engine.dart';

import '../l10n/app_localizations.dart';

/// How long a piece stays green after it is played, and how long the winning
/// line pulses once a game is decided.
const Duration kFlashDuration = Duration(seconds: 4);

/// Complete bright-dim cycles inside [kFlashDuration].
///
/// Four over four seconds is 1 Hz. WCAG 2.3.1 draws the seizure-risk line at
/// three flashes per second, so this sits at a third of the limit — the pulse
/// has to be slow enough to read as "look here" rather than as a strobe
/// anyway, and those two requirements point the same way (D203).
const int kFlashPulses = 4;

/// How green a flashing piece is at [t], the fraction of the flash elapsed.
///
/// Starts fully green so the move is marked the instant it lands, pulses
/// [kFlashPulses] times, and is faded out by a `1 - t` envelope so it arrives
/// at nothing rather than being cut off mid-pulse.
double flashStrength(double t) {
  if (t <= 0) return 1;
  if (t >= 1) return 0;
  return (1 - t) * (0.5 + 0.5 * math.cos(t * 2 * math.pi * kFlashPulses));
}

/// The cells a board should flash: the completed line once there is one,
/// otherwise the last move of *each* side.
///
/// Both sides, not just the most recent move. Marking only the last move meant
/// a player's own piece stopped being marked the moment the opponent answered
/// — about half a second in a real game — so the one move they never got to
/// see flash was their own. Turns alternate, so the last two moves are exactly
/// one from each side, and light and dark flash to greens of their own
/// lightness, which is what keeps them told apart while both are lit (D206).
///
/// One function rather than the same lines in the game screen and the
/// tutorial's practice game, because the two must agree — a player who learns
/// to read the flash in practice has to find it doing the same thing in a real
/// game.
List<int> flashCells(GameState state) => switch (outcome(state)) {
      Win(line: final line) => line,
      _ => state.moves.length <= 2
          ? state.moves
          : state.moves.sublist(state.moves.length - 2),
    };

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
class BoardView extends StatefulWidget {
  const BoardView({
    super.key,
    required this.state,
    required this.enabled,
    required this.onCellTap,
    this.highlight = const [],
    this.flash = const [],
  });

  final GameState state;

  /// Whether taps place a piece right now (it is a human's turn and the
  /// game is not over).
  final bool enabled;

  final void Function(Cell cell) onCellTap;

  /// Cell indices to emphasise — the winning line at the end of a game.
  final List<int> highlight;

  /// Cell indices whose pieces flash green for [kFlashDuration].
  ///
  /// Restarted whenever the list changes, which is what makes it fire once per
  /// move rather than on every rebuild. Empty on the tutorial's demonstration
  /// boards: those are static illustrations, and a step that highlights eight
  /// cells at once would pulse them all (D203).
  final List<int> flash;

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
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flash = AnimationController(
    vsync: this,
    duration: kFlashDuration,
  );

  @override
  void initState() {
    super.initState();
    if (widget.flash.isNotEmpty) _flash.forward(from: 0);
  }

  @override
  void didUpdateWidget(BoardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Contents, not identity: every rebuild hands over a freshly built list,
    // so comparing references would restart the flash on every frame.
    if (listEquals(oldWidget.flash, widget.flash)) return;
    if (widget.flash.isEmpty) {
      _flash.stop();
    } else {
      _flash.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _flash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Width holds one sheared grid; the shear consumes extra width.
        final byWidth =
            (constraints.maxWidth / (1 + BoardView._shear) -
                    3 * BoardView._cellGap) /
                4;
        // Height holds four layers: 16 cell rows, 12 cell gaps, 3 layer gaps
        // and four captions.
        final byHeight = (constraints.maxHeight -
                4 * BoardView._layerChrome -
                12 * BoardView._cellGap -
                3 * BoardView._layerGap) /
            16;
        // math.max guards degenerate constraints; a negative size would throw
        // in the Container below rather than merely look wrong.
        final cellSize = math.max(
            1.0, math.min(math.min(byWidth, byHeight), BoardView._maxCellSize));
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var z = 0; z < 4; z++)
              Padding(
                padding:
                    EdgeInsets.only(top: z == 0 ? 0 : BoardView._layerGap),
                child: _LayerView(
                  z: z,
                  state: state,
                  enabled: widget.enabled,
                  onCellTap: widget.onCellTap,
                  highlight: widget.highlight,
                  flash: widget.flash,
                  flashAnimation: _flash,
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
    required this.flash,
    required this.flashAnimation,
    required this.cellSize,
  });

  final int z;
  final GameState state;
  final bool enabled;
  final void Function(Cell cell) onCellTap;
  final List<int> highlight;
  final List<int> flash;
  final Animation<double> flashAnimation;
  final double cellSize;

  /// One cell, built from a single [Cell] rather than three identical
  /// constructions of it inside the collection-for below.
  Widget _cell(int x, int y) {
    final cell = Cell.xyz(x, y, z);
    return Padding(
      padding: EdgeInsets.only(left: x == 0 ? 0 : BoardView._cellGap),
      child: _CellView(
        cell: cell,
        state: state,
        enabled: enabled,
        onTap: onCellTap,
        highlighted: highlight.contains(cell.index),
        // Non-null only for the handful of cells actually flashing, so a
        // frame costs those pieces and not all sixty-four.
        flash: flash.contains(cell.index) ? flashAnimation : null,
        size: cellSize,
      ),
    );
  }

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
                            for (var x = 0; x < 4; x++) _cell(x, y),
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
    required this.flash,
    required this.size,
  });

  final Cell cell;
  final GameState state;
  final bool enabled;
  final void Function(Cell cell) onTap;
  final bool highlighted;

  /// Null unless this cell is flashing.
  final Animation<double>? flash;
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
                    flash: flash,
                  ),
                ),
        ),
      ),
    );
  }
}

/// A piece. Light versus dark is a *lightness* distinction, deliberately not
/// a hue one (D124): it survives every form of colour vision deficiency.
///
/// The flash keeps that promise. A light piece pulses to a *light* green and a
/// dark piece to a *dark* one, so the two stay told apart by lightness while
/// they are green — and the signal a player actually reads is the pulse over
/// time, which no colour vision deficiency touches at all (D203).
class _Pebble extends StatelessWidget {
  const _Pebble({
    required this.light,
    required this.diameter,
    this.flash,
  });

  final bool light;
  final double diameter;

  /// Null unless this piece is flashing. Its value is elapsed fraction, not
  /// strength — [flashStrength] turns one into the other.
  final Animation<double>? flash;

  static const _light = [
    Color(0xFFFFFFFF),
    Color(0xFFE4E4E6),
    Color(0xFFC3C3C8),
  ];
  static const _lightFlash = [
    Color(0xFFF4FFEF),
    Color(0xFFB8EDA4),
    Color(0xFF7FC96A),
  ];
  static const _dark = [
    Color(0xFF4A4A52),
    Color(0xFF1C1C22),
    Color(0xFF050507),
  ];
  static const _darkFlash = [
    Color(0xFF3E7A44),
    Color(0xFF14481E),
    Color(0xFF03200A),
  ];

  @override
  Widget build(BuildContext context) {
    final animation = flash;
    if (animation == null) return _build(0);
    // Read here rather than threaded down: only the flashing pebbles ask, so
    // this adds a handful of dependencies rather than sixty-four.
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: animation,
      builder: (_, _) => _build(
        reduceMotion
            ? (animation.value >= 1 ? 0.0 : 1.0)
            : flashStrength(animation.value),
      ),
    );
  }

  Widget _build(double strength) {
    final from = light ? _light : _dark;
    final to = light ? _lightFlash : _darkFlash;
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.45),
          colors: [
            for (var i = 0; i < from.length; i++)
              Color.lerp(from[i], to[i], strength)!,
          ],
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
