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
}
