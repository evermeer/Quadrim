# Quadrim — Specification, third edition

The buildable form of [idea-v3.md](idea-v3.md), with the findings from [idea-v3-brainstorming.md](idea-v3-brainstorming.md) folded in. Goal, scope, non-goals, exposed endpoints, data and acceptance criteria.

**This is a successor to [idea-v1-spec.md](tickets/done/idea-v1-spec.md), not a replacement for it.** Section numbers and criterion ids are preserved exactly, because both are cited from source comments (`spec §8.3`, `spec E7`, `criterion S4`, `spec D2/S2`) and from twenty-two completed tickets. Criteria whose *content* changed keep their id and change their text; new criteria are appended; nothing is renumbered. Progression takes a new `P` prefix (D271, D272).

Decisions are in [idea-v3-decisions.md](idea-v3-decisions.md), D218–D306, continuing [idea-v1-decisions.md](tickets/done/idea-v1-decisions.md) D01–D217.

Date: 2026-08-16
Status: **0.1 and 0.2 built** — the complete offline game with its final art, twenty-five tickets. 1.0 specified here and not yet built.

**The release ladder was re-cut on 2026-08-16** (§4.1, D302). Criterion ids are still never renumbered, so criteria that named a release in their text now name a different one; the ▲ marker shows which.

---

## 1. Problem Statement

Four-in-a-row in a 4×4×4 cube is a better game than its flat ancestor and almost nobody plays it. The versions that exist are either abandoned, unreadable on a phone, or offer one difficulty setting that is either trivial or impossible.

Three things make it hard to build well and are the reason most attempts stop. Sixty-four cells and seventy-six winning lines do not fit a phone screen in any obvious way. A believable opponent needs to be *specifically* as strong as it claims rather than merely strong. And a single-player game with no reason to be opened tomorrow is a demo, not a product.

## 2. Solution

A phone game with twenty named computer opponents whose ratings are measured rather than asserted, an unlock ladder that gives the single-player game a spine, and — from 2.0 — asynchronous play against real people.

The offline game is complete, private and makes no network call. The online game is a separate store with a separate rating and a separate trust model. Nothing crosses between them.

## 3. Goal

**Release 1.0 publicly available on at least one store, selling, with the pipeline proven end to end** — and enough players still playing on day ten to say the ladder works.

This goal changed on 2026-08-16 (D302). It used to be "twelve real people playing release 0.1 on their own devices", because Google Play's twelve-testers-for-fourteen-days requirement was the gate to everything and starting that clock was the critical path. That account cannot currently be reactivated, so the gate is now Apple's — TestFlight and store review — and the goal is the public release rather than the private test that used to precede it.

### 3.1 Success criteria

| # | Criterion |
|---|---|
| G1 ▲ | A tester cohort has the pre-1.0 build installed on their own devices and has opened it. **The size is now ours to choose**, not Google's to impose (D302) |
| G2 ▲ | Signed builds are produced and published to a testing track by a repeatable process, **on each platform that has an account** |
| G3 | All twenty opponents are distinguishable in play and calibrated by a self-play harness |
| G4 | A player can complete a whole game from launch to result using a screen reader |
| G5 | The app is complete in English and Dutch, enforced by the build |
| G6 ▲ | **1.0 passes store review and is publicly available.** Superseded "production access is unlocked at the end of the fourteen-day closed test", which was a Play-account concept and is now an Android-only gate (R11) rather than the gate |
| G7 | A player has a real computer rating that moves as they play, computed and stored entirely on their own device |
| **G8** | **A tester unlocks at least one opponent with points they earned.** The single behavioural signal that §7 works; without it the ladder is decoration. Measured by ticket 024's survey (D259) |
| **G9 ＋** | **A purchase completes and restores on a reinstall**, for both the one-time unlock and the subscription. 1.0 is the first release with anything to get wrong here |

## 4. Scope

### 4.1 The release ladder

| Release | Contains | Platforms | Public |
|---|---|---|---|
| **0.1** | The complete offline game: board, all twenty opponents, computer rating, **points, unlocks, quests and streaks**, history and replay, tutorial, settings, both languages | Android | no — closed test |
| **0.2** | Real art, polish | Android | no |
| **1.0** | **iOS, with no new gameplay.** The one-time unlock, the tier-2 subscription and the meter, entitlement read on the device. The Casual-tier roster fix | **+ iOS** | **first public release** |
| **2.0** | Accounts and the cloud repository; async online play, free; invite links; push; chat with block, report and name validation; account deletion; privacy policy. Entitlement and the meter move to the server | Android + iOS | yes |
| **3.0** | Human rating **and** server-side move validation, together. The tier-3 subscription, which makes online play paid | Android + iOS | yes |
| **4.0** | The remaining platforms — web and desktop | + web + desktop | yes |

**Re-cut on 2026-08-16 (D302).** The previous ladder was 0.3a → 0.3b → 0.4 → 1.0 and its critical path ran through a Google Play Console account that cannot currently be reactivated. The new one has no single queue: **1.0 is one version with two release dates**, shipping to each store as that store can accept it, iOS first on today's facts. 0.3a and 0.3b merge into 2.0 because the split existed to keep the first public release off an unfamiliar stack, and 1.0 now does that job. The 1.0 roster revision is gone; its one real item moves into 1.0 (D305).

### 4.2 Release 0.1 — in scope

The board and all four layers drawn at once. Pass-and-play. All twenty computer opponents. The computer rating. **Points, the unlock ladder, quests and streaks.** History, replay and a move scrubber. The tutorial including an interactive practice game. Settings. English and Dutch. Portrait phone only.

### 4.2a Release 1.0 — in scope

Everything 0.2 shipped, on iOS as well as Android, plus exactly four things:

- **The shop.** The one-time unlock at $4.99 and the tier-2 subscription at $1.99/yr, as one subscription product with one base plan so 3.0 can add the second (§4.1 of idea-v3.md).
- **The meter.** Three computer games a day and nine a week after an unmetered first month, counted at game *start*, with the paywall naming the limit that actually bit.
- **Entitlement, read on the device.** No server exists yet; the store's signed transaction is the authority, and the reinstall leak this leaves is documented rather than hidden (D303).
- **The Casual-tier roster fix.** Willow, Vireo and Finch reordered so that price and measured strength agree, confirmed by a calibration run (D305).

Out of scope for 1.0: everything online, every account, the human rating, chat, push. Those are 2.0 and 3.0.

### 4.3 What is already built

Twenty-five tickets are complete: **0.1 and 0.2 are both done**, the second being the art and polish pass in tickets 038–040. Everything below is built; the work that remains is 1.0's.

| Area | Spec section | State |
|---|---|---|
| Line table, win detection, symmetry | §7.1, §11.1 | **Built** — tickets 002, 003; verified exhaustively over all 635,376 four-cell sets |
| Engine, bots, search, strategy book | §7.1, §11.1 | **Built** — tickets 003, 006, 008–010, 025, 026 |
| Rating maths and calibration harness | §7.2, §11.2 | **Built** — tickets 014, 027 |
| Persistence behind the repository | §7.4, §8, §11.5 | **Built** — ticket 005 |
| Board, game screen, scrubber, result | §11.2, §11.3 | **Built** — tickets 004, 007, 012 |
| Opponent selection, tier accordion | §11.3 | **Built** — ticket 011. §8.7 of idea-v3.md asks for an accordion opened at the player's tier; it already is |
| Main screen | §11.3 | **Built, and being restructured** — ticket 013; see §12 |
| Tutorial and practice game | §11.4 | **Built** — tickets 018–020 |
| Settings, attribution | §11.3 | **Built** — ticket 028 |
| Placeholder avatars, opponent content | §11.3 | **Superseded** — ticket 029's drawn identicons existed to be replaced and were, by ticket 038's twenty painted portraits |
| **The look: theme, background, portraits, plaques, fonts, launcher icon** | **§8.16** | **Built** — ticket 038 |
| Build gate | §10 | **Built** — ticket 001 |
| **Points, unlocks, quests, streaks** | **§7.3, §8.8, §11.6** | **Built** — tickets 031–034 |
| **Your Path, trend graph, quests section, end-of-game panel** | **§11.3** | **Built** — tickets 030, 032, 035; revised by 037 |
| Store accounts, testing, survey | §11.7 | **Not built** — tickets 015, 016, 024, re-pointed at Apple by D302 |
| **iOS port, the shop, the meter, the roster fix** | **§4.2a** | **Not built** — 1.0's work, not yet cut into tickets |

## 5. Non-Goals

### 5.1 Out of scope for 0.1, planned later

Online play of any kind. Accounts. The human rating. Chat. Push notifications. Subscriptions, the one-time unlock and the meter. Server-side move validation. iOS.

### 5.2 Out of scope permanently

- **A large-screen or landscape layout.** Cancelled rather than deferred (D253). Ticket 017 is closed unbuilt.
- **Takebacks, undo and draw offers.** A submitted move is final.
- **Any device identifier**, in any release.
- **A network call during computer play**, in any release. On Android, enforced by the absence of the permission rather than by reading the code. **On iOS there is no permission to withhold**, so there it is reviewed rather than enforced, and claimed at that strength (D306, S20).
- **A solver sub-project.** Patashnik solved this in 1980 and the dictionary is obtainable (§7.1).
- **An import path from local storage to the cloud.** Offline games stay local for the life of the app.
- **Ads.**

## 6. User Stories

**Playing (0.1).** As a player I can start a game against any opponent I have unlocked, place a piece with one tap on any empty cell, see all four layers without scrolling, and see immediately when a line completes and which line it was. I can resign with a confirmation step. I can scrub back through the moves of a finished game without altering it.

**Progressing (0.1).** As a player I can see what I have earned, what the next opponent costs, and how close I am to affording them — on the first screen, on first launch, before I have played anything. When a win pays for the next unlock I am told so at the moment it happens, and offered the purchase there rather than made to navigate for it.

**Choosing an opponent (0.1).** As a player I can browse all twenty opponents grouped by tier, opened at the tier my own rating sits in, with each showing its rating, personality, my record against it, and — if locked — its price and my progress. I am warned when a pairing is too lopsided to be a fair test.

**Two humans on one device (0.1).** As two players sharing a phone we can play without either rating or points changing, and it is unambiguous whose turn it is.

**History and progress (0.1).** As a player I can see my record, my rating, my points, my trend over the last ten games, and every finished game with the rating change that game caused — and re-open any of them into replay.

**Learning (0.1).** As a new player I am offered a tutorial once, can decline it permanently, can restart it from settings, and can play a practice game with hints derived from the opponents' own rules.

**Later releases.** Lifting the daily cap by subscribing, and opening the whole roster at once by buying it (1.0); playing a friend asynchronously over days (2.0); a rating earned against real people that neither of us can forge (3.0).

## 7. Exposed Endpoints

Releases 0.1 and 0.2 have **no network surface at all**. The exposed contracts are the public APIs of the modules. Network endpoints appear at 2.0 and are specified in §7.6.

**1.0 is the awkward middle case and is stated rather than left implicit.** It has no endpoint of ours, and it does talk to a store: StoreKit on iOS, Play Billing on Android. That traffic is the platform's, made by the platform's own process on the app's behalf, and it carries no game data of any kind — no result, no rating, no move. §5.2's rule is unchanged and unweakened: no network call happens during computer play.

### 7.1 `quadrim_engine` — pure Dart

No Flutter, no Firebase, no `dart:io`, no ambient clock, no ambient random, and **no runtime dependencies at all**. Enforced by the build gate (§10).

| Export | Contract |
|---|---|
| `Cell` | A board position, from `(x, y, z)` or an index `0..63`. Canonical index `x + 4y + 16z` |
| `Player` | Which side. Two values |
| `GameState` | Immutable. Board, side to move, ordered move list |
| `winningLines` | The 76 lines, as a generated constant. **Never hand-edited** |
| `cellDegree` | 7 for the 8 corners and 8 inner cells, 4 for the other 48. Generated alongside the table |
| `canonicalise(GameState)` | Returns **both** the canonical key **and** the automorphism that produced it. A canonicaliser returning only the key is half-built, and the missing half is found late (§2.3 of idea-v3.md) |
| `CanonicalForm.cellFromCanonical` | Maps a move in canonical orientation back onto the real board. What makes a stored book usable |
| `legalMoves(GameState)` | All empty cells |
| `applyMove(GameState, Cell)` | Next state. Rejects an occupied cell or a move in a finished game |
| `outcome(GameState)` | `ongoing`, `draw`, or `win` carrying **both the winner and the completed line** |
| `threats(GameState, Player)` | Lines with three of `Player` and one empty cell. The primitive behind bot rules and tutorial hints |
| `BotConfig` | The parameter axes of §6.1 of idea-v3.md. **No `locked` field** — entitlement is not an engine concern |
| `chooseMove(BotConfig, GameState, int seed)` | The single bot brain, same function for all twenty. Takes a seed, not a `Random`, so the call can be hosted in an isolate. Returns a future; any transposition table is created and discarded within one call so E7 holds |
| `opponentCatalogue` | The roster as data. **Twenty entries, in roster order.** The list index *is* the roster index §7.3 prices from |
| `strategyBook` | Patashnik's dictionary, vendored byte for byte, keyed in canonical form |

**Invariants.** `applyMove` never mutates its input. `outcome` returning a win always names a line present in `winningLines`. `chooseMove` always returns a member of `legalMoves`. Given the same seed and state, `chooseMove` is reproducible.

**The catalogue's order is load-bearing and its rating field is not.** Point values, unlock costs and per-opponent quest awards are all keyed on the **roster index** — the ordinal position in `opponentCatalogue` — and never on `rating`. §6.4 of idea-v3.md is explicit that the two must not be conflated, and F3 of the brainstorming document is what happens when they are.

### 7.2 `quadrim_rating` — pure Dart

| Export | Contract |
|---|---|
| `expectedScore(own, opponent)` | `1 / (1 + 10^((opponent − own) / 400))` |
| `kFactor(gamesPlayed)` | 32 below 20 games on that ladder, 16 at or above |
| `updatedRating(current, k, score, expected)` | Rounded, floored at 100 |
| `ratingFrom(Iterable<CompletedGame>)` | Folds games ordered by `completedAt`, game id as tie-break, **from the 800 seed**, using each game's stored `opponentRating` |

The seed changed from 1200 to 800 (D226). The human ladder seeds at 1000 and is computed on the server from 3.0.

The human rating is **not** this fold. Human Elo is not separable per player, so recomputing it is a global chronological replay across every account rather than a per-player fold. The maths is shared; the traversal is not.

### 7.3 `quadrim_progression` — pure Dart, new

All the arithmetic of §7 of idea-v3.md. Same purity rules as the other two packages. It depends on `quadrim_engine` for the roster index — the only inter-package dependency in the project, and it runs in the allowed direction (D263).

| Export | Contract |
|---|---|
| `winValue(int rosterIndex)` | `2^i`. Draws and losses are worth nothing |
| `unlockCost(int rosterIndex)` | `2^(i+1)`, which is exactly four wins against opponent `i−1` |
| `isFree(BotConfig)` | Rating ≤ 1000. **A rule, not a count** — nothing anywhere hard-codes "five" |
| `nextUnlock(Set<String> owned)` | The lowest-indexed locked opponent, or null. Only this one may ever be bought |
| `pointsEarned(Iterable<CompletedGame>)` | A fold over the games **and nothing else**. No unlock record is consulted |
| `balance(games, unlocks)` | `pointsEarned(games) − Σ unlock.pricePaid`, **clamped at zero** |
| `questAward(Quest, Iterable<CompletedGame>)` | Per-opponent: `2^i` of the opponent named. Volume and streak: the multiple × `2^round(mean roster index of the qualifying games)` |
| `streak(games, DateTime dayBoundary)` | Consecutive local days with at least one **finished** game against the computer. **The day boundary is passed in, never read** |
| `stars(OpponentRecord)` | None / ★ / ★★ / ★★★ over decisive games only |

**No export takes the player's rating or their current rung.** That is the whole content of D261 and D270, expressed as a type signature: if no function can see how high the player has climbed, no reward can be priced by it.

**`pointsEarned` reads games alone.** Under the rejected current-rung rule an award depended on which opponents were unlocked when it fired, so the fold would have had to interleave games with unlock records in time order. Pricing by the opposition removes the dependency, and with it an ordering hazard and a balance that could not be checked against the game list.

### 7.4 `GameRepository` — the testing seam

Unchanged from the v1 spec except for one addition. The interface is what 2.0's Firestore implementation must satisfy by passing the *same* flow tests the local one passes.

| Member | Contract |
|---|---|
| `watchGame(id)` | Stream of a single game, null if absent or deleted |
| `watchActiveGames()` | Stream of unfinished games |
| `watchCompletedGames()` | Stream of finished games, most recent first |
| `loadCompletedGames()` | One-shot read, so the main screen folds one in-memory list many ways rather than sweeping storage many times |
| `createGame(...)` | Creates and returns a new game |
| `appendMove(id, cell)` | Appends; rejects illegal and out-of-turn moves; **records completion and awards points when the move ends the game** |
| `resign(id, seat)` | Ends the game as a loss for the resigning seat |
| `deleteGame(id)` | Removes a game |
| **`UnlockRepository`** | **New.** `watchUnlocks()`, `loadUnlocks()`, `purchase(opponentId, pricePaid, source)` |

**Points are awarded in the repository, not by the caller.** It is the one place that knows a game has just finished; awarding from a caller means every future caller must remember to. Completion is decided there for the same reason.

Streams, not futures, even locally, because 2.0's implementation is push-based and a future-shaped interface would force a UI rewrite.

### 7.5 `tools/linegen` — build-time generator

Not shipped. Emits from one definition: the 76-line table as Dart; the same table as TypeScript for 2.0's Cloud Functions; and a JSON corpus of complete games with known outcomes covering every winning-line family, forced draws and illegal-move cases. Generated files are committed and marked do-not-edit; the gate fails if they are stale.

### 7.6 Network endpoints — from 2.0 only

Nothing here exists in 0.1, 0.2 or 1.0, and nothing here is ever reached by computer play.

| Surface | From | Contract |
|---|---|---|
| Firebase Authentication | 2.0 | Anonymous to try; **linked to Google, Apple or email before a first rated game or any purchase** |
| Firestore — games | 2.0 | A client may write **only** its own move to a game it is in when it is its turn |
| Firestore — profile | 2.0 | A named, **field-level** allowlist of its own profile fields |
| Cloud Messaging | 2.0 | Your turn, new message, game ended, challenge received, streak about to lapse — each individually toggleable |
| Cloud Function — entitlement | 2.0 | Server-written after receipt validation; revoked on refund, chargeback or voided purchase. **Takes over from 1.0's on-device read**, and the local path is deleted rather than kept as a fallback (D303) |
| Cloud Function — validate | 3.0 | Firestore-triggered. Re-validates every move, detects the win, writes the result and the rating change |

**1.0 has a store-billing surface and no endpoint of ours** — see §7 above.

A client may **never** write results, either rating, entitlement, totals, timestamps, or another player's data.

**Points and unlocks are never network endpoints.** They are earned against deterministic opponents on the player's own hardware, exactly like the computer rating, and moving them to a server would mean sending computer-game results to a server, which §4 forbids categorically. The one thing that must be server-authoritative is the meter, because it gates a purchase.

## 8. Data

### 8.1 Design rule

**Store the simplest correct thing.** Everything derives from the move list: the board, whose turn it is, the outcome, the statistics, the rating, the points balance, the streak and every quest's progress are all folds over stored games. Never store a second copy of something the moves already say — the two drift the first time a game is deleted.

§8.8 records the one place this stops being true and why it had to.

### 8.2 Identity

**There is no device identity, in any release.** No uuid is generated, stored, claimed, backed up or cloned. A game records only who its opponent was: `bot:<botId>`, or `guest` for the second seat in pass-and-play. Seats are positional; which seat the device owner holds is recorded per game because the starting player alternates.

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

Unchanged from the v1 spec, and unchanged by progression — this is the point of pricing quests by the opposition rather than by the player. Notes that remain load-bearing:

- **`moves` is a plain ordered list of cell indices.** Whose move it was derives from list position and `startingSeat`. No per-move author, id or timestamp.
- **`opponentRating` records the anchor this game was actually played against.** Without it, recalibrating an opponent silently rewrites every player's rating history.
- **`completedAt` is the fold's ordering key**, with the game id as tie-break. It orders the rating fold and the points fold alike.
- **`outcome` and `reason` are separate.** A clock-driven ending cannot be derived from the moves.

### 8.4 No profile document

Still deleted. Settings and unlocks are the only local documents besides games.

### 8.5 Opponent catalogue — all twenty

Code-side constants, not persisted. Defined once in §6.4 of idea-v3.md and not duplicated here. What matters to implementation is which engine capability each tier requires:

| Tier | Opponents | Engine capability required |
|---|---|---|
| Novice | Pebble, Twig, Mote, Clover | Random selection; immediate win and block detection; blunder rate; corner preference |
| Casual | Bramble, Willow, Vireo, Finch, Kestrel | All four strategic rules; centre preference; aggression-versus-defence weighting |
| Club | Marlin, Ember, Basalt, Onyx, Sable | Full positional ladder including the building term; 2-ply and 4-ply alpha-beta; threat-space search |
| Expert | Corvus, Lyra, Quartz, Titan | Transposition table; node budgets; **defensive forcing search**; exact solving below 10 empties |
| Master | Oracle, Quadrim Prime | The strategy book from move one; Expert machinery from the second seat |

**Names were permuted at D257 and configurations were not.** Ten opponents changed name so the avatars read as a progression; no rating, configuration, tier or roster index moved. The v1 spec's names for the same slots are historical and are preserved there.

**Tier is stored on each catalogue entry, not derived from its rating** (D179) — otherwise a recalibration silently reclassifies an opponent.

**Both Master opponents hold the book, and it proves a first-player win and nothing else.** No catalogue entry or player-facing string may call either of them perfect without the qualification "unbeatable when it moves first" (D181), and §11.6 requires the unlock confirmation to repeat it.

### 8.6 Settings

```json
{ "schemaVersion": 1, "locale": "en | nl | system", "theme": "light | dark | system",
  "tutorialCompleted": false, "tutorialOffered": false }
```

`tutorialOffered` is separate from `tutorialCompleted` because declining is not the same as having learnt the game, and a dialog dismissed by tapping outside returns no answer — so the offer is recorded *before* it is shown (D193).

Release 2.0 adds `chatAvailability` with values `everyGame`, `friendsOnly` and `never`, defaulting to `friendsOnly`.

The computer rating and the points balance are deliberately **not** here.

### 8.7 Storage

One JSON document per record, keyed by id, under `files/quadrim/` in the platform application-support directory. Writes are atomic — temporary file then rename — so a kill mid-write cannot corrupt a record. A record whose `schemaVersion` is greater than the reader understands is skipped; equal or lower is read and upgraded.

**Backup.** Android's system backup is deliberately enabled, with an **explicit allowlist** committed rather than the platform default. The allowlist is `files/quadrim/`, which already covers games, settings and — from ticket 031 — unlocks, with no manifest change required. At 2.0 this same directory gains Firebase authentication material that must never be restored onto a second device, so the exclusions in S15 become mandatory then.

It follows that **"no data leaves the device" must never appear in any privacy text.** It is false, and the backup is a deliberate trade.

### 8.8 Unlock record — and the rule it breaks

§8.1 says everything derives from the move list. **This is the one place that stops being true.**

Points *earned* is still a fold over stored games. Points *spent* is a decision, and a decision is not in the move list. So one new document exists:

```json
{
  "id": "string",
  "schemaVersion": 1,
  "opponentId": "willow",
  "unlockedAt": "2026-08-14T09:12:31Z",
  "pricePaid": 64,
  "source": "points | purchase"
}
```

- **`pricePaid` is stored for the same reason a game stores the opponent's anchor rating.** Re-tuning a cost later must never retroactively bankrupt someone who already spent at the old price. The balance is *earned minus the sum of prices actually paid*, which is stable under any future change to the cost table.
- **`source`** distinguishes points from the one-time purchase (1.0), so a refund of the purchase can revoke exactly what it bought and nothing a player earned.
- Everything else stays derived. **No stored balance, no stored streak length, no stored quest progress** — all three are folds and all three would drift.
- A downward re-tune of the *quest* table is handled by a rule rather than a second stored table: **the balance clamps at zero and no unlock is ever revoked** (D264).

This record is **the first thing in the app that is not reconstructible from game history**, which is why §8.7's allowlist matters from 0.1 rather than from whenever the cloud arrives.

## 9. Implementation Decisions

### 9.1 Module structure

```
app/                            Flutter. The only place Flutter exists
packages/quadrim_engine/        pure Dart — rules, search, opponents, book
packages/quadrim_rating/        pure Dart — Elo maths
packages/quadrim_progression/   pure Dart — points, costs, quests, streaks, stars   [new]
tools/linegen/                  build-time generator, not shipped
third_party/patashnik/          vendored dictionary + NOTICE.md
```

### 9.2 The pure packages are pure, mechanically

No Flutter, no Firebase, no `dart:io`, no ambient clock, no ambient random source, and no runtime dependencies. Grepped by the build gate over each package's manifest and imports. Purity that is merely intended lasts until the first convenient import.

### 9.3 The 76 lines have exactly one definition

Generated at build time, committed, checked for staleness. Win detection, threat detection, evaluation, the tutorial's illustrations and 3.0's server-side validator all read the same table.

### 9.4 Bots are data

One `chooseMove` parameterised by a `BotConfig`. Adding an opponent is a catalogue entry. Ratings are fixed anchors: **when measurement disagrees with a published rating, the configuration changes and the rating does not** (D144).

### 9.5 Persistence sits behind the repository, and everything is derived

Statistics, the rating, the points balance, the streak and quest progress are folds over `loadCompletedGames()`. Safe because offline history stays local and small — there is no growing cloud collection and therefore no pagination requirement.

### 9.6 Streams, not futures

Even locally, so 2.0's push-based implementation satisfies the same contract without a UI rewrite.

### 9.7 The progression maths is a package, not part of the engine

§7.1 forbids the engine knowing who owns what: the catalogue has no `locked` field, because the strength harness plays all twenty against each other and has no business holding an entitlement. Arithmetic about what a player owns and what it cost belongs on the other side of that line (D263).

### 9.8 The board renders once

**Portrait phone only, orientation locked.** One layout. Geometry derives from the touch target, not the other way round: fix the minimum cell size first and let the board's dimensions follow. Four layers in one column against one edge, not a 2×2 grid — a grid wastes width a portrait phone does not have and produces cells below the minimum touch target on the smallest supported screen.

### 9.9 Localisation from the first commit

All strings in resource files. English and Dutch complete, enforced. Bot names are not translated; blurbs are. Relative dates, point totals and prices are locale-formatted — a thousands separator is not a decoration, and §7.3's numbers reach seven digits.

### 9.10 The tutorial's practice opponent is a bot configuration

And its hints derive from the opponents' own rule ladder rather than being scripted, so they are correct by construction in any position.

### 9.11 Store accounts start immediately; the closed test waits for progression

Ticket 015 has no code dependency and its clocks run long, so it starts on day one. But the fourteen-day closed-test clock waits until §7 is built (D259): a fourteen-day test *is* a measurement of whether people come back, and running it against a build without the ladder measures a product nobody intends to ship.

### 9.12 Android backup is enabled deliberately

With an explicit allowlist (§8.7). From 2.0 the exclusions in S15 are mandatory. iOS has no allowlist to write — it backs up `Documents` by default — so there the same requirement is met by marking those specific files excluded from backup instead (D306).

### 9.13 The three irreversible decisions

The **application id** (`nl.evict.quadrim`), permanent from the first upload to any track including closed testing. The **app name**, against both stores and trademark registers. The **published anchor ratings**, which every recorded result is measured against.

## 10. Testing Decisions

### 10.1 The build gate

One script, run before every commit, that analyses and tests every package and additionally checks what the specification demands but a compiler cannot:

- package purity, per §9.2
- no user-facing string outside the localisation files
- the licence attribution is still rendered somewhere in the app's source
- the vendored dictionary's SHA-256 is unchanged
- generated sources are not stale
- every string exists in **both** languages
- **the release manifest declares no networking permission**

That last one is how "computer play makes no network call" is enforced. Grepping for an HTTP client only checks the spellings you thought of, and a transitive dependency could reach the network without any of them appearing; the **permission** is categorical. When 2.0 genuinely needs networking, narrow the check to computer play rather than deleting it.

**Two things at 1.0 may reach that check earlier than planned** (D306). Play Billing needs `com.android.vending.BILLING`, and whether its manifest merge also injects `INTERNET` must be checked empirically rather than assumed — if it does, the check must narrow one release early. And **iOS has no counterpart at all**: an iOS app may open a socket without declaring anything, so on that platform this guarantee drops from enforced to reviewed. The Android build still proves it, about code both platforms share; that is weaker than a platform refusal and is claimed at its real strength.

Every long run gets a hard timeout. A hung suite is indistinguishable from a slow one.

### 10.2 Seams

- **The engine** is tested directly: it is pure, seeded and deterministic.
- **The repository** is the flow seam. Widget tests must use the in-memory store — `testWidgets` runs in a fake-async zone that never completes real file I/O, so a widget test over the file store hangs.
- **`quadrim_progression`** is tested exhaustively over the whole catalogue rather than by example, because it is small integer arithmetic over twenty known inputs and there is no excuse for sampling it.
- **Calibration** is measurement, not a test. It reports measured against published and never fits a fresh scale.

### 10.3 Injecting the clock

Streak evaluation needs a calendar and the package may not read one, so the day boundary is a parameter. The same applies to the rating fold's tie-break: if game ids are random and two games complete in the same millisecond their order is a coin flip, which is fine for the product and fatal for a fixture that creates games back to back.

## 11. Acceptance Criteria

Criteria carried from the v1 spec keep their ids. Where the content changed the id is kept and the text is replaced, so a source comment citing it still points at the right requirement (D272). Changed criteria are marked **▲**; new ones **＋**.

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
| E8 ▲ | A position with an immediate win available | **Kestrel** chooses | it takes the win |
| E9 ▲ | A position where the opponent wins next move | **Kestrel** chooses | it blocks |
| E10 ▲ | A position with a double-threat cell available | **Marlin** chooses | it plays the double threat |
| E11 | Every game in the generated corpus | replayed | the recorded outcome is reproduced |
| E12 ＋ | Any position | it is canonicalised | both the canonical key **and** the automorphism that produced it are returned |
| E13 ＋ | A book position in any of its 192 orientations | the book move is looked up | the move returned is legal in the *real* orientation, not the canonical one |
| E14 ＋ | Two book opponents | they are duelled | the harness flags the pairing as measuring the seat rather than strength |
| E15 ＋ | Any forcing search | it is run | it is bounded by a node budget, and the budget is shared among the candidates being checked |
| E16 ＋ | An exact-solve request above 16 empty cells | it is made | it is rejected, because above that an exact solve has no horizon and never returns |

E8 and E9 named Ember in the v1 spec, and E10 named Basalt. Those slots are now Kestrel and Marlin (D257); the configurations are unchanged.

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
| F8 | A game | resign is chosen | the game ends as a loss for the resigning seat, after a confirmation step |
| F9 ▲ | A new player with no history | the computer rating is read | it is **800** |
| F10 | A completed game against a computer opponent | the computer rating is recomputed | it moves by the Elo update against that opponent's fixed anchor, K=32 for the first 20 such games and K=16 after |
| F11 | The same set of completed games | the rating is computed twice | both results are identical, because it is a fold and not a stored counter |
| F12 | A pass-and-play game completing | any rating is read | nothing has changed |
| F13 | Any game against a computer opponent | it is played from first move to result | no network call is made at any point |
| F14 ＋ | A move by the strongest opponent | it is chosen on a reference device | it completes within twenty seconds, and a moving indication of thinking is on screen throughout |
| F15 ＋ | A subscription that lapses mid-series *(3.0)* | games in progress finish | they rate normally for both players, one rematch is permitted, and the lapsed player is exempt from the inactivity forfeit |
| F16 ＋ | A player at the daily or weekly cap *(1.0)* | a new computer game is started | it is refused, and the message names **the limit that actually bit** |
| F17 ＋ | A game started and abandoned *(1.0)* | the meter is read | it counted, because a game counts when it is started |

### 11.3 Interface

| # | Criterion |
|---|---|
| U1 ▲ | All four layers and all 64 cells are visible without scrolling, in the one portrait layout |
| U2 | Occupied and empty cells are distinguishable at a glance |
| U3 | One tap on an empty cell places a piece; no confirmation step |
| U4 | Every cell is a reliable touch target on the smallest supported phone — the WCAG 2.5.8 dense-grid floor of 24 dp plus a margin, asserted across the whole supported size range |
| U5 | Pieces are distinguishable with colour vision simulation applied, differing by **lightness** rather than hue |
| U6 | Every cell exposes a screen-reader label naming layer, row, column, and contents |
| U7 | Turn, result, and winning line are announced to a screen reader |
| U8 | The app is legible at the largest system font scale |
| U9 | Board and pieces are legible in light and dark themes |
| U10 ▲ | **The app is portrait-only on every device.** No large-screen layout exists and none is reachable by rotation or resizing |
| U11 | No hard-coded user-facing string exists; English and Dutch are complete |
| U12 ＋ | The last move by **each** side is marked, and each marked piece moves away from its own resting colour rather than towards a shared accent |
| U13 ＋ | Your Path shows three tiles at a time and **scrolls horizontally over the whole roster**; it rests on the lowest-rated opponent rated **strictly above** the player's rating; it clamps at both ends and never shows a hole. Superseded U13 centred it on the next unlock, which a scrollable row makes unnecessary (D287) |
| U13a ＋ | Tapping a Your Path tile opens that opponent's **detail page**; tapping a row in opponent selection still starts a game |
| U13b ＋ | The detail page leads with the avatar at its largest size, then name, rating, tier, blurb, how the pairing sits, the record and stars, and what a win pays |
| U13c ＋ | The detail page ends in one action: **start a game** when unlocked, or the price, the progress and an **unlock** button when not — the same confirmation the other two routes reach |
| U14 ＋ | An opponent never faced shows **no star row at all**, rather than three empty stars |
| U15 ＋ | The trend graph states its change as a **signed number** beside the line, and shows nothing at all below two completed games |
| U16 ＋ | Any rating shown as a bar is zero-based against the top of the catalogue, draws its unfilled track, and shows the number as well |
| U17 ＋ | The quests section shows the four closest to completion, ranked by percentage with ties going to the smaller absolute remainder |
| U18 ＋ | Achieving a quest during a game is acknowledged **when that game ends**, with the points it paid — not silently, and not interrupting play |
| U19 ＋ | The end-of-game panel shows the rating change **that game caused**, the points earned, any quest completed, and — if the win just paid for it — the next unlock, offered there |
| U20 ＋ | Finished-game rows show the result label above the rating change, a relative date, and a challenge button; a change that rounds to zero shows the number alone with no arrow |
| U21 ＋ | The whole main screen reaches its last row at the largest font scale on the smallest supported phone, with all six sections present |
| U22 ＋ | A locked opponent's tile and row are one accessibility node each — name, rating, record, stars, locked state and price — announced once |
| U23 ＋ | Backing out of the opponent list cancels the whole flow rather than falling back to a default opponent |
| U24 ＋ | Every screen sits on the forest background; no screen shows a white or otherwise undesigned surface |
| U25 ＋ | Every one of the twenty opponents draws its own portrait, and a locked one draws as a silhouette rather than a dimmed face |
| U26 ＋ | Every carved sign carries its caption in the player's language, drawn by the app; buttons announce it as their name and headings as a semantic header |
| U28 ＋ | A section listing the four most recently completed quests appears below the closest-four section, with what each paid, and is absent until at least one has been completed |
| U29 ＋ | Every heading sign is drawn at one height and overhangs its panel's top-left corner without being overlapped by the section above; the board is centred; layer captions are readable on both the forest and parchment |
| U27 ＋ | The shipped artwork and fonts together stay under 3 MB, and decorative artwork is not drawn at text scales where it would push a section off the screen |

### 11.4 Tutorial

| # | Criterion |
|---|---|
| T1 | Offered automatically on first launch, and restartable from settings |
| T2 | Exitable at any point without completing |
| T3 | Illustrates at least one example from each of the four winning-line families, with emphasis on the diagonals through layers |
| T4 | Explains the mapping from four parallelograms to one cube |
| T5 | Demonstrates a double threat |
| T6 | The practice game gives hints derived from real threat detection, not scripted text |
| T7 | Completion is persisted so it is not re-offered |
| T8 ＋ | Declining is persisted **separately** from completing, and is recorded *before* the offer is shown, so a dialog dismissed by tapping outside does not re-arm it |
| T9 ＋ | Demonstrations are drawn on the real board widget, and each is described to a screen reader in one sentence rather than sixty-four cell labels |

### 11.5 Data

| # | Criterion |
|---|---|
| D1 | Every persisted document carries a `schemaVersion` |
| D2 | No device identifier is generated, stored, or transmitted anywhere |
| D3 | Game documents match §8.3 exactly |
| D4 | A kill during a write leaves no corrupted record |
| D5 | A `schemaVersion` greater than the reader understands causes that record to be skipped; equal or lower is read and upgraded |
| D6 | Every game id is unique and stable across restarts |
| D7 | Whose move each move was is derivable from list position and `startingSeat`, and matches what the board displays during replay |
| D8 | The tutorial's practice game never reaches storage and never appears in statistics, the completed-games list, any quest, or the meter |
| D9 ▲ | Only games, settings **and unlocks** are backup-eligible, by explicit allowlist rather than platform default |
| D10 ＋ | Unlock documents match §8.8 exactly |
| D11 ＋ | A restore onto a new device returns every unlock the player had earned |
| D12 ＋ | **Nothing but the unlock records is stored.** A test reconstructs the balance, every streak and every quest's progress from game history alone and gets the same answers |

### 11.6 Progression

New section, new prefix.

| # | Given | When | Then |
|---|---|---|---|
| P1 | A win against roster index *i* | points are folded | it pays exactly 2ⁱ |
| P2 | A draw or a loss against any opponent | points are folded | it pays nothing |
| P3 | Opponent *i* | its unlock price is read | it is 2ⁱ⁺¹, which is exactly four wins against opponent *i−1* |
| P4 | The catalogue | the free set is computed | it is exactly those rated 1000 and below, by rule — no constant anywhere encodes "five" |
| P5 | Any locked opponent that is not the lowest-indexed locked one | it is offered for purchase | the purchase is refused |
| P6 | A player with unlocks | the balance is read | it is points earned minus the sum of prices actually paid, **clamped at zero** |
| P7 | An unlock bought at the old price | the cost table is re-tuned | the unlock stands and the balance is unchanged, because the price paid is stored with it |
| P8 | An unlock bought with points | the quest table is re-tuned downward | the unlock is **not revoked**, and the balance clamps at zero rather than going negative |
| P9 | A per-opponent quest against opponent *i* | it is claimed at any point in the player's career | it pays 2ⁱ — the same amount whenever it is claimed |
| P10 | A volume or streak quest | it is awarded | it pays its multiple × 2^round(mean roster index of the qualifying games) |
| P11 | A hundred games against Pebble in one day, by a player who has unlocked Titan | the volume quest is awarded | it pays **four points**, not four Titan wins |
| P12 | Nineteen Pebble games and one Titan game | the average is taken | it is taken over the **roster index**, not the payouts, so the set is worth 2 points and not 6,555 |
| P13 | Any quest | any function in `quadrim_progression` is called | no signature anywhere accepts the player's rating or current rung |
| P14 | Any quest | it is completed twice over | it pays exactly once |
| P15 | A set of completed games | points earned is folded | **no unlock record is read**, and the result is a pure function of the games |
| P16 | A day with at least one **finished** computer game | the streak is evaluated | the day counts. A day with only started games does not |
| P17 | A missed day | the streak is evaluated | it resets to zero, across a month boundary, a year boundary and a time-zone change alike |
| P18 | An ambiguous day boundary after a time-zone change | the streak is evaluated | it is evaluated generously — never break a streak that any reasonable reading would have kept |
| P19 | The streak evaluator | it is called | the day boundary is a parameter; no clock is read inside the package |
| P20 | A pass-and-play game or the tutorial's practice game | it completes | it pays no points and counts toward no quest |
| P21 | Oracle or Quadrim Prime | its unlock is confirmed | the confirmation repeats **"unbeatable when it moves first"**, not merely the store listing |
| P22 | The whole roster | its total cost is summed | it is 2,097,088 points, which is exactly sixty wins |

### 11.7 Release gates for 0.1

0.1 is a **private** release. No production listing, no public availability.

| # | Gate |
|---|---|
| R1 ▲ | The application id chosen — **permanent once published to any track, on either store**. Chosen: `nl.evict.quadrim`. The Google Play Console account it was paired with cannot currently be reactivated, which is what re-cut the plan (D302) |
| R2 ▲ | **Apple Developer enrolment — now the critical path, and not yet started.** A Mac is available and the account is not. No code depends on it and its clock runs long, which is exactly why it is the thing to start first |
| R3 | Release signing configured, upload keystore backed up and the backup **verified by restoring it** |
| R4 | 12 friends-and-family testers recruited and opted into the closed test — a real task with a real lead time |
| R5 | Play Data Safety declaration completed, with the reasoning and the date checked recorded. **A task, not a foregone conclusion**, given that backup is enabled |
| R6 | Content rating questionnaire and target-audience declaration completed. The audience answer silently constrains 1.0 |
| R7 | Closed-testing listing sufficient for testers to install, in English and Dutch |
| R8 | A build published to closed testing, all 12 testers installed and opened it, and the 14-day continuous clock started — with its start date recorded |
| R9 | The tester survey instrument exists and was given to testers **at install**, with its pass thresholds committed in advance |
| R10 ▲ | Every acceptance criterion in §11.1 to **§11.6** passing |
| R11 ▲ | Production access unlocked at the end of the 14 days — **an Android-only gate now, and no longer the gate to going public**. It is what the Android half of 1.0 waits for; the iOS half waits for store review instead (D302) |
| R12 ＋ | **Progression is complete before R8.** The clock starts against a build with the ladder in it, or the one test that could validate it runs against a product nobody intends to ship (D259) |
| R13 ＋ | The survey instrument measures **median time to each unlock** and **the rung at which players stop** — the two signals §7.7 of idea-v3.md names as the first things to instrument |

### 11.7a Release gates for 1.0

1.0 is the **first public** release. Everything in §11.7 that survives is Android-only; these are what the public release itself needs.

| # | Gate |
|---|---|
| R14 ＋ | **Apple Developer enrolment complete**, signing and provisioning configured, and the upload path proven by an actual TestFlight build |
| R15 ＋ | Store products created on both stores: the one-time unlock as a non-consumable, and tier 2 as **one subscription product with one base plan** — the group that 3.0 adds tier 3 to must exist from the first sale (§4.1 of idea-v3.md) |
| R16 ＋ | Price points chosen per country, with tax treatment confirmed. Closes the longest-standing open item |
| R17 ＋ | **A purchase, a restore and a reinstall tested on real hardware on both stores**, in sandbox and then once in production. Closes G9 |
| R18 ＋ | The iOS privacy manifest (`PrivacyInfo.xcprivacy`) and App Store privacy labels completed — declarations about a build that collects nothing, which makes them cheap to write and easy to forget (D306) |
| R19 ＋ | iOS backup verified: unlock records survive a restore onto a different device, matching what the Android allowlist already guarantees (D11) |
| R20 ＋ | **A tester cohort exists and its size and duration were chosen deliberately.** No store imposes either any more, so the discipline the Play requirement used to force must be supplied or it will not happen (D302) |
| R21 ＋ | The Casual-tier roster fix is in, confirmed by `calibrate.dart`, and shipped **before** the first sale — after that it becomes a migration rather than an edit (D305) |
| R22 ＋ | The paywall copy does not claim the 1.0 meter is stronger than it is (D303) |

### 11.8 Security and privacy

**Testable in 0.1:**

| # | Criterion |
|---|---|
| S1 | No network call is made at any point in a game against a computer opponent — cross-references F13 |
| S2 | No device identifier is generated, stored or transmitted — cross-references D2 |
| S3 ▲ | Only games, settings and unlocks are backup-eligible, by explicit allowlist — cross-references D9 |
| S4 | The repository is the only reader and writer of stored data; no screen touches storage directly |
| S5 | The twelve closed testers have been given a written privacy notice covering what is collected, why, who holds it, how long, and how to withdraw. **This is the only personal-data processing release 0.1 has, and it is the developer's, not the app's** |
| S6 | Tester screenshots are deleted once calibration has consumed them |
| S17 ＋ | Points and unlocks are client-written and local **by design**, and no code path sends a computer-game result anywhere |

**Gated on later releases and stated now so they are not invented later:**

| # | Criterion |
|---|---|
| S7 | The adversarial rules suite passes: every listed attempt is denied |
| S8 | The client write allowlist is field-level; ratings, entitlement, totals and timestamps are server-written only |
| S9 ▲ | Entitlement is written only after receipt validation, by the server, and is revoked on refund, chargeback or voided purchase. **From 2.0.** At 1.0 there is no server, so the authority is the store's own signed transaction read on the device and revocation follows the store's refresh (D303) |
| S10 | Invite codes resist enumeration, expire, are single-use, are revocable, and are checked against the creator's block list on join |
| S11 | A block prevents challenge, invite acceptance and profile visibility, checked in the game-creation path |
| S12 | Friendship requires acceptance; friend requests carry no free text and are rate-limited |
| S13 | Account deletion leaves no identifier linking a retained game to the deleted account, and the tombstone is randomly generated per game |
| S14 | Data export returns everything deletion would remove, in a machine-readable form |
| S15 | Firebase auth material, the entitlement cache, the FCM token and the Installations ID are excluded from backup |
| S16 | The backup allowlist is re-verified against the app directory at every release, because a new dependency can add state silently |
| S18 ▲ | The meter is server-authoritative and the free month is held against the account, because it gates a purchase. **From 2.0**, and the 2.0 migration *adopts* the local record rather than restarting the month |
| S19 ＋ | **At 1.0 the meter is local and a reinstall clears it.** Stated as a known limit rather than a defect: closing it needs a device identifier, forbidden by §5.2 in every release, or a server, which is 2.0. No code path may work around this by identifying the device (D303) |
| S20 ＋ | **On iOS, "no network call during computer play" is reviewed, not enforced.** There is no permission to withhold. The Android build's categorical check covers the code both platforms share, and the claim is made at that strength (D306) |

## 12. Build order

Approach **B** with main-screen approach **M2** (D266, D267). Bottom-up was rejected because it finishes with the riskiest part: the arithmetic is small and exhaustively testable whenever it is written, while six sections on the smallest phone at the largest font scale are neither.

| Ticket | Contains | Criteria it closes |
|---|---|---|
| **030** | Main-screen decomposition. `home_screen.dart` splits into per-section files. `_OpponentSection` is **extracted, not deleted** — 032 removes it when Your Path replaces it (D277). `HomeSummary.byOpponent` is kept, because Your Path needs exactly those records. **No behaviour change, no new strings** | none — the diff is provably a move |
| **031** | `quadrim_progression`; point values and unlock costs; points earned as a fold; the balance on the rating card | P1–P4, P15, P20, P22 |
| **032** | The unlock record and its persistence; the purchase; Your Path centred on the next unlock; lock state, price and progress in opponent selection; the unlock confirmation | P5–P8, P21, U13, U14, U22, D10, D11 |
| **033** | All fifty-three quests; the four-closest section; awards priced by the opposition; acknowledgement at end of game | P9–P14, U17, U18 |
| **034** | Streaks: the eight rungs, the injected day boundary, reset across month, year and time-zone boundaries | P16–P19 |
| **035** | The ten-game trend graph; the finished-game row changes; the end-of-game panel; the portrait lock | U10, U15, U19, U20, U21 |
| **037** | Your Path scrolls the whole roster and rests on the rating rather than the unlock; the opponent detail page and its one action | U13, U13a, U13b, U13c |
| **038** | The forest design: one theme, the background on every screen, the twenty painted portraits and their locked silhouettes, the carved plaques, Cinzel and EB Garamond, the new launcher icon, and `tools/artgen` | U24–U27 |
| **039** | Blank signs lettered by the app so the wood is localisable; a carved heading on every section; Your Path's sign overhanging its card; the recently-completed quests panel | U26, U28 |
| **040** | One height for every heading sign, each overhanging its panel; In progress moved under Your Path; Your Path snaps to a tile; a bigger detail avatar; the board centred; readable layer captions on parchment | U26, U29 |

Each of 031–034 crosses every layer, so a real unlock is on screen after 032. The package's *shape* — the signatures in §7.3 — is fixed before 031 starts, so the passes after it extend a settled interface rather than renegotiating one.

**031 was one ticket in an earlier draft of this section and is now two** (D276). Both halves ship without regression, which is the part worth checking rather than assuming: nothing is locked today, so 031 changes no opponent's availability and is purely additive.

**Ticket 030 is one commit that moves code and changes nothing.** That looks like wasted effort in a log and is the opposite: it is what makes the five diffs after it legible.

Disposition of the tickets already open: **015** starts immediately and is the longest lead time on the critical path; **016** sequences behind 030–035 and gains R12; **017** is cancelled by §5.2 and closed unbuilt; **021**'s blockers re-point from 017 and 023 to 032, 033 and 035, and it gains U21 and U22; **022** depends on everything; **023** is absorbed into 033 and closed unbuilt; **024** gains R13 and a threshold for G8. Later releases are not cut into tickets here (D275).

### 12.1 What the re-cut does to the five open tickets

All five were written when Google Play was the only store and its closed test was the gate. None is cancelled; each changes what it points at (D302).

| Ticket | Now |
|---|---|
| **015** Store accounts and release signing | **Split by platform.** The Apple half is the critical path and starts immediately; the Google half is blocked on reactivation and no longer blocks anything else. Gains R14 |
| **016** First closed-test upload | Becomes **first TestFlight upload**, with the Play upload as its Android sibling whenever that account returns |
| **021** Accessibility audit | Unchanged in content, and now runs on two platforms — VoiceOver as well as TalkBack |
| **022** Release readiness | Grows the iOS declarations, R18 and R19, and the store-product gates R15–R17 |
| **024** Closed-test survey and thresholds | Keeps its instrument and loses its imposed cohort. R20 is what replaces the twelve-and-fourteen that used to define it |

### 12.2 The 1.0 tickets

| Ticket | Contains | Criteria it closes |
|---|---|---|
| **041** | The iOS project exists and runs — cold-machine setup, `flutter create --platforms=ios`, bundle id, portrait lock, both locales, a game played on a physical iPhone | R14 (in part) |
| **042** | The iOS app icon and launch screen, generated by `artgen` from the same mark the Android icon uses (D290) | — |
| **043** | iOS parity: iCloud backup of unlock records, the privacy manifest, the VoiceOver pass, and the network claim recorded at its real strength | D11, R18, R19, S20 |
| **044** | The Casual-tier inversion, fixed by moving configurations between rungs rather than moving entries (D309), confirmed by `calibrate.dart` | R21 |
| **045** | The meter: `meter.dart` in `quadrim_progression` (D308), the free-month record, both limits, and which one bit | F16, F17, S19 |
| **046** | The shop: product ids, `in_app_purchase` (D307), entitlement read on the device, restore, and the pending-purchase path | G9, R15, S9 (1.0 form) |
| **047** | The paywall, the purchase screen, restore in settings, and the volume-quest restriction copy that has been waiting for a cap to be true | F16, R22, U20 |
| **048** | TestFlight and the iOS release pipeline; version to `1.0.0+1`; signing; a purchase verified from a TestFlight build | R14, G2 |
| **049** | Store listings, privacy labels, Data Safety, content rating, and the contact-address obligations a public listing brings forward | R16, G6 |

Sequencing: **041 first and 015 in parallel**, because 015 is waiting time and 041 is the only work that unblocks the rest of iOS. 044 and 045 are pure and need no account, no Mac and no store — they are what to build while enrolment is pending. 046 needs both. 049 is last and cannot be done by an agent.

**1.0's work is deliberately not sequenced more tightly than this** (D275 applies unchanged). Four of the nine are blocked on an account whose date nobody controls, and a plan that pretends otherwise is a plan that will be rewritten.

## 13. Further Notes

### 13.1 What this edition reversed, and why it is recorded rather than edited out

**Everything release 0.1 shipped is no longer free forever.** v2 said it was. That sentence was written before there was a business model and could not survive one. Nothing has shipped to a member of the public, so nobody is having anything taken away. What survives is narrower and true: no feature is held back and there are no ads; what is metered is how often a new computer game may be *started*.

**The release ladder was re-cut around a blocked store account, and the old one is left in the record.** 0.3a → 0.3b → 0.4 → 1.0 became 1.0 → 2.0 → 3.0 → 4.0 on 2026-08-16 (D302). Nothing about the *game* changed; what changed is that a plan whose critical path ran through an account nobody controls was replaced by one that ships to each store as that store becomes able to accept it. Two things got harder in the process and are recorded rather than absorbed: the meter now lands in the first public release instead of the fourth (§4.2 of idea-v3.md), and entitlement is on-device for one release (D303).

**Online play will be free before it is paid, and says so from the start.** 2.0 ships it free because the rating that makes it worth buying arrives at 3.0. Announcing the future price on day one is the direct lesson of the free-forever sentence above (D304).

**The large-screen layout is cancelled, not deferred.** A second set of screens to design, build, test at every font scale and keep correct, for a form factor nobody has asked for. Coming back later is cheaper than carrying it unused.

**Two quest-pricing rules were tried and both were wrong**, in opposite directions, and both are kept in §7.4 of idea-v3.md as rejected options rather than quietly replaced. Pricing at the player's current rung lets the cheap quests be banked — eight games against opponents that move at random would have paid twice the cost of the entire roster. Leaving the volume family on that rule made a hundred Pebble games in a day pay four Titan wins. Both are the same mistake: §7.3's shape exists so that grinding downward prices itself out without a rule, and a reward priced by the player's height reintroduced the exploit in the one place that shape was not looking.

### 13.2 What is still open

Every item is a business, account or measurement decision. **None is functional, and none blocks building the game.**

| Item | Why it is open |
|---|---|
| Store price points | $1.99 and $4.99 are intended; store tiers, tax treatment and per-country equivalents are not chosen. **Needed before 1.0**, which is three releases sooner than it used to be. Gates R16 |
| **Apple Developer enrolment** | **The critical path for 1.0 and not yet started.** Mac available, account not. Gates R14, and through it everything else in §11.7a (D302) |
| **The Google Play Console account** | Cannot currently be reactivated. It now blocks only the Android half of 1.0, which is the entire point of the re-cut. Gates R11 |
| **Whether Play Billing forces the INTERNET permission** | Decides whether `check.sh` keeps its categorical form on Android at 1.0. **Check empirically; assume neither answer** (D306) |
| **The 1.0 tester cohort** | No store imposes a size or a duration any more. Gates R20, and with it whether R13's two signals are ever measured (D302) |
| App name availability | Against both stores and trademark registers. Not yet done |
| The reference device | The twenty-second ceiling is a device number and the node-to-seconds conversion must be confirmed on real hardware. Gates F14 |
| The progression numbers | The shape is settled; the values are derived from a stated target rather than measured. First thing to instrument. Gates R13 |
| ~~Two Casual-tier rating inversions~~ | **Closed by ticket 044**, and not by the mechanism D305 predicted. `aggression` left the Casual tier (D314) and `calibrate.dart` began playing every within-tier pair instead of only adjacent ones (D313) — the second mattered more, because the tier is **intransitive** and a chain of adjacent measurements cannot see a cycle. Measured now: 946, 1137, 1236, 1261, 1275 against published 1000, 1100, 1200, 1250, 1300, every rung inside tolerance and in order. The cycle itself remains and is caused by the square-preference axis rather than by aggression (D315). Closed R21 |
| The remaining OI items | OI-06 through OI-27 in the v1 spec §12.4 are unchanged and still gate their stated releases |

### 13.3 Deviations from the requested process

Three clauses of the prompt that produced this document came from the v1 version of it and do not carry over. They are recorded here rather than silently reinterpreted (D274).

- **The `to-spec` skill is not available** in this environment. The structure below follows the sections requested directly — goal, scope, non-goals, exposed endpoints, data, acceptance criteria — which is what that skill produced for the v1 spec.
- **"Strategy A" does not exist in the v3 brainstorming document.** Its approach A — bottom-up — was explicitly rejected. The chosen approaches are **B** and **M2**, and §12 follows them.
- **The six suggested bots are v1's roster.** v3 has twenty, all built and calibrated, and §7 of idea-v3.md prices both wins and unlocks over roster index 0–19. Cutting to six would have deleted fourteen implemented opponents and required rewriting the whole economy.
