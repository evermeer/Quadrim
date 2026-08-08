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
}
