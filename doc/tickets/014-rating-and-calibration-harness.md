# 014 — Rating maths and the self-play calibration harness

**What to build:** The rating system as tested pure logic, and a headless command-line tool that plays opponents against each other thousands of times to measure their real relative strength.

The maths is used immediately: ticket 027 computes the player's live computer rating with it, and the same functions serve the human rating on the server from 0.3b.

The harness exists because the twenty opponents must actually play at the strength they advertise. **The published ratings are fixed and do not move (D144)** — they are the anchor every player's computer rating is earned against, so changing one would silently rewrite the meaning of every result already recorded against it. When measurement disagrees with the published number, the *opponent's configuration* is what changes: blunder rate, search depth, rule set, positional bias.

For 0.1 the strengths are an approximate estimate and are stated as such. All twenty ship together so they sit on one scale from the start, and the tuning pass happens once there is enough real play to measure against.

**Blocked by:** 026 — The Master tier

**Status:** ready-for-agent

- [x] Expected score, K-factor selection and rating update are implemented as pure functions in the rating package
- [x] K is 32 below twenty rated games on a ladder and 16 at or above
- [x] Draws score one half, and ratings are rounded and floored at 100
- [x] A function folds a set of completed games in order and returns the resulting rating, so a rating can be derived rather than stored
- [x] The rating package depends on nothing but the Dart core library
- [x] Rating maths is verified against worked examples, including provisional play, draws and the floor
- [x] A command-line tool plays any two catalogue opponents against each other for a configurable number of games
- [x] The tool alternates who starts, so the first-player advantage does not distort results
- [x] The tool reports win, loss and draw counts and an implied rating difference
- [x] Calibration runs as an **adjacent-pairs chain plus a sparse cross-tier sample**, at a reduced node budget — not a full round-robin. Twenty opponents is 190 pairs, the upper-tier pairs are the slowest, and the chain establishes the ordering and the gaps for a fraction of the cost
- [x] The whole calibration can be run in one command, with a recorded runtime that makes it practical to repeat after a configuration change
- [ ] Results confirm the intended strength ordering across all five tiers, and any inversion is treated as a configuration defect rather than accepted
- [x] The harness **reports** measured strength against each opponent's fixed published rating; it never rewrites the roster (D144)
- [x] An opponent measuring outside tolerance for its published rating is reported as a configuration defect, to be corrected by changing that opponent's parameters
- [x] The harness can measure a single opponent against others whose configurations are already settled — needed when Quadrim Prime is upgraded at 1.0, and for the post-0.1 tuning pass

## The one criterion left open, and why

Every inversion the harness found was chased to a cause. One turned out to be the harness, one pair of them is a conflict inside the roster itself, and only the roster's owner can settle it.

**Settled — Sable/Quartz was this tool's doing, not the catalogue's.** The reduced budget cuts only the node-limited side of a pair, and Sable is ply-limited. At full budget Quartz wins by 147 against a published 100. The harness now detects such a pair and refuses to call it a defect.

**Open — Finch/Kestrel and Kestrel/Willow, about 33 and 50 points inverted** over 300 games, down from 95 and 70 but not closed. One root cause: with two configurations identical *in every respect except `aggression`*, the aggressive setting beats the defensive one by 28 points and the defensive one loses by 50 — roughly 78 points turning on that number, because in Qubic building your own double threat beats denying the opponent's. Kestrel is published as "would rather build than block" and Willow as "Shuts your threats down before it starts its own", so the roster pins that lever in the direction that opens the gap, and nothing left is large enough to close it: Kestrel's extra good squares and lower blunder rate buy about 45 points, and the blunder rate cannot spread further because it must fall as rating rises between Bramble's 0.15 and Ember's 0.08. A configuration that did order Finch below Kestrel needed Finch at 0.25, above Bramble, and the catalogue test rejected it.

**This needs a decision that changes something published** (D210): swap the affected anchors, rewrite one of the blurbs, or accept two ~40-point inversions between adjacent rungs as within the approximate strengths 0.1 states it ships with. Until then the criterion stays open rather than being ticked on a partial result.
