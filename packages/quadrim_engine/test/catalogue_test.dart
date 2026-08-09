import 'package:quadrim_engine/quadrim_engine.dart';
import 'package:test/test.dart';

/// The tiers of spec §8.5, written out rather than derived, so that this test
/// disagrees with the catalogue when either one moves. Deriving the expectation
/// from `opponentCatalogue` would make it agree with itself forever (D179).
const Map<String, BotTier> _tiers = {
  'pebble': BotTier.novice,
  'twig': BotTier.novice,
  'mote': BotTier.novice,
  'clover': BotTier.novice,
  'bramble': BotTier.casual,
  'finch': BotTier.casual,
  'kestrel': BotTier.casual,
  'willow': BotTier.casual,
  'ember': BotTier.casual,
  'basalt': BotTier.club,
  'marlin': BotTier.club,
  'vireo': BotTier.club,
  'onyx': BotTier.club,
  'sable': BotTier.club,
  'quartz': BotTier.expert,
  'corvus': BotTier.expert,
  'lyra': BotTier.expert,
  'titan': BotTier.expert,
  'oracle': BotTier.master,
  'quadrim_prime': BotTier.master,
};

void main() {
  test('the catalogue is the twenty opponents of the specification', () {
    expect(opponentCatalogue.length, 20);
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

  test('the tier counts are 4 / 5 / 5 / 4 / 2', () {
    // Named separately from the map above because the specification states the
    // shape of the ladder as well as its membership, and a pair of typos that
    // moved one opponent between tiers would satisfy the per-opponent check
    // if the map were the only source.
    const expected = {
      BotTier.novice: 4,
      BotTier.casual: 5,
      BotTier.club: 5,
      BotTier.expert: 4,
      BotTier.master: 2,
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
