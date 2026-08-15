# 035 — The main screen and the end of a game, finished

**What to build:** The last of the 0.1 interface, once there is progression to show. Four things that each needed something earlier to exist first.

**The ten-game trend graph.** A line with a dot per game over the last ten completed games, green if the rating is higher than it was ten games ago and red if lower — **with the signed change stated beside it**, `+43` or `−12`. The number is not decoration. Trend colour here is *information* rather than confirmation, and red-versus-green is the worst possible pair for the commonest colour vision deficiency; without the number a red-green colourblind player learns nothing at all from the element. Below two completed games there is no graph.

**The finished-games rows.** The result label goes **above** the rating change rather than beside it, which is what buys the vertical room the quests section needs. Each row gains a relative date and a challenge button.

**The end-of-game panel.** The rating change, the points earned, any quest completed, and — if the win just paid for the next unlock — the offer, there. That is the moment the player is most interested, and making them navigate to find out wastes it.

**The portrait lock.** Spec §5.2: no large-screen layout exists and none is reachable by rotation or resizing. Ticket 017 is cancelled.

Two traps in the rating-change column, both cheap to avoid and expensive to find later. The change is a property of the history *up to* that game, so the obvious per-row call re-folds the entire prefix each time and is **quadratic** — compute the whole list in one pass. And a step can **round to zero** when beating an opponent far below you: there is no direction to point in, so show the number alone rather than an arrow claiming a movement that did not happen.

**Blocked by:** 032 — Unlocks, and Your Path; 033 — Quests

**Status:** ready-for-agent

- [ ] A ten-game trend graph appears on the rating card, one dot per completed game
- [ ] It states its change as a **signed number** beside the line, and no meaning anywhere depends on the red/green pair alone
- [ ] Below two completed games no graph is drawn at all — not an empty one
- [ ] Finished-game rows show the result label above the rating change, a relative date (`today`, `yesterday`, `2 days ago` … `7 days ago`, then the device's own date format), and a challenge button that starts a new game against that opponent
- [ ] The whole list's rating changes are computed in **one pass**; a test with a few hundred games asserts the cost does not grow quadratically
- [ ] A change that rounds to zero shows the number alone, with no arrow
- [ ] The arrow's direction and the number's sign each carry the meaning independently, so colour is confirmation rather than information
- [ ] **Show more** opens a full history screen rather than expanding the list in place
- [ ] The end-of-game panel shows the rating change **that game caused** — folded from the prefix ending at it, not the change the most recent game caused, because those differ the moment a player opens an older finished game
- [ ] It shows the points earned, any quest completed with what it paid, and the next unlock offered if the win just paid for it
- [ ] A pass-and-play result says plainly that no rating changed and no points were earned
- [ ] The app is portrait-only on every device, and no layout is reachable by rotation or by resizing a window
- [ ] The whole main screen reaches its last row at the **largest system font scale on the smallest supported phone**, with all six sections present — rating card, Your Path, games in progress, quests, finished games, and the primary button
- [ ] Any rating shown as a bar is zero-based against the top of the catalogue, draws its unfilled track, and shows the number as well
- [ ] Every fact shown visually on the screen is announced exactly once
- [ ] All new strings are present in English and Dutch

---

## Closed

All four pieces are in, and the 0.1 interface is complete.

**The trend graph** draws one dot per game over the last ten and states its
change as a signed number beside the line. Nothing depends on the red/green
pair: the number is there for the sighted reader and the same number is in the
rating card's announcement for a screen reader. Below two rated games there is
no graph at all — not an empty one. The window is measured against where the
player stood *before* it, so "the last ten games" means ten games and not the
nine gaps between them.

**The finished rows** put the result above the rating change, which gives the
opponent's name back the width it was losing to one long right-hand line. Each
carries a relative date — `Today`, `Yesterday`, `2 days ago` … `7 days ago`,
then `MaterialLocalizations`' own short date, which needs no string of ours —
and a challenge button. The button sits *outside* `GameRow`, because the row
excludes its children's semantics and re-says every fact once: a button
swallowed by that exclusion would be invisible to a screen reader.

**Show more** opens a screen (D284). The main list stops at ten.

**The end-of-game panel** shows what the game paid, any quest it achieved with
what that paid, and the next unlock if this win is what crossed the line
(D286). A pass-and-play result now says *both* numbers are absent rather than
only the rating.

**Portrait** is pinned in two places, neither redundant: `screenOrientation`
and `resizeableActivity="false"` in the manifest, which is what a freeform
window manager and a foldable obey, and `SystemChrome.setPreferredOrientations`
in `main()`, which is what the framework obeys. Ticket 017 stays cancelled, and
a test asserts it is not sitting in `doc/tickets/` waiting to be built.

**The one-pass requirement** was already met by `ratingDeltas` from ticket 027;
this ticket adds `computerRatingSeries` on the same shape, so the graph costs
one pass rather than ten folds. A test builds three hundred games, takes every
delta in one call, and checks six of them against the per-game fold they
replace.

**One criterion is vacuously satisfied and it is worth saying so.** *"Any
rating shown as a bar is zero-based against the top of the catalogue, draws its
unfilled track, and shows the number as well."* There is no rating bar in the
app: `RatingBar` was deleted in ticket 032 with the by-opponent breakdown that
was its only caller. The three progress bars that remain — quest progress,
unlock progress, tutorial progress — are not ratings, and each already shows
its number. If a rating bar ever returns, this is the paragraph that says what
it owes.

**D284** ten then a screen; **D285** the graph declares no semantics and the
card announces it; **D286** the offer fires on the crossing game and only from
the latest one.
