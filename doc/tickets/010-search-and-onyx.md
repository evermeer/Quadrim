# 010 — Search and Onyx

**What to build:** The strongest opponent in release 0.1. Onyx looks four plies ahead using alpha-beta search over a heuristic evaluation of the position, and will beat a competent human more often than not. This is the opponent that makes the game worth coming back to.

**Blocked by:** 009 — Positional rules and Basalt

**Status:** ready-for-agent

- [ ] An alpha-beta search over the heuristic position evaluation is implemented, with configurable depth
- [ ] The heuristic evaluation is derived from threats and line ownership, reusing existing engine primitives rather than duplicating them
- [ ] Onyx exists as a catalogue entry with the configuration given in the specification
- [ ] Onyx chooses a move within a time budget that feels responsive on a mid-range phone, with the budget recorded
- [ ] Search never blocks the interface; the board stays responsive while the opponent thinks
- [ ] Given a forced win within the search horizon, Onyx finds it
- [ ] Given a forced loss within the search horizon, Onyx delays or avoids it where possible
- [ ] Onyx beats Basalt over a significant number of self-play games
- [ ] Search results are reproducible for a given seed, state and depth
- [ ] Every opponent still returns only legal moves across thousands of random positions
