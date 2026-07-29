# Quadrim — Specification

Derived from [Idea-final.md](Idea-final.md) (what to build), [idea-decisions.md](idea-decisions.md) (why), and [Idea-final-brainstorming.md](Idea-final-brainstorming.md) (in what order).

Follows **Strategy A — Store-First Offline Slice**.
Release 0.1 is specified at implementation depth. Releases 0.2 through 1.0 are scoped but not detailed; each gets its own spec when its turn comes.

Date: 2026-07-27
Status: ready for implementation planning. No code written.

---

## 1. Problem Statement

Quadrim — four in a row inside a 4×4×4 cube — is a genuinely good game that is hard to play. Physical sets are rare, and the digital versions that exist render the cube badly enough that players cannot see the diagonals that make the game interesting. Someone who wants to play it against a decent opponent, on a phone, without organising a second human, currently cannot.

Secondarily: the developer is solo, working evenings, new to Flutter and Firebase, and has no store presence. A plan that produces nothing playable for months will not survive contact with real life.

## 2. Solution

A cross-platform Quadrim implementation whose board makes all 64 cells and all 76 winning lines legible at a glance, with a ladder of computer opponents from trivial to unbeatable, and — eventually — rated online play against other humans.

Built and released in stages. Release 0.1 is a complete, polished, **offline** game: the board, six computer opponents, pass-and-play, a full tutorial, local history and statistics, in English and Dutch, on Android. It has no accounts, no network, and therefore no compliance surface. Later releases add identity, online play, chat, real-time mode, the remaining platforms, and finally the perfect-play solver.

---

## 3. Goal

**For 0.1:** a store-shippable offline Quadrim that a stranger can install, understand without help, and enjoy against an opponent matched to their skill — while proving the release pipeline and starting the Google Play closed-testing clock.

**For 1.0:** everything in Idea-final.md.

### 3.1 Success criteria

| # | Criterion |
|---|---|
| G1 | A build is uploaded to Google Play closed testing, starting the 14-day / 12-tester clock |
| G2 | A tester who has never seen Quadrim can complete the tutorial and win a game against Pebble without assistance |
| G3 | Onyx beats a competent human more often than not |
| G4 | The engine's win detection is exhaustively verified, not spot-checked |
| G5 | Nothing in 0.1's data shapes forces a rewrite when accounts and Firestore arrive in 0.3 |

---

## 4. Scope

### 4.1 The release ladder

| Release | Contents | Platforms |
|---|---|---|
| **0.1** | Engine, board, 6 bots, pass-and-play, full tutorial, local history and stats, both layouts, English + Dutch | Android |
| 0.2 | iOS build, remaining 14 bots, visual identity, polish | Android, iOS |
| 0.3 | Anonymous auth, profiles, async online, invite links, ELO becomes live, push, account deletion, privacy policy | Android, iOS |
| 0.4 | Chat with block/report/filter, friends, open challenges, ELO auto-match | Android, iOS |
| 0.5 | Real-time mode with 60s move clocks, Web, Windows, macOS | all five |
| 1.0 | Rust solver, Quadrim Prime, rating recalibration | all five |

Only 0.1 is specified below. Later rows are commitments of intent, not of detail.

### 4.2 Release 0.1 — in scope

**Game**
- Full 4×4×4 board, all 76 winning lines, any-empty-cell placement
- Win, draw, and resign; draw offers are meaningless offline and are omitted until 0.3
- Random starting player, alternating on rematch
- Append-only move history; no undo, no takeback, in any mode

**Modes**
- Versus computer: Pebble, Mote, Bramble, Ember, Basalt, Onyx
- Local pass-and-play, two humans on one device

**Interface**
- Four-layer parallelogram board, single tap to place
- Phone portrait layout and large-screen landscape layout
- Move-history scrubber for live and completed games
- Result screen with the winning line highlighted, and one-tap rematch
- Main screen: local statistics, completed-games list, new-game button, tutorial button
- Opponent selection showing name, avatar, tier, and indicative rating

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
| Accounts, authentication, cloud sync | 0.3 |
| Any network call whatsoever | 0.3 |
| Live ELO ratings; 0.1 bot games are **unrated practice** | 0.3 |
| Push notifications | 0.3 |
| In-app account deletion and privacy policy | 0.3 (mandatory then, not before) |
| Chat, blocking, reporting, profanity filtering | 0.4 |
| Friends, invites, open challenges, auto-match | 0.3–0.4 |
| Real-time play and move clocks | 0.5 |
| iOS, Web, Windows, macOS builds | 0.2 / 0.5 |
| The other 14 computer players | 0.2 |
| Quadrim Prime and the Rust solver | 1.0 |

### 5.2 Out of scope permanently

Per Idea-final.md §11: no ads or in-app purchases; no undo or takeback in any mode; no spectating; no tournaments, leagues, seasons, or leaderboards; no chat outside a shared game; no uploaded avatars; no rotatable 3D board; no board size other than 4×4×4; bot ratings never float.

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
18. As a player, I want an indicative strength number for each opponent, so that I can track my improvement against them.
19. As a beginner, I want an opponent I can actually beat, so that my first game is not discouraging.
20. As an experienced player, I want an opponent that genuinely challenges me, so that the game stays interesting.
21. As a player, I want each computer opponent to feel recognisably different at the board, so that the roster is more than a difficulty slider.
22. As a player, I want to be told clearly that computer games are unrated practice for now, so that I am not misled about a rating that does not exist yet.

### Two humans on one device (0.1)

23. As two players sharing a phone, I want to play each other without accounts or a network, so that we can play anywhere.
24. As a pass-and-play player, I want the screen to make clear whose turn it is, so that we do not move for each other.
25. As a pass-and-play player, I want the game recorded in history, so that we can review it afterwards.

### History and progress (0.1)

26. As a player, I want to see how many games I have won, lost, and drawn, so that I can see progress.
27. As a player, I want a list of completed games, so that I can revisit them.
28. As a player, I want to replay any completed game move by move, so that I can learn from my mistakes.
29. As a player, I want my history to persist across app restarts, so that it is not lost.
30. As a player, I want statistics broken down by opponent, so that I can see which bots I beat.
31. As a player, I want my local history to carry over when accounts arrive, so that early play is not wasted.

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

48. As a player, I want to sign in so that my rating and history follow me across devices. *(0.3)*
49. As a player, I want to play a friend asynchronously over days, so that we do not need to be online together. *(0.3)*
50. As a player, I want a notification when it is my turn, so that I do not have to keep checking. *(0.3)*
51. As a player, I want an ELO rating that reflects my strength, so that I can measure improvement. *(0.3)*
52. As a player, I want to invite someone by sharing a link, so that starting a game is frictionless. *(0.3)*
53. As a player, I want to delete my account and data from within the app, so that I stay in control. *(0.3)*
54. As a player, I want to chat with my opponent, so that a long async game feels social. *(0.4)*
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
| `legalMoves(GameState)` | All empty cells. |
| `applyMove(GameState, Cell)` | Returns the next state. Rejects an occupied cell or a move in a finished game. |
| `outcome(GameState)` | `ongoing`, `draw`, or `win` carrying **both the winner and the completed line**. |
| `threats(GameState, Player)` | Lines with three of `Player` and one empty cell — the primitive behind both bot rules and tutorial hints. |
| `BotConfig` | The six parameter axes: search depth, enabled rules, blunder rate, positional bias, aggression, randomness. |
| `chooseMove(BotConfig, GameState, Random)` | The single bot brain. Same function for every opponent. |
| `botCatalogue` | The roster as data. Six entries in 0.1, twenty by 0.2. |

**Invariants.** `applyMove` never mutates its input. `outcome` returning a win always names a line present in `winningLines`. `chooseMove` always returns a member of `legalMoves`. Given the same `Random` seed and state, `chooseMove` is reproducible.

### 7.2 `quadrim_rating` — pure Dart

Built in 0.1 though unused by the UI until 0.3, because bot calibration needs it immediately.

| Export | Contract |
|---|---|
| `expectedScore(own, opponent)` | `1 / (1 + 10^((opponent − own) / 400))` |
| `kFactor(gamesPlayed)` | 32 below 20 games, 16 at or above |
| `updatedRating(current, k, score, expected)` | Rounded, floored at 100 |

### 7.3 `GameRepository` — the staging seam

The single interface separating the app from where games live. **Release 0.1 implements it locally. Release 0.3 adds a Firestore implementation and the UI does not change.** This is the most important contract in the project.

| Member | Contract |
|---|---|
| `watch(gameId)` | Stream of a single game's state |
| `activeGames()` | Stream of unfinished games |
| `completedGames()` | Stream of finished games, most recent first |
| `create(GameSetup)` | Creates and returns a new game |
| `appendMove(gameId, cell)` | Appends a move; rejects illegal moves and out-of-turn moves |
| `resign(gameId, participant)` | Ends the game as a loss for that participant |
| `delete(gameId)` | Removes a game |

Streams, not futures, even locally — because 0.3's Firestore implementation is push-based, and a future-shaped interface would force a UI rewrite.

### 7.4 `ProfileRepository`

| Member | Contract |
|---|---|
| `watchProfile()` | The local player's identity and aggregate statistics |
| `recordResult(GameResult)` | Updates win/loss/draw totals and per-opponent breakdown |

### 7.5 `tools/linegen` — build-time generator

Not shipped. Emits, from one definition:
- the 76-line table as Dart, for `quadrim_engine`
- the 76-line table as TypeScript, for 0.3's Cloud Functions
- a JSON corpus of complete games with known outcomes, covering every winning-line family, forced draws, and illegal-move cases

Generated files are committed and marked do-not-edit. CI fails if they are stale.

---

## 8. Data

### 8.1 Design rule

Every persisted shape in 0.1 is written **as if it were already a Firestore document**: a flat-ish JSON document with a string id, no local-only primary keys, no relational joins, timestamps in ISO-8601 UTC, and a `schemaVersion`. Migration in 0.3 becomes a transport swap behind `GameRepository`, not a data redesign.

### 8.2 Participant identity

The scheme that makes migration work. A participant is a tagged string:

| Form | Meaning | From |
|---|---|---|
| `local:<deviceId>` | The device owner, pre-account | 0.1 |
| `guest:<n>` | The second seat in pass-and-play | 0.1 |
| `bot:<botId>` | A computer opponent, e.g. `bot:onyx` | 0.1 |
| `user:<uid>` | An authenticated account | 0.3 |

A stable `local:<deviceId>` is generated on first launch and persisted. **In 0.3, anonymous auth adopts this identity rather than replacing it**, so 0.1 history and statistics survive into the account.

### 8.3 Game document

```json
{
  "id": "string",
  "schemaVersion": 1,
  "mode": "vsComputer | passAndPlay | asyncOnline | realtimeOnline",
  "participants": ["local:abc123", "bot:onyx"],
  "startingParticipant": 0,
  "startReason": "random | rematchAlternation",
  "moves": [{ "cell": 27, "by": 0, "at": "2026-07-27T18:04:11Z" }],
  "state": "active | complete",
  "result": {
    "outcome": "win | draw | resign",
    "winner": 0,
    "line": [3, 18, 33, 48]
  },
  "rated": false,
  "rematchOf": "string | null",
  "createdAt": "2026-07-27T18:03:02Z",
  "updatedAt": "2026-07-27T18:09:44Z"
}
```

Notes:
- `moves` is append-only and complete, which is what makes replay a pure function rather than a stored artefact.
- `cell` is the canonical `0..63` index.
- `result.line` holds the four cell indices of the completed line, so highlighting needs no recomputation.
- `rated` is present and always `false` in 0.1. It exists now so 0.3 adds no field.
- Fields 0.3 will add — `clock`, `expiresAt`, `drawOffer`, `ratingDelta` — are deliberately absent rather than stubbed.

### 8.4 Profile document

```json
{
  "id": "local:abc123",
  "schemaVersion": 1,
  "displayName": null,
  "avatarId": "avatar_07",
  "rating": null,
  "provisionalGamesPlayed": 0,
  "totals": { "wins": 0, "losses": 0, "draws": 0 },
  "perOpponent": { "bot:onyx": { "wins": 0, "losses": 2, "draws": 1 } },
  "createdAt": "2026-07-27T17:59:00Z"
}
```

`displayName` and `rating` are null in 0.1 and populated in 0.3.

### 8.5 Bot catalogue — 0.1

Code-side constants, not persisted. From Idea-final.md §6.4.

| Id | Name | Tier | Indicative | Configuration |
|---|---|---|---|---|
| `pebble` | Pebble | Novice | ~600 | Purely random legal moves |
| `mote` | Mote | Novice | ~800 | Win and block when seen; misses them 40% of the time; otherwise random |
| `bramble` | Bramble | Casual | ~1000 | All four strategic rules, 15% blunder rate, no positional sense |
| `ember` | Ember | Casual | ~1300 | All four strategic rules cleanly applied, 8% blunder rate |
| `basalt` | Basalt | Club | ~1400 | Strategic plus full positional rules, 6% blunder rate |
| `onyx` | Onyx | Club | ~1650 | 4-ply alpha-beta over the heuristic evaluation, 3% blunder rate |

Chosen to exercise every engine feature except deep search and the strategy book: random, partial rules, full rules, rules plus positional heuristics, and search.

### 8.6 Settings

```json
{ "schemaVersion": 1, "locale": "en | nl | system", "theme": "light | dark | system", "tutorialCompleted": false }
```

### 8.7 Storage

One JSON document per record, keyed by id, in the platform application-support directory. Writes are atomic — write to a temporary file, then rename — so a kill mid-write cannot corrupt a game. Reads tolerate an unknown `schemaVersion` by refusing to load that record rather than crashing the app.

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

One `chooseMove`, six configurations in 0.1 and twenty by 0.2. Adding an opponent is a catalogue entry. Calibration is a matter of running self-play across configurations rather than across code paths.

### 9.5 Persistence sits behind `GameRepository` from the first commit

Even though 0.1 has exactly one implementation. The interface is the entire staging strategy; introducing it later would mean touching every screen.

### 9.6 Streams, not futures

`GameRepository` is stream-based even for local storage, because Firestore is push-based and a future-shaped API would force a UI rewrite at 0.3.

### 9.7 Riverpod, layered

Three layers: pure domain (`quadrim_engine`, `quadrim_rating`), data (repositories), and presentation (Riverpod notifiers and widgets). Widgets read notifiers; notifiers own repositories; nothing reaches past its neighbour.

### 9.8 The board renders once, adapts twice

One board widget serving both layouts, differing in size and surrounding chrome rather than in structure. Piece rendering takes a shape token as well as a colour, so colourblind-safe rendering is intrinsic rather than a theme variant.

### 9.9 Localisation from the first commit

ARB resource files from commit one; no user-facing string is ever hard-coded. English and Dutch complete in 0.1. Bot names untranslated; tier labels and personality blurbs translated.

### 9.10 The scripted tutorial opponent is a bot configuration

The tutorial's guided opponent is a `BotConfig` with a fixed seed and a scripted opening, not a separate code path. Hints reuse `threats()`.

### 9.11 The first store upload is decoupled from 0.1 being complete

Google Play's 14-day / 12-tester closed-testing requirement runs against **any** uploaded build. The first upload happens as soon as a game is playable end to end — before the tutorial, before Dutch, before the tablet layout — and 0.1 continues shipping into the same track. The clock is the point; the feature set is not.

### 9.12 Application identity is a placeholder until first upload

The application id is recorded as `PLACEHOLDER_APPLICATION_ID` and must be chosen before the first upload. **It is permanent once published and can never be changed.**

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
| F5 | A game against a bot | it completes | it is recorded as unrated |
| F6 | Any completed game | the app restarts | the game is still present and replayable |
| F7 | A pass-and-play game | it is in progress | the current player is unambiguous on screen |
| F8 | A game | resign is chosen | the game ends as a loss for the resigning participant |

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

### 11.5 Data and migration

| # | Criterion |
|---|---|
| D1 | Every persisted document carries a `schemaVersion` |
| D2 | Participants use the tagged-id scheme throughout; no bare device ids |
| D3 | Game documents match §8.3 exactly, including `rated: false` |
| D4 | A kill during a write leaves no corrupted record |
| D5 | An unknown `schemaVersion` causes that record to be skipped, not a crash |
| D6 | The local player identity is stable across restarts |

### 11.6 Release gates for 0.1

| # | Gate |
|---|---|
| R1 | Google Play Console account created and the application id chosen — **permanent once published** |
| R2 | Apple Developer enrolment started (not blocking 0.1, but its clock runs long) |
| R3 | A build uploaded to closed testing, with the 12-tester / 14-day clock started |
| R4 | 12 testers recruited — tracked as a real task, not a formality |
| R5 | Play Data Safety declaration completed. With no accounts, no network, and no analytics, it declares no data collection — this is the easiest it will ever be |
| R6 | Store listing, icon, screenshots, and description in English and Dutch |
| R7 | Release signing configured and the keystore backed up — **a lost keystore cannot be recovered** |
| R8 | Every acceptance criterion in §11.1 to §11.5 passing |

---

## 12. Further Notes

### 12.1 Honest tension in 0.1's scope

0.1 was originally the minimum shippable slice. It now carries the full four-part tutorial, both layouts, and both languages — a materially better first release, but a slower one. §9.11 is the resolution: upload early and incomplete into closed testing so the 14-day clock runs concurrently with the remaining work. If that mitigation is dropped, the clock starts late and Strategy A's main advantage is lost.

### 12.2 Things 0.1 promises that only 0.3 can keep

Idea-final.md §5 rates games against computer opponents. 0.1 has no accounts and therefore no rating. Bot games must be presented as **unrated practice** with indicative strength numbers, and the numbers become live ratings in 0.3. Presenting them as ratings before then would be a lie the data cannot back up.

### 12.3 Bot calibration starts now, lands in 0.3

The indicative ratings in §8.5 are estimates (open item OI-03). The self-play harness built on top of the pure engine is the tool that turns them into calibrated anchors. Worth running well before 0.3, because once published as live ratings they are effectively frozen — correcting an anchor later invalidates every human rating derived from it.

### 12.4 Inherited open items

- **OI-01** — push unsupported on Flutter desktop; first matters at 0.5
- **OI-02** — solver effort and asset size unknown; deliberately deferred to 1.0, with §6.5's fallback ladder as the answer if it proves impractical
- **OI-04** — auto-match cold start; first matters at 0.4
- **OI-05** — Firebase cost model unestimated; first matters at 0.3

### 12.5 Deviations from the to-spec skill

The skill directs no interview and publication to a project issue tracker. Both were overridden by explicit instruction: clarifying questions were requested, and no issue tracker is configured for this repository. The spec's structure follows the skill's template, extended with the Goal, Scope, Exposed Endpoints, Data, and Acceptance Criteria sections requested directly.
