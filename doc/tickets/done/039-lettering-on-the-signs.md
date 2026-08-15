# Ticket 039 — Lettering on the signs, and what was just finished

**Depends on:** 038 (the forest design)

## Why

Ticket 038 shipped three pieces of artwork with their words painted into the
wood, and D292 recorded the cost: a Dutch player read English on three
controls. New art has arrived with the lettering left off, which removes that
ceiling rather than living with it.

Four changes to the design and two to the main screen, all asked for directly.

## What it does

1. **The signs ship blank and the app writes on them** (D297).
   `tutorial-background.png`, `title-banner-1.png`, `title-banner-2.png` and
   `new-game-background.png` replace the lettered originals. `SignArt` records
   where each caption sits, how big it is and how far the plank leans, as
   fractions of the picture. The tutorial board's **8.2°** is the angle of the
   lettering the old artwork carried, recovered by fitting a line through its
   glyphs; the gold and its rim are the median of those same pixels.
2. **Every section wears a carved heading**, not only Your Path. Which of the
   two planks a heading gets depends on how long the caption is, and the plank
   stretches to the word rather than the word shrinking to the plank.
3. **Your Path's sign hangs off its card's top-left corner** — left edges
   flush, top fifth above the card.
4. **New Game loses its sub-line.** The wood says "New game" and nothing else.
5. **The rating panel loses "on this device only".** It is still said at the
   end of a game, where a rating change has just happened.
6. **A recently-completed quests panel** below the closest-four one: the four
   finished most recently and what each paid, absent until there is one
   (D298).

## Acceptance criteria

1. `bash tool/check.sh` passes.
2. Every sign's caption is drawn by the app and reads in the player's language;
   nothing in `assets/art` carries baked-in words.
3. A heading too long for the short plank is written on the long one, and both
   render their caption at the same size.
4. Your Path's sign overhangs its card's top-left corner.
5. The rating panel no longer carries the device-only note; the end-of-game
   result still does.
6. The recently-completed panel shows at most four, newest first, and does not
   exist before the first quest is finished.
7. `QuestStatus.achievedAt` comes from the game that completed the quest, and
   nothing new is stored.

---

## Closure

Committed on `main`. `bash tool/check.sh`: **ALL CHECKS PASSED**, 322 app tests
and 95 in `quadrim_progression`.

Verified on the emulator (Android 16, 1080x2400): every heading is a carved
sign lettered by the app, the long planks carry the long captions at the same
size as the short ones, Your Path's sign hangs off its card, the rating panel
has lost the device-only note, and the recently-completed panel lists two
finished quests with what each paid.

**Two things the plan did not predict, both about sizing.**

An outlined caption drawn as a stroked `Text` behind a filled one looks right
and puts the caption in the tree twice — `find.text('Quests')` started matching
two widgets and a dozen unrelated tests failed. Eight offset shadows draw the
same rim from one node. The lesson is not "use shadows"; it is that a widget
which renders one thing should be one thing.

Sizing a sign by its height and shrinking the caption to fit made long headings
render at half the size of short ones, and *smaller the longer they got* —
because the long plank is proportionally shorter and so came out narrower at
equal height, which is exactly backwards. The plank now stretches to the word.

**Known ceiling:** the geometry in `SignArt` is measured against the artwork as
delivered. New art for any sign means measuring again — the same cost the baked
lettering had, except it now buys both languages instead of one.
