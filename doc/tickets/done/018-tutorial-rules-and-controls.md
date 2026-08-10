# 018 — Tutorial: rules and controls

**What to build:** A player who has never seen a 4×4×4 board can learn what the game is and how to read the screen. The tutorial explains the objective, shows examples of every family of winning line — including the diagonals through the cube that newcomers consistently miss — and explains how four flat parallelograms represent one cube.

It is offered automatically on first launch, can be restarted from the main screen, and can be left at any time.

**Blocked by:** 004 — Playable board and pass-and-play

**Status:** ready-for-agent

- [ ] The tutorial is offered automatically on first launch
- [ ] It can be restarted at any time from the main screen
- [ ] It can be exited at any point without completing it
- [ ] Completion is persisted in the settings document and survives a restart, so it is not offered again
- [ ] The objective is explained in a single screen
- [ ] At least one example is shown from each of the four winning-line families: along an axis, diagonally within a layer, diagonally through a vertical slice, and corner to corner through the cube
- [ ] Examples are drawn on the real board component rather than as static pictures
- [ ] The mapping from four parallelograms to one cube is explained explicitly
- [ ] The player is shown how to place a piece
- [ ] Progress through the tutorial is visible, and steps can be revisited
- [ ] Every step is navigable and comprehensible by screen reader
- [ ] All new strings are present in English and Dutch
