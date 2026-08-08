# 014 — Rating maths and the self-play calibration harness

**What to build:** The rating system as tested pure logic, and a headless command-line tool that plays opponents against each other thousands of times to measure their real relative strength.

The maths is used immediately: ticket 027 computes the player's live computer rating with it, and the same functions serve the human rating on the server from 0.3b.

The harness exists because the twenty opponents must actually play at the strength they advertise. **The published ratings are fixed and do not move (D144)** — they are the anchor every player's computer rating is earned against, so changing one would silently rewrite the meaning of every result already recorded against it. When measurement disagrees with the published number, the *opponent's configuration* is what changes: blunder rate, search depth, rule set, positional bias.

For 0.1 the strengths are an approximate estimate and are stated as such. All twenty ship together so they sit on one scale from the start, and the tuning pass happens once there is enough real play to measure against.

**Blocked by:** 026 — The Master tier

**Status:** ready-for-agent

- [ ] Expected score, K-factor selection and rating update are implemented as pure functions in the rating package
- [ ] K is 32 below twenty rated games on a ladder and 16 at or above
- [ ] Draws score one half, and ratings are rounded and floored at 100
- [ ] A function folds a set of completed games in order and returns the resulting rating, so a rating can be derived rather than stored
- [ ] The rating package depends on nothing but the Dart core library
- [ ] Rating maths is verified against worked examples, including provisional play, draws and the floor
- [ ] A command-line tool plays any two catalogue opponents against each other for a configurable number of games
- [ ] The tool alternates who starts, so the first-player advantage does not distort results
- [ ] The tool reports win, loss and draw counts and an implied rating difference
- [ ] Calibration runs as an **adjacent-pairs chain plus a sparse cross-tier sample**, at a reduced node budget — not a full round-robin. Twenty opponents is 190 pairs, the upper-tier pairs are the slowest, and the chain establishes the ordering and the gaps for a fraction of the cost
- [ ] The whole calibration can be run in one command, with a recorded runtime that makes it practical to repeat after a configuration change
- [ ] Results confirm the intended strength ordering across all five tiers, and any inversion is treated as a configuration defect rather than accepted
- [ ] The harness **reports** measured strength against each opponent's fixed published rating; it never rewrites the roster (D144)
- [ ] An opponent measuring outside tolerance for its published rating is reported as a configuration defect, to be corrected by changing that opponent's parameters
- [ ] The harness can measure a single opponent against others whose configurations are already settled — needed when Quadrim Prime is upgraded at 1.0, and for the post-0.1 tuning pass
