# 023 — Per-opponent milestones

**What to build:** The six-opponent ladder gets a visible spine. The main screen shows what the player has and has not yet achieved against each opponent, so there is a reason to open the app again tomorrow rather than only a win/loss/draw table that says nothing about progress.

Two milestones per opponent: beating them at all, and beating them **as the second player to move**. The second is a genuinely harder rung — Quadrim's first player has a real advantage — and it costs nothing extra, because which seat started is already recorded on every game.

Everything here is derived from games already stored. **No new stored shape.** That is what keeps it free.

**Blocked by:** 013 — Main screen

**Status:** ready-for-agent

- [ ] Twelve milestones exist: for each of the six opponents, a first win and a first win as second player to move
- [ ] Milestones are derived at read time from stored games; nothing new is persisted
- [ ] The main screen shows which are achieved and which remain
- [ ] Achieving one during a game is acknowledged when that game ends, not silently recorded
- [ ] Unachieved milestones against opponents the player has never faced do not read as failures
- [ ] Milestones are announced to a screen reader as state, not as decoration
- [ ] All new strings are present in English and Dutch
