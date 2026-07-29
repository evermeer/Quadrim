# 007 — Result screen, rematch and resign

**What to build:** A finished game ends properly. The winning line is highlighted on the board so the player can see exactly how it was won, the result is stated clearly, and one tap starts a rematch in which the other player moves first. A player can also resign a hopeless game rather than being forced to play it out.

Rematch is the cheapest retention mechanism the game has, and the alternating start is what keeps a series fair given the first player's advantage.

**Blocked by:** 004 — Playable board and pass-and-play

**Status:** ready-for-agent

- [ ] When a game is won, the four cells of the completed line are highlighted on the board
- [ ] The result screen states who won, or that the game was drawn
- [ ] The result screen states clearly that the game was unrated practice when played against a computer opponent
- [ ] A rematch can be started with one tap
- [ ] In a rematch, the player who did not start the previous game starts this one
- [ ] A rematch records which game it followed
- [ ] The starting player of a first game is chosen at random, and the reason it was chosen is recorded
- [ ] The game tells the player who moves first and why
- [ ] A player can resign at any point, and the game ends as a loss for them
- [ ] Resignation requires a confirmation so it cannot be triggered accidentally
- [ ] The result is announced to a screen reader
- [ ] All new strings are present in English and Dutch
