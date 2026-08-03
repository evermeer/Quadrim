# 011 — Opponent selection

**What to build:** Choosing who to play becomes a real decision. The player sees all twenty computer opponents with their names, avatars, tiers, ratings, and a line describing how each plays — and can pick one matched to their own rating instead of guessing.

Twenty is enough that presentation matters. A flat list of twenty is a wall; grouped by tier, with the player's own rating visible, it is a ladder with an obvious next rung.

**Blocked by:** 026 — The Master tier; 029 — Placeholder art and opponent content

*Note: this ticket gates the first upload through ticket 016, and 026 sits at the end of the entire engine chain. That was a deliberate choice — see the specification §12.3 — and its cost is that the first build twelve people ever see waits for the hardest engine work in the project.*

**Status:** ready-for-agent

- [ ] All twenty opponents are listed, from Pebble to Quadrim Prime
- [ ] Each shows a name, an avatar from the built-in set, a difficulty tier, and its rating
- [ ] Each shows a short description of how it plays, translated into both languages
- [ ] Opponents are grouped by tier and ordered by strength within it, so a list of twenty stays navigable
- [ ] The player's own computer rating is visible on this screen, so the choice can be made against it
- [ ] Opponents far above or below the player's rating are visually distinguishable from a fair match
- [ ] Quadrim Prime is described as extremely strong, **not perfect** — it ships without the strategy book
- [ ] Selecting an opponent starts a game against it
- [ ] The list is driven by the opponent catalogue, so a configuration or rating change needs no change to this screen
- [ ] Tier and rating are rendered independently, so an opponent whose number is not yet trustworthy can show its tier alone — a data change, not a code change
- [ ] The screen is navigable by screen reader, with each opponent's name, tier and strength announced
- [ ] All new strings are present in English and Dutch
