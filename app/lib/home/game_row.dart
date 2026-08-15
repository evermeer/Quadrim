import 'package:flutter/material.dart';

import '../data/documents.dart';
import '../game/opponent_avatar.dart';
import '../game/opponent_name.dart';
import '../l10n/app_localizations.dart';
import 'section_widgets.dart';

/// The avatar slot used by every row on this screen that names an opponent.
///
/// One widget rather than two copies, because the game rows and the
/// by-opponent breakdown have to line up: the names beside them share a left
/// edge, and that only holds while the slot is the same width in both. It also
/// puts the "there is nobody to draw" case — pass-and-play, and an opponent
/// this build does not know — in one place instead of two (D189, D191).
class OpponentAvatarSlot extends StatelessWidget {
  const OpponentAvatarSlot({super.key, required this.opponent});

  /// A stored `opponent` field: `bot:<id>`, or the guest.
  final String opponent;

  /// Small enough to ride a single line of text without setting its height.
  static const double size = 28;

  @override
  Widget build(BuildContext context) {
    final bot = botConfigFor(opponent);
    return SizedBox(
      width: size,
      height: size,
      child: bot == null
          ? Icon(
              Icons.people_outline,
              size: size * 0.8,
              color: Theme.of(context).colorScheme.outline,
            )
          : OpponentAvatar(id: bot.id, tier: bot.tier, size: size),
    );
  }
}

/// One game on one line: avatar, who it was against, and its state at the end.
///
/// The same shape as the by-opponent rows above it — name left, fact right —
/// so a screen that already lists opponents that way does not switch layouts
/// halfway down. Two-line `ListTile`s made a list of a dozen games longer than
/// the screen for no extra information (D189).
class GameRow extends StatelessWidget {
  const GameRow({
    super.key,
    required this.game,
    required this.trailing,
    required this.onTap,
    this.delta,
    this.subtitle,
  });

  final GameDocument game;

  /// The right-hand fact: moves played, or how the game ended.
  final String trailing;

  /// What this game did to the computer rating, shown after [trailing]. Null
  /// where there is nothing to show — a game in progress, or pass and play.
  final int? delta;

  /// A second line under the name — the relative date, on a finished game.
  /// Null on a game in progress, which has not ended to have a date.
  final String? subtitle;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final label = opponentLabel(l10n, game);
    // The anchor this game was actually played against, not the catalogue's
    // current value — the same rule the rating fold follows (spec §8.3), so a
    // recalibration never rewrites what a finished game says it was worth.
    // Null for pass-and-play, which has no opponent to rate.
    final rating = game.opponentRating;

    return InkWell(
      onTap: onTap,
      child: Semantics(
        button: true,
        // The arrow and its number are one more fact about the row, so they
        // join the row's single label rather than announcing separately. A
        // signed integer needs no translating, which is why it is appended
        // rather than routed through a placeholder of its own.
        label: rating == null
            ? '$label. $trailing${subtitle == null ? '' : '. $subtitle'}'
            : l10n.opponentRowSemantics(
                label,
                rating,
                [
                  trailing,
                  if (delta != null) signedDelta(delta!),
                  ?subtitle,
                ].join('. ')),
        child: ExcludeSemantics(
          // Constrained, not just padded. `ListTile` — which this replaced —
          // enforces a 48dp minimum; hand-rolling the row dropped it to 44,
          // under the minimum touch target Android and Material both specify.
          // A constraint holds at any text scale where a fixed padding would
          // only hold at 1.0 (D189).
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  OpponentAvatarSlot(opponent: game.opponent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child:
                                  Text(label, overflow: TextOverflow.ellipsis),
                            ),
                            if (rating != null) ...[
                              const SizedBox(width: 6),
                              RatingPill(rating: rating),
                            ],
                          ],
                        ),
                        ?switch (subtitle) {
                          final String date => Text(date,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                          _ => null,
                        },
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // The result **above** the rating change rather than beside
                  // it (ticket 035). Two short lines instead of one long one
                  // give the opponent's name back the width it was losing, and
                  // the pair still reads as one fact about the game.
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          trailing,
                          textAlign: TextAlign.end,
                          style: theme.textTheme.bodySmall,
                        ),
                        if (delta != null) RatingDelta(delta: delta!),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String signedDelta(int delta) => delta > 0 ? '+$delta' : '$delta';

/// What one finished game did to the computer rating: an arrow and a number.
///
/// The arrow's *direction* and the number's sign both carry the meaning, so
/// the colour is the third telling rather than the only one — which is what
/// keeps it readable to a player who cannot separate red from green (D124's
/// reasoning, applied to a different pair of colours).
///
/// It announces nothing of its own; the row it sits in says the number once,
/// in its single label.
class RatingDelta extends StatelessWidget {
  const RatingDelta({super.key, required this.delta});

  final int delta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Reachable, not hypothetical: beating an opponent far below you earns a
    // fraction of a point, which rounds to nothing. There is no direction to
    // point in, so it shows the number alone rather than an arrow that would
    // claim a movement that did not happen.
    final colour = delta == 0
        ? theme.colorScheme.onSurfaceVariant
        : delta > 0
            ? (theme.brightness == Brightness.dark
                ? const Color(0xFF7CD98C)
                : const Color(0xFF2E7D32))
            : theme.colorScheme.error;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (delta != 0)
          Icon(
            delta > 0 ? Icons.arrow_drop_up : Icons.arrow_drop_down,
            size: 18,
            color: colour,
          ),
        Text(
          signedDelta(delta),
          style: theme.textTheme.bodySmall?.copyWith(
            color: colour,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

String opponentLabel(AppLocalizations l10n, GameDocument game) =>
    game.mode == GameMode.vsComputer
        ? botName(l10n, game.opponent)
        : l10n.passAndPlay;

/// A finished game's outcome, from the player's seat.
///
/// Pass-and-play has no "you", so it reports which side won rather than
/// whether the player did.
String resultLabel(AppLocalizations l10n, GameDocument game) {
  final result = game.result;
  if (result == null) return '';
  if (result.outcome == GameOutcome.draw) return l10n.resultDrawn;
  if (game.mode != GameMode.vsComputer) {
    return result.winnerSeat == game.startingSeat
        ? l10n.lightWins
        : l10n.darkWins;
  }
  return result.winnerSeat == game.playerSeat ? l10n.resultWon : l10n.resultLost;
}
