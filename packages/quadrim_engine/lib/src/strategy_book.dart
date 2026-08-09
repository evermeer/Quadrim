/// Patashnik's strategy dictionary, as a lookup.
///
/// Qubic is a **first-player win**, proved by Oren Patashnik in 1980 by
/// exhibiting the 2929 strategic moves this book holds. Following them from the
/// opening, the first player cannot be beaten — and needs no search to do it,
/// because the book answers directly.
///
/// Two things it is not:
///
/// * It is not a full solution. The book runs to sixteen pieces; past that the
///   dictionary's own header says a forced win "must exist", and finding it is
///   the forcing search's job. Book, then forcing search, in that order.
/// * It is not play for the **second** player. There is no perfect second-player
///   play in Qubic — the game is won for the first player — so an opponent
///   playing second falls back to searching like any other (D172).
///
/// See `third_party/patashnik/NOTICE.md` for provenance and terms.
library;

import 'engine.dart';
import 'strategy_book.g.dart';
import 'symmetry.dart';

/// The strategic move for [me] in [state], or null when the position is not in
/// the book.
///
/// Null is the normal case, not a failure: the book covers the openings that
/// matter and hands over to the forcing search once it runs out.
Cell? bookMove(GameState state, Player me) {
  // The book is first-player play, and only from a position where the first
  // player is to move. Everything else is somebody else's question.
  if (me != Player.first || state.sideToMove != me) return null;
  if (state.moves.length > deepestBookPly) return null;
  if (outcome(state) is! Ongoing) return null;

  // Everything above is a cheap rejection, because this is not: canonicalising
  // walks all 192 automorphisms and builds a string for each. A book opponent
  // asks on every move of every game, and all but the first few are misses by
  // construction.
  final form = canonicalise(state);
  final index = _byBoard[form.key];
  if (index == null) return null;
  return form.cellFromCanonical(bookMoves[index]);
}

/// How many positions the book holds. Reported by tests, not used to play.
int get bookSize => bookMoves.length;

/// The most pieces any position in the dictionary has. Past this the book
/// cannot hold an answer, so the lookup does not go looking for one.
///
/// Asserted against the generated table rather than trusted, because a refresh
/// of the dictionary could deepen it and a stale constant here would silently
/// stop answering.
const int deepestBookPly = 16;

/// Built once, on first use: splitting a 190 KB string is not work to do at
/// startup for a player who never faces the opponent that needs it.
final Map<String, int> _byBoard = () {
  final map = <String, int>{};
  for (var i = 0; i < bookMoves.length; i++) {
    final start = i * bookBoardLength;
    map[bookBoards.substring(start, start + bookBoardLength)] = i;
  }
  return map;
}();
