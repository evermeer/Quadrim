# Code Review: main (ticket 041) → main@ae7a7a1

> Generated: 2026-08-17
> Merge base: ae7a7a1
> Changed files: 44 (40 new under `app/ios/`, plus `app/.metadata`, `doc/idea-v3-decisions.md`, and the ticket move)

---

## Summary

| Severity | Count |
|---|---|
| critical | 0 |
| major | 1 |
| minor | 2 |
| nit | 0 |

---

## Findings

### [MAJOR] Closure note states a causal claim that is false — `bug`

**File:** `doc/tickets/done/041-ios-project-and-first-run.md:AC-7 row`

**Evidence:**

```markdown
| 7 — a Dutch device runs the app in Dutch | **Met.** The Mac's locale is `nl-NL`, the simulator
inherits it, and the first screen came up in Dutch — "Uitleg", "Stap 2 van 12", "Vier lagen, één
kubus". This is what `CFBundleLocalizations` buys; without it the same simulator would have shown
English. |
```

**Problem:** The last sentence was never tested and is wrong. Rebuilding with
`CFBundleLocalizations` removed (`plutil -remove`) and reinstalling on a clean
simulator still produced a fully Dutch app — "Voor het eerst hier?", "Tegen de
computer", "Nog geen partijen." The Flutter engine reads the system-wide
`NSLocale.preferredLanguages`, not `Bundle.preferredLocalizations`, so it is not
filtered by the bundle's declared localisations at all. The key does real work —
it is what puts Quadrim in the per-app language picker in iOS Settings and what
App Store Connect reads for the listing's languages — but it is not what made
this screen Dutch, and the ticket's own rationale ("Without this iOS reports only
English to the system, and a Dutch device runs the app in English") does not hold
for a Flutter app.

This matters beyond tidiness: the claim as written would let someone conclude that
declaring a language is sufficient to ship it, when the actual gate is
`flutter gen-l10n` and the `supportedLocales` list on the Dart side.

**Fix:** Correct the row to state what was observed and what the key is actually
for, and record the disproof as a decision — the ticket's stated reason for the
key is wrong, which is exactly the kind of thing `idea-v3-decisions.md` exists to
capture.

---

### [MINOR] `CFBundleName` is lowercase `quadrim`, everywhere else the app is `Quadrim` — `style`

**File:** `app/ios/Runner/Info.plist:22`

**Evidence:**

```xml
	<key>CFBundleName</key>
	<string>quadrim</string>
```

Against Android, which was set deliberately:

```xml
<!-- app/android/app/src/main/AndroidManifest.xml:3 -->
android:label="Quadrim"
```

**Problem:** `flutter create` derives `CFBundleName` from the pubspec's `name:`
field, which is lowercase by Dart package convention. iOS prefers
`CFBundleDisplayName` ("Quadrim") in most user-visible places, so this is mostly
hidden — but not always: `CFBundleName` is the fallback where the display name
does not fit, and it is what several system surfaces read. The ticket set the
display name and did not look at its neighbour.

**Fix:**

```xml
	<key>CFBundleName</key>
	<string>Quadrim</string>
```

Well under the 15-character limit the key imposes.

---

### [MINOR] An unrelated `README.md` edit is sitting in the working tree — `style`

**File:** `README.md:398`

**Evidence:**

```diff
-2 small bug fixes for point count and quest calculation.
+2 small bug fixes for point count and quest calculation. Also made some minor UI tweaks
```

**Problem:** This change predates ticket 041 — it was already modified when the
session opened, and it belongs to the previous ticket's work. `CLAUDE.md` is
explicit that the unit of work and of commits is one ticket. Staging it with the
iOS folder would put an unrelated sentence in a commit titled `Ticket 041`.

**Fix:** Leave it unstaged and commit it separately, or fold it into whatever
ticket produced the UI tweaks it describes. Do not include it in the 041 commit.

---

## Checked and clean

Recorded so the next reviewer does not repeat the work:

- **Bundle identifier** is `nl.evict.quadrim` in all three Runner configurations
  (`project.pbxproj:385, 564, 586`) and extracts as such from the *built*
  `Runner.app/Info.plist`. This is D213's permanent value.
- **`ios/.gitignore` survived** `flutter create` and covers `**/Pods/`,
  `**/.symlinks/`, `Flutter/ephemeral/` and `Flutter/Generated.xcconfig`
  (`app/ios/.gitignore:13,14,22,21`). Nothing generated is staged — the 40 files
  added are all template sources.
- **Portrait lock is in the compiled binary**, both `UISupportedInterfaceOrientations`
  and `UISupportedInterfaceOrientations~ipad`, each reduced to
  `["UIInterfaceOrientationPortrait"]`. The `~ipad` key was not named by the
  ticket and needed doing: `TARGETED_DEVICE_FAMILY = "1,2"` (`project.pbxproj:367`),
  so an iPad would otherwise have rotated a portrait-only app.
- **`app/.metadata` was correctly repaired.** `flutter create` replaced the
  `android` platform entry with `ios` rather than appending, and stamped
  `channel: "[user-branch]"` from the tag clone. Both restored; the file now
  lists both platforms on `stable`.
- **The template's `test/widget_test.dart` was deleted, not adapted.** It imports
  a `MyApp` symbol that does not exist in `lib/main.dart`; keeping it would have
  broken `flutter test` on the next run.
- **`ENABLE_USER_SCRIPT_SANDBOXING = NO`** (`project.pbxproj:354, 474, 531`) is
  Flutter's own requirement — its build phase writes into the derived data tree —
  and is not a finding.
- **`bash tool/check.sh`: ALL CHECKS PASSED** with `ios/` present, 339 app tests
  and 121 engine tests. `flutter analyze`: no issues, before and after.

---

## Functional Validation

**Jira issue:** none — this repository tracks work in `doc/tickets/`, not Jira.
No `.jira.json` exists and no `[A-Z]+-[0-9]+` key appears in the branch name or
commit range. Validated against the ticket's own acceptance criteria instead.

### Acceptance Criteria Coverage

| # | Requirement | Status | Evidence |
|---|---|---|---|
| AC-1 | `flutter --version` reports 3.44.9 / Dart 3.12.2 | ✅ | `Flutter 3.44.9 • Tools • Dart 3.12.2` |
| AC-2 | `flutter test && flutter analyze` pass before and after `flutter create` | ✅ | 339 tests passed both times; "No issues found!" both times |
| AC-3 | `app/ios/` exists, bundle id `nl.evict.quadrim` in every configuration | ✅ | `project.pbxproj:385,564,586` and built `Info.plist` |
| AC-4 | Launches on the simulator | ✅ | Installed and launched on iPhone 17 Pro / iOS 26.5, screenshot captured |
| AC-4 | Launches on a physical iPhone | ❌ | Needs an Apple ID in Xcode; out of reach this run |
| AC-5 | A full game played to a win on the device | ❌ | Same cause; tap injection on the simulator also blocked by `xcode-select` |
| AC-6 | Portrait-locked, does not rotate | ⚠️ | Declaration verified in the compiled binary; not observed by rotating a device |
| AC-7 | A Dutch device runs the app in Dutch | ✅ | Observed on an `nl-NL` simulator — though see the MAJOR finding on *why* |
| AC-8 | `bash tool/check.sh` still passes | ✅ | ALL CHECKS PASSED |
| AC-9 | Deployment target and `flutter doctor` recorded in closure notes | ✅ | iOS 13.0 and the six doctor lines are in `## Closure` |

### Gaps

- **AC-4 (device) and AC-5** are blocked on signing, not on code. The closure
  notes list them as pending rather than ticking them, which is the correct
  handling.
- **AC-6** is met at the only place the lock actually lives — the `Info.plist`
  declaration, confirmed in the built bundle rather than the source. Watching a
  device fail to rotate would add confidence, not correctness.
- **The `xcode-select` blocker is environmental**, not a defect in this ticket:
  `/var/db/xcode_select_link` does not exist on this Mac, so
  `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer` has
  never been run. It needs a password.

---

# Code Review: ticket 042 → main@36c6bb0

> Generated: 2026-08-18
> Base: 36c6bb0 (ticket 041)
> Changed files: 8 tracked + 3 added, 15 deleted

## Summary

| Severity | Count |
|---|---|
| critical | 0 |
| major | 0 |
| minor | 2 |
| nit | 0 |

## Findings

### [MINOR] The scrim is defined twice and nothing checks the two agree — `architecture`

**File:** `tools/artgen/artgen.py:65` and `app/lib/design/forest.dart:47`

**Evidence:**

```python
# tools/artgen/artgen.py:65
SCRIM_RGB = (11, 22, 14)
SCRIM_ALPHA = 0x9E / 255.0
```

```dart
// app/lib/design/forest.dart:47
colorFilter: ColorFilter.mode(Color(0x9E0B160E), BlendMode.srcOver),
```

`grep` over `tool/check.sh` and `app/test/` finds no reference to either.

**Problem:** D331 makes the launch screen correct precisely by matching D296's
scrim. That match is now a coincidence maintained by hand across a Dart file and
a Python file. Change `0x9E0B160E` — which D296 says was *measured*, so it can
move if the artwork or the contrast target does — and the launch screen keeps the
old darkening. The symptom is a brightness step at launch on a real phone, the
exact defect this ticket just fixed, and nothing in the gate would fail.

**Fix:** Not a refactor — a check. The cheapest honest one is an assertion in
`artgen.py` that reads the literal out of `forest.dart` and fails the run if it
does not match, in the spirit of the existing dictionary SHA-256 check:

```python
src = (ROOT / "app/lib/design/forest.dart").read_text(encoding="utf-8")
if f"0x{int(SCRIM_ALPHA*255):02X}{SCRIM_RGB[0]:02X}{SCRIM_RGB[1]:02X}{SCRIM_RGB[2]:02X}" not in src:
    raise SystemExit("scrim in artgen.py no longer matches forest.dart (D331)")
```

Deferred rather than applied: it is a new cross-language coupling and belongs in
a ticket that can weigh it, not in a commit about an icon. Recorded here so the
next person to touch D296 finds it.

### [MINOR] `DEVELOPMENT_TEAM` is committed into the project file — `style`

**File:** `app/ios/Runner.xcodeproj/project.pbxproj:379, 559, 582`

**Evidence:**

```
+				DEVELOPMENT_TEAM = WTH4QGEA23;
```

**Problem:** An Apple Team ID is not a credential — it appears in every
provisioning profile and in public App Store metadata — so this is not a leak.
But it hardcodes one developer's account into a repository whose remote is a
personal GitHub project, and any second machine or contributor building for a
device now has to edit a tracked file to do it.

**Fix:** Acceptable as-is for a single-developer project, and it is what Xcode
writes by default. If the project ever gains a second signer, move it to an
untracked `ios/Flutter/Signing.xcconfig` and leave the build setting referencing
it. No change made now.

## Checked and clean

- **`ios_app_icon` deletes before it writes.** `out.glob("Icon-App-*.png")` is
  unlinked first, so the fifteen template icons cannot survive as unnamed files
  in the catalogue (D329). The same pattern guards `LaunchImage*.png`, which
  matters more there — the format changed from PNG to JPEG, so the old files
  would otherwise have been orphaned rather than overwritten.
- **The generated icon is genuinely opaque.** `sips -g hasAlpha` reports `no` on
  artgen's 1024, and on both icons Xcode *derived* into the archive. Pasting the
  mark through its own alpha onto an `Image.new("RGB", ...)` is what flattens it;
  there is no `convert("RGB")` at the end doing it by accident.
- **The 32 re-encoded art files were verified pixel-identical before being
  reverted**, not assumed. Max channel difference 0 across all 32, which is what
  D290 describes and what this ticket's own note instructs.
- **The archive validates.** `flutter build ipa --no-codesign` completed with no
  asset-validation warning, and the release build then signed and installed on a
  physical device.
- **No user-facing string entered the storyboard**, so §11.6's rule is not
  circumvented by a surface it cannot see.

---

# Code Review: ticket 043 → main@d488516

> Generated: 2026-08-19
> Base: d488516
> Changed files: 6 (1 added test, 1 added manifest, pbxproj, 2 amended tickets, decisions)

## Summary

| Severity | Count |
|---|---|
| critical | 0 |
| major | 0 |
| minor | 1 |
| nit | 0 |

## Findings

### [MINOR] The `xcodeproj` gem made an incidental change beyond the one asked for — `style`

**File:** `app/ios/Runner.xcodeproj/project.pbxproj:9, 121`

**Evidence:** The intended change was four lines adding `PrivacyInfo.xcprivacy`.
The gem also rewrote a Swift Package Manager reference's display comment:

```diff
-		781AD8BC2B33823900A9FFBB /* XCLocalSwiftPackageReference "Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage" */ = {
+		781AD8BC2B33823900A9FFBB /* XCLocalSwiftPackageReference "FlutterGeneratedPluginSwiftPackage" */ = {
```

**Problem:** Editing `project.pbxproj` with a tool means accepting whatever else
that tool normalises. Here it is cosmetic — pbxproj `/* … */` comments are
decorative, Xcode regenerates them, and the reference body is untouched:

```
			isa = XCLocalSwiftPackageReference;
			relativePath = Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage;
```

The UUID and the `relativePath` both survive, and a signed release build
succeeded after the edit and produced a working app, so nothing is broken. But
the diff is larger than the change, and the next person reading it has to work
out that two of the six lines are noise.

**Fix:** None applied. Hand-editing pbxproj to avoid this is the worse trade —
it is a format with cross-referenced UUIDs in four sections, and getting one
wrong produces a project that opens and silently omits a file. The tool is the
right instrument; this is its documented cost.

## Checked and clean

- **The manifest is in the Runner target's resources, not merely on disk.** Four
  references in `project.pbxproj` — one `PBXBuildFile`, one `PBXFileReference`,
  one group entry, one entry in the Resources build phase — which is the exact
  set required, with none leaking into `RunnerTests`. Confirmed the only way
  that counts: `Runner.app/PrivacyInfo.xcprivacy` exists in the signed release
  bundle and reads back with all four keys. **This is the failure mode the
  ticket does not mention** — an `.xcprivacy` outside Copy Bundle Resources
  ships nothing and reports nothing.
- **The declared API is traced to a line, not guessed.** `C617.1` covers
  `Directory.list()` at `document_store.dart:64` and `:89`. No other
  required-reason category is reached: no `shared_preferences` so no
  `UserDefaults`, no disk-space query, and the only plugin with an iOS side
  resolves container paths.
- **`path_provider_foundation` genuinely ships no manifest**, checked in the
  package (no native sources, `dartPluginClass` only) and in the built app (the
  sole other `.xcprivacy` is `Flutter.framework`'s). The ticket's instruction to
  rely on the plugin's own manifest was followed and found empty, not skipped.
- **The new test is not vacuous.** `sign_semantics_test.dart` was
  mutation-checked: removing `ExcludeSemantics` from `SectionSign` fails both
  assertions, and restoring it passes them. A semantics test that survives its
  own guard being deleted is the usual way this kind of coverage goes wrong.
- **The storage path was read out of a real container**, not inferred from the
  Android-oriented comment at `main.dart:31`:
  `<container>/Library/Application Support/quadrim/{games,unlocks,settings.json}`.
- **`bash tool/check.sh`: ALL CHECKS PASSED**, 341 app tests (up 2).

## Functional Validation

Validated against the ticket's own acceptance criteria; this repo has no Jira.

| # | Requirement | Status | Evidence |
|---|---|---|---|
| AC-1 | Unlocks survive a real backup and restore | ❌ | Mechanism confirmed (D346); the restore itself needs two devices and a person |
| AC-2 | Manifest declares no tracking, no collection, every reached API | ✅ | `Runner.app/PrivacyInfo.xcprivacy`, verified in the signed bundle |
| AC-3 | An upload produces no privacy-manifest warning | ⚠️ | Pending 048, which the ticket explicitly permits; noted, not claimed |
| AC-4 | A whole game played under VoiceOver | ❌ | Needs the phone; the ticket says the simulator cannot stand in |
| AC-5 | Headings announce as headers, artwork silent | ⚠️ | Met structurally by test and mutation-checked; not confirmed by ear |
| AC-6 | Network claim recorded at its real strength | ✅ | D347 — reviewed, not enforced, with the asymmetry stated |
| AC-7 | `bash tool/check.sh` passes | ✅ | ALL CHECKS PASSED |

### Gaps

Three criteria need a person holding a phone and none is blocked on code: AC-1,
AC-4, and AC-3 (which waits on ticket 048). The closure notes list them as open
rather than ticking them, which is the correct handling — and matches how 041
handled the same situation.

**One risk worth carrying forward.** D346 records that the iOS backup guarantee
and the Android allowlist agree only because one storage path was chosen once,
for an Android reason (D131). Nothing checks that they still agree. A future
change of storage directory made for one platform would move the other
platform's guarantee silently, and `art_assets_test.dart`-style coverage does
not exist for this.
