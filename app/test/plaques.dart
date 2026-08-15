import 'package:flutter_test/flutter_test.dart';
import 'package:quadrim/design/art.dart';

/// Finds a carved-wood button by what is written on it (ticket 038, D297).
///
/// The signs draw their caption on the wood rather than in a `Text` of their
/// own, so `find.text` does not reach them. This matches [SignButton.caption] —
/// the same string that is both drawn and given to the screen reader — so a
/// test written in Dutch finds "Nieuwe partij", and a sign whose caption was
/// dropped stops being findable at all, which is the failure worth having.
Finder plaqueLabelled(String label) => find.byWidgetPredicate(
      (widget) => widget is SignButton && widget.caption == label,
      description: 'sign captioned "\$label"',
    );
