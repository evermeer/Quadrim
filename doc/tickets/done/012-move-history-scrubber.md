# 012 — Move-history scrubber

**What to build:** A player can step backward and forward through the moves of a game — the one they are playing, or any they have finished — to see how a position arose. Reviewing never changes anything: scrubbing a live game is safe, and returning to the present resumes play exactly where it was.

This is cheap because the move list is append-only and complete, so any past position is a pure replay rather than something that has to be stored.

**Blocked by:** 005 — Local persistence behind a game repository

**Status:** ready-for-agent

- [ ] A control steps backward and forward one move at a time
- [ ] The board shows the position as it stood after the selected move
- [ ] The current move number and the total are visible
- [ ] Jumping to the start and to the end is possible without stepping through every move
- [ ] Scrubbing a game in progress does not alter its state, and no move can be made while viewing the past
- [ ] Returning to the present restores play with the game unchanged
- [ ] Any completed game can be replayed the same way
- [ ] The scrubber is operable by screen reader, and the displayed position is announced as it changes
- [ ] All new strings are present in English and Dutch
