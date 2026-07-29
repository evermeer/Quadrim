# 008 — Strategic-rule bots: Mote, Bramble and Ember

**What to build:** Three more opponents that actually understand the game. Mote spots wins and blocks but misses them often. Bramble applies the full rule ladder with frequent mistakes. Ember applies it cleanly and rarely errs. A player can now find an opponent roughly matched to a beginner's growing ability.

All three run the same four-rule ladder from the specification, differing only in blunder rate and configuration. No new decision code beyond the rules themselves.

**Blocked by:** 006 — Bot engine and Pebble

**Status:** ready-for-agent

- [ ] The four strategic rules are implemented and evaluated in order: take an immediate win; block the opponent's immediate win; create a double threat; deny the opponent a double threat
- [ ] Rules can be individually enabled or disabled by configuration
- [ ] Blunder rate is configurable and causes the chosen move to be replaced by a weaker legal one
- [ ] Mote, Bramble and Ember exist as catalogue entries with the configurations given in the specification
- [ ] Given a position with an immediate win available, a rule-enabled opponent takes it
- [ ] Given a position where the opponent wins next move, a rule-enabled opponent blocks it
- [ ] Given a position where a double threat is available, an opponent with that rule enabled plays it
- [ ] Blunder rates are verified statistically over many games rather than asserted on single moves
- [ ] Every opponent still returns only legal moves across thousands of random positions
- [ ] The three opponents are distinguishable in play, not merely in configuration
