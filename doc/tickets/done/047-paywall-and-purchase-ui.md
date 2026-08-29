# Ticket 047 — The paywall, the purchase screen, and the restriction copy

**Depends on:** 045 (the meter), 046 (products and entitlement)

**Status:** **done.** All ten acceptance criteria were already met and tested;
the one thing holding this ticket in `doc/tickets/` was that no one had seen the
shop screen against real products. The products now exist and the shop works, so
that condition is met and the ticket moves to `done/`. The end-of-game
remaining-games line is still deferred and still named in the closure.

## Why

045 counts and 046 sells. This is the ticket where the cap actually stops
someone, where the thing being sold is described, and where the quest tiles
stop lying to free players.

It is also the first user-facing text this project has written that asks for
money, in two languages, and every string goes through l10n like all the rest
— `check.sh` rejects `Text('...')` with letters in `app/lib` (D297).

## What it does

### 1. The wall

A new computer game against the cap is refused, and **the message names the
limit that actually bit** (D221, F16). "You have used this week's nine games"
and "come back tomorrow" are different sentences and only one of them is true
on a Thursday. Saying the wrong one teaches the player that the app does not
know its own rules.

What is refused is **starting a new game against the computer**. Not
finishing one in progress, not pass-and-play, not the tutorial's practice
game, not replay (§4.2).

**The copy must not overstate the meter.** At 1.0 it is device-local and a
reinstall clears it (D303, S19). Nothing in this UI may claim or imply a
guarantee the release does not have — no "you have used your free games on
this account", because there is no account.

### 2. The purchase screen

One screen, reachable from the wall and from settings, showing both products.
It states plainly what each does, and in particular what the one-time unlock
does **not** do: a buyer still plays three games a day unless they also
subscribe. That is deliberate — the unlock sells impatience, not capability
(§4.1) — and a player who discovers it after paying has been misled.

The Master-tier qualification survives into any copy that mentions the top
opponents: never "perfect", always **"unbeatable when it moves first"**
(D181, P21).

**Restore purchases** lives here and in settings.

### 3. The volume-quest restriction copy

§7.4 has been waiting for this release. Five games in a day exceeds the free
cap of three, so **no free player can complete even the first rung of the
volume ladder** — subscriber-only by arithmetic rather than by a rule.

Until now that copy would have been false, because there was no cap; the quest
tiles have shipped since ticket 033 with no restriction text at all. From 1.0
it is true, so the tiles show the requirement and a free player sees why it is
out of reach and what would change it. **A permanently unreachable goal
presented without explanation reads as a bug.**

### 4. The end-of-game panel

It already shows the rating change, the points, any quest completed and the
next unlock if the win just paid for it (U19). It gains the one line the meter
makes necessary: how many games remain today, when that number is small.

Not a countdown on every result — a number that appears when it starts to
matter. A player told "2 of 3 remaining" after every single game is being
nagged by their own game.

## Acceptance criteria

1. A player at the daily cap who starts a computer game is refused, and the
   message names the daily limit (F16).
2. A player at the weekly cap but not the daily one is refused with the
   **weekly** message.
3. A game in progress can always be finished; pass-and-play, the practice game
   and replay are never refused.
4. The purchase screen states that the one-time unlock does not lift the cap.
5. Restore purchases is reachable from settings and from the purchase screen.
6. Volume quest tiles state their requirement, and a free player is told why
   the rung is unreachable and what changes it.
7. No user-facing string exists outside l10n, and every string exists in
   English **and** Dutch — enforced by the build.
8. Every screen renders on the smallest and largest supported phone at the
   largest font scale (U20). The paywall is new and has not been through that.
9. No paywall or purchase copy claims a guarantee 1.0 does not have (S19).
10. `bash tool/check.sh` passes.

## Notes

**Dutch is not a translation afterthought here.** Store copy and price
formatting are the two places where machine-translated text reads as a scam,
and the app has been bilingual since 0.1 precisely so this would not be
special. `intl` formats the price the store gives you; do not build the string
by concatenating a currency symbol.

## Closure

**All ten acceptance criteria are met. One item from "What it does" is not, and
it is named below rather than left to be discovered.**

`bash tool/check.sh`: **ALL CHECKS PASSED**, 372 app tests (was 366).

### The wall

`showPaywall` names the limit that actually bit. The daily and weekly messages
are different strings with different remedies — "the next one is available
tomorrow" against "the next one is available on Monday" — and the test that
matters drives a Wednesday with nine games already used this week and none of
them today, so the daily cap has room and only the weekly one refuses. Saying
"tomorrow" there would be false, and that is the whole of D221.

**Checked in two places, and only one is the guard** (D352). `_start` is the
single place a game is created, so the challenge and rematch buttons cannot
slip past it; `_newGame` checks earlier so the refusal does not arrive after
the player has already chosen an opponent. The order inside `_start` is what
makes criterion 3 true — the resume loop returns first, so a game in progress
is never refused, and pass and play is excluded by `mode`.

### The shop

One screen from the wall and from settings. **The one-time unlock's caveat is
given the same visual weight as its description**, in bold, above the price: a
buyer who discovers afterwards that they still play three games a day has been
misled, and the unlock sells impatience rather than capability (§4.1).

Prices are the store's own formatted strings, never built by concatenating a
symbol — the ticket is explicit and it is one of the two places an app reads as
a scam.

`shopMeterNote` says the free games are counted **on this device**, which is
what S19 requires and what stops any copy here implying an account that does
not exist at 1.0.

### The quest tiles

Volume rungs are marked "Needs unlimited play" when the cap applies, and the
mark is derived from the family and the current entitlement rather than stored
on the quest (D354) — `quadrim_progression` may no more know what a
subscription is than the engine may know what an unlock is (§7.1).

The mark is absent inside the free month and absent for a subscriber. Tested
three ways, including that a *non*-volume quest is never marked: every
per-opponent and streak rung is completable on three games a day, so marking
them would be false.

### Not done, and deliberately

**The end-of-game panel does not yet show how many games remain today.** It is
in §4 of this ticket and it is not an acceptance criterion. Doing it needs the
settings document threaded into `GameScreen`, which currently takes the game
repository, the unlocks and a clock but not settings — a second screen's worth
of plumbing plus its own tests. It was left rather than rushed, because a
half-wired meter on the result panel would show a wrong number to a player who
has just finished a game, and a wrong number there is worse than no number.

Everything it needs exists: `MeterState.remainingToday` is already written and
tested in `quadrim_progression`, and already returns the min of the two limits
for exactly this purpose.

### Acceptance criteria

| AC | Status |
|----|--------|
| 1 — daily cap refused, names the daily limit | **Met**, tested. |
| 2 — weekly cap names the *weekly* message | **Met**, tested on a day with daily room left, which is the only fixture that can tell the two apart. |
| 3 — in-progress finishable; pass and play, practice and replay never refused | **Met.** Pass and play tested; the resume path returns before the wall; the practice game is never stored so it cannot reach the meter. |
| 4 — the purchase screen states the unlock does not lift the cap | **Met**, and in bold above the price. |
| 5 — restore reachable from settings and the purchase screen | **Met**, both. |
| 6 — volume tiles state the requirement and why it is out of reach | **Met**, tested three ways. |
| 7 — no string outside l10n, English and Dutch | **Met** — `check.sh` greps for it, and every key was added to both `.arb` files in the same edit. |
| 8 — renders at the layout extremes | **Met.** The paywall is driven at 1080×1920 and 1290×2796, at text scale 1 and 2; overflow surfaces as an exception and `takeException()` is asserted null. |
| 9 — no copy claims a guarantee 1.0 does not have | **Met** (`shopMeterNote`, S19). |
| 10 — `bash tool/check.sh` passes | **Met.** |

### What is still unverified

**Resolved.** This section said the shop screen shows its unavailable state
because 046's products did not exist. They exist, the shop resolves them, and it
has been tested against a real store (046's closure amendment). The prices on
screen are now the store's own formatted strings for real products rather than a
fake's, which is the one thing the store-less tests could never cover.

**Two things are still not verified, and neither is an acceptance criterion
here.** The end-of-game remaining-games line is still not built, for the reason
above. And the paywall's own copy has never been read by a store reviewer — the
submission in review is what settles that, and a rejection over subscription
metadata or a missing Terms of Use link would land on this screen and on ticket
049, not on the meter underneath it.
