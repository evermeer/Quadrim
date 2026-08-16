# 022 — Release 1.0 readiness

**What to build:** Release 1.0 is finished and defensible. Every acceptance
criterion in the specification passes, the test period has run its course, and
what the testers found has been acted on or explicitly deferred with a reason.

**Re-pointed by D302. This was "release 0.1 readiness", for a private release
that would never be promoted.** 1.0 goes public, so the same sweep now has to
clear a higher bar: everything below still applies, and the things a public,
paid, two-platform release adds are appended.

**Blocked by:** everything else in 1.0 — 015, 016, 021, 024, and 041–049.
Tickets 017 and 023 are closed unbuilt (cancelled and absorbed respectively,
D269) and do not gate this one.

**Status:** blocked

- [ ] Every engine acceptance criterion in the specification passes
- [ ] Every game-flow acceptance criterion passes
- [ ] Every interface acceptance criterion passes
- [ ] Every tutorial acceptance criterion passes
- [ ] Every data acceptance criterion passes
- [ ] Every security and privacy acceptance criterion that 0.1 can satisfy passes
- [ ] The backup allowlist has been re-verified against what is actually in the app directory — a new dependency can add state silently
- [ ] The test period chosen in ticket 016 has completed with its cohort intact
- [ ] **Play production access has been granted** — *Android half, whenever
      that account returns; no longer a gate on going public (D302)*
- [ ] Survey results are collected and compared against the thresholds committed in ticket 024
- [ ] Where a threshold was missed, the consequence pre-committed in ticket 024 has been carried out — not reinterpreted after the fact
- [ ] Tester feedback is reviewed, and anything blocking is fixed or explicitly deferred with a reason
- [ ] Measured opponent strengths from tester games are recorded against ticket 014's calibration chain
- [ ] Any privacy text shown in the app is accurate: gameplay data is stored on the device, and Android's system backup may copy it to the user's own Google account under Google's terms, where the developer cannot read it. **The phrase "no data leaves the device" must not appear anywhere** — it is not true
- [ ] The final build is signed with the backed-up upload key, and the backup is verified once more
- [ ] A fresh install on a device that has never run the app works correctly from first launch through the tutorial to a completed game
- [ ] All twenty opponents are present, distinguishable in play, and calibrated on one scale
- [ ] Quadrim Prime's description matches what it actually delivers — never "perfect", always **"unbeatable when it moves first"** (D181, P21)
- [ ] Known limitations of 1.0 are recorded: no accounts, no online play, the computer rating is local to this device and does not follow the player to another platform, and online play arrives free at 2.0 and becomes paid at 3.0 (D304)
- [ ] The release is tagged in version control

**Added by the 1.0 re-cut:**

- [ ] The app runs, and every criterion above passes, **on both Android and iOS**
- [ ] A purchase and a restore have been verified from a **TestFlight** build, not only from a development build (048)
- [ ] The **meter's limitation is stated accurately** wherever it is mentioned: at 1.0 it is device-local and a reinstall clears it (S19, D303). No copy claims otherwise
- [ ] The iOS privacy manifest and the App Store privacy labels are consistent with each other and with what the app actually does (043, 049)
- [ ] Unlock records survive a backup-and-restore **on both platforms** (D11)
- [ ] The Casual-tier inversion is fixed and measurement confirms it (044) — this must be true **before the first sale**, not before the first upload
- [ ] The iOS "no network call during computer play" claim is recorded at its real strength — reviewed, not enforced (S20, D306)
- [ ] Whether Play Billing's manifest merge injects `INTERNET` has been established empirically, and `check.sh` is correct either way (D306)
