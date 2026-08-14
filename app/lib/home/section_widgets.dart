import 'package:flutter/material.dart';

import '../data/documents.dart';
import '../l10n/app_localizations.dart';

/// The small shared pieces the main screen's sections are built from.
///
/// They live together because each is used by more than one section and none
/// is large enough to earn a file: a heading, the rating pill, and the sliver
/// pair that gives a list of games its heading (ticket 030).
///
/// The rating *bar* used to live here too. Its only caller was the by-opponent
/// breakdown, which ticket 032 deleted when Your Path replaced it, so it went
/// with it rather than staying as an unused public widget.

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
