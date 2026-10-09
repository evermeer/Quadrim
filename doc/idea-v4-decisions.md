# Quadrim — Decision Log, fourth edition

Every non-obvious choice taken from here on: the question, the decision, and what it costs or buys.

Numbering continues from [history/idea-v3-decisions.md](history/idea-v3-decisions.md), which ended at **D391**. Decisions here are **D392 onward**.

Date opened: 2026-09-21

---

## How this file is used

- **One entry per non-obvious choice**, with a `## Dnnn — <what it settles>` heading, then **Question**, **Decision** and **Cost**. The cost is not optional: an entry that only records what was chosen is a note, not a decision.
- **Entries are never rewritten.** When a later decision reverses an earlier one, the earlier entry stays exactly as written and gains a line at the top saying which entry superseded it. The reasoning that produced a wrong answer is the most useful thing in the file, and editing it away is how the same wrong answer gets reached twice — which has happened here.
- **Cite the number from the code.** A comment that says *why* should carry its D-number, so the reasoning is one grep away from the line it explains.
- **Numbers are taken from the trunk, not from a release branch.** Two branches each taking "the next number" collide on merge; taking the next number free on the trunk costs nothing.

The three preceding editions folded their decisions back into the brief and the spec once the log grew long enough that nobody would read it end to end. The same applies here: [idea-v4.md](idea-v4.md) and [idea-v4-spec.md](idea-v4-spec.md) are where a decision *lives* once it is settled, and this file is where it is *argued*.

---

## D393 — The plugin returns a string on success and throws on failure, and D391 read it backwards

**Question:** 0.2.0 (15) is live with the Game Center entitlement, and Game
Center still does nothing: the leaderboard button raises the sign-in banner and
opens no view, a win reaches no board, no achievement unlocks, and the
achievements earned before sign-in never arrive. Three of those were supposed to
be fixed by D390 and D391. What is actually wrong?

**Decision:** Three defects, one of them introduced by the fix for the last one.

### The live cause: the adapter inverts the plugin's contract

`games_services` 5.3.0 signals **success by returning a non-empty string** and
**failure by throwing**. Read out of the package rather than inferred:
`Messages.success` is `"Success"` and is what `showLeaderboards` and
`showAchievements` return when the view opens; `signIn` returns
`"Player authenticated successfully"` or `"Player already authenticated"`. Every
failure path goes through `error.flutterError(code:)`, which arrives in Dart as
a thrown `PlatformException`.

D391 concluded the opposite — *"the plugin reports failure as a returned string,
not as a throw"* — and added `_orThrow`, raising whenever the string was
non-empty. So every **successful** call became an exception, `_guard` swallowed
it, and the app reported the refusal it had invented. `offerSignIn` therefore
always left `available` false, which is why `_openAfterSignIn` never even called
`show()`, why `submitRating` and `reportQuests` returned at their first line,
and why the backfill — gated on a view having opened — never ran. One line, all
four symptoms.

**D391 was right about the symptom and wrong about the mechanism.** The buttons
really did do nothing on +12, and the cause really was outside this repository:
no Game Center entitlement, fixed in +14. The string was not evidence of
anything; it was the success it had always been.

### Why no test caught it, which is the part worth keeping

`game_services_test.dart` fakes `GameServicesPlatform` — the interface this app
owns — so it proves everything above the adapter and nothing about the adapter,
which is the only place the plugin's contract lives. The seam that exists to
make the store testable had quietly become the reason the store was never
tested. `game_services_adapter_test.dart` now drives the real adapter against a
mocked `games_services` method channel: a success string must not throw, a
`PlatformException` must reach the caller, and the ids and the 100% completion
must arrive as sent.

### The second defect: iOS never authenticates at launch

`start()` asked `isSignedIn()` and nothing else. On iOS that reads
`GKLocalPlayer.isAuthenticated`, which stays false until something sets the
authenticate handler — and only `signIn` does. So the answer was "no" on every
launch however long the player had been signed in, and a win went unreported
until they happened to tap a Game Center button in that same session. `start`
now takes `previouslyAccepted` and authenticates when it is true.

**This does not reopen D390.** Authenticating is silent for a player already
signed in at the system level; GameKit completes the handler with no view
controller. The banner appears only to someone *not* signed in, which is the
case D390 refused to impose on a splash screen — hence the gate on the stored
answer. A player who declined, or who has never been asked, is still left alone.
The settings document is read in `main` rather than inside `GameServices`, which
owns no storage and should not learn about documents to answer one question.

### The third: the backfill fired on a transition that no longer happens

It ran only when a tap moved the app from signed-out to opened. Once launch
re-authenticates, a returning player is already available when the first tap
arrives, so that transition never occurs and their history is never sent —
fixing the second defect would have created this one. `backfill` now owns its
own guard: a signed-in player, and once per session. The home screen calls it
from the fold that already computes the quest list and from the tap, and both
are safe.

**Cost.** `main` now awaits a local file read before `runApp` that it did not
await before; it is the settings document, already on the launch path, and the
network half stays unawaited. The adapter tests pin *this app's reading* of a
third-party contract rather than the contract itself, so a `games_services`
upgrade that changes the strings will leave them passing and the app broken —
the version is named in the test file and in the pubspec, and that pairing is
the only thing holding it. And `_reported` plus `_backfilled` now both guard
repeats, which is one guard more than the problem strictly needs; the second
exists because the first does not stop forty-six no-op plugin calls after every
finished game.

**No new build was needed to find any of this.** The plugin's source is in the
pub cache, and every claim above was read out of it rather than reasoned from
the symptom — which is what the previous two attempts did.

## D394 — The rating and the leaderboard button stop competing for one column

**Question:** At the default font scale a rating of 2400 renders as "240" and
the button beside it reads "Leaderbo…". D392 tuned the flex ratio and then the
button's font size to fix exactly this, and both defects survived. What is
actually wrong?

**Decision:** The button leaves the rating's row and takes a line of its own
across the whole card, under the cube. The rating gets a `FittedBox`.

**Measured before it was changed**, because the failure is invisible in the way
that matters. A `Text` with `maxLines: 1` and no `overflow` inside a `Flexible`
too narrow for it does not ellipsise — it clips. So 2400 does not become "240…",
it becomes **240**: a plausible rating, confidently drawn, with nothing on
screen admitting a digit is missing. `rating_card_fit_test.dart` compares the
painted width against what the same string wants:

| | painted | wanted |
|---|---|---|
| 2400 at 1.0x | 100.3dp | 144.0dp |
| 2400 at 1.6x | 132.3dp | 230.4dp |

**Two things competing for one shrinking space is a structure, not a number to
tune.** The rating and the button shared a column the cube had already taken
96dp from, and no division of the remainder fits both: a word is wider than a
number at every scale, and the number is the one that must never be wrong. D392
gave the button two shares to the rating's one and then dropped its label to
12sp; the measurements above are from *after* both. That is D374 again — an
overflow is fixed by removing the constant, not by choosing a better one.

**So the competition is removed rather than rebalanced.** The button now sits
below the row that holds the cube, so its line spans the full card and the label
is drawn at the button's own size with nothing to give up; the 12sp override is
gone with it. The rating has the left column to itself. The association D390
wanted — the board *is* this rating — survives: same card, directly under the
number and the record it ranks.

**The `FittedBox` is belt and braces, and it is the pattern already in this
file.** The points row uses it with the reason stated there: the number is the
fact, so it gives up size before it gives up a digit. At 2x on a 320pt phone the
cube is already dropped and a 72pt numeral still very nearly fills the card, so
the rating needs the same treatment rather than the same trust.

**Cost, and it was not hypothetical.** The card is one row taller wherever the
button is drawn, which is every iOS build and every Android build once the Play
Console ids exist. That is about 56dp, and on the 360x800 phone
`game_center_ui_test.dart` uses it was enough to push the *quests* panel's
Achievements button below the fold — a test that had tapped it without scrolling
started hitting the background instead. The main screen is a scrolling list and a
player reaches that button by scrolling, so the test now scrolls; but the height
is real and it is the first thing to look at if the card ever runs off the
bottom again. `accessibility_test.dart` and `main_screen_test.dart` still pass
at 2x. The alternative was to keep the
button beside the number and shrink the *word*, which is what had already failed
twice.

## D395 — The app matches the store's typo, because the store cannot be corrected

**Question:** Fourteen of the forty-six Game Center achievements were created in
App Store Connect with an extra `beat.` in their ids —
`nl.evict.quadrim2.beat.days_in_row.5` where the app sends
`nl.evict.quadrim2.days_in_row.5`. The volume and streak families therefore
never unlocked, while the thirty-one per-opponent ones did, because `beat.`
belongs on those. Which side changes?

**Decision:** The app. `beat.` is now part of the fourteen ids it sends.

**Because the store cannot change.** A Game Center achievement id is fixed once
published and **a deleted id can never be reused** — the same rule as a product
id (D213, D365). Correcting the console would mean destroying fourteen live
achievements and permanently burning the correct names to get them back. The
app's constant is a line of source. There is no symmetry here to weigh: one side
is free and the other is irreversible.

**The ids are invisible to players**, which is what makes this cheap rather than
merely unavoidable. Nothing a person reads changes; `beat.days_in_row.5` renders
as "Five days running" exactly as before.

**The word is kept where it is wrong, not hidden in the helper.** Folding
`beat.` into `_gc` would have produced the right strings and made the prefix
look deliberate at every call site. It is a named constant, `_publishedTypo`,
used only by the two families that carry it by mistake — so the next person to
add an achievement sees a decision rather than a convention, and has to ask
which of the two shapes theirs takes.

**The draw achievement was entered correctly** and keeps `nl.evict.quadrim2.tie`
— confirmed rather than assumed, because guessing would have produced exactly
the failure being fixed, silently, in the one achievement whose id already
disagrees with its key (D386).

**`doc/store/achievements.json` is the source of truth and moved first**; the
setup guide's tables and both CSVs are regenerated from it, so the console and
the app are described by one file (D379). `store_catalogue_test.dart` binds that
file to the derived catalogue and is what would have caught this had the
comparison ever been against the real console rather than against the JSON.

**Cost, and it is the interesting one.** The repository now carries a name that
is wrong on purpose, and the only thing keeping it wrong-on-purpose rather than
wrong is a comment. More importantly: **nothing in this project can detect this
class of defect.** A missing or misnamed achievement fails silently by design —
`_guard` swallows it, because a store outage must never reach a game loop — so
fourteen achievements were dead for as long as the feature has existed and the
only reason anyone noticed was a person looking at a shelf and counting. The
audit in `tools/storegen/store_audit.py` exists precisely to diff the console
against this file, and it has never been run against the live console; that is
what would have caught it in seconds.

## D396 — The subscription lifts the meter, which it never did

**Question:** A player who bought "unlimited play" was still refused a tenth
game in the week. `Shop` set `entitlement.unlimited`, and the only thing that
read it was the quests panel's `capped` flag. `meterState` knew about the free
month and nothing else, and both gates in `HomeScreen` ask only `meterState`.
Where does the subscription enter?

**Decision:** `meterState` takes `unlimited` and blocks nothing when it is set.
`HomeScreen._meter` passes the shop's entitlement as it stands at the tap.

**Because both gates already route through that one function**, and it is pure,
so the rule is a test in `meter_test.dart` rather than two guards at two call
sites. `inFreeMonth` is left alone: it is a statement about the month, and the
quests panel already reads the subscription separately.

**What it costs:** the entitlement still fills in only after the store answers
at launch (D349). A subscriber who taps "new game" in the first seconds, before
the restore arrives, can still meet the paywall once.
