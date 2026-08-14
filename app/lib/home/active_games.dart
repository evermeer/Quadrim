import 'package:flutter/material.dart';

import '../data/documents.dart';
import '../l10n/app_localizations.dart';
import 'game_row.dart';

/// One unfinished game: who it is against, and how far in it is.
class ActiveGameTile extends StatelessWidget {
  const ActiveGameTile({super.key, required this.game, required this.onTap});

  final GameDocument game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GameRow(
      game: game,
      trailing: l10n.movesPlayed(game.moves.length),
      onTap: onTap,
    );
  }
}
