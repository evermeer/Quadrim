# Quadrim — Specification, fourth edition

The buildable form of [idea-v4.md](idea-v4.md). Goal, scope, non-goals, exposed endpoints, data and acceptance criteria.

**This is a successor to [idea-v3-spec.md](history/idea-v3-spec.md) and, through it, to [idea-v1-spec.md](tickets/done/idea-v1-spec.md) — not a replacement for either.** Section numbers and criterion ids are preserved exactly, because both are cited from source comments (`spec §8.3`, `spec E7`, `criterion S4`, `spec D2/S2`) and from more than fifty completed tickets. Criteria whose *content* changed keep their id and change their text; new criteria are appended; **nothing is ever renumbered**.

The decisions that produced this edition and its two predecessors are archived in [history/idea-v3-decisions.md](history/idea-v3-decisions.md) (D218–D391) and [tickets/done/idea-v1-decisions.md](tickets/done/idea-v1-decisions.md) (D01–D217). Every `(Dnnn)` below resolves there. New decisions continue at D392 in [idea-v4-decisions.md](idea-v4-decisions.md).

Date: 2026-09-21
Status: **The offline game is built, sold and public.** 0.1.3 is on the App Store; 0.2.0 adds platform game services and is in TestFlight and Play closed testing. The online releases (2.0, 3.0) are specified and not built.

Markers: **▲** the id is unchanged and the text is not. **＋** new since the v1 spec. **△** the criterion holds and what enforces it has changed.

---

## 1. Problem Statement

Four-in-a-row in a 4×4×4 cube is a better game than its flat ancestor and almost nobody plays it. The versions that exist are either abandoned, unreadable on a phone, or offer one difficulty setting that is either trivial or impossible.

Three things make it hard to build well and are the reason most attempts stop. Sixty-four cells and seventy-six winning lines do not fit a phone screen in any obvious way. A believable opponent needs to be *specifically* as strong as it claims rather than merely strong. And a single-player game with no reason to be opened tomorrow is a demo, not a product.

## 2. Solution

A phone game with thirty-one named computer opponents whose ratings are measured rather than asserted, an unlock ladder that gives the single-player game a spine, and — from 2.0 — asynchronous play against real people.

The offline game is complete and private: **no network call is made during a game against a computer opponent**, in any release. The online game is a separate store with a separate rating and a separate trust model. Nothing crosses between them.

## 3. Goal

**A public release, selling, with the pipeline proven end to end — and enough players still playing on day ten to say the ladder works.**

The first half is met. The second half is not, and cannot now be measured for this release (§13.2) — which is a property of the release rather than an open task.

### 3.1 Success criteria

| # | Criterion | State |
|---|---|---|
| G1 ▲ | A tester cohort has a pre-release build installed on their own devices and has opened it. **The size is ours to choose**, not a store's to impose | met |
| G2 ▲ | Signed builds are produced and published to a testing track by a repeatable process, **on each platform that has an account** | met |
| G3 | All thirty-one opponents are distinguishable in play and calibrated by a self-play harness | **partly** — calibrated, and several neighbouring rungs are not distinguishable in play (§13.2) |
| G4 | A player can complete a whole game from launch to result using a screen reader | met |
| G5 | The app is complete in English and Dutch, enforced by the build | met |
| G6 ▲ | The app passes store review and is publicly available | met on one store |
| G7 | A player has a real computer rating that moves as they play, computed and stored entirely on their own device | met |
| G8 | **A tester unlocks at least one opponent with points they earned.** The single behavioural signal that §7.3 of idea-v4.md works; without it the ladder is decoration | **not measured** (§13.2) |
| G9 ＋ | **A purchase completes and restores on a reinstall**, for both the one-time unlock and the subscription | purchase met on one store; restore open |
| G10 ＋ | **A player signs in to platform game services and sees the achievements they had already earned**, not an empty shelf | open — needs the platform capability and the console entries (§13.2) |

## 4. Scope

### 4.1 The release ladder

| Release | Contains | Platforms | Public |
|---|---|---|---|
| **0.1** | The complete offline game: board, all thirty-one opponents, computer rating, points, unlocks, quests and streaks, history and replay, tutorial, settings, both languages | Android | no |
| **0.2 (art)** | Real art, polish | Android | no |
| **0.1.x** | iOS. The one-time unlock, the subscription and the meter, entitlement read on the device. The cube board. Terms and privacy in the binary | **+ iOS** | **first public release** |
| **0.2.0** | Platform game services (§7.7); the review prompt; the mercy rungs | Android + iOS | in testing |
| **2.0** | Accounts and the cloud repository; async online play, free; invite links; push; chat with block, report and name validation; account deletion; privacy policy. Entitlement and the meter move to the server | Android + iOS | yes |
| **3.0** | Human rating **and** server-side move validation, together. The online subscription, which makes online play paid | Android + iOS | yes |
| **4.0** | The remaining platforms — web and desktop | + web + desktop | yes |

**The ladder was re-cut once around a store account nobody controlled** (D302), and the shape of the fix is the part worth keeping: **one version, two release dates**, shipping to each store as that store can accept it. Two independent queues cannot both be stopped by one account. What it cost is in §13.1.

**The version names in the tickets and in the artefact disagree** (D372, D387). Tickets 015–049 call the first public release "1.0"; it shipped as 0.1.3, and the game-services release took 0.2.0 because a capability the previous build did not have at all is not a last-number bump. Nothing is broken — no store reads the version name for anything but display — and the disagreement is a documented confusion rather than a defect.

### 4.2 What is in scope, and when it arrived

**The offline game.** The board and all four layers drawn at once, plus a second rotatable cube board. Pass-and-play. All thirty-one computer opponents, three open on a first launch and three more opening by losing. The computer rating. Points, the unlock ladder, quests and streaks. History, replay and a move scrubber. The tutorial including an interactive practice game. Settings. English and Dutch. Portrait phone only.

**The shop.** The one-time unlock and the subscription, as one subscription product with one base plan so 3.0 can add the second. Entitlement read from the store on the device, with the reinstall leak that leaves documented rather than hidden (D303). The meter: three computer games a day and nine a week after an unmetered first month, counted at game *start*, with the paywall naming the limit that actually bit. Terms of use and privacy links **in the binary**, on the purchase screen as well as in settings (D384).

**Platform game services.** Sign-in, one leaderboard carrying the computer rating, and forty-six achievements. All best-effort, all optional, and an app that is identical for a player who never signs in (§7.7).

**Out of scope until 2.0 and 3.0:** everything online, every account, the human rating, chat, push.

### 4.3 What is built

Every ticket from 001 to 051 is complete except **022** (release readiness) and **051** (cloud save, challenges and friends, which belongs to a later release).

| Area | Spec section | State |
|---|---|---|
| Line table, win detection, symmetry | §7.1, §11.1 | **Built** — verified exhaustively over all 635,376 four-cell sets |
| Engine, bots, search, strategy book | §7.1, §11.1 | **Built** |
| Rating maths and calibration harness | §7.2, §11.2 | **Built** |
| Persistence behind the repository | §7.4, §8, §11.5 | **Built** |
| Layered board, game screen, scrubber, result | §11.2, §11.3 | **Built** |
| **Cube board and the display toggle** | **§11.3** | **Built** |
| Opponent selection, tier accordion, opponent detail | §11.3 | **Built** |
| Main screen, Your Path, trend graph, quests, end of game | §11.3 | **Built** |
| Tutorial and practice game, including the cube intro | §11.4 | **Built** |
| Settings, attribution, terms and privacy links | §11.3 | **Built** |
| The look: theme, background, portraits, signs, fonts, icons | §11.3 | **Built** |
| Build gate | §10 | **Built** |
| Points, unlocks, quests, streaks | §7.3, §11.6 | **Built** |
| **The mercy rungs** | **§7.3, §11.6** | **Built** |
| iOS project, icon, launch screen, parity pass | §9.14 | **Built** |
| The meter | §7.3, §11.2 | **Built** |
| The shop, the paywall, restore | §7.3, §11.3 | **Built**; restore untested on hardware |
| TestFlight and the release pipeline | §11.7 | **Built** |
| Store listings, declarations, privacy labels | §11.7 | **Built**, and the privacy declarations must be revised for game services |
| **Platform game services** | **§7.7, §11.9** | **Built**; not reachable until the platform capability and the console entries exist |
| **The review prompt** | **§7.8** | **Built** |
| Release readiness (022) | §11.7a | **Open** |
| Accounts, cloud repository, online play | §7.6 | **Not built** — 2.0 |

## 5. Non-Goals

### 5.1 Out of scope now, planned later

Online play of any kind. Accounts. The human rating. Chat. Push notifications. Server-side move validation.

### 5.2 Out of scope permanently

- **A large-screen or landscape layout.** Cancelled rather than deferred (D253). **A build that declares tablet support must declare all four orientations**, and modern SDKs have removed the escape hatch that let a tablet app refuse multitasking and keep an orientation lock — so the build declares phone only (D360, U10).
- **Takebacks, undo and draw offers.** A submitted move is final.
- **Any identifier generated or stored by this app**, in any release (D2, S2).
- **A network call during a game against a computer opponent**, in any release. **No longer enforced by a platform mechanism on either platform** — see S1, F13, S20 and §10.1.
- **A solver sub-project.** Patashnik solved this in 1980 and the dictionary is obtainable (§7.1).
- **An import path from local storage to the cloud.** Offline games stay local for the life of the app.
- **A third-party subscription or entitlement service** (D307). Every candidate assigns each installation a persistent app-user id, which is a device identifier by any reading that matters.
- **Incremental achievement reporting** (§7.7). A number sent on every game rather than an event sent when something becomes true.
- **Ads.**

## 6. User Stories

**Playing.** As a player I can start a game against any opponent I have unlocked, place a piece with one tap on any empty cell, see all four layers without scrolling — or turn the whole cube if I prefer — and see immediately when a line completes and which line it was. I can resign with a confirmation step. I can scrub back through the moves of a finished game without altering it.

**Progressing.** As a player I can see what I have earned, what the next opponent costs, and how close I am to affording them — on the first screen, on first launch, before I have played anything. When a win pays for the next unlock I am told so at the moment it happens, and offered the purchase there rather than made to navigate for it.

**Starting out.** As a new player the first opponent I meet is one I might actually lose to, and if I do lose, an easier one appears — without the game having told me in advance that it was holding something back.

**Choosing an opponent.** As a player I can browse the opponents grouped by tier, opened at the tier my own rating sits in, with each showing its rating, personality, my record against it, and — if locked — its price and my progress. I am warned when a pairing is too lopsided to be a fair test.

**Two humans on one device.** As two players sharing a phone we can play without either rating or points changing, and it is unambiguous whose turn it is.

**History and progress.** As a player I can see my record, my rating, my points, my trend over the last ten games, and every finished game with the rating change that game caused — and re-open any of them into replay.

**Learning.** As a new player I am offered a tutorial once, can decline it permanently, can restart it from settings, and can play a practice game with hints derived from the opponents' own rules.

**Comparing.** As a player I can put my computer rating on a platform leaderboard and collect achievements for what I have already done — and if I never sign in, nothing in the app is missing or broken.

**Paying.** As a player I can lift the daily cap by subscribing, or open the whole roster at once by buying it, and each product tells me plainly what it does not do.

**Later releases.** Playing a friend asynchronously over days (2.0); a rating earned against real people that neither of us can forge (3.0).

## 7. Exposed Endpoints

The offline releases have **no network surface of ours at all**. The exposed contracts are the public APIs of the modules.

**Three kinds of platform traffic exist and none of them is an endpoint of ours.** Store billing (StoreKit, Play Billing) carries no game data of any kind — no result, no rating, no move. Platform game services carry a score and achievement unlocks, **after** a game is scored (§7.7). A store-review request carries nothing. §5.2's rule is unchanged: no network call happens during a game against a computer opponent.

### 7.1 `quadrim_engine` — pure Dart

No Flutter, no Firebase, no `dart:io`, no ambient clock, no ambient random, **no platform-service plugin**, and **no runtime dependencies at all**. Enforced by the build gate (§10).

| Export | Contract |
|---|---|
| `Cell` | A board position, from `(x, y, z)` or an index `0..63`. Canonical index `x + 4y + 16z` |
| `Player` | Which side. Two values |
| `GameState` | Immutable. Board, side to move, ordered move list |
| `winningLines` | The 76 lines, as a generated constant. **Never hand-edited** |
| `cellDegree` | 7 for the 8 corners and 8 inner cells, 4 for the other 48. Generated alongside the table |
| `canonicalise(GameState)` | Returns **both** the canonical key **and** the automorphism that produced it. A canonicaliser returning only the key is half-built, and the missing half is found late (§2.3 of idea-v4.md) |
| `CanonicalForm.cellFromCanonical` | Maps a move in canonical orientation back onto the real board. What makes a stored book usable |
| `legalMoves(GameState)` | All empty cells |
| `applyMove(GameState, Cell)` | Next state. Rejects an occupied cell or a move in a finished game |
| `outcome(GameState)` | `ongoing`, `draw`, or `win` carrying **both the winner and the completed line**. **The only thing that says a game was drawn** — a resigned game is complete and is not a draw (D386) |
| `threats(GameState, Player)` | Lines with three of `Player` and one empty cell. The primitive behind bot rules and tutorial hints |
| `BotConfig` | The parameter axes of §6.1 of idea-v4.md, including `ruleChance` and `positionChance`. **No `locked` field** — entitlement is not an engine concern |
| `chooseMove(BotConfig, GameState, int seed)` | The single bot brain, same function for all thirty-one. Takes a seed, not a `Random`, so the call can be hosted in an isolate. Returns a future; any transposition table is created and discarded within one call so E7 holds |
| `opponentCatalogue` | The roster as data. **Thirty-one entries, in roster order.** The list index *is* the roster index §7.3 prices from |
| `strategyBook` | Patashnik's dictionary, vendored byte for byte, keyed in canonical form |

**Invariants.** `applyMove` never mutates its input. `outcome` returning a win always names a line present in `winningLines`. `chooseMove` always returns a member of `legalMoves`. Given the same seed and state, `chooseMove` is reproducible.

**The catalogue's order is load-bearing and its rating field is not.** Point values, unlock costs and per-opponent quest awards are all keyed on the **roster index** and never on `rating`. §6.4 of idea-v4.md is explicit that the two must not be conflated.

**`ruleChance` and `positionChance` are inert at their defaults** (D343). A chance of 1 draws no random number, so an opponent that predates them does not move by a single move. A test pins that property rather than trusting it, because it is what lets the mechanism ship without re-measuring the roster.

### 7.2 `quadrim_rating` — pure Dart

| Export | Contract |
|---|---|
| `expectedScore(own, opponent)` | `1 / (1 + 10^((opponent − own) / 400))` |
| `kFactor(gamesPlayed)` | 32 below 20 games on that ladder, 16 at or above |
| `updatedRating(current, k, score, expected)` | Rounded, floored at 100 |
| `ratingFrom(Iterable<CompletedGame>)` | Folds games ordered by `completedAt`, game id as tie-break, **from the 800 seed**, using each game's stored `opponentRating` |

The human ladder seeds at 1000 and is computed on the server from 3.0. **The human rating is not this fold.** Human Elo is not separable per player, so recomputing it is a global chronological replay across every account rather than a per-player fold. The maths is shared; the traversal is not.

### 7.3 `quadrim_progression` — pure Dart

All the arithmetic of §7 of idea-v4.md, **plus the meter** (D308). Same purity rules as the other two packages. It depends on `quadrim_engine` for the roster index — the only inter-package dependency in the project, running in the allowed direction.

| Export | Contract |
|---|---|
| `winValue(int rosterIndex)` | The `i`th rung of the Fibonacci ladder 1, 2, 3, 5, 8 … Draws and losses are worth nothing |
| `unlockCost(int rosterIndex)` | Twice `winValue(i)` — about 3¼ wins against opponent `i−1` |
| `isPurchasable(int rosterIndex)` | False for the mercy rungs and for anything already free. **One predicate, not three copies of a condition** (D382) |
| `nextUnlockIndex(Set<String> owned)` | The lowest-indexed *purchasable* locked opponent, or null. Only this one may ever be bought |
| `mercyUnlocks(Iterable<ScoredGame>)` | The held-back rungs a player has opened, **derived**: each opens when the rung above it has beaten the player at least once, and any the player has already played is granted |
| `fullRosterCost` | The sum over purchasable rungs only |
| `pointsEarned(Iterable<ScoredGame>)` | A fold over the games **and nothing else**. No unlock record is consulted |
| `balance(games, unlocks)` | `pointsEarned(games) − Σ unlock.pricePaid`, **clamped at zero** |
| `questAward(Quest, Iterable<ScoredGame>)` | Per-opponent: `winValue(i)` of the opponent named. Volume and streak: `multipleQuarters × winValue(round(mean roster index of the qualifying games)) ÷ 4`, floored, **clamped up to 1** |
| `streak(games, DateTime dayBoundary)` | Consecutive local days with at least one **finished** game against the computer. **The day boundary is passed in, never read** |
| `meterState(Iterable<StartedGame>, FreeMonth?, DateTime dayBoundary)` | Which limit, if any, currently bites. **Reads starts, not completions** (D310) |
| `stars(OpponentRecord)` | None / ★ / ★★ / ★★★ over decisive games only |
| `shouldAskForReview({settings, won, playedCount, now})` | Pure. §7.8 |

**No export takes the player's rating or their current rung.** That is D261 and D270 expressed as a type signature: if no function can see how high the player has climbed, no reward can be priced by it. **A meter needs neither**, which is why it fits here without weakening the invariant.

**`StartedGame` is a named type over a bare timestamp, deliberately** (D310). A function taking a list of dates accepts a list of *completion* times silently, and the entire correctness of the meter is that it does not get those.

**Quest multiples are integers over a fixed denominator of four**, never floating point (D280). All four families run through one award function because all four express their multiple the same way.

### 7.4 `GameRepository` — the testing seam

The interface is what 2.0's Firestore implementation must satisfy by passing the *same* flow tests the local one passes.

| Member | Contract |
|---|---|
| `watchGame(id)` | Stream of a single game, null if absent or deleted |
| `watchActiveGames()` | Stream of unfinished games — **all of them**, including the ones the screen filters out (D321) |
| `watchCompletedGames()` | Stream of finished games, most recent first |
| `loadCompletedGames()` | One-shot read, so the main screen folds one in-memory list many ways rather than sweeping storage many times |
| `createGame(...)` | Creates and returns a new game |
| `appendMove(id, cell)` | Appends; rejects illegal and out-of-turn moves; **records completion and awards points when the move ends the game** |
| `resign(id, seat)` | Ends the game as a loss for the resigning seat |
| `deleteGame(id)` | Removes a game |
| `UnlockRepository` | `watchUnlocks()`, `loadUnlocks()`, `purchase(opponentId, pricePaid, source)`, **`grantAllPurchased()`**, **`revokePurchasedUnlocks()`** |

**Points are awarded in the repository, not by the caller.** It is the one place that knows a game has just finished; awarding from a caller means every future caller must remember to. Completion is decided there for the same reason.

**`purchase` enforces "only the next one" categorically, and the one-time unlock gets its own method** (D350). A flag on `purchase` would make the rule conditional in the one place that enforces it, and the flag's default would become the only thing standing between the ladder and a caller that passes `true` for an unrelated reason. **`revokePurchasedUnlocks` deletes records whose source is the purchase and nothing else**, and no code path reaches it from a subscription event — which is how "a lapse never revokes an unlock" is guaranteed rather than promised.

Streams, not futures, even locally, because 2.0's implementation is push-based and a future-shaped interface would force a UI rewrite.

### 7.5 `tools/linegen` — build-time generator

Not shipped. Emits from one definition: the 76-line table as Dart; the same table as TypeScript for 2.0's Cloud Functions; and a JSON corpus of complete games with known outcomes covering every winning-line family, forced draws and illegal-move cases. Generated files are committed and marked do-not-edit; the gate fails if they are stale.

### 7.6 Network endpoints — from 2.0 only

Nothing here exists yet, and nothing here is ever reached during computer play.

| Surface | From | Contract |
|---|---|---|
| Firebase Authentication | 2.0 | Anonymous to try; **linked to Google, Apple or email before a first rated game or any purchase** |
| Firestore — games | 2.0 | A client may write **only** its own move to a game it is in when it is its turn |
| Firestore — profile | 2.0 | A named, **field-level** allowlist of its own profile fields |
| Cloud Messaging | 2.0 | Your turn, new message, game ended, challenge received, streak about to lapse — each individually toggleable |
| Cloud Function — entitlement | 2.0 | Server-written after receipt validation; revoked on refund, chargeback or voided purchase. **Takes over from the on-device read**, and the local path is deleted rather than kept as a fallback |
| Cloud Function — validate | 3.0 | Firestore-triggered. Re-validates every move, detects the win, writes the result and the rating change |

A client may **never** write results, either rating, entitlement, totals, timestamps, or another player's data.

**Points and unlocks are never network endpoints.** They are earned against deterministic opponents on the player's own hardware, exactly like the computer rating, and moving them to a server would mean sending computer-game results to a server, which §5.2 forbids categorically. The one thing that must be server-authoritative is the meter, because it gates a purchase.

### 7.7 Platform game services — `GameServicesPlatform`

An interface this app owns over the platform plugin, for the same reason `PurchasePlatform` exists: the part that talks to a store must be testable without one.

| Member | Contract |
|---|---|
| `isSignedIn()` | Whether a session exists |
| `signIn()` | Signs in, or **throws**. §10.1 |
| `submitScore(...)` | The computer rating, after a game is scored |
| `unlock({androidId, iosId})` | One achievement. Idempotent on both stores |
| `showLeaderboard({androidLeaderboardId, iosLeaderboardId})` | Presents the platform's own view, or **throws** |
| `showAchievements()` | Presents the platform's own view, or **throws** |

And over it, the service the app uses:

| Member | Contract |
|---|---|
| `usable` | **Whether the platform is configured at all.** Controls are gated on this, never on the service object existing (D390) |
| `available` | Whether a session exists right now |
| `offerSignIn()` | The one-time unprompted dialog. Returns the player's answer |
| `reportQuests(newlyAchieved)` | The end-of-game diff |
| `reportDraw()` | The one achievement with no quest behind it (D386) |
| `backfill(alreadyAchieved)` | **Everything already earned**, replayed once per session after a successful sign-in |
| `submitRating(int)` | After a game is scored |
| `openLeaderboard()` / `openAchievements()` | Sign in if needed, then present. **Return whether a view actually opened** — a plain fact, never an answer to store (D391) |

**Five contracts that are not optional, because breaking any one of them makes a completely broken integration invisible** (D390, D391):

1. **A returned error is turned into an exception at the adapter boundary.** The underlying plugins report failure by *returning a message*, not by throwing, and a best-effort layer that swallows exceptions is worth nothing if the thing it swallows never throws.
2. **A refusing platform is never recorded as a declining player.** Only the dialog's own yes or no is stored.
3. **A refused open tells the player something.** Best-effort means never interrupting a *game*; it does not mean a silent control.
4. **Controls are hidden when `usable` is false**, and drawn only where the platform can honour them. A control that does nothing is worse than an absent one.
5. **Sign-in backfills.** Reporting is a diff, so a player signed out until now has had nothing sent, and signing in later does not retroactively unlock anything. Without the backfill, the first thing a newly signed-in player sees is an empty shelf behind a fortnight of play.

**Nothing is incremental and nothing is persisted.** No identifier the platform issues is stored by this app or enters a Quadrim document (D2, S2, D377).

### 7.8 `ReviewPlatform` and the review decision

| Export | Contract |
|---|---|
| `ReviewPlatform.isAvailable()` / `.request()` | The platform's own review sheet, behind an interface |
| `shouldAskForReview({settings, won, playedCount, now})` | Pure. True only on a win, at or above the minimum game count, below the maximum number of asks, and at or past the interval since the last ask |
| `ReviewPrompt.maybeAsk(...)` | Records the attempt **even when the sheet certainly did not appear**, and returns the settings to persist |

**Neither platform reports whether the player rated**, by design, and both silently do nothing when over quota (D389). So the app records the only fact it has — that it asked, and when — and the rule is *ask three times, ninety days apart, then stop*. The comparison is *not before* rather than a subtraction, so a clock corrected backwards answers no rather than asking on every win until it catches up.

## 8. Data

### 8.1 Design rule

**Store the simplest correct thing.** Everything derives from the move list: the board, whose turn it is, the outcome, the statistics, the rating, the points balance, the streak, every quest's progress and the mercy unlocks are all folds over stored games. Never store a second copy of something the moves already say — the two drift the first time a game is deleted.

§8.8 records where this stops being true and why.

### 8.2 Identity

**The app generates no identifier and stores none.** Where a platform service identifies the player — game services, a store account — that identifier is the platform's, is never persisted by this app, and never enters a Quadrim document (D377, D2, S2).

A game records only who its opponent was: `bot:<botId>`, or `guest` for the second seat in pass-and-play. Seats are positional; which seat the device owner holds is recorded per game because the starting player alternates.

### 8.3 Game document

```json
{
  "id": "string",
  "schemaVersion": 1,
  "mode": "vsComputer | passAndPlay",
  "opponent": "bot:onyx | guest",
  "opponentRating": 1640,
  "playerSeat": 0,
  "startingSeat": 0,
  "startReason": "random | rematchAlternation",
  "moves": [27, 14, 3, 61],
  "state": "active | complete",
  "createdAt": "2026-07-27T18:03:02Z",
  "completedAt": "2026-07-27T18:09:44Z",
  "result": {
    "outcome": "win | draw",
    "reason": "line | fullBoard | resignation | timeout | abandonment",
    "winnerSeat": 0,
    "line": [3, 18, 33, 48]
  },
  "rematchOf": "string | null",
  "updatedAt": "2026-07-27T18:09:44Z"
}
```

Unchanged since the v1 spec, and unchanged by progression, the meter or game services — which is the point of pricing quests by the opposition rather than by the player. Notes that remain load-bearing:

- **`moves` is a plain ordered list of cell indices.** Whose move it was derives from list position and `startingSeat`. No per-move author, id or timestamp.
- **`opponentRating` records the anchor this game was actually played against.** Without it, recalibrating an opponent silently rewrites every player's rating history.
- **`completedAt` is the fold's ordering key**, with the game id as tie-break. It orders the rating fold and the points fold alike.
- **`createdAt` is the meter's key** (D310). Every other fold in the progression package reads `completedAt` over completed games; the meter reads `createdAt` over games in any status, and the file says so at the top because a reader who has seen the others will assume this one matches them.
- **`outcome` and `reason` are separate.** A clock-driven ending cannot be derived from the moves. And `state == complete` does not mean drawn — only `outcome` does (D386).

### 8.4 No profile document

Still deleted. Settings and unlocks are the only local documents besides games.

### 8.5 Opponent catalogue — all thirty-one

Code-side constants, not persisted. Defined once in §6.4 of idea-v4.md and not duplicated here. What matters to implementation is which engine capability each tier requires:

| Tier | Opponents | Engine capability required |
|---|---|---|
| Novice | Pebble, Twig, Mote, Hazel, Clover, Sorrel | Random selection; immediate win and block detection; blunder rate; building a double threat |
| Casual | Bramble, Juniper, Bracken, Willow, Rowan, Aspen | All four strategic rules **behind `ruleChance`**; centre preference **behind `positionChance`** |
| Club | Vireo, Finch, Kestrel, Osprey, Heron, Marlin | The full positional ladder including the building term |
| Expert | Lynx, Sable, Ember, Lyra, Onyx, Corvus | 2-ply to 4-ply alpha-beta; threat-space search; aggression-versus-defence weighting |
| Master | Basalt, Cairn, Flint, Quartz, Titan, Oracle, Quadrim Prime | Transposition table; node budgets; **defensive forcing search**; exact solving below 10 empties; the strategy book from move one |

**Names and configurations move independently, and both have moved** (D257, D333). A name is a label on a slot; **a configuration belongs to a rung**. When the roster was permuted so the avatars read as a progression, ten names moved and no configuration did. When it was re-cut from twenty rungs to thirty-one, both moved — *together*, each measured configuration placed at the rating nearest the one it was calibrated to, with eleven new rungs interpolated into the gaps a beginner and an average player actually occupy. **Blurbs follow the configuration**, because a blurb describes what a player meets at the board.

**Tier is stored on each catalogue entry, not derived from its rating** (D179) — otherwise a recalibration silently reclassifies an opponent.

**Both book opponents hold a proof of a first-player win and nothing else.** No catalogue entry or player-facing string may call either of them perfect without the qualification "unbeatable when it moves first" (D181), and P21 requires the unlock confirmation to repeat it.

**The roster has a ceiling it did not used to have.** Achievements are capped per app by one platform, and forty-six are used (§7.7), so **a roster past about forty-five opponents breaks it** and every achievement id is permanent from publication.

### 8.6 Settings

```json
{ "schemaVersion": 1,
  "locale": "en | nl | system",
  "theme": "light | dark | system",
  "boardStyle": "layers | cube",
  "tutorialCompleted": false,
  "tutorialOffered": false,
  "freeMonthStartedAt": "2026-08-27T09:12:31Z | null",
  "reviewPromptedAt": "2026-09-01T12:00:00Z | null",
  "reviewPromptCount": 0,
  "gameServicesOffer": "notYetOffered | accepted | declined" }
```

- **`theme` is inert and survives on purpose** (D293). There is one painted design, so the picker was deleted rather than left selecting the same screen three ways; the field stays so a future release can revive the choice without touching anyone's data.
- **`boardStyle` defaults to `layers`**, which is also the fallback for anything unrecognised — the layered board is the accessible one (U31).
- **`tutorialOffered` is separate from `tutorialCompleted`**, and the offer is recorded *before* it is shown, because a dialog dismissed by tapping outside returns no answer (D193).
- **`freeMonthStartedAt` absent means unmetered, never expired** (D312, D353). A document written before the meter existed has no such field, and so does a damaged one; both stamp at the next launch, which is exactly the rule for players who predate the meter, arriving as the natural reading of a missing field rather than as a migration. **The failure direction is deliberate: a missing record lets the player play.**
- **The review fields absent mean never-asked**, which is the *opposite* default to `tutorialOffered` (D389). Everyone who upgrades becomes eligible at their next win; defaulting the other way silently denies the prompt to the entire existing player base.
- **`gameServicesOffer` records the dialog's answer and nothing else.** A platform that refuses is never written here (D391).

Release 2.0 adds `chatAvailability` with values `everyGame`, `friendsOnly` and `never`, defaulting to `friendsOnly`.

The computer rating and the points balance are deliberately **not** here.

### 8.7 Storage

One JSON document per record, keyed by id, under a single directory in the platform application-support location. Writes are atomic — temporary file then rename — so a kill mid-write cannot corrupt a record. A record whose `schemaVersion` is greater than the reader understands is skipped; equal or lower is read and upgraded.

**Backup is deliberately enabled, and the two platforms guarantee it by opposite mechanisms** (D346). Android needs an **explicit allowlist**, committed rather than the platform default; iOS backs up the application-support directory by default and needs nothing. **They agree only because the same path was chosen once for Android's sake** — a coincidence worth naming, because a future change of storage directory made for one platform's reason silently moves the other platform's guarantee with it. From 2.0 the exclusions in S15 become mandatory, as an allowlist entry on one platform and a per-file flag on the other.

It follows that **"no data leaves the device" must never appear in any privacy text.** It is false, and the backup is a deliberate trade. §7.7 makes it more false, and the store declarations must say so in the same release.

### 8.8 What is stored that the move list does not say

§8.1 says everything derives from the move list. **Two things do not.**

Points *earned* is a fold over stored games. Points *spent* is a decision, and a decision is not in the move list:

```json
{
  "id": "string",
  "schemaVersion": 1,
  "opponentId": "willow",
  "unlockedAt": "2026-08-14T09:12:31Z",
  "pricePaid": 178,
  "source": "points | purchase"
}
```

- **`pricePaid` is stored for the same reason a game stores the opponent's anchor rating.** Re-tuning a cost later must never retroactively bankrupt someone who already spent at the old price. The balance is *earned minus the sum of prices actually paid*, which is stable under any future change to the cost table.
- **`source`** distinguishes points from the one-time purchase, so a refund of the purchase can revoke exactly what it bought and nothing a player earned. **Records written by the purchase carry a price of zero** — the player paid the store, not the balance, and any other number would bankrupt somebody for buying the unlock (D348).
- **Writing a purchase record never overwrites one earned with points**, which is the property a refund actually turns on.
- A downward re-tune of the *quest* table is handled by a rule rather than a second stored table: **the balance clamps at zero and no unlock is ever revoked** (D264).

The second is **`freeMonthStartedAt`** (§8.6, D312). It exists because a player who installs and never plays still has a month running, so it cannot be derived from game history.

**D12's sentence was amended rather than quietly broken.** "Nothing but the unlock records is stored" became "nothing but the unlock records and one timestamp", and the invariant it protects holds exactly where it matters: balances, streaks, quest progress, mercy unlocks and statistics remain derived, and a test reconstructs each of them from game history alone. **A specification sentence that has quietly stopped being true is worse than one that was amended.**

These are the only records not reconstructible from game history, which is why §8.7's backup matters from the first release rather than from whenever the cloud arrives.

## 9. Implementation Decisions

### 9.1 Module structure

```
app/                            Flutter. The only place Flutter exists
packages/quadrim_engine/        pure Dart — rules, search, opponents, book
packages/quadrim_rating/        pure Dart — Elo maths
packages/quadrim_progression/   pure Dart — points, costs, quests, streaks, stars, the meter
tools/linegen/                  build-time generator, not shipped
tools/artgen/                   art and icon pipeline, run by hand, output committed
third_party/patashnik/          vendored dictionary + NOTICE.md
```

### 9.2 The pure packages are pure, mechanically

No Flutter, no Firebase, no `dart:io`, no ambient clock, no ambient random source, **no store, game-service or review plugin**, and no runtime dependencies. Grepped by the build gate over each package's manifest and imports. **Purity that is merely intended lasts until the first convenient import**, and every plugin added to the app layer has to be added to that grep in the same commit.

### 9.3 The 76 lines have exactly one definition

Generated at build time, committed, checked for staleness. Win detection, threat detection, evaluation, the tutorial's illustrations, **both board renderers** and 3.0's server-side validator all read the same table.

### 9.4 Bots are data

One `chooseMove` parameterised by a `BotConfig`. Adding an opponent is a catalogue entry. Ratings are fixed anchors: **when measurement disagrees with a published rating, the configuration changes and the rating does not** (D144).

**Introduce a rule or a positional preference as a probability, not as a switch** (D343). Measured in isolation, each is worth 100–162 rating points and the rungs are forty apart, so a switch overshoots its rung by three or four rungs' worth and any rung introducing none of them is left with a blunder rate that cannot cover forty points. **This is an arithmetic failure, not a tuning one**: no arrangement of switches produces an ordered ladder.

**Do not order a tier by which good squares an opponent prefers** (D315, D336). Corners-first, centres-first and centres-only beat each other in a ring, so alternating them up a ladder builds a cycle rather than an order — twice, here, the second time after the warning had been written down. What orders that stretch is how *many* of the sixteen seven-line cells an opponent prefers, then `lineBias`, then the blunder rate: three levers monotone by construction. A test asserts nothing in that stretch ranks the corners first.

### 9.5 Persistence sits behind the repository, and everything is derived

Statistics, the rating, the points balance, the streak, quest progress and the mercy unlocks are folds over `loadCompletedGames()`. Safe because offline history stays local and small — there is no growing cloud collection and therefore no pagination requirement.

**Anything folded against "today" must be re-folded when the app resumes**, not only when the data changes (D317). A screen whose only trigger is the completed-games stream keeps yesterday's answers if the app is left open overnight.

### 9.6 Streams, not futures

Even locally, so 2.0's push-based implementation satisfies the same contract without a UI rewrite.

### 9.7 The progression maths is a package, not part of the engine

§7.1 forbids the engine knowing who owns what: the catalogue has no `locked` field, because the strength harness plays all thirty-one against each other and has no business holding an entitlement. Arithmetic about what a player owns and what it cost belongs on the other side of that line (D263). **The meter joins it rather than earning a fourth package** (D308) — same shape, same injected boundary, about a hundred lines — at the cost of a package name that is now slightly wrong.

### 9.8 The board renders once per style, and the styles share what must not drift

**Portrait phone only, orientation locked.** One layout. Geometry derives from the touch target, not the other way round: fix the minimum cell size first and let the board's dimensions follow. Four layers in one column, not a 2×2 grid.

**A second renderer exists and is a second *reading* of the same data** (D369). Everything on screen is a fold over the move list, so switching mid-game costs nothing. What is shared rather than copied is the flash controller and the piece colours — the rule about which cells flash was already in one place, and the reduce-motion handling and the stone colours are the halves that would have drifted. **A player who switches display mid-game must not find the stones have changed colour.**

**A hand-rolled projection is chosen over a 3D package** because a package is a plugin, and a plugin is a merged manifest to audit (§10.1) for a picture that is 64 boxes and 64 spheres. It also runs in a widget test, which a shader-backed renderer would not.

### 9.9 Localisation from the first commit

All strings in resource files. English and Dutch complete, enforced. Bot names are not translated; blurbs are. Relative dates, point totals and prices are locale-formatted — a thousands separator is not a decoration, and §7.3's numbers reach seven digits.

**Use plural forms wherever a count is interpolated** (D385). A count without one reads "1 games", and the case it is wrong in is usually the first thing a new player sees. **The singular is the case the tests assert**, because it is the one that breaks.

**A bundle-level language declaration is not what makes a Flutter app bilingual** (D328). The engine reads the system's preferred languages and resolves against the supported-locale list in Dart, bypassing the bundle declaration entirely. The declaration stays for the two things it *does* do — the per-app language picker in system settings, and what the store listing claims — and the way to tell which declarations are load-bearing is to delete one and rebuild.

### 9.10 The tutorial's practice opponent is a bot configuration

And its hints derive from the opponents' own rule ladder rather than being scripted, so they are correct by construction in any position.

**The tutorial's first board opens as a cube and comes apart** (D366), and the animation **interpolates parameters, never matrices**: it must land exactly on the resting board rather than next to it, or the player has seen two unrelated pictures. A test asserts all sixty-four cell rectangles match a board built with no intro at all.

### 9.11 The one-time unlock is materialised, and entitlement is never cached

**The entitlement is the authority and the unlock records are its consequence** (D348), re-derived at every launch — which also means an opponent added in a later release is covered the next time the app starts, with no migration. A flag alone cannot answer "which of these did you earn"; records alone are a copy of a store answer that can disagree with the store.

**Entitlement starts empty at every launch and is never written to disk** (D349). A cache disagrees with the store in exactly one situation — a refund, chargeback or lapse it has not heard about — and in that situation the cache is the one still saying yes. The honest cost is that a paying player offline sees the unpaid state briefly; **what it must not do is guess in the player's favour and then take something away.**

**The shop starts before the first frame and is not awaited**, and **its purchase-stream listener is attached before the first `await` inside it** (D351). Stores deliver interrupted purchases on the first stream event after launch, and a listener attached after the product query misses them — the store then redelivers forever and somebody has been charged for something they never received. This is a property of statement order that no type expresses.

### 9.12 Backup is enabled deliberately

With an explicit allowlist on Android and the platform default on iOS (§8.7). From 2.0 the exclusions in S15 are mandatory on both.

### 9.13 The irreversible decisions

Three kinds of id can never be changed or reused once published: **the application id** (per store, and ours differ by platform), **every in-app product id**, and **every achievement and leaderboard id**. Also permanent in practice: **the published anchor ratings**, which every recorded result is measured against.

**The application id is permanent per store, not per project** (D213, D359). Ours diverged because one platform was already on a testing track when the other's store record was created. The cost is a rule: **every place that names an application id has to say which platform it means**, because a single id assumed across platforms is a silent misconfiguration rather than a build error.

**Product ids follow whichever store you are standing in front of** (D365). Ours sit in one platform's namespace on both stores, deliberately: one id per product across both stores is worth more than each platform's ids matching its own application id, because a second set means a platform branch, two entitlement paths, and a class of bug where the wrong store is asked about the right product. A guard test pins the prefix.

**The version name is a story; the build number is a ratchet** (D358). One counter serves both stores. **It is spent on upload, not on release** — a build sent to a testing track and discarded has consumed its number. **A build number must never name two different artifacts.** Nothing enforces the ratchet and nothing can; the comment beside the field is the whole defence.

### 9.14 Platform floors and declarations

Each of these is a number or a flag somebody has to own, because a default is not a decision.

- **The minimum OS version** is recorded rather than tuned until there is evidence, and then taken when the evidence arrives. **Raising the floor later drops devices that had the app**, so the cheapest moment is before anything ships.
- **Export compliance is declared in the bundle**, not answered per build, or every build waits on a manual gate. What it costs is that the answer is committed rather than considered: **anything later that ships an algorithm makes the declaration false and must change it in the same commit.**
- **A privacy manifest declares what the *app* does.** Check the built product rather than the package sources: **a plugin with no native bundle has nothing to carry a manifest in**, so nothing declares an access on the app's behalf even when the plugin is what reaches the API. A manifest not listed in the target's bundled resources ships nothing and fails silently.
- **A release build without signing credentials must fail at build time** (D355). The scaffolding default that signs a release with the debug key and says nothing is the defect — the failure surfaces at the store rather than at the build, or does not surface at all and gets written down as success. **Delete the fallback rather than adding a config.** Credentials live outside the repository, and the gate asks the tool what is *tracked* rather than trusting what is *ignored*.
- **The launch screen bakes in whatever the app draws over the same picture** (D331), verified numerically rather than by eye — a screenshot taken during the app-open animation is dimmed and scaled by the platform and looks like a real defect.
- **Know which defaults the platform supplies** (D323). Modern Android draws the splash itself and ignores the window background, defaulting to a light field and the whole adaptive icon. Declare the version-gated attributes in the *unqualified* resource folder: night-mode qualifiers outrank version qualifiers, so a version-qualified file loses on exactly the devices that asked for dark.
- **A generator that owns a directory owns what it removes**, not only what it writes (D329), or a future scaffolding run re-adopts the orphans.
- **Check what a scaffolding command touched outside the directory it promised to touch** (D327), with a working-tree check immediately afterwards. "It adds one directory and nothing else" is a statement of intent.

**Machine conditions are not project conditions.** Toolchain workarounds that belong to one developer's machine are recorded in the contributor guide, not here; no path to them is committed and CI is untouched.

## 10. Testing Decisions

### 10.1 The build gate

One script, run before every commit, that analyses and tests every package and additionally checks what the specification demands but a compiler cannot:

- package purity, per §9.2, **including every plugin the app layer adds**
- no user-facing string outside the localisation files
- the licence attribution is still rendered somewhere in the app's source
- the vendored dictionary's SHA-256 is unchanged
- generated sources are not stale
- every string exists in **both** languages
- signing credentials are not tracked
- **the network permission is declared on purpose**
- **every platform declaration file parses**

#### The network check is a declaration check, not a ban

"Computer play makes no network call" began as a negative enforced by a platform mechanism: withholding the network permission made the platform refuse the call whatever the code asked for. **That mechanism is gone** (D376) — game services need the permission and the platform grants it per application rather than per screen — so S1 and F13 drop from *enforced* to *reviewed* on both platforms, which is the status they always had on one of them (S20).

What replaced it: **the permission must be declared deliberately**, as an explicit line with a comment naming the decision. The gate fails if the declaration disappears and fails if the old removal directive comes back. That turns "the permission is absent" into "the permission is present on purpose", and a diff that changes the app's network posture has to touch a line with the reasoning beside it.

**Three lessons outlive the mechanism:**

1. **Read the artifact, not the inputs** (D356). The original check grepped the *source* manifest, which is not what determines what ships. A telemetry transport riding in behind the billing library declared the permission, the merged manifest carried it, and the check passed on the very build that shipped it. **The guarantee was never enforced — it merely had nothing to catch.** Enumerating the dependencies you thought of is the wrong instrument; the merge report names the contributor of every line.
2. **A check that cannot run in every environment must say when it is not checking** (D357). The merged manifest only exists after a release build, which CI does not do, so the authoritative step is opportunistic and **says so rather than passing quietly**.
3. **Stripping a permission a dependency wants is a standing hazard** (D388). Removing it silently disables whatever wanted it, and the failure surfaces as a runtime symptom rather than a build error: three uploads shipped with it stripped, the billing client could not list products, and the shop read "unavailable" on one platform for three releases while the other was being exercised. **The intuitive answer was wrong** — billing talks to the store app over IPC, so the caller's own permission "should not" matter — and only a real install settled it. **And a release branch is a long-lived fork that a fix on the trunk does not reach.**

#### Three more gate rules

**A gate must not die where it means to admit ignorance** (D363). A command that exits non-zero when its starting point is missing, inside a command substitution, under strict shell settings, ends the script — before reaching the branch whose job was to say "not checking that here". **A silent abort under a section heading is indistinguishable from that section failing.** Trap errors and name the line; say whether the stop was a finding or an unguarded command. The real cost was not the failed builds but that **nothing after the abort had run on CI for three commits.**

**Parse every declaration file the platforms read** (D364). A privacy manifest was rejected for "invalid keys and values"; every key was correct and **the file was not valid XML at all**, because a house style full of em-dashes put a double hyphen inside a comment. The rejection message pointed away from the fault; two minutes with a parser answered it. The gate now loads every such file with a real parser, fails with the parser's own message, and **fails when none is found**.

**Do not gate on regenerated artwork** (D290). Generated *logic* is checked for staleness because a stale derivation is a wrong one. Images are not that: the same picture re-encoded by a different library build is different bytes, so the gate would fail on a library upgrade while nothing was wrong, and **a gate that cries wolf is a gate people learn to skip.** What is checked instead is what would reach a player: every catalogue entry resolves to real bytes, the fonts and licences are present, and the budget holds. A manifest that declares art by *directory* is silent about a missing file; the test is what objects.

Every long run gets a hard timeout. A hung suite is indistinguishable from a slow one.

### 10.2 Seams

- **The engine** is tested directly: it is pure, seeded and deterministic.
- **The repository** is the flow seam. Widget tests must use the in-memory store — `testWidgets` runs in a fake-async zone that never completes real file I/O, so a widget test over the file store hangs.
- **`quadrim_progression`** is tested exhaustively over the whole catalogue rather than by example, because it is small integer arithmetic over thirty-one known inputs.
- **Every platform plugin is behind an interface this app owns** — the store, game services, the review sheet, the URL launcher. What is proven is that the app asks for the right thing, never that the platform answers.
- **Calibration is measurement, not a test.** It reports measured against published and never fits a fresh scale.

### 10.3 Injecting the clock

Streak and meter evaluation need a calendar and the packages may not read one, so the day boundary is a parameter. The same applies to the rating fold's tie-break: if game ids are random and two games complete in the same millisecond their order is a coin flip, which is fine for the product and fatal for a fixture that creates games back to back.

**A fixture whose clock disagrees with itself cannot catch a bug about which day it is** (D317). Test data that plays its games months away from its own notion of *today* is incoherent, and invisible for exactly as long as nothing asks what day it is.

### 10.4 What the tests here have actually missed

Six failure shapes, every one of which shipped. They are listed because each is a *kind* of test that was missing rather than a bug that was made.

1. **A test that asserts a value exists, not that it is right** (D289). Trend tests asserted the presence of a signed number and its sign, never its value against an independently computed one — so a baseline that removed one game from the total passed. The replacements compute the expectation from the series, and one asserts that the right answer and the old wrong answer are *different numbers*, so it cannot pass by accident.
2. **A fixture that never exercises the difference** (D316). Every Your Path test spent nothing, so an earned total and a spendable balance were the same number and reading the wrong one could not fail. **The regression test buys something first.**
3. **A mutation nobody tried** (D386, D389). Two behaviours are now pinned by *making* the wrong change and watching a test go red — swapping an outcome check for a status check, and deleting a call that fires the review prompt. A feature whose deletion is silent has no test.
4. **A comment on one widget does not protect the widget beside it** (D316). The hazard was documented exactly where it had already been met.
5. **Coverage follows recency, not risk** (D374). A whole-app font-scale sweep at the largest setting on the smallest phone found three shipped overflows; the two screens already swept were the two most recently built.
6. **A check can pass because it is looking at the wrong file** (D356). See §10.1.

## 11. Acceptance Criteria

Criteria carried from earlier editions keep their ids. Where content changed the id is kept and the text replaced, so a source comment citing it still points at the right requirement (D272).

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
| E17 ＋ | Any opponent defined before `ruleChance` and `positionChance` existed | it plays with both fields at their defaults | **it makes identical moves**, because a chance of 1 draws no random number |
| E18 ＋ | The roster from Bramble to Marlin | each configuration is read | **none ranks the corners above the centre**, and the ordering levers are monotone by construction |
| E19 ＋ | A resigned game | it is asked whether it was drawn | **the answer is no.** `outcome` decides; `status == complete` does not |

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
| F13 △ | Any game against a computer opponent | it is played from first move to result | no network call is made at any point. **Unchanged and still true** — the rating and the achievements are reported *after* a game is scored, never during one (D376) |
| F14 ＋ | A move by the strongest opponent | it is chosen on a reference device | it completes within twenty seconds, and a moving indication of thinking is on screen throughout |
| F15 ＋ | A subscription that lapses mid-series *(3.0)* | games in progress finish | they rate normally for both players, one rematch is permitted, and the lapsed player is exempt from the inactivity forfeit |
| F16 ＋ | A player at the daily or weekly cap | a new computer game is started | it is refused, and the message names **the limit that actually bit** |
| F17 ＋ | A game started and abandoned | the meter is read | it counted, because a game counts when it is started |
| F18 ＋ | An unfinished game against a computer opponent | a new game against the same opponent is requested | **the existing one is resumed**, so the first-move draw cannot be re-rolled. Pass-and-play is exempt; a rematch alternates deterministically and is untouched |
| F19 ＋ | A game with fewer than two moves | the in-progress list is drawn | **it does not appear**, and the repository still returns it so F18 can find it |
| F20 ＋ | A finished game that is a win, with at least the minimum games played and no prompt in the last ninety days and fewer than three so far | the result is shown | the review sheet is requested, **and the attempt is recorded whether or not it could appear** |
| F21 ＋ | A device clock corrected backwards, so the last prompt reads as being in the future | a win completes | **no prompt is requested** |
| F22 ＋ | A loss, or a pass-and-play game | it completes | no review prompt, no points, no quest progress, no meter cost |

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
| U10 ▲ | **The app is portrait-only on every device.** No large-screen layout exists and none is reachable by rotation or resizing. The build declares **phone only**, because a tablet declaration would require declaring the orientations U10 forbids (D360) |
| U11 | No hard-coded user-facing string exists; English and Dutch are complete |
| U12 ＋ | The last move by **each** side is marked, and each marked piece moves away from its own resting colour rather than towards a shared accent |
| U13 ＋ | Your Path shows three tiles at a time and **scrolls horizontally over the whole roster**; it rests on the lowest-rated opponent rated **strictly above** the player's rating; it clamps at both ends and never shows a hole |
| U13a ＋ | Tapping a Your Path tile opens that opponent's **detail page**; tapping a row in opponent selection still starts a game |
| U13b ＋ | The detail page leads with the avatar at its largest size, then name, rating, tier, blurb, how the pairing sits, the record and stars, and what a win pays |
| U13c ＋ | The detail page ends in one action: **start a game** when unlocked, or the price, the progress and an **unlock** button when not — the same confirmation the other two routes reach |
| U14 ＋ | An opponent never faced shows **no star row at all**, rather than three empty stars |
| U15 ＋ | The trend graph states its change as a **signed number** beside the line, measured from a plotted baseline that is the rating held *before* the window, and shows nothing at all below two completed games |
| U16 ＋ | Any rating shown as a bar is zero-based against the top of the catalogue, draws its unfilled track, and shows the number as well |
| U17 ＋ | The quests section shows the four closest to completion, ranked by percentage with ties going to the smaller absolute remainder and then to **roster order**, weakest first |
| U18 ＋ | Achieving a quest during a game is acknowledged **when that game ends**, with the points it paid — not silently, and not interrupting play |
| U19 ＋ | The end-of-game panel shows the rating change **that game caused**, the points earned, any quest completed, and — if this game's win **crossed** the price and it is the most recent finished game — the next unlock, offered there |
| U20 ＋ | Finished-game rows show the result label above the rating change, a relative date, and a challenge button; a change that rounds to zero shows the number alone with no arrow |
| U21 ＋ | The whole app reaches its last row at the largest font scale on the smallest supported phone — swept across every screen, not only the most recently built |
| U22 ＋ | A locked opponent's tile and row are one accessibility node each — name, rating, record, stars, locked state and price — announced once |
| U23 ＋ | Backing out of the opponent list cancels the whole flow rather than falling back to a default opponent |
| U24 ＋ | Every screen sits on the designed background; no screen shows an undesigned surface |
| U25 ＋ | Every opponent draws its own portrait, a locked one is veiled rather than replaced, and the locked state is carried by a **symbol and a semantics label** as well as by the veil |
| U26 ＋ | Every carved sign carries its caption in the player's language, drawn by the app; buttons announce it as their name and headings as a semantic header |
| U27 ＋ | The shipped artwork and fonts together stay under 3 MB, and decorative artwork is not drawn at text scales where it would push a section off the screen |
| U28 ＋ | A section listing the four most recently completed quests appears below the closest-four section, with what each paid, and is absent until at least one has been completed |
| U29 ＋ | Every heading sign is drawn at one **plank** height regardless of how much margin its file carries, overhangs its panel without being overlapped by the section above, and is a sibling of its card rather than a child |
| U30 ＋ | **Your Path says it scrolls.** A control at each edge steps the row exactly one tile from the nearest boundary, fades and becomes non-interactive at the ends, and is **pressable across its whole target** — including the part outside the panel |
| U31 ＋ | **Both boards play the same game.** The style is a remembered preference; the layered board is the default and the fallback for anything unrecognised; reviewing always uses the layered board and the toggle disappears with it |
| U32 ＋ | **Every cell of the cube board is reachable from some angle**, an occupied cell swallows its own tap rather than passing it behind, and the farthest reachable cell still clears the touch-target floor |
| U33 ＋ | **The cube board declares that it is not readable cell by cell** and names the layered board as the way to do that |
| U34 ＋ | **The game-services controls are labelled buttons with distinct icons**, each its own accessibility node, and are **absent** when the platform is not usable |
| U35 ＋ | **A refused game-services open tells the player something** |
| U36 ＋ | **Terms of use and privacy links are in the binary** — in settings *and* on the purchase screen — are functional, and say so when a launch fails |
| U37 ＋ | **Each product states what kind of thing it is** — auto-renewing subscription with its length, or one-time purchase — with the price formatted by the store |
| U38 ＋ | **A record with no draws in it does not say so**, everywhere a record is drawn *and* everywhere one is spoken, through one helper rather than four copies |
| U39 ＋ | **Every interpolated count has a plural form** in both languages, and the singular is asserted |

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
| T10 ＋ | **The first board opens as a cube and comes apart**, and at the end **all sixty-four cell rectangles match a board built with no intro at all** |
| T11 ＋ | Reduce-motion parks the intro at its end state with no frames scheduled |

### 11.5 Data

| # | Criterion |
|---|---|
| D1 | Every persisted document carries a `schemaVersion` |
| D2 ▲ | **The app generates no identifier and stores none.** Where a platform service identifies the player — game services, a store account — that identifier is the platform's, is never persisted by this app, and never enters a Quadrim document (D377) |
| D3 | Game documents match §8.3 exactly |
| D4 | A kill during a write leaves no corrupted record |
| D5 | A `schemaVersion` greater than the reader understands causes that record to be skipped; equal or lower is read and upgraded |
| D6 | Every game id is unique and stable across restarts |
| D7 | Whose move each move was is derivable from list position and `startingSeat`, and matches what the board displays during replay |
| D8 | The tutorial's practice game never reaches storage and never appears in statistics, the completed-games list, any quest, the meter, or the review prompt |
| D9 ▲ | Only games, settings **and unlocks** are backup-eligible, by explicit allowlist rather than platform default |
| D10 ＋ | Unlock documents match §8.8 exactly |
| D11 ＋ | A restore onto a new device returns every unlock the player had earned, **on both platforms** |
| D12 ▲ | **Nothing but the unlock records and one timestamp is stored.** A test reconstructs the balance, every streak, every quest's progress **and the mercy unlocks** from game history alone and gets the same answers (D312) |
| D13 ＋ | **A missing or unreadable settings document fails open**: the player is unmetered, not walled out |
| D14 ＋ | **Unlock records written by the one-time purchase carry a price of zero and never overwrite a record earned with points**, so a refund revokes exactly what it bought |

### 11.6 Progression

| # | Given | When | Then |
|---|---|---|---|
| P1 | A win against roster index *i* | points are folded | it pays exactly the *i*th rung of the win ladder |
| P2 | A draw or a loss against any opponent | points are folded | it pays nothing |
| P3 | Opponent *i* | its unlock price is read | it is twice what a win against *i* pays, and the price sequence is 2, 4, 6, 10, 16, 26 … each the sum of the two before it |
| P4 ▲ | The catalogue | the free set is computed | **the first six — the Novice tier — by count** (D335, reversing D228). Of those six, three are held back by P23 |
| P5 | Any locked opponent that is not the lowest-indexed *purchasable* locked one | it is offered for purchase | the purchase is refused |
| P6 | A player with unlocks | the balance is read | it is points earned minus the sum of prices actually paid, **clamped at zero** |
| P7 | An unlock bought at the old price | the cost table is re-tuned | the unlock stands and the balance is unchanged, because the price paid is stored with it |
| P8 | An unlock bought with points | the quest table is re-tuned downward | the unlock is **not revoked**, and the balance clamps at zero rather than going negative |
| P9 | A per-opponent quest against opponent *i* | it is claimed at any point in the player's career | it pays `winValue(i)` — the same amount whenever it is claimed |
| P10 ▲ | A volume or streak quest | it is awarded | it pays its multiple × `winValue(round(mean roster index of the qualifying games))`, the multiple expressed in quarters |
| P11 | A hundred games against the weakest opponent in one day, by a player who has unlocked the roster | the volume quest is awarded | it pays **a handful of points**, not a hundred games' worth of the top of the ladder |
| P12 | Nineteen trivial games and one against the top of the roster | the average is taken | it is taken over the **roster index**, not the payouts |
| P13 | Any quest | any function in `quadrim_progression` is called | no signature anywhere accepts the player's rating or current rung |
| P14 | Any quest | it is completed twice over | it pays exactly once |
| P15 | A set of completed games | points earned is folded | **no unlock record is read**, and the result is a pure function of the games |
| P16 | A day with at least one **finished** computer game | the streak is evaluated | the day counts. A day with only started games does not |
| P17 | A missed day | the streak is evaluated | it resets to zero, across a month boundary, a year boundary and a time-zone change alike |
| P18 ▲ | A one-day gap whose surrounding games are **less than 48 hours apart** | the streak is evaluated | **it is bridged, and the bridged day counts toward the run's length.** A longer gap, or a gap of two days or more, breaks the streak (D283) |
| P19 | The streak evaluator | it is called | the day boundary is a parameter; no clock is read inside the package |
| P20 | A pass-and-play game or the tutorial's practice game | it completes | it pays no points and counts toward no quest |
| P21 | Either book opponent | its unlock is confirmed | the confirmation repeats **"unbeatable when it moves first"**, not merely the store listing |
| P22 ▲ | The whole roster | its purchasable cost is summed | it is **11,405,706 points**, about eighty wins across twenty-five purchasable rungs |
| P23 ＋ | **The three held-back Novice rungs** | a player loses to the rung immediately above one of them | **that rung opens**, derived from the game list and never stored. A **draw does not** open one |
| P24 ＋ | Any mercy rung | the next purchase is computed, or the roster cost is summed | **it is never named and never priced** |
| P25 ＋ | A player who has already finished a game against a held-back opponent | mercy unlocks are folded | **they keep it** |
| P26 ＋ | A locked mercy rung | the opponent list is drawn | **it is absent, not greyed**, and the tier heading counts the filtered list |
| P27 ＋ | A quest whose arithmetic award rounds to zero | it fires | **it pays one point** |
| P28 ＋ | A volume rung not yet achieved | its progress is read | **it is today's count**, not the best day ever. Its *achievement* is permanent |
| P29 ＋ | A streak rung not yet achieved | its progress is read | **it is the streak the player is on now.** Its *achievement* is the earliest run that ever reached it |
| P30 ＋ | The day changes while the app is open or backgrounded | the main screen is read | **every day-shaped fold has been recomputed** |
| P31 ＋ | The volume-quest restriction | a tile is drawn | it is **derived from the cap**, not carried on the quest, so the pure package never learns what an entitlement is |

### 11.7 Release gates

Originally written for a private first release on one store. Every one of them is met or superseded; they are kept because the ids are cited, and because two of them describe discipline that is now nobody's to impose (§13.2).

| # | Gate | State |
|---|---|---|
| R1 ▲ | The application id chosen — **permanent once published to any track, on either store**, and **per store rather than per project** (D359) | met, twice |
| R2 ▲ | Developer enrolment on each store | met |
| R3 | Release signing configured, upload keystore backed up and the backup **verified by restoring it** | met; **and a release build without credentials now fails at build time** (D355) |
| R4 | A tester cohort recruited and opted in | met |
| R5 | Data-safety declaration completed, with reasoning and date recorded. **A task, not a foregone conclusion**, given that backup is enabled | met; **must be revised for game services** |
| R6 | Content rating questionnaire and target-audience declaration completed | met |
| R7 | Listing sufficient for testers to install, in both languages | met |
| R8 ▲ | A build published to a testing track, installed and opened by the cohort | met |
| R9 | The tester survey instrument exists and was given at install, with pass thresholds committed in advance | **superseded** — closed informally and deliberately (§13.2) |
| R10 ▲ | Every acceptance criterion in §11.1 to **§11.6** passing | met |
| R11 ▲ | Production access unlocked where a store requires a closed test — **an Android-only gate, no longer the gate to going public** | in progress |
| R12 ＋ | **Progression is complete before the cohort installs.** The clock starts against a build with the ladder in it, or the one test that could validate it runs against a product nobody intends to ship | met |
| R13 ＋ | The survey measures **median time to each unlock** and **the rung at which players stop** | **not met** (§13.2) |

### 11.7a Release gates for the public release

| # | Gate | State |
|---|---|---|
| R14 ＋ | Enrolment complete, signing and provisioning configured, and the upload path proven by an actual build on a testing track | met |
| R15 ＋ | Store products created: the one-time unlock as a non-consumable, and the subscription as **one product with one base plan** — the group that 3.0 adds the second plan to must exist from the first sale | met on one store; **unverified on the other** (§13.2) |
| R16 ＋ | Price points chosen per country, with tax treatment confirmed | prices met; **tax treatment open** |
| R17 ＋ | **A purchase, a restore and a reinstall tested on real hardware on both stores**, in sandbox and then once in production | purchase met on one store; **restore open** |
| R18 ＋ | The privacy manifest and store privacy labels completed — declarations about a build that collects nothing, which makes them cheap to write and easy to forget | met; **must be revised for game services** |
| R19 ＋ | Backup verified on both platforms: unlock records survive a restore onto a different device (D11) | **open** |
| R20 ＋ | **A tester cohort exists and its size and duration were chosen deliberately.** No store imposes either any more, so the discipline the requirement used to force must be supplied or it will not happen | **superseded** (§13.2) |
| R21 ＋ | The Casual-tier inversion fixed, confirmed by calibration, and shipped **before** the first sale — after that it becomes a migration rather than an edit | met |
| R22 ＋ | The paywall copy does not claim the meter is stronger than it is | met |
| R23 ＋ | **Terms of use and privacy links are in the binary**, on the purchase screen as well as in settings (U36) | met |
| R24 ＋ | **The store's product copy is recorded in the repository** and says the same thing as the app's (D380, D381) | met |
| R25 ＋ | **The platform game-services capability is enabled in the platform project**, and the leaderboard and achievements exist in the consoles | **open** (§13.2) |

### 11.8 Security and privacy

**Testable now:**

| # | Criterion |
|---|---|
| S1 △ | No network call is made at any point in a game against a computer opponent — cross-references F13. **Still true; no longer enforced** (D376). The permission that once made this categorical is now needed by §7.7 and is granted per application, so this is **reviewed** on both platforms — the status it always had on one (S20). The engine's purity is still mechanical: the gate rejects a network import in any pure package |
| S2 ▲ | **The app generates no identifier and stores none**, and none enters a document — cross-references D2. Amended rather than reinterpreted when a leaderboard made a player attributable by definition (D377). **A rule kept alive by a careful reading is worse than an amended one** |
| S3 ▲ | Only games, settings and unlocks are backup-eligible, by explicit allowlist — cross-references D9 |
| S4 | The repository is the only reader and writer of stored data; no screen touches storage directly |
| S5 | Testers have been given a written privacy notice covering what is collected, why, who holds it, how long, and how to withdraw. **This is the developer's processing, not the app's** |
| S6 | Tester screenshots are deleted once calibration has consumed them |
| S17 ＋ | Points and unlocks are client-written and local **by design**, and no code path sends a computer-game result anywhere |
| S19 ＋ | **The meter is local and a reinstall clears it.** Stated as a known limit rather than a defect: closing it needs an identifier, forbidden by §5.2 in every release, or a server, which is 2.0. **No code path may work around this by identifying the device** |
| S20 ＋ | **"No network call during computer play" is reviewed, not enforced, on both platforms.** There is no permission to withhold on one and the permission is needed on the other. The claim is made at that strength and no higher |
| S21 ＋ | **The one-time unlock's revocation touches only what it bought.** No code path reaches it from a subscription event |
| S22 ＋ | **The network permission is declared deliberately**, with a comment naming the decision, and the gate fails if the declaration disappears or the old removal directive returns |
| S23 ＋ | **No identifier a platform service issues is persisted or enters a document**, and a signed-out player's app is identical to a signed-in one minus the leaderboard and the shelf |

**Gated on later releases and stated now so they are not invented later:**

| # | Criterion |
|---|---|
| S7 | The adversarial rules suite passes: every listed attempt is denied |
| S8 | The client write allowlist is field-level; ratings, entitlement, totals and timestamps are server-written only |
| S9 ▲ | Entitlement is written only after receipt validation, by the server, and is revoked on refund, chargeback or voided purchase. **From 2.0.** Before then the authority is the store's own signed transaction read on the device, **never cached**, and revocation follows the store's refresh (D303, D349) |
| S10 | Invite codes resist enumeration, expire, are single-use, are revocable, and are checked against the creator's block list on join |
| S11 | A block prevents challenge, invite acceptance and profile visibility, checked in the game-creation path |
| S12 | Friendship requires acceptance; friend requests carry no free text and are rate-limited |
| S13 | Account deletion leaves no identifier linking a retained game to the deleted account, and the tombstone is randomly generated per game |
| S14 | Data export returns everything deletion would remove, in a machine-readable form |
| S15 | Auth material, the entitlement cache and messaging tokens are excluded from backup |
| S16 | The backup allowlist is re-verified against the app directory at every release, because a new dependency can add state silently |
| S18 ▲ | The meter is server-authoritative and the free month is held against the account, because it gates a purchase. **From 2.0**, and the migration *adopts* the local record rather than restarting the month |

## 12. Build order

The offline product was built in fifty-one tickets, 001–051, and the ordering principle is the part worth keeping rather than the list.

**Slices, not layers.** Each progression pass crossed every layer — pure package, repository, screen — so a real unlock was on screen after the second one. Bottom-up was rejected because it finishes with the riskiest part: the arithmetic is small and exhaustively testable whenever it is written, while six sections on the smallest phone at the largest font scale are neither, and a slice meets that first.

**Fix the package's shape before the first slice.** The signatures in §7.3 were settled up front, so each pass extended a settled interface rather than renegotiating one.

**Split a screen before growing it.** One commit that moves code and changes nothing looks like wasted effort in a log and is the opposite: it is what makes the diffs after it legible, and it is only reviewable as a *move* if nothing else happens in it. Delete what the move is replacing in the ticket that replaces it, not in the move — otherwise the screen has a hole for two tickets and the move is no longer provably a move.

**Do not cut tickets for a release whose stack is not chosen.** A ticket written against guesses is a ticket that will be rewritten before it is built, and the rewriting costs more than the deferral. 2.0's Firestore schema is specified as a *contract* in §7.6 — the same flow tests as the local repository — precisely so it can be designed natively when it arrives. The cost is that the backlog does not show the whole road, and §4.1 is where that shape lives.

**Do not sequence work that is blocked on somebody else's queue more tightly than it deserves.** A plan that pretends to know when a store account will be restored is a plan that will be rewritten.

**A ticket may be closed on the developer's report, and the closure says so** (D371). Several tickets end at a boundary this repository cannot see across: an upload, an install, a sandbox purchase, a review queue, a web console. A ticket that cannot be closed by the only person able to close it is not a record, it is a ratchet that only turns one way. **Where the report does not reach a criterion, say so by name** — working through four such tickets against a four-sentence report surfaced three things that would otherwise have been assumed, including a code path (restore) that was never mentioned and a question about *which store* a tested purchase happened on, which decided an open empirical matter.

### 12.1 What remains

| Ticket | Contains |
|---|---|
| **022** Release readiness | A fresh install walked end to end on a virgin device; backup-and-restore on both platforms (R19); restore-purchases from a testing build (R17); the privacy policy's contact block; the tag |
| **051** Cloud save, challenges and friends | A later release. **Told not to add achievements** — the cap and the point total are both full (§8.5) |
| — | 2.0 and 3.0 are cut into tickets when their release is next |

## 13. Further Notes

### 13.1 What was reversed, and why it is recorded rather than edited out

**Everything the first release shipped is no longer free forever.** That sentence was written before there was a business model and could not survive one. Nothing had shipped to a member of the public, so nobody had anything taken away. What survives is narrower and true: no feature is held back and there are no ads; what is metered is how often a new computer game may be *started*.

**The offline guarantee lost its enforcement and kept its claim** (D376). The absence of a network permission was the strongest guarantee this project had — a platform refusal rather than a promise — and a leaderboard needs the permission, which the platform grants per application rather than per screen. **The criteria survive untouched because they were always narrow**: they say a game against a computer opponent makes no network call, not that the app never reaches the network. What is lost is the lever, and what is lost with it is worth naming: the merged-manifest check is the only reason anybody knows what a billing library drags in, so **the honest description of the new state is "declared on purpose" rather than "nobody is watching" — which is what deleting the check would have produced.**

**The identity claim was amended rather than reinterpreted** (D377). "No identifier is transmitted" could not survive a leaderboard, and there was a defensible reading under which a per-person id is not a *device* id. It was declined: **a rule kept alive by a careful reading is worse than an amended one, because the next person reads the rule and not the argument.**

**The release ladder was re-cut around a blocked store account, and the old one is left in the record.** Nothing about the *game* changed; what changed is that a plan whose critical path ran through an account nobody controls was replaced by one that ships to each store as that store becomes able to accept it. Two things got harder and are recorded rather than absorbed: the meter now lands in the first public release rather than the fourth, and entitlement is on-device for one release.

**Online play will be free before it is paid, and says so from the start.** 2.0 ships it free because the rating that makes it worth buying arrives at 3.0. Announcing the future price on day one is the direct lesson of the free-forever sentence.

**The large-screen layout is cancelled, not deferred**, and the platform has since made it a fork in the road rather than a preference (U10).

**Two quest-pricing rules were tried and both were wrong**, in opposite directions, and both are kept in §7.4 of idea-v4.md as rejected options. Pricing at the player's current rung lets the cheap quests be banked; leaving the volume family on that rule makes a hundred trivial games in a day pay four top-tier wins. Both are the same mistake: §7.3's shape exists so that grinding downward prices itself out without a rule, and a reward priced by the player's height reintroduced the exploit in the one place that shape was not looking.

**Three opponents were held back after the game was public** (D382), because reviews said the ladder opened too gently. That is the first change in this project driven by players rather than by measurement, and it was made *derivable* rather than stored precisely so it could be made safely on a live product.

### 13.2 What is still open

Every item is a business, account or measurement decision. **None is functional, and none blocks building the game.**

| Item | Why it is open |
|---|---|
| **The platform game-services capability** | Not enabled in the platform project, which is why the leaderboard and achievements controls do nothing on the current testing build. One action in the platform IDE — which both creates the entitlement and registers it against the app record, where hand-writing the file does only the first. It also needs the leaderboard to exist in the console. Gates R25, G10 |
| **The other store's console ids** | Unset, so that platform shows no game-services UI and reports nothing. Gates R25 |
| **Whether the two products exist in the other store's console** | Unverified, and would produce the identical "unavailable" screen the missing permission produced (§10.1). Gates R15 |
| **Restore-purchases on hardware** | A different code path from purchase, which stores ask to see and a reinstalling player needs. Gates R17 |
| **Backup and restore onto a second device** | The mechanism is confirmed on both platforms and the *outcome* is not; it needs two devices and a person. Gates R19 |
| **The reference device** | The twenty-second ceiling is a device number and the measured worst case (11.8 s) is a desktop one. Gates F14 |
| **The progression numbers** | The shape is settled; the values are derived from a stated target rather than measured. First thing to instrument. Gates R13 |
| **Tax treatment of the two prices** | Both stores act as merchant of record in most territories and remit VAT themselves — the answer, and not one to assume without checking. Gates R16 |
| **The Master tier's spacing** | Ordered on paper, unresolved on the board: three full-budget pairings is not a tier. An overnight full-budget run over the searching tiers |
| **Kestrel to Lynx is twice too steep** | Even, correctly ordered, and not fixable from inside the span — a dial can only weaken, so closing it means bringing the Master tier's node budgets down, after the run above |
| **Several rungs are not distinguishable in play** | The cost of removing a stylistic ordering axis (§9.4). Gates G3. Putting character back needs a *monotone* lever; `lineBias` is the candidate |
| **The privacy policy's contact block** | Placeholders in the repository while the published page must already carry real values. A paste, and a read of the two side by side |

**Two things are closed as *properties of the release* rather than as open tasks, and both cost something:**

**The tester cohort has no instrument** (D373). The specified test was a written cohort, a duration, a survey in two languages, pass thresholds with pre-committed consequences, and screenshots at day 3 and day 10. What happened is that testers were invited and interviewed in person. **For "what is wrong with this build", the informal route is the stronger instrument, not the weaker one** — people say what made them hesitate, where a form mostly collects what they are willing to type. What it gives up is the other question: an in-person conversation is very bad at finding who quietly stopped playing on day two. **Four pre-committed consequences are now unenforceable**, and the one worth naming is *"if most testers stopped after day 2, do not ship the meter into that"* — the only thing standing between a retention problem and a revenue feature layered on top of one. G8, R9, R13 and R20 are all downstream of this.

**The ladder is anchored to itself and never to a human** (D373). Every one of the thirty-one published ratings is measured by bots playing bots — internally consistent, reproducible, and never once checked against a person. That is not a defect; the harness measures exactly what it claims to, and §9.4 keeps the configurations honest against it. But **"Pebble is 600" is a statement about this ladder's own scale, not about human Elo**, and nothing shipped so far will tell us whether the two coincide. If a rung ever feels wrong to real players, that is the first explanation to reach for.

### 13.3 Deviations from the requested process

Recorded rather than silently reinterpreted, because two of them would have destroyed finished work (D274).

- **A prompt reused across document versions carries its old assumptions silently.** Three clauses of the prompt that produced the v3 spec referred to things that no longer existed — a lettered strategy from a different brainstorming document, a six-bot roster from before thirty-one were built and calibrated, and a tooling skill unavailable in the environment. Two of the three would have passed a casual reading and deleted implemented work, and neither would have failed a build.
- **The `to-spec` tooling is not available here.** The section list — goal, scope, non-goals, exposed endpoints, data, acceptance criteria — is followed directly.
