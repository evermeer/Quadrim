# 031 — The progression package, and points that accumulate

**What to build:** A win against a computer opponent starts paying, and the player can see the total.

This is the first of four progression tickets and it deliberately stops short of anything to spend the points on — that is ticket 032. What it establishes is the arithmetic and the place it lives, so the three tickets after it extend a settled interface rather than renegotiating one.

**A new pure package, `quadrim_progression`.** Not in the engine, by the engine's own rule: spec §7.1 says the catalogue carries no `locked` field, because the strength harness plays all twenty opponents against each other and has no business holding an entitlement. Arithmetic about what a player owns and what it cost sits on the other side of that line (D263). It depends on `quadrim_engine` for the roster index — the first inter-package dependency in the project, running in the allowed direction.

**A win against roster index *i* pays 2ⁱ.** Draws and losses pay nothing, which is what keeps "four wins buys the next opponent" exact rather than approximate. The whole roster costs 2,097,088 points, which is exactly sixty wins — that is the number to reason about; the totals are display.

**Keyed on the roster index, never on the rating.** Spec §7.1 is explicit that the index is an ordinal and the two must not be conflated, and finding F3 in the brainstorming document is what happens when they are. The catalogue is already stored in roster order, so the index is its list position and nothing new needs storing.

**Nothing is stored by this ticket.** Points earned is a fold over completed games, exactly like the computer rating, and for the same reason: a stored total is a second copy of something the games already say.

**Blocked by:** 030 — Main screen decomposition

**Status:** ready-for-agent

- [ ] A new package `packages/quadrim_progression` exists, pure Dart
- [ ] `check.sh` enforces its purity as it does for the other two: no Flutter, no Firebase, no `dart:io`, no ambient clock, no ambient random source, and no runtime dependency other than `quadrim_engine`
- [ ] `winValue(i)` returns 2ⁱ; a draw and a loss are worth nothing
- [ ] `unlockCost(i)` returns 2ⁱ⁺¹, and a test asserts it equals four wins against opponent *i−1* for every rung
- [ ] `isFree(bot)` is true exactly when the bot's rating is 1000 or below — **a rule, not a count**, and a test asserts that no constant anywhere encodes "five"
- [ ] Every value is keyed on the **roster index**, and a test over the whole catalogue asserts that no pricing function reads the `rating` field
- [ ] `pointsEarned(games)` is a fold over completed games and reads nothing else
- [ ] Computing it twice over the same games gives the same answer, in the same build and across builds
- [ ] Pass-and-play games pay nothing; the tutorial's practice game pays nothing because it is never stored at all
- [ ] Summing the unlock costs over the fifteen locked opponents gives 2,097,088, and a test pins that number
- [ ] The balance appears on the main screen's rating card, formatted with the locale's thousands separator — the top of the ladder is seven digits and a separator is not decoration
- [ ] The balance is announced to a screen reader **once**, as a labelled value, not twice as a number and a total
- [ ] The package is tested exhaustively over the twenty catalogue entries rather than by sampling — it is small integer arithmetic over twenty known inputs and there is no excuse for spot checks
- [ ] All new strings are present in English and Dutch
