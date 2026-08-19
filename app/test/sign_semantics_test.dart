import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrim/design/forest.dart';

/// Ticket 043: the carved signs read as headings, and the carving is silent.
///
/// The heading *labels* were already covered — `home_screen_test.dart` and
/// `settings_test.dart` both assert `isHeader` on real screens. The half that
/// was not covered is the other one: a `SectionSign` is a picture with the
/// words painted onto it, so without `ExcludeSemantics` a screen reader meets
/// the caption twice, or meets a heading with nothing in it and an unlabelled
/// image beside it.
///
/// This is the part of ticket 043's VoiceOver pass that can be held by a test
/// rather than by looking. Gesture order and announcement timing cannot —
/// those need the phone, and the simulator's accessibility inspector does not
/// reproduce them.
void main() {
  /// Every node in the tree under [finder], flattened.
  List<SemanticsNode> nodesUnder(WidgetTester tester, Finder finder) {
    final root = tester.getSemantics(finder);
    final found = <SemanticsNode>[];
    void walk(SemanticsNode node) {
      found.add(node);
      node.visitChildren((child) {
        walk(child);
        return true;
      });
    }

    walk(root);
    return found;
  }

  Future<void> pumpSign(WidgetTester tester, String caption) =>
      tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(child: SectionSign(caption)),
        ),
      ));

  testWidgets('a sign is one header node carrying its caption', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpSign(tester, 'Your path');

    final sign = find.byType(SectionSign);
    expect(tester.getSemantics(sign).label, 'Your path');
    expect(tester.getSemantics(sign).flagsCollection.isHeader, isTrue);

    handle.dispose();
  });

  testWidgets('the artwork under the caption announces nothing',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpSign(tester, 'Finished games');

    // One labelled node, not two. The picture carries the same words visually
    // and must not carry them again in the tree — the failure this catches is
    // `ExcludeSemantics` being dropped, which reads the caption twice.
    final labelled = nodesUnder(tester, find.byType(SectionSign))
        .where((node) => node.label.isNotEmpty)
        .toList();
    expect(labelled, hasLength(1),
        reason: 'the sign must contribute exactly one labelled node, '
            'found: ${labelled.map((n) => n.label).toList()}');
    expect(labelled.single.label, 'Finished games');

    // And nothing under it claims to be an image, which would give VoiceOver a
    // second thing to stop on inside a heading.
    expect(
      nodesUnder(tester, find.byType(SectionSign))
          .any((node) => node.flagsCollection.isImage),
      isFalse,
    );

    handle.dispose();
  });
}
