import 'package:flutter_test/flutter_test.dart';
import 'package:quadrim/design/art.dart';

/// Finds a carved-wood button by what it is called (ticket 038).
///
/// The plaques draw their lettering as part of the picture, so `find.text` no
/// longer reaches them and every test that used to tap "New game" needs this
/// instead. It matches on [Plaque.label] — the same string the screen reader is
/// given — so a test written in Dutch still finds "Nieuwe partij", and a plaque
/// whose accessible name was dropped stops being findable at all, which is the
/// failure worth having.
Finder plaqueLabelled(String label) => find.byWidgetPredicate(
      (widget) => widget is Plaque && widget.label == label,
      description: 'Plaque labelled "$label"',
    );
