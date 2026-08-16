# 021 — Accessibility audit

**What to build:** A sweep across the finished app confirming that everything earlier tickets promised individually actually holds together. A player using a screen reader can complete a whole game from launch to result. A colourblind player can tell the pieces apart on every screen. Nothing breaks at the largest system font scale.

Every previous ticket carried its own accessibility criteria, so this is a verification pass rather than a build — but it is kept as a separate ticket because cross-screen flows are exactly what per-ticket checks miss.

**Blocked by:** 032, 033, 035 (all done); **047** — the paywall and purchase
screens, which are the newest surfaces in the release and the ones no audit has
seen.

**Now a two-platform audit (D302).** Everything below was written against
TalkBack and it all applies unchanged to VoiceOver. Ticket 043 does the
narrower iOS pass — the board's traversal order and the carved heading signs —
so that this ticket meets a platform that already works rather than discovering
iOS and accessibility problems at the same time. **Both platforms must pass
every criterion here**, and where they differ, both results are recorded.

**Blockers changed (D269).** This ticket previously blocked on 017 and 023. Ticket 017 is cancelled unbuilt and 023 is absorbed into 033, so neither will ever complete. The progression tickets replace them, and they bring the two hardest accessibility surfaces in the release with them: a three-tile row with an avatar, a name, a rating, a record, stars and a price in each tile, and a trend graph whose meaning must not rest on the red/green pair.

**Status:** ready-for-agent

- [ ] A complete game can be played start to finish using only a screen reader, on a real device — **on both Android and iOS**
- [ ] The paywall and the purchase screen are navigable by screen reader, and the price, period and what each product provides are all announced
- [ ] Every cell announces its layer, row, column and contents
- [ ] Turn changes, the result and the winning line are announced
- [ ] Navigation order is sensible on every screen, with no unreachable or unlabelled controls
- [ ] Pieces remain distinguishable on every screen under simulation of the common forms of colour blindness
- [ ] No information anywhere is conveyed by colour alone
- [ ] Every screen is usable at the largest system font scale, with no clipped or overlapping text
- [ ] **The main screen reaches its last row at the largest font scale on the smallest supported phone with all six sections present** — rating card, Your Path, games in progress, quests, finished games and the primary button. The three-tile Your Path row is the tightest thing in the release and needs its own test rather than a general sweep
- [ ] A Your Path tile and a locked opponent row are each **one** accessibility node, announced once — not six separate readings of avatar, name, rating, record, stars and price
- [ ] The trend graph's change is available as a signed number, and no element anywhere carries meaning by colour alone
- [ ] Touch targets meet platform minimum sizes on the smallest supported phone
- [ ] Contrast meets accepted guidelines in both light and dark themes
- [ ] Findings that cannot be fixed within this ticket are recorded as follow-up work rather than left undocumented
