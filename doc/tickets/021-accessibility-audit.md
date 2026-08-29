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

**Status:** in-progress, and **now unblocked and on the critical path**. The
automatable half is done and green; the rest needs a real device with TalkBack
and with VoiceOver. There are twelve of them in testers' hands and a build in
App Store review, which makes the device pass available and overdue rather than
theoretical.

**What an automated sweep can and cannot settle.** `test/accessibility_test.dart`
runs the platform guideline matchers over the shop and the main screen, plus
the two structural criteria a matcher cannot express. Guidelines are a floor:
`labeledTapTargetGuideline` **passed** on a screen with two buttons both
announcing "Buy", because a label was present. The criteria below distinguish
*verified by test*, *verified by reading* and *needs a device* rather than
collapsing them into one tick.

- [ ] A complete game can be played start to finish using only a screen reader, on a real device — **on both Android and iOS**. *Needs a device; nothing here substitutes for it*
- [x] The paywall and the purchase screen are navigable by screen reader, and the price, period and what each product provides are all announced — *fixed and tested*. Both buy buttons announced "Buy" and nothing else; each now names its product. The period is in the product body ("Yearly, cancel any time"), which is its own node. **The unavailable state was a disabled button containing a whole sentence** — now body text, since a button is a promise of an action
- [ ] Every cell announces its layer, row, column and contents
- [ ] Turn changes, the result and the winning line are announced
- [ ] Navigation order is sensible on every screen, with no unreachable or unlabelled controls
- [ ] Pieces remain distinguishable on every screen under simulation of the common forms of colour blindness
- [ ] No information anywhere is conveyed by colour alone
- [ ] Every screen is usable at the largest system font scale, with no clipped or overlapping text — *shop and main screen tested at 2x; the remaining screens are not yet covered*
- [x] **The main screen reaches its last row at the largest font scale on the smallest supported phone with all six sections present** — *tested at 2x on 320pt, and it found a real overflow*: the AppBar's logo, gap and title needed 257pt of 240 and the row overflowed by 17. The decorative mark now yields to the name above 1.5x, with a `Flexible` behind it as the guarantee — rating card, Your Path, games in progress, quests, finished games and the primary button. The three-tile Your Path row is the tightest thing in the release and needs its own test rather than a general sweep
- [x] A Your Path tile and a locked opponent row are each **one** accessibility node, announced once — not six separate readings of avatar, name, rating, record, stars and price — *verified by test*: each tile has one label and zero child nodes
- [ ] The trend graph's change is available as a signed number, and no element anywhere carries meaning by colour alone — *the graph half is verified by reading*: it is `ExcludeSemantics`, and its change joins the rating card's single label through `trendSemantics` fed by `signedDelta`, which emits `+12` / `-7`. **The "anywhere" half is not verified** and is what the colour-blindness sweep below covers
- [x] Touch targets meet platform minimum sizes on the smallest supported phone — *verified by test* on shop and main screen, against both `androidTapTargetGuideline` and `iOSTapTargetGuideline`
- [x] Contrast meets accepted guidelines in both light and dark themes — *verified by test* via `textContrastGuideline`. **"Both themes" is a question this app does not have**: `main.dart` passes `QuadrimTheme.forest` as `theme` and `darkTheme` alike, so there is one theme and the platform setting cannot change it
- [ ] Findings that cannot be fixed within this ticket are recorded as follow-up work rather than left undocumented

## Findings carried forward

Recorded here rather than left in a commit message, per the last criterion.

- **The remaining screens are not swept.** The game board, opponent detail, settings, tutorial, history and the result screen have their own per-ticket semantics and none of them has been through the guideline matchers or a 2x pump. Extending `accessibility_test.dart` is mechanical; it is listed rather than done so that the gap is visible.
- **Colour-blindness simulation is not automated and was not performed.** Nothing in `flutter_test` simulates deuteranopia, so AC 6 and the second half of AC 11 need either a device with the platform simulators or a rendered-image comparison harness. **This is the largest untested criterion in the ticket.**
- **`labeledTapTargetGuideline` passing means less than it appears.** It checks that a label exists, not that it distinguishes. The duplicate-label test in `accessibility_test.dart` exists because the guideline passed on the defect it was supposed to catch, and any new screen with repeated controls needs the same explicit test.
