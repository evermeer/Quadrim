# 014 — Rating maths and the self-play calibration harness

**What to build:** The rating system as tested pure logic, and a headless command-line tool that plays opponents against each other thousands of times to measure their real relative strength.

The maths is used immediately: ticket 027 computes the player's live computer rating with it, and the same functions serve the human rating on the server from 0.3b.

The harness exists because the twenty published ratings are estimates. All twenty ship together in 0.1 specifically so that they can be calibrated on one scale, against each other and against real testers, before anything is public. Self-play establishes the ordering and the gaps; only humans can fix the absolute scale.

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
- [ ] A full round-robin across all twenty opponents can be run in one command, with a recorded runtime that makes it practical to repeat after a configuration change
- [ ] Results confirm the intended strength ordering across all five tiers, and any inversion is treated as a configuration defect rather than accepted
- [ ] The published numbers are derived by human-anchoring the lower tiers from closed-test results and chaining the upper tiers from measured gaps, with the chain recorded so a later correction can be reasoned about
- [ ] The harness can also calibrate a single opponent against others whose ratings are already fixed — needed when Quadrim Prime is upgraded and recalibrated at 1.0
