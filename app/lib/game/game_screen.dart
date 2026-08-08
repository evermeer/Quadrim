import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:quadrim_engine/quadrim_engine.dart';

import '../data/documents.dart';
import '../data/game_repository.dart';
import '../data/rating_fold.dart';
import '../l10n/app_localizations.dart';
import 'board_view.dart';

/// How long a computer opponent visibly takes over its move. Pebble decides
/// in microseconds; without a pause its piece would simply appear, which
/// reads as a rendering glitch rather than as a turn (ticket 006).
const Duration kBotMoveDelay = Duration(milliseconds: 550);

/// One game, whether against a person sharing the device or a computer
/// opponent. The first player always holds the light pieces.
///
/// This screen keeps no board of its own: it replays the stored move list and
/// every move goes through [GameRepository] (criterion S4).
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.repository,
    required this.gameId,
    this.random,
  });

  final GameRepository repository;
  final String gameId;

  /// Injected so a test can pin what the opponent plays. Null means a fresh
  /// unseeded source, which is what the app uses.
  final Random? random;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  StreamSubscription<GameDocument?>? _subscription;
  late final Random _random = widget.random ?? Random();
  GameDocument? _game;

  /// The computer-ladder rating either side of this game, computed once the
  /// game completes. Null while the game is running, or in pass-and-play.
  ({int before, int after})? _rating;

  /// True from the moment a move is dispatched until it has been stored and
  /// observed. It guards both directions:
  ///
  /// - the opponent's turn is noticed once, not on every stream re-emit;
  /// - a second tap landing before the first has round-tripped is ignored.
  ///   Without that, tapping twice quickly in a game against the computer
  ///   stores both moves and the player takes the opponent's turn too.
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Driving the opponent from the stream rather than from build() keeps the
    // side effect out of the widget lifecycle, where a rebuild for any reason
    // would trigger a second move.
    _subscription = widget.repository.watchGame(widget.gameId).listen(_onGame);
  }

  @override
  void didUpdateWidget(GameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Flutter reuses this State when the same widget type is rebuilt in the
    // same position, so a changed game id must re-point the subscription —
    // otherwise the screen keeps showing the game it was first given.
    if (oldWidget.gameId != widget.gameId) {
      _subscription?.cancel();
      _game = null;
      _rating = null;
      _busy = false;
      _subscription =
          widget.repository.watchGame(widget.gameId).listen(_onGame);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _onGame(GameDocument? game) {
    setState(() => _game = game);
    if (game == null) return;
    unawaited(_playOpponentIfItsTurn(game));
    if (game.status == GameStatus.complete &&
        game.mode == GameMode.vsComputer &&
        _rating == null) {
      unawaited(_loadRating());
    }
  }

  Future<void> _loadRating() async {
    final completed = await widget.repository.loadCompletedGames();
    if (!mounted) return;
    setState(() => _rating = computerRatingAround(completed, widget.gameId));
  }

  bool _isOpponentsTurn(GameDocument game) =>
      game.mode == GameMode.vsComputer &&
      game.status == GameStatus.active &&
      game.seatToMove != game.playerSeat;

  Future<void> _playOpponentIfItsTurn(GameDocument game) async {
    if (_busy || !_isOpponentsTurn(game)) return;
    final bot = botById(game.opponent.replaceFirst('bot:', ''));
    if (bot == null) return;

    setState(() => _busy = true);
    try {
      await Future<void>.delayed(kBotMoveDelay);
      if (!mounted) return;
      final move = chooseMove(GameState.fromMoves(game.moves), bot, _random);
      await widget.repository.appendMove(game.id, move.index);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _play(Cell cell) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.repository.appendMove(widget.gameId, cell.index);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Resigning ends the game as a loss for the resigner. There is deliberately
  /// no draw offer anywhere in the product — a player who wants out of a dead
  /// position resigns.
  Future<void> _resign(GameDocument game) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.resignConfirmTitle),
        content: Text(l10n.resignConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.resign),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    // Against the computer the player resigns whoever is to move; sharing a
    // device, it is the side whose turn it is that gives up.
    final seat = game.mode == GameMode.vsComputer
        ? game.playerSeat
        : game.seatToMove;
    await widget.repository.resign(game.id, seat: seat);
  }

  /// A rematch alternates the start, which is what keeps a series fair given
  /// the first player's advantage, and records the game it followed.
  Future<void> _rematch(GameDocument game) async {
    final next = await widget.repository.createGame(
      mode: game.mode,
      opponent: game.opponent,
      opponentRating: game.opponentRating,
      playerSeat: game.playerSeat,
      startingSeat: (game.startingSeat + 1) % 2,
      startReason: StartReason.rematchAlternation,
      rematchOf: game.id,
    );
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(
          repository: widget.repository,
          gameId: next.id,
          random: widget.random,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final game = _game;
    return Scaffold(
      appBar: AppBar(
        title: Text(game != null && game.mode == GameMode.vsComputer
            ? botName(l10n, game.opponent)
            : l10n.passAndPlay),
        actions: [
          if (game != null && game.status == GameStatus.active)
            TextButton(
              onPressed: () => _resign(game),
              child: Text(l10n.resign),
            ),
        ],
      ),
      body: SafeArea(
        child: game == null
            ? const SizedBox.shrink()
            : _GameBody(
                game: game,
                rating: _rating,
                // Taps are the human's alone: a game against the computer
                // must not let the player move for it while it thinks.
                enabled: !_isOpponentsTurn(game),
                onCellTap: _play,
                onRematch: () => _rematch(game),
              ),
      ),
    );
  }
}

/// Bot names are never translated, but they still go through l10n so no
/// screen hardcodes a user-facing string (D132).
String botName(AppLocalizations l10n, String opponent) =>
    switch (opponent) { 'bot:pebble' => l10n.botPebble, _ => opponent };

class _GameBody extends StatelessWidget {
  const _GameBody({
    required this.game,
    required this.rating,
    required this.enabled,
    required this.onCellTap,
    required this.onRematch,
  });

  final GameDocument game;
  final ({int before, int after})? rating;
  final bool enabled;
  final void Function(Cell cell) onCellTap;
  final VoidCallback onRematch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // The board is replayed from the stored moves, never held alongside them.
    final state = GameState.fromMoves(game.moves);
    final o = outcome(state);
    // The record decides whether the game is over, not the board: a
    // resignation leaves a perfectly playable position behind.
    final over = game.status == GameStatus.complete;
    final highlight = o is Win ? o.line : const <int>[];
    final lightToMove = state.sideToMove == Player.first;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              _TurnBanner(
                text: _statusText(l10n, game, o, lightToMove),
                lightToMove: !over && lightToMove,
                over: over,
              ),
              const SizedBox(height: 2),
              Text(
                _firstMoveCaption(l10n, game),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        Expanded(
          // Right-aligned column of four layers (D137). No scroll view:
          // the board sizes itself to fit, so a scrollable would only
          // ever hide a layout bug.
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: BoardView(
                state: state,
                enabled: enabled && !over,
                onCellTap: onCellTap,
                highlight: highlight,
              ),
            ),
          ),
        ),
        // The result sits below the board rather than over it, so the four
        // highlighted cells of the winning line stay visible while the player
        // reads how it ended.
        if (over) _ResultPanel(game: game, rating: rating, onRematch: onRematch),
      ],
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.game,
    required this.rating,
    required this.onRematch,
  });

  final GameDocument game;
  final ({int before, int after})? rating;
  final VoidCallback onRematch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final vsComputer = game.mode == GameMode.vsComputer;
    final change = rating;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (vsComputer && change != null) ...[
              Text(
                l10n.computerRatingChange(
                  change.after,
                  _signed(change.after - change.before),
                ),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 2),
              // The two ladders are independent; this one never leaves the
              // device, and saying so is the point of the label.
              Text(
                l10n.computerRatingNote,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            if (!vsComputer)
              Text(
                l10n.passAndPlayNoRating,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: onRematch,
                    child: Text(l10n.rematch),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.backToHome),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "+12", "-8", "0" — the sign is part of the text rather than left to the
/// reader, because a bare number next to a rating reads as the rating.
String _signed(int delta) => delta > 0 ? '+$delta' : '$delta';

/// Who opens, and why. Shown for the whole game rather than only at move one,
/// because against a computer opponent that moves first the player would
/// otherwise never see it.
String _firstMoveCaption(AppLocalizations l10n, GameDocument game) {
  final who = switch (game.mode) {
    GameMode.vsComputer => game.startingSeat == game.playerSeat
        ? l10n.you
        : botName(l10n, game.opponent),
    // Sharing a device the seats are anonymous, so the colours name them.
    GameMode.passAndPlay => l10n.sideLight,
  };
  return switch (game.startReason) {
    StartReason.random => l10n.firstMoveRandom(who),
    StartReason.rematchAlternation => l10n.firstMoveAlternating(who),
  };
}

/// Against a person the seats are anonymous, so the light/dark colours name
/// the turn. Against the computer the player is one of the two seats, so the
/// text says whose turn it is by name instead.
String _statusText(
  AppLocalizations l10n,
  GameDocument game,
  Outcome o,
  bool lightToMove,
) {
  final vsComputer = game.mode == GameMode.vsComputer;
  return switch (o) {
    Draw() => l10n.gameDrawn,
    Win() when vsComputer => game.result?.winnerSeat == game.playerSeat
        ? l10n.youWin
        : l10n.youLose(botName(l10n, game.opponent)),
    Win(winner: Player.first) => l10n.lightWins,
    Win() => l10n.darkWins,
    Ongoing() when game.status == GameStatus.complete && vsComputer =>
      // Resignation: the board is still playable, so only the record knows.
      game.result?.winnerSeat == game.playerSeat
          ? l10n.youWin
          : l10n.youLose(botName(l10n, game.opponent)),
    // Light is whoever opened, which is startingSeat — not seat 0.
    Ongoing() when game.status == GameStatus.complete =>
      game.result?.winnerSeat == game.startingSeat
          ? l10n.lightWins
          : l10n.darkWins,
    Ongoing() when vsComputer => game.seatToMove == game.playerSeat
        ? l10n.yourTurn
        : l10n.botThinking(botName(l10n, game.opponent)),
    Ongoing() => lightToMove ? l10n.lightPlays : l10n.darkPlays,
  };
}

class _TurnBanner extends StatelessWidget {
  const _TurnBanner({
    required this.text,
    required this.lightToMove,
    required this.over,
  });

  final String text;
  final bool lightToMove;
  final bool over;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!over) ...[
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.35, -0.45),
                  colors: lightToMove
                      ? const [Color(0xFFFFFFFF), Color(0xFFC3C3C8)]
                      : const [Color(0xFF4A4A52), Color(0xFF050507)],
                ),
                border: Border.all(
                    color: theme.colorScheme.outline, width: 0.5),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              text,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
