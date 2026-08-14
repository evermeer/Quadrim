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
