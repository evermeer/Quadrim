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
      'bot:finch' => l10n.botFinch,
      'bot:kestrel' => l10n.botKestrel,
      'bot:willow' => l10n.botWillow,
      'bot:ember' => l10n.botEmber,
      'bot:basalt' => l10n.botBasalt,
      'bot:marlin' => l10n.botMarlin,
      'bot:vireo' => l10n.botVireo,
      'bot:onyx' => l10n.botOnyx,
      'bot:sable' => l10n.botSable,
      'bot:quartz' => l10n.botQuartz,
      'bot:corvus' => l10n.botCorvus,
      'bot:lyra' => l10n.botLyra,
      'bot:titan' => l10n.botTitan,
      'bot:oracle' => l10n.botOracle,
      'bot:quadrim_prime' => l10n.botQuadrimPrime,
      // Showing the raw key for anything else is deliberate: it is obviously
      // wrong on screen, which is better than a plausible-looking name for an
      // opponent that does not exist. A stored game can name an opponent this
      // build has never heard of — an older catalogue, or a newer one after a
      // downgrade — and that is the case this arm is for.
      _ => opponent,
    };

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
      'bot:finch' => l10n.blurbFinch,
      'bot:kestrel' => l10n.blurbKestrel,
      'bot:willow' => l10n.blurbWillow,
      'bot:ember' => l10n.blurbEmber,
      'bot:basalt' => l10n.blurbBasalt,
      'bot:marlin' => l10n.blurbMarlin,
      'bot:vireo' => l10n.blurbVireo,
      'bot:onyx' => l10n.blurbOnyx,
      'bot:sable' => l10n.blurbSable,
      'bot:quartz' => l10n.blurbQuartz,
      'bot:corvus' => l10n.blurbCorvus,
      'bot:lyra' => l10n.blurbLyra,
      'bot:titan' => l10n.blurbTitan,
      'bot:oracle' => l10n.blurbOracle,
      'bot:quadrim_prime' => l10n.blurbQuadrimPrime,
      _ => null,
    };

/// The translated name of a difficulty tier. Names are not translated; tiers
/// are (ticket 029).
String tierLabel(AppLocalizations l10n, BotTier tier) => switch (tier) {
      BotTier.novice => l10n.tierNovice,
      BotTier.casual => l10n.tierCasual,
      BotTier.club => l10n.tierClub,
      BotTier.expert => l10n.tierExpert,
      BotTier.master => l10n.tierMaster,
    };
