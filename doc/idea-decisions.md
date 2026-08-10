# Quadrim — Decision Log

Every decision taken while turning [IDEA.md](history/IDEA.md) into a specification, a build approach, and a set of tickets.
Each entry records the question, the decision, and what it costs or buys.

Date: 2026-07-27
Status: agreed, pre-implementation. No code written.

## Steps

The project was planned in five steps, each producing one document. Decisions are numbered continuously and grouped by the step that produced them.

| Step | What it did | Produced | Decisions |
|---|---|---|---|
| 1 | Turned the rough idea into an unambiguous specification | [Idea-final.md](Idea-final.md) | D01–D35 |
| 2 | Chose a build approach and release staging | [Idea-final-brainstorming.md](history/Idea-final-brainstorming.md) | D36–D46 |
| 3 | Wrote the implementable specification | [Idea-final-spec.md](Idea-final-spec.md) | D47–D58 |
| 4 | Broke release 0.1 into tickets | [tickets/](tickets/) | D59–D64 |
| 5 | Reconciled the spec with a decision reversed in step 4 | [Idea-final-spec.md](Idea-final-spec.md) | D65 |
| 6 | Expert review by backend, security and product reviewers | [Idea-final-spec-review.md](history/Idea-final-spec-review.md) | D66–D83 |
| 7 | Private early releases and a clean start at 0.3 | [Idea-final-spec.md](Idea-final-spec.md) | D84–D91 |
| 8 | Split ratings, the full roster, and a subscription | all documents | D92–D100 |
| 9 | Second expert review: 0.3b becomes free online play | all documents | D101–D118 |
| 10 | The published Qubic literature | [Idea-final.md](Idea-final.md) §2.2, §2.3, §6.5.1, §14 | D119–D121 |
| 11 | First-run experience design review | [FirstRunHandoff.md](FirstRunHandoff.md) | D122–D129 |
| 12 | Implementation | the code | D130+ |

Open items carried across all steps are listed at the end.

---

# Step 1 — From idea to specification

Decisions D01–D35. Established what Quadrim *is*, without regard to how or in what order it would be built.

## 1. Scope and platforms

### D01 — Game modes
**Question:** Which modes must v1 support?
**Decision:** All four — asynchronous online vs human, real-time online vs human, vs computer (on-device), and local pass-and-play.
**Rationale:** Real-time is not a separate system: it is the async engine with both players subscribed to the same Firestore document plus a move clock. Pass-and-play needs no backend at all.
**Consequence:** One game-state model serves three of the four modes. Only the clock and presence handling are real-time-specific.

### D02 — Platforms in v1
**Question:** Which platforms actually ship?
**Decision:** iOS, Android, Web, Windows, and macOS.
**Rationale:** Flutter covers all five from one codebase; the idea document asks for maximum reach.
**Consequence:** Five build and release pipelines. Push notification support is not uniform across them — see [D26](#d26--push-notifications) and [OI-01](#oi-01--push-notifications-on-desktop-and-web).

### D03 — Business model
**Question:** Ads, in-app purchases, or free?
**Decision:** Free. No ads, no IAP.
**Rationale:** No billing SDK, no ad SDK, no revenue-related privacy disclosures. Fastest path to a shippable, reviewable app.
**Consequence:** No monetisation infrastructure exists; adding it later is a deliberate new project.

### D04 — Languages
**Question:** Which languages at launch?
**Decision:** English and Dutch, both complete at launch. English is the fallback locale.
**Rationale:** Full localisation plumbing from day one avoids retrofitting hard-coded strings later, which is the expensive way to do it.
**Consequence:** Every user-facing string lives in ARB resource files from the first commit. Bot names stay untranslated; bot personality blurbs are translated.

---

## 2. Identity and accounts

### D05 — Authentication
**Question:** How do players sign in?
**Decision:** Firebase anonymous authentication on first launch. Upgrade to Google or Apple sign-in is prompted only when the player wants online play or cross-device sync.
**Rationale:** The player can tap "play" within seconds of install. Tutorial, bot games, and pass-and-play need no account.
**Consequence:** Account-linking flow must preserve the anonymous account's stats and rating. An unlinked account lost with the device is lost permanently, and the app must say so before the player invests in a rating.

### D06 — Profile visible to opponents
**Question:** What does an opponent see when tapping your name?
**Decision:** Display name, avatar, ELO rating, win/loss/draw record, head-to-head record against the viewer, member-since date, and last-active date.
**Rationale:** Matches the large-screen layout described in the idea document.
**Consequence:** Head-to-head requires a per-pair aggregate, maintained by Cloud Function rather than computed by scanning game history on every profile open.

### D07 — Avatars
**Question:** Uploaded photos or a built-in set?
**Decision:** Built-in set only. Human players and computer players draw from the same curated pool.
**Rationale:** Photo upload requires Cloud Storage, an image moderation pipeline, and a report-an-image path. A shipped set costs an asset folder.
**Consequence:** No image moderation surface at all. Avatar variety is bounded by what is shipped.

### D08 — Display names
**Question:** How are display names handled?
**Decision:** Player-chosen, globally unique, validated server-side against a profanity list. Immutable for 30 days after each change.
**Rationale:** Uniqueness makes friend-by-name search work. The cooldown stops name-swapping used to evade blocks.
**Consequence:** A uniqueness index collection and a name-claim transaction are needed.

---

## 3. Game rules

### D09 — Winning lines
**Question:** Exactly which lines win?
**Decision:** All 76 lines. 48 axis-aligned + 24 planar diagonals + 4 space diagonals. This is standard Qubic.
**Rationale:** Confirmed as the intended game.
**Consequence:** The 76-line table is precomputed once as a constant and drives win detection, threat detection, and the AI evaluation function. It is the single most important shared data structure in the project.

### D10 — Placement rule
**Question:** Any constraints on where a piece may go?
**Decision:** Any empty cell, always. No gravity, no adjacency requirement, no reserved cells.
**Rationale:** As described in the idea document. This is Qubic, not 3D Connect-4.
**Consequence:** Legal-move generation is simply "all empty cells".

### D11 — First move and colour
**Question:** Who starts?
**Decision:** Random on the first game between two opponents. In a rematch, the other player starts. Colour follows the starting order.
**Rationale:** Qubic has a proven first-player advantage. Alternating across a series makes a rematch pair fair even though a single game is not.
**Consequence:** The game document stores which player started and why, so the rematch flow can invert it.

### D12 — Draw condition
**Question:** When is a game drawn?
**Decision:** All 64 cells filled with no line completed, or both players agree to a draw.
**Rationale:** Standard.
**Consequence:** Draws count as half a point for ELO.

### D13 — Available in-game actions
**Question:** What can a player do besides placing a piece?
**Decision:** Resign, and offer/accept/decline a draw. **No takebacks and no undo, not even against computer players.**
**Rationale:** Takeback is a negotiated two-party state machine that touches move history, clocks, and rating. Undo against bots would make bot games unrateable, which conflicts with [D18](#d18--do-bot-games-affect-human-elo).
**Consequence:** A move, once submitted, is final in every mode. Move history is append-only, which makes replay trivial and the audit trail sound.

### D14 — Move history and replay
**Question:** Is the full move list retained?
**Decision:** Yes, forever, for every game including bot and pass-and-play games. Every completed game is fully replayable and scrubbable.
**Rationale:** A game is at most 64 moves — a few hundred bytes. The idea document requires stepping back and forward through past games.
**Consequence:** Storage growth is negligible. Replay is a pure function of the move list, so no separate replay format is needed.

---

## 4. Clocks and abandonment

### D15 — Time controls
**Question:** What time limits apply?
**Decision:** Async games have no move clock but a 7-day inactivity deadline. Real-time games have a 60-second per-move countdown; exceeding it forfeits the game. Pass-and-play and bot games are untimed.
**Rationale:** Async play should tolerate real life. Real-time play needs a way to end when someone walks away.
**Consequence:** Two independent timeout mechanisms, both enforced by Cloud Functions rather than clients.

### D16 — Abandonment outcome
**Question:** An async game sits untouched for a week. What happens?
**Decision:** Reminder push at day 5. At day 7 the player whose turn it is forfeits; the game is recorded as a loss and ELO updates normally.
**Rationale:** Any softer rule (auto-draw, void) makes walking away a free escape from a losing position, which corrupts the rating system.
**Consequence:** A scheduled Cloud Function must sweep for expired games. The 5-day warning is required so the forfeit is never a surprise.

### D17 — Concurrent game cap
**Question:** How many games can one player have running?
**Decision:** Soft cap of 20 simultaneous active games against human opponents. Bot games are not capped.
**Rationale:** Bounds the active-games list, bounds per-user query cost, and stops queue-spam abuse.
**Consequence:** Attempting to start a 21st human game gives a clear message rather than a silent failure.

---

## 5. Rating

### D18 — Do bot games affect human ELO?
**Question:** Are computer games rated?
**Decision:** Yes. Computer players have hand-calibrated, **fixed** ratings that never move. Human ratings change from every rated game, human or computer.
**Rationale:** Fixed bots are a stable measuring stick. Floating bot ratings drift toward whatever the population does to them and make rating circular.
**Consequence:** Bot ratings must be calibrated before launch by self-play plus human testing ([OI-03](#oi-03--bot-rating-calibration)). Once published they are effectively frozen; changing one retroactively invalidates player histories.

### D19 — Rating formula
**Question:** Which rating system?
**Decision:** Standard ELO. Seed 1200. K = 32 for a player's first 20 rated games (provisional), K = 16 thereafter. Win = 1, draw = 0.5, loss = 0. Expected score `E = 1 / (1 + 10^((Ropp - Rown) / 400))`. New rating `R' = round(R + K × (S - E))`. Floor of 100.
**Rationale:** Well understood, explainable to players in one sentence, and cheap to compute.
**Consequence:** Ratings are computed only in the Cloud Function, never on a client.

### D20 — Which modes are rated
**Question:** Do all modes affect rating?
**Decision:** Async online, real-time online, and vs-computer games are rated. Local pass-and-play is **unrated**.
**Rationale:** Pass-and-play has no authenticated second party, so its result is unverifiable and trivially farmable.
**Consequence:** Pass-and-play games are stored locally and appear in history flagged as unrated.

---

## 6. Matchmaking

### D21 — How players find opponents
**Question:** Which matchmaking mechanisms?
**Decision:** All four — invite link/game code, automatic ELO-based matching, a friends list, and a public open-challenge board.
**Rationale:** Requested. They also cover each other's cold-start weaknesses: invite links and the challenge board work with a tiny population, auto-match needs a large one.
**Consequence:** Four entry paths into the same "create game" operation. The friends list adds a request/accept data model. Auto-match adds a queue collection and a matchmaker function.

---

## 7. Computer players

### D22 — Where the engine runs
**Question:** Device or cloud?
**Decision:** On-device, in Dart. Every computer player, including the perfect one.
**Rationale:** Zero latency, works offline, no per-move cloud cost, and the same code is directly unit-testable.
**Consequence:** The engine must be fast and small enough for a phone. This is what forces [D24](#d24--how-the-perfect-bot-achieves-perfect-play).

### D23 — Number and design of computer players
**Question:** Is "about 20" firm, and how are they built?
**Decision:** Ship 20, generated as named configurations of one parameterised engine. The parameter axes are: search depth, which strategic rules are enabled, blunder rate, positional bias, aggression versus defence weighting, and tie-break randomness.
**Rationale:** Twenty hand-written strategies is twenty times the code and twenty times the balancing. One engine with twenty configurations gives distinct, recognisable play styles for a fraction of the effort, and a twenty-first is a data change.
**Consequence:** Personality must be *visible* in play, not just in the blurb. Each bot needs a play-style description that a player can actually observe at the board.

### D24 — How the perfect bot achieves perfect play
**Question:** The top bot must play perfectly. How?
**Decision:** A build-time solver precomputes the proven first-player winning strategy and ships it as a compressed asset. At runtime the bot follows the book, and switches to exact search once the position is small enough to solve outright.
**Rationale:** Qubic is solved, but "solved" means a proof exists — not that alpha-beta at any practical depth reproduces it. Deep search alone is *strong*, not perfect. Runtime proof-number search would need seconds to minutes per opening move on a phone, which is unacceptable.
**Consequence:** The solver is a **separate build-time deliverable**, not part of the app. Asset size is unknown until it exists ([OI-02](#oi-02--strategy-book-size-and-solver-effort)). A fallback ladder is defined in Idea-final.md so the app can ship even if the book proves impractical.
**Honest caveat, agreed with the user:** the perfect bot is unbeatable when it moves first. That is the mathematical truth of the game, not a design flaw. Moving second it plays optimal defence and can be drawn but not beaten by perfect play.

---

## 8. User interface

### D25 — Board interaction
**Question:** How is a piece placed?
**Decision:** All four layers are drawn simultaneously as parallelograms suggesting depth. The player taps an empty cell directly — one tap, one move, no confirmation step.
**Rationale:** The whole cube stays visible, which is the point of the layered representation. A confirm step doubles the interaction cost of every move.
**Consequence:** Touch targets must stay finger-sized on the smallest supported phone; this constrains how much perspective skew the layers can carry.

### D26 — Push notifications
**Question:** What triggers a push?
**Decision:** Your turn, new chat message, game ended, and challenge received. Each is individually toggleable in settings.
**Rationale:** Async play is unusable without a turn notification. The rest are the events a player would otherwise have to poll for.
**Consequence:** Notification delivery is not uniform across the five platforms ([OI-01](#oi-01--push-notifications-on-desktop-and-web)).

### D27 — Orientation and layout
**Question:** Confirm the portrait/landscape lock?
**Decision:** Confirmed. Phones are portrait-only, large screens are landscape-only. The breakpoint is the shortest side of the window: under 600 dp is a phone, 600 dp or more is a large screen.
**Rationale:** One layout per form factor is half the layout work and eliminates awkward intermediate states.
**Consequence:** On desktop, a window narrower than 600 dp on its short side shows the phone layout. Resizing a desktop window can switch layouts live, so both must survive a rebuild mid-game.

### D28 — Accessibility
**Question:** What is required in v1?
**Decision:** All four: colourblind-safe pieces distinguished by shape as well as colour, screen reader labels for every cell and for game state, system font scaling with finger-sized targets, and working light and dark themes.
**Rationale:** The entire game is "my colour against yours". Colour-only encoding excludes roughly one in twelve men outright.
**Consequence:** Piece rendering carries a shape token, not just a fill colour. Every cell exposes a semantic label such as "layer 2, row 3, column 1, empty".

### D29 — End of game
**Question:** What happens when a game ends?
**Decision:** A result screen showing the winning line highlighted on the board and the ELO change for both players, plus a one-tap rematch button that swaps colours and the starting player.
**Rationale:** The rating change is the reward loop; hiding it wastes the moment. Rematch is the cheapest retention mechanism there is.
**Consequence:** The winning line must be identifiable, not just the fact of a win — win detection returns *which* of the 76 lines completed.

### D30 — Tutorial
**Question:** What must it teach?
**Decision:** Four parts — the rules and what the 76 winning lines look like, the controls and how to read the layered board, basic strategy (centre and corner value, double threats, blocking), and an interactive guided practice game against a scripted opponent with hints.
**Rationale:** The diagonals spanning layers are the part players consistently miss, and they cannot be learned from a static screen.
**Consequence:** The tutorial needs a scripted-opponent mode and a hint overlay — real features, not just content.

---

## 9. Chat and safety

### D31 — Chat scope
**Question:** Who can chat, and about what?
**Decision:** Free-text 1:1 chat, available only between the two players of a shared game, only while that game exists in history. No chat with computer players, no group chat, no global chat.
**Rationale:** Chat scoped to an existing game relationship is the narrowest surface that satisfies the requirement.
**Consequence:** Chat permissions derive from game membership, so security rules are straightforward.

### D32 — Safety features
**Question:** What moderation is needed?
**Decision:** Block a player, report a player or message, and server-side profanity filtering before delivery.
**Rationale:** Apple and Google both effectively require blocking and reporting for any app with user-generated content. Shipping without them risks rejection.
**Consequence:** A blocklist collection, a reports collection, and a filter in the message-write path. Blocking must also prevent challenges, not just messages.

### D33 — Account deletion
**Question:** Not asked, but required.
**Decision:** In-app account deletion that removes personal data — display name, avatar choice, chat messages, reports authored — while retaining anonymised game records so opponents' rating histories stay coherent.
**Rationale:** Apple requires in-app account deletion for any app that supports account creation. GDPR applies to an EU-based developer regardless.
**Consequence:** A deletion Cloud Function and a documented retention position are mandatory before submission, not optional polish.

---

## 10. Backend architecture

### D34 — Rules authority
**Question:** Who decides whether a move is legal and whether it wins?
**Decision:** The client computes and renders immediately; a Firestore-triggered Cloud Function re-validates every move, detects the win, and writes the result and the rating change.
**Rationale:** Instant local feedback with a tamper-proof outcome. A modified client cannot forge a win or inflate a rating.
**Consequence:** The same rules logic exists in Dart (client) and in the function. Both must be driven by the same 76-line definition and covered by the same test vectors, or they will diverge.

### D35 — What clients may write
**Decision:** A client may append its own move to its own game and write its own chat messages. It may never write game results, ratings, or another player's data. Enforced by Firestore security rules.
**Rationale:** Follows directly from D34.
**Consequence:** Rating and result fields are function-only writes.

---

---

# Step 2 — Build approach and staging

Decisions D36–D46. Produced [Idea-final-brainstorming.md](history/Idea-final-brainstorming.md). Where step 1 asked *what*, this step asked *by whom, in what order, and with what constraints* — and the answers reshaped the plan considerably.

## 11. Who is building it

### D36 — Team and cadence
**Question:** Who is building this, and at what capacity?
**Decision:** Solo, with Claude Code, evenings and weekends.
**Rationale:** Stated constraint.
**Consequence:** The dominant scarce resource is motivation, not skill or money. Any plan that produces nothing playable for months is disqualified regardless of its technical merits. This single fact drove the entire staging strategy.

### D37 — Experience level
**Question:** How familiar is the developer with Flutter and Firebase?
**Decision:** New to both.
**Rationale:** Stated constraint.
**Consequence:** Two unfamiliar stacks cannot be learned productively at once with no working system to validate against. Favours deferring the backend until the client is understood, and favours proving each new layer end to end on a trivial case before building breadth on it.

### D38 — Store accounts and hardware
**Question:** Do developer accounts already exist?
**Decision:** Neither Apple nor Google account exists yet. A Mac is available for iOS builds.
**Rationale:** Stated constraint.
**Consequence:** Two long lead times sit outside the developer's control and outside the code: Apple enrolment identity verification, and Google Play's closed-testing requirement. Both became critical-path items. See [D45](#d45--definition-of-first-success) and [D60](#d60--when-the-first-store-upload-happens).

## 12. Technical approach

### D39 — Server-side rules language
**Question:** The spec requires rules logic on both client and server, but Firebase Cloud Functions does not run Dart — only Node/TypeScript and Python. How should the server validate moves?
**Decision:** TypeScript Cloud Functions, with the 76-line table and a corpus of full games generated from one source and shared by both implementations.
**Rationale:** Keeps the standard Firebase path with its lowest operational cost. Running Dart on Cloud Run would remove the duplication entirely but adds a container, cold starts, and a step outside plain Firebase.
**Consequence:** Rules logic exists twice, in two languages. Drift is prevented not by discipline but by construction: neither implementation authors the line table, and both must pass the same generated corpus. Drift becomes a CI failure rather than a production bug. This is the origin of [D53](#d53--the-76-lines-have-exactly-one-definition) and of ticket 002.

### D40 — Solver language and host
**Question:** Where should the perfect-play solver live?
**Decision:** A separate offline tool in Rust or C. It runs once on a desktop; the app consumes only its output.
**Rationale:** The solver never runs on a phone, so raw speed matters more than language consistency with the app.
**Consequence:** The solver is not app code and not on the app's critical path. Reinforces deferring it to 1.0 with the fallback ladder of [D24](#d24--how-the-perfect-bot-achieves-perfect-play) as the answer if it proves impractical.

### D41 — Client architecture
**Question:** How opinionated should the Flutter client architecture be for someone new to Flutter?
**Decision:** Riverpod, layered into pure domain, data, and presentation, and testable throughout.
**Rationale:** One well-supported state solution with clear boundaries. More concepts to learn up front, but the structure holds at the size this app reaches — real-time streams, async games, and chat all touching the same screens is exactly where minimal state management tangles.
**Consequence:** A learning curve at the start, in exchange for not restructuring the app at 0.3.

### D42 — Testing discipline
**Question:** How much testing discipline?
**Decision:** Strict TDD on the engine, the rules, the rating maths, and bot behaviour. Pragmatic coverage elsewhere.
**Rationale:** These are pure logic with exactly correct answers, which is where TDD pays for itself. UI and Firebase wiring are not.
**Consequence:** Directly produced the seam structure of [D56](#d56--test-seams).

## 13. Staging

### D43 — Scope is stageable
**Question:** Must everything in the specification land in one release?
**Decision:** No. [Idea-final.md](Idea-final.md) becomes the **1.0 target**, delivered across releases 0.1 through 1.0. Nothing is cut; things are ordered.
**Rationale:** The specification as written is five projects — engine, solver, client, backend, content — and planning them as one unit is how projects stall at 70%.
**Consequence:** Every subsequent document addresses a release rather than the whole product. Created the release ladder.

### D44 — Build approach
**Question:** Which of the four proposed approaches — store-first offline slice, foundation-first, walking skeleton, or engine-first — should the project follow?
**Decision:** **Approach A, store-first offline slice**, adopting the layer-proving discipline of the walking skeleton and the standalone-engine rigour of the engine-first approach.
**Rationale:** It is the only approach that starts the uncontrollable store clocks early, defers the entire compliance surface until the release pipeline is understood, and produces something playable while motivation is still available. Foundation-first is right for a funded team with a deadline and wrong for evenings and weekends.
**Consequence:** Release 0.1 is a complete offline game with no accounts and no network. Confirmed by the user at the start of step 3.

### D45 — Definition of first success
**Question:** What is the first moment this project stops feeling theoretical?
**Decision:** An app live in the App Store and Play Store.
**Rationale:** Stated preference.
**Consequence:** Consequential and easy to underestimate. It makes **store logistics a critical path item rather than a closing formality**: Apple enrolment verification, and Google Play's requirement that personal accounts created after November 2023 run a closed test with at least twelve testers for fourteen continuous days before production access. Neither is a programming task; both gate the stated definition of success.

### D46 — First platform
**Question:** Which platform ships first?
**Decision:** Android first, iOS shortly after.
**Rationale:** Cheaper, faster review, no Mac dependency in the loop, and the fourteen-day closed test can begin as soon as any build exists.
**Consequence:** Release 0.1 is Android-only. iOS moves to 0.2.

---

# Step 3 — Specification

Decisions D47–D58. Produced [Idea-final-spec.md](Idea-final-spec.md), covering the whole 1.0 roadmap with release 0.1 at implementation depth.

## 14. Spec scope and shape

### D47 — What the specification covers
**Question:** Does the spec cover release 0.1 only, or the whole roadmap?
**Decision:** The whole 1.0 roadmap, with only 0.1 at implementation depth. Later releases are scoped, not detailed.
**Rationale:** The roadmap needs to be visible in one place, but specifying chat moderation before the board exists produces detail that is stale before it is read.
**Consequence:** Each later release gets its own spec when its turn comes.

### D48 — Meaning of "exposed endpoints"
**Question:** Release 0.1 is offline with no API. What does an endpoints section describe?
**Decision:** The public module APIs — the engine package, the rating package, and the `GameRepository` contract.
**Rationale:** These are the real contracts in 0.1 and the surfaces every later release builds against.
**Consequence:** The spec documents module boundaries with the same rigour it would give a network API.

### D49 — Release 0.1 feature set
**Question:** Which parts of the full experience are in 0.1?
**Decision:** Move-history scrubber, result screen with rematch, local statistics and a replayable completed-games list, and the tutorial.
**Rationale:** Requested. Each is cheap given an append-only move list, except the tutorial.
**Consequence:** 0.1 is a complete-feeling game rather than a demo, at the cost of being a larger first release.

### D50 — Tutorial depth in 0.1
**Question:** How much of the four-part tutorial ships in 0.1?
**Decision:** All four parts, including the interactive guided practice game with hints.
**Rationale:** Requested. A closed tester meeting a 4×4×4 board for the first time needs it.
**Consequence:** Significant. The scripted opponent and the hint overlay are genuine features, not content, and they delay the first upload. Mitigated by deriving hints from existing threat detection rather than scripting them ([D57](#d57--the-scripted-tutorial-opponent-is-a-bot-configuration)).

### D51 — Layouts in 0.1
**Question:** Phone only, or both layouts?
**Decision:** Both phone portrait and large-screen landscape.
**Rationale:** Requested. Play Console surfaces tablet quality warnings.
**Consequence:** Roughly doubles the layout and test surface of 0.1. Mitigated by one board component serving both, differing in size and chrome rather than structure.

### D52 — Languages in 0.1
**Question:** English only, or both from the start?
**Decision:** English and Dutch, both complete, from 0.1.
**Rationale:** The string count is at its smallest now, and translating as you go is far cheaper than a retrofit sweep.
**Consequence:** Every ticket from 004 onward carries "strings present in both languages" as acceptance criteria rather than there being a translation ticket. See [D62](#d62--localisation-and-accessibility-are-per-ticket-criteria).

## 15. Data and technical decisions

### D53 — Local persistence format
**Question:** How does 0.1 store games, given it must migrate to Firestore in 0.3 without a rewrite?
**Decision:** JSON documents keyed by id, shaped exactly as the Firestore documents will be.
**Rationale:** Makes the 0.3 migration a transport swap behind `GameRepository` rather than a data redesign.
**Consequence:** Drove the participant identity scheme ([D54](#d54--participant-identity-scheme)), the presence of an always-false `rated` field in 0.1, and the deliberate absence of fields 0.3 will add.

### D54 — Participant identity scheme
**Question:** How are players identified before accounts exist?
**Decision:** Tagged string identities — `local:<deviceId>`, `guest:<n>`, `bot:<botId>`, and later `user:<uid>`. A stable local identity is generated on first launch, and 0.3's anonymous auth **adopts** it rather than replacing it.
**Rationale:** Not asked directly; derived from [D53](#d53--local-persistence-format) and the requirement that early play not be wasted.
**Consequence:** Small now, unfixable later. Without it, every game and statistic accumulated in 0.1 and 0.2 is orphaned the moment accounts arrive.

### D55 — Bot difficulty presentation in 0.1
**Question:** 0.1 has no accounts and therefore no rating. How do the six opponents present their difficulty?
**Decision:** A named tier plus an indicative strength number, with the screen stating plainly that computer games are unrated practice for now.
**Rationale:** Sets honest expectations and lets the same UI carry live ratings from 0.3 without changing.
**Consequence:** The specification promises rated bot games ([D18](#d18--do-bot-games-affect-human-elo)); 0.1 cannot keep that promise and must say so rather than implying a rating system that does not exist.

### D56 — Test seams
**Question:** Where is the feature tested?
**Decision:** Three seams. **A:** the engine package's public API, under strict TDD, with win detection verified exhaustively rather than sampled. **B:** the game controller against an in-memory fake `GameRepository`, covering full user flows without widgets. **C:** a thin set of board golden tests across both layouts and both themes. Bots, the line table, and layout internals are tested *through* A and B, never directly.
**Rationale:** Tests assert external behaviour at module boundaries. A test that breaks on a refactor with no behaviour change is a defect in the test.
**Consequence:** Seam B's flow tests become the shared contract that both the local and the Firestore repository implementations must satisfy in 0.3.

### D57 — The scripted tutorial opponent is a bot configuration
**Question:** How is the tutorial's guided opponent built?
**Decision:** As an opponent configuration with a fixed seed, not a separate code path. Hints reuse the engine's threat detection.
**Rationale:** Not asked directly; derived from [D23](#d23--number-and-design-of-computer-players) and [D50](#d50--tutorial-depth-in-01).
**Consequence:** What the tutorial teaches is what the game actually rewards, because both read the same threat primitives.

### D58 — Application identity
**Question:** What is the application id?
**Decision:** A clearly marked placeholder, to be chosen before the first upload.
**Rationale:** No name decided yet, and the decision is not needed until upload.
**Consequence:** Recorded as a release gate, with the warning that **an application id is permanent once published and can never be changed**.

---

# Step 4 — Ticket breakdown

Decisions D59–D64. Produced the 22 files in [tickets/](tickets/).

### D59 — Ticket granularity
**Question:** How finely should release 0.1 be broken down?
**Decision:** 22 tickets, each a vertical slice sized to a single fresh context window.
**Rationale:** Each is demoable or verifiable on its own, roughly one to three evening sessions.
**Consequence:** After ticket 004 the graph fans out into four independent branches — persistence, the opponent ladder, the result screen, and the tutorial — so the path to upload is the longest branch rather than the sum.

### D60 — When the first store upload happens
**Question:** Should the first closed-test upload happen as early as possible, or wait for a more complete game?
**Decision:** **Wait.** The upload happens at ticket 016, after all six opponents, the result screen, the main screen, and history are in place.
**Rationale:** Testers get one first impression, and a build with one random opponent and no result screen spends it badly.
**Consequence:** This **reverses the position originally written into the spec**, which had decoupled the upload from 0.1 being complete specifically to start Google Play's fourteen-day clock sooner. The cost is real and unrecoverable: the clock starts later than it needed to. Accepted as a trade of schedule for first-impression quality. Reconciled in [D65](#d65--spec-reconciled-with-the-upload-timing-decision).

### D61 — Store accounts are separated from the upload
**Question:** Does deferring the upload also defer the store accounts?
**Decision:** No. Account creation is its own ticket, marked as having no blockers and startable on day one, despite being numbered 015.
**Rationale:** Not asked; derived. Apple enrolment verification takes days to weeks and has no code dependency whatsoever. Letting it inherit the upload's delay would compound [D60](#d60--when-the-first-store-upload-happens)'s cost for no benefit.
**Consequence:** Preserves most of what [D60](#d60--when-the-first-store-upload-happens) gave away.

### D62 — Localisation and accessibility are per-ticket criteria
**Question:** Dedicated tickets, or criteria carried by every ticket?
**Decision:** Plumbing lands in ticket 001; every subsequent ticket must add its own strings in both languages and its own screen-reader semantics. One final audit ticket sweeps for what slipped through.
**Rationale:** A retrofit sweep for either is expensive and error-prone; piece rendering that distinguishes players by colour alone is especially painful to unpick later.
**Consequence:** No localisation ticket exists. The audit ticket verifies cross-screen flows, which is precisely what per-ticket checks miss.

### D63 — Ticket scope
**Question:** Write tickets beyond release 0.1?
**Decision:** 0.1 only.
**Rationale:** Only 0.1 is specified in detail. Tickets for 0.3's backend would be guesses that go stale before they are reached.
**Consequence:** Later releases get their own breakdown after their own spec.

### D64 — Ticket storage and format
**Question:** Where do tickets live?
**Decision:** One markdown file per ticket in `doc/tickets/`, named with a three-digit number, a dash, and a short slug. Each file states what to build, what blocks it, and its acceptance criteria.
**Rationale:** Requested. No issue tracker is configured for this repository.
**Consequence:** Blocking edges are text rather than native tracker links, so renumbering means editing referenced files.

---

# Step 5 — Reconciliation

### D65 — Spec reconciled with the upload-timing decision
**Question:** [D60](#d60--when-the-first-store-upload-happens) contradicted §9.11 of the specification, which stated the opposite. Which wins?
**Decision:** The step 4 decision wins. §9.11 and §12.1 of [Idea-final-spec.md](Idea-final-spec.md) were rewritten to separate store account creation (day one) from the first upload (after the game is complete), and to record the schedule cost explicitly.
**Rationale:** Two planning documents disagreeing on a critical-path item reads as an oversight weeks later, when nobody remembers which was deliberate.
**Consequence:** Spec and tickets now agree. §12.1 also records the rule for next time: **if 0.1 grows again, protect the upload date rather than the feature list** — anything added after the main screen is complete can ship as 0.2 into the same testing track.

---

# Step 6 — Expert review

Decisions D66–D83. The specification and all 22 tickets were reviewed by three specialist reviewers — backend architecture, application security, and product management. Each was asked to raise clarifying questions before giving concerns; all eighteen questions were answered by the user and are recorded below. The reviewers' resulting concerns and recommendations are in [Idea-final-spec-review.md](history/Idea-final-spec-review.md).

**These eighteen were settled at the time. Several were then superseded by [Step 7](#step-7--private-early-releases-and-a-clean-start)** — read this section together with [§19](#19-review-findings-against-these-decisions), which records what survived.

The review document has since been updated: 27 of its 43 concerns are resolved and have been removed from it, leaving 16 open. Resolved findings are listed there in summary so the record survives without the detail.

## 16. Data shapes (backend review)

Every decision in this section changes a shape that release 0.1 writes to disk before any backend exists. All were adopted specifically because they are cheap now and expensive after 0.1 ships.

### D66 — Participant identity is a neutral uuid
**Question:** Firebase mints a uid the app does not control, so 0.3's anonymous auth "adopting" the 0.1 identity ([D54](#d54--participant-identity-scheme)) cannot mean the two are equal. What happens to the `local:<deviceId>` string baked into every participants array and per-opponent key?
**Decision:** 0.1 emits a neutral `player:<uuid>` for human seats. `user:<uid>` never appears in any document. The Firebase uid becomes a login credential mapped on the profile only.
**Rationale:** No document is ever rewritten, and the `local:` prefix stops being a lie the moment those games reach the cloud.
**Consequence:** Supersedes the identity scheme in [D54](#d54--participant-identity-scheme) and §8.2. The `guest:` and `bot:` tags are unaffected.

### D67 — Local history uploads once, then local storage is retired
**Question:** At 0.3, do offline games — including bot and pass-and-play games, which have no counterparty — go into Firestore?
**Decision:** A one-time opt-in upload of local history at 0.3, after which local storage is retired.
**Rationale:** The player chooses whether their offline history follows them. Avoids a permanent two-source repository.
**Consequence:** Creates a migration that must be resumable and idempotent — a half-finished upload must not duplicate or lose games. It also makes client-authored data cross the trust boundary, which is why [D73](#d73--imported-history-is-untrusted-input) exists.

### D68 — Games carry a queryable participant array from 0.1
**Question:** Firestore cannot filter or authorise on positional array indices, but the 0.1 game document has no queryable owner field. Should 0.1 write one anyway?
**Decision:** Yes. Top-level games with a `participantIds` array, written from 0.1 onward. Firestore rules will authorise with array-contains.
**Rationale:** Adding it later means backfilling every migrated document.
**Consequence:** One apparently redundant field in 0.1, in exchange for no backfill and no rule rewrite at 0.3.

### D69 — Moves carry an index and an id
**Question:** The 0.1 move record has no move number and no client-generated id, so any at-least-once retry over a network appends a duplicate.
**Decision:** Add both an explicit move index and a client-generated move id to the 0.1 shape now.
**Rationale:** The index makes ordering independent of clocks; the id makes a duplicate append detectable regardless of which write path 0.3 chooses.
**Consequence:** Changes §8.3 and ticket 005. The problem genuinely does not exist in offline 0.1 — this is paid entirely for 0.3's benefit.

### D70 — Ordering never depends on a clock
**Question:** Completed games are ordered most recent first using client-authored timestamps. A wrong or manipulated device clock misorders history and, later, rating-relevant sequencing.
**Decision:** Order by a monotonic sequence. Timestamps are display-only. 0.3 adds server timestamps alongside without converting anything.
**Rationale:** Removes the device clock from anything that determines an outcome or an order.
**Consequence:** Reinforced by [D75](#d75--move-validation-is-a-full-replay), which overwrites move timestamps server-side.

### D71 — Statistics are derived, not stored
**Question:** The profile stores totals and a per-opponent breakdown, duplicating what the games already contain — a second write that can silently drift.
**Decision:** Derive them at read time by folding the completed-games stream. The stored aggregate and the repository's record-result method are dropped.
**Rationale:** At a few hundred games of at most 64 moves, folding is free, and drift becomes impossible by construction rather than by discipline.
**Consequence:** Removes fields from §8.4 and simplifies §7.4 and ticket 013. Avoids turning a counter into a distributed-counter problem at 0.3.

## 17. Security and privacy (security review)

### D72 — Device identity is a random uuid; auto-backup stays on
**Question:** What is the device identity derived from, and does Android auto-backup — which is on by default — copy the identity and full game history to the user's Google Drive?
**Decision:** A random v4 UUID generated in-app, never a platform identifier. Auto-backup is **deliberately left on** so players do not lose history when they replace a device.
**Rationale:** A platform identifier such as ANDROID_ID is a persistent cross-app tracker and was rejected outright. Keeping backup on trades a disclosure obligation for genuine user benefit.
**Consequence:** Significant and easy to miss. Ticket 022 currently claims "no data leaves the device" — **that claim is now false and must be reworded.** Whether the Play Data Safety declaration must also change is genuinely uncertain, since platform backup to the user's own encrypted Drive is arguably outside its scope; this is recorded as a verify-before-submission item, not as a settled position.

### D73 — Imported history is untrusted input
**Question:** When local history is uploaded at 0.3, what proves the client owns that identity, and is the uploaded history trusted?
**Decision:** Every imported game is re-validated server-side, move by move, by the same function that validates live moves. Statistics are recomputed from validated games; client-supplied totals are never copied.
**Rationale:** The local JSON is entirely client-authored. Without this, a client could upload fabricated games and statistics that other players then see on a profile and head-to-head record inside a rated system.
**Consequence:** Makes [D67](#d67--local-history-uploads-once-then-local-storage-is-retired) safe. Import becomes a validation pipeline rather than a copy.

### D74 — Rated play is capped, not gated
**Question:** Firebase anonymous auth allows unlimited free accounts. Move-level validation proves each move was legal but says nothing about two accounts colluding.
**Decision:** Anonymous accounts may play rated, subject to per-account caps: new-account rate limits, capped rating gain per opponent pair, and no rating change for repeat matchups beyond a threshold per week.
**Rationale:** Requiring an upgraded account would add sign-in friction to the feature most likely to drive retention. Caps make farming not pay rather than making it impossible.
**Consequence:** Interacts with the day-7 auto-forfeit of [D16](#d16--abandonment-outcome), which would otherwise give collusion a fully automated form.

### D75 — Move validation is a full replay
**Question:** Does the validating function replay the whole game or trust the existing prefix?
**Decision:** Full replay from the empty board on every trigger. Move timestamps are overwritten with the server timestamp, participant and turn ownership are checked, and a failed validation rolls back and records an integrity event.
**Rationale:** A 64-move replay is trivially cheap. Trusting the prefix would let a modified client rewrite history, and client-set timestamps would let it manipulate the deadlines and clocks that decide outcomes.
**Consequence:** Sharpens [D34](#d34--rules-authority). Integrity events give visibility into attempted abuse rather than silently discarding it.

### D76 — Chat is written only by the server
**Question:** Profanity filtering is promised "before delivery", but the natural pattern — client writes, function cleans afterwards — lets the recipient read raw text before the function fires.
**Decision:** Clients cannot write to the messages collection at all. They call a function that filters and then writes, so unfiltered text never exists in a readable document.
**Rationale:** Removes the race rather than narrowing it.
**Consequence:** Costs a round trip per message and makes offline composition an explicit design problem. Sharpens [D32](#d32--safety-features).

### D77 — Deletion replaces the identity with a tombstone
**Question:** Account deletion promises "anonymised game records", but a record still keyed by the uid is pseudonymised, not anonymised — still personal data, so the erasure is incomplete under GDPR.
**Decision:** The identity is replaced with an opaque per-game tombstone token with no link back to the account.
**Rationale:** Opponents' rating histories stay coherent because only the rating delta is needed, not the identity. A hash with a held pepper was rejected: a key you hold is a key you can be compelled to use, so regulators treat it as pseudonymisation.
**Consequence:** Makes [D33](#d33--account-deletion) actually deliverable rather than merely stated.

## 18. Product (product review)

### D78 — 0.1 gets a progression loop
**Question:** What is a stranger's reason to open the app again on day 7, when ratings are null, bot games are unrated practice, and every designed return hook is in 0.3?
**Decision:** Add per-opponent milestones to the main screen — first win against each opponent, and beating Onyx — built from data already stored.
**Rationale:** One ticket, no new systems, gives the six-rung ladder a visible spine. A daily puzzle was rejected as a new feature with its own content burden; pulling online play into 0.1 was rejected as dragging the entire backend and compliance surface forward.
**Consequence:** Requires a new ticket and a change to ticket 013.

### D79 — The tutorial ships before the first upload
**Question:** The upload was delayed specifically to protect testers' first impression ([D60](#d60--when-the-first-store-upload-happens)), yet the entire tutorial is numbered after it and is not among its blockers.
**Decision:** Ticket 018, tutorial rules and controls, becomes a blocker of ticket 016. Strategy and the interactive practice game follow in later builds during the fourteen days.
**Rationale:** Otherwise the first twelve testers meet a 4×4×4 board with 76 winning lines and no onboarding, which contradicts both the reason for the delay and success criterion G2.
**Consequence:** One more ticket before the upload. Directly caught by review — the inconsistency was invisible in both documents.

### D80 — 0.1 success is measured against pre-committed thresholds
**Question:** With no analytics by design, what evidence tells you 0.1 worked? Every current criterion measures build completion, not user outcome, so the release cannot fail — and therefore cannot teach anything.
**Decision:** A structured tester survey with thresholds committed **before** the test runs, of the form "at least 8 of 12 finish the tutorial and beat Pebble unaided, at least 6 play a second session unprompted".
**Rationale:** Makes 0.1 falsifiable at no cost, before 0.2, 0.3 and 0.4 are built on top of it.
**Consequence:** Needs a new ticket. Also carries [D83](#d83--bot-difficulty-is-anchored-to-real-humans).

### D81 — 0.2 is compressed so online arrives sooner
**Question:** 0.2 adds fourteen bots, iOS and visual identity, none of which unlock new value, before the release containing the thing most of the roadmap's value depends on.
**Decision:** Compress 0.2 — ship iOS, defer the fourteen remaining bots until after 0.3.
**Rationale:** Reaches the highest-value release one increment earlier, while motivation is still available. The riskiest stretch of a solo hobby plan should not be spent on breadth.
**Consequence:** Changes the release ladder in §4.1.

### D82 — The competitive premise is validated before the board is designed
**Question:** The differentiation rests on the claim that existing Qubic apps render the cube too badly to see the diagonals, with no evidence cited anywhere.
**Decision:** Validate cheaply — read the one-star reviews of the leading Qubic apps before ticket 004 fixes the board design.
**Rationale:** An afternoon's work that either confirms the premise or reshapes the single most important screen in the game, at the only moment when reshaping it is free.
**Consequence:** Becomes a task blocking ticket 004.

### D83 — Bot difficulty is anchored to real humans
**Question:** Self-play proves relative ordering but says nothing about absolute human difficulty — whether Onyx really beats a competent human, or whether a dead zone exists between Ember and Basalt.
**Decision:** Anchor to humans using the closed testers, folded into the survey from [D80](#d80--01-success-is-measured-against-pre-committed-thresholds), and adjust the published indicative numbers before 0.3 freezes them into live ratings.
**Rationale:** The self-play harness in ticket 014 pins relative ordering; only humans can pin the absolute scale.
**Consequence:** Closes open item OI-03 with a concrete method and a deadline.

## 19. Review findings against these decisions

The reviewers examined D66–D83 and found several of them defective or incomplete. **These are recorded as open, not resolved.** The full findings are in [Idea-final-spec-review.md](history/Idea-final-spec-review.md); nothing there has been accepted.

| Decision | Status after review |
|---|---|
| [D66](#d66--participant-identity-is-a-neutral-uuid) + [D68](#d68--games-carry-a-queryable-participant-array-from-01) | **Contradictory.** Firestore rules only see `request.auth.uid`, so they cannot match it against an array of `player:<uuid>` without a billed profile read per rule evaluation. Proposed fix keeps both: a server-populated `memberUids` array added at 0.3 for rules and queries, with `participantIds` remaining the domain identity |
| [D67](#d67--local-history-uploads-once-then-local-storage-is-retired) | **Incomplete and dangerous.** Anonymous auth is not a durable credential, so retiring local storage makes 0.3 *less* durable than 0.1. The decline path is undefined. Proposed fix: delete local files only after per-game server acknowledgement and only once a durable credential exists |
| [D69](#d69--moves-carry-an-index-and-an-id) | **Partly redundant.** Under a transaction asserting `moves.size() == index`, the index is already the idempotency key; the separate move id earns its place only if 0.3 uses a callable with retries outside a transaction |
| [D70](#d70--ordering-never-depends-on-a-clock) | **Insufficient.** The sequence is per-move and says nothing about ordering games relative to each other; server timestamps stamped at import would collapse all imported history into one block |
| [D71](#d71--statistics-are-derived-not-stored) | **Creates an unbounded read.** Folding every completed game is free locally and a growing full-collection listener at 0.3. Proposed fix: paginate `completedGames()` and add a separate `stats()` stream now |
| [D72](#d72--device-identity-is-a-random-uuid-auto-backup-stays-on) | **Falsifies four shipped statements** — §2, §11.6 R5, ticket 016 and ticket 022. Also carries three consequences not previously seen: Firebase auth tokens would enter the backup at 0.3, a restore clones the player uuid onto two devices, and the ePrivacy position is weaker for cloud backup than for local storage |
| [D73](#d73--imported-history-is-untrusted-input) | **Does not achieve its goal.** Re-validation proves legality, not authenticity — a fabricated but legal game passes. Proposed fix: a server-set `origin` field with `rated` permanently false for imported games |
| [D74](#d74--rated-play-is-capped-not-gated) | **Has no stable subject and collides with the product.** Per-pair caps do nothing against throwaway accounts without App Check; and the repeat-matchup cap penalises the rematch loop that ticket 007 calls the app's cheapest retention mechanism |
| [D77](#d77--deletion-replaces-the-identity-with-a-tombstone) | **Misses three residues:** head-to-head pair aggregates, reports authored about the deleted user, and the Firebase Auth user record. The tombstone must also be randomly generated per game, not derived |
| [D79](#d79--the-tutorial-ships-before-the-first-upload) | **Cannot be satisfied as written** — no ticket owns the settings document, so "tutorial completion is remembered" has nothing to store it in and criterion T7 fails |
| [D80](#d80--01-success-is-measured-against-pre-committed-thresholds) | **One threshold is unobservable.** "Plays a second session unprompted" cannot be measured without analytics; proposed substitute is a tester-supplied screenshot of the statistics screen at day 3 and day 10 |
| [D81](#d81--02-is-compressed-so-online-arrives-sooner) | **Removes 0.2's only bounded work**, leaving "visual identity, polish" — no acceptance criteria, no definition of done — on the critical path. Also defers 14 rating anchors past the point where the scale freezes |

**Most of the above was resolved by [Step 7](#step-7--private-early-releases-and-a-clean-start), not by patching individual decisions.** D66, D67, D68, D69 and D73 are superseded outright; the contradiction between D66 and D68 cannot arise once no 0.1 document reaches Firestore. D70 survives only in its display-ordering half, D71 stands, and D72's surface shrinks because there is no longer a device identifier to back up. What Step 7 does **not** resolve, and which remains open: D74's caps having no stable subject and colliding with the rematch loop, D77's deletion residues, D80's unobservable threshold, D81's unbounded 0.2 scope, and the remaining Medium findings against the original documents.

### Correction to an earlier decision

[D58](#d58--application-identity) and §9.12 state that a lost keystore cannot be recovered. **That is half wrong.** With Play App Signing, mandatory for new applications, Google holds the app signing key and a lost *upload* key can be reset through support. The genuinely irreversible items are the application id and, once enrolled, the app signing key. The backup-and-verify requirement in gate R7 still stands — the reasoning behind it does not.

A third irreversible decision is missing from §9.12 entirely: **the Firestore database location**, fixed at creation, with Cloud Functions needing separate region pinning and Firebase Auth not region-pinnable at all.

---

# Step 7 — Private early releases and a clean start

Decisions D84–D91. Taken in response to the expert review. This is the single largest simplification in the project's planning, and it supersedes or reduces eight earlier decisions.

## 20. The change

### D84 — Releases 0.1 and 0.2 are not public
**Question:** Must the early releases be publicly available?
**Decision:** No. 0.1 and 0.2 are distributed only to friends and family, through Google Play **closed testing** on Android and TestFlight on iOS. Neither is promoted to production. The first public release is 0.3b.
**Rationale:** Nothing in 0.1 or 0.2 requires a stranger to find it. Closed testing is a real distribution channel with real installs, and it removes the public listing, discoverability, and public-facing privacy exposure from the early releases.
**Consequence:** Supersedes [D45](#d45--definition-of-first-success). See [D86](#d86--definition-of-first-success-replaced). Note the limit of this: Play still requires the Data Safety declaration, the content rating questionnaire, and the target-audience declaration **before publishing to any track, including closed testing** — so those obligations are not deferred, only the public listing is.

### D85 — 0.3 starts with a clean history
**Question:** Given 0.1 and 0.2 are private, must their local game history migrate into the cloud?
**Decision:** No. 0.3 starts with an empty database. There is no import path, ever. Local 0.1/0.2 games stay on the device and are never uploaded.
**Rationale:** The friends-and-family population is small and their offline history has no value worth the machinery. Import was the single largest source of complexity and risk in the entire plan.
**Consequence:** The largest simplification available. It closes eight review findings outright — see [§19](#19-review-findings-against-these-decisions). Supersedes [D67](#d67--local-history-uploads-once-then-local-storage-is-retired) and [D73](#d73--imported-history-is-untrusted-input) entirely, and removes the reason [D66](#d66--participant-identity-is-a-neutral-uuid), [D68](#d68--games-carry-a-queryable-participant-array-from-01) and [D69](#d69--moves-carry-an-index-and-an-id) existed.

### D86 — Definition of first success replaced
**Question:** [D45](#d45--definition-of-first-success) defined first success as "an app live in the App Store and Play Store". [D84](#d84--releases-01-and-02-are-not-public) abandons that. What replaces it?
**Decision:** First success is **twelve real people playing 0.1 on their own devices, and the release pipeline proven end to end** — signed builds, both stores' testing channels, and production access unlocked. Public availability moves to 0.3b and is no longer the first milestone.
**Rationale:** Leaving D45 in place unamended would leave the entire release strategy without a rationale. Strategy A was chosen in [D44](#d44--build-approach) specifically because it started the store clocks earliest; that argument has to be restated, not quietly dropped.
**Consequence:** The offline-first sequencing is retained on its own merits — no compliance surface early, no backend learning curve while learning Flutter, something playable soon — rather than on the store-clock argument.

### D87 — The 14-day clock is burned during 0.1
**Question:** Google Play requires personal accounts to run a closed test with twelve testers for fourteen continuous days before production access is granted. If nothing goes public until 0.3b, does that requirement simply move to 0.3?
**Decision:** No. The closed test runs during 0.1 with the twelve friends-and-family testers. The requirement is satisfied, and production access is unlocked, long before it is needed.
**Rationale:** Relocating the clock to 0.3b would place it on the hardest release, at the worst moment. Running it during 0.1 costs nothing extra — the testers are the distribution channel anyway.
**Consequence:** Preserves the one genuine benefit of [D60](#d60--when-the-first-store-upload-happens)'s original reasoning while removing its pressure. Whether an *internal* testing track would also satisfy the requirement is unverified and deliberately not relied on — closed testing is known to.

### D88 — 0.3 splits into a private and a public release
**Question:** [D84](#d84--releases-01-and-02-are-not-public) makes 0.3 both the first public release and the release that lands every unfamiliar technology at once — the "cliff" the review flagged as the most likely place the project stops.
**Decision:** Split it. **0.3a** is private: anonymous auth, a Firestore implementation of the repository that passes the identical flow tests as the local one, and one async game playable between two of the developer's own devices. No push, no rating, no functions. **0.3b** adds invite links, live rating, push, account deletion, the privacy policy, and is the **first public release**.
**Rationale:** Adopted because [D84](#d84--releases-01-and-02-are-not-public) made it necessary rather than merely advisable. Without it, the first public release is also the first release in an unfamiliar stack, with no prior public exposure to learn from. It is also the layer-proving step [D44](#d44--build-approach) claimed the plan had and never scheduled.
**Consequence:** Changes the release ladder. Reversible if the split proves unnecessary, but the reasoning for it strengthens rather than weakens under [D84](#d84--releases-01-and-02-are-not-public).

## 21. What the clean start simplifies

Every decision in this section removes work that existed solely to keep 0.1's data compatible with a cloud that will now never see it.

### D89 — Local storage is never retired
**Question:** With no import, what happens to local storage at 0.3?
**Decision:** Nothing. It stays. Offline games — against computer opponents and pass-and-play — remain local for the life of the app. Online games live in Firestore. The repository has two implementations serving two different kinds of game, not one replacing the other.
**Rationale:** There is nothing to migrate and nothing to retire.
**Consequence:** Supersedes [D67](#d67--local-history-uploads-once-then-local-storage-is-retired) and resolves the review's Critical durability finding: 0.3 can no longer be less durable than 0.1, because 0.1's data is never touched.

### D90 — 0.1 data shapes are simplified, not future-proofed
**Question:** [D66](#d66--participant-identity-is-a-neutral-uuid), [D68](#d68--games-carry-a-queryable-participant-array-from-01), [D69](#d69--moves-carry-an-index-and-an-id) and [D70](#d70--ordering-never-depends-on-a-clock) were adopted entirely to keep 0.1 documents usable in Firestore. That requirement is gone. Carry them anyway, or remove them?
**Decision:** Remove them. 0.1 stores the simplest correct thing:
- **No device identity at all.** There is no uuid to generate, store, claim or clone. A game records only its opponent.
- **No participants array and no participantIds.** A game has a seat that is the player and a named opponent — a computer opponent or the second pass-and-play seat.
- **Moves are a plain ordered list of cell indices.** Whose move it is derives from the position in the list and the recorded starting seat, so no per-move author, id, index or timestamp is stored.
- **No `rated` field.** Nothing in 0.1 or 0.2 is rated, and 0.3 starts clean.

0.3 designs its Firestore schema natively around `request.auth.uid` with no compatibility debt.
**Rationale:** These fields were bought entirely with forward-compatibility currency that no longer exists. Carrying them would be complexity paid for nothing.
**Consequence:** Supersedes [D54](#d54--participant-identity-scheme), [D66](#d66--participant-identity-is-a-neutral-uuid), [D68](#d68--games-carry-a-queryable-participant-array-from-01), [D69](#d69--moves-carry-an-index-and-an-id) and the forward-looking half of [D70](#d70--ordering-never-depends-on-a-clock). It also dissolves the review's other Critical finding — the identity-versus-rules contradiction cannot arise if no 0.1 document ever reaches Firestore. Removing the device uuid additionally shrinks the privacy surface of [D72](#d72--device-identity-is-a-random-uuid-auto-backup-stays-on): the backup now carries game history only, with no identifier in it.

### D91 — Settings own what the profile used to
**Question:** [D71](#d71--statistics-are-derived-not-stored) removed the stored statistics and [D90](#d90--01-data-shapes-are-simplified-not-future-proofed) removes the device identity, so the profile document has nothing left in it. But the review found that no ticket owns the settings document, which means tutorial completion has nowhere to be remembered and criterion T7 cannot pass.
**Decision:** Delete the profile document. Settings — locale, theme, tutorial completion — become the only local document besides games, and are owned by the same ticket that builds local storage. Statistics are derived from stored games at read time.
**Rationale:** Closes a real gap the review found, in the same place the change already lands.
**Consequence:** Also forces the fix for the tutorial practice game: since statistics are derived from stored games, the practice game must never be stored at all. It lives in memory for the tutorial's duration and never reaches the repository.

---

# Step 8 — Split ratings, the full roster, and a subscription

Decisions D92–D100. Taken in reaction to the expert review. Between them these resolve the awkwardness that had accumulated around ratings, close the review's anchor-freeze problem permanently, and give the project a business model it did not have.

## 22. Two ratings, not one

### D92 — A player has two separate ratings
**Question:** [D18](#d18--do-bot-games-affect-human-elo) made computer games affect a single human rating, which forced release 0.1 to present bot games as "unrated practice" with numbers that were not ratings ([D55](#d55--bot-difficulty-presentation-in-01)). Is one rating right?
**Decision:** No. A player has **two independent ratings**:
- a **computer rating**, earned against the twenty computer opponents, computed and stored entirely on the device, visible only on that device;
- a **human rating**, earned only against real opponents, server-authoritative, arriving with online play at 0.3b.

Neither influences the other. The same ELO maths and seed apply to both.
**Rationale:** They measure different things and have different trust models. A rating earned against a deterministic opponent on your own hardware cannot be verified by anyone and does not need to be; a rating earned against another person in a competitive ladder must be. Conflating them forced the worse property of each onto the other.
**Consequence:** Large and almost entirely simplifying. Supersedes [D18](#d18--do-bot-games-affect-human-elo), [D20](#d20--which-modes-are-rated) and [D55](#d55--bot-difficulty-presentation-in-01). Release 0.1 now has a **real, live rating from day one** instead of indicative numbers and an apology — which was the single most awkward thing in the plan. It also removes the reason the twenty opponent anchors were ever frozen against a live human scale.

### D93 — Computer play is entirely on-device, forever
**Question:** What part of a game against a computer opponent ever touches a server?
**Decision:** None of it. Move generation, validation, win detection, and rating computation all happen on the device. The computer rating never leaves the device and is never visible to anyone else.
**Rationale:** There is nothing to protect. A player who edits their own device rating has cheated only themselves, and no other player can see it or be affected by it. Server validation would be cost and complexity spent defending a number with no audience.
**Consequence:** Answers an open item the review raised — whether computer games sync — with a permanent no. Combined with [D85](#d85--03-starts-with-a-clean-history), it means the offline half of the product never touches the network at any point in its life. The computer rating is device-bound: it survives an Android backup restore but does not follow a player to a new platform, and the app should say so.

## 23. The full roster

### D94 — All twenty computer opponents ship in 0.1
**Question:** [D81](#d81--02-is-compressed-so-online-arrives-sooner) deferred fourteen of the twenty opponents until after online play, which the review then flagged as introducing fourteen fixed anchors into an already-live rating scale. Ship six or twenty?
**Decision:** All twenty, from release 0.1.
**Rationale:** Calibration is the reason. Twenty opponents calibrated together, against each other and against the closed testers, on one scale, before anything is published — rather than six now and fourteen later against frozen anchors.
**Consequence:** Supersedes [D81](#d81--02-is-compressed-so-online-arrives-sooner)'s bot deferral and deletes the 0.6 release entirely. It closes the review's anchor-freeze finding permanently rather than mitigating it, and [D92](#d92--a-player-has-two-separate-ratings) makes any later correction cheap anyway, since these anchors now govern a device-local rating.

**The honest cost:** this is a real scope increase to a release that was already growing. Most of it is cheap — opponents are configurations of one engine ([D23](#d23--number-and-design-of-computer-players)), so fourteen more is largely fourteen more catalogue entries. What is genuinely new engine work is the machinery the upper tiers need: threat-space search, a transposition table, iterative deepening, and exact endgame solving. That is two additional tickets of real work, not a data change.

### D95 — Quadrim Prime ships at fallback strength
**Question:** [D94](#d94--all-twenty-computer-opponents-ship-in-01) requires all twenty from the start, but Quadrim Prime is only perfect with the shipped strategy book, which [D24](#d24--how-the-perfect-bot-achieves-perfect-play) defers to 1.0 with unknown effort (OI-02).
**Decision:** Prime ships on rung 2 of §6.5's fallback ladder — exact endgame solving plus the deepest achievable search — described honestly as extremely strong rather than perfect. It is upgraded to true perfection when the solver lands at 1.0, and its rating is recalibrated then.
**Rationale:** Preserves the calibration goal without putting an unbounded research task ahead of anything playable. Recalibrating one anchor later is now cheap precisely because of [D92](#d92--a-player-has-two-separate-ratings) — it moves a device-local number, not a competitive ladder.
**Consequence:** Prime's advertised strength must match what it actually delivers until 1.0. The claim of perfection is not made until it is true.

## 24. The business model

### D96 — An annual subscription unlocks play against real opponents
**Question:** [D03](#d03--business-model) made the app free with no ads and no in-app purchases. Does that hold?
**Decision:** No. Everything offline stays free forever — all twenty opponents, the tutorial, pass-and-play, and the computer rating. **Playing against real opponents requires a subscription**, sold through the App Store and Google Play at a price per year.
**Rationale:** The free tier is a complete game, and the paid tier is the part that costs money to run. The line is explicable in one sentence, which is the main thing a paywall has to be.
**Consequence:** Supersedes [D03](#d03--business-model) and removes "no ads or in-app purchases" from the permanent non-goals. Brings real work at 0.3b: store product configuration, billing integration, entitlement checks, receipt validation, restore-purchases, and tax and payout setup — which makes the developer-identity question of OI-07 urgent rather than eventual.

**An unplanned security benefit.** The review's strongest unresolved abuse finding was that per-account rate limits have no stable subject, because anonymous accounts are free and unlimited. They are no longer free: rated human play now costs a yearly subscription per account. That does not eliminate collusion between two paying players, but it removes the cheap sybil attack entirely and makes OI-08 a much smaller problem.

### D97 — Two subscription products
**Question:** Auto-renewing, or a fixed term?
**Decision:** Both. An auto-renewing annual subscription, and a non-renewing one-year purchase for players who do not want a recurring charge.
**Rationale:** Requested. Both stores support the pair natively.
**Consequence:** Two products to configure and two entitlement paths to test, including the case where a player holds both.

### D98 — A lapsed subscription finishes what it started
**Question:** What happens when a subscription expires mid-season?
**Decision:** Games already in progress can be played to their end. No new online games can be started. The human rating is frozen and retained, and resumes where it left off if the player resubscribes.
**Rationale:** Nobody should lose a game they were winning because a card expired, and the opponent should not be handed a forfeit win by someone else's billing. Freezing rather than resetting the rating means resubscribing is a resumption, not a restart.
**Consequence:** Entitlement is checked at game *creation*, not on every move. Interacts with [D16](#d16--abandonment-outcome)'s day-7 forfeit: a lapsed player must still be able to move in an existing game, or the paywall would silently cause forfeits.

## 25. Chat control

### D99 — Chat availability is a player preference with a per-game override
**Question:** [D31](#d31--chat-scope) gives every shared game a chat channel. Is that always wanted?
**Decision:** No. A setting offers three values — chat in **every game**, **friends only**, or **never** — and the choice can be changed for one specific game in the start-a-game flow.
**Rationale:** Requested, and it directly addresses a review finding: because chat permission derives from game membership, creating a game was implicitly opening a channel to a stranger. Now it is not.
**Consequence:** Chat availability is decided at game creation and recorded on the game rather than derived at message time. The default should be **friends only** — the setting is worth little if the permissive value is the one nobody changes.

### D100 — The more restrictive preference wins
**Question:** Two players in one game have conflicting preferences. Whose applies?
**Decision:** The more restrictive. Chat exists for a game only if **both** players allow it for that game.
**Rationale:** Makes "never" actually mean never. Any other rule lets a stranger place someone in a conversation they opted out of.
**Consequence:** The start-a-game flow must show whether chat will be available for this game, and why not when it will not be — otherwise the setting is invisible and reads as a bug.

---

# Step 9 — Second expert review

Decisions D101–D118. A coverage check of [Idea-final.md](Idea-final.md) against the spec and tickets found four gaps, and a second review by the same three specialists produced five Critical findings. The result is the largest change to the release ladder since staging was adopted: **0.3b becomes free online play, and 0.4 becomes the competitive paid product.**

## 26. Gaps found by the coverage check

### D101 — Placeholder art in 0.1, real art in 0.2
**Question:** Tickets require twenty opponent avatars and an app icon; no ticket produced them.
**Decision:** A ticket produces placeholder avatars and a plain icon for 0.1. Real art becomes explicit scope in 0.2, named with a count and a make-or-commission decision.
**Consequence:** 0.2's row grows again, immediately before the release most likely to stall. The twenty personality blurbs in two languages get the same owner.

### D102 — A settings screen ships in 0.1
**Question:** [D91](#d91--settings-own-what-the-profile-used-to) created a settings document holding `locale` and `theme`, but nothing could write them.
**Decision:** A small settings screen ships in 0.1 — language override, theme override, restart tutorial.
**Rationale:** Without a language override a Dutch tester on an English-locale phone cannot see the Dutch build at all, and half the closed test is in Dutch.
**Consequence:** New ticket, and a blocker of the first upload.

### D103 — Draw offers are removed from the product entirely
**Question:** Idea-final.md gave both players a right to offer a draw; the spec deferred it as meaningless offline.
**Decision:** Removed everywhere. Games end by four-in-a-row, a full board, resignation, or timeout.
**Rationale:** A negotiated draw is a two-party state machine touching move history, clocks and rating, for a case players can resolve by resigning.
**Consequence:** Supersedes [D12](#d12--draw-condition) in part and [D13](#d13--available-in-game-actions). Removes work from every online mode, not just 0.1. `result.outcome` still needs a **timeout** value, which it did not have.

## 27. The ladder redrawn

The three reviewers independently converged on one shape. Security found the human rating unsafe at 0.3b; product found the subscription meaningless at 0.3b; both found that Cloud Functions exist at 0.3b regardless, so the reasoning behind deferring validation was mispriced.

### D104 — The human rating moves to 0.4
**Question:** Should a live, server-authoritative human rating ship with the first public release?
**Decision:** No. It moves to 0.4, together with the validation that makes it trustworthy. 0.3b ships online play with a win/loss/draw record and no ELO.
**Rationale:** Three Critical findings, deleted rather than mitigated. Replay proves legality, not authorship — a modified client authoring *both* players' moves produces a game that is legal, replays cleanly, and reproduces a fabricated result exactly, which "recompute later" can never detect. Worse, a fabricated game moves a *victim's* rating without them ever opening the app: a refund event, and a GDPR accuracy and rectification problem over data attributed to an identified person. The rating's only functional consumer, auto-match, is already at 0.4, and [D03's successor](#d96--an-annual-subscription-unlocks-play-against-real-opponents) permanently forbids leaderboards and tournaments, so nothing else needs it earlier.
**Consequence:** Nobody has a rating to lose at the first public release, because nobody has one. Supersedes the 0.3b half of [D92](#d92--a-player-has-two-separate-ratings) — the split itself stands, only its timing moves.

### D105 — Move validation travels with the rating
**Question:** [OI-10 re-taken.](#d104--the-human-rating-moves-to-04) Deferring server-side validation was justified as keeping a second language off 0.3b's critical path.
**Decision:** Validation lands at 0.4, with the rating. The justification is corrected: it was never about the language.
**Rationale:** Both reviewers found independently that 0.3b ships Cloud Functions regardless — push on opponent move, the scheduled 5-day and 7-day sweep, head-to-head aggregates, and later receipt validation. What deferral actually saves is the shared 76-line table in TypeScript and the corpus wiring. Validation now sits with the rating because that is the only thing it protects, not because it is expensive.
**Consequence:** Retires OI-10. `functions/` is created at 0.3b for other reasons; the validator is added to it at 0.4.

### D106 — The subscription moves to 0.4
**Question:** Should the subscription gate the first public release?
**Decision:** No. It moves to 0.4.
**Rationale:** At 0.3b the paid tier sells access to a population of zero. It is not a cold-start problem but a two-sided market where **both sides must pay to enter**, which forecloses every standard remedy. The plan already conceded it and mislabelled it: [Idea-final.md §7.6](Idea-final.md) has auto-match fall back to a computer opponent, which is the paid feature degrading into the free one. Both stores also expect a subscription's content to be available at purchase.
**Consequence:** Supersedes the timing in [D96](#d96--an-annual-subscription-unlocks-play-against-real-opponents). 0.4 is where friends, open challenges, auto-match and chat exist — the first moment there is something to sell.

### D107 — Free to accept, paid to initiate
**Question:** Should all human play be paid, or only part of it?
**Decision:** Accepting an invite or a direct challenge is **free forever**, with a cap of a few concurrent human games. The subscription buys initiation and discovery: creating invites, auto-match, the open challenge board, chat, and the full 20-game cap.
**Rationale:** Invite links are the only acquisition channel in the entire roadmap. Taxing them means a friend's invitation arrives as a sales pitch, and conversion at that moment is near zero. This keeps [D96](#d96--an-annual-subscription-unlocks-play-against-real-opponents)'s anti-abuse benefit almost intact, because auto-match and the open challenge board — the surfaces a throwaway account would farm — stay paid.
**Consequence:** Supersedes [D96](#d96--an-annual-subscription-unlocks-play-against-real-opponents)'s "all play against real opponents". Adds a user story: a player invited by a friend can accept and play without paying.

### D108 — Three products and a free trial
**Question:** Two annual products, no trial, no price.
**Decision:** Auto-renewing annual, auto-renewing monthly, and a non-renewing year, with a store-native free trial on the annual. **The price remains an explicit open decision before 0.4.**
**Consequence:** Supersedes [D97](#d97--two-subscription-products). The price is now a named open item rather than an omission.

### D109 — Block, report and name validation move to 0.3b
**Question:** These sat with chat at 0.4.
**Decision:** They move to 0.3b. Free-text chat, chat preferences and profanity filtering stay at 0.4.
**Rationale:** They are contact-surface features, not chat features, and 0.3b is what opens the contact surface — invites, profiles, push, and user-chosen display names visible to strangers. [D107](#d107--free-to-accept-paid-to-initiate) makes human play free there, so there are more accounts, not fewer. Both stores expect blocking and reporting wherever users can reach each other.
**Consequence:** The block check belongs in the **game-creation and invite-acceptance path**, not only the message path — which is where the first review located it and where it never landed.

### D110 — Linking is required before the first rated game or purchase
**Question:** Accounts are anonymous from 0.3a. Is that enough to hold a rating or a subscription?
**Decision:** No. Anonymous is fine for trying online play at 0.3b. Before the first rated game or any purchase, the account must be linked to Google, Apple or email.
**Rationale:** An anonymous account vanishes with the device — taking a paid year and a rating with it, with no support path. It also makes a GDPR data-subject request unverifiable: there is no way to establish that the person asking is the person whose data it is.
**Consequence:** Offering third-party sign-in on iOS requires Sign in with Apple alongside. In-app deletion must also state that it does not cancel the store subscription — a common review rejection.

### D111 — The free-forever promise is scoped to release 0.1's feature set
**Question:** "No paywall on anything offline" was a permanent non-goal written under the old free-with-no-purchases model, and [D96](#d96--an-annual-subscription-unlocks-play-against-real-opponents) reversed that model without revisiting the list.
**Decision:** Replace it with: everything release 0.1 shipped — twenty opponents, the tutorial, pass-and-play, local history and statistics, and the computer rating — is free forever.
**Rationale:** Keeps the promise actually made to the people who install the free game, and stops permanently foreclosing a future offline feature that has not been invented yet. No ads, no consumables, no cosmetics and no pay-to-win stay as written.
**Consequence:** The non-goals list was re-derived under [D96](#d96--an-annual-subscription-unlocks-play-against-real-opponents) rather than inherited from [D03](#d03--business-model).

### D112 — All twenty opponents ship in the first uploaded build
**Question:** Ticket 011 depends on the Master tier and ticket 016 depends on 011, so the first build twelve people ever see is gated behind transposition tables, 8-ply search and exact endgame solving. Both reviewers recommended shipping the first three tiers and adding the rest as updates.
**Decision:** **Recommendation declined.** All twenty ship in the first uploaded build.
**Rationale:** The user's call, made with the cost stated.
**Consequence, recorded plainly:** the first upload waits for the hardest engine work in the project, and the fourteen-day Play clock starts correspondingly later — the clock that [D87](#d87--the-14-day-clock-is-burned-during-01) exists to start early. This is the one place where the plan knowingly departs from §12.1's rule to protect the date twelve people first play.

## 28. Fixes adopted without a question

Taken directly from the reviews because they are corrections, not choices.

### D113 — Friendship is mutual and accepted
Adding someone is a request; friendship exists only once accepted. Unfriending revokes immediately, a block removes it, friend requests carry **no free text** and are rate-limited, and display-name lookup is exact-match only. Without this, `friendsOnly` — the default chat setting adopted to close the first review's unsolicited-contact finding — is defeated by the attacker's own action, because anyone who adds you becomes a friend.

### D114 — Chat availability is resolved at acceptance and stays revocable
Three of the four matchmaking paths have no start-a-game flow for the joiner, so combining both preferences at *creation* is unimplementable. Availability is resolved when the game is **accepted**, giving the joiner the same override. Either player can revoke it later, switching the global preference to `never` clears it across active games, and blocking terminates it immediately. An absent field means chat unavailable, so games created before 0.4 fail closed.

### D115 — Determinism uses node budgets, not wall-clock
Acceptance criterion E7 requires identical state and seed to produce identical moves. A millisecond budget makes every Expert and Master opponent non-deterministic across devices and between CI and a phone. All search budgets are expressed in **nodes**; the wall-clock equivalent is measured and recorded separately against a **named reference device**, which is also the device the responsiveness criteria are judged on.

### D116 — The computer-rating fold records its anchor and its ordering key
The fold is only reproducible if each completed game stores the opponent's anchor rating at the time it was played, and if "chronological" names a field. Games store `opponentRating`, and the fold orders by completion time with the game id as tie-break. Without the first, recalibrating any anchor silently rewrites every player's entire history and the "+12" they saw becomes unreproducible; without the second, a long-running game reorders the fold when it finally completes.

### D117 — Firestore security rules are a tested deliverable
With validation at 0.4, the rules are the entire trust boundary of the first public release. They get their own ticket at 0.3a and an adversarial emulator suite in CI where every test is an attempt that must be **denied**: write another player's game, overwrite an existing id, write a result, write an entitlement, append two moves at once, move out of turn, exceed the game cap. This is a fourth test seam.

### D118 — Security and privacy acceptance criteria exist as a section
The spec has criteria for the engine, game flow, interface, tutorial, data and release gates, and none for security or privacy — so every invariant above is a paragraph with no test behind it. A section is created now, seeded with what 0.1 can already assert, so 0.3's criteria are not invented under deadline pressure.

Also adopted without a question, as corrections: a field-level client write allowlist rather than a document-level one; invite codes with entropy, expiry, single-use and a block check; the export path shipping alongside deletion; a tester privacy notice for the closed test; the repository loading games once so the main screen's four derivations share one read; deletion of the `bots` Firestore collection, which contradicts device-only computer play; and a public store-listing ticket for 0.3b with the app name's availability checked.

---

# Step 10 — The published literature

Decisions D119–D121. The user found the Wikipedia entry for 3D tic-tac-toe. The plan already knew the game was solved; what it did not have were the **numbers**, and those change one of the largest risk items in the project.

## 29. What the sources actually say

### D119 — The perfect-play strategy is published work, not original research
**Question:** [D24](#d24--how-the-perfect-bot-achieves-perfect-play) planned a build-time solver to compute the proven winning strategy, and OI-02 has carried "unknown effort, unknown asset size" ever since.
**Decision:** The strategy is treated as **existing literature to be obtained and verified**, not computed. OI-02 becomes a bounded acquire-verify-licence task with proof-number search as the documented fallback.
**Rationale:** The game was weakly solved by Mahalko in 1976, given a complete first-player-win strategy by Patashnik in 1980 via a computer-assisted proof costing around 1,500 hours, and solved independently again by Allis using proof-number search. Three numbers matter: the strategy is roughly **2,929 stored positions**, everything else is reachable by **forcing moves** — which is the threat-space search the Club tier already builds — and the positions were reportedly published online.
**Consequence:** The asset is kilobytes, not an unknown. The 1.0 work shifts from original computation to verification. Two caveats stop this being a free win: the strategy covers the **first player only**, so Prime moving second still defends by search; and Wikipedia reporting that data was made available online is not confirmation that it is obtainable and redistributable today. [D95](#d95--quadrim-prime-ships-at-fallback-strength) therefore stands unchanged — Prime ships on rung 2 until verification succeeds, because unverified data is not a proof.

### D120 — Cell degree becomes a generated constant
**Question:** The positional rules ([D23](#d23--number-and-design-of-computer-players), §6.3) prefer the central 2×2×2 and then corners, on the strength of play experience.
**Decision:** Emit **cell degree** from the same generator as the line table: the 8 corners and 8 inner cells lie on **7** winning lines each; the other 48 lie on **4**.
**Rationale:** It turns folk wisdom into a measurable fact, and it is a free correctness check — if the generated degrees disagree with the literature, the line table is wrong.
**Consequence:** Two things follow. The heuristic becomes "prefer high-degree cells", which is what the hand-written ladder was approximating. And corners and inner cells are **the same class** under the board's symmetries, so ranking centre strictly above corners is a distinction the game does not make — it stays in the ladder as a *flavour* axis for opponent personalities, not a strength one.

### D121 — Positions are canonicalised under the 192 automorphisms
**Question:** The Expert tier needs a transposition table that fits on a phone, and any stored strategy needs to be small.
**Decision:** Canonicalise a position to a representative of its symmetry class before caching or looking it up. The group has **192** automorphisms (Silver, 1967) — the familiar rotations and reflections plus two operations that reorder cells along every line at once.
**Rationale:** Collapsing up to 192 equivalent positions into one entry is the difference between a table that fits and one that does not, and it shrinks the strategy book by the same factor.
**Consequence:** A new engine export and a correctness obligation — positions related by a symmetry must produce the same canonical form. It also means the opening is far smaller than it looks: an empty board has only **two** genuinely distinct first moves, a 7-line cell or a 4-line cell.

**Recorded for care rather than as a decision:** **Qubic** was a Parker Brothers trade name. This product is Quadrim; the older name is used descriptively in the documents and must never appear as branding.

---

# Step 11 — First-run experience design review

Decisions D122–D128. A first-run experience was designed in Claude Design and delivered as [design.md](design.md), a prototype in `design_reference/`, and the Nocturne design system in `design_system/`. It was reviewed against the specification and tickets. The reconciled result is [FirstRunHandoff.md](FirstRunHandoff.md).

## 30. Reconciling design with spec

### D122 — The specification's roster wins
**Question:** The prototype invents twenty opponents — Pip, Dott, Cubby, Fenn, Loop, Nook, Vex, Marlo, Suri, Halden, Quill, Ravel, Denz, Astra, Korr, Vantage, Ilex, Zephyrine, Oberon, Meridian — rated 620 to 2400. The specification's roster is Pebble through Quadrim Prime, rated 600 to 2600. Which is authoritative?
**Decision:** The specification's roster. The design adopts it.
**Rationale:** The roster is load-bearing well beyond the picker screen: [Idea-final.md](Idea-final.md) §6.4 defines it, ticket 011 renders it, tickets 006 through 026 build to it, and ticket 014's calibration chain is about to measure those exact ratings. Renaming twenty opponents to match a prototype would ripple through eight tickets and re-anchor a scale that is nearly ready to be measured.
**Consequence:** The prototype's names are a mock, not a proposal. Any string extracted from it must be checked against §6.4 rather than copied.

### D123 — Five tiers, not three categories
**Question:** The picker groups opponents into Easy, Medium and Hard. The specification has five tiers — Novice, Casual, Club, Expert, Master.
**Decision:** Five tiers.
**Rationale:** Twenty opponents in three groups is roughly seven per accordion, which is a long scroll inside each and flattens the sense of a ladder. Five tiers averages four, so each group is scannable and the rungs are visible. Ticket 011 already requires grouping by tier.
**Consequence:** The picker's accordion count changes from three to five. Tier labels are translated; opponent names are not.

### D124 — Lightness satisfies the non-hue requirement
**Question:** The design distinguishes pieces by lightness — a white pebble against a black one. The specification said pieces must be distinguished by **shape** as well as colour.
**Decision:** Lightness satisfies it. The specification's wording is relaxed: pieces must be distinguishable without relying on hue; shape is an acceptable alternative, not a requirement.
**Rationale:** The original rule existed to prevent hue-only encoding, which is the failure mode that excludes red-green colour vision deficiency. A light piece against a dark one does not merely avoid that failure — it is the strongest available signal, and it survives full achromatopsia, which two similarly-toned shapes would not. The rule was guarding against a problem this design already solves better.
**Consequence:** [Idea-final.md](Idea-final.md) §7.10 and [Idea-final-spec.md](Idea-final-spec.md) §4.2 reworded. The pebble treatment is kept, which also preserves the most characterful thing in the design. Ticket 021's audit criterion still applies — it must be verified under simulation, not assumed.

### D125 — First-run scope is the four screens plus the missing end state
**Question:** The design covers tutorial, main screen, opponent picker and match. Several things release 0.1 requires are absent. How much does the handoff cover?
**Decision:** The four designed screens, **plus the result screen**, which is added because a match with no win or lose state is not a finishable first run. Everything else absent is named as designed-but-deferred rather than left silent.
**Rationale:** The result screen is not a nice-to-have: ticket 007 requires the winning line highlighted, the rating delta shown, and a one-tap rematch. Without it the flow has no terminal state at all — the design tool's own suggested next step was to add win/lose detection to the match screen.
**Consequence:** Explicitly deferred to a later design pass, and listed as such: the move-history scrubber (ticket 012), the settings screen (ticket 028), pass-and-play entry (spec §4), per-opponent statistics and milestones (tickets 013, 023), the large-screen landscape layout (ticket 017), and a light theme (§7.10).

## 31. Defects found in the delivered design

### D126 — The prototype was missing one file, and now runs
**Question:** [DesignHandoff.md](DesignHandoff.md) states the prototype can be opened directly in a browser. The delivered copy rendered as literal `{{ … }}` placeholders. Why, and is it recoverable?

**Diagnosis, corrected twice.** The first reading — that `_ds_bundle.js` was an empty stub — was **wrong**. A fresh project download produced a byte-identical 300-byte bundle, so that file is simply empty by design: this prototype uses raw Nocturne tokens and inline logic rather than registered design-system components.

The actual cause was a single missing file. The design's whole content is inline — 16,695 bytes of `type="text/x-dc"` script carrying the board logic and all copy in both languages — and a browser will not execute that MIME type. The runtime that evaluates it, `support.js` (69 KB), was never copied into the repo. There are no CDN references and no external framework, so this was a packaging fault, not a network one.

**Decision:** Restored. `support.js` and the `_ds/nocturne-6bb5054c-7621-445d-889f-56706a347aa4/` asset directory now sit in `design_reference/` at the paths the HTML expects. The download also contained a **1.3 MB fully self-contained standalone HTML**, which is now the reference of record — it has zero external references and opens anywhere.

**Consequence:** The flow was walked end to end in a browser and **every source-based finding was confirmed visually**: all twenty prototype names present with none from the specification, Easy/Medium/Hard with none of the five tiers, "Unrated" on the main screen, and a five-step tutorial under a six-segment progress bar.

Three findings that only a running prototype could produce, now in the handoff: both the welcome step and the picker leave roughly half the screen empty above a bottom-pinned button; the tutorial's hint is static scripted text rather than computed from the position, which ticket 020 forbids; and "Start match" is enabled before an opponent is chosen.

**The lesson worth keeping:** the review's conclusions did not move, but three real defects were invisible until it ran. A prototype that cannot be executed is worth materially less than one that can, and "read the source instead" is not an equivalent substitute.

### D127 — The board's geometry must be re-derived from the touch target, not the other way round
**Question:** The design specifies a board 170 px wide holding four columns, each layer transformed by `rotateX(42deg)`.
**Decision:** The board's dimensions are a **derived** value in the handoff, not a fixed one. The constraint is the minimum touch target; the geometry follows from it.
**Rationale:** Four columns in 170 px is roughly 41 px before transformation, and a 42-degree rotation compresses the vertical axis to around 70 percent of that. The effective target lands near 29 px — comfortably below the platform minimum, on the smallest supported phone, for the single most-used control in the game.
**Consequence:** Either the board grows, the perspective angle softens, or the cells stop being square. This is structural rather than a tweak, and it is the one finding that could invalidate the layout. Acceptance criterion U4 and ticket 021 both already require the check.

### D128 — The rating on the main screen is live, not "Unrated"
**Question:** The design shows a rating tag reading "Unrated".
**Decision:** Wrong model. The main screen shows a live computer rating, seeded at 1200 and moving after every game against a computer opponent.
**Rationale:** "Unrated practice" was the pre-[D92](#d92--a-player-has-two-separate-ratings) position, superseded when ratings were split in two. The design was built against a specification snapshot that predates it.
**Consequence:** The tag becomes a value, and the result screen shows its delta (ticket 027). It must be labelled so it cannot be mistaken for the human rating arriving at 0.3b.

### D129 — Tier names carry a plain-language description
**Question:** [D123](#d123--five-tiers-not-three-categories) replaced the design's three categories with the specification's five tiers. The design's categories carried descriptions — "Makes mistakes on purpose", "Plays solid lines, punishes blunders", "Sees deep into the cube". Do those survive the replacement?
**Decision:** Yes. Each of the five tiers gets a one-line description in that voice. The tier name alone is not enough.
**Rationale:** Seen rendered, the descriptions do more work than the labels. "Novice" and "Casual" are internal vocabulary that tells a player nothing about how an opponent behaves; "makes mistakes on purpose" tells them exactly what to expect. Discarding the copy along with the three-way grouping would have been a real loss — and it was only obvious once the screen was running.
**Consequence:** Ten new strings, five descriptions in two languages, added to ticket 029's content scope. Tier rating ranges must also be **derived from the roster** rather than written by hand: the design's bands left 900–1100 and 1600–1800 uncovered, and the roster has opponents at 1000, 1650 and 1700.

---

# Step 12 — Implementation

Decisions taken while writing code, one batch per ticket. Routine choices (library versions, file layout already fixed by the spec) are not recorded; only what a future reader would otherwise have to reverse-engineer.

## 32. Ticket 001 — skeleton and CI

### D130 — Toolchain: Flutter 3.44.9 stable at C:\D\flutter
Flutter was not installed. Installed 3.44.9 stable (Dart 3.12.2) to `C:\D\flutter`, wired to the existing Android SDK at `%LOCALAPPDATA%\Android\Sdk`, cmdline-tools added, licenses accepted, `flutter doctor` fully green. Not on the system PATH — build scripts and CI set their own.

### D131 — Local storage lives under `files/quadrim/`
The backup allowlist (D72, spec §9.12) needs a concrete path to include, so the contract is fixed now: **everything ticket 005 persists goes under the `quadrim/` subdirectory of the app's files directory.** Both cloud backup and device-to-device transfer include exactly that path and nothing else — the allowlist-not-default rule exists so that 0.3a's Firebase auth material is excluded by construction rather than by remembering.

### D132 — The hardcoded-string check is a grep, not an analyzer plugin
Ticket 001 wants the build to fail when a user-facing literal appears. Implemented as a grep for `Text('…')` literals in `app/lib` (excluding generated l10n) inside `tool/check.sh`. A custom analyzer rule would catch more shapes; the grep catches the shape people actually write, costs nothing, and lives in the same script CI runs. Upgrade if it ever misses something that mattered.

### D133 — The light theme exists but is a seed derivation
Nocturne is dark-only (FirstRunHandoff §3). The light theme is generated from the same accent seed so `ThemeMode.system` works and nothing hardcodes darkness; it gets real design attention no later than ticket 021's audit. Recorded so nobody mistakes it for a designed artefact.

### D134 — CI is GitHub Actions running the same script as local
The repo already lives on GitHub. One workflow, one step: `bash tool/check.sh` — identical to the local gate, so CI cannot drift from what a developer runs. The APK build is deliberately not in CI (slow, and the analyze+test gate is what the ticket demands); it is verified locally per ticket.

## 33. Ticket 004 — the playable board

### D135 — Board geometry: 2×2 sheared layers, WCAG-AA cell sizing
**Question:** [D127](#d127--the-boards-geometry-must-be-re-derived-from-the-touch-target-not-the-other-way-round) demanded geometry derived from the touch target, with 44dp as the working minimum. Implementation proved that **44dp is geometrically impossible** for 64 always-visible cells on a phone: a 2×2 layer arrangement at 390dp width yields at most ~42dp even with zero decoration, and a single-column stack exceeds screen height.
**Decision:** The board is four 4×4 grids in a 2×2 arrangement. Depth comes from a **horizontal shear** (0.15), not a perspective rotation — shear leaves cell height untouched, so the rendered hit area equals the cell. Cell size derives from available width: ~37dp on a 390dp phone, ~34dp on 360dp, capped at 48dp on wide screens. The audited floor is **32dp**, justified by WCAG 2.5.8 AA, which permits dense adjacent-target grids at ≥24dp with spacing — the regime keyboards and calendar grids live in. A widget test pins the reference-device size and the floor.
**Rationale:** 44dp is the iOS-HIG/AAA bar for isolated controls; holding the whole product to it here would force scrolling (breaking U1) or a rotatable board (a permanent non-goal). The tests, not judgement, established the impossibility.
**Consequence:** Acceptance criterion U4's "platform minimum" reads as WCAG AA for board cells specifically. Flagged to ticket 021's real-device audit, and the closed-test survey already asks about hesitation and mis-taps — that is the empirical check on this decision. The shear also produced one real bug the widget tests caught: without reserving the shear width inside each layer's layout, sheared rows overlapped the neighbouring layer and stole its taps.

**Supported width floor.** The floor only holds down to **360dp**, which is therefore the narrowest supported screen; below roughly 340dp cells fall under 32dp. Pinned by widget tests at 360, 390 and 412dp, plus one asserting the whole board fits without scrolling at the narrowest. Sub-360dp devices are a recorded limitation for ticket 021, not a silent degradation — the review caught that an earlier comment claimed a guarantee the code did not provide.

### D136 — Screen-reader announcements via a live region, not explicit calls
The turn banner is a Semantics live region: every text change (turn, win, draw) is announced automatically. The explicit `SemanticsService.announce` API is deprecated in current Flutter and would have duplicated the live region anyway. Each board cell is its own semantics container so an occupied cell's label never merges into its layer's.

### D137 — The four layers stack in one column against the right edge, not a 2×2 grid
**Question:** [D135](#d135--board-geometry-2×2-sheared-layers-wcag-aa-cell-sizing) arranged the four layers as a 2×2 grid, on the reasoning that "a single-column stack exceeds screen height". Seeing it running, the user asked for the four boards beneath each other on the right of the screen instead.

**Decision:** One column, layers 1–4 top to bottom, aligned to the **right** edge. The left of the screen is deliberately left free.

**Rationale:** D135's rejection of the single column was measured against the **44dp** target it had just abandoned. Sixteen cell rows at 44dp need 824dp of board height, which no phone has. At the 32dp floor D135 itself adopted, the stack needs 632dp — which fits comfortably. The claim was true of the requirement it was written under and false of the requirement that survived it; it should have been re-derived when the floor moved. Measured, the column gives cells of roughly the same size as the 2×2 grid did (~42dp at 412×915, ~35dp at 390×844), so nothing was paid for the change.

**Consequence:**
- Cell size is now derived from **both** axes and the smaller wins; screen **height** is normally the binding constraint, where it was width before. `boardWidthForCell` and `clampBoardWidth` were deleted — the board sizes itself from its constraints, so no caller needs to compute a width for it.
- A second supported-device bound exists: `kMinSupportedHeight` = 760dp, alongside `kMinSupportedWidth` = 360dp. Below either, cells fall under the [D135](#d135--board-geometry-2×2-sheared-layers-wcag-aa-cell-sizing) floor. Both are pinned by widget tests at the corners of the supported range, including a wide-but-short case where height still binds.
- The game screen no longer wraps the board in a scroll view. The board fits by construction, so a scrollable could only ever hide a layout bug rather than reveal it.
- The freed left column is where the move list and scrubber (ticket 012) will go. A test asserts at least 30% of the width stays clear so that space is not quietly consumed.
- Each layer caption now has a fixed height, so the cell arithmetic is exact rather than dependent on how tall the caption renders; it scales down instead of overflowing at large system text sizes.

### D138 — The store is pluggable, not the repository
**Question:** Ticket 005 requires that no screen touches storage directly and that widget tests run against the repository contract. The first implementation put file I/O inside the repository, which made every widget test hang: `testWidgets` runs its body in a fake-async zone that never completes real `dart:io` futures.

**Decision:** Split into a `DocumentStore` (where bytes live) and one `LocalGameRepository` (the rules: validation, completion, ordering). `FileDocumentStore` is atomic tmp-then-rename on disk; `MemoryDocumentStore` does not outlive the process.

**Rationale:** The obvious alternative — a second fake `GameRepository` for widget tests — would have duplicated completion logic, so the rules of the game would exist twice and could disagree. Swapping only the storage keeps one implementation of the rules and still gives widget tests a store that works under fake async.

**Consequence:** The contract suite runs against **both** stores, which is the same suite 0.3a's Firestore implementation must pass. Behaviour only the disk can have — surviving a restart, surviving a truncated file, skipping a newer schema — is tested separately in plain `test` bodies where real I/O completes.

### D139 — Game completion is decided by the repository, not by each caller
**Question:** When a move ends a game, who writes the result — the repository or the screen that appended the move?

**Decision:** `appendMove` applies the move, asks the engine for the outcome, and writes `state`, `result` and `completedAt` itself.

**Rationale:** Completion is a pure function of the move list, so it is derivable exactly once. Any caller that forgot would leave a finished game stored as `active` forever, and 0.1 already has two callers (pass-and-play, and bot play in ticket 006) with more coming. Appending is also where validation belongs: the replay that decides the outcome is the same replay that rejects an illegal cell, so an illegal move cannot reach storage.

**Consequence:** The repository depends on `quadrim_engine`. That is the data layer depending on the pure domain layer, which is the direction spec §9.7 allows.

### D140 — Storage subscribes before it publishes
**Question:** How should the `watch` streams deliver the current value as well as subsequent changes?

**Decision:** `Stream.multi`: each listener gets its own controller, the change subscription is established first, and the current value is delivered after.

**Rationale:** The natural `async*` form — yield the current value, then `yield*` the change stream — subscribes only after the first value has been consumed, leaving a microtask-wide window in which a write emits to a broadcast controller with no listener and is silently lost. Unreachable while every write follows a user tap; reachable the moment ticket 006's bot replies as the screen opens. Found by code review, pinned by a test that writes in the same microtask as the subscribe.

**Consequence:** `onCancel` deliberately does not return the inner subscription's cancel future. Awaiting a *broadcast* subscription's cancel never completes inside `testWidgets`' fake-async zone, which hangs `.first` — reproduced in isolation with no project code involved. There is nothing useful to wait for, since cancelling a broadcast subscription cannot fail.

### D141 — Pass-and-play resumes the unfinished game rather than starting a new one
**Question:** Ticket 005 requires that an in-progress game survives a restart, but the main screen that would list and resume games is ticket 013.

**Decision:** Until ticket 013 exists, the placeholder home button resumes the unfinished pass-and-play game if there is one and starts a fresh one otherwise.

**Rationale:** Silently starting a new game would have made the acceptance criterion unverifiable end to end, and an explicit resume affordance is ticket 013's design decision to make, not something to invent here and then undo.

**Consequence:** Verified on the emulator, not only in tests: four moves, `am force-stop`, relaunch, board restored from `files/quadrim/games/` — the exact path the backup allowlist covers.

**Superseded by ticket 013.** The main screen now lists games in progress and resuming one is a tap on that list, which is what this decision said it would be. "New game" always starts a new game; nothing silently resumes any more.

### D142 — A bot configuration beyond what the code can do fails loudly
**Question:** `BotConfig` carries search depth, strategic rules and positional bias from ticket 006, but the behaviour behind those fields arrives with tickets 008–010. What should `chooseMove` do if a configuration asks for them today?

**Decision:** Throw `UnimplementedError`. Do not fall through to the random choice.

**Rationale:** Falling through would make any catalogue entry added ahead of its behaviour a second Pebble that *looks* like it works — and the thing that would eventually notice is ticket 014's calibration harness, reporting an opponent as badly mis-rated with no obvious cause. Failing at the first call names the actual problem.

**Consequence:** The catalogue holds exactly one entry until ticket 008. A test asserts the guard fires for a configuration with rules enabled.

### D143 — One busy flag guards both the player's move and the opponent's
**Question:** Code review found that a second tap landing before the first had round-tripped through the repository was stored as well — in a game against the computer, the player took the opponent's turn and the opponent then never moved.

**Decision:** A single `_busy` flag in the game screen, set synchronously before dispatching either a human move or the opponent's, cleared in a `finally`.

**Rationale:** The board's enabled state is derived from the last *stored* game, so it cannot be the guard against a move that has not been stored yet. Two separate flags — one for the human, one for the opponent — would have left the same window open between them.

**Consequence:** Found by reviewing the diff, then reproduced as a failing test (`[0, 1]` instead of `[0]`) before being fixed. The regression test also asserts the opponent still gets its own turn afterwards, so the guard cannot be "fixed" by simply blocking the opponent.

### D144 — Published opponent ratings are fixed; calibration moves the parameters, not the numbers
**Question:** The twenty ratings are estimates ([OI-03](#oi-03--bot-rating-calibration)). Ticket 014's harness will measure real relative strength. When measurement disagrees with the published number, which one changes?

**Decision:** **The published rating is final and does not move.** It is the anchor the player's rating is earned against. When measurement disagrees, the *opponent's configuration* is adjusted — blunder rate, search depth, rule set, positional bias — until its actual strength matches the number it advertises. Recalibration is therefore a tuning task on the bot, not a rewrite of the ladder.

**Rationale:** A rating a player earned against "Onyx, 1650" means nothing if Onyx later becomes 1520. Every derived rating in every player's history would silently change meaning, and the "+12" they saw on a result screen would become unreproducible. Fixing the advertised number and tuning the bot to meet it keeps every past result valid, and makes the failure mode a visible configuration change rather than an invisible historical rewrite. It also matches how the roster is presented: the tiers and their ratings are product, the parameters are implementation.

**Consequence:**
- Ticket 014's harness measures and **reports**; it never rewrites the roster. An opponent measuring outside tolerance for its published rating is a configuration defect to fix, exactly as a tier inversion already is.
- `opponentRating` on a completed game (spec §8.3) will now normally equal the catalogue rating for that opponent. It stays, because it is what makes the invariant checkable and would be the only record if the rule were ever broken.
- Real strength for 0.1 is an approximate estimate and is stated as such. The tuning pass waits for enough real play to measure against, which is a post-0.1 activity.
- [OI-03](#oi-03--bot-rating-calibration) narrows: it is no longer "what should the ratings be" but "do the current parameters produce the strength each fixed rating claims".

### D145 — The rating maths and the fold were pulled forward into ticket 007
**Question:** Ticket 007 is blocked only by 004, but one of its acceptance criteria — showing the change to the player's computer rating — needs the rating maths (ticket 014) and the fold over completed games (ticket 027). Which gives?

**Decision:** Implement `quadrim_rating` and the app-side fold now, as part of 007. Tickets 014 and 027 keep their remaining scope: 014 the self-play harness, 027 the main-screen display.

**Rationale:** The alternative was to ship 007 without the rating line and revisit the result screen twice. The maths is small, pure and fully specified in spec §7.2, so there was nothing to discover by waiting — the dependency in the ticket graph was simply missing.

**Consequence:** The ticket ordering is wrong as written, not just inconvenient. Recorded here rather than silently reordered, so the graph can be corrected if it is ever regenerated. `ratingAround` was added beyond §7.2's four exports: a result screen needs the rating either side of one game, and folding twice from the seed to get it would have been the same work written at the call site.

### D146 — The result sits below the board, not over it
**Question:** Ticket 007 calls for a "result screen", and also requires the four cells of the winning line to be highlighted so the player can see how it was won. A screen that covers the board satisfies one and defeats the other.

**Decision:** An inline result panel below the board, not a route or a dialog.

**Rationale:** Seeing *how* the line was completed is the more valuable half of the requirement, and it is worthless if the board is behind a card. Keeping both on screen also means rematch is one tap from the position that was just played rather than one tap after a dismissal.

**Consequence:** The panel competes with the board for height, on a screen where every dp above the board costs a sixteenth of a cell. Combined with the first-move caption this pushed `kMinSupportedHeight` from 760 to 780 — a real narrowing of the supported device range, taken deliberately and pinned by the geometry tests.

### D147 — Centre and corner preference are two weights, not one enum
**Question:** Ticket 006 gave `BotConfig` a `positionalBias` enum with `none | centre | corners`. Ticket 008 requires corner and centre preference to be **configurable independently**.

**Decision:** Replace the enum with two weights, `centreBias` and `cornerBias`, each 0–1.

**Rationale:** A three-valued enum cannot express "both" or "a little of each", and the roster needs exactly that range — Finch has a strong centre preference, Kestrel is corner-hungry, Bramble and Ember have no positional sense at all. It also matches what [Idea-final §6.3](Idea-final.md) already records: the central 2×2×2 and the corners are **the same class** under the board's symmetries, both sitting on seven lines each, so ranking one strictly above the other is a flavour choice rather than a strength one. Two weights say that; an ordered enum implies the opposite.

**Consequence:** A breaking change to an API one ticket old, which is cheap now and would not be later. Nothing outside the engine referenced it. Ticket 009's third positional rule — most lines already part-owned — becomes another term in the same scoring step rather than another enum case.

### D148 — Aggression is an ordering plus a skip probability
**Question:** Ticket 008 requires aggression to weight "building one's own threats against blocking the opponent's", and the roster describes Kestrel as ignoring opponent double threats "about a third of the time". What is aggression, numerically?

**Decision:** `aggression` ∈ [0,1] does two things: below 0.5 the opponent denies a double threat before building one and at or above it builds first; above 0.5 it additionally skips the denial entirely with probability `2 × aggression − 1`.

**Rationale:** Ordering alone cannot express "a third of the time" — it is all or nothing. A separate "ignore rate" field would have been a second knob meaning nearly the same thing, and Kestrel would be the only opponent to use it. One number that reads as temperament keeps the catalogue honest: Kestrel's 0.67 *is* the one-third.

**Consequence:** Rules 1 and 2 are deliberately exempt. Taking an offered win is never wrong, and missing an offered loss is what `blunderRate` already models — letting aggression skip those too would make a high-aggression opponent simply bad rather than reckless.

### D149 — The positional ladder is weights, not an if-else chain
**Question:** Ticket 009 states the positional rules as an order — centre, then corner, then the cell on the most lines already part-owned, then random — but also requires that "positional bias is configurable, so later opponents can weight centre, corner and edge differently". An order and a set of weights are not the same thing. Which is the implementation?

**Decision:** Weights, arranged to produce the order. `centreBias`, `cornerBias` and `edgeBias` weight the three classes the board partitions into, and `lineBias` weights the building term, scored as the fraction of the seven lines through a cell that already hold two or more own pieces and no opponent piece. Basalt uses 1.0 / 0.5 / 0.0 / 0.25, so any centre cell (1.00–1.25) outscores any corner (0.50–0.75), which outscores any other cell (0.00–0.25), and the building term decides within each class.

**Rationale:** A hard-coded chain would satisfy the first criterion and defeat the third: it cannot express an opponent that cares more about the structure it is building than about where on the board that structure sits, which is exactly the direction the Club and Expert tiers move in. One scoring function also means the ladder is the tie-break inside a strategic rule and the whole decision when no rule fires, without a second code path. The three classes partition the board, so the class weights are an `else if` chain rather than a sum — a cell cannot be both centre and corner.

**Consequence:** The order is a property of the numbers, not of the code, so a mis-set weight silently reorders the ladder. Basalt's test asserts the gaps (`centreBias − cornerBias > lineBias`, and the same for corner over edge) rather than the resulting behaviour alone. `edgeBias` ships unused by any opponent; it exists because the criterion asks for it and because the alternative is discovering the need for it in ticket 025.

### D150 — Temperament is one number, reaching the rule order and the evaluation alike
**Question:** Marlin and Vireo are described as searching two plies "with opposing temperaments". The search needs a weighting between one's own line ownership and the opponent's. Is that a new configuration field, or the existing `aggression`?

**Decision:** The existing one. `BotConfig.defence` is derived as `2 × (1 − aggression)`, and multiplies the opponent's line ownership in the heuristic evaluation. One number therefore sets the order of rules 3 and 4, the probability of skipping a denial ([D148](#d148--aggression-is-an-ordering-plus-a-skip-probability)), and now the evaluation's weighting.

**Rationale:** Two knobs meaning "how defensive is it" would inevitably be set inconsistently — an opponent that denies double threats first but evaluates aggressively is not a temperament, it is a bug that never throws. Deriving keeps the catalogue readable: Marlin's 0.6 and Vireo's 0.4 are the whole of their difference in intent.

**Consequence:** `aggression` is now load-bearing in three places, so changing its meaning is a change to every searching opponent. See [D154](#d154--the-club-tier-was-retuned-to-what-self-play-actually-measures) for what measurement then said about how much temperament is worth.

### D151 — Threat-space search is a separate depth, not a deeper search
**Question:** Sable is "4-ply plus dedicated threat-space search for double threats". Is that a bigger `searchDepth`, or its own thing?

**Decision:** Its own field, `threatSearchDepth`, counting how many of the opponent's *own* forcing moves it will follow. Zero disables it. It runs before the rule ladder, gated on neither side having an immediate win, and when it finds a forced win that move is the only candidate.

**Rationale:** The two look at different things. A depth-limited search examines every reply and so cannot go far; a forcing search examines only replies the opponent has no choice about, and so goes much further for much less work. Expressing "look eight plies ahead, but only down forcing lines" as a `searchDepth` of 8 would be a lie about the cost.

**Consequence:** The candidate set for a forcing move is not every empty cell but only cells on a line where the mover already holds two and the opponent none — a move creates a threat exactly when it does that, so the narrowing is the definition rather than a heuristic. It is what keeps the fan-out in single figures.

### D152 — The computer's move budget, and where the time is spent
**Question:** Ticket 010 requires a move "within a time budget that feels responsive on a mid-range phone, with the budget recorded". What is the budget, and does the search meet it?

**Decision:** **250 ms mean and 1 s worst case on a mid-range phone.** Measured on the development machine over complete games: Marlin 0.1 ms mean / 0.6 ms worst, Vireo 2.3 / 25.6, Onyx 1.8 / 12.9, Sable 21.3 / 476. The opponent's visible delay stays at 550 ms (ticket 006), so on that machine every opponent but Sable finishes inside the pause the player already sees.

**Rationale:** Getting there needed three changes, each measured. The search keeps its own mutable board with make/unmake and incrementally maintained line counts instead of copying a `GameState` per node (a four-ply look at the opening position: 438 ms → 79 ms). The root orders its candidates by a one-ply pass and then shares alpha between them (2087 ms → 62 ms worst over a game). The forcing search narrows candidates as in [D151](#d151--threat-space-search-is-a-separate-depth-not-a-deeper-search) (949 ms → 177 ms worst at nine forcing moves).

**Consequence:** Sable is the one opponent near the edge: a phone is perhaps two to four times slower than this machine, which puts its worst case around a second and a half. It is the strongest opponent in 0.1 and it thinks off the interface thread ([D153](#d153--the-search-runs-in-a-background-isolate-injected-as-a-function)), so a visibly long think is a reasonable thing for it to do — but ticket 016's first real-device run must confirm it, and this decision updated with what that finds. The engine test asserts only that no move exceeds 1 s on this machine: an order of magnitude loose on the mean, deliberately, because it guards against a change that makes the search catastrophically slower and is not pretending to be a device measurement.

### D153 — The search runs in a background isolate, injected as a function
**Question:** "Search never blocks the interface" — but `chooseMove` is synchronous, and a widget test cannot wait for a real isolate.

**Decision:** `GameScreen` takes an `OpponentMove` function, defaulting to `chooseMoveInBackground`, which hands the move list, the bot id and a drawn seed to `compute`. Widget tests pass `chooseMoveInline`, which makes the same choice on the spot. One test uses `tester.runAsync` to exercise the real isolate path with Onyx.

**Rationale:** A `Random` cannot cross an isolate boundary, so the seed is drawn on the interface side and sent as an integer — which incidentally keeps the opponent reproducible from an injected seeded source, as every existing test needs. Injecting a function rather than a class keeps this to one parameter with a default; the seam exists because `testWidgets` runs in a fake-async zone where an isolate's future never completes, which this project has already been bitten by twice ([D138](#d138--the-store-is-pluggable-not-the-repository)).

**Consequence:** The engine stays pure — `dart:isolate` never enters it, and the concurrency concern lives in the app layer where it belongs.

### D154 — The Club tier was retuned to what self-play actually measures
**Question:** Idea-final §6.4 gives Vireo 2-ply search with defensive weighting at 1550 and Marlin 2-ply with aggressive weighting at 1500, and Onyx a plain 4-ply search at 1650. Does that produce the ladder it claims?

**Decision:** No, and the parameters changed rather than the ratings ([D144](#d144--published-opponent-ratings-are-fixed-calibration-moves-the-parameters-not-the-numbers)). What ships is:

| | search plies | forcing moves | blunder | aggression |
|---|---|---|---|---|
| Marlin 1500 | 2 | — | 5% | 0.6 |
| Vireo 1550 | 3 | 3 | 4% | 0.4 |
| Onyx 1650 | 3 | 6 | 3% | 0.5 |
| Sable 1700 | 4 | 9 | 2% | 0.5 |

**Rationale:** Measured over matches of 200–400 games with alternating starts:
- **Defensive weighting is worth nothing.** At equal depth Vireo and Marlin are level however the two are set (185–185, 180–194, 173–206 across aggression pairs from 0.45/0.55 to 0.45/0.65), and a *more* aggressive Marlin is strictly stronger against Basalt (121–73 at 0.7 against 103–89 at 0.55). In a game of 76 competing lines, building beats shadowing.
- **Depth barely separates opponents.** A plain four-ply Onyx against a three-ply Vireo was 100–92; a four-ply Onyx against a three-ply Vireo *with* a two-move forcing search actually lost, 73–87.
- **Forced-win detection dominates everything.** Every rung above Marlin is separated by forcing depth alone.

The shipped ladder, at the sample sizes the tests use, holds across three independent seeds: Marlin–Basalt about 117–75, Vireo–Marlin about 110–90, Onyx–Vireo about 26–14 of 40, Sable–Onyx about 31–9 of 40.

**Consequence:** Vireo and Onyx search three plies rather than the two and four §6.4's prose gives them, and both have a forcing search it does not mention. Both deviations are recorded here rather than silently absorbed, and both are cheap — Onyx costs 1.8 ms a move where the four-ply version cost 59 ms and played worse. The larger finding is for [OI-03](#oi-03--bot-rating-calibration) and ticket 014: the levers that actually move strength in this game are, in order, forcing-search depth, then blunder rate, then search depth, and temperament not at all. The Expert and Master tiers (tickets 025, 026) should be built on the first of those, not the third — and the fact that ordinary depth stops paying past three plies is a statement about the evaluation, which is where that work should start.

### D155 — A bug the retuning exposed: an unforced "forced" win
**Question:** Sable initially lost to Onyx (19–21) despite strictly more machinery. Why?

**Decision:** The threat-space search returned a double-threat move before checking whether the opponent could simply complete a line on their next move. Reordered so that check comes first; Sable then beat Onyx 52–8 in the same harness.

**Rationale:** A double threat is only unanswerable if the opponent has to answer it. With a win of their own on the board they never do, and the "forced win" was a losing move played in preference to whatever the four-ply search wanted.

**Consequence:** The soundness of a claimed forced win is now a test, not an assumption: over the sequences short enough to check exhaustively, every reply to a claimed win is verified still to lose. A head-to-head result would not have caught this — it only showed up as a bot that was mysteriously no better than the one below it.

### D156 — Two search defects the ladder measurement exposed
**Question:** With the parameters of [D154](#d154--the-club-tier-was-retuned-to-what-self-play-actually-measures) settled, a four-ply Onyx still lost to a three-ply Vireo, and the tie the positional ladder breaks was sometimes not a tie at all. Both are search defects, not tuning.

**Decision:** Two fixes, both in `search.dart`:

1. **The root window opens one point below the best already in hand**, not at it. With the window at alpha, a candidate that fails low can return exactly alpha — an upper bound the caller cannot distinguish from a genuine tie. Since the caller uses ties to choose (the positional ladder picks among equal-scoring moves), a move the search rated *worse* could be played. One point lower, a bound always lands strictly below the maximum.
2. **One move of quiescence at the horizon.** A leaf where the side to move completes a line is a decided position, and evaluating it as quiet is simply wrong — the error is largest at even depths, where the search stops just after the opponent's reply. The count of lines one move from completing is maintained incrementally alongside the evaluation, so the check is a comparison rather than a scan.

**Rationale:** The first was found by reasoning about the fail-soft bound rather than by a failing test, and it changed play enough to flatten the whole ladder when fixed — which is what forced the retune in D154. The second was found by disbelieving a measurement: "deeper search loses" is a claim about the searcher, not about the game.

**Consequence:** Quiescence did not, in the end, make four-ply beat three-ply — so the horizon was not the whole story, and the evaluation itself is the remaining suspect. That is now the recorded starting point for the Expert tier rather than a surprise waiting in ticket 025. Both fixes have tests that fail without them: one asserts that no candidate reaches the maximum on a bound, the other that a position where the opponent wins next move never scores as quiet.

### D157 — Pass-and-play does not count towards the record
**Question:** The main screen shows wins, losses and draws. In pass-and-play the player holds both seats. Does a pass-and-play win count as a win?

**Decision:** No. Statistics and the per-opponent breakdown cover games against the computer only. Pass-and-play games still appear in the lists of games in progress and games finished, and a finished one reports which *side* won rather than whether "you" did.

**Rationale:** Every pass-and-play game is simultaneously a win and a loss for the one person playing it. Counting it either way makes the totals mean nothing, and counting it both ways makes them mean less. The same reasoning already excludes it from the rating ladder, where `passAndPlayNoRating` says so on the result screen — this is the same rule applied to the same games in a second place.

**Consequence:** A player who only ever passes and plays sees an empty record and a seed rating, which is correct but bleak. Ticket 029's copy should make the record's scope explicit rather than leaving "0 won" to imply failure.

### D158 — The main screen watches completed games rather than loading them once
**Question:** Ticket 013 asks both that the statistics, breakdown, rating and milestones come from **one** load rather than four sweeps, and that they update when a game finishes without a restart. `GameRepository` offers both `loadCompletedGames()` (one-shot) and `watchCompletedGames()` (a stream). Which?

**Decision:** The stream. One `HomeSummary.from(...)` fold per emission, feeding all four readings.

**Rationale:** The one-load criterion is about not sweeping storage once per statistic; it is satisfied by any design where the four readings share a list. The stream satisfies it *and* the live-update criterion, where the one-shot load would need a manual refresh on every navigation back. `loadCompletedGames` remains the right call for the result screen, which folds a fixed history at a fixed moment.

**Consequence:** The fold runs on every change rather than once per visit. It is a fold over a list already in memory, so the cost is nothing until the history is very large — and when it is, the answer is pagination in the repository, not a cached total (spec §7.2 forbids storing what the games already say).

### D159 — Entry points ship before their screens, as placeholders
**Question:** Ticket 013 requires a button that opens the tutorial (ticket 018) and an entry point to settings (ticket 028). Neither screen exists. Disable the buttons, omit them, or wire them to something?

**Decision:** Wire them. Both open a placeholder route carrying one translated line, and tickets 018 and 028 replace that route rather than add one.

**Rationale:** A disabled control is indistinguishable from a broken one, and an omitted control means the layout is re-litigated when the screen lands. A placeholder that says so is honest, is one widget, and makes the navigation path itself testable now.

**Consequence:** One new string, `comingSoon`, which must be gone from both `.arb` files by ticket 022. Nobody outside this repository sees it before then: ticket 016's closed test is blocked by both 018 and 028.

### D160 — The symmetry group is constructed and proved, not tabulated
**Question:** The board has 192 automorphisms. Where do they come from — a generated table, like the 76 lines, or code?

**Decision:** Constructed at load from a closed-form rule, and verified exhaustively by tests. A permutation of `{0,1,2,3}` may be applied to every axis at once exactly when it commutes with reversal — eight of the twenty-four qualify, because a plane's anti-diagonal `(t, 3−t)` survives only then. The y and z maps may each differ from the x map by a reversal, and the three axes may be permuted: 8 × 2 × 2 × 6 = 192.

**Rationale:** A hand-written table would be 12,288 numbers nobody could check by reading, and a generated one would need the same construction anyway. What matters is the proof, and that is what the tests are: exactly 192 members, every one a permutation of all 64 cells, every one mapping the 76 lines onto the 76 lines, closed under composition, closed under inverses, and preserving each cell's degree.

**Consequence:** Two independent facts fall out and are asserted rather than assumed — the group has exactly two orbits, of sizes 16 and 48, matching the known cell degrees; and an empty board has exactly **two** distinct opening moves, which is Idea-final §2.3's claim reproduced from first principles rather than quoted.

### D161 — Canonicalisation pays in the opening and nowhere else
**Question:** Ticket 025 calls canonicalising positions before caching them "the difference between a table that fits on a phone and one that does not". Is it?

**Decision:** Implemented, verified, and **switched off by default**. `SearchLimits.canonicalPlies` chooses how many plies from the root are keyed by canonical form; every shipped opponent leaves it at zero.

**Rationale:** Measured, not assumed.
- Maintaining one Zobrist hash per automorphism costs **540 ns a move** against roughly 10 ns of actual node work — the collapse has to earn two orders of magnitude.
- From an **empty** root it does: canonicalising the top four plies reached depth 5 in 71 ms where the plain table reached depth 4 in 89 ms. The opening's positions genuinely share classes — the 4,032 two-piece positions collapse to about 21.
- From a root with **four or more pieces** it does not. Those pieces break the symmetry: a position with two or more pieces already has all 192 images distinct, so its symmetric twins are boards the search never visits. Measured hit rate was unchanged at 3.0% and the search took **4× longer**.

**Consequence:** The ticket's claim is true of a *stored strategy book* — where positions are indexed globally and symmetric ones genuinely recur — and false of a per-move transposition table beyond the first few moves. The machinery stays because 1.0's solver needs exactly this, and because an opening book would use it tomorrow. The criterion "positions are canonicalised before being cached" is met by the code and provable by its tests; what changed is which opponents ask for it, which is a configuration.

### D162 — The Expert tier's budgets, and the reference device that is still missing
**Question:** Ticket 025 requires every budget in nodes, the wall-clock equivalent measured against a **named reference device**, and responsiveness judged on that device.

**Decision:** Budgets are in nodes — Quartz 175,000, Corvus 260,000, Lyra 400,000, Titan 550,000 — and the wall clock is recorded against the **development machine** (Windows 11, Dart VM JIT), because no phone has been measured yet:

| | nodes | mean | worst |
|---|---|---|---|
| Quartz | 175k | 53 ms | 151 ms |
| Corvus | 260k | 74 ms | 200 ms |
| Lyra | 400k | 101 ms | 453 ms |
| Titan | 550k | 228 ms | 762 ms |

**Rationale:** A node budget is the same number everywhere; a millisecond budget is not, and would make an opponent play differently on a fast phone than a slow one, in release than in debug, in CI than on a device — breaking spec E7 everywhere except the machine it was written on.

**Consequence:** **The named-reference-device criterion is not met**, and cannot be from here: the development machine is a stand-in. Against [D152](#d152--the-computers-move-budget-and-where-the-time-is-spent)'s 250 ms mean and 1 s worst, Quartz through Lyra have room and Titan does not — at two to four times slower, a phone puts Titan around 600 ms mean and 2.5 s worst. Ticket 016's first device run must measure all four and either confirm these budgets or cut them; this decision is the record of what to check.

### D163 — Eight plies is not affordable, and depth is not the reason these opponents are strong
**Question:** Idea-final §6.4 gives the Expert tier 6-ply and 8-ply searches. Does the engine reach them?

**Decision:** No, and the roster's depths are not what ships. The four are separated by node budget and forcing-search depth; the depth each reaches is whatever its budget buys, typically **five to six plies** in the middlegame.

**Rationale:** Measured with table-move and killer ordering in place, from a ten-piece root: 100k nodes reaches depth 4, 500k reaches depth 6, 2M reaches depth 6. Each further ply costs roughly seven times the last, so eight plies is around 25M nodes — about fifteen seconds here and a minute on a phone. Adding the transposition table, iterative deepening, best-move ordering and killer moves took the reachable depth from 4 to 6 at a fixed budget; that is what this machinery bought, and it is not enough for 8.

**Consequence:** This is the third measurement pointing the same way, after [D154](#d154--the-club-tier-was-retuned-to-what-self-play-actually-measures) and [D156](#d156--two-search-defects-the-ladder-measurement-exposed): **the evaluation, not the depth, is what limits this engine.** The Master tier (ticket 026) is specified as "full-strength search", and on this evidence buying it more nodes will not produce a 2300-rated opponent. That ticket should begin by improving the evaluation — the current one counts line ownership and nothing else, with no notion of forks, tempo, or which threats are actually reachable.

### D164 — The real move budget is twenty seconds on device, not a quarter of a second
**Question:** [D152](#d152--the-computers-move-budget-and-where-the-time-is-spent) set the computer's think time at 250 ms mean and 1 s worst. That number was inferred from "feels responsive", not given.

**Decision (product owner):** **A move must complete within twenty seconds on a device.** That is a ceiling, not a target.

**Rationale:** Given directly, and it supersedes the inferred budget. D152's number was chosen by an engineer guessing at what a player would tolerate, and every tuning decision in tickets 010 and 025 was made under it — including the conclusion that Titan was over budget, which on the real number it is not, by a factor of about thirty.

**Consequence:** The ceiling belongs to the strongest opponents alone. A twenty-second think from a 1500-rated opponent would be a defect, not a feature, so the budget is spent as a ladder: the Novice, Casual and Club tiers stay in single-digit milliseconds, the Expert tier moves into the low seconds, and only the Master tier goes near the ceiling. [D162](#d162--the-experts-tier-budgets-and-the-reference-device-that-is-still-missing)'s node budgets were sized against the wrong number and are raised accordingly. The ceiling is still a *device* number that no device has yet produced — ticket 016 must confirm the conversion from nodes.

### D165 — The whole app ships in fifty megabytes
**Question:** Idea-final leaves the size of a stored strategy book open (OI-02), and the Master tier's Quadrim Prime is described as following a proven winning strategy.

**Decision (product owner):** **No more than 50 MB of data ships with the app.**

**Rationale:** Given directly. It is the first hard number OI-02 has had.

**Consequence:** It is a generous bound for a *strategic* book — Patashnik's published solution is around 2,929 positions, which is kilobytes — and a tight one for anything resembling a tablebase. It also changes what [D161](#d161--canonicalisation-pays-in-the-opening-and-nowhere-else) is for: canonicalisation buys nothing in a per-move search table, but a stored book keyed by canonical form holds up to 192 times as many positions in the same 50 MB. That is the use the symmetry machinery was really built for, and it now has a budget to be measured against.

### D166 — A thinking opponent must be visibly thinking
**Question:** With a twenty-second ceiling, what does the player see?

**Decision (product owner):** While the computer is deciding, the player must see a **clear indication that it is thinking**, so that it is obvious what they are waiting for.

**Rationale:** Given directly. The existing treatment — a line of text reading "{bot} is thinking…" — was designed against a 550 ms pause, where it is ample. At twenty seconds a static line of text is indistinguishable from a frozen app.

**Consequence:** The game screen needs a visible, moving indicator for the duration, and the board must read as deliberately inactive rather than unresponsive. Ticket 025's "search runs off the interface thread and is abandoned cleanly if the player leaves" is what makes that honest: the indicator can animate only because the search is not on the interface thread ([D153](#d153--the-search-runs-in-a-background-isolate-injected-as-a-function)). Built as part of this ticket rather than deferred, because it is the difference between a slow opponent and a broken one. One side effect: an indefinite animation means `pumpAndSettle` never settles, so widget tests covering the opponent's turn must use bounded pumps.

### D167 — Teaching the evaluation about forks did not make it stronger
**Question:** [D163](#d163--eight-plies-is-not-affordable-and-depth-is-not-the-reason-these-opponents-are-strong) concluded the evaluation, not the search, is what limits this engine, and the obvious gap was that it counted line *ownership* and so could not tell two threats sharing a cell — one block kills both — from two on different cells, which is a won game. Does closing that gap help?

**Decision:** The evaluation now counts **distinct threatened cells** and pays `forkBonus` for the second and each further one, maintained incrementally at no per-node cost. The weight is configurable, defaulting to 3000. **It is kept, but it is not the improvement it was meant to be.**

**Rationale:** Measured by playing fork-aware against fork-blind at identical node budgets, which is the only question that matters:

| | result |
|---|---|
| 30k nodes, 30 games | 15–15 |
| 120k nodes, 30 games | 19–11 |
| 120k nodes, 120 games, bonus 1000 | 63–57 |
| 120k nodes, 120 games, bonus 3000 | 63–57 |

The encouraging 19–11 did not survive a larger sample. At 120 games, 63–57 is 52.5% — half a standard deviation, indistinguishable from a coin. Then a third weight, 9000, returned **byte-identical** 63–57. Three weights spanning nine times the range cannot produce the same games by chance, so before publishing the result the knob itself was put on trial:

- The reference evaluation does see forks: a position with light threatening at both cell 3 and cell 19 scores 3042, the bonus plainly included.
- The weight does reach the search: over 286 random positions, weight 0 and weight 9000 produce **different score vectors in 79** of them.
- But over 84 positions from real games between two searchers, the weight changed the scores 20 times and the **chosen move zero times**.

**Consequence:** That is the finding, and it is sharper than "the term is weak". When a fork is available, the move that creates it is *already* ranked first for other reasons — the three-in-a-line weight of 40, the quiescence check that returns a win score outright, and the forcing search that proves the win before the evaluation is consulted at all. The bonus adds 3000 to a move that was already winning the argmax. A static evaluation term can only change play by changing which move is best, and this one never does.

It is kept because it is free, correct, and proved consistent with the reference definition, and because a future evaluation that *does* change play will want the counter. It is recorded here as a **negative result** so that nobody spends the same week twice. What limits the evaluation is therefore something else: it has no notion of tempo, and no notion of which lines are actually reachable rather than merely alive. Those are the next things to try, and the fork term is evidence that "obvious gap" is not the same as "binding constraint" — the gap was real, and closing it changed nothing, because the search was already covering it by another route.

**One thing the rewrite did buy:** holding the incremental evaluation to the from-scratch definition exposed a real bug in make/unmake. `_adjust` reads the piece counts *and* the board to find where a threat lands, and the single interleaved loop left a cell occupied while its counts still said otherwise. The old evaluation never noticed because it only read counts.

### D168 — The forcing search had no budget, and took five minutes on one move
**Question:** Ticket 025 requires that every search budget be expressed in nodes. The threat-space search was given a *depth* in forcing moves and nothing else.

**Decision:** `threatSpaceWin` takes a node budget, defaulting to 200,000, and claims nothing when it runs out.

**Rationale:** Found by measuring, not by reading. A forcing search is narrow but not bounded — its fan-out is the number of cells that create a threat, which in a rich position is dozens. At Corvus's eleven forcing moves that produced a **worst case of 323,696 ms for a single move**, against a mean of 10.5 s. With the budget: 2,250 ms worst, 629 ms mean.

**Consequence:** This was a shipping defect against [D164](#d164--the-real-move-budget-is-twenty-seconds-on-device-not-a-quarter-of-a-second)'s twenty-second ceiling by a factor of sixteen, and it existed from ticket 010 — it went unseen because the Club tier's forcing depths are small enough never to reach the explosion. Worst-case timing, not mean, is what the ceiling is about, and only the raised budgets of D164 made it visible.

---

### D169 — Pointing the forcing search at the opponent is the largest strength gain measured
**Question:** [D163](#d163--eight-plies-is-not-affordable-and-depth-is-not-the-reason-these-opponents-are-strong) and [D167](#d167--teaching-the-evaluation-about-forks-did-not-make-it-stronger) both ended in negative results: neither deeper search nor a better static evaluation moved the ladder. The one component that had ever moved it was the forcing search, which Sable used to beat Onyx 52–8. But it was only ever asked one question — *can I force a win?* — and never the other one.

**Decision:** `BotConfig` gains `defenceSearchDepth`. Above zero, every candidate move is tested by running the same threat-space search for the **opponent** in the position that move creates, and any move that hands over a forced win is dropped before anything else scores it. When every move loses, the unfiltered list is returned and the game is played out.

**Rationale:** Measured as a duel between the same configuration with and without it, 60 games, both seats:

| pairing | result |
|---|---|
| `vireo+d3` vs `vireo` | 29–31 |
| `onyx+d6` vs `onyx` | 45–15 |
| `sable+d9` vs `sable` | 47–12 |
| `corvus+d11` vs `corvus` (30 games) | 20–10 |

Finding your own forced win only pays in the positions where you have one. Seeing the opponent's pays in every position where you were about to allow one — and in Qubic one allowed forcing sequence is the whole game.

Applied to the Expert tier, which is where the ladder had gone flat, the same adjacent pairs that could not be told apart on node budget alone now separate (30 games each):

| pairing | before, budget only | after, with defence |
|---|---|---|
| Corvus vs Quartz | 5–5 | 19–11 |
| Lyra vs Corvus | 4–6 | 20–10 |

Worst move time at the top of that: Lyra 4,974 ms, inside the twenty-second ceiling with room to spare.

**Consequence:** This is a **separate number** from `threatSearchDepth`, not the same one, for two reasons. It is the ladder dimension that raising the node budget failed to provide — the Expert tier went flat at 5-5 and 4-6 when the only dial was budget, whereas the table above spans roughly 300 rating points on this dial alone. And it is honest as difficulty: seeing your own combination and stopping others' are different skills that improve at different times, which is what a weak-but-tactical opponent should feel like. `vireo+d3` measuring as nothing also fixes the bottom of the range: below about four moves of defence there is nothing to gain, so the Novice and Casual tiers stay at zero and should.

---

### D170 — The forcing search now runs on the search's own board
**Question:** Defence multiplies the cost of the forcing search by the number of candidate moves — up to about fifty. The budget is shared out among them (the twenty-second ceiling of [D164](#d164--the-real-move-budget-is-twenty-seconds-on-device-not-a-quarter-of-a-second) is per *move*, not per question asked about it), so each candidate got roughly 4,000 nodes instead of 200,000 and missed wins a full-budget search finds. Buy the budget back, or accept a starved defence?

**Decision:** Buy it back. `threatSpaceWin` now runs on `_Board` — the search's incremental board — instead of on `GameState`. The original is kept as `threatSpaceWinNaively` and a test holds the two to identical answers over 1,500 positions at three depths.

**Rationale:** The naive version copied a 64-cell board twice and rescanned all 76 lines four times **per node**, to answer questions the board already tracks: "can the opponent win next move" is `_threat[1] > 0`, and "how many distinct cells do I threaten" is `_distinctThreats[0]`. Measured on the same 60-game duel:

| | worst move | mean |
|---|---|---|
| `sable+d9`, naive | 1,102 ms | 20 ms |
| `sable+d9`, on `_Board` | 175 ms | 10 ms |

The duel result was **47–12 both times, with the same single draw** — the rewrite changed the speed and nothing else, which is what the agreement test asserts and what makes the number above a clean measurement rather than two different opponents.

**Consequence:** Identical answers is a stronger requirement than identical verdicts, and the test asserts the stronger one: the positional ladder picks among tied candidates, so a forcing search that returned a different first move would be a different opponent even when both moves win. The naive version stays in the package for exactly this reason — a definition written the obvious way is worth keeping when something fast has to be checked against it.

---

### D171 — What the ladder is tuned with
**Question:** Every claim in D167, D169 and D170 is a duel result. Where does the instrument live?

**Decision:** `packages/quadrim_engine/tool/duel.dart`. It plays two configurations over N games from both seats and reports the result plus worst, median and mean move times. Opponent names accept modifiers — `sable+d9+b3000` is Sable with nine moves of defensive forcing search and a three-million-node forcing budget — so a knob can be measured without editing the catalogue.

**Rationale:** Under `tool/`, not `lib/`, which is what lets it use a clock: the purity gate scans `lib` only, and timing is the entire point of the thing. Keeping it in the repository rather than in a scratch directory is the difference between a ladder that was measured and a ladder that was measured once by someone who has since forgotten how.

**Consequence:** Ticket 014's calibration harness builds on this rather than starting over. It is not a shipped artefact and does not count against the 50 MB of [D165](#d165--fifty-megabytes-is-the-download-ceiling).

---

### D172 — Perfect play comes from Patashnik's dictionary, and nothing else comes from that repository
**Question:** Idea-final §14 left the top of the ladder resting on an open research question: is a perfect-play strategy obtainable, and on what terms? A copy was found at `github.com/kogorman/qubic`. That repository is **GPL-2.0**, which if it applied to what Quadrim takes would force Quadrim to be GPL-2.0 as well.

**Decision:** Take **`qubic.dictionary` and nothing else.** The file carries its own terms in its own header, quoted verbatim:

> Copyright 1988, all rights reserved. […] Anyone may use this dictionary as long its moves are unchanged and as long as its source is credited.

That is a permissive grant from the data's own copyright notice, and it predates the repository by decades. The GPL-2.0 covers Kevin O'Gorman's C++ under `qval/`, which Quadrim does not use: no line of it was read or adapted, and the move-generation procedure is implemented from the description in the dictionary's own header and from Patashnik's published article. The separation is recorded in `third_party/patashnik/NOTICE.md` with instructions to preserve it on any future refresh.

**Rationale:** Two obligations, both mechanised rather than promised. *Moves unchanged*: the file is vendored byte for byte, `.gitattributes` marks it `-text` so no line-ending conversion can touch it, and `tool/bookgen.dart` verifies its SHA-256 on every run of `tool/check.sh`. *Source credited*: see [D174](#d174--the-attribution-is-a-property-of-the-built-app-not-of-the-repository).

**Consequence:** This closes Idea-final §14 and OI-02's first half. The strategy book exists, it is 54,745 bytes, and it costs nothing against the fifty-megabyte ceiling of [D165](#d165--fifty-megabytes-is-the-download-ceiling). The solver sub-project OI-02 contemplated is not needed: Patashnik did it in 1976-77.

**This is not legal advice, and the licensing judgement above is the owner's to confirm.** What is recorded here is what the file says and what the code does about it.

---

### D173 — Perfect play is first-player play, and the perfect opponent still has to play second
**Question:** Qubic is a **first-player win** — that is what Patashnik proved, and the dictionary is the proof. There is therefore no such thing as perfect second-player play. What does the perfect opponent do when the player opens?

**Decision:** It falls back to searching, like any other opponent. One catalogue entry, both seats: unbeatable when it opens, merely the strongest thing in the catalogue when it does not. `bookMove` returns null for anything but the first player, and says so in its own gate rather than relying on a caller to remember.

**Rationale:** The alternatives were to let the perfect opponent always take the opening move, or to ship two entries. Both spend something real — the player's choice of seat, or two of the twenty opponent slots — to buy a claim that is only true half the time anyway. Falling back is honest: the opponent is exactly as strong as it can be in each seat, and nothing in the interface promises more.

**Consequence:** "Unbeatable" is a property of the *games it opens*, and any description of Quadrim Prime must say so. Verified rather than asserted: 200 games with Prime opening against random replies, **won 200, drawn 0, lost 0**, plus four games against Titan with the same result. The instructive number is that **0 of those moves fell through to the ordinary search** — 636 came from the book, 202 from the forcing search, 203 were an immediate win or block. The dictionary's header promises that past the book "a forced win must exist"; across 200 games it always did.

---

### D174 — The attribution is a property of the built app, not of the repository
**Question:** The dictionary may be used "as long as its source is credited". A NOTICE file in the repository credits it. Is that enough?

**Decision:** No. The credit goes **in the app**, as `l10n.strategyCredit`, in English and Dutch, and `tool/check.sh` fails if nothing in `app/lib` renders it.

**Rationale:** It is the built app that reaches people, and a repository nobody installs is not where a credit discharges an obligation. It currently sits on the settings placeholder, which is the screen ticket 028 will replace — deliberately, so that there is never a build in which the credit is merely planned. The check exists because the alternative is trusting that nobody deletes a line during that replacement.

**Consequence:** Ticket 028 inherits a requirement, not a suggestion: the settings screen it builds must carry this string, and the check will fail until it does. Ticket 022's release readiness should confirm it is visible in a release build, not only a debug one.

---

### D175 — The book is stored in canonical form, and the move has to be turned back with it
**Question:** 2929 entries cannot cover the positions a game reaches. The dictionary's header says why they can: "you will need (1) a canonical-form routine (there are 192 automorphisms of the Qubic board)". How is that stored?

**Decision:** Each entry is keyed by the canonical form of its position — the smallest of the 192 images — with the move rewritten into that same orientation. `canonicalise` now returns the automorphism alongside the key, and `CanonicalForm.cellFromCanonical` turns the stored move back onto the real board.

**Rationale:** This is the same defect the ticket-025 review found in the transposition table, where a canonically-keyed entry carried an orientation-dependent best move and was quietly useless for ordering. There it cost only pruning; here it would be a wrong move, so the machinery to invert the automorphism had to be built rather than skipped. `symmetry.dart` — flagged in that review as having no production caller — is now load-bearing.

**Consequence:** Two independent checks that the keying is sound. The generator refuses to build if two dictionary lines that are the same position up to symmetry disagree about the move: **2929 entries produced 2929 distinct canonical positions, no conflicts.** And the book's twelve entries at ply 2 are exactly the twelve orbits of the remaining 63 cells under the stabiliser of the opening cell, which the engine's own automorphism table reproduces independently.

A subtlety worth keeping, because it made the first version of the test wrong: when a position has a non-trivial stabiliser, the canonical form is reached by more than one automorphism, and they can disagree about *which* of several interchangeable cells the stored move names. The test asserts that turning the board gives the same **resulting position**, not the same cell index. Same move in every way the game can tell.

---

### D176 — Two book opponents can only differ in the seat the book does not cover
**Question:** The Master tier is two opponents, Oracle at 2300 and Quadrim Prime at 2600. Both play the same book, and the book makes its holder unbeatable in the games it opens ([D173](#d173--perfect-play-is-first-player-play-and-the-perfect-opponent-still-has-to-play-second)). What can possibly separate them?

**Decision:** Only the **second seat**. Oracle searches with the Expert tier's machinery there — 1.8M nodes, five moves of defensive forcing search, no exact endgame. Prime uses the largest configuration in the catalogue — 3M nodes, nine moves of defence, a twelve-cell exact endgame. In the games they open they are the same opponent and neither can be beaten, and the catalogue text has to say so.

**Rationale:** Arrived at by eliminating two alternatives, both of which were built before being measured.

*A blunder rate.* Oracle first shipped with `blunderRate: 0.002` as a deliberate human-sized crack. An existing test caught it within the hour: the catalogue requires that blunder rate never rise as rating rises, and Oracle at 2300 was blundering more than Titan at 2100. The invariant is right and the design was wrong — a player who beats Titan and then meets a *more* generous opponent has been told something false about the ladder.

*A shallower forcing search.* The replacement gave Oracle eleven moves of forcing search against Prime's twenty, and a budget a sixth the size, on the theory that it would sometimes fail to finish what the book started. Measured over 200 games opening against random replies, the result was **byte-identical to Prime's**: same 636 book moves, 202 forcing-search moves, 203 immediate wins or blocks, same zero fall-throughs, same 200-0. The forced wins that follow the book are short enough that eleven moves find them exactly as reliably as twenty.

**Consequence:** This is the third negative result in a row from the same family — [D163](#d163--eight-plies-is-not-affordable-and-depth-is-not-the-reason-these-opponents-are-strong) (depth), [D167](#d167--teaching-the-evaluation-about-forks-did-not-make-it-stronger) (evaluation), and now forcing depth past the book. The pattern is consistent and worth stating plainly: **once an opponent can find short forced wins, giving it more of the same buys nothing.** What has ever moved this ladder is a different *kind* of knowledge — the defensive question ([D169](#d169--pointing-the-forcing-search-at-the-opponent-is-the-largest-strength-gain-measured)), and now the book.

It also means the 300 points between Oracle and Prime are a claim about half the games, and can only be earned by measurement in that half. Measured against Titan, twelve games each, alternating seats:

| pairing | result | the half that matters |
|---|---|---|
| Titan vs Oracle | 6-6 | Oracle's second seat won **0 of 6** |
| Titan vs Quadrim Prime | 3-9 | Prime's second seat won **3 of 6** |

Both book players win every game they open, so the aggregate score says nothing; the second-seat column is the whole measurement, and it separates them in the direction the design intended. Six games apiece is a small sample and the gap it supports is not precisely 300 points — but it is a real difference arising from a real mechanism (nine moves of defensive forcing search against five, which the Expert tier measured at 19-11 and 20-10 on its own), rather than the byte-identical non-difference the previous two designs produced. Ticket 014 turns the direction into a number.

The same run settles the move-time question the review raised, because the second seat is where the book stops answering and the whole budget gets spent: **Prime worst 7,017 ms, Oracle worst 7,543 ms, Titan worst 10,379 ms** — all inside the twenty-second ceiling of [D164](#d164--the-real-move-budget-is-twenty-seconds-on-device-not-a-quarter-of-a-second), with the largest configuration in the catalogue not being the slowest one in it.

**Quadrim Prime's rating moved from 2600 to 2400 on this evidence**, and the number is still generous. Measured against two anchors, twenty games each against Corvus:

| Prime against | aggregate score | implied rating |
|---|---|---|
| Corvus (1900) | 16-4, 80% | ≈ 2140 |
| Titan (2100) | 9-3, 75% | ≈ 2290 |

The two disagree by 150 points, and the disagreement is structural rather than noise. A rating predicts a single expected score, but this opponent has two modes: it cannot lose the games it opens, and it is a strong searcher in the others. Its second seat scored 6/10 against Corvus and 3/6 against Titan — sensible, monotone, and the only part of it that varies with the opposition. Against a *perfect* opponent the aggregate would be exactly 50%, which is to say Prime's rating is the ceiling of the ladder and anyone who reaches it draws.

**Oracle measures at 2100, not 2300**: 6-6 against Titan and 15-5 (75%, implied 2091) against Corvus — two anchors that agree closely. Its stated rating is the one in the catalogue least supported by measurement, and it is flagged for ticket 014 rather than changed here.

---

### D177 — The gate had quietly become a two-hour job, and the cause was a filter that never existed
**Question:** `tool/check.sh` had grown from minutes to roughly two hours. A gate nobody can afford to run is not a gate. Where did the time go?

**Decision:** Two fixes, one in the tests and one in the engine.

1. **`strategic_bot_test.dart`'s legality sweep is filtered to the opponents that decide in microseconds.** It iterated `opponentCatalogue` entire, 400 positions each. That was free when every opponent was rule-based; ticket 025 added four opponents budgeted in nodes and ticket 026 added two more, so the sweep became six searching opponents times four hundred positions times seconds a move.
2. **`deepSearch` stops deepening once the root is inside the exact-solving window.** Iterative deepening ran the same full exact solve at every depth, proving the identical result each time, because a proven answer cannot improve with depth.

**Rationale:** Measured rather than guessed, and the first two guesses were both wrong. Per-node allocation in `_orderedMoves` was the first suspect and is not the cost. The redundant exact solves were the second, and are real — but a single twelve-empty solve was measured at **155 ms**, so eighty of them could not account for the time either.

The mistake underneath both wrong guesses was misreading the test reporter. `dart test` runs files concurrently and prints the elapsed time of the **suite** against whichever test is currently active, so a line reading `106:45 … exact endgame solving` says the suite has been running 107 minutes, not that this test has. The slow thing was in another file entirely.

| | engine tests |
|---|---|
| before | 106+ minutes |
| after | 108 tests in 2 min 26 s |

**Consequence:** This is the second sweep in three days found running opponents it was written to exclude. The first, in `bot_test.dart`, filtered on `searchDepth == 0` — a condition that stopped meaning anything the moment `nodeBudget` became the alternative way to spend a search. The second had no filter at all. Both were written when every opponent in the catalogue was cheap, and neither was revisited when that stopped being true.

The remedy applied to the surviving sweeps is to **derive the set from the catalogue rather than list it**: `deep_search_test.dart` now sweeps `opponentCatalogue.where((b) => b.nodeBudget > 0)` and asserts the result is not suspiciously small, so an opponent added later cannot escape it — which is exactly how the cheap sweep came to swallow the expensive ones.

The engine half of the fix is not only about tests. Titan and Quadrim Prime solve the endgame exactly in real play, and both were re-solving it once per iteration of the deepening loop.

---

### D178 — The engine suite had never finished, and a hang is not a failure
**Question:** Every full check in this session was started and never seen to complete. The logs told the story only in hindsight: of ten runs, exactly one wrote an exit line, and that one failed early on app tests before it ever reached the engine. Why did nobody notice?

**Decision:** Three fixes, and a change of habit.

1. **`SearchLimits` now asserts `exactEmpties <= 16`.** A test passed **64** — "always solve exactly" — from a six-move position with **58 cells empty**. Exact solving has no horizon and no budget it will abandon; that request is an instruction to solve Qubic, and it never returns.
2. **The test asks for something finishable.** It now takes endgames of ten empty cells, checks the score is a proof rather than an estimate, agrees with the independent solver, and asserts `depthReached == 1` — which also pins the [D177](#d177--the-gate-had-quietly-become-a-two-hour-job-and-the-cause-was-a-filter-that-never-existed) fix in place.
3. **`_endgames` tries 1500 times instead of 60.** A position with ten cells left and no completed line means neither side won for fifty-four plies, which Ember rarely allows. Sixty attempts yielded one or two where the callers wanted five, and the resulting assertion failures read as complaints about the solver rather than about the fixture. Each attempt is one fast self-play game.

**Rationale:** The habit is the real finding. **A hang produces no failure to read.** A failing test announces itself; a hanging one looks exactly like a slow one, and every instinct — wait a bit longer, the endgame tests are expensive — points away from the truth. It survived from ticket 025 through five more tickets because the run never got far enough to produce a verdict, and "still running" was accepted as a state rather than investigated as one.

Three wrong diagnoses were reached before the right one, and each was wrong in a way worth remembering:

- *Per-node allocation in `_orderedMoves`.* Plausible, unmeasured, wrong.
- *Redundant exact solves under iterative deepening.* Real, and fixed as D177 — but a single twelve-empty solve measures at **155 ms**, so eighty of them could never have explained hours. A true finding that was not the finding.
- *Orphaned processes exhausting the machine.* Thirteen were cleared; the next run wedged at the identical point. Reproducibility was the clue that should have come first.

What finally worked was refusing to read the reporter as prose. `dart test` prints the **suite's** elapsed time against whichever test is currently active, so `106:45 … exact endgame solving` says the suite has been running 107 minutes and that this test is the one running now — not that this test took 107 minutes, and not that the previous line's test was to blame.

**Consequence:** Every long-running command now carries a hard `timeout`, so a wedge ends as a non-zero exit rather than as silence. The engine suite went from never finishing to **19 tests in 22 seconds**, and `tool/check.sh` reached `ALL CHECKS PASSED` for the first time since ticket 025.

The uncomfortable part is worth writing down plainly: several tickets were reviewed, decided, and recorded on the strength of a suite that was never observed to pass. The tests themselves were sound — when finally run, three genuine fixture failures surfaced immediately and were fixed — but the confidence placed in them during that period was not earned.

---

## 40. Ticket 029 — placeholder art and opponent content

### D179 — Tier is stored on the opponent, not computed from its rating
**Question:** The five tiers occupy contiguous rating bands: Novice 600–900, Casual 1000–1300, Club 1400–1700, Expert 1800–2100, Master 2300–2400. A one-line function of `rating` would produce the tier for all twenty and need no data at all. Why carry a field?

**Decision:** `BotTier` is a stored field on `BotConfig`, defaulted rather than required, and the twenty are pinned by `catalogue_test.dart`.

**Rationale:** The bands are contiguous *today*, and the whole point of ticket 014 is that they might not stay that way. Deriving the tier would mean a recalibration silently reclassifies an opponent — move Titan to 2150 and it is still Expert, move it to 2250 and it has quietly become a Master without anybody deciding so. Ticket 011 also asks that tier and rating render independently, so that an opponent whose number is not yet trustworthy can show its tier alone; a derived tier cannot do that, because it *is* the number.

The field was briefly `required`, which broke thirteen call sites — every one of them a synthetic configuration in a test or in `tool/`, none of them on the ladder. That is the signal that `required` was the wrong instrument: it forces a fixture to name a band that means nothing for it, and it only guarantees that a catalogue entry names *a* tier, never the right one. What guarantees the right one is a test that writes the expected mapping out by hand and compares. So the field is defaulted and the test is the gate.

The test deliberately does not derive its expectation from `opponentCatalogue`; a test built from the thing it is checking agrees with itself forever. It also asserts the tier *counts* separately from the per-opponent mapping, because a pair of compensating typos would satisfy the mapping alone.

### D180 — The book belongs to the Master tier and nowhere else
**Question:** `usesBook` is a flag any catalogue entry could set. What stops a future edit from handing the dictionary to a mid-ladder opponent?

**Decision:** A catalogue test asserts that every book-holding opponent is in `BotTier.master`, and that exactly two hold it.

**Rationale:** An opponent with the book cannot be beaten in the games it opens. On the Master tier that is the point; on the Club tier it would mean a player rated 1400 meets something unbeatable half the time and has no way to understand why. The ladder stops being a ladder. This is the kind of invariant that is obvious while it is being written and invisible six months later, which is exactly the kind worth spending three lines of test on.

### D181 — Oracle and Prime say "unbeatable when it moves first", never "perfect"
**Question:** Both Master opponents now hold a dictionary that proves a first-player win. Three tickets, the specification and the design handoff all still said Prime must be described as "extremely strong, not perfect" — wording written when the book was expected to arrive at 1.0. The book arrived early. What should the player be told?

**Decision:** The blurbs state the asymmetry outright. Oracle: *"Opens from a proven winning strategy and cannot be beaten when it moves first. Moving second, it is only very strong."* Prime: *"The strongest opponent here. Unbeatable when it moves first; when it moves second it defends by the deepest calculation in the game."* Every document carrying the old wording was corrected to match.

**Rationale:** Three descriptions were possible and two of them are wrong. "Perfect", flatly, is **false** — the proof covers the opening player only ([D173](#d173--perfect-play-is-first-player-play-and-the-perfect-opponent-still-has-to-play-second)), and a tester who takes the first move and beats Prime has caught the app lying about itself. "Extremely strong", the old wording, is now merely **incomplete**: it hides something true, interesting, and discoverable — a player who loses every single game as second player deserves to know that this is a property of the opponent rather than of their own play.

Stating the asymmetry also makes the seat a real decision. Choosing who opens is already in the game; against these two it becomes the difference between a contest and a demonstration.

The stale wording had spread to five files — tickets 011, 026 and 029, specification §4.2, §8.5 and §11.7, and the design handoff — which is the ordinary cost of a plan changing under documents that describe it. It is recorded here rather than quietly fixed because the same thing will happen again the next time an open item resolves early. The decision log's own history was left alone: entries record what was decided when, and rewriting them would destroy the only account of how the project got here.

### D182 — Avatars are drawn from the opponent's id, not shipped as files
**Question:** Twenty placeholder avatars, at closed-test quality and no higher. Twenty PNGs at several densities, or something generated?

**Decision:** Drawn at run time by a `CustomPainter` from an FNV-1a hash of the opponent id — a mirrored 5×5 identicon whose glyph shape also varies. No asset files.

**Rationale:** Zero binary assets to commission, store, or keep in step with the catalogue: an opponent has an avatar the moment it has an id, and no avatar can drift out of sync with the roster because there is nothing to drift. It is also unmistakably placeholder, which the ticket asks for twice.

Identity is carried by **pattern and glyph, not colour** — the ticket requires avatars to be distinguishable without relying on colour, and a hue-only scheme fails that for the roughly one man in twelve with a colour vision deficiency. The tier is the one thing colour encodes, and it encodes it as a ring *width* as well as a hue, so the five bands survive greyscale too.

`String.hashCode` was not used: it is unspecified across Dart releases, so every avatar in the app could change when the toolchain did, and the resulting bug report would be unreproducible. FNV-1a is eight lines and pinned by a test with literal expected values.

Two properties are tested rather than eyeballed: that no two of the twenty produce the same pattern, and that none is nearly blank or nearly solid. Distinctness alone is not legibility — one lit cell and twenty-four lit cells are technically different and both unreadable. The bit arithmetic lives in one top-level function that both the painter and the tests call, because a duplicated copy would let the tests keep passing while checking a pattern nobody sees.

**Both legibility measures were wrong on the first attempt, and the review caught them.** The metric counted cells in the three *master* columns, but the last of those is the mirror spine and paints once where the other two paint twice. Mote's three lit cells all fell on the spine, so it scored 0.20 — identical to any other three-cell avatar — while drawing **three** marks on a face of twenty-five against a busiest of nineteen. Rendering the twenty as a contact sheet and looking at them is what exposed it; no amount of staring at the number would have.

The floor was wrong in a second, more embarrassing way: it was set to `0.2`, which is exactly what the sparsest avatar measured. An assertion fitted to its own sample cannot fail, and this one could not. It read as a safety margin and was not one.

Both are fixed. `avatarInkCells` counts what is painted, weighting the spine at one and the mirrored columns at two; the band is 6 to 21 of 25, chosen as a judgement about a 5×5 face rather than read off the roster, and the twenty now span 7 to 19 with real margin at both ends. A salt, `avatar-v1`, moves the roster off the pattern set that contained the unusable one — it is a tuning constant, and it is explicitly **not** what makes the avatars legible. The test is. If a future opponent lands outside the band, the test fails and the constant gets picked again.

### D184 — A missing Dutch string now fails the build
**Question:** `tool/check.sh` runs `flutter gen-l10n`, and ticket 029 added forty translated strings. What happens if the next ticket adds one to `app_en.arb` and forgets `app_nl.arb`?

**Decision:** `l10n.yaml` gains `untranslated-messages-file: untranslated.json`, and the gate fails when that file names anything.

**Rationale:** Verified rather than assumed: adding one key to English only and running the gate's own command, `gen-l10n` prints a suggestion that the option exists and **exits 0**. Nothing else objects, and a Dutch player is silently served English for that string — the failure is invisible in every language the developer reads.

Ticket 029's own strings were already safe, because `opponent_content_test.dart` enumerates `opponentCatalogue` and demands a blurb per opponent per language. But that protects blurbs, not strings in general, and tickets 021 and 028 each add many. A gate that covers the category is worth more than a test that covers this ticket.

The check was proved in both directions before being committed — red with a deliberately untranslated key naming it, green once removed. A gate nobody has watched fail is not known to be a gate; that lesson is [D178](#d178--the-engine-suite-had-never-finished-and-a-hang-is-not-a-failure) and it applies to checks as much as to suites. Two other assertions written this session went the same way: the "avatars announce nothing" test passed unchanged when the avatar was deliberately given a spoken label, twice, in two different wrong forms — `find.byType(Semantics)` as a descendant matched structure rather than content, and `tester.getSemantics` walks *up* to an ancestor node and so never saw a label attached below it. Only `find.bySemanticsLabel` actually goes red. Every assertion added here was mutation-checked before it was believed.

### D183 — The icon generator runs by hand, and is not in the gate
**Question:** `tool/check.sh` verifies that every generated file is current. The app icon is now generated too. Should it join them?

**Decision:** No. `tool/icongen.py` is run by hand, its output is committed, and the gate does not check it.

**Rationale:** The other generators are Dart and run on the toolchain CI already installs. This one needs Python and Pillow. Adding them to CI would trade a real check for a new way for the build to fail, and the thing being guarded barely moves — the icon changes when somebody decides it should, which is roughly never, and 0.2 replaces it with real art regardless. The script is committed so the icon is reproducible rather than a mystery PNG.

Android adaptive icons were skipped for the same reason they are not in the ticket: the Play Store requires a 512×512 listing icon and launcher icons at five densities, and that is what exists. Adaptive icons are a recommendation, and 0.2 owns real art.

---

## 41. Ticket 011 — opponent selection

### D185 — A fair match is an expected score, not a rating gap
**Question:** The ticket asks that opponents far above or below the player be visually distinguishable from a fair match. Distinguishable by what rule? The obvious one is a rating difference — say, 200 points.

**Decision:** `matchBalance` lives in `quadrim_rating` and is defined on `expectedScore`: at or below 0.25 the opponent is far stronger, at or above 0.75 far weaker, and in between the match is even.

**Rationale:** A gap in points does not mean the same thing everywhere it is measured, but an expected score does — it is the probability the player scores, which is exactly the question "is this a fair game?" asks. Two hundred points is two hundred points at either end of the ladder, and phrasing the rule that way would have been *accidentally* right here only because ELO's own curve is what makes it so. Saying it in the currency the rating system already speaks removes the coincidence: `matchBalance(600, 800)` and `matchBalance(2200, 2400)` are the same answer by construction, and there is a test that says so.

It also put the rule somewhere it can be tested without a widget. This is a presentation *decision* but a rating *calculation*, and the pure package is where calculations live in this project — five tests cover the bands, their symmetry, and the boundary, none of which needed Flutter to run.

A quarter was chosen over a third: it is about 190 rating points, nearly two rungs of this ladder. At a third the bands would be roughly 120 points and most of the roster would be marked a mismatch for most players, which tells them nothing.

**The cue is never colour alone.** Each row carries an icon and a phrase as well as a colour, because roughly one man in twelve would not see a red-versus-green distinction, and the criterion is that the difference be *distinguishable* rather than merely present. That is the same reasoning as the avatars ([D182](#d182--avatars-are-drawn-from-the-opponents-id-not-shipped-as-files)) and it will be audited again in ticket 021.

### D186 — One opponent, one announcement
**Question:** Each row shows a name, a tier, a rating, a blurb and a match cue. A screen reader meets those as five separate nodes by default. Is that right?

**Decision:** The row is a single semantics node whose label is `{name}. {tier}. Rating {rating}. {match}. {blurb}`, with its children excluded.

**Rationale:** Five nodes per opponent is a hundred stops to read a list of twenty, and the pieces do not mean anything apart — "Club" and "1650" are only useful attached to the name they belong to. The composite is a translated message with placeholders rather than a string built in code, so a language that orders those facts differently can say so.

This is the same shape the rating card on the home screen already uses, and the reason is the same one recorded there: a container label plus `ExcludeSemantics` beats letting the framework improvise.

### D187 — Backing out of the opponent list cancels the game
**Question:** The player taps "New game", chooses "Play the computer", reaches the list of twenty, and presses back. What should exist afterwards?

**Decision:** Nothing. The flow cancels and no game is stored.

**Rationale:** The alternative — falling back to a default opponent so that the tap is not wasted — creates a game against somebody the player did not choose, which then appears in their history and moves their rating. That is worse than no game. It also removes the only sensible way out of the list for a player who opened it to browse.

The previous behaviour was the opposite by accident: before this ticket the mode sheet created a Pebble game immediately, because there was no list to send anybody to. A test asserted that, and it was updated rather than deleted — the behaviour it described was real and is now deliberately different.

### D188 — A fixed-height strip under an app bar title is a text-scale trap
**Question:** The player's rating sits below the screen title, in the `AppBar`'s `bottom` slot, at a reserved height of 28 logical pixels. What happens at the 200% font size Android's accessibility slider offers?

**Decision:** The reserved height scales with the text: `Size.fromHeight(MediaQuery.textScalerOf(context).scale(28))`. A test measures the title and rating rectangles at 1.0, 1.5 and 2.0 and fails if the title leaves the screen or the two collide.

**Rationale:** Measured, because the failure is silent. At 200% the text inside the strip is 40 pixels in a 28-pixel slot; the `AppBar` grows upward to fit it, and the title's top edge lands at **-1** — clipped by the screen — while the two strings overlap by half a pixel. **No overflow error is raised.** Neither widget is a flex, so Flutter does not consider anything overconstrained; it simply paints one over the other. The yellow-and-black stripe that normally announces this class of bug never appears, and a developer whose own font size is 100% will never see it.

That is what makes it worth a decision entry rather than a quiet fix. The whole category — fixed heights holding scalable text — fails without a diagnostic, so it cannot be found by running the app and looking. It has to be measured, and the measurement has to be kept. The test asserts positions rather than the absence of an exception for exactly that reason, and it was checked against the unfixed code before being believed: it reports `title clipped off the top at scale 2.0`.

Ticket 021 owns the accessibility audit and will sweep for the rest of the category. This one is fixed here because this ticket introduced it.

---

## 42. Interface revisions after seeing the screens on a device

### D189 — A game is one line, with the face of who it was against
**Question:** The main screen listed each game as a two-line `ListTile` — opponent on top, moves or result underneath — while the by-opponent breakdown directly above it put name and record on a single line. Two layouts, one screen.

**Decision:** Games use the by-opponent shape: avatar, name, and the game's state on one line. The avatar is 28 logical pixels, against 44 on the selection screen.

**Rationale:** The second line never carried anything the first could not hold. "3 moves played" and "Won" are short, they belong to the name beside them, and stacking them doubled the height of a list that has no upper bound — a dozen games ran past the bottom of the screen for no extra information. Matching the section above it also means the screen stops changing layout halfway down.

The avatar is deliberately smaller than the selection screen's. It rides a single line of text, and at 44 it would set the row height itself, which would undo the change that motivated this. A test asserts both that it is smaller than the selection default and that it does not drive the row height.

**Pass-and-play has no avatar.** There is no opponent behind the guest seat, so the slot falls back to a neutral icon rather than inventing a face for somebody who does not exist. The same applies to a stored game naming an opponent this build has never heard of — an older catalogue, or a newer one after a downgrade — which now has a test of its own, because the row resolves a configuration that can be null and would otherwise be a crash rather than a blank.

### D190 — The opponent list is an accordion, opened where the player stands
**Question:** Twenty opponents in five sections is a long scroll, and the ticket's own note says twenty is enough that presentation matters. Which section should be open when the screen appears?

**Decision:** One section at a time. It opens on the tier of the catalogue entry **nearest the player's rating**, and opening another closes the one that was open. Tapping the open one closes it, collapsing the screen to five lines.

**Rationale:** The five headings are the ladder, and a collapsed accordion shows the whole of it at once — which a twenty-row scroll does not. Opening on the player's own tier means the opponents they can actually get a game out of are the ones already on screen, and the rungs above and below are one tap away.

**The tier is found by asking who is nearest, not by a rating band.** A band table would have been the obvious way to write it and would have quietly undone [D179](#d179--tier-is-stored-on-the-opponent-not-computed-from-its-rating): tier is stored rather than derived precisely so a recalibration cannot reclassify an opponent, and a table of bands here would have to be kept in step with twenty ratings by hand. "Which opponent is closest to this number" needs no table and cannot fall out of step. It also behaves at both ends without special cases — the rating floor lands on Novice, and a player past Prime lands on Master.

Writing the tests found a real defect in the first version. `late BotTier? _open = tierNearest(widget.playerRating)` runs its initialiser once, so when Flutter reused the `State` with a different rating the section stayed where the *first* rating had put it. Today the screen is always pushed fresh and the rating cannot change underneath it, so nothing visible was wrong — but the widget was not honouring its own input, and `didUpdateWidget` now makes it. A latent bug of that shape is worth five lines: it fails silently and only under a rebuild nobody is looking at.

### D191 — One avatar slot, shared by every row that names an opponent
**Question:** The by-opponent breakdown sits directly above the game list and names the same opponents. Should it carry avatars too, and if so, should it build its own?

**Decision:** Yes, and no. Both sections use one `_OpponentAvatarSlot` widget.

**Rationale:** The two sections are stacked on the same screen and name the same opponents, so a face in one and not the other reads as an inconsistency rather than a distinction. More practically, the names have to share a left edge: two independently written slots drift apart the first time one changes, and the columns step in and out between sections that touch. A single widget makes that alignment structural instead of a coincidence, and a test asserts both left edges are one value.

It also puts the "there is nobody to draw" case in one place. Pass-and-play has no bot behind the guest seat, and a stored game can name an opponent this build has never heard of — an older catalogue, or a newer one after a downgrade. Both resolve to a null configuration, and the fallback icon belongs in the slot rather than duplicated at each call site.

### D192 — The record belongs in the rating card, not under a heading of its own
**Question:** The main screen had a "Your record" heading over a single line — "16 won · 3 lost · 0 drawn" — directly beneath a card showing the computer rating. Two blocks, one subject.

**Decision:** The record line moves inside the rating card, under the number. The heading goes.

**Rationale:** They are the same fold over the same games. The rating *is* what that record produced, and putting the two side by side says so; separating them implied a distinction that does not exist. A heading over one line of text is also a heading for nothing — it cost a section header, a gap above it, and a gap below, to introduce eleven words.

Two consequences worth recording. The card's screen-reader announcement had to grow to carry the record, or the line would have been spoken by nobody: it was already a `Semantics` container with `ExcludeSemantics` beneath it, so a string that moves inside without joining the label becomes silent. The test now asserts the announcement contains both the number and the record.

And `yourRecord` was deleted from both locale files rather than left behind. An unused key still gets read, translated and maintained, and the next person to see it has to work out whether it is dead or merely not rendered yet. Two lines are cheap to restore if a later screen wants the heading back.

---

## Appendix — session tooling

Not product decisions, recorded so the session is complete.

- **MemPalace was broken and was repaired.** The plugin (3.4.1) launched its MCP server via a `mempalace-mcp` command that the installed package (3.3.2) never shipped, so the server failed to start every session. The package was upgraded to 3.6.0, which installs the launcher and also fixes a crash in `mempalace status` caused by a chromadb SQL-variable limit when fetching all drawer metadata in one query. Two stale directories, `palace.bak-2026-07-22` and `palace.corrupt-2026-07-22`, remain at roughly 263 MB each and were left for the user to decide on.
- **The `to-spec` and `to-tickets` skills are marked user-invocation-only** and could not be loaded through the skill mechanism; their instructions were read directly. Both were followed with two deliberate deviations, in each case on explicit instruction: clarifying questions *were* asked (both skills say not to), and output went to files rather than to an issue tracker (none is configured).

---

## Open items — all steps

These are unresolved facts that need discovery work, not further product decisions.

### OI-01 — Push notifications on desktop and web
Firebase Cloud Messaging does not support Flutter Windows or macOS. Web push works only in browsers that support it and requires an explicit permission grant; on iOS Safari it requires the site to be installed to the home screen. **Position:** push is a mobile feature. Web and desktop degrade to in-app notifications and a badge on the active-games list while the app is open. This must be stated in the UI so a desktop-only player is not silently timed out by D16.

### OI-02 — Strategy book size and solver effort
The perfect-play book (D24) has no known size until the solver is built. The solver is a build-time tool, likely not written in Dart, and is a genuine sub-project. **Mitigation:** the fallback ladder in Idea-final.md — book if practical, otherwise exact endgame plus deepest achievable search, with the top bot's rating and description adjusted honestly rather than overclaiming perfection.

### OI-03 — Bot rating calibration
The 20 fixed anchor ratings (D18) are currently estimates. They must be calibrated by round-robin self-play to establish relative ordering, then pinned to absolute values with human test games. Publishing a mis-calibrated anchor and correcting it later invalidates every rating derived from it.

### OI-04 — Auto-match cold start
ELO-based auto-matching (D21) needs a player population that will not exist at launch. **Mitigation:** the queue should offer a computer opponent of matching strength after a short wait rather than leaving the player waiting on an empty queue.

### OI-05 — Firebase cost model
Async play with four notification triggers, per-move validation functions, and a scheduled expiry sweep has a per-game function-invocation cost that has not been estimated. Worth a back-of-envelope check before launch, not before coding.
