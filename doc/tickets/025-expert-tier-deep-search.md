# 025 — Deep search and exact endgames: the Expert tier

**What to build:** Four opponents strong enough that a good player has to work. **Quartz**, **Corvus** and **Lyra** search six to eight plies with a transposition table and iterative deepening; **Titan** adds exact endgame solving — once few enough cells remain, it stops estimating and starts knowing.

This is the first ticket with genuinely new engine machinery rather than new configurations. The transposition table and iterative deepening are what make eight plies affordable on a phone at all, and exact solving is the foundation the Master tier and, eventually, the 1.0 solver build on.

**Blocked by:** 010 — Search: the Club tier

**Status:** ready-for-agent

- [ ] A transposition table caches evaluated positions, with a bounded memory footprint that is recorded
- [ ] Iterative deepening searches progressively deeper within a time budget rather than fixing a depth up front
- [ ] Exact endgame solving proves a win, loss or draw once the number of empty cells falls below a configurable threshold
- [ ] A proven result is never overridden by a heuristic estimate
- [ ] Quartz, Corvus, Lyra and Titan exist as catalogue entries with the configurations given in Idea-final.md §6.4
- [ ] **Every search budget is expressed in nodes, never in milliseconds.** A wall-clock budget makes each opponent non-deterministic across devices, between debug and release, and between CI and a phone — which would make acceptance criterion E7 a test that passes locally and flakes everywhere else, and would make calibration unrepeatable
- [ ] The wall-clock equivalent of each node budget is measured and recorded against a **named reference device**, which is also the device the responsiveness criteria are judged on
- [ ] Each chooses a move fast enough to feel responsive on that named device
- [ ] Search runs off the interface thread and is abandoned cleanly if the player leaves the game
- [ ] The transposition table is created and discarded within a single move choice, so the engine stays pure and reproducible
- [ ] Titan never loses a position that exact solving proves is drawn or won
- [ ] Each of the four beats the tier below it over a significant number of self-play games
- [ ] Results are reproducible for a given seed, state and node budget
- [ ] Every opponent still returns only legal moves across thousands of random positions
