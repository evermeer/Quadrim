# 022 — Release 0.1 readiness

**What to build:** Release 0.1 is finished and defensible. Every acceptance criterion in the specification passes, the closed test has run its full course, and what the testers found has been acted on or explicitly deferred with a reason.

0.1 is a **private** release. It is not promoted to production and gets no public listing — that arrives with 0.3b. What this ticket closes is the quality of the build twelve real people are using, and the readiness of everything that follows.

**Blocked by:** every other ticket in release 0.1.

**Status:** ready-for-agent

- [ ] Every engine acceptance criterion in the specification passes
- [ ] Every game-flow acceptance criterion passes
- [ ] Every interface acceptance criterion passes
- [ ] Every tutorial acceptance criterion passes
- [ ] Every data acceptance criterion passes
- [ ] Every security and privacy acceptance criterion that 0.1 can satisfy passes
- [ ] The backup allowlist has been re-verified against what is actually in the app directory — a new dependency can add state silently
- [ ] The fourteen-day closed test has completed with twelve testers throughout
- [ ] **Production access has been granted, and is banked rather than used**
- [ ] Survey results are collected and compared against the thresholds committed in ticket 024
- [ ] Where a threshold was missed, the consequence pre-committed in ticket 024 has been carried out — not reinterpreted after the fact
- [ ] Tester feedback is reviewed, and anything blocking is fixed or explicitly deferred with a reason
- [ ] Measured opponent strengths from tester games are recorded against ticket 014's calibration chain
- [ ] Any privacy text shown in the app is accurate: gameplay data is stored on the device, and Android's system backup may copy it to the user's own Google account under Google's terms, where the developer cannot read it. **The phrase "no data leaves the device" must not appear anywhere** — it is not true
- [ ] The final build is signed with the backed-up upload key, and the backup is verified once more
- [ ] A fresh install on a device that has never run the app works correctly from first launch through the tutorial to a completed game
- [ ] All twenty opponents are present, distinguishable in play, and calibrated on one scale
- [ ] Quadrim Prime's description matches what it actually delivers — extremely strong, not perfect, until the solver lands at 1.0
- [ ] Known limitations of 0.1 are recorded: no accounts, no online play, the computer rating is local to this device and does not follow the player to another platform, and playing real opponents will require a subscription from 0.3b
- [ ] The release is tagged in version control
