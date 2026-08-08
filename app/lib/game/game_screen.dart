import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:quadrim_engine/quadrim_engine.dart';

import '../data/documents.dart';
import '../data/game_repository.dart';
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
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _onGame(GameDocument? game) {
    setState(() => _game = game);
    if (game != null) unawaited(_playOpponentIfItsTurn(game));
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final game = _game;
    return Scaffold(
      appBar: AppBar(
        title: Text(game != null && game.mode == GameMode.vsComputer
            ? botName(l10n, game.opponent)
            : l10n.passAndPlay),
      ),
      body: SafeArea(
        child: game == null
            ? const SizedBox.shrink()
            : _GameBody(
                game: game,
                // Taps are the human's alone: a game against the computer
                // must not let the player move for it while it thinks.
                enabled: !_isOpponentsTurn(game),
                onCellTap: _play,
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
    required this.enabled,
    required this.onCellTap,
  });

  final GameDocument game;
  final bool enabled;
  final void Function(Cell cell) onCellTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // The board is replayed from the stored moves, never held alongside them.
    final state = GameState.fromMoves(game.moves);
    final o = outcome(state);
    final over = o is! Ongoing;
    final highlight = o is Win ? o.line : const <int>[];
    final lightToMove = state.sideToMove == Player.first;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: _TurnBanner(
            text: _statusText(l10n, game, o, lightToMove),
            lightToMove: !over && lightToMove,
            over: over,
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
        if (over)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.backToHome),
              ),
            ),
          ),
      ],
    );
  }
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
