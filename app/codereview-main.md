
---

# Ticket 044 — The Casual-tier inversion

> Reviewed 2026-08-16 against `main` (working tree, uncommitted).
> Scope: `packages/quadrim_engine/lib/src/bot.dart`,
> `packages/quadrim_engine/tool/calibrate.dart`,
> `packages/quadrim_engine/test/strategic_bot_test.dart`, the two `.arb` files
> and their generated localisations, and the three documents.
> `bash tool/check.sh`: **ALL CHECKS PASSED**.

| Severity | Count |
|---|---|
| major | 0 |
| minor | 1 |
| nit | 1 |

The functional diff is **two deleted lines** — `aggression: 0.67` from Vireo and
`aggression: 0.30` from Finch. Everything else is the instrument, the tests,
the blurbs and the record.

## [MINOR] `--only` now costs four times what its documentation implies — `efficiency`

**File:** `packages/quadrim_engine/tool/calibrate.dart:135`

```dart
for (final other in opponentCatalogue)
  if (other.tier == subject.tier && other.id != subject.id) other,
```

**Problem:** The header comment still advertises `--only` as the cheap
re-measure — *"one opponent, resettled"* — and it was 5 pairs. For a member of
a five-strong tier it is now 8, and the tool's own docstring for `_pairsFor`
("its neighbours … plus one opponent from each other tier") describes
behaviour the function no longer has. The tuning loop this exists for is now
noticeably slower, and nothing says so.

**Fix:** Update the docstring, which is the part that is now false. The cost
itself is the point of the change — the narrow sample is what hid the cycle —
so it stays.

*Applied: `_pairsFor`'s docstring rewritten to say it plays the subject's whole
tier and why.*

## [NIT] `indexOf` inside a nested loop to answer a question the loop already knows — `simplification`

**File:** `packages/quadrim_engine/tool/calibrate.dart:110`

```dart
final adjacent = opponentCatalogue.indexOf(members[j]) -
        opponentCatalogue.indexOf(members[i]) ==
    1;
```

**Problem:** Two O(n) scans per pair to recover positions that could have been
carried through the loop. Irrelevant at twenty opponents — the duels take
minutes and this takes microseconds — but it reads as if the position were
unavailable, and it is not.

**Fix:** Collect `(index, config)` when building `members`. Left as-is: this is
a measurement tool, the cost is unmeasurable, and the clearer diff at this size
is the one that changes least.

---

## Not findings, checked and cleared

- **Only two behavioural lines changed.** `git diff` over `bot.dart` shows the
  two `aggression` removals and nothing else; every other line in that file is
  comment. Willow, Bramble and Kestrel were already at the 0.5 default and are
  untouched.
- **No rating moved.** D144 holds — the fix is entirely in configurations, and
  the published anchors 1000/1100/1200/1250/1300 are unchanged.
- **No roster index moved**, so every unlock price and win payout is exactly
  what it was. D309 predicted this fix would need a reorder; it did not, so
  there is no migration and no price change (D315).
- **The blunder-rate monotonicity test still passes**, which is what would have
  caught a naive attempt to space the tier by that lever instead.
- **The two stale assertions were replaced, not deleted.**
  `vireo.aggression > 0.5` and `finch.aggression < 0.5` asserted the design
  this ticket removed; the new test asserts the tier's new invariant, so the
  removal cannot be silently undone.
- **Both blurbs were rewritten in both languages** and no longer describe
  behaviour the bots lack. Finch's first draft ended "rarely slips", echoing
  Kestrel's "rarely gives anything away" two rows below it; changed to "plays a
  tidy game".
- **The `--budget 1` caveat is unchanged.** Sable/Corvus is still reported as
  unreadable at 10% budgets, as before this ticket.
