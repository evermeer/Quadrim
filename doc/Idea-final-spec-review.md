# Quadrim — Expert Review of the Specification and Tickets

Review of [Idea-final-spec.md](Idea-final-spec.md) and the tickets in [tickets/](tickets/), by three specialist reviewers.

Original review: 2026-07-29 — 43 concerns, 54 recommendations.
**Updated 2026-07-29** after the private-release and clean-start change ([idea-decisions.md](idea-decisions.md) Step 7, D84–D91).

**Status: 27 of 43 concerns resolved. 16 remain open and are the substance of this document.**

Resolved findings have been removed rather than kept as noise; §3 lists what they were and how each was closed, so the record survives without the detail.

---

## 1. How this was run

Three reviewers — backend architecture, application security, product management — each read the specification and all tickets.

Because reviewers cannot question the user directly, the review ran in two phases. Each first returned only the clarifying questions it needed before it could review rigorously. All eighteen questions were answered and recorded as decisions D66–D83. The reviewers then produced their findings against those answers.

That sequencing matters for reading the result: **several of the most serious findings were defects in the answers themselves**, not in the original documents. Those answers were subsequently superseded by Step 7, which is why so much of the review is now closed.

| Reviewer | Original | Remaining open |
|---|---|---|
| Backend architecture | 13 | 4 |
| Application security | 19 | 9 |
| Product management | 11 | 3 |
| **Total** | **43** | **16** |

---

## 2. The one change that closed most of it

Releases 0.1 and 0.2 became private — friends and family only, via closed testing and TestFlight — and 0.3 starts with an empty database. No offline history is ever uploaded.

That removed an entire category of risk rather than mitigating it. There is no import endpoint, no migration to make resumable, no client-authored data crossing a trust boundary, no device identity to generate or protect, and no launch-day cost burst. **Eleven findings ceased to be possible.** Sixteen more were fixed by edits to the documents.

The distinction matters for what can regress: dissolved findings cannot come back without reversing D84 or D85. Fixed findings can come back if an edit is undone.

---

## 3. Resolved — the record

### Dissolved by the clean start (cannot recur without reversing D85)

| Finding | Was |
|---|---|
| Identity scheme and security rules contradicted each other | **Critical** — rules only see `request.auth.uid`, which cannot match an array of `player:` uuids without a billed read per evaluation. No 0.1 document now reaches Firestore |
| 0.3 was less durable than 0.1; declining the upload destroyed history | **Critical** — local storage is never retired now |
| Re-validation proves legality, not authenticity | **High** ×2 (backend + security) — no import channel to fabricate into |
| Import was an unmetered function amplification surface | **High** — no import endpoint |
| "Ownership" of a client-generated uuid was undefinable | **High** — no uuid exists |
| Backup restore cloned the uuid onto two devices | **High** — no uuid to clone |
| Game id format determined migration idempotency | **High** — no migration |
| Derived statistics were an unbounded cloud read | **High** — offline history stays local and small |
| Imported history collapsed the completed-games ordering | **Medium** — no import |
| Migration burst was the real cost exposure | **Medium** — this was the answer to OI-05; the burst is gone |
| The client move id was redundant | **Low** — removed entirely, along with per-move author, index and timestamp |

### Fixed by edits

| Finding | Fix |
|---|---|
| Four shipped artefacts claimed "no data leaves the device" | §2 rewritten, §9.12 added, ticket 022 forbids the phrase. **The underlying declaration question survives as OI-06 below** |
| The tutorial practice game had nowhere to hide | Never stored at all — in memory for the tutorial's duration (§9.5, ticket 020) |
| No ticket owned the settings document; criterion T7 could not pass | Settings folded into ticket 005; tutorial completion persisted there (D91) |
| "Second session unprompted" was unobservable | Replaced with day-3 and day-10 statistics screenshots (new ticket 024) |
| Thresholds had no stated consequence | Consequences pre-committed in ticket 024 and gated in §11.6 R9 |
| 0.2 had unbounded scope once its bots were deferred | Now exactly iOS build, App Store submission, and fixes the closed test demanded (§4.1) |
| Testers would anchor only the bottom of the opponent ladder | Anchor low, chain high from measured gaps, record the chain (§12.3, ticket 014) |
| The competitive premise had no evidence | Now an acceptance criterion on ticket 004, before the board design is fixed |
| The tutorial was scheduled after the upload it justified | Ticket 018 blocks ticket 016 |
| "A lost keystore cannot be recovered" was half wrong | Corrected in §9.13 and ticket 015 — Play App Signing can reset an upload key |
| Firestore region was a missing irreversible decision | Added as the third entry in §9.13 |
| The superseded identity scheme was still in the documents | Documents updated; the scheme itself no longer exists |
| 0.3 was a cliff with no layer-proving step | Split into 0.3a (private) and 0.3b (first public release) — **reduced, not eliminated; see §5** |
| Milestone loop risked being treated as having solved retention | 0.1 is now explicitly positioned as a private test vehicle, which is the positioning the finding asked for |
| 14 deferred bots would enter a live rating scale | Still true, now explicit — moved to 0.6, with ticket 014 required to calibrate against frozen anchors |
| OI-05 was unestimated | Sized: steady state ~250 games/day inside the free tier; the burst that mattered is gone |

---

## 4. Open — backend architecture

**1. The validating trigger creates a write-back loop and an illegal-move visibility window.** *High.*
A Firestore trigger fires *after* the client write lands, so an out-of-turn or illegal move is already in the document and already pushed to the opponent's listener for the trigger's lifetime. The trigger's own write re-fires the same trigger unless explicitly guarded — unguarded, it recurses until retry limits stop it — and every legitimate move costs two writes plus an invocation instead of one.
*Conditional on OI-10: if server-side validation is deferred to 0.4, this moves with it.*

**2. Client-chosen document ids let one account overwrite another's game.** *High.*
Without an explicit create rule asserting the document does not already exist, and an update rule gated on membership, an authenticated client can write over any id it can name. **This cannot be added defensively later — rules are the only gate.** Simpler now that 0.3 designs its own id scheme from scratch, but not automatic.

**3. Fourteen opponents will be introduced into a live rating scale.** *Medium.*
Computer ratings are fixed permanently once published. Moving the remaining fourteen to 0.6 means they can only be calibrated *relative to* the six already frozen. Recorded in §12.3 and required of ticket 014, but it remains a real constraint rather than a solved problem.

**4. Android backup will restore Firebase state it should not.** *Medium.*
Backup covers everything in app data, which at 0.3 gains Firebase auth persistence and FCM registration state. A restore produces two installs believing they are the same installation — stale tokens delivering "your turn" to the wrong device. §9.12 and ticket 001 now require an allowlist rather than the default; the specific exclusions still have to be written when 0.3 adds them.

---

## 5. Open — application security

**1. Firebase auth material in the backup is account takeover.** *High.*
The backup decision was made in 0.1, where the directory holds only game JSON. At 0.3 it gains a persisted refresh token. A backup restored to a second device arrives **already signed in**. The allowlist exists now; the exclusion must be written against the actual storage locations, which need checking against current Firebase documentation rather than assumed.

**2. Account deletion leaves three residues the tombstone does not reach.** *Medium.* → OI-09
Head-to-head pair aggregates (the opponent keeps seeing "your record vs X: 3–1"), reports authored *about* the deleted user (third-party personal data with its own basis and retention), and the Firebase Auth user record itself (a separate API call). Also: the tombstone must be **randomly generated per game at deletion time** — anything derived from the identity re-links every game they ever played.

**3. Controller identity means publishing a real address.** *Medium.* → OI-07
GDPR Art. 13(1)(a) requires the controller identified with contact details, and Play separately requires a publicly displayed address for individual developer accounts — for a solo developer, a home address. The realistic Dutch mitigation is a KvK eenmanszaak with address shielding. Ticket 015 now carries a check; the answer is not yet known.

**4. Rate limits have no stable subject to count.** *High.* → OI-08
Per-pair caps kill two-account boosting but do nothing against N throwaway anonymous accounts, because each is a fresh pair. Firebase anonymous auth gives you IP — rotatable — and nothing else. Without an attestation mechanism such as App Check backed by Play Integrity, the account-creation limit counts a value the attacker controls.
*Mitigating, and worth stating: ELO's own maths blunts the naive attack — beating a fresh provisional account gains about one point — and §5.2 permanently rules out leaderboards, seasons and tournaments, so there is nothing to spend an inflated rating on. This becomes real at 0.4's auto-match.*

**5. The repeat-matchup cap attacks the app's own retention loop.** *Medium.* → OI-08
Ticket 007 calls rematch "the cheapest retention mechanism the game has", with alternating starts specifically so a *series* is fair. A rematch chain hits the per-pair cap immediately, as do the friends loop and invite links. **Two friends who play only each other are the modal social user, and their games stop counting.** The security control and the primary engagement pattern are the same behaviour.
Proposed shape: make the cap a *visible product behaviour* — "unrated: you've played this opponent N times this week", shown before the game starts — and set N against the rematch loop rather than an attacker model.

**6. Integrity events are personal data defined nowhere.** *Medium.*
Recording a suspected-abuse event attached to a person creates a record with no shape, access rule, retention period, or home in any document. If accumulation ever triggers an automatic sanction, GDPR Art. 22 puts human review and a contest path on the table.
*Conditional on OI-10.*

**7. The content rating questionnaire silently sets the 0.4 chat regime.** *Medium.*
A clean abstract board game is exactly what gets classified as appealing to children. A declared audience including under-13s makes 1:1 free-text chat with strangers effectively unshippable at 0.4, and GDPR Art. 8 (Netherlands: 16) applies to the account. Ticket 016 now requires the reasoning to be recorded — but the answer is given in 0.1, three releases before it bites.

**8. Creating a game is opening a chat channel.** *Medium.*
Chat permission derives from game membership, so whoever can put your id into a game can talk to you. Combined with invite links and open challenges, unsolicited contact is created by game *creation*, not by message send. The block check therefore belongs in the game-creation path, not only the message-write path. Nothing in §4.1's 0.4 row or any ticket carries this yet.

**9. No data export path anywhere.** *Low.*
GDPR Art. 15 and Art. 20 both apply from 0.3b. The documents are already JSON with a schema version, so this is nearly free designed in and annoying retrofitted — a function that packages what the deletion function would delete.

---

## 6. Open — product management

**1. 0.3 remains the most likely place this stops.** *High — reduced from Critical.*
The 0.3a/0.3b split gives it a layer-proving step and a private first landing, and 0.1 and 0.2 do now ship to real people via closed testing and TestFlight. What remains: 0.3a is still the first encounter with auth, Firestore and security rules simultaneously, and it is the release with the least visible reward for the effort.

**2. 0.1 is a finite checklist with a terminal state.** *Medium — reduced from High.*
Six opponents, twelve milestones, one tutorial. Nothing regenerates. This is now the correct amount of product because 0.1 is explicitly a private test vehicle — but it means the survey in ticket 024 is doing real work, and its thresholds must not be reinterpreted after the fact.

**3. Offline history does not survive a platform switch.** *Medium.*
Android backup is Android-only. With offline history never syncing, a player moving to iOS loses it entirely — and at 0.3b a player invests in a rating held by an anonymous account with no recovery credential. §12.2 now states the limitation; the app still needs to say it at the moment it matters, which is before the first *rated* game, not in a settings screen nobody opens.

---

## 7. The one conflict still unresolved — OI-10

**Should server-side move validation be in 0.3b at all?**

**Product says remove it.** Compute ELO client-side under Firestore rules at 0.3b; defer the TypeScript function, the shared corpus wiring and the drift-prevention machinery to 0.4. Its argument: a determined cheater can inflate a rating in a free app with no leaderboards, tournaments, seasons or prizes — §5.2 removes all of those permanently. Taking a second language and a second rules implementation off the critical path to first online play is the largest de-risking available.

**Backend and security both assume it is present.** Backend's open findings 1 and 2 are about how the trigger behaves; security's findings 6 and much of its trust model rest on it.

§4.1 currently places it at **0.4**, which is Product's position. Three open findings above are conditional on that staying true.

A middle path neither reviewer proposed: adopt the deferral, and make 0.3b's ratings explicitly provisional and recomputable. Every game stores its complete move list, so ratings can be recomputed from scratch once validation exists.

---

## 8. Must be verified externally — do not reason about these

These cannot be answered by inference and must be checked against current sources before the relevant gate.

| Question | Gates |
|---|---|
| Does current Play Data Safety guidance require declaring Android Auto Backup transfers? Two threads plausibly exempt it — "collection" meaning transmission to the *developer*, and the exemption for end-to-end encrypted data (backup on Android 9+ with a lockscreen is encrypted with the device secret) | Ticket 016, R5 → OI-06 |
| Does Play require a privacy policy for every app regardless of declared collection? | Ticket 016 → OI-06 |
| Play's public address requirement for individual developer accounts, and whether a KvK registration with *afscherming* satisfies it | Ticket 015, 0.3b → OI-07 |
| Exact on-device storage locations of Firebase Auth and Installations data, to write the backup exclusion correctly | 0.3a |
| Whether the ePrivacy Art. 5(3) "strictly necessary" exemption covers cloud-backing-up game history. Storing locally is clearly necessary; copying to a cloud service the user did not request for that purpose is weaker — **the strongest argument for making backup a visible toggle rather than a silent default** | Ticket 001 |

Misdeclaring Data Safety is a policy-violation removal, not a warning. That asymmetry is why these are listed separately from everything else.

---

## 9. Suggested order of response

**Before ticket 001:** the backup allowlist, including whether to allow device-to-device transfer while excluding cloud backup.

**Before ticket 004:** the competitor scan — its only purpose is to constrain the board design, and only while that is still free.

**Before ticket 016:** the survey instrument and its pre-committed consequences; the Data Safety and privacy-policy verifications; the target-audience declaration, which silently sets the 0.4 chat regime.

**Before 0.3a is specified:** decide OI-10, since it determines whether 0.3 needs TypeScript at all; and the Firestore region, which is irreversible.

**Before 0.3b:** deletion residues, rating anti-abuse and its collision with the rematch loop, the export path, and the controller-address question.

---

## 10. Still unresolved after this review

- **Who the twelve testers are.** Ticket 016 requires all twelve to install and open the app, and no document identifies a source. A hard external dependency, on a solo developer with no stated audience, gating everything downstream. → OI-11
- Whether the fourteen deferred opponents ever ship. Once online play exists, twenty fixed-strength opponents compete with the thing that made the roadmap worth building. That may be the right outcome, but it should be a decision rather than a drift
- **Onyx's actual strength against a competent human remains an estimate.** G3 asserts it; nothing in the plan tests it, and twelve recruited beginners will not
- What happens if the day-10 screenshots show near-zero return play. Ticket 024 pre-commits "go straight at 0.3a", which is a schedule answer to what is really a positioning question: whether an offline Qubic with a good board is worth publishing on its own terms even if nobody returns to it
