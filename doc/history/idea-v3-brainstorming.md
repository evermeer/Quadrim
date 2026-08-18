# Quadrim — brainstorming the third edition against the build

[idea-v3.md](idea-v3.md) was written as a standalone brief: what the product should be, with no reference to how much of it exists. This document is the other half — v3 read back against the twenty-two tickets that are actually finished, to find where the specification and the code disagree, where §7 does not survive contact with the roster it prices, and in what order the remaining work should be built.

Decisions taken here are D258–D270 in [idea-v3-decisions.md](idea-v3-decisions.md).

Date: 2026-08-14

---

## 1. Where the build actually stands

Twenty-two tickets are done and seven remain. Read against v3's sections rather than against the ticket numbers, the picture is lopsided in a useful way: everything hard is finished and everything unbuilt is one feature.

**Built and matching v3 as written:**

| Section | State |
|---|---|
| §2 board, lines, symmetry | Generated, verified exhaustively over all 635,376 quads |
| §3 rules, move list, outcomes | `GameDocument` is append-only; outcome and reason are separate fields |
| §5 computer rating | Folded, never stored; anchor rating on every game; explicit completion time |
| §6 all twenty opponents | Catalogue of `BotConfig`, one `chooseMove`, book, calibration harness |
| §8.2 board | Four layers in one column, 24 dp floor, last-two marking, line highlight |
| §8.7 opponent selection | Already an accordion by tier, opened at `tierNearest(playerRating)` |
| §8.12 tutorial | Rules, strategy, interactive practice with hints derived from the bot rules |
| §8.14 settings | Language, theme, tutorial replay, attribution |
| §11.2 build gate | Purity, l10n completeness, dictionary SHA-256, generated staleness, no `INTERNET` |
| §11.3 layering | `DocumentStore` under `GameRepository`, stream-based, completion decided once |
| §11.5 data model | No device identifier, no per-move authorship, statistics derived |
| §11.6 localisation | English and Dutch complete, enforced |

**Unbuilt — and it is all one thing.** Every remaining gap is §7 or a consequence of §7:

- §7 entire: points, the unlock ladder, quests, streaks, the `unlock` record
- §8.3 main screen: the points balance, the ten-game trend graph, the quests section
- §8.4 Your Path, which replaces the by-opponent breakdown `_OpponentSection` currently renders
- §8.5 finished-game rows: result label above the delta, relative dates, a challenge button
- §8.6 the quests section
- §8.11 end of game: points earned, quest completed, the unlock offer
- §8.1 the portrait lock
- §8.7 lock state, price and progress on the rows that already exist

Two pleasant surprises fell out of this reading. The tier accordion §8.7 asks for is already there from ticket 011, so locked opponents are a matter of adding state to existing rows rather than a new screen. And the backup allowlist is `<include domain="file" path="quadrim/" />` — an explicit allowlist covering the app's own document directory — so §7.6's requirement that unlock records be backed up **from 0.1** is satisfied the moment they are written alongside games, with no manifest change at all.

---

## 2. What the reading turned up

Eleven findings, in descending order of how much they change the work.

### F1 — Quest rewards priced by the player's rung break the economy at both ends

§7.4 says quest rewards are "multiples of a win at the player's current rung — where the current rung is the highest-indexed opponent they have unlocked", and applies that uniformly to all four quest families. Forty of the fifty-three quests are per-opponent.

The unlock ladder never requires playing the weakest opponents. The cheapest route to Willow's 64 points is four Bramble wins, not sixty-four Pebble wins — that is exactly the self-pricing property §7.3 is proud of. But it means a player has no reason to touch Pebble, Twig, Mote or Clover *at all*, so their eight quests sit unclaimed and appreciating at whatever the player's current rung is worth.

Cashed in at rung 15 those eight games pay 8 × 32,768 = 262,144 points, which is the entire Titan unlock. At rung 19 they pay 4,194,304 against a roster that costs 2,097,088 in total — twice the whole ladder, for eight games against opponents that move at random.

The remaining thirty-two per-opponent quests are much less exposed, because §3.1 assigns the first seat randomly and alternates it on rematch, so "first win as second player to move" fires on its own about half the time. The reliably bankable set is the eight against the four opponents the ladder never asks you to play.

**And the same rule breaks the volume family in the opposite direction.** A hundred games in a day pays four wins-worth. Priced at the player's rung, a hundred instant Pebble games at rung 17 pay 524,288 points — four Titan wins for an afternoon of tapping. §7.4 had already spotted this and called the volume family "the only remaining farm vector", then leaned on the paywall to contain it. The paywall does not exist: the meter arrives at 0.4 and progression ships at 0.1, so nothing bounds it for three releases, and afterwards it bounds it only to people who have paid.

Both halves are the same mistake. §7.3's whole shape exists so that grinding downward prices itself out without a rule — every rung down halves the payout — and a quest priced by the player's height reintroduces the exploit in the one place that shape was not looking.

**Resolved by D261 and D270:** every quest is priced by the opponents it was earned against, and nothing anywhere is priced by the player's rung. A per-opponent quest pays 2ⁱ. A volume or streak quest pays its multiple of a win against the **average roster index of the qualifying games, rounded to the nearest opponent**.

Average the index, not the payout: because payouts double, an arithmetic mean of them is dominated by the strongest single game, so nineteen Pebble games and one Titan game would average 6,555 points — twenty games priced at roughly a Corvus win on the strength of one of them. The geometric mean pays 2 for the same set, which is what nineteen trivial games and one real one are worth. Rounding to the nearest opponent keeps it sayable: *your twenty games averaged Kestrel*.

### F2 — Your Path points at the wrong opponent on first launch

§8.4 centres the middle tile on "the first opponent rated above the player's current rating". §7.3 unlocks strictly in roster order. At launch these diverge.

A player seeded at 800 (§5) gets a window of Mote (800) / Clover (900) / Bramble (1000) — three opponents they already own. Their next unlock is Willow at 1100, which is outside the window. §8.4 provides for locked tiles showing "their price and the player's progress toward it", but on first launch no locked tile is on screen, so the price ladder — the entire motivation for §7 and the reason the section is on the main screen at all — is invisible until the rating climbs into it.

The section is titled "where am I, and who is next". Centred on rating it answers the first question twice and the second not at all.

**Resolved by D262:** the middle tile is the next unlock.

### F3 — The Casual inversion stops being cosmetic once prices are attached

§14 records that Willow measures about 33 points above Vireo and Vireo about 50 above Finch, and assigns the fix to the 1.0 roster revision. Confirmed against `bot.dart`: Willow 1100 at `aggression` 0.5, Vireo 1200 at 0.67, Finch 1250 at 0.30, and §6.5 measures `aggression` at about 78 Elo in the aggressive direction. The published order is the exact reverse of the measured one.

Under v2 that was a discrepancy between two numbers, one of which nobody could see. Under §7 the roster index sets both the unlock price and the win payout, so across three consecutive rungs the player now pays **monotonically increasing prices for monotonically decreasing strength**:

| Opponent | Unlock costs | A win pays | Measured, relative |
|---|---|---|---|
| Willow | 64 | 32 | strongest of the three |
| Vireo | 128 | 64 | middle |
| Finch | 256 | 128 | weakest, by about 83 points |

The farming vector this opens is real but bounded, and worth doing the arithmetic on rather than assuming. Beating Finch pays 128 against Kestrel's 256, so the same 1,024 points needs eight Finch wins or four Kestrel wins. Finch plays at roughly 1170 effective and Kestrel at its published 1300, so a player around 1300 needs about twelve games to take eight from Finch and about eight to take four from Kestrel. Kestrel is still the faster route. The economy holds.

What does not hold is legibility: the app is about to display three prices as a public claim about relative difficulty, and for these three the claim is false. Re-pricing by measured strength is not available — §6.4 pins pricing to roster index and D144 pins ratings as anchors — so the fix remains the roster change §14 already names.

**Resolved by D268:** the disposition does not change, the reason does. This moves from a cosmetic note to a stated defect with a user-visible symptom, and it is the strongest argument yet for doing the 1.0 roster revision early.

### F4 — The stored-price rule protects spends and not earnings

§7.6 stores `pricePaid` on every unlock, reasoning that "re-tuning a cost later must never retroactively bankrupt someone who already spent at the old price". Correct, and the same failure mode exists on the other side and is untreated: quest awards are derived from the live table, so re-tuning §7.4's multiples retroactively changes every player's earned total. Since balance is `earned − Σ pricePaid`, a downward re-tune can drive a balance below zero against unlocks already bought.

Adding a stored award record would fix it and would cost the property in DoD #10 that nothing but the unlock records is stored — for a re-tune that is expected once, before real players exist, if at all.

**Resolved by D264:** the balance clamps at zero and unlocks are never revoked (§7.3 already promises the second half). A downward re-tune costs future purchasing power and takes nothing away. That is a rule of one sentence rather than a second stored table.

### F5 — The balance was a merge of two time-ordered streams; fixing F1 removed it

§7.6 describes points earned as "a fold over stored games — sum 2ⁱ over wins, plus the quest awards". Under the original rule that was false: a volume or streak award depended on the rung the player was on when it fired, and the rung comes from unlock records with their own `unlockedAt`. The fold would have had to interleave completed games with unlock records in time order — two streams, an ordering hazard on each, and a balance that could not be checked against the game list alone. D265 recorded that and specified the signature `balance(games, unlocks)`.

**D270 makes it moot, which is the most valuable thing to come out of this pass.** Once no quest reward depends on the player's rung, nothing about points *earned* consults an unlock record. The signature collapses back to a fold over games, §3's "everything derives from the move list" holds for the whole of it, and the single stored record in §7.6 is read only for what was *spent*. A correctness fix and a simplification turned out to be the same change — which is usually the sign the fix is the right one.

### F6 — There is no meter in 0.1, so the volume quests are reachable by everyone

§7.4 says "the volume ladder is subscriber-only by arithmetic, not by a rule" because five games in a day exceeds the free cap of three. The cap arrives at 0.4 (§4.2). In 0.1 there is no cap, so every tester can complete the whole volume family, and the tile copy explaining why a free player cannot reach it would be false for the entire closed test.

**Resolved by D266:** in 0.1 the volume quests are ordinary quests with no restriction copy. The explanation ships with the meter at 0.4, in the same release that makes it true.

### F7 — Pricing keys on roster index; the code currently sorts by rating

`HomeSummary.byOpponent` sorts weakest-first by *rating*, which is right for a breakdown and wrong for pricing. §6.4 is explicit that the index "is an ordinal, not a rating, and the two must not be conflated", and F3 is what happens when they are. The catalogue is already stored in roster order, so the index is `opponentCatalogue.indexWhere` and nothing needs adding — but every point value, unlock cost and per-opponent quest award must come from that index and never from the rating field beside it. Worth a test that asserts it over the whole catalogue, in the same spirit as the positional-weight test §6.3 asks for.

### F8 — Fifty-three quests is a localisation bill

Twenty first-win quests, twenty second-seat quests, five volume rungs and eight streak rungs. Even with parameterised names — one template per family with the opponent name substituted — the tile copy, the requirement line, the completion acknowledgement and the accessibility label multiply across two languages. This is not difficult work but it is not free, and it is the kind of thing that gets estimated at zero because each string is trivial.

### F9 — The main screen is at its structural limit before the new sections arrive

`home_screen.dart` is 769 lines holding twelve private widget classes. §8.3 adds a trend graph, a balance, a Your Path row and a quests section, and rewrites the finished-game row. Extending in place lands somewhere past 1,200 lines in the one file that every remaining ticket touches.

**Resolved by D267:** split first, then grow. See §4.

### F10 — Six sections at the largest font scale on the smallest phone

§8.13 already singles out the three-tile Your Path row as the tightest thing on the screen. With the quests section added, §8.3 stacks six things above the primary button, and DoD #20 requires every screen to reach its last row at the largest setting. This needs a specific test at the extreme, not an assumption that scrolling absorbs it.

### F11 — Real avatars exist, and §6.4 does not know

`doc/Avatars.md` and `doc/designs/` now hold twenty avatar specifications, and D257 renamed ten opponents specifically so the images read as a progression. §6.4 still says "generate avatars from the opponent's id rather than shipping twenty image files", and §12 puts real art in 0.2.

**Resolved by D260:** §6.4 stands for 0.1 and the generated avatars ship to the closed test. The real ones arrive with 0.2's art pass, where §12 already puts them. The rename pays off either way — it is the names that had to be settled before the images were commissioned, and they are.

---

## 3. Approaches: how to build §7

### A — Bottom-up: package, then repository, then screens

Build `quadrim_progression` complete and exhaustively tested, wire the award into `LocalGameRepository`, add the unlock record and its persistence, then the screens.

Each layer is finished before the next depends on it, and the arithmetic — which is the part that must be exactly right — gets the most attention while it is the only thing in play. The cost is that nothing is visible until late, and the largest genuine unknown in this work is not the arithmetic but whether §8.3's six sections fit on a phone.

### B — Vertical slices: points and unlocks, then quests, then streaks *(chosen)*

Ship the smallest complete loop first: a win pays 2ⁱ, a balance appears on the main screen, the next opponent can be bought and Your Path shows its price. Then quests as a second slice. Then streaks as a third.

Each slice crosses every layer, so `quadrim_progression` grows in three passes rather than arriving whole. In exchange, a real unlock is on screen after the first slice, which is what the closed test is actually measuring (§12: "it is the reason to open the app on the second day"), and F9's main-screen risk is met at the start instead of at the end.

The package's *shape* is still fixed up front — the point and cost functions, the roster-index keying from F7, the games-only balance fold from F5 — so the three passes extend a settled interface rather than renegotiating it.

**Recommended, and taken as D266.** The arithmetic is small and exhaustively testable whenever it is written; the main screen is neither, so it should be met first.

### C — Screens first against a hand-written state

Build §8.3 and §8.4 against a fixture, then implement behind them. Fastest possible feedback on F9 and F10, and the fixture makes the largest-font-scale test available on day one.

Rejected because it invites the screens to pin an awkward model — the merge in F5 is exactly the kind of thing a UI built against a convenient fixture will assume away, and discovering it afterwards is more expensive than the feedback is worth.

---

## 4. Approaches: the main screen

### M1 — Extend `home_screen.dart` in place

Shortest diff. Produces a 1,200-line file that tickets 021, 022 and everything in 0.2 must then work inside.

### M2 — Split into per-section files, then add *(chosen)*

`app/lib/home/` gains `rating_card.dart`, `your_path.dart`, `quests_section.dart`, `finished_games.dart` and `active_games.dart`, and `home_screen.dart` becomes the composition and the state that feeds it.

This is close to mechanical: the twelve private widget classes already in the file are the extraction boundaries, and `_RatingCard`, `_ActiveGameTile`, `_FinishedGameTile`, `_GameRow`, `_RatingDelta`, `_RatingPill` and `_RatingBar` move with no change to their bodies. `_OpponentSection` is deleted rather than moved — Your Path replaces it (§8.4) — but `HomeSummary.byOpponent` is *kept*, because Your Path's tiles need exactly the per-opponent records it already produces, plus the locked ones the catalogue supplies.

The new sections then arrive as new files instead of as growth in the file everything else touches.

### M3 — Rewrite the main screen from §8.3

Cleanest result, discards working, reviewed, accessibility-tested code for sections whose specification did not change. Rejected on that basis: the rating card and the games lists are the same elements in v3 as in v2.

**M2 is taken as D267**, done as its own first step so that the diffs which follow are legible.

---

## 5. Ticket plan

Seven tickets are open. v3 contradicts three of them.

| Ticket | Disposition |
|---|---|
| **015** Store accounts and release signing | Unchanged, and now the longest lead time on the critical path. D259 keeps the fourteen-day clock behind progression, which makes starting the account work *immediately* more important, not less — it is waiting time, not effort |
| **016** Closed test with friends and family | Unchanged in content, moved behind the progression tickets by D259 |
| **017** Large-screen landscape layout | **Cancelled.** §8.1 ships portrait phone only (D253). The ticket file moves to `done/` with a cancellation note rather than being deleted — the reasoning is worth keeping |
| **021** Accessibility audit | Unchanged in content; blockers change. It currently lists 017 and 023, neither of which will exist. Re-point at the progression tickets, and add F10's largest-font-scale test on the six-section screen |
| **022** Release 0.1 readiness | Unchanged; its "every other ticket" dependency now includes the new ones |
| **023** Per-opponent milestones | **Absorbed.** §7.4 makes its two milestones the first two quest families (D240). The work is not lost — it becomes forty of the fifty-three quests — but it is no longer a separate ticket, and its "no new stored shape" property survives intact |
| **024** Closed-test survey and thresholds | Unchanged in content, and considerably more valuable: §7.7 names median time to each unlock and the rung at which players stop as the two signals to watch, and this survey is the only instrument that can see them. Add both to it |

New tickets, in build order:

| # | Ticket | Contains |
|---|---|---|
| 030 | Main screen decomposition | M2's split. No behaviour change, no new strings — the diff is provably a move |
| 031 | `quadrim_progression` and the first slice | The pure package, point values, unlock costs, the `unlock` record, the balance fold, awarding in the repository, balance on the rating card, Your Path centred on the next unlock, lock state and price in opponent selection, the unlock confirmation including §6.6's "unbeatable when it moves first" for Oracle and Prime |
| 032 | Quests | All fifty-three, the four-closest section (§8.6), every award priced by the opponents played, never by the player's rung (D261, D270), acknowledgement at end of game |
| 033 | Streaks | Day boundary injected, never read (§11.1); the eight rungs; reset on a missed day across month, year and time-zone boundaries |
| 034 | Main screen and end-of-game finish | The ten-game trend graph with its signed number (§8.3), the finished-game row changes (§8.5), the end-of-game points/quest/unlock panel (§8.11), the portrait lock (§8.1) |

Ticket 031 is the large one and could split further along the unlock/display seam if it proves unwieldy. Left whole for now because the first slice is only complete when a player can actually buy something, and half of it on screen with no purchase is not a slice.

---

## 6. What this pass did not settle

- **The progression numbers themselves.** §7.7 already says they are derived from a stated target rather than measured, and that they are the first thing to instrument. Nothing here changes them; D261 changes only *which rung* a per-opponent quest is measured against, not the multiples.
- **The 1.0 roster revision.** F3 sharpens the case and D268 restates the reason, but the change is still a roster change and still belongs to 1.0.
- **Everything in §14.** Store price points, store accounts, app-name availability and the reference device are unchanged business and account decisions.
