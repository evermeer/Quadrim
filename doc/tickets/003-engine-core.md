# 003 — Engine core

**What to build:** The complete rules of Quadrim, as pure deterministic functions. A game state can be created, advanced by a legal move, and asked for its outcome — and when that outcome is a win it names the exact line that was completed, because the board must later highlight it. Threat detection also lands here, since both the computer opponents and the tutorial's hints are built on it.

No user-visible change. This is the ticket that makes every subsequent ticket possible, and the one where test coverage must be uncompromising.

**Blocked by:** 002 — Line generation and win detection

**Status:** ready-for-agent

- [ ] A game state exposes the board, the side to move, and the ordered list of moves played, and is immutable
- [ ] Legal moves are exactly the empty cells
- [ ] Applying a move returns a new state and never mutates the input
- [ ] Applying a move to an occupied cell is rejected and leaves the state unchanged
- [ ] Applying a move to a game that has already finished is rejected
- [ ] Outcome reports ongoing, draw, or a win naming both the winner and the completed line
- [ ] A full board with no completed line reports a draw
- [ ] Threat detection reports lines holding three of one player's pieces and one empty cell
- [ ] Every game in the generated corpus replays to its recorded outcome
- [ ] The engine imports no Flutter, no platform I/O, no ambient clock, and no ambient random source
