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

  /// A rating on its own. Deliberately unformatted: a rating is written 1200, not 1,200 or 1.200, in every locale this ships in.
  ///
  /// In en, this message translates to:
  /// **'{rating}'**
  String ratingValue(int rating);

  /// The main screen's primary action.
  ///
  /// In en, this message translates to:
  /// **'New game'**
  String get newGame;

  /// No description provided for @tutorial.
  ///
  /// In en, this message translates to:
  /// **'Tutorial'**
  String get tutorial;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Label above the computer rating. Must not read as a universal rating: a separate rating against people arrives at 0.3b.
  ///
  /// In en, this message translates to:
  /// **'Against the computer'**
  String get computerRatingHeading;

  /// No description provided for @recordLine.
  ///
  /// In en, this message translates to:
  /// **'{wins} won · {losses} lost · {draws} drawn'**
  String recordLine(int wins, int losses, int draws);

  /// No description provided for @recordEmpty.
  ///
  /// In en, this message translates to:
  /// **'No finished games against the computer yet.'**
  String get recordEmpty;

  /// No description provided for @byOpponent.
  ///
  /// In en, this message translates to:
  /// **'By opponent'**
  String get byOpponent;

  /// One opponent's record: wins-losses-draws.
  ///
  /// In en, this message translates to:
  /// **'{wins}–{losses}–{draws} in {played} games'**
  String opponentRecord(int wins, int losses, int draws, int played);

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get inProgress;

  /// No description provided for @finishedGames.
  ///
  /// In en, this message translates to:
  /// **'Finished games'**
  String get finishedGames;

  /// No description provided for @movesPlayed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 move played} other{{count} moves played}}'**
  String movesPlayed(int count);

  /// No description provided for @resultWon.
  ///
  /// In en, this message translates to:
  /// **'Won'**
  String get resultWon;

  /// No description provided for @resultLost.
  ///
  /// In en, this message translates to:
  /// **'Lost'**
  String get resultLost;

  /// No description provided for @resultDrawn.
  ///
  /// In en, this message translates to:
  /// **'Drawn'**
  String get resultDrawn;

  /// No description provided for @noGamesYet.
  ///
  /// In en, this message translates to:
  /// **'No games yet.'**
  String get noGamesYet;

  /// No description provided for @botTwig.
  ///
  /// In en, this message translates to:
  /// **'Twig'**
  String get botTwig;

  /// No description provided for @botMote.
  ///
  /// In en, this message translates to:
  /// **'Mote'**
  String get botMote;

  /// No description provided for @botClover.
  ///
  /// In en, this message translates to:
  /// **'Clover'**
  String get botClover;

  /// No description provided for @botBramble.
  ///
  /// In en, this message translates to:
  /// **'Bramble'**
  String get botBramble;

  /// No description provided for @botFinch.
  ///
  /// In en, this message translates to:
  /// **'Finch'**
  String get botFinch;

  /// No description provided for @botKestrel.
  ///
  /// In en, this message translates to:
  /// **'Kestrel'**
  String get botKestrel;

  /// No description provided for @botWillow.
  ///
  /// In en, this message translates to:
  /// **'Willow'**
  String get botWillow;

  /// No description provided for @botEmber.
  ///
  /// In en, this message translates to:
  /// **'Ember'**
  String get botEmber;

  /// No description provided for @botBasalt.
  ///
  /// In en, this message translates to:
  /// **'Basalt'**
  String get botBasalt;

  /// No description provided for @botMarlin.
  ///
  /// In en, this message translates to:
  /// **'Marlin'**
  String get botMarlin;

  /// No description provided for @botVireo.
  ///
  /// In en, this message translates to:
  /// **'Vireo'**
  String get botVireo;

  /// No description provided for @botOnyx.
  ///
  /// In en, this message translates to:
  /// **'Onyx'**
  String get botOnyx;

  /// No description provided for @botSable.
  ///
  /// In en, this message translates to:
  /// **'Sable'**
  String get botSable;

  /// No description provided for @botQuartz.
  ///
  /// In en, this message translates to:
  /// **'Quartz'**
  String get botQuartz;

  /// No description provided for @botCorvus.
  ///
  /// In en, this message translates to:
  /// **'Corvus'**
  String get botCorvus;

  /// No description provided for @botLyra.
  ///
  /// In en, this message translates to:
  /// **'Lyra'**
  String get botLyra;

  /// No description provided for @botTitan.
  ///
  /// In en, this message translates to:
  /// **'Titan'**
  String get botTitan;

  /// No description provided for @botOracle.
  ///
  /// In en, this message translates to:
  /// **'Oracle'**
  String get botOracle;

  /// No description provided for @botQuadrimPrime.
  ///
  /// In en, this message translates to:
  /// **'Quadrim Prime'**
  String get botQuadrimPrime;

  /// Attribution required by the terms of the strategy dictionary. Must remain visible in the shipped app.
  ///
  /// In en, this message translates to:
  /// **'Perfect play from Oren Patashnik\'s Qubic strategy dictionary (1980), in the form Ken Thompson gave it in 1978. Used with permission, moves unchanged.'**
  String get strategyCredit;

  /// Title of the screen listing all twenty computer opponents.
  ///
  /// In en, this message translates to:
  /// **'Choose an opponent'**
  String get chooseOpponent;

  /// Shown on the opponent list so the choice can be made against the player's own strength.
  ///
  /// In en, this message translates to:
  /// **'Your rating: {rating}'**
  String yourRating(int rating);

  /// How many opponents a collapsed tier holds. A bare number, routed through l10n like ratingValue so it is formatted for the locale rather than interpolated in code.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String opponentCount(int count);

  /// Neither side is heavily favoured. Paired with a visual cue that does not rely on colour.
  ///
  /// In en, this message translates to:
  /// **'Even match'**
  String get matchEven;

  /// No description provided for @matchStronger.
  ///
  /// In en, this message translates to:
  /// **'Above your level'**
  String get matchStronger;

  /// No description provided for @matchWeaker.
  ///
  /// In en, this message translates to:
  /// **'Below your level'**
  String get matchWeaker;

  /// The whole of one opponent row, announced as a single unit so a screen reader user hears name, tier and strength together rather than swiping through four fragments.
  ///
  /// In en, this message translates to:
  /// **'{name}. {tier}. Rating {rating}. {match}. {blurb}'**
  String opponentSemantics(
    String name,
    String tier,
    int rating,
    String match,
    String blurb,
  );

  /// Difficulty tier. Opponent names are never translated; tier labels are.
  ///
  /// In en, this message translates to:
  /// **'Novice'**
  String get tierNovice;

  /// No description provided for @tierCasual.
  ///
  /// In en, this message translates to:
  /// **'Casual'**
  String get tierCasual;

  /// No description provided for @tierClub.
  ///
  /// In en, this message translates to:
  /// **'Club'**
  String get tierClub;

  /// No description provided for @tierExpert.
  ///
  /// In en, this message translates to:
  /// **'Expert'**
  String get tierExpert;

  /// No description provided for @tierMaster.
  ///
  /// In en, this message translates to:
  /// **'Master'**
  String get tierMaster;

  /// One-line personality blurb shown in the opponent list. Describes what a player will observe at the board, not how the opponent is implemented.
  ///
  /// In en, this message translates to:
  /// **'Drops pieces wherever they fall. Has never noticed a threat.'**
  String get blurbPebble;

  /// No description provided for @blurbTwig.
  ///
  /// In en, this message translates to:
  /// **'Plays at random, but takes a win that is staring at it.'**
  String get blurbTwig;

  /// No description provided for @blurbMote.
  ///
  /// In en, this message translates to:
  /// **'Sees wins and blocks — when it happens to be paying attention.'**
  String get blurbMote;

  /// No description provided for @blurbClover.
  ///
  /// In en, this message translates to:
  /// **'Watches for wins and blocks, loves a corner, and still slips often.'**
  String get blurbClover;

  /// No description provided for @blurbBramble.
  ///
  /// In en, this message translates to:
  /// **'Knows all the basics, and plays them with no feel for the board.'**
  String get blurbBramble;

  /// No description provided for @blurbFinch.
  ///
  /// In en, this message translates to:
  /// **'Crowds the middle of the cube and answers the obvious threats.'**
  String get blurbFinch;

  /// No description provided for @blurbKestrel.
  ///
  /// In en, this message translates to:
  /// **'Attacks from the corners, and would rather build than block.'**
  String get blurbKestrel;

  /// No description provided for @blurbWillow.
  ///
  /// In en, this message translates to:
  /// **'Cautious. Shuts your threats down before it starts its own.'**
  String get blurbWillow;

  /// No description provided for @blurbEmber.
  ///
  /// In en, this message translates to:
  /// **'Solid on the fundamentals and rarely gives anything away.'**
  String get blurbEmber;

  /// No description provided for @blurbBasalt.
  ///
  /// In en, this message translates to:
  /// **'Plays for good squares as well as good moves. The first real test.'**
  String get blurbBasalt;

  /// No description provided for @blurbMarlin.
  ///
  /// In en, this message translates to:
  /// **'Looks a move ahead, and spends it on attack.'**
  String get blurbMarlin;

  /// No description provided for @blurbVireo.
  ///
  /// In en, this message translates to:
  /// **'Looks a move ahead, and spends it on defence.'**
  String get blurbVireo;

  /// No description provided for @blurbOnyx.
  ///
  /// In en, this message translates to:
  /// **'Reads several moves deep. Punishes a careless answer.'**
  String get blurbOnyx;

  /// No description provided for @blurbSable.
  ///
  /// In en, this message translates to:
  /// **'Hunts for the double threat that cannot be answered.'**
  String get blurbSable;

  /// No description provided for @blurbQuartz.
  ///
  /// In en, this message translates to:
  /// **'Calculates hard, and remembers what it has already worked out.'**
  String get blurbQuartz;

  /// No description provided for @blurbCorvus.
  ///
  /// In en, this message translates to:
  /// **'Takes the centre early, then goes looking for a forcing line.'**
  String get blurbCorvus;

  /// No description provided for @blurbLyra.
  ///
  /// In en, this message translates to:
  /// **'Thinks further ahead the longer it is given. Hard to surprise.'**
  String get blurbLyra;

  /// No description provided for @blurbTitan.
  ///
  /// In en, this message translates to:
  /// **'Searches deeply and plays the endgame out exactly, never guessing.'**
  String get blurbTitan;

  /// Oracle and Quadrim Prime both play from a strategy proven for the first player only. The blurb must state that asymmetry rather than claim perfection outright (D181).
  ///
  /// In en, this message translates to:
  /// **'Opens from a proven winning strategy and cannot be beaten when it moves first. Moving second, it is only very strong.'**
  String get blurbOracle;

  /// Must not claim to be perfect without qualification — the proof it follows covers the first player only (D181).
  ///
  /// In en, this message translates to:
  /// **'The strongest opponent here. Unbeatable when it moves first; when it moves second it defends by the deepest calculation in the game.'**
  String get blurbQuadrimPrime;

  /// Tutorial progress. Also the screen-reader label for the progress bar, which carries no meaning on its own.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String tutorialStepOf(int current, int total);

  /// No description provided for @tutorialNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tutorialNext;

  /// No description provided for @tutorialBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get tutorialBack;

  /// Finishes the tutorial from its last step. Distinct from leaving early, which does not mark it complete.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get tutorialDone;

  /// Tooltip on the exit button. The tutorial can be left at any step.
  ///
  /// In en, this message translates to:
  /// **'Close the tutorial'**
  String get tutorialClose;

  /// No description provided for @tutorialOfferTitle.
  ///
  /// In en, this message translates to:
  /// **'New to Quadrim?'**
  String get tutorialOfferTitle;

  /// Shown once, on first launch. Says the tutorial can be left so the offer does not read as a commitment.
  ///
  /// In en, this message translates to:
  /// **'A short tutorial explains the cube and how a game is won. It takes a couple of minutes, and you can leave at any point.'**
  String get tutorialOfferBody;

  /// No description provided for @tutorialOfferAccept.
  ///
  /// In en, this message translates to:
  /// **'Show me'**
  String get tutorialOfferAccept;

  /// No description provided for @tutorialOfferDecline.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get tutorialOfferDecline;

  /// No description provided for @tutorialGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'The goal'**
  String get tutorialGoalTitle;

  /// No description provided for @tutorialGoalBody.
  ///
  /// In en, this message translates to:
  /// **'Put four of your pieces in a straight line and you win. Lines run in every direction through the cube, and there are 76 of them.'**
  String get tutorialGoalBody;

  /// Screen-reader description of one tutorial board. The board itself is silenced and described as a whole, because swiping through 64 cells to find four highlighted ones is not comprehension (D195).
  ///
  /// In en, this message translates to:
  /// **'Layer 1, row 1: four light pieces filling the row, highlighted as a completed line.'**
  String get tutorialGoalBoard;

  /// No description provided for @tutorialLayersTitle.
  ///
  /// In en, this message translates to:
  /// **'Four layers, one cube'**
  String get tutorialLayersTitle;

  /// No description provided for @tutorialLayersBody.
  ///
  /// In en, this message translates to:
  /// **'The board is a cube: four squares wide, four deep, four tall. It is drawn as four layers, one under the other, with layer 1 at the front and layer 4 at the back. The same row and column in all four layers is one straight line through the cube.'**
  String get tutorialLayersBody;

  /// No description provided for @tutorialLayersBoard.
  ///
  /// In en, this message translates to:
  /// **'Row 2, column 2 of every layer, highlighted: one line running from the front of the cube to the back.'**
  String get tutorialLayersBoard;

  /// No description provided for @tutorialPlacingTitle.
  ///
  /// In en, this message translates to:
  /// **'Taking a turn'**
  String get tutorialPlacingTitle;

  /// No description provided for @tutorialPlacingBody.
  ///
  /// In en, this message translates to:
  /// **'Tap any empty square to place a piece. Light goes first, then the players alternate. A piece never moves once it is placed, and the game ends the moment somebody makes a line.'**
  String get tutorialPlacingBody;

  /// No description provided for @tutorialPlacingBoard.
  ///
  /// In en, this message translates to:
  /// **'Layer 2 holds two light pieces and one dark piece, layer 3 holds one dark piece, and every other square is empty.'**
  String get tutorialPlacingBoard;

  /// No description provided for @tutorialLayerDiagonalTitle.
  ///
  /// In en, this message translates to:
  /// **'Diagonals inside a layer'**
  String get tutorialLayerDiagonalTitle;

  /// No description provided for @tutorialLayerDiagonalBody.
  ///
  /// In en, this message translates to:
  /// **'A line can run corner to corner across a single layer. Both diagonals of each of the four layers count.'**
  String get tutorialLayerDiagonalBody;

  /// No description provided for @tutorialLayerDiagonalBoard.
  ///
  /// In en, this message translates to:
  /// **'Layer 2, highlighted corner to corner: row 1 column 1, row 2 column 2, row 3 column 3, row 4 column 4.'**
  String get tutorialLayerDiagonalBoard;

  /// No description provided for @tutorialSliceDiagonalTitle.
  ///
  /// In en, this message translates to:
  /// **'Diagonals through the layers'**
  String get tutorialSliceDiagonalTitle;

  /// No description provided for @tutorialSliceDiagonalBody.
  ///
  /// In en, this message translates to:
  /// **'Take a slice through the cube — one row, all four layers deep — and it has diagonals of its own. These are the lines new players miss.'**
  String get tutorialSliceDiagonalBody;

  /// No description provided for @tutorialSliceDiagonalBoard.
  ///
  /// In en, this message translates to:
  /// **'Row 1 of every layer, highlighted: column 1 in layer 1, column 2 in layer 2, column 3 in layer 3, column 4 in layer 4.'**
  String get tutorialSliceDiagonalBoard;

  /// No description provided for @tutorialCubeDiagonalTitle.
  ///
  /// In en, this message translates to:
  /// **'Corner to corner'**
  String get tutorialCubeDiagonalTitle;

  /// No description provided for @tutorialCubeDiagonalBody.
  ///
  /// In en, this message translates to:
  /// **'Four lines run right through the middle of the cube, from one corner to the opposite one. They are the hardest to see and the easiest to lose to.'**
  String get tutorialCubeDiagonalBody;

  /// No description provided for @tutorialCubeDiagonalBoard.
  ///
  /// In en, this message translates to:
  /// **'Highlighted from row 1 column 1 of layer 1 to row 4 column 4 of layer 4, moving one row and one column with every layer.'**
  String get tutorialCubeDiagonalBoard;

  /// No description provided for @tutorialRulesDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'That is the whole game'**
  String get tutorialRulesDoneTitle;

  /// No description provided for @tutorialRulesDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Rows, columns, the lines through the layers, and every diagonal — 76 in all. That is everything you need to start playing. What follows is how games are actually won, which you can leave for later.'**
  String get tutorialRulesDoneBody;

  /// Ends the tutorial at the boundary between the rules and the strategy. Counts as completing it: a player who only wanted the rules has finished what they came for (ticket 019).
  ///
  /// In en, this message translates to:
  /// **'Finish here'**
  String get tutorialFinishHere;

  /// No description provided for @tutorialCentreTitle.
  ///
  /// In en, this message translates to:
  /// **'The middle is worth most'**
  String get tutorialCentreTitle;

  /// No description provided for @tutorialCentreBody.
  ///
  /// In en, this message translates to:
  /// **'Squares are not equal. The eight in the middle of the cube — rows and columns 2 and 3, in layers 2 and 3 — each sit on seven different lines. Most squares sit on four. Taking the middle early gives you more ways to win than your opponent has.'**
  String get tutorialCentreBody;

  /// No description provided for @tutorialCentreBoard.
  ///
  /// In en, this message translates to:
  /// **'Eight squares highlighted on an empty board: rows 2 and 3, columns 2 and 3, in layers 2 and 3.'**
  String get tutorialCentreBoard;

  /// No description provided for @tutorialCornersTitle.
  ///
  /// In en, this message translates to:
  /// **'Then the corners'**
  String get tutorialCornersTitle;

  /// No description provided for @tutorialCornersBody.
  ///
  /// In en, this message translates to:
  /// **'The eight corners of the cube also sit on seven lines each — they are the only other squares that do. That is why an opponent that seems to be playing for nothing in particular is often quietly collecting corners.'**
  String get tutorialCornersBody;

  /// No description provided for @tutorialCornersBoard.
  ///
  /// In en, this message translates to:
  /// **'Eight squares highlighted on an empty board: the corner of each layer, at rows 1 and 4, columns 1 and 4, in layers 1 and 4.'**
  String get tutorialCornersBoard;

  /// No description provided for @tutorialDoubleThreatTitle.
  ///
  /// In en, this message translates to:
  /// **'Two threats at once'**
  String get tutorialDoubleThreatTitle;

  /// No description provided for @tutorialDoubleThreatBody.
  ///
  /// In en, this message translates to:
  /// **'One line needing one more piece can be blocked. Two of them cannot. Light has just played the corner, and it completed three of a row and three of a column in the same move. Both highlighted squares now win, and dark has one turn.'**
  String get tutorialDoubleThreatBody;

  /// No description provided for @tutorialDoubleThreatBoard.
  ///
  /// In en, this message translates to:
  /// **'Light has just played layer 1, row 1, column 1. Two squares are highlighted: layer 1 row 1 column 4, and layer 1 row 4 column 1. Either one wins for light, and dark can block only one of them.'**
  String get tutorialDoubleThreatBoard;

  /// No description provided for @tutorialBlockingTitle.
  ///
  /// In en, this message translates to:
  /// **'Blocking before it is too late'**
  String get tutorialBlockingTitle;

  /// No description provided for @tutorialBlockingBody.
  ///
  /// In en, this message translates to:
  /// **'The same thing works against you. Dark holds three of a row in layer 2 and needs one more square. Light has to take the highlighted square now — and watch for the move that would give dark two threats, because by then it is already too late.'**
  String get tutorialBlockingBody;

  /// No description provided for @tutorialBlockingBoard.
  ///
  /// In en, this message translates to:
  /// **'Dark holds layer 2, row 1, columns 1 to 3. The highlighted square is layer 2, row 1, column 4, which light must take.'**
  String get tutorialBlockingBoard;

  /// No description provided for @tutorialStrategyDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'That is how they play'**
  String get tutorialStrategyDoneTitle;

  /// No description provided for @tutorialStrategyDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Take a win, block a loss, build two threats, and stop your opponent building them — over squares that sit on the most lines. That is not a simplification for the tutorial: it is what the computer opponents are doing, from the weakest up. The stronger ones just see further ahead. Try it out below, against one of the gentler ones.'**
  String get tutorialStrategyDoneBody;

  /// The tutorial's closing game. It is never stored, so it never appears in statistics or the finished-games list (ticket 020).
  ///
  /// In en, this message translates to:
  /// **'Practice game'**
  String get practiceTitle;

  /// No description provided for @practicePlay.
  ///
  /// In en, this message translates to:
  /// **'Play a practice game'**
  String get practicePlay;

  /// No description provided for @practiceLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave the practice game'**
  String get practiceLeave;

  /// No description provided for @practiceFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish the tutorial'**
  String get practiceFinish;

  /// Asks for advice about the position on screen. Nothing is shown until it is pressed.
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get practiceHint;

  /// Where a hint is pointing, in the same words the board's own cell labels use, so a screen reader user can find it.
  ///
  /// In en, this message translates to:
  /// **'layer {layer}, row {row}, column {column}'**
  String practiceHintWhere(int layer, int row, int column);

  /// Hints name a concrete reason, never generic encouragement. where comes from practiceHintWhere.
  ///
  /// In en, this message translates to:
  /// **'You can win now — {where} completes a line.'**
  String practiceHintWin(String where);

  /// No description provided for @practiceHintBlock.
  ///
  /// In en, this message translates to:
  /// **'Block at {where}, or your opponent completes a line there on their next move.'**
  String practiceHintBlock(String where);

  /// No description provided for @practiceHintFork.
  ///
  /// In en, this message translates to:
  /// **'Play {where}. It leaves two lines each needing one more piece, and only one of them can be blocked.'**
  String practiceHintFork(String where);

  /// No description provided for @practiceHintBuild.
  ///
  /// In en, this message translates to:
  /// **'Nothing is threatened yet. {where} sits on more lines than any other free square, so it gives you the most ways to win.'**
  String practiceHintBuild(String where);

  /// Opens the move-history scrubber. Available on a game in progress as well as a finished one; reviewing never changes the game (ticket 012).
  ///
  /// In en, this message translates to:
  /// **'Review the moves'**
  String get review;

  /// Leaves the scrubber. On a game in progress this returns the player to their turn, unchanged.
  ///
  /// In en, this message translates to:
  /// **'Back to the game'**
  String get reviewLeave;

  /// Where the scrubber is. Move 0 is the empty board before anybody has played.
  ///
  /// In en, this message translates to:
  /// **'Move {move} of {total}'**
  String moveOf(int move, int total);

  /// No description provided for @reviewStart.
  ///
  /// In en, this message translates to:
  /// **'Before the first move'**
  String get reviewStart;

  /// No description provided for @reviewToStart.
  ///
  /// In en, this message translates to:
  /// **'Jump to the start'**
  String get reviewToStart;

  /// No description provided for @reviewBack.
  ///
  /// In en, this message translates to:
  /// **'Previous move'**
  String get reviewBack;

  /// No description provided for @reviewForward.
  ///
  /// In en, this message translates to:
  /// **'Next move'**
  String get reviewForward;

  /// No description provided for @reviewToEnd.
  ///
  /// In en, this message translates to:
  /// **'Jump to the latest move'**
  String get reviewToEnd;

  /// Overrides the device language. Half the closed testers are Dutch, and a Dutch tester whose phone is set to English cannot otherwise see the Dutch build at all (ticket 028).
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsFollowDevice.
  ///
  /// In en, this message translates to:
  /// **'Follow the device'**
  String get settingsFollowDevice;

  /// The light colour scheme. Deliberately a separate key from sideLight, which names the light pieces — they are the same word in English and need not stay so.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// A language names itself in its own language, so this is identical in every locale file and is not a translation error.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageDutch.
  ///
  /// In en, this message translates to:
  /// **'Nederlands'**
  String get languageDutch;

  /// No description provided for @settingsShowTutorial.
  ///
  /// In en, this message translates to:
  /// **'Show the tutorial again'**
  String get settingsShowTutorial;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;
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
