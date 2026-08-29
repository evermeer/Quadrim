# 022 — Release 1.0 readiness

**What to build:** Release 1.0 is finished and defensible. Every acceptance
criterion in the specification passes, the test period has run its course, and
what the testers found has been acted on or explicitly deferred with a reason.

**Re-pointed by D302. This was "release 0.1 readiness", for a private release
that would never be promoted.** 1.0 goes public, so the same sweep now has to
clear a higher bar: everything below still applies, and the things a public,
paid, two-platform release adds are appended.

**Blocked by:** nothing any more. Every other 1.0 ticket is closed — 015, 016,
021, 024 and 041–049. Tickets 017 and 023 were closed unbuilt (cancelled and
absorbed respectively, D269) and never gated this one.

**Status:** **swept on 2026-08-29.** Most criteria pass and are ticked with the
evidence beside them. Two things came out of the sweep, and they are the point of
having done it:

1. **Three layout defects were found today and fixed — and they are in the build
   currently in App Store review** (ticket 021's closure). Nothing crashes; at
   200% font scale content is clipped, and on the new-game sheet that means the
   second of the two ways to start a game is partly off the bottom.
2. ~~The ladder has not been measured since `bot.dart` changed by 573 lines.~~
   **Re-measured — 140 pairs, 274 minutes — and it holds.** Every rung is inside
   tolerance and there are no configuration defects; all three of the run's flags
   were 10%-budget artefacts, two already settled by D342 and the third settled
   here (D375). Recorded below.
3. **The release is not tagged**, deliberately: a tag should mark what shipped,
   and what shipped is not what HEAD now says. Everything still open needs a
   device, a store, or a decision — the list is at the end.

- [x] Every engine acceptance criterion in the specification passes — 125 engine tests, 117 progression, 35 rating, all green
- [x] Every game-flow acceptance criterion passes — inside the 422-test app suite
- [x] Every interface acceptance criterion passes — **and U20 did not, until today.** The font-scale sweep added in ticket 021 found three overflows at 2x on a 320pt phone: the new-game sheet by 49dp, the opponent list by 212dp horizontally, and the opponent screen's app bar by 16dp. All three are fixed and covered by tests. **All three are in the build in review**
- [x] Every tutorial acceptance criterion passes — twelve steps, ten showing a board, and now swept at 2x step by step
- [x] Every data acceptance criterion passes
- [x] Every security and privacy acceptance criterion that 1.0 can satisfy passes — the release manifest was rebuilt today and carries **zero `INTERNET` declarations**; `check.sh` reported "verified against the merged release manifest" rather than falling back to asserting. *(The stale debug manifests in `app/build` do declare it, which is expected and is why the check looks only at release.)*
- [x] The backup allowlist has been re-verified against what is actually in the app directory — **and the structure is what makes this safe, not the audit.** Both rule files are include-only: `<include domain="file" path="quadrim/">` and nothing else, so state a new dependency adds is excluded by default rather than needing to be spotted. The app writes to `getApplicationSupportDirectory()/quadrim`, which is `files/quadrim/` on Android — the path the allowlist names (D131). The plugins that resolve are `in_app_purchase_android`, `in_app_purchase_storekit`, `path_provider_*` and `jni`; none keeps app-private state under `files/`, and entitlement is rebuilt each launch rather than persisted (D349)
- [x] The test period chosen in ticket 016 has completed with its cohort intact — twelve testers on Play, active, and the developer's judgement that it has run long enough (D373)
- [ ] **Play production access has been granted** — *Android half; the closed
      test is running and this follows from it. No longer a gate on going public
      (D302), since the public release goes out through the App Store*
- [~] ~~Survey results are collected and compared against the thresholds committed in ticket 024~~ — **waived (D373).** The survey was run in person and no thresholds were written, so there is nothing to compare against. What exists is a conversation with twelve people, and it is not written down
- [~] ~~Where a threshold was missed, the consequence pre-committed in ticket 024 has been carried out~~ — **waived (D373)**, and unenforceable: no threshold was committed, so none can be missed. The consequence this gives up by name is *"day-10 screenshots show most testers stopped after day 2 → do not ship the meter into that"*
- [ ] Tester feedback is reviewed, and anything blocking is fixed or explicitly deferred with a reason — **the one survivor of the four, and now the only tester-derived input to the release.** It is informal and unwritten, so reviewing it means recalling it deliberately rather than reading it. *Only the developer can do this one*
- [~] ~~Measured opponent strengths from tester games are recorded against ticket 014's calibration chain~~ — **waived (D373), decided 2026-08-29.** No statistics screenshots were collected and none will be. **Every one of the thirty-one published ratings is measured by bots playing bots**, which is internally consistent and has never been anchored to a human. That is a known property of the ladder rather than a defect, and it is what ticket 021's usable-range question would have tested
- [ ] The privacy policy's contact block is filled in `doc/store-listing.md` and matches the page actually published at the URL both stores were given — the decision closed with 015, the paste did not (049)
- [x] Any privacy text shown in the app is accurate: gameplay data is stored on the device, and Android's system backup may copy it to the user's own Google account under Google's terms, where the developer cannot read it. **The phrase "no data leaves the device" must not appear anywhere** — it is not true. **Verified by search** across `.dart`, `.arb`, `.md`, `.xml` and `.plist`, in English and Dutch: the only occurrences anywhere in the repository are documents forbidding the phrase or stating that the policy deliberately does not use it
- [~] The final build is signed with the backed-up upload key — a signed `app-release.aab` was produced today, `versionCode=9`, `versionName=0.1.3`. **Re-verifying the backup is the developer's action** and is the half this line exists for
- [ ] A fresh install on a device that has never run the app works correctly from first launch through the tutorial to a completed game — *needs a device that has never had a build on it; twelve testers are effectively this test, but nobody has walked the path deliberately and reported it*
- [x] All **thirty-one** opponents are present and distinguishable — thirty-one unique ids, ratings 600 to 2400, and **zero inversions in catalogue order**. *(This line said "twenty", which the roster outgrew.)* Calibration is the criterion below
- [x] Quadrim Prime's description matches what it actually delivers — verified in both languages. `blurbQuadrimPrime` says "Unbeatable when it moves first" / "Onverslaanbaar als het begint", and `unlockConfirmBook` says the same. The word "perfect" appears once in the whole app, in `strategyCredit`, where it describes **Patashnik's dictionary** rather than the opponent — which is what D174 requires that line to say
- [x] Known limitations of 1.0 are recorded — written out in the closure below rather than left as a list of things to remember
- [ ] The release is tagged in version control — **deliberately not done yet.** A tag should mark what shipped, and HEAD now contains three layout fixes the build in review does not. Tagging is one command once that is resolved

**Added by the 1.0 re-cut:**

- [x] The app runs, and every criterion above passes, **on both Android and iOS** — reported from TestFlight on iOS and the closed test on Android (D371)
- [~] A purchase and a restore have been verified from a **TestFlight** build, not only from a development build (048) — **the purchase half is reported done; the restore half is not recorded.** Restore is the one a reinstalling player needs and the one Apple asks to see, so do it deliberately rather than assuming it came along with the purchase
- [ ] The **meter's limitation is stated accurately** wherever it is mentioned: at 1.0 it is device-local and a reinstall clears it (S19, D303). No copy claims otherwise
- [x] The iOS privacy manifest and the App Store privacy labels are consistent with each other and with what the app actually does (043, 049) — the manifest parses in `check.sh` and declares no tracking and an empty collected-data list; the labels were filled to match and are reported so. **Neither is written down here**, which 049's closure already flags
- [ ] Unlock records survive a backup-and-restore **on both platforms** (D11) — *needs two devices and a restore; not attempted*
- [x] The Casual-tier inversion is fixed and measurement confirms it (044) — **re-measured against the shipped catalogue on 2026-08-29**, because 044's run no longer covered it: `bot.dart` had changed by 573 lines since, and `calibrate.dart` was itself rewritten in the same stretch (D339, D341). 140 pairs. Willow, Vireo and Finch measure **1108, 1213, 1224** against published 1100, 1220, 1260 — ascending, which is the whole of 044's criterion 1. See the calibration section below
- [x] The iOS "no network call during computer play" claim is recorded at its real strength — reviewed, not enforced (S20, D306). Android's is enforced by the absent permission; iOS has no equivalent lever and the claim there rests on reading the code
- [x] Whether Play Billing's manifest merge injects `INTERNET` has been established empirically, and `check.sh` is correct either way (D306) — **it does**: `transport-backend-cct` declares it, and a bundle shipped with the permission while the old source-manifest check passed. It is now stripped from the merge with `tools:node="remove"` and the check reads the *merged* manifest (D356, D357)
- [ ] **Whether a Play Billing purchase completes with `INTERNET` stripped is confirmed on a real Android install** — the other half of the same question, and the closed test is what settles it. Billing talks to the Play Store app over IPC rather than over a socket, so it is expected to work; expected is what D357 declined to accept

## Sweep, 2026-08-29

Run against HEAD with a release bundle on disk, so the permission check was
authoritative rather than asserting. `bash tool/check.sh`: **ALL CHECKS PASSED**
— 422 app tests, 125 engine, 117 progression, 35 rating.

### What the sweep found

**Three interface defects, all shipped.** They are described in ticket 021's
closure and all three are now fixed and covered by tests. What matters here is
that **the build in App Store review and on twelve testers' phones contains all
three**. None is a crash; in a release build an overflow clips silently rather
than painting the debug stripes. The one worth weighing is the new-game sheet: at
200% font scale it is capped at 319.5dp holding 368.5dp of content, so the second
of the two ways to start a game is partly off the bottom. "Play the computer" is
the first row and stays reachable.

**That is a decision, not a defect report.** Either the current submission ships
with them and the fixes ride the next build, or it is pulled and resubmitted.
Nobody at 200% font scale is blocked from playing, so letting it ride is
defensible — but it should be chosen rather than discovered.

**The ladder's calibration predated the catalogue, so it was re-run.** Ticket
044 pasted a measured run into its closure and that run was no longer evidence
about what ships: `bot.dart` had changed by 573 lines since, and `calibrate.dart`
was rewritten in the same stretch to measure every opponent against the five
rungs above it (D339) and to take the median rather than the mean of the per-pair
estimates (D341). The fresh run is below, and **the ladder holds**.

### Known limitations of 1.0

Recorded here rather than left implicit, per the criterion above.

- **No accounts and no online play.** Both arrive at 2.0, free; online play
  becomes paid at 3.0 (D304).
- **The computer rating is local to the device.** It does not follow the player
  to another platform, or to a new phone except through the platform's own
  backup.
- **The meter is device-local and a reinstall clears it** (S19, D303). The copy
  says so in both languages: "Your free games are counted on this device."
- **The ladder is calibrated against itself and never against a human player**
  (D373). Every published rating comes from bots playing bots. It is internally
  consistent and reproducible; whether its scale coincides with human Elo is
  untested and will stay untested at 1.0.
- **Quadrim Prime is unbeatable only when it moves first.** From the second seat
  it plays by search like the rest, and the copy says so.
- **Backup is enabled**, so gameplay data may be copied to the player's own
  Google or Apple account under those companies' terms. *The app* sends nothing
  anywhere. The phrase "no data leaves the device" is false and appears nowhere
  (D72) — verified by search across `.dart`, `.arb`, `.md`, `.xml` and `.plist`,
  in both languages.
- **The cube board is not accessible** (D369). It carries one label naming the
  layered board as the way to read a position cell by cell, and the layered board
  stays the default.

### What is left, and who has to do it

Everything below needs a device, a store, or a decision:

1. **Decide what happens to the build in review** (above).
2. **A fresh install on a device that has never run the app**, walked from first
   launch through the tutorial to a finished game.
3. **A backup-and-restore, on both platforms**, confirming unlock records survive
   (D11).
4. **Restore purchases from the TestFlight build** — the half of 048's AC 5 that
   was never separately recorded.
5. **Review the tester feedback**, which is informal and unwritten, so this means
   recalling it deliberately.
6. **Paste the privacy policy's contact block** into `doc/store-listing.md` and
   read it against the published page (049).
7. **Settle the version name** — the public release currently carries `0.1.3`,
   not the `1.0.0` every ticket calls it (D372).
8. **Tag the release**, once 1 and 7 are answered.

## Calibration, 2026-08-29

`dart run tool/calibrate.dart --games 50`. **140 pairs, 274 minutes.** Budgets at
10%, which is what that instrument does and which is the reason two of its three
flags are not defects.

### Every one of the thirty-one rungs is inside tolerance

Tolerance is 150 points; sampling noise is about 49 points at 50 games and 25 at
the 200 every pair below Lynx plays (D344). The largest deviations are
**Quadrim Prime −146, Titan −135, Marlin +135, Heron +119**, and the three
negative ones all sit on node-budgeted opponents, which is exactly where a 10%
run under-reads (D342).

The Casual tier — 044's subject and the one this ticket names — is the tightest
part of the ladder: Pebble −62, Twig +5, Mote +4, Hazel +9, Clover +16,
Sorrel −15, Bramble −13. **044's fix holds:** Willow, Vireo and Finch measure
1108, 1213 and 1224, ascending, which is that ticket's criterion 1 re-proven
against code it was not measured on.

### Two of the three flags are not defects, and the run cannot know that

`calibrate.dart` reported:

```
configuration defects — fix the opponent, never the rating (D144):
  inversion: quartz (2100) beats titan (2200) — 27-17-6
  inversion: flint (2000) beats titan (2200) — 29-20-1
not readable at this budget — re-run these at --budget 1 before believing them:
  corvus (1700) beats basalt (1800) — 28-22-0
```

**The first two are the precise pairings D342 already settled**, and it settled
them by measuring both ways:

| pairing | published | at 10% | at full budget |
|---|---|---|---|
| Quartz → Titan | −100 | +83 | **−115** |
| Flint → Titan | −200 | +95 | **−241** |

Today's run reproduces the 10% column. At full budget Titan wins both, which is
the published order. **No configuration changes**, and the run's own header —
*"Any 10% result involving a node-budgeted opponent is evidence of nothing"* — is
why. The tool flags them because it cannot see D342; a reader who acts on the
flag without reading D342 would tune a correct ladder into a wrong one.

**The third flag was open, and is now settled the way D342 says to settle one** —
with `duel.dart`, which never scales:

```
corvus 14 - 36 basalt  (draws 0, games 50)
  implied difference: corvus -164 against basalt
  corvus: worst  46 ms, median 0 ms, mean  5 ms, moves 573
  basalt: worst 395 ms, median 0 ms, mean 73 ms, moves 584
```

Basalt wins better than two to one. The published gap is −100 and the measured
one is −164, which is the same direction and inside tolerance. **The published
order is right and nothing needs changing.**

### So: no configuration defects anywhere in the ladder

All three flags were artefacts of the 10% budget, and the third one extends
D342's rule past the tier it was written about (D375). Thirty-one rungs, every
one inside tolerance, ordering correct top to bottom.

### The half-hour budget in CLAUDE.md is wrong by an order of magnitude

That file says *"Budget half an hour"* for a full calibration. This run took
**274 minutes** — four and a half hours. The number matters because a wrong one
gets runs killed halfway on the assumption that they have hung, which is a
failure mode this repository has already paid for once (D178). Corrected there.
