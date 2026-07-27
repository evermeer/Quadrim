# Quadrim — Decision Log

Every decision taken while turning [IDEA.md](IDEA.md) into [Idea-final.md](Idea-final.md).
Each entry records the question, the decision, and what it costs or buys.

Date: 2026-07-27
Status: agreed, pre-implementation. No code written.

---

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

## Open items

Decisions are complete. These are unresolved facts that need discovery work, not further product decisions.

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
