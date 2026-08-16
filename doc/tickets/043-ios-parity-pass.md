# Ticket 043 — iOS parity: backup, privacy manifest, and the accessibility pass

**Depends on:** 041 (the iOS project exists)

**Status:** ready-for-agent, on a Mac

## Why

Three of this project's guarantees are enforced by Android mechanisms with no
iOS counterpart, and a fourth is enforced by nothing on either platform and
was only ever verified by looking (D306). None of them is code that needs
writing so much as behaviour that needs *checking on a device* — which is why
they are one ticket and not four.

## What it does

### 1. Unlock records survive a device change

D11 says a restore onto a new device returns every unlock the player earned.
On Android that is the explicit backup allowlist (D9). On iOS there is no
allowlist: the app's `Documents` directory is backed up to iCloud by default,
and `path_provider`'s `getApplicationDocumentsDirectory()` maps to exactly
that. So the guarantee should already hold — **and "should already hold" is
the thing this ticket exists to disprove or confirm.**

Verify it the only way it can be verified: back up a device with unlocks
earned, restore onto another device or a wiped one, and check the unlocks are
there. Record the method and the result.

If Apple's "don't back up regenerable data" guidance comes up in review, the
answer is that unlock records are precisely the *non*-regenerable data —
everything else in this app (balances, streaks, quest progress, statistics) is
derived from game history and is regenerable by design (§7.4).

### 2. The privacy manifest

`ios/Runner/PrivacyInfo.xcprivacy`, which Apple requires and which is
a declaration about an app that collects nothing:

- **`NSPrivacyTracking`: false**, **`NSPrivacyTrackingDomains`: empty.** No
  tracking, no ATT prompt, no identifier — §5.2, in every release.
- **`NSPrivacyCollectedDataTypes`: empty**, for 1.0. It stops being empty at
  2.0 when accounts arrive, and the diff at that point should be visible
  rather than buried.
- **`NSPrivacyAccessedAPITypes`** must declare the required-reason APIs the
  app actually reaches. **File timestamp** (`NSPrivacyAccessedAPICategoryFileTimestamp`)
  is reached through `dart:io` by the document store; declare it with reason
  code `C617.1` — accessing timestamps of files inside the app's own
  container. **Check the plugin manifests too**: `path_provider` ships its own
  privacy manifest, and Xcode merges them, so the app's file declares what the
  *app* does, not what its dependencies do.

Getting this wrong is an email from App Store Connect after upload, not a
build failure.

### 3. VoiceOver

Ticket 021 is the full accessibility audit and it covers both platforms; this
is the narrower question of whether the semantics that were written and tested
against TalkBack behave under VoiceOver. They are the same `Semantics` widgets
and they usually do. The two places to look hardest:

- **The board.** 64 cells, and criterion U-era requires every fact shown
  visually to be announced exactly once. VoiceOver's rotor and swipe order over
  a 4×4×4 grid is a different traversal from TalkBack's.
- **The carved heading signs**, which are a picture with the caption drawn on
  it. `SectionSign` supplies `Semantics(header: true, label: …)` and excludes
  the artwork underneath (ticket 039). Confirm a header is announced with its
  text and the image is silent.

### 4. The network claim, stated honestly

On Android, "computer play makes no network call" is guaranteed by the absence
of the INTERNET permission and checked by `check.sh`. **iOS has nothing to
withhold.** This ticket does not add a mechanism that does not exist; it
records that the claim on iOS is a review rather than an enforcement (S20,
D306), and does the review: confirm no dependency in `ios/Podfile.lock` opens
a socket, and that nothing was added to `pubspec.yaml` between here and 0.2.

## Acceptance criteria

1. Unlock records survive a real backup-and-restore onto a different device,
   with the method recorded.
2. `PrivacyInfo.xcprivacy` exists, declares no tracking and no collection, and
   declares every required-reason API the app itself reaches.
3. An upload to App Store Connect produces no privacy-manifest warning. (This
   can be checked once 048 exists; if this ticket lands first, note it as
   pending rather than claiming it.)
4. A whole game can be played from launch to result using VoiceOver only.
5. Every heading sign announces as a header with its caption, and its artwork
   announces nothing.
6. The iOS network claim is recorded at its real strength in the closure
   notes — reviewed, not enforced.
7. `bash tool/check.sh` passes.

## Notes

**VoiceOver on the simulator is not VoiceOver.** The simulator's accessibility
inspector shows the tree; it does not reproduce gesture navigation or
announcement order. This one needs the physical iPhone.
