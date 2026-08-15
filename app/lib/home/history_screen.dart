import 'package:flutter/material.dart';

import '../data/documents.dart';
import '../l10n/app_localizations.dart';
import 'finished_games.dart';
import 'section_widgets.dart';

/// Every finished game, on a screen of its own.
///
/// **A screen rather than an expanding list** (ticket 035). Expanding in place
/// would push the primary button off the bottom of a main screen that already
/// carries six sections, and would leave the player scrolling back up past all
/// of them to reach it. Pushing a route also gives the list a back button,
/// which is the affordance for "I have finished looking at this" that an
/// expanded section does not have.
///
/// It takes the list rather than a repository: the main screen already watches
/// completed games, and a second subscription would be a second answer to a
/// question that already has one.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({
    super.key,
    required this.games,
    required this.deltas,
    required this.now,
    required this.onOpen,
    required this.onChallenge,
  });

  final List<GameDocument> games;
  final Map<String, int> deltas;
  final DateTime now;
  final void Function(GameDocument game) onOpen;

  /// Null for a game with nobody to challenge.
  final VoidCallback? Function(GameDocument game) onChallenge;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyTitle)),
      body: SafeArea(
        child: games.isEmpty
            ? Center(child: Text(l10n.noGamesYet))
            : CustomScrollView(
                slivers: [
                  ...gameSectionSlivers(
                    heading: l10n.finishedGames,
                    games: games,
                    tile: (game) => FinishedGameTile(
                      game: game,
                      delta: deltas[game.id],
                      now: now,
                      onChallenge: onChallenge(game),
                      onTap: () => onOpen(game),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                ],
              ),
      ),
    );
  }
}
