import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:quadrim_engine/quadrim_engine.dart';
import 'package:quadrim_progression/quadrim_progression.dart';

import '../data/documents.dart';
import '../data/game_repository.dart';
import '../data/points_fold.dart' as points_fold;
import '../data/rating_fold.dart';
import '../home/quests_section.dart';
import '../home/unlock_confirmation.dart';
import '../l10n/app_localizations.dart';
import 'board_view.dart';
import 'opponent_name.dart';

/// How long a computer opponent visibly takes over its move. Pebble decides
/// in microseconds; without a pause its piece would simply appear, which
/// reads as a rendering glitch rather than as a turn (ticket 006).
const Duration kBotMoveDelay = Duration(milliseconds: 550);

/// How the screen obtains a computer opponent's move.
///
/// Injected rather than called directly because the two callers need opposite
/// things: the app must not run a four-ply search on the interface thread,
/// and a widget test cannot wait for a real isolate — `testWidgets` runs in a
/// fake-async zone where an isolate's future never completes (D153).
typedef OpponentMove = Future<int> Function(
    List<int> moves, BotConfig bot, Random random);

/// The app's implementation: the search runs in a background isolate.
///
/// Onyx and Sable take tens of milliseconds for a typical move and up to a
/// couple of hundred for the worst one measured (D152); on the interface
/// thread that is a visible stutter in the middle of the opponent's turn.
/// The seed is drawn on this side and sent as an integer, because a [Random]
/// cannot cross an isolate boundary — which also keeps the move reproducible
/// from an injected seeded source.
Future<int> chooseMoveInBackground(
        List<int> moves, BotConfig bot, Random random) =>
    compute(_chooseMoveIsolate, (moves, bot.id, random.nextInt(1 << 31)));

int _chooseMoveIsolate((List<int>, String, int) request) {
  final (moves, botId, seed) = request;
  return chooseMove(GameState.fromMoves(moves), botById(botId)!, Random(seed))
      .index;
}

/// The test implementation: the same choice, made inline.
Future<int> chooseMoveInline(List<int> moves, BotConfig bot, Random random) =>
    Future.value(chooseMove(GameState.fromMoves(moves), bot, random).index);

/// One game, whether against a person sharing the device or a computer
/// opponent. The first player always holds the light pieces.
///
/// This screen keeps no board of its own: it replays the stored move list and
/// every move goes through [GameRepository] (criterion S4).
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.repository,
    required this.gameId,
    this.random,
    this.now,
    this.unlocks,
    this.opponentMove = chooseMoveInBackground,
  });

  final GameRepository repository;
  final String gameId;

  /// Injected so a test can pin what the opponent plays. Null means a fresh
  /// unseeded source, which is what the app uses.
  final Random? random;

  /// Local time, injected so a test can put the player on a chosen day. Read
  /// only when the game ends, to fold the quests it achieved.
  final DateTime Function()? now;

  /// Read once, when a game ends, to decide whether the win just paid for the
  /// next opponent. Optional rather than required: the panel simply makes no
  /// offer without it, which is the right behaviour for a caller that has no
  /// unlocks to speak of, and keeps a screen about *this game* from depending
  /// on a second repository to draw its board.
  final UnlockRepository? unlocks;

  /// How the opponent's move is computed. Defaults to a background isolate.
  final OpponentMove opponentMove;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  StreamSubscription<GameDocument?>? _subscription;
  late final Random _random = widget.random ?? Random();
  GameDocument? _game;

  /// The computer-ladder rating either side of this game, computed once the
  /// game completes. Null while the game is running, or in pass-and-play.
  ({int before, int after})? _rating;

  /// What this game achieved that the history before it had not.
  ///
  /// Derived by folding the quests twice — with this game and without it —
  /// rather than by storing anything, which is the same discipline the rating
  /// and the balance follow (spec §8.8). Empty until the game completes.
  List<QuestStatus> _achieved = const [];

  /// What this game paid, before any quest it also achieved. Zero for a draw,
  /// a loss, and pass and play.
  int _points = 0;

  /// The opponent this game's points just paid for, or null. Offered here
  /// because this is the moment the player is most interested, and making them
  /// navigate to find out wastes it (ticket 035).
  BotConfig? _offer;

  /// True from the moment a move is dispatched until it has been stored and
  /// observed. It guards both directions:
  ///
  /// - the opponent's turn is noticed once, not on every stream re-emit;
  /// - a second tap landing before the first has round-tripped is ignored.
  ///   Without that, tapping twice quickly in a game against the computer
  ///   stores both moves and the player takes the opponent's turn too.
  bool _busy = false;

  /// Which position is on screen while reviewing: 0 for the empty board,
  /// `moves.length` for the present. Null when not reviewing at all.
  ///
  /// A view, never a fact about the game — the stored move list is what the
  /// board is replayed from either way, so scrubbing cannot alter anything and
  /// leaving review restores play exactly where it was (D204).
  int? _review;

  @override
  void initState() {
    super.initState();
    // Driving the opponent from the stream rather than from build() keeps the
    // side effect out of the widget lifecycle, where a rebuild for any reason
    // would trigger a second move.
    _subscription = widget.repository.watchGame(widget.gameId).listen(_onGame);
  }

  @override
  void didUpdateWidget(GameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Flutter reuses this State when the same widget type is rebuilt in the
    // same position, so a changed game id must re-point the subscription —
    // otherwise the screen keeps showing the game it was first given.
    if (oldWidget.gameId != widget.gameId) {
      _subscription?.cancel();
      _game = null;
      _rating = null;
      _achieved = const [];
      _points = 0;
      _offer = null;
      _busy = false;
      _review = null;
      _subscription =
          widget.repository.watchGame(widget.gameId).listen(_onGame);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _onGame(GameDocument? game) {
    setState(() => _game = game);
    if (game == null) return;
    unawaited(_playOpponentIfItsTurn(game));
    if (game.status == GameStatus.complete &&
        game.mode == GameMode.vsComputer &&
        _rating == null) {
      unawaited(_loadOutcome());
    }
  }

  /// The two things a finished game has to say about itself: what it did to
  /// the rating, and what it achieved. One read of the history serves both.
  Future<void> _loadOutcome() async {
    final completed = await widget.repository.loadCompletedGames();
    if (!mounted) return;
    final today = (widget.now ?? DateTime.now)();
    // The **prefix ending at this game**, not "everything except this game" —
    // the same distinction `computerRatingAround` makes and for the same
    // reason. Removing one game from the middle of the history asks "would
    // this quest still stand without you", which five games on the same day
    // all answer yes to: each of the five would claim the five-game rung on
    // its own. Asking "what did the history not yet have before this move"
    // credits the game that actually completed it, and keeps the answer stable
    // when an old game is opened again from the history list.
    //
    // `completed` is most recent first, so the chronological prefix ending at
    // this game is the suffix starting at it.
    final index = completed.indexWhere((game) => game.id == widget.gameId);
    final upTo = index < 0 ? completed : completed.sublist(index);
    final before = index < 0 ? completed : completed.sublist(index + 1);
    final earned =
        points_fold.pointsFrom(upTo) - points_fold.pointsFrom(before);
    final offer = await _offerFor(before, completed, isLatest: index == 0);
    if (!mounted) return;
    setState(() {
      _rating = computerRatingAround(completed, widget.gameId);
      _points = earned;
      _offer = offer;
      _achieved = newlyAchieved(
        points_fold.questsFrom(before, today),
        points_fold.questsFrom(upTo, today),
      );
    });
  }

  /// The next opponent, if this game's points are what made it affordable.
  ///
  /// Only for the **most recent** finished game. Opening an older one from the
  /// history list would otherwise offer an unlock on the strength of points
  /// that everything played since had already spent or surpassed — an offer
  /// that is true of a moment the player has left.
  Future<BotConfig?> _offerFor(
    List<GameDocument> before,
    List<GameDocument> completed, {
    required bool isLatest,
  }) async {
    final repository = widget.unlocks;
    if (!isLatest || repository == null) return null;
    final unlocks = await repository.loadUnlocks();
    final next = nextUnlockIndex({for (final u in unlocks) u.opponentId});
    if (next == null) return null;
    final prices = [for (final u in unlocks) u.pricePaid];
    final price = unlockCost(next);
    final was = balance(
        earned: points_fold.pointsFrom(before), pricesPaid: prices);
    final now = balance(
        earned: points_fold.pointsFrom(completed), pricesPaid: prices);
    // Crossed the line *with this game*, not merely standing above it: an
    // offer repeated after every subsequent win is an advertisement.
    return was < price && now >= price ? opponentCatalogue[next] : null;
  }

  /// Buys the opponent this game paid for, from here rather than from the
  /// main screen. The confirmation is the same one Your Path shows, so the
  /// "unbeatable when it moves first" warning cannot be missing on one route
  /// and present on the other (D181).
  Future<void> _unlock() async {
    final bot = _offer;
    final repository = widget.unlocks;
    if (bot == null || repository == null) return;
    final completed = await widget.repository.loadCompletedGames();
    final unlocks = await repository.loadUnlocks();
    if (!mounted) return;
    await runUnlock(
      context,
      bot: bot,
      price: unlockCost(rosterIndexOf(bot.id)!),
      points: balance(
        earned: points_fold.pointsFrom(completed),
        pricesPaid: [for (final u in unlocks) u.pricePaid],
      ),
      purchase: (id, paid) => repository.purchase(id, pricePaid: paid),
    );
    // Whether it was bought or cancelled, the offer has been answered.
    if (mounted) setState(() => _offer = null);
  }

  bool _isOpponentsTurn(GameDocument game) =>
      game.mode == GameMode.vsComputer &&
      game.status == GameStatus.active &&
      game.seatToMove != game.playerSeat;

  Future<void> _playOpponentIfItsTurn(GameDocument game) async {
    if (_busy || !_isOpponentsTurn(game)) return;
    final bot = botById(game.opponent.replaceFirst('bot:', ''));
    if (bot == null) return;

    setState(() => _busy = true);
    try {
      await Future<void>.delayed(kBotMoveDelay);
      if (!mounted) return;
      final move = await widget.opponentMove(game.moves, bot, _random);
      if (!mounted) return;
      // The move was computed for the position as it stood when the turn
      // began, and the player can resign while it is being computed — the
      // Resign action is deliberately available during the opponent's turn.
      // Appending to a game the repository no longer accepts moves for throws
      // out of an unawaited future, so the stale move is dropped instead.
      final current = _game;
      if (current == null ||
          !_isOpponentsTurn(current) ||
          current.moves.length != game.moves.length) {
        return;
      }
      await widget.repository.appendMove(game.id, move);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _play(Cell cell) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.repository.appendMove(widget.gameId, cell.index);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Resigning ends the game as a loss for the resigner. There is deliberately
  /// no draw offer anywhere in the product — a player who wants out of a dead
  /// position resigns.
  Future<void> _resign(GameDocument game) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.resignConfirmTitle),
        content: Text(l10n.resignConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.resign),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    // Against the computer the player resigns whoever is to move; sharing a
    // device, it is the side whose turn it is that gives up.
    final seat = game.mode == GameMode.vsComputer
        ? game.playerSeat
        : game.seatToMove;
    await widget.repository.resign(game.id, seat: seat);
  }

  /// A rematch alternates the start, which is what keeps a series fair given
  /// the first player's advantage, and records the game it followed.
  Future<void> _rematch(GameDocument game) async {
    final next = await widget.repository.createGame(
      mode: game.mode,
      opponent: game.opponent,
      opponentRating: game.opponentRating,
      playerSeat: game.playerSeat,
      startingSeat: (game.startingSeat + 1) % 2,
      startReason: StartReason.rematchAlternation,
      rematchOf: game.id,
    );
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(
          repository: widget.repository,
          gameId: next.id,
          random: widget.random,
          opponentMove: widget.opponentMove,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final game = _game;
    return Scaffold(
      appBar: AppBar(
        title: Text(game != null && game.mode == GameMode.vsComputer
            ? botName(l10n, game.opponent)
            : l10n.passAndPlay),
        actions: [
          if (game != null && game.moves.isNotEmpty)
            IconButton(
              icon: Icon(_review == null ? Icons.history : Icons.close),
              tooltip: _review == null ? l10n.review : l10n.reviewLeave,
              onPressed: () => setState(
                  () => _review = _review == null ? game.moves.length : null),
            ),
          // Hidden while reviewing: resigning is the one thing on this screen
          // that would change the game the player came here to look at.
          if (game != null &&
              game.status == GameStatus.active &&
              _review == null)
            TextButton(
              onPressed: () => _resign(game),
              child: Text(l10n.resign),
            ),
        ],
      ),
      body: SafeArea(
        child: game == null
            ? const SizedBox.shrink()
            : _GameBody(
                game: game,
                rating: _rating,
                achieved: _achieved,
                points: _points,
                offer: _offer,
                onUnlock: _offer == null ? null : _unlock,
                // Taps are the human's alone: a game against the computer
                // must not let the player move for it while it thinks.
                enabled: !_isOpponentsTurn(game),
                onCellTap: _play,
                onRematch: () => _rematch(game),
                review: _review,
                onReview: (index) => setState(() => _review = index),
              ),
      ),
    );
  }
}

class _GameBody extends StatelessWidget {
  const _GameBody({
    required this.game,
    required this.rating,
    required this.achieved,
    required this.points,
    required this.offer,
    required this.onUnlock,
    required this.enabled,
    required this.onCellTap,
    required this.onRematch,
    required this.review,
    required this.onReview,
  });

  final GameDocument game;
  final ({int before, int after})? rating;

  /// The quests this game just achieved, passed through to the result panel.
  final List<QuestStatus> achieved;

  final int points;
  final BotConfig? offer;
  final VoidCallback? onUnlock;

  final bool enabled;
  final void Function(Cell cell) onCellTap;
  final VoidCallback onRematch;

  /// How many moves of the game to show, or null for the live position.
  final int? review;
  final void Function(int? index) onReview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reviewing = review != null;
    // The board is replayed from the stored moves, never held alongside them —
    // which is exactly what makes a past position free: it is the same replay,
    // stopped earlier.
    final state = GameState.fromMoves(
        reviewing ? game.moves.take(review!) : game.moves);
    final o = outcome(state);
    // The record decides whether the game is over, not the board: a
    // resignation leaves a perfectly playable position behind.
    final over = game.status == GameStatus.complete;
    final highlight = o is Win ? o.line : const <int>[];
    final lightToMove = state.sideToMove == Player.first;
    // Derived from the game rather than from the screen's `_busy` flag: the
    // banner should say "thinking" for the whole of the opponent's turn,
    // including the moment before the move is dispatched.
    final thinking = !over &&
        game.mode == GameMode.vsComputer &&
        game.seatToMove != game.playerSeat;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          // The scrubber *replaces* the banner rather than joining it. At the
          // shortest supported screen the board has about 6dp of vertical
          // slack before its cells fall under the audited floor, so a row that
          // added height was never available (D204).
          child: reviewing
              ? _ReviewBar(
                  game: game,
                  index: review!,
                  onReview: onReview,
                )
              : Column(
                  children: [
                    _TurnBanner(
                      text: _statusText(l10n, game, o, lightToMove),
                      lightToMove: !over && lightToMove,
                      over: over,
                      thinking: thinking,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _firstMoveCaption(l10n, game),
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
        ),
        Expanded(
          // Right-aligned column of four layers (D137). No scroll view:
          // the board sizes itself to fit, so a scrollable would only
          // ever hide a layout bug.
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: BoardView(
                state: state,
                // Never while reviewing: the criterion is that no move can be
                // made from a past position, and a tap that landed would be
                // played into the present anyway.
                enabled: enabled && !over && !reviewing,
                onCellTap: onCellTap,
                highlight: highlight,
                // The move just played, or the whole line once one is
                // completed. Against a computer opponent its reply otherwise
                // simply appears somewhere in sixty-four cells, and finding it
                // is the player's problem (D203).
                flash: flashCells(state),
              ),
            ),
          ),
        ),
        // The result sits below the board rather than over it, so the four
        // highlighted cells of the winning line stay visible while the player
        // reads how it ended. Hidden while reviewing: its Rematch button
        // starts a new game, which is not what "step back through this one"
        // should have within reach.
        if (over && !reviewing)
          _ResultPanel(
              game: game,
              rating: rating,
              achieved: achieved,
              points: points,
              offer: offer,
              onUnlock: onUnlock,
              onRematch: onRematch),
      ],
    );
  }
}

/// Step back and forth through a game's moves.
///
/// Occupies the turn banner's slot, and is deliberately no taller: see D204.
/// The four buttons keep their full 48dp targets — what gives is the board's
/// cell size, which is allowed to dip under [kMinCellSize] here because
/// nothing on a reviewed board is tappable. That floor is a touch-target
/// floor (D135), and the same argument the tutorial makes (D194) applies.
class _ReviewBar extends StatelessWidget {
  const _ReviewBar({
    required this.game,
    required this.index,
    required this.onReview,
  });

  final GameDocument game;
  final int index;
  final void Function(int? index) onReview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final total = game.moves.length;
    final atStart = index == 0;
    final atEnd = index >= total;

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.first_page),
          tooltip: l10n.reviewToStart,
          onPressed: atStart ? null : () => onReview(0),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: l10n.reviewBack,
          onPressed: atStart ? null : () => onReview(index - 1),
        ),
        Expanded(
          child: Semantics(
            liveRegion: true,
            // The announcement says which piece landed where; the label on
            // screen says only how far through the game we are. Same split as
            // D198 — the position is already visible, and reading the board
            // aloud is the only way to convey it to somebody who cannot see it.
            label: _reviewAnnouncement(l10n, game, index),
            child: ExcludeSemantics(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    l10n.moveOf(index, total),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          tooltip: l10n.reviewForward,
          onPressed: atEnd ? null : () => onReview(index + 1),
        ),
        IconButton(
          icon: const Icon(Icons.last_page),
          tooltip: l10n.reviewToEnd,
          onPressed: atEnd ? null : () => onReview(total),
        ),
      ],
    );
  }
}

/// What a screen reader hears when the scrubber moves: how far through the
/// game we are, and the move that got us here.
String _reviewAnnouncement(
    AppLocalizations l10n, GameDocument game, int index) {
  final where = l10n.moveOf(index, game.moves.length);
  if (index == 0) return '$where. ${l10n.reviewStart}';
  final cell = Cell(game.moves[index - 1]);
  // Move 1 is light by definition — the first player holds the light pieces,
  // whichever seat that is.
  final light = (index - 1).isEven;
  return '$where. ${l10n.cellSemantics(
    cell.z + 1,
    cell.y + 1,
    cell.x + 1,
    light ? l10n.cellLight : l10n.cellDark,
  )}';
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.game,
    required this.rating,
    required this.achieved,
    required this.points,
    required this.offer,
    required this.onUnlock,
    required this.onRematch,
  });

  final GameDocument game;
  final ({int before, int after})? rating;

  /// What this game achieved, acknowledged here rather than recorded silently
  /// and rather than interrupting play — the game is over by the time this
  /// panel exists, which is what the ticket asks for.
  final List<QuestStatus> achieved;

  /// What the game itself paid, separately from any quest it achieved.
  final int points;

  /// The opponent this game's points just paid for, or null.
  final BotConfig? offer;
  final VoidCallback? onUnlock;

  final VoidCallback onRematch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final vsComputer = game.mode == GameMode.vsComputer;
    final change = rating;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (vsComputer && change != null) ...[
              Text(
                l10n.computerRatingChange(
                  change.after,
                  _signed(change.after - change.before),
                ),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 2),
              // The two ladders are independent; this one never leaves the
              // device, and saying so is the point of the label.
              Text(
                l10n.computerRatingNote,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            if (!vsComputer) ...[
              Text(
                l10n.passAndPlayNoRating,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              // Said plainly rather than left to be inferred from an empty
              // space. A player who sees no number needs to know both are
              // absent by design (ticket 035).
              Text(
                l10n.passAndPlayNoPoints,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            if (vsComputer && points > 0) ...[
              const SizedBox(height: 4),
              Text(
                l10n.pointsEarnedLine(points),
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
            ],
            if (achieved.isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(l10n.questAchievedTitle,
                    style: theme.textTheme.titleSmall),
              ),
              for (final status in achieved)
                _AchievedRow(status: status),
            ],
            if (offer != null && onUnlock != null) ...[
              const SizedBox(height: 12),
              Text(
                l10n.unlockNowAffordable(botName(l10n, botOpponent(offer!.id))),
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: onUnlock,
                  child: Text(l10n.unlockAction),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: onRematch,
                    child: Text(l10n.rematch),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.backToHome),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One quest this game achieved, with what it paid.
///
/// The points are shown beside it rather than only added to a total, because
/// a reward the player never sees arrive is indistinguishable from no reward.
class _AchievedRow extends StatelessWidget {
  const _AchievedRow({required this.status});

  final QuestStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final name = questName(l10n, status.quest);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Semantics(
        // `container: true` because the child is wholly excluded: without it
        // there is no node of its own to carry the label, and the row is
        // announced as nothing at all.
        container: true,
        label: l10n.questAwardSemantics(name, status.award),
        child: ExcludeSemantics(
          child: Row(
            children: [
              Icon(questIcon(status.quest.family),
                  size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(name, style: theme.textTheme.bodyMedium)),
              const SizedBox(width: 8),
              Text(l10n.questAward(status.award),
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: theme.colorScheme.primary)),
            ],
          ),
        ),
      ),
    );
  }
}

/// "+12", "-8", "0" — the sign is part of the text rather than left to the
/// reader, because a bare number next to a rating reads as the rating.
String _signed(int delta) => delta > 0 ? '+$delta' : '$delta';

/// Who opens, and why. Shown for the whole game rather than only at move one,
/// because against a computer opponent that moves first the player would
/// otherwise never see it.
String _firstMoveCaption(AppLocalizations l10n, GameDocument game) {
  final who = switch (game.mode) {
    GameMode.vsComputer => game.startingSeat == game.playerSeat
        ? l10n.you
        : botName(l10n, game.opponent),
    // Sharing a device the seats are anonymous, so the colours name them.
    GameMode.passAndPlay => l10n.sideLight,
  };
  return switch (game.startReason) {
    StartReason.random => l10n.firstMoveRandom(who),
    StartReason.rematchAlternation => l10n.firstMoveAlternating(who),
  };
}

/// Against a person the seats are anonymous, so the light/dark colours name
/// the turn. Against the computer the player is one of the two seats, so the
/// text says whose turn it is by name instead.
String _statusText(
  AppLocalizations l10n,
  GameDocument game,
  Outcome o,
  bool lightToMove,
) {
  final vsComputer = game.mode == GameMode.vsComputer;
  return switch (o) {
    Draw() => l10n.gameDrawn,
    Win() when vsComputer => game.result?.winnerSeat == game.playerSeat
        ? l10n.youWin
        : l10n.youLose(botName(l10n, game.opponent)),
    Win(winner: Player.first) => l10n.lightWins,
    Win() => l10n.darkWins,
    Ongoing() when game.status == GameStatus.complete && vsComputer =>
      // Resignation: the board is still playable, so only the record knows.
      game.result?.winnerSeat == game.playerSeat
          ? l10n.youWin
          : l10n.youLose(botName(l10n, game.opponent)),
    // Light is whoever opened, which is startingSeat — not seat 0.
    Ongoing() when game.status == GameStatus.complete =>
      game.result?.winnerSeat == game.startingSeat
          ? l10n.lightWins
          : l10n.darkWins,
    Ongoing() when vsComputer => game.seatToMove == game.playerSeat
        ? l10n.yourTurn
        : l10n.botThinking(botName(l10n, game.opponent)),
    Ongoing() => lightToMove ? l10n.lightPlays : l10n.darkPlays,
  };
}

class _TurnBanner extends StatelessWidget {
  const _TurnBanner({
    required this.text,
    required this.lightToMove,
    required this.over,
    this.thinking = false,
  });

  final String text;
  final bool lightToMove;
  final bool over;

  /// True while a computer opponent is deciding. A move may take up to twenty
  /// seconds on a device (D164), and against that a line of static text is
  /// indistinguishable from a frozen app — so the stone the banner already
  /// shows is replaced by something that visibly moves (D166).
  final bool thinking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!over) ...[
            if (thinking)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: theme.colorScheme.primary,
                ),
              )
            else
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.35, -0.45),
                    colors: lightToMove
                        ? const [Color(0xFFFFFFFF), Color(0xFFC3C3C8)]
                        : const [Color(0xFF4A4A52), Color(0xFF050507)],
                  ),
                  border: Border.all(
                      color: theme.colorScheme.outline, width: 0.5),
                ),
              ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              text,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
