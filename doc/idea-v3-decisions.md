# Quadrim — Decision Log, third edition

Every decision taken while turning [idea-v2.md](idea-v2.md) and the notes in [idea-v2-additions.md](idea-v2-additions.md) into [idea-v3.md](idea-v3.md).
Each entry records the question, the decision, and what it costs or buys.

Numbering continues from [idea-v1-decisions.md](tickets/done/idea-v1-decisions.md), which ended at D217. Decisions here are **D218–D274**.

Date: 2026-08-14
Status: agreed, pre-implementation. No code written for any of it.

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

## Open items

Carried forward to [idea-v3.md](idea-v3.md) §14: store price points and tax treatment, store accounts and signing, app-name availability, the reference device for the twenty-second ceiling, the progression numbers pending measurement (D239 — and D261 changes only which rung a per-opponent quest is measured against, not the multiples), and the two Casual-tier rating inversions, still owned by the 1.0 roster revision but now with a user-visible symptom attached (D268).
