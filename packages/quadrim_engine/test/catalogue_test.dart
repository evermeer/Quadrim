import 'package:quadrim_engine/quadrim_engine.dart';
import 'package:test/test.dart';

/// The tiers of spec §8.5, written out rather than derived, so that this test
/// disagrees with the catalogue when either one moves. Deriving the expectation
/// from `opponentCatalogue` would make it agree with itself forever (D179).
///
/// Thirty-one since the roster was recut (D325): six rungs in each of the first
/// four tiers and seven in the last, so that the climb a beginner is actually
/// on has a step every forty points instead of every hundred.
const Map<String, BotTier> _tiers = {
  'pebble': BotTier.novice,
  'twig': BotTier.novice,
  'mote': BotTier.novice,
  'hazel': BotTier.novice,
  'clover': BotTier.novice,
  'sorrel': BotTier.novice,
  'bramble': BotTier.casual,
  'juniper': BotTier.casual,
  'bracken': BotTier.casual,
  'willow': BotTier.casual,
  'rowan': BotTier.casual,
  'aspen': BotTier.casual,
  'vireo': BotTier.club,
  'finch': BotTier.club,
  'kestrel': BotTier.club,
  'osprey': BotTier.club,
  'heron': BotTier.club,
  'marlin': BotTier.club,
  'lynx': BotTier.expert,
  'sable': BotTier.expert,
  'ember': BotTier.expert,
  'lyra': BotTier.expert,
  'onyx': BotTier.expert,
  'corvus': BotTier.expert,
  'basalt': BotTier.master,
  'cairn': BotTier.master,
  'flint': BotTier.master,
  'quartz': BotTier.master,
  'titan': BotTier.master,
  'oracle': BotTier.master,
  'quadrim_prime': BotTier.master,
};

void main() {
  test('the catalogue is the thirty-one opponents of the specification', () {
    expect(opponentCatalogue.length, 31);
    expect(
      opponentCatalogue.map((b) => b.id).toSet(),
      _tiers.keys.toSet(),
    );
  });

  test('every opponent is in the tier §8.5 puts it in', () {
    for (final bot in opponentCatalogue) {
      expect(bot.tier, _tiers[bot.id], reason: '${bot.id} is in the wrong tier');
    }
  });

  test('the tier counts are 6 / 6 / 6 / 6 / 7', () {
    // Named separately from the map above because the specification states the
    // shape of the ladder as well as its membership, and a pair of typos that
    // moved one opponent between tiers would satisfy the per-opponent check
    // if the map were the only source.
    const expected = {
      BotTier.novice: 6,
      BotTier.casual: 6,
      BotTier.club: 6,
      BotTier.expert: 6,
      BotTier.master: 7,
    };
    for (final tier in BotTier.values) {
      expect(
        opponentCatalogue.where((b) => b.tier == tier).length,
        expected[tier],
        reason: 'wrong number of opponents in $tier',
      );
    }
  });

  test('the catalogue is ordered weakest first, and tiers do not interleave',
      () {
    // Ticket 011 renders the list in catalogue order, grouped by tier. Both
    // properties have to hold in the data for that screen to be a plain
    // traversal rather than a sort.
    for (var i = 1; i < opponentCatalogue.length; i++) {
      expect(
        opponentCatalogue[i].rating,
        greaterThan(opponentCatalogue[i - 1].rating),
        reason: '${opponentCatalogue[i].id} does not follow '
            '${opponentCatalogue[i - 1].id} in strength',
      );
    }
    final order = opponentCatalogue.map((b) => b.tier.index).toList();
    expect(order, orderedEquals(List.of(order)..sort()));
  });

  test('only the Master tier plays from the book', () {
    // The dictionary proves a first-player win; an opponent holding it cannot
    // be beaten when it opens. That belongs to the top of the ladder and
    // nowhere else, or the tiers below stop being winnable (D180).
    for (final bot in opponentCatalogue) {
      if (bot.usesBook) {
        expect(bot.tier, BotTier.master, reason: '${bot.id} may not use it');
      }
    }
    expect(opponentCatalogue.where((b) => b.usesBook).length, 2);
  });
}
