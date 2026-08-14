import 'package:flutter/material.dart';
import 'package:quadrim_engine/quadrim_engine.dart';

import '../data/documents.dart';
import '../l10n/app_localizations.dart';

/// The small shared pieces the main screen's sections are built from.
///
/// They live together because each is used by more than one section and none
/// is large enough to earn a file: a heading, the two ways a rating is drawn,
/// and the sliver pair that gives a list of games its heading (ticket 030).

/// A heading followed by one lazily-built tile per game.
///
/// Slivers rather than a widget, because the finished-games list has no upper
/// bound and every row of it must stay lazily built.
List<Widget> gameSectionSlivers({
  required String heading,
  required List<GameDocument> games,
  required Widget Function(GameDocument) tile,
}) =>
    [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        sliver: SliverToBoxAdapter(child: SectionHeading(heading)),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList.builder(
          itemCount: games.length,
          itemBuilder: (_, i) => tile(games[i]),
        ),
      ),
    ];

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Semantics(
          header: true,
          child: Text(text, style: Theme.of(context).textTheme.titleMedium),
        ),
      );
}

/// An opponent's rating as a number, beside its name.
///
/// The bar under the row says how strong this opponent is *relative to the
/// ladder*, which is the comparison worth making at a glance; this says which
/// number it is. Both, because a length cannot be read off precisely and a
/// number cannot be compared at a glance.
///
/// Carries no semantics of its own — the row already announces the rating
/// once, and a screen reader that met it twice would be worse off than one
/// that met it never.
class RatingPill extends StatelessWidget {
  const RatingPill({super.key, required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: ShapeDecoration(
        color: theme.colorScheme.secondaryContainer,
        shape: const StadiumBorder(),
      ),
      child: Text(
        // Through l10n even though it is only digits: a rating is written 1200
        // rather than 1,200 or 1.200 in every locale this ships in, and that
        // is a decision recorded next to the string rather than in the layout.
        AppLocalizations.of(context)!.ratingValue(rating),
        style: theme.textTheme.labelSmall
            ?.copyWith(color: theme.colorScheme.onSecondaryContainer),
      ),
    );
  }
}

/// An opponent's rating drawn as a length, under its row.
///
/// Full width is the top of the catalogue rather than the strongest opponent
/// the player happens to have met, so a bar means the same thing on a fresh
/// install as on a finished one, and beating someone new never shortens the
/// bars already on the screen.
///
/// The scale starts at zero rather than at Pebble, so Pebble reads as a
/// quarter of Quadrim Prime — which is what the ratings say. Stretching the
/// bottom of the ladder to fill the bar would make the roster look evenly
/// spread when it is not.
class RatingBar extends StatelessWidget {
  const RatingBar({super.key, required this.rating});

  final int rating;

  /// The catalogue is ordered weakest first and a test pins that, so the last
  /// entry is the ceiling without a constant to keep in step with it.
  static final int _strongest = opponentCatalogue.last.rating;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        // Clamped because a stored anchor comes from the game it was played
        // in, and a recalibration could leave one above today's ceiling.
        value: (rating / _strongest).clamp(0.0, 1.0),
        minHeight: 4,
        // The unfilled track is drawn rather than left blank: without it a bar
        // is only comparable to the other bars on screen, and the claim being
        // made is against the top of the ladder, which may not be on screen.
        backgroundColor: scheme.surfaceContainerHighest,
        color: scheme.primary,
      ),
    );
  }
}
