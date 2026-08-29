# Ticket 051 — Cloud save, challenges and friends

**Depends on:** 050 (the services exist and the player can sign in).

**Status:** blocked on 050

## Why

Three things, kept in one ticket because they share the same sign-in and the same
privacy declaration, and split from 050 because none of them is a leaderboard.

**Cloud save is the valuable one.** "The computer rating is local to this device
and does not follow the player to another platform" is a recorded known limitation
of 1.0 (D304), and until 2.0 builds accounts there was no answer to it. Both
stores already run a per-player save-file service. It retires the limitation
without this project owning a single row of anyone's data.

**Challenges and friends are the cheap test of an expensive assumption.** 2.0's
online play and 3.0's tier-3 subscription both rest on players wanting to play
people they know. Ticket 024 was supposed to measure that and closed without doing
it (D373), so the assumption is currently untested and two releases are planned on
top of it. A challenge is one tap and it either gets used or it does not.

## 1. Cloud save

**What is saved: the whole document set.** Games, settings and unlocks — the same
three things the backup allowlist covers, for the same reason. `DocumentStore`
already abstracts bytes from meaning, so the snapshot is that store serialised.

**The conflict is the whole problem, and it is not a merge.** Two devices, each
with games the other has never seen, is the normal case rather than the edge one:
a player installs on a tablet, plays three games, and opens the phone. What must
never happen is a silent loss.

- **Games are append-only and identified**, so two sets union cleanly. This is the
  one part that genuinely merges, and it works because `GameState` derives
  everything from the move list (§7.2) — there is no counter to reconcile.
- **Unlocks union too**, and `source` survives, because a purchase-sourced unlock
  and a points-sourced one are different records (D348).
- **Settings do not merge.** Last write wins, and the loser is the *device*, not
  the player's history. A board-style preference is cheap to lose; a game is not.
- **The rating and the points balance are not saved at all** — they are folds
  over the games (§7.2, §8.8), so unioning the games reconstructs them. Saving a
  computed number would create exactly the second source of truth this project has
  refused everywhere else.

**Restore never runs unprompted on a device that already has games.** A player
who has been playing offline for a week and then signs in must be asked, and the
question must name what happens: merge, or keep this device's. The default is
merge, because it is the one that cannot lose anything.

## 2. Challenges

**"Beat my rating"** — the player sends their current rating to a friend, who is
invited to exceed it. Both stores support this natively; neither needs a server.

- Reachable from the rating card and from the end-of-game panel after a rating
  rise, and from nowhere else. A challenge offered after a loss is a taunt.
- **It sends a number and a name the store already knows.** No message body, no
  free text — 2.0's chat is where free text arrives, and it brings a moderation
  problem this ticket must not acquire early.
- Declining, ignoring, and having no friends are all normal and silent.

## 3. Friends

Only what the leaderboard needs: the social scope, so the board can be filtered to
people the player knows. **No friends list is stored, rendered, or read into the
app** — the store's own UI shows it, and the app asks for the permission at the
moment the player chooses the social board.

Play Games and Game Center both gate the friends list behind a consent prompt.
That prompt is the player's decision and must be asked at the point of use, never
at launch.

## 4. Acceptance criteria

1. A signed-in player's games, settings and unlocks are saved after a game
   completes, best-effort and never blocking.
2. A second device signing in with an empty store restores everything.
3. A second device signing in with games of its own is **asked**, and the default
   choice loses nothing.
4. A merge unions games and unlocks by id; no game is lost in either direction.
5. The rating and the balance after a merge equal a fresh fold over the unioned
   games — asserted by test, because this is the one place a wrong answer is
   invisible.
6. A challenge can be sent after a rating rise and is never offered after a loss.
7. The friends permission is requested at the point of use, and refusing it leaves
   the global leaderboard working.
8. No friends data and no player identifier is stored in any document.
9. Cloud save is off for a signed-out player and the app is unchanged.
10. `bash tool/check.sh` passes.

## Notes

**Do not let cloud save become a sync engine.** It is a snapshot push and a
snapshot pull with a union on top. Real-time sync, per-document versioning and
conflict UI beyond the single question in §1 are 2.0's problem, and 2.0 has a
server to do it properly with.

**Game Center's saved games are per-player iCloud containers** and need the
capability enabled; Play Games' Saved Games needs the Drive scope, which is a
*second* consent prompt on Android and a real drop-off point. Measure whether
anyone says yes before building anything else on top of it.

**The achievement cap from 050 applies here.** Game Center allows 100 and 44 are
spent. Nothing in this ticket should add achievements.
