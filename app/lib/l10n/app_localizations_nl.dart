// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'Quadrim';

  @override
  String get placeholderTagline => 'Vier op een rij, gestapeld in een kubus.';

  @override
  String get passAndPlay => 'Samen op één toestel';

  @override
  String get lightPlays => 'Licht is aan zet';

  @override
  String get darkPlays => 'Donker is aan zet';

  @override
  String get lightWins => 'Licht wint!';

  @override
  String get darkWins => 'Donker wint!';

  @override
  String get gameDrawn => 'Gelijkspel — het bord is vol.';

  @override
  String cellSemantics(int layer, int row, int column, String state) {
    return 'Laag $layer, rij $row, kolom $column, $state';
  }

  @override
  String get cellEmpty => 'leeg';

  @override
  String get cellLight => 'lichte steen';

  @override
  String get cellDark => 'donkere steen';

  @override
  String layerLabel(int layer) {
    return 'Laag $layer';
  }

  @override
  String get backToHome => 'Terug';

  @override
  String get playTheComputer => 'Tegen de computer';

  @override
  String get yourTurn => 'Jij bent aan zet';

  @override
  String botThinking(String bot) {
    return '$bot denkt na…';
  }

  @override
  String get youWin => 'Je wint!';

  @override
  String youLose(String bot) {
    return '$bot wint!';
  }

  @override
  String get botPebble => 'Pebble';

  @override
  String get you => 'Jij';

  @override
  String get sideLight => 'Licht';

  @override
  String firstMoveRandom(String who) {
    return 'Aftrap: $who — willekeurig gekozen';
  }

  @override
  String firstMoveAlternating(String who) {
    return 'Aftrap: $who — bij een revanche wisselt de aftrap';
  }

  @override
  String computerRatingChange(int rating, String delta) {
    return 'Computerrating $rating ($delta)';
  }

  @override
  String get computerRatingNote =>
      'Je rating tegen de computer, alleen op dit toestel.';

  @override
  String get passAndPlayNoRating =>
      'Samen op één toestel telt niet mee voor je rating.';

  @override
  String get rematch => 'Revanche';

  @override
  String get resign => 'Opgeven';

  @override
  String get resignConfirmTitle => 'Deze partij opgeven?';

  @override
  String get resignConfirmBody =>
      'De partij eindigt als verlies voor de speler die aan zet is. Remise aanbieden kan niet.';

  @override
  String get cancel => 'Annuleren';

  @override
  String ratingValue(int rating) {
    return '$rating';
  }

  @override
  String get newGame => 'Nieuwe partij';

  @override
  String get tutorial => 'Uitleg';

  @override
  String get settings => 'Instellingen';

  @override
  String get comingSoon => 'Komt in een latere versie.';

  @override
  String get computerRatingHeading => 'Tegen de computer';

  @override
  String recordLine(int wins, int losses, int draws) {
    return '$wins gewonnen · $losses verloren · $draws remise';
  }

  @override
  String get recordEmpty => 'Nog geen voltooide partijen tegen de computer.';

  @override
  String get byOpponent => 'Per tegenstander';

  @override
  String opponentRecord(int wins, int losses, int draws, int played) {
    return '$wins–$losses–$draws uit $played partijen';
  }

  @override
  String get inProgress => 'Bezig';

  @override
  String get finishedGames => 'Voltooide partijen';

  @override
  String movesPlayed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zetten gespeeld',
      one: '1 zet gespeeld',
    );
    return '$_temp0';
  }

  @override
  String get resultWon => 'Gewonnen';

  @override
  String get resultLost => 'Verloren';

  @override
  String get resultDrawn => 'Remise';

  @override
  String get noGamesYet => 'Nog geen partijen.';

  @override
  String get botTwig => 'Twig';

  @override
  String get botMote => 'Mote';

  @override
  String get botClover => 'Clover';

  @override
  String get botBramble => 'Bramble';

  @override
  String get botFinch => 'Finch';

  @override
  String get botKestrel => 'Kestrel';

  @override
  String get botWillow => 'Willow';

  @override
  String get botEmber => 'Ember';

  @override
  String get botBasalt => 'Basalt';

  @override
  String get botMarlin => 'Marlin';

  @override
  String get botVireo => 'Vireo';

  @override
  String get botOnyx => 'Onyx';

  @override
  String get botSable => 'Sable';

  @override
  String get botQuartz => 'Quartz';

  @override
  String get botCorvus => 'Corvus';

  @override
  String get botLyra => 'Lyra';

  @override
  String get botTitan => 'Titan';

  @override
  String get botOracle => 'Oracle';

  @override
  String get botQuadrimPrime => 'Quadrim Prime';

  @override
  String get strategyCredit =>
      'Perfect spel uit Oren Patashniks Qubic-strategieboek (1980), in de vorm die Ken Thompson het in 1978 gaf. Gebruikt met toestemming, zetten ongewijzigd.';

  @override
  String get chooseOpponent => 'Kies een tegenstander';

  @override
  String yourRating(int rating) {
    return 'Jouw rating: $rating';
  }

  @override
  String opponentCount(int count) {
    return '$count';
  }

  @override
  String get matchEven => 'Gelijkwaardig';

  @override
  String get matchStronger => 'Boven jouw niveau';

  @override
  String get matchWeaker => 'Onder jouw niveau';

  @override
  String opponentSemantics(
    String name,
    String tier,
    int rating,
    String match,
    String blurb,
  ) {
    return '$name. $tier. Rating $rating. $match. $blurb';
  }

  @override
  String get tierNovice => 'Beginner';

  @override
  String get tierCasual => 'Recreatief';

  @override
  String get tierClub => 'Club';

  @override
  String get tierExpert => 'Expert';

  @override
  String get tierMaster => 'Meester';

  @override
  String get blurbPebble =>
      'Legt stenen neer waar ze maar vallen. Heeft nog nooit een dreiging opgemerkt.';

  @override
  String get blurbTwig =>
      'Speelt willekeurig, maar pakt een winst die voor het grijpen ligt.';

  @override
  String get blurbMote => 'Ziet winst en blokkades — als het toevallig oplet.';

  @override
  String get blurbClover =>
      'Let op winst en blokkades, is dol op hoeken, en vergist zich nog vaak.';

  @override
  String get blurbBramble =>
      'Kent alle basisregels en speelt ze zonder enig gevoel voor het bord.';

  @override
  String get blurbFinch =>
      'Verdringt zich in het midden van de kubus en pareert de duidelijke dreigingen.';

  @override
  String get blurbKestrel =>
      'Valt aan vanuit de hoeken en bouwt liever dan dat het blokkeert.';

  @override
  String get blurbWillow =>
      'Voorzichtig. Legt jouw dreigingen stil voordat het aan zijn eigen begint.';

  @override
  String get blurbEmber => 'Degelijk in de basis en geeft zelden iets weg.';

  @override
  String get blurbBasalt =>
      'Speelt om goede velden en niet alleen om goede zetten. De eerste echte test.';

  @override
  String get blurbMarlin =>
      'Kijkt één zet vooruit en gebruikt dat om aan te vallen.';

  @override
  String get blurbVireo =>
      'Kijkt één zet vooruit en gebruikt dat om te verdedigen.';

  @override
  String get blurbOnyx =>
      'Rekent een paar zetten diep. Straft een slordig antwoord af.';

  @override
  String get blurbSable =>
      'Jaagt op de dubbele dreiging die niet te beantwoorden is.';

  @override
  String get blurbQuartz =>
      'Rekent hard en onthoudt wat het al heeft uitgerekend.';

  @override
  String get blurbCorvus =>
      'Neemt vroeg het centrum en gaat dan op zoek naar een forcerende variant.';

  @override
  String get blurbLyra =>
      'Denkt verder vooruit naarmate het meer tijd krijgt. Moeilijk te verrassen.';

  @override
  String get blurbTitan =>
      'Zoekt diep en speelt het eindspel exact uit, zonder ooit te gokken.';

  @override
  String get blurbOracle =>
      'Opent volgens een bewezen winnende strategie en is niet te verslaan als het begint. Als tweede speler is het alleen heel sterk.';

  @override
  String get blurbQuadrimPrime =>
      'De sterkste tegenstander hier. Onverslaanbaar als het begint; speelt het als tweede, dan verdedigt het met de diepste berekening in het spel.';
}
