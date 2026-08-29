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

**Status:** **closed as an informal test.** The survey was run face to face with
every active tester rather than built as an instrument, and the thresholds and
their pre-committed consequences were never written. **That is a decision, not an
oversight** (D373) — but it means this ticket did not do the one job it was
written for, so read the closure before treating 1.0's test as a measurement.

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


## Closure

**Closed without doing what it was written to do, deliberately.** This ticket's
first line is *"an instrument that lets the test actually fail"*, and no such
instrument exists. The survey happened — in person, with every active tester,
which for twelve people the developer knows is a better conversation than a form
would have been. What did not happen is everything that made it a *measurement*:

- no thresholds written before the test, so nothing can be missed;
- no pre-committed consequences, so nothing follows from missing them;
- no day-3 and day-10 statistics screenshots, so nothing distinguishes a tester
  who played once from one who came back;
- **no split between a metered and an unmetered part of the cohort**, which is
  the one that cannot be recovered afterwards.

**What that costs is specific, and it is not "we learned nothing".** An in-person
conversation is very good at finding what confused someone and quite bad at
finding who quietly stopped playing on day two — and the second is the question
1.0 exists to answer, because 2.0 and 3.0 are both built on the assumption that
people come back. The five pre-committed consequences in the list above are now
unenforceable: in particular *"day-10 screenshots show most testers stopped after
day 2 → do not ship the meter into that"*, which was the only thing standing
between a retention problem and a revenue feature layered on top of it.

**The invite-graph question is the one worth asking anyway, and it costs one
sentence.** *"Name someone you would actually play a game against over several
days."* It is the only cheap test of the demand for online play at 2.0 and the
tier-3 subscription at 3.0, and it can still be asked of twelve people in a
message this week. Nothing else here can be recovered retroactively; that one
can.

**Recorded in D373 with the rest of the reasoning.** The self-play calibration
chain (ticket 014) is unaffected — it never depended on tester data, and the
published ratings remain measured against each other rather than against humans.
