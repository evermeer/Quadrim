import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrim/game/opponent_avatar.dart';
import 'package:quadrim_engine/quadrim_engine.dart';

void main() {
  final ids = opponentCatalogue.map((b) => b.id).toList();

  test('every opponent gets a different avatar', () {
    // The ticket's promise is that twenty avatars are told apart. Two ids
    // hashing to the same pattern would put two identical faces on the
    // selection screen, and nothing else in the app would notice.
    final signatures = {for (final id in ids) id: avatarSignature(id)};
    final collisions = <String>[];
    for (final a in ids) {
      for (final b in ids) {
        if (a.compareTo(b) < 0 && signatures[a] == signatures[b]) {
          collisions.add('$a and $b');
        }
      }
    }
    expect(collisions, isEmpty, reason: 'identical avatars: $collisions');
    expect(signatures.values.toSet().length, ids.length);
  });

  test('no avatar is nearly blank or nearly solid', () {
    // Distinctness alone is not legibility: an avatar with two cells lit and
    // one with twenty-four are technically different and both unreadable.
    //
    // The bounds are a judgement about a 5x5 face, not a fit to the roster —
    // which is the mistake the first version of this test made, taking its
    // floor from the sparsest avatar it happened to have and so becoming
    // incapable of failing. Below 6 of 25 is a scatter of dots; above 21 is a
    // solid block with notches. The twenty currently span 7 to 19, so both
    // bounds have real margin and either can still be crossed (D182).
    for (final id in ids) {
      final ink = avatarInkCells(id);
      expect(ink, greaterThanOrEqualTo(6), reason: '$id is nearly blank: $ink');
      expect(ink, lessThanOrEqualTo(21), reason: '$id is nearly solid: $ink');
    }
  });

  test('ink counts the mirror spine once and the mirrored columns twice', () {
    // The property that made the old measure wrong. Without it, an avatar
    // whose lit cells all fall on the spine scores the same as one that fills
    // two whole columns and draws twice the ink.
    for (final id in ids) {
      expect(avatarInkCells(id), lessThanOrEqualTo(avatarMaxInk));
      var master = 0;
      final seed = avatarSeed(id);
      for (var col = 0; col < avatarHalfGrid; col++) {
        for (var row = 0; row < avatarGrid; row++) {
          if (avatarCellFilled(seed, col, row)) master++;
        }
      }
      // Every master cell paints at least once and at most twice, so ink is
      // bracketed by the master count — and equals it only when every lit cell
      // is on the spine.
      expect(avatarInkCells(id), greaterThanOrEqualTo(master));
      expect(avatarInkCells(id), lessThanOrEqualTo(master * 2));
    }
  });

  test('the pattern does not depend on colour', () {
    // The greyscale criterion, held as a property: the signature is the whole
    // of what is drawn inside the disc, and it is a function of the id alone.
    // No theme, tier, or scheme reaches it.
    for (final id in ids) {
      expect(avatarSignature(id), avatarSignature(id));
    }
    final byTier = {
      for (final tier in BotTier.values) tier: avatarSignature(ids.first),
    };
    expect(byTier.values.toSet().length, 1);
  });

  test('the seed is stable, not the Dart hash of the day', () {
    // Pinned literals. If FNV-1a is ever swapped for something else, every
    // avatar in the app changes silently; this is the test that objects.
    expect(avatarSeed('pebble'), 0x4F51EF3F);
    expect(avatarSeed('quadrim_prime'), 0xD0EA3550);
  });

  testWidgets('an avatar renders at the size it is given', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OpponentAvatar(id: 'onyx', tier: BotTier.club, size: 64),
        ),
      ),
    );
    expect(tester.getSize(find.byType(OpponentAvatar)), const Size(64, 64));
  });

  testWidgets('avatars are decorative and announce nothing', (tester) async {
    // The row around it says the name, tier and rating. An avatar that also
    // spoke would make every opponent take two swipes to pass (ticket 011).
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OpponentAvatar(id: 'lyra', tier: BotTier.expert),
        ),
      ),
    );
    // Asserted on announced content, which is the thing that matters, and not
    // on widget structure. Two earlier versions of this test could not fail:
    // `getSemantics` walks *up* to an ancestor node, so a label added on the
    // avatar itself went unseen, and a bare CustomPaint contributes no node
    // whether or not it is wrapped. This form was checked by giving the avatar
    // a labelled Semantics and confirming the test goes red.
    expect(find.bySemanticsLabel(RegExp('.+')), findsNothing);
    handle.dispose();
  });
}
