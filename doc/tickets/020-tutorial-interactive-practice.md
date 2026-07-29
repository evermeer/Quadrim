# 020 — Tutorial: interactive practice game

**What to build:** The tutorial ends with a real game. The player plays against a gentle scripted opponent and can ask for a hint at any point — and the hint reflects the actual position, pointing at a genuine threat or opportunity rather than reciting a fixed script.

This is the part that makes the tutorial stick, and the part that costs real engineering: the hint system is built on the same threat detection the computer opponents use, so what the tutorial teaches is what the game actually rewards.

**Blocked by:** 019 — Tutorial: basic strategy; 008 — Strategic-rule bots

**Status:** ready-for-agent

- [ ] A guided game is played against a scripted opponent that is deliberately beatable
- [ ] The scripted opponent is an opponent configuration with a fixed seed, not a separate code path
- [ ] A hint can be requested at any point during the practice game
- [ ] Hints are derived from real threat detection on the current position, not from scripted text
- [ ] A hint names a concrete reason: an available win, a threat that must be blocked, or a strong developing move
- [ ] The player can decline hints entirely and simply play
- [ ] Playing a move the hint discouraged is allowed, and the game continues
- [ ] The practice game can be abandoned at any point without blocking tutorial completion
- [ ] Completing it marks the tutorial as finished
- [ ] The practice game does not appear in the player's statistics or completed games
- [ ] Hints are announced by screen reader
- [ ] All new strings are present in English and Dutch
