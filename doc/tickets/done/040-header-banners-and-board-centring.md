# Ticket 040 — Header banners, snap scrolling, and a centred board

**Depends on:** 039 (lettering on the signs)

## Why

Seven adjustments asked for directly after living with ticket 039 on a device.

## What it does

1. **Every panel's heading hangs off its card**, further up and further left
   than Your Path's did — a label *on* the panel rather than a picture *in*
   it. The content of each panel moves up with its heading.
2. **One height for every heading sign**, each at its own proportions, with the
   caption shrinking into whatever room that leaves (D299). Signs at different
   sizes read as different signs; lettering a point or two smaller does not.
3. **In progress moves directly under Your Path** — a game waiting to be
   finished is the most actionable thing on the screen and it sat below two
   panels about what had already happened.
4. **Your Path snaps to a tile boundary**, so a flick always leaves three whole
   faces on screen rather than two and two halves.
5. **The opponent detail avatar is 40% bigger**, 200dp to 280dp.
6. **The board is centred**, in a real game and in the tutorial, reversing
   D137's right-alignment (D300).
7. **The tutorial's layer captions are ink**, not cream — that board sits on
   parchment, where cream is invisible. `BoardView` takes the colour rather
   than guessing.

## Acceptance criteria

1. `bash tool/check.sh` passes.
2. Every heading sign is the same height and overhangs the top-left corner of
   its panel.
3. No caption is clipped, on any sign, in either language.
4. Letting go of a Your Path drag leaves exactly three whole tiles visible.
5. The board is horizontally centred on the game screen and in the tutorial.
6. Layer captions are readable on both the forest and parchment.

---

## Closure

Committed on `main`. `bash tool/check.sh`: **ALL CHECKS PASSED**, 322 app tests.

Verified on the emulator (Android 16, 1080x2400): every heading hangs off its
panel's top-left corner clear of the section above, In progress sits under Your
Path, the board is centred, and the tutorial's layer captions are ink.

**Three things this cost that the list of seven did not predict.**

Hanging half of each sign above its card put it inside the *previous* section,
and a viewport paints its slivers back to front, so every heading lost its top
half to a panel it had nothing to do with. There is no z-index to reach for;
the answer is forty pixels of gap.

A `ConstrainedBox` added so the long banner could wrap broke the single-line
signs: the text clamped to the box, overflowed inside it, and the `FittedBox` —
now measuring the box rather than the line — stopped scaling. That shipped
"Tutorial" as "TUTORI". The constraint is applied only when the caption wraps.

Two lines on the long plank were tried and abandoned: its writable band is
barely a third of the picture's height and two readable lines spill over the
wood.

**And a process note.** While iterating I grepped `flutter analyze` for
`error|warning` and read "clean" three times over a deprecated `tolerance` that
`check.sh` rejected — the analyzer fails on `info` too. Read its last line, not
a filtered view.
