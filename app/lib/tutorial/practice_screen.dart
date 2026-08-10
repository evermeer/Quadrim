import 'dart:math';

import 'package:flutter/material.dart';
import 'package:quadrim_engine/quadrim_engine.dart';

import '../data/documents.dart';
import '../game/board_view.dart';
import '../game/opponent_name.dart';
import '../l10n/app_localizations.dart';
import 'practice_hint.dart';

/// The seed the practice opponent plays from.
///
/// Fixed so that the tutorial is the same tutorial for everyone: two players
/// comparing notes are talking about the same game, and a test that plays it
/// through gets the same replies every run. [Random] is injected rather than
/// ambient for the same reason it is in the engine.
const int kPracticeSeed = 20;

/// The opponent the tutorial hands the player.
///
/// Mote, unchanged from the catalogue: it takes a win and blocks one, and
/// blunders two moves in five. That is beatable by someone who has just been
/// shown the double threat, and not beatable by accident. It is a
/// [BotConfig], not a script — the ticket asks for a configuration rather than
/// a second code path, so what the player practises against is a real
/// opponent playing by the rules the tutorial just explained.
const BotConfig kPracticeOpponent = mote;

/// A real game that is never written down.
///
/// The position lives in this widget's state and nowhere else: there is no
/// repository here to hand it to. That is what keeps the practice game out of
/// the statistics, the rating and the finished-games list without adding a
/// mode that every later reader of [GameDocument] would have to filter (D200).
class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key, this.random});

  /// Injected so a test can pin the opponent's replies. Null means the fixed
  /// [kPracticeSeed], which is itself deterministic — this exists so a test can
  /// choose a *different* game, not so production can be random.
  final Random? random;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  /// How long the opponent appears to think. Long enough that its reply reads
  /// as an answer to the player's move rather than part of it.
  static const _replyDelay = Duration(milliseconds: 400);

  late final Random _random = widget.random ?? Random(kPracticeSeed);

  GameState _state = GameState.initial();
  Hint? _hint;
  bool _thinking = false;

  /// The player opens, because the tutorial has just said light goes first.
  static const _player = Player.first;

  bool get _playerToMove =>
      !_state.isOver && !_thinking && _state.sideToMove == _player;

  Future<void> _play(Cell cell) async {
    if (!_playerToMove) return;
    setState(() {
      _state = applyMove(_state, cell);
      // The hint described the position before this move, so it stops being
      // true the moment the move is made. Playing something a hint did not
      // suggest is allowed; leaving the old advice on screen is not.
      _hint = null;
    });
    if (_state.isOver) return;

    setState(() => _thinking = true);
    await Future<void>.delayed(_replyDelay);
    if (!mounted) return;
    setState(() {
      _state = applyMove(_state, chooseMove(_state, kPracticeOpponent, _random));
      _thinking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final opponentName = botName(l10n, botOpponent(kPracticeOpponent.id));
    final result = outcome(_state);

    final status = switch (result) {
      Win(winner: final w) =>
        w == _player ? l10n.youWin : l10n.youLose(opponentName),
      Draw() => l10n.gameDrawn,
      _ => _thinking ? l10n.botThinking(opponentName) : l10n.yourTurn,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.practiceTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: l10n.practiceLeave,
          // false: left, not finished. The tutorial stays where it was, and
          // the player can still finish it from the last step.
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Semantics(
                      liveRegion: true,
                      child: Text(status, style: theme.textTheme.titleMedium),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // A permanently reserved line, so asking for a hint does not
                  // resize the board underneath the player's finger.
                  //
                  // The live region is attached only when there is something
                  // to say. Wrapping the empty placeholder too puts an
                  // unlabelled focus stop between the status line and the
                  // board, which a screen reader lands on and reads as
                  // nothing — verified, not assumed (D201).
                  SizedBox(
                    width: double.infinity,
                    child: _hint == null
                        ? Text('', style: theme.textTheme.bodyMedium)
                        : Semantics(
                            liveRegion: true,
                            child: Text(
                              _hintText(l10n, _hint!),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: BoardView(
                  state: _state,
                  enabled: _playerToMove,
                  onCellTap: _play,
                  // The hint while there is one, the winning line once the
                  // game is decided. Never both: they would mean different
                  // things in the same colour.
                  highlight: _hint != null
                      ? [_hint!.cell.index]
                      : switch (result) {
                          Win(line: final l) => l,
                          _ => const <int>[],
                        },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: _state.isOver
                  ? SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(l10n.practiceFinish),
                      ),
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        // Nothing shows until it is asked for: a player who
                        // wants to work it out alone simply never presses this.
                        onPressed: _playerToMove
                            ? () => setState(
                                () => _hint = hintFor(_state, _player))
                            : null,
                        icon: const Icon(Icons.lightbulb_outline),
                        label: Text(l10n.practiceHint),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

String _hintText(AppLocalizations l10n, Hint hint) {
  final layer = hint.cell.z + 1;
  final row = hint.cell.y + 1;
  final column = hint.cell.x + 1;
  final where = l10n.practiceHintWhere(layer, row, column);
  return switch (hint.kind) {
    HintKind.win => l10n.practiceHintWin(where),
    HintKind.block => l10n.practiceHintBlock(where),
    HintKind.fork => l10n.practiceHintFork(where),
    HintKind.build => l10n.practiceHintBuild(where),
  };
}
