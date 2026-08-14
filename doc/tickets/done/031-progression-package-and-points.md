# 031 — The progression package, and points that accumulate

**What to build:** A win against a computer opponent starts paying, and the player can see the total.

This is the first of four progression tickets and it deliberately stops short of anything to spend the points on — that is ticket 032. What it establishes is the arithmetic and the place it lives, so the three tickets after it extend a settled interface rather than renegotiating one.

**A new pure package, `quadrim_progression`.** Not in the engine, by the engine's own rule: spec §7.1 says the catalogue carries no `locked` field, because the strength harness plays all twenty opponents against each other and has no business holding an entitlement. Arithmetic about what a player owns and what it cost sits on the other side of that line (D263). It depends on `quadrim_engine` for the roster index — the first inter-package dependency in the project, running in the allowed direction.

**A win against roster index *i* pays 2ⁱ.** Draws and losses pay nothing, which is what keeps "four wins buys the next opponent" exact rather than approximate. The whole roster costs 2,097,088 points, which is exactly sixty wins — that is the number to reason about; the totals are display.

**Keyed on the roster index, never on the rating.** Spec §7.1 is explicit that the index is an ordinal and the two must not be conflated, and finding F3 in the brainstorming document is what happens when they are. The catalogue is already stored in roster order, so the index is its list position and nothing new needs storing.

**Nothing is stored by this ticket.** Points earned is a fold over completed games, exactly like the computer rating, and for the same reason: a stored total is a second copy of something the games already say.

**Blocked by:** 030 — Main screen decomposition

**Status:** ready-for-agent

- [x] A new package `packages/quadrim_progression` exists, pure Dart
- [x] `check.sh` enforces its purity as it does for the other two: no Flutter, no Firebase, no `dart:io`, no ambient clock, no ambient random source, and no runtime dependency other than `quadrim_engine`
- [x] `winValue(i)` returns 2ⁱ; a draw and a loss are worth nothing
- [x] `unlockCost(i)` returns 2ⁱ⁺¹, and a test asserts it equals four wins against opponent *i−1* for every rung
- [x] `isFree(bot)` is true exactly when the bot's rating is 1000 or below — **a rule, not a count**, and a test asserts that no constant anywhere encodes "five"
- [x] Every value is keyed on the **roster index**, and a test over the whole catalogue asserts that no pricing function reads the `rating` field
- [x] `pointsEarned(games)` is a fold over completed games and reads nothing else
- [x] Computing it twice over the same games gives the same answer, in the same build and across builds
- [x] Pass-and-play games pay nothing; the tutorial's practice game pays nothing because it is never stored at all
- [x] Summing the unlock costs over the fifteen locked opponents gives 2,097,088, and a test pins that number
- [x] The balance appears on the main screen's rating card, formatted with the locale's thousands separator — the top of the ladder is seven digits and a separator is not decoration
- [x] The balance is announced to a screen reader **once**, as a labelled value, not twice as a number and a total
- [x] The package is tested exhaustively over the twenty catalogue entries rather than by sampling — it is small integer arithmetic over twenty known inputs and there is no excuse for spot checks
- [x] All new strings are present in English and Dutch

## How this was closed

`packages/quadrim_progression` is the third pure package and the first
inter-package edge in the repository. `tool/check.sh` allows exactly one runtime
dependency, for exactly this package, **by name** — verified by injecting
`http: ^1.0.0` and confirming it is still reported — and a second check greps the
engine and rating packages for `package:quadrim_progression` so the edge stays a
direction rather than a coupling.

The tests are exhaustive over the catalogue rather than sampled, and that earned
its keep immediately: two claims written into them were wrong. A thousand Pebble
wins does **not** fall short of a Willow unlock — Willow costs 64, so sixty-four
Pebble wins buys it, and grinding the bottom for the first rung is merely tedious
rather than impossible. What the doubling actually prices out is grinding the
bottom for the *top*: 1,048,576 games for Quadrim Prime against four from the rung
below. idea-v3.md §7.3's "grinding downward is self-defeating" is true of the
ladder as a whole and not of its first rung, and the test now says so.

D270 is carried by the type system rather than by a comment: no function in the
package's public surface accepts the player's rating or their current rung, so no
reward can be priced by how high the player has climbed even by accident.

Two things caught by tooling rather than by reading, both recorded in the review:
a `points` import prefix that shadowed the new `points` field at the one line
that sets it, and a localised value interpolated into a quoted literal, which the
gate's string grep cannot tell from a hardcoded one — correctly.

Review in `codereview-main.md`: one minor, one nit, both fixed in the ticket.
