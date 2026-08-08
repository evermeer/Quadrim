import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_nl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('nl'),
  ];

  /// The application name shown on the home screen. Not translated per se, but routed through l10n so no screen ever hardcodes it.
  ///
  /// In en, this message translates to:
  /// **'Quadrim'**
  String get appTitle;

  /// Placeholder tagline on the skeleton home screen until the main screen ships.
  ///
  /// In en, this message translates to:
  /// **'Four in a row, stacked in a cube.'**
  String get placeholderTagline;

  /// Button starting a two-players-one-device game.
  ///
  /// In en, this message translates to:
  /// **'Pass and play'**
  String get passAndPlay;

  /// Turn indicator. The first player always plays the light pieces.
  ///
  /// In en, this message translates to:
  /// **'Light to move'**
  String get lightPlays;

  /// No description provided for @darkPlays.
  ///
  /// In en, this message translates to:
  /// **'Dark to move'**
  String get darkPlays;

  /// No description provided for @lightWins.
  ///
  /// In en, this message translates to:
  /// **'Light wins!'**
  String get lightWins;

  /// No description provided for @darkWins.
  ///
  /// In en, this message translates to:
  /// **'Dark wins!'**
  String get darkWins;

  /// No description provided for @gameDrawn.
  ///
  /// In en, this message translates to:
  /// **'It\'s a draw — the board is full.'**
  String get gameDrawn;

  /// Screen reader label for one board cell. state is one of cellEmpty/cellLight/cellDark.
  ///
  /// In en, this message translates to:
  /// **'Layer {layer}, row {row}, column {column}, {state}'**
  String cellSemantics(int layer, int row, int column, String state);

  /// No description provided for @cellEmpty.
  ///
  /// In en, this message translates to:
  /// **'empty'**
  String get cellEmpty;

  /// No description provided for @cellLight.
  ///
  /// In en, this message translates to:
  /// **'light piece'**
  String get cellLight;

  /// No description provided for @cellDark.
  ///
  /// In en, this message translates to:
  /// **'dark piece'**
  String get cellDark;

  /// No description provided for @layerLabel.
  ///
  /// In en, this message translates to:
  /// **'Layer {layer}'**
  String layerLabel(int layer);

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backToHome;

  /// Button starting a game against a computer opponent.
  ///
  /// In en, this message translates to:
  /// **'Play the computer'**
  String get playTheComputer;

  /// Turn indicator in a game against the computer, when it is the player's move.
  ///
  /// In en, this message translates to:
  /// **'Your turn'**
  String get yourTurn;

  /// Shown while a computer opponent decides its move. Bot names are never translated.
  ///
  /// In en, this message translates to:
  /// **'{bot} is thinking…'**
  String botThinking(String bot);

  /// No description provided for @youWin.
  ///
  /// In en, this message translates to:
  /// **'You win!'**
  String get youWin;

  /// No description provided for @youLose.
  ///
  /// In en, this message translates to:
  /// **'{bot} wins!'**
  String youLose(String bot);

  /// Opponent name. Bot names are not translated; routed through l10n so no screen hardcodes a string.
  ///
  /// In en, this message translates to:
  /// **'Pebble'**
  String get botPebble;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @sideLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get sideLight;

  /// Caption explaining who opens a first game and why. who is You, a bot name, Light or Dark.
  ///
  /// In en, this message translates to:
  /// **'Opening move: {who} — chosen at random'**
  String firstMoveRandom(String who);

  /// No description provided for @firstMoveAlternating.
  ///
  /// In en, this message translates to:
  /// **'Opening move: {who} — the start alternates in a rematch'**
  String firstMoveAlternating(String who);

  /// Result screen rating line. delta is a preformatted signed number such as +12 or -8.
  ///
  /// In en, this message translates to:
  /// **'Computer rating {rating} ({delta})'**
  String computerRatingChange(int rating, String delta);

  /// Must make clear this is not a universal rating (spec: two independent ladders).
  ///
  /// In en, this message translates to:
  /// **'Your rating against the computer, on this device only.'**
  String get computerRatingNote;

  /// No description provided for @passAndPlayNoRating.
  ///
  /// In en, this message translates to:
  /// **'No rating changes in pass and play.'**
  String get passAndPlayNoRating;

  /// No description provided for @rematch.
  ///
  /// In en, this message translates to:
  /// **'Rematch'**
  String get rematch;

  /// No description provided for @resign.
  ///
  /// In en, this message translates to:
  /// **'Resign'**
  String get resign;

  /// No description provided for @resignConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Resign this game?'**
  String get resignConfirmTitle;

  /// No description provided for @resignConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The game ends as a loss for the side to move. There is no draw offer.'**
  String get resignConfirmBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'nl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'nl':
      return AppLocalizationsNl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
