# 008 — Rule-based opponents: the Novice and Casual tiers

**What to build:** Eight more opponents that actually understand the game, spanning everything from "spots a win half the time" to "applies the whole rule ladder and rarely errs". After this ticket a beginner has a real progression to climb rather than a single opponent to beat.

Novice: **Twig**, **Mote**, **Clover**. Casual: **Bramble**, **Finch**, **Kestrel**, **Willow**, **Ember**.

They all run the same four-rule ladder from the specification, differing only in which rules are enabled, how often they blunder, and how they weight building against blocking. No new decision code beyond the rules themselves and the weighting.

**Blocked by:** 006 — Bot engine and Pebble

**Status:** ready-for-agent

- [ ] The four strategic rules are implemented and evaluated in order: take an immediate win; block the opponent's immediate win; create a double threat; deny the opponent a double threat
- [ ] Rules can be individually enabled or disabled by configuration
- [ ] Blunder rate is configurable and causes the chosen move to be replaced by a weaker legal one
- [ ] Aggression is configurable, weighting building one's own threats against blocking the opponent's
- [ ] Corner and centre preference are configurable independently
- [ ] All eight opponents exist as catalogue entries with the configurations given in idea-v1.md §6.4
- [ ] Given a position with an immediate win available, a rule-enabled opponent takes it
- [ ] Given a position where the opponent wins next move, a rule-enabled opponent blocks it
- [ ] Given a position where a double threat is available, an opponent with that rule enabled plays it
- [ ] Blunder rates are verified statistically over many games rather than asserted on single moves
- [ ] An aggressive opponent demonstrably builds before it blocks, and a defensive one the reverse
- [ ] Every opponent still returns only legal moves across thousands of random positions
- [ ] The eight are distinguishable in play, not merely in configuration
