import '../l10n/app_localizations.dart';

/// One page of the tutorial: what it says, and the position it says it over.
///
/// Data rather than a widget subclass per step, for the same reason the
/// opponents are data (spec §9.4): a step is a title, a paragraph and a
/// position, and twenty lines of catalogue beat seven near-identical classes.
class TutorialStep {
  const TutorialStep({
    required this.title,
    required this.body,
    this.moves = const [],
    this.line = const [],
    this.boardLabel = '',
    this.endsSection = false,
  });

  final String title;
  final String body;

  /// The move list the demonstration position is played out from, in order.
  /// Empty is legitimate: the steps about which squares are worth most
  /// highlight cells on an empty board, because the point is the geometry
  /// rather than any particular game.
  final List<int> moves;

  /// Cell indices to emphasise. Empty is legitimate too: the step about
  /// placing a piece has a position but nothing to point at.
  final List<int> line;

  /// What a screen reader says instead of the board.
  ///
  /// The board's own 64 cell nodes stay, but a demonstration board is silenced
  /// behind this one sentence: finding four highlighted cells by swiping
  /// through sixty-four is not comprehension, and the criterion is that every
  /// step *be comprehensible* by screen reader (D195).
  final String boardLabel;

  /// Whether the tutorial can honourably be finished here.
  ///
  /// Ticket 019 asks for the strategy half to be skippable by a player who
  /// only wants the rules, so the last rules step offers to finish as well as
  /// to carry on — and finishing there counts as finishing.
  final bool endsSection;

  bool get hasBoard => moves.isNotEmpty || line.isNotEmpty;
}

/// A line along an axis — the simplest possible win, all within layer 1.
const List<int> kGoalLine = [0, 1, 2, 3];

/// The same row and column in all four layers. Doubles as the axis example
/// and as the proof that the four drawn parallelograms are one solid.
const List<int> kThroughLayersLine = [5, 21, 37, 53];

/// A diagonal inside layer 2.
const List<int> kLayerDiagonalLine = [16, 21, 26, 31];

/// A diagonal through one vertical slice: row 1, column advancing with layer.
const List<int> kSliceDiagonalLine = [0, 17, 34, 51];

/// A body diagonal, corner of layer 1 to opposite corner of layer 4.
const List<int> kCubeDiagonalLine = [0, 21, 42, 63];

/// A position mid-game, used to explain taking a turn. Light holds 21 and 26,
/// dark holds 22 and 42, and it is light's move.
const List<int> kPlacingMoves = [21, 22, 26, 42];

/// The central 2x2x2: rows and columns 2 and 3 of layers 2 and 3.
///
/// These eight and the eight corners are the only cells on seven lines each;
/// every other cell is on four. That asymmetry is the whole of positional play
/// in Qubic, and it is what `centreBias` and `cornerBias` in the opponent
/// catalogue are weighting.
const List<int> kCentreCells = [21, 22, 25, 26, 37, 38, 41, 42];

/// The eight corners of the cube — the other cells on seven lines each.
const List<int> kCornerCells = [0, 3, 12, 15, 48, 51, 60, 63];

/// A position in which the first player has just created two threats at once.
///
/// Light holds 1, 2, 4 and 8 and has just played the corner 0, which completes
/// three of the row {0,1,2,3} and three of the column {0,4,8,12} in one move.
/// The two answers are 3 and 12, and the second player has only one turn. The
/// second player's four pieces are deliberately clear of both lines — a block
/// anywhere on either would make the position teach the opposite lesson.
const List<int> kDoubleThreatMoves = [1, 32, 2, 47, 4, 53, 8, 58, 0];

/// The two cells that win for the first player in [kDoubleThreatMoves].
const List<int> kDoubleThreatCells = [3, 12];

/// A position in which the second player is one move from a line and the first
/// player must answer. Dark holds row 1 of layer 2 bar its last cell; light's
/// three pieces are scattered and threaten nothing, so there is no competing
/// win to take instead.
const List<int> kBlockingMoves = [0, 16, 42, 17, 60, 18];

/// The cell light has to take in [kBlockingMoves].
const List<int> kBlockingCell = [19];

/// Cells the demonstrations park the second player's pieces on.
///
/// Scattered rather than adjacent: three dark pieces in a row beside the line
/// being taught read as a second, nearly-complete threat, which is exactly the
/// thing the step is not about. Three pieces can never complete a line, so no
/// choice here can end the game early — only distract.
const List<int> _fillers = [3, 48, 30, 12, 33, 60];

/// A legal move list ending with the first player completing [line].
///
/// Built as moves rather than as a hand-set board because that is the only
/// thing [GameState] accepts, and it is the better constraint: every position
/// the tutorial shows is one that could actually arise in a game. The second
/// player's pieces are filler — they exist because turns alternate, not
/// because they mean anything.
List<int> demoMoves(List<int> line) {
  final filler = _fillers.where((c) => !line.contains(c)).toList();
  // Only reachable if a caller passes a line that is itself mostly filler.
  // None of the five is, but this function is public and tickets 019 and 020
  // add positions; a RangeError three frames deep in a builder is a poor way
  // to find that out.
  assert(filler.length >= line.length - 1, 'filler pool exhausted by $line');
  final moves = <int>[];
  for (var i = 0; i < line.length; i++) {
    moves.add(line[i]);
    if (i < line.length - 1) moves.add(filler[i]);
  }
  return moves;
}

/// The tutorial, in order. Rebuilt per locale rather than held as a constant,
/// because every string on it comes from [AppLocalizations].
List<TutorialStep> tutorialSteps(AppLocalizations l10n) => [
      TutorialStep(
        title: l10n.tutorialGoalTitle,
        body: l10n.tutorialGoalBody,
        moves: demoMoves(kGoalLine),
        line: kGoalLine,
        boardLabel: l10n.tutorialGoalBoard,
      ),
      TutorialStep(
        title: l10n.tutorialLayersTitle,
        body: l10n.tutorialLayersBody,
        moves: demoMoves(kThroughLayersLine),
        line: kThroughLayersLine,
        boardLabel: l10n.tutorialLayersBoard,
      ),
      TutorialStep(
        title: l10n.tutorialPlacingTitle,
        body: l10n.tutorialPlacingBody,
        moves: kPlacingMoves,
        boardLabel: l10n.tutorialPlacingBoard,
      ),
      TutorialStep(
        title: l10n.tutorialLayerDiagonalTitle,
        body: l10n.tutorialLayerDiagonalBody,
        moves: demoMoves(kLayerDiagonalLine),
        line: kLayerDiagonalLine,
        boardLabel: l10n.tutorialLayerDiagonalBoard,
      ),
      TutorialStep(
        title: l10n.tutorialSliceDiagonalTitle,
        body: l10n.tutorialSliceDiagonalBody,
        moves: demoMoves(kSliceDiagonalLine),
        line: kSliceDiagonalLine,
        boardLabel: l10n.tutorialSliceDiagonalBoard,
      ),
      TutorialStep(
        title: l10n.tutorialCubeDiagonalTitle,
        body: l10n.tutorialCubeDiagonalBody,
        moves: demoMoves(kCubeDiagonalLine),
        line: kCubeDiagonalLine,
        boardLabel: l10n.tutorialCubeDiagonalBoard,
      ),
      TutorialStep(
        title: l10n.tutorialRulesDoneTitle,
        body: l10n.tutorialRulesDoneBody,
        endsSection: true,
      ),
      TutorialStep(
        title: l10n.tutorialCentreTitle,
        body: l10n.tutorialCentreBody,
        line: kCentreCells,
        boardLabel: l10n.tutorialCentreBoard,
      ),
      TutorialStep(
        title: l10n.tutorialCornersTitle,
        body: l10n.tutorialCornersBody,
        line: kCornerCells,
        boardLabel: l10n.tutorialCornersBoard,
      ),
      TutorialStep(
        title: l10n.tutorialDoubleThreatTitle,
        body: l10n.tutorialDoubleThreatBody,
        moves: kDoubleThreatMoves,
        line: kDoubleThreatCells,
        boardLabel: l10n.tutorialDoubleThreatBoard,
      ),
      TutorialStep(
        title: l10n.tutorialBlockingTitle,
        body: l10n.tutorialBlockingBody,
        moves: kBlockingMoves,
        line: kBlockingCell,
        boardLabel: l10n.tutorialBlockingBoard,
      ),
      TutorialStep(
        title: l10n.tutorialStrategyDoneTitle,
        body: l10n.tutorialStrategyDoneBody,
      ),
    ];
