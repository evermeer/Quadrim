# Ticket 050 — Play Games Services and Game Center: the leaderboard and the achievements

**Depends on:** 022 (1.0 is out). **Blocks:** 051.

**Status:** ready-for-agent

## Why

Quadrim has a rating and seventy-five quests and nobody outside the device can
see either. Both stores run an identity and social layer that already knows the
player, already has a friends graph, and already renders leaderboards and
achievements far better than this app is going to. Using it costs a plugin and a
lot of console data entry; not using it means the progression system stops at the
edge of the phone.

**This ticket changes the project's oldest promise**, so read §1 before anything
else.

## 1. The thing that changes, and the thing that does not

Google Play Games Services cannot work without `android.permission.INTERNET`.
The permission is *app-wide* — Android has no way to grant it to one screen — so
the mechanism that has enforced offline play since D93 has to go.

**What is deleted is the enforcement, not the claim.** Spec F13 and S1 are, and
have always been, scoped to *a game against a computer opponent*:

> F13 — Any game against a computer opponent | it is played from first move to
> result | **no network call is made at any point**

That stays true and stays in the specification. Nothing in this ticket makes a
call during a game: the rating is submitted after a game is scored, achievements
are reported at the same moment, and the engine still has no network dependency
of any kind and still declares no runtime dependencies at all.

What changes is that S1 and F13 become **reviewed rather than enforced** on
Android — which is precisely the status iOS has carried since S20 and D306.
Recorded as D375.

**What genuinely must be amended is D2 and S2**, "no device identifier is
generated, stored or transmitted anywhere". Both services identify the player:
Play Games issues a Player ID, Game Center a `gamePlayerID` scoped per developer.
The app neither generates nor stores either one — but it does cause one to be
transmitted, and pretending otherwise would be the kind of privacy claim this
project has twice refused to make (D72). Recorded as D376.

**Two declarations become false the moment this ships** and must be updated in
the same release, not after it: Play's Data Safety form and the App Store privacy
labels both currently say the app collects nothing. `PrivacyInfo.xcprivacy` needs
re-examining too, though Game Center's own data is Apple's collection rather than
ours.

## 2. What is sold to the player

Nothing. This is not a product; it is the progression system becoming visible.
There is no new purchase, no new entitlement, and the meter is untouched.

## 3. The leaderboard

**One leaderboard: the computer rating.** An integer, the same number the main
screen's rating card shows, submitted whenever it changes — which is after every
scored game against a computer opponent.

- **Pass-and-play never submits.** It does not move the rating (F12), so there is
  nothing to send.
- **It is not verifiable, and the ticket says so rather than discovering it in a
  forum.** The rating is a fold computed on the device, with no server anywhere in
  the design (D303 said the same about entitlement). Anyone running a modified
  build can submit any number. That is the normal state of a casual leaderboard
  and it is the reason this is a *social* feature rather than a competitive one.
  No copy anywhere may call it a ranking of skill.
- **Higher is better**, integer score, no decimal places, and the display format
  is plain — the store renders it, and the store's own formatter is what handles
  the player's locale.

## 4. The achievements

**Forty-four, not seventy-five**, and the mapping is a deliberate narrowing
rather than an omission (D377):

| Source | Count | Achievement |
|---|---|---|
| `first_win:<opponent>` | 31 | One per opponent — "you have beaten this opponent" |
| `first_win_second:<opponent>` | 0 | **Merged into the row above** |
| `games_in_day:<n>` | 5 | 5, 10, 20, 50, 100 games in a day |
| `days_in_row:<n>` | 8 | 5, 10, 30, 90, 180, 360, 720, 1440 consecutive days |

**Why the two per-opponent families merge into one.** `firstWinSecond` is a
strict subset of `firstWin` — a win from the second seat is a win — so a player
who earns the harder one has already earned the easier one, and two achievements
would fire together and read as a bug. In the app they are worth telling apart
because they pay separately. On a store achievement list they are one thing said
twice.

**The cap matters and is close.** Game Center allows 100 achievements per app.
Forty-four leaves room for sixteen more opponents and no more; a roster past
about forty-seven breaks it, and there is no migration once achievements are
live. Ticket 051 must not spend the headroom casually.

**Every achievement needs an icon**, 512×512, in both consoles. Forty-four icons
is the largest single cost in this ticket and it is art, not code. The opponent
avatars in `doc/designs/` already exist and cover thirty-one of them; the thirteen
volume and streak rungs need something drawn.

**Nothing is incremental.** Both stores support partial progress on an
achievement, and this ticket does not use it: every one of the forty-four is
unlocked or not. Incremental reporting means sending a number on every game, which
is more traffic and more surface for no gain the player can see.

## 5. Identity, and what the app is allowed to keep

**The app stores no player id, ever.** Not the Play Games Player ID, not the
Game Center `gamePlayerID`, not a display name, not an avatar URL. Everything the
services need is asked for at the moment it is used and thrown away.

This is not squeamishness; it is what keeps D376's amendment narrow. "The app
transmits an identifier the platform issues" is a much smaller claim than "the app
holds an identity", and the second one would reach the backup allowlist, the
document schema and 2.0's account design all at once.

**A signed-out player is a first-class state, not an error.** Sign-in is offered
once, declined permanently if the player declines, and the whole app works
identically either way. Nothing is gated behind it.

## 6. Structure

`app/lib/services/`, and nothing outside `app/` gains a dependency —
`quadrim_engine`, `quadrim_rating` and `quadrim_progression` still declare none
and `check.sh` still enforces it.

- **`games.dart`** — `GameServicesPlatform`, an interface this app owns over the
  plugin, and its real adapter. The interface exists for the same reason
  `PurchasePlatform` does: the part that talks to a store has to be testable
  without a store in the room.
- **`achievements.dart`** — the forty-four, as a table from a stable Quadrim key
  to a Game Center id and a Play Games id. **The Play ids are issued by the
  console and are not knowable here**, so they are placeholders until the
  developer fills them in, and a test asserts the table is complete rather than
  asserting particular strings.
- **`GameServices`** — the object the app talks to. It takes the quest statuses
  and the rating, works out what is newly true, and reports it.

**It reports a diff, not a state.** The app already computes `newlyAchieved`,
which is what the end-of-game panel uses. Reporting only what just became true is
the difference between one call a game and forty-four.

## 7. Failure is silent

Every call here is best-effort. No network, no sign-in, a store outage, a player
who declined — none of it may produce an error the player has to dismiss, block a
game, or delay the end-of-game panel. The app has never needed the network and
still does not; this is a feature that either works or is invisible.

Concretely: nothing in this ticket may be `await`ed on a path that renders. The
precedent is `Shop.start()`, which is called and deliberately not awaited (D351).

## 8. Acceptance criteria

1. A scored game against a computer opponent submits the new rating to the
   leaderboard, on both platforms.
2. A pass-and-play game submits nothing.
3. A quest that becomes achieved reports exactly its one mapped achievement, once.
4. `first_win_second:<id>` reports nothing of its own.
5. Every one of the 44 achievements has an entry in the table, and every entry
   maps to a quest that exists — asserted by test, in both directions.
6. With the platform unavailable, signed out, or throwing, a game plays and
   completes with no visible difference and no dialog.
7. No player identifier is stored in any document, and the backup allowlist is
   unchanged.
8. Sign-in is offered once and never again if declined.
9. No package outside `app/` gains a dependency; the purity scan passes.
10. The Play Data Safety form and the App Store privacy labels are updated in the
    same release, and `doc/store-listing.md` records what they now say.
11. `bash tool/check.sh` passes — with the offline check replaced rather than
    deleted, per §1.

## 9. What this ticket does not do

Cloud save, challenges and friends are ticket 051. Turn-based multiplayer is not
in either and remains 2.0's problem — it was offered and declined.

## Notes for whoever picks this up

**The Play Games console setup is the long pole and it is all clicking.** A Play
Games Services project, an OAuth2 client, the app linked to it, and — because
this app uses Play App Signing — **the SHA-1 of Google's signing certificate, not
the local upload key**. Getting that wrong produces a sign-in that fails only on
the store build, which is the worst place to find it.

**Test the signed-out path first, not last.** It is the path most players will be
on for their first session and the one no simulator puts you in by accident.

**Achievements cannot be deleted after publication**, on either store, any more
than a product id can (D213, D365). The forty-four ids are permanent from the day
they go live.
