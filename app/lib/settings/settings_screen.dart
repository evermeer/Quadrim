import 'dart:async';

import 'package:flutter/material.dart';

import '../data/documents.dart';
import '../data/game_repository.dart';
import '../design/forest.dart';
import '../l10n/app_localizations.dart';
import '../shop/shop.dart';
import '../tutorial/tutorial_screen.dart';

/// The two things a player can change: language, and another look at the
/// tutorial.
///
/// Small, and a blocker of the first upload for a reason that is easy to miss:
/// half the closed testers are Dutch, and without a language override a Dutch
/// tester whose phone is set to English cannot see the Dutch build at all
/// (ticket 028).
///
/// It also carries the strategy-dictionary attribution. That is not decoration
/// — the dictionary's terms permit its use only if its source is credited in
/// the shipped app, so `check.sh` greps `app/lib` for `strategyCredit` and
/// fails if it renders nowhere (D174). This screen inherited it from the
/// placeholder it replaced.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.settings, this.shop});

  final SettingsRepository settings;

  /// Null in the tests that are about language and the tutorial, and in any
  /// build with no store attached. The restore row is simply absent then —
  /// a button that cannot reach a store is worse than no button.
  final Shop? shop;

  Future<void> _save(SettingsDocument next) => settings.saveSettings(next);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return ForestScaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      // Watched rather than loaded once: the repository is stream-based so
      // that 0.3a's Firestore implementation can satisfy the same contract,
      // and a screen that read the document once would be the one place that
      // stopped being true.
      body: StreamBuilder<SettingsDocument>(
        stream: settings.watchSettings(),
        builder: (context, snapshot) {
          final current = snapshot.data;
          if (current == null) return const SizedBox.shrink();
          return SafeArea(
            // A list, so the whole screen still reaches its last row at the
            // largest system font scale.
            child: ParchmentSheet(
              child: ListView(
                children: [
                  _Heading(l10n.settingsLanguage),
                  _Choice(
                    label: l10n.settingsFollowDevice,
                    value: 'system',
                    group: current.locale,
                    onSelected: (v) => _save(current.copyWith(locale: v)),
                  ),
                  _Choice(
                    label: l10n.languageEnglish,
                    value: 'en',
                    group: current.locale,
                    onSelected: (v) => _save(current.copyWith(locale: v)),
                  ),
                  _Choice(
                    label: l10n.languageDutch,
                    value: 'nl',
                    group: current.locale,
                    onSelected: (v) => _save(current.copyWith(locale: v)),
                  ),
                  // The theme choice is gone. Ticket 038 replaced the seeded
                  // dark/light pair with one painted design, so all three options
                  // now select the same screen, and a control that does nothing
                  // is worse than no control (D293). The stored field survives
                  // untouched for the day there is a second design to pick.
                  const Divider(),
                  _Heading(l10n.tutorial),
                  ListTile(
                    leading: const Icon(Icons.school_outlined),
                    title: Text(l10n.settingsShowTutorial),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => TutorialScreen(settings: settings),
                      ),
                    ),
                  ),
                  if (shop != null) ...[
                    const Divider(),
                    _Heading(l10n.settingsPurchases),
                    _RestoreRow(shop: shop!),
                  ],
                  const Divider(),
                  _Heading(l10n.settingsAbout),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: Text(
                      l10n.strategyCredit,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    ),
  );
}

/// One option in a mutually exclusive group.
///
/// A [RadioListTile] rather than a hand-rolled row, because it is the only
/// one of the two that tells a screen reader this is a choice among several
/// and which one is taken. The tick is not the point; the announcement is.
class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.value,
    required this.group,
    required this.onSelected,
  });

  final String label;
  final String value;
  final String group;
  final void Function(String value) onSelected;

  @override
  Widget build(BuildContext context) => RadioListTile<String>(
    title: Text(label),
    value: value,
    // ignore: deprecated_member_use
    groupValue: group,
    // ignore: deprecated_member_use
    onChanged: (v) {
      if (v != null && v != group) onSelected(v);
    },
  );
}


/// The explicit restore action (§4.1, ticket 046).
///
/// **Apple requires one**, and it is not merely a formality: a player who
/// reinstalls has paid and owns nothing until this runs. [Shop.start] restores
/// silently at launch too, but a silent path the player cannot trigger is no
/// use on the day it does not fire.
class _RestoreRow extends StatefulWidget {
  const _RestoreRow({required this.shop});

  final Shop shop;

  @override
  State<_RestoreRow> createState() => _RestoreRowState();
}

class _RestoreRowState extends State<_RestoreRow> {
  bool _running = false;

  /// How long to wait for the store to answer before saying it found nothing.
  ///
  /// The store replies on the purchase stream rather than by returning, so
  /// there is nothing to await. **Reporting "nothing to restore" too early is
  /// the failure that matters**: it tells a player who has paid that they own
  /// nothing, which reads as a lost purchase. So this waits for the entitlement
  /// to change and only gives up after a generous timeout.
  static const Duration _restoreTimeout = Duration(seconds: 8);

  Future<void> _restore() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    if (!widget.shop.storeAvailable) {
      messenger.showSnackBar(
          SnackBar(content: Text(l10n.settingsRestoreUnavailable)));
      return;
    }

    setState(() => _running = true);
    final entitlement = widget.shop.entitlement;
    final before = entitlement.value;

    // Resolves on the first change, or on the timeout, whichever comes first.
    final settled = Completer<void>();
    void onChange() {
      if (!settled.isCompleted) settled.complete();
    }

    entitlement.addListener(onChange);
    await widget.shop.restore();
    await settled.future.timeout(_restoreTimeout, onTimeout: () {});
    entitlement.removeListener(onChange);

    if (!mounted) return;
    setState(() => _running = false);

    final after = entitlement.value;
    // Already owning something and seeing no change is still a success: the
    // player asked for their purchases back and they have them.
    final owns = after.unlockAll || after.unlimited;
    messenger.showSnackBar(SnackBar(
      content: Text(owns
          ? l10n.settingsRestoreDone
          : after == before
              ? l10n.settingsRestoreNothing
              : l10n.settingsRestoreDone),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: const Icon(Icons.restore_outlined),
      title: Text(l10n.settingsRestorePurchases),
      subtitle: Text(l10n.settingsRestoreExplanation),
      trailing: _running
          ? const SizedBox(
              width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : null,
      onTap: _running ? null : _restore,
    );
  }
}
