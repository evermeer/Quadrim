import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrim/game/opponent_name.dart';
import 'package:quadrim/l10n/app_localizations.dart';
import 'package:quadrim_engine/quadrim_engine.dart';

/// Ticket 029 promises twenty blurbs in two languages — forty strings — and a
/// tier label for each of the five bands. A missing one is not a crash: the
/// list screen simply shows a name with nothing under it, which is the kind of
/// gap that ships. These tests are what make the promise checkable.
void main() {
  late AppLocalizations en;
  late AppLocalizations nl;

  setUpAll(() async {
    en = await AppLocalizations.delegate.load(const Locale('en'));
    nl = await AppLocalizations.delegate.load(const Locale('nl'));
  });

  test('every opponent has a name in both languages', () {
    for (final bot in opponentCatalogue) {
      final key = 'bot:${bot.id}';
      // Names are proper nouns and identical across languages by design
      // (D132); what matters is that the lookup resolves rather than falling
      // through to showing the raw key.
      expect(botName(en, key), isNot(key), reason: '${bot.id} has no name');
      expect(botName(nl, key), isNot(key), reason: '${bot.id} has no name');
    }
  });

  test('every opponent has a blurb in both languages', () {
    for (final bot in opponentCatalogue) {
      final key = 'bot:${bot.id}';
      for (final entry in {'en': en, 'nl': nl}.entries) {
        final blurb = botBlurb(entry.value, key);
        expect(blurb, isNotNull, reason: '${bot.id} has no ${entry.key} blurb');
        expect(blurb, isNotEmpty, reason: '${bot.id} ${entry.key} blurb empty');
      }
    }
  });

  test('the Dutch blurbs are translated, not copied', () {
    // A locale file filled in by duplicating English passes every other check
    // here. Blurbs are prose, so an identical pair means one was not written.
    for (final bot in opponentCatalogue) {
      final key = 'bot:${bot.id}';
      expect(
        botBlurb(nl, key),
        isNot(botBlurb(en, key)),
        reason: '${bot.id} has the English blurb in the Dutch file',
      );
    }
  });

  test('an unknown opponent has no blurb rather than a wrong one', () {
    // A stored game can name an opponent this build has never heard of. The
    // list screen omits a line it does not have; inventing one would be worse.
    expect(botBlurb(en, 'bot:nonesuch'), isNull);
  });

  test('every tier has a label in both languages', () {
    for (final tier in BotTier.values) {
      expect(tierLabel(en, tier), isNotEmpty);
      expect(tierLabel(nl, tier), isNotEmpty);
    }
    // Five distinct labels, or two bands would be indistinguishable on screen.
    expect(
      {for (final t in BotTier.values) tierLabel(en, t)}.length,
      BotTier.values.length,
    );
    expect(
      {for (final t in BotTier.values) tierLabel(nl, t)}.length,
      BotTier.values.length,
    );
  });

  test('the Master tier blurbs state the first-player asymmetry', () {
    // The dictionary proves a win for the opening player only. A blurb that
    // claimed perfection outright would be false in half of Prime's games,
    // and a tester playing it as White would catch the app in a lie (D181).
    for (final id in ['oracle', 'quadrim_prime']) {
      final english = botBlurb(en, 'bot:$id')!.toLowerCase();
      final dutch = botBlurb(nl, 'bot:$id')!.toLowerCase();
      expect(english, contains('first'), reason: '$id must qualify its claim');
      expect(dutch, contains('begint'), reason: '$id must qualify its claim');
    }
  });
}
