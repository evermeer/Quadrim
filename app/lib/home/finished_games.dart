import 'package:flutter/material.dart';

import '../data/documents.dart';
import '../l10n/app_localizations.dart';
import 'game_row.dart';

/// One finished game: who it was against, how it ended, and what it did to the
/// rating.
///
/// Ticket 035 rewrites this row — the result label moves above the rating
/// change, and a relative date and a challenge button join it.
class FinishedGameTile extends StatelessWidget {
  const FinishedGameTile({
    super.key,
    required this.game,
    required this.onTap,
    this.delta,
  });

  final GameDocument game;

  /// What this game did to the computer rating, or null if it was not on that
  /// ladder at all.
  final int? delta;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GameRow(
      game: game,
      trailing: resultLabel(l10n, game),
      delta: delta,
      onTap: onTap,
    );
  }
}
