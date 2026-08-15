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
  String get pointsHeading => 'Points';

  @override
  String pointsValue(int points) {
    final intl.NumberFormat pointsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String pointsString = pointsNumberFormat.format(points);

    return '$pointsString';
  }

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
  String opponentRowSemantics(String name, int rating, String record) {
    return '$name. Rating $rating. $record';
  }

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
  String get botWillow => 'Willow';

  @override
  String get botVireo => 'Vireo';

  @override
  String get botFinch => 'Finch';

  @override
  String get botKestrel => 'Kestrel';

  @override
  String get botMarlin => 'Marlin';

  @override
  String get botEmber => 'Ember';

  @override
  String get botBasalt => 'Basalt';

  @override
  String get botOnyx => 'Onyx';

  @override
  String get botSable => 'Sable';

  @override
  String get botCorvus => 'Corvus';

  @override
  String get botLyra => 'Lyra';

  @override
  String get botQuartz => 'Quartz';

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
  String get blurbWillow =>
      'Crowds the middle of the cube and answers the obvious threats.';

  @override
  String get blurbVireo =>
      'Attacks from the corners, and would rather build than block.';

  @override
  String get blurbFinch =>
      'Cautious. Shuts your threats down before it starts its own.';

  @override
  String get blurbKestrel =>
      'Solid on the fundamentals and rarely gives anything away.';

  @override
  String get blurbMarlin =>
      'Plays for good squares as well as good moves. The first real test.';

  @override
  String get blurbEmber => 'Looks a move ahead, and spends it on attack.';

  @override
  String get blurbBasalt => 'Looks a move ahead, and spends it on defence.';

  @override
  String get blurbOnyx =>
      'Reads several moves deep. Punishes a careless answer.';

  @override
  String get blurbSable =>
      'Hunts for the double threat that cannot be answered.';

  @override
  String get blurbCorvus =>
      'Calculates hard, and remembers what it has already worked out.';

  @override
  String get blurbLyra =>
      'Takes the centre early, then goes looking for a forcing line.';

  @override
  String get blurbQuartz =>
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

  @override
  String tutorialStepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get tutorialNext => 'Next';

  @override
  String get tutorialBack => 'Back';

  @override
  String get tutorialDone => 'Done';

  @override
  String get tutorialClose => 'Close the tutorial';

  @override
  String get tutorialOfferTitle => 'New to Quadrim?';

  @override
  String get tutorialOfferBody =>
      'A short tutorial explains the cube and how a game is won. It takes a couple of minutes, and you can leave at any point.';

  @override
  String get tutorialOfferAccept => 'Show me';

  @override
  String get tutorialOfferDecline => 'Not now';

  @override
  String get tutorialGoalTitle => 'The goal';

  @override
  String get tutorialGoalBody =>
      'Put four of your pieces in a straight line and you win. Lines run in every direction through the cube, and there are 76 of them.';

  @override
  String get tutorialGoalBoard =>
      'Layer 1, row 1: four light pieces filling the row, highlighted as a completed line.';

  @override
  String get tutorialLayersTitle => 'Four layers, one cube';

  @override
  String get tutorialLayersBody =>
      'The board is a cube: four squares wide, four deep, four tall. It is drawn as four layers, one under the other, with layer 1 at the front and layer 4 at the back. The same row and column in all four layers is one straight line through the cube.';

  @override
  String get tutorialLayersBoard =>
      'Row 2, column 2 of every layer, highlighted: one line running from the front of the cube to the back.';

  @override
  String get tutorialPlacingTitle => 'Taking a turn';

  @override
  String get tutorialPlacingBody =>
      'Tap any empty square to place a piece. Light goes first, then the players alternate. A piece never moves once it is placed, and the game ends the moment somebody makes a line.';

  @override
  String get tutorialPlacingBoard =>
      'Layer 2 holds two light pieces and one dark piece, layer 3 holds one dark piece, and every other square is empty.';

  @override
  String get tutorialLayerDiagonalTitle => 'Diagonals inside a layer';

  @override
  String get tutorialLayerDiagonalBody =>
      'A line can run corner to corner across a single layer. Both diagonals of each of the four layers count.';

  @override
  String get tutorialLayerDiagonalBoard =>
      'Layer 2, highlighted corner to corner: row 1 column 1, row 2 column 2, row 3 column 3, row 4 column 4.';

  @override
  String get tutorialSliceDiagonalTitle => 'Diagonals through the layers';

  @override
  String get tutorialSliceDiagonalBody =>
      'Take a slice through the cube — one row, all four layers deep — and it has diagonals of its own. These are the lines new players miss.';

  @override
  String get tutorialSliceDiagonalBoard =>
      'Row 1 of every layer, highlighted: column 1 in layer 1, column 2 in layer 2, column 3 in layer 3, column 4 in layer 4.';

  @override
  String get tutorialCubeDiagonalTitle => 'Corner to corner';

  @override
  String get tutorialCubeDiagonalBody =>
      'Four lines run right through the middle of the cube, from one corner to the opposite one. They are the hardest to see and the easiest to lose to.';

  @override
  String get tutorialCubeDiagonalBoard =>
      'Highlighted from row 1 column 1 of layer 1 to row 4 column 4 of layer 4, moving one row and one column with every layer.';

  @override
  String get tutorialRulesDoneTitle => 'That is the whole game';

  @override
  String get tutorialRulesDoneBody =>
      'Rows, columns, the lines through the layers, and every diagonal — 76 in all. That is everything you need to start playing. What follows is how games are actually won, which you can leave for later.';

  @override
  String get tutorialFinishHere => 'Finish here';

  @override
  String get tutorialCentreTitle => 'The middle is worth most';

  @override
  String get tutorialCentreBody =>
      'Squares are not equal. The eight in the middle of the cube — rows and columns 2 and 3, in layers 2 and 3 — each sit on seven different lines. Most squares sit on four. Taking the middle early gives you more ways to win than your opponent has.';

  @override
  String get tutorialCentreBoard =>
      'Eight squares highlighted on an empty board: rows 2 and 3, columns 2 and 3, in layers 2 and 3.';

  @override
  String get tutorialCornersTitle => 'Then the corners';

  @override
  String get tutorialCornersBody =>
      'The eight corners of the cube also sit on seven lines each — they are the only other squares that do. That is why an opponent that seems to be playing for nothing in particular is often quietly collecting corners.';

  @override
  String get tutorialCornersBoard =>
      'Eight squares highlighted on an empty board: the corner of each layer, at rows 1 and 4, columns 1 and 4, in layers 1 and 4.';

  @override
  String get tutorialDoubleThreatTitle => 'Two threats at once';

  @override
  String get tutorialDoubleThreatBody =>
      'One line needing one more piece can be blocked. Two of them cannot. Light has just played the corner, and it completed three of a row and three of a column in the same move. Both highlighted squares now win, and dark has one turn.';

  @override
  String get tutorialDoubleThreatBoard =>
      'Light has just played layer 1, row 1, column 1. Two squares are highlighted: layer 1 row 1 column 4, and layer 1 row 4 column 1. Either one wins for light, and dark can block only one of them.';

  @override
  String get tutorialBlockingTitle => 'Blocking before it is too late';

  @override
  String get tutorialBlockingBody =>
      'The same thing works against you. Dark holds three of a row in layer 2 and needs one more square. Light has to take the highlighted square now — and watch for the move that would give dark two threats, because by then it is already too late.';

  @override
  String get tutorialBlockingBoard =>
      'Dark holds layer 2, row 1, columns 1 to 3. The highlighted square is layer 2, row 1, column 4, which light must take.';

  @override
  String get tutorialStrategyDoneTitle => 'That is how they play';

  @override
  String get tutorialStrategyDoneBody =>
      'Take a win, block a loss, build two threats, and stop your opponent building them — over squares that sit on the most lines. That is not a simplification for the tutorial: it is what the computer opponents are doing, from the weakest up. The stronger ones just see further ahead. Try it out below, against one of the gentler ones.';

  @override
  String get practiceTitle => 'Practice game';

  @override
  String get practicePlay => 'Play a practice game';

  @override
  String get practiceLeave => 'Leave the practice game';

  @override
  String get practiceFinish => 'Finish the tutorial';

  @override
  String get practiceHint => 'Hint';

  @override
  String practiceHintWhere(int layer, int row, int column) {
    return 'layer $layer, row $row, column $column';
  }

  @override
  String practiceHintWin(String where) {
    return 'You can win now — $where completes a line.';
  }

  @override
  String practiceHintBlock(String where) {
    return 'Block at $where, or your opponent completes a line there on their next move.';
  }

  @override
  String practiceHintFork(String where) {
    return 'Play $where. It leaves two lines each needing one more piece, and only one of them can be blocked.';
  }

  @override
  String practiceHintBuild(String where) {
    return 'Nothing is threatened yet. $where sits on more lines than any other free square, so it gives you the most ways to win.';
  }

  @override
  String get review => 'Review the moves';

  @override
  String get reviewLeave => 'Back to the game';

  @override
  String moveOf(int move, int total) {
    return 'Move $move of $total';
  }

  @override
  String get reviewStart => 'Before the first move';

  @override
  String get reviewToStart => 'Jump to the start';

  @override
  String get reviewBack => 'Previous move';

  @override
  String get reviewForward => 'Next move';

  @override
  String get reviewToEnd => 'Jump to the latest move';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsFollowDevice => 'Follow the device';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageDutch => 'Nederlands';

  @override
  String get settingsShowTutorial => 'Show the tutorial again';

  @override
  String get settingsAbout => 'About';

  @override
  String get yourPath => 'Your path';

  @override
  String get locked => 'Locked';

  @override
  String unlockCost(int cost) {
    final intl.NumberFormat costNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String costString = costNumberFormat.format(cost);

    return '$costString points';
  }

  @override
  String unlockProgress(int have, int cost) {
    final intl.NumberFormat haveNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String haveString = haveNumberFormat.format(have);
    final intl.NumberFormat costNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String costString = costNumberFormat.format(cost);

    return '$haveString of $costString';
  }

  @override
  String get unlockAction => 'Unlock';

  @override
  String unlockConfirmTitle(String name) {
    return 'Unlock $name?';
  }

  @override
  String unlockConfirmBody(int cost, int left) {
    final intl.NumberFormat costNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String costString = costNumberFormat.format(cost);
    final intl.NumberFormat leftNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String leftString = leftNumberFormat.format(left);

    return 'This costs $costString points and leaves you $leftString.';
  }

  @override
  String unlockConfirmBook(String name) {
    return '$name plays a proven strategy and is unbeatable when it moves first. From the second seat it plays by search, like the rest.';
  }

  @override
  String unlockNotAffordable(int short) {
    final intl.NumberFormat shortNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String shortString = shortNumberFormat.format(short);

    return 'You need $shortString more points.';
  }

  @override
  String unlockDone(String name) {
    return '$name unlocked.';
  }

  @override
  String starsLabel(int count) {
    return '$count of 3 stars';
  }

  @override
  String get neverPlayed => 'Not played yet';

  @override
  String pathTileSemantics(String name, int rating, String state) {
    return '$name, rated $rating. $state';
  }

  @override
  String lockedWithPrice(int cost, int have) {
    final intl.NumberFormat costNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String costString = costNumberFormat.format(cost);
    final intl.NumberFormat haveNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String haveString = haveNumberFormat.format(have);

    return 'Locked. $costString points, you have $haveString.';
  }

  @override
  String get quests => 'Quests';

  @override
  String questFirstWin(String name) {
    return 'First win against $name';
  }

  @override
  String questFirstWinSecond(String name) {
    return 'First win as second player against $name';
  }

  @override
  String questGamesInDay(int count) {
    return '$count games in one day';
  }

  @override
  String questDaysInRow(int count) {
    return '$count days in a row';
  }

  @override
  String questProgressValue(int current, int target) {
    return '$current of $target';
  }

  @override
  String questSemantics(String name, int current, int target) {
    return '$name. $current of $target.';
  }

  @override
  String get questAchievedTitle => 'Achieved';

  @override
  String questAward(int points) {
    return '+$points';
  }

  @override
  String questAwardSemantics(String name, int points) {
    return '$name. Achieved, $points points.';
  }

  @override
  String get streakHeading => 'Streak';

  @override
  String streakValue(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days in a row',
      one: '1 day in a row',
      zero: 'No days yet',
    );
    return '$_temp0';
  }

  @override
  String get trendHeading => 'Last 10 games';

  @override
  String trendSemantics(String change) {
    return 'Last 10 games: $change.';
  }

  @override
  String trendChange(String change) {
    return '$change';
  }

  @override
  String get relativeToday => 'Today';

  @override
  String get relativeYesterday => 'Yesterday';

  @override
  String relativeDaysAgo(int days) {
    return '$days days ago';
  }

  @override
  String get challengeAgain => 'Play again';

  @override
  String get showMore => 'Show more';

  @override
  String get historyTitle => 'History';

  @override
  String pointsEarnedLine(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '+$points points',
      one: '+1 point',
    );
    return '$_temp0';
  }

  @override
  String get passAndPlayNoPoints => 'Pass and play earns no points.';

  @override
  String unlockNowAffordable(String name) {
    return 'You can now unlock $name.';
  }
}
