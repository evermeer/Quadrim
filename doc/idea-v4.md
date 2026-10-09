# Quadrim — Specification, fourth edition

What Quadrim is and what it must do, written so that someone rebuilding it from nothing has no functional question left to ask.

This is [idea-v3.md](history/idea-v3.md) with its decision log folded into it. v3 recorded what the product settled *before* it was built and carried D218–D391 alongside in a separate file; v4 is what that file settled, written into the place each decision belongs. The log itself is archived at [history/idea-v3-decisions.md](history/idea-v3-decisions.md) and is still the record of *how* each of these was arrived at — every `(Dnnn)` below resolves there, and source comments that cite a D-number still point at something real. New decisions continue at D392 in [idea-v4-decisions.md](idea-v4-decisions.md).

**The rules are here; the incidents are not.** Where v3 told the story of a particular bug on a particular afternoon, v4 states the rule that bug produced and, at most, notes that it has happened here. A rebuilder needs the rule. The story is in the log, one click away, for anyone who does not believe the rule.

Status: **0.1.3 is public on the App Store. 0.2.0 adds platform game services and is in TestFlight and Play closed testing.** The offline game is complete, sold, and in players' hands. The online releases (2.0, 3.0) are specified and not built.

Date: 2026-09-21

---

## 0. How to read this

Five things are true of this document.

**Nothing here is a question.** §14 lists the genuinely open items — every one a business, account or measurement decision, none functional, none blocking a line of code.

**Where a number appears, it was measured — except in §7.** Search budgets, rating gaps, board dimensions, think times and contrast ratios are results from running the thing. The point values in §7 are the one deliberate exception: they are derived from a stated target rather than observed, and §7.7 says exactly what that target was and how to tell when it is wrong.

**The mistakes are included, as rules rather than as anecdotes.** Earlier editions described a 2×2 grid of board layers, a solver sub-project, a Casual tier ordered by blunder rate, a permission check that read the wrong file, and a free-forever promise. All were wrong and finding out cost real time. Each appears below as the rule it produced, so nobody spends that time again.

**Two promises were withdrawn on purpose, and they stay withdrawn.** Everything release 0.1 shipped is not free forever — offline play is metered (§4.2). And the app does not refuse the network at the platform level any more — §15 needs it, so the guarantee dropped from *enforced* to *reviewed* and is claimed at that strength and no higher (§11.2).

**One future withdrawal is announced rather than sprung.** Online play arrives free at 2.0 and becomes part of a subscription at 3.0, because what makes it worth paying for — a rating that cannot be forged — does not exist until 3.0. Having already had to withdraw *free forever*, this edition will not repeat the shape of that mistake: the 2.0 copy says the price is coming, in the app and in the listing, from its first day (D304).

**On numbering.** §1–§14 keep v3's numbers, because source comments and finished tickets cite them (`idea-v4.md §6.4`, `§7.3`, `§14`). Platform game services are new and take **§15**; Sources move to **§16**. Nothing in the source cites either.

---

## 1. What Quadrim is

Quadrim is a two-player game played inside a 4×4×4 cube of 64 cells. Players alternate placing a piece of their own colour on any empty cell. The first player to occupy all four cells of any straight line wins. Lines run along the axes, diagonally within a flat plane, and diagonally through the body of the cube. If all 64 cells fill with no line completed, the game is drawn.

The game is known publicly as Qubic, or 3D tic-tac-toe. It is a solved game: with perfect play the first player wins. This fact shapes several decisions below and is not treated as a defect.

A player can play another human — asynchronously over days, or in real time — or any of thirty-one computer opponents, each with a name, an avatar, a play style, and a fixed rating. **Three are open on a first launch**, three more open by losing, and the other twenty-five are earned with points (§7).

**On the name.** Qubic was a Parker Brothers trade name. This product is called Quadrim; the older name is used descriptively and never as branding.

---

## 2. Board and coordinates

A cell is `(x, y, z)` with each coordinate in `0..3`. `z` is the layer index, `0` nearest the viewer. The canonical scalar index is `x + 4y + 16z`, giving `0..63`.

### 2.1 The 76 winning lines

Exactly 76 lines win:

| Family | Construction | Count |
|---|---|---|
| Axis-aligned along x | vary `x`, fix each of 16 `(y,z)` pairs | 16 |
| Axis-aligned along y | vary `y`, fix each of 16 `(x,z)` pairs | 16 |
| Axis-aligned along z | vary `z`, fix each of 16 `(x,y)` pairs | 16 |
| Planar diagonals in the xy-plane | 4 layers × 2 diagonals | 8 |
| Planar diagonals in the xz-plane | 4 slices × 2 diagonals | 8 |
| Planar diagonals in the yz-plane | 4 slices × 2 diagonals | 8 |
| Space diagonals | corner to opposite corner | 4 |
| **Total** | | **76** |

**Generate this table at build time; do not hand-write it and do not compute it at runtime.** A build-time generator emits it as a constant, its output is committed, and the build gate fails if the committed copy is stale. It is the single shared source of truth for win detection, threat detection, evaluation, the tutorial's illustrations, and the server-side validator. Nothing may enumerate lines independently.

The generator is worth a real test suite of its own, because everything else trusts it. Ours proves: exactly 76 lines; the generated set equals an independent direction-walk enumeration; cell degrees match the published figures; and — exhaustively over all C(64,4) = 635,376 four-cell sets — that no non-line quad is collinear. That last one is cheap and catches the failure mode where a plausible generator emits a plausible wrong table.

### 2.2 Cell degree

| Cell class | Count | Winning lines through it |
|---|---|---|
| Corner cells | 8 | **7** |
| Inner cells (the central 2×2×2) | 8 | **7** |
| Face cells | 24 | 4 |
| Edge cells | 24 | 4 |

Sixteen cells sit on seven lines each; the other forty-eight sit on four. Corner and inner cells are **equivalent under the game's symmetries** — one class, not two. §6.3 records what this costs anyone who tries to build a difficulty ladder out of the distinction.

### 2.3 The symmetry group

Qubic has **192 automorphisms**. `canonicalise()` must return **both** the canonical key **and** the automorphism that produced it: the strategy book stores moves in canonical orientation and they have to be mapped back onto the real board. A canonicaliser that returns only the key is half-built, and the missing half is found late — after the book is already wired in and returning legal-looking moves for the wrong squares.

### 2.4 Placement

Every empty cell is always legal. No gravity, no adjacency requirement, no reserved or blocked cell, no handicap. Legal-move generation is "the set of empty cells".

---

## 3. Rules of play

1. The board starts empty.
2. Two players hold distinct colours. Turns strictly alternate.
3. On a turn, the player to move places one piece on any empty cell.
4. A placement completing any of the 76 lines with four pieces of the mover's colour ends the game immediately as a win. The completed line is recorded and highlighted.
5. If the 64th piece is placed with no line completed, the game is drawn.
6. Either player may **resign** at any point, losing immediately. Resigning requires a confirmation step.
7. There are **no takebacks and no undo**, in any mode. A submitted move is final.
8. There are **no draw offers**, anywhere in the product. A game ends by four-in-a-row, a full board, resignation, or timeout.
9. Move history is append-only and complete, which makes every game replayable.

A terminal state records an **outcome** — win or draw — and a separate **reason**: line, full board, resignation, timeout, or abandonment. The two are separate because a clock-driven ending cannot be derived from the moves.

**Everything derives from the move list.** The board, whose turn it is, the outcome, the statistics and the rating are all folds over the stored moves. Never store a second copy of something the moves already say: the two drift the first time a game is deleted. §7.6 records the two places this edition breaks that rule, and why each had to.

**A finished game is not the same question as a complete one.** `status == complete` says a game is over; only the outcome function says *how*. A resignation is complete and leaves a position the board would still play, so anything that means "this game was drawn" must ask the outcome and not the status. Getting that wrong awards a draw to everyone who ever resigned (D386).

### 3.1 First move

The starting player is chosen at random for the first game between a given pair of opponents. In a rematch the other player starts. Colour follows starting order. The game record stores who started **and why** — random, or alternating from a previous game — because the screen says so and it cannot be re-derived later.

**There is at most one unfinished game per computer opponent, and asking for a new one resumes it** (D322). This is a fairness rule, not a tidiness one. Who moves first is decided once, by a coin flip, when the game is created; without this rule a player who dislikes the answer leaves and asks again until they get the first move, and in a 4×4×4 game the first move is worth real rating. Pass-and-play is exempt — both seats are the same person, so there is nothing to farm. A rematch is untouched, because it alternates deterministically rather than drawing.

**A game with fewer than two moves is not "in progress"** (D321). Zero moves is a board the player never touched; one is the opening the computer played before they saw it. Both accumulate every time somebody opens the opponent list and backs out. The filter belongs in the screen rather than in storage, because the resume rule above still has to find them.

### 3.2 Time and abandonment

| Mode | Clock | Expiry |
|---|---|---|
| Async online | none | reminder at 5 days of inactivity; forfeit by the player to move at 7 days |
| Real-time online | 60 seconds per move | forfeit on expiry |
| Vs computer | none | never |
| Pass-and-play | none | never |

Forfeits are ordinary losses and update ratings normally. Both timers are enforced server-side; a client clock is display only.

---

## 4. Game modes

| Mode | Opponent | Network | Affects | Metered | Subscription |
|---|---|---|---|---|---|
| Async online | human | yes | Human rating | no | only to *initiate* |
| Real-time online | human | yes | Human rating | no | only to *initiate* |
| Vs computer | one of 31 | **not during play** | Computer rating, points | **yes** | to lift the cap |
| Pass-and-play | human, same device | no | Nothing | no | no |

Async and real-time share one game-state model and one move pipeline. Real-time adds only the per-move clock and opponent presence.

Pass-and-play affects no rating because the second party is unauthenticated and the result unverifiable. It is excluded from the win/loss/draw record for the same reason — a record that counts games you played against yourself is not a record of anything. It earns no points, counts toward no quest, is not metered, and never triggers the review prompt (§8.17): it is not a result, so it can neither pay nor cost.

A player may hold at most **20 simultaneous active games against human opponents**. Computer games are uncapped in *concurrency*; what is capped is how many may be **started** per day (§4.2).

### 4.1 What is sold

Three tiers and one permanent unlock, all through the App Store and Google Play. Both stores are merchant of record; no direct payment path is ever added.

| | Free | Tier 2 — €2.99/yr | Tier 3 — (3.0) |
|---|---|---|---|
| First month after first launch | unlimited computer games | — | — |
| After that | 3 computer games/day, 9/week | unlimited | unlimited |
| All thirty-one opponents, tutorial, history, replay, statistics, computer rating, pass-and-play | yes | yes | yes |
| Accept an invite link or a direct challenge | yes | yes | yes |
| Concurrent human games | up to 3 | up to 3 | up to 20 |
| Human rating, earned normally | yes | yes | yes |
| Create invite links, challenge someone directly | no | no | yes |
| Auto-match | no | no | yes |
| Open challenge board | no | no | yes |
| Chat | no | no | yes |

**Tier 3 contains tier 2.** A tier 3 subscriber has no daily cap.

**Unlock all opponents — €4.99, one time.** Opens all thirty-one opponents immediately and changes nothing else. A buyer still plays three games a day unless they also subscribe. This is deliberate: it is the least powerful thing in the shop, so a one-time purchase cannot undercut the subscription. What it sells is impatience, not capability.

**The subscription is cheaper than the one-off, and that is not a mistake to fix in the copy** (D368). €2.99 a year buys unlimited games; €4.99 once buys every opponent. A player who wants both pays both. The risk is somebody buying the cheaper one expecting the other's benefit, and the answer is that **each product's body says what it does not do**.

**Both prices are euro base prices** and each store derives its own per-country price. The description carries the euro figures and one line saying that outside the euro area the store charges the local equivalent — a bare "€2.99" is not merely unhelpful to a reader in Canada, it is false, and store guidelines are about the metadata being accurate.

**Tiers 2 and 3 must be two plans of one product**, in a single iOS subscription group and a single Play subscription with two base plans. That is the only mechanism by which "subscribing to tier 3 cancels tier 2" actually happens — the store performs a plan change and prorates the remainder. An app that sells tier 3 as a separate product and cancels tier 2 itself produces double-billed users and a refund queue, and neither store offers an API that would let it do so correctly. The subscription **product** is therefore created with one base plan at the first sale, not with two at 3.0: a subscription group cannot be retro-fitted around a product that already has subscribers.

**Accepting a game is free at every tier.** Invite links are the only way a new person ever reaches this app. Charging the *recipient* makes a friend's invitation arrive as a sales pitch and throttles the one growth loop the product has, at its highest-intent moment. Auto-match and the open challenge board — the surfaces a throwaway account would farm — stay paid, so the anti-abuse benefit is kept.

**When a subscription lapses:**

- Games in progress play to the end and **rate normally for both players**. Frozen means no new rated games can be *started*, not that results stop counting — an asymmetric update would inflate the ladder for whoever happened to be playing a lapsed opponent.
- A lapsed player may accept one rematch of a series in progress, so a billing date cannot deny them the first move §3.1 owes them.
- A lapsed player is **exempt from the inactivity forfeit**. A billing event must never hand someone a forfeit win.
- A lapsed subscriber returns to the free cap. Their **free month does not restart**.
- Opponents unlocked with points, or with the one-time purchase, **stay unlocked forever**. Nothing a player earned or bought outright is ever taken back by a billing event, and the way to be sure of that is that **no code path exists from a subscription event to an unlock record** (D350).

Entitlement is checked when a game is **created and when one is joined** — never on a move, so the lapse behaviour above works.

#### Entitlement before there is a server

From 2.0 entitlement is a server-written field no client can touch, set only after receipt validation and revoked on refund, chargeback or voided purchase. **Until then it is the store's own signed transaction, read on the device**, and this is the one place the design is knowingly weaker than it should be (D303).

- **It is never cached** (D349). The entitlement is an in-memory value that starts empty at every launch and is filled by the restore the shop performs. A cache is a second answer, and it is wrong in exactly the situation that matters — a refund, chargeback or lapse the cache has not heard about, where the cache is the one still saying yes. Persisting it turns "revocation follows the store's next refresh" into "revocation never happens on this device". The cost is honest: between launch and the store's answer the app believes nothing is owned, so a paying player who opens the app on a plane sees the unpaid state. **What it must not do is guess in the player's favour and then take something away**, which is worse than the wait.
- **The shop starts before the first frame and is not awaited** (D351). Awaiting it makes a bad connection into a hung launch, for a game whose premise is that computer play needs no network. Nothing on the first screen depends on knowing what is owned.
- **The purchase-stream listener is attached before the first `await` inside that start**, and this is load-bearing in a way no type expresses. Stores deliver purchases interrupted by a crash, a lost connection or a parental approval on the first stream event after launch; a listener attached after the product query misses them, the store redelivers forever, and somebody has been charged for something they never received.
- **Every delivered purchase is completed, including errors and cancellations.** An uncompleted purchase is redelivered on every launch for the life of the install.
- **The one-time unlock is materialised into unlock records** (D348), with the entitlement as the authority and the records as its consequence, re-derived at every launch. A flag alone cannot answer "which of these did you earn and which did you buy", which is what a refund needs; records alone are a copy of a store answer that can disagree with the store. The records are written at a price paid of zero — the player paid the store, not the balance — and writing one never overwrites an unlock already earned with points.
- **Buying the whole roster gets its own method** (D350), rather than a flag on the ordinary purchase. §7.3's "only the next opponent may be bought" stops being a promise the moment the method that enforces it also carries a way to skip it.

**No third-party subscription service** (D307). The obvious candidates give server-side receipt validation and cross-platform entitlement without running a server, and every one of them assigns each installation a persistent app-user id. An anonymous, per-installation, persistent identifier is a device identifier by any reading that matters, and §11.7 forbids one in every release — not "except when a vendor generates it for us". The honest accounting is that declining it leaves the reinstall leak below open until 2.0.

#### Terms, links and store copy

**The subscription's terms and links belong in the binary, not only in the listing** (D384). An app selling an auto-renewing subscription must carry a functional link to the privacy policy and to the terms of use *within the app*, on the purchase screen as well as in settings — a reviewer who opens the paywall must not have to go looking in settings. Each product states what kind of thing it is: "auto-renewing subscription · 1 year" against "one-time purchase", with the price always formatted by the store in the player's own currency and never assembled locally. **A link that fails says so**, because the failure mode the requirement is about is invisible both at the call site and on screen: a row that looks like a link and does nothing.

**Store copy that lives only in a console is copy nobody can review** (D380, D381). This project enforces that no user-facing string lives outside the localisation files, and that both languages exist for every one — and then let the two most commercially important strings in the product live in a web form with no review, no diff and no test. Two rules follow:

- **The store's copy is recorded in the repository** beside the app's, where a human reads both at once. They are genuinely allowed to differ, because stores impose character ceilings the app does not, so a mechanical check would have to encode which differences are legitimate; recording them together is the cheaper half of that and the half that was missing.
- **The app's shop strings *are* the store's strings.** A player tapping a promoted purchase sees the store's sentence and then the app's, and it is that pair a reviewer judges. Making the two products distinguishable from each other is necessary and not sufficient.

Products must share **no word at all** between them, in either language, in either field, and describe different *kinds* of thing. "Not identical" passes a guideline and leaves the next reviewer making the same judgement call.

### 4.2 The meter

**No feature is held back, and there are no ads.** Every opponent, the tutorial, every screen and the whole of local history are in the free tier. What is metered is *how often you may start a new game against the computer* — not what you may reach.

- **The first month is unmetered.** The clock starts at first launch and runs for one calendar month.
- **Thereafter: 3 games per day and 9 per week.** Both apply; the weekly limit binds first from the fourth playing day of any week.
- A game counts against the meter **when it is started**, not when it finishes. An abandoned game is a spent game — otherwise the meter is defeated by starting and quitting.
- **Only games against the computer count.** Pass-and-play, the tutorial's practice game, replay of a finished game, and online play are all outside the meter.

**The meter reads starts, and every neighbouring fold reads completions** (D310). Points, quests and streaks all fold over *completed* games because they reward results; the meter folds over *created* games in any status. That is one word of difference and the whole correctness of the file, so the input is a named type rather than a bare timestamp — a function taking a list of dates accepts the wrong list silently.

**The week starts on Monday, in every locale** (D311). A calendar week rather than a rolling seven days, because the paywall has to say when the limit lifts: "your games come back on Monday" is a sentence a player can act on, and "in three days, when Tuesday's games age out" is not. Monday rather than the locale's own week start, because reading the locale puts an ambient input into a pure package and because two players in different countries would then hit the same limit on different days for a reason neither could see. The cost is real: where the wall calendar starts on Sunday, the app's week disagrees with it.

**The paywall message must name the limit that actually bit.** "You have used this week's nine games" and "come back tomorrow" are different sentences and only one of them is true on a Thursday. Saying the wrong one teaches the player that the app does not know its own rules.

**The wall is checked twice and only one of the two is the guard** (D352). The guard is the single place a game is created, which is also where §3.1's resume rule lives and which the challenge and rematch paths reach as well; a check anywhere else can be walked around. The second check fires as soon as the mode is chosen and **before** the opponent list is shown, so the refusal does not arrive *after* the player has picked who to play, which reads as the app changing its mind. Deleting it would let nothing through that the guard does not already stop.

**A missing or unreadable settings document means unmetered** (D353), and that hole is deliberate. A player whose storage is damaged must fail towards being allowed to play rather than towards a wall nobody can explain. The loading window between the first frame and the settings stream's first event inherits the same behaviour for free, which costs at most one extra game, once. The alternative — blocking while settings are unknown — tells a player they have used games they have not, which is the exact failure the paragraph above is about.

**Where the month is remembered.** From 2.0, against the account. Before then it is one timestamp on the settings document (D312) — a document of its own would need a store path, a reader, a writer, a repository method, an unreadable-document fallback and its own tests, and settings already has all six and is already in the backup allowlist. It costs a document that is otherwise entirely *preferences* holding one *record*, so the field carries a comment saying what it is rather than only what it holds.

**Absent means unmetered, never expired.** A document written before the meter existed has no such field, and so does a damaged one; both stamp at the next launch. That gives an existing player their month starting at the update — which is the rule this section would have had to state anyway, arriving as the natural reading of a missing field rather than as a migration.

**The local version is the weaker one and the weakness is not fixable without a server.** A device-local month is cleared by a reinstall and can be defeated by changing the system clock. Closing that needs either a device identifier — forbidden in every release, §11.7 — or a server, which is what 2.0 is. So the meter is a **speed bump against forgetting, not a wall against determination**, and the paywall copy must not imply otherwise. At 2.0 the local record is *adopted* by the account rather than replaced: a player who has already consumed their free month does not receive a second one for signing in.

---

## 5. Rating

A player has **two independent ratings**. Neither influences the other.

| | Computer rating | Human rating |
|---|---|---|
| Earned against | The 31 computer opponents | Real opponents only |
| Seeded at | **800** | **1000** |
| Computed | On the device | On the server |
| Stored | Derived, never stored | In the cloud, with the account |
| Visible to | Only that device's owner | The player and their opponents |
| Arrives in | 0.1 | 3.0 |

Both use the same maths:

- K-factor **32** for the first 20 rated games on that ladder, **16** thereafter
- Score: win 1, draw 0.5, loss 0
- Expected score `E = 1 / (1 + 10^((R_opponent − R_self) / 400))`
- Update `R' = round(R + K × (S − E))`; floor **100**

**The two seeds differ on purpose.** A new player seeded at 1200 against a roster that starts at 600 spends their first week watching a number fall, which is the opposite of the story the ladder is telling. Seeded at 800 they sit inside the Novice tier with somewhere obvious to climb. The human ladder seeds at 1000 because there is no fixed roster to sit inside — the population is the roster, and a round number is the least misleading start in a pool whose distribution is unknown.

**The computer rating is derived, never stored** — a fold over the games already on disk. Two details make the fold reproducible, and both live in the data rather than in the code:

- **Each completed game stores the opponent's anchor rating as it was when the game was played.** Without this, recalibrating any opponent silently rewrites every player's entire history and the "+12" they were shown becomes unreproducible.
- **Ordering is by an explicit completion-time field, with the game id as tie-break.** Without it, a long-running game reorders the fold when it finally completes. That tie-break is load-bearing in a way that is easy to miss: if game ids are random and two games complete in the same millisecond, their order is a coin flip — fine for the product and fatal for a fixture that creates games back to back. **Inject a clock in tests.**

**Changing the seed rewrites every existing rating**, and this is the derived rating's great virtue turning into its great constraint. Nothing can drift, which is the same property that makes any change to the seed or the K-factor a silent restatement of everyone's history. It was affordable exactly once, before anybody had seen a number (D227, D278). A shipped product cannot do it again.

That change also taught the second-order lesson, which is the useful one: **moving the seed moves where a new player is standing**, so a dozen tests that were correct stopped being correct — a tier accordion opened at a different tier, a fair-match band moved, a rating step that used to round to zero started paying one. None of them was broken and all of them were newly wrong about what they asserted.

Computer opponents have **fixed** ratings that never change. They are anchors: the player's rating moves, the opponent's does not. **When measurement disagrees with a published rating, the opponent's configuration changes and the rating does not.** Changing an anchor would silently rewrite the meaning of every result already recorded against it.

**The ladder is anchored to itself and never to a human** (D373). Every published rating is measured by bots playing bots — internally consistent, reproducible, and never once checked against a person. That is not a defect; the harness measures exactly what it claims to. But it means "Pebble is 600" is a statement about **this ladder's own scale**, not about human Elo, and nothing shipped so far will tell us whether the two coincide. **If a rung ever feels wrong to real players, that is the first explanation to reach for.**

**Why the split.** The two ratings measure different things under different trust models. A rating earned against a deterministic opponent on your own hardware cannot be verified by anyone and does not need to be — editing it cheats only yourself. A rating earned against another person must be trustworthy. Conflating them forces the worse property of each onto the other.

**The human rating ships at 3.0, together with server-side move validation**, because they are the same feature. Without validation, a modified client can author a legal, replayable game naming any opponent and move that opponent's rating without them ever opening the app. Replay proves legality, never authorship. Release 2.0 therefore ships online play with a win/loss/draw record and no rating — and nobody has a rating to lose, because nobody has one yet. This is also why online play is free at 2.0 and sold at 3.0: what 2.0 offers is games with a record, and the thing worth subscribing for is a rating that cannot be forged.

Because a rating is worth losing, it requires a **linked account** (§9).

### 5.1 How lopsided a pairing is

The opponent list marks pairings that are not a fair test. Express this as an **expected score, not a rating gap**: below 0.25 expected the opponent is far stronger, above 0.75 far weaker. A gap in points means different things at different places on the ladder; an expected score means the same thing everywhere.

**Rating and unlocks are independent ladders that happen to advance together** (§7.3). Neither gates the other: a player whose rating has raced ahead still has to earn the next opponent, and a player who has unlocked someone far above them can play and lose to them as often as they like.

---

## 6. Computer players

### 6.1 One engine, thirty-one configurations

All thirty-one are configurations of a single move-choosing function. **Bots are data, not classes** — adding an opponent is a catalogue entry, and calibration is a matter of running self-play across configurations rather than across code paths.

Move selection order:

1. **Book** — the stored strategy, if this opponent has one (§6.6)
2. **Forced win** — a move that wins now, or a forcing sequence that wins
3. **Strategic rules** — §6.2
4. **Safety filter** — discard any candidate that hands the opponent a forced win (§6.5)
5. **Search** — narrow the survivors
6. **Positional ladder** — decide among what search cannot separate (§6.3)

The parameter axes:

| Axis | Meaning |
|---|---|
| `rules` | which strategic rules are enabled |
| `ruleChance` | probability that an enabled rule fires at all |
| `positionChance` | probability that the positional preference is consulted at all |
| `blunderRate` | probability per move of discarding the chosen move for another legal one |
| `centreBias`, `cornerBias`, `edgeBias` | preference for each cell class |
| `lineBias` | weight of the building term within a class |
| `aggression` | build-before-block ordering, plus the probability of skipping a denial |
| `searchDepth` / `nodeBudget` / `maxSearchDepth` | how much adversarial search |
| `threatSearchDepth` | how far it follows **its own** forcing moves |
| `defenceSearchDepth` | how far it follows **the opponent's** forcing moves |
| `exactEmpties` | below this many empty cells, stop estimating and prove |
| `usesBook` | whether it plays from the strategy dictionary |
| `tieBreakRandomness` | temperature when breaking ties |

A bot's personality must be **visible at the board**, not only in its description.

**Randomness is injected, never ambient.** The engine may not reach for a global random source. A position and a seed always produce the same move — that is what makes the self-play harness and the tests reproducible, and it is worth enforcing mechanically.

**Locking is not an engine concern.** Whether an opponent is available to a given player is a fact about that player, held outside the catalogue. The engine knows thirty-one configurations and nothing about who has paid for what; the catalogue has no `locked` field. Otherwise the strength harness — which plays all thirty-one against each other — needs an entitlement it has no business having.

**A configuration belongs to a rung, not to a name** (D257, D333). Names, avatars and blurbs are labels on slots; ratings and playing strength are properties of the slot. When the roster is re-cut, each measured configuration is placed at the rung nearest the rating it was calibrated to, and a name that moves rungs inherits whatever strength that rung already had. The alternative — letting a name keep its configuration and publishing it at a new rating — is exactly the thing the whole calibration apparatus exists to prevent. **Blurbs move with the configuration**, because a blurb describes what a player meets at the board; getting that backwards leaves every opponent described as playing in a way it does not.

**Renaming has one real cost and it is in storage.** Games name their opponent by id, so a game recorded before a rename resolves to a bot with a different name and avatar. The *rating* fold stays correct because each game stores its own anchor. A rename after the first public release needs a stored-id migration and should be treated as a much larger change than one before it.

### 6.2 Strategic rules, evaluated in order

1. Is there a cell that gives four in a row immediately? Play it.
2. Is there an empty cell where the opponent would get four in a row next move? Block it.
3. Is there an empty cell creating two separate lines of three, each with its fourth cell empty? Play it — an unstoppable double threat.
4. Is there an empty cell that would let the opponent create such a double threat? Deny it.

**Each rule is introduced as a probability, not as a switch** (D343). This is the single most important thing in this section and it was learned the expensive way. Measured in isolation over a thousand games a pair:

| lever | worth |
|---|---|
| a preference for the sixteen seven-line cells | **162 Elo** |
| building a double threat | **100** |
| denying one | **128** |
| the blunder rate | **~6 points per 0.01** |

The rungs in the middle of the ladder are forty to fifty points apart. So **every rule and every positional preference overshoots its rung by three or four rungs' worth**, and any rung that introduces none of them is left with the blunder rate, which cannot cover forty points without moving a quarter of the way across its whole usable range. There is no arrangement of switches that produces an ordered ladder — an arithmetic failure, not a tuning one.

`ruleChance` and `positionChance` turn the cliffs into dials. A rule worth 100 points introduced at a chance of 0.05 is worth about five. Both are **inert at their defaults**, deliberately: a chance of 1 draws no random number, so no opponent that predates them moves by a single move, and a test pins that property rather than trusting it — which is what lets the mechanism ship without re-measuring the whole roster.

It also describes something real. An opponent that has heard of forks before it reliably spots them, and notices the middle of the cube before it always plays there, is how people actually learn this game. A switch says a player goes from never having heard of a double threat to always seeing one, in one rung.

### 6.3 The positional ladder

Applied when no strategic rule decides, and as the tie-break within a rule.

1. Prefer a cell in the central 2×2×2 cube.
2. Otherwise prefer a corner.
3. Among candidates, prefer the cell on the most lines already holding two or more of its own pieces and none of the opponent's.
4. Otherwise choose at random.

**Implement this as weights, not as an if-else chain.** The order is then a property of the numbers, which a test can assert over the whole catalogue: each class gap must exceed the maximum building term, or a later opponent copying another and raising `lineBias` silently inverts the ladder.

**Four things about these weights that cost real time:**

**Only the *order* of the weights reaches the board.** With `lineBias` at zero there is nothing to compare magnitudes against, so an opponent ranking corners above centres above the rest plays *identically* at (0.55, 0.35) and at (0.8, 0.6). Changing a bot's biases to weaken it produced results identical byte for byte across 300 games. To make a positional change have an effect, change the ranking or add a building term.

**Centre and corner are the same class** (§2.2), so ranking centre above corner is a flavour choice, not a strength one. What *is* a strength choice is **how many of the sixteen seven-line cells an opponent prefers at all** — none, eight, or sixteen.

**Corner-hunger is a strength, not a quirk.** It is easy to write "drawn to corners" as a charming weakness. It is not a weakness — corners are seven-line cells.

**Which good squares an opponent prefers is a *style*, and a style cannot be a rung** (D315, D336). Corners-first beats centres-first, centres-first beats centres-only, and centres-only beats corners-first. Rock-paper-scissors, in the lever a whole tier was once built on. Alternating two styles up a ladder builds a **cycle** rather than an order, no matter how the blunder rates are set — and this project did it twice, the second time after having written down the warning. What orders that stretch now is how many of the sixteen cells an opponent prefers, then `lineBias`, then the blunder rate: **three levers that are monotone by construction**, so an inversion among them means a defect rather than a triangle. A test asserts that nothing in the middle of the roster ranks the corners first, so a third attempt cannot happen quietly.

The cost of that rule is real and unpaid: several neighbouring rungs are now one configuration at different blunder rates, so the roster reads thinner than it did. **Putting character back means finding a monotone axis to hang it on** — `lineBias` is the candidate, measured at 60–120 points per 0.05 step — not reinstating the stylistic one.

### 6.4 The roster

Thirty-one opponents across five tiers. **Ratings are fixed anchors.** The `#` column is the roster index, which §7 uses to price both wins and unlocks; it is an ordinal, not a rating, and the two must not be conflated.

**Novice** — the tier a new player starts in. **Three of these six are held back and open by losing** (§7.3a).

| # | Name | Rating | Configuration |
|---|---|---|---|
| 0 | Pebble | 600 | Random legal moves, plus `winNow` behind a 71% blunder rate — it takes about a third of the wins it is handed |
| 1 | Twig | 700 | Random, but takes an immediate win. No blunder rate — its weakness is knowing one rule |
| 2 | Mote | 800 | Wins and blocks, 40% blunder rate |
| 3 | Hazel | 850 | The same two rules, 30% blunder rate. **The first opponent a new player meets** |
| 4 | Clover | 900 | Wins and blocks, 23% blunder rate. No feel for the board — that starts at Juniper |
| 5 | Sorrel | 940 | The first that builds a double threat, and plays it one time in twenty. 21% |

**Pebble is the one rung that had to learn a rule before it could learn to be weak** (D341). Purely random is not 600 — it lost 1-49 to an opponent whose only advantage is taking an immediate win, so on this board that single rule is worth nearly seven hundred points, and no gap of a hundred can be built across it by giving the rule to one side and not the other. With no rules there is nothing for a blunder to discard, so the old configuration played identically at every blunder setting and the rung could not be moved at any price. It now has the rule and misses most of what it offers, and the relationship is steeply non-linear: 0.30 gives −10, 0.65 gives −78, 0.72 gives −117.

**Casual and Club** — one ramp rather than two tiers of steps. `fork` and `deny` are the chances of building and denying a double threat; `pos` is the chance the positional preference is consulted at all. **No opponent here sets aggression and none ranks the corners first** (§6.3).

| # | Name | Rating | Prefers | fork | deny | pos | line | Blunder |
|---|---|---|---|---|---|---|---|---|
| 6 | Bramble | 980 | nothing | 0.10 | 0.03 | — | — | 0.19 |
| 7 | Juniper | 1020 | the 8 centres | 0.16 | 0.06 | 0.09 | — | 0.185 |
| 8 | Bracken | 1060 | the 8 centres | 0.24 | 0.11 | 0.16 | — | 0.18 |
| 9 | Willow | 1100 | the 8 centres | 0.33 | 0.17 | 0.26 | — | 0.175 |
| 10 | Rowan | 1140 | all 16 | 0.43 | 0.24 | 0.29 | — | 0.17 |
| 11 | Aspen | 1180 | all 16 | 0.52 | 0.31 | 0.36 | — | 0.165 |
| 12 | Vireo | 1220 | all 16 | 0.60 | 0.38 | 0.44 | — | 0.16 |
| 13 | Finch | 1260 | all 16 | 0.64 | 0.44 | 0.48 | 0.05 | 0.15 |
| 14 | Kestrel | 1300 | all 16, wider | 0.74 | 0.58 | 0.62 | 0.10 | 0.13 |
| 15 | Osprey | 1340 | all 16, wider | 0.86 | 0.78 | 0.80 | 0.17 | 0.11 |
| 16 | Heron | 1380 | the full ladder | 0.96 | 0.94 | 0.93 | 0.22 | 0.082 |
| 17 | Marlin | 1420 | the full ladder | 1.0 | 1.0 | 0.97 | 0.25 | 0.07 |

**Expert** — the searching opponents. What separates them is how far they look, at what, and with which temperament.

| # | Name | Rating | Configuration |
|---|---|---|---|
| 18 | Lynx | 1460 | No ordinary search; two moves of forcing search, 5.5% |
| 19 | Sable | 1500 | 2-ply plus a 2-move forcing search, aggressive weighting, 5% |
| 20 | Ember | 1540 | 3-ply plus a 3-move forcing search, defensive weighting, 4% |
| 21 | Lyra | 1580 | 3-ply, 4-move forcing search, even-handed, 3.5% |
| 22 | Onyx | 1640 | 3-ply, 6-move forcing search, 3% |
| 23 | Corvus | 1700 | 4-ply plus a 9-move forcing search, 2% |

**Master** — budgets in nodes rather than plies, because how deep a budget reaches depends on the position; and at the top, the two that stop estimating and start knowing.

| # | Name | Rating | Configuration |
|---|---|---|---|
| 24 | Basalt | 1800 | 500k nodes, transposition table, 1.5% |
| 25 | Cairn | 1900 | 900k nodes, deeper threat search, first with a **defensive** forcing search, 1% |
| 26 | Flint | 2000 | 1.8M nodes, deeper defence, 0.5% |
| 27 | Quartz | 2100 | 2.5M nodes, exact solving below 10 empty cells, unstarved defence, no deliberate blunders |
| 28 | Titan | 2200 | 3M nodes, 11 empty cells solved exactly, the deepest **defensive** forcing search of any opponent, the strongest that plays no book |
| 29 | Oracle | 2300 | Plays the book from move one. Unbeatable when it opens; the searching machinery of the rungs below from the second seat |
| 30 | Quadrim Prime | 2400 | The same book, and the largest configuration in the catalogue from the second seat |

**The measured state of the ladder.** Eleven consecutive rungs from Hazel to Kestrel measure between 37 and 54 points apart against a published forty. Every anchor below Lynx is inside tolerance. Two problems remain and both are honestly stated rather than hidden:

- **Kestrel to Lynx is about twice as steep as published**, evenly and in the right order, and **nothing between them can fix it**. A dial can only weaken an opponent, so the span between two *fixed* configurations is an invariant: tuning a rung inside that span moves the excess from one side to the other without reducing it, which was measured and reverted. Hazel's configuration and Lynx's are about 880 Elo apart where the roster allots 610. Closing it means bringing the Master tier's node budgets down.
- **The Master tier is ordered on paper and only partly resolved on the board.** Run at full budget, Titan beats Quartz by 115 against a published 100, beats Flint by 241 against 200, and Flint beats Cairn by 147 against 100 — three correct orderings. Their *spacing* is unmeasured; three pairings is not a tier, and settling it is an overnight full-budget run over Lynx upward.

### 6.5 What actually makes an opponent strong

Measured, in descending order of effect. This is the part of the document a rebuilder should read twice.

**A defensive forcing search is worth about 300 Elo — the largest single lever in the project.** Before playing a candidate move, follow the *opponent's* forcing sequences and discard the move if it hands them a forced win. This is a separate depth from the opponent's own threat search, and separating the two is what gives the ladder a dimension that raising the node budget did not. Seeing your own wins and seeing your opponent's are different skills that improve at different times.

**More of everything is not more** (D338). Three of the levers a strong opponent seems to want are saturated, and this project measured each of them separately: depth stops separating opponents past three plies; a forcing search past eleven moves finds the same wins as one past twenty; and a node budget buys depth, which is the saturated lever, so a bigger budget buys nothing either. An opponent built by adding to those three and *matching* on the defensive forcing search lost to both rungs below it. **When a rung is not strong enough, the question is which lever it does not already lead on.**

**Being defensive in temperament is worth about −78 Elo.** With two configurations identical except for `aggression`, the aggressive one beats the defensive one by 28 points and the defensive one loses by 50. In Qubic, building your own double threat beats denying the opponent's. Design the roster knowing this: a "cautious" personality is a *weaker* personality. And do not order a tier by it — which setting wins depends on which setting it is facing, so it aligns the average while leaving the tier intransitive.

**Search budgets are counted in nodes, never milliseconds.** A millisecond budget makes every searching opponent a different opponent on a fast phone and a slow one, in debug and release, in CI and on a device. Nodes keep them the same everywhere. Measure the wall-clock equivalent separately, against a named reference device.

**Every forcing search needs a node budget of its own.** An unbudgeted one took five minutes on a single move. The budget is also shared out among candidates being checked, and an unstarved defence measured 36–24 against a starved one.

**Teaching the evaluation about forks did not make it stronger.** It is an obvious idea, it costs a day, and it measured as noise. The rules already handle double threats.

### 6.6 Perfect play

**Qubic is a first-player win, and Patashnik proved it in 1980.** The proof is a dictionary of move choices for the difficult positions; everything else is reachable by forcing sequences the engine already computes.

**The dataset exists and is obtainable.** A copy of `qubic.dictionary` is published; it is 54,745 bytes and its own header carries a permissive grant — usable as long as its moves are unchanged and its source is credited. **A solver sub-project is not needed and should not be built.** That is the single largest scope reduction available in this project: an unbounded research task for something that had already been done in 1977.

Two obligations, both worth mechanising rather than promising:

- **Moves unchanged.** Vendor the file byte for byte, mark it binary so no line-ending conversion touches it, and verify its SHA-256 on every run of the build gate.
- **Source credited.** The credit must be rendered *in the shipped app*, not merely present in the repository. Have the gate grep for the string in the app's source. A licence obligation that lives only in a README is one refactor away from being violated.

If the dictionary is taken from a repository under a restrictive licence, **take only the data file**. Implement the move-generation procedure from the dictionary's own header and the published article, read no line of the surrounding code, and record the separation in a NOTICE file with instructions to preserve it on any refresh.

**Store the book in canonical form** and map the move back through the automorphism that produced the key (§2.3).

**Perfect play is first-player play.** There is no such thing as perfect second-player play in a first-player win. An opponent playing the book **cannot be beaten when it opens**, and from the second seat has no book at all and falls back on search. This has three consequences:

- **Two book opponents can only differ in the seat the book does not cover.** Everything separating them is second-seat search. Attempts to differentiate them otherwise failed instructively — a blunder rate would have made the higher-rated opponent blunder more, and a shallower forcing search measured as *no difference at all*, byte-identical over 200 games, because the wins that follow the book are short enough that eleven plies find them as reliably as twenty.
- **Never say "perfect" in the interface.** Say "unbeatable when it moves first". The first claim is false from the second seat and a player will find that out.
- **The two most expensive unlocks buy opponents that cannot be beaten half the time.** A player who spends a million points on an opponent that opens with the book and wins will feel cheated unless the app said so first. The unlock confirmation must repeat the "unbeatable when it moves first" line, not just the store listing.

A consequence for measurement: **a pairing of two book opponents measures the seat, not the strength.** Any self-play harness must detect and flag this, or it will confidently report 50% and mean nothing by it.

### 6.7 Calibration

The thirty-one must play at the strengths they advertise. This needs a headless self-play harness, and it is worth building properly because **every claim that one opponent is stronger than another should come from a run of it rather than from an argument about the code**.

**Two instruments:**

- **A duel** — two configurations, N games, alternating seats, reporting wins/losses/draws and the implied rating difference. It never scales a budget.
- **A ladder calibration** — **every opponent against the five rungs above it: 140 pairs**, at a reduced node budget so it finishes in hours rather than overnight.

**A window, not a chain** (D313, D339). Two sampling failures are possible and this project hit both.

*A chain has no triangle in it.* Playing only adjacent pairs cannot see a **cycle**, because a cycle needs three mutual results. A tier measured that way reported one opponent 159 points above its anchor for the simple reason that its only two opponents were the two it beats. **Play every pair within reach, not a path through them.**

*A tier boundary measured through one pair is a scale that can drift.* Sampling thoroughly inside tiers and joining them with a single brace let two opponents that draw with each other be reported 259 points apart, because each had been measured entirely against its own side. **A fixed reach deletes the concept of a tier from the sampling**: every rung is tied to the five above it whether or not they share a band, so no join is thinner than any other point on the ladder.

What is given up is the long brace. Nothing plays anything more than five rungs away, so the ladder's *absolute span* is no longer checked — only its ordering. If that span is ever in question the brace has to come back.

**Game counts are per-pair, because precision is not uniform.** Fifty games leaves about 49 rating points of noise, which is more than a forty-point rung, so **a perfectly ordered ladder reports a couple of spurious inversions per run**. Every pair in which neither side searches plays four times the base count — noise falls with the square root, so two hundred games brings it to about 25 — and those pairs are free, because the opponents below the searching tier decide a move in microseconds. The searching tiers keep the base count, where a single pair is twenty minutes. The reported noise line prints both figures, because a run no longer has a single precision.

**A reduced budget is unsafe wherever the two sides are budgeted differently** (D342, D375). This is the trap that matters most, and the obvious framing of it is wrong.

The reduction is not merely imprecise at the top of the ladder — **it can change the sign of a result**. Measured both ways at fifty games a pair:

| pairing | published | at 10% | at full budget |
|---|---|---|---|
| Quartz → Titan | −100 | **+83** | **−115** |
| Flint → Titan | −200 | **+95** | **−241** |
| Cairn → Flint | −100 | −23 | −147 |

Why is visible in the timings: a Master-tier move costs **0 ms at the median and about 900 ms at the mean**, with a worst case near 12 seconds. Almost every move is decided instantly by the book, by a rule, or by a forced win already in view, and the tier's entire separation lives in a handful of genuinely hard positions a game. Cutting the budget leaves the cheap moves untouched and removes exactly the deep search that distinguishes one rung from the next — so the opponent that suffers most is the one whose budget was doing the most work, which is the strongest one, which is why the result inverts rather than merely narrowing.

The general rule is **not about the tier**. What matters is whether the reduction lands **symmetrically**, and it does not whenever one side is ply-limited and the other node-budgeted: the cut passes straight through one opponent and takes nine tenths of the other's thinking. So: **a 10% result is evidence only when neither side spends a node or forcing budget, or when both do and the cut is proportionate.** Everything else is a bound, and the tool must say so on the line.

**An opponent excluded from every pair vanishes silently** (D337), and that is the worst failure a report whose purpose is finding holes can have. Discarding asymmetric pairs is correct; one opponent once spent *neither* budget while every opponent within reach spent one, so all five of its pairs were discarded and it appeared nowhere at all — not out of tolerance, not inverted, absent. **The report must say when it measured nothing.**

**Report the median of an opponent's per-pair estimates, not the mean** (D340, D341). Each estimate is a partner's *published* rating plus a measured gap, so it carries that partner's anchor error in full. One anchor that is wrong by 400 points moves the mean of ten pairs by forty — enough to report an opponent above three rungs that beat it two to one. A median cannot be moved far by one outlying pair. **The report exists to find anchors that are wrong, so it must not assume they are right.**

It follows that near a broken anchor **only the head-to-head scores mean anything**. The inversion list is computed from head-to-heads rather than from the estimate column, which is why it is the part of the report to trust — and why fixing the worst anchor is a precondition for reading the rungs around it, not a cosmetic tidy-up.

**Four more traps in a harness like this, all of which we fell into:**

1. **A budget scaled to zero changes what an opponent *is*.** If move selection branches on `nodeBudget > 0`, a budget rounded away does not make an opponent think briefly — it stops it searching at all, while the report still carries its name. Clamp a non-zero budget to a minimum of one.
2. **A swept pair has no finite implied difference.** Clamp the score half a game off the end and mark the result as a bound rather than a value, or the average silently understates whichever side did the sweeping.
3. **Never fit a fresh scale.** A least-squares fit over the whole graph answers "what scale best explains these results", which quietly moves all thirty-one anchors at once and produces a self-consistent ladder that no longer means what the player was told. Anchor each estimate on the *other* side's published rating.
4. **An inversion list headed "configuration defects" is an instruction, and it is the wrong one for a bound.** A reader who acted on that heading without reading the budget annotation would have tuned a correct ladder into a wrong one three times in one run. The heading is not wrong so much as unqualified; what protects against it is the annotation printed on the same line.

**A dial can only weaken, so the span between two fixed configurations is an invariant.** This is the one arithmetic fact that decides what tuning can and cannot achieve, and it is worth stating on its own: excess spacing can be *moved* between neighbouring rungs and never removed. Closing a too-steep span means changing one of its endpoints.

**Budget the run honestly.** The 140-pair run measured **274 minutes** on a desktop. A figure that was never measured — and was four hours out — is how a run gets killed halfway on the assumption that it has hung.

### 6.8 Responsiveness

**A move must complete within twenty seconds on a device.** That is a ceiling, not a target, and it belongs to the strongest opponents alone — a twenty-second think from a 1500-rated opponent is a defect. Spend the budget as a ladder: Novice, Casual and Club in single-digit milliseconds; Expert in the low seconds; only Master near the ceiling.

Beware of inferring this number. Ours was first guessed at 250 ms because that "feels responsive", and every tuning decision made under it was distorted — including a conclusion that the second-strongest opponent was over budget, which on the real number it was not, by a factor of about thirty. **Ask the product owner for the ceiling before tuning anything against it.**

The measured worst case is **11.8 seconds**, on a desktop. That ceiling is a *phone* number, so the headroom is unverified rather than comfortable (§14).

**Run the search off the UI thread**, injected as a function so tests can run it inline. And while the computer is deciding, the player must see a **clear, moving indication that it is thinking**. At twenty seconds a static line of text is indistinguishable from a frozen app.

**The whole app ships in no more than 50 MB**, with artwork and fonts together under 3 MB.

---

## 7. Progression

The rating (§5) says how strong a player is. Progression says what they have *earned*, and it is what gives a single-player game a reason to be opened tomorrow. It is a separate ladder that happens to advance at a similar pace, and the two never gate each other.

Progression ships in the **first** release. A closed test of Quadrim without it evaluates a product nobody intends to ship.

### 7.1 Two currencies, one of them not a currency

- **Rating** is a measurement. It goes up and down, cannot be spent, and reflects only how well you played.
- **Points** are earned and spent. They only come from winning against the computer, and there is exactly one thing to spend them on.

Keeping these separate is what lets the rating stay honest. A rating you could spend would be a score, and a score people spend is a score people farm.

### 7.2 What a win is worth

**A win against roster index *i* pays the *i*th rung of a Fibonacci ladder: 1, 2, 3, 5, 8, 13, 21 …** Each rung is the sum of the two below it. Draws and losses pay nothing.

| Opponent | # | A win pays | | Opponent | # | A win pays |
|---|---|---|---|---|---|---|
| Pebble | 0 | 1 | | Osprey | 15 | 1,597 |
| Twig | 1 | 2 | | Heron | 16 | 2,584 |
| Mote | 2 | 3 | | Marlin | 17 | 4,181 |
| Hazel | 3 | 5 | | Lynx | 18 | 6,765 |
| Clover | 4 | 8 | | Sable | 19 | 10,946 |
| Sorrel | 5 | 13 | | Ember | 20 | 17,711 |
| Bramble | 6 | 21 | | Lyra | 21 | 28,657 |
| Juniper | 7 | 34 | | Onyx | 22 | 46,368 |
| Bracken | 8 | 55 | | Corvus | 23 | 75,025 |
| Willow | 9 | 89 | | Basalt | 24 | 121,393 |
| Rowan | 10 | 144 | | Cairn | 25 | 196,418 |
| Aspen | 11 | 233 | | Flint | 26 | 317,811 |
| Vireo | 12 | 377 | | Quartz | 27 | 514,229 |
| Finch | 13 | 610 | | Titan | 28 | 832,040 |
| Kestrel | 14 | 987 | | Oracle | 29 | 1,346,269 |
| | | | | Quadrim Prime | 30 | 2,178,309 |

**Fibonacci rather than powers of two** (D335). Doubling over thirty-one rungs puts the top of the ladder at 1,073,741,824 points for a single win and the whole roster at four billion — numbers no interface can make mean anything. Growing by the golden ratio instead keeps every property §7.3 relies on and puts the top win at 2,178,309.

That change is worth recording as a *shape* lesson rather than a number one. The doubling ladder was chosen for twenty rungs and was still correct at twenty; **an exponent does not care how many rungs are added to it**, so re-cutting the roster from twenty to thirty-one multiplied every point total by about two thousand without any decision being taken. The invariant a player feels — three or four wins buys the next rung — was untouched throughout, which is exactly why nobody noticed until the numbers were on screen.

Wins only, because it keeps the arithmetic in §7.3 clean: "about three wins buys the next opponent" is a promise the interface can make, and it stops being one the moment draws pay a fraction.

### 7.3 The unlock ladder

Opponents are bought with points, **strictly in roster order**: only the next locked opponent can ever be purchased. The first six rungs — the Novice tier — are never bought (§7.3a covers how they open).

**Unlocking opponent *i* costs twice what a win against *i* pays: 2, 4, 6, 10, 16, 26 …** — each price the sum of the two before it.

| Unlock | Costs | | Unlock | Costs |
|---|---|---|---|---|
| Bramble | 42 | | Osprey | 3,194 |
| Juniper | 68 | | Heron | 5,168 |
| Bracken | 110 | | Marlin | 8,362 |
| Willow | 178 | | Lynx | 13,530 |
| Rowan | 288 | | Sable | 21,892 |
| Aspen | 466 | | Ember | 35,422 |
| Vireo | 754 | | Lyra | 57,314 |
| Finch | 1,220 | | Onyx | 92,736 |
| Kestrel | 1,974 | | Corvus | 150,050 |
| | | | Basalt | 242,786 |
| | | | Cairn | 392,836 |
| | | | Flint | 635,622 |
| | | | Quartz | 1,028,458 |
| | | | Titan | 1,664,080 |
| | | | Oracle | 2,692,538 |
| | | | Quadrim Prime | 4,356,618 |

**Every unlock costs 2φ ≈ 3.24 wins against the rung below**, to within a hundredth, from the second rung up. **The whole roster is 11,405,706 points, about eighty wins** — that is the number to reason about; the point totals are display.

**The promise is no longer exact, and that is the price of readability.** Under powers of two an unlock was *exactly* four wins. "Three or four games" is the only form of the promise a player can actually use, and it is true of the whole ladder.

Four properties fall out of this shape rather than being ruled in, and they are the reason to prefer it over a hand-tuned table:

**Grinding downward is self-defeating, so no anti-farming rule is needed.** Every rung down divides the payout by the golden ratio. Unlocking the top opponent by beating the bottom one takes 4,356,618 games. The obvious exploit prices itself out without a line of code, and without punishing a player who genuinely enjoys easy games. Note that this property is **weaker than doubling gave**: a rung down costs a factor of 1.618 rather than 2, so over one or two rungs the pressure to play the strongest opponent you can beat is genuinely milder. That is a deliberate softening, not an oversight.

**The two ladders advance together without being coupled.** From a seed of 800, a few wins against an opponent just above you is roughly +90 rating, and the roster's rungs are about 40 points apart. A player who is earning the next unlock is also, independently, becoming strong enough to want it.

**A rung is a session.** Three or four wins takes eight to twelve games while an opponent is still unfamiliar, which is one sitting.

**Every rung feels identical.** Costs and payouts grow at the same rate, so the *effort* per unlock is flat all the way up. The numbers on screen become large, and that is the price of the property. Format them with the locale's thousands separator and let the progress bar carry the meaning; nobody does this arithmetic, they watch a bar fill.

**Unlocks are permanent.** Nothing revokes one — not a lapsed subscription, not a refund of an unrelated product, not a roster revision.

**Unlocking is strictly sequential**, and the cost is worth naming: the wallet has no strategic decision in it — it is a savings counter, not an economy. That is traded for a ladder that is trivially explainable and a difficulty curve nobody can accidentally skip past into an opponent that beats them forty times running.

### 7.3a The mercy rungs

**The roster starts at Hazel, and the three opponents below it open by losing** (D382). A loss to Hazel hands back Mote, a loss to Mote hands back Twig, a loss to Twig hands back Pebble. **Nobody is offered an easier opponent until the game has shown them they might want one.**

This exists because the opening impression of the published game was three matches an average adult cannot lose. Removing those three outright would strand the players who genuinely need them; holding them behind a loss keeps them for exactly those players.

Four properties make it cheap and safe:

- **Derived, not stored.** It is a fold over the game list, like the points total, the streak and the rating. That buys idempotence, immunity to being killed between finishing a game and writing a record, and — importantly — immunity to a refund of the one-time unlock, because a game that was lost stays lost. The stored alternative gets that last one wrong by default, since revoking a purchase deletes every record the purchase wrote.
- **They are outside the points economy entirely.** The "next opponent to buy" walks up from the first purchasable rung, and the roster cost and price functions skip them, through **one predicate rather than three copies of the same condition**. Without that the shop offers the weakest opponent in the game for sale, at a price, to every new player, for something no amount of points can reach.
- **Existing players keep what they have.** The same fold also grants any of the three the player has already finished a game against. The complaint was about a gentler *opening*; taking an opponent away from somebody already using it is a different and worse change.
- **A draw is not a loss**, and the signature is the proof rather than a comment: the fold takes the opponents *lost to*, and there is nowhere to pass a draw.

**Locked mercy rungs are hidden, not greyed out.** A locked row shows its price and these have none, so the row could say nothing about how to open it — and the true answer, *lose to the rung above*, is not something to advertise. It invites deliberate losing, and it reads as condescension to a player who is already struggling. The tier heading counts the filtered list.

**Hiding a catalogue entry breaks prose that names it.** The first row of the first screen a new player opens described itself by comparison to an opponent they can no longer see. No test could have caught it: every string was present, in both languages, and a check that greps for hardcoded strings has nothing to say about whether a sentence still makes sense.

### 7.4 Quests

**One achievement system, not three.** Everything that pays points is a quest, including the per-opponent milestones:

| Family | Instances | Notes |
|---|---|---|
| First win against an opponent | 31 | one per opponent |
| First win **as the second player to move** | 31 | a genuinely harder rung — the first player has a real advantage — and free to detect, since which seat started is already on every game |
| Games played in one day | 5 | 5, 10, 20, 50, 100 |
| Consecutive days played | 9 | 5, 10, 30, 90, 180, 360, 720, 1080, 1440 |

**Every quest is priced by the opponents it was earned against, never by how high the player has climbed.** That is one rule for all four families, and it is the rule §7.2 already applies to a plain win: points measure the strength of what you played, not who you are.

- **A per-opponent quest pays one win against that opponent** — fixed by the roster, worth the same whenever it is claimed.
- **A volume or streak quest pays its multiple of a win against the average of the games that earned it**, where the average is taken over the **roster index** and rounded to the nearest opponent.

**Average the index, not the payout.** Because payouts grow exponentially, an arithmetic mean of them is dominated by the single strongest game in the set: nineteen trivial games and one against the top of the roster would price twenty games at roughly a top-tier win on the strength of one of them. Averaging the index and then exponentiating — the geometric mean — gives what nineteen trivial games and one real one are actually worth. Round the mean index to the nearest opponent so the result is nameable: the interface can say *your twenty games averaged Kestrel*, which is a sentence, where a fractional exponent is not.

**Two ways of pricing quests by the player instead of the opposition were tried and both fail, in opposite directions** (D261, D270).

*Pricing at the player's current rung lets the cheap quests be banked.* The ladder never requires playing the weakest opponents — the cheapest route to any unlock is wins against the rung below, which is exactly the self-pricing property §7.3 relies on. So a player has no reason to touch the bottom of the roster at all, and those quests sit unclaimed and appreciating. Cashed in near the top, a handful of games against opponents that move at random would pay a large fraction of the entire ladder. **The optimal play would be to avoid a fifth of the roster on purpose.**

*And it makes the volume family a pure grind.* A hundred games in a day pays four wins-worth; priced at the player's rung, a hundred instant games against the weakest opponent pay four wins at that rung — an afternoon of tapping for the price of real games. This is the failure the rest of §7 was carefully built to avoid: §7.3's whole argument is that grinding downward prices itself out, and a reward priced by the player's height reintroduced the exploit in the one place nobody was looking.

| Games in one day | 5 | 10 | 20 | 50 | 100 |
|---|---|---|---|---|---|
| Pays, in wins-worth | ¼ | ½ | 1 | 2 | 4 |

| Consecutive days | 5 | 10 | 30 | 90 | 180 | 360 | 720 | 1080 | 1440 |
|---|---|---|---|---|---|---|---|---|---|
| Pays, in wins-worth | 1 | 2 | 4 | 8 | 12 | 16 | 24 | 28 | 32 |

Three or four wins is one unlock, so a 30-day streak of real games, or a 100-game day against opponents near the player's own level, is worth roughly one free opponent. The same streak kept alive with one trivial game a day is worth a handful of points, and **that is the intended answer rather than a shortcoming**: showing up is what the streak measures, but *what you showed up to* is what the points measure.

**Multiples are stored as integers over a fixed denominator of four**, never as floating-point (D280). Two of the five volume rungs pay a fraction of a win, and a `double` multiple puts a rounding argument between a re-tune and a payout in the one part of this project where the arithmetic *is* the product. §7.7 says these numbers are the most likely in the document to be wrong and the first to instrument; whoever changes them should be changing an integer. All four families run through one award function because all four express their multiple the same way.

**Every quest that fires pays at least one point** (D279). The cheapest volume rung against the weakest opponents rounds to zero, and zero is arithmetically honest and reads as a defect — an achievement that arrives with "+0" beside it is indistinguishable from a bug in the awarding code, and a player who reported one would be right. The clamp cannot be farmed, because **a quest fires exactly once**.

**From the release that has a meter, the volume ladder is subscriber-only by arithmetic, not by a rule.** Five games in a day exceeds the free cap of three, so no free player can complete even the first rung. This must be *stated* rather than left to be discovered: the quest tiles show the requirement, and a free player sees why it is out of reach and what would change it. A permanently unreachable goal presented without explanation reads as a bug.

**That restriction is computed from the cap, never carried on the quest** (D354). It is arithmetic, not policy: five exceeds three, and that is the whole of it. A `subscriberOnly` flag would put an entitlement concept inside the pure progression package — the same line §6.1 draws when it forbids the engine a `locked` field — and would go stale the moment either number moved. The remaining gap is honest: **nothing connects the daily cap to the first volume target**, so if either is ever changed the tile lies and no test fails. That connection is the thing to add if either number is touched.

**There is no remaining farm vector, and no rule is doing the work.** Pricing the volume family by the average opponent means a hundred games against the weakest opponent pay a hundred games' worth of *that* opponent. This is the same property §7.3 has and for the same reason: **the exponent does the work, so no anti-farming rule has to.** That matters because a containment rule that arrives releases after the thing it contains is not a containment rule, and the paywall did.

### 7.5 Streaks

**A day is the device's local calendar day**, and it is kept alive by **finishing** at least one game against the computer. Starting one is not enough — otherwise the streak is maintained by opening the app and quitting.

**A missed day resets the streak to zero.** No forgiveness, no rest days, no repair purchase. The long rungs are meant to be rare, and every softening mechanism is another rule to explain, another thing to store, and another surface for "I *did* play on Tuesday" support mail.

**One narrow exception, and it defends against an artefact rather than forgiving a miss** (D283). Rendering history in the device's *current* time zone shifts every stored game by the same offset — up to about twenty-six hours — so games near midnight cross into the neighbouring day while the rest do not, and a player who never missed a day sees a one-day hole. **A gap of exactly one calendar day is bridged when the games either side of it are less than 48 hours apart in real time.** Anything longer, or a gap of two days or more, breaks the streak. Two games less than 48 hours apart cannot span a day somebody was absent for, so the bridge can never forgive a real miss — which is what makes it consistent with "no forgiveness" rather than an exception to it. It also catches the honest near-miss: 23:30 Monday to 00:15 Wednesday is 24¾ hours, and "you missed Tuesday" is technically true and the wrong thing to tell that player. A bridged day **counts** toward the run's length, because counting days played rather than days spanned would break a streak's length instead of the streak itself.

**The head is generous separately and for a different reason.** A streak is alive while the last day played is today *or yesterday*: a player who has not opened the app yet today has not missed anything, and telling them their streak is zero before they have had a chance is the surest way to make it true.

**Progress and achievement are read from different places, and the asymmetry is the point** (D282). A rung is **achieved** from the earliest run that ever reached it, so it fires once and stays fired when a streak later breaks. **Progress** on a rung not yet achieved is the streak the player is on **right now**. A day is over and cannot be resumed, so the best day ever is the only honest reading of a volume rung; a streak is a thing you are currently holding, and after it lapses you are genuinely back at zero. Showing "29 of 30" to somebody whose run broke last month is a lie about the quantity being measured.

**The equivalent trap on the volume family is the mirror of that, and it shipped** (D317). Progress on *games in one day* is **today's count**, not the best day ever — a player shown "16 of 20" from yesterday reads it as four more games when in fact it is twenty. The achievement half is permanent; the progress half is not.

**Anything folded against "today" has to notice midnight.** A screen that only recalculates when a game finishes keeps yesterday's answers if the app is left open overnight or resumed the next morning. Re-fold on resume as well as on the data stream.

**A fixture whose clock disagrees with itself cannot catch a bug about which day it is.** Test data that plays its games months away from its own notion of *today* is incoherent, and it is invisible for exactly as long as nothing asks what day it is.

Two consequences to handle honestly rather than hide:

- **A player who crosses time zones can gain or lose a day.** Accept it, and evaluate generously where the rule is ambiguous — never break a streak that any reasonable reading would have kept.
- **The 1440-day rung is just under four years.** It exists as a horizon, not as a target, and nothing in the design depends on anyone reaching it. **1080 — three years — was added because two years to four was the longest gap on the ladder** and the only one a player could sit inside for two whole years with nothing to reach (D379). It pays the linear interpolation between its neighbours, deliberately not a rounder number of its own: a rung should neither reward better nor worse than the trend it sits on. Nothing migrates, because quest progress is a fold — a player who already has such a streak gets the rung the moment they update.

**The window for adding a rung closes at publication.** Store achievements cannot be deleted or renamed once published (§15), so a rung inserted later sits at the end of the console's list forever, out of order with the ladder it belongs to.

### 7.6 What must be stored — and the rules it breaks

§3 says everything derives from the move list. **Two things are stored that are not in it**, and both are worth being explicit about rather than letting a rebuilder discover an undocumented table.

Points *earned* is still a fold over stored games. Points *spent* is a decision, and a decision is not in the move list. So:

```
unlock:  { opponentId, unlockedAt, pricePaid, source }
settings.freeMonthStartedAt        (§4.2)
```

- **`pricePaid` is stored for the same reason a game stores the opponent's anchor rating** (§5): re-tuning a cost later must never retroactively bankrupt someone who already spent at the old price. The balance is *earned minus the sum of prices actually paid*, which is stable under any future change to the table.
- **`source`** distinguishes points from the one-time purchase, so a refund of the purchase can revoke exactly what it bought and nothing a player earned.
- Everything else stays derived. There is no stored balance, no stored streak length, no stored quest progress, and no stored mercy-unlock record — all four are folds, and all four would drift.

**Points earned is a fold over the games and nothing else** — no unlock record is consulted to compute it. That is a consequence of §7.4 pricing every quest by the opponents it was earned against rather than by the player's current rung, and it is worth stating because the alternative was not obviously worse until it was written down. Under a current-rung rule an award would depend on which opponents were unlocked *at the moment it fired*, so the fold would have had to interleave completed games with unlock records in time order — two streams, an ordering hazard on both, and a balance that could not be checked against the game list alone. Pricing by the opposition removes the dependency entirely.

**Storing the price but deriving the award is asymmetric, and the asymmetry is resolved by a rule rather than a second table.** Re-tuning §7.4's multiples downward reduces every player's earned total, and since the balance is *earned minus prices actually paid*, it could drive a balance below zero against unlocks already bought. **The balance clamps at zero, and no unlock is ever revoked.** A downward re-tune costs future purchasing power and takes nothing away. The alternative — storing each award as it fires — buys insurance against a re-tune expected once, before real players exist, at the permanent cost of the property that almost nothing is stored.

**The invariant is "almost nothing", and it used to be "nothing"** (D312). The second stored field arrived for a good reason and the sentence had to move with it, because **a specification sentence that has quietly stopped being true is worse than one that was amended.** What the invariant protects still holds exactly where it matters: balances, streaks, quest progress and statistics remain derived, and a test reconstructs each of them from game history alone.

These records are the **only things in the app not reconstructible from game history**, which is why they must be in the backup allowlist from the first release rather than from whenever the cloud arrives. A player who replaces their phone and loses months of unlocks has lost the only thing in this app that was expensive to acquire.

### 7.7 How these numbers were chosen, and when to change them

Every other number in this document was measured. These were derived from a single stated target: **one unlock should be about one sitting, and the full roster about two months of ordinary play.**

That makes them the most likely numbers in the document to be wrong, and the ones to instrument first. Take the same stance §6.7 takes on opponent strength: **when observed play disagrees with the table, the table changes.** The two signals worth watching are the median time to each unlock and the rung at which players stop.

What must *not* change casually is the **shape** — the same growth rate on both sides. It is what makes downward grinding self-pricing, and a flattened curve reintroduces an exploit that no rule elsewhere is defending against.

---

## 8. User interface

### 8.1 Layout policy

**Portrait phone only.** One layout, orientation locked, on every device.

A large-screen layout is cancelled rather than deferred. It is a second set of screens to design, build, test at every font scale and keep correct, in service of a form factor nobody has yet asked for. It can come back when there is a reason, and coming back is cheaper than carrying it unused.

**That policy has a platform consequence and it is not negotiable** (D360). A build that declares tablet support must declare all four orientations, because tablet multitasking requires them — and modern SDKs have removed the escape hatch that used to let a tablet app refuse multitasking and keep an orientation lock. There is no configuration in which "tablet" and "portrait-only" are both true. **So the build declares phone only**, and a tablet owner gets the app letterboxed in phone compatibility mode, which is a better experience than a resizable window with no landscape layout behind it. Declaring four orientations to satisfy a validator is how a build passes review and then draws a game into a window it has no layout for. Reversing this means building the landscape layout first, not flipping a flag.

### 8.2 The board

There are **two boards**, and the player chooses (§8.16). Both are readings of the same stored move list, so switching mid-game costs nothing — the position, the flash and the winning line are identical the instant it redraws.

**The layered board is the default and the fallback.** All four layers are drawn at once, as sheared parallelograms suggesting depth, so the whole cube is visible without rotation. A move is a **single tap on an empty cell**, with no confirmation step.

- **Derive the geometry from the touch target, not the other way round.** Decide the minimum cell size first and let the board's dimensions follow. Doing it the other way produces a board that looks right and cannot be played on a small phone.
- **The four layers stack in one column.** A 2×2 grid of layers wastes the width a portrait phone does not have and produces cells below the minimum touch target on the smallest supported screen.
- 44 dp per cell is geometrically impossible for 64 always-visible cells on a phone. Adopt the WCAG 2.5.8 dense-grid floor of 24 dp plus a margin, and assert it in a test **across the whole supported size range** rather than on the one device that happened to be tested first.
- **The board is centred.** An earlier edition put it against one edge so a thumb could reach every cell one-handed; the reach argument was real and it is not what the screen looks like. A 4×4×4 board is the subject of the game screen, and a subject pushed against one edge with an empty column beside it reads as something shoved aside. If one-handed play turns out to matter, the honest fix is an alignment the player chooses, not a default nobody sees.
- **A shear, not a perspective rotation**, for a board being played on: shear leaves every cell its own hit area.

**The cube board is 64 glass cells with a gap, drawn on one canvas** (D369). Drag turns it, pinch zooms, and a tap plays a cell. It is where a 4×4×4 game actually lives, and the layered board has needed an animation to explain itself ever since testers read it as four separate boards.

- **Hand-rolled projection, no 3D package.** A GPU library is a plugin, and a plugin is a merged manifest to audit (§11.2) for a picture that is 64 boxes and 64 spheres. The whole renderer is a yaw, a pitch, one perspective divide and a sort — under 200 lines, no dependency, and it runs in a widget test, which a shader-backed one would not.
- **The eye distance is a safety property, not a taste one.** A hand-rolled perspective divide is the one place this kind of renderer fails catastrophically rather than merely looking wrong. Place the eye so the divisor cannot approach zero, and say so where the constant is defined.
- **The tap radius decides how much of the cube can be *reached*, not just how easy each cell is to hit**, because a near cell's disc covers whatever is behind it. This was measured and the first guess was badly wrong: at the obvious radius only 39 of 64 cells were reachable without turning the board, and the opening angle made it worse — near 45 degrees of yaw the horizontal and depth axes project onto nearly the same screen direction, so cells one step apart in each land on each other. Sweeping both numbers reached 55 of 64 while leaving the farthest cell comfortably above the touch-target floor. **A test asserts that every cell is reachable from some angle**, because a cell the rules say can be played and the interface says cannot is a defect the player cannot diagnose.
- **Frontmost wins, and an occupied cell swallows the tap** rather than passing it to the empty cell behind. Playing a cell the player never saw is a legal move no game record could explain afterwards.
- **A played piece is drawn much larger than an empty marker.** At the same size a piece is a dot, and counting a line of four means leaning into the phone. The step between the two is what makes occupancy readable across the cube at any rotation.
- **Reviewing always uses the layered board, and the toggle disappears with it.** Scrubbing is a reading task, and an instrument that must be turned to be read is the wrong one for it.
- **The cube is not accessible, and says so rather than pretending.** Sixty-four cells on a canvas have no stable rectangle for touch exploration. It carries one label naming the layered board as the way to read the position cell by cell. **This is the one thing the two boards do not do equally, and it is why the layered board is the default.**

Common to both:

- **When a game ends, highlight the completed line.** Win detection therefore returns *which* line completed, not merely that one did.
- **Mark the last move played, by each side.** Marking only the newest move means a player's own piece stops being marked the instant the opponent answers — about half a second against a computer — so the one move they never see marked is their own. Mark the last two: turns alternate, so that is exactly one per side.
- If the mark is a colour change, **move each piece away from its own resting colour** rather than towards a shared accent. A light piece going to a light green is a hue shift with no lightness shift, and on a small piece under phone glare that is nearly nothing. Ours failed exactly this way and every test passed, because every assertion compared the two *marked* pieces to each other rather than to an unmarked piece of the same colour.
- Any pulsing stays well under **three flashes per second** (WCAG 2.3.1), and holds steady instead of pulsing when the platform reports reduced-motion.
- **The pieces are shared between the two boards and the geometry is not.** A player who switches display mid-game must not find the stones have changed colour.

### 8.3 Main screen

Top to bottom:

1. **Rating card** — the computer rating, the win/loss/draw record, the points balance, a streak, a ten-game trend graph, a leaderboard button, and a line making clear it is a rating against the computer
2. **Your path** — a scrollable row of opponent tiles (§8.4)
3. **Games in progress**
4. **Quests** — the four closest to completion, with an achievements button (§8.6)
5. **Recently completed quests**
6. **Finished games** — ten rows and a way to see the rest (§8.5)
7. A large primary **new game** button, and an entry to the tutorial

**The ten-game trend graph.** A line with a dot per game over the last ten completed games, coloured green if the rating is higher than it was ten games ago and red if it is lower, **with the signed change stated beside it** — `+43`, `−12`. The number is not decoration. Trend colour here is *information*, not confirmation, and red-versus-green is the worst possible pair for the commonest colour vision deficiency; without the number, a red-green colourblind player learns nothing at all from the graph. Fewer than two completed games, no graph.

**The graph measures from a real baseline, and draws it** (D289). The series holds the rating **after** each game, so measuring from its first entry silently removes that game from the total — a player who had won once was told their last ten games were worth nothing. The change is measured from the rating held *before* the window, which is the seed when the window reaches back to the start of history, and **that baseline is plotted as the line's first point**. Drawing it is part of the fix rather than a flourish: a line that starts at a point it never plots makes the rise the eye takes off the graph disagree with the number printed beside it, in the direction that makes a good run look flat.

That defect had a twin at exactly the window length, where an off-by-one reached for a non-existent entry and fell back to measuring from within the window. **The tests that missed both asserted the presence of a signed number and its sign, never its value against an independently computed one.**

**On showing a rating as a bar anywhere:** scale it against the **top of the catalogue**, from zero. Scaling against the strongest opponent the player has met puts a full bar in every list, means something different on each device, and shortens every existing bar the first time they beat someone new. Zero-based rather than min-max, because 600 really is a quarter of 2400 and the roster is not evenly spread. Draw the unfilled track too — the comparison being offered is against the top of the ladder, which is usually not on screen. And show the number as well: a bar is comparative and cannot be read off; a number is exact and cannot be compared at a glance.

**A summary object holding both an earned total and a spendable balance is a trap** (D316). Two surfaces once disagreed about the same number because one of them read the earned total — which keeps rising as unlocks are bought — where it meant the balance. Two things let that reach a device: a warning comment on one widget, which does not protect the widget beside it; and a test suite in which nothing was ever *spent*, so earned and balance were the same number and the defect could not appear. **Name the parameter for the quantity it is, and make the regression test buy something first.**

### 8.4 Your path

**A horizontally scrollable row of the whole roster, resting on the opponent the player is climbing toward.** Three tiles are visible at a time and the row starts scrolled so that the middle one is the **lowest-rated opponent rated strictly above the player's rating**. The player can scroll left through everyone they have beaten and right through everyone they have not, in roster order. Each tile stacks vertically: a full-tile-width avatar, the name, the rating, the win/loss/draw record, three stars, and a rematch button — icon only, with a spoken label, because no button text fits the width.

**It rests on the rating ladder, and scrolling is what makes that safe.** A *fixed* three-tile window could not rest there: a new player would have seen three opponents they already own with their next unlock outside the window entirely, so the price ladder would be invisible on first launch. A scrollable row removes that objection rather than answering it — the unlock ladder is one swipe right, and it is reachable at every point on the roster instead of only where the two ladders happen to coincide. What the resting position buys is the answer to "where am I", which is the question the player asks first and the one a rating answers.

**Rated strictly above, so the centre is always a step up.** An opponent rated exactly the player's own rating sits to the *left* of the resting tile. An even match is not "next", and the even-match marker (§5.1) already says what it is.

**The row clamps at both ends without leaving a hole.** A player below the whole roster rests at the first opponent, one above it rests at the last, and either way three tiles are on screen. A two-tile row with a gap in it looks like a bug.

**It says it scrolls, with two buttons that step it** (D318). The row shows three tiles and is exactly three tiles wide, which is what hides the gesture: a list that overflows by a little has a half-visible fourth item promising more, and here the fit is exact, so a player who never guesses to swipe sees five opponents out of thirty-one. **A swipe nobody makes is the same as no swipe**, and the whole reason the row scrolls is that the price ladder should be one swipe away rather than invisible. An arrow at each edge steps the row exactly one tile, from the nearest tile boundary rather than from wherever the row currently sits — a drag is a gesture and a press is an instruction. They **fade at the ends rather than disappearing**, and become non-interactive at the same time: removing them would take their explanation with it, and an invisible control that still swallowed a press would eat a tap meant for the tile underneath.

**A control that hangs outside its parent is painted and never pressed** (D319). Hit testing checks the parent's own box before it asks any child, so every pixel of an overhang is dead — not a rounding problem a bigger target fixes. Disabling clipping changes only the painting. **The box that contains such a control has to be the one that extends past the panel**, which means the section owns the full screen width and applies its own margin, with the control a sibling of the panel rather than a child. The control's size is then *decided* by the geometry rather than chosen: with part of it outside the panel and a full touch target around it, the target's outer edge must land on the screen edge and not past it, for exactly the same reason.

**The row snaps to a tile boundary**, so a flick always leaves three whole faces on screen rather than two and two halves — implemented by rewriting the fling's simulation rather than by animating after it ends, so it does not fight a finger that is still dragging.

**Locked opponents appear in full**, with their price and the player's progress toward it. Hiding them would hide the goal, which is the entire motivation for the ladder. (The mercy rungs are the deliberate exception — §7.3a.)

**Tapping a tile opens that opponent's detail page** (§8.15). The tile is a summary and the page is the whole of what is known about them.

**The three stars count decisive games only.** Draws are ignored, on both sides of every comparison.

| Stars | Condition |
|---|---|
| none | never played, or no wins |
| ★ | fewer wins than losses |
| ★★ | wins at least equal to losses |
| ★★★ | at least 80% of decisive games won |

An opponent never faced shows **no star row at all**, rather than three empty stars. Unearned and failed must not look the same.

**One name is written short, and only where the width is a third of a phone** (D320). The longest name in the roster does not fit a tile. This is deliberately **not** a general rule: a width-aware shortening — first word, or initials past N characters — would have to be right for thirty-one names in two languages, and it is wrong for one of them today. When a second name needs shortening it gets a second arm, chosen by somebody who has looked at it. **And the tile speaks the long name while writing the short one**, because a screen reader has no width: the abbreviation buys nothing there and costs the listener the name.

### 8.5 Finished games

Ten rows, most recent first, each opening into replay. A **show more** button opens a full history screen rather than expanding the list in place (D284). Ten is one screenful and roughly a week of ordinary play, so the common case never sees the button. The reason it is a screen is that the main screen carries seven sections: expanding a list in the middle of it pushes the primary button below everything and leaves the player scrolling back up past all seven to reach it. A pushed route also comes with a back button, which is the affordance for "I have finished looking at this" that an expanded section does not have.

Each row carries:

- the result label **above** the rating change rather than beside it, which is what buys the vertical room for the quests section
- an up arrow and `+n`, or a down arrow and `−n`
- a **relative date**: `today`, `yesterday`, `2 days ago` … `7 days ago`, and beyond that the device's own date format, in both languages
- a **challenge** button that starts a new game against that opponent

Two things about the rating change:

- Compute the whole list's changes in **one pass**. The change is a property of the history *up to* that game, so the obvious per-row call re-folds the entire prefix each time and is quadratic.
- **A step can round to zero.** Beating an opponent far below you earns a fraction of a point. There is no direction to point in, so show the number alone rather than an arrow claiming a movement that did not happen.

Let the arrow's direction and the number's sign each carry the meaning independently, so colour is confirmation rather than information.

### 8.6 Quests

The **four quests closest to completion**, ranked by percentage complete with ties going to the smaller absolute remainder. Each shows an icon, its name, and a progress bar.

**Ties break by roster order, weakest opponent first** (D281), with the id as a final tie-break only so the list cannot reshuffle between two identical rebuilds. On a fresh install more than sixty per-opponent quests are tied on both primary rules, and breaking by id is breaking by spelling — which opened the section with four opponents chosen alphabetically, three of them locked. Roster order shows the player the cheapest things they could actually go and do next, which is the question the section exists to answer.

A quest a free player cannot reach (§7.4) shows its requirement plainly and what would change it, rather than presenting an unexplained wall.

Achieving a quest during a game is acknowledged **when that game ends**, together with the points it paid — not silently recorded and not interrupting play.

**A second panel lists the four completed most recently**, below the four closest, and only once there is at least one (D298). "What should I do next" and "what have I just done" are different questions and a single list answers neither: a finished thing is not close to finishing. The recent panel is also the only place a quest's award can honestly be shown, because until a volume or streak quest fires there is no figure for it.

**The completion timestamp is not a new source of truth.** Every branch of the fold already had to identify the game that completed a quest in order to price it, so recency costs one field and no second pass. **A quest whose completing game has no timestamp sorts last** — documents written before completion times existed carry none, and reading null as "now" pins the oldest history permanently at the top of a list about recency.

### 8.7 Opponent selection

Thirty-one opponents is too many for a flat list on a phone. Present them as an **accordion by tier, opened at the tier containing the player's own rating** — where they are standing, not at the top or the bottom. Each row carries name, avatar, rating, tier description, blurb, record, stars, and a marker for pairings that are lopsided (§5.1).

Locked opponents show their unlock price and progress. The unlock action lives here, on the Your Path tiles and on the detail page (§8.15), and all three lead to the same confirmation — which, for the two book opponents, must repeat what §6.6 requires.

**Tapping a row here starts a game**, as it always has. This screen is reached by pressing *new game*, so the player has already said what they want to do; routing them through the detail page first would add a tap to the commonest path in the app. The detail page is for browsing, and it is reached from Your Path.

**Backing out of the opponent list cancels the whole flow.** Falling back to a default opponent gives the player a game against somebody they did not choose, which is worse than no game.

### 8.8 Game screen

Opponent above the board, the board, a move-history scrubber, and — against a human — chat.

**The result panel sits below the board, not over it.** A player wants to see the position that just ended alongside the result.

**The scrubber replaces the turn banner rather than adding a row.** There is no vertical room for both on the smallest supported phone — measure the slack before designing the control. While reviewing, the board is not interactive, so the touch-target floor does not apply to it and it may give up height.

**Opening a finished game goes straight to review**: the scrubber is present and active immediately, with the result shown alongside it. A finished game has exactly one thing a player came for, and making them find the control first is a step with no purpose.

**The game screen has almost no vertical slack**, and that decides where controls go. A labelled row above the board costs more height than exists, and adding one puts the cells under the audited touch floor. The app bar has the room; a caption that has to be dropped survives as a tooltip, which is also what a screen reader announces, so what is lost is the sighted caption alone.

### 8.9 Matchmaking entry points

| Path | Behaviour | Creating | Accepting |
|---|---|---|---|
| Invite link or code | Share a link; whoever opens it joins | tier 3 | **free** |
| Direct challenge | Challenge someone on your friends list | tier 3 | **free** |
| Auto-match | Server pairs the nearest-rated waiting player | tier 3 | tier 3 |
| Open challenge board | Public list anyone may accept | tier 3 | tier 3 |

**Invite codes are bearer tokens**: enough entropy to resist enumeration, short expiry, single use, revocable, and checked against the creator's block list on join.

**Friendship is mutual.** Adding sends a request; friendship exists only once accepted. Friend requests carry **no free text** and are rate-limited, because an unfiltered request message is a chat channel that bypasses the chat preference. Display-name lookup is exact-match only and rate-limited.

This matters more than it looks: *friends only* is the default chat preference, so if friendship were unilateral, anyone who added you would become a friend and the default would be defeated by the adder's own action.

Auto-match offers a similarly-rated computer opponent after a short wait rather than leaving a player queued against an empty population. That fallback creates a local computer game, does not consume the online cap, and **never offers a locked opponent** — it falls back to the nearest unlocked one instead.

### 8.10 Profile view

Display name, avatar, human rating, record, head-to-head against the viewer, member-since. The computer rating, the points balance and the unlock progress are never shown to anyone but their owner — they describe a single-player journey and mean nothing to an opponent.

Last-active is **coarsened** — "active this week", not a timestamp — and shown only to accepted friends. Combined with unique display names and add-by-name, a precise last-active is a presence-tracking capability against a named individual.

### 8.11 End of game

A result screen showing the highlighted line, the rating change on whichever ladder the game belonged to, the points earned, any quest completed, and a one-tap rematch that swaps colours and the starting player. A pass-and-play result says plainly that no rating changed and no points were earned.

The rating change shown must be **the step that game caused**, folded from the prefix ending at it — not the step the most recent game caused. Those differ the moment a player opens an older finished game.

**If the win just paid for the next unlock, say so here and offer it** — that is the moment the player is most interested. Two conditions, both necessary (D286):

- **It must be the crossing game.** The balance before this game is below the price and after it is at or above. Offering whenever the player merely *stands* above the price repeats the offer after every subsequent win, which is an advertisement rather than a prompt.
- **It must be the most recent finished game.** Opening an older game out of the history list would otherwise make an offer on the strength of points that everything played since had already spent. This is the same distinction the rating change makes with its prefix fold, applied to a different quantity.

### 8.12 Tutorial

Shown once on first launch, restartable from settings. It covers the objective and what the 76 lines look like — with emphasis on the diagonals through layers that new players consistently miss — how the layered view maps to the cube, basic strategy, and an **interactive practice game with hints**.

**The first board is a cube before it is four layers** (D366). The first tester to reach the tutorial read step 1 as four separate boards, so the one picture a first-time player sees argued *against* the sentence it sat under. The board now opens shut, turns, and comes apart over two seconds, and the text points at the picture. Four things about that:

- **The intro interpolates parameters, never matrices.** Spread, angle and perspective each arrive at exactly the value the resting board is drawn with, and at the end the widget returns the plain board every other screen is built from — not the intro's own stack with its spacing happening to match. **An animation that lands *next to* its resting state and snaps has taught nothing**: the player saw two unrelated pictures. A test asserts all sixty-four cell rectangles match a board built with no intro at all, which is the only form of that promise worth having.
- **It is cheap only because the board is inert.** Hit testing through an inverted perspective matrix and sixty-four moving semantics nodes are what make 3D-in-Flutter expensive; a tutorial board is disabled and carries one label, so neither applies. This does not license a perspective rotation on a board being *played* on (§8.2).
- **Three details had to be found by looking rather than by reasoning**: the layers had to be staggered sideways as well as stacked, or the shut cube shows straight through its own gaps and reads as four tall columns; the shut spacing had to come down until each layer showed a sliver rather than a row, because a sliver reads as an edge and a row reads as a row; and the captions had to be held back almost to the end, because a caption needs the full chrome height above its grid and that gap only exists in the last few percent.
- **Connectors between the layers were built, shipped and removed one look later.** The argument was sound in the abstract — an exploded view uses connectors to say "one object, pulled apart" — and it was never checked against the projection. Every layer is drawn with the *same* parallelogram, so corresponding corners share an x and each connector is a plain vertical line; a genuine cube edge under an oblique projection of an exploded stack is not vertical. They were twelve tick marks in the right neighbourhood, and they ran through the captions. **An argument by analogy to a diagram convention is not a derivation.**

Six more things learned building it:

- **Draw the demonstrations on the real board widget.** A second, simplified illustration board is a second thing to keep correct, and it will drift.
- **Describe a demonstration board in one sentence**, not sixty-four cell labels. A screen reader reading out an entire empty board to reach the three interesting cells is worse than useless.
- **Strategy is a section of the one tutorial, not a second tutorial.** Splitting produces two things a player must find.
- **Derive hints from the opponents' own rule ladder** rather than scripting them. The hint is then correct by construction in any position, and it is the same code the opponents use.
- **The practice game is never written down.** It is not on any ladder, has no opponent worth recording, earns no points, counts against no meter, and would otherwise appear in the player's history as a game they did not play.
- **Remember that the offer was declined, separately from completion.** Record the offer *before* showing it: a dialog dismissed by tapping outside returns no answer, and recording afterwards re-arms the offer on the next launch. Repeating a question the player has waved away is the failure mode to design out.

### 8.13 Accessibility

- **Pieces distinguishable without hue.** The two players' pieces differ by **lightness**, which survives every form of colour vision deficiency including full achromatopsia. Shape is an acceptable alternative, not a requirement. Whatever else the board does with colour — marking a move, highlighting a win — must not turn this into a hue distinction.
- **Every cell exposes a position-and-contents label** such as "Layer 2, row 3, column 1, empty".
- **A row that shows several facts announces them as one node**, not three. An avatar is decorative; a name and a state only mean anything side by side. Equally: whatever the eye can read from a shape must be *said* somewhere, and said **once** — a rating shown as a bar and a pill and announced twice is worse than never announced.
- **A container that announces itself and excludes its children swallows anything added inside it** (D285, D390). This is the single most repeatable accessibility trap in this codebase. A widget dropped into such a container that declares its own semantics compiles, renders, and says nothing — the failure is silent, and only a test for the label fails. Two rules follow. A new widget that wants to speak from inside one must be given a line in the *container's* label instead. And **a control is not a fact**: when an interactive element lands inside such a container, the exclusion moves to each piece of text individually so the control keeps a node of its own. One stop for the facts, one for the action. Excluding a button along with the text hides a control from exactly the readers who most need it announced.
- **Nothing carries meaning by colour alone.** The trend graph states its change as a signed number, a locked tile says "locked", stars are counted rather than merely drawn.
- **A state carried by dimming needs a symbol too.** "Dark" is not a word: a locked portrait carries a padlock, and the state is in the semantics label of every row and tile that draws one.
- **Announce changing state through a live region**, attached to the message rather than to the space reserved for it. A live region wrapped around an empty placeholder announces nothing, repeatedly.
- **System font scaling is respected**, and every screen must reach its last row at the largest setting.

**Sweep the whole app at the largest scale on the smallest phone, not the screens you just built** (D374). A sweep at 2× on a 320pt screen found three shipped overflows; every one of them is invisible at 1.5×, so a sweep calibrated to what looks plausible would have found none. The two screens that had already been swept were the two most recently built — **coverage follows recency, not risk**, which is the normal shape of a test suite and the reason a whole-app sweep finds what a per-ticket criterion does not.

**Fix a font-scale overflow by removing the constant, not by raising it.** A taller cap is a bigger number the next accessibility setting can exceed again; a scroll view cannot be exceeded, a `Flexible` wraps, and a toolbar height scaled by the text scaler grows with what it holds. **And generalise the fix one level up**: a constant strip scaled correctly while the platform's constant toolbar directly above it was left alone, for the identical reason, and survived a further release because the strip failed *visibly* while the toolbar merely overflowed into a clip. A partial fix to a class of bug is more durable than no fix, because it removes the symptom that would have found the rest.

- **Light and dark themes** would both have to be readable. There is one painted design and therefore one theme (§8.16).

### 8.14 Settings

Language (system, or an explicit choice), subscription and restore-purchases, the **privacy policy and terms of use** links (§4.1), the two game-service rows (§15), and the attribution required by §6.6.

**There is no theme choice** (D293). §8.16 is one painted design and there is no second one to switch to, so a control offering system/light/dark selected the same screen three ways — and a control that does nothing is worse than no control, because it makes the player doubt the ones that do. The single theme object is handed to both the light and dark slots, and a test asserts they are the same object so a later edit that reintroduces a second theme fails loudly rather than silently shipping half a design. **The stored field survives** rather than being migrated away, so a future release can revive the choice without touching anyone's data.

**Language is watched at the root of the app** and applied immediately, without a restart. "System" is the *absence* of an override, not a third value to translate into one.

**Settings is finite, and a required row displaces an optional one.** When the terms and privacy links had to go in, the tutorial row came out: the main screen already carries a tutorial sign, so settings held a second route to a screen one tap away while two required links had no route at all. **The string for the removed row stays in both translation files** — deleting a translated string to re-add it later is the expensive order to do it in.

### 8.15 Opponent detail

One opponent, in full. Reached by tapping a Your Path tile (§8.4).

**The avatar is the top of the screen, at the largest size it is ever drawn.** These are thirty-one characters with names and faces, and the roster is the thing the player is working through; a page about one of them that leads with a table is a page about a number. Below it, in order: the name, the rating and the tier; the blurb; how the pairing sits against the player's own rating; the record and the three stars; what a win against them pays; and for the two book opponents, the warning §6.6 requires.

**At the bottom, one action.** Unlocked, it is **start a game**. Locked, it is the price, the progress toward it and an **unlock** button, leading to the same confirmation the other two routes lead to. **The page is never a dead end**: the locked opponents are exactly the ones a player came to look at, and a page that shows a price and cannot act on it is worse than a third route into the purchase flow. All three routes call the same code, which is where the confirmation and the warning live.

**It reads the same catalogue and the same folds as everything else.** No new record, no second copy of a rating, no per-opponent document. What it adds is a place to put what is already known, at a size worth looking at.

**Selection and browsing are entered with different intentions**, which is why opponent selection does not route through this page (§8.7).

### 8.16 The look

**One painted design, on every screen, in every brightness setting.** A mockup is an indication rather than a specification: where it and the built functionality disagree, the functionality leads. Ours draws several things that were never built, and the app has several things the mockup does not draw; both are fine and neither is a defect list.

**The frame.** A sunlit forest is painted behind a transparent scaffold on every screen and does not scroll — it is a place the app is in, not a thing on a page. On it sit two kinds of card: one dark panel for the headline number, and parchment for everything else. The main screen is a stack of short cards on the forest; every other screen puts a single sheet of parchment under its whole body, because ink over a photograph of leaves is unreadable at any size.

**No ink colour survives a photograph, so the photograph is darkened** (D296). This was settled by measuring rather than by looking, and the measurement is the point:

| Text | vs the picture's median | vs its brightest fifth |
|---|---|---|
| light, on the app bar | 3.45 | **1.01** |
| dark, on the turn banner | **2.90** | 11.2 |

A photograph with a bright clearing and dark trunks makes *every* choice illegible somewhere on the same screen. A constant darkening filter applied where the picture is painted — one line, in the one place, so a screen added later cannot forget it — is what makes a single light text colour work everywhere. Nothing on a card was ever in doubt; the problem is only ever the bare picture.

Three corollaries, each of which cost real time:

- **Anything a player reads on every move belongs on a card**, not on the scrim. A live-region turn banner is the clearest example.
- **A text style carries the colour it was designed for, and no ancestor can take it back.** A default text style is consulted only for text with no style at all, and a theme override cannot help if the caller resolved the theme above the widget doing the overriding. Both were tried. Three lines shipped as dark ink on a dark panel at 1.04:1. **The colour has to be named at the call site.**
- **Screenshots are part of reviewing a design change.** All three of those lines were found on screenshots of the running app, after a review that had measured the palette correctly and had no way to see what was rendered.

**A token used outside the surface it was defined for is the commonest way to get no contrast at all** (D383). A muted-ink token that is right on parchment arrives as dark brown on a dark-brown filled button at **1.31:1** — not low contrast, *no* contrast. Nothing catches it, because both colours are correct tokens and the pairing is made at a call site where no check looks. And where a palette has no lighter option that clears WCAG AA, **say which way the judgement went and why**: ours settles at 4.30:1 against a 4.5 threshold, because every alternative is worse and because the signal the colour carries is also carried in numbers directly above it.

**Portraits.** Each of the thirty-one opponents has a painted portrait, drawn in a circle with a ring. **A locked opponent is a runtime colour filter over the same file, not a second file** (D291) — one filter, the same thirty-one images, against twice the files and twice the download. That is only possible because the pipeline cuts the portraits to a circle and gives them real alpha; source art delivered as opaque squares carries whatever the artist left in the corners, and masking the disc discards it. **It is a veil, not a silhouette**: these are full-bleed circular *scenes* rather than subjects cut out on transparency, so there is no outline in the file to silhouette, and a constant-colour matrix produced a flat dark disc that read as a picture which had failed to load. A partial veil leaves the creature visible as a shape in the gloom.

**Carved wood.** The primary actions and every section heading are wooden signs rather than buttons. **The signs ship blank and the app writes on them** (D297), which is what makes them localisable — the alternative was inpainting wood grain from a script to replace baked-in lettering, which would have looked patched. Four rules come out of that:

- **The geometry is measured, not guessed.** Each sign carries a record of where its caption sits, how big it is and how far the plank leans, **as fractions of the picture**, so one set of numbers holds at any size. The lettering angle and colour are recovered from the artwork that carried the words, so the app writes at the angle the painter used. New artwork means measuring again.
- **Captions do not scale with the system font slider**, deliberately: the wood is a picture and cannot grow, and a caption at 200% would run off the plank. Nothing is lost — every sign is either a button whose accessible name is the caption or a heading whose semantic label is it, so a screen reader gets the same string at whatever size the reader wants.
- **One `Text` with several shadows, not two stacked `Text`s.** A stroked layer behind a filled one looks identical and puts every caption in the widget tree twice, so a finder for the caption starts matching two widgets and a dozen unrelated tests fail. That is not a testing inconvenience to work around with a count; it is a signal that the widget was lying about how many things it was.
- **Every section wears one.** A sign that one section had and the others did not reads as an accident rather than as a hierarchy. Which plank a heading gets depends on how long the caption is rather than on which section it is — the long one is needed in one language and not the other.

**One height means the plank, not the file** (D299, D301). Four separate mechanisms can make "the same height" produce four different sizes, and this project hit all four:

1. **The file's height is not the wood's height.** Different artwork carries wildly different transparent margin — 0.555 of the picture against 0.385 — so drawing both at the same picture height gives one of them two thirds more board. The record has to carry where the plank starts and how much of the picture it is.
2. **Reserving space and constraining a child are the same thing unless you say otherwise.** A sign that hangs mostly outside its panel has only the inside part reserved, and a box of that height passes its maximum *down*, squashing the sign to the few pixels reserved for it. This is the same class of mistake as an image with no known size: a box meant to describe layout silently also describes the child.
3. **A card paints its border over its children.** A heading inside a card gets the card's own top edge drawn through the lettering. The sign has to be a *sibling* of the card, in a stack, rather than a child of it — which is why one section looked right while the rest did not, since a decorated sliver paints behind.
4. **An overhanging heading needs a gap, not a z-order.** A viewport paints its slivers back to front, so half of each sign disappeared into the panel *above* it. There is no z-index to reach for; the fix is real vertical space between sections.

A fifth arrived from the same rewrite: splitting one placement into two dropped an inset argument at the one call site that needed it, **and a default is exactly what lets a required value go missing quietly.**

**Every picture is drawn in a box the layout already knows** — both dimensions, before decode (D295). An image with an unknown dimension reports zero until its bytes arrive. This cost three separate bugs with the same shape and none obvious from reading the code: a button that laid out at zero height and was untappable, a zero-width gap beside a title, a heading row that collapsed. **On a device each self-corrects a frame later, which is worse than failing** — it is a layout that jumps once, on first launch, where nobody is looking. In a widget test nothing ever decodes, so they never self-correct, which is how all three were found.

**Decoration yields to text.** Above roughly a 1.4 text scale, decorative artwork is not drawn. Artwork is the only thing on the screen carrying no information, so it is the first thing to go when the words need the room. The failure it prevents is worth naming precisely: a panel that fills the entire viewport on its own does not overflow and does not throw — it simply pushes everything below it out of view, and a lazily built list means a test that pumps and looks reports the other sections *missing* when a player would have found them by scrolling.

**Type.** A display face for headings and the rating, a reading face for anything in sentences. Both are bundled, never fetched.

**The board keeps its geometry.** It gains the palette and the background and nothing else. It is the one screen where a mis-tap costs a game. Its own empty-cell markers take a colour from the palette rather than a neutral grey: a grey chosen as "a tint of neither side" sat *inside* one piece's own colour range and was told apart mostly by being smaller, where a warm parchment is further from both pieces than the grey ever was.

**Layer captions take their colour from the caller**, because they are the one part of the board drawn on whatever is behind it rather than on a cell — the forest in a real game, parchment in the tutorial. A widget guessing from a theme cannot tell the two apart.

### 8.17 Asking for a review

The app asks the player to rate it, on a win, once they have played enough games to have an opinion.

**Neither platform will tell you whether the player rated** (D389). Both store-review APIs return no success signal, no callback and no way to query rating state — deliberately, so an app cannot nag or reward based on the answer. Both also **silently do nothing when over quota**: roughly three prompts per user per year, after which a request returns normally having shown nothing at all.

So the app records the only fact it has: **that it asked, and when.** The rule is *ask, three times, ninety days apart, then stop.*

- **Three, because past three the platform drops the request anyway.** A fourth prompt is stored state kept to trigger something that does nothing, and a player who did rate — and cannot tell us so — would otherwise get a sheet every quarter forever.
- **Ninety days rather than "three months"**, because months are not a unit a duration has and the difference is at most two days on a prompt that is already deliberately imprecise.
- **Every repeat waits for a win too**, not only the first. A rating sheet immediately after a loss is the worst moment this app has to offer, and waiting costs nothing at a ninety-day interval.
- **The attempt is recorded even when the sheet certainly did not appear** — on a build that did not come from a store, or when the call throws. The alternative is worse than it looks: such a build retries on every win forever, accumulating nothing, and then fires three real prompts in three minutes the day that player installs from the store. **The counter is a record of asking, not of showing, and the name says so.**
- **A clock that goes backwards says no.** A device whose time was wrong and then corrected reads as "the last prompt is in the future"; comparing *not before* rather than subtracting makes that case answer no, instead of asking on every win until the clock catches up.
- **Absent fields mean never-asked**, which is the opposite default to the tutorial offer. Everyone who upgrades becomes eligible at their next win. Defaulting the other way silently denies the prompt to the entire existing player base, who are the people most likely to rate. A *dialog* defaults safe by being suppressed; a *prompt nobody minds seeing once* defaults safe by being offered.

**The feature is unobservable by construction** — no test and no device run can tell you the sheet appeared, let alone that anyone rated. What is testable is every rule about when to ask, which is why the decision is a pure function and why the one call that uses it has a wiring test of its own, **verified by deleting the call and watching a test go red.**

---

## 9. Chat and safety

Free-text 1:1 chat, only between the two players of a shared game and only while that game exists. No chat with computer players, no group chat, no global chat.

**Chat is opt-in per player, and the more restrictive preference wins.** Three values — every game, friends only, never — defaulting to friends only, overridable for one specific game.

Chat exists for a game only if **both** players allow it. Otherwise permission derives from game membership, which means creating a game against a stranger implicitly opens a channel to them.

Availability is resolved when the game is **accepted**, not created — three of the four matchmaking paths give the joiner no start-a-game flow, so resolving at creation silently ignores their preference. It stays revocable: either player can turn it off, switching the global preference to *never* clears it everywhere, and blocking terminates it. **A game record with no chat field means chat is unavailable**, so games created before chat existed fail closed.

Required: **block** (checked in the game-creation and invite-acceptance path, not only on send), **report**, and **server-side profanity filtering** before delivery. Chat messages are written by the server, never directly by a client.

**Block, report and display-name validation ship one release *before* chat**, because they are contact-surface features and the contact surface opens with invites, profiles and push.

Display names are globally unique, validated server-side, and immutable for 30 days after each change so name-swapping cannot evade blocks.

**Accounts are linked before they are worth anything.** Anonymous auth is enough to try online play; before a first rated game or any purchase the account must be linked to Google, Apple or email. An anonymous account cannot be recovered, and a data-subject request against one cannot be verified. Offering third-party sign-in on iOS requires Sign in with Apple alongside it.

**Account deletion and data export** are both in-app. Deletion removes personal data while retaining game records with the identity replaced by an opaque per-game token, so opponents' rating histories stay coherent. It must state plainly that **it does not cancel the store subscription** — a common review rejection.

---

## 10. Notifications

Your turn, new message, game ended, challenge received, streak about to lapse — each individually toggleable.

**A streak reminder is the one notification the product genuinely wants to send and the one most likely to be resented.** Send at most one a day, late enough to be useful and early enough to act on, only to players with a streak of at least five days, and never to a player who has already played that day. It must be individually toggleable like the rest, and turning it off must not turn off "your turn".

**Push is a mobile feature; web and desktop degrade** to in-app notification and a badge while the app is open. **The app must say so**, because a desktop-only player would otherwise be silently forfeited by the 7-day rule.

---

## 11. Technical architecture

### 11.1 Stack

Flutter for the client. Android and iOS. Firebase for the backend from 2.0: Authentication, Firestore, Cloud Functions, Cloud Messaging.

**Structure the code as a Flutter app over pure-Dart packages**: the rules, search and opponents in one, the rating maths in another, the progression and meter arithmetic in a third — all with **no dependency on Flutter, on any I/O library, on an ambient clock or on an ambient random source, and no runtime dependencies at all**.

Streak and meter evaluation *do* need a calendar, so **the day boundary is passed in, never read**.

**Progression is not in the engine package, by the engine's own rule.** §6.1 says locking is not an engine concern and the catalogue carries no `locked` field, because the strength harness plays all thirty-one against each other and has no business holding an entitlement. Arithmetic about what a player owns and what it cost sits on the other side of that line. It does need the roster index, so it depends on the engine package — the one inter-package dependency in the project, running in the allowed direction.

**The meter lives in the progression package, not a fourth one** (D308). Streak evaluation is the precedent and it is exact: a fold over games plus an injected day boundary, with no clock read inside the package. A fourth package would earn its own purity scan, manifest, CI entry and import graph for about a hundred lines. The cost is that the package's name is now slightly wrong — it holds progression *and* one thing that is really commerce — and that is cheaper than a package. **The package invariant is unaffected and was checked rather than assumed**: no function there accepts the player's rating or rung, and a meter needs neither, because it counts games and which opponent they were against does not change the count.

**Enforce purity mechanically.** A grep in the build gate over each package's manifest and imports. Purity that is merely intended lasts until the first convenient import.

### 11.2 The build gate

One script that analyses and tests every package and additionally checks what the specification demands but a compiler cannot:

- package purity, as above — no I/O library, no Flutter, no Firebase, no platform-service plugin
- no user-facing string outside the localisation files
- the licence attribution is still rendered somewhere in the app's source
- the vendored dictionary's SHA-256 is unchanged
- generated sources are not stale
- every string exists in **both** languages — a missing translation fails the build
- signing credentials are not tracked
- the network posture is declared on purpose (below)
- every platform declaration file actually parses

Nothing is committed without this passing. Give every long run a hard timeout — a hung suite is indistinguishable from a slow one.

#### The network check, and why it is a declaration check

"Computer play makes no network call" began as a negative enforced by a platform mechanism: Android grants network access per application, so **withholding the permission made the platform refuse the call whatever the code asked for**. That was the strongest guarantee this project had, and it is gone (§15) — a leaderboard needs the permission and Android grants it to an application rather than to a screen.

What replaced it is weaker and still worth having: **the permission must be declared *deliberately*, as an explicit line with a comment naming the decision, rather than arriving because a dependency merged it in.** The gate fails if the declaration disappears and fails if the old removal directive comes back. That turns "the permission is absent" into "the permission is present on purpose", and a diff that changes the app's network posture has to touch a line with the reasoning written beside it.

**Three lessons from that history outlive the mechanism, and every one of them generalises past this project:**

1. **Read the artifact, not the inputs.** The original check grepped the *source* manifest, which is not the file that determines what ships. A telemetry transport riding in behind the billing library declared network access, the merged manifest carried it, and the check passed on the very build that shipped it. **The guarantee was never enforced — it merely had nothing to catch.** Enumerating the dependencies you thought of is the wrong instrument; the merge report names the contributor of every line and answers it in one grep.
2. **A guarantee that cannot be checked in every environment must say when it is not checking.** The merged manifest only exists after a release build, which CI does not do. So the check is opportunistic, and **when it cannot run it says so rather than passing quietly** — a check whose limits are invisible is exactly how the defect above survived for releases.
3. **Stripping a permission a dependency wants is a standing hazard, whichever way it is resolved.** Removing it silently disables whatever wanted it, and the failure surfaces as a runtime symptom rather than a build error — which is precisely what happened: three uploads shipped with the permission stripped, and the store's own billing client could not list products, so the shop read "unavailable" on one platform for three releases while the other platform was being exercised (D388). **The intuitive answer was wrong** (billing talks to the store app over IPC, so the caller's own permission "should not" matter) and only an install settled it.

**A release branch is a long-lived fork, and a fix on the trunk does not reach it.** That is what actually went wrong above: the gate had no opinion about which branch a bundle was built from, and it is not obvious that it should.

#### Three more gate rules worth carrying

**A gate must not die where it means to admit ignorance** (D363). A check that looked for an optional build artifact used a command that exits non-zero when its starting directory is missing; under strict shell settings **a failing command substitution in an assignment ends the script** — before reaching the branch whose entire job was to say "no release build on disk, running the cheaper steps only". CI failed three builds printing a section heading and nothing under it.

The symptom was worse than the bug. **A silent abort under a section heading is indistinguishable from that section failing**, so the log accused the wrong check of finding something. The gate now traps errors and names the line, saying whether it stopped on a finding or on an unguarded command. And the real cost was not the three builds: the abort was a third of the way through, so **nothing after it had run on CI for three commits** — a lapsed safety net rather than an unexamined one, but the next run is the first to exercise those steps.

**Parse every declaration file the platforms read** (D364). A privacy manifest was rejected by the store with a message about invalid keys and values; every key and value was correct and **the file was not valid XML at all**, so nothing in it was ever read. XML forbids a double hyphen inside a comment, and this project writes reasoning comments everywhere in a house style full of em-dashes. Two things generalise: **the rejection message pointed away from the fault**, and two minutes with a parser answered what an hour of reading the keys would not. The gate now loads every such file with a real parser and fails with the parser's own message — and fails when *none* is found, because an absent manifest is as shippable a mistake as a malformed one.

**Do not gate on regenerated artwork** (D290). Generated *logic* is regenerated by the gate and the build fails if the committed copy has drifted, because a stale derivation is a wrong one. Images are not that: re-encoding the same picture with a different library build produces different bytes, so a byte-comparison gate fails on a library upgrade while nothing is actually wrong. **A gate that cries wolf is a gate people learn to skip**, and this repository has exactly two that must never be skipped. What is checked instead is the failure that would reach a player: that every catalogue entry resolves to real bytes in the bundle, that the fonts and their licences are there, and that the whole budget holds. A manifest that declares art by *directory* is convenient and silent — nothing objects to a directory missing a file, so the test is what objects.

### 11.3 Layering on the device

A **document store** (bytes: file or in-memory) sits under a **repository** (rules: completion, validation, ordering). The store is the pluggable part, not the repository — swapping the repository in tests would test a path the app does not use, while swapping the store keeps every rule under test.

Make the repository **stream-based rather than future-based**, so the cloud implementation satisfies the same contract without a UI rewrite.

**Game completion is decided in the repository**, once, not by each caller. Points are awarded there too, for the same reason: it is the one place that knows a game has just finished, and awarding from a caller means every future caller must remember to.

### 11.4 Authority model, from 2.0

The client computes and renders moves immediately so play feels instant. A Firestore-triggered Cloud Function re-validates every move, detects the win, and writes the result and the rating change.

A client may write **only** its own move to a game it is in when it is its turn, its own chat messages, and a named list of its own profile fields. A client may **never** write results, either rating, entitlement, totals, timestamps, or another player's data. The allowlist is **field-level, not document-level** — "its own profile fields" would otherwise permit exactly the writes that sentence forbids.

**Points and unlocks stay local and stay client-written**, and that is deliberate. They are earned against deterministic opponents on the player's own hardware, exactly like the computer rating — editing them cheats nobody but yourself. Moving them to the server would mean sending computer-game results to a server, which §4 forbids categorically. The one thing that must be server-authoritative is the **meter** (§4.2), because that gates a purchase.

**The security rules are the trust boundary, so they are a tested deliverable, not configuration**: their own ticket and an adversarial suite in CI where every test is an attempt that must be *denied*.

The rules logic exists in two places — Dart on the client and in the validating function — and both must be driven by the same 76-line definition and the same shared test vectors, or they will drift.

### 11.5 Data model

**Store the simplest correct thing.**

- **No device identifier at all.** None is generated and none is stored. §11.7 states this precisely, including what a platform service is allowed to do.
- A game records a seat that is the player, a named opponent, an ordered list of cell indices, who started and why, and — when finished — the outcome, the reason, the winning line, the completion time, and the opponent's anchor rating.
- An unlock records the opponent, when, the price paid, and whether it came from points or the one-time purchase (§7.6).
- Whose move it is derives from position in the list and the starting seat. No per-move author, id or timestamp.
- Statistics, ratings, point balances, streaks, quest progress and mercy unlocks are all derived, never stored.

Local storage is **never retired**. Offline games stay local for the life of the app; online games live in the cloud. Two implementations serving two kinds of game, not one replacing the other. **There is no import path from local to cloud, ever** — that decision removed the single largest source of complexity and risk in the whole plan.

There is deliberately **no server-side copy of the opponent catalogue**. Computer play never touches the network during a game, so it would be a second source of truth for something the server never uses.

**Backup is enabled on purpose, and the two platforms guarantee it by opposite mechanisms** (D346). One needs an **explicit allowlist**, committed rather than the platform default; the other backs up the application-support directory by default and needs nothing. **They happen to agree because the same storage path was chosen once for one platform's sake**, and that is a coincidence worth naming: a future change of storage directory made for one platform's reason silently moves the other platform's backup guarantee with it, in whichever direction. From 2.0, auth material, the entitlement cache and messaging tokens must be *excluded* — an allowlist entry on one platform, a per-file flag on the other.

"Don't back up regenerable data" does not bite here, for the reason §7.6 gives: the unlock records are precisely the *non*-regenerable data, and everything else is a fold.

It follows that **"no data leaves the device" must never appear in any privacy text** — it is false, and the backup is a deliberate trade. §15 makes it more false, in the same release the store declarations must say so.

**Writes are atomic** — temporary file then rename — so a kill mid-write cannot corrupt a record. A record whose schema version is greater than the reader understands is skipped; equal or lower is read and upgraded.

### 11.6 Localisation

English and Dutch, both complete at launch, English the fallback. All strings in resource files from the first commit. Bot names are not translated; blurbs are. Relative dates, point totals and prices are all locale-formatted; a thousands separator is not a decoration, and §7.3's numbers reach seven digits.

**Plurals are a translation concern, not a formatting one.** A count interpolated into a sentence without a plural form reads "1 games", and the case it is wrong in is usually the *first* thing a new player sees. Use the localisation format's own plural support, and let the singular be the case the tests assert, because it is the one that breaks.

**A bundle-level language declaration is not what makes the app bilingual** (D328). Platforms filter a *native* app's language list by what the bundle declares, and a Flutter app does not read that — the engine reads the system's preferred languages and resolves against the supported-locale list in Dart. The declaration was removed, rebuilt and installed on a wiped device in the other language, and the app came up in that language anyway. **The key stays for the two things it does do**: it puts the app in the per-app language picker in system settings, and the store reads it when deciding which languages the listing claims. **A platform declaration that *looks* load-bearing is often not, and the way to tell is to delete it and rebuild** — which took four minutes.

### 11.7 Identity

**The app generates no identifier and stores none.** Where a platform service identifies the player (§15), that identifier is the platform's, is never persisted by this app, and never enters a Quadrim document.

This is narrower than the claim earlier editions made, and it was amended rather than reinterpreted (D377). A leaderboard entry is attributable by definition, so "no identifier is transmitted" could not stand. **A rule kept alive by a careful reading is worse than an amended one, because the next person reads the rule and not the argument.** What the narrower form buys is that everything downstream is untouched: no player id in any document, nothing new that is backup-eligible, and no migration when accounts arrive and have to decide what an identity is.

### 11.8 Application ids, product ids and versions

**Three kinds of id are permanent once published, and none can ever be reused:** the application id, every in-app product id, and every achievement or leaderboard id. Treat all three as decisions taken once.

**The application id is permanent per store, not per project** (D213, D359). Ours diverged: Android and iOS carry different bundle ids, because one was already on a testing track when the other's store record was created under a different name. That is survivable and it costs a rule — **every place that names an application id has to say which platform it means**, because a single id assumed across platforms is a silent misconfiguration rather than a build error.

**Product ids and achievement ids follow whichever store you are standing in front of** (D365). A product id has no technical requirement to match a bundle id; the binding consideration is what the store will accept. Ours ended up in the iOS bundle id's namespace on both platforms, which is deliberate: **one id per product across both stores** is worth more than each platform's ids matching its own application id, because a second set means a platform branch, two entitlement paths, and a class of bug where the wrong store is asked about the right product. A guard test pins the prefix.

That episode also carries a lesson about how a document can mislead. The decision to keep the *old* namespace was justified by the claim that those ids were "already configured on the other store". They were not — the box was unticked and nothing had ever been created anywhere. **A sentence that sounds like a constraint and is actually an assumption makes a wrong recommendation sound settled.**

**The version name is a story; the build number is a ratchet** (D358). They are not two views of one number.

- **The name is for people.** It may go up, sideways, or nowhere; it may repeat across stores; nothing technical depends on it. It is the number a tester quotes back when reporting a bug, which is its whole job — so **let it say something true about what changed.** A release that adds a capability the previous build did not have at all takes the middle number, because "some fixes" is what a last-number bump looks like, and a player who reads it and then finds a new feature has been told the wrong thing by the one string that exists to tell them (D387).
- **The code only ratchets**, and **it is spent on upload, not on release.** A bundle sent to a testing track and then discarded has still consumed its number. So it is raised on *every* upload, never reused, and never reasoned about as "this release is only a test". The one exception is a delivery that fails validation before the binary transfers, where the store holds no record at all.
- **One counter serves both stores.** Each store only requires the number to increase, so gaps are fine, and splitting it means a second source of truth in a platform project. **A build number must never name two different artifacts**, which is what happens when two branches with different content are uploaded at the same number.
- **Do not derive the code from the name.** A scheme like `0.1.1 → 101` fails the first time two builds of one version are uploaded, which is exactly what a testing track is for.
- **Nothing enforces the ratchet**, and nothing can: the gate cannot know what the store already holds. The comment beside the field is the whole defence.

**Four places must agree** on the application id: the id itself, the build namespace, the source package, and the directory mirroring it. A mismatch is a crash on launch rather than a build error.

### 11.9 Platform floors and declarations

Each of these is a number or a flag that somebody has to own, because a default is not a decision.

**The minimum OS version.** Record it rather than tuning it, until there is evidence to tune it with — the argument for raising it is an API the app does not reach and the argument for lowering it is a device the toolchain will not build for. Then take the evidence when it arrives: ours was raised by the store refusing an upload against a deadline it described as years away. **Raising the floor later drops devices that had the app, so the cheapest moment to raise it is before anything has shipped.** Note also that a floor two versions above the toolchain's own default is a number somebody has to *maintain*: a future toolchain upgrade that raises its default past it will silently agree, and one that does not will leave it looking deliberate when it is merely enforced.

**Export compliance, declared in the bundle rather than answered per build.** Without the declaration the store asks the question about every build and the build sits unavailable until somebody answers. Declaring it is a statement of fact — this app implements and links no cryptography, and the transport-level encryption the system frameworks use for store traffic is exempt on two independent grounds. What it costs is that the answer is now committed rather than considered: **anything later that ships an algorithm makes the declaration false and must change it in the same commit.** The gate cannot see that a package has started encrypting something; the comment beside the key is the whole defence.

**A privacy manifest declares what the *app* does.** Check the dependency manifests too — and check the built product rather than the package sources, because **a plugin with no native bundle has nothing to carry a manifest in**, so nothing declares an access on the app's behalf even when the plugin is the thing reaching the API. Ours declares exactly one accessed API, traced to the line that reaches it: directory enumeration, under the file-timestamp category, with the app-container reason. **A manifest not listed in the target's bundled resources ships nothing and fails silently**, so confirm it in the built product rather than on disk.

**A release build without signing credentials must fail at build time** (D355). The scaffolding default that signs a release with the debug key and says nothing is the actual defect: the failure surfaces at the store instead of at the build — or does not surface at all and gets written down as success, which is what happened here for two releases. **The fix is to delete the fallback, not to add a config**, so that a missing credentials file throws at configure time for any release task. Verified both ways: a release build fails with the message, a debug build is clean.

The credentials themselves live **outside the repository, not merely outside version control**, and the gate asks the tool what is *tracked* rather than trusting what is *ignored* — a rule is a habit with a config file, and a force-add beats it.

**The launch screen is not the first frame unless you make it one** (D323, D331). Two rules:

- **Bake in whatever the app draws over the same picture.** Shipping the bare photograph puts a bright image on screen for a few hundred milliseconds and then darkens it the instant the first frame lands — a flash, just not a white one. "Nothing on top of it" means no logo and no text, not no scrim. Verify it **numerically**, by comparing a fixed strip of the generated file against the running app, because a screenshot taken during the app-open animation is dimmed and scaled by the platform and looks like a real defect.
- **Know which defaults the platform is supplying.** Modern Android draws the splash itself and ignores the window background entirely, defaulting to a light colour and to the whole adaptive launcher icon. A mark designed for a dark field then appears as a dark square on white. Set the splash colour, point the splash icon at the foreground layer alone, and make the normal theme match so the hand-off is not a flash. **Declare version-gated attributes in the unqualified resource folder**, not a version-qualified one — night-mode qualifiers outrank version qualifiers, so a version-qualified file loses to an existing night-mode file on exactly the devices that asked for dark.

**A generator that owns a directory must own what it removes**, not only what it writes (D329). Dropping a declaration without dropping the files leaves orphans that nothing names and nothing renders — invisible in the app, present in the repository, and exactly the sort of thing a future scaffolding run re-adopts. And **the same mark needs different insets on different platforms**: one platform's adaptive mask eats the outer third and wants clearance for it, the other shows the whole square and rounds the corners itself. Reusing one inset puts a small mark in a large field.

**Format is decided by measurement, not by intuition** (D330). The launch image is the one lossy asset in an otherwise lossless pipeline, and the reasoning is worth keeping because "lossless is better" is the instinct it contradicts:

| encoding | size | worst channel error |
|---|---|---|
| lossless | 2198 KB | 0 |
| lossless, quantised to 256 colours | 1231 KB | 32 |
| lossy, quality 88 | 375 KB | 10 |

Quantising — the obvious way to shrink a lossless image — is **three times larger and three times less accurate** than the lossy encoding. A scrim compresses the whole picture into a narrow band of smooth gradients, which is the case lossy encoders handle well and palettes handle badly. Note also that asset catalogues read by the platform before the framework starts accept fewer formats than the framework does, which is what removes the project's usual choice.

**A scrim constant that lives in both the app and the art pipeline is a synchronisation hazard** with no mechanism behind it. The symptom would be a visible brightness step at launch.

**Source art is named after the catalogue ids** (D332). A filename-to-id map to paper over delivered typos is the right call at two entries and the wrong one at three: a folder that matches a typo is not matching anything worth preserving, and the cost is a second place to look every time an id and a picture disagree. Rename the files; version control records the renames. The test that every id resolves to a file is the property the map existed to buy, and the only one that ever mattered.

**Check what a scaffolding command touched outside the directory it promised to touch** (D327). "It adds one directory and nothing else" is a statement of intent, not of fact, and the only way to hold it to that is to look at the working tree immediately afterwards, before anything else runs. Ours wrote a template test that does not compile against this project, and rewrote the project metadata twice over — replacing one platform in a list rather than joining it, and recording a toolchain channel that was an artefact of how the toolchain was installed. **Two of the three would have been invisible in a diff read at the end.**

**Dependency resolution files are only a guarantee if they exist.** A toolchain that resolves platform dependencies through a package manager with no committed resolution file lets two machines build against different point releases without the repository noticing. That is acceptable for one dependency and would not be for ten. **An instruction from before a toolchain default flipped is dormant, not wrong** — leave it in place rather than deleting it, because the moment a dependency without support for the new mechanism is added, it becomes live again.

**Machine conditions are not project conditions.** Some of what stands between a fresh machine and a build belongs to that machine — a toolchain's temp-directory behaviour under a security filter, a system package manager too old for a modern dependency graph. Record them where developers look (a contributor guide), not in the specification, commit no path to them, and leave CI untouched.

---

## 12. Release plan

| Release | Contains | Platforms | Public |
|---|---|---|---|
| **0.1** | The complete offline game: board, all thirty-one opponents, computer rating, points, unlocks, quests and streaks, history and replay, tutorial, settings, both languages | Android | no |
| **0.2 (art)** | Real art, polish | Android | no |
| **0.1.x** | iOS. The one-time unlock, the subscription and the meter, entitlement read on the device. The cube board. Terms and privacy in the binary | **+ iOS** | **first public release** |
| **0.2.0** | Platform game services: sign-in, one leaderboard, forty-six achievements (§15). The review prompt. The mercy rungs | Android + iOS | in testing |
| **2.0** | Accounts and the cloud repository; async online play, free; invite links; push; chat with block, report and name validation; account deletion; privacy policy. Entitlement and the meter move to the server | Android + iOS | yes |
| **3.0** | Human rating **and** server-side move validation, together. The online subscription, which is what makes online play paid | Android + iOS | yes |
| **4.0** | The remaining platforms — web and desktop | + web + desktop | yes |

**The plan was re-cut once for a reason that was not technical, and that is the part worth keeping** (D302). An earlier ladder had every release queued behind a single store account, so one blocked account stopped everything. The re-cut removed the single queue rather than working around it: **one version, two release dates**, shipping to each store as that store becomes able to accept it. Two independent queues cannot both be stopped by one account.

**What that cost, recorded rather than absorbed.** The store requirement that used to gate the first public release — twelve testers for fourteen continuous days — was not only a requirement, it was the **measurement instrument**. A fourteen-day cohort is a retention experiment, and the one behavioural signal that matters (does a tester unlock an opponent with points they earned?) was to be measured by it. Removing the requirement removed the discipline, and **the discipline then has to be supplied deliberately or it will not happen** (§14).

It also moved the meter from three releases after first public contact to the first release anybody outside the family ever sees. So there is no prior public build to compare against, and if retention disappoints there is nothing in the data that separates the ladder from the cap.

**Why the first release is a complete game rather than a demo.** It costs a larger first release and buys something to actually test. A move-history scrubber, a result screen, statistics and replay are all cheap given an append-only move list.

**Why progression ships first.** It is the reason to open the app on the second day. Shipping the ladder afterwards means the first release anyone tested had nothing in it to come back for.

**Why the iOS release added no gameplay.** It was a port plus a shop. Adding features to the release that also introduces a second platform, a second signing pipeline, a second store review and the first money means that anything going wrong has four candidate causes.

**Why the meter arrived with the shop and not before.** There is nothing to sell before there is a shop, so metering earlier is a wall with no door.

**Why the human rating waits.** It ships with the validation that makes it trustworthy, because they are the same feature (§5).

**A version name that the documents and the artefact disagree about is a small confusion repeated everywhere** (D372, D387). Ours does: the plan called the first public release 1.0 throughout and the artefact went out as 0.1.3. Nothing is broken — neither store reads the version name for anything but display — and the window to change it cheaply closes at the first public release, after which the version history has a gap that gets explained in a support email forever.

---

## 13. Definition of done

1. The 76-line table is generated once, and win detection returns the specific completed line. Verified exhaustively.
2. A game can be played to a win and to a draw in all four modes, on both boards.
3. Client and validating function agree on every move of a shared corpus of full games.
4. All thirty-one opponents exist, are distinguishable in play, and are calibrated by a self-play harness that reports measured against published strength.
5. The top opponent's advertised strength matches what it delivers, and the interface never claims perfection it cannot deliver from both seats.
6. Both ratings update correctly and independently — provisional K, draws, forfeits, the floor. The computer rating is derived from stored games, never stored, and never leaves the device except as a leaderboard score the player opted into; the human rating is never written by a client.
7. **Points, unlocks, quests and streaks are correct**: a win pays its rung, an unlock costs twice that rung and is available only in roster order, the balance is earned minus prices actually paid, and every quest fires exactly once and pays at least one point. **No quest reward anywhere depends on the player's own rung.**
8. **An unlock survives a re-tune of either table.** The cost table, because the price paid is stored with it; the quest table, because the balance clamps at zero and no unlock is ever revoked.
9. **A missed day resets a streak and a played day does not**, across a month boundary, a year boundary and a time-zone change; and a time-zone artefact never breaks one.
10. **Only the unlock records and one timestamp are stored.** Balances, streaks, quest progress, mercy unlocks and statistics are all derived, and a test proves each one reconstructs from game history alone.
11. **The mercy rungs open by losing and can never be bought**, and the ladder never names one as the next purchase.
12. Async games expire correctly, with a warning first.
13. All four matchmaking paths create playable games, and the computer fallback never offers a locked opponent.
14. Chat works with block, report and profanity filtering, honours the more restrictive of the two preferences, is revocable, and fails closed on records that predate it.
15. All subscription products and the one-time unlock purchase and restore; the subscriptions sit in one group so an upgrade is a store-native plan change; a lapse lets existing games finish and rate, blocks new ones, exempts from forfeit, permits one rematch in a series, and **never revokes an unlock**.
16. **The meter counts started games, applies both limits, and names the one that bit**, and a missing settings record fails open.
17. Entitlement is revoked on refund or chargeback, and **from 2.0** cannot be written by any client.
18. The security rules pass an adversarial suite in which every attempt is denied.
19. Account deletion and data export work in-app, and deletion states it does not cancel the subscription.
20. An account is linked before its first rated game or purchase.
21. The one portrait layout renders on the smallest and largest supported phone, at the largest font scale, with every section present — swept across the whole app, not only the screens most recently built.
22. The board is playable and legible for a colourblind player and navigable by screen reader, every fact shown visually is announced exactly once, **no element carries meaning by colour alone**, and every interactive control has a node of its own.
23. The tutorial runs end to end, including the practice game, which is never stored, never paid and never metered.
24. Every string exists in English and Dutch, enforced by the build, with plural forms where a count is interpolated.
25. **The app's network posture is declared deliberately**, asserted by the build, and claimed at the strength it actually has — reviewed rather than enforced (§11.2).
26. **The unlock records survive a device change on both platforms.**
27. **Game services degrade to nothing.** A signed-out player, a declined offer and an unconfigured platform each leave an app that works identically and shows no dead controls (§15).
28. **The store's copy and the app's copy say the same thing**, and both are in the repository.

---

## 14. What is still open

Every item here is a business, account or measurement decision. **None is functional, and none blocks building the game.**

| Item | Why it is open |
|---|---|
| **The reference device** | The twenty-second ceiling (§6.8) is a device number and the measured worst case is a desktop one. The node-to-seconds conversion must be confirmed on real hardware. |
| **The progression numbers** | The shape is settled and the values are derived from a stated target rather than measured (§7.7). Watch the median time to each unlock and the rung at which players stop. |
| **The Master tier's spacing** | Ordered on paper and unresolved on the board. Three full-budget pairings is not a tier; settling it is an overnight full-budget run over the searching tiers (§6.7). |
| **Kestrel to Lynx is twice too steep** | Even, correctly ordered, and not fixable from inside the span — closing it means bringing the Master tier's node budgets down, after the run above (§6.7). |
| **The ladder is anchored to itself** | No published rating has ever been checked against a human (§5). Not actionable today; the first explanation to reach for if a rung feels wrong to real players. |
| **Retention was never measured** | The instrument that would have measured it went with the store requirement that forced it (§12). The qualitative half ran — testers interviewed in person — and that is very good at finding what confused somebody and very bad at finding who quietly stopped playing on day two. Two releases are built on the assumption that people come back. |
| **Personality in the middle of the roster** | Several neighbouring rungs are one configuration at different blunder rates (§6.3). Putting character back needs a *monotone* axis, and `lineBias` is the candidate. |
| **Tax treatment of the two prices** | Both stores act as merchant of record in most territories and remit VAT themselves, which is the answer and not one to assume without checking. |

**Closed, and worth knowing they were once open:** the two Casual-tier rating inversions (fixed by removing a stylistic ordering axis and by playing every pair within a tier rather than only adjacent ones); the size and obtainability of the strategy book; anchor calibration; auto-match cold start; the business model; the large-screen layout, cancelled rather than deferred; store price points; store accounts, signing and app-name availability; and whether the billing client works without network permission — **it does not**, and three uploads shipped before anybody found out (§11.2).

---

## 15. Platform game services

A leaderboard and a shelf of achievements, through the platforms' own services. **Everything here is best-effort and optional**, and the app must work identically for a player who never signs in.

**What it costs the specification is stated in §11.7 and §11.2, in the same release, not the one after.** A leaderboard entry is attributable by definition, so the identity claim narrowed from *no identifier is transmitted* to **no identifier is generated or stored**; and the network permission that used to make the offline guarantee categorical had to be granted, because the platform grants it per application rather than per screen. Both stores' privacy declarations become false the moment a leaderboard ships and must be updated in the same release.

**The offline criteria themselves survive untouched, and reading them literally is what shows it.** They say *a game against a computer opponent makes no network call* — not *the app never reaches the network*. Nothing here calls during a game: the rating is submitted after a game is scored and achievements are reported at the same moment. What could not survive is the *lever*, not the claim (D376).

### 15.1 What is published

- **One leaderboard**, carrying the computer rating. The board *is* that rating — one board, that figure.
- **Forty-six achievements**, derived by walking the quest catalogue plus one that is not a quest at all.

**Not every quest crosses over.** Each store achievement needs an id, a name and a description in every language, and an icon, entered by hand in two consoles — hundreds of text fields and dozens of pieces of art. From seventy-six quests, forty-six cross: the streak rungs, the volume rungs, one per opponent, and the drawn game.

**The two per-opponent quests merge into one**, and that is a correctness argument before it is an economy. *First win as the second player to move* is a strict subset of *first win*: a win from the second seat is a win, so the harder quest cannot be achieved without the easier one already being achieved. As two achievements they unlock in the same instant, on the same game, for every player who ever earns the harder one — **which reads as a bug and is indistinguishable from one.** In the app they are worth separating because they *pay* separately; on a list of unlocked badges there is one event and it should be one badge.

**Nothing is incremental.** Both stores support partial progress and this uses none of it: forty-six achievements that are unlocked or not. Incremental reporting means a number sent on every game rather than an event sent when something becomes true — more traffic and more attributable data, for progress the player can already see on the quest tile.

**One achievement has no quest behind it** (D386). A drawn game against a computer opponent pays no points and claims no rung, so it is not a quest — and inventing one for it would be the tidier-looking option and the wrong one. A quest is a user-facing object: it appears as a tile, it pays points, and it enters the fold the progression package owns. A quest for a draw would have to be marked invisible and zero-paying everywhere that handles quests — **a special case pushed into the pure package to avoid a special case in the one file that already knows what a store id is.** So the achievement's quest link is nullable, this is the only null, and it is reported directly. A test asserts there is exactly *one* such entry, so a second questless achievement added without a caller — which would silently never unlock — fails rather than ships.

**The code's word and the store's word need not agree, and neither can move.** Ours says `draw` internally and `tie` in the published id. A comment and a test hold the seam.

### 15.2 Three hard limits

**Ids are permanent from publication**, like product ids. An achievement cannot be deleted or renamed on either store once published.

**There is a cap on how many achievements an app may declare** — one hundred, on one of the two platforms. Forty-six used leaves fourteen spare against a roster of thirty-one. **A roster past about forty-five opponents breaks it**, which is a hard ceiling on the opponent ladder that did not exist before the leaderboard did.

**There is a cap on the total points an achievement set may award**, and ours sits exactly on it. **The cap is on the sum, so every award is coupled to every other**: the opponent column is priced as a flat step of one per rung, weakest first, which is both a cleaner rule than a hand-spread and frees points for the rarest achievement in the game. Two tests hold it — one asserts the opponent column is exactly the sequence rather than merely ascending, one asserts the total. **An opponent added to the roster shifts every rung above it and breaks the total**, which is the failure those two exist to make loud. Anything added later has to come from somewhere, and that is the point of writing the number down rather than recomputing it.

**The console is the authority for those numbers, not the repository.** What is committed mirrors what was set in the store. The tests check internal consistency; they cannot check that the console agrees.

### 15.3 Three ways in, and why each one

- **A button beside the computer rating → the leaderboard.** The control sits next to the number it ranks.
- **A button on the quests panel → the achievements.** The forty-six are derived by walking the quest catalogue: same rungs, same opponents. The shelf is that panel as the platform renders it.
- **Two rows in settings**, which is where people look for account-shaped things and the only route that survives a decline.

**The platform draws both views.** Each service has a native UI that already knows about boards, positions, friends and time scopes; a hand-drawn one would need all of that and still not be the thing players recognise.

**They are real buttons with words in them, not tinted glyphs** (D391). A glyph beside a number reads as decoration, and nothing about it says it can be pressed. **And the two use different icons**, deliberately: they are two *destinations*, and two controls that look identical while going to different places is a worse kind of consistency than none — the label was carrying the whole distinction and a shared glyph worked against it.

**Tapping either control signs in if needed, and then opens the view.** Making somebody find a separate sign-in switch before the button does anything is a worse answer than doing it for them — they have already said what they want by pressing it. **That holds even after a decline**, and the stored answer deliberately does not gate it: "declined permanently" exists to stop the *app* nagging, and a button the player presses is not the app nagging. Obeying the letter of that rule against its purpose leaves somebody who once dismissed a dialog permanently unable to reach a leaderboard.

**The unprompted offer waits for a finished game.** Not at launch: there is nothing to sync, nothing to explain, and the first-run tutorial prompt already owns that moment. Once a game is in the history there is a rating to put on a board, which is what the dialog is actually about. Declining is stored and permanent, or it arrives after every game until the player gives in.

### 15.4 Achievements do not backfill, and that decided the design

Reporting is a **diff** at the end of each game. A player who was signed out while playing has had nothing reported, and **signing in later does not retroactively unlock anything.** Without a fix, the first thing a newly signed-in player sees is an empty shelf behind a fortnight of play: it looks like a broken integration, and it is one.

So **sign-in reports everything already earned**, not just the diff. Unlocking an already-unlocked achievement is a no-op on both stores, so replaying the whole set is safe, and a session guard keeps it to once. **This is what makes "sign in whenever you like" a real option rather than a trap**, and it is why the sign-in can wait for the player to ask.

### 15.5 Silence is not an acceptable failure mode

This whole layer is best-effort and swallows errors, which is right — nothing here may interrupt a game or block a render. **Four separate things then conspired to make a completely broken integration invisible**, and each is a rule (D390, D391):

1. **A best-effort layer that swallows exceptions is worth nothing if the thing it swallows never throws.** The plugin reports failure by *returning a string*, not by throwing. The adapter discarded it, so the guard saw a clean completion and reported success while the platform was refusing. **Every such call must turn a returned error back into an exception**, so there is something to catch, log and tell the player.
2. **A platform that refuses is not a player who declined.** The open call returned the sign-in answer and the caller persisted it, so a build whose service was simply not configured recorded a permanent decline — and the unprompted offer then never came back. The app both did nothing *and* stopped asking. The call now returns a plain "did a view open", and **only the dialog's own yes or no is ever stored.**
3. **A control that gives no sign it was pressed is a defect.** Best-effort means never interrupting a *game*; it does not mean a silent button. A refused open raises a message. It cannot name the cause — the app does not know it — but it distinguishes *refused* from *did not notice you*, which is the question the player is actually asking.
4. **Gate a control on the service being usable, not on the service existing.** The buttons were hidden when the service object was null, and on one platform it is not null — it is merely unable to do anything, so both controls were drawn over a platform that would refuse them. **Ask the service whether it is configured.** A control that does nothing is worse than an absent one, which is the same rule §8.14 applies to a theme picker with one theme.

**And the cause was outside the repository entirely.** The project had no game-services capability enabled in its platform project, so the framework showed a sign-in banner and then refused to present anything. That fix belongs in the platform IDE rather than in the source tree, because doing it through the UI both creates the entitlement *and* registers the capability against the app record — hand-writing the file does the first and not the second, and the build then fails to sign.

**What a test can say about this feature is narrow, and saying so is part of the design.** A test can assert that the button exists, is reachable, is announced, and calls the platform. Whether the platform then draws anything is the platform's business and a device's.

---

## 16. Sources

The game is public, old, and thoroughly analysed. Nothing about its mathematics needs deriving.

- **Wikipedia, "3D tic-tac-toe"** — https://en.wikipedia.org/wiki/3D_tic-tac-toe — line counts, cell degrees, automorphism count, solution history.
- **R. Silver (1967)** — established the group of 192 automorphisms.
- **Eugene Mahalko (1976)** — weak solution: a first-player win exists.
- **Oren Patashnik (1980)** — "Qubic: 4 × 4 × 4 Tic-Tac-Toe", *Mathematics Magazine* 53(4), 202–216. The complete first-player-win strategy, computer-assisted, about 1,500 hours, roughly 2,929 stored strategic positions. **Method and proof, not the dataset**, and copyrighted — read it to understand the forcing-move machinery, do not ship content from it.
- **Victor Allis** — independent solution by proof-number search.
- **`qubic.dictionary`** — the strategy data itself, carrying its own permissive grant. See §6.6 for the obligations that come with it.

**The licensing judgement in §6.6 is the implementer's to confirm.** What this document records is what the file says and what the build does about it. It is not legal advice.
