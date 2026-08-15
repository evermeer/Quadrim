import 'package:flutter/material.dart';

import '../data/documents.dart';
import '../design/art.dart';
import '../design/forest.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';

/// The small shared pieces the main screen's sections are built from.
///
/// They live together because each is used by more than one section and none
/// is large enough to earn a file: a heading, the rating pill, and the sliver
/// pair that gives a list of games its heading (ticket 030).
///
/// The rating *bar* used to live here too. Its only caller was the by-opponent
/// breakdown, which ticket 032 deleted when Your Path replaced it, so it went
/// with it rather than staying as an unused public widget.

/// A heading followed by one lazily-built tile per game, on parchment.
///
/// Slivers rather than a widget, because the finished-games list has no upper
/// bound and every row of it must stay lazily built. That is also why the
/// parchment is a [DecoratedSliver] over a [SliverMainAxisGroup] rather than a
/// `Card` around a column: a card would have to know its children's height, and
/// knowing it means building all of them (ticket 038).
List<Widget> gameSectionSlivers({
  required String heading,
  required List<GameDocument> games,
  required Widget Function(GameDocument) tile,
}) =>
    [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        sliver: DecoratedSliver(
          decoration: BoxDecoration(
            color: QuadrimPalette.parchment,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: QuadrimPalette.edge, width: 1.5),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x660B160E), blurRadius: 10, offset: Offset(0, 3)),
            ],
          ),
          sliver: SliverMainAxisGroup(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                sliver: SliverToBoxAdapter(child: SectionHeading(heading)),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverList.builder(
                  itemCount: games.length,
                  itemBuilder: (_, i) => tile(games[i]),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
            ],
          ),
        ),
      ),
    ];

/// A section's heading, on the same carved sign every other section wears.
///
/// The words are drawn on the wood by the app rather than painted into it, so
/// this is one widget for every heading in both languages (D297).
class SectionHeading extends StatelessWidget {
  const SectionHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Semantics(
            header: true,
            label: text,
            child: ExcludeSemantics(
              child: WoodenSign(
                art: SignArt.bannerFor(text),
                caption: text,
                height: kBannerHeight,
              ),
            ),
          ),
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
      decoration: const ShapeDecoration(
        color: QuadrimPalette.moss,
        shape: StadiumBorder(),
      ),
      child: Text(
        // Through l10n even though it is only digits: a rating is written 1200
        // rather than 1,200 or 1.200 in every locale this ships in, and that
        // is a decision recorded next to the string rather than in the layout.
        AppLocalizations.of(context)!.ratingValue(rating),
        style: theme.textTheme.labelSmall
            ?.copyWith(color: QuadrimPalette.cream),
      ),
    );
  }
}
