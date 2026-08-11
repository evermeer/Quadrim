# 027 — Rating against the computer

**What to build:** A real rating. The player starts at 1200, and every game against a computer opponent moves it — up for beating a stronger opponent, barely at all for beating a much weaker one. It is the progression the offline game is built around, and it replaces the earlier plan of showing indicative numbers and calling the games unrated practice.

**This rating never leaves the device.** It is computed here, stored here, and visible only to whoever holds the phone. Nobody else can see it and no server ever validates it. Editing it would cheat only yourself, so it needs no defending — which is exactly why it can be this simple.

It is **derived, not stored**: a fold over completed games against the fixed opponent anchors, in order, from the 1200 seed. That means it cannot drift from the games that produced it, and there is no second copy to migrate or reconcile.

**Blocked by:** 014 — Rating maths and the self-play calibration harness (done); 013 — Main screen (done)

**Status:** ready-for-agent

- [x] A new player with no history has a computer rating of 1200
- [x] The rating is computed by folding completed games against computer opponents, ordered by completion time with the game id as tie-break; nothing is stored separately
- [x] The fold uses the **anchor stored on each game**, not the current catalogue value — so recalibrating an opponent is a deliberate re-fold rather than a silent rewrite of history, and every delta a player was shown stays reproducible
- [x] Computing it twice over the same games gives the same answer, in the same build and across builds
- [x] K is 32 for the first 20 games on this ladder and 16 thereafter
- [x] Draws score one half; the rating is rounded and floored at 100
- [x] Opponent ratings are fixed anchors and never move
- [x] Pass-and-play games do not affect it
- [x] The tutorial's practice game does not affect it, because it is never stored at all
- [x] The rating is shown on the main screen, and the change is shown on the result screen when a game ends
- [x] The interface makes clear that this rating is for games against the computer, and is local to this device — so that the separate human rating arriving at 0.3b is never mistaken for the same number
- [x] No network call is made at any point in computing, storing or displaying it
- [x] The rating is announced to a screen reader as a value with a label, not as a bare number
- [x] All new strings are present in English and Dutch

## How this was closed

Most of the code shipped incidentally with ticket 013 — `quadrim_rating`,
`rating_fold.dart`, the rating on the main screen, the delta on the result
screen. This ticket was therefore a **verification** pass, not an
implementation one, and CLAUDE.md said so: "verify its criteria before moving
it rather than assuming".

What verification found was that the fold had almost no coverage of its own.
Two assertions existed — the seed for an empty history, and one
`greaterThan(kSeedRating)` after two wins. Every rating rule the ticket names
was unproven. `test/rating_fold_test.dart` now covers them at the document
level: the stored anchor rather than the catalogue value, determinism, the K
step at twenty games, a draw scoring half, the floor at 100, the player's seat
rather than seat zero, pass-and-play exclusion, and the fold's dependence on
completion order.

Criterion 12 (no network call) was the one with no code to test. It is now
mechanised instead: `check.sh` fails if the **release** manifest ever declares
`INTERNET`, which is a stronger guarantee than reading the code, because
without the permission Android refuses the call whatever the code asks for
(D212). Flutter's debug and profile manifests declare it for hot reload and are
deliberately not checked — only what ships is.
