# Quadrim — Specification, second edition

What Quadrim is and what it must do, written so that someone rebuilding it from nothing has no functional question left to ask.

This is [idea-v1.md](idea-v1.md) rewritten against everything the build actually settled. Release 0.1 is implemented; the decisions that shaped it are recorded individually in [idea-v1-decisions.md](idea-v1-decisions.md) (D01–D217), and this document is their result rather than their index. Where v1 left a question open, the answer is here. Where v1 was wrong, the correction is here and the mistake is named, because the wrong turnings are worth more to a rebuilder than the destination.

Status: 0.1 built and playable. 0.2 onward specified, not built.
Date: 2026-08-14

---

## 0. How to read this

Three things are true of this document that were not true of v1.

**Nothing here is a question.** v1 carried five open items and a fallback ladder for the top opponent. All of them are resolved below, and §13 lists the handful of genuinely open items that remain — every one of them a business or account decision, none of them functional.

**Where a number appears, it was measured.** Search budgets, rating gaps, board dimensions and think times are results from running the thing, not estimates. Where a number is still an estimate, it says so.

**The mistakes are included.** v1 described a 2×2 grid of board layers, a solver sub-project, and a Casual tier ordered by blunder rate. All three were wrong, and finding out cost real time. They appear below as corrections rather than being quietly replaced, so nobody spends that time again.

---

## 1. What Quadrim is

Quadrim is a two-player game played inside a 4×4×4 cube of 64 cells. Players alternate placing a piece of their own colour on any empty cell. The first player to occupy all four cells of any straight line wins. Lines run along the axes, diagonally within a flat plane, and diagonally through the body of the cube. If all 64 cells fill with no line completed, the game is drawn.

The game is known publicly as Qubic, or 3D tic-tac-toe. It is a solved game: with perfect play the first player wins. This fact shapes several decisions below and is not treated as a defect.

A player can play another human — asynchronously over days, or in real time — or any of twenty computer opponents, each with a name, an avatar, a play style, and a fixed rating.

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

| Mode | Opponent | Network | Affects | Subscription |
|---|---|---|---|---|
| Async online | human | yes | Human rating | only to *initiate* |
| Real-time online | human | yes | Human rating | only to *initiate* |
| Vs computer | one of 20 | **never** | Computer rating | no |
| Pass-and-play | human, same device | no | Nothing | no |

Async and real-time share one game-state model and one move pipeline. Real-time adds only the per-move clock and opponent presence.

Pass-and-play affects no rating because the second party is unauthenticated and the result unverifiable. It is also excluded from the win/loss/draw record for the same reason — a record that counts games you played against yourself is not a record of anything.

A player may hold at most **20 simultaneous active games against human opponents**. Computer games are uncapped.

### 4.1 Access and subscription

**Everything release 0.1 shipped is free, forever.** All twenty computer opponents, the tutorial, pass-and-play, local history and statistics, and the computer rating. No ads, no time limit, no feature held back.

Note the scope carefully: the promise is *the 0.1 feature set*, not "nothing offline is ever paid". The broader promise would permanently foreclose an offline feature nobody has invented yet.

**Accepting a game is free. Initiating and discovering are paid.**

| | Free | Subscription |
|---|---|---|
| Accept an invite link or a direct challenge | yes | yes |
| Concurrent human games | up to 3 | up to 20 |
| Human rating, earned normally | yes | yes |
| Create invite links, challenge someone directly | no | yes |
| Auto-match | no | yes |
| Open challenge board | no | yes |
| Chat | no | yes |

Invite links are the only way a new person ever reaches this app. Charging the *recipient* makes a friend's invitation arrive as a sales pitch and throttles the one growth loop the product has at its highest-intent moment. Auto-match and the open challenge board — the surfaces a throwaway account would farm — stay paid, so the anti-abuse benefit is kept.

Three products, sold through the App Store and Google Play: annual auto-renewing with a store-native free trial, monthly auto-renewing, and a one-year non-renewing option.

**When a subscription lapses:**

- Games in progress play to the end and **rate normally for both players**. Frozen means no new rated games can be *started*, not that results stop counting — an asymmetric update would inflate the ladder for whoever happened to be playing a lapsed opponent.
- A lapsed player may accept one rematch of a series in progress, so a billing date cannot deny them the first move §3.1 owes them.
- A lapsed player is **exempt from the inactivity forfeit**. A billing event must never hand someone a forfeit win.

Entitlement is checked when a game is **created and when one is joined** — never on a move, so the lapse behaviour above works. It is a server-written field no client can touch, set only after receipt validation, revoked on refund, chargeback or voided purchase.

Both stores are merchant of record. No direct payment path is ever added.

---

## 5. Rating

A player has **two independent ratings**. Neither influences the other.

| | Computer rating | Human rating |
|---|---|---|
| Earned against | The 20 computer opponents | Real opponents only |
| Computed | On the device | On the server |
| Stored | Derived, never stored | In the cloud, with the account |
| Visible to | Only that device's owner | The player and their opponents |
| Arrives in | 0.1 | 0.4 |

Both use the same maths:

- Seed **1200**; K-factor **32** for the first 20 rated games on that ladder, **16** thereafter
- Score: win 1, draw 0.5, loss 0
- Expected score `E = 1 / (1 + 10^((R_opponent − R_self) / 400))`
- Update `R' = round(R + K × (S − E))`; floor **100**

**The computer rating is derived, never stored** — a fold over the games already on disk. Two details make the fold reproducible, and both live in the data rather than in the code:

- **Each completed game stores the opponent's anchor rating as it was when the game was played.** Without this, recalibrating any opponent silently rewrites every player's entire history and the "+12" they were shown becomes unreproducible.
- **Ordering is by an explicit completion-time field, with the game id as tie-break.** Without it, a long-running game reorders the fold when it finally completes.

That tie-break is load-bearing in a way that is easy to miss. If game ids are random and two games complete in the same millisecond, their order is a coin flip — which is fine for the product and fatal for a test fixture that creates games back to back. Inject a clock in tests.

Computer opponents have **fixed** ratings that never change. They are anchors: the player's rating moves, the opponent's does not. **When measurement disagrees with a published rating, the opponent's configuration changes and the rating does not.** Changing an anchor would silently rewrite the meaning of every result already recorded against it.

**Why the split.** The two ratings measure different things under different trust models. A rating earned against a deterministic opponent on your own hardware cannot be verified by anyone and does not need to be — editing it cheats only yourself. A rating earned against another person must be trustworthy. Conflating them forces the worse property of each onto the other.

**The human rating ships at 0.4, together with server-side move validation**, because they are the same feature. Without validation, a modified client can author a legal, replayable game naming any opponent and move that opponent's rating without them ever opening the app. Replay proves legality, never authorship. Release 0.3b therefore ships online play with a win/loss/draw record and no rating — and nobody has a rating to lose, because nobody has one yet.

Because a rating is worth losing, it requires a **linked account** (§8).

### 5.1 How lopsided a pairing is

The opponent list marks pairings that are not a fair test. Express this as an **expected score, not a rating gap**: below 0.25 expected the opponent is far stronger, above 0.75 far weaker. A gap in points means different things at different places on the ladder; an expected score means the same thing everywhere.

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

Twenty opponents across five tiers. **Ratings are fixed anchors.**

**Novice**

| Name | Rating | Configuration |
|---|---|---|
| Pebble | 600 | Random legal moves. Never notices a threat. |
| Twig | 700 | Random, but takes an immediate win. No blunder rate — its weakness is knowing one rule. |
| Mote | 800 | Wins and blocks, 40% blunder rate. |
| Clover | 900 | Wins and blocks, 20% blunder rate, drawn to corners. |

**Casual** — all four rules; what separates them is how many good squares they prefer.

| Name | Rating | Prefers | Blunder | Aggression |
|---|---|---|---|---|
| Bramble | 1000 | none of the sixteen | 0.15 | 0.5 |
| Finch | 1100 | the 8 centres | 0.13 | 0.5 |
| Kestrel | 1200 | all 16, corners first | 0.11 | 0.67 |
| Willow | 1250 | all 16, centres first | 0.10 | 0.30 |
| Ember | 1300 | all 16, centres first | 0.08 | 0.5 |

**Club** — Basalt's rules and full positional ladder, plus a look ahead.

| Name | Rating | Configuration |
|---|---|---|
| Basalt | 1400 | Full positional ladder including the building term, 6% blunder rate, no search |
| Marlin | 1500 | 2-ply, aggressive weighting, 5% |
| Vireo | 1550 | 2-ply, defensive weighting, 4% |
| Onyx | 1650 | 4-ply, 3% |
| Sable | 1700 | 4-ply plus threat-space search, 2% |

**Expert** — budgets in nodes rather than plies, because how deep a budget reaches depends on the position.

| Name | Rating | Configuration |
|---|---|---|
| Quartz | 1800 | 500k nodes, transposition table, 1.5% |
| Corvus | 1900 | 900k nodes, deeper threat search, first with a **defensive** forcing search, 1% |
| Lyra | 2000 | 1.8M nodes, deeper defence, 0.5% |
| Titan | 2100 | 2.5M nodes, exact solving below 10 empty cells, unstarved defence, no deliberate blunders |

**Master** — the first opponents that stop estimating and start knowing.

| Name | Rating | Configuration |
|---|---|---|
| Oracle | 2300 | Plays the book from move one. Unbeatable when it opens; Expert-tier machinery from the second seat |
| Quadrim Prime | 2400 | The same book, and the largest configuration in the catalogue from the second seat |

Every opponent has an avatar and a one-line personality blurb, translated. **Bot names are not translated.** Tier names carry a plain-language description, because "Club" means nothing to someone who has not played rated games.

**Tier is stored on the opponent, not derived from its rating**, even though the five tiers occupy contiguous bands today. A tier is what an opponent *is*; a rating is how strong it measured. Deriving one from the other means a recalibration silently reclassifies an opponent.

**Generate avatars from the opponent's id** rather than shipping twenty image files. A deterministic pattern from the id gives twenty distinguishable faces, costs no download, and cannot go stale when a name changes.

### 6.5 What actually makes an opponent strong

Measured, in descending order of effect. This is the part of the document a rebuilder should read twice.

**A defensive forcing search is worth about 300 Elo — the largest single lever in the project.** Before playing a candidate move, follow the *opponent's* forcing sequences and discard the move if it hands them a forced win. This is a separate depth from the opponent's own threat search, and separating the two is what gives the ladder a dimension that raising the node budget did not. Seeing your own wins and seeing your opponent's are different skills that improve at different times.

**Being defensive in temperament is worth about −78 Elo.** With two configurations identical in every respect except `aggression`, the aggressive one beats the defensive one by 28 points and the defensive one loses by 50. In Qubic, building your own double threat beats denying the opponent's. Design the roster knowing this: a "cautious" personality is a *weaker* personality, and if the ladder needs cautious opponents to be strong, the ladder and the personalities will fight. Ours do — see §13.

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

**Perfect play is first-player play.** There is no such thing as perfect second-player play in a first-player win. An opponent playing the book **cannot be beaten when it opens**, and from the second seat has no book at all and falls back on search. This has two consequences:

- **Two book opponents can only differ in the seat the book does not cover.** Oracle and Prime play an identical opening; everything separating them is second-seat search. Attempts to differentiate them otherwise failed instructively — a blunder rate would have made the higher-rated opponent blunder more, and a shallower forcing search measured as *no difference at all*, byte-identical over 200 games, because the wins that follow the book are short enough that eleven plies find them as reliably as twenty.
- **Never say "perfect" in the interface.** Say "unbeatable when it moves first". The first claim is false from the second seat and a player will find that out.

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

## 7. User interface

### 7.1 Layout policy

The breakpoint is the **shortest side of the window**: phone below 600 dp, portrait locked; large screen at or above, landscape locked. On desktop a resize can cross the breakpoint mid-game, so both layouts must survive a live rebuild without losing game state.

### 7.2 The board

**All four layers are drawn at once**, as sheared parallelograms suggesting depth, so the whole cube is visible without rotation. A move is a **single tap on an empty cell**, with no confirmation step.

**Derive the geometry from the touch target, not the other way round.** Decide the minimum cell size first and let the board's dimensions follow. Doing it the other way produces a board that looks right and cannot be played on a small phone.

**The four layers stack in one column, against one edge of the screen.** v1 proposed a 2×2 grid; that was wrong, and the reason is worth stating. A 2×2 grid of layers wastes the width a portrait phone does not have and produces cells below the minimum touch target on the smallest supported screen. One column, layer 1 to layer 4 top to bottom, right-aligned, leaves a usable strip on the left for the move list and scrubber and keeps the cells finger-sized.

44 dp per cell is geometrically impossible for 64 always-visible cells on a phone. Adopt the WCAG 2.5.8 dense-grid floor of 24 dp plus a margin, and assert it in a test **across the whole supported size range** rather than on the one device that happened to be tested first.

**When a game ends, highlight the completed line.** Win detection therefore returns *which* line completed, not merely that one did.

**Mark the last move played, by each side.** Marking only the newest move means a player's own piece stops being marked the instant the opponent answers — about half a second against a computer — so the one move they never see marked is their own. Mark the last two: turns alternate, so that is exactly one per side.

If the mark is a colour change, **move each piece away from its own resting colour** rather than towards a shared accent. A light piece going to a light green is a hue shift with no lightness shift, and on a small pebble under phone glare that is nearly nothing. Ours failed exactly this way, and every test passed, because every assertion compared the two *marked* pieces to each other rather than to an unmarked piece of the same colour.

Any pulsing stays well under **three flashes per second** (WCAG 2.3.1), and holds steady instead of pulsing when the platform reports reduced-motion.

### 7.3 Main screen

- A rating card: the computer rating, the win/loss/draw record, and a line making clear it is a rating **against the computer, on this device only**
- A breakdown by opponent, weakest first, each row carrying the opponent's rating and a bar as long as that rating
- Games in progress, and finished games, each opening into replay
- A large primary "new game" button, and an entry to the tutorial

**On showing an opponent's rating as a bar:** scale it against the **top of the catalogue**, from zero. Scaling against the strongest opponent the player has met puts a full bar in every list, means something different on each device, and shortens every existing bar the first time they beat someone new. Zero-based rather than min-max, because 600 really is a quarter of 2400 and the roster is not evenly spread. Draw the unfilled track too — the comparison being offered is against the top of the ladder, which is usually not on screen.

Show the number as well as the bar. A bar is comparative and cannot be read off; a number is exact and cannot be compared at a glance.

**On the finished-games list:** show what each game did to the rating — an up arrow and `+n`, or a down arrow and `−n`. Two things about this:

- Compute the whole list's changes in **one pass**. The change is a property of the history *up to* that game, so the obvious per-row call re-folds the entire prefix each time and is quadratic.
- **A step can round to zero.** Beating an opponent far below you earns a fraction of a point. There is no direction to point in, so show the number alone rather than an arrow claiming a movement that did not happen.

Let the arrow's direction and the number's sign each carry the meaning independently, so colour is confirmation rather than information. Red-versus-green is the worst pair for the commonest colour vision deficiency.

### 7.4 Game screen

Phone: opponent above the board, the board, a move-history scrubber, and — against a human — chat. Large screen: board left; both profiles, head-to-head statistics and inline chat right.

**The result panel sits below the board, not over it.** A player wants to see the position that just ended alongside the result.

**The scrubber replaces the turn banner rather than adding a row.** There is no vertical room for both on the smallest supported phone — measure the slack before designing the control. While reviewing, the board is not interactive, so the touch-target floor does not apply to it and it may give up height.

### 7.5 Matchmaking entry points

| Path | Behaviour | Creating | Accepting |
|---|---|---|---|
| Invite link or code | Share a link; whoever opens it joins | paid | **free** |
| Direct challenge | Challenge someone on your friends list | paid | **free** |
| Auto-match | Server pairs the nearest-rated waiting player | paid | paid |
| Open challenge board | Public list anyone may accept | paid | paid |

**Invite codes are bearer tokens**: enough entropy to resist enumeration, short expiry, single use, revocable, and checked against the creator's block list on join.

**Friendship is mutual.** Adding sends a request; friendship exists only once accepted. Friend requests carry **no free text** and are rate-limited, because an unfiltered request message is a chat channel that bypasses the chat preference. Display-name lookup is exact-match only and rate-limited.

This matters more than it looks: `friendsOnly` is the default chat preference, so if friendship were unilateral, anyone who added you would become a friend and the default would be defeated by the adder's own action.

Auto-match offers a similarly-rated computer opponent after a short wait rather than leaving a player queued against an empty population. That fallback creates a local computer game and does not consume the online cap.

**Backing out of the opponent list cancels the whole flow.** Falling back to a default opponent gives the player a game against somebody they did not choose, which is worse than no game.

### 7.6 Opponent selection

Twenty opponents is too many for a flat list on a phone. Present them as an **accordion by tier, opened at the tier containing the player's own rating** — where they are standing, not at the top or the bottom. Each row carries name, avatar, rating, tier description and blurb, and a marker for pairings that are lopsided (§5.1).

### 7.7 Profile view

Display name, avatar, human rating, record, head-to-head against the viewer, member-since. The computer rating is never shown to anyone but its owner.

Last-active is **coarsened** — "active this week", not a timestamp — and shown only to accepted friends. Combined with unique display names and add-by-name, a precise last-active is a presence-tracking capability against a named individual.

### 7.8 End of game

A result screen showing the highlighted line, the rating change on whichever ladder the game belonged to, and a one-tap rematch that swaps colours and the starting player. A pass-and-play result says plainly that no rating changed.

The rating change shown must be **the step that game caused**, folded from the prefix ending at it — not the step the most recent game caused. Those differ the moment a player opens an older finished game.

### 7.9 Tutorial

Shown once on first launch, restartable from settings. It covers the objective and what the 76 lines look like — with emphasis on the diagonals through layers that new players consistently miss — how the layered view maps to the cube, basic strategy, and an **interactive practice game with hints**.

Six things learned building it:

- **Draw the demonstrations on the real board widget.** A second, simplified illustration board is a second thing to keep correct, and it will drift.
- **Describe a demonstration board in one sentence**, not sixty-four cell labels. A screen reader reading out an entire empty board to reach the three interesting cells is worse than useless.
- **Strategy is a section of the one tutorial, not a second tutorial.** It was tempting to split; splitting produces two things a player must find.
- **Derive hints from the opponents' own rule ladder** rather than scripting them. The hint is then correct by construction in any position, and it is the same code the opponents use.
- **The practice game is never written down.** It is not on any ladder, has no opponent worth recording, and would otherwise appear in the player's history as a game they did not play.
- **Remember that the offer was declined, separately from completion.** Record the offer *before* showing it: a dialog dismissed by tapping outside returns no answer, and recording afterwards re-arms the offer on the next launch. Repeating a question the player has waved away is the failure mode to design out.

### 7.10 Accessibility

- **Pieces distinguishable without hue.** The two players' pieces differ by **lightness**, which survives every form of colour vision deficiency including full achromatopsia. Shape is an acceptable alternative, not a requirement. Whatever else the board does with colour — marking a move, highlighting a win — must not turn this into a hue distinction.
- **Every cell exposes a position-and-contents label** such as "Layer 2, row 3, column 1, empty".
- **A row that shows several facts announces them as one node**, not three. An avatar is decorative; a name and a state only mean anything side by side. Equally: whatever the eye can read from a shape must be *said* somewhere, and said **once** — a rating shown as a bar and a pill and announced twice is worse than never announced.
- **Announce changing state through a live region**, attached to the message rather than to the space reserved for it. A live region wrapped around an empty placeholder announces nothing, repeatedly.
- **System font scaling is respected**, and every screen must reach its last row at the largest setting.
- **Light and dark themes**, both readable.

### 7.11 Settings

Language (system, or an explicit choice), theme (system, light, dark), a way to see the tutorial again, and the attribution required by §6.6.

**Language and theme are watched at the root of the app** and applied immediately, without a restart. "System" is the *absence* of an override, not a third value to translate into one.

---

## 8. Chat and safety

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

## 9. Notifications

Your turn, new message, game ended, challenge received — each individually toggleable.

**Firebase Cloud Messaging does not support Flutter on Windows or macOS.** Web push requires an explicit grant and, on iOS Safari, home-screen installation. Push is a mobile feature; web and desktop degrade to in-app notification and a badge while the app is open. **The app must say so**, because a desktop-only player would otherwise be silently forfeited by the 7-day rule.

---

## 10. Technical architecture

### 10.1 Stack

Flutter for the client — iOS, Android, Web, Windows, macOS. Firebase for the backend from 0.3a: Authentication, Firestore, Cloud Functions, Cloud Messaging.

**Structure the code as a Flutter app over pure-Dart packages**: the rules, search and opponents in one, the rating maths in another, both with **no dependency on Flutter, on any I/O library, on an ambient clock or on an ambient random source, and no runtime dependencies at all**.

**Enforce that mechanically.** Ours is a grep in the build gate over each package's manifest and imports. Purity that is merely intended lasts until the first convenient import.

### 10.2 The build gate

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

### 10.3 Layering on the device

A **document store** (bytes: file or in-memory) sits under a **repository** (rules: completion, validation, ordering). The store is the pluggable part, not the repository — swapping the repository in tests would test a path the app does not use, while swapping the store keeps every rule under test.

Make the repository **stream-based rather than future-based**, so the cloud implementation satisfies the same contract without a UI rewrite.

**Game completion is decided in the repository**, once, not by each caller.

### 10.4 Authority model, from 0.3a

The client computes and renders moves immediately so play feels instant. A Firestore-triggered Cloud Function re-validates every move, detects the win, and writes the result and the rating change.

A client may write **only** its own move to a game it is in when it is its turn, its own chat messages, and a named list of its own profile fields. A client may **never** write results, either rating, entitlement, totals, timestamps, or another player's data. The allowlist is **field-level, not document-level** — "its own profile fields" would otherwise permit exactly the writes that sentence forbids.

**The security rules are the trust boundary, so they are a tested deliverable, not configuration**: their own ticket and an adversarial suite in CI where every test is an attempt that must be *denied*.

The rules logic exists in two places — Dart on the client and in the validating function — and both must be driven by the same 76-line definition and the same shared test vectors, or they will drift.

### 10.5 Data model

**Store the simplest correct thing.** For the offline releases specifically:

- **No device identifier at all.** None is generated, stored or transmitted. This is not merely a privacy nicety — it removes an entire class of question about what a backup contains.
- A game records a seat that is the player, a named opponent, an ordered list of cell indices, who started and why, and — when finished — the outcome, the reason, the winning line, the completion time, and the opponent's anchor rating.
- Whose move it is derives from position in the list and the starting seat. No per-move author, id or timestamp.
- Statistics are derived, never stored.

Local storage is **never retired**. Offline games stay local for the life of the app; online games live in the cloud. Two implementations serving two kinds of game, not one replacing the other. **There is no import path from local to cloud, ever** — that decision removed the single largest source of complexity and risk in the whole plan.

There is deliberately **no server-side copy of the opponent catalogue**. Computer play never touches the network, so it would be a second source of truth for something the server never uses.

Android auto-backup is left **on**, so players do not lose history when they replace a device, with an **explicit allowlist** rather than the platform default. It follows that **"no data leaves the device" must never appear in any privacy text** — it is false, and the backup is a deliberate trade.

### 10.6 Localisation

English and Dutch, both complete at launch, English the fallback. All strings in resource files from the first commit. Bot names are not translated; blurbs are.

### 10.7 Identity

The application id is **permanent** from the first upload to any track, including closed testing. A different id is a different app, with its own listing and its own install base. Choose it against a domain you control, and never ship the scaffolding default — stores reject `com.example.*`.

Four places must agree: the application id, the build namespace, the source package, and the directory mirroring it. A mismatch is a crash on launch rather than a build error.

---

## 11. Release plan

The ordering matters more than the dates, and this ordering was arrived at by correcting an earlier one.

| Release | Contains | Public |
|---|---|---|
| **0.1** | The complete offline game: board, all twenty opponents, computer rating, history and replay, tutorial, settings, both languages | no — closed test |
| **0.2** | Real art, large-screen layout, polish | no |
| **0.3a** | Anonymous auth; a cloud repository passing the *identical* flow tests as the local one; one async game between two of the developer's own devices. No push, no rating, no functions | no |
| **0.3b** | Invite links, push, block/report/name validation, account deletion, privacy policy | **first public release** |
| **0.4** | Human rating **and** server-side move validation, together. Subscription | yes |
| **1.0** | Roster revision, remaining platforms | yes |

**Why 0.1 is a complete game rather than a demo.** It costs a larger first release and buys something to actually test. A move-history scrubber, a result screen, statistics and replay are all cheap given an append-only move list.

**Why 0.3 is split.** Without the split, the first public release is also the first release in an unfamiliar stack, with no prior public exposure to learn from. 0.3a proves the layering privately; 0.3b opens the contact surface.

**Why the human rating waits for 0.4.** It ships with the validation that makes it trustworthy, because they are the same feature (§5).

**Run the store's closed-testing requirement early.** Google Play requires a personal account to run a closed test with twelve testers for fourteen continuous days before granting production access. Run that clock during 0.1, where the testers are the distribution channel anyway, rather than during the hardest release at the worst moment.

**First success is twelve real people playing 0.1 on their own devices, with the release pipeline proven end to end** — signed builds, both testing channels, production access unlocked. Not "an app in the store".

---

## 12. Definition of done

1. The 76-line table is generated once, and win detection returns the specific completed line. Verified exhaustively.
2. A game can be played to a win and to a draw in all four modes.
3. Client and validating function agree on every move of a shared corpus of full games.
4. All twenty opponents exist, are distinguishable in play, and are calibrated by a self-play harness that reports measured against published strength.
5. The top opponent's advertised strength matches what it delivers, and the interface never claims perfection it cannot deliver from both seats.
6. Both ratings update correctly and independently — provisional K, draws, forfeits, the floor. The computer rating is derived from stored games, never stored, and never leaves the device; the human rating is never written by a client.
7. Async games expire correctly, with a warning first.
8. All four matchmaking paths create playable games.
9. Chat works with block, report and profanity filtering, honours the more restrictive of the two preferences, is revocable, and fails closed on records that predate it.
10. All three subscription products purchase and restore, gate *initiation* while leaving acceptance free, and a lapse lets existing games finish and rate, blocks new ones, exempts from forfeit, and permits one rematch in a series.
11. Entitlement cannot be written by any client and is revoked on refund or chargeback.
12. The security rules pass an adversarial suite in which every attempt is denied.
13. Account deletion and data export work in-app, and deletion states it does not cancel the subscription.
14. An account is linked before its first rated game or purchase.
15. Both layouts render on phone and large screen, in both themes, at the largest font scale.
16. The board is playable and legible for a colourblind player and navigable by screen reader, and every fact shown visually is announced exactly once.
17. The tutorial runs end to end, including the practice game, which is never stored.
18. Every string exists in English and Dutch, enforced by the build.
19. Notification limitations on web and desktop are surfaced.
20. The release build declares no networking permission, enforced by the build.

---

## 13. What is still open

Every item here is a business or account decision. **None is functional, and none blocks building the game.**

| Item | Why it is open |
|---|---|
| **Subscription price** | Determines whether monthly is needed and how long the trial should be. Needed before 0.4, not before code. |
| **Store accounts and signing** | Requires the owner's Google and Apple accounts. The application id must be chosen before the first upload and is permanent thereafter (§10.7). |
| **App name availability** | Checked against both stores and trademark registers. Not yet done. |
| **The reference device** | The twenty-second ceiling (§6.8) is a device number, and the node-to-seconds conversion must be confirmed on real hardware. |
| **Two Casual-tier rating inversions** | Kestrel measures above Willow, and Finch above Kestrel, by about 40 points each. This is **not** a configuration defect and no parameter change closes it: the roster pins `aggression` in the direction that opens the gap (§6.5), and the blunder rate cannot spread far enough because it must fall as rating rises between Bramble's 0.15 and Ember's 0.08. The fix is a roster change, owned by 1.0. A rebuilder starting from this document should instead design the Casual tier so that its personalities and its rungs agree — see the note in §6.5. |

**Things v1 listed as open that are now closed:** push on desktop and web (§9 — a stated platform limitation, not a problem to solve); the size and obtainability of the strategy book (§6.6 — 54,745 bytes, published, permissively granted); anchor calibration (§6.7 — a built harness); auto-match cold start (§7.5 — a computer opponent after a short wait); and the per-game Firebase cost, which is negligible in steady state now that the migration burst that dominated it no longer exists.

---

## 14. Sources

The game is public, old, and thoroughly analysed. Nothing about its mathematics needs deriving.

- **Wikipedia, "3D tic-tac-toe"** — https://en.wikipedia.org/wiki/3D_tic-tac-toe — line counts, cell degrees, automorphism count, solution history.
- **R. Silver (1967)** — established the group of 192 automorphisms.
- **Eugene Mahalko (1976)** — weak solution: a first-player win exists.
- **Oren Patashnik (1980)** — "Qubic: 4 × 4 × 4 Tic-Tac-Toe", *Mathematics Magazine* 53(4), 202–216. The complete first-player-win strategy, computer-assisted, about 1,500 hours, roughly 2,929 stored strategic positions. **Method and proof, not the dataset**, and copyrighted — read it to understand the forcing-move machinery, do not ship content from it.
- **Victor Allis** — independent solution by proof-number search.
- **`qubic.dictionary`** — the strategy data itself, carrying its own permissive grant. See §6.6 for the obligations that come with it.

**The licensing judgement in §6.6 is the implementer's to confirm.** What this document records is what the file says and what the build does about it. It is not legal advice.
