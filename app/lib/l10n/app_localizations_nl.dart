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
}
