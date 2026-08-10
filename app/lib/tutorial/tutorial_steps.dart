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
  });

  final String title;
  final String body;

  /// The move list the demonstration position is played out from, in order.
  /// Empty means this step shows no board.
  final List<int> moves;

  /// Cell indices to emphasise — the line being taught. Empty is legitimate:
  /// the step about placing a piece has a position but nothing to highlight.
  final List<int> line;

  /// What a screen reader says instead of the board.
  ///
  /// The board's own 64 cell nodes stay, but a demonstration board is silenced
  /// behind this one sentence: finding four highlighted cells by swiping
  /// through sixty-four is not comprehension, and the criterion is that every
  /// step *be comprehensible* by screen reader (D195).
  final String boardLabel;

  bool get hasBoard => moves.isNotEmpty;
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
      ),
    ];
