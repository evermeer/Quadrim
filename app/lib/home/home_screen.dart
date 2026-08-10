import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:quadrim_engine/quadrim_engine.dart';

import '../data/documents.dart';
import '../data/game_repository.dart';
import '../data/home_summary.dart';
import '../game/game_screen.dart';
import '../game/opponent_avatar.dart';
import '../game/opponent_name.dart';
import '../game/opponent_screen.dart';
import '../l10n/app_localizations.dart';

/// The app's home: what the player has done, what they are in the middle of,
/// and the one button that starts something new.
///
/// Everything it says about finished games comes from a single list of them,
/// folded once per change into a [HomeSummary] (criterion 18). Nothing here is
/// stored — a stored total is a second copy of what the games already say, and
/// the two drift the first time one is deleted.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.repository, this.random});

  final GameRepository repository;

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
      });
    });
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

  Future<void> _openPlaceholder(String title, {bool credit = false}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _PlaceholderScreen(title: title, credit: credit),
      ),
    );
  }

  /// A heading followed by one lazily-built tile per game.
  List<Widget> _gameSection({
    required String heading,
    required List<GameDocument> games,
    required Widget Function(GameDocument) tile,
  }) =>
      [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverToBoxAdapter(child: _SectionHeading(heading)),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.builder(
            itemCount: games.length,
            itemBuilder: (_, i) => tile(games[i]),
          ),
        ),
      ];

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
            onPressed: () => _openPlaceholder(l10n.settings, credit: true),
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
                        _RatingCard(summary: _summary),
                        if (_summary.byOpponent.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _OpponentSection(records: _summary.byOpponent),
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
                    ..._gameSection(
                      heading: l10n.inProgress,
                      games: _activeGames,
                      tile: (game) =>
                          _ActiveGameTile(game: game, onTap: () => _openGame(game.id)),
                    ),
                  if (_completedGames.isNotEmpty)
                    ..._gameSection(
                      heading: l10n.finishedGames,
                      games: _completedGames,
                      tile: (game) => _FinishedGameTile(
                          game: game, onTap: () => _openGame(game.id)),
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
                      onPressed: () => _openPlaceholder(l10n.tutorial),
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

/// The computer rating and the record that produced it, in a card of its own.
///
/// Its own card because a second rating — against people — arrives at 0.3b,
/// and the two must never read as one number (criterion 21). A labelled card
/// takes a sibling; a bare number in a row of statistics does not.
///
/// The record sits inside the card rather than under a heading of its own: it
/// is the same fold over the same games that produced the number above it, and
/// a "Your record" heading over a single line was a heading for nothing (D192).
class _RatingCard extends StatelessWidget {
  const _RatingCard({required this.summary});

  final HomeSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final record = summary.played == 0
        ? l10n.recordEmpty
        : l10n.recordLine(summary.wins, summary.losses, summary.draws);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Semantics(
          container: true,
          label: '${l10n.computerRatingHeading}: ${summary.computerRating}. '
              '$record. ${l10n.computerRatingNote}',
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.computerRatingHeading,
                    style: theme.textTheme.labelLarge),
                Text(l10n.ratingValue(summary.computerRating),
                    style: theme.textTheme.displaySmall),
                Text(record, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(l10n.computerRatingNote, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OpponentSection extends StatelessWidget {
  const _OpponentSection({required this.records});

  final List<OpponentRecord> records;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(l10n.byOpponent),
        for (final record in records)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                // The same slot the game rows use, so the two sections share a
                // left edge for their names rather than stepping in and out.
                _OpponentAvatarSlot(opponent: record.opponent),
                const SizedBox(width: 12),
                Expanded(child: Text(botName(l10n, record.opponent))),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    l10n.opponentRecord(record.wins, record.losses,
                        record.draws, record.played),
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ActiveGameTile extends StatelessWidget {
  const _ActiveGameTile({required this.game, required this.onTap});

  final GameDocument game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _GameRow(
      game: game,
      trailing: l10n.movesPlayed(game.moves.length),
      onTap: onTap,
    );
  }
}

class _FinishedGameTile extends StatelessWidget {
  const _FinishedGameTile({required this.game, required this.onTap});

  final GameDocument game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _GameRow(
      game: game,
      trailing: _resultLabel(l10n, game),
      onTap: onTap,
    );
  }
}

/// The avatar slot used by every row on this screen that names an opponent.
///
/// One widget rather than two copies, because the game rows and the
/// by-opponent breakdown have to line up: the names beside them share a left
/// edge, and that only holds while the slot is the same width in both. It also
/// puts the "there is nobody to draw" case — pass-and-play, and an opponent
/// this build does not know — in one place instead of two (D189, D191).
class _OpponentAvatarSlot extends StatelessWidget {
  const _OpponentAvatarSlot({required this.opponent});

  /// A stored `opponent` field: `bot:<id>`, or the guest.
  final String opponent;

  /// Small enough to ride a single line of text without setting its height.
  static const double size = 28;

  @override
  Widget build(BuildContext context) {
    final bot = botConfigFor(opponent);
    return SizedBox(
      width: size,
      height: size,
      child: bot == null
          ? Icon(
              Icons.people_outline,
              size: size * 0.8,
              color: Theme.of(context).colorScheme.outline,
            )
          : OpponentAvatar(id: bot.id, tier: bot.tier, size: size),
    );
  }
}

/// One game on one line: avatar, who it was against, and its state at the end.
///
/// The same shape as the by-opponent rows above it — name left, fact right —
/// so a screen that already lists opponents that way does not switch layouts
/// halfway down. Two-line `ListTile`s made a list of a dozen games longer than
/// the screen for no extra information (D189).
class _GameRow extends StatelessWidget {
  const _GameRow({
    required this.game,
    required this.trailing,
    required this.onTap,
  });

  final GameDocument game;

  /// The right-hand fact: moves played, or how the game ended.
  final String trailing;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final label = _opponentLabel(l10n, game);

    return InkWell(
      onTap: onTap,
      child: Semantics(
        button: true,
        label: '$label. $trailing',
        child: ExcludeSemantics(
          // Constrained, not just padded. `ListTile` — which this replaced —
          // enforces a 48dp minimum; hand-rolling the row dropped it to 44,
          // under the minimum touch target Android and Material both specify.
          // A constraint holds at any text scale where a fixed padding would
          // only hold at 1.0 (D189).
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  _OpponentAvatarSlot(opponent: game.opponent),
                  const SizedBox(width: 12),
                  Expanded(child: Text(label)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      trailing,
                      textAlign: TextAlign.end,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _opponentLabel(AppLocalizations l10n, GameDocument game) =>
    game.mode == GameMode.vsComputer
        ? botName(l10n, game.opponent)
        : l10n.passAndPlay;

/// A finished game's outcome, from the player's seat.
///
/// Pass-and-play has no "you", so it reports which side won rather than
/// whether the player did.
String _resultLabel(AppLocalizations l10n, GameDocument game) {
  final result = game.result;
  if (result == null) return '';
  if (result.outcome == GameOutcome.draw) return l10n.resultDrawn;
  if (game.mode != GameMode.vsComputer) {
    return result.winnerSeat == game.startingSeat
        ? l10n.lightWins
        : l10n.darkWins;
  }
  return result.winnerSeat == game.playerSeat ? l10n.resultWon : l10n.resultLost;
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Semantics(
          header: true,
          child: Text(text, style: Theme.of(context).textTheme.titleMedium),
        ),
      );
}

/// Stands in for a screen whose ticket has not shipped.
///
/// A dead button is indistinguishable from a broken one, and the criteria ask
/// for the entry points now — the tutorial arrives with ticket 018 and
/// settings with 028, both of which replace this route rather than add one
/// (D159).
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title, this.credit = false});

  final String title;

  /// Whether to carry the strategy-dictionary attribution.
  ///
  /// Not decoration and not deferrable: the dictionary's terms permit its use
  /// only if its source is credited, and it is the built app that reaches
  /// people. It lives on this placeholder until ticket 028 builds the real
  /// settings screen, so that there is never a build in which the credit is
  /// merely planned (D174).
  final bool credit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.comingSoon, textAlign: TextAlign.center),
              if (credit) ...[
                const SizedBox(height: 32),
                Text(
                  l10n.strategyCredit,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
