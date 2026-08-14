# 036 — The computer ladder seeds at 800

**What to build:** A new player's computer rating starts at **800**, not 1200.

D226 moved it there and gave the reason: a player seeded at 1200 against a roster that starts at 600 spends their first week watching a number fall, which is the opposite of the story the ladder is telling. At 800 they sit just below Clover, above the two weakest opponents, with somewhere obvious to climb.

Ticket 027 shipped 1200 because it was built before that decision existed, and the ticket breakdown in D269 did not cut a ticket for the change — so the specification (§7.2, criterion F9) and the code have disagreed since, with nothing scheduled to reconcile them. This is that ticket.

**Every existing rating changes, and no migration is written.** The computer rating is a fold over stored games with nothing persisted, so moving the constant re-derives every player's history from the new seed the moment the app next opens. That is not a side effect to be worked around — it is the property that makes the rating impossible to drift from the games that produced it (D227).

The owner's call, recorded here because it is a judgement rather than a derivation: **the re-derived numbers are approximately right and no correction is needed.** A player who had started at 800 would have gained slightly more per win than they actually did — the Elo step is larger when you are further below your opponent — so the re-fold understates them a little. Against twelve closed testers who do not exist yet, that is noise. Writing a migration to preserve numbers nobody has seen would cost more than the numbers are worth.

**The constant keeps its name.** `kSeedRating` becomes 800 and its doc comment says plainly that it is the *computer* ladder's seed. D226 notes that "seed" becomes a per-ladder constant, and the human ladder's 1000 arrives at 0.4 — but the human rating is not this fold at all (spec §7.2: Elo is not separable per player, so it is a global chronological replay rather than a per-player fold), so it will bring its own constant rather than share this one. Renaming forty call sites now to anticipate a constant that will not be shared is churn.

**Blocked by:** nothing.

**Status:** ready-for-agent

- [x] A new player with no history has a computer rating of **800** — spec criterion F9
- [x] The human ladder's seed of 1000 is **not** introduced here; it arrives at 0.4 with the rating it belongs to, and the doc comment says so
- [x] No migration, no stored rating, and no second copy of anything: the fold is still the only source
- [x] K is still 32 for the first 20 games and 16 after, the floor is still 100, and a draw still scores one half — this ticket moves one number and nothing else
- [x] Every test that pinned a value derived from the old seed is corrected rather than deleted, and any test whose *meaning* changed at the new seed says so
- [x] `tool/check.sh` passes

## How this was closed

One constant, and **fourteen tests** — none of them broken, every one of them
newly wrong about a premise that had moved. That ratio is the whole story of
this ticket and the reason D227 says what it says.

Moving the seed moves where a new player is *standing*. The tier accordion
opens at the tier nearest the player, so a seeded player now lands on Novice —
Mote is rated 800 exactly — where they used to land on Casual. Four tests
tapped a tier heading to open a section that is now already open, and so shut
the very list they were about to look inside. A seeded player's fair-match band
moved with them: 1250 read "even" and now reads "above your level", while 900
reads even.

The case worth keeping in mind is the rounded-away rating step. The UI branches
on it — a zero step gets no arrow rather than one claiming a movement that did
not happen — so a test that stopped producing zeroes would have quietly rotted
that branch. From 1200 a single win over a 100-rated opponent rounded away;
from 800 the same win pays 1. It is still reachable and the test now reaches it
the way a player actually does: climb past the twentieth game where K halves,
then beat the weakest opponent on the roster from far above it.

No migration, and none needed: nothing stores a rating, so the fold simply
re-derives from 800. The owner's call that the re-derived numbers stand is
D278.

Review in `codereview-main.md`: no findings.
