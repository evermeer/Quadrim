# 032 — Unlocks, and Your Path

**What to build:** The points earned in ticket 031 buy something, and the main screen shows what is next.

Fifteen of the twenty opponents start locked — every one rated above 1000. They are bought **strictly in roster order**: only the next locked opponent can ever be purchased, so a player cannot save up and skip to the top. Unlocking opponent *i* costs 2ⁱ⁺¹, which is exactly four wins against opponent *i−1*, so every rung costs the same effort all the way up even though the numbers reach seven digits.

**This ticket introduces the only stored record in the app that is not reconstructible from game history**, and that is worth being deliberate about rather than discovering later. Points *earned* is a fold; points *spent* is a decision, and a decision is not in the move list. So an unlock record exists, and it stores `pricePaid` for the same reason a game stores the opponent's anchor rating: re-tuning a cost later must never retroactively bankrupt someone who already spent at the old price.

It follows that unlocks must survive a device change. They are the only thing in this app a player cannot regenerate by playing, and losing them loses months of work. This costs nothing to get right — the backup allowlist is already `files/quadrim/`, so a record written beside the games inherits it with no manifest change.

**Your Path replaces the by-opponent breakdown**, which listed all twenty weakest-first and answered a question nobody was asking. The middle tile is the **next unlock**, not the next opponent above the player's rating. Those diverge exactly where it matters: a player seeded at 800 would get a rating-centred window of three opponents they already own, while their next unlock sits at 1100 outside it — so the price ladder, which is the entire motivation for the feature, would be invisible on first launch (D262).

**Blocked by:** 031 — The progression package, and points that accumulate

**Status:** ready-for-agent

- [x] An unlock document exists with `opponentId`, `unlockedAt`, `pricePaid` and `source`, plus `id` and `schemaVersion` like every other record
- [x] It is stored under `files/quadrim/`, so it is backup-eligible through the existing allowlist with **no manifest change** — and a test or a documented manual check confirms a restore on a second device returns it
- [x] `UnlockRepository` exposes watch, load and purchase, and is the only writer
- [x] The balance is points earned minus the sum of prices actually paid, **clamped at zero**
- [x] Only the lowest-indexed locked opponent may be purchased; any attempt at another is refused
- [x] An unlock bought at the old price survives a re-tune of the cost table, because the price is stored with it
- [x] **No unlock is ever revoked** — not by a re-tune, not by anything this release can do
- [x] There is still no stored balance; a test reconstructs it from games and unlock records alone
- [x] Your Path shows **three equal tiles** across the width, the middle one the next unlock, highlighted, with its price and the player's progress toward it
- [x] Each tile stacks vertically: full-tile-width avatar, name, rating, win/loss/draw record, stars, and an icon-only rematch button with a spoken label
- [x] The window **clamps at both ends** — a player who has unlocked nothing beyond the free five, or everything, still sees three tiles rather than a row with a hole in it
- [x] Locked opponents appear in full, greyed, with price and progress — hiding them would hide the goal
- [x] Stars count decisive games only: none for never-played or no wins, ★ below even, ★★ at or above even, ★★★ at 80% of decisive games won
- [x] An opponent never faced shows **no star row at all**, rather than three empty stars — unearned and failed must not look the same
- [x] `_OpponentSection` and its file are deleted, now that Your Path replaces it
- [x] `HomeSummary.byOpponent` is **kept** — Your Path's tiles need exactly those per-opponent records
- [x] Opponent selection rows carry lock state, price and progress, in the tier accordion that already exists
- [x] The unlock action exists both on the Your Path tile and in opponent selection, and both lead to the same confirmation
- [x] For Oracle and Quadrim Prime the confirmation repeats **"unbeatable when it moves first"** — the two most expensive unlocks buy opponents that cannot be beaten half the time, and the player must be told before they spend, not only in a store listing
- [x] A Your Path tile is **one** accessibility node: name, rating, record, stars, locked-or-not, and price if locked — announced once, not six times
- [x] Every locked state is stated in words, not carried by grey alone
- [x] All new strings are present in English and Dutch

## How this was closed

The unlock record is the first thing in the app not reconstructible from game
history, and it went in under `files/quadrim/unlocks/` — inside the path the
backup allowlist has covered since ticket 001, so it is backed up with **no
manifest change**, exactly as the spec predicted.

Sequential purchase is enforced in `LocalGameRepository.purchase` rather than
only in the UI, because the repository is the only writer and the promise is
about the *next* opponent. Buying out of order, buying a free opponent and
buying the same one twice are all refused and all tested.

`pricePaid` is proven to be what was charged rather than what the table says:
the test buys Willow at 40, not at `unlockCost(5)`, so a re-tune could not make
it pass by accident.

**Nineteen existing tests changed**, all for the same reason — they asserted
that an opponent's name appears twice on the main screen, which was true while
the by-opponent breakdown listed everything played. Your Path shows the window
around the *next unlock* instead, so on a fresh fixture that is Bramble, Willow
and Vireo and every other opponent appears once. A `_inGameRows` finder now
scopes assertions that mean "in the list of games", which is stricter than the
index-based finders it replaced. `RatingBar` was deleted with the breakdown that
was its only caller.

**One thing found and deliberately not fixed here:** `kSeedRating` is still
1200, while spec §7.2 and criterion F9 say 800 (D226). No ticket owns that
change, and it is not a one-liner — D227 records that moving the seed silently
rewrites every existing rating, because the rating is a fold with nothing
stored. Raised rather than absorbed.

Review in `codereview-main.md`: one minor, one nit.
