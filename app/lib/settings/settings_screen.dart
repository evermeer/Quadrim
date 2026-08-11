import 'package:flutter/material.dart';

import '../data/documents.dart';
import '../data/game_repository.dart';
import '../l10n/app_localizations.dart';
import '../tutorial/tutorial_screen.dart';

/// The three things a player can change: language, theme, and another look at
/// the tutorial.
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
  const SettingsScreen({super.key, required this.settings});

  final SettingsRepository settings;

  Future<void> _save(SettingsDocument next) => settings.saveSettings(next);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
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
                const Divider(),
                _Heading(l10n.settingsTheme),
                _Choice(
                  label: l10n.settingsFollowDevice,
                  value: 'system',
                  group: current.theme,
                  onSelected: (v) => _save(current.copyWith(theme: v)),
                ),
                _Choice(
                  label: l10n.themeLight,
                  value: 'light',
                  group: current.theme,
                  onSelected: (v) => _save(current.copyWith(theme: v)),
                ),
                _Choice(
                  label: l10n.themeDark,
                  value: 'dark',
                  group: current.theme,
                  onSelected: (v) => _save(current.copyWith(theme: v)),
                ),
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
