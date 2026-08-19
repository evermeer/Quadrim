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

---

# Code Review: ticket 046 → main@2465ec0

> Generated: 2026-08-19
> Base: 2465ec0
> Changed files: 11 (4 added, 7 modified)

## Summary

| Severity | Count |
|---|---|
| critical | 0 |
| major | 1 (fixed) |
| minor | 2 |
| nit | 0 |

## Findings

### [MAJOR — fixed] The restore action told paying players they owned nothing — `bug`

**File:** `app/lib/settings/settings_screen.dart` (as first written)

**Evidence:** The original `_restore` waited a flat second and then decided:

```dart
await widget.shop.restore();
await Future<void>.delayed(const Duration(seconds: 1));
...
final owns = after.unlockAll || after.unlimited;
messenger.showSnackBar(SnackBar(content: Text(owns ? l10n.settingsRestoreDone : ...)));
```

**Problem:** The store answers on the purchase stream, not by returning, so
there is nothing to await and one second is a guess. A store slower than that —
a poor connection, a cold StoreKit cache, the first call after a reinstall,
which is *exactly when restore is used* — produced "Nothing to restore on this
account." for a player who had paid. That reads as a lost purchase and is the
single most damaging thing this screen could say.

**Fix (applied):** Wait for the entitlement to actually change, with a generous
timeout instead of a fixed delay:

```dart
final settled = Completer<void>();
void onChange() { if (!settled.isCompleted) settled.complete(); }
entitlement.addListener(onChange);
await widget.shop.restore();
await settled.future.timeout(_restoreTimeout, onTimeout: () {});
entitlement.removeListener(onChange);
```

`_restoreTimeout` is 8 seconds. **Mutation-checked**: restoring the flat
one-second wait fails `settings_restore_test.dart`'s "a slow store is waited for
rather than reported as empty", which drives a fake store that answers after
three seconds.

---

### [MINOR] `Shop` is never disposed — `architecture`

**File:** `app/lib/main.dart:44`

**Evidence:** `Shop` is constructed in `main()` and owns a stream subscription
and four `ValueNotifier`s. `Shop.dispose()` exists and nothing calls it.

**Problem:** Nothing leaks in practice — the object lives exactly as long as the
process, which is the correct lifetime for the app's connection to the store,
and `QuadrimApp.dispose` would be the wrong place because the shop outlives the
widget. But an unused `dispose()` invites someone to conclude it is called.

**Fix:** None applied. Either delete `dispose()` or comment why it exists for
tests only. Left as-is because 047 attaches listeners to these notifiers and may
want the method; changing it now would be churn in the wrong ticket.

---

### [MINOR] Nothing reads `Entitlement` yet — `test-coverage`

**File:** `app/lib/shop/products.dart:31`

**Evidence:** `grep` for `entitlement` outside `app/lib/shop/` returns nothing.

**Problem:** The entitlement is computed, tested, and unconsumed. That is
correct for this ticket — 047 owns the paywall and the meter, and this one
"ends with products that can be bought and an entitlement the rest of the app
can ask about" — but it means the *integration* is unexercised: no screen has
yet had to cope with entitlement arriving after first frame (D351's stated
cost).

**Fix:** None. Recorded so 047 starts knowing the empty-then-populated sequence
is untested end to end.

## Checked and clean

- **The money-losing paths are tested and the tests are not vacuous.** Errored
  and cancelled purchases are still completed — an uncompleted purchase is
  redelivered by the store forever — and that assertion sits outside the status
  switch in the code for the same reason it is tested separately.
- **A refund cannot revoke an earned unlock.** `grantAllPurchased` skips
  opponents already unlocked, so a points-bought opponent keeps
  `UnlockSource.points` *and* its original `pricePaid`;
  `revokePurchasedUnlocks` filters on source. Both directions tested, including
  the price, which is what stops a re-tuned cost table bankrupting someone
  (§8.8).
- **D229 stays categorical.** `purchase()` is untouched and still throws for any
  opponent that is not the next locked one; the bulk grant is a separate method
  rather than a flag on the rule's own enforcer (D350).
- **Purity holds.** `in_app_purchase` is in `app/pubspec.yaml` alone; no package
  under `packages/` gained a dependency and `check.sh`'s scan passes.
- **The iOS build takes the plugin with no Podfile** — SPM resolves
  `in_app_purchase_storekit`, consistent with D325 — and the release build signs
  and installs on the device.
- **The plugin ships an empty `PrivacyInfo.xcprivacy`**, which confirms rather
  than contradicts D345: a plugin with a native bundle can carry a manifest and
  does. The app's manifest correctly needs no change — with no server of ours,
  nothing about a purchase is collected or transmitted.
- **`bash tool/check.sh`: ALL CHECKS PASSED**, 361 app tests (was 341).

## Functional Validation

| # | Requirement | Status | Evidence |
|---|---|---|---|
| AC-1 | Products in both consoles, subscription in a group with one base plan | ❌ | Only in `Quadrim.storekit`; the real products need the App Store Connect console |
| AC-2 | A sandbox purchase completes, entitlement readable | ❌ | Nothing has been bought anywhere |
| AC-3 | Reinstall restores both without re-paying | ⚠️ | `shop_test.dart` covers it against a fake; no store involved |
| AC-4 | Interrupted purchase completes on next launch | ⚠️ | Same — stream subscribed before any await (D351), completion tested |
| AC-5 | Lapsed subscription leaves unlocks intact | ⚠️ | Tested against the fake |
| AC-6 | Refunds revoke precisely | ⚠️ | Tested against the fake, both directions |
| AC-7 | Purchased unlocks carry `source` | ✅ | Written at `UnlockSource.purchase`, asserted |
| AC-8 | No package outside `app/` gains a dependency | ✅ | Purity scan passes |
| AC-9 | `check.sh` passes | ✅ | ALL CHECKS PASSED |

### Gaps

**Five of nine criteria are unverified against a real store**, and four of those
are "tested against a fake, which is not the same thing". The fake was written
from the plugin's documented contract, so it encodes what the plugin is
*believed* to do; the ways real StoreKit differs from that belief are precisely
what sandbox testing exists to find. The closure notes say this rather than
claiming the tests close the criteria.

**The ordering constraint in AC-1 is the one with a deadline.** The subscription
group cannot be retro-fitted around a product that already has subscribers
(D223), so the group must be right at creation — before anything ships, not
before anything is tested.

---

# Code Review: ticket 047 → main@82c92e2

> Generated: 2026-08-19
> Base: 82c92e2
> Changed files: 10 (3 added, 7 modified)

## Summary

| Severity | Count |
|---|---|
| critical | 0 |
| major | 0 |
| minor | 2 |
| nit | 0 |

## Findings

### [MINOR] The wall leaks for a frame or two after launch — `bug`

**File:** `app/lib/home/home_screen.dart` (`_meter`), `app/lib/data/meter_fold.dart:40`

**Evidence:**

```dart
freeMonth: _settingsDoc == null ? null : meter_fold.freeMonthFrom(_settingsDoc!),
```

and in `meter.dart`, a null `FreeMonth` means unmetered — `freeMonth == null || freeMonth.covers(now)`.

**Problem:** `_settingsDoc` is populated by a stream and is null until its first
event. During that window `canStart` is true regardless of how many games have
been started, so a player who taps New game fast enough gets one extra game.

**Fix:** None applied, and the behaviour is now recorded as deliberate (D353).
Failing towards letting the player play is the direction `meter_fold` was
already written for — a damaged settings document must not produce a wall
nobody can explain — and the loading window inherits it. Blocking while
settings are unknown would tell a player with briefly slow storage that they
had used games they had not, which is the failure D221 is about. The leak is
one or two frames, once, on a meter that is device-local anyway (S19).

---

### [MINOR] Nothing ties the daily cap to the first volume rung — `test-coverage`

**File:** `app/lib/home/quests_section.dart` (`unreachable`)

**Evidence:** The tile marks a volume quest unreachable whenever the cap
applies:

```dart
final unreachable = capped && status.quest.family == QuestFamily.gamesInDay;
```

`kDailyLimit` is 3 and `_volumeTargets.first` is 5. Nothing asserts 5 > 3.

**Problem:** The mark is true *because* five exceeds three. If a later release
raises the cap to five, or lowers the first rung to three, the tile tells a
player a reachable goal is out of reach and no test fails.

**Fix:** None applied — it would be a test about two constants in a package
this ticket did not touch. Recorded in D354 so whoever moves either number
knows the tile depends on their relationship.

## Checked and clean

- **Criterion 3 is a property of statement order and was checked as such.** In
  `_start` the resume loop returns before the wall, so a game in progress is
  never refused; `mode` excludes pass and play; the tutorial's practice game is
  never stored and so cannot reach the meter at all. Pass and play is tested
  against a fixture that is over *both* caps.
- **The daily/weekly distinction is tested with the only fixture that can tell
  them apart** — a Wednesday with nine games this week and none today, so the
  daily limit has room and only the weekly one refuses. A fixture over both
  caps would pass whichever message the code emitted.
- **The two guards are not redundant** (D352): deleting the early one changes
  no outcome, deleting the one in `_start` lets the challenge and rematch
  buttons through.
- **Prices come from the store already formatted.** No currency symbol is
  concatenated anywhere; `ProductDetails.price` is rendered as given, and the
  unavailable state is what shows when the query returned nothing — which is
  the state this build is actually in.
- **Every new key exists in both `.arb` files**, added in the same edit rather
  than English-first, and `check.sh` rejects any `Text('...')` with letters in
  `app/lib`.
- **The layout extremes are asserted by exception**, not by eye:
  `takeException()` must be null at 1080×1920 and 1290×2796, at text scale 1
  and 2. The shop screen's price-and-button row is a `Wrap` for that reason —
  at scale 2 on the narrow phone they do not fit side by side.
- **`bash tool/check.sh`: ALL CHECKS PASSED**, 372 app tests (was 366).

## Functional Validation

| # | Requirement | Status | Evidence |
|---|---|---|---|
| AC-1 | Daily cap refused, names the daily limit | ✅ | `paywall_test.dart` |
| AC-2 | Weekly cap uses the weekly message | ✅ | Wednesday fixture, daily room left |
| AC-3 | In-progress finishable; pass and play never refused | ✅ | Tested; order in `_start` |
| AC-4 | Purchase screen states the unlock does not lift the cap | ✅ | `shopUnlockAllCaveat`, bold, above the price |
| AC-5 | Restore reachable from settings and purchase screen | ✅ | Both |
| AC-6 | Volume tiles state the requirement and why | ✅ | Three tests, including the negative |
| AC-7 | No string outside l10n; English and Dutch | ✅ | Enforced by `check.sh` |
| AC-8 | Renders at the layout extremes | ✅ | Three configurations, exception asserted null |
| AC-9 | No copy claims a guarantee 1.0 lacks | ✅ | `shopMeterNote` |
| AC-10 | `check.sh` passes | ✅ | ALL CHECKS PASSED |

### Gaps

**Not an acceptance criterion, but in the ticket:** the end-of-game panel does
not show remaining games. Deferred explicitly in the closure with the reason —
`GameScreen` has no settings document and wiring one badly would put a wrong
number in front of a player who has just finished a game.

**Nothing here has met a real store.** The shop screen has only ever rendered
its unavailable branch, because 046's products do not exist while the bundle
identifier is held by a personal team. The purchase and owned states are
covered by `shop_test.dart` at the `Shop` level but have not been seen drawn.
