# Quadrim — Final Specification

The unambiguous description of what Quadrim is and what v1 must do.
Derived from [idea-v0.md](history/idea-v0.md); every choice is justified in [idea-v1-decisions.md](idea-v1-decisions.md).

Status: agreed. No code written yet.
Date: 2026-07-27

---

## 1. What Quadrim is

Quadrim is a two-player game played inside a 4×4×4 cube of 64 cells. Players alternate placing a piece of their own colour on any empty cell. The first player to occupy all four cells of any straight line wins. Lines run along the axes, diagonally within a flat plane, and diagonally through the body of the cube. If all 64 cells fill with no line completed, the game is drawn.

The game is known publicly as Qubic, or 3D tic-tac-toe. It is a solved game: with perfect play the first player wins. This fact shapes several decisions below and is not treated as a defect.

A player can play another human — asynchronously over days, or in real time — or any of twenty computer opponents, each with a name, an avatar, a play style, and a fixed rating.

---

## 2. Board and coordinates

A cell is `(x, y, z)` with each coordinate in `0..3`. `z` is the layer index, `0` nearest the viewer. The canonical scalar index is `x + 4y + 16z`, giving `0..63`.

### 2.1 The 76 winning lines

Exactly 76 lines win. They are generated as:

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

This table is precomputed once as a constant list of 76 four-element cell sets. It is the single shared source of truth for win detection, threat detection, the computer engine's evaluation, the tutorial's line illustrations, and the server-side validator. Nothing in the system may enumerate lines independently.

The construction above matches the published analysis exactly: 48 lines parallel to an edge, 24 parallel to a face diagonal, 4 body diagonals (§14).

### 2.2 Cell degree — how many lines each cell sits on

Not every cell is worth the same, and the difference is exact rather than a matter of taste:

| Cell class | Count | Winning lines through it |
|---|---|---|
| Corner cells | 8 | **7** |
| Inner cells (the central 2×2×2) | 8 | **7** |
| Face cells | 24 | 4 |
| Edge cells | 24 | 4 |

Sixteen cells sit on seven lines each; the other forty-eight sit on four. Corner and inner cells are **equivalent under the game's symmetries** — they are one class, not two.

This is a shared constant, emitted by the same generator as the line table, and it is what the positional rules in §6.3 are actually expressing.

### 2.3 The symmetry group

The board has **192 automorphisms**. They combine the familiar rotations and reflections with two less obvious operations that reorder cells along every line at once — swapping inner cells for outer ones, and permuting within those pairs (§14).

Two consequences the engine should exploit:

- A position can be **canonicalised** to a representative of its symmetry class, which collapses up to 192 distinct positions into one. That shrinks a transposition table and any stored strategy proportionally.
- The opening is far smaller than it looks: an empty board has only **two** genuinely distinct first moves — a 7-line cell or a 4-line cell — not 64.

### 2.4 Placement

Every empty cell is always legal. There is no gravity, no adjacency requirement, no reserved or blocked cell, and no handicap. Legal-move generation is "the set of empty cells".

---

## 3. Rules of play

1. The board starts empty.
2. Two players hold distinct colours. Turns strictly alternate.
3. On a turn, the player to move places one piece on any empty cell.
4. A placement completing any of the 76 lines with four pieces of the mover's colour ends the game immediately as a win for that player. The completed line is recorded and highlighted.
5. If the 64th piece is placed with no line completed, the game is a draw.
6. Either player may **resign** at any point on or off turn, losing immediately.
7. There are **no takebacks and no undo**, in any mode, including against computer opponents. A submitted move is final.
8. There are **no draw offers**. A game ends by four-in-a-row, a full board, resignation, or timeout — nothing is negotiated. A player who wants out of a dead position resigns.
9. Move history is append-only and complete, which makes every game replayable.

A game's terminal state therefore records an **outcome** — win or draw — and a separate **reason**: line, full board, resignation, timeout, or abandonment. The two are separate because a clock-driven ending cannot be derived from the moves.

### 3.1 First move

The starting player is chosen at random for the first game between a given pair of opponents. In a rematch the other player starts. Colour follows starting order. The game record stores who started.

### 3.2 Time and abandonment

| Mode | Clock | Expiry |
|---|---|---|
| Async online | none | reminder at 5 days of inactivity; forfeit by the player to move at 7 days |
| Real-time online | 60 seconds per move | forfeit on expiry |
| Vs computer | none | never |
| Pass-and-play | none | never |

Forfeits are recorded as ordinary losses and update ratings normally. Both timers are enforced server-side; a client clock is display only.

---

## 4. Game modes

| Mode | Opponent | Network | Affects | Needs a subscription |
|---|---|---|---|---|
| Async online | human | yes | Human rating | only to *initiate* — see §4.1 |
| Real-time online | human | yes | Human rating | only to *initiate* |
| Vs computer | one of 20 opponents | **never** | Computer rating | no |
| Pass-and-play | human, same device | no | Nothing | no |

Async and real-time share one game-state model and one move pipeline. Real-time adds only the per-move clock and opponent presence.

Pass-and-play affects no rating because the second party is unauthenticated and the result is therefore unverifiable.

A player may hold at most **20 simultaneous active games against human opponents**. Computer games are uncapped. Exceeding the cap produces a clear message.

### 4.1 Access and subscription

**Everything release 0.1 shipped is free, forever.** All twenty computer opponents, the tutorial, pass-and-play, local history and statistics, and the computer rating. No ads, no time limit, no feature held back. This is a complete game on its own.

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

The line is drawn here because invite links are the only way a new person ever reaches this app. Charging the *recipient* means a friend's invitation arrives as a sales pitch, and the one growth loop the product has is throttled at its highest-intent moment. It also keeps the anti-abuse benefit: auto-match and the open challenge board are the surfaces a throwaway account would farm, and both stay paid.

Three products, sold through the App Store and Google Play:

| Product | Behaviour |
|---|---|
| Annual | Auto-renewing yearly, with a store-native free trial |
| Monthly | Auto-renewing monthly |
| One year, non-renewing | A single year, no recurring charge |

**The price is not yet decided.** It is an open decision that must be made before 0.4, not an implementation detail — it determines whether monthly is needed and how long the trial should be.

**When a subscription lapses:**

- Games already in progress play to the end and **rate normally for both players**. "Frozen" means no new rated games can be *started*, not that results stop counting — an asymmetric rating update would inflate the ladder for whoever happened to be playing a lapsed opponent.
- A lapsed player may accept one rematch of a series already in progress, so a billing date cannot deny them the first move that §3.1's alternating rule owes them.
- A lapsed player is **exempt from the inactivity forfeit** in their remaining games. A billing event must never hand someone a forfeit win.

Entitlement is checked when a game is **created and when one is joined** — never on a move, so that the lapse behaviour above works. It is a server-written field that no client can touch, set only after receipt validation, and revoked on refund, chargeback or a voided purchase.

The developer never handles payment instruments: both stores are merchant of record. No direct payment path is ever added.

---

## 5. Rating

A player has **two independent ratings**. Neither influences the other.

| | Computer rating | Human rating |
|---|---|---|
| Earned against | The 20 computer opponents | Real opponents only |
| Computed | On the device | On the server |
| Stored | On the device | In the cloud, with the account |
| Visible to | Only that device's owner | The player and their opponents |
| Requires | Nothing | A linked account (§8) |
| Arrives in | 0.1 | 0.4 |

Both use the same maths:

- Seed: **1200**
- K-factor: **32** for a player's first 20 rated games on that ladder, **16** thereafter
- Score: win 1, draw 0.5, loss 0
- Expected score: `E = 1 / (1 + 10^((R_opponent − R_self) / 400))`
- Update: `R' = round(R + K × (S − E))`
- Floor: 100

Computer players have **fixed** ratings that never change. They are anchors on the computer ladder: a player's computer rating moves after a game, the opponent's does not. All 20 are calibrated together before release, against each other and against real testers.

**Why the split.** The two ratings measure different things under different trust models. A rating earned against a deterministic opponent on your own hardware cannot be verified by anyone and does not need to be — editing it cheats only yourself, and nobody else can see it. A rating earned against another person in a competitive ladder must be trustworthy. Conflating them forced the worse property of each onto the other.

The human rating is computed exclusively on the server; no client ever writes it. The computer rating is computed only on the device and never leaves it — which also means it does not follow a player to a different platform.

**The human rating arrives at 0.4, not with the first online play at 0.3b.** It ships together with the server-side move validation that makes it trustworthy, because the two are the same feature: without validation, a modified client can author a legal, replayable game naming any opponent and move that opponent's rating without them ever opening the app. Replay proves legality, never authorship, so a rating recomputed later from unvalidated move lists would faithfully reproduce every fabrication. Release 0.3b therefore ships online play with a win/loss/draw record and no rating — and nobody has a rating to lose, because nobody has one yet.

Because a rating is worth losing, it also requires a **linked account** (§8). An anonymous account vanishes with the device.

---

## 6. Computer players

### 6.1 One engine, twenty configurations

All twenty bots are configurations of a single engine. The parameter axes are:

| Axis | Meaning |
|---|---|
| `searchDepth` | plies of alpha-beta search; 0 means no search |
| `rules` | which strategic rules are enabled (see 6.2) |
| `blunderRate` | probability per move of discarding the best move for a weaker legal one |
| `positionalBias` | weighting of centre 2×2×2 cells versus corners versus edges |
| `aggression` | relative weight of building own threats versus blocking the opponent's |
| `randomness` | temperature applied when breaking ties among equal moves |

A bot's personality must be **visible at the board**, not only in its description. An "aggressive" bot must demonstrably build before it blocks.

### 6.2 Strategic rules, evaluated in order

Taken from the original idea document and treated as the canonical rule ladder. As soon as a rule matches, the bot plays there. If several cells satisfy the same rule, the tie is broken by the positional rules in 6.3.

1. Is there a cell that gives the bot four in a row immediately? Play it.
2. Is there an empty cell where the opponent would get four in a row next move? Block it.
3. Is there an empty cell creating two separate lines of three, each with its fourth cell still empty? Play it — this is an unstoppable double threat.
4. Is there an empty cell that would let the opponent create such a double threat? Deny it.

### 6.3 Positional rules, evaluated in order

Applied when no strategic rule fires, and as the tie-break within a rule.

1. Prefer an available cell inside the central 2×2×2 cube.
2. Otherwise prefer a cube corner.
3. Among candidates, choose the cell lying on the greatest number of lines that already contain two or more of the bot's own pieces and none of the opponent's.
4. If still tied, choose at random.

**Why these rules work, and a correction they imply.** Rules 1 and 2 are folk wisdom that turns out to be exactly right for a measurable reason: the eight inner cells and the eight corners are the sixteen cells sitting on **seven** winning lines each, against four for every other cell (§2.2). The rules are a hand-written approximation of "prefer high-degree cells".

But the two are **the same class** — inner and corner cells are equivalent under the board's symmetries — so ranking centre strictly above corners is a distinction the game does not make. Implement the ladder as written, because the roster's personalities are defined against it and `positionalBias` deliberately lets opponents weight them differently. Just record that a bias favouring centre over corners is a *flavour* choice, not a strength one.

### 6.4 The roster

Twenty opponents across five tiers. **The ratings below are fixed** — they are the anchor a player's computer rating is earned against, so they do not move (D144). Each opponent's *actual* strength is an approximate estimate at 0.1; where it disagrees with the published number, the opponent's configuration is what gets corrected, not the number.

**Novice**

| Name | Rating | Behaviour |
|---|---|---|
| Pebble | 600 | Purely random legal moves. Never notices a threat. |
| Twig | 700 | Random, but takes an immediate win when one is available. |
| Mote | 800 | Wins and blocks when it sees them, misses them 40% of the time, otherwise random. |
| Clover | 900 | Wins and blocks, 20% blunder rate, drawn to corners. |

**Casual**

| Name | Rating | Behaviour |
|---|---|---|
| Bramble | 1000 | All four strategic rules, 15% blunder rate, no positional sense. |
| Finch | 1100 | Strategic rules with a strong centre preference, 12% blunder rate. |
| Kestrel | 1200 | Strategic rules, corner-hungry and aggressive — ignores opponent double threats about a third of the time. |
| Willow | 1250 | Defensive: blocks before it builds. 10% blunder rate. |
| Ember | 1300 | All four strategic rules cleanly applied, 8% blunder rate, no positional heuristic. |

**Club**

| Name | Rating | Behaviour |
|---|---|---|
| Basalt | 1400 | Strategic plus full positional rules, 6% blunder rate. |
| Marlin | 1500 | Basalt plus 2-ply search, aggressive weighting, 5% blunder rate. |
| Vireo | 1550 | Basalt plus 2-ply search, defensive weighting, 4% blunder rate. |
| Onyx | 1650 | 4-ply alpha-beta over the heuristic evaluation, 3% blunder rate. |
| Sable | 1700 | 4-ply plus dedicated threat-space search for double threats, 2% blunder rate. |

**Expert**

| Name | Rating | Behaviour |
|---|---|---|
| Quartz | 1800 | 6-ply alpha-beta with a transposition table, 1.5% blunder rate. |
| Corvus | 1900 | 6-ply with threat-space search and a centre-first opening preference, 1% blunder rate. |
| Lyra | 2000 | 8-ply iterative deepening, 0.5% blunder rate. |
| Titan | 2100 | 8-ply plus exact solving once few cells remain. No deliberate blunders, no opening book. |

**Master**

| Name | Rating | Behaviour |
|---|---|---|
| Oracle | 2300 | Opens from the strategy book, so it cannot be beaten when it moves first. Falls back to a shallower search than Prime's from the second seat, which is the only place the two differ. |
| Quadrim Prime | 2400 | The strongest opponent. Unbeatable when it moves first; defends by the deepest search in the game when it moves second. **Not perfect** — the proof it follows covers the opening player only (D181). |

Every bot has a shipped avatar and a one-line personality blurb, translated into every supported language. Bot names are not translated.

### 6.5 Quadrim Prime and what "perfect" means

Quadrim Prime plays perfectly. Because Quadrim is a solved first-player win, **Prime cannot be beaten when it moves first** — that is a property of the game, not a bug, and the UI should say so plainly rather than implying the player can win every matchup. Moving second, Prime plays optimal defence: a perfect opponent draws it, an imperfect one loses.

Perfection is achieved by a **build-time solver** that precomputes the proven winning strategy and ships it as a compressed asset. At runtime Prime follows the book, and switches to exact search once the remaining position is small enough to solve outright. Deep alpha-beta alone is very strong but not perfect, and runtime proof search is far too slow on a phone.

The solver is a separate build-time deliverable, not part of the app.

### 6.5.1 This has already been solved — twice

The strategy does not have to be invented. See §14 for sources.

- **1976 — Eugene Mahalko** weakly solved the game: proved a first-player win exists, without producing the strategy.
- **1980 — Oren Patashnik** published a complete first-player-win strategy, via a computer-assisted proof costing about **1,500 hours** of contemporary computer time. Independently verified.
- **Later — Victor Allis** solved it again independently, using **proof-number search**.

Three details change this project's estimate materially:

**The strategy is about 2,929 positions, not an unbounded artefact.** Patashnik's result is a set of move choices for roughly 2,929 difficult "strategic" positions; everything else is reachable by sequences made entirely of *forcing* moves. That is a small dataset — kilobytes, not megabytes — and it means the shipped asset is far smaller than "a proven winning strategy" suggests. Under symmetry canonicalisation (§2.3) it is smaller still.

**Most of the work is forcing-move search, which the engine already needs.** If only ~2,929 positions require a stored choice, the runtime job is largely threat and forcing-sequence search — precisely the threat-space search the Club tier already builds. The book covers the hard branch points; the engine plays the rest.

**The positions were reportedly published online.** If they can be obtained, verified and licensed, the build-time "solver" becomes an *acquire-verify-encode* task rather than 1,500 hours of original computation.

**The 1980 paper is not that source.** It runs to fifteen pages (Math. Mag. 53(4), 202–216) and contains the method, the proof and the categorisation — not a dataset of thousands of positions, which could not fit. It is also a copyrighted article distributed under JSTOR terms: reading it to understand the method is fine, shipping content from it is not. Read it for the forcing-move machinery, which is the shape of the runtime engine, and as a reference to verify against.

**Preferred route: re-derive it.** Proof-number search is documented and reproducible, what took 1,500 hours in 1980 is a modest run on a modern desktop, and the symmetry reduction in §2.3 shrinks it further. Decisive advantage: **data derived in-house carries no licence question** — it can be shipped outright, and the published result becomes an independent cross-check rather than a dependency.

**What this does not solve.** Patashnik's strategy is for the **first player**. Moving second, Prime has no book to follow — its optimal defence still comes from search. And "weakly solved" means the strategy wins, not that every position carries a stored evaluation.

**Effect on the plan:** OI-02 stops being an unbounded research task and becomes a bounded verification one — obtain the data, confirm it against an independent implementation, check its licence. Prime still ships on rung 2 until that verification succeeds, because an unverified dataset is not a proof, but rung 1 is now considerably more likely and considerably cheaper than assumed.

**Fallback ladder**, in order (see open item OI-02):

1. Book plus exact endgame — the target, and what Prime becomes at 1.0.
2. Exact endgame plus deepest achievable search, described as extremely strong rather than perfect.
3. Titan promoted to top opponent, Prime withdrawn from the roster.

**Prime ships on rung 2 and stays there until the solver exists.** The full roster is present from the first release so that all twenty can be calibrated together, but the solver is an unbounded research task that must not sit ahead of a playable game. Until it lands, Prime is advertised as extremely strong, not perfect, and its rating is recalibrated when it is upgraded — cheap to do, because computer ratings are device-local (§5).

Claiming perfection the engine does not deliver is not an option.

---

## 7. User interface

### 7.1 Layout policy

The breakpoint is the **shortest side of the window**.

| Form factor | Threshold | Orientation |
|---|---|---|
| Phone | shortest side < 600 dp | portrait only, locked |
| Large screen | shortest side ≥ 600 dp | landscape only, locked |

On desktop, resizing a window can cross the breakpoint mid-game, so both layouts must survive a live rebuild without losing game state.

### 7.2 Main screen

- Statistics for completed games: wins, losses, draws, and both ratings — the computer rating always, the human rating once a subscription exists
- List of active games, each showing opponent, whose turn it is, and time remaining where applicable
- A large, primary "new game" button
- A button to launch the tutorial
- List of completed games, each opening into replay

Starting a new game offers: play a human, or play a computer opponent. Choosing human offers the four matchmaking paths in 7.6. Choosing computer shows the roster of twenty with names, avatars, ratings, and personality blurbs.

### 7.3 Game screen — phone (portrait)

- Opponent name above the board; tapping it opens their profile
- The board
- Against a human, a button opening a chat screen
- Move-history scrubber

### 7.4 Game screen — large screen (landscape)

- Board on the left
- On the right: the player's own profile and the opponent's, with general information and head-to-head statistics
- Chat inline on the right, not on a separate screen
- Move-history scrubber

### 7.5 The board

All four layers are drawn at once as parallelograms suggesting depth, so the entire cube is visible without rotation. Occupied and empty cells must be unmistakably distinguishable at a glance.

A move is a **single tap on an empty cell**. No confirmation step. Touch targets must remain finger-sized on the smallest supported phone, which constrains how much perspective skew the layers can carry.

The move-history scrubber steps back and forward through every move of the current game and of any completed game. Scrubbing is read-only; it never alters the game.

When a game ends, the completed line is highlighted on the board. Win detection therefore returns *which* line completed, not merely that one did.

### 7.6 Matchmaking entry points

| Path | Behaviour | Creating | Accepting |
|---|---|---|---|
| Invite link or code | Create a game, share a link or code; whoever opens it joins | paid | **free** |
| Direct challenge to a friend | Challenge someone on your friends list | paid | **free** |
| Auto-match | Join a queue; the server pairs the nearest-rated waiting player | paid | paid |
| Open challenge board | Public list of open games anyone may accept | paid | paid |

**Invite codes are bearer tokens and are specified as such:** enough entropy to resist enumeration, short expiry, single use, revocable by the creator, and checked against the creator's block list on join. A guessable code is a way into strangers' games, and with it their profile and — where both allow it — a chat channel.

**Friendship is mutual.** Adding someone sends a request; friendship exists only once it is accepted. Unfriending revokes it immediately and a block removes it. Friend requests carry **no free text** and are rate-limited per sender, because an unfiltered request message would be a chat channel that bypasses the chat preference entirely. Display-name lookup is exact-match only and rate-limited, returning only what is needed to send a request — not the full profile.

This matters more than it looks: `friendsOnly` is the default chat preference, so if friendship were unilateral, anyone who added you would become a friend and the default would be defeated by the adder's own action.

Auto-match should offer a similarly-rated computer opponent after a short wait rather than leaving a player queued against an empty population. That fallback creates a local computer game on the computer ladder — it is not an online game and does not consume the online cap.

### 7.7 Profile view

Display name, avatar, human rating, win/loss/draw record, head-to-head record against the viewer, and member-since date. The computer rating is never shown to anyone but its owner.

Last-active is **coarsened** — "active this week" rather than a timestamp — and shown only to accepted friends. Combined with globally unique display names and add-by-name, a precise last-active is a presence-tracking capability against a named individual.

Head-to-head totals are maintained incrementally by Cloud Function, not recomputed by scanning history.

### 7.8 End of game

A result screen showing the highlighted winning line, the rating change on whichever ladder the game belonged to, and a one-tap rematch that swaps colours and the starting player. A pass-and-play result shows no rating change, because it affects none.

### 7.9 Tutorial

Shown automatically on first launch, restartable at any time from the main screen. Four parts:

1. **Rules and lines** — the objective, and what all 76 winning lines look like in the layered view, with emphasis on the diagonals spanning layers that new players consistently miss
2. **Controls and board reading** — how the four parallelograms map to the cube, how to tap, how to scrub history
3. **Basic strategy** — the value of centre and corner cells, building a double threat, blocking
4. **Interactive practice game** — a guided game against a scripted opponent, with hints

Parts 1 and 4 require real features: line illustration on the board, a scripted-opponent mode, and a hint overlay.

### 7.10 Accessibility

- **Pieces distinguishable without hue.** The two players' pieces must differ by something other than hue alone — the whole game is "my piece against yours", and hue-only encoding excludes roughly one man in twelve. **Lightness satisfies this**, and a light piece against a dark one is the strongest available signal: it survives every form of colour vision deficiency including full achromatopsia, which two shapes in similar tones would not. Shape is an acceptable alternative, not a requirement.
- **Screen reader support.** Every cell exposes a semantic label such as "layer 2, row 3, column 1, empty". Game state, whose turn it is, and the result are announced.
- **Scalable text and large targets.** System font scaling is respected; cells stay finger-sized on small phones.
- **Light and dark themes.** Board and pieces readable in both.

---

## 8. Chat and safety

Free-text 1:1 chat, available only between the two players of a shared game and only while that game exists in history. No chat with computer players, no group chat, no global chat.

**Chat is opt-in per player, and the more restrictive preference wins.** A setting offers three values — chat in **every game**, **friends only**, or **never** — defaulting to friends only. The choice can be overridden for one specific game in the start-a-game flow.

Chat exists for a game only if **both** players allow it for that game. This matters because chat permission otherwise derives from game membership, which would mean that creating a game against a stranger implicitly opens a channel to them.

Availability is resolved when the game is **accepted**, not when it is created — three of the four matchmaking paths give the joiner no start-a-game flow, so resolving at creation would silently ignore their preference. The joiner gets the same per-game override the creator does, and both are shown whether chat will be available, and why not when it will not be.

It stays revocable. Either player can turn chat off in an existing game; switching the global preference to `never` clears it across every active game; and blocking terminates it immediately. A game record with no chat field means chat is unavailable, so games created before chat existed fail closed.

Required safety features:

- **Block a player** — blocked players cannot message, challenge, invite, accept your invites, or see your profile. The block is checked **in the game-creation and invite-acceptance path**, not only when a message is sent
- **Report a player or a message** — routed for review
- **Profanity filtering** — server-side, applied before a message is delivered

**Block, report, and server-side display-name validation ship at 0.3b, one release before chat.** They are contact-surface features, not chat features, and 0.3b is what opens the contact surface: invites, profiles, push, and user-chosen display names visible to strangers.

Display names are globally unique, validated server-side against a profanity list, and immutable for 30 days after each change so name-swapping cannot be used to evade blocks.

**Accounts are linked before they are worth anything.** Anonymous authentication is enough to try online play at 0.3b, but before a first rated game or any purchase the account must be linked to Google, Apple or email. An anonymous account cannot be recovered when the device is lost, and a data-subject request against one cannot be verified — there is no way to establish that the person asking is the person whose data it is. Offering third-party sign-in on iOS requires Sign in with Apple alongside it.

**Account deletion and data export** are both available in-app; they are the same traversal in opposite directions. Deletion removes personal data — display name, avatar choice, chat messages, authored reports — while retaining game records with the identity replaced by an opaque per-game token, so opponents' rating histories remain coherent. Deletion must state plainly that **it does not cancel the store subscription**, which is a common review rejection.

---

## 9. Notifications

| Trigger | Event |
|---|---|
| Your turn | The opponent has moved |
| New chat message | The opponent sent a message |
| Game ended | Win, loss, resignation, or timeout |
| Challenge received | An invite or an accepted open challenge |

Each is individually toggleable in settings.

**Platform limitation.** Firebase Cloud Messaging does not support Flutter on Windows or macOS. Web push requires an explicit browser permission grant and, on iOS Safari, home-screen installation. Push is therefore a mobile feature; web and desktop degrade to in-app notification and a badge on the active-games list while the app is open. The app must say so, because a desktop-only player would otherwise be silently forfeited by the 7-day rule.

---

## 10. Technical architecture

### 10.1 Stack

Flutter for the client, targeting iOS, Android, Web, Windows, and macOS. Firebase for the backend: Authentication, Firestore, Cloud Functions, and Cloud Messaging.

### 10.2 Authority model

The client computes moves and renders them immediately so play feels instant. A Firestore-triggered Cloud Function re-validates every move, detects the win, and writes the result and the rating change.

A client may write **only**:
- its own move appended to a game it is a participant in, when it is that client's turn
- its own chat messages
- these profile fields, and no others: display name, avatar id, notification toggles, chat preference

A client may **never** write game results, either rating, subscription entitlement, win/loss/draw totals, provisional counts, timestamps, or opponents' data. The allowlist is **field-level, not document-level** — "its own profile fields" would otherwise permit exactly the writes the sentence above forbids. Enforced by Firestore security rules.

**Those rules are the trust boundary, so they are a tested deliverable, not configuration.** They get their own ticket and an adversarial emulator suite in CI in which every test is an attempt that must be *denied*: writing another player's game, overwriting an existing game id, writing a result or a rating or an entitlement, appending two moves in one write, moving out of turn, exceeding the game cap.

The rules logic exists in two places — Dart on the client, and in the validating function. Both must be driven by the same 76-line definition and covered by the same shared test vectors, or they will drift apart.

### 10.3 Data model sketch

Provisional; refined during planning.

| Collection | Holds |
|---|---|
| `players` | profile, avatar id, human rating, provisional game count, W/L/D totals, subscription entitlement, timestamps |
| `players/{id}/blocks` | blocked player ids |
| `games` | participants, mode, colours, who started, move list, state, result, winning line, clock/expiry fields |
| `games/{id}/messages` | chat messages |
| `headToHead` | per-pair aggregate record |
| `matchQueue` | waiting auto-match entries |
| `challenges` | open and directed challenges |
| `reports` | user reports awaiting review |

There is deliberately **no `bots` collection**. The twenty computer opponents are code-side constants; computer play never touches the network, so a server-side copy of their configuration would be a second source of truth for something the server never uses.

Pass-and-play and computer games are stored locally on the device and are never written to Firestore. Only games against real opponents reach the cloud.

### 10.4 Scheduled work

A scheduled Cloud Function sweeps for async games that have crossed the 5-day warning and 7-day forfeit thresholds, and for real-time games whose 60-second move clock has expired.

### 10.5 Localisation

English and Dutch, both complete at launch. English is the fallback locale. All user-facing strings live in ARB resource files from the first commit; no string is ever hard-coded. Bot names are not translated; personality blurbs are.

---

## 11. Explicit non-goals for v1

Named so that nobody builds them by accident:

- No ads, ever. The only payment path is the subscription in §4.1 — no consumables, no cosmetics, no pay-to-win
- **Everything release 0.1 shipped stays free forever**: all twenty opponents, the tutorial, pass-and-play, local history and statistics, and the computer rating. This is the promise made to the people who install the free game. It is deliberately *not* the broader "nothing offline is ever paid", which would permanently foreclose a future offline feature nobody has invented yet
- Accepting an invite or a challenge is free forever; only initiating and discovering are paid
- No takebacks or undo, in any mode
- No draw offers, in any mode
- No spectating of other people's games
- No tournaments, leagues, seasons, or leaderboards beyond the rating shown on profiles
- No group chat, global chat, or chat outside a shared game
- No uploaded avatars or profile photos
- No true rotatable 3D board
- No board sizes other than 4×4×4
- No floating of computer opponent ratings — they are fixed anchors
- No syncing of the computer rating or of offline games; both are device-local permanently

---

## 12. Definition of done for v1

Quadrim v1 is complete when:

1. The 76-line table is implemented once, and win detection returns the specific completed line. Verified by exhaustive test.
2. A game can be played to a win and to a draw in all four modes.
3. Client and validating function agree on every move of a shared test corpus of full games.
4. All twenty computer players exist, are distinguishable in play, and have calibrated ratings.
5. The top bot's advertised strength matches what it actually delivers, per the fallback ladder in 6.5.
6. Both ratings update correctly and independently, including provisional K, draws, forfeits, and the rating floor. The computer rating never leaves the device; the human rating is never written by a client.
7. Async games expire correctly with a warning first.
8. All four matchmaking paths create playable games.
9. Chat works, with block, report, and profanity filtering all functional, and honours the per-player preference — including the case where the two players disagree and the more restrictive setting applies. Blocking terminates chat in existing games, and a game with no chat field fails closed.
9a. All three subscription products can be purchased, restored on a new device, and correctly gate *initiation* while leaving acceptance free; a lapsed subscription lets existing games finish and rate normally, blocks new ones, exempts the player from inactivity forfeit, and permits one rematch of a series in progress.
9b. Entitlement cannot be written by any client, and is revoked on refund, chargeback or voided purchase.
9c. The Firestore security rules pass an adversarial suite in which every attempt is denied.
10. Account deletion and data export both work and are reachable in-app, and deletion states that it does not cancel the store subscription.
10a. An account is linked to a recoverable credential before its first rated game or purchase.
11. Both layouts render correctly on phone and large screen, in both themes, at increased font scale.
12. The board is playable and legible for a colourblind player, and navigable by screen reader.
13. The tutorial runs end to end, including the interactive practice game.
14. Every string is localised into English and Dutch.
15. Notification limitations on web and desktop are surfaced to the player.
16. Builds ship for iOS, Android, Web, Windows, and macOS.

---

## 13. Known risks

| Risk | Impact | Mitigation |
|---|---|---|
| Perfect-play book cannot be obtained, verified or licensed | Top opponent cannot deliver what it promises | Fallback ladder in 6.5. Risk is materially lower than first assessed: the strategy is published, is about 2,929 positions, and has been solved independently twice (§6.5.1) |
| Computer anchor ratings mis-calibrated | Every player's computer rating is distorted; recalibrating rewrites their history unless each game stored the anchor it was played against | Calibrate all twenty together before release; store the anchor on each completed game |
| **The subscription gates a feature whose value depends on a population that does not exist at launch** | Zero conversion and zero online games, misread as the online half failing when what failed was the gate | Subscription moves to 0.4; accepting an invite is free forever, so the growth loop is not taxed |
| **A fabricated but legal game moves a victim's rating** | Paying customers lose rating from games they never played — a refund event and a data-accuracy obligation | Human rating and server-side validation ship together at 0.4 |
| Auto-match has no population at launch | Players queue against nobody | Offer a rating-matched computer opponent after a short wait |
| Client and server rules logic drift | Moves rejected or wins missed | One shared line definition, one shared test corpus |
| Desktop and web players silently forfeit async games | Unfair losses | Surface the notification limitation; consider exempting desktop-only accounts from forfeit |
| Firebase per-game function cost unestimated | Cost surprise at scale | Sized: steady state is negligible; the migration burst that dominated it no longer exists |

---

## 14. Sources

The game is public, old, and thoroughly analysed. Nothing about its mathematics needs to be derived here.

- **Wikipedia, "3D tic-tac-toe"** — https://en.wikipedia.org/wiki/3D_tic-tac-toe — the entry point, and the source of the line counts, cell degrees, automorphism count and solution history cited above.
- **R. Silver (1967)** — established the group of 192 automorphisms.
- **Eugene Mahalko (1976)** — weak solution: a first-player win exists.
- **Oren Patashnik (1980)** — "Qubic: 4 × 4 × 4 Tic-Tac-Toe", *Mathematics Magazine* 53(4), pp. 202–216. Complete first-player-win strategy, computer-assisted, ~1,500 hours, ~2,929 stored strategic positions. Independently verified. **Method and proof, not the dataset** — and copyrighted, distributed under JSTOR terms.
- **Victor Allis** — independent solution by proof-number search.

Two cautions before anything here is depended on. The published strategy data must be **located, verified against an independent implementation, and checked for licence** before it is shipped inside an application — Wikipedia reports it was made available online, which is not the same as confirming it is obtainable and redistributable today. And the game's commercial name **Qubic** was a Parker Brothers trade name; this product is called Quadrim, and the older name should be used descriptively, never as branding.
