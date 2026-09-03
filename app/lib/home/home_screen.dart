import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:quadrim_engine/quadrim_engine.dart';
import 'package:quadrim_progression/quadrim_progression.dart';

import '../data/documents.dart';
import '../data/game_repository.dart';
import '../data/home_summary.dart';
import '../data/points_fold.dart' as points_fold;
import '../data/rating_fold.dart' as fold;
import '../design/art.dart';
import '../design/forest.dart';
import '../game/game_screen.dart';
import '../game/opponent_screen.dart';
import '../l10n/app_localizations.dart';
import '../data/meter_fold.dart' as meter_fold;
import '../shop/paywall.dart';
import '../shop/shop.dart';
import '../settings/settings_screen.dart';
import '../theme.dart';
import '../tutorial/tutorial_screen.dart';
import 'active_games.dart';
import 'completed_quests.dart';
import 'finished_games.dart';
import 'history_screen.dart';
import 'opponent_detail.dart';
import 'quests_section.dart';
import 'rating_card.dart';
import 'section_widgets.dart';
import 'unlock_confirmation.dart';
import 'your_path.dart';

/// The app's home: what the player has done, what they are in the middle of,
/// and the one button that starts something new.
///
/// Everything it says about finished games comes from a single list of them,
/// folded once per change into a [HomeSummary] (criterion 18). Nothing here is
/// stored — a stored total is a second copy of what the games already say, and
/// the two drift the first time one is deleted.
///
/// This file holds the screen's state and its composition, and nothing else.
/// Each section is its own file beside it (ticket 030), because §11.3 adds a
/// trend graph, a points balance, a Your Path row and a quests section to this
/// screen, and every remaining 0.1 ticket touches it.
///
/// (The class's own doc comment is below; the constant between them belongs to
/// the layout rather than to the screen's contract.)

/// How tall the *wood* is on the two carved signs at the bottom of the main
/// screen — not how tall their pictures are, which differ by whatever leaf and
/// margin each one carries (D301). Fixed rather than intrinsic: the wood is a
/// picture and cannot grow, so the words written on it do not grow either.
const double _kSignPlank = 46;

/// The strip the two of them sit in. Both pictures are taller than their plank
/// and by different amounts, so the row is given room for the taller.
const double _kSignRow = 104;

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.repository,
    required this.settings,
    required this.unlocks,
    this.shop,
    this.random,
    this.now,
  });

  final GameRepository repository;

  /// What the player has bought. Separate contract from [repository] even
  /// though 0.1's one implementation satisfies both.
  final UnlockRepository unlocks;

  /// Null when no store is attached; the settings screen then omits its
  /// restore row entirely (ticket 046).
  final Shop? shop;

  /// Read on first frame to decide whether to offer the tutorial, and written
  /// once the offer has been made. Separate from [repository] because they are
  /// separate contracts, even though 0.1's one implementation satisfies both.
  final SettingsRepository settings;

  /// Injected so a test can pin who opens a new game. Null means unseeded.
  final Random? random;

  /// Local time, injected so a test can put the player on a chosen day.
  ///
  /// The quest fold and the streak both read it. It is a parameter here for
  /// the same reason it is one in the package: the calendar is the one thing a
  /// fixture cannot arrange by writing games (spec §9.2), and a streak that
  /// could only be tested by waiting a day could not be tested.
  final DateTime Function()? now;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription<List<GameDocument>>? _active;
  StreamSubscription<List<GameDocument>>? _completed;
  StreamSubscription<List<UnlockDocument>>? _unlocks;
  StreamSubscription<SettingsDocument>? _settingsSub;
  AppLifecycleListener? _lifecycle;

  List<GameDocument> _activeGames = const [];
  List<GameDocument> _completedGames = const [];

  /// How many moves an unfinished game needs before it is worth listing.
  ///
  /// Zero moves is a board the player has not touched; one is the opening the
  /// computer played before they saw it. Neither is a game in progress in any
  /// sense the player would recognise, and listing them filled the panel with
  /// rows nobody had played (D321).
  static const int _kListedFrom = 2;

  /// The unfinished games the player is shown. [_activeGames] keeps all of
  /// them, because [_start] has to find the one it must resume.
  List<GameDocument> get _startedGames =>
      _activeGames.where((game) => game.moves.length >= _kListedFrom).toList();
  HomeSummary _summary = HomeSummary.empty;
  SettingsDocument? _settingsDoc;

  /// What the meter says right now, folded rather than stored.
  ///
  /// Both lists, because a game started today may still be unfinished — the
  /// meter counts games *started*, and counting only completed ones would let
  /// a player open three games and start a fourth.
  MeterState get _meter => meterState(
        games: meter_fold.startedGamesFrom([..._activeGames, ..._completedGames]),
        now: (widget.now ?? DateTime.now)(),
        freeMonth: _settingsDoc == null
            ? null
            : meter_fold.freeMonthFrom(_settingsDoc!),
      );
  List<UnlockDocument> _unlockList = const [];

  /// The four quests closest to completion, folded from the same list of
  /// finished games as the rating and the balance. Nothing about them is
  /// stored (spec §8.8).
  List<QuestStatus> _quests = const [];

  /// The four finished most recently, from the *same* fold — `questsFrom` is
  /// called once and read twice, because folding fifty-three quests over the
  /// whole history a second time to sort the same list differently would be a
  /// second pass for a `sort`.
  List<QuestStatus> _completedQuests = const [];

  /// Consecutive days played, folded with the quests from the same list.
  int _streak = 0;

  /// True while a purchase is in flight, which is what stops a second tap
  /// buying a second time before the first write lands.
  bool _unlocking = false;
  /// What each finished ladder game did to the rating, by game id. Computed
  /// with the summary rather than per row, which would re-fold the history
  /// once for every row on the screen.
  Map<String, int> _deltas = const {};

  /// The rating after each ladder game, for the trend graph. Computed with the
  /// summary rather than in the card, so the whole screen folds the history
  /// once per change (ticket 035).
  List<int> _series = const [];

  /// How many finished games the main screen shows before offering the rest on
  /// a screen of their own.
  static const int _recentLimit = 10;

  List<GameDocument> get _recentGames => _completedGames.length <= _recentLimit
      ? _completedGames
      : _completedGames.sublist(0, _recentLimit);

  /// Everything the main screen derives from the finished games.
  ///
  /// Called with a new list when one lands, and with the list it already has
  /// when the app resumes — the second is what keeps the day-shaped answers
  /// honest, since `today` is read here rather than stored.
  ///
  /// Must run inside `setState`; it assigns fields and notifies nothing.
  void _refold(List<GameDocument> games) {
    _completedGames = games;
    _summary = HomeSummary.from(games);
    _deltas = fold.ratingDeltas(games);
    _series = fold.computerRatingSeries(games);
    final today = (widget.now ?? DateTime.now)();
    final quests = points_fold.questsFrom(games, today);
    _quests = closestQuests(quests);
    _completedQuests = recentlyAchieved(quests);
    _streak = points_fold.streakFrom(games, today);
  }

  @override
  void initState() {
    super.initState();
    _active = widget.repository
        .watchActiveGames()
        .listen((games) => setState(() => _activeGames = games));
    _settingsSub = widget.settings
        .watchSettings()
        .listen((doc) => setState(() => _settingsDoc = doc));
    // Watched rather than loaded once: the criteria ask both for a single
    // list folded four ways and for the screen to update when a game finishes,
    // and a stream gives one list per change rather than four sweeps (D158).
    _completed = widget.repository
        .watchCompletedGames()
        .listen((games) => setState(() => _refold(games)));
    // **And again when the app comes back, because the day may have changed.**
    // Everything day-shaped here — the streak, and the progress on every "in
    // one day" quest — is folded against a `today` read at fold time, and the
    // fold above only runs when a game finishes. A player who leaves the app
    // open overnight, or reopens it from the background the next morning,
    // would otherwise be shown yesterday's answers until they finished a game
    // (D317).
    _lifecycle = AppLifecycleListener(
      onResume: () => setState(() => _refold(_completedGames)),
    );
    // After the first frame, not during it: showing a dialog needs a Navigator
    // above this widget, and there is none until the tree is built.
    _unlocks = widget.unlocks
        .watchUnlocks()
        .listen((list) => setState(() => _unlockList = list));
    WidgetsBinding.instance.addPostFrameCallback((_) => _offerTutorial());
  }

  /// Offers the tutorial the first time the app is opened, once.
  ///
  /// The offer is recorded before it is shown rather than after. The player
  /// can dismiss this dialog by tapping outside it, which returns no answer at
  /// all; recording afterwards would mean that dismissal re-armed the offer for
  /// the next launch, and repeating a question the player has already waved
  /// away is the failure mode worth designing out (D193).
  Future<void> _offerTutorial() async {
    final settings = await widget.settings.loadSettings();
    if (settings.tutorialOffered || settings.tutorialCompleted) return;
    await widget.settings.saveSettings(settings.copyWith(tutorialOffered: true));
    if (!mounted) return;
    if (await showTutorialOffer(context) && mounted) await _openTutorial();
  }

  Future<void> _openTutorial() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TutorialScreen(settings: widget.settings),
      ),
    );
  }

  @override
  void dispose() {
    _active?.cancel();
    _completed?.cancel();
    _unlocks?.cancel();
    _lifecycle?.dispose();
    _settingsSub?.cancel();
    super.dispose();
  }

  /// Everything the player may play: what they bought, plus what losing handed
  /// back.
  ///
  /// **The one place the two are joined.** Every screen that asks whether an
  /// opponent is playable is handed this set rather than computing its own, so
  /// a caller cannot see the stored unlocks and miss the derived ones (D382).
  Set<String> get _unlockedIds => {
        for (final unlock in _unlockList) unlock.opponentId,
        ..._mercyIds,
      };

  /// The mercy rungs earned back, folded from the same summary the rest of this
  /// screen reads (D382). Nothing about them is stored.
  Set<String> get _mercyIds {
    final played = <String>{};
    final lostTo = <String>{};
    for (final record in _summary.byOpponent) {
      final id = botIdOf(record.opponent);
      if (id == null) continue;
      played.add(id);
      if (record.losses > 0) lostTo.add(id);
    }
    return mercyUnlocks(played: played, lostTo: lostTo);
  }

  /// The balance: earned minus the prices **actually paid**, clamped at zero.
  ///
  /// The prices come from the stored records rather than from the cost table,
  /// so re-tuning a cost can never retroactively bankrupt someone who already
  /// spent at the old price (spec §8.8).
  int get _balance => balance(
        earned: _summary.points,
        pricesPaid: [for (final unlock in _unlockList) unlock.pricePaid],
      );

  Future<void> _unlock(BotConfig bot, int price) async {
    if (_unlocking) return;
    setState(() => _unlocking = true);
    try {
      await runUnlock(
        context,
        bot: bot,
        price: price,
        points: _balance,
        purchase: (id, paid) =>
            widget.unlocks.purchase(id, pricePaid: paid),
        shop: widget.shop,
      );
    } finally {
      if (mounted) setState(() => _unlocking = false);
    }
  }

  Future<void> _openGame(String id) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(
          repository: widget.repository,
          gameId: id,
          random: widget.random,
          now: widget.now,
          unlocks: widget.unlocks,
          settings: widget.settings,
        ),
      ),
    );
  }

  /// Mode first, then — for a computer game — which of the twenty.
  ///
  /// Backing out of the opponent list cancels the whole flow rather than
  /// falling back to a default opponent: a game against somebody the player
  /// did not choose is worse than no game (ticket 011).
  Future<void> _newGame() async {
    final l10n = AppLocalizations.of(context)!;
    final mode = await showModalBottomSheet<GameMode>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.computer_outlined),
              title: Text(l10n.playTheComputer),
              onTap: () => Navigator.of(context).pop(GameMode.vsComputer),
            ),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: Text(l10n.passAndPlay),
              onTap: () => Navigator.of(context).pop(GameMode.passAndPlay),
            ),
          ],
        ),
      ),
    );
    if (mode == null || !mounted) return;

    // **Refused before the player is made to choose an opponent.** `_start`
    // guards too, and that is the guard that counts — it is the single place a
    // game is created, so the challenge and rematch buttons cannot slip past
    // it. This one exists so the wall does not arrive after a choice, which
    // reads as the app changing its mind.
    if (mode == GameMode.vsComputer && !_meter.canStart) {
      await showPaywall(context, limit: _meter.blocked, shop: widget.shop);
      return;
    }

    // **Refused before the player is made to choose an opponent.** `_start`
    // guards too, and that is the guard that counts — it is the single place a
    // game is created, so the challenge and rematch buttons cannot slip past
    // it. This one exists so the wall does not arrive after a choice, which
    // reads as the app changing its mind.
    if (mode == GameMode.vsComputer && !_meter.canStart) {
      await showPaywall(context, limit: _meter.blocked, shop: widget.shop);
      return;
    }

    BotConfig? bot;
    if (mode == GameMode.vsComputer) {
      bot = await Navigator.of(context).push<BotConfig>(
        MaterialPageRoute<BotConfig>(
          builder: (_) => OpponentScreen(
            playerRating: _summary.computerRating,
            unlocked: _unlockedIds,
            points: _balance,
            onUnlock: _unlock,
          ),
        ),
      );
      if (bot == null || !mounted) return;
    }

    await _start(mode, bot);
  }

  /// Creates a game and opens it. The one place a game is started, so the
  /// challenge button on a finished row cannot drift from the new-game flow.
  ///
  /// **Against the computer there is only ever one unfinished game per
  /// opponent**, and asking for a new one resumes it. Who moves first is drawn
  /// once, when the game is created; without this, leaving a game where the
  /// computer opened and starting another draws again, so a player who wanted
  /// the first move could keep asking until they got it — and the first move is
  /// worth real rating in a game this small (D322).
  Future<void> _start(GameMode mode, BotConfig? bot) async {
    final opponent = bot == null ? kGuestOpponent : botOpponent(bot.id);
    if (mode == GameMode.vsComputer) {
      for (final game in _activeGames) {
        if (game.mode == mode && game.opponent == opponent) {
          await _openGame(game.id);
          return;
        }
      }
    }
    // **The wall, and it is here rather than earlier for two reasons.** The
    // resume loop above has already returned for a game in progress, so
    // finishing one is never refused (§4.2); and `mode` is checked, so pass and
    // play is never refused either. The tutorial's practice game never reaches
    // this method at all — it is not stored, which is also why it is not
    // metered.
    if (mode == GameMode.vsComputer) {
      final meter = _meter;
      if (!meter.canStart) {
        await showPaywall(context, limit: meter.blocked, shop: widget.shop);
        return;
      }
    }
    final game = await widget.repository.createGame(
      mode: mode,
      opponent: opponent,
      opponentRating: bot?.rating,
      startingSeat: (widget.random ?? Random()).nextInt(2),
    );
    if (!mounted) return;
    await _openGame(game.id);
  }

  /// What the challenge button on [game] does, or null if there is nobody to
  /// challenge — pass and play, an opponent this build does not know, or one
  /// the player has not unlocked. The last case is not hypothetical: a game
  /// against an opponent whose unlock was refunded is still in the history.
  VoidCallback? _challenge(GameDocument game) {
    final id = botIdOf(game.opponent);
    if (id == null) return null;
    final bot = botById(id);
    if (bot == null || !isUnlocked(id, _unlockedIds)) return null;
    return () => _start(GameMode.vsComputer, bot);
  }

  /// One opponent's page. It is handed everything it shows rather than a
  /// repository, so it stays a view over the same folds the main screen already
  /// has and adds no second source of truth (D288).
  Future<void> _openOpponent(BotConfig bot) async {
    final index = rosterIndexOf(bot.id);
    if (index == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OpponentDetail(
          bot: bot,
          record: _summary.recordFor(bot.id),
          playerRating: _summary.computerRating,
          locked: !isUnlocked(bot.id, _unlockedIds),
          price: unlockCost(index),
          points: _balance,
          onStart: () {
            // Pop first, so returning from the game lands on the main screen
            // rather than back on the page that started it.
            Navigator.of(context).pop();
            unawaited(_start(GameMode.vsComputer, bot));
          },
          onUnlock: _unlocking ? null : () => unawaited(_unlock(bot, unlockCost(index))),
        ),
      ),
    );
  }

  Future<void> _openHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HistoryScreen(
          games: _completedGames,
          deltas: _deltas,
          now: (widget.now ?? DateTime.now)(),
          onOpen: (game) => _openGame(game.id),
          onChallenge: _challenge,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ForestScaffold(
      appBar: AppBar(
        // The mark, then the name, in the mockup's order. The logo is
        // decorative — the title beside it says the same word out loud, and a
        // picture of a letter Q announced as well would say it twice.
        title: Row(
          children: [
            // **The decorative mark yields to the name at large text scale**
            // (ticket 021). At 2x on a 320pt phone the logo, its gap and the
            // title need 257pt of the 240 the bar allows, and the row
            // overflowed by 17. Dropping the logo returns exactly the 40 that
            // closes it, and costs nothing a screen reader was ever told
            // about: the mark is already excluded from semantics because the
            // title beside it says the same word.
            //
            // The `Flexible` below is the guarantee rather than this is — a
            // threshold is a number that some future font will step past. It
            // ellipsises in the case the threshold misses; the threshold is
            // what keeps that case from arising.
            if (MediaQuery.textScalerOf(context).scale(16) < 24) ...[
              // Both dimensions given. An `Image` reports zero size until it
              // has decoded, so a logo with only a height is a zero-width gap
              // on the first frame and forever in a widget test.
              const ExcludeSemantics(
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: Image(
                    image: AssetImage(Art.logo),
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Text(l10n.appTitle, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settings,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SettingsScreen(
                    settings: widget.settings, shop: widget.shop),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Slivers rather than a ListView of children: the finished-games
            // list has no upper bound, and `ListView(children: [...])` builds
            // every one of them whether or not it is on screen. The fixed
            // sections above it are cheap and stay eager.
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, kSectionGap),
                    sliver: SliverList.list(
                      children: [
                        RatingCard(
                            summary: _summary,
                            balance: _balance,
                            streak: _streak,
                            series: _series),
                      ],
                    ),
                  ),
                  // The one section laid out at the full width of the screen:
                  // its scroll arrows hang off the outside of its panel, and a
                  // widget positioned beyond its parent's box is painted but
                  // never hit-tested (D319). It applies the 16 itself.
                  SliverToBoxAdapter(
                    child: YourPath(
                      summary: _summary,
                      balance: _balance,
                      unlocked: _unlockedIds,
                      onUnlock: _unlocking ? null : _unlock,
                      onOpen: _openOpponent,
                    ),
                  ),
                  // The quests panel is not built before the first finished
                  // game. "Closest to completion" ranks fifty-three quests that
                  // are all at zero, so the four it picks are arbitrary — and
                  // they would push the empty state off the first screen, which
                  // is the one moment it exists for.
                  // Directly under Your Path, and above the quests: a game
                  // waiting to be finished is the most actionable thing on the
                  // screen, and it used to sit below two panels about what has
                  // already happened.
                  if (_startedGames.isNotEmpty)
                    ...gameSectionSlivers(
                      heading: l10n.inProgress,
                      games: _startedGames,
                      tile: (game) =>
                          ActiveGameTile(game: game, onTap: () => _openGame(game.id)),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    sliver: SliverList.list(
                      children: [
                        if (_completedGames.isNotEmpty) ...[
                          const SizedBox(height: kSectionGap),
                          QuestsSection(
                            quests: _quests,
                            // Capped unless the free month still covers today
                            // or the subscription is owned. The entitlement
                            // starts empty and fills in after the store
                            // answers (D349), so this can flip shortly after
                            // launch — which is right: it must never claim a
                            // rung is unreachable for someone who has paid.
                            capped: !_meter.inFreeMonth &&
                                !(widget.shop?.entitlement.value.unlimited ??
                                    false),
                          ),
                        ],
                        // Only once something has actually been finished. A
                        // heading over an empty list is a heading for nothing.
                        if (_completedQuests.isNotEmpty) ...[
                          const SizedBox(height: kSectionGap),
                          CompletedQuestsSection(quests: _completedQuests),
                        ],
                        // On a card, not loose on the background. It is the
                        // only text on this screen that would otherwise sit
                        // directly on a photograph of leaves.
                        if (_startedGames.isEmpty && _completedGames.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(l10n.noGamesYet,
                                    textAlign: TextAlign.center,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_completedGames.isNotEmpty) ...[
                    ...gameSectionSlivers(
                      heading: l10n.finishedGames,
                      games: _recentGames,
                      tile: (game) => FinishedGameTile(
                        game: game,
                        delta: _deltas[game.id],
                        now: (widget.now ?? DateTime.now)(),
                        onChallenge: _challenge(game),
                        onTap: () => _openGame(game.id),
                      ),
                    ),
                    // A screen, not an expanding list: expanding in place would
                    // push the primary button off the bottom of a screen that
                    // already carries six sections (ticket 035).
                    if (_completedGames.length > _recentGames.length)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                        sliver: SliverToBoxAdapter(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            // Cream, not the theme's bronze: this is the one
                            // control on the screen that sits on the forest
                            // rather than on parchment, and bronze on leaves
                            // is not a legible pairing.
                            child: TextButton(
                              onPressed: _openHistory,
                              style: TextButton.styleFrom(
                                  foregroundColor: QuadrimPalette.cream),
                              child: Text(l10n.showMore),
                            ),
                          ),
                        ),
                      ),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                ],
              ),
            ),
          ],
        ),
      ),
      // The two carved plaques of the mockup, pinned below the scroll so the
      // primary action never scrolls away. `NEW GAME` takes the width it can
      // and `Tutorial` sits to its right, which is where the mockup puts it.
      bottom: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          // A fixed height, not one the artwork chooses: the plaques are
          // decorative and must not resize when a picture finishes decoding,
          // and this strip is pinned above the bottom edge on every phone.
          child: SizedBox(
            height: _kSignRow,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: SignButton(
                    art: SignArt.newGame,
                    caption: l10n.newGame,
                    onPressed: _newGame,
                    plankHeight: _kSignPlank,
                  ),
                ),
                const SizedBox(width: 8),
                // Its own aspect rather than a square. The tutorial board is
                // 3:2 and the word written on it has to be legible; squeezing
                // it into the height made the caption too small to read.
                SignButton(
                  art: SignArt.tutorial,
                  caption: l10n.tutorial,
                  onPressed: _openTutorial,
                  plankHeight: _kSignPlank,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// The placeholder screen that stood in for the tutorial and settings (D159)
// is gone: ticket 018 replaced one route and ticket 028 the other, which is
// what it was for. The strategy-dictionary attribution it carried moved with
// it, to SettingsScreen — there was never a build in which that credit was
// merely planned (D174).
