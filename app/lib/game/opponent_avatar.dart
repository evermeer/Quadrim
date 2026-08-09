import 'package:flutter/material.dart';
import 'package:quadrim_engine/quadrim_engine.dart';

/// A placeholder avatar for one opponent, drawn rather than loaded.
///
/// Ticket 029 asks for twenty distinguishable avatars at the quality a private
/// closed test needs and no higher, and says plainly that they must read as
/// placeholder. Drawing them from the opponent's id satisfies that with no
/// binary assets to commission, store, or keep in step with the catalogue: a
/// new opponent gets an avatar the moment it has an id, and an avatar can
/// never drift out of sync with the roster because there is nothing to drift.
///
/// **Identity is carried by shape, not colour.** The pattern is a mirrored
/// grid — the same construction as a repository identicon — and the glyph its
/// filled cells are drawn with varies too. Two opponents rendered in greyscale
/// are still told apart, which is the accessibility criterion in this ticket
/// and the one ticket 021 will audit against.
class OpponentAvatar extends StatelessWidget {
  const OpponentAvatar({
    super.key,
    required this.id,
    required this.tier,
    this.size = 44,
  });

  /// The catalogue id, without the `bot:` prefix.
  final String id;

  /// Drives the ring only. An opponent's identity is its pattern, so a
  /// recalibration that moved it between tiers would not give it a new face.
  final BotTier tier;

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      // Decorative. The name, tier and rating sit beside it as real text, so
      // there is nothing here a screen reader could announce that the row does
      // not already say (ticket 011).
      child: ExcludeSemantics(
        child: CustomPaint(
          painter: _AvatarPainter(
            seed: avatarSeed(id),
            tierIndex: tier.index,
            background: scheme.surfaceContainerHighest,
            foreground: scheme.onSurface,
            ring: scheme.primary,
          ),
        ),
      ),
    );
  }
}

/// Odd, so the mirrored pattern has a spine rather than a seam.
const int avatarGrid = 5;

/// The columns that are drawn before mirroring.
const int avatarHalfGrid = (avatarGrid + 1) ~/ 2;

/// Prefixed to the id before hashing, to move the whole roster off a set of
/// patterns that contained an unusable one.
///
/// Unsalted, Mote's three lit cells all landed on the mirror spine and its
/// avatar drew **three** marks where the busiest drew nineteen. The salt is a
/// tuning constant chosen by measuring the roster, and it is not what makes the
/// avatars legible — [avatarInkCells] and the test over it are. If a future
/// opponent lands outside the legible band, that test fails and this constant
/// gets picked again (D182).
const String _avatarSalt = 'avatar-v1';

/// FNV-1a over the salted id's code units.
///
/// Not `String.hashCode`: that is unspecified across Dart releases, and an
/// avatar that changes when the toolchain does is a bug report nobody can
/// reproduce.
int avatarSeed(String id) {
  var hash = 0x811c9dc5;
  for (final unit in '$_avatarSalt/$id'.codeUnits) {
    hash = (hash ^ unit) * 0x01000193;
    hash &= 0xffffffff;
  }
  return hash;
}

/// Whether the cell at [col], [row] is filled, for the avatar of [seed].
///
/// Top-level rather than a method on the painter so that the tests which
/// assert the twenty are distinct read the same bits the painter draws. Were
/// this duplicated, changing one copy would leave the test passing while
/// checking a pattern nobody sees.
bool avatarCellFilled(int seed, int col, int row) {
  // Rotated by a few bits of the seed so ids sharing a prefix do not share a
  // top row.
  final bit = (col * avatarGrid + row + (seed & 7)) % 30;
  return (seed >> bit) & 1 == 1;
}

/// Which of the four glyphs the filled cells use. Taken from bits the pattern
/// does not, so shape and pattern vary independently.
int avatarGlyph(int seed) => (seed >> 28) & 3;

/// A stable description of what one avatar looks like: its glyph and every
/// bit of its pattern. Two ids with the same signature render identically.
String avatarSignature(String id) {
  final seed = avatarSeed(id);
  final out = StringBuffer()..write(avatarGlyph(seed));
  for (var col = 0; col < avatarHalfGrid; col++) {
    for (var row = 0; row < avatarGrid; row++) {
      out.write(avatarCellFilled(seed, col, row) ? '1' : '0');
    }
  }
  return out.toString();
}

/// How many of the 25 cells an avatar actually paints.
///
/// Counts what is **drawn**, not what is stored: the last master column is the
/// mirror spine and paints once, the two before it paint twice. Counting master
/// cells instead — as this did at first — scores an avatar whose lit cells all
/// sit on the spine the same as one that fills two full columns, and it was
/// exactly that blind spot which let Mote ship as three marks on a face of
/// twenty-five (D182).
///
/// An avatar that is nearly empty or nearly solid carries no identity however
/// unique its bits are, so the tests assert a band rather than mere
/// distinctness.
int avatarInkCells(String id) {
  final seed = avatarSeed(id);
  var ink = 0;
  for (var col = 0; col < avatarHalfGrid; col++) {
    for (var row = 0; row < avatarGrid; row++) {
      if (!avatarCellFilled(seed, col, row)) continue;
      ink += col == avatarHalfGrid - 1 ? 1 : 2;
    }
  }
  return ink;
}

/// The most cells any avatar can paint.
const int avatarMaxInk = avatarGrid * avatarGrid;

class _AvatarPainter extends CustomPainter {
  _AvatarPainter({
    required this.seed,
    required this.tierIndex,
    required this.background,
    required this.foreground,
    required this.ring,
  });

  final int seed;
  final int tierIndex;
  final Color background;
  final Color foreground;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide / 2;
    final centre = (Offset.zero & size).center;

    canvas.drawCircle(centre, radius, Paint()..color = background);

    // Clipped to the disc so a corner cell cannot spill past the ring.
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: centre, radius: radius)),
    );

    final cell = size.shortestSide / avatarGrid;
    final paint = Paint()..color = foreground.withValues(alpha: 0.72);
    for (var col = 0; col < avatarHalfGrid; col++) {
      for (var row = 0; row < avatarGrid; row++) {
        if (!avatarCellFilled(seed, col, row)) continue;
        _glyph(canvas, paint, Offset(col * cell, row * cell), cell);
        if (col != avatarHalfGrid - 1) {
          _glyph(
            canvas,
            paint,
            Offset((avatarGrid - 1 - col) * cell, row * cell),
            cell,
          );
        }
      }
    }
    canvas.restore();

    // The ring is the only thing the tier controls, and it is a width as well
    // as a colour so the five bands survive greyscale.
    final strokeWidth = 1 + tierIndex * 0.5;
    canvas.drawCircle(
      centre,
      radius - strokeWidth / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = ring,
    );
  }

  void _glyph(Canvas canvas, Paint paint, Offset topLeft, double cell) {
    final box =
        Rect.fromLTWH(topLeft.dx, topLeft.dy, cell, cell).deflate(cell * 0.12);
    switch (avatarGlyph(seed)) {
      case 0:
        canvas.drawRect(box, paint);
      case 1:
        canvas.drawCircle(box.center, box.width / 2, paint);
      case 2:
        canvas.drawRRect(
          RRect.fromRectAndRadius(box, Radius.circular(cell * 0.28)),
          paint,
        );
      default:
        canvas.drawPath(
          Path()
            ..moveTo(box.center.dx, box.top)
            ..lineTo(box.right, box.center.dy)
            ..lineTo(box.center.dx, box.bottom)
            ..lineTo(box.left, box.center.dy)
            ..close(),
          paint,
        );
    }
  }

  @override
  bool shouldRepaint(_AvatarPainter old) =>
      old.seed != seed ||
      old.tierIndex != tierIndex ||
      old.background != background ||
      old.foreground != foreground ||
      old.ring != ring;
}
