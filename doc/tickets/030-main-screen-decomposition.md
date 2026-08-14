# 030 — Main screen decomposition

**What to build:** Nothing. This ticket changes no behaviour, adds no string and closes no acceptance criterion. It moves code.

`home_screen.dart` is 769 lines holding twelve private widget classes, and it is the file every remaining 0.1 ticket touches. Spec §11.3 adds a trend graph, a points balance, a Your Path row and a quests section to it, and rewrites the finished-game row. Extending in place lands somewhere past 1,200 lines before tickets 021 and 022 have to work inside it.

So: split first, then grow. The private widget classes already in the file *are* the extraction boundaries, which makes this close to mechanical — `_RatingCard`, `_ActiveGameTile`, `_FinishedGameTile`, `_GameRow`, `_RatingDelta`, `_RatingPill`, `_RatingBar` and `_SectionHeading` move with no change to their bodies.

**One thing deliberately not done here.** `_OpponentSection` — the by-opponent breakdown — is *extracted*, not deleted, even though Your Path replaces it (spec §11.3, U13). It is deleted in ticket 032, when there is something to put in its place. Removing it here would leave the main screen with a hole for two tickets, which is a visible regression in exchange for nothing (D277).

**A commit that moves code and changes nothing looks like wasted effort in a log.** It is the opposite: it is what makes the four diffs after it legible. Review it as a move — if a hunk is not a move, it does not belong in this ticket.

**Blocked by:** 013 — Main screen (done)

**Status:** ready-for-agent

- [ ] `home_screen.dart` holds the screen's state and its composition, and nothing else
- [ ] Each section is its own file under `app/lib/home/`: at minimum `rating_card.dart`, `active_games.dart`, `finished_games.dart`, `opponent_section.dart`, and the shared row widgets
- [ ] `_OpponentSection` is extracted to its own file and **not** deleted — ticket 032 removes it when Your Path replaces it
- [ ] No user-facing behaviour changes anywhere on the screen
- [ ] No l10n key is added, removed or renamed, in either language
- [ ] Every existing widget test passes **without any edit to its assertions**; a test that needed changing means something other than a move happened
- [ ] Each extracted widget's body is unchanged apart from imports and its privacy modifier
- [ ] `HomeSummary` and the folds it performs are untouched — this ticket moves widgets, not data
- [ ] No new file exceeds roughly 200 lines; a section that would is a sign it needs splitting further rather than a larger budget
- [ ] `tool/check.sh` passes
