import 'documents.dart';
// Both prefixed, and neither prefix may be the field's name: the summary has a
// `points` field and a `computerRating` field, and an import prefix that
// collides with either shadows it at exactly the line that sets it.
import 'points_fold.dart' as points_fold;
import 'rating_fold.dart' as fold;

/// Everything the main screen says about finished games, derived from **one**
/// list of them (ticket 013, criterion 18).
///
/// Statistics are never stored (spec §7.2). A stored total is a second copy of
/// something the games already say, and the two drift the first time a game is
/// deleted or a schema changes. The cost is a fold on every change; the fold
/// is over a list already in memory, so that cost is nothing.
///
/// Ticket 023's per-opponent milestones and ticket 027's rating display are
/// further readings of this same list, and belong here rather than in a fifth
/// sweep of storage.
class HomeSummary {
  const HomeSummary({
    required this.wins,
    required this.losses,
    required this.draws,
    required this.computerRating,
    required this.points,
    required this.byOpponent,
  });

  /// Against a computer opponent only.
  ///
  /// Pass-and-play is deliberately excluded (D157): the player holds both
  /// seats, so a win there is also a loss and counting it would make every
  /// total meaningless. Those games still appear in the lists.
  final int wins;
  final int losses;
  final int draws;

  /// The player's live rating on the computer ladder, folded from the same
  /// list rather than read from anywhere.
  final int computerRating;

  /// What the player has earned and can spend, folded from the same list.
  ///
  /// Never stored, for the same reason the rating is not (spec §8.8). Unlike
  /// the rating it needs no stored anchor: a win pays by the opponent's
  /// position in the roster, and an ordinal is not something a recalibration
  /// moves. From ticket 032 the *balance* is this minus what has been spent;
  /// until unlocks exist the two are the same number.
  final int points;

  /// One record per computer opponent ever played, weakest first.
  final List<OpponentRecord> byOpponent;

  int get played => wins + losses + draws;

  /// The record against one catalogue id, or null if never played.
  ///
  /// Null rather than an empty record, because "never faced" and "faced and
  /// never won" are different things and the interface must not show them the
  /// same way — an opponent never played shows no star row at all.
  OpponentRecord? recordFor(String botId) {
    final key = botOpponent(botId);
    for (final record in byOpponent) {
      if (record.opponent == key) return record;
    }
    return null;
  }

  static final HomeSummary empty = HomeSummary.from(const []);

  factory HomeSummary.from(List<GameDocument> completed) {
    var wins = 0;
    var losses = 0;
    var draws = 0;
    // Keyed by opponent so a rating change to an opponent later cannot split
    // one opponent's history into two rows.
    final records = <String, _Tally>{};

    for (final game in completed) {
      if (game.mode != GameMode.vsComputer) continue;
      final result = game.result;
      if (result == null) continue;

      final tally = records.putIfAbsent(
          game.opponent, () => _Tally(game.opponentRating));
      // The rating an opponent is shown at is the most recent one played
      // against, which is what a recalibration should move the list by.
      tally.rating = game.opponentRating ?? tally.rating;

      if (result.outcome == GameOutcome.draw) {
        draws++;
        tally.draws++;
      } else if (result.winnerSeat == game.playerSeat) {
        wins++;
        tally.wins++;
      } else {
        losses++;
        tally.losses++;
      }
    }

    final byOpponent = [
      for (final entry in records.entries)
        OpponentRecord(
          opponent: entry.key,
          rating: entry.value.rating,
          wins: entry.value.wins,
          losses: entry.value.losses,
          draws: entry.value.draws,
        ),
    ]..sort(_weakestFirst);

    return HomeSummary(
      wins: wins,
      losses: losses,
      draws: draws,
      computerRating: fold.computerRating(completed),
      points: points_fold.pointsFrom(completed),
      byOpponent: List.unmodifiable(byOpponent),
    );
  }
}

/// Weakest first, so the breakdown reads as the ladder it is. An opponent
/// whose rating is not stored sorts last rather than at zero — an unknown
/// number is not a weak one.
int _weakestFirst(OpponentRecord a, OpponentRecord b) {
  final ra = a.rating;
  final rb = b.rating;
  if (ra == null && rb == null) return a.opponent.compareTo(b.opponent);
  if (ra == null) return 1;
  if (rb == null) return -1;
  final byRating = ra.compareTo(rb);
  return byRating != 0 ? byRating : a.opponent.compareTo(b.opponent);
}

/// The player's record against one opponent.
class OpponentRecord {
  const OpponentRecord({
    required this.opponent,
    required this.rating,
    required this.wins,
    required this.losses,
    required this.draws,
  });

  /// The stored opponent key, `bot:<id>`.
  final String opponent;

  /// The anchor rating of the most recent game against it, or null if that
  /// game did not record one.
  final int? rating;

  final int wins;
  final int losses;
  final int draws;

  int get played => wins + losses + draws;

  /// What ticket 023's milestones are built on.
  bool get everBeaten => wins > 0;
}

class _Tally {
  _Tally(this.rating);
  int? rating;
  int wins = 0;
  int losses = 0;
  int draws = 0;
}
