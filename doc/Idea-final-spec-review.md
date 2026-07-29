# Quadrim — Expert Review of the Specification and Tickets

Review of [Idea-final-spec.md](Idea-final-spec.md) and the 22 tickets in [tickets/](tickets/), by three specialist reviewers.

Date: 2026-07-29
Status: findings delivered. **No recommendation here has been accepted.** All of them are proposals until folded into the spec and tickets.

---

## 1. How this was run

Three reviewers — backend architecture, application security, product management — each read the specification and all 22 tickets.

Because reviewers cannot question the user directly, the review ran in two phases. Each reviewer first returned only the clarifying questions it needed answered before it could review rigorously. All eighteen questions were put to the user and answered; those answers are recorded as decisions **D66–D83** in [idea-decisions.md](idea-decisions.md). The reviewers then produced their concerns and recommendations against those answers.

This matters when reading what follows: **several of the most serious findings are defects in the answers themselves**, not in the original documents. The review was given a moving target and correctly shot at where it landed.

### Volume

| Reviewer | Concerns | Recommendations |
|---|---|---|
| Backend architecture | 13 (2 Critical, 5 High, 5 Medium, 1 Low) | 17 |
| Application security | 19 (1 Critical, 7 High, 9 Medium, 2 Low) | 22 |
| Product management | 11 (1 Critical, 4 High, 6 Medium) | 15 |
| **Total** | **43** | **54** |

---

## 2. Read this first — four Critical findings

### C1 — Two decisions from the same round contradict each other
*Backend, Critical.*

D66 puts `player:<uuid>` in documents and keeps the Firebase uid on the profile. D68 says rules authorise via `array-contains` on `participantIds`. **Firestore security rules only ever see `request.auth.uid`.** The only expressible rule is `get(/profiles/$(request.auth.uid)).data.playerId in resource.data.participantIds` — a billed document read on *every* rule evaluation, on every listener snapshot, plus a hard ordering dependency that the profile exists and is readable before any game can be touched.

Left alone, this ends in exactly the outcome D66 was chosen to avoid: reversing the identity decision at 0.3 and rewriting every imported document.

**Fix, preserving both decisions:** add a server-populated `memberUids` array at 0.3 for rules and queries. `participantIds` stays the ordered domain identity that `by`, `startingParticipant` and `result.winner` index into. 0.1 writes nothing new.

### C2 — 0.3 is less durable than 0.1, and declining the upload destroys history
*Backend, Critical. Independently reached by Product (concern 5).*

Firebase anonymous auth holds the uid in app-local state only. D67 retires local storage after the opt-in upload — so an uninstall, factory reset, or device change before any durable credential exists loses everything, silently. **0.1 with auto-backup on is strictly more durable than 0.3 after migration.**

Separately, D67 says nothing about the user who *declines*. As written they either keep local storage forever (the composite repository that decision rejected) or lose their history. User story 31 and the entire identity scheme exist to guarantee this cannot happen.

**Fix:** local files are deleted only after a per-game server acknowledgement *and* only once a durable credential exists — retirement gates on account upgrade, not on upload success. Declining keeps the app fully offline-capable; those games simply never sync.

### C3 — Three shipped artefacts now contain false statements
*Security, Critical.*

With auto-backup on (D72), the player uuid, every game document, the full move history and settings are transmitted to Google's servers into the user's Drive. These four statements are now factually wrong:

| Location | Claim |
|---|---|
| §2 | "no accounts, no network, and therefore no compliance surface" |
| §11.6 R5 | "declares no data collection" |
| ticket 016 | "with no accounts, no network and no analytics, it declares no data collection" |
| ticket 022 | "accurately stating that no data leaves the device" |

Whatever the Data Safety form turns out to require, **"no data leaves the device" in a published privacy policy is a false statement of fact** — and that is the sentence a data protection authority or a Play policy reviewer reads.

### C4 — 0.3 is a cliff, and the most likely place this project stops
*Product, Critical.*

0.3 lands, in one release, every technology never used before: anonymous auth, Firestore, security rules, a second rules implementation in TypeScript (D39), push, account deletion, a published privacy policy, and now a history upload with local storage retirement.

D37 recorded that two unfamiliar stacks cannot be learned at once with no working system to validate against. D44 claimed the plan adopts "the layer-proving discipline of the walking skeleton". **Nothing in the ladder actually schedules that layer-proving step.** After 22 tickets of steady familiar progress, the developer meets a release with no demoable milestone for many weeks — precisely where the roadmap's value begins.

**Proposed fix:** split into **0.3a** (anonymous auth + a Firestore `GameRepository` passing the *identical* Seam B flow tests as the local one + one async game between two of the developer's own devices; no push, no ELO, no functions) and **0.3b** (everything else). 0.3a ships to the same closed track.

---

## 3. Where reviewers agreed independently

Convergence between reviewers who could not see each other's work is the strongest signal in this document.

| Finding | Found by |
|---|---|
| Server-side re-validation proves **legality, not authenticity** — a fabricated but legal game against a document claiming `bot:onyx` passes perfectly. D73 does not close the import channel. | Backend (4), Security (6) |
| The tutorial practice game must never touch persistence at all — the mode enum has no value for it, and stats are now derived | Backend (9), Product (8) |
| Deferring 14 bots past 0.3 (D81) means introducing 14 new **fixed** anchors into an already-live rating scale | Backend (10), Product (6) |
| The decline path for the 0.3 upload is undefined | Backend (2), Product (5) |
| The same set of document locations is now stale and self-contradicting | Backend (16), Security (15), Product (9) |
| Migration/import is the real cost exposure and the answer to OI-05 | Backend (11), Security (7) |

The shared fix for the authenticity problem: a **server-set `origin: "import" | "native"`** field, with `rated` permanently false for imported games. Security goes further and would keep imported statistics off the profile other players see, or surface them as a separate "offline practice" counter — since D06 shows win/loss/draw and per-opponent records to opponents, imported stats are otherwise attacker-chosen display data.

---

## 4. Where reviewers conflict — your decision

### Should server-side move validation be in 0.3 at all?

**Product says remove it (recommendation 2).** Compute ELO client-side under Firestore rules at 0.3; defer the TypeScript function, the shared corpus wiring and the drift-prevention machinery to 0.4. Its argument, stated plainly: a determined cheater can inflate a rating in a free app with **no leaderboards, no tournaments, no seasons and no prizes** — §5.2 removes all of those permanently. Removing a second language and a second rules implementation from the critical path to first online play is the single largest de-risking available.

**Backend and Security both assume it is present.** Backend's concerns 3, 4 and 7 are all about how the trigger behaves. Security's model rests on it.

This is a genuine trade between shipping risk and integrity risk, and it runs directly at D34, D39 and D75. Two observations that may help:

- Security independently notes that **ELO's own maths already blunts the naive attack** — a 1650 player beating a fresh 1200 provisional gains roughly one point — and that the payoff for an inflated rating today is near zero because §5.2 rules out everything one could spend it on.
- That changes at **0.4's auto-match**, where an inflated rating stops being self-deception and starts mismatching real opponents.

A middle path neither reviewer proposed: adopt Product's deferral, and make 0.3b's ratings explicitly provisional and recomputable — since every game stores its complete move list, ratings can be recomputed from scratch once server validation exists.

### The repeat-matchup cap attacks the app's own retention loop
*Security, concern 9.*

D74's per-pair cap correctly kills two-account boosting. But ticket 007 calls rematch "the cheapest retention mechanism the game has", with alternating starts specifically so a *series* is fair. A rematch chain hits the per-pair cap immediately — as do the friends loop at 0.4 and invite links at 0.3. **Two friends who play only each other are the modal social user, and their games stop counting.**

The security control and the product's primary engagement pattern are the same behaviour. Security's proposal: make the cap a designed, *visible* product behaviour specified alongside D19/D20 — the game says "unrated — you've played this opponent N times this week" *before* the game starts — and set N against the rematch loop, not against an attacker model.

### The caps have no stable subject to count
*Security, concern 8.*

Per-pair caps do nothing against N throwaway accounts, because each is a fresh pair. "New-account rate limits" needs a subject, and Firebase anonymous auth gives you IP (rotatable) and nothing else. Without **Firebase App Check backed by Play Integrity**, the account-creation limit counts a value the attacker controls. App Check is also the missing control on the import endpoint and the chat callable.

---

## 5. Backend architecture — remaining findings

Beyond C1 and C2 above.

| # | Severity | Finding |
|---|---|---|
| 3 | High | The Firestore trigger fires *after* the client write lands, so an illegal move is already in the document and already pushed to the opponent's listener. The trigger's own write re-fires the same trigger unless explicitly guarded — an unguarded trigger recurses until retry limits stop it, and every legitimate move costs two writes plus an invocation instead of one |
| 5 | High | With stored totals gone (D71), the main screen folds *every* completed game — free locally, a full-collection listener per app open at 0.3, growing for the life of the account. `completedGames()` has no pagination, so adding one later touches every caller — the rewrite §9.6 exists to prevent |
| 6 | High | Nothing specifies the game id format, and migration idempotency depends entirely on it. A resumable upload works only if the local id *is* the Firestore document id and `set()` is naturally repeatable |
| 7 | High | Top-level `/games/{id}` with client-chosen ids lets any authenticated client `set()` over another user's game unless the create rule is explicitly gated. **This cannot be added defensively later — rules are the only gate** |
| 8 | Medium | D70's monotonic sequence is per-*move* and says nothing about ordering games relative to each other. Server timestamps stamped at import give every imported game the same time, collapsing years of history into one block |
| 12 | Medium | Auto-backup covers everything in app data — which at 0.3 includes Firebase auth persistence and FCM registration state. A restore produces two installs believing they are the same installation: stale FCM tokens delivering "your turn" to the wrong device |
| 13 | Low | The client move id (D69) is redundant given the index plus a transaction precondition of `moves.size() == index` — the index *is* the idempotency key. It earns its place only if 0.3 moves to a callable with retries outside a transaction |

**Its answer to OI-05.** Steady state is negligible: a 40-move async game is ~40 client writes + ~40 trigger writes + ~80 listener reads, so the free daily tier covers roughly 250 games/day. **Migration is the opposite shape** — a user with 500 local games generates ~500 import writes plus ~500 validation writes plus 500 invocations in one burst, so about 20 users migrating on 0.3 launch day consumes an entire day's free write quota.

### Selected backend recommendations

1. Add `memberUids: []` to §8.3's "fields 0.3 will add"; rules and every list query key on it, never on `participantIds`
2. Rename `participants` to `participantIds` in §8.3 — one array, not two parallel ones
3. Rewrite §8.2's table: `player:<uuid>` for both human seats and `bot:<botId>`; delete the `local:`, `guest:` and `user:` rows. The pass-and-play second seat gets one **stable per-device** uuid, not a fresh one per game, so per-opponent statistics have a stable key
4. Specify the game id as **UUIDv7 or ULID, generated client-side, and state it is the Firestore document id** — time-ordered gives collision-free import, `set()`-idempotent resumption, and creation ordering independent of any timestamp
5. Change §7.3 to `completedGames({limit, startAfter})` and add a separate `stats()` stream, so 0.3 can back it with a `count()` aggregation without touching a caller
7. State in ticket 020 that the practice game never touches `GameRepository` — in memory for the tutorial's duration, never persisted
9. `completedGames()` orders by the client `createdAt` string **permanently** — display-only and untrusted is acceptable for ordering your own history. 0.3's `serverUpdatedAt` is for sync and authority, never display order
10. §11.5 D5 is wrong as written: change "unknown schemaVersion is skipped" to "a version *greater than the reader's* is skipped; equal or lower is read and upgraded" — otherwise a 0.3 client cannot read the version-1 documents it is meant to migrate
14. §7.5 understates the work: 0.3's server needs `applyMove` and `outcome` in TypeScript, not just the line table. Roughly 40 lines, currently unlisted, resting on §9.3's "one definition" claim
17. Add acceptance criteria D7 (every game id globally unique and stable across restarts) and D8 (move indices contiguous from 0, matching array positions) — cheap in 0.1, and the invariants the entire migration rests on

---

## 6. Application security — remaining findings

Beyond C3 above.

| # | Severity | Finding |
|---|---|---|
| 3 | High | At 0.3 the backed-up directory gains Firebase Auth's persisted refresh token and Installations ID. A restore arrives **already signed in** — account takeover by anyone who can trigger a restore. Nothing owns the exclusion rules |
| 4 | High | Restore does not remove the source. Replace-phone-and-restore produces two devices holding the same `player:<uuid>`, then a one-time import. No rule exists for the second claim: silent failure, duplicate import, or the second device losing its history. **This is the likely accident, and it lands on the users the backup decision was made for** |
| 5 | High | "Ownership" of a client-generated uuid cannot be defined — it is a bearer token with no secret. The correct framing is not authenticating the claim but making a false claim worthless: first-claim-wins binding, and imported data that cannot influence anything worth having |
| 7 | High | Import is unmetered function amplification: no cap on games per import, moves per game, imports per account, or attempts per uuid. A flaky network mid-import does it accidentally |
| 10 | Medium | The deletion tombstone misses three residues: head-to-head pair aggregates (the opponent keeps seeing "your record vs X: 3–1"), reports authored *about* the deleted user (third-party personal data with its own basis), and the Firebase Auth user record (a separate API call). **The tombstone must be randomly generated per game at deletion time** — a deterministic hash re-links every game they ever played |
| 11 | Medium | **Firestore region is irreversible and is on no checklist.** The spec flags the application id and the keystore and misses this. Functions default to `us-central1` and must be pinned separately. Firebase Auth cannot be region-pinned at all — user records are processed in the US regardless, and the privacy policy must say so rather than claiming EU-only |
| 12 | Medium | Art. 13(1)(a) requires the controller identified with contact details, and Play separately requires a publicly displayed address for individual accounts — for a solo developer, a home address. The realistic NL mitigation is a KvK eenmanszaak with address shielding |
| 13 | Medium | `rated: false` is client-written in 0.1 and D35 never names it — a client can mark its own game rated. The move id must be namespaced per game and never trusted as globally unique, and the replay must reject any index that is not exactly the current list length |
| 14 | Medium | Integrity events (D75) are a new record of suspected abuse attached to a person, with no shape, access rule, retention period, or home in any document. If accumulation ever triggers an automatic sanction, Art. 22 puts human review and a contest path on the table |
| 16 | Medium | **Ticket 016's content-rating questionnaire silently sets the 0.4 chat regime.** A clean abstract board game is exactly what gets classified as appealing to children; a declared audience including under-13s makes 1:1 free-text chat with strangers effectively unshippable at 0.4, and GDPR Art. 8 (NL: 16) applies. Decided in 0.1, three releases before it bites |
| 17 | Medium | Chat permission derives from game membership, so **creating a game is opening a chat channel**. Whoever can put your id in a `participantIds` array can talk to you. D32 notes blocking must prevent challenges; nothing in §4.1's 0.4 row or any ticket carries it |
| 18 | Low | No data export path anywhere. Art. 15 and 20 apply from 0.3; the documents are already JSON with a schemaVersion, so this is nearly free designed in and annoying retrofitted |
| 19 | Low | **"A lost keystore cannot be recovered" is half true.** With Play App Signing (mandatory for new apps) Google holds the app signing key and a lost *upload* key can be reset through support. The genuine irreversibles are the application id and the app signing key itself |

### Selected security recommendations

1. Rewrite ticket 016's Data Safety bullet from an assertion into a **task**: determine the correct answers given auto-backup is enabled, by checking current Play guidance, and record the reasoning and the date checked. Same for §11.6 R5
2. Rewrite ticket 022's privacy bullet: drop "no data leaves the device" and "if the store requires one". State that gameplay data is stored locally, that Android's system backup may copy it to the user's own Google account under Google's terms, that the developer has no access, and name the controller
3. §2 becomes "a minimal compliance surface: a privacy policy and an accurate Data Safety declaration, but no data controlled by the developer"
4. Commit an explicit `dataExtractionRules` / `fullBackupContent` file from ticket 001 with an **allowlist, not the default include-everything**. Consider allowing device-to-device transfer while excluding cloud backup — Android 12+ splits these, and it delivers the "don't lose history on a new phone" goal with a materially smaller disclosure
7. Define the second-claim rule in §8.2: first import binds the uuid permanently; a later claim by a different account is refused with a user-facing explanation, never a silent merge or wipe. **Write the refusal copy now** — a restored-phone user hitting it is the expected case
10. Add Firebase App Check with Play Integrity to the 0.3 spec as the subject for rate limits, applied to the import and chat callables
13. Add Firestore location as a third irreversible decision to §9.12 and a new gate in §11.6
15. Rename `at` to `clientReportedAt` so its untrustworthiness is structural; reserve `at` for the server timestamp
21. Add repo-wide secret scanning to ticket 001's CI command — 0.3 adds service-account keys and Firebase config

---

## 7. Product management — remaining findings

Beyond C4 above.

| # | Severity | Finding |
|---|---|---|
| 2 | High | The milestone loop (D78) extends 0.1 from ~3 sessions to perhaps ~8. Six opponents with one first-win each is a finite checklist with a terminal state; nothing regenerates. That is the right amount of product for a closed-test vehicle **only if 0.1 is positioned as one** — if the loop is treated as having solved retention, the survey's real job quietly disappears |
| 3 | High | **"At least 6 of 12 play a second session unprompted" cannot be observed.** No analytics, no network, and R5 depends on there never being any. It is knowable only by asking a tester you personally recruited — the most upward-biased measurement available. And neither threshold has a stated consequence: ticket 022 requires only that "anything blocking is fixed or explicitly deferred", which passes regardless of the number |
| 4 | High | Compressing 0.2 (D81) removes its only bounded work and leaves "visual identity, polish" on the critical path — two items with no user problem, no acceptance criteria and no definition of done. **The release created to shorten the path to online play becomes the one with unbounded scope** |
| 7 | Medium | No ticket owns the settings document or `ProfileRepository`. Ticket 018 — now a blocker of the first upload — requires "completion is remembered", and there is nothing to remember it in. **Acceptance criterion T7 cannot pass, and testers are re-offered the tutorial on every launch** |
| 10 | Medium | Twelve recruited beginners generate results against Pebble and Mote and almost none against Basalt and Onyx — precisely where a mis-set anchor does damage, since G3 claims Onyx beats a competent human and 4-ply is shallow relative to Qubic's forcing sequences. **The frozen numbers end up human-anchored at the bottom and guessed at the top** |
| 11 | Medium | Auto-backup is Android-only and does not survive a move to iOS, which D81 makes a real path. A player invests weeks in a rating and loses it on a platform switch, warned only in a settings screen they never opened |

### Selected product recommendations

1. Split 0.3 into 0.3a and 0.3b (see C4)
3. Redefine 0.2 as exactly three things: the iOS build, App Store submission, and fixes the survey demanded. Delete "visual identity" — icon and screenshots are already required by ticket 022 — and replace "polish" with the enumerated defect list
4. **Proposed ladder:** 0.1 Android; 0.2 iOS + submission + survey fixes; 0.3a auth + Firestore repository + one async game; 0.3b invite links, ELO live, push, account deletion, privacy policy, history upload; 0.4 chat/safety, friends, challenges, auto-match, server validation; 0.5 real-time, Web, desktop; **0.6 the remaining 14 opponents**; 1.0 solver, Prime, recalibration
5. **New ticket 023 — per-opponent milestones.** Blocked by 013, explicitly *not* a blocker of 016. Two axes from data already stored: first win against each opponent, and first win *as second player to move* — `startingParticipant` is already in §8.3, and D11's first-player advantage makes that a genuinely harder second rung. Twelve milestones from six opponents. **Derive from stored games; persist no new shape**
6. **New ticket 024 — closed-test survey and thresholds.** No blockers; **must block 016**, because testers need the instrument at install, not at the end. Replace the unobservable "second session" measure with a verifiable artefact: each tester sends a screenshot of their main-screen statistics at day 3 and day 10. No analytics, no network, no Data Safety change — and it doubles as the human-versus-bot data ticket 014 needs
7. **Pre-commit the consequences** in ticket 024 and as a new gate R9 in §11.6: under 8 of 12 finish the tutorial and beat Pebble unaided → the board or tutorial is wrong, fix before promoting out of closed testing; median tester never beats above Bramble → the ladder is mis-anchored, adjust in 014 before 0.2; day-10 screenshots show most stopped after day 2 → skip 0.2's polish and go straight at 0.3a. Add G6 to §3.1 so the thresholds live in the spec, not only a ticket
8. Make the competitor scan (D82) an acceptance criterion **on ticket 004**, not its own ticket — a 45-minute task whose only value is constraining the board design. Write the findings into §1 as the evidence the problem statement currently asserts without a source
9. Move the settings document and `ProfileRepository` into ticket 005 — same atomic-write local store, two more document types. Then add to ticket 018: "tutorial completion is persisted and survives a restart"
10. **New ticket 025 — minimal settings screen** (language and theme override). Blocked by 013, not a blocker of 016. Alternative: delete `locale` and `theme` from §8.6 and follow the system only — but a Dutch speaker on an English-locale phone is a real case in this market
12. **Anchor the ladder bottom-up and chain the top from measured gaps.** Human-anchor Pebble through Ember from the survey; set Basalt and Onyx from the implied rating differences ticket 014's round-robin already produces, and record the chain. Where it is weak, publish the tier label alone — ticket 011 renders both, so showing one is a data change
14. Gate the first *rated* game behind the device-loss warning at 0.3 — one screen, shown once, with the upgrade option on it, not a settings entry

---

## 8. Must be verified externally — do not reason about these

Security was explicit that these cannot be answered by inference and must be checked against current sources before the relevant gate.

| Question | Needed before |
|---|---|
| Does current Play Data Safety guidance require declaring Android Auto Backup transfers? Two threads plausibly exempt it — "collection" meaning transmission to the *developer*, and the exemption for end-to-end encrypted data (Auto Backup on Android 9+ with a lockscreen is E2E-encrypted with the device secret) | Ticket 016 |
| Does Play require a privacy policy for every app now, regardless of declared collection? | Ticket 016 |
| Play's public address requirement for individual developer accounts, and whether a KvK address with *afscherming* satisfies it | Ticket 015 |
| Exact on-device storage locations of Firebase Auth and Firebase Installations data, to write the backup exclusion correctly | 0.3 |
| Whether the ePrivacy Art. 5(3) "strictly necessary" exemption covers cloud-backing-up game history — storing locally is clearly necessary; copying to a cloud service the user did not request for that purpose is weaker. **This is the strongest argument for making backup a user-visible toggle rather than a silent default** | Ticket 001 |

Misdeclaring Data Safety is a policy-violation removal, not a warning. That asymmetry is why these are listed separately.

---

## 9. Suggested order of response

Not a recommendation about *what* to accept — only about what to look at first.

**Before writing any code:**
1. Resolve C1 — the identity/rules contradiction changes §8.3, which every later document is measured against (G5 is meaningless while §8.3 is stale)
2. Decide the server-validation conflict in §4, since it determines whether 0.3 needs TypeScript at all
3. Fix the false claims in C3 — they are wrong today, in files that describe a shipped artefact

**Before ticket 001:**
4. Backup rules as an allowlist, and the device-transfer-versus-cloud-backup split
5. Repo-wide secret scanning

**Before ticket 004:**
6. The competitor scan, since its only purpose is to constrain the board design

**Before ticket 016:**
7. The survey instrument and its pre-committed consequences — testers need it at install
8. The external verifications in §8
9. The target-audience declaration, which silently sets the 0.4 chat regime

**Before 0.3 is specified:**
10. Everything else

---

## 10. Still unresolved after this review

Carried from all three reviewers, unanswered:

- **Whether `vsComputer` and `passAndPlay` games upload at all.** They have no counterparty, they are the bulk of the migration burst, and they are the entire rating-inflation surface. Excluding them removes two High findings almost completely
- **Who the twelve testers actually are.** R4 calls it "a real task, not a formality", ticket 016 requires all twelve to install and open the app, and nothing in any document identifies a source. A hard external dependency, on a solo developer with no stated audience, gating the definition of success in D45
- Whether making ticket 018 a blocker of the upload is a one-off or a **repeal of §12.1's rule to protect the upload date**. If the rule changed, say so; if it is an exception, name the compensating cut
- Whether the 14 deferred bots ever ship. Once online play exists, twenty fixed-strength opponents compete with the thing that made the roadmap worth building. That may be right, but it should be a decision rather than a drift
- Whether 0.3 rating counts any imported game at all, or whether the live scale starts clean and 0.1 history is archive only
- Whether imported statistics appear on the profile other players see
- Whether `activeGames()` at 0.3 includes in-progress bot games — determines whether a bot game resumes on a second device or is device-bound forever
- Whether a second device restored from auto-backup, then signed into a *different* Firebase account, is a case worth handling
- **Onyx's actual strength against a competent human remains an estimate.** G3 asserts it; nothing in the plan tests it
- What happens if day-10 screenshots show near-zero return play. "Compress 0.2" is a schedule answer to what is really a positioning question: whether an offline Qubic with a good board is worth publishing on its own terms even if nobody returns to it
