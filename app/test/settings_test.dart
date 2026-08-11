import 'dart:ui' show CheckedState;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrim/data/document_store.dart';
import 'package:quadrim/data/documents.dart';
import 'package:quadrim/data/local_game_repository.dart';
import 'package:quadrim/main.dart';

void _phone(WidgetTester tester, {double textScale = 1}) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Future<LocalGameRepository> _open(
  WidgetTester tester, {
  DocumentStore? store,
  SettingsDocument settings = const SettingsDocument(tutorialOffered: true),
}) async {
  final repository =
      await LocalGameRepository.open(store ?? MemoryDocumentStore());
  addTearDown(repository.dispose);
  await repository.saveSettings(settings);
  await tester.pumpWidget(
      QuadrimApp(repository: repository, settings: repository));
  await tester.pumpAndSettle();
  return repository;
}

Future<void> _openSettings(WidgetTester tester, {String tooltip = 'Settings'}) async {
  await tester.tap(find.byTooltip(tooltip));
  await tester.pumpAndSettle();
}

/// The MaterialApp actually on screen, so assertions are about what the app
/// resolved rather than what was passed in.
MaterialApp _app(WidgetTester tester) =>
    tester.widget<MaterialApp>(find.byType(MaterialApp));

/// Every labelled semantics node, keyed by its label, first occurrence wins.
///
/// `getSemantics` walks *up* from the widget it is given, so on a merged
/// subtree like a `RadioListTile` it does not reliably land on the node
/// carrying the radio's own flags. Walking down and matching the label does.
Map<String, SemanticsFlags> _byLabel(WidgetTester tester) {
  final found = <String, SemanticsFlags>{};
  void walk(SemanticsNode node) {
    final data = node.getSemanticsData();
    if (data.label.isNotEmpty) {
      found.putIfAbsent(data.label, () => data.flagsCollection);
    }
    node.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  SemanticsNode? root;
  void findRoot(PipelineOwner owner) {
    root ??= owner.semanticsOwner?.rootSemanticsNode;
    owner.visitChildren(findRoot);
  }

  findRoot(tester.binding.rootPipelineOwner);
  walk(root!);
  return found;
}

void main() {
  testWidgets('is reachable from the main screen', (tester) async {
    _phone(tester);
    await _open(tester);
    await _openSettings(tester);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
  });

  testWidgets('changing the language applies immediately, without a restart',
      (tester) async {
    _phone(tester);
    final repo = await _open(tester);
    await _openSettings(tester);

    await tester.tap(find.text('Nederlands'));
    await tester.pumpAndSettle();

    // The screen the player is standing on is already Dutch — no restart, no
    // going back and in again. That is the whole point: a Dutch tester whose
    // phone is set to English has to be able to see the Dutch build.
    expect(find.text('Taal'), findsOneWidget);
    expect(find.text('Language'), findsNothing);
    expect(_app(tester).locale, const Locale('nl'));
    expect((await repo.loadSettings()).locale, 'nl');

    // And the main screen underneath came with it. Tapped by type rather than
    // by tooltip: the tooltip is Dutch by now too.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Nieuwe partij'), findsOneWidget);
  });

  testWidgets('English can be forced too, not only Dutch', (tester) async {
    // Guards against a "switch to Dutch" special case: the override has to
    // work in the direction that pins English on a Dutch phone as well.
    _phone(tester);
    final repo = await _open(tester,
        settings: const SettingsDocument(tutorialOffered: true, locale: 'nl'));
    expect(_app(tester).locale, const Locale('nl'));

    await _openSettings(tester, tooltip: 'Instellingen');
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(_app(tester).locale, const Locale('en'));
    expect(find.text('Language'), findsOneWidget);
    expect((await repo.loadSettings()).locale, 'en');
  });

  testWidgets('following the device clears the override', (tester) async {
    _phone(tester);
    final repo = await _open(tester,
        settings: const SettingsDocument(tutorialOffered: true, locale: 'nl'));
    await _openSettings(tester, tooltip: 'Instellingen');

    // `.first` — "Follow the device" is an option in both groups, and the
    // language group is the one above.
    await tester.tap(find.text('Volg het toestel').first);
    await tester.pumpAndSettle();

    // Null, not a locale of its own: MaterialApp's own default is to follow
    // the device, so "system" is the absence of an override.
    expect(_app(tester).locale, isNull);
    expect((await repo.loadSettings()).locale, 'system');
  });

  testWidgets('changing the theme applies immediately', (tester) async {
    _phone(tester);
    final repo = await _open(tester);
    expect(_app(tester).themeMode, ThemeMode.system);

    await _openSettings(tester);
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(_app(tester).themeMode, ThemeMode.dark);
    expect((await repo.loadSettings()).theme, 'dark');

    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(_app(tester).themeMode, ThemeMode.light);
    expect((await repo.loadSettings()).theme, 'light');
  });

  testWidgets('choices survive a restart', (tester) async {
    _phone(tester);
    final store = MemoryDocumentStore();
    await _open(tester, store: store);
    await _openSettings(tester);
    await tester.tap(find.text('Nederlands'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Donker'));
    await tester.pumpAndSettle();

    // A second app over the same bytes. Reading it back off the repository
    // that just wrote it would pass whether or not it reached storage.
    final reopened = await LocalGameRepository.open(store);
    addTearDown(reopened.dispose);
    // A key of its own, or Flutter updates the existing element tree in place
    // and the Navigator keeps the settings route it already had pushed — which
    // is a rebuild, not the fresh launch this test is about.
    await tester.pumpWidget(QuadrimApp(
      key: const ValueKey('relaunch'),
      repository: reopened,
      settings: reopened,
    ));
    await tester.pumpAndSettle();

    expect(_app(tester).locale, const Locale('nl'));
    expect(_app(tester).themeMode, ThemeMode.dark);
    expect(find.text('Nieuwe partij'), findsOneWidget);
  });

  testWidgets('the tutorial can be restarted from here', (tester) async {
    _phone(tester);
    await _open(tester);
    await _openSettings(tester);

    await tester.tap(find.text('Show the tutorial again'));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 12'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('Language'), findsOneWidget, reason: 'back on settings');
  });

  testWidgets('carries the strategy-dictionary attribution', (tester) async {
    // Not decoration: the dictionary may be used only if its source is
    // credited in the shipped app (D174). It used to live on the placeholder
    // screen this ticket deleted, so this is the assertion that it moved
    // rather than vanished. check.sh greps app/lib for the key as well.
    _phone(tester);
    await _open(tester);
    await _openSettings(tester);
    expect(find.textContaining('Oren Patashnik'), findsOneWidget);
    expect(find.textContaining('Used with permission'), findsOneWidget);
  });

  testWidgets('the choices announce themselves as a group', (tester) async {
    _phone(tester);
    final handle = tester.ensureSemantics();
    await _open(tester);
    await _openSettings(tester);

    // Read off the semantics tree by label rather than through getSemantics,
    // which walks up from the Text and does not reliably land on the tile's
    // own merged node.
    final nodes = _byLabel(tester);

    // A radio, not a row with a tick: only the former tells a screen reader
    // that this is one choice among several and which one is taken.
    // "Follow the device" appears in both groups; the language one is first.
    expect(nodes['Follow the device']!.isInMutuallyExclusiveGroup, isTrue);
    expect(nodes['Follow the device']!.isChecked, CheckedState.isTrue);
    expect(nodes['Nederlands']!.isInMutuallyExclusiveGroup, isTrue);
    expect(nodes['Nederlands']!.isChecked, CheckedState.isFalse);

    for (final heading in ['Language', 'Theme', 'About']) {
      expect(nodes[heading]?.isHeader, isTrue, reason: heading);
    }
    handle.dispose();
  });

  testWidgets('reaches its last row at the largest font setting',
      (tester) async {
    _phone(tester, textScale: 2);
    await _open(tester);
    await _openSettings(tester);
    expect(tester.takeException(), isNull);

    // The attribution is the last thing on the screen, so scrolling to it is
    // the check that nothing below the fold became unreachable.
    await tester.scrollUntilVisible(
      find.textContaining('Oren Patashnik'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Oren Patashnik'), findsOneWidget);
  });

  testWidgets('every settings string exists in Dutch', (tester) async {
    _phone(tester);
    await _open(tester,
        settings: const SettingsDocument(tutorialOffered: true, locale: 'nl'));
    await _openSettings(tester, tooltip: 'Instellingen');

    for (final text in [
      'Taal',
      'Thema',
      'Volg het toestel',
      'Licht',
      'Donker',
      'Uitleg opnieuw bekijken',
      'Over',
    ]) {
      expect(find.text(text), findsWidgets, reason: text);
    }
    // Language names are written in their own language in every locale.
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Nederlands'), findsOneWidget);
  });
}
