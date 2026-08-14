# 033 — Quests

**What to build:** One achievement system, not three. Everything that pays points besides a plain win is a quest, including the two per-opponent milestones that were once ticket 023.

| Family | Instances | Rungs |
|---|---|---|
| First win against an opponent | 20 | one per opponent |
| First win **as the second player to move** | 20 | one per opponent |
| Games played in one day | 5 | 5, 10, 20, 50, 100 |
| Consecutive days played | 8 | 5, 10, 30, 90, 180, 360, 720, 1440 |

The eight streak rungs are specified here and implemented in ticket 034; everything else lands in this one.

**Every quest is priced by the opponents it was earned against, never by how high the player has climbed.** That is the single most important sentence in this ticket and it took two attempts to get right, so both failures are recorded rather than quietly replaced.

Pricing at the player's current rung lets the cheap quests be *banked*. The ladder never requires playing the weakest opponents — four Bramble wins is a cheaper route to Willow than sixty-four Pebble wins — so a player has no reason to touch Pebble, Twig, Mote or Clover, and their eight quests would sit unclaimed and appreciating. Claimed at rung 15 they pay the entire Titan unlock; at rung 19 they pay twice the cost of the whole roster, for eight games against opponents that move at random.

And the same rule makes the volume family a pure grind: a hundred instant Pebble games at rung 17 would pay four Titan wins for an afternoon of tapping. Both are the same mistake — the doubling in the unlock ladder exists so that grinding downward prices itself out *without a rule*, and a reward priced by the player's height reintroduced the exploit in the one place that shape was not looking (D261, D270).

**So: a per-opponent quest pays 2ⁱ of the opponent it names. A volume or streak quest pays its multiple of a win against the average of the qualifying games — averaged over the roster index, then rounded to the nearest opponent.** Averaging the index rather than the payout matters, because payouts double and an arithmetic mean of them is dominated by the single strongest game in the set.

| Games in one day | 5 | 10 | 20 | 50 | 100 |
|---|---|---|---|---|---|
| Pays, in wins-worth | ¼ | ½ | 1 | 2 | 4 |

**Nothing new is stored.** Quest progress is a fold over games, like everything else.

**Blocked by:** 031 — The progression package, and points that accumulate

Ordered after 032 and not dependent on it: the per-opponent quests are more meaningful once opponents are locked, but nothing here reads an unlock record.

**Status:** ready-for-agent

- [ ] Fifty-three quests exist across the four families above
- [ ] A per-opponent quest against opponent *i* pays 2ⁱ — the same amount whenever it is claimed, so deferring it earns nothing extra
- [ ] A volume or streak quest pays its multiple × 2^round(mean roster index of the qualifying games)
- [ ] The average is taken over the **index**, not the payouts: a test pins nineteen Pebble games and one Titan game at **2 points**, and records that averaging the payouts would have paid 6,555
- [ ] A hundred games against Pebble in one day pays **four points**, for a player who has unlocked Titan exactly as for one who has not
- [ ] **No function signature in `quadrim_progression` accepts the player's rating or their current rung** — the rule is enforced by the types, not by discipline
- [ ] Every quest fires exactly once, however many times its condition is met again
- [ ] Progress is derived from stored games; nothing is persisted by this ticket
- [ ] The main screen shows the **four quests closest to completion**, ranked by percentage complete, ties going to the smaller absolute remainder
- [ ] Each shows an icon, its name and a progress bar, with the bar's meaning also available as a number
- [ ] Achieving a quest during a game is acknowledged **when that game ends**, together with the points it paid — not silently recorded, and not interrupting play
- [ ] The volume family carries **no restriction copy in 0.1**. It becomes subscriber-only by arithmetic when the meter arrives at 0.4; saying so now would be false for the whole closed test
- [ ] Pass-and-play games and the tutorial's practice game count toward no quest
- [ ] Quests are announced to a screen reader as state with progress, not as decoration
- [ ] All new strings are present in English and Dutch

---

## Closed

All fifty-three quests exist and forty-five of them are evaluated. The eight
consecutive-day rungs are defined here and left unevaluated on purpose — that
is ticket 034, which owns the injected day boundary and the time-zone answer.
They report as 0 of their target rather than being absent, so the rungs are
visible from 0.1 and only the evaluator is missing.

**The pricing rule is carried by the types.** No function in
`quadrim_progression` accepts a rating or a rung, so no reward *can* be priced
by how high the player has climbed. A per-opponent quest pays 2ⁱ whenever it is
claimed; a volume quest pays its multiple × 2^round(mean roster index). Both
rejected rules are pinned as tests rather than described in a comment: banking
the four cheapest per-opponent quests is worth 15 points and not 4,194,304, and
a hundred Pebble games in a day pays 4 whether or not the player has beaten
Titan.

Nothing is stored. `ScoredGame` gained `movedSecond` and `completedAt`, both
**required** rather than defaulted, so the compiler — not a test — is what
stops the app forgetting to map them and silently killing two quest families.

The end-of-game acknowledgement is the difference between folding the quests
with this game and without it. That is two folds of a small in-memory list and
no new record.

Three decisions came out of building it: D279 (a quest that fires pays at least
one point), D280 (multiples are integers in quarters of a win), D281 (ties rank
by roster order, not alphabetically — the first implementation opened the
section with four opponents chosen by spelling).

**Deferred, deliberately:** the volume family carries no restriction copy, per
the ticket — it becomes subscriber-only by arithmetic when the meter arrives at
0.4, and saying so now would be false for the whole closed test.
