# 024 — Closed-test survey and thresholds

**What to build:** An instrument that lets the closed test actually fail.

Every other success criterion for release 0.1 measures whether the build got finished. None of them measure whether anyone wanted it. Without this ticket, 0.1 cannot fail — and therefore cannot teach anything before 0.2, 0.3a and 0.3b are built on top of it.

The app has no analytics and no network, by design, and that must not change. So the measurement is a survey plus an artefact the tester supplies: a screenshot of their own main-screen statistics, at day 3 and again at day 10. That is verifiable, costs nothing to build, changes no privacy declaration — and doubles as the human-versus-opponent result set that ticket 014's calibration needs.

**Thresholds and their consequences must be written down before the test starts.** A threshold decided afterwards is a rationalisation, and a threshold with no consequence attached is decoration.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] A short survey exists in English and Dutch, written to be answerable in a few minutes
- [ ] It asks what the tester found confusing, where they hesitated, and which opponent felt like the right match
- [ ] Testers are asked for a screenshot of their main-screen statistics at day 3 and at day 10
- [ ] It asks **"name someone you would actually play a game against over several days"** and counts how many testers can name at least one. This measures the invite graph, which is the entire demand for the paid tier arriving at 0.4 — and it is the only cheap chance to test the business model before three releases are built on the assumption that it works
- [ ] It asks which opponent felt like the right match, so the ladder's usable range is measured rather than assumed
- [ ] Testers receive the written privacy notice alongside the survey, and the screenshots are deleted once ticket 014's calibration has consumed them
- [ ] The instrument is given to testers at install, not at the end of the test
- [ ] Pass thresholds are committed in writing **before** the first tester installs. As a starting point: at least 8 of 12 complete the tutorial and beat Pebble without help; at least 6 of 12 have played again between day 3 and day 10, evidenced by their two screenshots differing
- [ ] Each threshold has a pre-committed consequence, also written before the test:
  - [ ] Tutorial or Pebble threshold missed → the board or the tutorial is wrong; fix before 0.2
  - [ ] Most testers never beat anything above Bramble → the ladder is mis-anchored; adjust configurations and published ratings in ticket 014 before 0.2
  - [ ] Day-10 screenshots show most testers stopped after day 2 → do not spend time on 0.2 polish; go straight at 0.3a
  - [ ] Fewer than half can name a human they would play → the paywall does not ship at 0.4 either, and human play stays free until a population exists
- [ ] Results are recorded somewhere durable alongside the decision each one triggered
- [ ] No analytics, no network call, and no change to any store declaration is introduced by any of this
