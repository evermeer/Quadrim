# Quadrim — Decision Log, third edition

Every decision taken while turning [idea-v2.md](idea-v2.md) and the notes in [idea-v2-additions.md](idea-v2-additions.md) into [idea-v3.md](idea-v3.md).
Each entry records the question, the decision, and what it costs or buys.

Numbering continues from [idea-v1-decisions.md](tickets/done/idea-v1-decisions.md), which ended at D217. Decisions here are **D218–D278**.

Date: 2026-08-14
Status: D218–D277 agreed pre-implementation; D278 onward were taken while building.

| Group | What it settles | Decisions |
|---|---|---|
| 1 | Money — tiers, the meter, and a withdrawn promise | D218–D225 |
| 2 | Rating — the new seeds | D226–D227 |
| 3 | Progression — points, unlocks, quests, streaks | D228–D239 |
| 4 | The main screen | D240–D252 |
| 5 | Scope, platforms and staging | D253–D256 |
| 6 | The roster rename | D257 |
| 7 | v3 read back against the build | D258–D270 |
| 8 | The specification | D271–D274 |
| 9 | The ticket breakdown | D275–D277 |
| 10 | Implementation | D278 |

---

# Group 1 — Money

## D218 — The free-forever promise is withdrawn
**Question:** v2 §4.1 opened with "Everything release 0.1 shipped is free, forever… no time limit, no feature held back." The new metering of offline play contradicts it directly. Which survives?
**Decision:** The promise is withdrawn, and v3 says so in the text rather than quietly deleting the sentence. Nothing has shipped to a member of the public, so nobody is having anything taken away; the promise was written before there was a business model and could not survive one.
**Cost:** A rebuilder reading v2 and v3 side by side sees the project reverse itself on a stated principle. That is the honest record. What is kept is the narrower and still-true half — no ads, and no *feature* held back; only the rate of starting new computer games is limited.

## D219 — Offline play is metered
**Question:** How is the offline game monetised, given that all twenty opponents remain reachable?
**Decision:** One unmetered month from first launch, then **3 computer games per day and 9 per week**. Tier 2 ($1.99/yr) lifts the cap; tier 3 ($4.99/yr) contains tier 2 and adds online initiation.
**Cost:** The product now has a wall in it, and the first month is the only chance to establish the habit that makes crossing the wall feel worth $1.99. It also makes the retention curve the thing to measure, rather than a nice-to-have.

## D220 — What the meter counts
**Question:** Which games consume the daily allowance?
**Decision:** Only games against the computer. Pass-and-play, the tutorial's practice game, replay of a finished game and online play are all outside the meter. A game is counted **when it is started**, not when it finishes.
**Cost:** Counting at start means an accidental start is a spent game. Counting at finish would be defeated by starting and abandoning, which is worse. The rule must be stated in the paywall copy so it is not discovered.

## D221 — The paywall must name the limit that bit
**Question:** With two limits, which does the message describe?
**Decision:** Whichever one actually blocked the game. "You have used this week's nine games" and "come back tomorrow" are different sentences and only one is true on a Thursday.
**Cost:** Two message variants instead of one, and a test for each. Saying the wrong one teaches the player the app does not know its own rules, which is more expensive than the second string.

## D222 — Three tiers rather than two
**Question:** v2 had one subscription. The additions propose a cheaper offline-only tier beneath it.
**Decision:** Free, tier 2 at $1.99/yr (unlimited offline), tier 3 at $4.99/yr (everything in tier 2 plus online initiation, auto-match, the challenge board and chat).
**Cost:** A second product to price, describe, test and support in both stores, and a third state in every entitlement check. It buys a price point for the large majority of players who will never play online.

## D223 — Tiers 2 and 3 are two plans of one product
**Question:** "Subscribing to tier 3 cancels tier 2" — how?
**Decision:** By the store, not by the app. One iOS subscription group, one Play subscription with two base plans. An upgrade is a store-native plan change with proration.
**Cost:** Constrains the store configuration and makes the two tiers permanently siblings — separating them later is a migration. The alternative, selling them as independent products and cancelling one from the app, is not something either store's API supports correctly, and produces double-billed users and a refund queue.

## D224 — The one-time unlock buys opponents and nothing else
**Question:** What does the $4.99 permanent unlock include, given it costs the same as a year of tier 3?
**Decision:** All twenty opponents, immediately, and no change to the meter. It is deliberately the least powerful item in the shop.
**Cost:** A player who buys it and then hits the daily cap may feel misled, so the listing must be explicit about what it does not do. In exchange, the cheapest permanent purchase cannot undercut either subscription, which it would if it also lifted the cap.

## D225 — The free month starts at first launch and is remembered against the account
**Question:** When does the month start, and what stops a reinstall from restarting it?
**Decision:** At first launch. Stored against the account, which exists from 0.3a — a full release before the meter arrives. Accounts that predate 0.4 start their month **at the 0.4 update**, not retroactively.
**Cost:** The meter cannot ship before accounts do, which is fine because it ships with the store products anyway. A device-local month would have been buildable earlier and defeated by a reinstall or a clock change, and there is no reason to build the weaker version when the stronger one arrives first. The retroactive exemption exists so existing testers are not metered on update having never had the month.

---

# Group 2 — Rating

## D226 — Seeds move to 800 and 1000
**Question:** Both ladders seeded at 1200. Against a roster starting at 600, a new player's first week is a number falling.
**Decision:** **800** against the computer, **1000** against humans. K 32/16 and the floor of 100 are unchanged.
**Cost:** The two ladders no longer share a seed, so "seed" becomes a per-ladder constant rather than a global one. It buys a new player a position just below Clover with somewhere obvious to climb, which is the story the roster is telling.

## D227 — Changing the seed rewrites every existing rating
**Question:** The computer rating is a fold with nothing stored, so a seed change silently restates every player's history. Acceptable?
**Decision:** Yes, here — the affected players are closed testers and the new number is the intended one. Recorded explicitly because the same property makes any *future* change to the seed or K-factor a silent rewrite, which a shipped product cannot do casually.
**Cost:** Testers see their rating change on update with no explanation unless one is given. The general lesson is the valuable part: the derived rating's great virtue, that nothing can drift, is also the thing that makes its constants un-changeable later.

---

# Group 3 — Progression

## D228 — Fifteen of the twenty opponents are earned
**Question:** Which opponents are locked at first launch?
**Decision:** Those rated **above 1000** — Willow through Quadrim Prime. Pebble, Twig, Mote, Clover and Bramble are free. The rule is the rating threshold, not the count; nothing hard-codes "five".
**Cost:** A new player meets five opponents rather than twenty, which is a smaller first impression. It buys the only long-running goal a single-player game has. Expressing it as a threshold means a future roster revision does not silently change which opponents are free by leaving a magic number behind.

## D229 — Unlocking is strictly sequential
**Question:** With a spendable balance, can a player save up and skip ahead?
**Decision:** No. Only the next locked opponent may ever be bought.
**Cost:** The wallet has no strategic decision in it — it is a savings counter, not an economy. That is a real loss of depth, traded for a ladder that is trivially explainable and a difficulty curve nobody can accidentally skip past into an opponent that beats them forty times running.

## D230 — A win pays 2ⁱ; an unlock costs 2ⁱ⁺¹
**Question:** The additions asked for a doubling unlock cost *and* for four wins to buy the next opponent. Across fifteen rungs those cannot both hold at a fixed win value — the last unlock would be 16,384× the first.
**Decision:** Both scale. A win against roster index *i* pays 2ⁱ points; unlocking opponent *i* costs 2ⁱ⁺¹, which is exactly four wins against the opponent below. The whole roster is 2,097,088 points — **60 wins**.
**Cost:** Seven-digit numbers on screen by the top of the ladder, which need locale thousands separators and a progress bar to be legible at all. It buys three properties that would otherwise each need a rule: flat effort per rung, a self-pricing anti-grind (D233), and an unlock ladder that advances in step with the rating ladder without being coupled to it.

## D231 — Wins only; draws and losses pay nothing
**Question:** Should a draw against a far stronger opponent pay something?
**Decision:** No. Wins only.
**Cost:** A draw against Quadrim Prime — a genuinely good result — earns nothing, which is arguably unjust at the very top. It buys an exact promise the interface can make: four wins buys the next opponent. A fractional draw payment makes that sentence approximate, and it is the sentence the whole ladder is explained with.

## D232 — Sixty wins is the balance target
**Question:** What is the intended pace?
**Decision:** One unlock ≈ one sitting (four wins, or eight to twelve games against an unfamiliar opponent); the full roster ≈ two months of ordinary play. At the free tier's three games a day, fifteen rungs is around fifty days — after an unmetered first month in which the early rungs go past almost unnoticed.
**Cost:** Ties the progression pace to the meter, so changing either changes both. Stated as a target so that when it is measured (D239) there is something to measure against.

## D233 — No anti-farming rule
**Question:** What stops a player grinding the weakest opponent for the top unlock?
**Decision:** Nothing, because the price curve already does. Every rung down halves the payout, so unlocking Quadrim Prime by beating Pebble takes 1,048,576 games.
**Cost:** None, which is the point. A minimum-move-count rule or a per-opponent daily cap would have punished a player who genuinely enjoys easy games in order to stop an exploit the arithmetic already prices out.

## D234 — Quest rewards are multiples of a win at the player's current rung
**Question:** A flat quest reward is ladder-skipping at the bottom and pocket change at the top. What scales it?
**Decision:** Express every quest reward in *wins-worth* at the player's highest unlocked opponent. A 30-day streak or a 100-game day is worth about four wins — one unlock.
**Cost:** A quest's point value is no longer a constant, so the tile must compute and display it, and a screenshot of a quest is not portable between players. It buys quests that stay relevant for the whole life of the account.

## D235 — The daily-volume ladder stays as written and is subscriber-only by arithmetic
**Question:** Points for 5, 10, 20, 50 and 100 games in a day are unreachable under a 3-a-day free cap.
**Decision:** Keep the ladder unchanged. It is a subscriber reward, not by a rule but because five games exceeds three. The quest tiles must **state the requirement and what would change it**, rather than leaving a free player to discover an unreachable goal.
**Cost:** Most players will look at a permanently incomplete quest family. The mitigation is entirely in the copy, which makes that copy load-bearing. This family is also the only remaining farm vector, since it rewards game count rather than opponent strength — bounded by being behind the paywall and capped at four wins-worth a day.

## D236 — A missed day resets the streak
**Question:** The ladder runs to 1440 consecutive days. Does it survive real life?
**Decision:** No forgiveness, no rest days, no repair purchase. A day is the device's **local calendar day**, kept alive by *finishing* at least one computer game — starting one is not enough, or the streak is maintained by opening the app and quitting.
**Cost:** The long rungs will be reached by almost nobody, and a player who loses a 200-day streak to one bad Tuesday may leave. It buys three mechanics that do not exist: no rest-day accounting, no repair currency, no "I *did* play on Tuesday" support burden. Where the local-time rule is ambiguous — a time-zone change — resolve generously and never break a streak any reasonable reading would have kept.

## D237 — Points are a wallet, not a lifetime total
**Question:** Do points accumulate forever and unlock at thresholds, or are they spent?
**Decision:** Spent. Unlocking deducts.
**Cost:** This is the decision that breaks "everything derives from the move list" (D238). A lifetime-total design would have stayed a pure fold. It buys a balance that means something — what you can afford right now — rather than a career score that only ever grows.

## D238 — Unlocks are stored, with the price paid
**Question:** A spend is a decision, and a decision is not in the move list. What is stored?
**Decision:** One record per unlock: `{ opponentId, unlockedAt, pricePaid, source }`. Nothing else. The balance is *earned minus the sum of prices actually paid*; streaks, quest progress and statistics all remain derived.
**Cost:** The first stored shape in the app that is not reconstructible from game history, and therefore the first thing that can be lost or corrupted independently. `pricePaid` is stored for exactly the reason a game stores the opponent's anchor rating (§5): re-tuning a cost later must never retroactively bankrupt someone who already spent. `source` lets a refund of the one-time purchase revoke what it bought and nothing that was earned.

## D239 — The progression numbers are provisional and instrumented
**Question:** Every other number in the specification was measured. These were derived from a target.
**Decision:** Say so. Take the same stance §6.7 takes on opponent strength — when observed play disagrees with the table, the table changes. The two signals to watch are the median time to each unlock and the rung at which players stop. The **shape** (doubling on both sides) is not to be changed casually, because flattening it reintroduces the exploit D233 relies on the curve to price out.
**Cost:** Admits in the specification that part of it is a guess. That is cheaper than a rebuilder treating these numbers with the same confidence as the measured ones.

---

# Group 4 — The main screen

## D240 — One achievement system
**Question:** Ticket 023 defined two milestones per opponent; Your Path tiles now carry a star record; the additions introduce Quests. Three systems?
**Decision:** One. Everything that pays points is a quest, including the two per-opponent milestones — first win, and first win as the second player to move. Ticket 023 is rewritten into this rather than deleted.
**Cost:** Forty of the fifty-three quests are per-opponent, so the quest list is dominated by one family and the "closest to completion" ranking (D251) must not be swamped by it. It buys one progress model, one data shape and one screen section instead of three.

## D241 — Your Path replaces the by-opponent breakdown
**Question:** v2's main screen listed all twenty opponents weakest-first with a rating bar each.
**Decision:** Replace it with five tiles centred on the first opponent rated above the player. Each tile stacks vertically: full-width avatar, name, rating, win/loss/draw, three stars, rematch. The full roster with the same records stays browsable in opponent selection.
**Cost:** The at-a-glance overview of all twenty is gone from the main screen. It buys an answer to the question players actually have — where am I, and who is next — in the space that was showing fifteen rows of opponents they have never met.

## D242 — The window clamps at both ends
**Question:** What fills the tiles when the player is below Pebble or above Quadrim Prime?
**Decision:** Always five tiles; the window slides rather than shrinking.
**Cost:** At the extremes the highlighted tile is not in the middle, which is a small inconsistency. A four-tile row with a hole in it looks like a defect, which is a larger one.

## D243 — Locked opponents are shown in full
**Question:** Silhouette them, hide them, or show them?
**Decision:** Show everything — name, rating, avatar, blurb — greyed, with the price and the player's progress toward it.
**Cost:** A new player sees fifteen padlocks, which is a lot of locked content on day one. Hiding them would hide the goal, and the goal is the entire reason the ladder exists.

## D244 — Stars count decisive games only
**Question:** Where do draws sit in "lost all / lost more than won / won as much or more / winning 80%"?
**Decision:** Ignored, on both sides of every comparison. 80% is 80% of wins and losses. An opponent never faced shows **no star row at all** rather than three empty ones.
**Cost:** A player who has only ever drawn with an opponent shows no stars, which reads correctly — they have not beaten them — but gives no credit for a hard-won draw. Suppressing the row entirely for unplayed opponents costs a second visual state and stops "not yet attempted" looking identical to "failed".

## D245 — Rematch on a tile is an icon button
**Question:** No button text fits a fifth of a phone's width.
**Decision:** Icon only, with a spoken label.
**Cost:** An unlabelled icon is a guess for a sighted first-time user. Accepted for one control that appears five times in a row, where the alternative is truncated text.

## D246 — The trend graph is trend-coloured and states its change
**Question:** "Green when winning, red when losing" over the last ten games. Per-segment or overall?
**Decision:** Overall — coloured by whether the rating is higher or lower than it was ten games ago — **with the signed change stated beside it** (`+43`). Fewer than two completed games, no graph.
**Cost:** The per-game detail is gone; the graph answers "am I improving", not "what happened in game seven". The number is not optional: trend colour here is *information*, not confirmation, and red-versus-green is the worst pair for the commonest colour vision deficiency, so without it the element is useless to a substantial minority rather than merely weaker.

## D247 — Show more opens a screen
**Question:** Four finished games are shown. Where do the rest go?
**Decision:** A full history screen, not an in-place expansion.
**Cost:** One more screen to build and localise. A four-row section that grows to three hundred rows inside an already-scrolling main screen is worse than a screen built for the job.

## D248 — Relative dates for seven days, then the device format
**Question:** How is the date of a finished game shown?
**Decision:** `today`, `yesterday`, `2 days ago` … `7 days ago`, then the locale's own date format.
**Cost:** Nine strings per language instead of none, and a rule about when "7 days ago" becomes a date. It buys a list that reads as recent activity rather than as a log.

## D249 — The result label sits above the rating change
**Question:** The finished-games section has to give up height for Quests.
**Decision:** Stack the result label above the arrow and number rather than beside it.
**Cost:** A taller, narrower row shape. It is the cheapest vertical saving available on that screen and costs nothing but a layout change.

## D250 — A challenge button in the finished list
**Question:** How does a player replay an opponent they enjoyed?
**Decision:** A challenge button on each finished-game row, alongside the rematch button on each Your Path tile.
**Cost:** Two entry points to the same action. They serve different intents — "again, against this one" and "next, up the ladder" — and both are one tap from the main screen.

## D251 — Quests rank by percentage complete
**Question:** Which four of fifty-three are shown?
**Decision:** The four closest to completion, ties broken by the smaller absolute remainder.
**Cost:** A player far from everything sees four barely-started bars, which is honest but not motivating. Ranking by reward or by recency would each be worse: one shows unreachable prizes, the other shows whatever happened last.

## D252 — A finished game opens straight into review
**Question:** Opening a finished game currently shows a static board.
**Decision:** The scrubber is present and active immediately, with the result shown alongside it.
**Cost:** None worth naming. A finished game has exactly one thing a player came for, and making them find the control first is a step with no purpose.

---

# Group 5 — Scope, platforms and staging

## D253 — The large-screen layout is cancelled
**Question:** v2 specified a landscape layout above a 600 dp breakpoint, with a ticket to build it.
**Decision:** Cancelled, not deferred. **Portrait phone only**, orientation locked. v2's §7.1 breakpoint, its large-screen game screen and the definition-of-done item covering both layouts all go with it.
**Cost:** Tablet and desktop users get a stretched phone layout. It removes a second set of screens to design, build, test at every font scale and keep correct, in service of a form factor nobody has asked for. Bringing it back later is cheaper than carrying it unused, because the layout policy is one breakpoint rather than a structural assumption.

## D254 — Android through 0.2; iOS from 0.3b
**Question:** The additions say the released product is for iPhone and Android. v2 had iOS at 1.0. When does it actually arrive?
**Decision:** Android for 0.1, 0.2 and 0.3a. **iOS joins at 0.3b**, the first public release.
**Cost:** iOS-specific problems are found late, in the release that also opens the contact surface. It buys the critical path: Google Play's twelve-tester, fourteen-day closed-test requirement is the long pole and needs no Apple account, no Apple hardware and no second signing pipeline. The Apple developer account is needed by 0.3b rather than now.

## D255 — Progression ships in 0.1; the meter in 0.4
**Question:** Which release gets the ladder, and which gets the wall?
**Decision:** Points, unlocks, quests, streaks and the trend graph in **0.1**. Subscriptions, the one-time unlock and the meter in **0.4**.
**Cost:** 0.1 grows substantially — it rewrites the main screen, replaces ticket 023, and introduces the first stored non-derived data. It buys the one thing the closed test can measure that nothing else can: a twelve-person, fourteen-day test *is* a retention measurement, and running it against a build without the ladder would validate a product nobody intends to ship. The meter waits because there is nothing to sell before 0.4, so metering earlier is a wall with no door — and a tester limited to three games a day cannot give useful feedback about twenty opponents.

## D256 — Unlock records are in the backup allowlist from 0.1
**Question:** Android auto-backup is on with an explicit allowlist. Does the new record belong in it?
**Decision:** Yes, from 0.1 — not from whenever the cloud arrives.
**Cost:** One more entry in the allowlist and one more thing whose absence must be tested for on restore. The unlock records are the only thing in the app a player cannot regenerate by playing; losing them on a device change loses months of work.

---

# Group 6 — The roster rename

## D257 — Ten opponents change name so the avatars read as a progression
**Question:** The avatars (see [Avatars.md](Avatars.md)) are a single forest world getting steadily more powerful — cute, then animal, then guardian, then mythical, then godlike. Drawn against the roster as it stood, that progression did not hold: a crystal guardian sat below a raven king, a rock giant below a fish. Can the order be fixed without disturbing a calibrated ladder?
**Decision:** Yes, because a name is a label on a slot and nothing else. **Ten names move; no rating, configuration, tier, blurb text or roster index changes.** The new order is:

| Rating | Was | Is now |
|---|---|---|
| 1100 | Finch | **Willow** |
| 1200 | Kestrel | **Vireo** |
| 1250 | Willow | **Finch** |
| 1300 | Ember | **Kestrel** |
| 1400 | Basalt | **Marlin** |
| 1500 | Marlin | **Ember** |
| 1550 | Vireo | **Basalt** |
| 1800 | Quartz | **Corvus** |
| 1900 | Corvus | **Lyra** |
| 2000 | Lyra | **Quartz** |

Pebble, Twig, Mote, Clover, Bramble, Onyx, Sable, Titan, Oracle and Quadrim Prime keep their slots. As a permutation this is a swap (Finch ↔ Willow), a five-cycle (Kestrel → Vireo → Basalt → Marlin → Ember → Kestrel) and a three-cycle (Quartz → Corvus → Lyra → Quartz), which is why a sequential find-and-replace would have collided and the change had to be applied in one atomic pass.

**Three things that had to follow the slot rather than the name:**

- **Blurbs describe behaviour, so they stay with the configuration.** The text now under `blurbVireo` is the one that used to be under `blurbKestrel`, because it describes the 1200 bot and the 1200 bot did not change. The *key* moves with the name; the *value* does not. Getting this backwards would have left every opponent in the Casual and Club tiers described as playing in a way it does not.
- **Prose about a slot follows the slot.** "Basalt's rules and full positional ladder" in §6.4 now reads "Marlin's", because it names the 1400 rules-only bot and that bot is now called Marlin. The same is true of the two accepted Casual-tier inversions, which are now Willow above Vireo and Vireo above Finch — the same three configurations, the same measurement, different labels.
- **Historical documents keep the old names.** The done tickets, `doc/history`, idea-v1, idea-v2 and `codereview-main.md` describe what was true when they were written, and rewriting them would falsify a record. Ticket 009 is still called `009-positional-rules-and-basalt.md` and still built what is now Marlin. This table is how those documents stay readable.

**Cost:** Two real ones. **Stored games name their opponent by id**, so a game recorded against `finch` at 1100 now resolves to a bot called Finch rated 1250 — the rating fold stays correct because each game stores its own anchor rating (§5), but the name and avatar shown for that historical game are wrong. Only closed testers hold such games and only pre-release, so this is accepted rather than migrated; a rename after the first public release would need a stored-id migration and should be treated as a much larger change. Second, **blurbs were written for the old pairings** and now describe the right behaviour under a new name — several land well (Corvus, a corvid, is the one that "remembers what it has already worked out") but a polish pass over the twenty one-liners belongs to whoever owns opponent content, and was deliberately not done here.

---

# Group 7 — v3 read back against the build

D218–D257 were taken against v2 and a set of notes, with the build deliberately out of view. These were taken with it in view: [idea-v3.md](idea-v3.md) read against the twenty-two finished tickets, which is what surfaced two structural problems in §7 that reading the specification on its own did not. The reasoning is in [idea-v3-brainstorming.md](idea-v3-brainstorming.md).

## D258 — What the brainstorming pass is allowed to change

**Question:** Is reading v3 against the build an implementation-planning exercise, or may it reopen v3's product decisions?

**Decision:** Both, and v3 may be amended. Four of the decisions below change what the product does rather than how it is built (D260, D261, D262, D266), and each is folded back into idea-v3.md rather than left as an erratum in a second document.

**Cost:** A specification that has already been reviewed changes again before any of it is built. Accepted because the alternative is a brief that is known to be wrong in two places and a build that follows it anyway — and because both problems (D261, D262) were found by looking at the roster and the seed value, which is exactly the kind of thing only a read against the real numbers catches.

## D259 — The closed-test clock waits for progression

**Question:** Google Play requires twelve testers for fourteen continuous days before granting production access, and ticket 016 starts that clock. §12 puts progression in 0.1, before the closed test. Does the clock wait?

**Decision:** Yes. 0.1 goes to closed test complete, with points, unlocks, quests and streaks.

**Cost:** Weeks of the critical path. This is the same argument §12 already makes — a fourteen-day test *is* a measurement of whether people come back, and shipping the ladder afterwards means the one test that could have validated it ran against a build without it — but it is worth recording as a cost rather than only as a rationale. The mitigation is that ticket 015 is waiting time rather than effort and has no code dependency, so the store and signing work should start immediately and run alongside, not after.

## D260 — Generated avatars in 0.1; the real ones at 0.2

**Question:** `doc/Avatars.md` now holds twenty avatar specifications and D257 renamed ten opponents specifically so the images read as a progression. But §6.4 says to generate avatars from the opponent id, and §12 puts real art in 0.2. Which is true?

**Decision:** §6.4 stands for 0.1. The generated avatars ship to the closed test; the real ones arrive with 0.2's art pass, where §12 already puts them.

**Cost:** The closed test sees placeholder faces on the Your Path tiles, which is the one place §8.4 gives an avatar full tile width and therefore the place the difference is most visible. Accepted because the rename bought what it needed to buy: the names had to be settled before images could be commissioned against them, and they now are. Nothing about D257 is wasted by shipping the art one release later.

## D261 — Per-opponent quests pay at that opponent's rung, not the player's

**Question:** §7.4 pays every quest as a multiple of a win at the player's current rung. Forty of the fifty-three quests are per-opponent. Does that hold?

**Extended by D270**, which found the same defect in the half this decision left alone and applied the same fix there.

**Decision:** No. **Per-opponent quests pay 2ⁱ for opponent *i*** — fixed by the roster index and therefore worth the same whenever they are claimed. The volume and streak families keep the current-rung scaling.

The hole is that the unlock ladder never requires playing the weakest opponents: the cheapest route to Willow's 64 points is four Bramble wins, not sixty-four Pebble wins, which is precisely the self-pricing property §7.3 relies on. So a player has no reason to touch Pebble, Twig, Mote or Clover at all, and their eight quests appreciate untouched. Claimed at rung 15 they pay 262,144 — the whole Titan unlock. At rung 19 they pay 4,194,304 against a roster costing 2,097,088 in total: twice the entire ladder, for eight games against opponents that move at random.

The other thirty-two are far less exposed, because §3.1 assigns the first seat at random and alternates on rematch, so "first win as second player to move" fires on its own about half the time. The reliably bankable set is the eight against opponents the ladder never asks you to play.

**Decision detail:** the two families keep different bases because they measure different things. A first encounter is a property of the opponent, so it is priced by the opponent. A hundred games in a day or a ninety-day streak is a property of recent effort, and §7.4's argument that a flat reward would be ladder-skipping at the bottom and pocket change at the top applies to those and only those.

**Cost:** Two reward rules where §7.4 had one, and the sentence explaining quest rewards is now two sentences. Cheap next to the alternative, which is an economy whose optimal play is to avoid four of the twenty opponents on purpose. A side benefit: forty of the fifty-three awards become constants keyed by roster index, which takes them out of the ordering problem in D265.

## D262 — Your Path centres on the next unlock, not the next rating rung

> **Superseded by D287.** The reasoning below is correct for the *fixed three-tile window* it was written about, and that premise stopped holding when the row became scrollable. Left intact rather than rewritten, because it is the argument D287 had to answer.

**Question:** §8.4 centres the middle tile on "the first opponent rated above the player's current rating". §7.3 unlocks strictly in roster order. Which ladder does the section follow?

**Decision:** The unlock ladder. The middle tile is the **next locked opponent**, with its price and the player's progress toward it; one owned opponent behind it and one locked one ahead.

The two diverge exactly where it matters most. A player seeded at 800 (§5) gets a rating-centred window of Mote (800) / Clover (900) / Bramble (1000) — three opponents they already own — while their next unlock is Willow at 1100, outside the window entirely. §8.4 provides for locked tiles showing their price and progress, but on first launch there is no locked tile on screen, so the price ladder is invisible until the rating climbs into it. The section is titled "where am I, and who is next"; centred on rating it answers the first question twice and the second not at all.

**Cost:** The section no longer shows where the player sits on the *rating* ladder, which was its original job in v2. That reading is not lost — §8.7's tier accordion still opens at the tier containing the player's rating, which is the same information in the place a player goes looking for it. The clamping rule in §8.4 still applies at both ends: a player who has unlocked everything sees the top three, not a hole.

## D263 — Progression maths goes in a new pure package

**Question:** §11.1 says the progression maths belongs in a pure package. `quadrim_engine` or a new one?

**Decision:** A new package, **`quadrim_progression`** — point values, unlock costs, the quest tables, streak evaluation and the star thresholds.

Not the engine, by the engine's own rule: §6.1 says locking is not an engine concern and the catalogue has no `locked` field, because the strength harness plays all twenty against each other and has no business holding an entitlement. Arithmetic about what a player owns and what it cost belongs on the other side of that line. `quadrim_rating` is the precedent — a small pure package for one body of maths that must be exhaustively testable and must not acquire a clock.

**Cost:** A third package to wire into the build gate's purity scan and a third `pubspec`. Small and mechanical. The package does need the roster index, which lives in the engine, so it takes a dependency on `quadrim_engine` — the first inter-package dependency in the project, and one that runs in the allowed direction.

## D264 — A derived balance clamps at zero; unlocks are never revoked

**Question:** §7.6 stores `pricePaid` so that re-tuning a cost cannot retroactively bankrupt someone. Quest awards are derived from the live table, so re-tuning §7.4's multiples changes every player's earned total — and since balance is `earned − Σ pricePaid`, a downward re-tune can drive a balance negative against unlocks already bought. Same failure mode, untreated.

**Decision:** The balance clamps at zero, and unlocks are never revoked — §7.3 already promises the second half. A downward re-tune costs future purchasing power and takes nothing away.

**Cost:** A player who re-tunes into a clamped balance sees no points until they earn past the shortfall, with no explanation available that would not be worse than silence. Accepted because the alternative is a stored award record, which would cost the property in DoD #10 that nothing but the unlock records is stored — a permanent structural cost to insure against a re-tune expected once, before real players exist, if at all.

## D265 — The balance is a merge of two time-ordered streams

**Question:** §7.6 describes points earned as a fold over stored games. Is it?

**Superseded by D270**, which removes the dependency entirely. Kept because the reasoning is what made D270's benefit visible.

**Decision:** No — it is a fold over games **and** unlock records, interleaved in completion order. The signature is `balance(games, unlocks)`, and the specification says so rather than leaving it to be discovered.

Volume and streak awards depend on the rung at the time the quest fired, and the rung comes from the unlock records with their own `unlockedAt`. Games alone cannot say what rung the player was on. D261 shrinks this from fifty-three quests to thirteen but does not remove it.

**Cost:** The fold is more expensive and more intricate than "sum 2ⁱ over wins", and it runs on every main-screen render. Bounded by the same argument §7.2 of the v1 spec makes about statistics — it is a fold over a list already in memory. The ordering key is settled and already exists: `completedAt` with the game id as tie-break (§5), and `unlockedAt` under the same rule.

## D266 — Three vertical slices, and no meter copy in 0.1

**Question:** In what order is §7 built, and what do the volume quests say in a release that has no meter?

**Decision:** Three slices, each crossing every layer: **points and unlocks**, then **quests**, then **streaks**. The package's shape is fixed up front — the point and cost functions, roster-index keying, the `balance(games, unlocks)` signature — so the three passes extend a settled interface rather than renegotiating it.

Bottom-up was the alternative: package, then repository, then screens. Rejected because it finishes with the riskiest part. The arithmetic is small and exhaustively testable whenever it is written; §8.3's six sections on the smallest supported phone at the largest font scale are neither, and slices meet that first.

**And in 0.1 the volume quests carry no restriction copy.** §7.4 says they are subscriber-only by arithmetic because five games in a day exceeds the free cap of three — but the cap arrives at 0.4, so through the entire closed test every tester can complete the whole family and the explanation would be false. The copy ships with the meter, in the release that makes it true.

**Cost:** `quadrim_progression` is written in three passes rather than once, so its tests are extended twice. The 0.4 meter work gains a small UI task it would not otherwise have had.

## D267 — The main screen is split before it grows

**Question:** `home_screen.dart` is 769 lines holding twelve private widget classes, and §8.3 adds a trend graph, a balance, a Your Path row and a quests section while rewriting the finished-game row. Extend it or restructure it?

**Decision:** Split first, as its own step with no behaviour change. `app/lib/home/` gains `rating_card.dart`, `your_path.dart`, `quests_section.dart`, `finished_games.dart` and `active_games.dart`; `home_screen.dart` becomes the composition and the state feeding it. The new sections then arrive as new files instead of as growth in the file every remaining ticket touches.

The split is close to mechanical — the private widget classes already in the file are the extraction boundaries. `_OpponentSection` is deleted rather than moved, since Your Path replaces it (§8.4), but `HomeSummary.byOpponent` is kept: Your Path's tiles need exactly the per-opponent records it already produces, plus the locked ones the catalogue supplies.

**Cost:** One commit that moves code and changes nothing, which is the kind of commit that looks like wasted effort in a log. It is the opposite: it is what makes the four diffs after it legible. Rewriting the main screen outright was the other option and was rejected — the rating card and the games lists have the same specification in v3 as in v2, and discarding working, reviewed, accessibility-tested code for them buys nothing.

## D268 — The Casual inversion is now a user-visible defect, and still a 1.0 fix

**Question:** §14 records that Willow measures about 33 points above Vireo and Vireo about 50 above Finch, and assigns the fix to the 1.0 roster revision. Does progression change that disposition?

**Decision:** The disposition does not change. The reason does, and §14 is rewritten to say so.

Under v2 this was a discrepancy between two numbers, one of which nobody could see. Under §7 the roster index sets both the unlock price and the win payout, so across three consecutive rungs a player now pays **increasing prices for decreasing strength**: Willow costs 64 and is the strongest of the three, Vireo costs 128, Finch costs 256 and is the weakest by about 83 points. Three prices are about to be displayed as a public claim about relative difficulty, and for these three the claim is false.

The farming vector it opens is real but bounded, and the arithmetic is worth doing rather than assuming. Beating Finch pays 128 against Kestrel's 256, so 1,024 points is eight Finch wins or four Kestrel wins; at roughly 1170 effective against a published 1300, a player near 1300 needs about twelve games for the first and about eight for the second. Kestrel remains the faster route and §7.3's self-pricing property survives. What does not survive is legibility.

Re-pricing by measured strength is not available: §6.4 pins pricing to roster index and D144 pins ratings as anchors, so a price that followed measurement would be a rating change wearing a different name.

**Cost:** 0.1 ships with three prices that misdescribe three opponents, and the closed test will see them. Accepted, because the fix is a roster change and a roster change invalidates every calibration run and every stored game's anchor — which is exactly why §14 put it at 1.0. What this decision buys is that the 1.0 revision now has a symptom attached rather than only a measurement, which is the strongest argument yet for scheduling it early rather than late.

## D269 — Disposition of the seven open tickets

**Question:** v3 contradicts three of the tickets still open. What happens to each?

**Decision:**

| Ticket | Disposition |
|---|---|
| **015** Store accounts and release signing | Unchanged, and started immediately — D259 puts the fourteen-day clock behind progression, which makes the waiting-time work more urgent, not less |
| **016** Closed test | Unchanged in content; sequenced behind the progression tickets |
| **017** Large-screen landscape layout | **Cancelled** by §8.1 (D253). Moved to `done/` with a cancellation note rather than deleted — the reasoning is worth keeping |
| **021** Accessibility audit | Content unchanged; blockers re-pointed, since it currently lists 017 and 023 and neither will exist. Gains a largest-font-scale test over §8.3's six sections |
| **022** Release 0.1 readiness | Unchanged; its "every other ticket" dependency now includes the new ones |
| **023** Per-opponent milestones | **Absorbed** into the quest system by §7.4 (D240). The work survives as forty of the fifty-three quests, and its "no new stored shape" property survives with it |
| **024** Closed-test survey | Content unchanged and considerably more valuable — §7.7 names median time to each unlock and the rung at which players stop as the two signals to watch, and this survey is the only instrument that can see them. Both are added to it |

Five new tickets, in build order: **030** main-screen decomposition (D267); **031** `quadrim_progression` and the first slice — points, unlock records, balance, Your Path, lock state and the unlock confirmation; **032** quests; **033** streaks; **034** the trend graph, the finished-game row changes, the end-of-game panel and the portrait lock.

**Cost:** Two tickets that were written, reviewed and ready to build are cancelled or absorbed without a line of their code existing. That is the cheapest possible moment for it to happen, and it is what a specification pass before implementation is for. Ticket 031 is the largest of the five and could split along the unlock/display seam if it proves unwieldy; it is left whole because the first slice is only a slice when a player can actually buy something.

## D270 — No quest reward anywhere depends on the player's own rung

**Question:** D261 repriced the forty per-opponent quests by the opponent and left the thirteen volume and streak quests scaling with the player's current rung, on the argument that those measure recent effort rather than a first meeting. Does that hold?

**Decision:** No. **Every quest is priced by the opponents it was earned against.** One rule, all four families, and it is the rule §7.2 already applies to a plain win. This extends D261 and supersedes D265.

- A per-opponent quest pays 2ⁱ for opponent *i*.
- A volume or streak quest pays its multiple of a win against the **average roster index of the qualifying games, rounded to the nearest opponent**.

D261 fixed one half of the problem and left the other half in place. A hundred games in a day pays four wins-worth; priced at the player's rung, a hundred instant Pebble games at rung 17 pay 524,288 points — four Titan wins for an afternoon of tapping. §7.4 had already noticed this and called the volume family "the only remaining farm vector", then leaned on the paywall to contain it. That containment does not exist: the meter arrives at 0.4 and progression ships at 0.1, so for three releases nothing bounds it, and even afterwards it only bounds it to people who have paid. §7.3's entire shape exists so that grinding downward prices itself out without a rule; a quest priced by the player's height reintroduced the exploit in the one place nobody was checking.

**Average the index, not the payout.** Because payouts double, an arithmetic mean of them is dominated by the strongest single game: nineteen Pebble games and one Titan game average 6,555 points, pricing twenty games at roughly a Corvus win on the strength of one. The mean of the *index*, exponentiated — a geometric mean — pays 2 for the same set. Rounding the mean index to the nearest opponent keeps the result nameable, so the interface can say *your twenty games averaged Kestrel*; a fractional exponent is a correct number that cannot be put in a sentence.

**Cost:** Two real ones, and a large refund.

*The streak rungs are worth much less to a casual player.* A ninety-day streak kept alive with one easy game a day now pays a handful of points instead of eight wins-worth. That is the intended answer — showing up is what the streak measures, but what you showed up *to* is what the points measure — and it is a genuine reduction in what the longest rungs are worth to the player most likely to reach them. Worth watching under §7.7 alongside the rest of the table.

*Volume and streak awards now need the games that earned them, not just a count.* A quest can no longer fire off a tally; it has to know which games qualified so it can average them. In practice both folds already walk the game list.

*And the refund:* **points earned becomes a fold over the games alone.** Under a current-rung rule the award depended on what was unlocked when it fired, so the fold had to interleave games with unlock records in time order — the two-stream merge D265 described, with an ordering hazard on both sides and a balance that could not be checked against the game list by itself. That is now gone. §3's "everything derives from the move list" holds for the whole of points earned, and §7.6's single stored record is consulted only for what was *spent*.

---

# Group 8 — The specification

Taken while turning [idea-v3.md](idea-v3.md) and [idea-v3-brainstorming.md](idea-v3-brainstorming.md) into [idea-v3-spec.md](idea-v3-spec.md).

## D271 — The v3 spec is a successor, and preserves the v1 spec's numbering

**Question:** idea-v1-spec.md has twelve numbered sections and eight criterion prefixes (E, F, U, T, D, R, S, G). Does the v3 spec start clean?

**Decision:** No. **Identical section numbers and identical criterion ids.** §7 is still Exposed Endpoints, §8 is still Data, §8.3 is still the game document, §11 is still Acceptance Criteria. New material is appended inside the existing structure.

The reason is that both are cited from things that already exist and would otherwise silently start pointing at the wrong requirement. Source comments carry `spec §8.3`, `spec §8.6`, `spec §9.5`, `spec §9.12`, `spec E7`, `criterion S4`, `spec D2/S2` and `spec S1/F13`; twenty-two completed tickets cite the same ids. A renumbering would be a silent, repository-wide invalidation with no compiler to catch it.

**Cost:** The v3 spec inherits a structure designed for a smaller product. Progression has no natural home in a layout that predates it, so it is spread across §7.3 (the package), §8.8 (the one stored record) and §11.6 (a new criteria section) rather than sitting in one place the way §7 of idea-v3.md does. Accepted: a reader who wants progression whole reads the brief, and a reader who wants it testable reads the spec.

## D272 — A changed criterion keeps its id and changes its text

**Question:** F9 says a new player's rating is 1200; D226 made it 800. U10 requires a large-screen layout that D253 cancelled. New id, or same id with new text?

**Decision:** **Same id, new text**, marked ▲ in the spec. F9 is still "a new player with no history has the seed rating" and the seed changed. U10 is still "the layout policy holds" and the policy changed. A comment citing F9 wants whatever the seed rule currently is.

New criteria are appended and marked ＋. Retired criteria would keep their id and be struck rather than reused — none are, so far.

**Cost:** The criteria tables no longer read as a clean list; they carry two kinds of annotation and a note under §11.1 explaining that E8–E10 name different opponents than they used to. That is the honest record, and it is cheaper than a citation that resolves to the wrong requirement.

## D273 — Progression criteria take a new `P` prefix

**Question:** Where do the twenty-two progression criteria go — inside F for game flow, D for data, or their own section?

**Decision:** **A new §11.6 with a `P` prefix**, and the release gates and security sections shift from §11.6/§11.7 to §11.7/§11.8. Progression is neither game flow nor data: it spans a pure package, a repository award point, a stored record and four screens, and every one of its interesting properties is arithmetic that no other section tests.

**Cost:** Two section numbers move, so `§11.6` in an old document now means release gates where it used to mean the same thing — the *criterion ids* R1–R13 are unambiguous but the section number is not. Nothing in the source cites `§11.6` or `§11.7`, only `§8.x` and `§9.x`, which is why this was affordable and why the section numbers in §7–§9 were not.

## D274 — Three clauses of the v1 spec prompt do not carry to v3

**Question:** The prompt that produced this spec was the v1 prompt with the filenames changed. Three of its clauses no longer refer to anything that exists. Follow them literally, or resolve them?

**Decision:** Resolved, with the user's confirmation on each, and recorded here because two of them would have destroyed finished work.

- **"Follow recommended strategy A from the brainstorming document."** There is no strategy A in idea-v3-brainstorming.md. It has approaches A/B/C for building §7 and M1/M2/M3 for the main screen, and **approach A — bottom-up — is the one that document explicitly rejects**. The chosen approaches are B (three vertical slices) and M2 (split the main screen before growing it), per D266 and D267. "Strategy A" is from the *v1* brainstorming document, which had lettered strategies of its own.
- **"Use the suggested bots Pebble, Mote, Bramble, Kestrel, Marlin and Onyx."** That is v1's six-bot roster, from before the twenty were built. All twenty exist, are calibrated, and are what §7 of idea-v3.md prices over — a win pays 2ⁱ for roster index *i*, an unlock costs 2ⁱ⁺¹, the whole roster is exactly sixty wins, and the free tier is "everything rated 1000 and below". Cutting to six would have deleted fourteen implemented opponents and required rewriting the economy from scratch.
- **"Use the Matt Skills to-spec skill."** Not available in this environment; the v1 spec's §12.5 recorded its own deviations from it. The requested section list — goal, scope, non-goals, exposed endpoints, data, acceptance criteria — is followed directly instead.

**Cost:** None to the work, but a general lesson worth keeping: **a prompt reused across document versions carries its old assumptions silently.** Two of these three would have passed a casual reading and destroyed work, and neither would have failed a build. The v1 spec has the same hazard in the other direction — its §12.1 opens "Strategy A was chosen", meaning v1's strategy A, which is not this document's approach A.

---

# Group 9 — The ticket breakdown

Taken while cutting [idea-v3-spec.md](idea-v3-spec.md) into `doc/tickets/`.

## D275 — The breakdown covers the 0.1 remainder only

**Question:** "Not yet implemented" in the spec includes 0.3a, 0.3b and 0.4 — accounts, the cloud repository, invites, push, chat, the human rating, server validation, subscriptions and the meter. Does the breakdown reach them?

**Decision:** No. **Six new tickets, all 0.1**, plus the five already-open process tickets. Later releases are cut when their release is next, exactly as 0.1 was.

Tickets 001–029 were all 0.1 and that was not an accident: a ticket written against a stack whose details are not yet chosen is a ticket that will be rewritten before it is built, and the rewriting costs more than the deferral. 0.3a's Firestore schema in particular is specified as a *contract* in spec §7.6 — the same flow tests as the local repository — precisely so that it can be designed natively when it arrives rather than being pre-cut now against guesses.

**Cost:** The backlog does not show the whole road. Someone looking at `doc/tickets/` sees eleven items and the release plan says there are four releases after this one. The spec's §4.1 and §7.6 are where that shape lives, and they are linked from the tickets that need them.

## D276 — Ticket 031 splits along the unlock/display seam

**Question:** Spec §12 proposed 031 as one ticket covering the package, points, the unlock record, the purchase flow, Your Path, lock state and the confirmation, noting it "could split if it proves unwieldy". Small and independently shippable was asked for. Does it split?

**Decision:** Yes, into two, and the four following tickets renumber to 032–035.

- **031** — the package, points earned, the balance on the rating card
- **032** — the unlock record, the purchase, lock state, Your Path, the confirmation

Both ship without regression. That is the part worth checking rather than assuming: nothing is locked today, so 031 changes no opponent's availability and is purely additive. The counter-argument was D266's — a slice is only a slice when a player can actually buy something, and 031 alone shows a number with nothing to spend it on. That argument was about **slices versus bottom-up**, not about how thick a slice must be, and 031 is still a vertical slice: a pure package, a repository read and a screen, in one ticket.

**Cost:** One release-shaped moment is split across two commits, so there is a build in which points accumulate and buy nothing. Acceptable for a closed test that has not started. The three-way split — package alone, then purchase, then display — was rejected: the middle ticket would have had no screen and the last no logic, which is approach A wearing a different name.

## D277 — The by-opponent section survives until Your Path replaces it

**Question:** Spec §12 put the deletion of `_OpponentSection` in ticket 030, the decomposition. Your Path arrives in 032. What happens to the main screen in between?

**Decision:** **Extract it in 030, delete it in 032.** Spec §12's row for ticket 030 is corrected accordingly.

Deleting it during the decomposition would leave the main screen with a hole for two tickets — a visible regression in exchange for nothing, in the one ticket whose entire discipline is that it changes no behaviour. It would also have made 030 unreviewable as a move: a reviewer checking that every hunk is a move cannot also be checking that one deletion is intentional.

**Cost:** One file is created in 030 and removed in 032, which shows in the log as churn. Half a commit's worth, against a main screen that stays whole throughout.

---

# Group 10 — Implementation

## D278 — The seed moves to 800 with no migration, and the re-derived ratings stand

**Question:** D226 moved the computer seed from 1200 to 800, ticket 027 had already shipped 1200, and D269's breakdown cut no ticket for the change. The rating is a fold with nothing stored, so changing the constant silently re-derives every existing rating (D227). Is that acceptable, or does it need a migration?

**Decision:** Acceptable. The constant changes, the fold does what it does, and **no migration is written**. Ticket 036.

The owner's reasoning, recorded because it is a judgement rather than a derivation: a player who had actually started at 800 would have gained slightly *more* per win than the stored games recorded, since the Elo step is larger the further you sit below your opponent. So the re-fold understates such a player a little. Against twelve closed testers who do not yet exist, that is noise, and preserving numbers nobody has seen would cost more than the numbers are worth.

**The constant keeps its name.** `kSeedRating` is now documented as the *computer* ladder's seed. The human ladder's 1000 arrives at 0.4 with its own constant rather than sharing this one, because the human rating is not this fold at all — Elo is not separable per player, so recomputing it is a global chronological replay across every account (spec §7.2).

**Cost:** Real, and larger than the one-line change suggests. **Fourteen tests changed**, none of them broken and all of them newly wrong about what they were asserting, because moving the seed moves where a new player is *standing* on the ladder:

- The tier accordion opens at the tier nearest the player, so a seeded player now lands on **Novice** (Mote is rated 800 exactly) where they used to land on Casual. Four tests toggled a section that is now already open, and so closed the very list they were about to look inside.
- A seeded player's fair-match band moved with them: 1250 used to read "even" and now reads "above your level", while 900 reads even. That is the change working, not a regression.
- A win over a 100-rated opponent used to round away to a zero rating step; from 800 the same win pays 1. The zero case is still reachable — it now takes a player who has climbed well clear of the bottom of the roster and then beats Pebble — and the test reaches it the way a player actually would.

The general lesson is the one D227 already states and this is the first instance of: the derived rating's great virtue, that nothing can drift, is the same property that makes any change to its constants a silent rewrite of everyone's history. It was affordable exactly once.

---

## D279 — A quest that fires must pay at least one point

**Question:** The volume family's cheapest rung pays a **quarter** of a win (§7.4's table: 5 games in a day is worth ¼). Priced by the opposition, five Pebble games are a quarter of a point, and integer arithmetic rounds that to nothing. What does the interface do with a quest that announces itself and pays zero?

**Decision:** **Every quest that fires pays at least one point.** The award is `multipleQuarters × 2^index ÷ 4`, floored, and clamped up to 1.

Zero is arithmetically honest and reads as a defect. An achievement that arrives with "+0" beside it is indistinguishable from a bug in the awarding code, and a player who saw it would be right to report one.

The clamp cannot be farmed, because **a quest fires exactly once**. It is worth one point to the player who does five trivial games on their first day, and never again.

**Cost:** The ¼ and ½ rungs are worth slightly more than the table says at the bottom of the roster — one point instead of a quarter or a half. Only the two lowest multiples against the two weakest opponents are affected; above index 2 the arithmetic is exact.

---

## D280 — Quest multiples are stored in quarters of a win

**Question:** Two of the five volume rungs pay a fraction of a win. Store the multiple as a `double`, or as a rational?

**Decision:** **An integer numerator over a fixed denominator of four** — `multipleQuarters`. Volume: 1, 2, 4, 8, 16. Streak: 4, 8, 16, 32, 48, 64, 96, 128. Both per-opponent families: 4, which is exactly one win against the opponent they name, so all four families run through one award function rather than two.

A `double` multiple would put a floating-point rounding argument between a re-tune and a payout, in the one part of this project where the arithmetic is the product. §7.7 says these numbers are the most likely in the document to be wrong and the first to instrument; whoever changes them should be changing an integer.

**Cost:** A denominator that has to stay 4. If a future rung needs a third of a win, the constant moves and every multiple is rescaled — mechanical, and the test file pins the payouts rather than the numerators, so it would catch a rescale done wrongly.

---

## D281 — Tied quests are ranked by roster order, not by id

**Question:** The main screen shows the four quests closest to completion, ranked by percentage complete with ties going to the smaller absolute remainder (ticket 033). On a fresh install **forty** per-opponent quests are tied on both rules — all at 0 of 1. What breaks the tie?

**Decision:** **Roster order**, weakest opponent first, with the id as a final tie-break only so the list cannot reshuffle between two identical rebuilds.

The first implementation used the id alone, which is alphabetical: it opened the section with Basalt, Bramble, Clover and Corvus — four opponents picked by spelling, three of them locked. Roster order shows the player the cheapest things they could actually go and do next, which is the question the section exists to answer.

**Cost:** None measured. It is a comparator clause, and the ordering is pinned by a test that names the four it expects.

**A related observation that is not a defect.** One finished game puts the volume family at 1 of 5 — twenty per cent — which outranks every per-opponent quest still at zero, so a player who has played exactly one game sees four *games in one day* rungs and nothing else. That is the ticket's ranking rule working exactly as written, and the section diversifies as soon as anything else has progress on it. If it still reads badly with the whole main screen assembled, it belongs to ticket 035's restructure rather than to a rule change here.

---

## D282 — A streak rung's progress is the current streak; its achievement is the best run ever

**Question:** The volume family shows the **best day the player ever had**, so a rung already cleared cannot un-clear itself. Should the streak family work the same way and show the longest run ever?

**Decision:** **No — the two halves are read from different places.** A rung is **achieved** from the earliest run that ever reached it, so it fires once and stays fired when a streak later breaks. **Progress** on a rung not yet achieved is the streak the player is on **right now**.

The asymmetry is the point. "The best day you ever had" is the only reading of a volume rung that means anything, because a day is over and cannot be resumed. A streak is the opposite: it is a thing you are currently holding, and after it lapses you are genuinely back at zero. Showing "29 of 30" to somebody whose run broke last month would be a lie about the quantity being measured, and the one number a streak display exists to be honest about.

**Cost:** One family's progress falls, which no other progress in this app does. A player who lapses sees a number go down. That is what happened.

---

## D283 — An ambiguous day is bridged when less than 48 hours passed

**Question:** Ticket 034 asks that the reset be correct across a time-zone change in both directions and that an ambiguous boundary be evaluated **generously** — never break a streak any reasonable reading would have kept. It also says, two paragraphs earlier, that a missed day resets to zero with **no forgiveness**. Those pull in opposite directions. Where is the line?

**Decision:** **A gap of exactly one calendar day is bridged when the games either side of it are less than 48 hours apart in real time.** Anything longer, or a gap of two days or more, breaks the streak.

The mechanism this exists for is precise. `toLocal()` renders the **whole** history in the device's *current* zone, so moving zones shifts every stored game by the same offset — up to about twenty-six hours. Games near midnight cross into the neighbouring day while the rest do not, and the result is a one-day hole in a history the player lived without a gap. Two games less than 48 hours apart cannot span a day somebody was absent for, so the bridge can never forgive a real miss — which is what keeps it consistent with "no forgiveness" rather than an exception to it.

It also catches the honest near-miss the same way: a game at 23:30 on Monday and the next at 00:15 on Wednesday is 24 hours and 45 minutes of real time, and "you missed Tuesday" is technically true and the wrong thing to tell that player.

The **head** is generous separately and for a different reason: a streak is alive while the last day played is today *or yesterday*, because a player who has not opened the app yet today has not missed anything, and telling them their streak is zero before they have had a chance is the surest way to make it true.

**Cost:** A rule with a constant in it — `kAmbiguousDayWindow` — where the rest of the streak arithmetic is pure calendar. It is named, documented with the mechanism it defends against, and pinned by three tests: it bridges the artefact, it refuses a sixty-hour gap, and it never bridges two days.

**A consequence worth stating.** A bridged day *counts* toward the streak's length, so the run is measured from its first calendar day to its last. That is the generous reading applied consistently; counting the days played and not the days spanned would break a streak's length instead of the streak itself, which is the same unkindness one level down.

---

## D284 — The main screen shows ten finished games; the rest is a screen, not an expansion

**Question:** Ticket 035 says **Show more** must open a full history screen rather than expand the list in place, but does not say how many the main screen shows first.

**Decision:** **Ten**, then a *Show more* button that pushes `HistoryScreen`.

Ten is one screenful on a phone and roughly a week of ordinary play, so the common case never sees the button at all. The reason it is a screen and not an expansion is the one the ticket gives and worth restating: the main screen now carries six sections, and expanding a list in the middle of it pushes the primary button below everything and leaves the player scrolling back up past all six to reach it. A pushed route also comes with a back button, which is the affordance for "I have finished looking at this" that an expanded section does not have.

**Cost:** A second widget that renders finished games. It takes the list and the deltas from the caller rather than watching the repository itself, so there is still exactly one subscription and one fold.

---

## D285 — The trend graph declares no semantics; the rating card announces it

**Question:** The graph is a line and a number. The line says nothing to a screen reader, so the change must be spoken. Where?

**Decision:** **In the rating card's single label**, and the graph declares nothing of its own.

Not a style preference — the first implementation gave the graph its own `Semantics(container: true, label: …)` and it was **silently dead**, because `RatingCard` wraps its whole body in an `ExcludeSemantics` and re-says its facts once in one announcement. A node declared inside that exclusion is swallowed, and the failure mode is the quiet one: the widget looks right, the test for the label fails, and nothing else does.

So the graph is `ExcludeSemantics` like the rest of the card's body, and the card's label gains the change — the *same* signed number the sighted reader sees beside the line, so neither reader is told something the other is not.

**The general trap, worth carrying forward:** in this codebase several containers announce themselves and exclude their children. Any new widget that lands inside one and wants to speak must be given a line in the container's label instead; declaring semantics locally compiles, renders, and says nothing.

**Cost:** The card's label is now five facts long. That is the design it has had since D192, and the alternative — five stops for a screen reader on one card — is worse.

---

## D286 — The unlock offer fires on the crossing game, and only from the latest one

**Question:** Ticket 035 asks the end-of-game panel to offer the next unlock "if the win just paid for it". Which wins count?

**Decision:** Two conditions, both necessary.

**It must be the crossing game.** The balance before this game is below the price and after it is at or above. Offering whenever the player merely *stands* above the price would repeat the offer after every subsequent win, which is an advertisement rather than a prompt.

**It must be the most recent finished game.** Opening an older game out of the history list would otherwise make an offer on the strength of points that everything played since had already spent or surpassed — true of a moment the player has left. This is the same distinction the rating change makes with its prefix fold, applied to a different quantity.

**Cost:** One read of the unlock records per finished game shown, and a rule with two clauses where one would have looked sufficient. Both clauses have a test; the second one's test opens a game with a later game after it and asserts silence.

---

## D287 — Your Path rests on the rating ladder, because scrolling removed the reason it could not

**Question:** D262 centred Your Path's middle tile on the **next unlock** and gave a specific reason: a fixed window centred on the player's *rating* would show a player seeded at 800 three opponents they already own, with their next unlock outside the window entirely, so the price ladder would be invisible on first launch. The owner has now asked for the middle tile to be the first opponent above the player's rating, and for the row to scroll. Does D262 still hold?

**Decision:** **No, and the reason it fails is the scrolling, not the centring.** The row now scrolls horizontally over the whole roster and *rests* on the lowest-rated opponent rated strictly above the player's rating.

D262's argument was never about which ladder is more interesting. It was about a **fixed** window: with three tiles and nothing beyond them, whatever the window is centred on is the only thing that exists, so centring on the rating genuinely hid the prices. A scrollable row does not have that property. The unlock ladder is one swipe right — and, unlike the old design, it is reachable from *every* point on the roster instead of only where the two ladders happen to coincide.

What the resting position buys is an answer to "where am I", which is the question a player asks first and the one a rating answers. The old design answered "who is next" twice and "where am I" not at all — the mirror image of the complaint D262 made about its own alternative.

**Rated strictly above, so the centre is always a step up.** Mote is rated exactly 800 and a player seeded at 800 rests on Clover at 900, with Mote one tile to the left. An even match is not "next", and the even-match marker (§5.1) already says what Mote is.

**Cost:** The next unlock is no longer guaranteed to be on screen without scrolling, which is the thing D262 was protecting. Two things carry it instead: a locked tile still shows its price and progress wherever it appears, and the end-of-game panel offers the unlock outright at the moment it becomes affordable (D286) — which is a better moment than any resting position, because it is the moment the player earned it.

**What this cost the build:** ticket 032's Your Path tests asserted the old resting position by name, including one written specifically to pin D262. They are rewritten rather than deleted, and the D262 test becomes the D287 test — the same fixture, the opposite expectation, and a comment saying which decision it now belongs to.

---

## D288 — The opponent detail page, and why opponent selection does not use it

**Question:** Tapping a Your Path tile opens a detail page: avatar large at the top, then everything known about that opponent, then one action. Opponent selection (§8.7) already lists all twenty with the same facts and starts a game on tap. Should it route through the detail page too, for one consistent path to every opponent?

**Decision:** **No.** Selection keeps starting the game on tap; the detail page is reached from Your Path.

The two screens are entered with different intentions. §8.7 is behind the *new game* button, so the player has already said what they want to do and every extra screen is a tax on the commonest path in the app. Your Path is on the main screen, where the player is looking rather than deciding, and a tile is a summary that ought to expand into something.

**One action at the bottom, never none.** Unlocked, it starts a game. Locked, it shows the price, the progress and an unlock button, reaching the same confirmation the other two routes reach — including the "unbeatable when it moves first" warning D181 requires for Oracle and Quadrim Prime. A page a player can reach and do nothing on is a dead end, and the locked opponents are exactly the ones they came to look at.

**It stores nothing and derives everything** — the catalogue for the facts, the existing folds for the record and the balance. It adds a place to put what is already known, at a size worth looking at, and no new source of truth.

**Cost:** A third route into the purchase flow. Mitigated by all three calling the same `runUnlock`, which is where the confirmation and the warning live; the alternative — a page that shows a price and cannot act on it — trades a real dead end for an imagined risk.

---

## D289 — The trend graph measures from a real baseline, and draws it

**Question:** The ten-game trend states its change as a signed number beside the line. `computerRatingSeries` holds the rating **after** each game. Measured from the first entry of the window, what is the number?

**Decision:** Wrong, and it was shipped that way in ticket 035. The change is now measured from a **baseline** — the rating held *before* the window — which is the seed when the window reaches back to the start of the player's history. The baseline is also **plotted**, as the line's first point.

The defect was found by the owner on the running app: a player with a couple of games saw a number that did not include their first one. The first entry of `series` already contains the first game's result, so subtracting it removes exactly that game from the total. A player who had won once was told their last ten games were worth nothing.

**The same slip sat at exactly ten games**, in a place nobody would have looked: the test was `series.length <= kTrendGames`, so a window of exactly ten reached for a non-existent eleventh entry, found none, and fell back to measuring from within itself. It is `> kTrendGames` now, and a test names the case.

**And drawing the baseline is part of the fix, not a flourish.** Above ten games the old code measured from a point it never plotted, so the rise the eye took off the line and the number printed beside it disagreed by exactly the first game in the window — in the direction that makes a good run look flat. The line now starts where the measurement starts. That is eleven plotted points for a ten-game window: the baseline, then one per game, so criterion U15's "one dot per completed game" still holds and the origin is visible rather than implied.

**Cost:** One extra point on the line, and a graph that starts at the seed for a player's first nine games rather than at their first result — which is the honest picture, since the seed is where they actually started.

**What this says about the tests that missed it.** Ticket 035's trend tests asserted the *presence* of a signed number and its sign, never its value against an independently computed one. The three tests added here each compute the expected figure from the series and the seed, and one of them asserts that the right answer and the old wrong answer are different numbers — so it cannot pass by accident if the baseline is dropped again.

---

## D290 — The art pipeline is a script that is run by hand, and its output is committed

**Question:** `doc/designs/` holds 65 MB of source PNGs: twenty 1254×1254 opponent portraits, a background, a cube, a logo, three plaques. None of it can ship as-is. Where does the conversion live, and does `check.sh` verify it the way it verifies `linegen` and `bookgen`?

**Decision:** `tools/artgen/artgen.py`, run by hand, output committed, **not** staleness-checked.

The repository's convention is that generated sources are regenerated by the gate and the build fails if the committed copy has drifted. That convention is right for `winning_lines.g.dart` and `strategy_book.g.dart` because they are *derived logic* — a stale one is a wrong one, and the check is what makes "the book matches the dictionary it came from" a fact rather than a promise.

Images are not that. Re-encoding the same picture with a different Pillow build produces different bytes, so a byte-comparison gate would fail on a library upgrade while nothing was actually wrong. A gate that cries wolf is a gate people learn to skip, and this repository has exactly two that must never be skipped.

**What is checked instead is the failure that would reach a player**: `art_assets_test.dart` walks `opponentCatalogue` and asserts that every one of the twenty resolves to real bytes in the bundle, that the six named assets resolve, that the fonts and their licences are inside the APK, and that the whole budget stays under 3 MB. `pubspec.yaml` declares the art by directory — convenient, because a new opponent's portrait is a file drop, and silent, because nothing objects to a directory missing a file. The test is what objects.

**Python rather than Dart**, which is the one place this ticket steps outside the repository's language. Dart image processing needs a package dependency and a `pub get` to do what Pillow does out of the box, and the script never runs in CI, so its runtime is a developer's convenience rather than part of the build. `tool/check.sh` is already bash.

**Two of the twenty source files are misspelt** — `peble.png` and `quarts.png` against catalogue ids `pebble` and `quartz`. The mapping lives in the script rather than in a rename, so the source folder still matches what was delivered, and a test names both cases.

**Cost:** Somebody can change the source art and forget to re-run the script, and nothing will tell them. Mitigated by the fact that they would also have to not look at the app. The 65 MB of source stays in the repository, which is what makes the pipeline re-runnable at all.

---

## D291 — A locked opponent is a silhouette made by a colour filter, not a second file

**Question:** Locked opponents should show a shadow rather than a face. Twenty more files, or a runtime effect?

**Decision:** A runtime `ColorFilter.matrix` whose last row passes alpha through untouched and whose first three replace the colour with a constant. One filter, the same twenty files.

This is only possible because `artgen` cuts the portraits to a circle. The source is a 1254×1254 opaque square with the character inscribed in a disc — **thirteen have white corners and seven have black**, which is the kind of inconsistency that would otherwise leak into the UI as "some avatars have a light halo". Masking the disc discards both, and having real alpha is what lets a colour filter produce a shape rather than a coloured square.

The alternative was baking twenty silhouettes at build time: twice the files, twice the download, and a second thing to keep in step with the catalogue.

**It is a veil at 86%, not a silhouette at 100%, and the difference was found on the device.** A constant-colour matrix replaces every pixel, and these portraits are full-bleed circular *scenes* rather than subjects cut out on transparency — so there is no outline in the file to silhouette, and Kestrel’s locked page showed a flat dark disc that read as a picture which had failed to load. Laying the panel green over at 86% leaves the creature visible as a shape in the gloom, which is what the mockup draws. **A padlock sits on top**, because “dark” is not a word: the state is carried in the semantics label of every row and tile that draws one, and the lock is what carries it to everyone else.

**Cost:** A `ColorFiltered` layer on each locked portrait. Negligible at the sizes drawn, and the roster is twenty.

---

## D292 — Three plaques carry English lettering in every locale

> **Superseded by D297.** The signs were redrawn without their lettering, so the app writes it and it is localised after all. What follows is kept because the reasoning was sound on the art that existed at the time: the alternative on the table was retouching wood grain from a script, and that was correctly refused.

**Question:** `new_game.png`, `your-path.png` and `tutorial.png` have their words painted into the wood — "NEW GAME / Start a new adventure", "YOUR PATH", "Tutorial". The Dutch strings differ (`Nieuwe partij`, `Jouw pad`, `Uitleg`), and `check.sh` exists to stop user-facing text escaping l10n. What ships?

**Decision:** The artwork ships as drawn, in both locales. Asked and answered by the owner, with the alternatives on the table.

The alternatives were: inpaint the wood grain where the words sit and render the localised string over it, or fall back to plain buttons in Dutch. The first is retouching textured wood from a script and would have looked patched — "Tutorial" is large, diagonal, and over grain. The second gives the Dutch build a visibly worse screen than the English one.

**The accessible name is still localised.** `Plaque` takes a `label`, does not draw it, and hands it to `Semantics`, so a Dutch screen reader says "Nieuwe partij" over a plank that reads NEW GAME. Your Path's carved sign is wrapped in `Semantics(header: true, label: …)` around an `ExcludeSemantics`, so the heading survives as a heading in both languages while being a picture on screen — and two tests assert exactly that, because it is the property most easily lost in a later edit.

**Cost:** A Dutch player reads English on three controls. Recorded as a ceiling owned by a later art pass, not by this ticket. It also cost the test suite its `find.text('New game')` idiom; `test/plaques.dart` replaces it with a finder over `Plaque.label`, which fails if the accessible name is ever dropped — the failure worth having.

---

## D293 — One theme, and the theme picker goes with it

**Question:** The app had a seeded dark/light pair and a settings control to choose between them and the device. The forest design is one painting. What happens to the pair, and to the control?

**Decision:** One `ThemeData`, handed to both `theme` and `darkTheme`. The settings picker is deleted; the stored `theme` field is left untouched.

There is no second painting. The background is a specific sunlit forest and the panels are dark green on parchment; a dark mode would need a second background image and a second palette, which is a design job nobody has done. Handing `darkTheme` something different would give a device set to dark a half-inverted version of a design that was never inverted.

**The picker had to go with it**, because all three of its options would then select the same screen, and a control that does nothing is worse than no control — it makes the player doubt the ones that do. A test now asserts that the two theme slots are the same object, so a later edit that reintroduces a second theme fails loudly rather than silently shipping half a design.

**The stored field survives** rather than being migrated away, so 0.2 can revive the choice without touching anyone's data.

**Cost:** A player who prefers dark interfaces has no recourse. Named for ticket 021's accessibility audit, which is where contrast against the forest gets measured properly anyway.

---

## D294 — Decoration stands down before text does

**Question:** The rating panel puts the cube beside the number, as the mockup does. At the 200% the Android font slider reaches, the cube's 96dp of width pushes "Against the computer" onto three lines and the whole panel past the height of the screen. What gives?

**Decision:** The cube is not drawn above a text scale of roughly 1.4. The words keep their width.

This is worth a numbered entry because of *how* it failed rather than that it did. At 200% the panel measured 787dp on a 960dp screen — it filled the viewport on its own. It did not overflow, and it did not throw. The main screen's fixed sections live in a `SliverList.list`, which builds lazily, so a test that pumped and looked found only the rating panel and reported four sections missing. **A player was never in that position**: scrolling builds them, which is what lazy slivers are for, and criterion U21 was satisfiable throughout. The bug was the panel's height; the vanishing sections were the test's view of it, and this entry said otherwise until the ticket-038 review corrected it.

The general rule the app now follows: at large text scales, decorative artwork yields. It is the only thing on the screen that carries no information.

**Cost:** The mockup's headline composition is not what a player at 200% sees. That is the right trade — they are at 200% because they need the words.

---

## D295 — Every picture is drawn in a box the layout already knows

**Question:** `Image.asset` with only a height, or with neither, reports a size of zero until its bytes have decoded. Does that matter?

**Decision:** It matters enough to be a rule: **every image in this app is wrapped in a `SizedBox` whose dimensions are known before decode.**

It cost this ticket three separate bugs, all with the same shape and none obvious from reading the code. The New Game plaque laid out 316×0 and was untappable. The app-bar logo was a zero-width gap beside the title. Your Path's carved sign had no width and the heading row collapsed. On a device each of these self-corrects a frame later, which is worse than failing — it is a layout that jumps once, on first launch, where nobody is looking. In a widget test nothing ever decodes, so they never self-correct, which is how all three were found.

**Cost:** Two numbers per picture instead of none, and a `kBannerAspect` constant so the carved signs keep their proportions. Cheap, and the tests now hold it in place.

---

## D296 — The background is darkened under everything, because no ink colour survives a photograph

**Question:** Every screen now sits on a photograph of a forest. What colour is text on it?

**Decision:** There is no such colour, so the picture is darkened instead. `ForestScaffold` applies a 55% `#0B160E` filter to the background image, and everything drawn on the forest is cream.

Found by measuring during the ticket-038 review rather than by looking, which is the point of recording it. Against the shipped `background.webp`:

| Text | Where | vs the median | vs its brightest fifth |
|---|---|---|---|
| cream | app-bar title, every screen | 3.45 | **1.01** |
| cream | "Show more" | 3.75 | **1.43** |
| ink | the game screen's turn banner | **2.90** | 11.2 |
| bronze | the `Resign` button | **2.06** | 7.1 |

The picture has a near-white clearing at the top — exactly where the app bar sits — and dark trunks lower down. A light ink disappears into the clearing and a dark one into the trees, so *every* choice is illegible somewhere on the same screen. Nothing on a card was ever in doubt: ink on parchment is 11.44, cream on the dark panel 11.94, the rating pill 7.47, the trend colours 8.33 and 5.18, and the worst pairing anywhere on a surface is disabled text at 4.79.

**A filter on the `DecorationImage` rather than a `Stack` with a translucent box**, because it is one line in the one place the picture is painted, and it cannot be forgotten by a screen added later.

**Two things moved onto parchment rather than relying on the scrim.** The game screen's turn banner is a live region a player reads on every move, and it now sits on a card like the result panel below the board already did. The `Resign` button is the only `TextButton` in the app not on parchment, so it is cream where the theme's bronze is right everywhere else.

**Three lines needed naming individually, and the review did not catch them.** A `Text` that passes `theme.textTheme.something` already carries the ink colour meant for parchment, and no ancestor can take it back: `DefaultTextStyle` is consulted only for text with no style at all, and a `Theme` override cannot help either, because the caller resolved `Theme.of` above the widget doing the overriding. Both were tried. The rating card's record line and streak line shipped as ink on dark green at 1.04:1, and the board's layer captions as ink on the photograph — Layer 4's lands on the lit path and is simply absent. All three were found on screenshots of the running app, after a review that had measured the palette correctly and had no way to see what was rendered. **Screenshots are part of reviewing a design ticket.**

**Cost:** The forest is dimmer than the source art. That is the trade the mockup itself makes — every panel in `Design-alt0.png` sits on a visibly darkened frame — and the alternative was a design that looks right in a screenshot and cannot be read at the top of the screen.

---

## D297 — The signs ship blank and the app writes on them

**Question:** D292 accepted English lettering baked into three pieces of artwork, because the alternative was inpainting wood grain from a script. New art has arrived with the words left off. What now?

**Decision:** The wood ships blank and every caption is drawn by the app, in Cinzel, at the tilt each board was painted at. D292's ceiling is removed rather than lived with.

**The geometry is measured, not guessed.** Each sign carries a `SignArt` record of where its caption sits, how big it is and how far the plank leans — all as *fractions of the picture*, so one set of numbers holds at any size it is drawn. The tutorial board's **8.2°** is the angle of the lettering the old artwork carried, recovered by fitting a line through its glyphs; the colour, `#FDDE7C` on a `#5C300C` rim, is the median of those same pixels. The board was redrawn without its text and the app now writes at the angle the painter used.

**Captions do not scale with the system font slider,** and that is deliberate rather than an oversight. The wood is a picture and cannot grow; a caption at 200% would run off the plank it is written on. Nothing is lost — every sign is either a button whose accessible name is the caption or a heading whose semantic label is the caption, so a screen reader gets the same string either way, at whatever size the reader wants it.

**One `Text` with eight shadows, not two stacked `Text`s.** A stroked layer behind a filled one is the obvious way to draw an outline and looks identical. It also puts every caption in the widget tree twice, so `find.text('Quests')` starts matching two widgets and a dozen tests fail for reasons unrelated to what they assert. That is not a testing inconvenience to be worked around with `findsNWidgets`; it is a signal that the widget was lying about how many things it was.

**Every section wears one now**, not only Your Path. A wooden sign that one section had and the others did not read as an accident rather than as a hierarchy. Which of the two banner planks is used depends on how long the caption is rather than on which section it is — "Finished games" needs the long one in English and "Voltooide partijen" needs it more in Dutch, while "Quests" and "Bezig" would rattle around on it.

**Your Path's sign hangs off the card's corner.** Its left edge lines up with the card's own and its top fifth rises above it. `Transform.translate` moves it without changing what it is measured as, so the column below still reserves only the four fifths that are inside — a sign that had been *laid out* where it is drawn would have pushed the whole section down by the amount it overhangs.

**Cost:** Four more numbers per sign, and they are only correct for the art they were measured against. New artwork means measuring again — which is the same cost the baked-in lettering had, except that it now buys two languages instead of one.

---

## D298 — What was just finished is a second panel, not a filter on the first

**Question:** The main screen ranks quests by how close they are to done. Where do the finished ones go?

**Decision:** Their own panel below it, showing the four completed most recently, and absent entirely until there is one.

"What should I do next" and "what have I just done" are different questions, and a single list answers neither. The closest-to-completion ranking has no room for finished work — a finished thing is not close to finishing — and D280 already settled that the closest panel shows *no reward*, because until a volume or streak quest fires there is no honest figure for it. The recent panel is the one place that figure exists, so it is the one place it is shown.

**`QuestStatus` gained `achievedAt`, and it is not a new source of truth.** Every branch of the fold already had to identify the game that completed a quest in order to price it: the first win against an opponent, the Nth game of the day that reached a volume rung, the last qualifying game of a streak run. The timestamp is that game's, so recency costs one field and no second pass. Nothing is stored, which is the rule the whole progression system is built on (spec §8.8).

**A quest whose completing game has no timestamp sorts last.** Documents written before completion times were stored carry none, and a null read as "now" would pin the oldest history permanently at the top of a list about recency — the one thing it must not do.

**Cost:** A seventh section on a screen that already had six, and the two test files whose tall viewports exist to keep lazily built rows on screen had to grow with it. Criterion U21's real-phone test is untouched and still applies the pressure; what it caught this time was a section list written in the wrong order, which had been harmless only because nothing had ever sat between the two entries that were the wrong way round.

## D299 — One height for every heading sign, and the words shrink into it

**Question:** D297 stretched a heading's plank horizontally so a long caption could keep its lettering size. On a screen with five headings, that produced five signs of visibly different lengths. Which is worth more: lettering that is one size, or signs that are one size?

**Decision:** The signs. Every heading is drawn at the same height and at its own natural proportions, and the caption shrinks into whatever room that leaves.

Five planks at five lengths read as five different signs rather than one sign used five times, and the eye notices the shape of a wooden board long before it notices that one caption is two points smaller than another. The uniformity that matters here is the furniture, not the type.

**The long banner earns its keep by taking two lines.** Its plank is proportionally taller than the short one, which is exactly the shape a wrapped heading needs — "Voltooide partijen" sits on it as two readable lines instead of being squeezed onto one line of a plank with no room for it. That is what the second piece of art is *for*, and the first version of this used it as merely a different picture.

**Cost:** A long caption is smaller than a short one. That is the trade, and it was the owner's call.

---

## D300 — The board is centred, and D137 is reversed

**Question:** D137 put the board against the right edge of the game screen, so a thumb could reach every cell one-handed. Should it stay there?

**Decision:** No. It is centred.

The reach argument was real and it is not what the screen looks like. A 4×4×4 board is the subject of the game screen, and a subject pushed against one edge with a column of empty forest beside it reads as something shoved aside rather than something to look at. The owner asked for centred; the one-handed case is a preference this project has no measurement for, and the composition is visible to everyone.

Recorded rather than edited into D137, because the reasoning there was sound and the trade is what changed.

**Two other things moved with it.** The in-progress list now sits directly under Your Path: a game waiting to be finished is the most actionable thing on the screen and it had been below two panels about what has already happened. And **Your Path snaps to a tile boundary**, so a flick always leaves three whole faces on screen rather than two and two halves — implemented by rewriting the fling's simulation rather than by animating after it ends, so it does not fight a finger that is still dragging.

**The layer captions needed a colour the caller chooses.** They are the one part of the board drawn on whatever is behind it rather than on a cell. A real game puts the board on the darkened forest, where cream is right; the tutorial and the practice game put it on parchment, where cream is invisible — which is what the owner saw. `BoardView` takes the colour rather than guessing from a theme that cannot tell the two apart.

**An overhanging heading needs a gap, not a z-order.** Hanging half of each sign above its card put it inside the *previous* section, and a viewport paints its slivers back to front — the first one last — so every heading lost its top half to a panel it had nothing to do with. There is no z-index to reach for; the fix is forty pixels of space between sections, so the sign hangs into nothing.

**Two lines on the long plank were tried and abandoned.** Its writable band is barely a third of the picture's height and two readable lines simply do not fit in it — they spilled over the wood. What the long plank buys is length, and a single line scaled into it reads better than two cramped ones. The owner had already said the heading text could be smaller, which is what made that the easy call.

**A note on how the gate was nearly slipped past.** `flutter analyze` fails on `info`-level findings, not only errors and warnings — and a grep for `error|warning` while iterating reported "clean" three times while the snap physics carried a deprecated `tolerance` that `check.sh` would have rejected. Read the analyzer's own last line, not a filtered view of its output.

**Cost:** One-handed play on a large phone is worse than it was. If that turns out to matter, the honest fix is an alignment the player chooses, not a default nobody sees. And forty pixels between sections is real vertical budget on a small phone — spent to make the headings read as labels rather than as pictures.

## D301 — One height means the plank, and three ways a sign can be the wrong size

**Question:** With every heading on the same carved sign at the same height, why did four of the five still look different?

**Decision:** Because "the same height" was measured on the wrong thing, and because two Flutter behaviours quietly resized or overdrew the result. Three separate causes, found together.

**The height was the file's, not the wood's.** The four signs carry very different amounts of transparent margin and leaf: the short banner's plank is **0.555** of its picture and the long banner's is **0.385**, measured on the shipped files. Drawing both at the same picture height gave the long one two thirds of the board. `SignArt` now records `plankTop` and `plankFraction`, and `WoodenSign` takes a `plankHeight` — so one number means one size of wood, and the margin is free to be whatever the artist drew. The caption's size is a fraction of the plank too, which is why the same number now produces the same lettering everywhere.

**Reserving space and constraining a child are the same thing** unless you say otherwise. The sign hangs mostly outside its panel, so the layout reserves only the part inside — and a `SizedBox` of that height passed its maximum *down*, squashing each sign to the few pixels reserved for it. Every banner came out a different wide thin sliver, because each reserves a different amount. `OverflowBox` is the way to say otherwise. This is the same class of mistake as D295's undecoded images: a box that was meant to describe layout was silently also describing the child.

**`Material` paints its border over its children.** A heading inside a `Card` had the card's own top edge drawn as a line straight through the lettering. The sections built from `gameSectionSlivers` never showed it, because their parchment is a `DecoratedSliver`, which paints *behind* — and that is exactly why the owner reported that one section looked right and the rest did not. `ParchmentSection` now puts the sign in a `Stack` as a **sibling** of the card rather than a child of it.

**Cost:** Two ways to hang a sign — positioned beside a card, translated inside a sliver — because the lazy game lists cannot be wrapped in a `Stack` without giving up the laziness they exist for. They share `SectionSign` so the artwork and the semantics stay in one place, and the difference is confined to who does the placing.

**And then a fourth, from the same rewrite.** Splitting the two placements dropped the `inset` argument at the one call site that needs it, so the sliver headings never climbed out of their panel's padding and sat twelve pixels down and to the right of the card-backed ones. `SectionHeading.inset` defaults to zero for the case that has no panel around it, and a default is exactly what lets a required value go missing quietly. It is documented at the call site now; the honest alternative is to make it required and give the no-panel case an explicit `EdgeInsets.zero`.

**What this says about looking.** Each of the four is invisible in a diff, none fails a test, and all four were reported by the owner from a screenshot in a single sentence. `flutter analyze` and 322 green tests had nothing to say about any of them.

## D302 — The release plan is re-cut around an account nobody controls

**Supersedes D254, D255 and D259.** Those entries are left standing with their original text, as everything in this log is. What each of them decided is still *reasoned* correctly — they are wrong now only because the fact they rested on stopped being true.

**Question:** The whole plan from 0.3a onward assumed a working Google Play Console account, because the fourteen-day closed test was the critical path and everything else queued behind it. That account cannot currently be reactivated. What replaces the plan?

**Decision:** Four releases, re-cut so that no version's *date* depends on a store account being restored.

| Was | Is | Contains |
|---|---|---|
| 0.3b + 0.4 (partly) | **1.0** | iOS, with no new gameplay. The one-time unlock, the unlimited-play subscription and the meter. The Casual-tier roster fix (D305) |
| 0.3a + 0.3b | **2.0** | The two halves of 0.3 merged: accounts, the cloud repository, async play, invites, push, chat and its safety features, deletion, privacy policy |
| 0.4 | **3.0** | The human rating and server-side move validation, together. The online subscription |
| 1.0 | **4.0** | The remaining platforms |

**1.0 is one version with two release dates.** Whichever store can accept it goes first — on today's facts, iOS — and the other follows when it can, without a version bump and without new work. This is the point of the re-cut: the previous plan had one queue, and a blocked account stopped the queue. Two independent queues cannot both be stopped by one account.

**TestFlight replaces the closed test as the gate.** Google Play requires twelve testers for fourteen continuous days before granting production access, which is why 0.1 was shaped around it. Apple requires no such thing: an internal TestFlight build goes to the owner's own devices immediately, and App Store review is the only gate to public. The Play requirement does not go away — it applies whenever Android ships — but it stops setting the date of the first public release. Ticket 024's survey moves to TestFlight testers, and R8/R11 become Android-only gates.

**Cost, and it is real.** The fourteen-day closed test was not only a store requirement; it was the measurement instrument. Twelve testers on a fourteen-day clock is a retention experiment, and G8 — a tester unlocking an opponent with points they earned — was to be measured by it. TestFlight internal testing is capped at 100 testers but has no minimum, no duration and no structure, so the *discipline* has to be supplied deliberately rather than imposed by Google. R13's two signals must be instrumented whatever the tester count turns out to be, or 1.0 launches with the progression numbers still unmeasured (§7.7).

**And the first public release now carries a paywall it has never tested.** Under the old plan the meter arrived at 0.4, three releases after real users. Under this one it arrives in the first release anybody outside the developer's family ever sees. There is no prior public build to compare against, so if retention is poor at 1.0 there is no way to tell the ladder from the meter.

## D303 — Selling before there is a server

**Amends D225** — the free month is still consumed once at first launch, but for one release it is remembered on the device rather than against an account, because there is no account to remember it against.

**Question:** 1.0 sells the one-time unlock and a subscription, and 1.0 has no backend. §4.1 says entitlement is "a server-written field no client can touch, set only after receipt validation, revoked on refund, chargeback or voided purchase". §4.2 says the free month is held against the account, and explicitly rejects a device-local month because a reinstall resets it and a clock change defeats it. Both of those servers arrive at 2.0. What gives?

**Decision:** Entitlement and the meter are **local at 1.0**, and the weakness is written down rather than designed around.

- **Entitlement** is the store's own signed transaction, read on the device — StoreKit 2's `Transaction.currentEntitlements` on iOS, the Play Billing purchase record on Android. Both are cryptographically signed by the store and both survive a reinstall, because the store re-issues them to the same store account. Refund and chargeback revocation happens on the store's next refresh, not immediately.
- **The meter and the free month** are local records under `files/quadrim/`, alongside games, settings and unlocks, and are in the same backup allowlist.
- At **2.0**, when an account first exists, both migrate. The local free-month record is *adopted* by the account rather than restarted, exactly as D-era §4.2 already required for accounts that predate the meter. A player who consumed their free month at 1.0 does not get a second one for signing in.

**What this leaks, stated plainly.** A reinstall clears the local meter and starts a fresh free month. Nothing in this design stops that, and nothing may be added that would: closing it requires either a device identifier, which §5.2 forbids in every release, or a server, which is what 2.0 is. So the honest description of the 1.0 meter is that it is a **speed bump against forgetting, not a wall against determination** — and the paywall copy must not claim otherwise.

**Why not pull a minimal backend forward.** It was considered. Receipt validation and a meter is a small Firebase project, and it would make entitlement authoritative from day one. It was rejected because it moves the privacy policy, the account plumbing, the data-safety declaration and the INTERNET permission question (D306) into the release whose entire purpose is to be the offline game on a second platform. 1.0 would stop being a port and become the first online release with the online features removed.

**Cost:** S9 and S18 — entitlement server-written, meter server-authoritative — are no longer testable at 1.0 and become 2.0 criteria. Between 1.0 and 2.0 the app ships a paid tier that a motivated user can reset by reinstalling, and the revenue that leaks in that window is not recoverable afterwards.

## D304 — Online play is free at 2.0 and paid at 3.0

**Question:** Online play arrives at 2.0; the subscription that sells it arrives at 3.0. What is the status of online play in between?

**Decision:** Free, and **labelled as a preview from its first day**.

The reason it is free is sound: until 3.0 there is no human rating and no server-side validation, so what 2.0 offers is asynchronous games with a win/loss/draw record — worth having, not worth a subscription. Charging for it before the rating makes it meaningful sells the weaker product at the stronger price.

The reason it must be *labelled* is that this project has already made this mistake once. v2 promised that everything release 0.1 shipped would be free forever, and D-era §4.2 had to withdraw it. That withdrawal was defensible only because nothing had shipped publicly and nobody lost anything. At 2.0 people will have shipped, and taking online play behind a paywall at 3.0 is precisely the withdrawal that promise was. So the copy at 2.0 says what it is — free while it has no rating, subscription when it does — in the release notes, on the online screen and in the store listing.

**Cost:** A feature that announces its own future price is a worse-looking feature, and some players will not start using something they are told will cost money later. That is the price of not repeating the free-forever sentence.

## D305 — The Casual-tier inversion is fixed now, because now is the last moment it is free

**Question:** Willow measures about 33 points above Vireo and Vireo about 50 above Finch, while the roster prices Finch highest of the three. D268 assigned the fix to a 1.0 roster revision. That revision is cancelled. Does the inversion ship?

**Decision:** No — it is fixed before 1.0, by reordering those three roster entries so that price and measured strength agree.

**Why now rather than later, and this is the whole argument.** The roster index sets three things at once: the unlock price, the win payout, and the order in which opponents become available. Changing the index therefore changes what everything costs and what everything pays. Today that is free, because nothing has been sold and no unlock record exists outside the developer's own devices. The moment 1.0 ships, every reorder is a migration: a player who paid 128 points for an opponent that is now worth 64 either keeps a record that no longer matches the table, or is repriced. D-era §7.3 already handles the first case — the price paid is stored with the unlock, so old unlocks stand — but that mechanism exists to survive a *re-tune*, not to make a reorder painless for players comparing notes.

So the choice is not "fix it at 1.0 or fix it at 4.0". It is "fix it before anybody buys anything, or accept it permanently". D268 assumed a roster revision was coming anyway and could absorb it; with that revision cancelled, the deferral has no destination.

**Cost:** A calibration run must confirm the reorder, because the three ratings are anchors and the inversion was measured rather than argued — `calibrate.dart --only vireo`, `--only willow`, `--only finch` against the settled rest. It is also a change to shipped content in a build that has already been through art and layout: three opponents move position in Your Path, in the tier accordion and in every screenshot taken so far.

## D306 — What iOS costs that the Android constraints were written without

**Question:** Three of this project's hard constraints are enforced by Android mechanisms. What happens to them on a platform that has no such mechanisms?

**Decision:** Each is re-stated for iOS, and where the enforcement genuinely does not transfer, that is recorded rather than papered over.

**"Computer play makes no network call" loses its categorical enforcement.** On Android it is guaranteed by the *absence of the INTERNET permission* (D212), which is why `check.sh` greps the release manifest. iOS has no equivalent: an app may open a socket without declaring anything. So on iOS this constraint drops from *enforced* to *reviewed*, and the honest statement is that the Android build proves it and the iOS build shares the code that the Android build proves it about. That is weaker, and it is the best available.

**Billing may cost the permission on Android too.** Play Billing requires `com.android.vending.BILLING`, and whether the library's manifest merge also injects `INTERNET` must be **checked empirically at implementation time, not assumed either way**. If it does, `check.sh`'s manifest grep fails on a release that has made no network call, and the check must narrow to computer play — the same instruction D212 already leaves for 0.3a, arriving one release earlier than expected.

**Backup.** Android's explicit allowlist has no iOS counterpart; iOS backs up the app's `Documents` directory to iCloud by default. Unlock records must be there, so D11 — a restore on a new device returns every unlock — holds on both platforms. From 2.0 the exclusions S15 requires (auth material, FCM token, Installations ID) need the iOS equivalent, which is `isExcludedFromBackup` on the specific files rather than a manifest list.

**And two things iOS adds that Android never needed:** a privacy manifest (`PrivacyInfo.xcprivacy`) declaring required-reason API use, and App Store privacy labels. Both are declarations about a build that collects nothing, which makes them cheap to write and easy to forget.

**Cost:** The single strongest privacy guarantee this project has — a platform-level refusal rather than a promise — is now true on one of its two platforms. Nothing in the code changes; what changes is what can be claimed.

## D307 — `in_app_purchase`, and what declining RevenueCat costs

**Question:** 1.0 sells two products with no backend. RevenueCat would give server-side receipt validation, cross-platform entitlement and a closed reinstall leak, without us running a server. Why not take it?

**Decision:** Flutter's `in_app_purchase` plugin — one Dart API over StoreKit and Play Billing, no third party, entitlement read on the device exactly as D303 describes.

**RevenueCat was genuinely tempting and was rejected on one point.** It assigns every installation an app user id and receives the purchase stream. An anonymous, per-installation, persistent identifier is a device identifier by any reading that matters, and §5.2 forbids one **in any release** — not "except when a vendor generates it for us". Around that sits the rest: a processor to name in two privacy declarations, a network dependency in the release whose selling point is that it has none, and an outage in someone else's service becoming a player unable to prove they paid.

The honest accounting is that declining it **leaves D303's reinstall leak open until 2.0**. A paid service would have closed it now. What it would have cost is the clearest privacy claim this project has, one release before an account system closes the same hole for free.

**Cost:** Revenue leaks for one release to anyone who works out that reinstalling resets the meter. The unlock purchase itself is safe — the store re-issues it — so what leaks is subscription pressure, not the ability to charge.

## D308 — The meter goes in `quadrim_progression`, not a fourth package

**Question:** The meter is pure arithmetic over game history with an injected clock, which is the shape the pure packages exist for. New package or existing one?

**Decision:** `meter.dart` inside `quadrim_progression`, beside `points.dart`, `quests.dart`, `streaks.dart` and `unlocks.dart`.

`streaks.dart` is the precedent and it is exact: a fold over completed games plus an injected day boundary, no clock read inside the package (P19). The meter is the same computation with a different predicate. A fourth package would earn its own purity scan, pubspec, CI entry and import graph for about a hundred lines.

**The package invariant is unaffected**, and it is worth checking rather than asserting: D261/D270 require that no function in `quadrim_progression` accepts the player's rating or rung. A meter needs neither — it counts games, and which opponent they were against does not change the count.

**Cost:** The package's name is now slightly wrong. It holds progression *and* one thing that is really commerce, and a reader looking for the meter will not guess where it lives. That is cheaper than a package.

## D309 — The Casual fix moves the configurations, not the entries

**Question:** D305 says the inversion is fixed by reordering three roster entries. Reordering changes the roster index, and the index sets every unlock price and every win payout. Is that the right mechanism?

**Decision:** No — **move the configurations between the rungs and leave the entries where they are.** Willow, Vireo and Finch keep indices 5, 6 and 7 and keep their ratings of 1100, 1200 and 1250; what moves is which personality sits on which rung, so that the stronger-measuring configuration ends up on the higher-priced one.

This refines D305 rather than contradicting it — same defect, same release, better mechanism — and it is better on three counts:

- **No price and no payout changes at all**, because no entry changes index (§7.3). D305 assumed a price migration and reasoned that it had to happen before the first sale. It turns out there is no migration; what was actually urgent is the *displayed difficulty claim*, which is a weaker form of the same argument and still points at 1.0.
- **No avatar moves.** Ticket 038's twenty portraits are keyed on the opponent id.
- **The ratings stay anchors.** Nothing here edits a `BotConfig.rating` to meet a measurement, which is the one edit that would make the app's central claim false (D144).

**Cost:** The personality copy has to move with the configuration rather than staying with the name, so two of the three opponents' descriptions change in both languages. Text that no longer describes the bot it names is worse than the inversion it fixed — and it is the kind of thing that passes every test and is caught only by reading it.

## D310 — The meter reads starts, and the ticket that specified it said otherwise

**Question:** Ticket 045's own signature was `meterState({required Iterable<CompletedGame> games, …})`. Two lines below it, the same ticket says a game counts when it is **started**, not when it finishes. Which is right?

**Decision:** Starts. The signature was wrong and is now `Iterable<StartedGame>`.

`CompletedGame` does not exist — the type the ticket was reaching for is `ScoredGame`, which every other fold in `quadrim_progression` takes. That is exactly how the mistake happened: points, quests and streaks all read completed games because they reward *results*, so a fourth fold in the same package looked like a fifth of the same shape. It is not. **A meter that counted results would be defeated by starting a game and quitting**, which §4.2 says in as many words and which F17 tests.

The fold therefore reads `GameDocument.createdAt` over games in any status, where the other folds read `completedAt` over completed ones. `meter_fold.dart` says so at the top, because a reader who has seen the other two will assume this one matches them.

**`StartedGame` is a named type over a bare `DateTime` for the same reason.** A function taking `Iterable<DateTime>` accepts a list of `completedAt` values silently, and the entire correctness of the file is that it does not get those.

**Cost:** A fourth input type in a package that already has `ScoredGame`, carrying one field. Worth it: the alternative is a type that makes the one mistake this file exists to avoid invisible at the call site.

## D311 — The week starts on Monday, in every locale

**Question:** "Nine per week" needs a week. Calendar week or rolling seven days, and if calendar, starting which day?

**Decision:** A calendar week, starting **Monday**, fixed, everywhere.

**Calendar rather than rolling** because the paywall has to say when the limit lifts (D221). "Your games come back on Monday" is a sentence a player can act on; "in three days, when Tuesday's games age out of the window" is not, and a limit nobody can predict reads as the app being broken rather than as a rule.

**Monday rather than the locale's own week start** because reading the locale would put an ambient input into a pure package, and because two players in different countries would then hit the same limit on different days for a reason neither could see. `kWeekStartsOn` is a constant, so a future locale-aware caller changes one line rather than a design.

**Cost:** In locales that draw calendars Sunday-first — the United States among them — the app's week disagrees with the wall calendar. A player there whose Sunday is "the start of the week" finds their allowance refreshing a day late. That is a genuine wrongness and it is chosen over the alternative, which is a limit whose reset day depends on device settings.

## D312 — The free month lives in the settings document

**Question:** The free month's start is not derivable from game history — a player who installs and never plays still has a month running. Where is the one timestamp stored?

**Decision:** A `freeMonthStartedAt` field on `SettingsDocument`.

A document of its own would need a store path, reader, writer, repository method, unreadable-document fallback and its own tests. Settings already has all six, is already inside the backup allowlist under `files/quadrim/`, and is already versioned. That is the whole argument, and it is a laziness argument.

**Two things it costs, and both are real.**

It makes a document that is otherwise entirely *preferences* hold one *record*. A reader looking for the meter's state will not think to look in settings, which is why the field carries a comment saying what it is rather than only what it holds.

And it is the **second** thing this app stores that game history cannot reconstruct. D12 — "nothing but the unlock records is stored" — is now "nothing but the unlock records and one timestamp". The invariant it protected still holds where it matters: balances, streaks, quest progress and statistics remain derived, and the test that reconstructs each of them from game history alone is untouched. But the sentence is no longer literally true, and a spec sentence that has quietly stopped being true is worse than one that was amended.

**Absent means unmetered, never expired.** A document written by 0.1 or 0.2 has no such field, and so does a damaged one. Both stamp at the next launch, which gives an existing player their month starting at the update — the rule §4.2 already states for players who predate the meter, arriving as the natural reading of a missing field rather than as a migration. The failure direction is deliberate: a missing record must let the player play, not wall them out of a game they cannot explain.

## D313 — The calibrator could not see a cycle, because a chain has no triangle

**Question:** Three decision entries — D210, D211, D268 — described the Casual tier's ordering from measurement, and all three missed that the tier is **intransitive**. How did the instrument not show it?

**Decision:** Because it never played the pairs that would have shown it. `calibrate.dart` played every *adjacent* pair plus ten cross-tier braces; `--only` played an opponent's two neighbours plus one bot per other tier. Within a tier, every non-adjacent pairing was unplayed — and a cycle needs three mutual results to appear. A chain has no triangle in it.

What that produced, measured before this ticket changed anything:

| pair | result |
|---|---|
| willow → vireo | willow **+45** |
| vireo → finch | vireo **+70** |
| willow → finch | willow **−207** — never played by any tool |

Willow's two neighbours are bramble and vireo, and it beats both, so it measured **1259 against a published 1100** — flagged as a defect, and the defect it named was the wrong one. It was not 159 points too strong; it was being asked only the two questions it could answer.

`calibrate.dart` now plays **every pair inside a tier**, and `--only` measures against a subject's whole tier rather than its neighbours. The full run goes from 29 pairs to 47, and from 13½ minutes to 15¼.

**Cost:** A longer run, and two problems in the Novice tier that were previously invisible are now on the report — Pebble measures 508 points below its anchor from 3 pairs and Clover 220 above from 4. Neither is new; both were always true and never asked about. That is what a better instrument does, and it is not a reason to keep the worse one.

## D314 — Aggression leaves the Casual tier

**Question:** D211 left two ways out of the Casual tier's ordering problem: space the rungs by something other than `aggression`, or make `aggression` a strength axis rather than a personality one. Which ships?

**Decision:** The first. No opponent in the Casual tier sets `aggression` any more — Vireo's 0.67 and Finch's 0.30 are gone, and a test asserts that every member of the tier is at the 0.5 default.

The second route was rejected on the measurement rather than on taste. `aggression` above 0.5 skips a share of denials and below 0.5 surrenders the initiative, so which setting wins depends on which setting it is facing. Ordering rungs by an axis like that aligns the *average* while leaving the tier intransitive: Finch would still lose to an opponent priced below it, and the price would still be a claim the board does not honour.

**What it cost, and it is what the option promised.** Two personalities are gone. "Attacks from the corners, and would rather build than block" and "Cautious. Shuts your threats down before it starts its own" were the two most recognisable descriptions in the tier, and they were true of how those bots played. The blurbs are rewritten in both languages to describe what is left, which is a preference for squares — a duller thing to read and an accurate one. D211 defended those personalities explicitly as "the thing players actually experience"; this reverses that, because a description that is vivid and false is worse than one that is plain and true.

**What it bought:** measured with the fixed instrument, the tier now runs 946, 1137, 1236, 1261, 1275 against published 1000, 1100, 1200, 1250, 1300. Every rung inside tolerance, and in the right order for the first time.

## D315 — Aggression was not what made the tier cyclic

**Question:** Removing `aggression` was supposed to remove the cycle. Did it?

**Decision:** No, and recording that matters more than the fix does.

Head-to-head after removing it: Willow still beat Vireo (+26 where it had been +45), Vireo still beat Finch (+38 where it had been +70), and Finch still beat Willow by **212**. The cycle shrank by roughly 40% and did not close. What remains is driven by **which of the two eight-cell groups an opponent prefers** — the axis D210 chose to order the tier by:

- corners-first beats centres-first
- centres-first beats centres-only
- centres-only beats corners-first

Rock-paper-scissors, in the one lever the tier was built on.

**And D210's central claim does not survive a direct test.** It says preferring more of the sixteen seven-line cells is worth more than anything else in the tier. Dropping Vireo's `centreBias` — taking it from sixteen preferred cells to eight — made it measurably **stronger**: its win over Finch grew from +38 to +70 and its win over Kestrel from +17 to +31. That change was reverted, because it made the rung it sits on worse, but the result stands: **more preferred squares is not monotonically stronger.** Ranking centres above the remaining cells apparently costs more than the extra eight good cells pay.

**So why is the ladder now ordered?** Because aggregate rating and head-to-head are different questions. A published rating claims how hard an opponent is *in general*, and against a broad enough sample the tier now ascends. Three specific matchups inside it still run the other way, and the calibration report names them as inversions — correctly, and they are no longer hidden.

**Cost, and it is the honest limit of this ticket:** a player who happens to play like Willow will find Finch harder than its price suggests, and a player who plays like Vireo will find Kestrel easier. Nothing in the available levers fixes that. Closing it needs a lever that is monotone rather than stylistic — search depth, or a finer blunder scale — and both are larger changes than a roster fix, and neither is 1.0's.

## D316 — Your Path showed the earned total where it meant the balance

**Question:** Reported from a device: a player holding 64 points saw "256 of 256" on Your Path's Finch tile, with a full progress bar and an Unlock button that did nothing. The opponent detail page, one tap away, showed "64 of 256". Why did two surfaces disagree?

**Decision:** Because they were reading two different numbers, and only one of them was the right one. `HomeSummary.points` is the **earned** total — a fold over every game ever won — and it keeps rising as unlocks are bought. The spendable balance is that minus the prices actually paid, clamped at zero. The player had earned 256, spent 192 on Willow and Vireo, and had 64 left.

`OpponentScreen`, `OpponentDetail` and `RatingCard` were all handed `_balance`. **`YourPath` was never handed it at all** — it took `summary` and read `summary.points` off it. It now takes `balance` as its own required parameter, and the field on both tile widgets is *named* `balance` rather than `points`, so the call site says which number it is.

**Two things made this survive to a device.**

`RatingCard` already carried the warning — *"Earned minus spent, clamped at zero — not `HomeSummary.points`, which is the earned total"* — written when this hazard was first met. A comment on one widget does not protect the widget next to it.

And every Your Path test spent nothing. With no unlocks bought, earned and balance are the same number and the defect cannot appear; the suite had a test asserting "0 of 64" and another asserting "64 of 64", both of which pass either way. The regression test buys two opponents first, which is the cheapest possible way to make the two numbers differ.

**Cost:** One more required parameter on a widget that already takes five. That is the right trade against a shared `summary` object holding a field most of its readers must not use — the field is correct and the name `points` is what invites the mistake.

## D317 — A volume quest's progress is today's, and the screen has to notice midnight

**Question:** Reported from a device: "it's a new day and the quests panel still shows 16 of 20 games in one day." Sixteen games were played yesterday and none today. What is wrong?

**Decision:** Two things were, and either alone would have produced the same screen.

**The fold answered the wrong question.** `_volume` returned the **best day ever** as progress, defended by a comment saying a cleared rung must not un-clear itself when the next day starts quietly. That defence is about *achievement*, which is permanent and returns from an earlier branch. Progress is a different question, and for a target that says *in one day* the honest answer is today's count: a player shown "16 of 20" reads it as four more games, when in fact it is twenty. Progress is now `playedToday`, counted once per fold and shared by all five rungs.

**And the screen only recalculated when a game finished.** Everything day-shaped on the main screen — the streak and every volume rung — is folded against a `today` read at fold time, and the only trigger was the completed-games stream. Leave the app open overnight, or reopen it from the background the next morning, and it kept yesterday's answers until something else changed. `HomeScreen` now re-folds on `AppLifecycleState.resumed` as well, which is one `AppLifecycleListener` and a method extracted from the stream callback.

**Cost:** A volume rung at zero drops out of the four-closest section entirely, because it is outranked by the per-opponent quests that need one thing rather than five. So a player who cleared nothing yesterday opens the app to a quests panel with no daily rung in it at all, where before there was one showing a number. That is correct — an unreachable-today claim is worse than an absent one — and it is a visible change.

**What this says about the tests, again.** Three app tests broke, and each was passing for the wrong reason. The fixture played its games on 2026-01-01 while its own `today` was 2026-08-14, seven months later — incoherent, and invisible while progress was the best day ever. The two that then double-matched "1 of 5" did so because a coherent fixture gives the player a one-day streak as well, which the old one never had. **A fixture whose clock disagrees with itself cannot catch a bug about which day it is**, and this one had disagreed since ticket 033.

## D318 — Your Path says it scrolls, with two buttons that step it

**Question:** Reported from a device: the roster row is scrollable and nothing on it says so. Can it be made obvious?

**Decision:** A carved arrow at each edge of the panel, each stepping the row exactly one tile.

The row shows three tiles and is exactly three tiles wide, which is what hides it: on a list that overflows by a little there is a half-visible fourth item promising more, and here the fit is exact, so a player who never guesses to swipe sees five opponents out of twenty — the free ones and whatever the rating rests on. D287 replaced the fixed window with this scrolling row precisely so the price ladder would be one swipe away instead of invisible, and a swipe nobody makes is the same as no swipe.

Stepping one tile rather than a page, and from the nearest tile boundary rather than from wherever the row currently sits: a drag lands where `_SnapToTile` rounds it to, and a tap after a half-finished drag has to behave like every other tap. The two are then the only precise way to move the row — a drag is a gesture, a press is an instruction.

**They fade at the ends rather than disappearing**, and are made non-interactive at the same time. Removing them would take their explanation with it, so a player at the strong end of the roster would have nothing left saying the row moves at all; and an invisible control that still swallowed a press would eat a tap meant for the tile it sits on.

**Cost:** Two 6.5KB assets, and 48dp of each outer tile covered by a tap target. The artwork was delivered on a painted transparency checkerboard like the signs, but with the checker showing **through** the glass button face, so removing it needed something the signs did not: the pattern is two flat greys, so on a small neighbourhood the difference between its two phases is the whole of it and everything else the picture does is common to both. `_dechecker` in `tools/artgen` subtracts half that difference from one phase and adds it to the other, which leaves the stone texture, the highlight and the drop shadow untouched. Its grid is not on integer pixels — 34.5 across, 34.3 down, fitted to the tile boundaries in the top row and left column — so a modulus of 34 would drift a whole cell over the width of the file.

## D319 — An arrow that hangs off the panel needs the panel not to bound it

**Question:** The arrows of D318 are asked to sit half in and half out of the panel — 30% of each disc outside its border — and to be translucent and vertically centred. The first of those is not a styling change. Why?

**Decision:** `Your path` is now the one section laid out at the **full width of the screen**, applying its own 16dp margin, with the arrows as siblings of the panel rather than children of it.

`RenderBox.hitTest` checks `size.contains(position)` before it asks any child, so **a widget positioned outside its parent's box is painted and never pressed.** `Stack(clipBehavior: Clip.none)` changes only the painting. Left inside the panel, the arrows drew correctly across the border and then failed to respond: the tap landed on the tile behind them, because their centres were a few pixels outside the scrolling row that contained them. This is not a rounding problem that a bigger target fixes — every pixel outside the parent is dead, so the whole overhang is.

So the box that contains the arrows has to be the one that extends past the panel, which is the screen. `home_screen.dart` splits its first `SliverPadding` and gives this section a `SliverToBoxAdapter` at the full width; `YourPath` carries the 16 itself. Everything downstream is unchanged — `_kSectionInset` still adds up to the same 25.5, because the margin moved rather than changed.

**The arrow's size is decided by this, not chosen.** With 30% of it outside the panel and a full 48dp target around it, the target's outer edge lands exactly on the screen edge at 40dp. Smaller, and the target hangs off the *screen*, where its outer part stops being pressable for precisely the same reason the overhang would have been.

**Cost:** One section of the home screen no longer shares the list padding with its neighbours, so a future change to that 16 has to be made in two places. The constant is named on both sides and this entry is the third. Two tests moved with it: one measured "off the right-hand edge" against `YourPath`'s own rect, which is now wider than the row it was standing in for.

## D320 — One name is written short, and only where the width is a third of a phone

**Question:** The `Your path` tile shows "Quadrim P…". Shorten it, or shorten every name?

**Decision:** One arm, for one opponent: `botShortName` returns "Q. Prime" for `bot:quadrim_prime` and the full name for everything else. It is used by the tile alone. The opponent's page, the game screen, the history and every announcement say "Quadrim Prime".

Deliberately not a general rule. A width-aware shortening — first word, or initials past N characters — would have to be right for twenty names in two languages, and it is only wrong for one of them today. When a second name needs shortening it gets a second arm, chosen by a person who has looked at it.

**And the tile speaks the long name while writing the short one.** A screen reader has no width, so the abbreviation buys nothing there and costs the listener the name. `_PathTile` therefore builds two strings: `name` for the semantics label, `written` for the `Text`.

**Cost:** A locale that transliterated the roster would have to remember to supply the short form as well, and nothing checks that it did. Both arb files carry the key today.

## D321 — A game with fewer than two moves is not in progress

**Question:** "In progress" listed games nobody had played. What counts as a game in progress?

**Decision:** Two moves. Nought is a board the player has not touched, and one is the opening the computer played before they saw it — neither is something a player would recognise as a game they were in the middle of, and both accumulate every time someone opens the opponent list and backs out.

The filter is in the screen, not the repository: `_activeGames` still holds every unfinished game, because [D322](#d322--one-unfinished-game-per-opponent-and-a-new-one-resumes-it) needs to find the one it must resume. `_startedGames` is what the panel draws and what decides whether the empty state appears.

**Cost:** Six fixtures had to start playing. Every one of them created a game and asserted its row, which had been enough since ticket 005; they now append two moves first. That is the honest cost of a rule about what a game is — the old fixtures were asserting on something the product no longer calls a game.

## D322 — One unfinished game per opponent, and a new one resumes it

**Question:** D321 hides the games with nothing in them. They still exist. What happens when the player asks for a new game against the same opponent?

**Decision:** It opens the one already there. Against the computer there is at most one unfinished game per opponent, and `_start` looks for it before it creates anything.

**The reason is the draw, not the tidiness.** Who moves first is decided once, by `random.nextInt(2)`, when the game is created. Without this rule a player who did not like the answer could leave and ask again, and again, until they got the first move — and in a 4×4×4 game the first move is worth real rating, which is what makes it worth farming. Hiding the abandoned games (D321) would have made that *easier*, not harder: the evidence of the reroll disappears from the screen.

Pass and play is exempt: both seats are the same person, so there is nothing to gain, and two games on the go is a reasonable thing to want.

A rematch is also untouched. It alternates the seat deterministically rather than drawing one, which is the fairness mechanism for a series and cannot be farmed by repetition.

**Cost:** A player cannot have two games running against one opponent. Nothing in the product wanted that, but it was previously possible and is now not — asking for a new game against someone you are already playing takes you back to that board, which is a surprise exactly once.

## D323 — The splash is black, and shows the mark without its disc

**Question:** The launch screen is a white field with the logo on a black square in the middle of it. Why, and what fixes it?

**Decision:** Black splash background, and the launcher icon's **foreground layer alone** as the splash icon.

Two stock defaults were doing it. On Android 12 and up the platform draws the splash itself and ignores `windowBackground` entirely: unset, its colour is `?android:colorBackground` — white under `Theme.Light.NoTitleBar`, which is what the Flutter template ships — and its icon is the whole adaptive launcher icon, green disc and all. The mark is gold drawn on black, which is how it was delivered and what lets `artgen` recover its alpha from the luminance (D290), so a dark square on white is exactly what that composition looks like when the field around it is not black.

`LaunchTheme` is now `Theme.Black.NoTitleBar` in both modes, with `windowSplashScreenBackground` black and `windowSplashScreenAnimatedIcon` pointing at `ic_launcher_foreground` — the gold mark on transparency, without the green disc the launcher icon wears. `NormalTheme` is black too, so the hand-off from the splash to the first frame is not a white flash.

**The two API-31 attributes are declared in the unqualified `values/`, not in a `values-v31/`.** They did not exist before API 31 and are ignored there, and a version-qualified folder would have to be duplicated for night mode: night sorts ahead of version when resources are matched, so an existing `values-night/styles.xml` would beat `values-v31/styles.xml` on a dark-mode phone and the splash would be white again on exactly the devices that asked for dark.

**Cost:** `values/styles.xml` and `values-night/styles.xml` are now the same file twice. Deleting the night one would be tidier and wrong — the platform still needs a night answer, and the stock one it would fall back to is not this one. Below API 31 there is no icon on the splash at all, only the black field; that is what a window-background splash is, and it is not worth a bitmap layer to change.

## D324 — The minimum iOS is 13.0, and nobody chose it

**Question:** §12 has no minimum-iOS decision in it. `flutter create` has now made one by default. What is it, and does it stand?

**Decision:** `IPHONEOS_DEPLOYMENT_TARGET = 13.0`, in all three build configurations, and it stands for 1.0 unchanged. Ticket 041 was explicit that this number is to be *recorded* rather than tuned, and the reason is that the ticket had no evidence to tune it with: the argument for raising it is an API this app does not reach, and the argument for lowering it is a device Flutter 3.44.9 will not build for.

**What it costs is nothing measurable and one thing worth naming.** iOS 13 is 2019, so the floor excludes no phone anybody is still playing on. But the number is now load-bearing in a way a default is not: `MinimumOSVersion` in the shipped `Info.plist` is `13.0`, and App Store Connect will show it as the app's requirement from the first upload. Raising it later drops devices that had the app; that is a product decision and it now has a starting point instead of an accident.

## D325 — There is no Podfile, because iOS builds through Swift Package Manager

**Question:** Ticket 041 says "`ios/Podfile.lock` **is** committed, like `pubspec.lock`". There is no `ios/Podfile` and no `ios/Podfile.lock`. Is something missing?

**Decision:** Nothing is missing. Flutter 3.44.9 ships `enable-swift-package-manager` on by default — it is in `flutter doctor -v`'s feature-flag line — and the app's only plugin with an iOS side, `path_provider_foundation`, has a `Package.swift`. So the plugin is resolved by SPM and no Podfile is ever generated. The simulator build succeeds with `ios/` containing only `Flutter`, `Runner`, `Runner.xcodeproj`, `Runner.xcworkspace` and `RunnerTests`.

**The ticket's instruction is not wrong, it is from before the flag flipped**, and it is left in the ticket text rather than edited, because the ticket is the record of what was believed at the time.

**CocoaPods is still installed and still matters**, which is the confusing part. `flutter doctor` will not report the Xcode toolchain green without it, and the moment a dependency without SPM support is added, a Podfile appears and the ticket's instruction becomes live again. Treat "commit `Podfile.lock`" as dormant, not deleted.

**Cost:** the lockfile guarantee is weaker than the ticket assumed. `pubspec.lock` pins the Dart side and is committed; the SPM side is resolved from `Package.swift` at build time with no committed resolution file in `ios/`. Two machines can therefore build against different `path_provider_foundation` point releases without the repository noticing. That is acceptable for one plugin and would not be for ten.

## D326 — CocoaPods runs under bundler on this Mac, and that is a machine condition

**Question:** `gem install cocoapods` fails on this Mac. Ticket 041 says to use Homebrew, whose installer needs a password no agent has. What actually happened?

**Decision:** CocoaPods 1.17.0 is installed into `~/.cocoapods-bundle` by bundler, and `~/.local/bin/pod` is a three-line shim that sets `BUNDLE_GEMFILE` and `exec`s `bundle exec pod`. `flutter doctor` finds it on `PATH` and reports it exactly as it would a Homebrew install.

**The failure mode is why this is written down.** macOS 26 ships Ruby 2.6. Every modern CocoaPods dependency has moved past it, and `gem install` surfaces them one at a time — `ffi` wants ≥ 3.0, then `securerandom` wants ≥ 3.1, then `drb` wants ≥ 2.7, then `connection_pool` wants ≥ 3.2 — so pinning each one in turn looks like progress and never terminates. Bundler resolves the whole graph against the Ruby requirement at once and finishes in a single command. Anyone who reaches for `gem install cocoapods` here will spend an hour learning this.

**This is a machine condition, like `JAVA_TOOL_OPTIONS` on the Windows box (CLAUDE.md).** Nothing in the repository caused it, nothing in the repository fixes it, and no path to it is committed. Homebrew remains the recommended route for anyone who can type a password; this is the route for anyone who cannot.

**Cost:** one more undocumented-if-not-for-this-entry thing between a fresh Mac and a build, and a `pod` that is a shim rather than a binary — so `which pod` answers a shell script and `pod --version` pays bundler's startup on every call.

## D327 — What `flutter create --platforms=ios` touched outside `ios/`, and what was put back

**Question:** Ticket 041 says the command "adds `app/ios/` and touches nothing else." It wrote 47 files. What were the others, and which of them should survive?

**Decision:** Three things landed outside `ios/` and two were reverted.

- **`app/test/widget_test.dart`** — the template's counter smoke test, which imports a `MyApp` this project does not have and fails on sight. **Deleted.** It is not a test this project lost; it is a test this project never had.
- **`app/.metadata`** — rewritten twice over. `channel` became `[user-branch]`, which is an artefact of cloning Flutter at a tag rather than a fact about the project, and would tell the Windows machine the repository is on a user branch. And the `migration.platforms` list had `android` **replaced** by `ios` rather than joined by it, which would have left `flutter migrate` blind to the Android half. **Both put back:** `stable`, and both platforms listed.
- **`app/.idea/` and `app/quadrim.iml`** — IDE scaffolding, already covered by `.gitignore` and therefore never staged. Left where they fell.

**The lesson is that the ticket's "touches nothing else" is a statement of intent, not of fact**, and the only way to hold the command to it is `git status` immediately afterwards, before anything else is run. Two of these three would have been invisible in a diff read at the end of the ticket.

**Cost:** `.metadata` now says something `flutter create` did not write, so the next `flutter create` or `flutter migrate` on this project will try to rewrite it the same way, and the same check is needed again.

## D328 — `CFBundleLocalizations` is declared, and it is not what makes the app Dutch

**Question:** Ticket 041 says: "Without this iOS reports only English to the system, and a Dutch device runs the app in English no matter what `flutter gen-l10n` produced." Is that true?

**Decision:** The key is declared — `[en, nl]` — and the stated reason for it is wrong. It was disproved by removing it, rebuilding, and installing on a wiped `nl-NL` simulator: the app came up entirely in Dutch anyway.

**Why the ticket's reasoning fails is specific to Flutter.** iOS does filter a *native* app's language list by the bundle's declared localisations — `Bundle.preferredLocalizations` is the intersection of the device's ordered languages and what the app says it has. The Flutter engine does not read that. It reads the system-wide `NSLocale.preferredLanguages`, hands the raw list to Dart, and `MaterialApp.supportedLocales` resolves against it. So the bundle declaration is bypassed entirely on the path that chooses the app's language.

**The key stays, for the two things it does do.** It is what puts Quadrim in the per-app language picker in iOS Settings, so a player with a Dutch phone can choose to run this one app in English. And App Store Connect reads it when deciding which languages the listing claims. Both are real and neither is the in-app language.

**What actually guarantees Dutch is unchanged and lives on the Dart side**: `flutter gen-l10n`, the `supportedLocales` list, and the existing test that every string exists in Dutch. That guarantee was already enforced and already tested; iOS adds nothing to it and could not have taken it away.

**Cost:** none in the product, and one correction in the record — a criterion that had been ticked with the right observation and the wrong explanation. The general form is worth keeping: a platform declaration that *looks* load-bearing is not, and the way to tell is to delete it and rebuild, which took four minutes.

## D329 — The iOS icon is one 1024, and the fifteen it replaced are deleted

**Question:** Flutter's template ships fifteen icon PNGs and a `Contents.json` naming every one. Ticket 042 says a single 1024 is enough since Xcode 14. What happens to the other fifteen?

**Decision:** `ios_app_icon` deletes every `Icon-App-*.png` before it writes, and the new `Contents.json` declares one `universal` 1024x1024 entry. Xcode derives the rest at build time — verified in the archive, which contains `AppIcon60x60@2x.png` and `AppIcon76x76@2x~ipad.png` that artgen never wrote, both with `hasAlpha: no`.

**The deletion is the part worth writing down.** Dropping the declaration without dropping the files leaves fifteen Flutter logos in `Assets.xcassets` that nothing names and nothing renders — invisible in the app, present in the repository, and exactly the sort of thing that gets re-adopted by a future `flutter create` or a hand-edit in Xcode. A generator that owns a directory has to own what it removes as well as what it writes.

**The inset is 70%, not the adaptive icon's 62% (D290's `launcher_icon`).** Android's adaptive mask eats the outer third and 62% is clearance for it; iOS shows the whole square and rounds the corners itself. Reusing 62% here would have put a small mark in a large green field.

**Cost:** the icon is only checked by looking at it and by the archive not complaining. `art_assets_test.dart` cannot help — it tests what Flutter loads, and neither the icon nor the launch screen is loaded by Flutter.

## D330 — The launch screen is JPEG, alone in this pipeline

**Question:** Every shipped image in this project is WEBP, and the app icon must be PNG. The launch image was generated as PNG and came to 4.0 MB across the three scales — against a total art-and-font budget of 2.25 MB. What format should it be?

**Decision:** JPEG at quality 88, 4:4:4. The three scales total 658 KB.

WEBP was never available: the launch screen is drawn by iOS before Flutter exists, so it is read by the asset catalogue rather than by Flutter, and asset catalogues do not take WEBP. That leaves PNG and JPEG, and the image is a photograph with no alpha.

**Measured on the 3x rather than assumed**, because "PNG is lossless so PNG is better" is the intuition this contradicts:

| encoding | size | worst channel error |
|---|---|---|
| PNG | 2198 KB | 0 |
| PNG, quantised to 256 colours | 1231 KB | 32 |
| JPEG q88 | 375 KB | 10 |

Quantising — the obvious way to shrink a PNG — is **three times larger and three times less accurate** than the JPEG. That is what the scrim does to this image: it compresses the whole picture into roughly 6-114 of each channel's range, which is a narrow band of smooth gradients, the case JPEG handles well and palettes handle badly.

**Cost:** one format exception to explain, and a lossy launch screen. The error is under 10/255 on a picture that is deliberately out of focus behind a 62% scrim, so it is not visible; the entry exists so nobody "fixes" it back to PNG.

## D331 — The launch screen bakes in the scrim, and that is what makes the hand-off invisible

**Question:** Ticket 042 says the launch screen shows `background.png` "with nothing on top of it". The app never shows that picture — it shows it under D296's 62% scrim. Which one goes on the launch screen?

**Decision:** The darkened one. `ios_launch_image` composites `Color(0x9E0B160E)` srcOver the photograph exactly as `ForestBackground` does, then crops it the way `BoxFit.cover` with `Alignment.topCenter` crops it.

**"Nothing on top of it" means no logo and no text, not no scrim.** Shipping the bare photograph would have put a bright forest on screen for a few hundred milliseconds and then darkened it by 62% the instant Flutter's first frame landed — a flash, just not a white one, and criterion 4 is about exactly that class of discontinuity.

**Verified numerically, because the eye is a bad instrument for this.** On a fixed strip of the left margin, the generated file reads `[64.8, 76.0, 55.5]` and the running app reads `[65.4, 76.4, 55.8]` — a difference of about half a level in 255, which is the JPEG quantisation and nothing else. The scrim arithmetic was confirmed independently: applying alpha 0.620 to the source predicts `[65.2, 76.6, 55.8]`, and that is what the app measures.

**A screenshot taken during the app-open animation is not evidence.** One read `[29.1, 51.7, 36.0]` — half the brightness — and looked like a real defect for a while. iOS dims and scales the launch screen while it zooms the icon into place, so any frame captured mid-transition is darker than the asset. The file and the settled app are what can be compared.

**The crop matches the app rather than approximating it.** `BoxFit.cover` against a target narrower than the source keeps the full height and crops the width, which leaves `Alignment.topCenter` no vertical excess to bias — so the app's top-anchoring and a centre crop are the same crop here. The image is authored at 440x956, the narrowest aspect any iPhone has, so `scaleAspectFill` crops a little on every other phone and letterboxes on none.

**Cost:** the scrim constant now lives in two places — `forest.dart` and `artgen.py` — and a change to one silently desynchronises the other. Nothing checks it; the symptom would be a visible brightness step at launch.

## D332 — The source art is named after the catalogue ids

**Question:** `peble.png` and `quarts.png` were delivered misspelt and `artgen.py` carried a filename-to-id map to paper over it (D290). A third arrived misspelt as `ospray.png`. Keep mapping, or rename?

**Decision:** Rename the files. `OPPONENTS` in `artgen.py` is now a plain list of ids, because the source filename *is* the id.

The mapping was the right call at two entries and the wrong one at three. Its stated reason was that the source folder should match what was delivered — but a folder that matches a typo is not matching anything worth preserving, and the cost is a second place to look every time an id and a picture disagree. `art_assets_test.dart` still asserts that every id resolves to a file, which is the property the mapping existed to buy and the only one that ever mattered.

**Cost:** Anyone holding the original delivery has three filenames that no longer match. Git records the renames, so the history follows them.

## D333 — The roster is recut from twenty rungs to thirty-one, and strength follows the rung

**Question:** A beginner climbs 600 → 700 → 800 → 900, and an average player 1000 → 1100 → 1200. A hundred rating points is roughly a week of improvement, so most of a player's time is spent between two rungs rather than on one. Eleven new opponents were commissioned to close that. What happens to the twenty configurations that already exist?

**Decision:** **A configuration belongs to a rung, not to a name.** The thirty-one slots are filled by placing each of the twenty measured configurations at the new rating nearest the one it was calibrated to, and interpolating eleven new ones into the gaps. Where a name moved rungs — Sable from 1700 to 1500, Lyra from 1900 to 1580, Basalt from 1550 to 1800 — the name took on whatever strength its new rung already had, and the strength it used to carry stayed where it was under a new name.

This is D257's rule applied to the other half of the pair. That entry permuted ten *names* so the avatars would read as a progression and moved no configuration, and `doc/history/Avatars.md` states the principle outright: ratings and playing strength are properties of the slot. Doing the opposite here — letting each name keep its configuration and publishing it at a new rating — would have published Sable at 1500 while it measured 1700, which is the one thing the whole calibration apparatus exists to prevent (D144).

The blurbs moved with the configurations rather than with the names, for the same reason: a blurb describes what a player meets at the board. "Looks a move ahead, and spends it on attack" now belongs to Sable, because that is now the two-ply aggressive rung.

Tiers are six / six / six / six / seven. The searching opponents moved from Club to Expert and the node-budgeted ones from Expert to Master, which is what makes room for a Club tier of positional opponents and a Novice tier that reaches 940.

**Eleven of the thirty-one ratings are anchors nobody has measured yet.** The ladder shipped here is principled — good squares then blunder rate in Casual, forcing depth in Expert, budget and defence depth in Master — and it is not calibrated. `calibrate.dart` is what settles it, and it now plays 95 pairs rather than 47, which is the better part of an hour rather than a quarter of one. Until that run happens every new rung's rating is a claim rather than a measurement, and `search_test.dart` deliberately asserts only the pairs that were measured before the recut.

**Cost, and it is the largest single cost in the project so far:**

* **The point totals grew by a factor of two thousand.** `winValue` is 2^i and `unlockCost` is 2^(i+1); eleven new rungs move the top of the ladder from 1,048,576 to 2,147,483,648, and the whole roster from 2,097,088 to 4,294,967,040. **The invariant a player actually experiences is untouched** — four wins at any rung still buys the next one — which is what makes the change acceptable, but the numbers on screen are ten digits at the top. The points balance on the rating card had to become a `FittedBox`: at a 2× font scale it overflowed its row by 43 pixels.
* **Twenty-eight app tests and eleven package tests were fixtures keyed on a roster index**, and every one of them had to move. Nothing was wrong with them; they were asserting real behaviour against numbers that changed underneath.
* **The free set grew from five to seven** without anyone deciding it should, because `isFree` is defined by the 1000 ceiling rather than by a count (D228). That is the rule working exactly as designed — but it doubles what a new player is handed, and it deserves to be noticed rather than discovered.

## D334 — Where the eleven new rungs went

**Question:** Which gaps did the new opponents fill, and why those?

**Decision:** Where a player spends time. Six of the eleven sit at or below 1180 — Hazel 850, Sorrel 940, Juniper 1020, Bracken 1060, Rowan 1140, Aspen 1180 — because that is the stretch a beginner and an average player are on, and it was the stretch with hundred-point gaps. Three more sit between 1340 and 1460, across the old Casual-to-Club boundary, which is the other place the ladder asked for a jump. Only two are above 1580.

The top of the ladder was deliberately left coarse: Basalt to Quadrim Prime still steps in hundreds. Players there are not the ones the recut is for, and a rung every forty points at the top would be a rung nobody could tell apart from its neighbour.

Sorrel is the one new opponent that adds a *rule* rather than a number: it is the first in the catalogue that builds a double threat and still cannot see one coming. That is the honest last lesson of the Novice tier, and it makes 940 a different opponent rather than a slightly better Clover.

## D335 — Fibonacci prices, and a free set that is a count again

**Question:** D333 recut the roster to thirty-one rungs and left the doubling ladder alone, so the top unlock became 2,147,483,648 points and the roster four billion. The invariant a player feels — four wins buys the next rung — was untouched, and the numbers on screen were still unreadable. And the free set had grown from five to seven because the rating threshold said so, not because anyone chose it.

**Decision:** Two changes, both to `points.dart`.

**The win ladder is Fibonacci: 1, 2, 3, 5, 8, 13, 21 …** and an unlock costs twice its own rung — 2, 4, 6, 10, 16, 26 … each price the sum of the two before it. **This is the same relationship the doubling ladder had**, since 2ⁱ⁺¹ is twice 2ⁱ; the shape of the economy is unchanged and only its steepness moved. The top win falls from 1,073,741,824 to 2,178,309, the top unlock from 2,147,483,648 to 4,356,618, and the whole roster from 4,294,967,040 to 11,405,706.

**The free set is the first six, by count.** This reverses [D228](#d228), which made it a rating threshold *precisely* so nothing would have to be kept in step with a number written in words — and the threshold did exactly what it promised: recutting the roster moved the free set to seven without anyone deciding it. That is the argument for a threshold working correctly and producing the wrong answer. Six is the Novice tier exactly, which is what makes it a number worth naming: what is free is the tier a new player starts in, and Bramble at 980 is the first thing anybody buys.

**What was given up, and it is a real promise:** the unlock was *exactly* four wins against the rung below. It is now 2φ ≈ 3.24, which every rung above the second sits within a hundredth of. Exactness went with the powers of two. It is not much missed — a player counts games, and "three or four" is one sentence — but the interface can no longer say a precise number, and §7.2's old claim that wins-only pricing keeps the arithmetic *exact* is now a claim that it keeps it *clean*.

**And the anti-farming property is weaker.** §7.3's whole argument is that grinding a weak opponent prices itself out with no rule to enforce it. Under doubling, a rung down cost a factor of two; under Fibonacci it costs 1.618. Over the thirty rungs from Pebble to Quadrim Prime that is still 4,356,618 games rather than 2,147,483,648 — the same answer for every purpose a person has. Over one or two rungs the pressure to play the strongest opponent you can beat is genuinely milder. That is a softening rather than an oversight, and it is the direction the whole change is going: the request was to make unlocking easier.

**Cost:** Roughly thirty test fixtures moved again, one release after D333 moved them. Several app fixtures had to change *which opponent they farm* as well as how often, because the free set now stops at Sorrel and Bramble is the first purchase — a fixture that earned points by beating Bramble and then bought Bramble was nonsense the old free set had been hiding.


## D336 — Ranking corners first is a style, and a style cannot be a rung

**Question:** The first whole-roster calibration after the recut reported nine ordering inversions. Six were in the Casual and Club tiers, which [D314](#d314) and ticket 044 had already been through once. What was left in there that still produces a cycle?

**Decision:** **Nothing from Bramble to Marlin ranks the corners above the centre any more.** Juniper, Rowan and Vireo did; they now rank centre, then corner, then the rest, like the eight opponents around them.

The measurement is unusually clean for this kind of question. Sort every centre-first opponent in the stretch by its measured rating and the published order comes back exactly — Bracken 1093, Willow 1109, Aspen 1176, Finch 1198, Kestrel 1261, Osprey 1291, Heron 1361, Marlin 1465, eight rungs in a row with not one out of place. Every inversion in the tier involved one of the three corner-first rungs. Vireo was the worst of them: 107 points above its anchor, beating Finch, Kestrel *and* Osprey from below while carrying a worse blunder rate than any of the three.

**This is [D315](#d315) generalised rather than a new finding.** D315 had already measured that eight corner cells beat sixteen corners-first — a result it recorded as surprising and left alone. It stops being surprising once the axis is named: which good squares an opponent prefers is a *style*, and two styles beat each other in a ring, so alternating them up a ladder builds a cycle no matter how the blunder rates are set. §14 of idea-v3.md said as much after ticket 044 and told a rebuilder to space this tier by something monotone. The recut then added four new rungs and spaced them by alternating corner and centre, which is precisely what it had been warned off. That is the actual mistake here, and it is worth recording as one.

**What orders the stretch now:** how many of the sixteen seven-line cells an opponent prefers (none, eight, sixteen), then `lineBias`, then the blunder rate. All three are monotone by construction, so an inversion among them means a defect rather than a rock-paper-scissors triangle.

**Cost, and it is the reason this was not done at ticket 044:** three opponents lose the only thing that distinguished them from a neighbour. Juniper, Bracken and Willow are now the same configuration at three blunder rates, and so are Rowan and Aspen. The roster reads thinner, and their blurbs had to stop promising a corner habit that no longer exists — `blurbJuniper`, `blurbRowan` and `blurbVireo` in both locales. A thin distinction that measures is worth more than a vivid one that inverts, but the trade is real, and a future roster should find a *monotone* axis to put the personality back on rather than reinstating this one.

The blunder rates in the stretch were spread more evenly at the same time, because five of the rungs sat 0.005 apart — below what fifty games can resolve. That part is a guess awaiting the next run, not a measurement.

## D337 — Sable was not weak, it was invisible

**Question:** Sable has a published rating of 1500 and did not appear in the calibration report at all. Not out of tolerance, not inverted — absent. Is the tool wrong or the catalogue?

**Decision:** Neither, and that is the interesting part. `calibrate.dart` discards any pair whose two sides spend different budgets, because a calibration run scales the node and forcing budgets to a tenth and that scaling hits a node-limited opponent hard, a ply-limited one a little, and a rules-only one not at all ([D208](#d208)). Sable took its configuration from Ember in the recut ([D333](#d333)), and that configuration spends *neither* budget — two plies of plain search and nothing else. Every opponent within reach of it spends the forcing budget. So all five of its pairs were discarded and Sable became the one opponent on a thirty-one rung ladder with no measured rating of any kind.

**Sable gains `threatSearchDepth: 2`.** It is the smallest change that puts it on the same footing as Lynx below it and Ember above it, and it is defensible on its own terms rather than only as a fix: Lynx looks two forcing moves ahead and nothing else, Sable now does that *and* searches two plies, and Ember does both one move deeper. It measures from five pairs afterwards.

**What this says about the tool is the part worth keeping.** The exclusion rule is right — a pair measured across that boundary tells you about the budget scale rather than about the opponents. But an opponent excluded from *every* pair vanishes silently, and a silent hole in a report whose whole purpose is to find holes is the worst failure mode it has. The report should say so out loud. It does not yet; that is left open rather than fixed here, because the roster no longer has such an opponent and a check with nothing to catch is hard to trust.

## D338 — More of everything is not more

**Question:** Titan is published at 2200 and configured with a larger node budget, a deeper search, a longer forcing search and one more cell of exact solve than Quartz at 2100. It lost to Quartz 10-17, and to Flint at 2000 by 11-19. Every lever already pointed the right way. What is left?

**Decision:** **Titan's `defenceSearchDepth` goes from 9 to 11**, which is the only lever it did not already lead on — Quartz matched it at 9.

The levers it did lead on are the ones this project has already measured as saturated, and the decision log says so in three separate places. Depth stops separating opponents past three plies ([D154](#d154), [D156](#d156)). A forcing search past eleven moves finds the same wins as one past twenty ([D176](#d176)). And a node budget buys depth, which is the saturated lever, so a bigger budget spent on it buys nothing either. Meanwhile [D169](#d169) measured the *defensive* forcing search at roughly 300 Elo, the largest single strength lever in the project. Titan had been built by adding to the three that do not work and matching on the one that does.

**Confirmed at full budget, and the confirmation is stronger than the fix.** Fifty games a pair with no budget reduction at all: Titan beats Quartz by 115 against a published 100, beats Flint by 241 against a published 200, and Flint beats Cairn by 147 against a published 100. All three rungs are correctly ordered and two of the three sit within sampling noise of their published gaps. The defence lever was the right diagnosis.

**The top of the ladder is compressed and this does not uncompress it.** Cairn, Flint, Quartz and Titan measured 2044, 2117, 2128 and 2109 against published ratings spanning 1900 to 2200 — three hundred points of ladder inside eighty points of measurement. Two rungs of defence will separate Titan from Quartz; they will not separate Cairn from Flint. Part of the compression is the instrument rather than the catalogue, because a tenth of a three-million-node budget is three hundred thousand nodes and the Master tier is the tier the reduction hits hardest. Believing any Master-tier number needs `--budget 1`, which nobody has run since the recut. **That is the honest state of the top four rungs: ordered on paper, unresolved on the board.**

## D339 — A window instead of a chain

**Question:** The calibration harness played adjacent pairs, every pair inside a tier, and one brace between the middle of each tier — 95 pairs at 30 games. Sorrel measured 1127 and Bramble 868, 259 points apart, while the two of them measured *level* head to head at 14-16. Both numbers cannot be right. What sampling produces that?

**Decision:** **Every opponent now plays the five rungs above it — 140 pairs — at 50 games each.**

The old scheme measured each tier thoroughly and the *joins between them* through a single pair. Sorrel is the top of the Novice tier and Bramble the bottom of Casual, so Sorrel's rating was estimated entirely from beating Pebble, Twig, Mote, Hazel and Clover, and Bramble's entirely from losing to Juniper, Bracken, Willow, Rowan and Aspen. Each estimate is honest against the opponents it saw. Nothing tied the two halves together except that one adjacent pair, so the two scales drifted apart and the report presented the drift as a 259-point strength difference between opponents that draw with each other.

A fixed reach deletes the concept of a tier from the sampling. Every rung is tied to the five above it whether or not they share a band, so the scale is pinned continuously from Pebble to Quadrim Prime and no join is thinner than any other point on the ladder. `--only` uses the same window centred on its subject — five above and five below, up to ten pairs — which is the same rule and cannot reproduce [D313](#d313)'s failure of sampling an opponent from a set that happens to exclude the ones that beat it.

**Fifty games rather than thirty** because thirty leaves about 64 points of noise on rungs that are forty apart, so one pair could not distinguish a correct rung from an inverted one; several of the nine inversions in the motivating run sat within a game or two of even. Fifty brings it to about 50. The run is affordable because the 95-pair run took twenty minutes, not the hour `CLAUDE.md` had budgeted for it.

**What is given up is the long brace.** Nothing plays anything more than five rungs away any more, so Hazel against Quartz is gone. Those pairs were swept almost without exception and produced a bound rather than a value, so the loss is small — but they were the only check on the ladder's *absolute* span rather than on its ordering, and if that span is ever in question the brace has to come back.


## D340 — Rungs dealt out by measurement, and the column that is not a ranking

**Question:** After D336–D339 the ladder still reported eight inversions, all of them transitive. A transitive inversion is not a cycle — it is a set of configurations in the wrong order, and the roster has an established move for that: a configuration belongs to a rung rather than to a name ([D333](#d333)). Should the configurations be dealt out in measured order?

**Decision:** **One group moved. Two candidate groups were examined and rejected, and the reasons are the useful part of this entry.**

**What moved: rungs 1140, 1180, 1220 and 1260.** Those four hold one configuration at four blunder rates, and the rates now read 0.10, 0.105, 0.11, 0.115 *up* the ladder rather than down. Measured over fifty games a pair, the one that blunders most beat the one that blunders least, and all six head-to-heads inside the group agreed: 30-19, 28-21, 27-23, 29-20, 27-22, 28-21. Six for six is about 1.6% by chance. Across this range the blunder rate is worth nothing at best and carries the wrong sign at worst.

These four are also safe to judge, which the rest of this entry turns on: every opponent from Pebble to Marlin has no node budget and no forcing search, so the tenth-scale budget a calibration run uses scales *nothing* about them. Their duels ran at full strength.

**What was rejected, first case: the Master tier.** Cairn, Flint, Quartz and Titan measured 2052, 2114, 2138 and 2101, which would deal Titan's configuration down to rung 2000 and Quartz's up to 2200. Declined. The Master tier is separated entirely by node budget, a run cuts that budget to a tenth, and Titan's configuration is the one carrying `exactEmpties: 11` — an exact endgame solve that at 300,000 nodes may consume the budget Flint, which has no exact solve, spends on searching. **The measurement that would justify the move is the one the budget reduction is least able to make.** [D338](#d338) already said no Master-tier number should be believed without `--budget 1`; dealing rungs out on those numbers would be using the report against its own warning.

**That refusal was then vindicated, and by the largest margin available.** Run at full budget, both Master pairings reverse: Quartz went from +83 to **−115** against Titan, and Flint from +95 to **−241**. Dealing those rungs out by the reduced-budget numbers would have moved Titan's configuration down to 2000 and Quartz's up to 2200 — permanently, and in exactly the wrong order. **A reduced budget does not blur a Master-tier result, it can invert it**, which is a stronger claim than [D338](#d338) was able to make and the reason this entry exists.

**What was rejected, second case — and this one was rejected only after being implemented and reverted.** The measured column put Bramble at 959 and Sorrel at 1062, so the three configurations at rungs 900/940/980 were rotated to put all four rules at the bottom. That was wrong, and the head-to-heads say so plainly: Sorrel's configuration loses 16-34 to Juniper, 15-35 to Bracken and 17-33 to Willow, every one of them a rung it supposedly outranked. Meanwhile Clover loses to Sorrel 12-38 and to Bramble 18-32, and Sorrel and Bramble draw 25-25. **The published order down there was already right, and the tool never reported an inversion among the three.**

**Why the column lied, because it will lie again the same way.** Each opponent's estimate is the mean over its pairs of the *other side's published rating* plus the measured gap. Pebble plays some 400 points below its published 600. Sorrel is within five rungs of Pebble and Bramble is not — so Sorrel banks a swept 49-1 win credited from an anchor that is wrong by 400 points, and Bramble banks nothing of the kind. The estimate is not a strength ranking; it is a strength ranking plus the error in every anchor within reach. **Near a broken anchor, only the head-to-head scores mean anything**, and the inversion list — which is computed from head-to-heads and not from the estimates — is the part of the report to trust.

That makes fixing Pebble a precondition for reading the bottom of the ladder at all, not a cosmetic tidy-up. It is the largest single source of error in the report and it contaminates the ten rungs above it.

**One rule was bent.** Blunder rate is no longer strictly non-increasing up the roster; `strategic_bot_test.dart` allows 0.01 of slack, which is what the four reversed rungs need and little enough to still catch an opponent handed a wildly wrong rate.

**Cost.** Four blurbs moved with their configurations, in both locales, and they now read oddly against the ladder: the 1180 rung "seldom wastes a turn" while the 1260 rung "still drops one now and then". Both sentences are true of the configurations that now sit there. The real problem underneath is that **those four opponents are not distinguishable in play at all**, which spec §6.4 requires and this stretch does not deliver — D336's unpaid bill, since removing the corner ranking removed the only other thing separating them. `lineBias` is the lever that should replace it: monotone, and measured at 60–120 points per 0.05 step.

**And this fixes ordering, not spacing.** Where two configurations are genuinely five points apart and the roster claims forty, the sign of the measured gap is a coin flip and the inversion will return at random on some future run. Dealing rungs out absorbs a residual misplacement; it is not a substitute for a lever that produces forty-point steps.

## D341 — Pebble takes some of its wins, and the report stops trusting its anchors

**Question:** Pebble measured 400 points below its published 600 and, because every estimate in the report is another opponent's published rating plus a measured gap, that error was banked by every rung within five of it — which is how [D340](#d340) came to rotate three configurations that were already in the right order. Fix the report, fix the opponent, or both?

**Decision:** Both, and neither is a workaround for the other.

**Pebble gains `winNow` with a blunder rate of 0.71.** It was purely random, and purely random is not 600: it lost 1-49 to Twig, whose only advantage is that one rule. **So on this board `winNow` is worth nearly seven hundred points**, and no gap of a hundred can be built across it by giving the rule to one side and not the other. Pebble now has the rule and misses most of what it offers. Measured over a thousand games it sits 97 points below Twig against a published 100 — the closest fit on the ladder, and it took a sweep of blunder rates to find, because the relationship is steeply non-linear: 0.30 gives −10, 0.65 gives −78, 0.72 gives −117.

**The blunder rate is the only lever Pebble has, and it did not have it before.** With no rules there is nothing for a blunder to discard, so the old configuration played identically at every setting — which is why this rung could not be moved at any price and had to change what it *knows* before it could change how well it plays.

**What this costs is the personality.** Pebble was "drops pieces wherever they fall, has never noticed a threat", and it now notices roughly one threat in three. That is a real loss — the absolute-beginner rung is less absolute than it was — and it is not optional, because the alternative is a published rating that overstates the opponent by 400 points. A player's rating is earned against these anchors, so beating a 200-strength opponent labelled 600 credits them for something they did not do. `blurbPebble` changes in both locales.

**And `calibrate.dart` now reports the median of an opponent's per-pair estimates rather than the mean.** Each estimate carries its partner's anchor error in full, so a single wrong anchor moves the mean of ten pairs by a tenth of its error — enough, at 400 points, to report Sorrel above three rungs that beat it 34-16, 35-15 and 33-17 on the board. A median cannot be moved far by one outlying pair. **The report exists to find anchors that are wrong, so it must not assume they are right**, and the mean quietly did.

**What is left, and it is not Pebble's to fix.** Pebble still measures 174 below its anchor, because the bottom of the ladder is roughly twice as steep as it is published: Pebble to Sorrel is 340 points on paper and 676 on the board, and the same is true of Hazel and Clover at −424 and −552 against −250 and −300. Pebble's *adjacent* gap is now exact; the rungs above it are too strong for the rest of the span. That is a Novice-tier spacing problem and it belongs to those four configurations, not to this one — and it is newly visible only because the opponent that was drowning it has stopped.

## D342 — A reduced budget inverts the top of the ladder, and what a full-budget run actually costs

**Question:** [D208](#d208) scales every node and forcing budget to a tenth so that a whole-ladder calibration takes minutes instead of hours, on the argument that the ordering question survives the reduction because every opponent is reduced by the same factor. Does it?

**Decision:** **Not at the top of the ladder. Record the reduction as unsafe for any node-budgeted opponent, and settle those pairings with `duel.dart`, which never scales.**

Measured both ways, fifty games a pair:

| pairing | published | at 10% | at full budget |
|---|---|---|---|
| Quartz → Titan | −100 | **+83** | **−115** |
| Flint → Titan | −200 | **+95** | **−241** |
| Cairn → Flint | −100 | −23 | −147 |

Two of the three **change sign**. That is a different failure from the one D208 anticipated: it assumed the reduction costs precision, and the reduction costs *direction*.

**Why, and it is visible in the timings.** A Master-tier move has a median cost of **0 ms** and a mean of about 900 ms, with a worst case near 12 seconds. Almost every move is decided instantly by the book, by a rule, or by a forced win already in view; the tier's entire separation lives in a handful of genuinely hard positions a game. Cutting the budget to a tenth does not weaken these opponents evenly — it leaves the cheap moves untouched and removes precisely the deep search that distinguishes one rung from the next. The opponent that suffers most is the one whose budget was doing the most work, which is the strongest one, which is why the result inverts rather than merely narrowing.

D208's argument holds where it was made: below Lynx nothing spends a node or forcing budget at all, so the reduction is a no-op and those fourteen rungs are measured exactly. It is the extrapolation upward that fails.

**What a full-budget run costs, having now measured it rather than guessed.** The three pairings above took roughly 25, 15 and 9 minutes of compute for 50 games each — the spread is wide because Cairn and Flint are three times cheaper per move than Titan. A `--budget 1` pass over Lynx upward is about 65 pairs, of which some 35 involve the Master tier; at those rates it is an **overnight job of eight to ten hours**, not the four to six first estimated and not the several days feared when the first pairing ran long. A full-budget run of the *whole* roster would be the same figure plus nothing useful, since the rungs below Lynx cannot change.

**What this does not fix.** Cairn to Titan is 300 published points and the full-budget gaps across it total 388, so the ordering is right and the spacing is loose rather than compressed — the reverse of what the 10% run appeared to show. Whether the four rungs are *evenly* spaced is a question only the overnight run can answer, and nothing should be tuned on the strength of three pairings.

**And one number to check on hardware.** Titan's worst move here was 11.8 seconds against [D164](#d164)'s twenty-second ceiling. That ceiling is a phone number and this is a desktop measurement, so the headroom is unverified rather than comfortable.

## D343 — The levers were cliffs, so they were given dials

**Question:** [D341](#d341) fixed Pebble's anchor and, with it out of the way, the shape of the bottom of the ladder became readable: from Hazel (850) to Juniper (1020) the roster asks for 170 rating points and the configurations delivered **618**, while from Juniper to Willow it asks for 80 and delivered **12**. Every rung down there was either a cliff or a no-op. Why, and what fixes it?

**Decision:** **Two new fields, `BotConfig.ruleChance` and `BotConfig.positionChance`, and the whole stretch from Clover to Marlin re-spaced as a ramp.**

**The cause, measured in isolation rather than argued.** Holding everything else equal and running a thousand games a pair:

| lever | worth |
|---|---|
| a preference for the sixteen seven-line cells | **162** |
| `makeDoubleThreat` | **100** |
| `blockDoubleThreat` | **128** |
| the blunder rate | **~6 points per 0.01** |

The rungs in this stretch are forty to fifty points apart. So every rule and every positional preference overshot its rung by three or four rungs' worth, and any rung that introduced none of them was left with the blunder rate, which cannot cover forty points without moving a quarter of the way across its whole usable range. There was no arrangement of these levers that produced an ordered ladder — not a tuning failure but an arithmetic one, and the same shape of finding as [D336](#d336)'s.

**The fix is to stop introducing them all at once.** `ruleChance` gives each strategic rule a probability of firing; `positionChance` gives the positional preference a probability of being consulted at all. A rule worth 100 points introduced at a chance of 0.05 is worth about five. The cliffs become dials, and the ladder becomes a ramp: `makeDoubleThreat` climbs 0.05 → 0.10 → 0.16 → … → 1.0 across fourteen rungs, `blockDoubleThreat` behind it, `positionChance` behind that, and the blunder rate falls underneath all three.

**What it measures.** Eleven consecutive adjacent gaps, six hundred games each, against a published forty (fifty for the first):

| pair | before | after |
|---|---|---|
| Hazel → Clover | −247 | **−45** |
| Clover → Sorrel | −188 | **−41** |
| Sorrel → Bramble | **+17** | **−37** |
| Bramble → Juniper | −200 | **−46** |
| Juniper → Bracken | −42 | −42 |
| Bracken → Willow | −7 | **−40** |
| Willow → Rowan | −200 | **−40** |
| Rowan → Aspen | **+78** | **−50** |
| Aspen → Vireo | **+49** | **−42** |
| Vireo → Finch | **+28** | **−50** |
| Finch → Kestrel | −49 | −54 |

Four of those were inversions and two were five-fold cliffs.

**It also describes something real**, which matters more than it sounds. An opponent that has heard of forks before it reliably spots them, and notices the middle of the cube before it always plays there, is how people actually learn this game. The previous ladder said a player goes from never having heard of a double threat to always seeing one, in one rung.

**Three consequences worth recording.**

*[D340](#d340)'s blunder reversal is superseded.* That entry had to let the blunder rate *rise* across four Club rungs, because those four were one configuration at four rates and measured in the opposite order to the one the rates implied. They are no longer one configuration — three dials separate them — so the blunder rate falls monotonically again and `strategic_bot_test.dart` asserts it strictly. The spec §6.4 complaint that those four were indistinguishable in play goes with it.

*Clover and Sorrel lose their corner preference.* A preference is 162 points and their rungs are fifty. Board sense now starts at Juniper behind `positionChance` and arrives a fraction at a time. Their blurbs change in both locales, and the Novice tier's character becomes learning the *rules* rather than learning the board — which is the better story for it anyway.

*Both fields are inert at their defaults, deliberately.* A chance of 1 draws no random number, so no opponent that predates them moved by a single move: `hazel vs clover` measured −247 before the fields existed and −247 after. A test pins that property rather than trusting it, because it is what let this ship without re-measuring the roster.

**What is not fixed, and cannot be with these two dials.** The last four gaps — Kestrel to Osprey to Heron to Marlin to Lynx — measure 104, 92, 67 and 90 against a target of forty. They are even and correctly ordered, but roughly twice too steep, and no setting of the dials fixes them: **a dial can only weaken an opponent, so the span between two fixed configurations is an invariant.** Hazel's configuration and Lynx's are about 880 Elo apart and the roster allots them 610. The excess can be moved but not removed, and it settles at the top because Lynx's forcing search is the first lever these dials do not reach. Closing it means bringing the Master tier's node budgets down — a real lever, and the one place D144's "change the configuration" still has room — and that should wait for the full-budget run [D342](#d342) describes.

**Cost.** Fourteen catalogue entries rewritten with their doc comments, four pinned test values moved, two blurbs, and one test in `deep_search_test.dart` that turned out to generate its endgame fixtures by self-playing **Kestrel** — so re-spacing the Club tier changed which positions it reached and a *proof* test failed on its sample count rather than on the solver. That fixture is now a frozen configuration owned by the test. A tuning pass on the roster must not be able to break a proof.

## D344 — The cheap pairs play four times the games, and Heron is not a defect

**Question:** The run that measured [D343](#d343)'s ramp put every anchor inside tolerance for the first time, and then reported five inversions. Two were the known Master-tier budget artefacts ([D342](#d342)). The other three — Clover over Sorrel, Willow over Rowan, Aspen over Vireo — contradicted duels of six hundred games each that had measured those same pairs at −41, −40 and −42, the right way round. Which is wrong, the run or the duels?

**Decision:** Neither. **The rungs are now finer than the instrument resolves**, and the fix is to play more games where they are cheap.

Sampling noise at fifty games is about 49 rating points and the ladder's rungs are forty apart. A *perfectly ordered* ladder therefore reports a couple of inversions per run purely by chance, and three is what turned up. That is not a defect in the roster; it is the report telling the truth about its own precision, and it becomes actively misleading once the ladder is good enough that real inversions are rare — every run would name a different innocent pair.

**Every pair in which neither side searches now plays `kCheapGamesFactor` — four — times the base count.** Noise falls with the square root, so two hundred games brings it to about 25, comfortably under a rung. The choice of *which* pairs is the whole trick: the opponents below Lynx are exactly the ones with forty-point rungs **and** exactly the ones that decide a move in microseconds, so the resolution is free. The Master tier keeps the base count — its rungs are a hundred points apart and a single pair there is twenty minutes.

The reported noise line now prints both figures rather than one, because a run no longer has a single precision.

**And Heron's +122 was investigated and is not Heron's to fix.** It was the one error the run flagged that looked like a genuine configuration defect. It is not: the adjacent chain from Vireo reads 50, 54, 104, 92 — three hundred points where the roster publishes 160 — and the direct Vireo–Heron pair measures −312, agreeing with the chain. Heron simply sits where the accumulated excess of the too-steep top becomes visible in the estimate column.

Weakening it was tried and measured rather than reasoned about. `osprey → heron` improved from 92 to 53 and `heron → marlin` degraded from 67 to 121 — the total went from 159 to 174 and the distribution became *less* even. **The excess is conserved**, exactly as D343 predicted it must be: a dial can only weaken, so the span between two fixed configurations is an invariant and tuning a rung inside it moves points from one side to the other. The change was reverted.

What that leaves is a clean statement of the last open problem on the ladder: **Kestrel to Lynx is about twice as steep as published, and nothing between them can fix it.** The span shrinks only if one of the endpoints moves, which means bringing the Master tier's node budgets down — the one place D144's "change the configuration, never the rating" still has room, and work that should follow the full-budget run D342 describes rather than precede it.

## D345 — The privacy manifest declares one API, and no dependency declares it for us

**Question:** Ticket 043 says to declare the required-reason APIs the app reaches, and adds: "**Check the plugin manifests too**: `path_provider` ships its own privacy manifest, and Xcode merges them, so the app's file declares what the *app* does, not what its dependencies do." Is that division still right?

**Decision:** `ios/Runner/PrivacyInfo.xcprivacy` declares `NSPrivacyTracking` false, an empty `NSPrivacyTrackingDomains`, an empty `NSPrivacyCollectedDataTypes`, and exactly one accessed-API entry: `NSPrivacyAccessedAPICategoryFileTimestamp` with reason `C617.1`.

**The ticket's premise about the plugin is no longer true, and that is why the entry has to be here.** `path_provider_foundation` 2.6.0 has no native code at all — its pubspec declares a `dartPluginClass` and its package directory contains no Swift and no `.xcprivacy`. It reaches Foundation through `objective_c` FFI bindings from Dart. A plugin with no bundle has nothing to carry a manifest in, so there is no dependency manifest to merge and nothing declares the file-timestamp access on the app's behalf. Checked on the built app rather than inferred: the only other `PrivacyInfo.xcprivacy` in `Runner.app` is `Flutter.framework`'s own, which covers the engine, not us.

**The reach is real and was traced to a line, not guessed.** `DocumentStore` enumerates its two directories with `Directory.list()` (`document_store.dart:64` and `:89`), which lands on Foundation's directory enumeration — on Apple's required-reason list under the file-timestamp category. `C617.1` is the app-container reason, which is exactly the case: the files are this app's own and their timestamps never leave the device.

**Nothing else on the list is reached.** No `UserDefaults` (no `shared_preferences` — the only runtime dependency with a platform side is `path_provider`), no disk-space query, no active-keyboard or system-boot-time access from app code.

**The file is in the Runner target's resources, not merely on disk.** A manifest that is not in Copy Bundle Resources ships nothing and fails silently, so it was added through the `xcodeproj` gem and then confirmed in the built product: `Runner.app/PrivacyInfo.xcprivacy` exists and reads back with the four keys above.

**Cost:** one more thing that must be revisited when a dependency is added, and no mechanism that will notice if it is not. The failure is an email from App Store Connect after upload rather than a build error — ticket 043 says so, and it remains true.

## D346 — The unlocks are backed up, and not from the directory the ticket named

**Question:** D11 says a restore onto a new device returns every unlock the player earned. Ticket 043 argues this already holds on iOS because "the app's `Documents` directory is backed up to iCloud by default, and `path_provider`'s `getApplicationDocumentsDirectory()` maps to exactly that". Does it?

**Decision:** The guarantee holds. The stated reason does not, because this app never calls `getApplicationDocumentsDirectory()`.

`main.dart:30` calls `getApplicationSupportDirectory()` and opens the store at `quadrim/` beneath it — chosen for Android, where it resolves to `files/quadrim/` and is precisely the path the backup allowlist includes (D131). Confirmed on iOS by looking in the container rather than by reading the code: the store lands at `<container>/Library/Application Support/quadrim/`, holding `games/`, `unlocks/` and `settings.json`.

**That directory is backed up.** iOS backs up everything in the app container except `Library/Caches`, `tmp`, and anything explicitly flagged `NSURLIsExcludedFromBackupKey`. `Library/Application Support` is none of those, and nothing in this repository sets that flag anywhere. The app's own `Library/Caches/nl.evict.quadrim` holds Metal shader caches, which is regenerable data correctly outside the backup.

**So one platform's guarantee is an allowlist and the other's is a default**, and they happen to agree because the same path was chosen once for Android's sake. That is a coincidence worth naming: a future change of storage directory made for an Android reason would silently move the iOS backup guarantee with it, in whichever direction.

**Apple's "don't back up regenerable data" guidance does not bite**, for the reason ticket 043 gives: unlock records are precisely the *non*-regenerable data. Balances, streaks, quest progress and statistics are all folds over game history (§7.4) and would survive being thrown away; an unlock is a fact about what the player earned and exists nowhere else.

**Cost:** the mechanism is confirmed and the *outcome* is not. Only a real backup and a real restore onto another device settles AC 1, and that needs two devices and a person.

## D347 — On iOS the no-network claim is a review, and the review is recorded

**Question:** On Android, "computer play makes no network call" is enforced by the absence of `INTERNET` from the release manifest, and `check.sh` fails if it appears (D212, and the check is still there at `tool/check.sh:54`). iOS has no permission to withhold. What is the claim worth there?

**Decision:** It is a **review, not an enforcement**, and it is stated at that strength rather than at Android's (S20, D306). The review was done and this is its result.

- **Runtime dependencies are unchanged since 0.2**: `flutter`, `flutter_localizations`, `intl`, `path_provider`, and the three local packages. Nothing was added between there and here.
- **One plugin has an iOS side**, `path_provider_foundation`, and it resolves container paths. It opens no socket.
- **There is no `Podfile.lock` to audit** — D325, iOS resolves through Swift Package Manager — so the artefact ticket 043 names for this check does not exist. What was audited instead is the generated SPM package, whose only dependency is `FlutterFramework`, and the frameworks actually bundled into `Runner.app`: `App.framework`, `Flutter.framework`, `objective_c.framework`. No networking library among them.
- **The engine packages cannot reach a network by construction.** `quadrim_engine`, `quadrim_rating` and `quadrim_progression` may declare no runtime dependencies and may not import `dart:io`, and `check.sh` greps for it. That half *is* enforced, on both platforms, and it is the half that contains computer play.

**What is not enforced on iOS is the app layer.** Nothing would stop a future `HttpClient` in `app/lib` from compiling and running on iOS, where on Android it would fail at runtime for want of the permission and fail at commit for want of `check.sh`. That asymmetry is real and is the honest content of this entry.

**Cost:** an iOS-side claim resting on a reading of the dependency graph at one moment. It should be re-read whenever `pubspec.yaml` gains a dependency, and nothing will remind anyone to do so. Narrowing `check.sh` to computer play rather than to the manifest — already flagged as the 0.3a Firebase problem — would let one mechanism cover both platforms, and is the real fix whenever someone wants it.

## D348 — The one-time unlock is materialised into unlock records, not held as a flag

**Question:** Owning "unlock all opponents" could be a boolean the roster consults, or thirty-one `UnlockDocument`s written at `UnlockSource.purchase`. Which?

**Decision:** Both, with the entitlement as the authority and the records as its consequence. `Shop._grant` sets `Entitlement.unlockAll` and then calls `grantAllPurchased()`, which writes a record for every opponent not already unlocked.

**A flag alone fails two acceptance criteria.** AC 7 wants points-earned and bought-outright distinguishable in storage, and AC 6 wants a refund to revoke exactly what it bought and nothing the player earned. Both are questions about *records*, and a boolean has none to answer with. `UnlockSource.purchase` has existed since ticket 031 for precisely this, with a comment saying it is unreachable until the product exists. It is reachable now.

**Records alone fail differently:** they are a copy of a store answer, and a copy that disagrees with the store is the thing D303 exists to avoid. So the entitlement is what is believed and the records are what is written from it, re-derived at every launch — which also means an opponent added in a later release is covered the next time the app starts, with no migration.

**`pricePaid` is zero on every record written this way.** The balance is earned minus the sum of these (§8.8), and the player paid the store rather than the points balance; any other number would bankrupt someone for buying the unlock.

**Idempotent, and it refuses to overwrite.** An opponent already unlocked keeps its existing record, so an unlock earned with points stays `UnlockSource.points` and survives a later refund. That is the property AC 6 actually turns on, and it is tested.

**Cost:** thirty-one small writes on the launch after a purchase, and two representations of one fact that must not drift. What keeps them from drifting is that only one of them is ever *read* as authority.

## D349 — Entitlement is rebuilt every launch and never written to disk

**Question:** The store is slow and sometimes unreachable. Should what the player owns be cached locally so the app knows it before the store answers?

**Decision:** No. `Entitlement` is an in-memory value that starts empty at every launch and is populated by the restore that `Shop.start()` performs.

**A cache is a second answer, and it is wrong exactly when it matters.** The store's signed transaction is the authority at 1.0 (D303, spec S9), there is no server and no receipt validation of our own. A cached entitlement disagrees with the store in precisely one situation — a refund, chargeback or lapse that the cache has not heard about — and in that situation the cache is the one still saying yes. Persisting it would convert "revocation follows the store's next refresh" into "revocation never happens on this device".

**This is also what makes the lapse test writable.** A lapsed subscription is modelled as nothing more than a fresh launch where the store no longer re-delivers it, because that is all it is.

**The cost is honest and is the reason it is written down.** Between launch and the store's answer, the app believes nothing is owned. A paying player who opens the app on a plane sees the unpaid state. 047 owns what that looks like on screen; what it must not do is guess in the player's favour and then take something away, which is worse than the wait.

## D350 — Buying the whole roster gets its own method, so D229 stays categorical

**Question:** `LocalGameRepository.purchase` throws unless the opponent is the lowest-indexed locked one (D229). The one-time unlock has to bypass that. Add a flag to `purchase`, or add a method?

**Decision:** A method — `grantAllPurchased()`, beside `revokePurchasedUnlocks()`.

**A flag would make D229 conditional in the one place that enforces it.** "Four wins buys the *next* opponent" stops being a promise the moment the method carrying the rule also carries a way to skip it, and the flag's default becomes the only thing standing between the ladder and a caller that passes `true` for an unrelated reason. Two methods keep the rule absolute where it is written and put the exception somewhere it can be read as an exception.

**Revocation is the mirror and is equally narrow.** `revokePurchasedUnlocks` deletes records whose source is `purchase` and nothing else. No billing event on the *subscription* reaches it: §4.1 says losing the subscription loses unmetered play and nothing more, and the way to be sure of that is that no code path exists from one to the other.

**Cost:** `DocumentStore` gained `deleteUnlock`, so unlocks are now deletable where before they were append-only. That is a sharper tool than the app previously had, reachable from exactly one caller.

## D351 — The shop starts without being awaited, and subscribes before it awaits anything

**Question:** `Shop.start()` reaches the network. Where in launch does it go?

**Decision:** After the repository, before `runApp`, and **not awaited** — `unawaited(shop.start())`.

**Awaiting it would make a bad connection into a hung launch**, for a game whose entire premise is that computer play needs no network at all (D93, S1, and on Android enforced by the absence of `INTERNET`). Nothing on the first screen depends on knowing what is owned.

**But the order inside `start()` is load-bearing.** It attaches the purchase-stream listener *first*, before any `await`. The plugin delivers purchases interrupted by a crash, a lost connection or an "Ask to Buy" approval on the first stream event after launch; a listener attached after the product query would miss them, the store would redeliver forever, and a player would have been charged for something they never received. That is AC 4, and it is a property of statement order rather than of anything visible in a type.

**Every delivered purchase is completed, including errors and cancellations.** The completion call sits outside the status switch on purpose — the plugin marks exactly which ones need it, and an uncompleted purchase is redelivered on every launch for the life of the install.

**Cost:** the entitlement arrives some hundreds of milliseconds after the first frame, so anything drawn from it must tolerate starting empty. That is 047's problem and it is now stated in advance.

## D352 — The wall is checked twice, and only one of the two is the guard

**Question:** Where does the cap refuse a game — before the player picks an opponent, or at the single place a game is created?

**Decision:** Both, and they are not the same kind of check.

`_start` is the guard. It is the one place a game is created, which is why D322's resume rule lives there too, and it is reached by the challenge button and the rematch path as well as by the new-game flow. A check anywhere else can be walked around; this one cannot.

`_newGame` checks as well, immediately after the mode is chosen and **before** the opponent list is pushed. That one is not a guard — if it were deleted nothing would get through that `_start` does not already stop. It exists so the refusal does not arrive *after* the player has chosen who to play, which reads as the app changing its mind.

**The order inside `_start` is what makes criterion 3 true.** The resume loop runs first and returns for a game already in progress, so finishing one is never refused; the `mode` check means pass and play is never refused; and the tutorial's practice game never reaches this method at all, because it is not stored — which is also why it is not metered (§4.2).

**Cost:** two call sites of one condition, and if the meter's meaning ever changes, both must move. The alternative was one check in the wrong place, which is worse in a way the player would feel.

## D353 — A missing settings document means unmetered, and that hole is deliberate

**Question:** `MeterState` treats a null `FreeMonth` as unmetered — nothing is ever blocked. The home screen's settings document arrives asynchronously, so for the first frames after launch it is null. Does the wall therefore leak?

**Decision:** Yes, briefly, and that is the right direction to fail.

`meter_fold.freeMonthFrom` returns null when `freeMonthStartedAt` has never been stamped or cannot be read, and `meterState` reads null as "no cap applies". It was written that way for damaged records: a player whose settings document is unreadable must fail towards being allowed to play rather than towards a wall nobody can explain. The loading window inherits the same behaviour for free.

**What it costs is bounded and small.** The window is between first frame and the settings stream's first event — one or two frames — and reaching the wall inside it requires tapping New game and choosing the computer within that time. A player who managed it would get one extra game, once, on a meter that is device-local at 1.0 anyway (S19).

**What the alternative costs is worse.** Blocking while settings are unknown means a player whose storage is briefly slow is told they have used games they have not, and that is the failure the whole of D221 is about: the app must not appear to misunderstand its own rules.

## D354 — The volume-quest restriction is computed from the cap, not from a flag on the quest

**Question:** §7.4 says no free player can complete even the first rung of the volume ladder. Should the quest carry that fact, or should the tile derive it?

**Decision:** The tile derives it, from `family == QuestFamily.gamesInDay` and whether the cap currently applies.

**The restriction is arithmetic, not policy.** Five games in a day exceeds a free cap of three; that is the whole of it. Marking the quest itself would put a `subscriberOnly` field in `quadrim_progression`, which is a package that may not know what an entitlement is — the same line §7.1 draws when it forbids the engine a `locked` field on `BotConfig`. It would also go stale the moment either number moved.

**"Currently" is doing work in that sentence.** The tile is unmarked inside the free month and unmarked for a subscriber, and the entitlement starts empty and fills in after the store answers (D349) — so a paying player may see the mark for a fraction of a second at launch. That is the acceptable direction: briefly under-promising to someone who has paid is recoverable, and telling a free player a rung is reachable when it is not is the thing §7.4 exists to prevent.

**Cost:** if a later release changes the daily cap to five or the first volume rung to three, this tile lies and no test fails, because nothing connects `kDailyLimit` to `_volumeTargets.first`. That connection is the honest thing to add if either number is ever touched.

## D355 — A release build without the upload keystore fails, and ticket 015 was wrong about Android signing

**Question:** The Google Play account is active again, so the Android upload that [D302](#d302) parked is live work. Ticket 015 records Android release signing as **done** — "met for the 0.1 and 0.2 builds", with a signed build ticked as installed on a physical device. Is it?

**Decision:** No. `app/android/app/build.gradle.kts` still carried the Flutter template verbatim:

```kotlin
// TODO: Add your own signing config for the release build.
// Signing with the debug keys for now, so `flutter run --release` works.
signingConfig = signingConfigs.getByName("debug")
```

There was no `key.properties` and no keystore anywhere in the tree. Whatever ran on a device for 0.1 and 0.2 was signed with the debug certificate, which Play rejects on upload. **The ticket recorded an intention as an outcome**, and the only reason it cost nothing is that nothing was ever uploaded.

**The fix is not to add a signing config but to delete the fallback.** The template's default is the actual defect: it signs a release with the debug key and says nothing, so the failure surfaces at the store rather than at the build — or, as here, does not surface at all and gets written down as success. A missing `key.properties` now throws at configure time for any task whose name contains `Release`. Verified both ways: `flutter build appbundle --release` fails with the message, `flutter build apk --debug` builds clean.

**The keystore lives outside the repository, not merely outside git.** `key.properties` names an absolute path. `.gitignore` already listed `**/*.jks`, but a rule is a habit with a config file — `git add -f` beats it and so does an accidental edit — so `check.sh` now asks git what is *tracked* rather than trusting what is *ignored*. That closes ticket 015's "a check enforces this", which had been open since the ticket was written.

**What this does not do.** It produces a signable build; it does not produce a signed one. `keytool` needs passwords, so generating and backing up the key stays with the developer, and ticket 015's backup-and-restore-verify criterion is untouched by any of this.

**And it puts [D306](#d306)'s empirical question on the critical path.** Whether Play Billing's manifest merge injects `INTERNET` — and therefore whether `check.sh`'s categorical grep survives on Android — is answered by the first internal-track install, not before it. The upload is now the experiment.

**Cost:** a developer without the keystore can no longer run `flutter run --release`, which the template's fallback allowed. For a one-developer project that is the correct trade; on a team it would need a second path, and the honest one is a debug-signed *build type* that is named as such rather than a release that quietly is one.

## D356 — Billing brings `INTERNET` after all, and `check.sh` has been grepping the wrong file since D212

**Question:** [D306](#d306) parked one thing to be "checked empirically at implementation time, not assumed either way": whether Play Billing's manifest merge injects `INTERNET`. The first release bundle makes it answerable. Does it?

**Decision:** **Yes, and the check that was supposed to catch it cannot see it.** Two findings, the second worse than the first.

**One: `INTERNET` arrives, from a library nobody chose.** Not from `billing:8.0.0`, whose manifest declares only `com.android.vending.BILLING`, and not from `in_app_purchase_android`, whose manifest is empty. It comes from `com.google.android.datatransport:transport-backend-cct:3.1.8` — Google's telemetry transport, transitively behind billing — which declares both `INTERNET` and `ACCESS_NETWORK_STATE`. The shipped `app-release.aab` carries `INTERNET`, `ACCESS_NETWORK_STATE`, `BIND_JOB_SERVICE` and `DUMP`.

**An intermediate conclusion here was wrong and is recorded rather than quietly fixed.** Reading the two obvious AARs and finding no `INTERNET` produced a confident "the check survives unchanged". The AAR scan was the wrong instrument: it enumerated the dependencies that were *thought of* instead of asking the merger what it actually produced. `manifest-merger-blame-release-report.txt` names the contributor of every line and would have answered it in one grep. **Read the artifact, not the inputs** — the same lesson [D341](#d341) records about trusting an estimate column over a head-to-head score.

**Two, and this is the real defect: `check.sh` greps `app/android/app/src/main/AndroidManifest.xml`.** That is the *source* manifest. The permission that ships comes from the *merge*. So the check passes — it passed on this very build — while the artifact it is supposed to be guarding declares the permission it exists to forbid.

That has been true since [D212](#d212) and was invisible for as long as nothing merged a permission in. D212's claim was that "the strongest available guarantee is not a code review but the permission itself"; what was implemented is a grep of a file that does not determine the permission. **The guarantee was never enforced — it merely had nothing to catch.**

**Cost, stated plainly:** every release built before this one would have passed the check with any permission a dependency cared to add. Nothing did, so nothing shipped wrong, and D93's substance ("computer play makes no network call") was never violated because no code makes one. What was lost is the claim that a mechanism rather than a promise was holding it — and that claim is in the spec, in `check.sh`'s own comment, and in [D306](#d306)'s account of what iOS gives up relative to Android. All three overstate what Android was doing.

**What is not yet decided** is whether to strip the permission with `tools:node="remove"` and keep the guarantee categorical, or to accept it and narrow the check to computer play. That turns on whether `BillingClient` still works without `INTERNET` — it binds to the Play Store over IPC and the Play Store does the networking, so it should — and that is a measurement on the internal track, not an argument. Left open deliberately: this entry records what is true, and the next one records what was chosen.

## D357 — The permission is stripped from the merge, and the check now tests the artifact

**Question:** [D356](#d356) left two things open: whether to strip `INTERNET` or accept it, and what to do about a check that was grepping a file which does not determine the shipped permission. Both are decided here.

**Decision: strip it, with `tools:node="remove"`, and rebuild the check around the merged manifest.**

**Why strip rather than accept.** Accepting would have meant narrowing the check to computer play, which [D212](#d212) already anticipates for 2.0's Firebase work — the simpler route, and the one with no risk to purchases. It was declined because of *what* brings the permission. This is not billing needing a socket; it is `transport-backend-cct`, a telemetry transport, riding in behind billing. Accepting the permission to keep a library quiet that nobody asked for, in a project whose privacy claim is "the platform refuses the call", is paying the whole price of the compromise for none of its benefit. Removing it leaves billing to reach the Play Store over IPC, which is how it works anyway, and leaves the transport unable to do the one thing it exists for.

**`ACCESS_NETWORK_STATE` is deliberately left in place.** It grants no access — only the ability to ask whether a network exists — and stripping permissions a dependency declares is something to do for a reason. There is a reason for `INTERNET`; tidiness is not one for this.

**The check now tests three things in increasing order of authority**, replacing one grep that tested none of them:

1. Our own manifest declares no `INTERNET` — a line carrying the removal directive is excluded by name, since it is the fix rather than the violation.
2. The removal directive is present. **Absence is no longer sufficient**, because absence is exactly the state in which the permission shipped.
3. If a merged release manifest exists on disk, it is checked, and that is the authority. When it does not exist the run *says so* rather than passing quietly — a check whose limits are invisible is how D356 survived from D212 until the first bundle.

**What step 3 still cannot do.** `check.sh` does not build a release, and should not: it would need the keystore, which CI does not have, and it would add over a minute to every run. So the authoritative check is opportunistic — it fires for anyone who has built a bundle, and CI runs steps 1 and 2 only. **The honest statement is that the guarantee is verified at release time and asserted the rest of the time**, which is weaker than D212 claimed and stronger than what D212 shipped.

**The evidence that purchases will survive is better than "it should".** `billing-8.0.0.aar`'s own classes were scanned for network APIs — `java.net.URL`, `HttpURLConnection`, `javax.net.ssl`, `java.net.Socket`, `okhttp3` — and reference **none of them**. The library is pure IPC to the Play Store, which does the networking in its own process under its own permissions. That is consistent with where the `INTERNET` declaration actually came from: a *separate* library, for telemetry, not billing. It is still not proof — the Play Store service could in principle refuse a caller lacking the permission — so the internal-track install was left as the settling test.

**It settled the right way.** The bundle built here was uploaded to internal testing on 2026-08-21, both products were created against it, and they are live. **Play Billing works with no `INTERNET` permission**, which means the categorical guarantee and a paid app are not in tension on Android after all — the thing D306 was right to refuse to assume in either direction.

**Hot reload survives, and that was not obvious.** `tools:node="remove"` in `main` could plausibly have stripped the `INTERNET` that Flutter's *debug* source-set manifest adds for hot reload, breaking `flutter run` in a way that would have been diagnosed weeks later and blamed on something else. It does not: the build-type manifest outranks `main` in the merger, so the directive reaches the libraries below and not the source set above. Measured on both builds rather than reasoned about — release drops it, debug keeps it.

**Cost:** a `tools:` namespace and a directive in the manifest that will look like dead weight to anyone who does not read the comment, which is why the comment names the library. And a standing hazard: any future dependency that declares `INTERNET` is now silently stripped rather than loudly rejected, so if something one day genuinely needs the network, the failure will be a runtime error rather than a build one. That is the correct direction for this project and it is not free.

## Open items

Carried forward to [idea-v3.md](idea-v3.md) §14: store price points and tax treatment, store accounts and signing, app-name availability, the reference device for the twenty-second ceiling, and the progression numbers pending measurement (D239 — and D261 changes only which rung a per-opponent quest is measured against, not the multiples).

**Closed since:** the two Casual-tier rating inversions, which had been owned by a 1.0 roster revision that no longer exists and are now fixed before 1.0 ships (D305).

**Opened by the re-cut:** Apple Developer enrolment, which is the critical path for 1.0 and is not yet started (D302); ~~whether to strip `INTERNET` or narrow the check~~ — stripped, and the check rebuilt around the merged manifest (D357). What remains is empirical: whether purchases still work without it, which the first internal-track install settles; and how the 1.0 tester cohort is structured now that no store imposes a size or a duration (D302).
