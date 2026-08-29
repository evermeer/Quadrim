# 024 — Test survey and thresholds

**What to build:** An instrument that lets the test actually fail.

Every other success criterion for 1.0 measures whether the build got finished.
None of them measure whether anyone wanted it. Without this ticket, 1.0 cannot
fail — and therefore cannot teach anything before 2.0 and 3.0 are built on top
of it.

**Re-pointed by D302, and this ticket matters more than it did, not less.** It
was written to sit inside a Play closed test whose twelve testers and fourteen
days were imposed by Google. That imposition is gone, and with it the only
external force that was going to make this measurement happen. **The
thresholds below are now the entire discipline.**

One thing genuinely changed rather than being renamed: **the meter ships in
1.0**, which means this test is the last chance to see the ladder *without* a
cap on top of it. Whatever cohort runs this, part of it should run unmetered
and part metered, or the two effects can never be told apart afterwards
(§4.2).

The app has no analytics and no network, by design, and that must not change. So the measurement is a survey plus an artefact the tester supplies: a screenshot of their own main-screen statistics, at day 3 and again at day 10. That is verifiable, costs nothing to build, changes no privacy declaration — and doubles as the human-versus-opponent result set that ticket 014's calibration needs.

**Thresholds and their consequences must be written down before the test starts.** A threshold decided afterwards is a rationalisation, and a threshold with no consequence attached is decoration.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent — **and now late.** The test it measures has
started: twelve testers are invited on Play and a TestFlight build has been in
hands for longer. Every instrument here is specified to reach a tester **at
install**, and installs are happening now. Each day this waits, part of the
cohort permanently cannot be measured — a survey handed out at the end asks
people to remember what confused them, which is the one thing they will have
forgotten.

**The unmetered/metered split is the item that expires first.** It cannot be
applied retroactively to anyone already playing, and without it the ladder and
the cap can never be told apart in the results (D302).

- [ ] A short survey exists in English and Dutch, written to be answerable in a few minutes
- [ ] It asks what the tester found confusing, where they hesitated, and which opponent felt like the right match
- [ ] Testers are asked for a screenshot of their main-screen statistics at day 3 and at day 10
- [ ] It asks **"name someone you would actually play a game against over several days"** and counts how many testers can name at least one. This measures the invite graph, which is the entire demand for online play at 2.0 and the tier-3 subscription at 3.0 — and it is the only cheap chance to test that half of the business model before two releases are built on the assumption that it works
- [ ] It asks which opponent felt like the right match, so the ladder's usable range is measured rather than assumed
- [ ] Testers receive the written privacy notice alongside the survey, and the screenshots are deleted once ticket 014's calibration has consumed them
- [ ] The instrument is given to testers at install, not at the end of the test
- [ ] Pass thresholds are committed in writing **before** the first tester installs, as fractions of whatever cohort ticket 016 chose. As a starting point: **two thirds** complete the tutorial and beat Pebble without help; **half** have played again between day 3 and day 10, evidenced by their two screenshots differing
- [ ] Each threshold has a pre-committed consequence, also written before the test:
  - [ ] Tutorial or Pebble threshold missed → the board or the tutorial is wrong; fix before 1.0 goes public
  - [ ] Most testers never beat anything above Bramble → the ladder is mis-anchored; adjust configurations in ticket 014's chain, never the published ratings (D144)
  - [ ] Day-10 screenshots show most testers stopped after day 2 → **do not ship the meter into that**; a cap on top of a retention problem hides the retention problem behind a revenue problem
  - [ ] Fewer than half can name a human they would play → tier 3 does not ship at 3.0 either, and human play stays free until a population exists
  - [ ] **The metered part of the cohort quits materially sooner than the unmetered part** → the cap is set wrong, and three-a-day is a number derived from a target rather than measured (§7.7). Change it before the public release, not after
- [ ] It measures **the median time to each unlock** and **the rung at which players stop** — spec gate R13. The progression numbers are the only ones in the specification derived from a stated target rather than measured, so these two are the first things to instrument, and the day-3 and day-10 screenshots already carry them
- [ ] A threshold and a consequence exist for the ladder itself: **if no tester unlocks a single opponent, the ladder has failed** — that is success criterion G8, and it is the one behavioural signal that the app's central feature works
- [ ] Part of the cohort runs **unmetered** and part **metered**, so the ladder and the cap can be told apart. Without this split, a retention number after 1.0 means nothing (D302)
- [ ] Results are recorded somewhere durable alongside the decision each one triggered
- [ ] No analytics, no network call, and no change to any store declaration is introduced by any of this
