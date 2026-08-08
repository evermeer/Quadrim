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
  String get yourRecord => 'Jouw resultaten';

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
}
