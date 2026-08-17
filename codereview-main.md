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
