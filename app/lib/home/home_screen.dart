import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:quadrim_engine/quadrim_engine.dart';

import '../data/documents.dart';
import '../data/game_repository.dart';
import '../data/home_summary.dart';
import '../data/rating_fold.dart' as fold;
import '../game/game_screen.dart';
import '../game/opponent_screen.dart';
import '../l10n/app_localizations.dart';
import '../settings/settings_screen.dart';
import '../tutorial/tutorial_screen.dart';
import 'active_games.dart';
import 'finished_games.dart';
import 'opponent_section.dart';
import 'rating_card.dart';
import 'section_widgets.dart';

/// The app's home: what the player has done, what they are in the middle of,
/// and the one button that starts something new.
///
/// Everything it says about finished games comes from a single list of them,
/// folded once per change into a [HomeSummary] (criterion 18). Nothing here is
/// stored — a stored total is a second copy of what the games already say, and
/// the two drift the first time one is deleted.
///
/// This file holds the screen's state and its composition, and nothing else.
/// Each section is its own file beside it (ticket 030), because §11.3 adds a
/// trend graph, a points balance, a Your Path row and a quests section to this
/// screen, and every remaining 0.1 ticket touches it.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.repository,
    required this.settings,
    this.random,
  });

  final GameRepository repository;

  /// Read on first frame to decide whether to offer the tutorial, and written
  /// once the offer has been made. Separate from [repository] because they are
  /// separate contracts, even though 0.1's one implementation satisfies both.
  final SettingsRepository settings;

  /// Injected so a test can pin who opens a new game. Null means unseeded.
  final Random? random;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription<List<GameDocument>>? _active;
  StreamSubscription<List<GameDocument>>? _completed;

  List<GameDocument> _activeGames = const [];
  List<GameDocument> _completedGames = const [];
  HomeSummary _summary = HomeSummary.empty;
  /// What each finished ladder game did to the rating, by game id. Computed
  /// with the summary rather than per row, which would re-fold the history
  /// once for every row on the screen.
  Map<String, int> _deltas = const {};

  @override
  void initState() {
    super.initState();
    _active = widget.repository
        .watchActiveGames()
        .listen((games) => setState(() => _activeGames = games));
    // Watched rather than loaded once: the criteria ask both for a single
    // list folded four ways and for the screen to update when a game finishes,
    // and a stream gives one list per change rather than four sweeps (D158).
    _completed = widget.repository.watchCompletedGames().listen((games) {
      setState(() {
        _completedGames = games;
        _summary = HomeSummary.from(games);
        _deltas = fold.ratingDeltas(games);
      });
    });
    // After the first frame, not during it: showing a dialog needs a Navigator
    // above this widget, and there is none until the tree is built.
    WidgetsBinding.instance.addPostFrameCallback((_) => _offerTutorial());
  }

  /// Offers the tutorial the first time the app is opened, once.
  ///
  /// The offer is recorded before it is shown rather than after. The player
  /// can dismiss this dialog by tapping outside it, which returns no answer at
  /// all; recording afterwards would mean that dismissal re-armed the offer for
  /// the next launch, and repeating a question the player has already waved
  /// away is the failure mode worth designing out (D193).
  Future<void> _offerTutorial() async {
    final settings = await widget.settings.loadSettings();
    if (settings.tutorialOffered || settings.tutorialCompleted) return;
    await widget.settings.saveSettings(settings.copyWith(tutorialOffered: true));
    if (!mounted) return;
    if (await showTutorialOffer(context) && mounted) await _openTutorial();
  }

  Future<void> _openTutorial() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TutorialScreen(settings: widget.settings),
      ),
    );
  }

  @override
  void dispose() {
    _active?.cancel();
    _completed?.cancel();
    super.dispose();
  }

  Future<void> _openGame(String id) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(
          repository: widget.repository,
          gameId: id,
          random: widget.random,
        ),
      ),
    );
  }

  /// Mode first, then — for a computer game — which of the twenty.
  ///
  /// Backing out of the opponent list cancels the whole flow rather than
  /// falling back to a default opponent: a game against somebody the player
  /// did not choose is worse than no game (ticket 011).
  Future<void> _newGame() async {
    final l10n = AppLocalizations.of(context)!;
    final mode = await showModalBottomSheet<GameMode>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.computer_outlined),
              title: Text(l10n.playTheComputer),
              onTap: () => Navigator.of(context).pop(GameMode.vsComputer),
            ),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: Text(l10n.passAndPlay),
              onTap: () => Navigator.of(context).pop(GameMode.passAndPlay),
            ),
          ],
        ),
      ),
    );
    if (mode == null || !mounted) return;

    BotConfig? bot;
    if (mode == GameMode.vsComputer) {
      bot = await Navigator.of(context).push<BotConfig>(
        MaterialPageRoute<BotConfig>(
          builder: (_) => OpponentScreen(playerRating: _summary.computerRating),
        ),
      );
      if (bot == null || !mounted) return;
    }

    final game = await widget.repository.createGame(
      mode: mode,
      opponent: bot == null ? kGuestOpponent : botOpponent(bot.id),
      opponentRating: bot?.rating,
      startingSeat: (widget.random ?? Random()).nextInt(2),
    );
    if (!mounted) return;
    await _openGame(game.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settings,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SettingsScreen(settings: widget.settings),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Slivers rather than a ListView of children: the finished-games
            // list has no upper bound, and `ListView(children: [...])` builds
            // every one of them whether or not it is on screen. The fixed
            // sections above it are cheap and stay eager.
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    sliver: SliverList.list(
                      children: [
                        RatingCard(summary: _summary),
                        if (_summary.byOpponent.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          OpponentSection(records: _summary.byOpponent),
                        ],
                        if (_activeGames.isEmpty && _completedGames.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(l10n.noGamesYet,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium),
                          ),
                      ],
                    ),
                  ),
                  if (_activeGames.isNotEmpty)
                    ...gameSectionSlivers(
                      heading: l10n.inProgress,
                      games: _activeGames,
                      tile: (game) =>
                          ActiveGameTile(game: game, onTap: () => _openGame(game.id)),
                    ),
                  if (_completedGames.isNotEmpty)
                    ...gameSectionSlivers(
                      heading: l10n.finishedGames,
                      games: _completedGames,
                      tile: (game) => FinishedGameTile(
                          game: game,
                          delta: _deltas[game.id],
                          onTap: () => _openGame(game.id)),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _newGame,
                      child: Text(l10n.newGame),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _openTutorial,
                      child: Text(l10n.tutorial),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// The placeholder screen that stood in for the tutorial and settings (D159)
// is gone: ticket 018 replaced one route and ticket 028 the other, which is
// what it was for. The strategy-dictionary attribution it carried moved with
// it, to SettingsScreen — there was never a build in which that credit was
// merely planned (D174).
