# Ticket 042 — The iOS icon and launch screen

**Depends on:** 041 (the iOS project exists)

**Status:** ready-for-agent, on a Mac

## Why

`flutter create` leaves the Flutter logo as the app icon and a white
`LaunchScreen.storyboard` behind it. Both ship unless something replaces them,
and the first thing anyone sees of Quadrim on iOS would be someone else's
logo.

The mark already exists. `tools/artgen/artgen.py` builds the Android launcher
icon from `logo.png` in `doc/designs/` (D290), and this ticket extends the same
generator rather than exporting anything by hand — the point of artgen is that
the assets can be rebuilt from source art, and a hand-made iOS icon breaks that
the day the logo changes.

## What it does

1. **`artgen.py` gains an `ios_app_icon(mark)` function** beside
   `launcher_icon(mark)`, writing into
   `app/ios/Runner/Assets.xcassets/AppIcon.appiconset/`.

   iOS differs from Android in three ways that matter here:

   - **No transparency.** An icon with an alpha channel is rejected at upload
     with an error that names the asset and not the reason. Composite the mark
     onto `ICON_BACKGROUND` — the same colour the Android legacy icon uses —
     and save RGB, not RGBA.
   - **No safe-area crop.** Android's adaptive icon eats the outer third, which
     is why `launcher_icon` insets the mark to 62%. iOS shows the whole square
     and rounds the corners itself, so the mark uses the 70% inset the Android
     *legacy* icon uses, not the adaptive one.
   - **Since Xcode 14 a single 1024×1024 is enough**, and Xcode derives the
     rest. Emit that one, plus the `Contents.json` that declares it. Emitting
     the full historical ladder of sizes is allowed and is more files to keep
     correct for no visible gain.

2. **The launch screen becomes the forest.** `LaunchScreen.storyboard` shows
   `background.png` scaled to fill, with nothing on top of it. No text —
   a launch screen is not localisable and §11.6's rule against strings outside
   l10n would have nothing to say about a storyboard, which is exactly how a
   hardcoded English word gets shipped.

   The asset goes in `Assets.xcassets` as an image set, not into
   `app/assets/`; the launch screen is drawn by iOS before Flutter exists and
   cannot read a Flutter asset.

3. **`art_assets_test.dart` gains nothing.** It tests what the Flutter app
   loads, and neither of these is loaded by Flutter. What checks this ticket is
   looking at a phone.

## Acceptance criteria

1. `python tools/artgen/artgen.py` regenerates both, and its output is
   committed, as with every other artgen product (D290).
2. The icon has **no alpha channel**, verified on the file rather than assumed
   — `sips -g hasAlpha <file>` reports `no`.
3. The home screen shows the Quadrim mark, at every icon size iOS renders:
   home screen, Settings, Spotlight, and the App Switcher.
4. The launch screen shows the forest, and the transition into the app has no
   white flash.
5. `bash tool/check.sh` passes.
6. An archive build (`flutter build ipa`) completes without an asset-validation
   warning. **This is the check that matters** — icon problems are an upload
   error, not a build error, and finding them at upload wastes the round trip.

## Notes

**Run artgen on the Mac or on Windows, either is fine.** It writes into
`app/ios/`, so if it runs on Windows the output is committed there and pulled
on the Mac. `check.sh` deliberately does **not** verify artgen's output is
fresh, because the same picture re-encoded by a different Pillow build is
different bytes (D290) — so if this runs on both machines, expect noise in the
diff and commit only what actually changed.
