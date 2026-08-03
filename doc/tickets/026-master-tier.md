# 026 — The Master tier: Oracle and Quadrim Prime

**What to build:** The top of the ladder. **Oracle** plays at full strength with exact endgame solving and varies its openings among proven-strong moves, so it does not feel like a fixed script. **Quadrim Prime** is the final boss.

**Prime is not yet perfect, and must not claim to be.** True perfection needs the precomputed strategy book, which is a build-time solver deferred to release 1.0 with unbounded effort (OI-02). Prime therefore ships on rung 2 of Idea-final.md §6.5's fallback ladder — exact endgame solving plus the deepest achievable search — and is described as extremely strong. It is upgraded and recalibrated when the solver lands.

That is safe to do precisely because computer ratings are device-local: changing Prime's anchor later moves a number only its owner can see.

**Blocked by:** 025 — Deep search and exact endgames

**Status:** ready-for-agent

- [ ] Oracle and Quadrim Prime exist as catalogue entries with the configurations given in Idea-final.md §6.4
- [ ] Oracle varies its opening among moves that measure as strong, rather than replaying one line
- [ ] Both use exact endgame solving and never lose a position that solving proves is drawn or won
- [ ] Prime's catalogue description and any text shown to the player describe it as extremely strong, **not perfect** — the roster is now complete, the claim of perfection is not yet earned
- [ ] Prime beats Oracle over a significant number of self-play games
- [ ] Both choose a move within a recorded time budget on the oldest supported device, and the interface stays responsive
- [ ] Where the time budget forces a shallower search than intended, that is recorded rather than silently accepted
- [ ] A note is carried into the 1.0 work: Prime's description and anchor must both be revisited when the solver lands
- [ ] Every opponent still returns only legal moves across thousands of random positions
