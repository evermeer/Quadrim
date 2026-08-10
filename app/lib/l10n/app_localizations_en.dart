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
      'Perfect play from Oren Patashnik\'s Qubic strategy dictionary (1980), in the form Ken Thompson gave it in 1978. Used with permission, moves unchanged.';

  @override
  String get chooseOpponent => 'Choose an opponent';

  @override
  String yourRating(int rating) {
    return 'Your rating: $rating';
  }

  @override
  String opponentCount(int count) {
    return '$count';
  }

  @override
  String get matchEven => 'Even match';

  @override
  String get matchStronger => 'Above your level';

  @override
  String get matchWeaker => 'Below your level';

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
  String get tierNovice => 'Novice';

  @override
  String get tierCasual => 'Casual';

  @override
  String get tierClub => 'Club';

  @override
  String get tierExpert => 'Expert';

  @override
  String get tierMaster => 'Master';

  @override
  String get blurbPebble =>
      'Drops pieces wherever they fall. Has never noticed a threat.';

  @override
  String get blurbTwig =>
      'Plays at random, but takes a win that is staring at it.';

  @override
  String get blurbMote =>
      'Sees wins and blocks — when it happens to be paying attention.';

  @override
  String get blurbClover =>
      'Watches for wins and blocks, loves a corner, and still slips often.';

  @override
  String get blurbBramble =>
      'Knows all the basics, and plays them with no feel for the board.';

  @override
  String get blurbFinch =>
      'Crowds the middle of the cube and answers the obvious threats.';

  @override
  String get blurbKestrel =>
      'Attacks from the corners, and would rather build than block.';

  @override
  String get blurbWillow =>
      'Cautious. Shuts your threats down before it starts its own.';

  @override
  String get blurbEmber =>
      'Solid on the fundamentals and rarely gives anything away.';

  @override
  String get blurbBasalt =>
      'Plays for good squares as well as good moves. The first real test.';

  @override
  String get blurbMarlin => 'Looks a move ahead, and spends it on attack.';

  @override
  String get blurbVireo => 'Looks a move ahead, and spends it on defence.';

  @override
  String get blurbOnyx =>
      'Reads several moves deep. Punishes a careless answer.';

  @override
  String get blurbSable =>
      'Hunts for the double threat that cannot be answered.';

  @override
  String get blurbQuartz =>
      'Calculates hard, and remembers what it has already worked out.';

  @override
  String get blurbCorvus =>
      'Takes the centre early, then goes looking for a forcing line.';

  @override
  String get blurbLyra =>
      'Thinks further ahead the longer it is given. Hard to surprise.';

  @override
  String get blurbTitan =>
      'Searches deeply and plays the endgame out exactly, never guessing.';

  @override
  String get blurbOracle =>
      'Opens from a proven winning strategy and cannot be beaten when it moves first. Moving second, it is only very strong.';

  @override
  String get blurbQuadrimPrime =>
      'The strongest opponent here. Unbeatable when it moves first; when it moves second it defends by the deepest calculation in the game.';
}
