# 002 — Line generation and win detection

**What to build:** The 76 winning lines of a 4×4×4 cube exist as generated data that nobody hand-writes, together with proof that they are correct: every one of the 76 lines wins, and no other set of four cells does.

This is the foundation the whole game rests on, and it is the one place where a subtle error would be invisible for months. It is generated rather than written because release 0.3 introduces a second implementation in TypeScript, and the only defence against the two drifting apart is that neither is authored by hand.

**Blocked by:** 001 — Project skeleton and CI

**Status:** ready-for-agent

- [ ] A build-time generator emits the 76 lines as committed source, marked as generated and not to be edited
- [ ] Exactly 76 lines are produced: 48 axis-aligned, 24 diagonals lying within a flat plane, 4 corner-to-corner space diagonals
- [ ] The generator also emits a corpus of complete games with known outcomes, covering every winning-line family, forced draws, and illegal-move cases
- [ ] CI fails if the generated output is stale relative to the generator
- [ ] A test verifies that each of the 76 lines, filled by either player, is recognised as a win
- [ ] A test verifies exhaustively that no set of four cells outside the 76 is ever recognised as a win
- [ ] Nothing anywhere else in the codebase enumerates or derives lines independently
