# 027 — Rating against the computer

**What to build:** A real rating. The player starts at 1200, and every game against a computer opponent moves it — up for beating a stronger opponent, barely at all for beating a much weaker one. It is the progression the offline game is built around, and it replaces the earlier plan of showing indicative numbers and calling the games unrated practice.

**This rating never leaves the device.** It is computed here, stored here, and visible only to whoever holds the phone. Nobody else can see it and no server ever validates it. Editing it would cheat only yourself, so it needs no defending — which is exactly why it can be this simple.

It is **derived, not stored**: a fold over completed games against the fixed opponent anchors, in order, from the 1200 seed. That means it cannot drift from the games that produced it, and there is no second copy to migrate or reconcile.

**Blocked by:** 014 — Rating maths and the self-play calibration harness; 013 — Main screen

**Status:** ready-for-agent

- [ ] A new player with no history has a computer rating of 1200
- [ ] The rating is computed by folding completed games against computer opponents in chronological order; nothing is stored separately
- [ ] Computing it twice over the same games gives the same answer
- [ ] K is 32 for the first 20 games on this ladder and 16 thereafter
- [ ] Draws score one half; the rating is rounded and floored at 100
- [ ] Opponent ratings are fixed anchors and never move
- [ ] Pass-and-play games do not affect it
- [ ] The tutorial's practice game does not affect it, because it is never stored at all
- [ ] The rating is shown on the main screen, and the change is shown on the result screen when a game ends
- [ ] The interface makes clear that this rating is for games against the computer, and is local to this device — so that the separate human rating arriving at 0.3b is never mistaken for the same number
- [ ] No network call is made at any point in computing, storing or displaying it
- [ ] The rating is announced to a screen reader as a value with a label, not as a bare number
- [ ] All new strings are present in English and Dutch
