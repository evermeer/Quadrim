# 016 — Closed test with friends and family

**What to build:** A real build of Quadrim is on Google Play's closed testing track, twelve friends and family have it installed on their own devices, and the fourteen-day clock is running.

**This is not a public launch.** Release 0.1 is never promoted to production; the first public release is 0.3b. The closed test is simultaneously the distribution channel for the people who are 0.1's entire audience, and the mechanism that unlocks production access — Google Play requires personal developer accounts to run a closed test with at least twelve testers for fourteen continuous days before granting it. Satisfying that requirement now, with people who would be testing anyway, means it is banked long before 0.3b needs it.

Recruiting twelve people who will actually install and open the app is a real task with a real lead time. It is listed as acceptance criteria rather than assumed, because it is the part most likely to be treated as a formality and then to block everything.

**Staying private does not remove Play's declaration obligations.** Data Safety, content rating and the target-audience declaration are required before publishing to *any* track. What being private removes is the public listing and public discoverability.

**Blocked by:** 015 — Store accounts and release signing; 024 — Closed-test survey and thresholds; 030–035 — the progression tickets. (011, 013, 018, 028 and 029 are done.)

**The fourteen-day clock waits for progression (D259).** That is a deliberate cost to the critical path and the reason ticket 015 should already be underway — it is waiting time rather than effort and has no code dependency. The argument for waiting is that a fourteen-day closed test *is* a measurement of whether people come back, so running it against a build without the unlock ladder would measure a product nobody intends to ship.

**Status:** ready-for-agent

- [ ] A signed build is published to the closed testing track
- [ ] **The Data Safety declaration is completed as a research task, not an assumption** — determine the correct answers given that Android backup is enabled, by checking current Play Console guidance on backup and on end-to-end-encrypted data, and record both the answers and the date the guidance was checked
- [ ] The content rating questionnaire is completed
- [ ] The target-audience declaration is completed, with its reasoning recorded — **an audience band including under-13s would make the free-text chat planned for 0.4 effectively unshippable**
- [ ] Whether Play requires a published privacy policy for this app, on this track, is checked and the answer recorded
- [ ] A closed-testing listing exists with enough for a tester to install: title, short description, icon and screenshots, in English and Dutch
- [ ] Twelve testers are recruited and have opted into the closed test
- [ ] All twelve have installed the app and opened it at least once
- [ ] The survey instrument from ticket 024 is given to testers **at install**, not at the end
- [ ] The fourteen-day continuous-testing clock has started, and its start date is recorded
- [ ] A route exists for testers to report problems, and it is communicated to them
- [ ] Tester feedback is collected somewhere durable rather than in scattered messages
- [ ] Testers are given a written privacy notice at install: what is collected (their Play enrolment address, survey answers, two statistics screenshots), why, who holds it, how long, and how to withdraw. **This is the developer's processing, not the app's, and it is the only personal data release 0.1 involves**
- [ ] Whether DSA trader-verification duties apply to closed-testing-only distribution is checked and recorded with a date — if they do, they apply here and not only at 0.4
- [ ] The build published to the track contains points, unlocks, quests and streaks — spec gate R12
- [ ] The build is **not** promoted to production
