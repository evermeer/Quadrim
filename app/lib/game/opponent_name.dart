import 'package:quadrim_engine/quadrim_engine.dart';

import '../l10n/app_localizations.dart';

/// The display name of a stored `opponent` field.
///
/// Bot names are proper nouns and identical in every language, but they still
/// go through l10n so that no screen hardcodes a user-facing string (D132) —
/// and so that a future locale which *does* transliterate them has somewhere
/// to say so.
///
/// Two screens need this now, which is why it is here rather than on either.
/// Ticket 029 owns opponent content — avatars and descriptions — and ticket
/// 011 the screen that lists all twenty; both build on this lookup rather
/// than replace it.
String botName(AppLocalizations l10n, String opponent) => switch (opponent) {
      'bot:pebble' => l10n.botPebble,
      'bot:twig' => l10n.botTwig,
      'bot:mote' => l10n.botMote,
      'bot:clover' => l10n.botClover,
      'bot:bramble' => l10n.botBramble,
      'bot:willow' => l10n.botWillow,
      'bot:vireo' => l10n.botVireo,
      'bot:finch' => l10n.botFinch,
      'bot:kestrel' => l10n.botKestrel,
      'bot:marlin' => l10n.botMarlin,
      'bot:ember' => l10n.botEmber,
      'bot:basalt' => l10n.botBasalt,
      'bot:onyx' => l10n.botOnyx,
      'bot:sable' => l10n.botSable,
      'bot:corvus' => l10n.botCorvus,
      'bot:lyra' => l10n.botLyra,
      'bot:quartz' => l10n.botQuartz,
      'bot:titan' => l10n.botTitan,
      'bot:oracle' => l10n.botOracle,
      'bot:hazel' => l10n.botHazel,
      'bot:sorrel' => l10n.botSorrel,
      'bot:juniper' => l10n.botJuniper,
      'bot:bracken' => l10n.botBracken,
      'bot:rowan' => l10n.botRowan,
      'bot:aspen' => l10n.botAspen,
      'bot:osprey' => l10n.botOsprey,
      'bot:heron' => l10n.botHeron,
      'bot:lynx' => l10n.botLynx,
      'bot:cairn' => l10n.botCairn,
      'bot:flint' => l10n.botFlint,
      'bot:quadrim_prime' => l10n.botQuadrimPrime,
      // Showing the raw key for anything else is deliberate: it is obviously
      // wrong on screen, which is better than a plausible-looking name for an
      // opponent that does not exist. A stored game can name an opponent this
      // build has never heard of — an older catalogue, or a newer one after a
      // downgrade — and that is the case this arm is for.
      _ => opponent,
    };

/// The display name for somewhere a third of a phone's width wide.
///
/// Only `Your path` uses it, and only one of the twenty needs it: at three
/// tiles across, "Quadrim Prime" ellipsises to "Quadrim P…", which reads as a
/// rendering fault rather than as an abbreviation. Everywhere with room — the
/// opponent's page, the game screen, the history — says the whole name, so this
/// deliberately does not fall back to a general shortening rule. A second name
/// that needs one gets a second arm, chosen by a person.
String botShortName(AppLocalizations l10n, String opponent) =>
    opponent == 'bot:quadrim_prime'
        ? l10n.botQuadrimPrimeShort
        : botName(l10n, opponent);

/// The one-line description of how an opponent plays (ticket 029).
///
/// Blurbs describe what a player meets at the board rather than how the
/// opponent is built, so that reading the list tells you something true about
/// the game you are about to play.
///
/// Null rather than a placeholder for an unknown opponent: the list screen can
/// omit a line it does not have, where invented text would be worse than none.
String? botBlurb(AppLocalizations l10n, String opponent) => switch (opponent) {
      'bot:pebble' => l10n.blurbPebble,
      'bot:twig' => l10n.blurbTwig,
      'bot:mote' => l10n.blurbMote,
      'bot:clover' => l10n.blurbClover,
      'bot:bramble' => l10n.blurbBramble,
      'bot:willow' => l10n.blurbWillow,
      'bot:vireo' => l10n.blurbVireo,
      'bot:finch' => l10n.blurbFinch,
      'bot:kestrel' => l10n.blurbKestrel,
      'bot:marlin' => l10n.blurbMarlin,
      'bot:ember' => l10n.blurbEmber,
      'bot:basalt' => l10n.blurbBasalt,
      'bot:onyx' => l10n.blurbOnyx,
      'bot:sable' => l10n.blurbSable,
      'bot:corvus' => l10n.blurbCorvus,
      'bot:lyra' => l10n.blurbLyra,
      'bot:quartz' => l10n.blurbQuartz,
      'bot:titan' => l10n.blurbTitan,
      'bot:oracle' => l10n.blurbOracle,
      'bot:hazel' => l10n.blurbHazel,
      'bot:sorrel' => l10n.blurbSorrel,
      'bot:juniper' => l10n.blurbJuniper,
      'bot:bracken' => l10n.blurbBracken,
      'bot:rowan' => l10n.blurbRowan,
      'bot:aspen' => l10n.blurbAspen,
      'bot:osprey' => l10n.blurbOsprey,
      'bot:heron' => l10n.blurbHeron,
      'bot:lynx' => l10n.blurbLynx,
      'bot:cairn' => l10n.blurbCairn,
      'bot:flint' => l10n.blurbFlint,
      'bot:quadrim_prime' => l10n.blurbQuadrimPrime,
      _ => null,
    };

/// The catalogue entry behind a stored `opponent` field, or null for
/// pass-and-play and for an opponent this build has never heard of.
///
/// The prefix is stripped here rather than at each call site so that the one
/// place that knows a stored opponent looks like `bot:<id>` stays the one
/// place — [botOpponent] writes it and this reads it.
BotConfig? botConfigFor(String opponent) {
  const prefix = 'bot:';
  if (!opponent.startsWith(prefix)) return null;
  return botById(opponent.substring(prefix.length));
}

/// The translated name of a difficulty tier. Names are not translated; tiers
/// are (ticket 029).
String tierLabel(AppLocalizations l10n, BotTier tier) => switch (tier) {
      BotTier.novice => l10n.tierNovice,
      BotTier.casual => l10n.tierCasual,
      BotTier.club => l10n.tierClub,
      BotTier.expert => l10n.tierExpert,
      BotTier.master => l10n.tierMaster,
    };
