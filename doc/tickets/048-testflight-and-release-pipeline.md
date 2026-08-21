# Ticket 048 — TestFlight and the iOS release pipeline

**Depends on:** 041, 042, 043. **Blocked on** Apple Developer enrolment.

**Status:** blocked on the account, on a Mac

## Why

The Android release pipeline was proven at ticket 015: one command produces a
signed build that installs on a device. iOS needs its own, and it is the gate
to everything public — under the re-cut plan **TestFlight, not Play's
fourteen-day closed test, is what stands between the work and a public
release** (D302).

## What it does

### 1. Version

The app is at `0.1.0+1` in `pubspec.yaml`. It becomes **`1.0.0+1`**.

The build number `+N` must increase on every upload to App Store Connect and
can never be reused for a version, including for builds that were rejected or
never released. Pick the scheme now and write it down — a monotonic integer is
enough and is what the rest of this repo's simplicity suggests. Note it beside
the Android `versionCode`, which has the same rule and its own counter.

### 2. Signing

- An App ID for `nl.evict.quadrim2` in the developer portal — **not**
  `nl.evict.quadrim`, which is the Android id and stays Android's (D359).
- Distribution certificate and provisioning profile.
- **Automatic signing in Xcode** unless there is a reason not to; a solo
  developer on one Mac gains nothing from managing profiles by hand and loses
  an afternoon each time one expires.
- **Credentials stay out of version control**, as the Android keystore does
  (ticket 015). `ExportOptions.plist` is committed; nothing with a secret in it
  is.

### 3. The command

```
cd app && flutter build ipa --release
```

and an upload path — Xcode Organizer, or `xcrun altool`/`notarytool` from the
command line. **Prove the whole path once by hand before automating any of
it.**

### 4. TestFlight

- Internal testing first: the developer's own devices, no review, available in
  minutes.
- Then external testing if the cohort chosen in ticket 024 needs more than the
  internal limit — external builds go through a review, which is a wait to
  plan for rather than discover.
- **Install from TestFlight and play a game**, on a device that has never had a
  development build on it. A build that runs from Xcode and fails from
  TestFlight is a signing or entitlements problem, and it is better to find it
  here than in review.

### 5. What this ticket proves about purchases

Nothing — and that is worth stating, because it is a trap. **Sandbox purchases
behave differently in a TestFlight build than in a development build**: a
TestFlight build uses the sandbox environment automatically for the tester's
Apple Account, without a Sandbox Apple Account. Re-run 046's purchase and
restore checks here, from TestFlight, and record the result separately.

## Acceptance criteria

1. `pubspec.yaml` reads `1.0.0+1`, and the build-number scheme is recorded.
2. One command produces a signed release `.ipa`.
3. That `.ipa` uploads to App Store Connect with no validation warning —
   including no icon-alpha and no privacy-manifest warning (042, 043).
4. An internal TestFlight build installs on a device with no development
   profile on it, and a full game can be played on it.
5. A purchase and a restore complete **from the TestFlight build**, recorded
   separately from 046's sandbox results.
6. No signing credential is in version control, enforced the way ticket 015
   enforces it for the keystore.
7. `bash tool/check.sh` passes.

## Notes

**The Android half of 1.0 is the same version and a different queue.** When
the Play account returns, the Android build ships as 1.0 with no version bump
and no new work beyond its own upload (D302). **Superseded by D359:** one `+N` counter in
`pubspec.yaml` serves both stores and is raised on every upload to either, so
the stores see gaps rather than separate sequences. Each store only requires
the number to increase, which a shared ratchet satisfies.

**Do not let the first upload be the first time anyone reads Apple's review
guidelines.** The likely friction points for this app are the subscription
metadata (a subscription must state its price, period and what it unlocks in
the listing itself) and the restore action being findable. Both are cheaper to
fix before submission than after a rejection.
