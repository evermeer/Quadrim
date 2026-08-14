# 010 — Search: the Club tier

**What to build:** Four opponents that look ahead. **Marlin** and **Vireo** search two plies with opposing temperaments, **Onyx** searches four, and **Sable** adds dedicated threat-space search for double threats. Onyx is the first opponent that will beat a competent human more often than not.

**Blocked by:** 009 — Positional rules and Basalt

**Status:** ready-for-agent

- [ ] An alpha-beta search over the heuristic position evaluation is implemented, with configurable depth
- [ ] The heuristic evaluation is derived from threats and line ownership, reusing existing engine primitives rather than duplicating them
- [ ] Threat-space search finds forcing sequences that plain depth-limited search at the same depth misses
- [ ] Marlin, Vireo, Onyx and Sable exist as catalogue entries with the configurations given in idea-v1.md §6.4
- [ ] Each chooses a move within a time budget that feels responsive on a mid-range phone, with the budget recorded
- [ ] Search never blocks the interface; the board stays responsive while an opponent thinks
- [ ] Given a forced win within the search horizon, the opponent finds it
- [ ] Given a forced loss within the horizon, it delays or avoids it where possible
- [ ] Each of the four beats the tier below it over a significant number of self-play games
- [ ] Search results are reproducible for a given seed, state and depth
- [ ] Every opponent still returns only legal moves across thousands of random positions
