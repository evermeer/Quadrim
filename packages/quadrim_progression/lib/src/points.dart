import 'package:quadrim_engine/quadrim_engine.dart';

/// What a player has earned, and what the ladder costs.
///
/// Everything here is keyed on the **roster index** — an opponent's ordinal
/// position in [opponentCatalogue] — and never on its rating. Spec §7.1 is
/// explicit that the two must not be conflated, and the Casual-tier inversion
/// (idea-v3.md §14) is what happens when they are: three consecutive rungs
/// whose measured strength runs the opposite way to their published ratings.
/// Prices follow the ordinal, so they stay monotonic whatever measurement says.

/// A win against roster index `i` pays `2^i`.
///
/// Doubling is what makes grinding downward self-pricing: every rung down
/// halves the payout, so unlocking Quadrim Prime by beating Pebble would take
/// 2,147,483,648 games. That is why no anti-farming rule exists anywhere in this
/// package — the exponent does the work (idea-v3.md §7.3).
int winValue(int rosterIndex) {
  _checkIndex(rosterIndex);
  return 1 << rosterIndex;
}

/// Unlocking roster index `i` costs `2^(i+1)` — exactly four wins against
/// opponent `i - 1`.
///
/// That equality is the promise the interface makes, and it is exact rather
/// than approximate only because draws and losses pay nothing (§7.2).
int unlockCost(int rosterIndex) {
  _checkIndex(rosterIndex);
  return 1 << (rosterIndex + 1);
}

/// Opponents at or below this rating are available from first launch.
///
/// The free set is defined by **this threshold, not by a count**. If a future
/// roster revision changes the ratings the free set changes with it, and
/// nothing anywhere has to be kept in step with the word "five" (D228).
const int kFreeRatingCeiling = 1000;

/// Whether [bot] is playable without being earned.
bool isFree(BotConfig bot) => bot.rating <= kFreeRatingCeiling;

/// The roster index of [botId], or null if this build has no such opponent.
///
/// Null rather than throwing: a stored game can name an opponent a later build
/// removed, and a history that cannot be folded is worse than one whose oldest
/// games pay nothing.
int? rosterIndexOf(String botId) {
  final i = opponentCatalogue.indexWhere((bot) => bot.id == botId);
  return i < 0 ? null : i;
}

/// What every locked opponent costs together: 4,294,967,040 points, which is
/// exactly ninety-six wins.
///
/// Ninety-six is the number to reason about; the point totals are display —
/// four wins at each of the twenty-four locked rungs. Both numbers grew with
/// the roster (D325): the doubling is per rung, so eleven new rungs multiply
/// the top of the ladder by two thousand and leave the *experience* of it
/// unchanged, because what a player feels is the four wins, not the total.
int get fullRosterCost => [
  for (var i = 0; i < opponentCatalogue.length; i++)
    if (!isFree(opponentCatalogue[i])) unlockCost(i),
].fold(0, (a, b) => a + b);

/// One completed game, reduced to what progression cares about.
///
/// Deliberately not the app's document type: this package may not know what a
/// document is. The app maps its stored games onto this, the same way it maps
/// them onto `RatedGame` for the rating fold.
class ScoredGame {
  const ScoredGame({
    required this.rosterIndex,
    required this.won,
    required this.movedSecond,
    required this.completedAt,
  });

  /// The opponent's ordinal position in the catalogue.
  final int rosterIndex;

  /// Whether the player won. Draws and losses are false and pay nothing.
  final bool won;

  /// Whether the player was the **second** to move, which one quest family
  /// asks for. Already on every stored game as the two seat fields, so it
  /// costs nothing to carry (spec §7.4).
  final bool movedSecond;

  /// When it finished, **in local time**, or null if the record has no
  /// completion time. Converting to local is the app's job: this package may
  /// not read a clock and may not guess a zone either (spec §9.2).
  ///
  /// Required rather than defaulted, though only the quest fold reads it. A
  /// default would let the app forget to map it and the day-counting family
  /// would silently never fire — the compiler is cheaper than that test.
  final DateTime? completedAt;
}

/// Points earned: a fold over the games and **nothing else**.
///
/// No unlock record is consulted, and that is a property worth protecting
/// rather than an accident. It holds because §7.4 prices every quest by the
/// opponents it was earned against rather than by how high the player has
/// climbed. Under the rejected rule an award depended on which opponents were
/// unlocked at the moment it fired, so this fold would have had to interleave
/// games with unlock records in time order — two streams, an ordering hazard on
/// each, and a total that could not be checked against the game list alone
/// (D265, superseded by D270).
int pointsEarned(Iterable<ScoredGame> games) {
  var total = 0;
  for (final game in games) {
    if (game.won) total += winValue(game.rosterIndex);
  }
  return total;
}

void _checkIndex(int rosterIndex) {
  assert(
    rosterIndex >= 0 && rosterIndex < opponentCatalogue.length,
    'roster index $rosterIndex is outside the catalogue of '
    '${opponentCatalogue.length}; prices are keyed on the ordinal, not the '
    'rating, so an index from anywhere else is a bug rather than a new price',
  );
}
