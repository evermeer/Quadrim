# Ticket 050 — Play Games Services and Game Center: the leaderboard and the achievements

**Depends on:** 022 (1.0 is out). **Blocks:** 051.

**Status:** **code complete, unverified against either store.** Everything that
can be built and tested without a console is done and under test; nothing has
been reported to Play Games or Game Center, so AC 1 through 3 are proven only
against a fake and AC 10 needs both consoles. **Stays in `doc/tickets/`** for the
same reason ticket 046 did. See the closure.

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
Recorded as D376.

**What genuinely must be amended is D2 and S2**, "no device identifier is
generated, stored or transmitted anywhere". Both services identify the player:
Play Games issues a Player ID, Game Center a `gamePlayerID` scoped per developer.
The app neither generates nor stores either one — but it does cause one to be
transmitted, and pretending otherwise would be the kind of privacy claim this
project has twice refused to make (D72). Recorded as D377.

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

**Forty-five, not seventy-six**, and the mapping is a deliberate narrowing
rather than an omission (D378):

| Source | Count | Achievement |
|---|---|---|
| `first_win:<opponent>` | 31 | One per opponent — "you have beaten this opponent" |
| `first_win_second:<opponent>` | 0 | **Merged into the row above** |
| `games_in_day:<n>` | 5 | 5, 10, 20, 50, 100 games in a day |
| `days_in_row:<n>` | 9 | 5, 10, 30, 90, 180, 360, 720, 1080, 1440 consecutive days |

**Why the two per-opponent families merge into one.** `firstWinSecond` is a
strict subset of `firstWin` — a win from the second seat is a win — so a player
who earns the harder one has already earned the easier one, and two achievements
would fire together and read as a bug. In the app they are worth telling apart
because they pay separately. On a store achievement list they are one thing said
twice.

**The cap matters and is close.** Game Center allows 100 achievements per app.
Forty-five leaves room for fifteen more opponents and no more; a roster past
about forty-six breaks it, and there is no migration once achievements are live.
Ticket 051 must not spend the headroom casually. **The 1000-point budget is the
tighter of the two**: the forty-five sum to 980, and the cap is on the sum, so
every new achievement re-prices every existing one (D379).

**Every achievement needs an icon**, 512×512, in both consoles. The opponent
avatars in `doc/designs/` cover thirty-one of them; the fourteen volume and streak
rungs are drawn and in place, named `games_in_day_<n>.png` and
`days_in_row_<n>.png` — the quest id with its colon replaced by an underscore, so
the mapping is mechanical rather than a lookup (D379). Prompts are in
[achievement-icons.md](../achievement-icons.md); the console steps and the full
id table are in [store-game-services-setup.md](../store-game-services-setup.md).

**Nothing is incremental.** Both stores support partial progress on an
achievement, and this ticket does not use it: every one of the forty-five is
unlocked or not. Incremental reporting means sending a number on every game, which
is more traffic and more surface for no gain the player can see.

## 5. Identity, and what the app is allowed to keep

**The app stores no player id, ever.** Not the Play Games Player ID, not the
Game Center `gamePlayerID`, not a display name, not an avatar URL. Everything the
services need is asked for at the moment it is used and thrown away.

This is not squeamishness; it is what keeps D377's amendment narrow. "The app
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
- **`achievements.dart`** — the forty-five, as a table from a stable Quadrim key
  to a Game Center id and a Play Games id. **The Play ids are issued by the
  console and are not knowable here**, so they are placeholders until the
  developer fills them in, and a test asserts the table is complete rather than
  asserting particular strings.
- **`GameServices`** — the object the app talks to. It takes the quest statuses
  and the rating, works out what is newly true, and reports it.

**It reports a diff, not a state.** The app already computes `newlyAchieved`,
which is what the end-of-game panel uses. Reporting only what just became true is
the difference between one call a game and forty-five.

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
than a product id can (D213, D365). The forty-five ids are permanent from the day
they go live.

## Closure

`bash tool/check.sh`: **ALL CHECKS PASSED**, 446 app tests (was 422).

### What exists

`app/lib/services/`, and nothing outside `app/` gained a dependency — the purity
scan still passes, so AC 9 is met.

- **`achievements.dart`** — the forty-five, **derived from the same catalogues
  the quests are built from** rather than typed out, so the roster and the rungs
  cannot drift from the quests they mirror. Only the store ids are hand-written.
- **`games.dart`** — `GameServicesPlatform`, the interface this app owns over the
  plugin, its adapter, and `GameServices`.
- Wired through `main.dart` → `HomeScreen` → `GameScreen`, optional at every
  step, so every existing widget test builds the app without one.

`GameServices.start()` is called and **not awaited** at launch, like
`Shop.start()` and for the same reason (D351). `_report` in `game_screen.dart`
is called from `_loadOutcome` and awaits nothing.

### What is tested

`game_services_test.dart`, 19 tests against a fake, and
`game_services_wiring_test.dart`, 5 more that drive the real game screen over the
real repository. **The second file exists because the first cannot fail if the
wiring is missing** — it proves `GameServices` behaves, not that anything calls
it.

The ones that matter: the catalogue is complete in **both** directions (a table
entry naming a dead quest, and a quest family growing unmapped, fail differently
and only one is visible); `first_win_second` reports nothing; a failing platform
leaves the result panel rendering and throws nothing; and Android does nothing at
all while the Play ids are unset.

### Verified on a device, and what it did not prove

The debug APK was installed on an emulator carrying **Google Play services
25.26.35 and the Play Store**, and the app launched and rendered normally. That
matters because `PlayGamesInitProvider` is a `ContentProvider` with `initOrder=99`
which the SDK merges into the manifest — it runs before anything of ours.

**It does not prove the Play Games path works**, and the reason is worth keeping:
the app never called in, because `playGamesConfigured` is false and `_configured`
therefore gates every method. The launch proves the SDK's presence is harmless,
not that sign-in succeeds.

### The trap waiting for whoever fills in the console ids

**Play Games v2 needs `com.google.android.gms.games.APP_ID` meta-data in the
application element**, valued at the Play Games project number. It is **not**
present in the merged manifest today, and it must be added in the same change
that fills in the ids in `achievements.dart`. Filling in one without the other
gives a build that launches and then fails at sign-in.

### Acceptance criteria

| AC | Status |
|----|--------|
| 1 — a scored computer game submits the rating | **Covered by test, not by a store.** |
| 2 — pass and play submits nothing | **Met**, tested through the real game screen. |
| 3 — a newly achieved quest reports its one achievement, once | **Covered by test.** |
| 4 — `first_win_second` reports nothing | **Met**, tested both in the catalogue and end to end. |
| 5 — the table is complete in both directions | **Met**, asserted by test. |
| 6 — a failing or signed-out platform changes nothing | **Met**, tested three ways. |
| 7 — no identifier stored, allowlist unchanged | **Met.** Nothing here writes a document; `backup_rules.xml` and `data_extraction_rules.xml` are untouched and still include-only. |
| 8 — sign-in offered once | **Partly.** `offerSignIn` returns what to persist and `SignInOffer` exists; **no UI offers it yet and nothing stores the answer**, so a player is never asked. Named here rather than left to be found. |
| 9 — no package outside `app/` gains a dependency | **Met.** Purity scan passes, and it now also rejects `package:http` and `games_services`. |
| 10 — privacy declarations updated in the same release | **Not met**, and it is a release gate rather than a code task. |
| 11 — `check.sh` passes with the offline check replaced | **Met** (D376). |

### What has to happen next, and by whom

1. **The Play Games console**: a project, an OAuth2 client, the app linked, and
   the SHA-1 of **Google's** app-signing certificate rather than the local upload
   key. Then the 44 achievements and the leaderboard, and their ids pasted into
   `achievements.dart` — **with the `APP_ID` meta-data**, per the trap above.
2. **App Store Connect**: Game Center enabled, the leaderboard and the 44
   achievements created with the ids already in `achievements.dart`.
3. **44 icons at 512x512.** The opponent avatars cover 31; the 13 volume and
   streak rungs need drawing.
4. **Both privacy declarations**, in the same release (AC 10).
5. **The sign-in offer UI**, which is AC 8's missing half.
