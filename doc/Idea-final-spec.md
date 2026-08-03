# Quadrim — Specification

Derived from [Idea-final.md](Idea-final.md) (what to build) and [idea-decisions.md](idea-decisions.md) (why). The build approach was chosen in [history/Idea-final-brainstorming.md](history/Idea-final-brainstorming.md).

Follows **Strategy A — Store-First Offline Slice**.
Release 0.1 is specified at implementation depth. Releases 0.2 through 1.0 are scoped but not detailed; each gets its own spec when its turn comes.

Date: 2026-07-27
Status: ready for implementation planning. No code written.

---

## 1. Problem Statement

Quadrim — four in a row inside a 4×4×4 cube — is a genuinely good game that is hard to play. Physical sets are rare, and the digital versions that exist render the cube badly enough that players cannot see the diagonals that make the game interesting. Someone who wants to play it against a decent opponent, on a phone, without organising a second human, currently cannot.

**This premise is currently an assertion, not evidence.** Before the board design is fixed, the one-star reviews of the leading Qubic apps must be read and their specific legibility complaints recorded here. It is an afternoon's work, and it either confirms the premise or reshapes the single most important screen in the game at the only moment when reshaping it is free.

Secondarily: the developer is solo, working evenings, new to Flutter and Firebase, and has no store presence. A plan that produces nothing playable for months will not survive contact with real life.

## 2. Solution

A cross-platform Quadrim implementation whose board makes all 64 cells and all 76 winning lines legible at a glance, with a ladder of computer opponents from trivial to unbeatable, and — eventually — rated online play against other humans.

Built and released in stages. Release 0.1 is a complete, polished, **offline** game: the board, all twenty computer opponents, pass-and-play, a full tutorial, local history and statistics, a live rating earned against the opponents, in English and Dutch, on Android.

**The offline game is free forever.** Playing against real opponents requires an annual subscription, arriving with online play at 0.3b. That is the only payment path in the product, and everything on the free side of the line is a complete game rather than a demonstration.

**0.1 and 0.2 are not public.** They go to friends and family through Google Play closed testing and TestFlight, and are never promoted to production. The first public release is 0.3b. This keeps the early releases free of a public listing and a public-facing privacy exposure — though not of Play's declaration obligations, which apply to every track including closed testing.

Because the early releases are private and their audience is small, **0.3 starts with an empty database.** Offline history is never uploaded. Later releases add identity, online play, chat, real-time mode, the remaining platforms, and finally the perfect-play solver.

---

## 3. Goal

**For 0.1:** an offline Quadrim good enough that twelve real people install it, understand it without help, and enjoy it against an opponent matched to their skill — while proving the release pipeline end to end and unlocking production access before it is needed.

**For 1.0:** everything in Idea-final.md.

### 3.1 Success criteria

| # | Criterion |
|---|---|
| G1 | Twelve friends-and-family testers have 0.1 installed on their own devices and have opened it |
| G2 | A tester who has never seen Quadrim can complete the tutorial and win a game against Pebble without assistance |
| G3 | Onyx beats a competent human more often than not |
| G4 | The engine's win detection is exhaustively verified, not spot-checked |
| G5 | The release pipeline is proven: signed builds, closed testing on Play, TestFlight on iOS, and Play production access unlocked |
| G6 | All twenty opponents exist, are distinguishable in play, and are calibrated against each other and against real testers on one scale |
| G7 | A player has a real computer rating that moves as they play, computed and stored entirely on their own device |

G5 replaces an earlier criterion about 0.1's data shapes surviving into Firestore. With a clean start at 0.3 there is nothing to survive, so the criterion measured nothing.

G7 replaces the previous position that 0.1 could only offer "unrated practice" with indicative numbers. With ratings split in two, the computer ladder is real from the first release.

---

## 4. Scope

### 4.1 The release ladder

| Release | Contents | Platforms | Audience |
|---|---|---|---|
| **0.1** | Engine, board, **all 20 opponents**, live computer rating, pass-and-play, full tutorial, settings screen, placeholder art, local history and stats, both layouts, English + Dutch | Android | **Private** — 12 friends and family, Play closed testing |
| 0.2 | iOS build, App Store submission, **art package**, fixes the closed test demanded | Android, iOS | **Private** — closed testing + TestFlight |
| 0.3a | Anonymous auth, a Firestore repository passing the same flow tests as the local one, **security rules as a tested deliverable**, one async game between two owned devices | Android, iOS | **Private** |
| 0.3b | **Free online play** via invite links, W/L/D record but **no rating**, push, block, report, server-side display-name validation, account deletion and export, privacy policy, public store listing | Android, iOS | **First public release** |
| 0.4 | **Subscription**, **human rating**, **server-side move validation**, account linking, chat with preferences and filtering, friends, open challenges, auto-match | Android, iOS | Public |
| 0.5 | Real-time mode with 60s move clocks, Web, Windows, macOS | all five | Public |
| 1.0 | Rust solver, Quadrim Prime upgraded to true perfection, computer-ladder recalibration | all five | Public |

Only 0.1 is specified below. Later rows are commitments of intent, not of detail.

**Why 0.3 is split.** Making the first public release also the first release in an entirely unfamiliar stack — auth, Firestore, security rules, push, billing, and a published privacy policy at once — puts every risk on one release with no prior public exposure to learn from. 0.3a is the layer-proving step: one thin slice through auth and Firestore, verified against the identical flow tests the local implementation already passes, before any of it is exposed to a stranger.

**Why 0.3b ships neither the rating nor the subscription.** A second expert review found both unsafe there, for unrelated reasons that happen to have the same remedy.

The **rating** cannot be trusted without server-side validation, and validation cannot rescue it retroactively: replay proves a move list is *legal*, never that it is *authentic*. A modified client authoring both players' moves produces a game that replays perfectly and reproduces a fabricated result — and that result moves a real opponent's rating without them ever opening the app. So the rating ships with the validation, at 0.4, and 0.3b has none to forge.

The **subscription** at 0.3b would sell access to a population of zero — not a cold start but a two-sided market where both sides must pay to enter, which forecloses every standard remedy. §7.6 already conceded it by having auto-match fall back to a computer opponent, which is the paid feature degrading into the free one. Both stores also expect a subscription's content to exist at purchase.

What 0.3b does ship is the thing that has to work first: **can two people actually play each other**. Free, via invite links, with a win/loss/draw record and no ladder.

**Why block and report move earlier, to 0.3b.** They are contact-surface features, not chat features. 0.3b is what opens the contact surface — invites, profiles, push, and user-chosen display names visible to strangers — and free online play means more accounts on it, not fewer. Free-text chat, chat preferences and profanity filtering stay at 0.4.

**Why all twenty opponents ship in 0.1.** Calibration. Twenty opponents measured together, against each other and against the closed testers, on one scale, before anything is published — rather than six now and fourteen later against anchors that can no longer move. An earlier plan deferred fourteen of them past the point where the scale froze; that created a permanent constraint for no gain.

**What that costs.** This is a real scope increase to a release that was already growing. Most of it is cheap: opponents are configurations of one engine, so fourteen more is largely fourteen more catalogue entries. What is genuinely new is the machinery the upper tiers need — threat-space search, a transposition table, iterative deepening, and exact endgame solving. That is two additional tickets of engine work, not a data change.

**Quadrim Prime is present but not yet perfect.** It ships on rung 2 of Idea-final.md §6.5's fallback ladder — exact endgame plus the deepest achievable search — and is advertised as extremely strong rather than perfect until the solver lands at 1.0. Its rating is recalibrated then, which is cheap because computer ratings are device-local.

### 4.2 Release 0.1 — in scope

**Game**
- Full 4×4×4 board, all 76 winning lines, any-empty-cell placement
- Win, draw, and resign. **There are no draw offers, in any mode or release** — a game ends by four-in-a-row, a full board, resignation or timeout, and nothing is negotiated
- Random starting player, alternating on rematch
- Append-only move history; no undo, no takeback, in any mode

**Modes**
- Versus computer: **all twenty opponents**, from Pebble to Quadrim Prime (Idea-final.md §6.4)
- Local pass-and-play, two humans on one device

**Rating**
- A live **computer rating**, seeded at 1200, moving after every game against a computer opponent
- Computed and stored entirely on the device; it never leaves it and nobody else can see it
- Derived by folding completed computer games in order against the fixed opponent anchors, so it cannot drift from the games that produced it
- Pass-and-play affects no rating

**Interface**
- Four-layer parallelogram board, single tap to place
- Phone portrait layout and large-screen landscape layout
- Move-history scrubber for live and completed games
- Result screen with the winning line highlighted, and one-tap rematch
- Main screen: local statistics, completed-games list, new-game button, tutorial button
- Opponent selection showing name, avatar, tier, and the opponent's rating, grouped by tier
- A settings screen: language override, theme override, restart tutorial

**Tutorial** — all four parts
1. Rules, and what the 76 winning lines look like on the board
2. Controls and reading the four layers
3. Basic strategy: centre and corner value, double threats, blocking
4. Interactive guided practice game against a scripted opponent, with hints

**Non-functional**
- English and Dutch, complete
- Light and dark themes
- Colourblind-safe pieces distinguished by shape as well as colour
- Screen reader labels for every cell and for game state
- System font scaling respected; finger-sized targets on the smallest supported phone
- Local persistence in Firestore-shaped JSON documents

---

## 5. Non-Goals

### 5.1 Out of scope for 0.1, planned later

| Item | Arrives |
|---|---|
| Accounts and authentication | 0.3a |
| Any network call whatsoever | 0.3a |
| Play against real opponents, free, by invite link | 0.3b |
| Push notifications | 0.3b |
| Blocking, reporting, server-side display-name validation | 0.3b |
| In-app account deletion, data export, privacy policy | 0.3b (mandatory then, not before) |
| A public release of any kind | 0.3b |
| **The subscription** | 0.4 |
| **The human rating** | 0.4 |
| **Server-side move validation** | 0.4 |
| Account linking to a recoverable credential | 0.4 (required before a first rated game or purchase) |
| Chat, chat preferences, profanity filtering | 0.4 |
| Friends, open challenges, auto-match | 0.4 |
| Real-time play and move clocks | 0.5 |
| iOS, Web, Windows, macOS builds | 0.2 / 0.5 |
| The Rust solver, and Quadrim Prime becoming genuinely perfect | 1.0 |

**Permanently out of scope, not deferred:** uploading offline history to the cloud. Games played in 0.1 and 0.2 stay on the device for the life of the app. 0.3 starts with an empty database and never imports.

### 5.2 Out of scope permanently

Per Idea-final.md §11: **no ads ever**, and no payment path other than the subscription — no consumables, no cosmetics, nothing pay-to-win; **everything release 0.1 shipped stays free forever**, and accepting an invite is free forever; no undo or takeback in any mode; **no draw offers in any mode**; no spectating; no tournaments, leagues, seasons, or leaderboards; no chat outside a shared game; no uploaded avatars; no rotatable 3D board; no board size other than 4×4×4; computer opponent ratings never float; the computer rating and offline games never sync.

Note the deliberate narrowing: the promise is that **0.1's feature set** is free forever, not that nothing offline is ever paid. The broader form was written under a free-with-no-purchases model and would permanently foreclose a future offline feature nobody has designed yet.

---

## 6. User Stories

### Playing (0.1)

1. As a new player, I want the game to open straight to a screen with an obvious "new game" button, so that I can start playing without exploring.
2. As a new player, I want a tutorial offered on first launch, so that I understand a 4×4×4 board before I lose to it.
3. As a player, I want to see all four layers of the cube at once, so that I can plan lines that span layers.
4. As a player, I want occupied and empty cells to be unmistakably different, so that I never misread the board.
5. As a player, I want to place a piece with a single tap, so that playing feels immediate.
6. As a player, I want my opponent's move to be visibly distinct from my own, so that I can follow the game.
7. As a player, I want the winning line highlighted when a game ends, so that I can see exactly how it was won.
8. As a player, I want to know whose turn it is at all times, so that I am never confused about waiting.
9. As a player, I want to resign a hopeless game, so that I am not forced to play it out.
10. As a player, I want a full board with no winner to be declared a draw, so that the game always ends cleanly.
11. As a player, I want to step backward and forward through the moves of the current game, so that I can review how a position arose.
12. As a player, I want scrubbing history never to alter the game, so that reviewing is safe mid-game.
13. As a player, I want a rematch button when a game ends, so that I can play again without navigating back.
14. As a player, I want the starting player to swap on a rematch, so that the first-move advantage evens out.
15. As a player, I want to be told who moves first and why it was decided, so that a loss never feels arbitrary.

### Choosing an opponent (0.1)

16. As a player, I want to choose between a computer opponent and a friend beside me, so that I can play in either situation.
17. As a player, I want to see each computer opponent's name, avatar, and difficulty tier, so that I can pick a fair match.
18. As a player, I want a rating for each opponent and one for myself, so that I can see who is a fair match and track my improvement against them.
19. As a beginner, I want an opponent I can actually beat, so that my first game is not discouraging.
20. As an experienced player, I want an opponent that genuinely challenges me, so that the game stays interesting.
21. As a player, I want each computer opponent to feel recognisably different at the board, so that the roster is more than a difficulty slider.
22. As a player, I want it made clear that my computer rating is separate from the rating I will earn against real people, so that I do not mistake one for the other.

### Two humans on one device (0.1)

23. As two players sharing a phone, I want to play each other without accounts or a network, so that we can play anywhere.
24. As a pass-and-play player, I want the screen to make clear whose turn it is, so that we do not move for each other.
25. As a pass-and-play player, I want the game recorded in history, so that we can review it afterwards.

### History and progress (0.1)

25a. As a player, I want a rating that goes up when I beat a stronger opponent, so that improvement is measurable rather than remembered.
25b. As a player, I want twenty opponents rather than a handful, so that there is always a next rung rather than a ceiling.
25c. As a player, I want my rating against the computer to be mine alone and never published, so that experimenting and losing costs me nothing socially.
25d. As a player, I want everything I can do offline to be free, so that the game is worth having even if I never pay.
26. As a player, I want to see how many games I have won, lost, and drawn, so that I can see progress.
27. As a player, I want a list of completed games, so that I can revisit them.
28. As a player, I want to replay any completed game move by move, so that I can learn from my mistakes.
29. As a player, I want my history to persist across app restarts, so that it is not lost.
30. As a player, I want statistics broken down by opponent, so that I can see which bots I beat.
31. As a player, I want my history to survive replacing my phone, so that early play is not wasted. *(Delivered by device backup, not by the cloud — offline history stays on the device permanently and never syncs.)*

### Learning (0.1)

32. As a new player, I want the objective explained in one screen, so that I grasp the game quickly.
33. As a new player, I want to see examples of every family of winning line, so that I recognise diagonals through the cube.
34. As a new player, I want the four-layer representation explained explicitly, so that I can map it to a cube in my head.
35. As a new player, I want to be taught that centre cells and corners are valuable, so that my first games are not random.
36. As a new player, I want the idea of a double threat demonstrated, so that I understand how games are actually won.
37. As a new player, I want to play a guided game with hints, so that I can practise safely.
38. As a returning player, I want to replay the tutorial from the main screen, so that I can refresh my memory.
39. As a player who has already learned, I want to skip or exit the tutorial at any point, so that I am not trapped in it.

### Accessibility and comfort (0.1)

40. As a colourblind player, I want pieces distinguished by shape as well as colour, so that I can tell them apart at all.
41. As a screen reader user, I want every cell announced with its position and contents, so that I can play without sight.
42. As a screen reader user, I want game state and the result announced, so that I know what happened.
43. As a player with reduced vision, I want the app to respect my system font size, so that text is readable.
44. As a player on a small phone, I want touch targets large enough to hit reliably, so that I do not misplace pieces.
45. As a player who prefers dark mode, I want the board readable in both themes, so that the app matches my system.
46. As a Dutch speaker, I want the whole app in Dutch, so that nothing is half-translated.
47. As a tablet user, I want a layout that uses the wider screen, so that the app does not look like a stretched phone.

### Later releases

48. As a player, I want to sign in so that my rating and my online games follow me across devices. *(0.3a — offline history is not included and stays on the device where it was played)*
49. As a player, I want to play a friend asynchronously over days, so that we do not need to be online together. *(0.3)*
50. As a player, I want a notification when it is my turn, so that I do not have to keep checking. *(0.3)*
51. As a player, I want an ELO rating that reflects my strength, so that I can measure improvement. *(0.3)*
52. As a player, I want to invite someone by sharing a link, so that starting a game is frictionless. *(0.3)*
53. As a player, I want to delete my account and data from within the app, so that I stay in control. *(0.3)*
53a. As a player, I want to subscribe for a year to unlock playing real people, so that the cost is one predictable decision rather than a recurring surprise. *(0.3b)*
53b. As a player, I want the option to buy a single year that does not auto-renew, so that I am not signing up to an ongoing charge. *(0.3b)*
53c. As a player whose subscription has lapsed, I want to finish the games I am already in, so that a billing date does not cost me a game I was winning. *(0.3b)*
53d. As a returning player, I want my human rating to be where I left it rather than reset, so that resubscribing resumes rather than restarts. *(0.3b)*
54. As a player, I want to chat with my opponent, so that a long async game feels social. *(0.4)*
54a. As a player, I want to choose whether games come with a chat at all — always, only with friends, or never — so that playing a stranger does not open a channel to me. *(0.4)*
54b. As a player, I want to change that decision for one specific game as I start it, so that the setting is a default rather than a cage. *(0.4)*
54c. As a player who chose never, I want that respected even when my opponent chose always, so that the setting means what it says. *(0.4)*
55. As a player, I want to block and report someone, so that I can protect myself. *(0.4)*
56. As a player, I want to be matched automatically with someone near my rating, so that games are competitive. *(0.4)*
57. As a player, I want a live game with a move clock, so that I can play a quick game start to finish. *(0.5)*
58. As a player, I want to play in a browser, so that I can try it without installing. *(0.5)*
59. As a strong player, I want an opponent that cannot be beaten, so that I have something to aspire to. *(1.0)*

---

## 7. Exposed Endpoints

Release 0.1 has no network surface. The exposed contracts are the public APIs of the modules — these are what later releases build against, and the only surfaces other code may depend on.

### 7.1 `quadrim_engine` — pure Dart, no Flutter, no Firebase, no I/O

The whole of the game's logic. Every function is deterministic given its inputs; any randomness arrives as an injected `Random`. No clock, no ambient state.

| Export | Contract |
|---|---|
| `Cell` | A board position. Constructible from `(x, y, z)` or from an index `0..63`. Canonical index is `x + 4y + 16z`. |
| `Player` | Which side. Two values. |
| `GameState` | Immutable. Exposes the board, the side to move, and the ordered move list. |
| `winningLines` | The 76 lines, as a constant. **Generated — never hand-edited.** |
| `cellDegree` | How many winning lines each cell sits on — 7 for the 8 corners and 8 inner cells, 4 for the other 48. Generated alongside the line table, and the measurable fact the positional rules approximate |
| `canonical(GameState)` | A representative of the position's symmetry class under the board's 192 automorphisms. Collapses up to 192 positions into one, which is what makes a transposition table and any stored strategy affordable |
| `legalMoves(GameState)` | All empty cells. |
| `applyMove(GameState, Cell)` | Returns the next state. Rejects an occupied cell or a move in a finished game. |
| `outcome(GameState)` | `ongoing`, `draw`, or `win` carrying **both the winner and the completed line**. |
| `threats(GameState, Player)` | Lines with three of `Player` and one empty cell — the primitive behind both bot rules and tutorial hints. |
| `BotConfig` | The six parameter axes: search depth, enabled rules, blunder rate, positional bias, aggression, randomness. |
| `chooseMove(BotConfig, GameState, int seed)` | The single bot brain. Same function for every opponent. Takes a **seed**, not a `Random`, so the call can be hosted in an isolate — `Random` is not sendable across one. Returns a future: the Expert and Master tiers must search without blocking the interface and must be abandonable when the player leaves. Any transposition table is created and discarded within a single call, so the function stays pure and E7's determinism holds. |
| `botCatalogue` | The roster as data. **Twenty entries, from 0.1.** |

**Invariants.** `applyMove` never mutates its input. `outcome` returning a win always names a line present in `winningLines`. `chooseMove` always returns a member of `legalMoves`. Given the same `Random` seed and state, `chooseMove` is reproducible.

### 7.2 `quadrim_rating` — pure Dart

Used from 0.1 for real: it computes the live computer rating on the device, and it is the tool that calibrates the twenty opponents. The same maths serves the human rating on the server from 0.3b.

| Export | Contract |
|---|---|
| `expectedScore(own, opponent)` | `1 / (1 + 10^((opponent − own) / 400))` |
| `kFactor(gamesPlayed)` | 32 below 20 games on that ladder, 16 at or above |
| `updatedRating(current, k, score, expected)` | Rounded, floored at 100 |
| `ratingFrom(Iterable<CompletedGame>)` | Folds games ordered by `completedAt`, game id as tie-break, from the 1200 seed, using each game's stored `opponentRating` |

The last export is what makes the computer rating derived rather than stored: it is a pure function of the games already on disk, so it cannot drift from them, and it needs no separate persistence. The two ladders are computed by the same functions over different game sets and never mix.

Two details make the fold actually reproducible, and both live in the data rather than here: it folds against the anchor **stored on each game**, not the current catalogue value, and it orders by an explicit field. See §8.3.

The human rating is **not** this fold. Human ELO is not separable per player — each update depends on the opponent's rating at that moment — so recomputing it is a global chronological replay across every account, not a per-player fold. The maths is shared; the traversal is not. That is one reason the human rating and its validation ship together at 0.4 rather than being retrofitted.

### 7.3 `GameRepository` — the testing seam

The single interface separating the app from where games live.

Its original justification was migration: 0.1 implements it locally, 0.3 swaps in Firestore, the UI never changes. **That justification is gone** — with a clean start at 0.3, local games stay local forever and online games are a separate store. The interface survives for a different and still sufficient reason: it is the boundary Seam B tests against, and 0.3's Firestore implementation must pass the *same* flow tests the local one does. That equivalence is what proves the online layer works before anything is exposed publicly.

| Member | Contract |
|---|---|
| `watch(gameId)` | Stream of a single game's state |
| `activeGames()` | Stream of unfinished games |
| `completedGames()` | Stream of finished games, most recent first |
| `create(GameSetup)` | Creates and returns a new game |
| `appendMove(gameId, cell)` | Appends a move; rejects illegal moves and out-of-turn moves |
| `resign(gameId)` | Ends the game as a loss for the resigning seat |
| `delete(gameId)` | Removes a game |

Streams, not futures, even locally — because 0.3's implementation is push-based, and a future-shaped interface would force a UI rewrite.

Statistics are derived by folding `completedGames()`, not stored. This is safe precisely because offline history stays local and small: there is no growing cloud collection behind it, and therefore no pagination requirement.

There is no profile repository. See §8.4.

### 7.5 `tools/linegen` — build-time generator

Not shipped. Emits, from one definition:
- the 76-line table as Dart, for `quadrim_engine`
- the 76-line table as TypeScript, for 0.3's Cloud Functions
- a JSON corpus of complete games with known outcomes, covering every winning-line family, forced draws, and illegal-move cases

Generated files are committed and marked do-not-edit. CI fails if they are stale.

---

## 8. Data

### 8.1 Design rule

**Store the simplest correct thing.** 0.1's data is never uploaded, never queried by a server, and never authorised against — so it is designed for what 0.1 actually does, not for what 0.3 might want.

This reverses an earlier rule that shaped every 0.1 document as a future Firestore document. That rule bought forward-compatibility with a cloud that will now never see this data, and it was buying it with real complexity: a device identifier to generate and protect, a participant array to keep queryable, per-move authorship, ids and timestamps. All of it is removed.

0.3 designs its Firestore schema natively, around `request.auth.uid`, with no compatibility debt.

What survives from the old rule, because it is good practice regardless: a string id per document, a `schemaVersion`, and ISO-8601 UTC timestamps.

### 8.2 Identity in 0.1

**There is no device identity.** No uuid is generated, stored, claimed, backed up or cloned. 0.1 has one player — whoever holds the phone — and they need no name to play a bot or hand the device to someone else.

A game records only who its opponent was:

| Value | Meaning |
|---|---|
| `bot:<botId>` | A computer opponent, e.g. `bot:onyx` |
| `guest` | The second seat in pass-and-play |

Seats are positional: seat 0 and seat 1. Which seat the device owner holds is recorded per game, because the starting player alternates.

Removing the device identifier also shrinks what the Android backup carries (§8.7): game history, and nothing that identifies anyone.

### 8.3 Game document

```json
{
  "id": "string",
  "schemaVersion": 1,
  "mode": "vsComputer | passAndPlay",
  "opponent": "bot:onyx | guest",
  "opponentRating": 1650,
  "playerSeat": 0,
  "startingSeat": 0,
  "startReason": "random | rematchAlternation",
  "moves": [27, 14, 3, 61],
  "state": "active | complete",
  "completedAt": "2026-07-27T18:09:44Z",
  "result": {
    "outcome": "win | draw",
    "reason": "line | fullBoard | resignation | timeout | abandonment",
    "winnerSeat": 0,
    "line": [3, 18, 33, 48]
  },
  "rematchOf": "string | null",
  "createdAt": "2026-07-27T18:03:02Z",
  "updatedAt": "2026-07-27T18:09:44Z"
}
```

Notes:

- **`moves` is a plain ordered list of cell indices, `0..63`.** Whose move it was derives from position in the list and `startingSeat` — turns strictly alternate, so storing an author per move would be storing a derivable fact. No per-move id, index, or timestamp is stored either: the array position *is* the index, there is no network to retry over, and no clock decides anything in 0.1.
- The list is append-only and complete, which is what makes replay a pure fold rather than a stored artefact.
- `result.line` holds the four cell indices of the completed line, so highlighting needs no recomputation.
- **`opponentRating` records the anchor this game was actually played against.** Without it, recalibrating any opponent silently rewrites every player's entire rating history, and the "+12" they saw on a result screen becomes unreproducible. It is one integer, and it is what makes recalibration a deliberate re-fold rather than a silent rewrite.
- **`completedAt` is the fold's ordering key**, with the game id as tie-break. "Chronological" has to name a field: computer games are uncapped and concurrent, so a game started Monday and finished Friday must not fold before one started and finished on Tuesday.
- **`outcome` and `reason` are separate.** A clock-driven ending cannot be derived from the moves, so the reason has to be recorded rather than inferred. `timeout` and `abandonment` are unreachable in 0.1 and present because the field's shape should not change when they become reachable.
- There is no `rated` field. The ladder a game belongs to follows from its `mode`, so a flag would be a second source of truth.
- There is no `participants` array. It existed to be queryable by Firestore security rules, which will never see this document.

### 8.4 No profile document

Deleted. It held a device identity that no longer exists (§8.2), stored statistics that are now derived by folding completed games (§9.5), and a display name and rating that belong to 0.3's accounts.

Settings (§8.6) is therefore the only local document besides games.

### 8.5 Opponent catalogue — all twenty

Code-side constants, not persisted. The roster, ratings and personalities are defined once in Idea-final.md §6.4 and are not duplicated here.

What matters to implementation is which engine capability each tier requires, because that — not the count — is what the work actually is:

| Tier | Opponents | Engine capability required |
|---|---|---|
| Novice | Pebble, Twig, Mote, Clover | Random selection; immediate win and block detection; blunder rate; corner preference |
| Casual | Bramble, Finch, Kestrel, Willow, Ember | All four strategic rules; centre preference; aggression-versus-defence weighting |
| Club | Basalt, Marlin, Vireo, Onyx, Sable | Full positional rules; 2-ply and 4-ply alpha-beta; threat-space search for double threats |
| Expert | Quartz, Corvus, Lyra, Titan | Transposition table; iterative deepening to 6–8 ply; exact endgame solving |
| Master | Oracle, Quadrim Prime | Full-strength search with exact endgame; varied opening choice among proven-strong moves |

Fourteen of the twenty are catalogue entries over capabilities the lower tiers already establish. The genuinely new engine work sits in the Club, Expert and Master rows.

**Quadrim Prime ships without the strategy book** and is therefore not yet perfect — see §4.1. Its catalogue entry must describe what it currently is, not what it becomes at 1.0.

That book is now known to be a small, published dataset rather than something to be computed from scratch — about 2,929 positions, solved independently twice since 1976 (Idea-final.md §6.5.1). It is still not shipped until it has been obtained, verified and licence-checked, but the odds of Prime reaching genuine perfection at 1.0 are considerably better than when this plan was written.

All twenty are calibrated together before release, which is the reason they all ship at once.

### 8.6 Settings

```json
{ "schemaVersion": 1, "locale": "en | nl | system", "theme": "light | dark | system", "tutorialCompleted": false }
```

The only local document besides games, and the home for anything that is neither a game nor derivable from one. `tutorialCompleted` lives here — without it, acceptance criterion T7 in §11.4 cannot pass and testers are re-offered the tutorial on every launch.

The computer rating is deliberately **not** here: it is derived from completed games (§7.2), so storing it would create a second copy that can drift.

Release 0.4 adds `chatAvailability` with values `everyGame`, `friendsOnly` and `never`, **defaulting to `friendsOnly`**. The default matters more than the setting — a preference whose permissive value is the one nobody changes is not a preference. The chosen value can be overridden for a single game in the start-a-game flow, and the effective availability is recorded on that game rather than resolved when a message is sent, because the two players' preferences have to be combined once and then honoured.

### 8.7 Storage

One JSON document per record, keyed by id, in the platform application-support directory. Writes are atomic — write to a temporary file, then rename — so a kill mid-write cannot corrupt a game.

Version handling: a record whose `schemaVersion` is **greater than** the reader understands is skipped; equal or lower is read and upgraded. Skipping anything unrecognised would mean a newer build could not read the records an older one wrote.

**Backup.** Android's system backup is deliberately left enabled so a player replacing a device keeps their history (see §9.12). The backed-up set is games and settings — with §8.2 removing the device identifier, nothing in it identifies anyone. An explicit allowlist is committed rather than relying on the platform default of including everything, because at 0.3 this same directory gains Firebase authentication material that must never be restored onto a second device.

---

## 9. Implementation Decisions

### 9.1 Module structure

```
packages/quadrim_engine/     pure Dart
packages/quadrim_rating/     pure Dart
tools/linegen/               build-time generator
app/                         Flutter, Riverpod
```

`functions/` (TypeScript) and `solver/` (Rust) are created at 0.3 and 1.0 respectively.

### 9.2 The engine is pure

`quadrim_engine` must not import Flutter, Firebase, `dart:io`, or any ambient clock or random source. This is enforced by dependency review, not convention: the package's `pubspec.yaml` declares no dependency that would permit it.

This purity is what allows the identical code to run in a unit test, in the app, and in a headless self-play harness — which is the tool that resolves open item OI-03, bot calibration.

### 9.3 The 76 lines have exactly one definition

`tools/linegen` generates them. Nothing else enumerates lines. This is not an aesthetic preference: 0.3 introduces a second implementation in TypeScript, and the only defence against the two drifting is that neither is written by hand and both are tested against a shared generated corpus.

### 9.4 Bots are data

One `chooseMove`, **twenty configurations from 0.1**. Adding an opponent is a catalogue entry. Calibration is a matter of running self-play across configurations rather than across code paths.

### 9.5 Persistence sits behind `GameRepository`, and statistics are derived

The interface exists from the first commit even though 0.1 has one implementation. Its purpose is no longer migration — it is the boundary Seam B tests against, and the contract 0.3a's Firestore implementation must satisfy by passing the *same* flow tests.

Statistics are computed by folding completed games at read time, never stored. A stored aggregate is a second write that can silently drift from the games it summarises, and there is no scale here to justify it: offline history stays local, stays small, and is never behind a network.

**The main screen loads games once and all four derivations fold the same in-memory list** — overall statistics, the per-opponent breakdown, the computer rating, and the milestones. Four independent sweeps of one-file-per-game storage would make the home screen's cost grow four times faster than a player's history, which is invisible at fifty games and not at several thousand.

The tutorial's practice game follows directly from this. Because statistics are derived from stored games, a stored practice game would count. **It is therefore never stored at all** — it lives in memory for the tutorial's duration and never reaches the repository. That is strictly cheaper than adding a mode value every future reader would have to filter out.

### 9.6 Streams, not futures

`GameRepository` is stream-based even for local storage, because 0.3's implementation is push-based and a future-shaped API would force a UI rewrite.

### 9.7 Riverpod, layered

Three layers: pure domain (`quadrim_engine`, `quadrim_rating`), data (repositories), and presentation (Riverpod notifiers and widgets). Widgets read notifiers; notifiers own repositories; nothing reaches past its neighbour.

### 9.8 The board renders once, adapts twice

One board widget serving both layouts, differing in size and surrounding chrome rather than in structure. Piece rendering takes a shape token as well as a colour, so colourblind-safe rendering is intrinsic rather than a theme variant.

### 9.9 Localisation from the first commit

ARB resource files from commit one; no user-facing string is ever hard-coded. English and Dutch complete in 0.1. Bot names untranslated; tier labels and personality blurbs translated.

### 9.10 The scripted tutorial opponent is a bot configuration

The tutorial's guided opponent is a `BotConfig` with a fixed seed and a scripted opening, not a separate code path. Hints reuse `threats()`.

### 9.11 Store accounts start immediately; the closed test runs during 0.1

**Store accounts start on day one.** Apple Developer enrolment involves identity verification that can take days to weeks, and Google Play Console setup gates everything downstream. Neither has any code dependency; both are waiting time rather than effort.

**The closed test is the distribution channel, not a public launch.** Google Play requires personal developer accounts to run a closed test with at least twelve testers for fourteen continuous days before production access is granted. Those twelve testers are the friends and family who are 0.1's entire audience, so the requirement costs nothing extra to satisfy — and satisfying it during 0.1 means production access is already unlocked long before 0.3b needs it. Relocating that clock to 0.3b would have put it on the hardest release at the worst moment.

**The first upload waits until the game is worth showing, and now includes the tutorial.** Testers get one first impression, and a build with one random opponent and no result screen spends it badly. A build with no onboarding at all spends it worse: a stranger meeting a 4×4×4 board with 76 winning lines and no explanation cannot satisfy success criterion G2. The tutorial's rules-and-controls part therefore ships before the first upload; strategy and the practice game follow as updates during the fourteen days.

**What is not deferred by staying private.** Play requires the Data Safety declaration, the content rating questionnaire, and the target-audience declaration before publishing to *any* track, closed testing included. Being private removes the public listing and public discoverability. It does not remove those obligations, and the target-audience answer given here silently constrains what chat is permissible at 0.4.

### 9.12 Android backup is enabled deliberately

The platform default would back up everything in the application directory. That default is not accepted; an explicit allowlist is committed from the first commit, covering games and settings.

Backup stays **on** so a player replacing a device keeps their history. With §8.2 removing the device identifier, what travels is game history containing nothing that identifies anyone, into the user's own Google account, which the developer cannot read.

Two consequences follow, and both are load-bearing:

1. **"No data leaves the device" is not a true statement** and must not appear in any privacy text. Data does leave the device — to the user's own account, under Google's terms, outside the developer's control. That is a defensible position, but only if it is stated accurately.
2. **At 0.3 this same directory gains Firebase authentication material.** Restored onto a second device it would arrive already signed in. The allowlist must exclude it, and the exclusion is easier to write now, while the list is two entries long, than to remember later.

Android 12 and later distinguish device-to-device transfer from cloud backup. Allowing transfer while excluding cloud backup would deliver the same benefit with a smaller disclosure, and is worth evaluating when the allowlist is written.

### 9.13 The three irreversible decisions

Everything else in this plan can be changed later. These cannot.

| Decision | When | Why it is final |
|---|---|---|
| **Application id** | Before the first upload | Permanent once published to any track. Currently recorded as `PLACEHOLDER_APPLICATION_ID` |
| **App signing key** | At Play App Signing enrolment | Google holds it and it cannot be replaced for an existing app |
| **Firestore database location** | Before the first write at 0.3a | Fixed at creation. Cloud Functions must be pinned to a compatible region separately, and Firebase Auth cannot be region-pinned at all — user records are processed in the US regardless, which the privacy policy must state rather than claiming EU-only |

**A correction worth making explicitly:** an earlier version of this document stated that a lost keystore can never be recovered. That is half wrong. With Play App Signing — mandatory for new applications — Google holds the app signing key, and a lost *upload* key can be reset through support. The upload keystore should still be backed up and the backup verified; it is simply not the catastrophe it was described as. The genuinely unrecoverable items are the three above.

---

## 10. Testing Decisions

### 10.1 What makes a good test here

Tests assert external behaviour at a module's public boundary. They do not reach into internals: bot decision helpers, the line table's construction, and widget internals are exercised *through* the public API or not at all. A test that breaks when an implementation is refactored without a behaviour change is a defect in the test.

### 10.2 Seams — confirmed

**Seam A — `quadrim_engine` public API. Primary, strict TDD.**

The whole of the game's logic, tested only through §7.1's exports. Pure functions with exact right answers, which is where TDD pays and where correctness actually matters.

- Win detection verified **exhaustively**: every one of the 76 lines completes a win, for both players, and no set of four cells that is not a line ever does. This is a generated test, not a sample.
- Every game in `linegen`'s corpus replays to its recorded outcome.
- `applyMove` rejects occupied cells, out-of-range cells, and moves in finished games.
- Draw detection on a full board with no line.
- `chooseMove` always returns a legal move, for every bot, from thousands of random positions.
- Bot behaviour asserted at the rule level: given a position with an immediate win, a rule-enabled bot takes it; given an immediate loss threat, it blocks; Pebble does neither reliably.
- Determinism: identical seed and state produce an identical move.

**Seam B — the game controller against a fake `GameRepository`.**

Full user flows without widgets: start a game, play to a win, play to a draw, resign, scrub history, rematch with swapped starter, persist and reload. The fake is in-memory and shared with 0.3's tests, where the same flow tests must pass against the Firestore implementation.

**Seam D — Firestore security rules, adversarially. From 0.3a.**

With move validation at 0.4, the rules are the entire trust boundary of the first public release. Every test in the suite is an attempt that must be **denied**: write another player's game; overwrite an existing game id; write a `result`, a rating, or an entitlement; append two moves in one write; move out of turn; create a game while unentitled; delete a move; exceed the concurrent-game cap. Run in the Firebase emulator, in CI, from the first commit that has rules.

This is a deliverable with a ticket, not configuration. "The rules are correct" is currently the whole security argument for 0.3b, and an argument with no artefact behind it is an assumption.

**Seam C — golden tests for the board. Thin.**

A small fixed set: empty board, mid-game, won game with the line highlighted — in each layout, each theme. Enough to catch a rendering regression, few enough not to become a maintenance tax.

**Not a seam.** Bots, the line table, layout internals, and repository implementation details are not tested directly. They are covered through A and B.

### 10.3 Prior art

None — this is a new codebase. Seam A's conventions therefore set the pattern for the project, and are worth getting right first. From 0.3, Seam B's flow tests become the shared contract that both the local and Firestore repositories must satisfy.

### 10.4 Coverage expectations

Exhaustive on Seam A. Every flow in §6's 0.1 user stories covered at Seam B. Seam C deliberately sparse. Firebase wiring, from 0.3, is covered by emulator tests rather than unit tests.

---

## 11. Acceptance Criteria

### 11.1 Engine

| # | Given | When | Then |
|---|---|---|---|
| E1 | Any of the 76 lines, filled by one player | outcome is evaluated | a win is reported for that player, naming that exact line |
| E2 | Any four cells not forming a line, filled by one player | outcome is evaluated | no win is reported |
| E3 | A full board with no completed line | outcome is evaluated | a draw is reported |
| E4 | An occupied cell | a move is applied to it | the move is rejected and state is unchanged |
| E5 | A finished game | any move is applied | the move is rejected |
| E6 | Any position and any bot | a move is chosen | the move is legal |
| E7 | Identical state and seed | a move is chosen twice | both moves are identical |
| E8 | A position with an immediate win available | Ember chooses | it takes the win |
| E9 | A position where the opponent wins next move | Ember chooses | it blocks |
| E10 | A position with a double-threat cell available | Basalt chooses | it plays the double threat |
| E11 | Every game in the generated corpus | replayed | the recorded outcome is reproduced |

### 11.2 Game flow

| # | Given | When | Then |
|---|---|---|---|
| F1 | A new game | it is created | the starting player is random and recorded with its reason |
| F2 | A completed game | rematch is chosen | the previous non-starter starts, and the new game references the old |
| F3 | An in-progress game | history is scrubbed | the displayed position changes and the game state does not |
| F4 | A won game | the result screen is shown | the winning line is highlighted |
| F5 | Any search budget | a move is chosen twice on different hardware | the same move is returned, because budgets are counted in **nodes**, never milliseconds |
| F6 | Any completed game | the app restarts | the game is still present and replayable |
| F7 | A pass-and-play game | it is in progress | the current player is unambiguous on screen |
| F8 | A game | resign is chosen | the game ends as a loss for the resigning seat |
| F9 | A new player with no history | the computer rating is read | it is 1200 |
| F10 | A completed game against a computer opponent | the computer rating is recomputed | it moves by the ELO update against that opponent's fixed anchor, using K=32 for the first 20 such games and K=16 after |
| F11 | The same set of completed games | the rating is computed twice | both results are identical, because it is a fold and not a stored counter |
| F12 | A pass-and-play game completing | any rating is read | nothing has changed |
| F13 | Any game against a computer opponent | it is played from first move to result | no network call is made at any point |

### 11.3 Interface

| # | Criterion |
|---|---|
| U1 | All four layers and all 64 cells are visible without scrolling, in both layouts |
| U2 | Occupied and empty cells are distinguishable at a glance |
| U3 | One tap on an empty cell places a piece; no confirmation step |
| U4 | Every cell is a reliable touch target on the smallest supported phone |
| U5 | Pieces are distinguishable with colour vision simulation applied |
| U6 | Every cell exposes a screen-reader label naming layer, row, column, and contents |
| U7 | Turn, result, and winning line are announced to a screen reader |
| U8 | The app is legible at the largest system font scale |
| U9 | Board and pieces are legible in light and dark themes |
| U10 | Phone shows portrait only; large screen shows landscape only; crossing the breakpoint mid-game preserves state |
| U11 | No hard-coded user-facing string exists; English and Dutch are complete |

### 11.4 Tutorial

| # | Criterion |
|---|---|
| T1 | Offered automatically on first launch, and restartable from the main screen |
| T2 | Exitable at any point without completing |
| T3 | Illustrates at least one example from each of the four winning-line families |
| T4 | Explains the mapping from four parallelograms to one cube |
| T5 | Demonstrates a double threat |
| T6 | The practice game gives hints derived from real threat detection, not scripted text |
| T7 | Completion is persisted so it is not re-offered |

### 11.5 Data

| # | Criterion |
|---|---|
| D1 | Every persisted document carries a `schemaVersion` |
| D2 | No device identifier is generated, stored, or transmitted anywhere |
| D3 | Game documents match §8.3 exactly |
| D4 | A kill during a write leaves no corrupted record |
| D5 | A `schemaVersion` **greater than** the reader understands causes that record to be skipped; equal or lower is read and upgraded |
| D6 | Every game id is unique and stable across restarts |
| D7 | Whose move each move was is derivable from list position and `startingSeat`, and matches what the board displays during replay |
| D8 | The tutorial's practice game never reaches storage and never appears in statistics or the completed-games list |
| D9 | Only games and settings are backup-eligible, by explicit allowlist rather than platform default |

### 11.6 Release gates for 0.1

0.1 is a **private** release. There is no production listing and no public availability.

| # | Gate |
|---|---|
| R1 | Google Play Console account created and the application id chosen — **permanent once published to any track** |
| R2 | Apple Developer enrolment started — no code depends on it, and its clock runs long |
| R3 | Release signing configured, upload keystore backed up and the backup **verified by restoring it** |
| R4 | 12 friends-and-family testers recruited and opted into the closed test — a real task with a real lead time, not a formality |
| R5 | Play Data Safety declaration completed. **This is a task, not a foregone conclusion:** determine the correct answers given that Android backup is enabled, by checking current Play guidance on backup and on end-to-end-encrypted data, and record the reasoning and the date checked |
| R6 | Content rating questionnaire and target-audience declaration completed. **The audience answer silently constrains 0.4:** a declared band including under-13s makes free-text chat with strangers effectively unshippable |
| R7 | Closed-testing listing sufficient for testers to install, in English and Dutch |
| R8 | A build published to closed testing, all 12 testers installed and opened it, and the 14-day continuous clock started — with its start date recorded |
| R9 | The tester survey instrument exists and was given to testers **at install**, with its pass thresholds committed in advance |
| R10 | Every acceptance criterion in §11.1 to §11.5 passing |
| R11 | Production access unlocked at the end of the 14 days — banked for 0.3b, not used |

Gate R5 was previously written as an assertion that the declaration would say "no data collected". With backup enabled that is no longer safe to assume, and misdeclaring Data Safety is a policy-violation removal rather than a warning — so it is now a verification task with a recorded answer.

### 11.7 Security and privacy

This section exists from 0.1 even though most of it is not yet reachable. Every invariant below was, until now, a paragraph of prose with no test behind it — and the ones that bite hardest arrive under deadline pressure at 0.3.

**Testable in 0.1:**

| # | Criterion |
|---|---|
| S1 | No network call is made at any point in a game against a computer opponent — cross-references F13 |
| S2 | No device identifier is generated, stored or transmitted — cross-references D2 |
| S3 | Only games and settings are backup-eligible, by explicit allowlist — cross-references D9 |
| S4 | The repository is the only reader and writer of stored data; no screen touches storage directly |
| S5 | The twelve closed testers have been given a written privacy notice covering what is collected (their Play enrolment address, survey answers, two statistics screenshots), why, who holds it, how long, and how to withdraw. **This is the only personal-data processing release 0.1 has, and it is the developer's, not the app's** |
| S6 | Tester screenshots are deleted once ticket 014's calibration has consumed them |

**Gated on 0.3 and stated now so they are not invented later:**

| # | Criterion |
|---|---|
| S7 | The adversarial rules suite passes: every listed attempt is denied |
| S8 | The client write allowlist is field-level; ratings, entitlement, totals and timestamps are server-written only |
| S9 | Entitlement is written only after receipt validation, by the server, and is revoked on refund, chargeback or voided purchase |
| S10 | Invite codes resist enumeration, expire, are single-use, are revocable, and are checked against the creator's block list on join |
| S11 | A block prevents challenge, invite acceptance and profile visibility, checked in the game-creation path |
| S12 | Friendship requires acceptance; friend requests carry no free text and are rate-limited |
| S13 | Account deletion leaves no identifier linking a retained game to the deleted account, and the tombstone is randomly generated per game |
| S14 | Data export returns everything deletion would remove, in a machine-readable form |
| S15 | Firebase auth material, the entitlement cache, the FCM token and the Installations ID are excluded from backup |
| S16 | The backup allowlist is re-verified against the app directory at every release, because a new dependency can add state silently |

---

## 12. Further Notes

### 12.1 What going private changed, and what it did not

Strategy A was chosen in [history/Idea-final-brainstorming.md](history/Idea-final-brainstorming.md) largely because it reached the stores soonest. Making 0.1 and 0.2 private removes that argument, so it needs replacing rather than quietly dropping.

**The sequencing still holds, on different grounds.** Offline-first still means the entire backend learning curve is deferred until Flutter is familiar, still means something is playable within weeks, and still means the first release carries no public listing and no public privacy exposure. Those were always the stronger reasons; the store-clock argument was the one most sensitive to scope growth, and it is now simply not needed — §9.11 satisfies the fourteen-day requirement using the same twelve people who are the audience anyway.

**What it genuinely solved.** The clean start at 0.3 removed an entire category of risk: no import endpoint, no migration to make resumable, no client-authored data crossing a trust boundary, no device identity to generate, protect, claim or clone, and no cost burst on launch day. Roughly a third of the expert review's findings ceased to exist rather than being fixed.

**What it did not solve, and made slightly worse.** There is now no shipped artefact of any kind — private or otherwise — before 0.3, which was already the release most likely to stall. §4.1's split into 0.3a and 0.3b exists specifically to address that, and it is the mitigation to protect if anything else slips.

**The rule for future scope growth is unchanged in spirit:** what is worth protecting is the date twelve people first play the game. Anything added after the main screen is complete can ship as an update into the same closed track.

### 12.2 Things 0.1 promises that only 0.3 can keep

**This section used to be longer.** Splitting the rating in two removed its main entry: 0.1 no longer has to present computer games as "unrated practice" with numbers that were not ratings, because the computer ladder is real, live, and complete from the first release. That was the most awkward compromise in the plan and it is simply gone.

What remains is smaller and still worth stating plainly in the app rather than discovering later:

- **Nothing offline ever syncs.** Statistics, history and the computer rating follow the *device*, via Android backup, not the account. A player moving to a different platform starts that ladder again. A player who subscribes at 0.3b keeps their offline history locally and begins their human record empty.
- **The two ratings never mix.** Beating Quadrim Prime says nothing about a player's human rating, and the interface must not imply otherwise by placing them where they read as one number.
- **Quadrim Prime is not yet perfect** and must not be described as though it were until the solver lands.

### 12.3 Calibrating twenty opponents at once

The published ratings in Idea-final.md §6.4 are estimates (open item OI-03). The self-play harness turns them into an ordering; only humans can turn them into a scale.

**All twenty are calibrated together, in 0.1, before anything is published.** That is the reason they all ship at once. The alternative — six now, fourteen later — meant introducing new anchors into a scale that could no longer move, which is a permanent constraint accepted for no benefit.

**And all twenty are in the first uploaded build**, not just in the release. Both reviewers recommended otherwise — ship the first three tiers, add Expert and Master as updates inside the fourteen days, exactly as tutorial parts 3 and 4 already do — on the grounds that twelve recruited testers will produce no games above Sable anyway. That was declined. The cost is recorded plainly: the first build twelve people ever see waits for transposition tables, 8-ply search and exact endgame solving, and the fourteen-day Play clock starts correspondingly later. It is the one place this plan knowingly departs from §12.1's rule about protecting that date.

A full round-robin over twenty opponents is 190 pairs, not the 15 that six would have been, and the upper-tier pairs are the slowest. Ticket 014 therefore calibrates an **adjacent-pairs chain plus a sparse cross-tier sample** at a reduced node budget, which establishes the ordering and the gaps without the quadratic cost.

**Anchor from the bottom and chain upward.** Twelve friends-and-family testers will produce many results against Pebble and Twig and almost none against Oracle and Prime, which is exactly where a wrong anchor does damage. So: human-anchor the lower tiers from tester results, then set the upper ones from the rating differences the round-robin already measures, and record the chain. Where the chain is weak, publish the tier label without a number — the opponent list renders both, so showing one is a data change.

**Correcting an anchor is now cheap, and that is a deliberate consequence.** These twenty govern a *device-local* computer rating, not a competitive human ladder. Adjusting one changes a number only its owner can see, on their own device — which is what makes it acceptable for Quadrim Prime to ship at fallback strength and be recalibrated when the solver lands at 1.0. Under the previous single-rating model, that would have invalidated every human rating derived from it.

### 12.4 Open items

None of these block starting.

**Inherited:**

- **OI-01** — push unsupported on Flutter desktop; first matters at 0.5
- **OI-02** — **substantially reduced.** The strategy is published literature, not original research: independently solved twice, with the first-player-win strategy amounting to roughly 2,929 stored positions and everything else reachable by forcing moves (Idea-final.md §6.5.1). Asset size is kilobytes, not an unknown. What remains is a bounded task, and the **preferred route is to re-derive the strategy in-house by proof-number search** rather than to source it. What cost 1,500 hours in 1980 is a modest modern run, the symmetry reduction shrinks it further, and derived data carries **no licence question** — which sourced data does. The 1980 paper is method and proof, not a dataset, and is copyrighted under JSTOR terms; it is a reference to verify against, not a supply. Prime stays on fallback rung 2 until a derivation is complete and cross-checked against the published result, because unverified data is not a proof
- **OI-03** — **largely resolved.** All twenty opponents are calibrated together in 0.1 with the method in §12.3, and split ratings make a later correction cheap. What remains is doing it
- **OI-04** — auto-match cold start; first matters at 0.4
- **OI-05** — **largely answered.** The expert review sized it: steady state is negligible, roughly 250 games a day inside the free tier. The real exposure was the migration burst — one user with 500 local games costing about 1,000 writes at once — and the clean start removed it entirely. What remains is ordinary steady-state sizing before 0.3b

**Raised by the expert review and still open:**

- **OI-06** — Play's Data Safety treatment of Android backup, and whether a privacy policy is required for every app regardless of declared collection. Must be checked against current Play guidance, not reasoned about. Gates R5
- **OI-07** — Play's public address requirement for individual developer accounts, and whether a Dutch KvK registration with address shielding satisfies it. Shape of the problem is certain; today's rules are not. Gates 0.3b
- **OI-08** — **substantially reduced.** The subscription removes the cheap sybil attack outright: rated human play now costs a yearly fee per account, so throwaway accounts are no longer free. What survives is collusion between two people who both pay, and the unresolved collision between a repeat-matchup cap and the rematch loop §7.8 calls the app's cheapest retention mechanism
- **OI-12** — subscription mechanics at 0.3b: store product configuration on both platforms, receipt validation (server-side, since a client can claim anything), restore-purchases, the case where a player holds both products, grace and billing-retry periods, and refund handling
- **OI-13** — tax and payout setup for a paid product, which makes the developer-identity question in OI-07 urgent rather than eventual. Both stores act as marketplace facilitator for VAT in most of the EU, but the developer still needs banking and tax details registered
- **OI-14** — whether a subscription paywall changes the app's store category, content rating, or the target-audience answer given in ticket 016
- **OI-09** — account deletion residues at 0.3b: head-to-head aggregates, reports authored *about* a deleted user, and the auth record itself are not covered by replacing an identity in a game document
- **OI-10** — **closed.** Validation ships at 0.4 together with the human rating, because that is the only thing it protects. The original justification — keeping a second language off 0.3b's critical path — was mispriced: 0.3b needs Cloud Functions regardless, for push, the scheduled forfeit sweep, and head-to-head aggregates. What deferral actually saves is the shared TypeScript line table and corpus wiring
- **OI-11** — who the twelve testers are. Gates R4 and, through it, everything
- **OI-15** — a Firestore-triggered validator fires *after* the client write lands, so an illegal move is already in the document and already pushed to the opponent for the trigger's lifetime; and the trigger's own write re-fires it unless explicitly guarded. Conditional on OI-10
- **OI-16** — Firestore rules must gate document creation on the document not already existing, and updates on membership. Otherwise an authenticated client can write over any game id it can name. **This cannot be added defensively later — rules are the only gate.** Gates 0.3a
- **OI-17** — integrity events from failed validation are a record of suspected abuse attached to a person, with no shape, access rule or retention period. If accumulation ever drives an automatic sanction, GDPR Art. 22 requires human review and a contest path. Conditional on OI-10
- **OI-18** — no data export path. GDPR Art. 15 and 20 apply from 0.3b; the documents are already JSON with a schema version, so this is nearly free designed in and awkward retrofitted
- **OI-19** — the exact on-device storage locations of Firebase Auth and Installations data, needed to write the backup exclusion in §9.12 correctly. Verify against current Firebase documentation rather than assuming. Gates 0.3a
- **OI-20** — whether the ePrivacy Art. 5(3) "strictly necessary" exemption covers cloud-backing-up game history. Storing locally is clearly necessary; copying to a cloud service the user did not request for that purpose is a weaker argument, and it is the strongest reason to consider making backup a visible toggle rather than a silent default. Gates ticket 001. **Stronger now than when raised:** at 0.3 that directory also holds auth material and entitlement, and a visible toggle would simultaneously resolve this and simplify the OI-06 Data Safety answer by making it a user choice
- **OI-21** — **the subscription price.** No number exists anywhere. It determines whether the monthly product is needed and how long the trial should be, so nothing downstream of it can be evaluated. Must be decided before 0.4
- **OI-22** — whether the twelve testers can name someone they would actually play a game against. This is the demand signal for the entire paid tier, it is free to measure in the closed test, and until it is measured the business model is the largest untested assumption in the plan
- **OI-23** — DSA trader-verification duties, which both stores now enforce on EU-established developers. Selling a subscription makes the developer unambiguously a trader. **Verify whether it also reaches closed-testing-only distribution** — if it does, this touches 0.1 rather than 0.4. Undeclared traders being delisted in the EU is a real outcome, so this needs an answer with a date attached
- **OI-24** — VAT treatment of store payouts for a Dutch sole trader, and whether the small-business scheme is compatible. **Verify with an accountant, not by reasoning**
- **OI-25** — chat message retention. "While the game exists in history" is not a period, and history is indefinite
- **OI-26** — the app name's availability on both stores and against trademark registers. It sits beside the application id in irreversibility and is currently unchecked
- **OI-27** — the 0.4 human ladder will be seeded by invite-only pairs of people who know each other, then auto-match will pair strangers using numbers produced by that population. Decide before 0.4 whether the ladder reseeds

### 12.5 Deviations from the to-spec skill

The skill directs no interview and publication to a project issue tracker. Both were overridden by explicit instruction: clarifying questions were requested, and no issue tracker is configured for this repository. The spec's structure follows the skill's template, extended with the Goal, Scope, Exposed Endpoints, Data, and Acceptance Criteria sections requested directly.
