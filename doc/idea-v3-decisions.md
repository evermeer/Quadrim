# Quadrim — Decision Log, third edition

Every decision taken while turning [idea-v2.md](idea-v2.md) and the notes in [idea-v2-additions.md](idea-v2-additions.md) into [idea-v3.md](idea-v3.md).
Each entry records the question, the decision, and what it costs or buys.

Numbering continues from [idea-v1-decisions.md](idea-v1-decisions.md), which ended at D217. Decisions here are **D218–D257**.

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

## Open items

Carried forward to [idea-v3.md](idea-v3.md) §14: store price points and tax treatment, store accounts and signing, app-name availability, the reference device for the twenty-second ceiling, the progression numbers pending measurement (D239), and the two Casual-tier rating inversions owned by the 1.0 roster revision.
