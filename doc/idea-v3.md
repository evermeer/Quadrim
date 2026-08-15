# Quadrim — Specification, third edition

What Quadrim is and what it must do, written so that someone rebuilding it from nothing has no functional question left to ask.

This is [idea-v2.md](idea-v2.md) with a progression system folded in and the offline game metered. v2 recorded what the *build* settled; v3 records what the *product* settled on top of it. The decisions that produced v2 are in [idea-v1-decisions.md](tickets/done/idea-v1-decisions.md) (D01–D217); the ones that produced this edition are in [idea-v3-decisions.md](idea-v3-decisions.md) (D218–D270). D258 onward were taken by reading this document back against the twenty-two tickets already built, and the reasoning is in [idea-v3-brainstorming.md](idea-v3-brainstorming.md).

Status: 0.1 built and playable up to the progression system, which is specified here and not yet built. 0.2 onward specified, not built.
Date: 2026-08-14

---

## 0. How to read this

Four things are true of this document.

**Nothing here is a question.** §14 lists the genuinely open items that remain — every one of them a business or account decision, none of them functional, none of them blocking a line of code.

**Where a number appears, it was measured — except in §7.** Search budgets, rating gaps, board dimensions and think times are results from running the thing. The point values in §7 are the one deliberate exception: they are derived from a stated target rather than observed, and §7.7 says exactly what that target was and how to tell when it is wrong.

**The mistakes are included.** v1 described a 2×2 grid of board layers, a solver sub-project, and a Casual tier ordered by blunder rate. All three were wrong and finding out cost real time. They appear below as corrections rather than being quietly replaced, so nobody spends that time again.

**Two promises from v2 are withdrawn here, on purpose.** v2 said everything release 0.1 shipped would be free forever, and it planned a large-screen layout. This edition meters offline play and ships portrait phone only. Both reversals are recorded rather than edited out, because a rebuilder should see that the free-forever sentence was written before there was a business model and could not survive one.

---

## 1. What Quadrim is

Quadrim is a two-player game played inside a 4×4×4 cube of 64 cells. Players alternate placing a piece of their own colour on any empty cell. The first player to occupy all four cells of any straight line wins. Lines run along the axes, diagonally within a flat plane, and diagonally through the body of the cube. If all 64 cells fill with no line completed, the game is drawn.

The game is known publicly as Qubic, or 3D tic-tac-toe. It is a solved game: with perfect play the first player wins. This fact shapes several decisions below and is not treated as a defect.

A player can play another human — asynchronously over days, or in real time — or any of twenty computer opponents, each with a name, an avatar, a play style, and a fixed rating. Five of those opponents are available from the first launch; the other fifteen are earned (§7).

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

**Generate this table at build time; do not hand-write it and do not compute it at runtime.** A build-time generator emits it as a constant, and its output is committed and checked for staleness by the build gate. It is the single shared source of truth for win detection, threat detection, the engine's evaluation, the tutorial's illustrations, and the server-side validator. Nothing may enumerate lines independently.

The generator is worth a real test suite of its own, because everything else trusts it. Ours proves: exactly 76 lines; the generated set equals an independent direction-walk enumeration; cell degrees match the published figures; and — exhaustively over all C(64,4) = 635,376 four-cell sets — that no non-line quad is collinear. That last one is cheap and catches the failure mode where a plausible generator emits a plausible wrong table.

### 2.2 Cell degree

| Cell class | Count | Winning lines through it |
|---|---|---|
| Corner cells | 8 | **7** |
| Inner cells (the central 2×2×2) | 8 | **7** |
| Face cells | 24 | 4 |
| Edge cells | 24 | 4 |

Sixteen cells sit on seven lines each; the other forty-eight sit on four. Corner and inner cells are **equivalent under the game's symmetries** — one class, not two.

**This is the single most useful fact in the whole document for building the opponents**, and it is easy to under-weight. See §6.3.

### 2.3 The symmetry group

The board has **192 automorphisms**. Construct and prove them rather than tabulating them: generate the group from its generators, verify closure, verify that every element maps the line set onto itself, and verify the order is exactly 192. A hand-copied table of 192 permutations is a large surface for a silent transcription error that would corrupt every canonical lookup downstream.

`canonicalise()` must return **both** the canonical key **and** the automorphism that produced it. Anything stored in canonical orientation — the strategy book especially — yields moves in that orientation, and they have to be mapped back onto the real board. A canonicaliser that returns only the key is a half-built one, and the missing half is discovered late.

**Where canonicalisation pays, and where it does not.** In a per-move transposition table it is a net loss: the canonicalisation cost exceeds the collapse benefit everywhere except within a few plies of an empty board. In a *stored book* it is decisive — a book keyed by canonical form holds up to 192 times as many positions in the same space. Build the machinery for the book, and use it in search only for the first few plies, if at all.

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

**Everything derives from the move list.** The board, whose turn it is, the outcome, the statistics and the rating are all folds over the stored moves. Never store a second copy of something the moves already say: the two drift the first time a game is deleted.

§7.6 records the one place this edition breaks that rule, and why it had to.

### 3.1 First move

The starting player is chosen at random for the first game between a given pair of opponents. In a rematch the other player starts. Colour follows starting order. The game record stores who started **and why** — random, or alternating from a previous game — because the screen says so and it cannot be re-derived later.

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
| Vs computer | one of 20 | **never** | Computer rating, points | **yes** | to lift the cap |
| Pass-and-play | human, same device | no | Nothing | no | no |

Async and real-time share one game-state model and one move pipeline. Real-time adds only the per-move clock and opponent presence.

Pass-and-play affects no rating because the second party is unauthenticated and the result unverifiable. It is also excluded from the win/loss/draw record for the same reason — a record that counts games you played against yourself is not a record of anything. It earns no points and is not metered, for that same reason: it is not a result, so it can neither pay nor cost.

A player may hold at most **20 simultaneous active games against human opponents**. Computer games are uncapped in *concurrency*; what is capped is how many may be **started** per day (§4.2).

### 4.1 What is sold

Three tiers and one permanent unlock, all through the App Store and Google Play. Both stores are merchant of record; no direct payment path is ever added.

| | Free | Tier 2 — $1.99/yr | Tier 3 — $4.99/yr |
|---|---|---|---|
| First month after first launch | unlimited computer games | — | — |
| After that | 3 computer games/day, 9/week | unlimited | unlimited |
| All twenty opponents, tutorial, history, replay, statistics, computer rating, pass-and-play | yes | yes | yes |
| Accept an invite link or a direct challenge | yes | yes | yes |
| Concurrent human games | up to 3 | up to 3 | up to 20 |
| Human rating, earned normally | yes | yes | yes |
| Create invite links, challenge someone directly | no | no | yes |
| Auto-match | no | no | yes |
| Open challenge board | no | no | yes |
| Chat | no | no | yes |

**Tier 3 contains tier 2.** A tier 3 subscriber has no daily cap.

**Unlock all opponents — $4.99, one time.** Opens all twenty opponents immediately and changes nothing else. A buyer still plays three games a day unless they also subscribe. This is deliberate: it is the least powerful thing in the shop, so a one-time purchase at the same headline price as a year of tier 3 cannot undercut it. What it sells is impatience, not capability.

**Tiers 2 and 3 must be two plans of one product**, in a single iOS subscription group and a single Play subscription with two base plans. That is the only mechanism by which "subscribing to tier 3 cancels tier 2" actually happens — the store performs a plan change and prorates the remainder. An app that tries to sell tier 3 as a separate product while cancelling tier 2 itself produces double-billed users and a refund queue, and neither store offers an API that would let it do so correctly.

**Accepting a game is still free at every tier.** Invite links are the only way a new person ever reaches this app. Charging the *recipient* makes a friend's invitation arrive as a sales pitch and throttles the one growth loop the product has, at its highest-intent moment. Auto-match and the open challenge board — the surfaces a throwaway account would farm — stay paid, so the anti-abuse benefit is kept.

**When a subscription lapses:**

- Games in progress play to the end and **rate normally for both players**. Frozen means no new rated games can be *started*, not that results stop counting — an asymmetric update would inflate the ladder for whoever happened to be playing a lapsed opponent.
- A lapsed player may accept one rematch of a series in progress, so a billing date cannot deny them the first move §3.1 owes them.
- A lapsed player is **exempt from the inactivity forfeit**. A billing event must never hand someone a forfeit win.
- A lapsed tier 2 or 3 subscriber returns to the free cap. Their **free month does not restart** — it is consumed once, at first launch, and never again.
- Opponents unlocked with points, or with the one-time purchase, **stay unlocked forever**. Nothing a player earned or bought outright is ever taken back by a billing event.

Entitlement is checked when a game is **created and when one is joined** — never on a move, so the lapse behaviour above works. It is a server-written field no client can touch, set only after receipt validation, revoked on refund, chargeback or voided purchase.

### 4.2 The meter

**v2 promised that everything release 0.1 shipped would be free forever. That promise is withdrawn.** It was written before there was a business model, it is incompatible with the one there now is, and nothing has shipped to a member of the public, so no one is having anything taken from them. A rebuilder should not carry it forward.

What survives of it is narrower and true: **no feature is held back, and there are no ads.** Every opponent, the tutorial, every screen and the whole of local history are in the free tier. What is metered is *how often you may start a new game against the computer* — not what you may reach.

- **The first month is unmetered.** The clock starts at first launch and runs for one calendar month.
- **Thereafter: 3 games per day and 9 per week.** Both apply; the weekly limit binds first from the fourth playing day of any week.
- A game counts against the meter **when it is started**, not when it finishes. An abandoned game is a spent game — otherwise the meter is defeated by starting and quitting.
- **Only games against the computer count.** Pass-and-play, the tutorial's practice game, replay of a finished game, and online play are all outside the meter.

**The paywall message must name the limit that actually bit.** "You have used this week's nine games" and "come back tomorrow" are different sentences and only one of them is true on a Thursday. Saying the wrong one teaches the player that the app does not know its own rules.

**The meter arrives at 0.4**, with the store products (§12). Before then there is nothing to sell and therefore nothing to meter, and the closed test runs unmetered — which is correct, because a tester on a fourteen-day clock who is rate-limited to three games a day cannot give useful feedback about twenty opponents.

**Where the month is remembered.** Against the account, which exists from 0.3a. A device-local month is reset by a reinstall and defeated by changing the system clock, and there is no reason to build the weaker version when the stronger one is already available by the release that needs it. Accounts that predate 0.4 start their month **at the 0.4 update**, not retroactively at whenever they first launched — otherwise every existing tester is metered the moment they update, having never had the month at all.

---

## 5. Rating

A player has **two independent ratings**. Neither influences the other.

| | Computer rating | Human rating |
|---|---|---|
| Earned against | The 20 computer opponents | Real opponents only |
| Seeded at | **800** | **1000** |
| Computed | On the device | On the server |
| Stored | Derived, never stored | In the cloud, with the account |
| Visible to | Only that device's owner | The player and their opponents |
| Arrives in | 0.1 | 0.4 |

Both use the same maths:

- K-factor **32** for the first 20 rated games on that ladder, **16** thereafter
- Score: win 1, draw 0.5, loss 0
- Expected score `E = 1 / (1 + 10^((R_opponent − R_self) / 400))`
- Update `R' = round(R + K × (S − E))`; floor **100**

**The two seeds differ on purpose.** A new player seeded at 1200 against a roster that starts at 600 spends their first week watching a number fall, which is the opposite of the story the ladder is telling. Seeded at 800 they sit just below Clover, above the two weakest opponents, with somewhere obvious to climb. The human ladder seeds at 1000 because there is no fixed roster to sit inside — the population is the roster, and a round number is the least misleading starting point in a pool whose distribution is unknown.

**The computer rating is derived, never stored** — a fold over the games already on disk. Two details make the fold reproducible, and both live in the data rather than in the code:

- **Each completed game stores the opponent's anchor rating as it was when the game was played.** Without this, recalibrating any opponent silently rewrites every player's entire history and the "+12" they were shown becomes unreproducible.
- **Ordering is by an explicit completion-time field, with the game id as tie-break.** Without it, a long-running game reorders the fold when it finally completes.

That tie-break is load-bearing in a way that is easy to miss. If game ids are random and two games complete in the same millisecond, their order is a coin flip — which is fine for the product and fatal for a test fixture that creates games back to back. Inject a clock in tests.

**Changing the seed rewrites every existing rating.** That is a direct consequence of the rating being a fold with nothing stored, and it is accepted: the players affected are closed testers, and the new number is the one the product intends. It is worth stating explicitly because the same property makes any *future* change to the seed or the K-factor a silent rewrite of everyone's history, and a shipped product cannot do that casually.

Computer opponents have **fixed** ratings that never change. They are anchors: the player's rating moves, the opponent's does not. **When measurement disagrees with a published rating, the opponent's configuration changes and the rating does not.** Changing an anchor would silently rewrite the meaning of every result already recorded against it.

**Why the split.** The two ratings measure different things under different trust models. A rating earned against a deterministic opponent on your own hardware cannot be verified by anyone and does not need to be — editing it cheats only yourself. A rating earned against another person must be trustworthy. Conflating them forces the worse property of each onto the other.

**The human rating ships at 0.4, together with server-side move validation**, because they are the same feature. Without validation, a modified client can author a legal, replayable game naming any opponent and move that opponent's rating without them ever opening the app. Replay proves legality, never authorship. Release 0.3b therefore ships online play with a win/loss/draw record and no rating — and nobody has a rating to lose, because nobody has one yet.

Because a rating is worth losing, it requires a **linked account** (§9).

### 5.1 How lopsided a pairing is

The opponent list marks pairings that are not a fair test. Express this as an **expected score, not a rating gap**: below 0.25 expected the opponent is far stronger, above 0.75 far weaker. A gap in points means different things at different places on the ladder; an expected score means the same thing everywhere.

**Rating and unlocks are independent ladders that happen to advance together** (§7.3). Neither gates the other: a player whose rating has raced ahead still has to earn the next opponent, and a player who has unlocked someone far above them can play and lose to them as often as they like.

---

## 6. Computer players

### 6.1 One engine, twenty configurations

All twenty are configurations of a single move-choosing function. **Bots are data, not classes** — adding an opponent is a catalogue entry, and calibration is a matter of running self-play across configurations rather than across code paths.

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

**Locking is not an engine concern.** Whether an opponent is available to a given player is a fact about that player, held outside the catalogue. The engine knows twenty configurations and nothing about who has paid for what; the catalogue has no `locked` field. Otherwise the strength harness — which plays all twenty against each other — needs an entitlement it has no business having.

### 6.2 Strategic rules, evaluated in order

1. Is there a cell that gives four in a row immediately? Play it.
2. Is there an empty cell where the opponent would get four in a row next move? Block it.
3. Is there an empty cell creating two separate lines of three, each with its fourth cell empty? Play it — an unstoppable double threat.
4. Is there an empty cell that would let the opponent create such a double threat? Deny it.

### 6.3 The positional ladder

Applied when no strategic rule decides, and as the tie-break within a rule.

1. Prefer a cell in the central 2×2×2 cube.
2. Otherwise prefer a corner.
3. Among candidates, prefer the cell on the most lines already holding two or more of its own pieces and none of the opponent's.
4. Otherwise choose at random.

**Implement this as weights, not as an if-else chain.** The order is then a property of the numbers, which a test can assert over the whole catalogue: each class gap must exceed the maximum building term, or a later opponent copying another and raising `lineBias` silently inverts the ladder.

**Three things about these weights that cost us real time:**

**Only the *order* of the weights reaches the board.** With `lineBias` at zero there is nothing to compare magnitudes against, so an opponent ranking corners above centres above the rest plays *identically* at (0.55, 0.35) and at (0.8, 0.6). We changed a bot's biases to weaken it and got results identical byte for byte across 300 games. If you want a positional change to have an effect, change the ranking or add a building term.

**Centre and corner are the same class** (§2.2), so ranking centre above corner is a flavour choice, not a strength one. What *is* a strength choice is **how many of the sixteen seven-line cells an opponent prefers at all**. An opponent preferring only the eight centres and one preferring only the eight corners are about equally strong; one preferring all sixteen is stronger than both.

**Corner-hunger is a strength, not a quirk.** It is easy to write "drawn to corners" as a charming weakness. It is not a weakness — corners are seven-line cells.

### 6.4 The roster

Twenty opponents across five tiers. **Ratings are fixed anchors.** The `#` column is the roster index, which §7 uses to price both wins and unlocks; it is an ordinal, not a rating, and the two must not be conflated.

**Novice** — all four free from first launch.

| # | Name | Rating | Configuration |
|---|---|---|---|
| 0 | Pebble | 600 | Random legal moves. Never notices a threat. |
| 1 | Twig | 700 | Random, but takes an immediate win. No blunder rate — its weakness is knowing one rule. |
| 2 | Mote | 800 | Wins and blocks, 40% blunder rate. |
| 3 | Clover | 900 | Wins and blocks, 20% blunder rate, drawn to corners. |

**Casual** — all four rules; what separates them is how many good squares they prefer. Bramble is free; the rest are earned.

| # | Name | Rating | Prefers | Blunder | Aggression |
|---|---|---|---|---|---|
| 4 | Bramble | 1000 | none of the sixteen | 0.15 | 0.5 |
| 5 | Willow | 1100 | the 8 centres | 0.13 | 0.5 |
| 6 | Vireo | 1200 | all 16, corners first | 0.11 | 0.67 |
| 7 | Finch | 1250 | all 16, centres first | 0.10 | 0.30 |
| 8 | Kestrel | 1300 | all 16, centres first | 0.08 | 0.5 |

**Club** — Marlin's rules and full positional ladder, plus a look ahead.

| # | Name | Rating | Configuration |
|---|---|---|---|
| 9 | Marlin | 1400 | Full positional ladder including the building term, 6% blunder rate, no search |
| 10 | Ember | 1500 | 2-ply, aggressive weighting, 5% |
| 11 | Basalt | 1550 | 2-ply, defensive weighting, 4% |
| 12 | Onyx | 1650 | 4-ply, 3% |
| 13 | Sable | 1700 | 4-ply plus threat-space search, 2% |

**Expert** — budgets in nodes rather than plies, because how deep a budget reaches depends on the position.

| # | Name | Rating | Configuration |
|---|---|---|---|
| 14 | Corvus | 1800 | 500k nodes, transposition table, 1.5% |
| 15 | Lyra | 1900 | 900k nodes, deeper threat search, first with a **defensive** forcing search, 1% |
| 16 | Quartz | 2000 | 1.8M nodes, deeper defence, 0.5% |
| 17 | Titan | 2100 | 2.5M nodes, exact solving below 10 empty cells, unstarved defence, no deliberate blunders |

**Master** — the first opponents that stop estimating and start knowing.

| # | Name | Rating | Configuration |
|---|---|---|---|
| 18 | Oracle | 2300 | Plays the book from move one. Unbeatable when it opens; Expert-tier machinery from the second seat |
| 19 | Quadrim Prime | 2400 | The same book, and the largest configuration in the catalogue from the second seat |

**The free five are exactly those rated 1000 and below.** That is a rule about the roster, not a count: if a future roster revision changes the ratings, the free set changes with it, and nothing anywhere hard-codes "five".

Every opponent has an avatar and a one-line personality blurb, translated. **Bot names are not translated.** Tier names carry a plain-language description, because "Club" means nothing to someone who has not played rated games.

**Tier is stored on the opponent, not derived from its rating**, even though the five tiers occupy contiguous bands today. A tier is what an opponent *is*; a rating is how strong it measured. Deriving one from the other means a recalibration silently reclassifies an opponent.

**Generate avatars from the opponent's id** rather than shipping twenty image files. A deterministic pattern from the id gives twenty distinguishable faces, costs no download, and cannot go stale when a name changes.

### 6.5 What actually makes an opponent strong

Measured, in descending order of effect. This is the part of the document a rebuilder should read twice.

**A defensive forcing search is worth about 300 Elo — the largest single lever in the project.** Before playing a candidate move, follow the *opponent's* forcing sequences and discard the move if it hands them a forced win. This is a separate depth from the opponent's own threat search, and separating the two is what gives the ladder a dimension that raising the node budget did not. Seeing your own wins and seeing your opponent's are different skills that improve at different times.

**Being defensive in temperament is worth about −78 Elo.** With two configurations identical in every respect except `aggression`, the aggressive one beats the defensive one by 28 points and the defensive one loses by 50. In Qubic, building your own double threat beats denying the opponent's. Design the roster knowing this: a "cautious" personality is a *weaker* personality, and if the ladder needs cautious opponents to be strong, the ladder and the personalities will fight. Ours do — see §14.

**Depth is not why the strong opponents are strong.** Eight plies of full-width alpha-beta is not affordable and is not the reason. Threat-space search — following only replies the opponent has no choice about — goes far deeper for far less work.

**Search budgets are counted in nodes, never milliseconds.** A millisecond budget makes every searching opponent a different opponent on a fast phone and a slow one, in debug and release, in CI and on a device. Nodes keep them the same everywhere. Measure the wall-clock equivalent separately, against a named reference device.

**Every forcing search needs a node budget of its own.** An unbudgeted one took five minutes on a single move. The budget is also shared out among candidates being checked, and an unstarved defence measured 36–24 against a starved one.

**Teaching the evaluation about forks did not make it stronger.** It is an obvious idea, it costs a day, and it measured as noise. The rules already handle double threats.

### 6.6 Perfect play

**Qubic is a first-player win, and Patashnik proved it in 1980.** The proof is a dictionary of move choices for the difficult positions; everything else is reachable by forcing sequences the engine already computes.

**The dataset exists and is obtainable.** A copy of `qubic.dictionary` is published; it is 54,745 bytes and its own header carries a permissive grant — usable as long as its moves are unchanged and its source is credited. **The solver sub-project v1 contemplated is not needed and should not be built.** That is the single largest scope reduction available in this project: v1 budgeted an unbounded research task for something that had already been done in 1977.

Two obligations, both worth mechanising rather than promising:

- **Moves unchanged.** Vendor the file byte for byte, mark it binary so no line-ending conversion touches it, and verify its SHA-256 on every run of the build gate.
- **Source credited.** The credit must be rendered *in the shipped app*, not merely present in the repository. Have the gate grep for the string in the app's source. A licence obligation that lives only in a README is one refactor away from being violated.

If the dictionary is taken from a repository under a restrictive licence, **take only the data file**. Implement the move-generation procedure from the dictionary's own header and the published article, read no line of the surrounding code, and record the separation in a NOTICE file with instructions to preserve it on any refresh.

**Store the book in canonical form** and map the move back through the automorphism that produced the key (§2.3).

**Perfect play is first-player play.** There is no such thing as perfect second-player play in a first-player win. An opponent playing the book **cannot be beaten when it opens**, and from the second seat has no book at all and falls back on search. This has three consequences:

- **Two book opponents can only differ in the seat the book does not cover.** Oracle and Prime play an identical opening; everything separating them is second-seat search. Attempts to differentiate them otherwise failed instructively — a blunder rate would have made the higher-rated opponent blunder more, and a shallower forcing search measured as *no difference at all*, byte-identical over 200 games, because the wins that follow the book are short enough that eleven plies find them as reliably as twenty.
- **Never say "perfect" in the interface.** Say "unbeatable when it moves first". The first claim is false from the second seat and a player will find that out.
- **The two most expensive unlocks buy opponents that cannot be beaten half the time.** §7.3 prices Oracle and Quadrim Prime as the top of the ladder, and a player who spends a million points on an opponent that opens with the book and wins will feel cheated unless the app said so first. The unlock confirmation must repeat the "unbeatable when it moves first" line, not just the store listing.

A consequence for measurement: **a pairing of two book opponents measures the seat, not the strength.** Any self-play harness must detect and flag this, or it will confidently report 50% and mean nothing by it.

### 6.7 Calibration

The twenty must play at the strengths they advertise. This needs a headless self-play harness, and it is worth building properly because every claim about relative strength should come from a run of it rather than an argument about the code.

**Two instruments:**

- **A duel** — two configurations, N games, alternating seats, reporting wins/losses/draws and the implied rating difference.
- **A ladder calibration** — 19 adjacent pairs plus about 10 cross-tier pairs, not a full round-robin. Twenty opponents is 190 pairs and the expensive configurations are exactly the ones a round-robin makes meet everyone. Adjacent pairs establish the ordering and the gaps; a sparse cross-tier sample braces the chain against accumulated drift.

Run calibration at a **reduced node budget** — a tenth — so it finishes in minutes rather than hours. Scale only the budgets: depths, rules, biases and blunder rate are what make an opponent that opponent.

**Four traps in a harness like this, all of which we fell into:**

1. **A budget scaled to zero changes what an opponent *is*.** If move selection branches on `nodeBudget > 0`, a budget rounded away does not make an opponent think briefly — it stops it searching at all, while the report still carries its name. Clamp a non-zero budget to a minimum of one.
2. **A reduced budget is unfair across the ply/nodes boundary.** It trims a ply-limited opponent not at all and takes nine tenths off a node-limited one. Such a pair is not a fair fight and its result is a property of the tool. Detect the mismatch and refuse to call it a defect — one of our three reported "inversions" was entirely this.
3. **A swept pair has no finite implied difference.** Clamp the score half a game off the end and mark the result as a bound rather than a value, or the average silently understates whichever side did the sweeping.
4. **Report measured-against-published; never fit a fresh scale.** A least-squares fit over the whole graph answers "what scale best explains these results", which quietly moves all twenty anchors at once and produces a self-consistent ladder that no longer means what the player was told. Anchor each estimate on the *other* side's published rating.

An inversion is a configuration defect, not noise. Chase every one to a cause.

### 6.8 Responsiveness

**A move must complete within twenty seconds on a device.** That is a ceiling, not a target, and it belongs to the strongest opponents alone — a twenty-second think from a 1500-rated opponent is a defect. Spend the budget as a ladder: Novice, Casual and Club in single-digit milliseconds; Expert in the low seconds; only Master near the ceiling.

Beware of inferring this number. Ours was first guessed at 250 ms because that "feels responsive", and every tuning decision made under it was distorted — including a conclusion that the second-strongest opponent was over budget, which on the real number it was not, by a factor of about thirty. **Ask the product owner for the ceiling before tuning anything against it.**

**Run the search off the UI thread**, injected as a function so tests can run it inline. And while the computer is deciding, the player must see a **clear, moving indication that it is thinking**. At twenty seconds a static line of text is indistinguishable from a frozen app.

**The whole app ships in no more than 50 MB.** Generous for a strategic book of a few thousand positions; tight for anything resembling a tablebase.

---

## 7. Progression

The rating (§5) says how strong a player is. Progression says what they have *earned*, and it is what gives a single-player game a reason to be opened tomorrow. It is a separate ladder that happens to advance at a similar pace, and the two never gate each other.

Progression ships in **0.1**, before the closed test. A closed test of Quadrim without it evaluates a product nobody intends to ship.

### 7.1 Two currencies, one of them not a currency

- **Rating** is a measurement. It goes up and down, cannot be spent, and reflects only how well you played.
- **Points** are earned and spent. They only come from winning against the computer, and there is exactly one thing to spend them on.

Keeping these separate is what lets the rating stay honest. A rating you could spend would be a score, and a score people spend is a score people farm.

### 7.2 What a win is worth

**A win against roster index *i* pays 2ⁱ points.** Draws and losses pay nothing.

| Opponent | # | A win pays |
|---|---|---|
| Pebble | 0 | 1 |
| Twig | 1 | 2 |
| Mote | 2 | 4 |
| Clover | 3 | 8 |
| Bramble | 4 | 16 |
| Willow | 5 | 32 |
| Vireo | 6 | 64 |
| Finch | 7 | 128 |
| Kestrel | 8 | 256 |
| Marlin | 9 | 512 |
| Ember | 10 | 1,024 |
| Basalt | 11 | 2,048 |
| Onyx | 12 | 4,096 |
| Sable | 13 | 8,192 |
| Corvus | 14 | 16,384 |
| Lyra | 15 | 32,768 |
| Quartz | 16 | 65,536 |
| Titan | 17 | 131,072 |
| Oracle | 18 | 262,144 |
| Quadrim Prime | 19 | 524,288 |

Wins only, because it keeps the arithmetic in §7.3 exact rather than approximate: "four wins buys the next opponent" is a promise the interface can make, and it stops being one the moment draws pay a fraction.

### 7.3 The unlock ladder

The five opponents rated 1000 and below are available from first launch. The other fifteen are bought with points, **strictly in roster order** — only the next locked opponent can ever be purchased.

**Unlocking opponent *i* costs 2ⁱ⁺¹ points, which is exactly four wins against opponent *i−1*.**

| Unlock | Costs | = four wins against |
|---|---|---|
| Willow | 64 | Bramble |
| Vireo | 128 | Willow |
| Finch | 256 | Vireo |
| Kestrel | 512 | Finch |
| Marlin | 1,024 | Kestrel |
| Ember | 2,048 | Marlin |
| Basalt | 4,096 | Ember |
| Onyx | 8,192 | Basalt |
| Sable | 16,384 | Onyx |
| Corvus | 32,768 | Sable |
| Lyra | 65,536 | Corvus |
| Quartz | 131,072 | Lyra |
| Titan | 262,144 | Quartz |
| Oracle | 524,288 | Titan |
| Quadrim Prime | 1,048,576 | Oracle |

**The whole roster costs 2,097,088 points, which is exactly 60 wins.** That is the number to reason about; the point totals are display.

Four properties fall out of this shape rather than being ruled in, and they are the reason to prefer it over a hand-tuned table:

**Grinding downward is self-defeating, so no anti-farming rule is needed.** Every rung down halves the payout. Unlocking Quadrim Prime by beating Pebble takes 1,048,576 games. The obvious exploit — spend an afternoon farming the weakest opponent — prices itself out without a single line of code to stop it, and without punishing a player who genuinely enjoys easy games.

**The two ladders advance together without being coupled.** From a seed of 800, four wins against Bramble is roughly +90 rating, and the roster's rungs are about 100 points apart. A player who is earning the next unlock is also, independently, becoming strong enough to want it.

**A rung is a session.** Four wins takes eight to twelve games while an opponent is still unfamiliar, which is one sitting. Fifteen rungs at the free tier's three games a day is around fifty days — after a first month in which the early rungs go past unmetered and almost unnoticed.

**Every rung feels identical.** Costs double and payouts double, so the *effort* per unlock is flat all the way up. The numbers on screen become large — the last unlock is seven digits — and that is the price of the property. Format them with the locale's thousands separator and let the progress bar carry the meaning; nobody does this arithmetic, they watch a bar fill.

**Unlocks are permanent.** Nothing revokes one — not a lapsed subscription, not a refund of an unrelated product, not a roster revision.

### 7.4 Quests

**One achievement system, not three.** Everything that pays points is a quest, including the two per-opponent milestones that were previously a separate feature:

| Family | Instances | Notes |
|---|---|---|
| First win against an opponent | 20 | one per opponent |
| First win **as the second player to move** | 20 | a genuinely harder rung — the first player has a real advantage — and free to detect, since which seat started is already on every game |
| Games played in one day | 5 | 5, 10, 20, 50, 100 |
| Consecutive days played | 8 | 5, 10, 30, 90, 180, 360, 720, 1440 |

**Every quest is priced by the opponents it was earned against, never by how high the player has climbed.** That is one rule for all four families, and it is the rule §7.2 already applies to a plain win: points measure the strength of what you played, not who you are.

- **A per-opponent quest pays one win against that opponent** — 2ⁱ for opponent *i*, fixed by the roster and worth the same whenever it is claimed.
- **A volume or streak quest pays its multiple of a win against the average of the games that earned it**, where the average is taken over the **roster index** and rounded to the nearest opponent. Twenty games averaging index 8 pay as one win against Kestrel; twenty games against Pebble pay as one win against Pebble.

**Average the index, not the payout.** Because payouts double, an arithmetic mean of them is dominated by the single strongest game in the set: nineteen Pebble games and one Titan game average 6,555 points, which prices twenty games at roughly a Corvus win on the strength of one of them. Averaging the index and then exponentiating — the geometric mean — gives 2 points for the same set, which is what nineteen trivial games and one real one are actually worth. Round the mean index to the nearest opponent so the result is nameable: the interface can say *your twenty games averaged Kestrel*, which is a sentence, where a fractional exponent is not.

**Two ways of pricing quests by the player instead of the opposition were tried and both fail, in opposite directions.**

*Pricing at the player's current rung lets the cheap quests be banked.* The ladder never requires playing the weakest opponents — the cheapest route to Willow's 64 points is four Bramble wins, not sixty-four Pebble wins, which is exactly the self-pricing property §7.3 relies on. So a player has no reason to touch Pebble, Twig, Mote or Clover at all, and their eight per-opponent quests would sit unclaimed and appreciating. Cashed in at rung 15 those eight games pay 262,144 points — the entire Titan unlock. At rung 19 they pay 4,194,304 against a roster costing 2,097,088 in total: twice the whole ladder, for eight games against opponents that move at random. The optimal play would be to avoid a fifth of the roster on purpose.

*And it makes the volume family a pure grind.* A hundred games in a day pays four wins-worth; priced at the player's rung, a hundred instant Pebble games at rung 17 pay 524,288 points — four Titan wins for an afternoon of tapping. Priced by the opposition it pays four. This is the failure the rest of §7 was carefully built to avoid: §7.3's whole argument is that every rung down halves the payout, so grinding downward prices itself out. A quest that pays by the player's height reintroduced the exploit that §7.3 spent its entire shape defending against, in the one place nobody was looking.

| Games in one day | 5 | 10 | 20 | 50 | 100 |
|---|---|---|---|---|---|
| Pays, in wins-worth | ¼ | ½ | 1 | 2 | 4 |

| Consecutive days | 5 | 10 | 30 | 90 | 180 | 360 | 720 | 1440 |
|---|---|---|---|---|---|---|---|---|
| Pays, in wins-worth | 1 | 2 | 4 | 8 | 12 | 16 | 24 | 32 |

Four wins is one unlock, so a 30-day streak of real games, or a 100-game day against opponents near the player's own level, is worth roughly one free opponent. The same streak kept alive with one Pebble game a day is worth four points, and that is the intended answer rather than a shortcoming: showing up is what the streak measures, but *what you showed up to* is what the points measure. A per-opponent quest pays 2ⁱ — one win against the opponent it names — so the forty of them are worth about two extra wins against each opponent the player actually works through.

**From 0.4, the volume ladder is subscriber-only by arithmetic, not by a rule.** Five games in a day exceeds the free cap of three, so no free player can complete even the first rung. This is deliberate and must be *stated* rather than left to be discovered: the quest tiles show the requirement, and a free player sees why it is out of reach and what would change it. A permanently unreachable goal presented without explanation reads as a bug.

**That copy ships with the meter, not before it.** The cap arrives at 0.4 (§4.2) and progression arrives at 0.1, so for the whole of the closed test every tester can complete the entire volume family and an explanation of why they cannot would be false. In 0.1 these are ordinary quests with no restriction copy; the explanation arrives in the release that makes it true.

**There is no remaining farm vector, and no rule is doing the work.** The daily-volume family was the last one, because it counts games rather than weighing them — but pricing it by the average opponent means a hundred games against Pebble pay a hundred games' worth of Pebble, which is four points. The paywall is no longer what contains it, which matters because the paywall does not exist until 0.4 and progression ships at 0.1; a containment rule that arrives three releases after the thing it contains is not a containment rule. This is the same property §7.3 has and for the same reason: the exponent does the work, so no anti-farming rule has to.

### 7.5 Streaks

**A day is the device's local calendar day**, and it is kept alive by finishing at least one game against the computer. Starting one is not enough — otherwise the streak is maintained by opening the app and quitting.

**A missed day resets the streak to zero.** No forgiveness, no rest days, no repair purchase. The long rungs are meant to be rare, and every softening mechanism is another rule to explain, another thing to store, and another surface for "I *did* play on Tuesday" support mail.

Two consequences to handle honestly rather than hide:

- **A player who crosses time zones can gain or lose a day.** Evaluating against local time means an eastward flight can shorten a day below the point where they played. Accept it, and evaluate generously where the rule is ambiguous — never break a streak that any reasonable reading would have kept.
- **The 1440-day rung is just under four years.** It exists as a horizon, not as a target, and nothing in the design depends on anyone reaching it.

### 7.6 What must be stored — and the rule it breaks

§3 says everything derives from the move list. **This is the one place that stops being true**, and it is worth being explicit about why rather than letting a rebuilder discover an undocumented table.

Points *earned* is still a fold over stored games — sum 2ⁱ over wins, plus the quest awards, all of which are themselves derivable from the games and the calendar. Points *spent* is a decision, and a decision is not in the move list. So one new record exists:

```
unlock: { opponentId, unlockedAt, pricePaid, source }
```

- **`pricePaid` is stored for the same reason a game stores the opponent's anchor rating** (§5): re-tuning a cost later must never retroactively bankrupt someone who already spent at the old price. The balance is *earned minus the sum of prices actually paid*, which is stable under any future change to the table.
- **`source`** distinguishes points from the one-time purchase, so a refund of the purchase can revoke exactly what it bought and nothing a player earned.
- Everything else stays derived. There is no stored balance, no stored streak length, no stored quest progress — all three are folds, and all three would drift.

**Points earned is a fold over the games and nothing else** — no unlock record is consulted to compute it. That is a consequence of §7.4 pricing every quest by the opponents it was earned against rather than by the player's current rung, and it is worth stating because the alternative was not obviously worse until it was written down. Under a current-rung rule, an award would depend on which opponents were unlocked *at the moment it fired*, so the fold would have had to interleave completed games with unlock records in time order — two streams, an ordering hazard on both, and a balance that could not be checked against the game list alone. Pricing by the opposition removes the dependency entirely.

The ordering key stays exactly as §5 defines it, and it is still load-bearing for the per-game rating steps: `completedAt`, with the game id as tie-break.

**Storing the price but deriving the award is asymmetric, and the asymmetry is resolved by a rule rather than a second table.** Re-tuning §7.4's multiples downward would reduce every player's earned total, and since the balance is *earned minus prices actually paid*, it could drive a balance below zero against unlocks already bought — the same bankruptcy `pricePaid` exists to prevent. **The balance clamps at zero, and no unlock is ever revoked.** A downward re-tune costs future purchasing power and takes nothing away. The alternative — storing each award as it fires — would buy insurance against a re-tune expected once, before real players exist, at the permanent cost of the property that nothing but the unlock records is stored.

This record is **the first thing in the app that is not reconstructible from game history**, which means it must be in the **explicit Android backup allowlist from 0.1**, not from whenever the cloud arrives. A player who replaces their phone and loses fifteen unlocks they earned over two months has lost the only thing in this app that was expensive to acquire.

### 7.7 How these numbers were chosen, and when to change them

Every other number in this document was measured. These were derived from a single stated target: **one unlock should be about one sitting, and the full roster about two months of ordinary play.** Everything else — the doubling, the four-wins rule, the quest multiples — follows from that target and from wanting the effort per rung to be flat.

That makes them the most likely numbers in the document to be wrong, and the ones to instrument first. Take the same stance §6.7 takes on opponent strength: **when observed play disagrees with the table, the table changes.** The two signals worth watching are the median time to each unlock and the rung at which players stop.

What must *not* change casually is the **shape** — doubling on both sides. It is what makes downward grinding self-pricing (§7.3), and a flattened curve reintroduces an exploit that no rule elsewhere is defending against.

---

## 8. User interface

### 8.1 Layout policy

**Portrait phone only.** One layout, orientation locked.

v2 specified a second landscape layout above a 600 dp breakpoint, and a ticket existed to build it. It is cancelled. The first release targets phones; a large-screen layout is a second set of screens to design, build, test at every font scale and keep correct, in service of a form factor nobody has yet asked for. It can come back when there is a reason, and coming back is cheaper than carrying it unused.

### 8.2 The board

**All four layers are drawn at once**, as sheared parallelograms suggesting depth, so the whole cube is visible without rotation. A move is a **single tap on an empty cell**, with no confirmation step.

**Derive the geometry from the touch target, not the other way round.** Decide the minimum cell size first and let the board's dimensions follow. Doing it the other way produces a board that looks right and cannot be played on a small phone.

**The four layers stack in one column, against one edge of the screen.** v1 proposed a 2×2 grid; that was wrong, and the reason is worth stating. A 2×2 grid of layers wastes the width a portrait phone does not have and produces cells below the minimum touch target on the smallest supported screen. One column, layer 1 to layer 4 top to bottom, right-aligned, leaves a usable strip on the left for the move list and scrubber and keeps the cells finger-sized.

44 dp per cell is geometrically impossible for 64 always-visible cells on a phone. Adopt the WCAG 2.5.8 dense-grid floor of 24 dp plus a margin, and assert it in a test **across the whole supported size range** rather than on the one device that happened to be tested first.

**When a game ends, highlight the completed line.** Win detection therefore returns *which* line completed, not merely that one did.

**Mark the last move played, by each side.** Marking only the newest move means a player's own piece stops being marked the instant the opponent answers — about half a second against a computer — so the one move they never see marked is their own. Mark the last two: turns alternate, so that is exactly one per side.

If the mark is a colour change, **move each piece away from its own resting colour** rather than towards a shared accent. A light piece going to a light green is a hue shift with no lightness shift, and on a small pebble under phone glare that is nearly nothing. Ours failed exactly this way, and every test passed, because every assertion compared the two *marked* pieces to each other rather than to an unmarked piece of the same colour.

Any pulsing stays well under **three flashes per second** (WCAG 2.3.1), and holds steady instead of pulsing when the platform reports reduced-motion.

### 8.3 Main screen

Top to bottom:

1. **Rating card** — the computer rating, the win/loss/draw record, the points balance, a ten-game trend graph, and a line making clear it is a rating against the computer, on this device only
2. **Your path** — a scrollable row of opponent tiles (§8.4)
3. **Games in progress**
4. **Quests** — the four closest to completion (§8.6)
5. **Finished games** — four rows and a way to see the rest (§8.5)
6. A large primary **new game** button, and an entry to the tutorial

**The ten-game trend graph.** A line with a dot per game over the last ten completed games, coloured green if the rating is higher than it was ten games ago and red if it is lower, **with the signed change stated beside it** — `+43`, `−12`. The number is not decoration. Trend colour here is *information*, not confirmation, and red-versus-green is the worst possible pair for the commonest colour vision deficiency; without the number, a red-green colourblind player learns nothing at all from the graph. It is the same argument the paragraph below makes about bars and numbers, in a case where getting it wrong makes the element useless rather than merely weaker. Fewer than two completed games, no graph.

**On showing a rating as a bar anywhere:** scale it against the **top of the catalogue**, from zero. Scaling against the strongest opponent the player has met puts a full bar in every list, means something different on each device, and shortens every existing bar the first time they beat someone new. Zero-based rather than min-max, because 600 really is a quarter of 2400 and the roster is not evenly spread. Draw the unfilled track too — the comparison being offered is against the top of the ladder, which is usually not on screen. And show the number as well: a bar is comparative and cannot be read off; a number is exact and cannot be compared at a glance.

### 8.4 Your path

Replaces v2's by-opponent breakdown, which listed all twenty weakest-first and answered a question nobody was asking. This one answers "where am I, and who is next".

**A horizontally scrollable row of the whole roster, resting on the opponent the player is climbing toward.** Three tiles are visible at a time and the row starts scrolled so that the middle one is the **lowest-rated opponent rated above the player's rating** — Clover at 900 for a player seeded at 800. The player can scroll left through everyone they have beaten and right through everyone they have not, all twenty, in roster order. Each tile stacks vertically:

- a full-tile-width avatar
- the name
- the rating
- the win/loss/draw record
- three stars
- a rematch button — icon only, with a spoken label, because no button text fits the width

**It rests on the rating ladder, and scrolling is what makes that safe.** A fixed three-tile window centred on the *unlock* ladder was the earlier design (D262), and its argument was sound while the window was fixed: a player seeded at 800 would have seen Mote, Clover and Bramble — three opponents they already own — with their next unlock at 1100 outside the window entirely, so the price ladder would have been invisible on first launch. A scrollable row removes that objection rather than answering it. Nothing is outside the window any more; the unlock ladder is one swipe right, and it is reachable at every point on the roster instead of only where the two ladders happen to coincide. What the resting position buys is the answer to "where am I", which is the question the player asks first and the one a rating answers.

**Rated strictly above, so the centre is always a step up.** An opponent rated exactly the player's own rating sits to the *left* of the resting tile. Mote at 800 is an even match for a player at 800 and the section is about who is next, not who is level; the even match is one tile away and clearly marked as even (§5.1).

**The row clamps at both ends without leaving a hole.** A player below the whole roster rests at the first opponent, one above it rests at the last, and either way three tiles are on screen. A two-tile row with a gap in it looks like a bug.

**Locked opponents appear in full**, greyed, with their price and the player's progress toward it. Hiding them would hide the goal, which is the entire motivation for the ladder. The full roster, with the same records and stars, remains browsable in opponent selection (§8.7).

**Tapping a tile opens that opponent's detail page** (§8.15). The tile is a summary and the page is the whole of what is known about them.

**The three stars count decisive games only.** Draws are ignored, on both sides of every comparison.

| Stars | Condition |
|---|---|
| none | never played, or no wins |
| ★ | fewer wins than losses |
| ★★ | wins at least equal to losses |
| ★★★ | at least 80% of decisive games won |

An opponent never faced shows **no star row at all**, rather than three empty stars. Unearned and failed must not look the same.

### 8.5 Finished games

Four rows, most recent first, each opening into replay. A **show more** button opens a full history screen rather than expanding the list in place — a four-row section that grows to three hundred rows inside an already-scrolling page is worse than a screen made for the job.

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

A quest a free player cannot reach (§7.4) shows its requirement plainly and what would change it, rather than presenting an unexplained wall.

Achieving a quest during a game is acknowledged **when that game ends**, together with the points it paid — not silently recorded and not interrupting play.

### 8.7 Opponent selection

Twenty opponents is too many for a flat list on a phone. Present them as an **accordion by tier, opened at the tier containing the player's own rating** — where they are standing, not at the top or the bottom. Each row carries name, avatar, rating, tier description, blurb, record, stars, and a marker for pairings that are lopsided (§5.1).

Locked opponents show their unlock price and progress. The unlock action lives here, on the Your Path tiles and on the detail page (§8.15), and all three lead to the same confirmation — which, for Oracle and Quadrim Prime, must repeat what §6.6 requires the store listing to say.

**Tapping a row here starts a game**, as it always has. This screen is reached by pressing *new game*, so the player has already said what they want to do; routing them through the detail page first would add a tap to the commonest path in the app. The detail page is for browsing, and it is reached from Your Path.

**Backing out of the opponent list cancels the whole flow.** Falling back to a default opponent gives the player a game against somebody they did not choose, which is worse than no game.

### 8.8 Game screen

Opponent above the board, the board, a move-history scrubber, and — against a human — chat.

**The result panel sits below the board, not over it.** A player wants to see the position that just ended alongside the result.

**The scrubber replaces the turn banner rather than adding a row.** There is no vertical room for both on the smallest supported phone — measure the slack before designing the control. While reviewing, the board is not interactive, so the touch-target floor does not apply to it and it may give up height.

**Opening a finished game goes straight to review**: the scrubber is present and active immediately, with the result shown alongside it. A finished game has exactly one thing a player came for, and making them find the control first is a step with no purpose.

### 8.9 Matchmaking entry points

| Path | Behaviour | Creating | Accepting |
|---|---|---|---|
| Invite link or code | Share a link; whoever opens it joins | tier 3 | **free** |
| Direct challenge | Challenge someone on your friends list | tier 3 | **free** |
| Auto-match | Server pairs the nearest-rated waiting player | tier 3 | tier 3 |
| Open challenge board | Public list anyone may accept | tier 3 | tier 3 |

**Invite codes are bearer tokens**: enough entropy to resist enumeration, short expiry, single use, revocable, and checked against the creator's block list on join.

**Friendship is mutual.** Adding sends a request; friendship exists only once accepted. Friend requests carry **no free text** and are rate-limited, because an unfiltered request message is a chat channel that bypasses the chat preference. Display-name lookup is exact-match only and rate-limited.

This matters more than it looks: `friendsOnly` is the default chat preference, so if friendship were unilateral, anyone who added you would become a friend and the default would be defeated by the adder's own action.

Auto-match offers a similarly-rated computer opponent after a short wait rather than leaving a player queued against an empty population. That fallback creates a local computer game, does not consume the online cap, and **never offers a locked opponent** — it falls back to the nearest unlocked one instead. Handing someone a game against an opponent they have not earned would either give away an unlock or produce a game they cannot start again.

### 8.10 Profile view

Display name, avatar, human rating, record, head-to-head against the viewer, member-since. The computer rating, the points balance and the unlock progress are never shown to anyone but their owner — they describe a single-player journey and mean nothing to an opponent.

Last-active is **coarsened** — "active this week", not a timestamp — and shown only to accepted friends. Combined with unique display names and add-by-name, a precise last-active is a presence-tracking capability against a named individual.

### 8.11 End of game

A result screen showing the highlighted line, the rating change on whichever ladder the game belonged to, the points earned, any quest completed, and a one-tap rematch that swaps colours and the starting player. A pass-and-play result says plainly that no rating changed and no points were earned.

The rating change shown must be **the step that game caused**, folded from the prefix ending at it — not the step the most recent game caused. Those differ the moment a player opens an older finished game.

If the win just paid for the next unlock, say so here and offer it. That is the moment the player is most interested, and making them navigate to find out wastes it.

### 8.12 Tutorial

Shown once on first launch, restartable from settings. It covers the objective and what the 76 lines look like — with emphasis on the diagonals through layers that new players consistently miss — how the layered view maps to the cube, basic strategy, and an **interactive practice game with hints**.

Six things learned building it:

- **Draw the demonstrations on the real board widget.** A second, simplified illustration board is a second thing to keep correct, and it will drift.
- **Describe a demonstration board in one sentence**, not sixty-four cell labels. A screen reader reading out an entire empty board to reach the three interesting cells is worse than useless.
- **Strategy is a section of the one tutorial, not a second tutorial.** It was tempting to split; splitting produces two things a player must find.
- **Derive hints from the opponents' own rule ladder** rather than scripting them. The hint is then correct by construction in any position, and it is the same code the opponents use.
- **The practice game is never written down.** It is not on any ladder, has no opponent worth recording, earns no points, counts against no meter, and would otherwise appear in the player's history as a game they did not play.
- **Remember that the offer was declined, separately from completion.** Record the offer *before* showing it: a dialog dismissed by tapping outside returns no answer, and recording afterwards re-arms the offer on the next launch. Repeating a question the player has waved away is the failure mode to design out.

### 8.13 Accessibility

- **Pieces distinguishable without hue.** The two players' pieces differ by **lightness**, which survives every form of colour vision deficiency including full achromatopsia. Shape is an acceptable alternative, not a requirement. Whatever else the board does with colour — marking a move, highlighting a win — must not turn this into a hue distinction.
- **Every cell exposes a position-and-contents label** such as "Layer 2, row 3, column 1, empty".
- **A row that shows several facts announces them as one node**, not three. An avatar is decorative; a name and a state only mean anything side by side. Equally: whatever the eye can read from a shape must be *said* somewhere, and said **once** — a rating shown as a bar and a pill and announced twice is worse than never announced. A Your Path tile is one node: name, rating, record, stars, locked-or-not, and price if locked.
- **Nothing carries meaning by colour alone.** The trend graph states its change as a signed number, a locked tile says "locked", stars are counted rather than merely drawn.
- **Announce changing state through a live region**, attached to the message rather than to the space reserved for it. A live region wrapped around an empty placeholder announces nothing, repeatedly.
- **System font scaling is respected**, and every screen must reach its last row at the largest setting. The three-tile row is the tightest thing on the main screen at large font sizes and needs a specific test.
- **Light and dark themes**, both readable.

### 8.14 Settings

Language (system, or an explicit choice), theme (system, light, dark), a way to see the tutorial again, subscription and restore-purchases, and the attribution required by §6.6.

**Language and theme are watched at the root of the app** and applied immediately, without a restart. "System" is the *absence* of an override, not a third value to translate into one.

---

### 8.15 Opponent detail

One opponent, in full. Reached by tapping a Your Path tile (§8.4).

**The avatar is the top of the screen, at the largest size it is ever drawn.** These are twenty characters with names and faces, and the roster is the thing the player is working through; a page about one of them that leads with a table is a page about a number. Below it, in order:

- the name, the rating and the tier
- the blurb — the sentence that says how they play (§6.5)
- how the pairing sits against the player's own rating: even, above, or below (§5.1)
- the record: won, lost, drawn, and the three stars (§8.4)
- what a win against them pays, in points (§7.2)
- for Oracle and Quadrim Prime, the warning §6.6 requires

**At the bottom, one action.** Unlocked, it is **start a game**, and it does exactly what selecting them in §8.7 does. Locked, it is the price, the progress toward it and an **unlock** button, leading to the same confirmation the other two routes lead to. The page is never a dead end: every opponent has something to do on it.

**It reads the same catalogue and the same folds as everything else.** No new record, no second copy of a rating, no per-opponent document. What it adds is a place to put what is already known, at a size worth looking at.

## 9. Chat and safety

Free-text 1:1 chat, only between the two players of a shared game and only while that game exists. No chat with computer players, no group chat, no global chat.

**Chat is opt-in per player, and the more restrictive preference wins.** Three values — every game, friends only, never — defaulting to friends only, overridable for one specific game.

Chat exists for a game only if **both** players allow it. Otherwise permission derives from game membership, which means creating a game against a stranger implicitly opens a channel to them.

Availability is resolved when the game is **accepted**, not created — three of the four matchmaking paths give the joiner no start-a-game flow, so resolving at creation silently ignores their preference. It stays revocable: either player can turn it off, switching the global preference to `never` clears it everywhere, and blocking terminates it. **A game record with no chat field means chat is unavailable**, so games created before chat existed fail closed.

Required: **block** (checked in the game-creation and invite-acceptance path, not only on send), **report**, and **server-side profanity filtering** before delivery. Chat messages are written by the server, never directly by a client.

**Block, report and display-name validation ship one release *before* chat**, because they are contact-surface features and the contact surface opens with invites, profiles and push.

Display names are globally unique, validated server-side, and immutable for 30 days after each change so name-swapping cannot evade blocks.

**Accounts are linked before they are worth anything.** Anonymous auth is enough to try online play; before a first rated game or any purchase the account must be linked to Google, Apple or email. An anonymous account cannot be recovered, and a data-subject request against one cannot be verified. Offering third-party sign-in on iOS requires Sign in with Apple alongside it.

**Account deletion and data export** are both in-app. Deletion removes personal data while retaining game records with the identity replaced by an opaque per-game token, so opponents' rating histories stay coherent. It must state plainly that **it does not cancel the store subscription** — a common review rejection.

---

## 10. Notifications

Your turn, new message, game ended, challenge received, streak about to lapse — each individually toggleable.

**A streak reminder is the one notification the product genuinely wants to send and the one most likely to be resented.** Send at most one a day, late enough to be useful and early enough to act on, only to players with a streak of at least five days, and never to a player who has already played that day. It must be individually toggleable like the rest, and turning it off must not turn off "your turn".

**Firebase Cloud Messaging does not support Flutter on Windows or macOS.** Web push requires an explicit grant and, on iOS Safari, home-screen installation. Push is a mobile feature; web and desktop degrade to in-app notification and a badge while the app is open. **The app must say so**, because a desktop-only player would otherwise be silently forfeited by the 7-day rule.

---

## 11. Technical architecture

### 11.1 Stack

Flutter for the client. **Android first; iOS from 0.3b** (§12). Firebase for the backend from 0.3a: Authentication, Firestore, Cloud Functions, Cloud Messaging.

**Structure the code as a Flutter app over pure-Dart packages**: the rules, search and opponents in one, the rating maths in another, both with **no dependency on Flutter, on any I/O library, on an ambient clock or on an ambient random source, and no runtime dependencies at all**.

The progression maths — point values, unlock costs, quest multiples, star thresholds — belongs in a pure package of its own, `quadrim_progression`, under the same rules. It is arithmetic over stored records, it needs to be exhaustively testable, and it must not acquire a clock. Streak evaluation *does* need a calendar, so **the day boundary is passed in, never read**.

**Not in the engine package, by the engine's own rule.** §6.1 says locking is not an engine concern and the catalogue carries no `locked` field, because the strength harness plays all twenty against each other and has no business holding an entitlement. Arithmetic about what a player owns and what it cost sits on the other side of that line. It does need the roster index, so it depends on the engine package — the one inter-package dependency in the project, running in the allowed direction.

**Enforce that mechanically.** Ours is a grep in the build gate over each package's manifest and imports. Purity that is merely intended lasts until the first convenient import.

### 11.2 The build gate

One script that analyses and tests every package and additionally checks what the specification demands but a compiler cannot:

- package purity, as above
- no user-facing string outside the localisation files
- the licence attribution is still rendered somewhere in the app's source
- the vendored dictionary's SHA-256 is unchanged
- generated sources are not stale
- every string exists in **both** languages — a missing translation fails the build
- **the release manifest declares no networking permission**

That last one deserves comment. "Computer play makes no network call" is a negative, and grepping the source for an HTTP client only checks the spellings you thought of, while a transitive dependency could reach the network without any of them appearing. The **permission** is categorical: without it the platform refuses the call whatever the code asks for. When the online releases genuinely need networking, narrow the check to computer play rather than deleting it.

Nothing is committed without this passing. Give every long run a hard timeout — a hung suite is indistinguishable from a slow one.

### 11.3 Layering on the device

A **document store** (bytes: file or in-memory) sits under a **repository** (rules: completion, validation, ordering). The store is the pluggable part, not the repository — swapping the repository in tests would test a path the app does not use, while swapping the store keeps every rule under test.

Make the repository **stream-based rather than future-based**, so the cloud implementation satisfies the same contract without a UI rewrite.

**Game completion is decided in the repository**, once, not by each caller. Points are awarded there too, for the same reason: it is the one place that knows a game has just finished, and awarding from a caller means every future caller must remember to.

### 11.4 Authority model, from 0.3a

The client computes and renders moves immediately so play feels instant. A Firestore-triggered Cloud Function re-validates every move, detects the win, and writes the result and the rating change.

A client may write **only** its own move to a game it is in when it is its turn, its own chat messages, and a named list of its own profile fields. A client may **never** write results, either rating, entitlement, totals, timestamps, or another player's data. The allowlist is **field-level, not document-level** — "its own profile fields" would otherwise permit exactly the writes that sentence forbids.

**Points and unlocks stay local and stay client-written**, and that is deliberate. They are earned against deterministic opponents on the player's own hardware, exactly like the computer rating — editing them cheats nobody but yourself. Moving them to the server would mean sending computer-game results to a server, which §4 forbids categorically. The one thing that must be server-authoritative is the **meter** (§4.2), because that gates a purchase.

**The security rules are the trust boundary, so they are a tested deliverable, not configuration**: their own ticket and an adversarial suite in CI where every test is an attempt that must be *denied*.

The rules logic exists in two places — Dart on the client and in the validating function — and both must be driven by the same 76-line definition and the same shared test vectors, or they will drift.

### 11.5 Data model

**Store the simplest correct thing.** For the offline releases specifically:

- **No device identifier at all.** None is generated, stored or transmitted. This is not merely a privacy nicety — it removes an entire class of question about what a backup contains.
- A game records a seat that is the player, a named opponent, an ordered list of cell indices, who started and why, and — when finished — the outcome, the reason, the winning line, the completion time, and the opponent's anchor rating.
- An unlock records the opponent, when, the price paid, and whether it came from points or the one-time purchase (§7.6).
- Whose move it is derives from position in the list and the starting seat. No per-move author, id or timestamp.
- Statistics, ratings, point balances, streaks and quest progress are all derived, never stored.

Local storage is **never retired**. Offline games stay local for the life of the app; online games live in the cloud. Two implementations serving two kinds of game, not one replacing the other. **There is no import path from local to cloud, ever** — that decision removed the single largest source of complexity and risk in the whole plan.

There is deliberately **no server-side copy of the opponent catalogue**. Computer play never touches the network, so it would be a second source of truth for something the server never uses.

Android auto-backup is left **on**, so players do not lose history when they replace a device, with an **explicit allowlist** rather than the platform default. **The unlock records are in that allowlist from 0.1** — they are the only thing in the app a player cannot regenerate by playing, and losing them on a device change loses months of work.

It follows that **"no data leaves the device" must never appear in any privacy text** — it is false, and the backup is a deliberate trade.

### 11.6 Localisation

English and Dutch, both complete at launch, English the fallback. All strings in resource files from the first commit. Bot names are not translated; blurbs are. Relative dates, point totals and prices are all locale-formatted; a thousands separator is not a decoration.

### 11.7 Identity

The application id is **permanent** from the first upload to any track, including closed testing. A different id is a different app, with its own listing and its own install base. Choose it against a domain you control, and never ship the scaffolding default — stores reject `com.example.*`.

Four places must agree: the application id, the build namespace, the source package, and the directory mirroring it. A mismatch is a crash on launch rather than a build error.

---

## 12. Release plan

| Release | Contains | Platforms | Public |
|---|---|---|---|
| **0.1** | The complete offline game: board, all twenty opponents, computer rating, **points, unlocks, quests and streaks**, history and replay, tutorial, settings, both languages | Android | no — closed test |
| **0.2** | Real art, polish | Android | no |
| **0.3a** | Anonymous auth; a cloud repository passing the *identical* flow tests as the local one; one async game between two of the developer's own devices. No push, no rating, no functions | Android | no |
| **0.3b** | Invite links, push, block/report/name validation, account deletion, privacy policy | **+ iOS** | **first public release** |
| **0.4** | Human rating **and** server-side move validation, together. Subscriptions, the one-time unlock, and the meter | Android + iOS | yes |
| **1.0** | Roster revision, remaining platforms | Android + iOS + whatever 1.0 adds | yes |

**Why 0.1 is a complete game rather than a demo.** It costs a larger first release and buys something to actually test. A move-history scrubber, a result screen, statistics and replay are all cheap given an append-only move list.

**Why progression is in 0.1 rather than later.** It is the reason to open the app on the second day, and a twelve-tester closed test that runs for fourteen days is precisely a measurement of whether people come back. Shipping the ladder afterwards would mean the one test that could have validated it ran against a build without it.

**Why the meter is not.** There is nothing to sell before 0.4, so metering earlier would be a wall with no door. A closed tester limited to three games a day also cannot give useful feedback about twenty opponents.

**Why iOS waits for 0.3b.** Google Play requires a personal account to run a closed test with twelve testers for fourteen continuous days before granting production access. Starting that clock is the critical path, and it needs no Apple account, no Apple hardware and no second signing pipeline. iOS joins for the first public release, where a second platform starts earning something.

**Why 0.3 is split.** Without the split, the first public release is also the first release in an unfamiliar stack, with no prior public exposure to learn from. 0.3a proves the layering privately; 0.3b opens the contact surface.

**Why the human rating waits for 0.4.** It ships with the validation that makes it trustworthy, because they are the same feature (§5).

**First success is twelve real people playing 0.1 on their own devices, with the release pipeline proven end to end** — signed builds, both testing channels, production access unlocked. Not "an app in the store".

---

## 13. Definition of done

1. The 76-line table is generated once, and win detection returns the specific completed line. Verified exhaustively.
2. A game can be played to a win and to a draw in all four modes.
3. Client and validating function agree on every move of a shared corpus of full games.
4. All twenty opponents exist, are distinguishable in play, and are calibrated by a self-play harness that reports measured against published strength.
5. The top opponent's advertised strength matches what it delivers, and the interface never claims perfection it cannot deliver from both seats.
6. Both ratings update correctly and independently — provisional K, draws, forfeits, the floor. The computer rating is derived from stored games, never stored, and never leaves the device; the human rating is never written by a client.
7. **Points, unlocks, quests and streaks are correct**: a win pays 2ⁱ, an unlock costs 2ⁱ⁺¹ and is available only in roster order, the balance is earned minus prices actually paid, and every quest fires exactly once. **No quest reward anywhere depends on the player's own rung** — a per-opponent quest pays that opponent's index, and a volume or streak quest pays the rounded mean index of the games that earned it. A hundred games against Pebble in one day pay four points, and deferring a first win against a weak opponent earns nothing extra.
8. **An unlock survives a re-tune of either table.** The cost table, because the price paid is stored with it; the quest table, because the balance clamps at zero and no unlock is ever revoked.
9. **A missed day resets a streak and a played day does not**, across a month boundary, a year boundary and a time-zone change.
10. **Nothing but the unlock records is stored.** Balances, streaks, quest progress and statistics are all derived, and a test proves each one reconstructs from game history alone.
11. Async games expire correctly, with a warning first.
12. All four matchmaking paths create playable games, and the computer fallback never offers a locked opponent.
13. Chat works with block, report and profanity filtering, honours the more restrictive of the two preferences, is revocable, and fails closed on records that predate it.
14. All subscription products and the one-time unlock purchase and restore; the subscriptions sit in one group so an upgrade is a store-native plan change; a lapse lets existing games finish and rate, blocks new ones, exempts from forfeit, permits one rematch in a series, and **never revokes an unlock**.
15. **The meter counts started games, applies both limits, names the one that bit, and does not restart the free month on reinstall.**
16. Entitlement cannot be written by any client and is revoked on refund or chargeback.
17. The security rules pass an adversarial suite in which every attempt is denied.
18. Account deletion and data export work in-app, and deletion states it does not cancel the subscription.
19. An account is linked before its first rated game or purchase.
20. The one portrait layout renders on the smallest and largest supported phone, in both themes, at the largest font scale — including the Your Path row and the opponent detail page.
21. The board is playable and legible for a colourblind player and navigable by screen reader, every fact shown visually is announced exactly once, and **no element carries meaning by colour alone** — the trend graph in particular states its change as a number.
22. The tutorial runs end to end, including the practice game, which is never stored, never paid and never metered.
23. Every string exists in English and Dutch, enforced by the build.
24. Notification limitations on web and desktop are surfaced, and the streak reminder is separately toggleable.
25. The release build declares no networking permission, enforced by the build.
26. **The unlock records are in the explicit Android backup allowlist**, and a restore on a new device returns them.

---

## 14. What is still open

Every item here is a business, account or measurement decision. **None is functional, and none blocks building the game.**

| Item | Why it is open |
|---|---|
| **Store price points** | $1.99 and $4.99 are the intended prices; the actual store tiers, tax treatment and per-country equivalents are not yet chosen. Needed before 0.4, not before code. |
| **Store accounts and signing** | Requires the owner's Google account now and Apple account by 0.3b. The application id must be chosen before the first upload and is permanent thereafter (§11.7). |
| **App name availability** | Checked against both stores and trademark registers. Not yet done. |
| **The reference device** | The twenty-second ceiling (§6.8) is a device number, and the node-to-seconds conversion must be confirmed on real hardware. |
| **The progression numbers** | The shape is settled and the values are derived from a stated target rather than measured (§7.7). They are the first thing to instrument once real players exist. Watch the median time to each unlock and the rung at which players stop. |
| **Two Casual-tier rating inversions** | Vireo measures above Finch, and Willow above Vireo, by about 40 points each. This is **not** a configuration defect and no parameter change closes it: the roster pins `aggression` in the direction that opens the gap (§6.5), and the blunder rate cannot spread far enough because it must fall as rating rises between Bramble's 0.15 and Kestrel's 0.08. The fix is a roster change, owned by 1.0. **Progression gives it a visible symptom**: the roster index sets both the unlock price and the win payout, so across three consecutive rungs the player is shown increasing prices for decreasing strength — Willow at 64 is the strongest of the three, Finch at 256 the weakest by about 83 points. The economy survives (four Kestrel wins remain a faster 1,024 points than eight Finch wins, so §7.3's self-pricing property holds), but three prices are displayed as a public claim about difficulty and for these three the claim is false. Re-pricing by measured strength is not available — §6.4 pins pricing to the index and the ratings are anchors — so this is an argument for scheduling the 1.0 roster revision early, not for a tuning pass. A rebuilder starting from this document should instead design the Casual tier so that its personalities and its rungs agree. |

**Things earlier editions listed as open that are now closed:** push on desktop and web (§10 — a stated platform limitation, not a problem to solve); the size and obtainability of the strategy book (§6.6 — 54,745 bytes, published, permissively granted); anchor calibration (§6.7 — a built harness); auto-match cold start (§8.9 — a computer opponent after a short wait); the per-game Firebase cost, negligible in steady state now that the migration burst that dominated it no longer exists; the business model (§4.1); and the large-screen layout, which is cancelled rather than deferred (§8.1).

---

## 15. Sources

The game is public, old, and thoroughly analysed. Nothing about its mathematics needs deriving.

- **Wikipedia, "3D tic-tac-toe"** — https://en.wikipedia.org/wiki/3D_tic-tac-toe — line counts, cell degrees, automorphism count, solution history.
- **R. Silver (1967)** — established the group of 192 automorphisms.
- **Eugene Mahalko (1976)** — weak solution: a first-player win exists.
- **Oren Patashnik (1980)** — "Qubic: 4 × 4 × 4 Tic-Tac-Toe", *Mathematics Magazine* 53(4), 202–216. The complete first-player-win strategy, computer-assisted, about 1,500 hours, roughly 2,929 stored strategic positions. **Method and proof, not the dataset**, and copyrighted — read it to understand the forcing-move machinery, do not ship content from it.
- **Victor Allis** — independent solution by proof-number search.
- **`qubic.dictionary`** — the strategy data itself, carrying its own permissive grant. See §6.6 for the obligations that come with it.

**The licensing judgement in §6.6 is the implementer's to confirm.** What this document records is what the file says and what the build does about it. It is not legal advice.
