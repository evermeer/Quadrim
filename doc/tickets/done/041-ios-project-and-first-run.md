# Ticket 041 — The iOS project exists and runs

**Depends on:** nothing in the repo. **Blocked on** Apple Developer enrolment
only for the signing steps at the end; everything up to and including the
simulator run works without an account.

**Status:** ready-for-agent, on a Mac

## Why

`app/` has an `android/` directory and no `ios/` one. The iOS platform folder
has never been created, so there is nothing to open in Xcode and nothing to
run. This ticket is the whole of "Quadrim launches on an iPhone" and nothing
else — no purchases, no new screens, no behaviour changes.

**This ticket is written to be picked up on a machine that has never seen this
project**, because it will be. It assumes an Apple Silicon Mac with nothing
installed, and a physical iPhone available.

## What it does

### 1. The machine

Run in order. Each step is checkable before the next.

1. **Xcode** from the Mac App Store. It is ~10 GB and the App Store download
   is the reliable path; the developer-portal `.xip` is faster to start and
   slower to finish.
2. **Command-line tools and licence:**
   ```
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -runFirstLaunch
   sudo xcodebuild -license accept
   ```
3. **Rosetta**, which some of the Flutter and CocoaPods toolchain still wants
   on Apple Silicon:
   ```
   sudo softwareupdate --install-rosetta --agree-to-license
   ```
4. **Homebrew**, then **CocoaPods through Homebrew**:
   ```
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   brew install cocoapods
   ```
   Use Homebrew rather than `sudo gem install cocoapods`. The system Ruby on
   recent macOS is not writable in the way the gem install expects, and the
   failure it produces names permissions rather than the actual problem.
5. **Flutter 3.44.9** — the version this repo is built against, and the
   version `tool/check.sh` expects. Match it exactly rather than taking
   whatever `brew install flutter` offers:
   ```
   git clone https://github.com/flutter/flutter.git -b 3.44.9 ~/flutter
   export PATH="$HOME/flutter/bin:$PATH"   # add to ~/.zshrc
   flutter --version                        # must print 3.44.9 / Dart 3.12.2
   ```
6. **Clone the repo** and confirm the existing suite passes *before* touching
   anything iOS. If it does not, the problem is the machine, and finding that
   out now costs minutes instead of a day:
   ```
   cd app && flutter pub get && flutter test && flutter analyze
   cd ../packages/quadrim_engine && dart test
   ```
7. `flutter doctor -v`. Everything except the Android toolchain must be green.
   **Android being red on this machine is fine and expected** — that half of
   the build lives on the Windows machine.

### 2. The iOS project

```
cd app && flutter create --platforms=ios --org nl.evict .
```

This adds `app/ios/` and touches nothing else. Then, before anything else:

- **Verify the bundle identifier is `nl.evict.quadrim`** in
  `ios/Runner.xcodeproj` — `PRODUCT_BUNDLE_IDENTIFIER` in all three build
  configurations. `flutter create` derives it from `--org` plus the project
  name and gets it right, but this is the one value in the project that can
  never be changed after the first upload to App Store Connect (D213), so it
  is checked rather than assumed.
- **Set the display name** to Quadrim in `ios/Runner/Info.plist`
  (`CFBundleDisplayName`), which `flutter create` leaves as the project name.
- **Lock to portrait.** `UISupportedInterfaceOrientations` keeps only
  `UIInterfaceOrientationPortrait`. Android's lock was ticket 035's work; iOS
  has its own and the app is portrait-only by §8.1.
- **Declare the supported languages.** `CFBundleLocalizations` gets `en` and
  `nl`, and `CFBundleDevelopmentRegion` gets `en`. Without this iOS reports
  only English to the system, and a Dutch device runs the app in English no
  matter what `flutter gen-l10n` produced.
- **Record the deployment target** that Flutter 3.44.9 defaults to, in the
  ticket's closure notes. Do not raise or lower it; just write down what it
  is, because §12 of idea-v3.md has no minimum-iOS decision in it and one is
  about to exist by default.

### 3. Run it

- On the **simulator** — proves the build.
- On the **physical iPhone** — proves signing, and is the only thing that
  proves the fonts, the artwork and the layout on a real screen with a real
  notch. Needs an Apple ID in Xcode; a free personal team is enough for a
  7-day build, so this step does **not** wait for the paid enrolment.

Play a game through to a win. The board is 64 cells on a phone screen and this
is the first time it has been drawn by iOS's text and image stack rather than
Android's.

## Acceptance criteria

1. `flutter --version` on the Mac reports **3.44.9 / Dart 3.12.2**.
2. `cd app && flutter test && flutter analyze` passes on the Mac, before and
   after `flutter create`.
3. `app/ios/` exists, and the bundle identifier is `nl.evict.quadrim` in every
   build configuration.
4. The app launches on the simulator and on a physical iPhone.
5. A full game can be played to a win on the physical device.
6. The app is portrait-locked and does not rotate.
7. A device set to Dutch runs the app in Dutch.
8. `bash tool/check.sh` still passes — creating an iOS folder must not break
   the Android gate.
9. The deployment target and the `flutter doctor` output are recorded in the
   closure notes.

## Notes for whoever picks this up

**`tool/check.sh` is the gate and it is a bash script.** It runs on macOS
as-is. The `JAVA_TOOL_OPTIONS` workaround in `CLAUDE.md` is a Windows-machine
condition and is irrelevant here — do not copy it into anything.

**Do not commit `ios/Pods/` or `ios/.symlinks/`.** `flutter create` writes a
`.gitignore` in `ios/` that handles this; check it survived before the first
commit. `ios/Podfile.lock` **is** committed, like `pubspec.lock`.

**Do not "fix" anything else while you are in here.** This ticket is a
platform folder and a green run. Every temptation you meet — an icon that is
Flutter's default, a launch screen that is white, a purchase that does not
exist — is a later ticket in this same folder.

## Closure

`app/ios/` exists and the app runs. `bash tool/check.sh`: **ALL CHECKS PASSED**,
339 app tests, 121 engine tests, unchanged by this ticket — nothing in it
touches Dart.

**The Mac, as required by AC 1 and 9.** Flutter 3.44.9 / Dart 3.12.2, cloned to
`~/flutter` at the tag rather than installed by Homebrew, because Homebrew ships
whatever is current. `flutter doctor`:

```
[!] Flutter (Channel [user-branch], 3.44.9, on macOS 26.6.1 25G76 darwin-arm64, locale nl-NL)
[✗] Android toolchain - develop for Android devices
[✓] Xcode - develop for iOS and macOS (Xcode 26.6)
[✗] Chrome - develop for the web
[✓] Connected device (3 available)
[✓] Network resources
```

Android red is the expected split — that half of the build lives on the Windows
machine. The Flutter warning is the tag clone, not a fault. Chrome is not
installed and this app has no web target.

**The deployment target is iOS 13.0** in all three build configurations, taken
as Flutter's default and left there (D324). `MinimumOSVersion` in the built
`Info.plist` reads `13.0`.

**The bundle identifier is `nl.evict.quadrim`** in all three Runner
configurations, matching Android's `applicationId`. Verified in the built
binary, not only in `project.pbxproj` — `CFBundleIdentifier` extracts as
`nl.evict.quadrim` from `Runner.app/Info.plist`. This is D213's permanent value
and it is right.

**Info.plist**: display name `Quadrim`; `UISupportedInterfaceOrientations` and
its `~ipad` variant both reduced to portrait alone; `CFBundleLocalizations`
`[en, nl]`; `CFBundleDevelopmentRegion` `en`. All four verified by extracting
them from the compiled `Runner.app/Info.plist` rather than by reading the
source. The `~ipad` key goes beyond the ticket's wording: `TARGETED_DEVICE_FAMILY`
is `1,2`, so leaving it at four orientations would have let an iPad rotate an
app that §8.1 says is portrait-only.

**Three decisions the ticket did not anticipate.** There is no Podfile at all —
Flutter 3.44.9 resolves `path_provider_foundation` through Swift Package
Manager, so the ticket's "commit `Podfile.lock`" is dormant rather than wrong
(D325). CocoaPods had to be installed under bundler, because the system Ruby is
2.6 and `gem install cocoapods` fails one dependency at a time without ever
terminating (D326). And `flutter create` touched three things outside `ios/`,
two of which had to be put back — including an `.metadata` that silently
*replaced* the Android platform entry with the iOS one (D327).

### Criteria, and what settled them

Amended after the fact: this ticket closed with the device criteria pending,
because there was no Apple ID on the Mac. There is one now — a paid developer
account, team `WTH4QGEA23` — so a signed release build was installed on a
physical iPhone 17 Pro running iOS 27.0 and launched there. The rows below say
what is actually true, not what was true on the day.

| AC | Status |
|----|--------|
| 4 — launches on the simulator | **Met.** Built, installed and launched on iPhone 17 Pro / iOS 26.5; screenshot taken of the running app. |
| 4 — launches on a physical iPhone | **Met.** `flutter build ios --release` signed with team `WTH4QGEA23`, installed to device `00008150-000A4D281ADA401C`, and launched — `devicectl` reports the process alive. It is a *release* build, so it runs with no debugger attached and no cable; a debug build could not have proved this, because a Flutter debug build needs the JIT and will not start on its own. |
| 5 — a full game played to a win on the device | **Still open, and it needs a person.** The app launches and the first screen draws, but nobody has played sixty-four cells to a win on the phone. There is no tap-injection path to a physical device from this Mac, and the simulator's needs `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer` — never run here (`/var/db/xcode_select_link` does not exist) — which takes a password. This is the one criterion in the ticket that no amount of tooling closes: it is a human playing a game and saying it felt right. |
| 6 — portrait-locked and does not rotate | **Met at the declaration**, which is where the lock lives: portrait alone in the built `Info.plist`, both keys. Not observed by rotating a device. |
| 7 — a Dutch device runs the app in Dutch | **Met on the simulator.** The Mac's locale is `nl-NL`, the simulator inherits it, and the app came up in Dutch — "Voor het eerst hier?", "Tegen de computer", "Nieuwe partij". Not, however, *because* of `CFBundleLocalizations`, which the review disproved by experiment (D328). |

The fonts and the artwork are right on the first thing iOS drew: Cinzel small
caps in the headings, EB Garamond in the body, the forest photograph behind a
cream panel, and the four layer diagrams with their stones. That was the risk in
this ticket — 64 cells drawn by a text and image stack that had never drawn them
— and it is not a risk any more.
