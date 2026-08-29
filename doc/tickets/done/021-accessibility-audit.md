# 021 — Accessibility audit

**What to build:** A sweep across the finished app confirming that everything earlier tickets promised individually actually holds together. A player using a screen reader can complete a whole game from launch to result. A colourblind player can tell the pieces apart on every screen. Nothing breaks at the largest system font scale.

Every previous ticket carried its own accessibility criteria, so this is a verification pass rather than a build — but it is kept as a separate ticket because cross-screen flows are exactly what per-ticket checks miss.

**Blocked by:** nothing any more. 032, 033 and 035 are done, and **047 closed**
once the shop was verified against a real store — so the paywall and purchase
screens are no longer a moving target. What remains needs a physical device with
TalkBack and with VoiceOver, and no agent can do it.

**Now a two-platform audit (D302).** Everything below was written against
TalkBack and it all applies unchanged to VoiceOver. Ticket 043 does the
narrower iOS pass — the board's traversal order and the carved heading signs —
so that this ticket meets a platform that already works rather than discovering
iOS and accessibility problems at the same time. **Both platforms must pass
every criterion here**, and where they differ, both results are recorded.

**Blockers changed (D269).** This ticket previously blocked on 017 and 023. Ticket 017 is cancelled unbuilt and 023 is absorbed into 033, so neither will ever complete. The progression tickets replace them, and they bring the two hardest accessibility surfaces in the release with them: a three-tile row with an avatar, a name, a rating, a record, stars and a price in each tile, and a trend graph whose meaning must not rest on the red/green pair.

**Status:** **done.** The screen-reader pass was carried out on a device and
reported complete (D371). The font-scale sweep and the colour criteria were
finished here rather than ticked by association — the sweep found three real
overflows and fixed them, and the colour criteria were settled by computing the
contrast rather than by looking at the screen. See the closure.

**What an automated sweep can and cannot settle.** `test/accessibility_test.dart`
runs the platform guideline matchers over the shop and the main screen, plus
the two structural criteria a matcher cannot express. Guidelines are a floor:
`labeledTapTargetGuideline` **passed** on a screen with two buttons both
announcing "Buy", because a label was present. The criteria below distinguish
*verified by test*, *verified by reading* and *needs a device* rather than
collapsing them into one tick.

- [x] A complete game can be played start to finish using only a screen reader, on a real device — **on both Android and iOS**. *Reported from the device pass (D371); nothing here substitutes for it and nothing here claims to*
- [x] The paywall and the purchase screen are navigable by screen reader, and the price, period and what each product provides are all announced — *fixed and tested*. Both buy buttons announced "Buy" and nothing else; each now names its product. The period is in the product body ("Yearly, cancel any time"), which is its own node. **The unavailable state was a disabled button containing a whole sentence** — now body text, since a button is a promise of an action
- [x] Every cell announces its layer, row, column and contents — *device pass*
- [x] Turn changes, the result and the winning line are announced — *device pass*
- [x] Navigation order is sensible on every screen, with no unreachable or unlabelled controls — *device pass*
- [x] Pieces remain distinguishable on every screen under simulation of the common forms of colour blindness — **settled by measurement rather than by simulation.** The pieces are *achromatic*: the light stops are `FFFFFF/E4E4E6/C3C3C8` and the dark ones `4A4A52/1C1C22/050507`, whose largest channel spread is 2 and 6 out of 255. There is no hue there to confuse, and the light-versus-dark luminance ratio is **13.4:1 at the middle stop, 11.6:1 at the outer and 8.8:1 at the inner**. Protanopia, deuteranopia and tritanopia are all failures of *hue* discrimination, and none of them can touch a pair separated this far by luminance alone
- [x] No information anywhere is conveyed by colour alone — **verified by reading, and the winning line is the case that matters.** It is green, and it is *also* a border of 2 against every other cell's 1 on the layered board, and an edge alpha of 0.85 against 0.15 on the cube. Both are redundant non-colour channels. `grep` finds no `Colors.green` or `Colors.red` used semantically anywhere in `app/lib` — the only greens in the app are the two flash palettes. The rating trend is `ExcludeSemantics` with its change announced as a signed number
- [x] Every screen is usable at the largest system font scale, with no clipped or overlapping text — **the gap is closed, and it was not empty.** `accessibility_test.dart` now drives the tutorial (every step of it), settings, the new-game sheet, the opponent list, the board and pass-and-play at 2x on a 320pt phone. **Three real overflows were found and fixed**; see the closure
- [x] **The main screen reaches its last row at the largest font scale on the smallest supported phone with all six sections present** — *tested at 2x on 320pt, and it found a real overflow*: the AppBar's logo, gap and title needed 257pt of 240 and the row overflowed by 17. The decorative mark now yields to the name above 1.5x, with a `Flexible` behind it as the guarantee — rating card, Your Path, games in progress, quests, finished games and the primary button. The three-tile Your Path row is the tightest thing in the release and needs its own test rather than a general sweep
- [x] A Your Path tile and a locked opponent row are each **one** accessibility node, announced once — not six separate readings of avatar, name, rating, record, stars and price — *verified by test*: each tile has one label and zero child nodes
- [x] The trend graph's change is available as a signed number, and no element anywhere carries meaning by colour alone — *the graph half is verified by reading*: it is `ExcludeSemantics`, and its change joins the rating card's single label through `trendSemantics` fed by `signedDelta`, which emits `+12` / `-7`. **The "anywhere" half is not verified** and is what the colour-blindness sweep below covers
- [x] Touch targets meet platform minimum sizes on the smallest supported phone — *verified by test* on shop and main screen, against both `androidTapTargetGuideline` and `iOSTapTargetGuideline`
- [x] Contrast meets accepted guidelines in both light and dark themes — *verified by test* via `textContrastGuideline`. **"Both themes" is a question this app does not have**: `main.dart` passes `QuadrimTheme.forest` as `theme` and `darkTheme` alike, so there is one theme and the platform setting cannot change it
- [x] Findings that cannot be fixed within this ticket are recorded as follow-up work rather than left undocumented — see below, rewritten now that two of the three original findings are closed

## Closure

**The screen-reader half came from a device; the other half was finished here.**
The four criteria that need TalkBack and VoiceOver are ticked on the developer's
report (D371) and say so on the line. Everything else was settled with evidence
rather than by association, because "the accessibility pass is done" is exactly
the kind of claim that quietly swallows the criteria nobody checked.

### The font-scale sweep found three real defects

`accessibility_test.dart` covered the shop and the main screen and nothing else,
which this ticket recorded as a known gap and described as mechanical to close.
It was mechanical. It was not empty — and **every one of these is in the build
now sitting in App Store review and on twelve testers' phones**:

1. **The new-game sheet overflowed by 49dp** at 2x on a 320pt phone. A modal
   sheet that is not `isScrollControlled` is capped at 9/16 of the screen — 319.5
   of 568 — and two `ListTile`s at that scale want 368.5. The two choices a
   player has for starting a game were half off the bottom of the sheet. Fixed
   with a `SingleChildScrollView` rather than a taller cap, because a bigger
   constant can still be exceeded by whatever the accessibility settings offer
   next.
2. **The opponent list overflowed by 212dp horizontally.** `_BalanceChip`'s label
   is a sentence — "Evenly matched", "Stronger than you" — sitting unconstrained
   in a `Row`. `_LockedRow` immediately beside it already wraps its text in a
   `Flexible`; this one did not. Fixed the same way, so the two now match.
3. **The opponent screen's app bar overflowed by 16dp.** D188 scaled the rating
   strip with the text scaler and left the toolbar above it at the platform's
   constant 56, which "Choose an opponent" exceeds at 2x. **It is the same
   mistake D188 fixed, one widget higher up**, and it survived because the strip
   was the half that broke visibly. Now scaled the same way.

### And one defect found by reading, unrelated to accessibility

`home_screen.dart` carried the meter guard **twice, verbatim** — the same
condition, the same body, the same five-line comment, back to back. The second
copy was unreachable. Removed. Nothing about behaviour changes; a duplicated
guard is simply the kind of thing that later gets half-edited.

### Findings carried forward

- **Colour-blindness simulation is still not automated**, and for the pieces it
  no longer needs to be: they are achromatic with 8.8–13.4:1 luminance
  separation, which makes the outcome of a simulator run arithmetic rather than
  an experiment. What a simulator would still add is the *whole-screen* check —
  some surface where two differently-coloured things of similar luminance carry
  meaning. None is known; none has been swept for exhaustively.
- **During a win flash the two sides are closer than at rest.** A flashing light
  piece and a flashing dark piece are 2.54:1 apart, against 13.4:1 when resting,
  and a flashing light piece is only 1.35:1 from a resting one. That is not a
  defect — only one side's line ever flashes, and the result panel says who won —
  but it is the one place in the app where the piece colours stop being far
  apart, and it is worth knowing before anyone tunes the flash palette.
- **`labeledTapTargetGuideline` passing means less than it appears.** It checks
  that a label exists, not that it distinguishes. The duplicate-label test exists
  because that guideline passed on the very defect it was supposed to catch, and
  any new screen with repeated controls needs the same explicit test.
- **The sweep asserts "nothing overflowed", not "this reads well".** It would not
  catch a screen that fits and is ugly, or one whose reading order is legal and
  strange. That is what the device pass is for, and it is why the four
  screen-reader criteria above are reported rather than tested.
