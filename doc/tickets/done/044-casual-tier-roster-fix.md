# Ticket 044 — The Casual-tier inversion

**Depends on:** nothing. Pure engine work, runnable on either machine.

**Status:** ready-for-agent

## Why

Across three consecutive rungs the player is shown **increasing prices for
decreasing strength**. Willow (index 5, rated 1100) measures about 33 points
above Vireo (index 6, rated 1200), and Vireo about 50 above Finch (index 7,
rated 1250). The roster index sets the unlock price and the win payout, so
those three prices are a public claim about difficulty and for these three the
claim is false.

This has been known since D210/D211 and was deferred twice — first to a 1.0
roster revision, then, when that revision was cancelled, to nothing. D305
brought it here because **1.0 is the last release in which this is free to
change.** Nothing has been sold and no unlock record exists outside the
developer's own devices.

**It is not a tuning defect and no parameter change closes it as the roster
currently stands** (D268). `aggression` is worth about 78 points and the
roster pins its direction: Vireo "would rather build than block", the stronger
setting, sits below Finch "shuts your threats down first", the weaker one. The
blunder rate cannot spread far enough to compensate, because it must fall as
rating rises between Bramble's 0.15 and Kestrel's 0.08.

## What it does

**The mechanism is to move the configurations between the three rungs, not to
move the entries.** The catalogue order stays exactly as it is —
`willow(1100), vireo(1200), finch(1250)` at indices 5, 6, 7 — and what changes
is which personality sits on which rung: the more aggressive, stronger-measuring
configuration moves up to 1250 and the weaker one moves down to 1100.

That choice matters more than it looks:

- **No price and no payout changes at all.** Both are keyed on the roster
  index (§7.3), and no entry changes index. D305 described this as a reorder
  and assumed a price migration; there is none. What was urgent about doing it
  before the first sale turns out to be the *displayed difficulty claim*, not
  the economy.
- **No avatar moves.** The twenty painted portraits from ticket 038 are keyed
  on the opponent id, so leaving ids on their rungs leaves the art alone.
- **The personality copy follows the configuration, not the id.** Willow,
  Vireo and Finch's descriptions in the `.arb` files describe how they play,
  and after this ticket two of them play differently. Copy that no longer
  describes the bot it names is worse than the inversion it fixed.

Then **measure, and let the measurement decide the final values**:

```
cd packages/quadrim_engine
dart run tool/calibrate.dart --only willow
dart run tool/calibrate.dart --only vireo
dart run tool/calibrate.dart --only finch
```

**When measurement disagrees with a published rating, the configuration
changes and the rating does not** (D144). The three anchors 1100, 1200 and
1250 are fixed. If the first swap overshoots — and a swap of a parameter worth
78 points across gaps of 33 and 50 plausibly will — the answer is to adjust the
configurations again and re-measure, never to move an anchor to meet a
measurement.

## Acceptance criteria

1. Measured strength **ascends** across Willow, Vireo and Finch, confirmed by
   a `calibrate.dart` run whose output is pasted into the closure notes.
2. The three published ratings are unchanged: 1100, 1200, 1250.
3. Roster indices are unchanged, and a test asserts the unlock price and win
   payout of every opponent are what they were before this ticket.
4. Each of the three opponents' personality description matches how it now
   plays, in **both** English and Dutch.
5. The wider ladder has not moved: a full `calibrate.dart` run shows no new
   inversion anywhere else. Three adjacent rungs cannot be changed in isolation
   — Bramble below and Kestrel above are the neighbours to check.
6. `bash tool/check.sh` passes.

## Notes

**Budget the time.** A full calibration run is ~6 minutes on an idle machine
at 10% budgets (D208), and this ticket needs several. Give every run a hard
`timeout` — a hung suite is indistinguishable from a slow one, and this repo
has lost days to exactly that (D178).

**Do not fix this by editing `BotConfig.rating`.** It is the one edit that
makes the symptom disappear from the screen while making the app's central
claim — that these ratings are measured rather than asserted — false.

---

## Closure

Committed on `main`. `bash tool/check.sh`: **ALL CHECKS PASSED**.

Measured with the fixed instrument, 60 games a pair, budgets at 10%:

| | published | measured | before |
|---|---|---|---|
| bramble | 1000 | 946 | — |
| willow | 1100 | **1137** | 1259, flagged outside tolerance |
| vireo | 1200 | **1236** | 1215 |
| finch | 1250 | **1261** | 1176 |
| kestrel | 1300 | 1275 | 1263 |

Measured strength ascends and every rung is inside tolerance. Criterion 1 met.

**Almost nothing about this ticket's plan survived contact with measurement.**

The plan was to move configurations between rungs so that the stronger one sits
higher (D309). Before doing that I measured the third pair — Willow against
Finch, which no tool had ever played — and found **+207 the other way**. The
tier is not mis-ordered, it is **intransitive**: Willow beats Vireo, Vireo beats
Finch, Finch beats Willow. There is no assignment of three configurations to
three rungs that makes a cycle ascend.

**The instrument was half the defect.** `calibrate.dart` played adjacent pairs
and cross-tier braces, so within a tier the non-adjacent pairs were never
played — and a cycle needs a triangle to show up in. Willow's only two
opponents were the two it beats, which is the whole reason it measured 159
points above its anchor. It now plays every within-tier pair: 47 pairs instead
of 29, 15¼ minutes instead of 13½ (D313).

**Removing `aggression` was the owner's call and it was not the cause.** It
shrank the cycle by about 40% and did not close it. What remains is driven by
*which* good squares an opponent prefers — corners-first beats centres-first
beats centres-only beats corners-first — which is the very axis D210 chose to
order the tier by (D314, D315).

**And D210's central claim does not survive a direct test.** It holds that
preferring more of the sixteen seven-line cells is the tier's strongest lever.
Taking Vireo from sixteen preferred cells to eight made it measurably
*stronger* — its win over Finch grew from +38 to +70. That change was reverted
because it made this rung worse, but the finding stands and is recorded.

**What is fixed:** the aggregate ladder, which is what a published rating
claims. **What is not:** three head-to-head matchups still run against the
prices, and the calibration report now names them instead of hiding them. No
lever available to this tier closes that; it needs a monotone one — search
depth, or a finer blunder scale — and that is not 1.0's work.

**No price and no payout changed.** Two lines were deleted from `bot.dart` and
no roster index moved, so D309's predicted migration never arose.
