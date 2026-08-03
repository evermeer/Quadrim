# 026 — The Master tier: Oracle and Quadrim Prime

**What to build:** The top of the ladder. **Oracle** plays at full strength with exact endgame solving and varies its openings among proven-strong moves, so it does not feel like a fixed script. **Quadrim Prime** is the final boss.

**Prime is not yet perfect, and must not claim to be.** True perfection needs the precomputed strategy book, deferred to release 1.0 (OI-02). Prime therefore ships on rung 2 of Idea-final.md §6.5's fallback ladder — exact endgame solving plus the deepest achievable search — and is described as extremely strong. It is upgraded and recalibrated when the book lands.

**The book is smaller and closer than this plan first assumed.** The game was solved independently twice, and the published first-player-win strategy is roughly 2,929 stored positions, with everything else reachable by forcing moves — see Idea-final.md §6.5.1. So the 1.0 work is largely *acquire, verify, encode* rather than original computation, and the runtime job is mostly the forcing-sequence search this tier already has. Two things it does not solve: the strategy covers the **first player only**, so Prime moving second still defends by search; and an unverified dataset is not a proof, which is why rung 2 ships now.

That is safe to do precisely because computer ratings are device-local: changing Prime's anchor later moves a number only its owner can see.

**Blocked by:** 025 — Deep search and exact endgames

**Status:** ready-for-agent

- [ ] Oracle and Quadrim Prime exist as catalogue entries with the configurations given in Idea-final.md §6.4
- [ ] Oracle varies its opening among moves that measure as strong, rather than replaying one line
- [ ] Both use exact endgame solving and never lose a position that solving proves is drawn or won
- [ ] Prime's catalogue description and any text shown to the player describe it as extremely strong, **not perfect** — the roster is now complete, the claim of perfection is not yet earned
- [ ] Prime beats Oracle over a significant number of self-play games
- [ ] Both use **node budgets, never wall-clock**, so their play is identical across devices and in CI
- [ ] The wall-clock equivalent is measured and recorded against the named reference device, and the interface stays responsive there
- [ ] Where the node budget forces a shallower search than intended, that is recorded rather than silently accepted
- [ ] A note is carried into the 1.0 work: Prime's description and anchor must both be revisited when the solver lands
- [ ] Every opponent still returns only legal moves across thousands of random positions
