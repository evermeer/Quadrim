# 034 — Streaks

**What to build:** The eight consecutive-day rungs specified in ticket 033, and the day arithmetic underneath them.

**A day is the device's local calendar day, and it is kept alive by *finishing* at least one game against the computer.** Starting one is not enough — otherwise the streak is maintained by opening the app and quitting, which measures nothing.

**A missed day resets the streak to zero.** No forgiveness, no rest days, no repair purchase. The long rungs are meant to be rare, and every softening mechanism is another rule to explain, another thing to store, and another surface for "I *did* play on Tuesday" support mail.

| Consecutive days | 5 | 10 | 30 | 90 | 180 | 360 | 720 | 1440 |
|---|---|---|---|---|---|---|---|---|
| Pays, in wins-worth | 1 | 2 | 4 | 8 | 12 | 16 | 24 | 32 |

Priced like the volume family — the multiple × a win against the rounded mean roster index of the games that kept the streak alive. A ninety-day streak of real games is worth about two unlocks; the same streak kept alive with one Pebble game a day is worth a handful of points. **That is the intended answer, not a shortcoming:** showing up is what the streak measures, but what you showed up *to* is what the points measure (D270).

**The package may not read a clock**, so the day boundary is a parameter. This is not a testing convenience — it is the same purity rule that makes every opponent reproducible, applied to the one piece of progression arithmetic that genuinely needs a calendar.

Two consequences are handled honestly rather than hidden. A player crossing time zones can gain or lose a day, so where the rule is ambiguous it is evaluated **generously** — never break a streak that any reasonable reading would have kept. And the 1440-day rung is just under four years; it exists as a horizon, not as a target, and nothing depends on anyone reaching it.

**Blocked by:** 033 — Quests

**Status:** ready-for-agent

- [ ] `streak(games, dayBoundary)` takes the day boundary as a parameter; **no clock is read inside the package**, and `check.sh`'s purity scan continues to pass
- [ ] A day counts only if a computer game was **finished** on it; a day with only started games does not
- [ ] A missed day resets the streak to zero
- [ ] The reset is correct across a month boundary, a year boundary and a leap day
- [ ] The reset is correct across a time-zone change in both directions, and where the boundary is ambiguous the streak is preserved rather than broken
- [ ] The eight rungs pay the multiples in the table above
- [ ] Each is priced by the rounded mean roster index of the games that kept the streak alive, exactly as the volume family is
- [ ] A streak kept alive with one Pebble game a day pays Pebble money, and a test states that number explicitly so nobody later reads it as a bug
- [ ] Each rung fires exactly once
- [ ] **Nothing is stored** — no streak length, no last-played date. A test reconstructs the current streak and every rung's state from game history and an injected boundary alone
- [ ] Pass-and-play games and the tutorial's practice game do not keep a streak alive
- [ ] The current streak is announced to a screen reader as a labelled value
- [ ] All new strings are present in English and Dutch
