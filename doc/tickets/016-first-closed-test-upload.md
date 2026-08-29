# 016 — The first test build in testers' hands

**What to build:** A real build of Quadrim is on a testing track and a cohort
of friends and family have it installed on their own devices, playing it, with
the survey from ticket 024 in their hands.

**Re-pointed by D302. This was a Google Play ticket and is now an Apple one
first.** It used to read "twelve friends and family, fourteen continuous days,
because that is what Play requires before granting production access". That
requirement has not gone away — it still applies to the Android build — but it
is no longer the gate to a public release, because the public release now goes
out through the App Store.

What changed, concretely:

- **TestFlight is the primary channel.** Internal testing reaches the owner's
  own devices with no review; external testing reaches a wider cohort after a
  review. Ticket 048 builds that pipeline; this ticket is about the people at
  the other end of it.
- **The cohort size and duration are ours to choose.** Twelve-and-fourteen was
  Google's number, and with it gone there is no externally imposed discipline
  at all. **Choose both deliberately and write them down** (spec gate R20), or
  the measurement quietly becomes "some people looked at it".
- **The Play closed test still happens**, whenever that account returns, as the
  Android build's own gate. Its criteria are kept below rather than deleted.

**Blocked by:** 048 — TestFlight and the release pipeline; 024 — the survey and
its thresholds; 015 — the Apple account. The Play half is additionally blocked
on reactivation.

**The clock still waits for a build worth measuring (D259).** The original
argument survives its store change intact: a retention test measures whether
people come back, so running it against a build missing the thing that brings
them back measures a product nobody intends to ship. That was progression; at
1.0 it also means the meter, because a cap changes retention and shipping it
untested is the one thing this re-cut made worse (D302).

**Status:** in-progress — **both tracks are live and the builds are in
testers' hands.** TestFlight has been tested and a build is in review; Play's
closed test is running with twelve testers invited and more expected this week.
What is missing is the whole measuring half: the cohort and duration are not
written down, the survey from ticket 024 does not exist, and no privacy notice
has gone out. **A test that is running without those is not this ticket** — it
is people playing the game, which is pleasant and proves nothing (§ ticket 024).

- [x] A signed build is published to **TestFlight**, and testers can install it
- [ ] **The cohort size and the test duration are chosen and written down
      before the first tester installs** — no store imposes either any more
      (R20), and a number chosen afterwards is a rationalisation
- [x] A signed build is published to Play's closed testing track — the account
      came back on 2026-08-21 and the track is live
- [x] **The Data Safety declaration is completed as a research task, not an assumption** — determine the correct answers given that Android backup is enabled, by checking current Play Console guidance on backup and on end-to-end-encrypted data, and record both the answers and the date the guidance was checked
- [x] The content rating questionnaire is completed
- [x] The target-audience declaration is completed, with its reasoning recorded — **an audience band including under-13s would make the free-text chat planned for 0.4 effectively unshippable**
- [ ] Whether Play requires a published privacy policy for this app, on this track, is checked and the answer recorded
- [x] A closed-testing listing exists with enough for a tester to install: title, short description, icon and screenshots, in English and Dutch
- [~] Testers are recruited and have opted in — **twelve invited on Play**, with
      more expected. It is marked part-done rather than done because the number
      to compare it against was never chosen: twelve is Play's old requirement,
      not a decision, and the line above this one is what makes it one
- [ ] All of them have installed the app and opened it at least once —
      **invited is not installed**, and the gap between the two is the single
      most common way a closed test quietly fails to happen
- [ ] The survey instrument from ticket 024 is given to testers **at install**, not at the end
- [ ] The test period has started and its start date is recorded — it has
      started; **the date is not written down anywhere in this repository**, and
      Play's fourteen continuous days is counted from it. Record it here. *(Play's
      fourteen continuous days applies to the Android track, which is now running.)*
- [ ] A route exists for testers to report problems, and it is communicated to them
- [ ] Tester feedback is collected somewhere durable rather than in scattered messages
- [ ] Testers are given a written privacy notice at install: what is collected (their Play enrolment address, survey answers, two statistics screenshots), why, who holds it, how long, and how to withdraw. **This is the developer's processing, not the app's, and it is the only personal data release 0.1 involves**
- [ ] Whether DSA trader-verification duties apply to closed-testing-only distribution is checked and recorded with a date — if they do, they apply here and not only at 0.4
- [ ] The build contains points, unlocks, quests and streaks — spec gate R12 —
      **and the meter**, for the reason in the header
- [ ] The build is **not** promoted to production. Going public is ticket 049
      and a deliberate act, not the end of this one
- [ ] The target-audience declaration's reasoning is recorded — **an audience
      band including under-13s would make the free-text chat planned for 2.0
      effectively unshippable**, and it also constrains what may be sold at 1.0


## What the running test still needs

Three of the boxes above are ticked because **Play will not release to any
track, closed testing included, until they are answered** — Data Safety, the
content rating questionnaire, the target audience and a store listing are all
gates in front of the button that was pressed. They are recorded as done for
that reason and not on a separate report.

**Two of them carry a consequence worth re-reading rather than filing.** The
target-audience answer constrains what may be sold at 1.0 and would make 2.0's
free-text chat effectively unshippable if it includes under-13s; and the Data
Safety answers must match the App Store privacy labels and
`PrivacyInfo.xcprivacy` exactly, because a mismatch between the two forms is a
rejection rather than a note. **Whatever was answered in the Play Console, copy
it into `doc/store-listing.md`** — the answers currently live only in a web form,
and the next person to fill Apple's version will answer from memory.

**The measuring half has not started, and the test is already running.** Ticket
024 is the instrument and it is unbuilt: no survey, no thresholds, no
pre-committed consequences, no day-3 and day-10 screenshots asked for, and no
split between a metered and an unmetered part of the cohort. Every one of those
has to be in a tester's hands *at install* to mean anything, and testers are
installing now. **This is the one thing on this ticket that gets harder every
day rather than staying still.**
