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

## Open items

Carried forward to [idea-v3.md](idea-v3.md) §14: store price points and tax treatment, store accounts and signing, app-name availability, the reference device for the twenty-second ceiling, the progression numbers pending measurement (D239 — and D261 changes only which rung a per-opponent quest is measured against, not the multiples), and the two Casual-tier rating inversions, still owned by the 1.0 roster revision but now with a user-visible symptom attached (D268).
