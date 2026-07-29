# 011 — Opponent selection

**What to build:** Choosing who to play becomes a real decision. The player sees all six computer opponents with their names, avatars, difficulty tiers, indicative strength, and a line describing how each plays — and can pick one matched to their ability instead of guessing.

The honesty requirement matters here: release 0.1 has no accounts and therefore no rating. The numbers shown are indicative strength, and the screen must say so rather than implying a rating system that does not exist yet.

**Blocked by:** 010 — Search and Onyx

**Status:** ready-for-agent

- [ ] All six opponents are listed: Pebble, Mote, Bramble, Ember, Basalt and Onyx
- [ ] Each shows a name, an avatar from the built-in set, a difficulty tier, and an indicative strength number
- [ ] Each shows a short description of how it plays, translated into both languages
- [ ] Opponents are ordered by strength
- [ ] The screen states plainly that games against computer opponents are unrated practice for now
- [ ] Selecting an opponent starts a game against it
- [ ] The list is driven by the opponent catalogue, so adding the remaining fourteen in release 0.6 needs no change to this screen
- [ ] Tier and indicative strength are rendered independently, so an opponent whose number is not yet trustworthy can show its tier alone — a data change, not a code change
- [ ] The screen is navigable by screen reader, with each opponent's name, tier and strength announced
- [ ] All new strings are present in English and Dutch
