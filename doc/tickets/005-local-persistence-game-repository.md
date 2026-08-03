# 005 — Local persistence behind a game repository

**What to build:** Games survive closing the app. A player can start a game, kill the app, reopen it, and continue exactly where they left off — and completed games remain available afterwards. Settings persist too, including whether the tutorial has been completed.

All access to games goes through a single repository contract. That contract exists because it is the boundary the flow tests run against, and because release 0.3a's Firestore implementation must pass the *same* tests to prove the online layer works.

**Storage is deliberately minimal.** Releases 0.1 and 0.2 are private, and their data is never uploaded — release 0.3 starts with an empty database. So nothing here is shaped for a future cloud: no device identity, no participant arrays, no per-move authorship. Store the simplest thing that is correct.

**Blocked by:** 004 — Playable board and pass-and-play

**Status:** ready-for-agent

- [ ] A single repository contract covers watching a game, listing active games, listing completed games, creating, appending a move, resigning, and deleting
- [ ] The contract is stream-based rather than future-based, so a push-based implementation can replace it without changing callers
- [ ] Games are stored as JSON documents keyed by id, matching the game document shape in the specification
- [ ] Moves are stored as a plain ordered list of cell indices; whose move each was is derived from list position and the recorded starting seat, never stored
- [ ] A game records only which opponent it was against — a computer opponent or the pass-and-play second seat
- [ ] A completed game records the **opponent's rating at the time it was played**, so that recalibrating an opponent later does not silently rewrite the player's whole rating history
- [ ] A completed game records a completion timestamp, which is the ordering key for the rating fold, with the game id as tie-break
- [ ] A result records an outcome and a **separate reason** — line, full board, resignation, timeout or abandonment — because a clock-driven ending cannot be derived from the moves
- [ ] The repository can load all completed games once, so callers can fold the same in-memory list rather than sweeping storage repeatedly
- [ ] **No device identifier is generated, stored or transmitted anywhere**
- [ ] Every stored document carries a schema version
- [ ] A document whose schema version is greater than the reader understands is skipped; equal or lower is read and upgraded
- [ ] Game ids are unique and stable across restarts
- [ ] A settings document stores language, theme and tutorial completion, using the same storage mechanism
- [ ] Statistics are derived by folding completed games at read time and are never stored
- [ ] An in-progress game survives an app restart with its full move list intact
- [ ] A process kill during a write leaves no corrupted record
- [ ] No screen reads or writes storage except through the repository contract
