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

**Status:** **done.** Both tracks are live, twelve testers are playing on Play
and TestFlight has been in hands longer. The measuring half was carried out **in
person rather than as an instrument** — see the closure, which records that as a
deliberate choice and names what it costs (D373).

- [x] A signed build is published to **TestFlight**, and testers can install it
- [x] **The cohort size and the test duration are chosen** — twelve, running
      until the developer judges it has run long enough. Written down here rather
      than beforehand, which is what R20 warned against; recorded honestly in the
      closure rather than backdated
- [x] A signed build is published to Play's closed testing track — the account
      came back on 2026-08-21 and the track is live
- [x] **The Data Safety declaration is completed as a research task, not an assumption** — determine the correct answers given that Android backup is enabled, by checking current Play Console guidance on backup and on end-to-end-encrypted data, and record both the answers and the date the guidance was checked
- [x] The content rating questionnaire is completed
- [x] The target-audience declaration is completed, with its reasoning recorded — **an audience band including under-13s would make the free-text chat planned for 0.4 effectively unshippable**
- [ ] Whether Play requires a published privacy policy for this app, on this track, is checked and the answer recorded
- [x] A closed-testing listing exists with enough for a tester to install: title, short description, icon and screenshots, in English and Dutch
- [x] Testers are recruited and have opted in — **twelve on Play**, and the
      developer's judgement is that twelve is enough; more are welcome rather than
      needed
- [x] All of them have installed the app and opened it at least once — the
      testers the survey was run with are the *active* ones, which is a stronger
      statement than installed
- [x] The survey was carried out **in person with every active tester** —
      not the written instrument ticket 024 specifies, and closer to the intent of
      "at install" than a form sent at the end would have been
- [x] The test period has started — *(Play's fourteen continuous days applies to
      the Android track, which is running.)* **The start date is not written down
      in this repository**; Play Console holds it, and that is where the fourteen
      days are counted anyway
- [x] A route exists for testers to report problems — informal and active, which
      for a cohort of twelve people the developer knows is the route that actually
      gets used
- [ ] Tester feedback is collected somewhere durable rather than in scattered
      messages — **not done, and the one item here worth regretting later.** In-person
      feedback that is never written down is gone in a fortnight
- [~] Testers are given a written privacy notice at install: what is collected (their Play enrolment address, survey answers, two statistics screenshots), why, who holds it, how long, and how to withdraw. **This is the developer's processing, not the app's, and it is the only personal data release 0.1 involves**
- [x] Whether DSA trader-verification duties apply to closed-testing-only distribution is checked and recorded with a date — answered with ticket 015
- [x] The build contains points, unlocks, quests and streaks — spec gate R12 —
      **and the meter**, for the reason in the header
- [x] The build is **not** promoted to production on Play. *(The iOS submission
      in review is a deliberate act of the same kind, made knowingly.)*
- [x] The target-audience declaration's reasoning is recorded — set, and fine for
      now. **The reasoning lives in the Play Console rather than here**, and the
      constraint stands: an audience band including under-13s would make 2.0's
      free-text chat effectively unshippable, and it also constrains what may be
      sold at 1.0


## Closure

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

**The measuring half happened in person instead of as an instrument**, which is
the whole of D373 and the reason this ticket closes rather than waiting. The
survey was run face to face with every active tester, feedback is informal and
ongoing, and the developer's judgement is that twelve is enough. What that gives
up — written thresholds, pre-committed consequences, day-3 and day-10 statistics
screenshots, and a metered/unmetered split — is listed in D373 with its cost
rather than quietly dropped.

**One item is left unticked on purpose.** Tester feedback is not being written
down anywhere durable. That is not process hygiene: in a fortnight the difference
between "three people hesitated at the same screen" and "somebody mentioned
something about the board" is the difference between a fix and a vague unease.
It costs a text file.

**And one is marked part-done.** Testers were given no *written* privacy notice.
The survey was in person, so what is held is survey answers and a Play enrolment
address for twelve people the developer knows — small, and still the developer's
own processing rather than the app's, which is the distinction this line was
written to catch. Worth a short message to the twelve rather than a document.
