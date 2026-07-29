# 016 — Closed test with friends and family

**What to build:** A real build of Quadrim is on Google Play's closed testing track, twelve friends and family have it installed on their own devices, and the fourteen-day clock is running.

**This is not a public launch.** Release 0.1 is never promoted to production; the first public release is 0.3b. The closed test is simultaneously the distribution channel for the people who are 0.1's entire audience, and the mechanism that unlocks production access — Google Play requires personal developer accounts to run a closed test with at least twelve testers for fourteen continuous days before granting it. Satisfying that requirement now, with people who would be testing anyway, means it is banked long before 0.3b needs it.

Recruiting twelve people who will actually install and open the app is a real task with a real lead time. It is listed as acceptance criteria rather than assumed, because it is the part most likely to be treated as a formality and then to block everything.

**Staying private does not remove Play's declaration obligations.** Data Safety, content rating and the target-audience declaration are required before publishing to *any* track. What being private removes is the public listing and public discoverability.

**Blocked by:** 011 — Opponent selection; 013 — Main screen; 015 — Store accounts and release signing; 018 — Tutorial: rules and controls; 024 — Closed-test survey and thresholds

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
- [ ] The build is **not** promoted to production
