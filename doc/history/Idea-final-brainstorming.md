# Quadrim — Build Approach Brainstorming

How to build what [Idea-final.md](Idea-final.md) specifies.
The spec says *what*. This says *in what order, in what shape, and why*.

Date: 2026-07-27
Status: approaches proposed, awaiting a decision. No code written.

---

## 1. The constraints that decide everything

Established before proposing anything:

| Constraint | Value |
|---|---|
| Team | Solo, with Claude Code |
| Cadence | Evenings and weekends |
| Experience | New to both Flutter and Firebase |
| First success | An app live in the App Store and Play Store |
| Scope flexibility | Stageable — Idea-final.md is the 1.0 target, not the first release |
| First platform | Android first, iOS shortly after |
| Store accounts | None yet. Mac available for iOS builds |
| Client architecture | Riverpod, layered, testable |
| Testing | Strict TDD on engine and rules, pragmatic elsewhere |
| Server rules | TypeScript Cloud Functions, shared artifacts generated from one source |
| Solver | Separate offline tool in Rust or C |

### 1.1 The honest reading

Idea-final.md is five projects wearing one hat: a game engine, a build-time perfect-play solver, a Flutter client for five platforms, a Firebase backend with matchmaking and moderation, and content work across twenty bots and two languages. Built literally as written, by one person on evenings, that is a multi-year effort in which nothing is playable for months.

Nothing needs to be cut. It needs to be **ordered**, and the order should be driven by two things the spec does not mention: what produces feedback soonest, and what has lead times outside your control.

### 1.2 The critical path is not code

Two facts dominate the schedule and neither is a programming task:

**Google Play closed testing.** Personal developer accounts created after November 2023 must run a closed test with at least 12 testers for 14 continuous days before production access is granted. That clock cannot start until there is a build to test. It is the single longest lead time in the project and it runs in parallel with development — if you let it.

**Apple enrolment.** $99/year, with identity verification that can take days to weeks. Also parallelisable, also currently not started.

**Implication:** the first release should be whatever is *shippable soonest*, because its real job is to start those clocks and to teach you the release pipeline. Its feature set is almost secondary.

### 1.3 The compliance insight

An offline-only build has **no accounts and no user-generated content**. That means no in-app account deletion requirement, no chat moderation, no blocking or reporting, and a trivial Data Safety declaration. The moment the app has accounts and chat, all of Section 8 of the spec becomes mandatory *before* review will pass.

Learning App Store Connect and Play Console on a build with zero compliance surface, then adding accounts once the pipeline is understood, is dramatically easier than meeting both learning curves at once.

---

## 2. Decomposition — true for every approach

Whatever the order, the seams go in the same places. This is the part worth getting right regardless.

### 2.1 Modules

```
quadrim/
  packages/
    quadrim_engine/     pure Dart, zero Flutter and zero Firebase
    quadrim_rating/     pure Dart ELO maths
  tools/
    linegen/            single source of the 76 lines + test corpus
  app/                  Flutter client (Riverpod)
  functions/            TypeScript Cloud Functions
  solver/               Rust, offline, emits the strategy book
```

| Module | Responsibility | Depends on |
|---|---|---|
| `quadrim_engine` | Board state, the 76 lines, legal moves, win and threat detection, the bot engine and its 20 configurations | nothing |
| `quadrim_rating` | ELO expected score and update, provisional K, floor | nothing |
| `linegen` | Emits the 76-line table as Dart *and* TypeScript, plus a JSON corpus of full games with known outcomes | nothing |
| `app` | UI, navigation, persistence, Firebase wiring, i18n, accessibility | engine, rating |
| `functions` | Move validation, result and rating writes, expiry sweeps, notifications, moderation | generated artifacts |
| `solver` | Precomputes the proven winning strategy, once, on a desktop | nothing |

### 2.2 The interfaces that matter

**The engine is pure.** `quadrim_engine` must not import Flutter, Firebase, `dart:io`, or any clock or random source it does not receive as a parameter. Every function is deterministic given its inputs. This is what makes TDD on it pleasant and what lets the identical code run in a test, in the app, and in a headless self-play harness for bot calibration.

```
GameState        immutable; board, side to move, move list
legalMoves(GameState) -> List<Cell>
applyMove(GameState, Cell) -> GameState
outcome(GameState) -> Outcome        // ongoing | win(line) | draw
Bot.chooseMove(GameState, Random) -> Cell
```

Note `outcome` returns the *winning line*, not a boolean — Section 7.8 of the spec requires highlighting it, and retrofitting that later means touching every call site.

**Persistence is behind an interface from day one.** This is the single most important decision for staging:

```
abstract class GameRepository {
  Stream<Game> watch(GameId id);
  Future<void> appendMove(GameId id, Cell cell);
  Stream<List<Game>> activeGames();
  ...
}
```

Release 0.1 implements it locally. Release 0.3 adds a Firestore implementation. **The UI never changes.** Without this seam, adding online play means rewriting every screen; with it, online play is a new implementation of a known contract.

**Bots are data, not classes.** One engine, twenty configurations, per spec §6.1. A bot is a config record plus a shared `chooseMove`. Adding a twenty-first is a data change, and calibrating all twenty is a matter of running self-play over configurations rather than over code paths.

### 2.3 Solving the two-language rules problem

You chose TypeScript functions with generated shared artifacts. Concretely:

- `linegen` owns the *only* definition of the 76 lines. It emits a Dart file and a TypeScript file, both generated, both committed, both marked do-not-edit.
- `linegen` also emits a corpus of complete games — move lists with known outcomes, including every win family and forced draws.
- The Dart test suite and the TypeScript test suite both run against that same corpus.
- CI fails if the generated files are stale or if either implementation disagrees with the corpus.

Rules logic still exists twice. Drift becomes a test failure rather than a production bug, which is the achievable goal here.

---

## 3. The approaches

### Approach A — Store-First Offline Slice ⭐ recommended

Ship a genuinely good offline game to the stores as fast as possible. Add the network later.

**Release ladder**

| Release | Contains | Purpose |
|---|---|---|
| 0.1 | Engine, board UI, 6 bots, pass-and-play, phone portrait layout, English | First Play Console upload. **Starts the 14-day closed-test clock.** |
| 0.2 | iOS build, tutorial, all 20 bots, Dutch, accessibility, large-screen layout | Production-quality offline game on both stores |
| 0.3 | Anonymous auth, profiles, async online, invite links, ELO, push | First backend release. Brings account deletion and privacy work with it. |
| 0.4 | Chat with block/report/filter, friends, open challenges, auto-match | Completes the social surface |
| 0.5 | Real-time mode with clocks, web and desktop builds | Completes the mode matrix |
| 1.0 | Solver, Quadrim Prime, rating recalibration | The spec, in full |

**Why it fits.** It puts the two long external clocks — Play closed testing, Apple enrolment — into motion in weeks rather than months. It front-loads the part that is pure logic, testable, and the actual heart of the game, and it happens to be the part best suited to TDD and to working with an AI assistant. It defers the entire compliance surface until you already know how store review behaves. And on a hobby cadence it produces something playable early, which is the difference between a project that ships and one that becomes a folder.

**Costs, stated plainly.** Firebase learning is deferred, so the backend releases will feel like a step change in difficulty. Local persistence in 0.1 must be designed knowing Firestore is coming, or 0.3 becomes a migration. Rated bot play is promised in the spec but cannot be rated until accounts exist in 0.3 — 0.1 and 0.2 must present bot games honestly as unrated practice, and local stats must be designed to fold into a server profile later.

**What makes it work.** The `GameRepository` seam from §2.2, and modelling the domain for the online future in 0.1 even while the implementation is local.

---

### Approach B — Foundation First

Build the engine, then the complete Firebase backend, then the client on top. Ship when it is whole.

**Why it appeals.** No migrations, no interim compromises, no "we'll fix this in 0.3". Anti-cheat and the authority model are correct from the first line. The architecture is coherent because it was never bent around a shortcut.

**Why I do not recommend it here.** It is the approach most sensitive to exactly your constraints. Months pass with nothing playable, on a cadence where motivation is the scarcest resource. Neither store clock has started, so even when the code is finished the release is still weeks away. And it asks you to make consequential backend decisions in an unfamiliar stack with no working system to validate them against — the errors surface late, all at once.

This is a good approach for a funded team with a deadline. It is a poor one for evenings and weekends.

---

### Approach C — Walking Skeleton

Build the thinnest possible slice that touches every layer at once — one bot, a crude board, anonymous auth, one Firestore document, one validating function, deployed to a device — then thicken each layer in place.

**Why it appeals.** It is the textbook answer for unfamiliar stacks, and the textbook is usually right. Every integration risk is discovered on day one instead of month four. There is never a big-bang integration. You learn Flutter and Firebase together, on a system small enough to hold in your head.

**Why it comes second, not first.** For someone new to both, the skeleton is not thin. It means Flutter, Riverpod, Firestore, security rules, the emulator suite, TypeScript functions, and Android signing before a single satisfying moment of play. And it still does not produce a store build early, so the long clocks stay unstarted.

**Worth stealing from it:** the discipline of proving each new layer end to end on a trivial case before building breadth on top. Approach A should adopt that within each release — release 0.3 in particular should begin with its own miniature skeleton (auth → one game document → one function → one device) before any feature work.

---

### Approach D — Engine as a standalone product first

Build and perfect `quadrim_engine` as a published Dart package with a CLI, including the solver, before any app exists.

**Why it appeals.** Maximum focus on the intellectually interesting part. Bot calibration (spec open item OI-03) needs a headless self-play harness anyway, so building the engine as a standalone tool with a CLI is not wasted work. The engine is fully testable with zero UI.

**Why it is not the whole plan.** It is a component strategy mistaken for a project strategy. Taken alone it produces no app, no store presence, and no feedback. The solver in particular is open item OI-02 — unknown effort, unknown output size — and putting an unbounded research task before anything playable is how a hobby project quietly ends.

**Worth stealing from it:** build the engine as a genuine standalone package with a self-play CLI from the start. Approach A does this in 0.1 and gets the calibration harness for free.

---

## 4. Recommendation

**Approach A, with the layer-proving discipline of C and the standalone-engine rigour of D.**

Concretely, that means:

1. Start both store enrolments **this week**, before writing anything. They cost money and waiting time, not effort, and they gate your stated definition of success.
2. Build `quadrim_engine` as a pure, standalone, TDD'd Dart package with a self-play CLI. No Flutter anywhere near it.
3. Build `linegen` early — it is small, and everything downstream depends on the 76 lines being defined exactly once.
4. Build the 0.1 app: board, six bots, pass-and-play, local persistence behind `GameRepository`.
5. Upload to Play closed testing the moment it is playable, even while polishing. **The 14-day clock is the point.**
6. Recruit the 12 testers early — this is a real task with a real lead time and it is not a programming problem.
7. Then 0.2 polish and iOS, then the backend releases in order.

Deviating from A is entirely reasonable if what you actually want from this project is the engine and the solver, and the store presence is secondary. In that case say so, and D becomes the spine instead — but then "live in the stores" stops being the first success criterion, and that should be a conscious trade rather than a drift.

---

## 5. Risks this ordering creates, and the mitigations

| Risk | Why it arises under Approach A | Mitigation |
|---|---|---|
| Local persistence shape blocks the Firestore migration | 0.1 stores games locally with no server in mind | Design the game document schema in 0.1 as if it were already Firestore; implement `GameRepository` locally against that shape |
| Local stats cannot fold into a server profile | 0.1 and 0.2 accumulate offline history against an anonymous device | Keep a stable local player identity from 0.1; 0.3's anonymous auth adopts it rather than replacing it |
| Bot ratings claimed before rating exists | Spec §5 rates bot games; 0.1 has no accounts | Present bot games as unrated practice in 0.1 and 0.2; introduce rating in 0.3 with the calibration already done |
| Backend difficulty spike at 0.3 | All Firebase learning deferred to one release | Start 0.3 with its own walking skeleton; use the Firebase emulator suite from the first day of backend work |
| Solver never gets built | It sits at 1.0, after everything | This is acceptable and already handled: spec §6.5's fallback ladder ships Titan as top bot and adjusts Prime's claim honestly |
| Store review rejects the first upload | New to the process | This is precisely why the first upload has no accounts, no UGC, and no network — the smallest possible thing to be rejected over |
| Twelve testers not found in time | Not a code problem, so easily forgotten | Treat tester recruitment as a tracked task starting at 0.1, not a formality at the end |

---

## 6. What I still need from you

Nothing blocking. These become the first questions of the implementation plan:

- Confirm Approach A, or name the deviation.
- Which six bots go in 0.1. My suggestion: Pebble, Mote, Bramble, Ember, Basalt, Onyx — a real difficulty spread from trivial to genuinely challenging, exercising every engine feature except deep search.
- Whether 0.1 ships with a placeholder visual identity or waits for real art. My recommendation: placeholder, since closed testing is not public.

---

## 7. Open items inherited from the spec

Unchanged, and none of them block starting:

- **OI-01** Push unsupported on Flutter desktop; degraded behaviour must be surfaced — first matters at 0.5
- **OI-02** Solver effort and asset size unknown — deliberately deferred to 1.0
- **OI-03** Bot rating calibration — the self-play CLI built in step 2 above is the tool for this
- **OI-04** Auto-match cold start — first matters at 0.4
- **OI-05** Firebase cost model — first matters at 0.3
