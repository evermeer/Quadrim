import 'package:flutter/material.dart';
import 'package:quadrim_engine/quadrim_engine.dart';

import '../l10n/app_localizations.dart';
import 'board_view.dart';

/// Pass-and-play: two humans, one device (ticket 004). The first player
/// always holds the light pieces. Bot play arrives with ticket 006 and the
/// full result screen with ticket 007 — here a game ends with an announced
/// banner and a back button.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  GameState _state = GameState.initial();

  void _onCellTap(Cell cell) {
    setState(() {
      _state = applyMove(_state, cell);
    });
    // The turn banner is a Semantics live region: screen readers announce
    // every text change there (turn, win, draw) without an explicit call.
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final o = outcome(_state);
    final over = o is! Ongoing;
    final highlight = o is Win ? o.line : const <int>[];

    final statusText = switch (o) {
      Win(winner: Player.first) => l10n.lightWins,
      Win() => l10n.darkWins,
      Draw() => l10n.gameDrawn,
      Ongoing() => _state.sideToMove == Player.first
          ? l10n.lightPlays
          : l10n.darkPlays,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.passAndPlay)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: _TurnBanner(
                text: statusText,
                lightToMove: !over && _state.sideToMove == Player.first,
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
                    state: _state,
                    enabled: !over,
                    onCellTap: _onCellTap,
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
        ),
      ),
    );
  }
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
