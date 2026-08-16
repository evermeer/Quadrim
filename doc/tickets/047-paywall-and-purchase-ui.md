# Ticket 047 — The paywall, the purchase screen, and the restriction copy

**Depends on:** 045 (the meter), 046 (products and entitlement)

**Status:** blocked by 045 and 046

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
