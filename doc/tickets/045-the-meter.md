# Ticket 045 — The meter

**Depends on:** nothing. Pure arithmetic plus one stored record; runnable on
either machine.

**Status:** ready-for-agent

## Why

1.0 sells a subscription whose entire value is lifting a cap, so the cap has to
exist first. Three computer games a day and nine a week, after an unmetered
first month (§4.2).

This ticket is the **counting**, not the selling and not the wall. The paywall
UI is 047 and the purchase is 046, and keeping them apart means the arithmetic
is testable before any store exists.

## What it does

### 1. `meter.dart` in `quadrim_progression`

Not a new package. The meter is a fold over completed games plus an injected
day boundary, which is exactly the shape `streaks.dart` already has — and a
fourth package would earn its purity scan, its pubspec and its CI entry for
about a hundred lines of arithmetic.

The package's invariant holds unchanged: **no function here accepts the
player's rating or rung** (D261/D270). A meter has no business knowing either.

```dart
/// Games started today and this week, and which limit bit first.
MeterState meterState({
  required Iterable<CompletedGame> games,
  required DateTime now,
  required FreeMonth freeMonth,
});
```

Rules, all of them from §4.2:

- **A game counts when it is *started*, not when it finishes.** An abandoned
  game is a spent game, or the meter is defeated by starting and quitting.
- **Only games against the computer count.** Pass-and-play, the tutorial's
  practice game, and replay of a finished game are all outside it.
- **Both limits apply**, and the weekly one binds first from the fourth
  playing day of any week.
- **The state names which limit bit**, because "you have used this week's nine
  games" and "come back tomorrow" are different sentences and only one of them
  is true on a Thursday (D221).
- **No clock is read inside the package.** `now` and the day boundary are
  parameters, exactly as the streak evaluator takes them (P19).

### 2. The free month

One record, stored, alongside the unlock records: when the month started. It is
consumed **once, at first launch, and never again** — a lapse does not restart
it (§4.1).

**At 1.0 this is device-local, and a reinstall restores it.** That is a known
limit, not a defect to engineer around: closing it needs either a device
identifier, forbidden in every release (§5.2), or a server, which is 2.0
(D303, S19). **No code in this ticket may reach for anything that identifies
the device** — not an install id, not a vendor id, not a keychain entry that
survives uninstall specifically to defeat this.

At 2.0 the record is adopted by the account rather than restarted. Write it so
that migration is reading one field, and note the field in the closure.

### 3. Backup

The free-month record joins games, settings and unlocks under
`files/quadrim/`, so it is inside the existing Android allowlist with no
manifest change, and inside iOS's `Documents` by default. That is correct: a
restore that returned the unlocks but reset the free month would hand a
returning player a second free month.

## Acceptance criteria

1. Three started games in a day exhaust the daily limit; the fourth is
   refused.
2. Nine started games in a week exhaust the weekly limit **even when no day
   exceeded three**, and the state names the weekly limit as the one that bit.
3. A game that was started and abandoned counts.
4. Pass-and-play, the practice game and replay never count.
5. The first month is unmetered, ends one calendar month after first launch,
   and does not restart on any subsequent launch.
6. Day and week boundaries are correct across a month boundary, a year
   boundary and a time-zone change — the same cases `streaks_test.dart`
   already covers (P16–P19).
7. No clock and no random source is read inside `quadrim_progression`;
   `check.sh`'s purity scan proves it.
8. No device identifier is generated, stored or read anywhere in the diff
   (S2).
9. `bash tool/check.sh` passes.

## Notes

**Nothing in this ticket blocks a game.** The meter reports; 047 is what
refuses. Splitting it this way means the counting can be wrong in a test rather
than in front of a player, and it means this ticket ships without a single
user-facing string.
