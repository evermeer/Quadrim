/// The rules of Quadrim as pure, deterministic functions (spec 7.1).
///
/// Everything here is derivable from a move list. No clocks, no randomness,
/// no I/O — the same inputs always produce the same outputs, which is what
/// lets the identical code run in tests, in the app, and in the self-play
/// calibration harness.
library;

import 'winning_lines.g.dart';

/// A board position, addressed either by canonical index `0..63` or by
/// coordinates `(x, y, z)` with each in `0..3`. Index = x + 4y + 16z.
extension type const Cell(int index) {
  Cell.xyz(int x, int y, int z)
      : assert(x >= 0 && x < 4 && y >= 0 && y < 4 && z >= 0 && z < 4),
        index = x + 4 * y + 16 * z;

  int get x => index & 3;
  int get y => (index >> 2) & 3;
  int get z => (index >> 4) & 3;

  bool get isValid => index >= 0 && index < 64;
}

/// Which side. [first] is whoever made the first move of the game; players
/// strictly alternate, so the mover of move `i` is `Player.values[i % 2]`.
enum Player {
  first,
  second;

  Player get opponent => this == first ? second : first;
}

/// Lines through each cell, derived once from the generated table so that
/// per-move win checks scan at most 7 lines instead of 76.
final List<List<List<int>>> _linesThroughCell = () {
  final byCell = List.generate(64, (_) => <List<int>>[]);
  for (final line in winningLines) {
    for (final c in line) {
      byCell[c].add(line);
    }
  }
  return [
    for (final lines in byCell) List<List<int>>.unmodifiable(lines),
  ];
}();

/// The result of a finished or ongoing game.
sealed class Outcome {
  const Outcome();
}

final class Ongoing extends Outcome {
  const Ongoing();
}

final class Draw extends Outcome {
  const Draw();
}

final class Win extends Outcome {
  const Win(this.winner, this.line);

  final Player winner;

  /// The four cell indices of the completed line, sorted ascending — the
  /// board highlights exactly these at the end of a game (spec 7.8).
  final List<int> line;
}

/// An immutable position: the moves played so far, in order, plus the win
/// state that placement produced. Construct via [GameState.initial] or
/// [GameState.fromMoves]; advance via [applyMove].
final class GameState {
  GameState._(this._moves, this._board, this._win);

  /// The empty board.
  factory GameState.initial() =>
      GameState._(const [], List<Player?>.filled(64, null), null);

  /// Replays [moves] from the empty board, validating every placement.
  /// Throws [ArgumentError] on the first illegal move.
  factory GameState.fromMoves(Iterable<int> moves) {
    var state = GameState.initial();
    for (final m in moves) {
      state = applyMove(state, Cell(m));
    }
    return state;
  }

  final List<int> _moves;
  final List<Player?> _board;
  final Win? _win;

  /// The moves played so far, oldest first, as canonical cell indices.
  List<int> get moves => List.unmodifiable(_moves);

  /// Who occupies [cell], or null if it is empty.
  Player? owner(Cell cell) => _board[cell.index];

  /// Whose turn it is. Meaningless once the game is over.
  Player get sideToMove => Player.values[_moves.length % 2];

  bool get isOver => _win != null || _moves.length == 64;
}

/// Every empty cell — placement is never restricted beyond emptiness
/// (idea-v1 2.4).
List<Cell> legalMoves(GameState state) {
  if (state._win != null) return const [];
  return [
    for (var i = 0; i < 64; i++)
      if (state._board[i] == null) Cell(i),
  ];
}

/// Returns the position after the side to move places on [cell].
/// Throws [ArgumentError] if the cell is out of range or occupied, or
/// [StateError] if the game is already over. Never mutates [state].
GameState applyMove(GameState state, Cell cell) {
  if (state.isOver) {
    throw StateError('game is over');
  }
  if (!cell.isValid) {
    throw ArgumentError.value(cell.index, 'cell', 'out of range');
  }
  if (state._board[cell.index] != null) {
    throw ArgumentError.value(cell.index, 'cell', 'occupied');
  }

  final mover = state.sideToMove;
  final board = [...state._board]..[cell.index] = mover;

  Win? win;
  for (final line in _linesThroughCell[cell.index]) {
    if (line.every((c) => board[c] == mover)) {
      win = Win(mover, line);
      break;
    }
  }

  return GameState._([...state._moves, cell.index], board, win);
}

/// Ongoing, draw, or a win naming both the winner and the completed line.
Outcome outcome(GameState state) {
  final win = state._win;
  if (win != null) return win;
  if (state._moves.length == 64) return const Draw();
  return const Ongoing();
}

/// A line one move away from winning: three cells of [Threat.player], one
/// empty. The primitive behind the bots' rule ladder and the tutorial's
/// hints (tickets 008, 020).
final class Threat {
  const Threat(this.player, this.line, this.emptyCell);

  final Player player;
  final List<int> line;
  final Cell emptyCell;
}

/// All lines where [player] has exactly three pieces and the fourth cell is
/// empty. Playing [Threat.emptyCell] wins for [player]; leaving it open
/// loses to them.
List<Threat> threats(GameState state, Player player) {
  final result = <Threat>[];
  for (final line in winningLines) {
    int owned = 0;
    int empty = -1;
    var blocked = false;
    for (final c in line) {
      final o = state._board[c];
      if (o == player) {
        owned++;
      } else if (o == null) {
        if (empty != -1) {
          blocked = true; // two empties: not a threat yet
          break;
        }
        empty = c;
      } else {
        blocked = true; // opponent piece: line is dead for player
        break;
      }
    }
    if (!blocked && owned == 3 && empty != -1) {
      result.add(Threat(player, line, Cell(empty)));
    }
  }
  return result;
}
