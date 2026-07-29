# 005 — Local persistence behind a game repository

**What to build:** Games survive closing the app. A player can start a game, kill the app, reopen it, and continue exactly where they left off — and completed games remain available afterwards.

The important part is invisible: all access to games goes through a single repository contract, and the stored documents are shaped exactly as the Firestore documents of release 0.3 will be. This is the seam that lets online play arrive later as a new implementation rather than a rewrite of every screen.

**Blocked by:** 004 — Playable board and pass-and-play

**Status:** ready-for-agent

- [ ] A single repository contract covers watching a game, listing active games, listing completed games, creating, appending a move, resigning, and deleting
- [ ] The contract is stream-based rather than future-based, so that a push-based implementation can replace it without changing callers
- [ ] Games are stored as JSON documents keyed by id, matching the game document shape defined in the specification
- [ ] Every stored document carries a schema version
- [ ] Participants use the tagged identity scheme, with no bare device identifiers anywhere
- [ ] A stable local player identity is generated on first launch and persists across restarts
- [ ] Games marked as played against a computer opponent record that they are unrated
- [ ] An in-progress game survives an app restart with its full move list intact
- [ ] A process kill during a write leaves no corrupted record
- [ ] A record with an unrecognised schema version is skipped rather than crashing the app
- [ ] No screen reads or writes storage except through the repository contract
