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
