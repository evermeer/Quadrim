import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quadrim_engine/quadrim_engine.dart';

import '../data/game_repository.dart';
import '../design/forest.dart';
import '../game/board_view.dart';
import '../l10n/app_localizations.dart';
import 'practice_screen.dart';
import 'tutorial_steps.dart';

/// The tutorial: one idea per page, each shown on the board the game is
/// actually played on.
///
/// The board is [BoardView] rather than a picture, which costs a little —
/// every demonstration has to be expressible as a legal move list, and the
/// board has to shrink to share a page with a paragraph — and buys the thing
/// the pictures could not: what the player learns to read here is pixel for
/// pixel what they will be looking at in a game (D194).
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key, required this.settings});

  /// Where completion is recorded. Reaching the last step is the only thing
  /// that marks the tutorial done; leaving early deliberately does not, so a
  /// player who backs out on step two is still offered it from the main screen.
  final SettingsRepository settings;

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final _controller = PageController();
  int _index = 0;

  /// Guards [_finish] against a second tap landing during the settings write.
  ///
  /// `mounted` stays true for the whole of the route's exit transition, so two
  /// taps inside that window each reach `pop()` and the second one takes the
  /// main screen with it. No widget test can demonstrate this: it needs
  /// `saveSettings` to do real file I/O, and `testWidgets` runs in a fake-async
  /// zone that never completes it, so the in-memory store every widget test is
  /// obliged to use closes the window that production leaves open.
  bool _finishing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int index) => _controller.animateToPage(
        index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );

  /// Hands the player a real game against a real opponent, and finishes the
  /// tutorial if they see it through.
  ///
  /// Abandoning it returns false and changes nothing: the ticket asks that
  /// leaving the practice game not block completion, and the player is put
  /// back on the last step with Done still in front of them.
  Future<void> _practice() async {
    final finished = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const PracticeScreen()),
    );
    if (finished == true && mounted) await _finish();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    final settings = await widget.settings.loadSettings();
    await widget.settings
        .saveSettings(settings.copyWith(tutorialCompleted: true));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final steps = tutorialSteps(l10n);
    final last = _index == steps.length - 1;

    return ForestScaffold(
      appBar: AppBar(
        title: Text(l10n.tutorial),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: l10n.tutorialClose,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ParchmentSheet(
          child: Column(
          children: [
            _Progress(
              index: _index,
              total: steps.length,
              title: steps[_index].title,
            ),
            Expanded(
              // Swipeable as well as buttoned: "steps can be revisited" is
              // cheapest to honour by leaving the gesture the widget already
              // has, and a player who has just been told to tap the board will
              // try to swipe it.
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                itemCount: steps.length,
                itemBuilder: (_, i) => _StepView(step: steps[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  // At the end of a section, finishing is offered on a line of
                  // its own rather than as a third button in the row below.
                  // Three buttons abreast fit at a text scale of 1.0 and stop
                  // fitting well before 2.0, which is the trap D188 already
                  // cost this project once.
                  if (steps[_index].endsSection)
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _finish,
                        child: Text(l10n.tutorialFinishHere),
                      ),
                    ),
                  // The same slot on the last step: the practice game is the
                  // optional extra there, and Done stays the plain way out.
                  if (last)
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _practice,
                        child: Text(l10n.practicePlay),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed:
                              _index == 0 ? null : () => _goTo(_index - 1),
                          child: Text(l10n.tutorialBack),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: last ? _finish : () => _goTo(_index + 1),
                          child:
                              Text(last ? l10n.tutorialDone : l10n.tutorialNext),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}

/// How far through the tutorial the player is, said twice: as a bar for
/// sighted players and as a sentence for everyone else. A bare
/// [LinearProgressIndicator] announces nothing.
///
/// The announcement carries the new step's title as well as its number, and
/// the visible text does not. Pressing Next moves focus nowhere, so a live
/// region saying only "Step 8 of 12" tells a screen-reader user that something
/// changed without telling them what — they then have to go looking for the
/// heading. Two words in the label save that hunt on every one of twelve steps
/// (D198). On screen the title is already the largest thing on the page.
class _Progress extends StatelessWidget {
  const _Progress({
    required this.index,
    required this.total,
    required this.title,
  });

  final int index;
  final int total;
  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = l10n.tutorialStepOf(index + 1, total);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Semantics(
        container: true,
        liveRegion: true,
        label: '$label. $title',
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 4),
              LinearProgressIndicator(value: (index + 1) / total),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepView extends StatelessWidget {
  const _StepView({required this.step});

  final TutorialStep step;

  /// Share of the page the board may claim.
  ///
  /// A fraction rather than a fixed height because the page scrolls: at a
  /// large text scale the paragraph grows without squeezing the board down to
  /// nothing, and the player scrolls instead. The floor keeps a board that
  /// shares a page with six lines of text from collapsing to a smear.
  static const _boardShare = 0.72;
  static const _minBoardHeight = 240.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardHeight =
            math.max(_minBoardHeight, constraints.maxHeight * _boardShare);
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(step.title, style: theme.textTheme.headlineSmall),
              ),
              const SizedBox(height: 8),
              Text(step.body, style: theme.textTheme.bodyLarge),
              if (step.hasBoard) ...[
                const SizedBox(height: 16),
                SizedBox(
                  // Full width, or the box shrinks to the board's own narrow
                  // width and the enclosing Column's start-alignment drops it
                  // against the left edge — where a game never puts it (D137).
                  // Only visible on a device; every widget test passed with the
                  // board on the wrong side of the screen.
                  width: double.infinity,
                  height: boardHeight,
                  child: Semantics(
                    container: true,
                    label: step.boardLabel,
                    child: ExcludeSemantics(
                      child: BoardView(
                        state: GameState.fromMoves(step.moves),
                        // Nothing on a tutorial board is placeable: the
                        // position is the lesson, and a stray tap that changed
                        // it would make the caption a lie.
                        enabled: false,
                        onCellTap: (_) {},
                        highlight: step.line,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// The first-launch offer.
///
/// Returns true if the player wants the tutorial now. Whether it was accepted
/// or declined, the caller records that the offer was made — asking again next
/// launch is nagging, and the tutorial stays one tap away on the main screen
/// either way (D193).
Future<bool> showTutorialOffer(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.tutorialOfferTitle),
      content: Text(l10n.tutorialOfferBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.tutorialOfferDecline),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.tutorialOfferAccept),
        ),
      ],
    ),
  );
  return accepted ?? false;
}
