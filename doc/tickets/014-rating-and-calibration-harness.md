# 014 — Rating maths and the self-play calibration harness

**What to build:** The rating system exists as tested pure logic, and a headless command-line tool can play opponents against each other thousands of times to measure their real relative strength.

Nothing here is visible to a player in release 0.1 — rating only becomes live in 0.3. It is built now because the indicative strength numbers currently attached to the six opponents are estimates, and once they are published as live ratings they are effectively frozen. Correcting an anchor later invalidates every human rating derived from it. This is the tool that resolves that risk while it is still cheap.

**Blocked by:** 010 — Search and Onyx

**Status:** ready-for-agent

- [ ] Expected score, K-factor selection and rating update are implemented as pure functions in the rating package
- [ ] K is 32 below twenty rated games and 16 at or above
- [ ] Draws score one half, and ratings are rounded and floored at 100
- [ ] The rating package depends on nothing but the Dart core library
- [ ] Rating maths is verified against worked examples, including provisional play, draws and the floor
- [ ] A command-line tool plays any two catalogue opponents against each other for a configurable number of games
- [ ] The tool alternates who starts, so the first-player advantage does not distort results
- [ ] The tool reports win, loss and draw counts and an implied rating difference
- [ ] A full round-robin across all six opponents can be run in one command
- [ ] Results confirm the intended strength ordering: Pebble, Mote, Bramble, Ember, Basalt, Onyx
- [ ] Measured relative strengths are recorded so that the indicative numbers can be corrected before 0.3b makes them live
- [ ] The harness can calibrate a new opponent against opponents whose ratings are already fixed, not only run a free-floating round robin — the fourteen remaining opponents arrive in 0.6, after the scale is live and the first six are frozen
- [ ] The published indicative numbers are derived by human-anchoring the weaker opponents from closed-test results and chaining the stronger ones from measured gaps, and the chain is recorded so a later correction can be reasoned about
