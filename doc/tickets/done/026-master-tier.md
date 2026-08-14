# 026 — The Master tier: Oracle and Quadrim Prime

**What to build:** The top of the ladder. **Oracle** plays at full strength with exact endgame solving and varies its openings among proven-strong moves, so it does not feel like a fixed script. **Quadrim Prime** is the final boss.

**The book arrived early, and Prime plays from it.** This ticket was written expecting rung 2 of idea-v1.md §6.5's fallback ladder — exact endgame solving plus the deepest achievable search — with the strategy book deferred to 1.0 (OI-02). The dictionary was then obtained, licence-checked and verified during implementation, so both Master opponents ship holding it (D172, D175).

**What that does and does not buy.** The dictionary proves a **first-player win**. Oracle and Prime are therefore unbeatable when they open, and fall back to search when they move second — which is the one place the two differ (D176). "Perfect" without that qualification is false in half their games, so no text in the app says it (D181).

**The book was smaller and closer than this plan first assumed.** The game was solved independently twice, and the published first-player-win strategy is 2,929 stored positions, with everything else reachable by forcing moves — see idea-v1.md §6.5.1. The work was therefore *acquire, verify, encode* rather than original computation, and the runtime job was mostly the forcing-sequence search this tier already had.

That is safe to do precisely because computer ratings are device-local: changing Prime's anchor later moves a number only its owner can see.

**Blocked by:** 025 — Deep search and exact endgames

**Status:** ready-for-agent

- [ ] Oracle and Quadrim Prime exist as catalogue entries with the configurations given in idea-v1.md §6.4
- [ ] Oracle varies its opening among moves that measure as strong, rather than replaying one line
- [ ] Both use exact endgame solving and never lose a position that solving proves is drawn or won
- [ ] Prime's catalogue description and any text shown to the player describe it as **unbeatable when it moves first**, never as perfect without qualification — the proof it follows covers the opening player only (D181)
- [ ] Prime beats Oracle over a significant number of self-play games
- [ ] Both use **node budgets, never wall-clock**, so their play is identical across devices and in CI
- [ ] The wall-clock equivalent is measured and recorded against the named reference device, and the interface stays responsive there
- [ ] Where the node budget forces a shallower search than intended, that is recorded rather than silently accepted
- [ ] A note is carried into the 1.0 work: Prime's description and anchor must both be revisited when the solver lands
- [ ] Every opponent still returns only legal moves across thousands of random positions
