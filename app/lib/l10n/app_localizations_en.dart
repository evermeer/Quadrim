// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Quadrim';

  @override
  String get placeholderTagline => 'Four in a row, stacked in a cube.';

  @override
  String get passAndPlay => 'Pass and play';

  @override
  String get lightPlays => 'Light to move';

  @override
  String get darkPlays => 'Dark to move';

  @override
  String get lightWins => 'Light wins!';

  @override
  String get darkWins => 'Dark wins!';

  @override
  String get gameDrawn => 'It\'s a draw — the board is full.';

  @override
  String cellSemantics(int layer, int row, int column, String state) {
    return 'Layer $layer, row $row, column $column, $state';
  }

  @override
  String get cellEmpty => 'empty';

  @override
  String get cellLight => 'light piece';

  @override
  String get cellDark => 'dark piece';

  @override
  String layerLabel(int layer) {
    return 'Layer $layer';
  }

  @override
  String get backToHome => 'Back';

  @override
  String get playTheComputer => 'Play the computer';

  @override
  String get yourTurn => 'Your turn';

  @override
  String botThinking(String bot) {
    return '$bot is thinking…';
  }

  @override
  String get youWin => 'You win!';

  @override
  String youLose(String bot) {
    return '$bot wins!';
  }

  @override
  String get botPebble => 'Pebble';

  @override
  String get you => 'You';

  @override
  String get sideLight => 'Light';

  @override
  String firstMoveRandom(String who) {
    return 'Opening move: $who — chosen at random';
  }

  @override
  String firstMoveAlternating(String who) {
    return 'Opening move: $who — the start alternates in a rematch';
  }

  @override
  String computerRatingChange(int rating, String delta) {
    return 'Computer rating $rating ($delta)';
  }

  @override
  String get computerRatingNote =>
      'Your rating against the computer, on this device only.';

  @override
  String get passAndPlayNoRating => 'No rating changes in pass and play.';

  @override
  String get rematch => 'Rematch';

  @override
  String get resign => 'Resign';

  @override
  String get resignConfirmTitle => 'Resign this game?';

  @override
  String get resignConfirmBody =>
      'The game ends as a loss for the side to move. There is no draw offer.';

  @override
  String get cancel => 'Cancel';

  @override
  String ratingValue(int rating) {
    return '$rating';
  }

  @override
  String get newGame => 'New game';

  @override
  String get tutorial => 'Tutorial';

  @override
  String get settings => 'Settings';

  @override
  String get comingSoon => 'Arrives in a later build.';

  @override
  String get computerRatingHeading => 'Against the computer';

  @override
  String get yourRecord => 'Your record';

  @override
  String recordLine(int wins, int losses, int draws) {
    return '$wins won · $losses lost · $draws drawn';
  }

  @override
  String get recordEmpty => 'No finished games against the computer yet.';

  @override
  String get byOpponent => 'By opponent';

  @override
  String opponentRecord(int wins, int losses, int draws, int played) {
    return '$wins–$losses–$draws in $played games';
  }

  @override
  String get inProgress => 'In progress';

  @override
  String get finishedGames => 'Finished games';

  @override
  String movesPlayed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count moves played',
      one: '1 move played',
    );
    return '$_temp0';
  }

  @override
  String get resultWon => 'Won';

  @override
  String get resultLost => 'Lost';

  @override
  String get resultDrawn => 'Drawn';

  @override
  String get noGamesYet => 'No games yet.';

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
