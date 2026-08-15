# 037 — Your Path scrolls, and every opponent gets a page

**What to build:** Two changes to the same section, asked for together because the second is what makes the first safe.

**Your Path scrolls the whole roster and rests on the rating.** Today it is a fixed window of three tiles centred on the next *unlock*. It becomes a horizontally scrollable row over all twenty, resting so the middle tile is the **lowest-rated opponent rated strictly above the player's rating** — Clover at 900 for a player seeded at 800. Left is everyone weaker, right is everyone stronger.

This reverses D262, and the reason is worth stating rather than assuming: **D262 was an argument about a *fixed* window, not about which ladder is more interesting.** With three tiles and nothing beyond them, whatever the window is centred on is the only thing that exists, so centring on rating really did hide the price ladder on first launch. A scrollable row does not have that property — the unlock ladder is one swipe right, from every point on the roster rather than only where the two ladders coincide (D287).

**Strictly above, so the centre is always a step up.** Mote is rated exactly 800; a player at 800 rests on Clover, with Mote one tile left. An even match is not "next", and the even-match marker already says what Mote is.

**Tapping a tile opens that opponent's detail page.** The avatar at the top, at the largest size it is ever drawn, then the name, rating and tier; the blurb; how the pairing sits against the player's rating; the record and stars; what a win pays. For Oracle and Quadrim Prime, the warning §6.6 requires.

**One action at the bottom, never none.** Unlocked, it starts a game against them. Locked, it is the price, the progress and an unlock button, reaching the same confirmation the other two routes reach.

**Opponent selection is not touched.** Tapping a row there still starts a game. That screen is behind the *new game* button, so the player has already decided; a detail page in front of it would tax the commonest path in the app (D288).

**Nothing new is stored.** The catalogue supplies the facts and the existing folds supply the record and the balance.

**Blocked by:** nothing — 032 and 035 are done.

**Status:** ready-for-agent

- [ ] Your Path scrolls horizontally over all twenty opponents, in roster order
- [ ] It rests with the lowest-rated opponent rated **strictly above** the player's rating in the middle; a player seeded at 800 rests on Clover, not Mote and not Willow
- [ ] A player rated below the whole roster rests at the first opponent, and one rated above it rests at the last; three tiles are on screen either way and there is never a hole
- [ ] The resting position is computed once per rating change, not on every rebuild — scrolling away and back does not snap the row
- [ ] Tapping a tile opens the detail page for that opponent
- [ ] Tapping a row in opponent selection still starts a game, unchanged
- [ ] The detail page shows the avatar at the largest size it is drawn anywhere, then name, rating, tier, blurb, how the pairing sits, the record, the stars, and what a win pays
- [ ] An opponent never faced shows **no star row**, as everywhere else
- [ ] Oracle and Quadrim Prime repeat "unbeatable when it moves first" on the page, not only in the confirmation
- [ ] An unlocked opponent's page ends in a button that starts a game against them
- [ ] A locked opponent's page ends in the price, the progress and an unlock button, leading to the same confirmation Your Path and opponent selection lead to
- [ ] The page adds no stored record and no second copy of any rating
- [ ] The page and the row render on the smallest supported phone at the largest font scale
- [ ] Every fact on the page is announced exactly once, and the row's tiles keep announcing themselves as one node each
- [ ] All new strings are present in English and Dutch
- [ ] Ticket 032's tests that pinned the old resting position are **rewritten, not deleted** — the D262 test becomes the D287 test, same fixture, opposite expectation

---

## Closed

Your Path scrolls the whole roster and rests on the rating; every opponent has
a page.

**The resting rule lives in the app, not in `quadrim_progression`** — beside
`tierNearest`, which is the app's other rating-to-catalogue question. Putting it
in the package would have meant weakening the test that asserts no signature
there accepts the player's rating, and that assertion is what makes it
impossible to price a reward by how high the player has climbed (D261, D270). A
presentation rule is not a reward, but an invariant that gets an exception is
not an invariant.

**The row measures its height rather than predicting it.** Two fixed-height
guesses overflowed — 18 pixels at the largest font scale, then 28 on a
different phone — because the avatar is sized by the tile width and does not
grow with the font while everything under it does. `IntrinsicHeight` over a
stretched `Row` sizes to the tallest tile at any scale. That builds all twenty
tiles eagerly, which is affordable precisely here: the roster is exactly twenty
and cannot grow without a code change, unlike the finished-games list below it.

**Ticket 032's tests were rewritten rather than deleted**, as this ticket asked:
the test that pinned D262's "middle one is the next unlock" is now the test that
pins D287's "rests on the first opponent above the player", same fixture,
opposite expectation, with a comment naming both decisions.

**D287** the row rests on the rating because scrolling removed the reason it
could not; **D288** the detail page, and why opponent selection does not use it.
