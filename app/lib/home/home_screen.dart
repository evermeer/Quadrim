import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:quadrim_engine/quadrim_engine.dart';

import '../data/documents.dart';
import '../data/game_repository.dart';
import '../data/home_summary.dart';
import '../data/rating_fold.dart' as fold;
import '../game/game_screen.dart';
import '../game/opponent_avatar.dart';
import '../game/opponent_name.dart';
import '../game/opponent_screen.dart';
import '../l10n/app_localizations.dart';
import '../settings/settings_screen.dart';
import '../tutorial/tutorial_screen.dart';

/// The app's home: what the player has done, what they are in the middle of,
/// and the one button that starts something new.
///
/// Everything it says about finished games comes from a single list of them,
/// folded once per change into a [HomeSummary] (criterion 18). Nothing here is
/// stored — a stored total is a second copy of what the games already say, and
/// the two drift the first time one is deleted.
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
          Builder(builder: (context) {
            final name = botName(l10n, record.opponent);
            final tally = l10n.opponentRecord(
                record.wins, record.losses, record.draws, record.played);
            final rating = record.rating;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Semantics(
                container: true,
                // The bar below carries the rating as a length, which a screen
                // reader cannot read. Saying it here is what keeps the two
                // presentations equivalent rather than one of them decorative.
                label: rating == null
                    ? '$name. $tally'
                    : l10n.opponentRowSemantics(name, rating, tally),
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // The same slot the game rows use, so the two
                          // sections share a left edge for their names rather
                          // than stepping in and out.
                          _OpponentAvatarSlot(opponent: record.opponent),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Row(
                              children: [
                                // Flexible, so a long name gives way to the
                                // pill rather than pushing it off the row.
                                Flexible(
                                  child: Text(name,
                                      overflow: TextOverflow.ellipsis),
                                ),
                                if (rating != null) ...[
                                  const SizedBox(width: 6),
                                  _RatingPill(rating: rating),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              tally,
                              textAlign: TextAlign.end,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      // Absent rather than empty when the rating is unknown: a
                      // zero-length bar would read as "very weak", and an
                      // unknown number is not a low one — the same reasoning
                      // that sorts these rows last.
                      if (rating != null) ...[
                        const SizedBox(height: 6),
                        _RatingBar(rating: rating),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
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
  const _FinishedGameTile({
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
    return _GameRow(
      game: game,
      trailing: _resultLabel(l10n, game),
      delta: delta,
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
    this.delta,
  });

  final GameDocument game;

  /// The right-hand fact: moves played, or how the game ended.
  final String trailing;

  /// What this game did to the computer rating, shown after [trailing]. Null
  /// where there is nothing to show — a game in progress, or pass and play.
  final int? delta;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final label = _opponentLabel(l10n, game);
    // The anchor this game was actually played against, not the catalogue's
    // current value — the same rule the rating fold follows (spec §8.3), so a
    // recalibration never rewrites what a finished game says it was worth.
    // Null for pass-and-play, which has no opponent to rate.
    final rating = game.opponentRating;

    return InkWell(
      onTap: onTap,
      child: Semantics(
        button: true,
        // The arrow and its number are one more fact about the row, so they
        // join the row's single label rather than announcing separately. A
        // signed integer needs no translating, which is why it is appended
        // rather than routed through a placeholder of its own.
        label: rating == null
            ? '$label. $trailing'
            : l10n.opponentRowSemantics(label, rating,
                delta == null ? trailing : '$trailing. ${_signedDelta(delta!)}'),
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
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child:
                              Text(label, overflow: TextOverflow.ellipsis),
                        ),
                        if (rating != null) ...[
                          const SizedBox(width: 6),
                          _RatingPill(rating: rating),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            trailing,
                            textAlign: TextAlign.end,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        if (delta != null) ...[
                          const SizedBox(width: 6),
                          _RatingDelta(delta: delta!),
                        ],
                      ],
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

String _signedDelta(int delta) => delta > 0 ? '+$delta' : '$delta';

/// What one finished game did to the computer rating: an arrow and a number.
///
/// The arrow's *direction* and the number's sign both carry the meaning, so
/// the colour is the third telling rather than the only one — which is what
/// keeps it readable to a player who cannot separate red from green (D124's
/// reasoning, applied to a different pair of colours).
///
/// It announces nothing of its own; the row it sits in says the number once,
/// in its single label.
class _RatingDelta extends StatelessWidget {
  const _RatingDelta({required this.delta});

  final int delta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Reachable, not hypothetical: beating an opponent far below you earns a
    // fraction of a point, which rounds to nothing. There is no direction to
    // point in, so it shows the number alone rather than an arrow that would
    // claim a movement that did not happen.
    final colour = delta == 0
        ? theme.colorScheme.onSurfaceVariant
        : delta > 0
            ? (theme.brightness == Brightness.dark
                ? const Color(0xFF7CD98C)
                : const Color(0xFF2E7D32))
            : theme.colorScheme.error;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (delta != 0)
          Icon(
            delta > 0 ? Icons.arrow_drop_up : Icons.arrow_drop_down,
            size: 18,
            color: colour,
          ),
        Text(
          _signedDelta(delta),
          style: theme.textTheme.bodySmall?.copyWith(
            color: colour,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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

/// An opponent's rating as a number, beside its name.
///
/// The bar under the row says how strong this opponent is *relative to the
/// ladder*, which is the comparison worth making at a glance; this says which
/// number it is. Both, because a length cannot be read off precisely and a
/// number cannot be compared at a glance.
///
/// Carries no semantics of its own — the row already announces the rating
/// once, and a screen reader that met it twice would be worse off than one
/// that met it never.
class _RatingPill extends StatelessWidget {
  const _RatingPill({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: ShapeDecoration(
        color: theme.colorScheme.secondaryContainer,
        shape: const StadiumBorder(),
      ),
      child: Text(
        // Through l10n even though it is only digits: a rating is written 1200
        // rather than 1,200 or 1.200 in every locale this ships in, and that
        // is a decision recorded next to the string rather than in the layout.
        AppLocalizations.of(context)!.ratingValue(rating),
        style: theme.textTheme.labelSmall
            ?.copyWith(color: theme.colorScheme.onSecondaryContainer),
      ),
    );
  }
}

/// An opponent's rating drawn as a length, under its row.
///
/// Full width is the top of the catalogue rather than the strongest opponent
/// the player happens to have met, so a bar means the same thing on a fresh
/// install as on a finished one, and beating someone new never shortens the
/// bars already on the screen.
///
/// The scale starts at zero rather than at Pebble, so Pebble reads as a
/// quarter of Quadrim Prime — which is what the ratings say. Stretching the
/// bottom of the ladder to fill the bar would make the roster look evenly
/// spread when it is not.
class _RatingBar extends StatelessWidget {
  const _RatingBar({required this.rating});

  final int rating;

  /// The catalogue is ordered weakest first and a test pins that, so the last
  /// entry is the ceiling without a constant to keep in step with it.
  static final int _strongest = opponentCatalogue.last.rating;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        // Clamped because a stored anchor comes from the game it was played
        // in, and a recalibration could leave one above today's ceiling.
        value: (rating / _strongest).clamp(0.0, 1.0),
        minHeight: 4,
        // The unfilled track is drawn rather than left blank: without it a bar
        // is only comparable to the other bars on screen, and the claim being
        // made is against the top of the ladder, which may not be on screen.
        backgroundColor: scheme.surfaceContainerHighest,
        color: scheme.primary,
      ),
    );
  }
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

// The placeholder screen that stood in for the tutorial and settings (D159)
// is gone: ticket 018 replaced one route and ticket 028 the other, which is
// what it was for. The strategy-dictionary attribution it carried moved with
// it, to SettingsScreen — there was never a build in which that credit was
// merely planned (D174).
