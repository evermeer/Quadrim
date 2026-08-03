# 009 — Positional rules and Basalt: entering the Club tier

**What to build:** An opponent that plays well even when no rule fires. Basalt prefers the central 2×2×2 cube, then corners, and breaks remaining ties by choosing the cell lying on the most lines it already part-owns. It is the first opponent that feels like it has a plan rather than merely reacting.

**Blocked by:** 008 — Strategic-rule bots

**Status:** ready-for-agent

- [ ] The positional rules are implemented and evaluated in order: prefer a free cell in the central 2×2×2 cube; otherwise prefer a corner; otherwise choose the cell on the most lines already holding two or more own pieces and no opponent piece; otherwise choose at random
- [ ] Positional rules are used both when no strategic rule fires and as the tie-break within a strategic rule
- [ ] Positional bias is configurable, so later opponents can weight centre, corner and edge differently
- [ ] Basalt exists as a catalogue entry with the configuration given in the specification
- [ ] Given an empty board, Basalt opens in the central cube
- [ ] Given several cells satisfying the same strategic rule, Basalt picks by the positional tie-break rather than at random
- [ ] Basalt beats Ember over a significant number of self-play games
- [ ] Every opponent still returns only legal moves across thousands of random positions
