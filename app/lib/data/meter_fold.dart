import 'package:quadrim_progression/quadrim_progression.dart';

import 'documents.dart';

/// Maps stored games onto the meter's input, the way `points_fold.dart` maps
/// them onto the progression package's (ticket 045).
///
/// **This fold reads every computer game, finished or not**, which makes it the
/// only one of the three that does. Points and the rating fold completed games,
/// because they reward results; the meter counts starts, because a meter that
/// waited for a result would be defeated by starting a game and quitting
/// (§4.2, F17).

/// Every computer game that was started, at the local time it was started.
///
/// Three exclusions, and each is the *absence* of a document rather than a
/// filter here doing work — worth knowing, because it means nothing has to be
/// kept in step when a fourth kind of game appears:
///
/// - **Pass-and-play** is excluded by [GameMode], the one filter below.
/// - **The tutorial's practice game** is never stored at all, so it cannot
///   reach this. That is also why it is never paid and never metered (§4.2).
/// - **Replay** re-reads a game that already exists and creates nothing.
///
/// `createdAt` is stored UTC and converted here, because the package may not
/// decide which day an instant falls in — the same rule that puts `Day` in
/// `streaks.dart` rather than a `DateTime`.
List<StartedGame> startedGamesFrom(Iterable<GameDocument> games) => [
      for (final game in games)
        if (game.mode == GameMode.vsComputer)
          StartedGame(startedAt: game.createdAt.toLocal()),
    ];

/// The free month recorded in settings, or null if first launch has not been
/// stamped yet.
///
/// Null is not "expired" — [meterState] treats it as unmetered, because a
/// missing or damaged record must fail towards letting the player play rather
/// than towards a wall they cannot explain.
FreeMonth? freeMonthFrom(SettingsDocument settings) {
  final started = settings.freeMonthStartedAt;
  return started == null ? null : FreeMonth(startedAt: started.toLocal());
}
