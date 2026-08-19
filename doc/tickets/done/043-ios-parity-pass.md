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

## Closure

Two of the four parts are settled in the repository, one is settled as far as a
machine can settle it, and one needs a person with two phones. `bash
tool/check.sh`: **ALL CHECKS PASSED**, 341 app tests (was 339).

**Three of this ticket's four sections rested on a premise that turned out to be
wrong**, and in every case the conclusion survived and the reasoning did not.
That is the actual content of this ticket.

### 1. Unlock records survive a device change — mechanism confirmed, outcome not

The ticket says the guarantee holds because `Documents` is backed up and
`getApplicationDocumentsDirectory()` maps to it. **This app never calls that.**
`main.dart:30` calls `getApplicationSupportDirectory()`, chosen for Android's
allowlist (D131), and on iOS the store lands at
`<container>/Library/Application Support/quadrim/` — looked at in a real
container, not inferred.

That directory *is* backed up: iOS excludes only `Library/Caches`, `tmp`, and
files flagged `NSURLIsExcludedFromBackupKey`, and nothing here sets that flag.
So the guarantee holds by a different route than the ticket describes (D346).

**AC 1 is not met.** The mechanism is confirmed; the restore is not performed.
It needs a real backup and a second device, and no amount of reading settles it.

### 2. The privacy manifest — done

`ios/Runner/PrivacyInfo.xcprivacy` declares no tracking, no collection, and one
accessed-API entry: file timestamp, reason `C617.1`, for the `Directory.list()`
calls at `document_store.dart:64` and `:89`.

**The ticket's instruction to let `path_provider` declare its own was followed
and found empty.** `path_provider_foundation` 2.6.0 has no native code — it is a
`dartPluginClass` reaching Foundation through `objective_c` FFI — so it ships no
manifest and there is nothing to merge. The only other manifest in the built app
is `Flutter.framework`'s. The app's file therefore has to carry this entry
itself (D345).

Verified in the built product rather than on disk, because a manifest outside
Copy Bundle Resources ships nothing and says so nowhere:
`Runner.app/PrivacyInfo.xcprivacy` exists and reads back correctly.

### 3. VoiceOver — the half a test can hold, held

`SectionSign` already had `Semantics(header: true, label: text)` wrapping an
`ExcludeSemantics` (ticket 039), and the heading *labels* were already asserted
on real screens by `home_screen_test.dart` and `settings_test.dart`.

**The untested half was the artwork's silence**, which is the half AC 5 is
actually about. `test/sign_semantics_test.dart` now asserts a sign contributes
exactly one labelled node and no node claiming to be an image. It was
mutation-checked: removing `ExcludeSemantics` fails both tests, so it is not
vacuous.

**AC 4 is not met and AC 5 is met only structurally.** Gesture order,
announcement timing and rotor traversal over 64 cells cannot be tested this way,
and this ticket's own note says the simulator does not reproduce them.

### 4. The network claim, at its real strength

Reviewed and recorded as a **review, not an enforcement** (D347). Dependencies
are unchanged since 0.2; the one plugin with an iOS side resolves container
paths; the bundled frameworks are `App`, `Flutter` and `objective_c`, none of
them a networking library.

**The artefact this ticket names for the audit does not exist**: there is no
`ios/Podfile.lock`, because iOS resolves through Swift Package Manager (D325).
The generated SPM package was read instead — its only dependency is
`FlutterFramework`.

The engine packages cannot reach a network by construction and `check.sh`
enforces that on both platforms, which covers computer play. What is unenforced
on iOS is the app layer, and that is stated rather than papered over.

### Acceptance criteria

| AC | Status |
|----|--------|
| 1 — unlocks survive a real backup and restore | **Not met.** Mechanism confirmed (D346); the restore needs two devices and a person. |
| 2 — manifest exists, declares no tracking or collection, declares every reached API | **Met**, and verified in the built bundle. |
| 3 — an upload produces no privacy-manifest warning | **Pending**, as this ticket permits: it needs 048, which does not exist yet. Not claimed. |
| 4 — a whole game played launch-to-result under VoiceOver | **Not met.** Needs the physical phone and a person. |
| 5 — every heading announces as a header with its caption, artwork silent | **Met structurally**, by test, and mutation-checked. Not confirmed by ear under VoiceOver. |
| 6 — the network claim recorded at its real strength | **Met** (D347). |
| 7 — `bash tool/check.sh` passes | **Met.** |

### What is left, and who has to do it

Three criteria need a person holding a phone, and none of them is blocked on
code: **AC 1** (back up a device with unlocks earned, restore onto another,
check they are there), **AC 4** (turn on VoiceOver and play a game to a result),
and **AC 3** (wait for 048). They are listed here rather than quietly dropped.
