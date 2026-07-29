# 004 — Playable board and pass-and-play

**What to build:** The first playable game. Two people sharing one phone can play Quadrim start to finish: they see the whole 4×4×4 cube as four layers at once, tap an empty cell to place a piece, watch the turn pass, and reach a win or a draw.

This is the project's first tracer bullet and the first moment it stops being documents. Accessibility of the board is part of this ticket rather than a later sweep, because piece rendering that distinguishes players by colour alone is far more expensive to unpick afterwards than to get right once.

**Blocked by:** 003 — Engine core

**Status:** ready-for-agent

- [ ] All four layers and all 64 cells are visible at once, without scrolling, on a phone in portrait
- [ ] Layers are drawn so that the cube's depth is legible
- [ ] Occupied and empty cells are unmistakably distinguishable at a glance
- [ ] A single tap on an empty cell places a piece; there is no confirmation step
- [ ] Taps on occupied cells do nothing
- [ ] The player to move is unambiguous on screen at all times
- [ ] The game reaches a win and reaches a draw, and announces which
- [ ] Pieces are distinguished by shape as well as colour, and remain distinguishable under colour vision simulation
- [ ] Every cell carries a screen reader label naming its layer, row, column, and contents
- [ ] Turn changes and the game result are announced to a screen reader
- [ ] Every cell is a reliable touch target on the smallest supported phone
- [ ] The board is legible in both light and dark themes
- [ ] All new strings are present in English and Dutch
