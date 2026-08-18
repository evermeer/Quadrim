import 'package:quadrim_engine/quadrim_engine.dart';

/// What a player has earned, and what the ladder costs.
///
/// Everything here is keyed on the **roster index** — an opponent's ordinal
/// position in [opponentCatalogue] — and never on its rating. Spec §7.1 is
/// explicit that the two must not be conflated, and the Casual-tier inversion
/// (idea-v3.md §14) is what happens when they are: three consecutive rungs
/// whose measured strength runs the opposite way to their published ratings.
/// Prices follow the ordinal, so they stay monotonic whatever measurement says.

/// The payout ladder: 1, 2, 3, 5, 8, 13, 21 … each rung the sum of the two
/// below it.
///
/// **Fibonacci rather than powers of two** (D327). Doubling put the top of a
/// thirty-one rung ladder at 2,147,483,648 points and the whole roster at four
/// billion, which is a number no interface can make mean anything. Growing by
/// the golden ratio instead puts the top at 4,356,618 and the roster at
/// 11,405,706 — still large, and *readable* large.
///
/// Built once rather than computed per call, because it is read inside folds
/// over the whole history.
final List<int> _payouts = List.unmodifiable(_ladder(opponentCatalogue.length));

List<int> _ladder(int rungs) {
  if (rungs <= 0) return const [];
  final values = <int>[1, 2];
  while (values.length < rungs) {
    values.add(values[values.length - 1] + values[values.length - 2]);
  }
  return values.sublist(0, rungs);
}

/// A win against roster index `i` pays the `i`th rung of the payout ladder.
///
/// The ladder is what makes grinding downward self-pricing: every rung down
/// divides the payout by the golden ratio, so unlocking Quadrim Prime by
/// beating Pebble would take 4,356,618 games. That is why no anti-farming rule
/// exists anywhere in this package — the sequence does the work
/// (idea-v3.md §7.3).
///
/// It does the work less *steeply* than doubling did: a rung down used to cost
/// a factor of two and now costs 1.618. Over thirty rungs that is still four
/// million games, so the property holds; over one or two rungs the pressure to
/// play the strongest opponent you can beat is milder than it was, which is a
/// deliberate softening rather than an oversight (D327).
int winValue(int rosterIndex) {
  _checkIndex(rosterIndex);
  return _payouts[rosterIndex];
}

/// Unlocking roster index `i` costs twice what a win against `i` pays: 2, 4, 6,
/// 10, 16, 26 … each price the sum of the two before it.
///
/// **The same relationship the doubling ladder had** — it too priced a rung at
/// twice its own win — so the shape of the economy is unchanged and only its
/// steepness moved (D327). What did change is the promise: an unlock used to be
/// *exactly* four wins against the rung below, and is now about 3¼, settling on
/// twice the golden ratio. Exactness went with the powers of two, and it is not
/// missed: a player counts games, and three or four is the same sentence.
int unlockCost(int rosterIndex) {
  _checkIndex(rosterIndex);
  return 2 * _payouts[rosterIndex];
}

/// How many opponents are playable without being earned.
///
/// **A count, and this reverses D228**, which made the free set a rating
/// threshold precisely so that nothing would have to be kept in step with a
/// number written in words. The threshold did what it promised: recutting the
/// roster (D325) moved the free set from five opponents to seven without anyone
/// choosing that. Being handed seven of thirty-one before earning anything is
/// too many, and the honest fix is to say how many rather than to tune a
/// rating until it happens to mean six (D327).
///
/// Six is the Novice tier exactly, which is what makes it a number worth
/// naming: what is free is *the tier a new player starts in*, and Bramble at
/// 980 is the first thing they buy.
const int kFreeCount = 6;

/// Whether [bot] is playable without being earned.
///
/// An opponent this build has never heard of is not free — the same answer
/// [rosterIndexOf] gives it everywhere else, and the safe one.
bool isFree(BotConfig bot) {
  final index = rosterIndexOf(bot.id);
  return index != null && index < kFreeCount;
}

/// The roster index of [botId], or null if this build has no such opponent.
///
/// Null rather than throwing: a stored game can name an opponent a later build
/// removed, and a history that cannot be folded is worse than one whose oldest
/// games pay nothing.
int? rosterIndexOf(String botId) {
  final i = opponentCatalogue.indexWhere((bot) => bot.id == botId);
  return i < 0 ? null : i;
}

/// What every locked opponent costs together: 11,405,706 points.
///
/// Roughly eighty wins spread across the twenty-five locked rungs — a little
/// over three at each — where the doubling ladder charged four at each and
/// totalled four billion. The per-rung number is what a player experiences and
/// it barely moved; the total is display, and it became a number that fits on
/// a phone (D327).
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
