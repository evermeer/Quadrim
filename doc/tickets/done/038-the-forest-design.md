# Ticket 038 — The forest design

**Depends on:** 037 (Your Path scrolls, opponent detail page)
**Blocks:** nothing. 021's accessibility audit inherits it.

## Why

Release 0.1 is functionally complete and looks like a wireframe. `doc/designs/`
now holds a main-screen mockup (`Design-alt0.png`), a background, twenty
opponent portraits, a cube, a logo, and three carved wooden plaques. This ticket
turns the app into that picture.

**The mockup is an indication, not a specification, and the current
functionality is what leads.** Where the two disagree, the app wins:

| In the mockup, not in the app | Decision |
| --- | --- |
| "Today's journey" panel | Not built. There is no such feature. |
| Rank names (WANDERER, PATHFINDER) and a progress bar to the next rank | Not built. There are no ranks; there is an Elo rating and an unlock ladder. |
| "Best: 1287" | Not built. Nothing stores a peak. |
| Bottom navigation (HOME / PLAY / OPPONENTS / LEADERS / PROFILE) | Not built. Four of the five screens do not exist. |
| Daily quests with a countdown and CLAIM REWARDS | Not built. The quests are milestones, not dailies, and they pay automatically. |
| A profile button, a "+" on the points chip | Not built. |

| In the app, not in the mockup | Decision |
| --- | --- |
| The trend graph | Kept, inside the rating panel. |
| Points balance and streak | Kept, inside the rating panel. |
| Pass-and-play games in the lists | Kept. |

## What it does

1. **An asset pipeline** — `tools/artgen/artgen.py` turns `doc/designs/`'s 65 MB
   of source PNGs into 2.2 MB of shipped WebP and subset fonts, plus the Android
   launcher icons. Run by hand; its output is committed (D290).
2. **One theme.** The seeded Nocturne dark/light pair is replaced by a single
   painted design. `QuadrimPalette` holds the colours read off the mockup;
   `MaterialApp` gets the same `ThemeData` for both brightnesses, and the
   settings screen loses a theme picker that would now select the same screen
   three ways (D293).
3. **Fonts.** Cinzel for display, EB Garamond for body — both SIL OFL, instanced
   to the weights used and subset to Latin, with their licences bundled.
4. **The forest on every screen.** `ForestScaffold` paints the background behind
   a transparent scaffold. The main screen is cards on the forest; the secondary
   screens put one `ParchmentSheet` under everything, because ink over a
   photograph of leaves is unreadable at any size.
5. **Real portraits.** The drawn identicon of ticket 029 is deleted — it existed
   to be replaced and said so. `OpponentArt` draws the shipped portrait, and a
   locked opponent is a silhouette produced by a colour filter over the same
   file rather than a second set of files (D291).
6. **The carved plaques.** New Game and Tutorial become `Plaque` buttons; Your
   Path gets its sign as a section banner. Their lettering is baked into the
   artwork in English; the accessible name still comes from l10n, so a Dutch
   screen reader says "Nieuwe partij" over a plank that reads NEW GAME (D292).
7. **The logo** in the app bar and as the Android adaptive launcher icon.
8. **The board keeps its geometry** and gains only the palette and the
   background. It is the one screen where a mis-tap costs a game.

## Acceptance criteria

1. `bash tool/check.sh` passes.
2. Every screen sits on the forest background; none shows a white or purple
   surface.
3. All twenty opponents draw their own portrait, and a locked one draws as a
   silhouette. `art_assets_test.dart` proves every catalogue id resolves to real
   bytes.
4. The shipped art and fonts together stay under 3 MB, asserted by a test.
5. The New Game and Tutorial plaques are buttons with an accessible name in the
   player's language, and both still work in Dutch.
6. Your Path's carved sign is still a semantic heading, in both languages.
7. The main screen survives a 200% font scale on the smallest supported phone
   with every section reachable — the cube stands down at large scales rather
   than pushing the rating panel past the height of the screen.
8. No user-facing string leaves l10n; both locales stay complete.
9. The Android launcher icon is the new logo, adaptive, with a monochrome layer.

## Notes

- `doc/designs/` stays in the repository as the source of truth for the art. It
  is large, and it is what makes the pipeline re-runnable.
- The lettering baked into three plaques is a known ceiling, recorded as D292
  and owned by a later art pass, not by this ticket.

---

## Closure

Committed on `main`. `bash tool/check.sh`: **ALL CHECKS PASSED**, 322 app tests.
Review in `codereview-main.md` — five findings, all applied — plus a follow-up
section for three more found on the device after it.

Verified on the emulator (Android 16, 1080x2400): main screen, opponent list,
game board. The art and fonts weigh 2.22 MB against a 3 MB ceiling asserted by
`art_assets_test.dart`.

**What the ticket cost that the plan did not predict:** six bugs, five of them
one of two shapes. Three were images sized by their own undecoded bytes (D295)
and three were text carrying the ink colour of a theme meant for parchment
(D296). Neither shape is visible in a diff and neither fails a widget test; the
first three were found because a test could not tap a zero-height button, and
the second three because somebody looked at a screenshot.

**Known ceilings, both recorded rather than fixed here:**

- Three plaques carry English lettering in every locale (D292). Owned by a later
  art pass.
- Your Path's tiles are all as tall as the tallest, so a row of unlocked
  opponents carries empty space under each name. That is `IntrinsicHeight`
  doing what it was asked in ticket 037, and it is more visible now that the
  portraits are photographs. Not a defect; a layout choice worth revisiting if
  it grates.
