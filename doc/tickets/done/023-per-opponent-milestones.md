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

## Absorbed — not built as a separate ticket

Absorbed into the quest system by idea-v3.md §7.4 (D240). **Nothing in this
ticket was implemented under this number**, and none of the work is lost: its
two milestones became the first two quest families, twenty instances each, and
are built in ticket 033.

What carried over unchanged:

- both milestones per opponent — a first win, and a first win as the second
  player to move
- derived at read time from stored games, with **no new stored shape**, which is
  what kept it free and still does
- acknowledged when the game ends rather than silently recorded

What changed by being folded in. The milestones now **pay points** — 2ⁱ for
opponent *i*, the same as one win against them — where before they were a
display-only badge. Pricing them by the opponent rather than by the player's
current rung is not a detail: the alternative let eight games against opponents
that move at random pay twice the cost of the entire roster (D261, D270).

And the presentation changed. This ticket grouped forty milestones by tier with
the player's tier expanded. Ticket 033 instead shows the **four quests closest to
completion**, because forty milestones and thirteen more from the volume and
streak families is far past what a phone screen can present as a list.
