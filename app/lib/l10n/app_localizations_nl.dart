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
  String get pointsHeading => 'Punten';

  @override
  String pointsValue(int points) {
    final intl.NumberFormat pointsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String pointsString = pointsNumberFormat.format(points);

    return '$pointsString';
  }

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
  String opponentRowSemantics(String name, int rating, String record) {
    return '$name. Rating $rating. $record';
  }

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
  String get botHazel => 'Hazel';

  @override
  String get botSorrel => 'Sorrel';

  @override
  String get botJuniper => 'Juniper';

  @override
  String get botBracken => 'Bracken';

  @override
  String get botRowan => 'Rowan';

  @override
  String get botAspen => 'Aspen';

  @override
  String get botOsprey => 'Osprey';

  @override
  String get botHeron => 'Heron';

  @override
  String get botLynx => 'Lynx';

  @override
  String get botCairn => 'Cairn';

  @override
  String get botFlint => 'Flint';

  @override
  String get botQuadrimPrime => 'Quadrim Prime';

  @override
  String get botQuadrimPrimeShort => 'Q. Prime';

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
      'Speelt min of meer willekeurig en ziet ongeveer één op de drie winstkansen.';

  @override
  String get blurbTwig =>
      'Speelt willekeurig, maar pakt een winst die voor het grijpen ligt.';

  @override
  String get blurbMote => 'Ziet winst en blokkades — als het toevallig oplet.';

  @override
  String get blurbClover =>
      'Let op winst en blokkades, en vergist zich nog vaak.';

  @override
  String get blurbBramble =>
      'Kent alle basisregels en speelt ze zonder enig gevoel voor het bord.';

  @override
  String get blurbWillow =>
      'Verdringt zich in het midden van de kubus en pareert de duidelijke dreigingen.';

  @override
  String get blurbVireo =>
      'Neemt het midden van de kubus, daarna de hoeken. Af en toe slordig.';

  @override
  String get blurbFinch =>
      'Wil elk goed veld in de kubus, en laat er nog wel eens een liggen.';

  @override
  String get blurbKestrel => 'Degelijk in de basis en geeft zelden iets weg.';

  @override
  String get blurbMarlin =>
      'Het volledige positiespel, en nauwelijks een verspilde zet. De eerste echte test.';

  @override
  String get blurbEmber =>
      'Kijkt een zet vooruit en gebruikt dat om te verdedigen.';

  @override
  String get blurbBasalt =>
      'Rekent hard en onthoudt wat het al heeft uitgerekend.';

  @override
  String get blurbOnyx =>
      'Rekent een paar zetten diep. Straft een slordig antwoord af.';

  @override
  String get blurbSable =>
      'Kijkt een zet vooruit en gebruikt dat om aan te vallen.';

  @override
  String get blurbCorvus =>
      'Jaagt op de dubbele dreiging die niet te beantwoorden is.';

  @override
  String get blurbLyra =>
      'Neemt vroeg het centrum en gaat dan op zoek naar een forcerende variant.';

  @override
  String get blurbQuartz =>
      'Zoekt diep en speelt het eindspel exact uit, zonder ooit te gokken.';

  @override
  String get blurbTitan =>
      'De diepste berekening op de ladder die uit geen enkel boek speelt.';

  @override
  String get blurbHazel => 'Ziet winst en blokkades iets vaker dan Mote.';

  @override
  String get blurbSorrel =>
      'Heeft net geleerd een val te zetten, en denkt er soms aan.';

  @override
  String get blurbJuniper =>
      'Kent alle basisregels en speelt in het midden, maar verliest steeds de draad.';

  @override
  String get blurbBracken => 'Kent alle basisregels en gaat voor het midden.';

  @override
  String get blurbRowan =>
      'Neemt het midden vóór de hoeken en speelt een net spel.';

  @override
  String get blurbAspen =>
      'Houdt elk goed veld in de gaten en verspilt zelden een beurt.';

  @override
  String get blurbOsprey =>
      'Speelt op de lijnen die het al opbouwt, niet alleen op goede velden.';

  @override
  String get blurbHeron =>
      'Bouwt geduldig op en wacht tot jij een lijn open laat.';

  @override
  String get blurbLynx =>
      'Kijkt alleen vooruit naar zijn eigen geforceerde winst, en vindt die.';

  @override
  String get blurbCairn =>
      'Controleert wat zijn eigen zet weggeeft voordat het die speelt.';

  @override
  String get blurbFlint =>
      'Denkt verder vooruit naarmate het meer tijd krijgt. Moeilijk te verrassen.';

  @override
  String get blurbOracle =>
      'Opent volgens een bewezen winnende strategie en is niet te verslaan als het begint. Als tweede speler is het alleen heel sterk.';

  @override
  String get blurbQuadrimPrime =>
      'De sterkste tegenstander hier. Onverslaanbaar als het begint; speelt het als tweede, dan verdedigt het met de diepste berekening in het spel.';

  @override
  String tutorialStepOf(int current, int total) {
    return 'Stap $current van $total';
  }

  @override
  String get tutorialNext => 'Verder';

  @override
  String get tutorialBack => 'Terug';

  @override
  String get tutorialDone => 'Klaar';

  @override
  String get tutorialClose => 'Uitleg sluiten';

  @override
  String get tutorialOfferTitle => 'Voor het eerst hier?';

  @override
  String get tutorialOfferBody =>
      'Een korte uitleg laat zien hoe de kubus werkt en hoe je wint. Het duurt een paar minuten en je kunt op elk moment stoppen.';

  @override
  String get tutorialOfferAccept => 'Laat maar zien';

  @override
  String get tutorialOfferDecline => 'Nu niet';

  @override
  String get tutorialGoalTitle => 'Het doel';

  @override
  String get tutorialGoalBody =>
      'Leg vier van jouw stenen op een rechte lijn en je wint. Lijnen lopen in elke richting door de kubus; er zijn er 76.';

  @override
  String get tutorialGoalBoard =>
      'Laag 1, rij 1: vier lichte stenen die de rij vullen, gemarkeerd als voltooide lijn.';

  @override
  String get tutorialLayersTitle => 'Vier lagen, één kubus';

  @override
  String get tutorialLayersBody =>
      'Het bord is een kubus: vier vakjes breed, vier diep en vier hoog. Het wordt getekend als vier lagen onder elkaar, met laag 1 vooraan en laag 4 achteraan. Dezelfde rij en kolom in alle vier de lagen vormt één rechte lijn door de kubus.';

  @override
  String get tutorialLayersBoard =>
      'Rij 2, kolom 2 van elke laag, gemarkeerd: één lijn die van de voorkant van de kubus naar de achterkant loopt.';

  @override
  String get tutorialPlacingTitle => 'Aan zet';

  @override
  String get tutorialPlacingBody =>
      'Tik op een leeg vakje om een steen te leggen. Licht begint, daarna wisselen de spelers elkaar af. Een steen verplaatst nooit meer, en het spel stopt zodra iemand een lijn maakt.';

  @override
  String get tutorialPlacingBoard =>
      'In laag 2 liggen twee lichte stenen en één donkere steen, in laag 3 één donkere steen; alle andere vakjes zijn leeg.';

  @override
  String get tutorialLayerDiagonalTitle => 'Diagonalen binnen een laag';

  @override
  String get tutorialLayerDiagonalBody =>
      'Een lijn kan van hoek tot hoek door één laag lopen. Beide diagonalen van elk van de vier lagen tellen mee.';

  @override
  String get tutorialLayerDiagonalBoard =>
      'Laag 2, gemarkeerd van hoek tot hoek: rij 1 kolom 1, rij 2 kolom 2, rij 3 kolom 3, rij 4 kolom 4.';

  @override
  String get tutorialSliceDiagonalTitle => 'Diagonalen door de lagen heen';

  @override
  String get tutorialSliceDiagonalBody =>
      'Neem een plak door de kubus — één rij, vier lagen diep — en die heeft ook eigen diagonalen. Dit zijn de lijnen die nieuwe spelers over het hoofd zien.';

  @override
  String get tutorialSliceDiagonalBoard =>
      'Rij 1 van elke laag, gemarkeerd: kolom 1 in laag 1, kolom 2 in laag 2, kolom 3 in laag 3, kolom 4 in laag 4.';

  @override
  String get tutorialCubeDiagonalTitle => 'Van hoek tot hoek';

  @override
  String get tutorialCubeDiagonalBody =>
      'Vier lijnen lopen dwars door het midden van de kubus, van de ene hoek naar de tegenoverliggende. Ze zijn het moeilijkst te zien en het makkelijkst om aan te verliezen.';

  @override
  String get tutorialCubeDiagonalBoard =>
      'Gemarkeerd van rij 1 kolom 1 in laag 1 naar rij 4 kolom 4 in laag 4, met elke laag één rij en één kolom verder.';

  @override
  String get tutorialRulesDoneTitle => 'Dat is het hele spel';

  @override
  String get tutorialRulesDoneBody =>
      'Rijen, kolommen, de lijnen door de lagen en alle diagonalen — 76 in totaal. Meer heb je niet nodig om te beginnen. Hierna volgt hoe partijen echt gewonnen worden; dat kun je ook voor later bewaren.';

  @override
  String get tutorialFinishHere => 'Hier stoppen';

  @override
  String get tutorialCentreTitle => 'Het midden is het meest waard';

  @override
  String get tutorialCentreBody =>
      'Vakjes zijn niet gelijkwaardig. De acht vakjes in het midden van de kubus — rij en kolom 2 en 3, in laag 2 en 3 — liggen elk op zeven verschillende lijnen. De meeste vakjes liggen op vier. Wie het midden vroeg pakt, heeft meer manieren om te winnen dan de tegenstander.';

  @override
  String get tutorialCentreBoard =>
      'Acht vakjes gemarkeerd op een leeg bord: rij 2 en 3, kolom 2 en 3, in laag 2 en 3.';

  @override
  String get tutorialCornersTitle => 'Daarna de hoeken';

  @override
  String get tutorialCornersBody =>
      'De acht hoeken van de kubus liggen ook elk op zeven lijnen — het zijn de enige andere vakjes waarvoor dat geldt. Daarom is een tegenstander die nergens op lijkt te spelen vaak stilletjes hoeken aan het verzamelen.';

  @override
  String get tutorialCornersBoard =>
      'Acht vakjes gemarkeerd op een leeg bord: de hoeken op rij 1 en 4, kolom 1 en 4, in laag 1 en 4.';

  @override
  String get tutorialDoubleThreatTitle => 'Twee dreigingen tegelijk';

  @override
  String get tutorialDoubleThreatBody =>
      'Eén lijn die nog één steen nodig heeft, kun je blokkeren. Twee niet. Licht heeft net de hoek gespeeld en maakte daarmee in één zet drie op een rij én drie in een kolom. Beide gemarkeerde vakjes winnen nu, en donker heeft één zet.';

  @override
  String get tutorialDoubleThreatBoard =>
      'Licht heeft net laag 1, rij 1, kolom 1 gespeeld. Twee vakjes zijn gemarkeerd: laag 1 rij 1 kolom 4, en laag 1 rij 4 kolom 1. Beide winnen voor licht, en donker kan er maar één blokkeren.';

  @override
  String get tutorialBlockingTitle => 'Blokkeren voordat het te laat is';

  @override
  String get tutorialBlockingBody =>
      'Hetzelfde werkt tegen jou. Donker heeft drie op een rij in laag 2 en heeft nog één vakje nodig. Licht moet het gemarkeerde vakje nu pakken — en letten op de zet die donker twee dreigingen zou geven, want dan is het al te laat.';

  @override
  String get tutorialBlockingBoard =>
      'Donker heeft laag 2, rij 1, kolom 1 tot en met 3. Het gemarkeerde vakje is laag 2, rij 1, kolom 4, dat licht moet pakken.';

  @override
  String get tutorialStrategyDoneTitle => 'Zo spelen ze';

  @override
  String get tutorialStrategyDoneBody =>
      'Pak een winst, blokkeer een verlies, bouw twee dreigingen en verhinder dat je tegenstander dat doet — op de vakjes die op de meeste lijnen liggen. Dat is geen vereenvoudiging voor de uitleg: het is precies wat de computertegenstanders doen, van de zwakste af. De sterkere kijken alleen verder vooruit. Probeer het hieronder meteen uit, tegen een van de zachtaardige.';

  @override
  String get practiceTitle => 'Oefenpartij';

  @override
  String get practicePlay => 'Speel een oefenpartij';

  @override
  String get practiceLeave => 'Oefenpartij verlaten';

  @override
  String get practiceFinish => 'Uitleg afronden';

  @override
  String get practiceHint => 'Tip';

  @override
  String practiceHintWhere(int layer, int row, int column) {
    return 'laag $layer, rij $row, kolom $column';
  }

  @override
  String practiceHintWin(String where) {
    return 'Je kunt nu winnen — $where maakt een lijn af.';
  }

  @override
  String practiceHintBlock(String where) {
    return 'Blokkeer op $where, anders maakt je tegenstander daar bij de volgende zet een lijn af.';
  }

  @override
  String practiceHintFork(String where) {
    return 'Speel $where. Dat levert twee lijnen op die elk nog één steen nodig hebben, en er kan er maar één geblokkeerd worden.';
  }

  @override
  String practiceHintBuild(String where) {
    return 'Er wordt nog niets bedreigd. $where ligt op meer lijnen dan elk ander vrij vakje en geeft je dus de meeste manieren om te winnen.';
  }

  @override
  String get review => 'Zetten teruglezen';

  @override
  String get reviewLeave => 'Terug naar de partij';

  @override
  String moveOf(int move, int total) {
    return 'Zet $move van $total';
  }

  @override
  String get reviewStart => 'Voor de eerste zet';

  @override
  String get reviewToStart => 'Naar het begin';

  @override
  String get reviewBack => 'Vorige zet';

  @override
  String get reviewForward => 'Volgende zet';

  @override
  String get reviewToEnd => 'Naar de laatste zet';

  @override
  String get settingsLanguage => 'Taal';

  @override
  String get settingsFollowDevice => 'Volg het toestel';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageDutch => 'Nederlands';

  @override
  String get settingsShowTutorial => 'Uitleg opnieuw bekijken';

  @override
  String get settingsPurchases => 'Aankopen';

  @override
  String get settingsRestorePurchases => 'Aankopen herstellen';

  @override
  String get settingsRestoreExplanation =>
      'Al iets gekocht? Hiermee krijg je het terug zonder opnieuw te betalen.';

  @override
  String get settingsRestoreDone => 'Aankopen hersteld.';

  @override
  String get settingsRestoreNothing => 'Niets te herstellen op dit account.';

  @override
  String get settingsRestoreUnavailable => 'De winkel is nu niet beschikbaar.';

  @override
  String get paywallDailyTitle => 'Dat waren je drie partijen van vandaag';

  @override
  String get paywallDailyBody =>
      'Je kunt drie partijen per dag tegen de computer beginnen. De volgende kan morgen.';

  @override
  String get paywallWeeklyTitle => 'Dat waren je negen partijen van deze week';

  @override
  String get paywallWeeklyBody =>
      'Je kunt negen partijen per week tegen de computer beginnen. De volgende kan maandag.';

  @override
  String get paywallFooter =>
      'Partijen die al begonnen zijn kun je altijd afmaken, en samen spelen op één toestel is nooit beperkt.';

  @override
  String get paywallSeeOptions => 'Bekijk de mogelijkheden';

  @override
  String get paywallNotNow => 'Niet nu';

  @override
  String get shopTitle => 'Winkel';

  @override
  String get shopUnlimitedName => 'Onbeperkt spelen';

  @override
  String get shopUnlimitedBody =>
      'Begin zoveel partijen tegen de computer als je wilt. Per jaar, elk moment op te zeggen.';

  @override
  String get shopUnlockAllName => 'Alle tegenstanders vrijspelen';

  @override
  String get shopUnlockAllBody =>
      'Meteen alle tegenstanders op de ladder, in plaats van ze met punten te verdienen.';

  @override
  String get shopUnlockAllCaveat =>
      'Dit verandert niet hoeveel partijen je kunt beginnen. Je speelt er nog steeds drie per dag, tenzij je ook onbeperkt spelen hebt.';

  @override
  String get shopOwned => 'In bezit';

  @override
  String get shopBuy => 'Kopen';

  @override
  String get shopUnavailable => 'De winkel is nu niet beschikbaar.';

  @override
  String get shopMeterNote =>
      'Je gratis partijen worden op dit toestel geteld.';

  @override
  String get questVolumeLocked => 'Vereist onbeperkt spelen';

  @override
  String resultGamesLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nog $count partijen vandaag',
      one: 'Nog 1 partij vandaag',
      zero: 'Geen partijen meer vandaag',
    );
    return '$_temp0';
  }

  @override
  String get settingsAbout => 'Over';

  @override
  String get yourPath => 'Jouw pad';

  @override
  String get pathScrollLeft => 'Toon zwakkere tegenstanders';

  @override
  String get pathScrollRight => 'Toon sterkere tegenstanders';

  @override
  String get locked => 'Op slot';

  @override
  String unlockCost(int cost) {
    final intl.NumberFormat costNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String costString = costNumberFormat.format(cost);

    return '$costString punten';
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

    return '$haveString van $costString';
  }

  @override
  String get unlockAction => 'Vrijspelen';

  @override
  String unlockConfirmTitle(String name) {
    return '$name vrijspelen?';
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

    return 'Dit kost $costString punten en je houdt $leftString over.';
  }

  @override
  String unlockConfirmBook(String name) {
    return '$name speelt een bewezen strategie en is onverslaanbaar als hij begint. Vanaf de tweede zet speelt hij op zoekkracht, net als de rest.';
  }

  @override
  String unlockNotAffordable(int short) {
    final intl.NumberFormat shortNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String shortString = shortNumberFormat.format(short);

    return 'Je hebt nog $shortString punten nodig.';
  }

  @override
  String unlockDone(String name) {
    return '$name vrijgespeeld.';
  }

  @override
  String starsLabel(int count) {
    return '$count van 3 sterren';
  }

  @override
  String get neverPlayed => 'Nog niet gespeeld';

  @override
  String pathTileSemantics(String name, int rating, String state) {
    return '$name, waardering $rating. $state';
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

    return 'Op slot. $costString punten, je hebt er $haveString.';
  }

  @override
  String get quests => 'Opdrachten';

  @override
  String questFirstWin(String name) {
    return 'Eerste winst tegen $name';
  }

  @override
  String questFirstWinSecond(String name) {
    return 'Eerste winst als tweede speler tegen $name';
  }

  @override
  String questGamesInDay(int count) {
    return '$count partijen op één dag';
  }

  @override
  String questDaysInRow(int count) {
    return '$count dagen op rij';
  }

  @override
  String questProgressValue(int current, int target) {
    return '$current van $target';
  }

  @override
  String questSemantics(String name, int current, int target) {
    return '$name. $current van $target.';
  }

  @override
  String get questAchievedTitle => 'Behaald';

  @override
  String questAward(int points) {
    return '+$points';
  }

  @override
  String questAwardSemantics(String name, int points) {
    return '$name. Behaald, $points punten.';
  }

  @override
  String get streakHeading => 'Reeks';

  @override
  String streakValue(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dagen op rij',
      one: '1 dag op rij',
      zero: 'Nog geen dagen',
    );
    return '$_temp0';
  }

  @override
  String get trendHeading => 'Laatste 10 partijen';

  @override
  String trendSemantics(String change) {
    return 'Laatste 10 partijen: $change.';
  }

  @override
  String trendChange(String change) {
    return '$change';
  }

  @override
  String get relativeToday => 'Vandaag';

  @override
  String get relativeYesterday => 'Gisteren';

  @override
  String relativeDaysAgo(int days) {
    return '$days dagen geleden';
  }

  @override
  String get challengeAgain => 'Opnieuw spelen';

  @override
  String get showMore => 'Meer tonen';

  @override
  String get historyTitle => 'Geschiedenis';

  @override
  String pointsEarnedLine(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '+$points punten',
      one: '+1 punt',
    );
    return '$_temp0';
  }

  @override
  String get passAndPlayNoPoints => 'Samen spelen levert geen punten op.';

  @override
  String unlockNowAffordable(String name) {
    return 'Je kunt $name nu vrijspelen.';
  }

  @override
  String opponentHeadline(String name, int rating, String tier) {
    return '$name. Rating $rating. $tier.';
  }

  @override
  String winPays(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'Winst levert $points punten op',
      one: 'Winst levert 1 punt op',
    );
    return '$_temp0';
  }

  @override
  String get playThisOpponent => 'Start een partij';

  @override
  String get questsCompleted => 'Onlangs voltooid';

  @override
  String questAwardValue(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '+$points punten',
      one: '+1 punt',
    );
    return '$_temp0';
  }
}
