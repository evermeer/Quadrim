# 023 — Per-opponent milestones

**What to build:** The ladder gets a visible spine beyond the rating number. The main screen shows what the player has and has not yet achieved against each opponent.

The rating from ticket 027 now carries most of the progression weight, so this is deliberately smaller than it once was: two milestones per opponent — beating them at all, and beating them **as the second player to move**. The second is a genuinely harder rung, since Quadrim's first player has a real advantage, and it costs nothing extra because which seat started is already recorded on every game.

With twenty opponents that is forty milestones, which is too many to show at once. Present them by tier, with the player's current tier expanded.

Everything here is derived from games already stored. **No new stored shape.** That is what keeps it free.

**Blocked by:** 013 — Main screen; 027 — Rating against the computer

**Status:** ready-for-agent

- [ ] Two milestones exist per opponent: a first win, and a first win as second player to move
- [ ] Milestones are derived at read time from stored games; nothing new is persisted
- [ ] They are grouped by tier rather than listed as forty flat rows
- [ ] The tier the player's rating currently sits in is the one expanded by default
- [ ] Achieving one during a game is acknowledged when that game ends, not silently recorded
- [ ] Unachieved milestones against opponents the player has never faced do not read as failures
- [ ] Milestones are announced to a screen reader as state, not as decoration
- [ ] All new strings are present in English and Dutch
