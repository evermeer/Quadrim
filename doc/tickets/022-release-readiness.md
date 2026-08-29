# 022 — Release 1.0 readiness

**What to build:** Release 1.0 is finished and defensible. Every acceptance
criterion in the specification passes, the test period has run its course, and
what the testers found has been acted on or explicitly deferred with a reason.

**Re-pointed by D302. This was "release 0.1 readiness", for a private release
that would never be promoted.** 1.0 goes public, so the same sweep now has to
clear a higher bar: everything below still applies, and the things a public,
paid, two-platform release adds are appended.

**Blocked by:** **021 alone.** Everything else in 1.0 is closed: 015, 016, 024,
041–049. Tickets 017 and 023 are closed unbuilt (cancelled and absorbed
respectively, D269) and never gated this one.

**Status:** blocked on one thing, and it is not a build. **021's screen-reader
pass needs a physical device with TalkBack and with VoiceOver**, and no agent can
do it. Everything else on this ticket is a sweep that can be run from here.

**Four criteria below were re-pointed when 016 and 024 closed informally**
(D373). They asked for survey results against pre-committed thresholds; no
thresholds were written, so there is nothing to compare against and no consequence
to carry out. They are marked waived with their reason rather than deleted, so
that a later reader can see 1.0 shipped without the measurement rather than
concluding it passed one.

- [ ] Every engine acceptance criterion in the specification passes
- [ ] Every game-flow acceptance criterion passes
- [ ] Every interface acceptance criterion passes
- [ ] Every tutorial acceptance criterion passes
- [ ] Every data acceptance criterion passes
- [ ] Every security and privacy acceptance criterion that 0.1 can satisfy passes
- [ ] The backup allowlist has been re-verified against what is actually in the app directory — a new dependency can add state silently
- [x] The test period chosen in ticket 016 has completed with its cohort intact — twelve testers on Play, active, and the developer's judgement that it has run long enough (D373)
- [ ] **Play production access has been granted** — *Android half; the closed
      test is running and this follows from it. No longer a gate on going public
      (D302), since the public release goes out through the App Store*
- [~] ~~Survey results are collected and compared against the thresholds committed in ticket 024~~ — **waived (D373).** The survey was run in person and no thresholds were written, so there is nothing to compare against. What exists is a conversation with twelve people, and it is not written down
- [~] ~~Where a threshold was missed, the consequence pre-committed in ticket 024 has been carried out~~ — **waived (D373)**, and unenforceable: no threshold was committed, so none can be missed. The consequence this gives up by name is *"day-10 screenshots show most testers stopped after day 2 → do not ship the meter into that"*
- [ ] Tester feedback is reviewed, and anything blocking is fixed or explicitly deferred with a reason — **the one survivor of the four, and now the only tester-derived input to the release.** It is informal and unwritten, so reviewing it means recalling it deliberately rather than reading it
- [~] ~~Measured opponent strengths from tester games are recorded against ticket 014's calibration chain~~ — **waived (D373), decided 2026-08-29.** No statistics screenshots were collected and none will be. **Every one of the thirty-one published ratings is measured by bots playing bots**, which is internally consistent and has never been anchored to a human. That is a known property of the ladder rather than a defect, and it is what ticket 021's usable-range question would have tested
- [ ] The privacy policy's contact block is filled in `doc/store-listing.md` and matches the page actually published at the URL both stores were given — the decision closed with 015, the paste did not (049)
- [ ] Any privacy text shown in the app is accurate: gameplay data is stored on the device, and Android's system backup may copy it to the user's own Google account under Google's terms, where the developer cannot read it. **The phrase "no data leaves the device" must not appear anywhere** — it is not true
- [ ] The final build is signed with the backed-up upload key, and the backup is verified once more
- [ ] A fresh install on a device that has never run the app works correctly from first launch through the tutorial to a completed game
- [ ] All twenty opponents are present, distinguishable in play, and calibrated on one scale
- [ ] Quadrim Prime's description matches what it actually delivers — never "perfect", always **"unbeatable when it moves first"** (D181, P21)
- [ ] Known limitations of 1.0 are recorded: no accounts, no online play, the computer rating is local to this device and does not follow the player to another platform, and online play arrives free at 2.0 and becomes paid at 3.0 (D304). **Add to that list: the ladder is calibrated against itself and never against a human player** (D373)
- [ ] The release is tagged in version control

**Added by the 1.0 re-cut:**

- [ ] The app runs, and every criterion above passes, **on both Android and iOS**
- [~] A purchase and a restore have been verified from a **TestFlight** build, not only from a development build (048) — **the purchase half is reported done; the restore half is not recorded.** Restore is the one a reinstalling player needs and the one Apple asks to see, so do it deliberately rather than assuming it came along with the purchase
- [ ] The **meter's limitation is stated accurately** wherever it is mentioned: at 1.0 it is device-local and a reinstall clears it (S19, D303). No copy claims otherwise
- [ ] The iOS privacy manifest and the App Store privacy labels are consistent with each other and with what the app actually does (043, 049)
- [ ] Unlock records survive a backup-and-restore **on both platforms** (D11)
- [ ] The Casual-tier inversion is fixed and measurement confirms it (044) — this must be true **before the first sale**, not before the first upload
- [ ] The iOS "no network call during computer play" claim is recorded at its real strength — reviewed, not enforced (S20, D306)
- [x] Whether Play Billing's manifest merge injects `INTERNET` has been established empirically, and `check.sh` is correct either way (D306) — **it does**: `transport-backend-cct` declares it, and a bundle shipped with the permission while the old source-manifest check passed. It is now stripped from the merge with `tools:node="remove"` and the check reads the *merged* manifest (D356, D357)
- [ ] **Whether a Play Billing purchase completes with `INTERNET` stripped is confirmed on a real Android install** — the other half of the same question, and the closed test is what settles it. Billing talks to the Play Store app over IPC rather than over a socket, so it is expected to work; expected is what D357 declined to accept
