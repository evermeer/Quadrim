# Code Review: ticket 001 (staged) → main @ 02bb1a1

> Generated: 2026-08-10T20:35:00+02:00
> Merge base: 02bb1a1 (diff = staged changes vs HEAD; no develop branch exists)
> Changed files: 56 (14 substantive; remainder is Flutter/Dart scaffolding and lockfiles)

---

## Summary

| Severity | Count |
|---|---|
| critical | 0 |
| major | 0 |
| minor | 2 |
| nit | 2 |

---

## Findings

### [MINOR] Purity check misses double-quoted imports — `bug`

**File:** `tool/check.sh:17`

**Evidence:**
```bash
if grep -rnE "import 'dart:(io|html)'|package:flutter|package:firebase" "$pkg/lib" 2>/dev/null; then
```

**Problem:** `import "dart:io";` (double quotes) is legal Dart and slips through; the check that guards the spec's §9.2 purity rule can be defeated by a style choice the default lints do not forbid.

**Fix:** Match either quote: `import ['\"]dart:(io|html)['\"]`. The `package:` alternatives already match regardless of quoting.

---

### [MINOR] NL locale is never rendered by any test — `bug`

**File:** `app/test/smoke_test.dart:6`

**Evidence:**
```dart
await tester.pumpWidget(const QuadrimApp());
expect(find.text('Four in a row, stacked in a cube.'), findsOneWidget);
```

**Problem:** Only the default (en) locale is exercised. gen-l10n falls back to English on a missing NL key with a warning, not an error — so deleting a key from `app_nl.arb` would pass CI while shipping a half-translated screen, which ticket 001's "localisation resources exist for English and Dutch" criterion exists to prevent.

**Fix:** Add a second widget test that pumps `MaterialApp` (or `QuadrimApp` wrapped) with `locale: Locale('nl')` and asserts `find.text('Vier op een rij, gestapeld in een kubus.')`.

---

### [NIT] CI runs twice for pull requests — `style`

**File:** `.github/workflows/ci.yml:3`

**Evidence:**
```yaml
on:
  push:
  pull_request:
```

**Problem:** A PR from a branch in the same repo triggers both events; every check runs twice. Cosmetic for a solo repo.

**Fix:** Restrict push to `branches: [main]`, or add a concurrency group. Defer.

---

### [NIT] Committed generated l10n can drift from the ARB files — `style`

**File:** `app/lib/l10n/app_localizations.dart:1`

**Evidence:** generated file committed; `tool/check.sh` runs `flutter gen-l10n` before analyze, silently overwriting the working copy in CI without failing on staleness.

**Problem:** A stale committed copy is corrected invisibly in CI, so the repo's copy can lag the ARBs. Harmless while the check script regenerates on every run.

**Fix:** If it ever bites, add a `git diff --exit-code app/lib/l10n` after gen-l10n in the script. Defer.

---

## Functional Validation

⚠️ No Jira issue key detected in branch name or commit range — skipping Jira validation. Ticket reference: `doc/tickets/001-project-skeleton-and-ci.md`; every acceptance criterion in it was verified during implementation (analyze+test green, purity check trips on a violation, string check active, APK builds, backup allowlist committed, CI workflow present, placeholder id marked).

---
---

# Code Review: ticket 002 (working tree) → main @ 24ba9ff

> Generated: 2026-08-10T21:20:00+02:00
> Changed files: 8 (generator lib+bin+test, two generated artifacts, engine export, check.sh, pubspec.lock)

## Summary

| Severity | Count |
|---|---|
| critical | 0 |
| major | 0 |
| minor | 1 |
| nit | 2 |

## Findings

### [MINOR] Determinism test asserts a tautology — `bug`

**File:** `tools/linegen/test/linegen_test.dart:171`

**Evidence:**
```dart
expect(Random(20260727).nextInt(1 << 30),
    Random(20260727).nextInt(1 << 30));
```

**Problem:** Two `Random` instances with the same seed trivially agree; this proves nothing about corpus determinism and adds false confidence. The real determinism gate is CI's staleness check, which regenerates and `git diff`s on every run.

**Fix:** Drop the `Random` assertion; keep the `buildLines()` self-comparison and add a comment pointing at the CI gate as the actual cross-run proof.

### [NIT] Staleness gate cannot see untracked generated files — `style`

**File:** `tool/check.sh:24`

**Evidence:** `git diff --exit-code -- <paths>` reports nothing for untracked paths.

**Problem:** Before the first commit of a generated file, the gate passes vacuously. Self-resolves the moment this ticket is committed; only recurs if a new generated artifact is added and forgotten.

**Fix:** None now. If a third generated file is ever added, extend the gate with an untracked-file check in the same breath.

### [NIT] Generator's internal assert never runs under `dart run` — `style`

**File:** `tools/linegen/lib/linegen.dart:113`

**Evidence:** `assert(completed != null && _sameLine(completed, line));` — asserts are disabled in `dart run` by default.

**Problem:** The sanity assert is dead in the CI generation step. Harmless: the corpus replay test independently verifies every game's outcome, which is the check that matters.

**Fix:** None needed; noted so nobody relies on the assert.

## Functional Validation

⚠️ No Jira key — ticket reference `doc/tickets/002-line-generation-and-win-detection.md`. All criteria verified: 76 lines emitted and independently cross-checked by direction-walk enumeration (test), degree table matches literature exactly (16×7, 48×4, per-cell), corpus covers all 76 lines × both seats + 3 draws + illegal cases, replay test proves every recorded outcome, exhaustive C(64,4) scan finds exactly 76 collinear quads, CI staleness gate live, nothing else enumerates lines.

---
---

# Code Review: ticket 003 (working tree) → main @ e1a82a1

> Generated: 2026-08-10T22:05:00+02:00
> Changed files: 3 (engine.dart, engine_test.dart, package export)

## Summary

| Severity | Count |
|---|---|
| critical | 0 |
| major | 0 |
| minor | 0 |
| nit | 2 |

## Findings

### [NIT] `owner()` throws RangeError, not ArgumentError, on an invalid cell — `style`

**File:** `packages/quadrim_engine/lib/src/engine.dart:103`

**Evidence:**
```dart
Player? owner(Cell cell) => _board[cell.index];
```

**Problem:** `owner(Cell(64))` surfaces as a raw list `RangeError` instead of the `ArgumentError` the mutating API throws; inconsistent error shape on the read path. No caller constructs out-of-range cells today.

**Fix:** Defer. If it ever bites, mirror `applyMove`'s `isValid` guard.

### [NIT] A move completing two lines at once records the first in table order — `style`

**File:** `packages/quadrim_engine/lib/src/engine.dart:131`

**Evidence:**
```dart
for (final line in _linesThroughCell[cell.index]) {
  if (line.every((c) => board[c] == mover)) {
    win = Win(mover, line);
    break;
  }
}
```

**Problem:** A double-completing move exists in Qubic; the recorded/highlighted line is the lexicographically first. Deterministic and spec-compatible (idea-v1 rule 4 speaks of "the completed line", singular), but undocumented.

**Fix:** One doc line on `Win.line` noting the tie-break. Defer to next touch of the file.

## Functional Validation

⚠️ No Jira key — ticket reference `doc/tickets/003-engine-core.md`. (Section continues below with ticket 004.) All criteria verified by tests: immutable `GameState` (mutation attempt throws, input never changes), `legalMoves` = empty cells and empty once won, occupied/out-of-range/finished-game rejections, outcome names winner and exact line for all 76 lines × both players, near-miss quads never win, full corpus replays (155 games incl. 3 draws), threat detection with structure invariant over 200 pseudo-random positions, engine purity enforced by tool/check.sh. One test-helper bug (predicate rejecting all candidates) was found and fixed during the run, before review.

---
---

# Code Review: ticket 004 (working tree) → main @ 3acb934

> Generated: 2026-08-11T00:15:00+02:00
> Changed files: 9 (board_view.dart, game_screen.dart, game_screen_test.dart, main.dart, 2 ARB + 3 generated l10n)

## Summary

| Severity | Count |
|---|---|
| critical | 0 |
| major | 0 |
| minor | 2 |
| nit | 1 |

## Findings

### [MINOR] `cellSizeForWidth` is dead code — `style`

**File:** `app/lib/game/board_view.dart:289`

**Evidence:**
```dart
/// Effective cell size for a given available width.
double cellSizeForWidth(double width) {
  final gridInnerWidth = (width - BoardView._layerGap) / 2;
```
Grep across `lib/` and `test/`: zero call sites.

**Problem:** A speculative public helper duplicating the arithmetic already inlined in `BoardView.build`. Two copies of the same geometry that can drift apart, and neither the app nor the tests use this one.

**Fix:** Delete it. Reintroduce when a caller exists.

### [MINOR] The kMinCellSize floor is claimed but not enforced below 360dp — `bug`

**File:** `app/lib/game/board_view.dart:304`

**Evidence:**
```dart
  // Cap cells at 48dp on wide screens; narrow phones get what fits,
  // never below kMinCellSize (asserted in tests).
  final ideal = boardWidthForCell(48);
  return math.min(available, ideal);
```

**Problem:** `clampBoardWidth` only caps the upper bound; there is no lower bound, and the sole size test runs at 390dp. Working the geometry backwards through the screen's 8dp padding: a 320dp-wide device yields ~30dp cells — below the 32dp floor the comment asserts. The comment claims a guarantee the code does not provide.

**Fix:** Add a test at the narrowest width the product supports and state that width, so the floor is a gate rather than a comment. Record sub-360dp as a known limitation for ticket 021's device audit rather than silently shipping cells under the audited floor.

### [NIT] Production widgets carry test-only keys — `style`

**File:** `app/lib/game/board_view.dart:203`

**Evidence:**
```dart
key: ValueKey('cell-${cell.index}'),
```

**Problem:** The key exists solely so widget tests can address a cell; nothing in the app reads it.

**Fix:** None. This is the conventional Flutter approach and the alternative (finding by semantics label) is slower and more brittle. Noted so the intent is on record.

## Functional Validation

⚠️ No Jira key — ticket reference `doc/tickets/004-playable-board-pass-and-play.md`.

| # | Criterion | Status | Evidence |
|---|---|---|---|
| All four layers, all 64 cells, no scrolling | ✅ | 2x2 layer arrangement, `board_view.dart:47`; semantics test walks all 64 |
| Layers legible as depth | ✅ | horizontal shear 0.15, `board_view.dart:35` |
| Occupied vs empty unmistakable | ✅ | pebble with radial gradient vs empty tile, `board_view.dart:217` |
| Single tap places, no confirmation | ✅ | `game_screen_test.dart:47` full game via single taps |
| Taps on occupied cells do nothing | ✅ | test `tapping an occupied cell does nothing` |
| Player to move unambiguous | ✅ | turn banner with piece swatch; asserted each half-move in the win test |
| Reaches a win and a draw, announces which | ✅ | win test + draw test replaying a corpus drawn game |
| Pieces distinguished by lightness not hue | ✅ | `board_view.dart:255` (D124) |
| Every cell has a screen-reader label | ✅ | test asserts all 64 match layer/row/column/contents |
| Turn changes and result announced | ✅ | `Semantics(liveRegion: true)` banner, `game_screen.dart:108` (D136) |
| Reliable touch target on smallest phone | ⚠️ | verified at 390dp (~37dp cells); see MINOR above for <360dp |
| Legible in light and dark themes | ⚠️ | uses `ColorScheme` roles throughout, so both themes render; visual verification is ticket 021 |
| Strings in English and Dutch | ✅ | both ARB files extended; `tool/check.sh` string gate passes |

---
---

# Code Review: ticket 005 (working tree) → main @ 66972b5

> Generated: 2026-08-11T02:40:00+02:00
> Changed files: 9 (4 new data-layer sources, 1 new test file, game_screen, main, 2 existing test files; plus pubspec + lock)

## Summary

| Severity | Count |
|---|---|
| critical | 0 |
| major | 0 |
| minor | 3 |
| nit | 2 |

## Findings

### [MINOR] `_watch` can drop a change emitted between the first value and the subscription — `bug`

**File:** `app/lib/data/local_game_repository.dart:80`

**Evidence:**
```dart
Stream<T> _watch<T>(T Function() value) async* {
  yield value();
  yield* _changes.stream.map((_) => value());
}
```

**Problem:** The generator subscribes to `_changes` only *after* the initial value has been consumed. A write landing in that microtask gap emits into a broadcast controller with no listener and is lost, so the subscriber keeps showing stale state until the next write. Not reachable today because every write follows a user tap, but ticket 006's bot writes its reply immediately after the screen subscribes — squarely inside the gap.

**Fix:** Subscribe first, then push the current value:
```dart
Stream<T> _watch<T>(T Function() value) {
  late StreamController<T> controller;
  StreamSubscription<void>? sub;
  controller = StreamController<T>(
    onListen: () {
      sub = _changes.stream.listen((_) => controller.add(value()));
      controller.add(value());
    },
    onCancel: () => sub?.cancel(),
  );
  return controller.stream;
}
```

### [MINOR] `appendMove` and `resign` return a Future but throw synchronously — `bug`

**File:** `app/lib/data/local_game_repository.dart:139`

**Evidence:**
```dart
Future<GameDocument> appendMove(String id, int cell) {
  final game = _requireActive(id);
```

**Problem:** Neither method is `async`, so `_requireActive`'s `ArgumentError`/`StateError` and `GameState.fromMoves`'s validation error escape synchronously rather than as a failed Future. A caller that treats the result as a Future — `repository.appendMove(...).catchError(...)`, or the fire-and-forget call in `game_screen.dart:47` — does not catch them; in the widget case the throw lands in the gesture callback and takes down the frame. The screen only avoids this because `BoardView` already refuses taps on occupied cells, which is a second guard, not the contract.

**Fix:** Mark both `async`. Errors then surface through the returned Future, which is what the signature promises.

### [MINOR] Stored lists are handed out mutable, unlike every other model in the repo — `architecture`

**File:** `app/lib/data/documents.dart:115`

**Evidence:**
```dart
final List<int> moves;
```
and `documents.dart:199`
```dart
moves: (json['moves'] as List?)?.cast<int>() ?? const [],
```

**Problem:** `cast<int>()` returns a *view* over the decoded list, not a copy, so `GameDocument.moves` aliases whatever the store handed over and is freely mutable by any caller. The engine established the opposite standard one ticket ago — ticket 003's `GameState` is immutable and has a test asserting a mutation attempt throws. Two neighbouring models with opposite mutability rules is the kind of inconsistency that gets discovered by a bug.

**Fix:** Wrap in the constructor: `moves = List.unmodifiable(moves)`, same for `GameResult.line`.

### [NIT] A settings document from a newer build is reset rather than preserved — `bug`

**File:** `app/lib/data/local_game_repository.dart:47`

**Evidence:**
```dart
final settings = SettingsDocument.fromJson(await store.readSettings() ?? {});
```

**Problem:** `fromJson` correctly returns null for a newer `schemaVersion`, and the caller falls back to defaults — but unlike a skipped *game*, the next `saveSettings` then overwrites the newer document with the older shape. Skipping preserves games; for settings it silently destroys them. Only reachable by installing an older build over a newer one.

**Fix:** Defer. When it matters, record that the on-disk version was newer and refuse to write until the user changes a setting deliberately. Not worth the machinery for a private 0.1 with no downgrade path.

### [NIT] Unknown enum values coerce to a default rather than skipping the record — `style`

**File:** `app/lib/data/documents.dart:74`

**Evidence:**
```dart
outcome: _enumByName(GameOutcome.values, json['outcome'], GameOutcome.draw),
```

**Problem:** A malformed `outcome` reads as a draw rather than being rejected, so a damaged win would be silently miscounted by the rating fold. Unreachable while `schemaVersion` gates the field set, which is why this is a nit and not a bug.

**Fix:** None now. If the shape ever changes within a schema version, make the enum readers return null and skip the document, as `fromJson` already does for a bad id or timestamp.

## Functional Validation

⚠️ No Jira key — ticket reference `doc/tickets/005-local-persistence-game-repository.md`.

| # | Criterion | Status | Evidence |
|---|---|---|---|
| Single contract: watch, list active, list completed, create, append, resign, delete | ✅ | `game_repository.dart:14-59` |
| Stream-based, not future-based | ✅ | all three `watch*` return `Stream`; `local_game_repository.dart:80` |
| JSON documents keyed by id, matching spec §8.3 | ✅ | test `stored games carry a schema version and no device identifier` asserts the exact key set |
| Moves a plain ordered list; authorship derived | ✅ | `documents.dart:126` `seatForMove`; test `whose move each was derives from position and the starting seat` |
| Records only which opponent | ✅ | `documents.dart:104`; `kGuestOpponent` / `botOpponent` |
| Completed game records opponent's rating at the time | ✅ | `documents.dart:110`; asserted in `a created game is stored, active and empty` |
| Completion timestamp is the fold's ordering key, id as tie-break | ✅ | `local_game_repository.dart:92-98`; test `active and completed lists separate, completed ordered for the fold` |
| Outcome and reason separate | ✅ | tests for line, fullBoard and resignation; resignation test asserts the position is still `Ongoing` |
| Load all completed games once | ✅ | `loadCompletedGames`; test `statistics are derivable by folding completed games` |
| No device identifier anywhere | ✅ | exact-key-set assertion; verified on device — stored document contains no identifier |
| Every document carries a schema version | ✅ | `documents.dart:13`, asserted on disk |
| Newer schema skipped, equal/lower read | ✅ | test `a document from a newer schema is skipped, not misread` |
| Game ids unique and stable across restarts | ✅ | `local_game_repository.dart:62`; restart test reads the same id back |
| Settings document with language, theme, tutorial completion | ✅ | `documents.dart:224`; round-trip and restart tests |
| Statistics derived, never stored | ✅ | no aggregate is written; the stored key set assertion would fail if one were |
| In-progress game survives restart with moves intact | ✅ | unit test, **and** verified on device: 4 moves → `am force-stop` → relaunch → restored |
| A process kill during a write leaves no corrupted record | ✅ | atomic tmp+rename, `document_store.dart:104`; test `a kill mid-write leaves no corrupted record` |
| No screen reads or writes storage except through the repository | ✅ | only `main.dart` constructs the store (composition root); `game_screen.dart` imports the contract only |

### Post-review outcome

All three minor findings were applied. The first turned out to be worth more than its severity suggested:

- **`_watch` race** — fixed with `Stream.multi`, which subscribes before publishing. The first attempt (a `StreamController` adding inside `onListen`) hung every widget test. Bisected to a cause with no project code in it: `.first` on a stream whose `onCancel` awaits a *broadcast* subscription's `cancel()` never completes inside `testWidgets`' fake-async zone. `onCancel` now fires and forgets. Pinned by a new test that writes in the same microtask as the subscribe (D140).
- **Synchronous throws** — `appendMove` and `resign` are now `async`, so validation failures surface through the returned Future.
- **Mutable lists** — `GameDocument.moves` and `GameResult.line` are `List.unmodifiable`, matching the standard ticket 003 set for `GameState`. New test asserts mutation throws.

The two nits were deliberately not implemented; both are recorded above with the condition that would make them worth doing.

Full suite after fixes: 43 app tests, 8 engine tests, 8 generator tests. `tool/check.sh` reports ALL CHECKS PASSED.

---
---

# Code Review: ticket 006 (working tree) → main @ d0d11d1

> Generated: 2026-08-11T04:05:00+02:00
> Changed files: 11 (bot.dart + bot_test.dart new, game_screen, main, engine export, 2 ARB + 3 generated l10n, bot_game_test.dart new)

## Summary

| Severity | Count |
|---|---|
| critical | 0 |
| major | 1 |
| minor | 0 |
| nit | 2 |

## Findings

### [MAJOR] A second tap before the first is stored lets the player take the opponent's turn — `bug`

**File:** `app/lib/game/game_screen.dart:104`

**Evidence:** before the fix,
```dart
enabled: !_isOpponentsTurn(game),
onCellTap: (cell) => widget.repository.appendMove(game.id, cell.index),
```

**Problem:** `enabled` is derived from `_game`, which only updates when the write round-trips through the repository. A second tap inside that window sees a board that is still enabled and appends a second move — so in a game against the computer the player plays the opponent's move as well, and the opponent then never gets a turn. Reproduced by a test before fixing: two taps in one frame stored `[0, 1]` rather than `[0]`.

**Fix:** One `_busy` flag covering both directions — dispatching a human move and running the opponent's — set synchronously before the await and cleared in a `finally`. Regression test asserts the second tap is dropped *and* that the opponent still gets its own turn afterwards.

### [NIT] `botName` duplicates the catalogue as a switch — `architecture`

**File:** `app/lib/game/game_screen.dart:115`

**Evidence:**
```dart
String botName(AppLocalizations l10n, String opponent) =>
    switch (opponent) { 'bot:pebble' => l10n.botPebble, _ => opponent };
```

**Problem:** Every new opponent needs an arm here as well as a catalogue entry, and the fallback silently renders the raw `bot:<id>` string if one is forgotten.

**Fix:** Defer to ticket 029, which owns opponent names, avatars and blurbs and will need a real per-bot content lookup anyway. Not worth a lookup table for one entry.

### [NIT] The opponent's pause is a fixed delay, not a floor on real thinking time — `style`

**File:** `app/lib/game/game_screen.dart:15`

**Evidence:**
```dart
const Duration kBotMoveDelay = Duration(milliseconds: 550);
```

**Problem:** Pebble decides instantly so the delay is the whole visible time, but Onyx at 4-ply (ticket 010) will take real time and then add 550ms on top, making strong opponents feel sluggish rather than thoughtful.

**Fix:** When ticket 010 lands, measure the search and pad to a minimum rather than adding to it. Premature now — there is nothing to measure.

## Functional Validation

⚠️ No Jira key — ticket reference `doc/tickets/006-bot-engine-and-pebble.md`.

| # | Criterion | Status | Evidence |
|---|---|---|---|
| One move-choosing function serves every opponent, parameterised | ✅ | `bot.dart` `chooseMove(state, config, random)`; no per-bot class |
| Config covers depth, rules, blunder rate, positional bias, aggression, tie-break randomness | ✅ | `BotConfig`, all six fields with range asserts |
| Catalogue exists as data, Pebble first | ✅ | `opponentCatalogue`; tests assert unique ids, weakest-first ordering |
| Randomness injected, not ambient | ✅ | `Random` is a parameter; purity check forbids ambient sources; test asserts same seed + state ⇒ same move |
| Starting a game offers computer or second human | ✅ | two buttons; test asserts the created game is `vsComputer` against `bot:pebble` |
| A full game against Pebble reaches win, loss or draw | ✅ | widget test plays to completion and asserts a stored result; verified on the emulator |
| Chosen move always legal, thousands of positions, every entry | ✅ | 3000 random reachable positions per catalogue entry, cross-checked against `legalMoves` and `applyMove` |
| The computer's move is visible as it happens | ✅ | `kBotMoveDelay` + "Pebble is thinking…" banner; test asserts the mid-think state and that the board is closed to taps |
| All new strings in English and Dutch | ✅ | both ARBs; Dutch test asserts "Pebble denkt na…" and "Jij bent aan zet" |

### Post-review outcome

The major finding was fixed test-first: the reproduction was written and confirmed failing (`[0, 1]`) before the guard was added. The two nits are deliberately deferred, each with the ticket that will make it worth doing.

Full suite: 51 app tests, 23 engine tests, 8 generator tests. `tool/check.sh` passes.

---
---

# Code Review: ticket 007 (working tree) → main @ d2fcb31

> Generated: 2026-08-11T05:20:00+02:00
> Changed files: 10 (rating package + its tests, rating_fold.dart new, game_screen, board_view, 2 ARB + 3 generated l10n, result_screen_test.dart new)

## Summary

| Severity | Count |
|---|---|
| critical | 0 |
| major | 0 |
| minor | 3 |
| nit | 1 |

## Findings

### [MINOR] The rating change assumed this game was the most recent ever finished — `bug`

**File:** `app/lib/data/rating_fold.dart:56`

**Evidence:** before the fix,
```dart
({int before, int after}) computerRatingAround(List<GameDocument> completed) =>
    ratingAround(ratedGamesFrom(completed));
```

**Problem:** `ratingAround` reports the step caused by the **last** entry it is given, so this returned the change caused by the most recently completed game on the ladder — correct only while the game whose result screen is open is also the newest one ever finished. That holds for the only navigation 0.1 has today and stops holding the moment ticket 013 lets a player open a finished game from a list.

**Fix:** Take the prefix ending at the game being shown: `computerRatingAround(completed, gameId)` finds the game on the ladder and folds up to and including it. Returns the seed for a game not on the ladder.

### [MINOR] `didUpdateWidget` did not re-point the subscription — `bug`

**File:** `app/lib/game/game_screen.dart:76`

**Evidence:** `initState` subscribed to `widget.gameId` and nothing re-subscribed on change.

**Problem:** Flutter reuses `State` when the same widget type is rebuilt in the same position, so a `GameScreen` handed a different `gameId` kept watching the first one — showing the wrong game with no error. Caught by a test that pumped two games in succession.

**Fix:** `didUpdateWidget` cancels and re-subscribes when the id changes, clearing `_game`, `_rating` and `_busy` with it.

### [MINOR] "You moves first" — `bug`

**File:** `app/lib/l10n/app_en.arb:72`

**Evidence:** `"firstMoveRandom": "{who} moves first, chosen at random"` with `who` ∈ {You, Pebble, Light}.

**Problem:** Composing a sentence around a placeholder that is sometimes second person produces "You moves first". The test asserted the broken string, so it passed.

**Fix:** Reworded to a label form that takes any subject in both languages: "Opening move: {who} — chosen at random" / "Aftrap: {who} — willekeurig gekozen".

### [NIT] `sideDark` was added and never used — `style`

**File:** `app/lib/l10n/app_nl.arb`

**Problem:** Light always opens, so the pass-and-play caption only ever names Light. The dark string was dead in both locales.

**Fix:** Removed. Reintroduce when something needs it.

## Functional Validation

⚠️ No Jira key — ticket reference `doc/tickets/007-result-screen-rematch-resign.md`.

| # | Criterion | Status | Evidence |
|---|---|---|---|
| Winning line highlighted on the board | ✅ | `highlight` from `Win.line`; result sits *below* the board so the line stays visible |
| Result states who won, or that it was drawn | ✅ | tests for win, loss, draw and resignation |
| Computer-rating change shown, labelled so it is not mistaken for universal | ✅ | "Computer rating 1169 (-31)" + "Your rating against the computer, on this device only." — verified on the emulator |
| Pass-and-play result makes clear no rating changed | ✅ | "No rating changes in pass and play."; test also asserts no rating line appears |
| Rematch in one tap | ✅ | test taps `Rematch` |
| Rematch: the player who did not start, starts | ✅ | test asserts `startingSeat` flipped |
| Rematch records which game it followed | ✅ | `rematchOf` asserted |
| First game's starter random, reason recorded | ✅ | `StartReason.random` written at creation |
| The game says who moves first and why | ✅ | permanent caption; cost 20dp of supported height, recorded in `kMinSupportedHeight` |
| Resign at any point, ends as a loss for the resigner | ✅ | test asserts `winnerSeat` is the other seat and `reason` is `resignation` |
| No draw-offer mechanism anywhere | ✅ | test asserts no "draw"/"Draw" text on a running game; dialog says so explicitly |
| Resignation requires confirmation | ✅ | test cancels once and confirms once |
| Result announced to a screen reader | ✅ | test asserts the banner carries the result text and the live-region flag |
| All new strings in English and Dutch | ✅ | Dutch test asserts "Je wint!", "Revanche", and the rating note |

### Post-review outcome

All three minor findings fixed; the nit removed. The rating maths (ticket 014) and the fold (ticket 027) were pulled forward because this ticket's rating criterion depends on both — recorded as D145 rather than left as an undocumented dependency inversion.

Full suite: 61 app tests, 23 engine tests, 19 rating tests, 8 generator tests. `tool/check.sh` passes.

---
---

# Code Review: ticket 008 (working tree) → main @ 6d35745

> Generated: 2026-08-11T06:30:00+02:00
> Changed files: 3 (bot.dart rewritten, bot_test.dart updated, strategic_bot_test.dart new)

## Summary

| Severity | Count |
|---|---|
| critical | 0 |
| major | 0 |
| minor | 1 |
| nit | 2 |

## Findings

### [MINOR] `PositionalBias` was replaced by two independent weights — `architecture`

**File:** `packages/quadrim_engine/lib/src/bot.dart:76`

**Evidence:**
```dart
final double centreBias;
final double cornerBias;
```
replacing ticket 006's `enum PositionalBias { none, centre, corners }`.

**Problem:** This is a breaking change to an API shipped one ticket ago, and it was not called out in the ticket. Left unrecorded it looks like churn.

**Fix:** Kept, and recorded as D147. The criterion "corner and centre preference are configurable independently" cannot be met by a three-valued enum — Kestrel is corner-hungry, Finch centre-loving, and a configuration must be able to say both or neither. Nothing outside the engine referenced the enum, so the blast radius was two lines of ticket 006's test.

### [NIT] `botName` in the app still knows only Pebble — `architecture`

**File:** `app/lib/game/game_screen.dart:196`

**Problem:** Eight new opponents exist in the catalogue but the app would render `bot:twig` for them.

**Fix:** Deliberately not fixed here. Nothing can start a game against them until ticket 011 adds opponent selection, so there is no reachable defect; 011 and 029 own opponent names and content and will need a real lookup rather than another switch arm.

### [NIT] The fork test's helper duplicates `_followUpWins` — `style`

**File:** `packages/quadrim_engine/test/strategic_bot_test.dart:352`

**Problem:** `_forkCells` in the test re-implements the production scan.

**Fix:** Intentional. A test that asks the implementation whether the implementation is right proves nothing; this one walks all 76 lines independently, which is the same technique ticket 002 used to cross-check the generated line table.

## Functional Validation

⚠️ No Jira key — ticket reference `doc/tickets/008-strategic-rule-bots.md`.

| # | Criterion | Status | Evidence |
|---|---|---|---|
| Four rules implemented and evaluated in order | ✅ | `_ruleCandidates`; tests for each rule plus "taking a win outranks blocking one" |
| Rules individually enabled or disabled | ✅ | `Set<StrategicRule>`; Twig has only `winNow` and demonstrably fails to block |
| Blunder rate replaces the chosen move with a weaker legal one | ✅ | test asserts the considered move is *never* played at rate 1 — a re-roll would sometimes return it |
| Aggression weights building against blocking | ✅ | ordering of rules 3/4 plus a denial-skip probability; test finds positions where both forks exist and asserts opposite choices |
| Corner and centre preference configurable independently | ✅ | two weights; test asserts each alone, and both together |
| All eight exist with the §6.4 configurations | ✅ | catalogue test checks each personality and the descending blunder ladder |
| Immediate win taken | ✅ | >30/60 seeds for three bots; Pebble finds it <10/60 |
| Immediate loss blocked | ✅ | Mote blocks ~60% (its 40% blunder rate); Twig, lacking the rule, <10/60 |
| Double threat played when available | ✅ | over sampled positions, the rule-enabled bot picks a fork more than twice as often as one without |
| Blunder rates verified statistically | ✅ | 3000 trials per bot, observed within 0.04 of configured |
| Aggressive builds before blocking, defensive the reverse | ✅ | both >60% of comparable positions |
| Only legal moves across thousands of positions | ✅ | every catalogue entry, 400 positions each, cross-checked against `legalMoves` and `applyMove` |
| The eight are distinguishable in play | ✅ | head-to-head matches with alternating starts: Ember beats Pebble >3:1, beats Mote, Twig beats Pebble |

### Post-review outcome

The API change is recorded as D147 rather than left implicit. Both nits stand as written, each with the reason.

Full suite: 37 engine tests, 61 app, 19 rating, 8 generator. `tool/check.sh` passes.

---

# Code Review: ticket 009 (working tree) → main @ 5adae40

> Generated: 2026-08-08
> Base: HEAD (5adae40), work uncommitted
> Changed files: 4 — `packages/quadrim_engine/lib/src/bot.dart`, `packages/quadrim_engine/test/positional_bot_test.dart` (new), `packages/quadrim_engine/test/strategic_bot_test.dart`, `doc/idea-v1-decisions.md`

---

## Summary

| Severity | Count |
|---|---|
| critical | 0 |
| major | 0 |
| minor | 2 |
| nit | 2 |

---

## Findings

### [MINOR] The ladder's ordering invariant was asserted for Basalt alone — `architecture`

**File:** `packages/quadrim_engine/test/positional_bot_test.dart:95`

**Evidence (before the fix):**
```dart
expect(basalt.centreBias - basalt.cornerBias, greaterThan(basalt.lineBias));
expect(basalt.cornerBias - basalt.edgeBias, greaterThan(basalt.lineBias));
```

**Problem:** D149 makes the positional order a property of the numbers, not of the code, but nothing checked it beyond one hard-coded opponent — ticket 010 adds Marlin and Vireo as "Basalt plus 2-ply search", and either could raise `lineBias` past the 0.5 class gap and silently invert the ladder with the whole suite still green.

**Fix:** Applied. The assertion is now a loop over every catalogue entry with `lineBias > 0` (`positional_bot_test.dart:99`), so the check arrives with the opponent rather than having to be remembered.

### [MINOR] `expect(opponentCatalogue.last, same(basalt))` breaks in the next ticket — `bug`

**File:** `packages/quadrim_engine/test/positional_bot_test.dart:99`

**Evidence (before the fix):**
```dart
expect(opponentCatalogue.last, same(basalt));
```

**Problem:** Basalt is last only until Marlin (1500) is appended in ticket 010. The assertion tests the catalogue's length, not anything about Basalt, and would fail for a correct change.

**Fix:** Applied — `expect(opponentCatalogue, contains(basalt))`. Ordering by rating is already covered by the catalogue test in `strategic_bot_test.dart:42`.

### [NIT] `edgeBias` ships unused by every opponent — `architecture`

**File:** `packages/quadrim_engine/lib/src/bot.dart:84`

**Evidence:**
```dart
final double edgeBias;
```

**Problem:** No catalogue entry sets it; the forty-eight non-centre non-corner cells are scored 0 by all ten.

**Fix:** Kept deliberately. The ticket requires that "positional bias is configurable, so later opponents can weight centre, corner and edge differently", and two knobs cannot express a preference for the third class. Recorded in D149, and exercised by a test that builds an edge-preferring configuration (`positional_bot_test.dart:78`) so the knob is proven rather than merely present.

### [NIT] `_match` and `_randomPosition` are duplicated across the two bot test files — `style`

**File:** `packages/quadrim_engine/test/positional_bot_test.dart:163`

**Evidence:**
```dart
({int wins, int losses, int draws}) _match(
```
duplicating `strategic_bot_test.dart:8`.

**Problem:** Two copies of a self-play harness will drift.

**Fix:** Left as is for now. Extracting a `test/support/` library is the right move once a third file needs it — which ticket 010 will make true, since search opponents need the same match harness. Noted there rather than done here.

---

## Rejected during validation

- **"Changing the two `if`s to an `else if` chain alters Clover, Finch and Kestrel."** Checked and false: `isCentreCell` requires all three coordinates inner and `isCornerCell` all three outer, so the classes are disjoint and no cell ever scored both. With `edgeBias` defaulting to 0 the third branch reproduces the old `0.0` starting score exactly.
- **"Normalising by 7 makes the building term unfair to the 48 cells that lie on only 4 lines."** The divisor is a constant, so it cannot change the ordering by count within or across classes. Wrong assumption; discarded.
- **"Scoring every candidate now costs 64 x 7 x 4 board reads per move."** `GameState.owner` is a list index (`engine.dart:99`), so this is ~1800 array reads, and the term is skipped entirely when `lineBias == 0`. The 120-game self-play match runs inside the suite's one-second budget. Not a finding.

## Functional Validation

⚠️ No Jira key — ticket reference `doc/tickets/009-positional-rules-and-basalt.md`.

| # | Criterion | Status | Evidence |
|---|---|---|---|
| Positional rules implemented and evaluated in order: centre, corner, most part-owned lines, random | ✅ | `bot.dart:405` scores class then building term; four tests, one per rung (`positional_bot_test.dart:18–60`) |
| Used both when no strategic rule fires and as the tie-break within a rule | ✅ | `chooseMove` passes `_ruleCandidates(...) ?? moves` to the one `_positionalPick` (`bot.dart:261`); the tie-break case is tested at `positional_bot_test.dart:117` |
| Positional bias configurable — centre, corner and edge weighted differently | ✅ | `centreBias`/`cornerBias`/`edgeBias`/`lineBias` (`bot.dart:81–95`); edge-preferring configuration tested at `positional_bot_test.dart:78` |
| Basalt exists with the specified configuration | ✅ | `bot.dart:200` — 1400, all four rules, 6% blunder, matching idea-v1 §6.4; asserted at `positional_bot_test.dart:90` |
| Given an empty board, Basalt opens in the central cube | ✅ | 200 seeds, opened centrally in more than 170 — the shortfall is its configured 6% blunder rate, verified statistically as ticket 008 established |
| Given several cells satisfying the same strategic rule, Basalt picks by the tie-break rather than at random | ✅ | a position offering wins at cell 21 (centre) and cell 3 (corner): Basalt takes 21 in >85/100 seeds, Ember — same rule, no positional sense — in <70/100 |
| Basalt beats Ember over a significant number of self-play games | ✅ | 120 games with alternating starts: 103–17–0. Re-run at two further seeds off-test: 96–24–0 and 102–17–1 |
| Every opponent still returns only legal moves across thousands of random positions | ✅ | 3000 positions for Basalt (`positional_bot_test.dart:150`), plus the existing all-catalogue sweeps in `bot_test.dart:59` and `strategic_bot_test.dart:282`, which now cover ten entries |

### Gaps

None — every criterion is addressed.

### Notes

- `botName` in `app/lib/game/game_screen.dart:231` still knows only Pebble, so Basalt would render as `bot:basalt`. Unchanged from ticket 008's review and still unreachable: nothing can start a game against it until ticket 011 adds opponent selection.
- Basalt is the tenth of twenty opponents and the last that needs no search. Ticket 010 is the first that must implement `searchDepth`, which `chooseMove` currently rejects with `UnimplementedError` by design (D142).

### Post-review outcome

Both minor findings fixed; both nits stand with the reason recorded. New decision: D149 — the positional ladder is weights arranged to produce an order, not an if-else chain.

Full suite: 49 engine tests, 61 app, 19 rating, 8 generator. `tool/check.sh` passes.

---

# Code Review: ticket 010 (working tree) → main @ b4fd4f3

> Generated: 2026-08-08
> Base: HEAD (b4fd4f3), work uncommitted
> Changed files: 10 — `packages/quadrim_engine/lib/src/search.dart` (new), `.../lib/src/bot.dart`, `.../lib/quadrim_engine.dart`, `.../test/search_test.dart` (new), `.../test/bot_test.dart`, `.../test/strategic_bot_test.dart`, `app/lib/game/game_screen.dart`, `app/test/bot_game_test.dart`, `app/test/result_screen_test.dart`, `doc/idea-v1-decisions.md`

---

## Summary

| Severity | Count |
|---|---|
| critical | 0 |
| major | 1 |
| minor | 1 |
| nit | 2 |

---

## Findings

### [MAJOR] Resigning while the opponent thinks crashes the screen — `bug`

**File:** `app/lib/game/game_screen.dart:160`

**Evidence (before the fix):**
```dart
final move = await widget.opponentMove(game.moves, bot, _random);
if (!mounted) return;
await widget.repository.appendMove(game.id, move);
```
The Resign action is rendered whenever `game.status == GameStatus.active` (`game_screen.dart:242`) with no `_busy` gate, and `LocalGameRepository.appendMove` calls `_requireActive`, which throws `StateError('game … is already complete')` (`local_game_repository.dart:225`).

**Problem:** The player can resign inside the opponent's thinking time; the move then computed is appended to a game that no longer accepts moves, and the `StateError` escapes an `unawaited` future as an unhandled exception.

**Reproduced first:** `app/test/bot_game_test.dart` — "resigning while the opponent is thinking does not crash" fails on HEAD with `Bad state: game … is already complete` thrown from `_playOpponentIfItsTurn`.

**Fix:** Applied. Before appending, the screen re-checks the live document: the game must still be active, still the opponent's turn, and still at the move count the search was given. A move computed for a position that is no longer on the board is dropped.

**Note on severity:** the window existed before this ticket — the 550 ms delay alone was enough — but ticket 010 widens it by an isolate round-trip plus up to half a second of search, and Sable is the opponent most likely to be thinking when the player gives up.

### [MINOR] A candidate could tie for best on a bound rather than a score — `bug`

**File:** `packages/quadrim_engine/lib/src/search.dart:100`

**Evidence (before the fix):**
```dart
final score =
    board.scoreAfter(candidates[i].index, depth, defence, alpha: alpha);
```

**Problem:** The root shares alpha between candidates. At the minimising node below the root the cut condition is `alpha >= best`, so a fail-low candidate returns a value less than *or equal to* alpha — including exactly alpha. `_searchBest` in `bot.dart` selects every candidate whose score equals the maximum and hands the set to the positional ladder, so a move the search rated strictly worse could be the one played.

**Fix:** Applied — the window opens at `alpha - 1`, so a bound always lands strictly below the running maximum and only exact scores can equal it. A test now asserts that every candidate tying for the maximum reproduces that score under an exact, unwindowed search.

**Consequence, recorded:** this changed play enough to flatten the whole Club ladder, which is what forced the retune in D154. Worth stating plainly — the ladder measured before this fix was measuring a bug.

### [NIT] `_orderedMoves` rescans all 76 lines at every internal node — `performance`

**File:** `packages/quadrim_engine/lib/src/search.dart:344`

**Evidence:**
```dart
for (var l = 0; l < 76; l++) {
  for (var side = 0; side < 2; side++) {
    if (_count[side][l] == 3 && _count[1 - side][l] == 0) {
```

**Problem:** 152 iterations plus a `Set` allocation per node, where the evaluation next to it is O(1) by design.

**Fix:** Not applied. The measured budget is met with room (Onyx 1.8 ms mean, Sable 21.3 ms — D152), and the same counters the quiescence check uses could drive this incrementally if a later tier needs it. Optimising an already-fast path against no measurement is how the four-ply version got slower *and* weaker.

### [NIT] `_forcedWin` and `_ruleCandidates` both compute the immediate wins — `performance`

**File:** `packages/quadrim_engine/lib/src/bot.dart:355`

**Evidence:**
```dart
if (_immediateWins(state, me).isNotEmpty) return null;
if (_immediateWins(state, me.opponent).isNotEmpty) return null;
```
followed, for the same position, by the same two calls inside `_ruleCandidates`.

**Problem:** Four scans of the 76 lines where two would do.

**Fix:** Not applied. Each scan is roughly 300 array reads against a search that visits tens of thousands of nodes; threading the result through would trade a measurable nothing for a less readable gate. The gate is where it is because it states a rule — a forcing sequence means nothing when either side wins outright — and that is worth more than the scans.

---

## Rejected during validation

- **"`_lineWeight[4] = 0` means a completed line scores nothing."** True and harmless: a winning placement is caught by `_place`'s return value and never reaches the evaluation.
- **"`botById(botId)!` in the isolate entry point can throw on an unknown id."** The caller looks the bot up from the same catalogue and passes `bot.id` back, so the id round-trips. Not reachable.
- **"The threat-space search should reuse the engine's lines-through-cell table."** It stores different data — line *indices*, because the per-line counters are keyed by identity, not contents. Building it from `winningLines` in six lines is not duplication of the engine's table.

## Functional Validation

⚠️ No Jira key — ticket reference `doc/tickets/010-search-and-onyx.md`.

| # | Criterion | Status | Evidence |
|---|---|---|---|
| Alpha-beta over the heuristic evaluation, configurable depth | ✅ | `search.dart:68` `searchScores`; `BotConfig.searchDepth`; tests for depth validation, forced win, faster win, delayed loss |
| Evaluation derived from threats and line ownership, reusing engine primitives | ✅ | `evaluatePosition` walks `winningLines`; the search's incremental copy is held to it exactly, over 60 complete games, at `search_test.dart:51` |
| Threat-space search finds what plain search at the same depth misses | ✅ | `search_test.dart:196` sweeps for positions where the forcing search sees a win and depth 4 does not, and requires five of them |
| Marlin, Vireo, Onyx and Sable exist as catalogue entries | ✅ | `bot.dart:250`–`:305`; configurations asserted at `search_test.dart:254`. Two documented deviations from §6.4's prose — see Gaps |
| Each chooses within a responsive budget, with the budget recorded | ✅ | Budget recorded as D152: 250 ms mean / 1 s worst on a mid-range phone. Measured here: Marlin 0.1/0.6, Vireo 2.3/25.6, Onyx 1.8/12.9, Sable 21.3/476 ms |
| Search never blocks the interface | ✅ | `compute` in a background isolate (D153), `game_screen.dart:31`; exercised through `tester.runAsync` in `bot_game_test.dart` |
| Given a forced win within the horizon, it is found | ✅ | `search_test.dart:85` and `:94` — the immediate win scores `kWinScore - 1` and a two-move win evaluates positively |
| Given a forced loss within the horizon, it delays or avoids it | ✅ | `search_test.dart:118` — blocking scores far above every non-blocking move, all of which score as losses |
| Each of the four beats the tier below it | ✅ | `search_test.dart:302`, and verified off-test across three independent seeds: Marlin–Basalt ≈117–75, Vireo–Marlin ≈110–90, Onyx–Vireo ≈26–14, Sable–Onyx ≈31–9 |
| Search results reproducible for a given seed, state and depth | ✅ | `search_test.dart:152`; `chooseMove`'s determinism is covered by `bot_test.dart:39`, and the isolate is handed a drawn seed rather than a `Random` |
| Every opponent still returns only legal moves across thousands of positions | ✅ | `search_test.dart:326` (150 positions each for the four, at milliseconds a move), plus the unchanged 3000-position sweep for the ten cheap opponents |

### Gaps

None blocking. Two deviations from idea-v1 §6.4's *prose*, both deliberate, measured and recorded as D154:

- **Vireo searches three plies, not two.** At equal depth it and Marlin are level however the temperaments are set, over 400-game matches. Defensive weighting is worth nothing in this game.
- **Onyx searches three plies with a six-move forcing search, not four plies plain.** The four-ply version was both slower (59 ms mean against 1.8) and weaker — it lost to a three-ply Vireo, 73–87.

The published ratings are unchanged, which is what D144 requires: measurement moves the parameters, not the numbers.

### Notes

- Ticket 006's `UnimplementedError` guard for `searchDepth > 0` (D142) is removed, since the behaviour it stood in for now exists. Its test is replaced by one asserting a four-ply configuration returns a legal move.
- `botName` in `app/lib/game/game_screen.dart:268` still knows only Pebble, so the four new opponents would render as `bot:onyx`. Unchanged since ticket 008 and still unreachable — nothing can start a game against them until ticket 011.
- The catalogue is now fourteen of twenty. Tickets 025 and 026 add the Expert and Master tiers; D154 and D156 together say where that work should start, and it is the evaluation, not the depth.

### Post-review outcome

One major and one minor finding, both fixed; the major one test-first. Two nits stand with the reason. New decisions: D150–D156.

Full suite: 71 engine tests, 63 app, 19 rating, 8 generator. `tool/check.sh` passes.

---

# Code Review: ticket 013 (working tree) → main @ 8e3f06f

> Generated: 2026-08-08
> Base: HEAD (8e3f06f), work uncommitted
> Changed files: 13 — `app/lib/home/home_screen.dart` (new), `app/lib/data/home_summary.dart` (new), `app/lib/game/opponent_name.dart` (new), `app/lib/main.dart`, `app/lib/game/game_screen.dart`, both `.arb` files and their generated output, `app/test/home_screen_test.dart` (new), `app/test/home_summary_test.dart` (new), `app/test/{smoke,game_screen,bot_game}_test.dart`, `doc/idea-v1-decisions.md`

---

## Summary

| Severity | Count |
|---|---|
| critical | 0 |
| major | 0 |
| minor | 2 |
| nit | 2 |

---

## Findings

### [MINOR] The finished-games list built every row, and it has no upper bound — `performance`

**File:** `app/lib/home/home_screen.dart:139`

**Evidence (before the fix):**
```dart
child: ListView(
  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
  children: [
    ...
    for (final game in _completedGames)
      _FinishedGameTile(game: game, onTap: () => _openGame(game.id)),
```

**Problem:** `ListView(children: [...])` materialises every child regardless of what is on screen, and the number of finished games grows without limit — a closed tester with a hundred games rebuilds a hundred tiles on every emission of the completed-games stream.

**Fix:** Applied. The screen is now a `CustomScrollView`: the fixed sections stay eager in a `SliverList.list`, and each game list is a `SliverList.builder` behind a `_gameSection` helper. A regression test fails on the old code — with sixty finished games it asserts that fewer than sixty rows are built.

### [MINOR] "Most recent first" was asserted nowhere on the screen — `test-coverage`

**File:** `app/test/home_screen_test.dart:145`

**Problem:** Criterion 14 is an ordering claim about this screen, and the screen simply passes `watchCompletedGames()` through. The repository's contract suite covers the stream's order; nothing covered the screen honouring it, so reversing the list here would have passed every test.

**Fix:** Applied — a test finishes a game against Pebble and then one against Ember and asserts Ember's row sits above Pebble's, below the "Finished games" heading. It deliberately locates the rows by position rather than by count, because the per-opponent breakdown above orders the *other* way (weakest first) and both sections name the same opponents.

### [NIT] D141 read as current after this ticket retired it — `documentation`

**File:** `doc/idea-v1-decisions.md:1071`

**Evidence:**
```
**Decision:** Until ticket 013 exists, the placeholder home button resumes the
unfinished pass-and-play game if there is one and starts a fresh one otherwise.
```

**Problem:** The placeholder home is gone and "New game" now always creates one; resuming is a tap on the in-progress list. A reader of the decisions file would have found a rule the code no longer follows.

**Fix:** Applied — D141 carries a "Superseded by ticket 013" note. Not a rewrite: the decision was correct when taken and the record of why should survive.

### [NIT] `_ActiveGameTile` and `_FinishedGameTile` differ only in their subtitle — `style`

**File:** `app/lib/home/home_screen.dart:295`

**Problem:** Two twelve-line widgets that share everything but one line.

**Fix:** Not applied. Merging them means a nullable-result parameter or a subtitle callback, which is more machinery than the duplication costs — and ticket 023's milestones and ticket 012's replay entry point are both likely to push the two further apart, not closer together.

---

## Rejected during validation

- **"`_newGame` no longer resumes an in-progress game, regressing D141."** Checked: D141 explicitly scoped itself to "until ticket 013 exists… the real main screen lists games and makes resuming explicit". This is that screen, and the in-progress list is that affordance. Recorded rather than treated as a defect.
- **"The pass-and-play result label picks the wrong side."** `_resultLabel` compares `winnerSeat` to `startingSeat`, and the seat that moves first is the one holding the light pieces — `seatForMove(0) == startingSeat` in `documents.dart`. Correct, and covered by a test asserting "Light wins!".
- **"`setState` in a stream listener registered from `initState` can fire before the first build."** The repository's `_watch` delivers its initial value through `Stream.multi`'s controller, which is asynchronous; no listener runs synchronously during `initState`.

## Functional Validation

⚠️ No Jira key — ticket reference `doc/tickets/013-main-screen.md`.

| # | Criterion | Status | Evidence |
|---|---|---|---|
| Overall statistics show wins, losses and draws | ✅ | `HomeSummary.from`; `home_summary_test.dart` "counts wins, losses and draws from the player's seat", and the screen renders `1 won · 0 lost · 0 drawn` |
| Broken down by opponent | ✅ | `HomeSummary.byOpponent`; screen test "breaks the record down by opponent, weakest first" |
| Games in progress listed with their opponent; tapping resumes | ✅ | `_ActiveGameTile`; screen test "tapping a game in progress resumes it" asserts the stored move is still on the board |
| Completed games most recent first; tapping opens the replay | ✅ | screen tests "lists finished games most recent first" and "tapping a finished game opens it". The replay *scrubber* is ticket 012 — tapping opens the finished game and its result, which 012 adds to rather than replaces |
| A large, obviously primary button starts a new game | ✅ | full-width `FilledButton`; test "the primary button starts a new game" |
| A separate button opens the tutorial | ✅ | `TextButton`, opening a placeholder route until ticket 018 (D159); test "the tutorial and settings entry points exist and open" |
| An entry point to settings exists | ✅ | app-bar `IconButton`, same placeholder treatment until ticket 028 |
| Statistics, breakdown, rating and milestones from **one** load | ✅ | one `HomeSummary.from(games)` per stream emission (`home_screen.dart:50`); the rating comes from that same list via `rating_fold`, and `OpponentRecord.everBeaten` is the seam ticket 023's milestones read |
| Statistics and lists update when a game finishes, without a restart | ✅ | screen test drives a game to completion against a live screen and asserts the record, the list and the section headings all change |
| The computer rating is shown prominently and labelled as such | ✅ | `_RatingCard` with `computerRatingHeading` and the existing `computerRatingNote`; test asserts all three |
| Room for the human rating arriving at 0.3b, never reading as one number | ✅ | the rating is a labelled `Card`, not a number in a statistics row — a card takes a sibling card. Deliberately no placeholder for the second rating: an empty "against people" slot is noise for a release that has no online play |
| Statistics derived at read time, never stored | ✅ | nothing in `home_summary.dart` writes; the only storage call the screen makes is `createGame` |
| Navigable by screen reader, readable at the largest font scale | ✅ | rating card exposes one composed `Semantics` label instead of three fragments; section headings carry `header: true`, asserted per heading; a 2× text-scale test asserts no overflow exception |
| All new strings present in English and Dutch | ✅ | 20 new keys plus 13 opponent names in both `.arb` files; a Dutch-locale test asserts seven of them render and `tool/check.sh` rejects any user-facing literal outside l10n |

### Gaps

None — every criterion is addressed.

### Notes

- The string check caught `Text('$rating')` as a hardcoded literal. Rather than suppress it, the number now goes through `l10n.ratingValue`. It is deliberately **not** given `decimalPattern`: that renders 1200 as "1,200" in English and "1.200" in Dutch, and a rating is written unseparated in both.
- `botName` moved out of `game_screen.dart` into `game/opponent_name.dart` and grew from one opponent to the fourteen that ship. The Expert and Master tiers (tickets 025, 026) still fall through to the raw `bot:<id>` key — deliberately, because an obviously wrong string on screen is better than a plausible name for an opponent that does not exist yet.
- Choosing among twenty opponents is ticket 011, which is blocked by 026 and 029. Until then the primary button opens a two-option sheet, and every game against the computer is against Pebble.

### Post-review outcome

Two minor findings, both fixed, one with a regression test that fails on the previous code. Two nits, one applied to the decisions file and one declined with a reason. New decisions: D157–D159, plus a supersession note on D141.

Full suite: 86 app tests, 71 engine, 19 rating, 8 generator. `tool/check.sh` passes.

---

# Code Review: tickets 025 + 026 (working tree) → main @ ac459b4

> Generated: 2026-08-09
> Merge base: ac459b4 (diff = working tree vs HEAD; no develop branch exists)
> Changed files: 10 (6 modified, 4 new)

---

## Summary

| Severity | Count |
|---|---|
| critical | 0 |
| major | 0 |
| minor | 5 |
| nit | 1 |

---

## Findings

### [MINOR] `canonicalPlies` is zero for every shipped opponent — the symmetry machinery has no production caller — `architecture`

**File:** `packages/quadrim_engine/lib/src/bot.dart:353-411`

**Evidence:** none of the four Expert configs sets it, so the field defaults to 0:

```dart
const BotConfig titan = BotConfig(
  id: 'titan',
  rating: 2100,
  nodeBudget: 2500000,
  maxSearchDepth: 10,
  threatSearchDepth: 15,
  exactEmpties: 10,
  rules: _clubRules,
```

`grep -rn canonicalPlies` finds it only in `BotConfig` (declaration), `_searchBest` (pass-through), and `deep_search_test.dart:112,124`.

**Problem:** `symmetry.dart` (168 lines) and `CanonicalHash` (`transposition.dart:154-219`) ship in the app and are reachable only from tests — `_tableKey` takes the `_plainHash` branch on every node of every shipped opponent.

**Fix:** either give one Expert config a non-zero `canonicalPlies` (D161 says the opening is where it pays, so `canonicalPlies: 2-4` on `titan`), or delete the canonical path and keep `symmetry.dart` as a `tools/` analysis script. Success criterion: `grep -rn canonicalPlies packages/quadrim_engine/lib/src/bot.dart` shows a non-zero value, or `CanonicalHash` no longer exists in `lib/`.

---

### [MINOR] A canonical table entry's `bestMove` is recorded in another orientation — `bug`

**File:** `packages/quadrim_engine/lib/src/search.dart:535`

**Evidence:**

```dart
suggested = entry.bestMove;
```

keyed by `_tableKey(ply)`, which above `_canonicalPlies` is the symmetric minimum:

```dart
int _tableKey(int ply) =>
    ply < _canonicalPlies ? _hash!.key : _plainHash;
```

**Problem:** the canonical key is shared by up to 192 boards, and the stored `bestMove` is a cell index in whichever of the 192 orientations wrote the entry — so above `_canonicalPlies` the ordering hint names an unrelated cell. The score stays sound (minimax is invariant under an automorphism); only the ordering is wrong, and it is wrong in exactly the plies where the table is meant to help most.

**Fix:** store `-1` as the best move when writing a canonical key, or record which automorphism produced the minimum and map the move back through its inverse on read. Success criterion: with `canonicalPlies: 4`, `SearchOutcome.nodes` at a fixed depth does not increase relative to `canonicalPlies: 0`.

---

### [MINOR] Exact endgame solving is invisible to the node budget — `performance`

**File:** `packages/quadrim_engine/lib/src/search.dart:662-681`

**Evidence:** `_solveExactly` never touches `_budget`, while `_search` does:

```dart
int _solveExactly(int alpha, int beta, int ply) {
  if (_isFull) return 0;
  final maximising = _toMove == 0;
  var best = maximising ? -kWinScore - 1 : kWinScore + 1;
  for (final cell in _orderedMoves()) {
```

**Problem:** `titan` sets `exactEmpties: 10`, so once ten cells remain the whole subtree runs outside the counter. `SearchOutcome.nodes` under-reports by exactly that work — which is the number ticket 014's calibration harness reads — and `nodeBudget` stops being an upper bound on `titan`'s worst case.

**Fix:** decrement `_budget` in `_solveExactly` too, without acting on `_outOfBudget` (a proven result must still be completed). One line at the top of the loop body. Success criterion: `deepSearch(..., exactEmpties: 10).nodes` on a 10-empty position is greater than the same call with `exactEmpties: 0`.

---

### [MINOR] The exact solver discards the move ordering the rest of the search uses — `performance`

**File:** `packages/quadrim_engine/lib/src/search.dart:666`

**Evidence:**

```dart
for (final cell in _orderedMoves()) {
```

against `_search`'s

```dart
for (final cell in _orderedMoves(suggested: suggested, ply: ply)) {
```

`_orderedMoves` defaults `ply` to -1, which skips the killer tier entirely.

**Problem:** the exact solve is the most expensive part of `titan`'s search and the only part running with no ordering evidence beyond the urgent-cell tier.

**Fix:** `_orderedMoves(ply: ply)`. The table suggestion cannot be used (the exact path never probes), but killers are free and already maintained.

---

### [MINOR] The fork weight is configurable in the incremental evaluation and hardcoded in the reference — `bug`

**File:** `packages/quadrim_engine/lib/src/search.dart:141`

**Evidence:**

```dart
mine += kForkBonus * _forkTerm(myThreatCells.length);
theirs += kForkBonus * _forkTerm(theirThreatCells.length);
```

against `_Board._evaluate` at `search.dart:687`:

```dart
final mine = _total[0] + _fork * _forkTerm(_distinctThreats[0]);
```

**Problem:** `SearchLimits.forkBonus` exists so the term can be played against itself rather than argued about (D167), but it only moves `_Board`. `evaluatePosition` — the reference the incremental version is tested against, and the evaluation the whole Club tier uses through `searchScores` — keeps 3000 whatever the limits say. A `forkBonus: 0` A/B therefore measured a half-disabled term.

**Fix:** add `{int forkBonus = kForkBonus}` to `evaluatePosition` and thread it from `SearchLimits`. Success criterion: `evaluatePosition(p, me, forkBonus: 0)` on a two-threat position equals the pre-026 line-ownership score.

---

### [NIT] `_clubRules` is an alias that adds a name and no behaviour — `style`

**File:** `packages/quadrim_engine/lib/src/bot.dart:353`

**Evidence:**

```dart
const Set<StrategicRule> _clubRules = _allRules;
```

**Problem:** the Expert tier uses the same rule set as the Club tier; a second name for it suggests they can diverge, and nothing enforces that they do.

**Fix:** use `_allRules` directly in the four configs and delete the alias.

---

## Functional Validation

⚠️ No Jira issue key detected — this project tracks work in `doc/tickets/`, not Jira. Validated against the ticket files instead.

### Ticket 025 — Expert tier, deep search

| # | Requirement | Status | Evidence |
|---|---|---|---|
| Budget in nodes, never wall-clock | ✅ | `SearchLimits.nodeBudget` (`search.dart:19-63`); `deepSearch` has no clock reference; `tool/check.sh` purity gate forbids `dart:io` |
| Iterative deepening, partial iterations discarded | ✅ | `deepSearch` `if (board._outOfBudget) break;` before `scores = iteration` |
| Transposition table, created and discarded per move | ✅ | `TranspositionTable` constructed inside `deepSearch`; `transposition.dart:9-13` states the reason |
| Bounded memory | ✅ | `Int64List`/`Int32List` at `2^sizeLog2`, 4 MB default; `assert(sizeLog2 <= 24)` |
| Mate scores corrected for ply | ✅ | `_toTable`/`_fromTable` (`search.dart:628-646`) |
| A proven result is never overridden by a heuristic estimate | ✅ | `_solveExactly` is taken before the table probe (`search.dart:513-520`) |
| Four opponents, 1800-2100 | ✅ | `quartz`, `corvus`, `lyra`, `titan` in `opponentCatalogue` |
| Same state + seed gives the same move | ⚠️ | holds — no clock, no ambient random, table discarded per call — but the ladder went flat at these budgets (Corvus-Quartz 5-5, Lyra-Corvus 4-6, Titan-Lyra 5-5), so the *ratings* attached to these four are not yet earned |

### Ticket 026 — Master tier

| # | Requirement | Status | Evidence |
|---|---|---|---|
| Evaluation understands forks | ✅ | `_forkTerm` counts distinct threatened cells, not lines (`search.dart:150-151`); mirrored incrementally in `_adjust` (`search.dart:760-775`) |
| Incremental and reference evaluations agree | ✅ | verified over 286 random positions; `_place`'s three-pass make is the fix for the desync |
| Oracle (2300) | ❌ | not built |
| Quadrim Prime (2600) | ❌ | not built |

### Gaps

- **Ticket 026 is half done.** The evaluation rewrite landed; the two Master opponents did not. D167 records why: the fork term changed the chosen move in **0 of 84** positions from real games, so the evaluation is not the lever. Reaching 2300+ needs the strategy-book route, which starts with the idea-v1 §14 licensing question — a decision that is the owner's, not the reviewer's.
- **The Expert ladder is flat.** Four opponents are shipped with ratings that measurement does not yet support. Ticket 014's calibration harness is the place that gets settled.

### Notes

- D168 (unbudgeted forcing search) was found and fixed during this work: `corvus` took 323,696 ms on one move before `kForcingBudget` existed. Worst-case move times after: sable 49 ms, quartz 751 ms, corvus 2250 ms, lyra 2374 ms, titan 3676 ms — all inside the 20 s ceiling (D164).
- The fork term is kept despite the negative result: it is free, it is proved consistent with the reference, and D167 records the disproof so nobody re-derives it.

---

# Code Review: ticket 026, perfect play (working tree) → main @ ac459b4

> Generated: 2026-08-09
> Merge base: ac459b4 (diff = working tree vs HEAD; no develop branch exists)
> Changed files: 14 (7 new, 7 modified). `strategy_book.g.dart` excluded from
> line-by-line review as generated output.

---

## Summary

| Severity | Count |
|---|---|
| critical | 0 |
| major | 1 |
| minor | 3 |
| nit | 1 |

---

## Findings

### [MAJOR] The Master tier's move time is unmeasured in the seat the book does not cover — `performance`

**File:** `packages/quadrim_engine/lib/src/bot.dart:478-495`

**Evidence:**

```dart
const BotConfig quadrimPrime = BotConfig(
  id: 'quadrim_prime',
  rating: 2600,
  usesBook: true,
  nodeBudget: 3000000,
  maxSearchDepth: 12,
  threatSearchDepth: 20,
  defenceSearchDepth: 9,
  forcingBudget: 2000000,
  exactEmpties: 12,
```

**Problem:** every timing measurement taken of Prime is of games it **opened**, where the book answers in microseconds and no search runs — but the book is first-player only (D173), so the second seat is precisely the case that spends the whole 3,000,000-node budget, a twelve-empty exact solve, and a defensive forcing scan of up to fifty candidates sharing 2,000,000 nodes. That is the largest configuration in the catalogue and the only one whose worst case has never been measured against D164's twenty-second ceiling.

**Fix:** measure it — `dart run tool/duel.dart titan quadrim_prime 10` reports worst and mean per side, and Prime takes the second seat in half the games. If the worst case exceeds twenty seconds, `nodeBudget` and `exactEmpties` are the two dials, in that order. Success criterion: a recorded worst-case move time for Prime and Oracle in the second seat, below 20,000 ms.

---

### [MINOR] The book is consulted at every ply, though nothing past ply 16 can be in it — `performance`

**File:** `packages/quadrim_engine/lib/src/strategy_book.dart:35`

**Evidence:**

```dart
  final form = canonicalise(state);
```

`canonicalise` walks all 192 automorphisms over 64 cells and builds a 64-character string for each — about 12,000 operations and 192 allocations per call. The dictionary's deepest entry holds 16 pieces:

```
by ply: {"0":1,"2":12,"4":195,"6":1448,"8":788,"10":309,"12":110,"14":51,"16":15}
```

**Problem:** a book opponent pays that on every move of every game, including ply 30 where a hit is impossible by construction.

**Fix:** one line at the top of `bookMove`, above the canonicalisation:

```dart
if (state.moves.length > 16) return null; // deeper than the dictionary goes
```

Success criterion: `bookMove` on a 40-ply position performs no automorphism walk.

---

### [MINOR] Prime's and Oracle's ratings cannot be separated by the thing that separates opponents — `architecture`

**File:** `packages/quadrim_engine/lib/src/bot.dart:461` and `:484`

**Evidence:**

```dart
  rating: 2300,   // oracle
  usesBook: true,
```
```dart
  rating: 2600,   // quadrimPrime
  usesBook: true,
```

**Problem:** both win every game they open, so an alternating pairing splits 50-50 and measures the seat rather than the strength. What separates them is Oracle's `blunderRate: 0.002` — roughly one blundered move in five hundred, so about four games in a hundred over a twenty-move game. A 300-point gap asserts Prime scores about 85% against Oracle; the mechanism in the code supports something nearer 52%.

**Fix:** either derive both ratings from performance against the *non-book* ladder and against the second seat, where the difference is real, or narrow the gap to what the blunder rate justifies. Success criterion: the gap between the two ratings is one that a recorded measurement supports. This is ticket 014's job and is flagged rather than fixed here.

---

### [MINOR] The hash that enforces "moves unchanged" is hand-rolled and has no test vector — `bug`

**File:** `packages/quadrim_engine/tool/bookgen.dart:186`

**Evidence:**

```dart
String sha256Hex(List<int> message) {
```

`grep -rn sha256 packages/quadrim_engine/test/` returns nothing.

**Problem:** this function is the whole mechanism behind the licence obligation that the dictionary's moves are unchanged (D172). It currently agrees with an independent implementation — that is how `_expectedSha256` was produced — but nothing preserves that agreement. A silent break would make the integrity check accept any file.

**Fix:** one test with the standard vector:

```dart
expect(sha256Hex(utf8.encode('abc')),
    'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
```

`bookgen.dart` is under `tool/`, so the test needs it imported by path or the function moved somewhere importable.

---

### [NIT] `bookprobe.dart` restates the move-choice order and can drift from it — `style`

**File:** `packages/quadrim_engine/tool/bookprobe.dart:26-44`

**Evidence:**

```dart
        if (_immediateWin(state, Player.first) != null ||
            _immediateWin(state, Player.second) != null) {
          immediate++;
        } else if (bookMove(state, Player.first) != null) {
```

**Problem:** the probe reproduces the order `chooseMove` applies. If that order changes, the probe keeps reporting confidently and wrongly, and its output is the evidence behind D173's central claim.

**Fix:** leave it, but only because it is a diagnostic rather than shipped code. If it is ever used to justify a decision again, have `chooseMove` report which rule fired instead of guessing from outside.

---

## Functional Validation

⚠️ No Jira issue key detected — this project tracks work in `doc/tickets/`. Validated against `doc/tickets/026-master-tier.md` and idea-v1 §14.

### Ticket 026 — Master tier

| # | Requirement | Status | Evidence |
|---|---|---|---|
| A perfect-play opponent exists | ✅ | `quadrimPrime`, `usesBook: true`; 200 games opening against random replies won 200, drawn 0, lost 0 |
| Perfect play is proved, not estimated | ✅ | `tool/bookprobe.dart`: of Prime's moves, 636 came from the book, 202 from the forcing search, 203 were an immediate win or block, and **0 fell through to the ordinary search** |
| Oracle at 2300 | ⚠️ | exists and plays the book with `blunderRate: 0.002`; the rating itself is not yet earned — see the minor finding above |
| Quadrim Prime at 2600 | ⚠️ | same — the opponent is right, the number is not yet measured |
| The strategy source is obtainable and licensed | ✅ | `third_party/patashnik/NOTICE.md`; the dictionary's own header grants use on two conditions, both mechanised |
| Moves unchanged | ✅ | vendored byte for byte, `.gitattributes` `-text`, SHA-256 verified by `tool/bookgen.dart` on every `tool/check.sh` run |
| Source credited | ✅ | `l10n.strategyCredit` in English and Dutch, rendered on the settings screen; `tool/check.sh` fails if nothing in `app/lib` renders it |
| No GPL-2.0 code taken | ✅ | only `qubic.dictionary` is vendored; `qval/` is absent from the tree, and NOTICE.md records the separation and how to preserve it |
| Ships inside the size budget | ✅ | 54,745 bytes of source data, 220 KB of generated Dart, against the 50 MB ceiling of D165 |
| Book lookup cannot return an illegal move | ✅ | the automorphism is a bijection, so an empty canonical cell maps to an empty real cell; exercised over 200 complete games, where `applyMove` would have thrown |
| Symmetry is handled | ✅ | 2929 entries → 2929 distinct canonical positions with no conflicts; the book's 12 ply-2 entries equal the 12 orbits of the remaining cells under the stabiliser of the opening cell, computed independently |

### Gaps

- **The two Master ratings are placeholders with opponents attached.** The opponents are real and verified; 2300 and 2600 are not yet measurements. Ticket 014 owns this, and the re-anchoring the owner asked for covers the Expert tier — these two sit above it and need the same treatment.
- **Second-seat move time is unmeasured** (the major finding). This is the one item that could violate a shipping constraint rather than merely a rating.

### Notes

- The licensing separation is the load-bearing judgement in this ticket and is **not legal advice**. What is recorded is what the dictionary's header says, what was taken, and what was deliberately not taken. Confirming it is the owner's call.
- The credit currently sits on the settings *placeholder*, which ticket 028 will replace. The `check.sh` grep exists precisely so that replacement cannot silently drop it.
- `symmetry.dart`, which the ticket-025 review flagged as having no production caller, is now load-bearing: the book cannot be read without it. The two open findings from that review — canonical hashing being unused, and canonical entries carrying an orientation-dependent move — are resolved in spirit here, because `CanonicalForm.cellFromCanonical` is exactly the inverse mapping that review said was missing.

### Post-review outcome

Three findings fixed, one resolved by measurement, one deferred with a reason, one nit left as noted.

| # | Finding | Outcome |
|---|---|---|
| 1 | Master tier move time unmeasured in the second seat | **Resolved by measurement.** Prime worst 7,017 ms, Oracle worst 7,543 ms, Titan worst 10,379 ms, all inside D164's twenty-second ceiling. The largest configuration in the catalogue is not the slowest one in it |
| 2 | Book consulted at every ply though it ends at ply 16 | **Fixed.** `deepestBookPly` guard above the canonicalisation, and a test derives the constant from the generated table rather than trusting it |
| 3 | Prime and Oracle cannot be separated by play | **Fixed, after two wrong designs — see below** |
| 4 | Hand-rolled SHA-256 has no test vector | **Fixed.** `test/bookgen_test.dart`, three standard vectors plus a 64-byte block-boundary case |
| 5 | `bookprobe.dart` restates `chooseMove`'s order | Left as noted; it is a diagnostic, not shipped code |

Finding 3 took three attempts and is worth recording, because the first two were built before being measured:

1. **A blunder rate.** Oracle shipped briefly with `blunderRate: 0.002`. `strategic_bot_test.dart:70` caught it: the catalogue requires blunder rate never to rise as rating rises, and Oracle at 2300 was blundering more than Titan at 2100. The invariant is right and the design was wrong.
2. **A shallower forcing search.** Eleven moves against Prime's twenty, a sixth the budget. Measured over 200 games it was **byte-identical** to Prime — same 636 book moves, 202 forcing-search moves, 203 immediate wins or blocks, zero fall-throughs, 200-0. The forced wins that follow the book are short enough that the extra depth never bites.
3. **The second seat**, which is the only place the book does not reach. Oracle searches there with the Expert tier's dials, Prime with the catalogue's largest. Measured against Titan over twelve games each: Oracle's second seat won **0 of 6**, Prime's won **3 of 6**.

The mechanism behind (3) is the defensive forcing search at depth nine against depth five — the dial the Expert tier already measured at 19-11 and 20-10. Six second-seat games apiece is a small sample and does not pin the gap at 300 points; ticket 014 turns the direction into a number. What matters here is that it is a real difference from a real mechanism, which the two designs before it were not.

Recorded as D176. It is the third negative result of the same family after D163 (depth) and D167 (evaluation), and together they say something worth carrying forward: **once an opponent finds short forced wins, more of the same buys nothing.** Every gain this ladder has ever made came from a different kind of knowledge — the defensive question (D169), and the book.

---

# Code Review: ticket 029 — placeholder art and opponent content

> Generated: 2026-08-09T20:24:11Z
> Base: 813dd26 (working tree vs HEAD, changes uncommitted at review time)
> Changed files: 25 (19 modified, 6 new)

Scope is ticket 029 only. `app/lib/l10n/app_localizations*.dart` are excluded as
generated output.

## Summary

| Severity | Count |
|---|---|
| critical | 0 |
| major | 0 |
| minor | 3 |
| nit | 1 |

Three of the four questions put to this review came back clean and are recorded
below the findings, because "we checked and it holds" is worth as much here as a
defect.

---

## Findings

### [MINOR] The avatar legibility floor is set to the value the sparsest avatar already has — `test-coverage`

**File:** `app/test/opponent_avatar_test.dart:31`

**Evidence:**
```dart
expect(density, greaterThanOrEqualTo(0.2), reason: '$id is nearly blank');
```

Measured across the twenty: the sparsest avatar is **Mote at exactly 3/15 =
0.200**, the next two are Ember and Kestrel at 5/15. The densest is 11/15.

**Problem:** The lower bound equals the minimum the current roster produces, so
the assertion has zero margin and cannot fail on anything shipping today — it
was fitted to the data rather than to a judgement about what is legible. Mote's
avatar draws three cells in the master columns, six after mirroring, on a 5×5
grid at 44 logical pixels.

**Fix:** Decide the floor from legibility, not from the sample — `0.27` (4/15)
is the next value up and would currently fail exactly one opponent, which is the
useful outcome: either Mote's avatar is too sparse and the seed should be salted
(`avatarSeed('$id-avatar')`), or 3/15 is genuinely fine and the comment should
say so rather than the number implying a margin that is not there.

---

### [MINOR] A Dutch string can go missing without failing anything — `test-coverage`

**File:** `app/l10n.yaml:1`

**Evidence:** `l10n.yaml` sets `arb-dir`, `template-arb-file` and
`output-localization-file`, and no `untranslated-messages-file`. Verified by
adding one key to `app_en.arb` only and running the gate's own command:

```
untranslated-messages-file: desiredFileName.txt
<other option>: <other selection>
This will generate a JSON format file containing all messages that
need to be translated.
gen-l10n status: 0
```

**Problem:** `flutter gen-l10n` *suggests* the option and exits **0**, so
`tool/check.sh` passes with an untranslated key and the app silently falls back
to English at runtime for that string. Ticket 029's own forty strings are
covered by `opponent_content_test.dart:31` and `:44`, but that test enumerates
`opponentCatalogue` — it protects blurbs and tier labels specifically, not the
next string anybody adds. Tickets 021 and 028 both add many.

**Fix:** Add `untranslated-messages-file: untranslated.json` to `app/l10n.yaml`
and fail the gate when it is non-empty:

```bash
[ -s app/untranslated.json ] && { echo "FAIL: untranslated strings"; cat app/untranslated.json; exit 1; }
```

---

### [MINOR] `icongen.py` fails with a raw traceback when run from anywhere but the repo root — `correctness`

**File:** `tool/icongen.py:72`

**Evidence:**
```python
root = "app/android/app/src/main/res"
```
Run from `tool/`:
```
Traceback (most recent call last):
  File "C:\D\Quadrim\tool\icongen.py", line 73, in main
    draw(size).save(path)
FileNotFoundError
```

**Problem:** Every path is relative to the repo root with nothing asserting the
working directory, so the obvious invocation — `cd tool && python icongen.py` —
dies in the Pillow save with a traceback that does not name the real cause. The
sibling generator handles this: `tool/bookgen.dart:33` checks and prints
`not found: ... (run from packages/quadrim_engine)`.

**Fix:** Resolve paths from the script's own location instead of the caller's:

```python
from pathlib import Path
ROOT = Path(__file__).resolve().parent.parent
...
path = ROOT / f"app/android/app/src/main/res/mipmap-{density}/ic_launcher.png"
```

---

### [NIT] The "avatars announce nothing" test cannot fail — `test-coverage`

**File:** `app/test/opponent_avatar_test.dart:78`

**Evidence:**
```dart
expect(
  find.descendant(
    of: find.byType(OpponentAvatar),
    matching: find.byType(Semantics),
  ),
  findsNothing,
);
```

**Problem:** A bare `CustomPaint` with no `semanticsBuilder` contributes no
semantics node whether or not it is wrapped in `ExcludeSemantics`, so this
assertion passes identically with the wrapper deleted. It documents the
intention but verifies nothing — and the intention is the part that would
break, if some later change gave the painter a `semanticsBuilder`.

**Fix:** Assert against the merged semantics of the subtree instead, which does
change when the wrapper is removed:

```dart
final node = tester.getSemantics(find.byType(OpponentAvatar));
expect(node.label, isEmpty);
```

Or delete the test and keep the comment on `ExcludeSemantics`; a test that
cannot fail is worse than no test, because it reads as coverage.

---

## Questions asked of this review that came back clean

**Can a wrong tier ship now that `tier` is defaulted rather than required?**
No. `packages/quadrim_engine/test/catalogue_test.dart:31` compares the
catalogue's id set against a hand-written map, so a twenty-first opponent fails
the suite until the map names it; `:39` then compares each opponent's `tier`
against that map, so an entry that forgets `tier:` and silently takes the
`BotTier.club` default fails too. Both failure modes were traced through. The
default is safe **because** the test is exhaustive over the catalogue — the two
are a pair, and removing either one removes the guarantee.

**Can the avatar hash collide?**
Not on the current roster: all twenty signatures are distinct, and
`opponent_avatar_test.dart:16` fails the build if two ever match. Headroom is
smaller than the 4 × 2¹⁵ = 131,072 signature space suggests — a synthetic sweep
found its first collision at the **153rd** id, because the pattern window
`(col * 5 + row + (seed & 7)) % 30` reads overlapping bits and its offset comes
from the same seed. That is ample for a roster of twenty and would still be
caught, loudly, by the existing test at any size.

**Does any player-facing string still overclaim Quadrim Prime?**
No. The only remaining occurrences of "perfect" in the arb files are
`strategyCredit`, which describes Patashnik's dictionary rather than the
opponent, and two `@`-prefixed metadata descriptions, which are never rendered.
Both Master blurbs state the first-player qualification, and
`opponent_content_test.dart:80` fails if either stops doing so.

---

## Outcome — all four applied

| # | Finding | What was done |
|---|---|---|
| 1 | Avatar legibility floor fitted to the sample | Metric replaced, salt added, band widened |
| 2 | A missing Dutch string fails nothing | `untranslated-messages-file` + gate in `check.sh` |
| 3 | `icongen.py` traceback from the wrong cwd | Paths resolved from `__file__` |
| 4 | Semantics test cannot fail | Rewritten twice, mutation-checked |

**Finding 1 was worse than the review said.** Rendering the twenty as a contact
sheet showed Mote as a bare vertical bar of three marks. The cause was not the
threshold but the measure: `avatarDensity` counted cells in the three master
columns, and the last of those is the mirror spine, which paints once where the
other two paint twice. Mote's three lit cells all fell on the spine, so it
scored the same 0.2 as any other three-cell avatar while drawing barely half the
ink. `avatarInkCells` now counts what is painted; the band is 6–21 of 25, set
as a judgement about a 5×5 face rather than read off the roster; a salt
(`avatar-v1`) moves the roster off the pattern set containing the unusable one.
The twenty now span **7 to 19**, with margin at both ends.

**Finding 4 took three attempts, and the first two fixes were also untestable.**
`find.byType(Semantics)` as a descendant matches structure, not announced
content. `tester.getSemantics` walks *up* to an ancestor node, so a label
attached to the avatar itself is never seen — that version passed unchanged with
the avatar deliberately given `Semantics(label: 'probe')`. Only
`find.bySemanticsLabel` goes red. Each version was mutation-checked before being
believed, which is the only reason the first two were caught.

**Finding 2 was verified in both directions** before being committed: red with a
deliberately untranslated key naming it in `untranslated.json`, green once
removed. `app/untranslated.json` is gitignored — it is regenerated on every run,
so committing it would only preserve a stale answer.

Gate after the fixes: `ALL CHECKS PASSED`, exit 0 captured without a pipe.
App 100 tests, engine 120, rating 19, linegen 8.

---

# Code Review: ticket 011 — opponent selection

> Generated: 2026-08-09T21:20:00Z
> Base: c12d5fc (working tree vs HEAD, changes uncommitted at review time)
> Changed files: 8 (6 modified, 2 new)

Scope is ticket 011 only. `app/lib/l10n/app_localizations*.dart` excluded as
generated output.

## Summary

| Severity | Count |
|---|---|
| critical | 0 |
| major | 0 |
| minor | 1 |
| nit | 2 |

---

## Findings

### [MINOR] At 200% text scale the app-bar title is pushed off the top of the screen — `accessibility`

**File:** `app/lib/game/opponent_screen.dart:40`

**Evidence:**
```dart
bottom: PreferredSize(
  preferredSize: const Size.fromHeight(28),
```

Measured by pumping the screen at three text scales and reading the rects:

| Text scale | "Choose an opponent" | "Your rating: 1182" | Gap |
|---|---|---|---|
| 1.0 | 14 – 42 | 56 – 76 | 14 px |
| 1.5 | — | 46 – 76 | — |
| 2.0 | **-1 – 37** | 36 – 76 | **-0.5 px** |

**Problem:** The bottom strip is a constant 28 logical pixels while the text
inside it scales with the user's font-size setting — 20 px at 1.0, 40 px at 2.0.
The `AppBar` absorbs the difference by growing upward, so at 200% the title's
top edge lands at **-1** — clipped by the screen — and the two strings touch.
No overflow error is raised, because nothing here is a flex; Flutter simply
paints them over one another. Android's font-size slider reaches 200% on stock
Pixel settings, so this is a real device configuration, not a synthetic one.

**Fix:** Scale the reserved height with the text, so the strip grows as its
contents do:

```dart
bottom: PreferredSize(
  preferredSize: Size.fromHeight(MediaQuery.textScalerOf(context).scale(28)),
```

Ticket 021 is the accessibility audit, but this was introduced here and the fix
is one line.

---

### [NIT] A comment claims a dependency on catalogue ordering that the code does not have — `documentation`

**File:** `app/lib/game/opponent_screen.dart:31`

**Evidence:**
```dart
// Grouped by walking the catalogue in order rather than filtering it five
// times: `catalogue_test.dart` holds tiers to be contiguous and ordered
// weakest first, which makes one pass correct and keeps the screen's
// ordering the catalogue's business rather than this widget's.
```

**Problem:** `putIfAbsent` groups correctly whether or not tiers are contiguous
— an interleaved catalogue would still produce five correct sections. The
contiguity guarantee affects only the *order* the sections appear in, not
whether the grouping is right. The comment claims correctness rests on an
invariant it does not rest on, which is the kind of thing a later reader
believes and then reasons from.

**Fix:** Say what the invariant actually buys: section order follows first
appearance, and the catalogue's ordering is what makes that the ladder's order.

---

### [NIT] A missing blurb would produce a label ending in a bare full stop — `correctness`

**File:** `app/lib/game/opponent_screen.dart:113`

**Evidence:**
```dart
final blurb = botBlurb(l10n, key) ?? '';
```
feeding
```dart
label: l10n.opponentSemantics(..., blurb),
```
whose pattern is `{name}. {tier}. Rating {rating}. {match}. {blurb}`.

**Problem:** With an empty blurb the announcement ends `"... Even match. "` —
harmless, but the `?? ''` implies the case is expected while the message shape
assumes it is not. **Not currently reachable:** the screen iterates
`opponentCatalogue`, and `opponent_content_test.dart:31` fails if any catalogue
member lacks a blurb in either language. It is defensive code guarding a case
another test already forbids.

**Fix:** Either drop the fallback and let the missing blurb be a loud failure,
or keep it and note in the comment that the guard is belt-and-braces against a
condition `opponent_content_test.dart` already enforces.

---

## Questions asked of this review that came back clean

**Can `_newGame` create a game the player did not choose, or leave a dangling
route?** No. `home_screen.dart:104` returns early when the opponent screen pops
null, before `createGame` is reached, and `bot_game_test.dart:57` asserts that
no game is stored at that point. Pass-and-play never reaches the list and
correctly passes `kGuestOpponent` with a null rating.

**Any `BuildContext` used across an async gap?** No. Every `await` is followed
by a `mounted` check before the next `context` use — `flutter analyze` runs with
`use_build_context_synchronously` active and reports no issues.

**Does `matchBalance` behave at the extremes?** Yes. The widest pairing the app
can produce is the rating floor against the top of the ladder — `expectedScore`
computes `10^((2400-100)/400)`, about 5.6 million, with no overflow and no
division by zero. `rating_test.dart` covers the seed against both ends of the
catalogue, the boundary either side of 190 points, and band symmetry across a
0–600 sweep.

**Does the tier grouping break if the catalogue is reordered?** No — see the nit
above; grouping is order-independent, and section order is pinned by
`catalogue_test.dart`.

## Outcome — all three applied

| # | Finding | What was done |
|---|---|---|
| 1 | Title clipped at 200% text scale | Height now scales with the text; regression test at 1.0/1.5/2.0 |
| 2 | Comment overstated an ordering dependency | Rewritten to say what the invariant actually buys |
| 3 | Blurb fallback guarded an impossible case | Kept, with the reason and the test that forbids it named |

The regression test for (1) asserts **positions**, not the absence of an
exception, because there is no exception: at 200% the AppBar grows upward to
fit its oversized bottom strip and paints the title off the top of the screen
with no overflow stripe and no error. Verified against the unfixed code, where
it reports `title clipped off the top at scale 2.0`.

Gate after the fixes: `ALL CHECKS PASSED`, exit 0 captured without a pipe.
App 111 tests, engine 120, rating 24, linegen 8. Verified on an emulator as
well: all twenty render grouped by tier, with three distinct match cues and
both Master blurbs stating the first-player qualification in place.

---

# Code Review: interface revisions after device review

> Generated: 2026-08-10T04:20:00Z
> Base: e7b5727 (working tree vs HEAD, changes uncommitted at review time)
> Changed files: 9 (all modified)

Three user-requested revisions, not a ticket: one-line game rows with avatars,
avatars in the by-opponent breakdown, and a single-open accordion on the
opponent list. `app/lib/l10n/app_localizations*.dart` excluded as generated.

## Summary

| Severity | Count |
|---|---|
| critical | 0 |
| major | 0 |
| minor | 1 |
| nit | 0 |

---

## Findings

### [MINOR] Game rows lost the minimum tap target when they stopped being ListTiles — `accessibility`

**File:** `app/lib/home/home_screen.dart:398`

**Evidence:**
```dart
child: Padding(
  padding: const EdgeInsets.symmetric(vertical: 8),
```

Measured by walking every `InkWell` on a rendered home screen at 1080×2400:

```
INKWELL height=44.0 width=400   <- the game row
INKWELL height=40.0 width=400   <- New game button (Material 3 default)
INKWELL height=40.0 width=400   <- Tutorial button
INKWELL height=40.0 width=40    <- settings icon button
```

**Problem:** The row is **44 dp** tall — 28 dp of avatar plus 8 dp of padding
either side. `ListTile`, which this replaced, enforces a minimum of 48 dp;
hand-rolling the row silently dropped that. Android's own accessibility
guidance and Material both specify 48 dp as the minimum touch target, and WCAG
2.5.8 sets 24 CSS px as the floor with 44 as the AA target size. The rows are
the primary way into a saved game, so this is the control most often missed.

For contrast, the accordion headers added in the same change measure **52 dp**
and are fine.

**Fix:** Constrain the row rather than padding it, so it holds at any text
scale rather than only at 1.0:

```dart
child: ConstrainedBox(
  constraints: const BoxConstraints(minHeight: 48),
  child: Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
```

---

## Questions asked of this review that came back clean

**Can `botConfigFor` misparse a stored opponent string?** No.
`opponent_name.dart:44` checks the `bot:` prefix before stripping it, so
`guest` returns null rather than slicing into a short string, and `bot:` with
an empty id reaches `botById('')` which returns null. Both fall through to the
neutral icon, and both have tests.

**Can the accordion strand the player with nothing open?** No. Tapping the open
section closes it, but all five headings stay on screen with their counts and
chevrons, and any of them reopens. `opponent_screen_test.dart:105` asserts the
headings survive with nothing open — that collapsed state is deliberate, since
it shows the whole ladder at once.

**Is `tierNearest` right at the boundaries?** Yes, and it is tested at all of
them: the rating floor and 0 land on Novice, 9999 lands on Master, and 1350 —
exactly between Ember at 1300 and Basalt at 1400 — resolves to the first of the
two rather than throwing. It walks the catalogue rather than consulting a band
table, which is what keeps it from re-coupling tier to rating (D179).

**Does the shared avatar slot throw for a guest or an unknown opponent?** No.
Both produce a null configuration and render the fallback icon;
`home_screen_test.dart` covers pass-and-play and a stored `bot:nonesuch`
separately, the latter asserting the row renders at all rather than crashing.

**Do collapsed sections break lazy building?** No, and they improve it. The
finished-games list is still a `SliverList.builder`, and its
"a long history does not build every row" test still passes over sixty games.
The opponent list builds only the open section — five tiles at most, where
before it built all twenty.

**Any semantics regression from dropping `ListTile`?** No. Measured on a
rendered row: the node carrying the label `"Ember. Won"` is also the node with
the tap action and the button flag — Flutter merges the `InkWell`'s gesture
semantics with the `Semantics` wrapper rather than producing a labelled node
and a separate tappable one, which was the failure worth checking for.

## Outcome — applied, plus a fourth revision

The tap-target finding is fixed with a `ConstrainedBox(minHeight: 48)` rather
than more padding, so it holds at any text scale instead of only at 1.0. Pinned
by a test that was checked against the unconstrained code first, where it
reports `Expected: a value greater than or equal to <48> / Actual: <44.0>`.

A fourth revision arrived mid-review and is included here: the "Your record"
heading is gone and its won-lost-drawn line now sits inside the rating card,
under the number (D192). Two knock-on effects were handled rather than
discovered later:

- **The card's announcement had to grow.** It is a `Semantics` container over
  `ExcludeSemantics`, so a string moved inside it is silent unless the label
  takes it too. The test now asserts the announcement carries both the rating
  and the record.
- **`yourRecord` was deleted from both locale files.** An orphaned key still
  gets translated and maintained, and the next reader cannot tell dead from
  not-yet-rendered.

Gate after all four: `ALL CHECKS PASSED`, exit 0 captured without a pipe.
App 129 tests, engine 120, rating 24, linegen 8.

---

# Ticket 018 — Tutorial: rules and controls

> Reviewed: working tree against `8fd4592` on `main` (changes uncommitted, so the
> working tree *is* the diff — `git diff MERGE_BASE HEAD` is empty).
> Changed: 13 tracked files + `app/lib/tutorial/` and `app/test/tutorial_test.dart`.
> `app/lib/l10n/app_localizations*.dart` excluded from line-by-line review: `flutter gen-l10n` output.

## Summary

| Severity | Count |
|---|---|
| critical | 0 |
| major | 0 |
| minor | 1 |
| nit | 1 |

## Findings

### [MINOR] `_finish()` has no re-entrancy guard, and the harness cannot catch it — `bug`

**File:** `app/lib/tutorial/tutorial_screen.dart:47`

**Evidence:**
```dart
Future<void> _finish() async {
  final settings = await widget.settings.loadSettings();
  await widget.settings
      .saveSettings(settings.copyWith(tutorialCompleted: true));
  if (mounted) Navigator.of(context).pop();
}
```

**Problem:** The button stays live across both awaits, and `mounted` stays true
for the route's ~300ms exit transition, so two "Done" taps inside the settings
write can each reach `Navigator.pop()` — the second one pops the home screen.

**Reproduction attempted and failed, which is the interesting part.** A probe
that taps `Done` twice in a single frame does *not* trigger it: with
`MemoryDocumentStore` the first `_finish` resolves in a microtask and the second
tap fails hit-testing (`would not hit test on the specified widget`). The window
only exists when `saveSettings` does real file I/O, which is exactly the store
every widget test is forbidden from using — `testWidgets` runs in a fake-async
zone that never completes real file I/O. So no widget test can ever demonstrate
this, and the absence of a failing test is not evidence of absence.

**Fix:**
```dart
bool _finishing = false;

Future<void> _finish() async {
  if (_finishing) return;
  _finishing = true;
  ...
}
```

### [NIT] `demoMoves` indexes the filler pool without checking it is long enough — `bug`

**File:** `app/lib/tutorial/tutorial_steps.dart:78`

**Evidence:**
```dart
List<int> demoMoves(List<int> line) {
  final filler = _fillers.where((c) => !line.contains(c)).toList();
  final moves = <int>[];
  for (var i = 0; i < line.length; i++) {
    moves.add(line[i]);
    if (i < line.length - 1) moves.add(filler[i]);
  }
```

**Problem:** `filler[i]` throws `RangeError` if a caller passes a line that
shares four or more cells with the six-cell `_fillers` pool. No current line
does — the test asserts it for all five — but `demoMoves` is public and tickets
019 and 020 will add positions.

**Fix:** `assert(filler.length >= line.length - 1, 'filler pool exhausted by $line');`

## Not findings, checked and cleared

- **The offer cannot be shown twice, and cannot be shown to a finished player.**
  `_offerTutorial` (`app/lib/home/home_screen.dart:81`) returns early on either
  flag and writes `tutorialOffered` before the dialog opens. Four tests cover
  never-asked / already-offered / already-completed / declined-then-recorded.
- **Recording before showing is a deliberate trade, not an oversight.** An
  `AlertDialog` is barrier-dismissible, and a dismissal returns `null`;
  recording afterwards would make the clearest "not now" gesture the one that
  guarantees the question returns (D193). Cost — a kill between the write and
  the dialog consumes that launch's offer — is one dialog, not the feature.
- **`context` is never used across an await unguarded.** `_offerTutorial` checks
  `mounted` before `showTutorialOffer(context)` and again before `_openTutorial`;
  `await X && mounted` parses as `(await X) && mounted`, which is what was meant.
- **No demonstration can render a non-line or end early.** All five lines are
  asserted to be members of `winningLines`, and separately asserted by *shape*
  (which coordinates are fixed and which vary) so a plausible-looking index
  typo that turns a diagonal into a row still fails. Filler is three pieces,
  which cannot complete a line, and each `demoMoves` output is replayed and
  asserted to end in `Win(Player.first, line)`.
- **The accessibility swap leaves nothing unreachable.** Both halves of D195
  were mutation-checked: removing the `Semantics` label leaves the sentence
  unfindable, removing `ExcludeSemantics` makes `Layer 1, row 1, column 1`
  findable. Every step's title is a header, body text is plain, and the six
  board steps all carry a non-empty `boardLabel` (asserted over the catalogue).
- **The four repository helpers that now pre-set `tutorialOffered` weaken
  nothing.** They only suppress a dialog that would otherwise open over the
  screen under test; no assertion in `smoke_test`, `home_screen_test`,
  `bot_game_test` or `game_screen_test` depends on settings state. The
  first-launch path they stop exercising is covered directly in
  `tutorial_test.dart`.

## Functional Validation

⚠️ No Jira issue key detected (no `.jira.json`, none in the branch name or
commits) — validated against `doc/tickets/018-tutorial-rules-and-controls.md`
instead.

| # | Criterion | Status | Evidence |
|---|---|---|---|
| 1 | Offered automatically on first launch | ✅ | `home_screen.dart:69` post-frame callback; `tutorial_test.dart` "is made to a player who has never been asked" |
| 2 | Restartable at any time from the main screen | ✅ | `home_screen.dart:233`; "can be restarted from the main screen" |
| 3 | Exitable at any point without completing | ✅ | `tutorial_screen.dart:63` close button; "leaving early does not mark it complete" |
| 4 | Completion persisted, survives restart, not re-offered | ✅ | `documents.dart:231`; "reaching the end marks it complete and survives a restart" re-reads via a second repository over the same store |
| 5 | Objective explained in a single screen | ✅ | step 1, `tutorialGoalTitle`/`Body` |
| 6 | One example from each of the four line families | ✅ | `tutorial_steps.dart:39-53`; "each family is represented, and they are distinct" asserts the shape of all four, not the indices |
| 7 | Examples on the real board component | ✅ | `tutorial_screen.dart:186` uses `BoardView`; "shows every family of winning line on a real board" reads `board.highlight` off the widget |
| 8 | Four parallelograms → one cube explained explicitly | ✅ | step 2, `tutorialLayersBody`, over the through-the-layers line |
| 9 | Player is shown how to place a piece | ⚠️ | step 3 explains tapping over a mid-game position, but the player cannot try it here — the interactive board is ticket 020 |
| 10 | Progress visible, steps revisitable | ✅ | `_Progress`; Back button and `PageView` swipe; "advances, goes back, and reports where it is" |
| 11 | Every step navigable by screen reader | ✅ | header flag, described board, live-region progress; both mutation-checked |
| 12 | All new strings in English and Dutch | ✅ | "every tutorial string exists in Dutch"; `check.sh` fails on any untranslated key (D184) |

### Gaps

- **Criterion 9 is partial by design.** "Shown how to place a piece" is
  satisfied as instruction, not as practice. Ticket 020 adds the interactive
  game and is the natural home for a hands-on version; nothing here needs to
  change unless 020 slips.

Gate: `ALL CHECKS PASSED`, exit 0, captured without a pipe.
App 148 tests, engine 120, rating 24, linegen 8.

### Outcome

Both applied.

- `_finishing` guard added at `app/lib/tutorial/tutorial_screen.dart:34`, with a
  comment recording *why* no test guards it — the harness structurally cannot.
- `assert` added at `app/lib/tutorial/tutorial_steps.dart:80`.

148 app tests still green, `flutter analyze` clean.

---

# Ticket 019 — Tutorial: basic strategy

> Reviewed: working tree against `730be24` on `main`.
> Changed: `app/lib/tutorial/tutorial_steps.dart`, `app/lib/tutorial/tutorial_screen.dart`,
> both `.arb` files (+ generated), `app/test/tutorial_test.dart`,
> `app/test/home_screen_test.dart` (step count), `doc/idea-v1-decisions.md` (D196–D198).

## Summary

| Severity | Count |
|---|---|
| critical | 0 |
| major | 0 |
| minor | 1 |
| nit | 1 |

## Findings

### [MINOR] Changing step announced the number but not the step — `accessibility`

**File:** `app/lib/tutorial/tutorial_screen.dart:130` (before the fix)

**Evidence:**
```dart
final label = l10n.tutorialStepOf(index + 1, total);
return Padding(
  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
  child: Semantics(
    container: true,
    liveRegion: true,
    label: label,
```

**Problem:** Pressing Next moves focus nowhere, so a screen-reader user heard
"Step 8 of 12" — that something changed, but not what — and then had to hunt
for the heading. Twelve steps, twelve hunts. The criterion is that every step
be *comprehensible* by screen reader, and this is the same failure D195 fixed
for the board, one level up.

**Fix:** `label: '$label. $title'`, with the title passed in from the step the
`PageView` is on. No new string: the titles are the ones the headings already
use.

### [NIT] The 200% text-scale test only ever saw step 1 — `test-coverage`

**File:** `app/test/tutorial_test.dart` (accessibility group)

**Evidence:** the sole scale test opened the tutorial and asserted on `The goal`,
which is the step with the *least* chrome. Ticket 019 then added a step carrying
progress + board + a full-width "Finish here" + the Back/Next row.

**Problem:** the step most likely to overflow was the one step never checked at
scale.

**Fix:** a second test pinning the section boundary at 360×780dp — the shortest
screen `kMinSupportedHeight` claims support for — at a text scale of 2.0.
**Probed before writing it: the layout already holds.** No code change; this
closes a coverage hole rather than a defect, which is why it is a nit.

## Not findings, checked and cleared

- **The strategy positions are what the captions say they are.** Not by
  inspection — by handing each to the engine. `kDoubleThreatMoves` yields
  exactly two first-player threats whose empty cells are the two highlighted,
  the opponent has none, and the game is `Ongoing`. `kBlockingMoves` yields
  exactly one second-player threat at the highlighted cell, *and no first-player
  threat at all* — a light win on the board would make "light has to block"
  false, since taking the win beats blocking.
- **The centre and corner claims are counted, not asserted.** Each of the
  sixteen cells is confirmed to lie on seven lines, and the set of all cells on
  seven lines is confirmed to be exactly those sixteen — so the two steps are
  provably exhaustive and no third family is being omitted.
- **"This is what the opponents do" cannot rot silently.** Every
  `StrategicRule` is asserted to be used by some catalogue entry and both biases
  to be non-zero somewhere; deleting a rule now fails a tutorial test.
- **`endsSection` is on exactly one step, and not the last.** Asserted as a
  list, so a second boundary or a boundary on step 12 — which would stack
  "Finish here" above "Done" — fails.
- **Skipping the strategy marks the tutorial complete, deliberately.** Ticket
  019 blesses stopping after the rules; not recording it would re-offer the
  whole thing next launch, which is the nagging D193 exists to prevent.
- **`_finish` is reached from both "Done" and "Finish here"**, so the
  re-entrancy guard added in ticket 018 covers the new path too.

## Functional Validation

⚠️ No Jira issue key — validated against `doc/tickets/019-tutorial-strategy.md`.

| # | Criterion | Status | Evidence |
|---|---|---|---|
| 1 | Value of the central 2×2×2 explained and shown | ✅ | step 8, `kCentreCells`; "the highlighted squares are the ones on seven lines" |
| 2 | Value of the corners explained and shown | ✅ | step 9, `kCornerCells`; same test |
| 3 | Double threat on a real position, why it cannot be blocked | ✅ | step 10; "the double threat really is one, and really cannot be blocked" |
| 4 | Blocking a developing threat demonstrated | ✅ | step 11; "the blocking position has exactly one threat, and it is dark's" |
| 5 | Strategy matches what the opponents use | ✅ | "the taught strategy is what the opponents actually do" |
| 6 | Positions on the real board component | ✅ | "shows the strategy on real positions too" reads `highlight` off `BoardView` |
| 7 | Skippable by a player who only wants the rules | ✅ | `endsSection`; "the strategy half can be skipped, and that still counts as finishing" |
| 8 | Every step navigable by screen reader | ✅ | headers, described boards, live region now carrying the title |
| 9 | All new strings in English and Dutch | ✅ | Dutch walk-through to step 10; `check.sh` fails on any untranslated key |

### Gaps

None — all nine criteria are addressed.

### Outcome

Both applied. Live-region label now carries the step title (D198); section-boundary
scale test added. 157 app tests green, `flutter analyze` clean.

---

# Ticket 020 — Tutorial: interactive practice game

> Reviewed: working tree against `185e27c` on `main`.
> New: `app/lib/tutorial/practice_hint.dart`, `app/lib/tutorial/practice_screen.dart`,
> `app/test/practice_test.dart`. Modified: `tutorial_screen.dart`, both `.arb`
> files (+ generated), `doc/idea-v1-decisions.md` (D199–D201).

## Summary

| Severity | Count |
|---|---|
| critical | 0 |
| major | 0 |
| minor | 1 |
| nit | 1 |

## Findings

### [MINOR] The reserved hint line was a live region even when empty — `accessibility`

**File:** `app/lib/tutorial/practice_screen.dart:124` (before the fix)

**Evidence:** walking the semantics tree on the opened practice screen, before
any hint is requested:

```
LIVE REGIONS: [[Your turn], []]
```

**Problem:** the hint line holds its height so the board does not jump when a
hint appears, but wrapping the *empty* placeholder in `Semantics(liveRegion:
true)` put an unlabelled focus stop between the status line and the board. A
screen reader lands on it and reads nothing.

**Fix:** keep the `SizedBox`, attach the `Semantics` only when `_hint != null`.
Re-measured after: `LIVE REGIONS: [[Your turn]]`.

**Note on the test.** No `find.bySemanticsLabel` can catch this — the defect is
a node with *no* label. The guard walks the tree and collects live-region
labels. Reaching the semantics owner turned out to be its own small problem:
since Flutter's multi-view work it hangs off a *child* of the root pipeline
owner, and `tester.binding.pipelineOwner`, which still reaches it in one line,
is deprecated and would fail `check.sh`. The helper walks to find it.

### [NIT] `_bestSquare` built the legal-move list twice — `performance`

**File:** `app/lib/tutorial/practice_hint.dart:60`

**Evidence:**
```dart
var best = legalMoves(state).first;
var bestScore = _score(best);
for (final cell in legalMoves(state)) {
```

**Problem:** two allocations of a list of up to 64 `Cell`s per hint press. Not
measurable; it is untidy rather than slow.

**Fix:** hoist to a local, with a comment recording why `.first` is safe —
`hintFor` has already returned null for a finished game, and a full board is a
finished game.

## Not findings, checked and cleared

- **Hints are the opponents' own ladder.** `hintFor` runs win → block → fork →
  best square using the same `threats()` the bots use. A test builds a position
  where a win *and* a block are both available and asserts the win is named:
  blocking there loses the game it was trying to save.
- **The fork claim is verified the way it is made.** `threats(applyMove(state,
  move), player).length >= 2` — the check and the claim are the same
  computation, so a hint cannot promise a fork the board will not show.
- **No hint can name an occupied square.** Not asserted on fixtures: a test
  walks a whole game to its end and checks every hint on the way.
- **The practice game cannot reach storage, structurally.** `PracticeScreen`
  takes no repository — there is nothing in scope to write to. Asserted three
  ways after a full game: no completed games, no active games, and the main
  screen still reading "No games yet." The last is the assertion a future
  `GameMode.practice` would fail.
- **The opponent is a catalogue member, not a script.** Asserted to be *in*
  `opponentCatalogue`, which is what stops a "practice opponent" being forked
  off later and drifting from the twenty. Fixed seed, so the tutorial is the
  same game for everybody and a test can play it through.
- **Following the advice actually wins.** The play-it-out test follows the hints
  move after move and asserts `You win!`. If the tutorial's own advice lost to
  the opponent the tutorial chose, the closing lesson would be that the lessons
  do not work.
- **No re-entrancy window in `_play`.** The move, the over-check and
  `_thinking = true` are all synchronous with no await between them, and the
  hint button and board are both gated on `_playerToMove`.
- **`botOpponent(kPracticeOpponent.id)` is not a smell.** `botName` keys on the
  stored `bot:<id>` form by design; this is the intended call, not a round trip.

## Functional Validation

⚠️ No Jira issue key — validated against `doc/tickets/020-tutorial-interactive-practice.md`.

| # | Criterion | Status | Evidence |
|---|---|---|---|
| 1 | Guided game against a deliberately beatable opponent | ✅ | `kPracticeOpponent = mote` (blunders 2 in 5); "is a real opponent configuration" asserts novice tier and a non-zero blunder rate |
| 2 | A configuration with a fixed seed, not a separate code path | ✅ | `kPracticeSeed`; asserted to be a member of `opponentCatalogue` |
| 3 | A hint can be requested at any point | ✅ | Hint button, enabled whenever it is the player's move |
| 4 | Hints from real threat detection, not scripted text | ✅ | `practice_hint.dart` calls `threats()`; seven unit tests over constructed positions |
| 5 | A hint names a concrete reason | ✅ | Four `HintKind`s, four distinct strings, each naming the square |
| 6 | The player can decline hints entirely | ✅ | Nothing shows until pressed; "shows nothing until a hint is asked for" asserts an empty highlight |
| 7 | A discouraged move is allowed and play continues | ✅ | "a move the hint discouraged is allowed, and play continues" plays elsewhere and checks the opponent still replied |
| 8 | Abandonable without blocking completion | ✅ | Close returns false; the test then finishes from the last step anyway |
| 9 | Completing it marks the tutorial finished | ✅ | "playing it out finishes the tutorial" |
| 10 | Never reaches the repository | ✅ | No repository in scope; asserted three ways |
| 11 | Hints announced by screen reader | ✅ | Live region carrying layer/row/column in the board's own words |
| 12 | All new strings in English and Dutch | ✅ | Dutch walk-through to a rendered hint; `check.sh` gate |

### Gaps

None — all twelve criteria are addressed.

### Outcome

Both applied. Live region now attaches to the message rather than the reserved
space (D201), with a tree-walking guard; `legalMoves` hoisted. 175 app tests
green, `flutter analyze` clean.

---

# Last-move and winning-line flash

> Reviewed: working tree against `8191fe2` on `main`. Not a ticket — a change
> asked for after playing the game.
> Changed: `app/lib/game/board_view.dart`, `app/lib/game/game_screen.dart`,
> `app/lib/tutorial/practice_screen.dart`, `app/test/board_flash_test.dart` (new),
> `app/test/game_screen_test.dart`, `doc/idea-v1-decisions.md` (D203).

## Summary

| Severity | Count |
|---|---|
| critical | 0 |
| major | 0 |
| minor | 0 |
| nit | 1 |

## Findings

### [NIT] `Cell.xyz(x, y, z)` was constructed three times per cell — `simplification`

**File:** `app/lib/game/board_view.dart:200` (before the fix)

**Evidence:**
```dart
child: _CellView(
  cell: Cell.xyz(x, y, z),
  ...
  highlighted: highlight.contains(Cell.xyz(x, y, z).index),
  flash: flash.contains(Cell.xyz(x, y, z).index) ? flashAnimation : null,
```

**Problem:** it was already twice before this change and the flash made it
three. Nothing measurable — `Cell` is a value wrapper round an int — but the
expression is now the noisiest thing in the loop.

**Fix:** a `_cell(x, y)` method that builds the `Cell` once. The collection-for
becomes `for (var x = 0; x < 4; x++) _cell(x, y)`.

## Not findings, checked and cleared

- **The flash cannot restart on every frame.** Every rebuild hands the board a
  freshly built list, so the restart test is `listEquals`, not `==`.
  Mutation-checked: swapping it turns "does not restart when the board rebuilds
  for another reason" red.
- **D124 survives.** A test asserts the flashed light piece stays more than 0.2
  luminance above the flashed dark one, so going green cannot quietly convert a
  lightness distinction into a hue one. Both are also asserted to actually be
  green (`g > r`, `g > b`), so the test cannot pass by the flash doing nothing.
- **The pulse rate is counted, not restated.** The test finds peaks in the
  sampled curve and divides by the real duration — 1 Hz against WCAG 2.3.1's
  three-per-second limit. Asserting `kFlashPulses / 4 < 3` would have passed
  whatever the curve did.
- **The colours are not copied into the test.** A flashing piece is compared
  against another piece of the same side on the same board that is not
  flashing, so the palette can change freely without touching the test.
- **Reduced motion is handled, not ignored.** `MediaQuery.disableAnimationsOf`
  holds the piece steadily green for the four seconds rather than pulsing —
  same information, nothing moving. Turning the cue off would have removed it
  from the people most likely to want it.
- **No re-entrancy or leak.** The controller is disposed with the state, and
  `didUpdateWidget` stops it when the flash list empties.
- **Per-frame cost is bounded.** The animation is passed down as null for
  non-flashing cells, so a frame rebuilds the one-to-four pulsing pieces rather
  than all sixty-four cells and their shear transforms.
- **The tutorial's demonstration boards do not flash.** They are static
  illustrations and one highlights eight cells at once. The practice game does,
  through the same `flashCells` helper the real game uses.
- **Verified on a device, not only in tests.** A dark piece flashing dark green
  in layer 1 against a resting black piece in layer 3, and a light piece
  flashing light green in layer 4. This is a change about whether something is
  visible; a passing test could not have answered that.

## Known gap, not addressed

- **A screen reader user still cannot find the opponent's last move.** The
  flash is a purely visual cue, and the problem it solves — "where did that
  piece go among sixty-four cells" — is worse without sight, not better. The
  turn banner is already a live region and could carry "Ember played layer 4,
  row 3, column 2", but that is a new string in two languages and a change to
  what the banner says, which is past what was asked for here. Belongs to
  ticket 021.

### Outcome

The nit applied. 189 app tests green, `flutter analyze` clean,
`ALL CHECKS PASSED` exit 0.

---

# Ticket 012 — Move-history scrubber

> Reviewed: working tree against `2202c93` on `main`.
> Changed: `app/lib/game/game_screen.dart`, both `.arb` files (+ generated),
> `app/test/review_test.dart` (new), `doc/idea-v1-decisions.md` (D204).

## Summary

| Severity | Count |
|---|---|
| critical | 0 |
| major | 0 |
| minor | 0 |
| nit | 0 |

## Findings

None survived verification. Two candidates were investigated and cleared;
both are recorded below because the investigation is the evidence.

## Investigated and cleared

- **"The scrubber buttons have no accessible name."** The semantics dump showed
  four button nodes with empty `label`. That reads as a criterion failure —
  "operable by screen reader" — and it is not one: Flutter puts an
  `IconButton`'s tooltip in the semantics `tooltip` field, which TalkBack
  reads, and `find.bySemanticsLabel` cannot see. Dumping the tree distinguished
  "the app is broken" from "the finder is wrong" in a single run. The test now
  asserts `node.tooltip` and `isButton`, so it still fails if the name is ever
  dropped.
- **"A timer leaks when the opponent moves during review."** A probe left a
  pending timer and the same probe without review mode did not. The difference
  is the test harness, not the app: a reviewed board is static, so no frames
  are scheduled, and `pumpAndSettle` returns without advancing past
  `kBotMoveDelay`. Worth knowing — this suite has been implicitly relying on
  the flash animation to advance simulated time — but nothing to fix in
  `lib/`. It did earn a real test: the opponent's reply is now pumped for
  explicitly, and the assertion is that it lands *and* the view does not move.

## Not findings, checked and cleared

- **Reviewing cannot alter the game.** The position is
  `GameState.fromMoves(moves.take(n))` — the same replay, stopped earlier —
  and there is no write path on the screen while reviewing. The test taps a
  cell that is empty in every position shown and asserts the stored move list
  is byte-for-byte unchanged, which is stronger than asserting the board
  did not update.
- **The height budget was measured, not estimated.** 6dp of slack at 360×780
  before cells fall under the audited floor, so the scrubber replaces the turn
  banner rather than joining it. The test pins both halves: the *playing* board
  still meets `kMinCellSize`, the reviewed one merely stays legible — the floor
  is a touch-target floor and nothing on a reviewed board is tappable (D135,
  D194).
- **Resign and Rematch are both out of reach while reviewing.** They are the
  only two controls on this screen that would change the game being looked at
  or start a different one.
- **Leaving review restores play, not just the view.** The test plays a move
  afterwards and asserts it lands in the stored game — a check that the board
  merely looks live would have passed with a dead board.
- **The announcement is not the visible text.** "Move 3 of 3" on screen;
  "Move 3 of 3. Layer 2, row 3, column 3, light piece" announced, reusing
  `cellSemantics` so coordinates are worded as the board words them (D198).
- **Move 1 is light regardless of seat.** The announcement derives the colour
  from move parity, matching `GameState`, not from `playerSeat`.

## Functional Validation

⚠️ No Jira issue key — validated against `doc/tickets/012-move-history-scrubber.md`.

| # | Criterion | Status | Evidence |
|---|---|---|---|
| 1 | Steps backward and forward one move at a time | ✅ | "steps back and forward one move at a time" |
| 2 | Board shows the position after the selected move | ✅ | same test asserts `BoardView.state.moves` at each step |
| 3 | Current move number and total visible | ✅ | `moveOf`; asserted as rendered text |
| 4 | Jumping to start and end without stepping | ✅ | "jumps to the start and to the latest move" |
| 5 | Scrubbing a live game alters nothing; no move from the past | ✅ | "no move can be made from a past position" |
| 6 | Returning to the present resumes play unchanged | ✅ | "leaving review resumes play exactly where it was" |
| 7 | Any completed game can be replayed | ✅ | "a finished game can be replayed the same way" |
| 8 | Operable by screen reader, position announced as it changes | ✅ | "the scrubber is reachable and the position is announced" |
| 9 | All new strings in English and Dutch | ✅ | "every scrubber string exists in Dutch"; `check.sh` gate |

### Gaps

None — all nine criteria are addressed.

Gate: `ALL CHECKS PASSED`, exit 0. App 199 tests, engine 120, rating 24, linegen 8.

---

# Ticket 028 — Settings screen

> Reviewed: working tree against `5e56bcd` on `main`.
> New: `app/lib/settings/settings_screen.dart`, `app/test/settings_test.dart`.
> Modified: `app/lib/main.dart` (root now watches the settings document),
> `app/lib/home/home_screen.dart` (placeholder deleted), both `.arb` files
> (+ generated), `app/test/home_screen_test.dart`, `doc/idea-v1-decisions.md` (D205).

## Summary

| Severity | Count |
|---|---|
| critical | 0 |
| major | 0 |
| minor | 0 |
| nit | 0 |

## Findings

None survived verification. One candidate was investigated and cleared.

## Investigated and cleared

- **"The radio choices are not announced as a group."** The first assertion
  said `isInMutuallyExclusiveGroup` was false, which would have meant a screen
  reader could not tell these were mutually exclusive. A semantics dump showed
  the opposite: `excl=true`, `checked=CheckedState.isTrue` on the selected one,
  and the headings carrying the header flag. Two harness facts caused the false
  alarm — `getSemantics` walks *up* and does not land on a merged
  `RadioListTile`'s own node, and `isChecked` is a `CheckedState` enum rather
  than a bool, so `expect(..., isTrue)` fails in a way that reads like a widget
  defect. The test now walks the tree by label.

## Not findings, checked and cleared

- **The attribution moved rather than vanished.** It rode on the placeholder
  screen this ticket deletes, precisely so that no build would ship with the
  credit merely planned (D174). It is now under "About" on this screen, a test
  asserts it renders, and `check.sh` still greps `app/lib` for the key — that
  grep is what would have caught a silent loss, and it passes.
- **"Follow the device" is the absence of an override.** `MaterialApp.locale`
  null and `ThemeMode.system`, not an invented `Locale('system')`. A test pins
  that choosing it clears a previously stored override rather than pinning
  whatever was last selected.
- **The override works in both directions.** The ticket motivates it with Dutch
  testers on English phones, and building only that direction would have passed
  a naive test. A separate test forces English on a Dutch-configured app.
- **The injected test locale still wins over the document**, so the existing
  locale tests are asserting that Dutch strings render, not exercising settings.
- **Persistence is checked against the bytes.** A second repository over the
  same store, and a distinct widget key so the relaunch is a relaunch — without
  it, `pumpWidget` updates the element tree in place and the Navigator keeps
  the settings route, so the test would have been standing on the same screen
  it started on.
- **`comingSoon` was deleted from both locale files**, not left behind, per
  D192: an unused key still gets read, translated and maintained.
- **Identical `languageEnglish`/`languageDutch` across locales is deliberate**,
  not a missing translation — a language names itself in its own language.
- **Largest font scale reaches the last row.** The screen is a `ListView` and
  the test scrolls to the attribution, which is the bottom-most element.

## Functional Validation

⚠️ No Jira issue key — validated against `doc/tickets/028-settings-screen.md`.

| # | Criterion | Status | Evidence |
|---|---|---|---|
| 1 | Reachable from the main screen | ✅ | gear icon routes to `SettingsScreen`; "is reachable from the main screen" |
| 2 | Language: system/English/Dutch, applied immediately | ✅ | "changing the language applies immediately, without a restart" — asserts the current screen *and* the one underneath |
| 3 | Theme: system/light/dark, applied immediately | ✅ | "changing the theme applies immediately" asserts `MaterialApp.themeMode` |
| 4 | Restart the tutorial from here | ✅ | "the tutorial can be restarted from here" |
| 5 | Choices persist and survive a restart | ✅ | "choices survive a restart", read back through a second repository |
| 6 | Screen reader, largest font scale, both themes | ⚠️ | first two asserted; "correct in both themes" is a visual claim no widget test settles — `themeMode` is asserted to change, and the appearance itself belongs to ticket 021 |
| 7 | All new strings in English and Dutch | ✅ | "every settings string exists in Dutch"; `check.sh` gate |

### Gaps

- **Criterion 6, "correct in both themes", is partial.** The test asserts the
  app *switches* to each theme; whether the result looks right in dark is a
  visual judgement, and this screen is now the easiest place in the app to
  make that switch. Ticket 021 gets a better tool than it had.

Gate: `ALL CHECKS PASSED`, exit 0. App 210 tests, engine 120, rating 24, linegen 8.

---

# Flash the last move of each side

> Reviewed: working tree against `37683c0` on `main`. Not a ticket — a
> correction after playing the game.
> Changed: `app/lib/game/board_view.dart` (`flashCells`),
> `app/test/board_flash_test.dart`, `app/test/game_screen_test.dart`,
> `doc/idea-v1-decisions.md` (D206).

## Summary

| Severity | Count |
|---|---|
| critical | 0 |
| major | 0 |
| minor | 0 |
| nit | 0 |

## Findings

None. The change is four lines in one function; the work was in the
investigation of the second report.

## Investigated: "the win line does not flash"

Reported alongside the change above. It **does** flash — established three
ways rather than by re-reading the code:

1. A widget test that samples the *painted* gradient rather than the flash
   list, immediately after a winning move and deliberately without
   `pumpAndSettle` (which would run the four seconds to completion before
   anything could be observed). All four cells of the line return
   `#fff4ffef,#ffb8eda4,#ff7fc96b` — full flash — against `#ff4a4a52,...`
   for a resting piece.
2. On the emulator, a light win: four bright green pieces plus the borders.
3. On the emulator, a dark win: four dark-green pieces, clearly distinct from
   the resting black. This was the case worth checking, since a dark-green
   flash on a black piece is inherently lower contrast than a light-green one
   on white.

The prior test asserted only that `BoardView.flash` *contained* the winning
line, which is why it could not have caught a rendering failure. That gap is
now closed by (1).

Timing, not logic, is the likely explanation for the report: the flash starts
at the instant the result panel animates in and the board resizes, and four
seconds is short when attention has just been pulled elsewhere. Recorded in
D206 as a real complaint about a real experience, with the remedy — a longer
or repeating flash for the winning line — left as the user's call, since four
seconds is a duration they chose.

## Not findings, checked and cleared

- **Two green cells are not ambiguous.** Light and dark flash to greens of
  their own lightness, so both being lit at once still reads as one piece each.
  The D124 luminance assertion already covers it and needed no change.
- **The scrubber gets it for free.** `flashCells` is shared, so stepping now
  shows the move stepped to *and* the one before it — the exchange rather than
  a single lit cell.
- **`state.moves.sublist` is safe at every length.** Lengths 0, 1 and 2 return
  the list itself; only longer positions slice. Covered by tests at each.
- **Parity trap in the game-screen test.** Adding a third assertion tap flipped
  which side completed the line and the win never happened. Caught by the test
  failing rather than by review — the assertion moved to the pure `flashCells`
  test where parity is explicit.

### Outcome

Shipped. 211 app tests green, `ALL CHECKS PASSED` exit 0.

---

# Widen both flash palettes

> Reviewed: working tree against `86e36d2` on `main`. Not a ticket — a second
> correction after playing the game.
> Changed: `app/lib/game/board_view.dart` (`_Pebble._lightFlash`,
> `_Pebble._darkFlash`), `app/test/board_flash_test.dart`,
> `doc/idea-v1-decisions.md` (D207).

## Summary

| Severity | Count |
|---|---|
| critical | 0 |
| major | 0 |
| minor | 0 |
| nit | 0 |

## Findings

None. Six colour constants and one test.

## The finding is against the previous review, not this change

The interesting part is that D203's palettes shipped through a review with a
test suite that could not have caught the defect.

**File:** `app/test/board_flash_test.dart:124` (as it stood before this change)

```dart
expect(light.computeLuminance(),
    greaterThan(dark.computeLuminance() + 0.2));
```

**Problem:** every assertion about flash colour compared the two *flashing*
pieces with each other. Nothing compared a flashing piece with a resting piece
of its own colour — which is the only comparison a player makes. A palette
where both pieces went green at exactly their resting lightness satisfies every
one of them, and that is what shipped: the light piece moved 0.78 → 0.73 and
the dark one 0.012 → 0.049.

**Fix, applied:** a test that samples a flashing and a resting piece of the
same colour from one board and pins the gap in the direction each moves.
It fails on the shipped palettes.

## Not findings, checked and cleared

- **D124 still holds, with margin.** The two flashing pieces differ by 0.36
  relative luminance, against the 0.2 the existing test demands. Verified by
  that test passing unchanged rather than by recomputing it here.
- **The margin is now the binding constraint** and D207 records it: a third
  round of widening would have to move the audited floor or change the
  mechanism, not the colours.
- **Nothing else reads these constants.** The winning-line borders and the
  cell backgrounds have their own colours; `_lightFlash`/`_darkFlash` are
  private to `_Pebble` and referenced only in `_build`.
- **Reduced motion is unaffected.** It selects between strength 1 and 0 on the
  same lerp, so it inherits the new endpoints with no separate path.

### Outcome

Shipped. 212 app tests green, `ALL CHECKS PASSED` exit 0.

---

# Ticket 014 — Rating maths and the self-play calibration harness

> Reviewed: working tree against `02a753a` on `main`.
> New: `packages/quadrim_engine/tool/calibrate.dart`.
> Changed: `packages/quadrim_rating/lib/quadrim_rating.dart`,
> `packages/quadrim_rating/test/rating_test.dart`,
> `packages/quadrim_engine/tool/duel.dart`,
> `packages/quadrim_engine/pubspec.yaml`,
> `packages/quadrim_engine/lib/src/bot.dart` (the Casual tier),
> `packages/quadrim_engine/test/positional_bot_test.dart`,
> `CLAUDE.md`, `doc/idea-v1-decisions.md` (D208–D210), the ticket.

## Summary

| Severity | Count |
|---|---|
| critical | 0 |
| major | 0 |
| minor | 2 |
| nit | 1 |

All three were fixed during the review. Both `minor` findings were reproduced
by running the tool, not by reading it.

## Findings

### [MINOR] A small `--budget` turns a searching opponent into a different opponent — `bug`

**File:** `packages/quadrim_engine/tool/calibrate.dart:196`

**Evidence** — before the fix:

```dart
nodeBudget: (config.nodeBudget * scale).round(),
forcingBudget: (config.forcingBudget * scale).round(),
```

`chooseMove` switches on the budget being non-zero, in two places:

```dart
// bot.dart:635
if (candidates.length > 1 &&
    (config.searchDepth > 0 || config.nodeBudget > 0)) {
// bot.dart:738
final scores = config.nodeBudget > 0 ? deepSearch(...) : ...
```

**Problem:** rounding a non-zero budget to zero does not make an opponent think
briefly — it stops it searching at all. Quartz through Quadrim Prime have
`searchDepth: 0`, so they become rules-only opponents while the report still
carries their names and ratings. Reproduced: `--only quartz --budget 0.0000001`
printed `quartz vs corvus 1-1-0 measured 0` as a measurement of two opponents
that were no longer searching. `SearchLimits` also asserts `nodeBudget > 0`
(`search.dart:35`), so the forcing path is an assertion failure rather than a
wrong answer.

Not reachable at the default scale — the smallest real budget is 200,000 — but
`--budget` is an advertised flag and the failure is silent.

**Fix, applied:**

```dart
/// [budget] scaled, never crossing from "some" to "none".
int _scaleBudget(int budget, double scale) =>
    budget == 0 ? 0 : max(1, (budget * scale).round());
```

### [MINOR] `duel.dart` with zero games throws instead of complaining — `bug`

**File:** `packages/quadrim_engine/tool/duel.dart:58`

**Evidence:**

```dart
final margin = 0.5 / games;
final score = ((aWins + draws / 2) / games).clamp(margin, 1 - margin);
```

**Problem:** introduced by this ticket's own change. At `games == 0`, `margin`
is `Infinity` and `raw` is `NaN`, so `clamp` is called with
`lowerLimit > upperLimit`. Reproduced:

```
mote 0 - 0 twig  (draws 0, games 0)
Unhandled exception:
Invalid argument(s): Infinity
#1      main (file:///C:/D/Quadrim/packages/quadrim_engine/tool/duel.dart:53:47)
```

Before this ticket the same invocation printed a zero-game line and exited 0.
`calibrate.dart` already guarded the equivalent case; `duel.dart` did not.

**Fix, applied:** reject `games <= 0` with a message, above the arithmetic.

### [NIT] `--seed` accepted junk and silently used 0 — `bug`

**File:** `packages/quadrim_engine/tool/calibrate.dart:469`

**Evidence** — before the fix:

```dart
case '--seed':
  seed = int.tryParse(value) ?? 0;
```

**Problem:** `--games` and `--budget` reject an unparseable value; `--seed` did
not. `--seed oops` ran with seed 0, so two runs the caller believed were
independent would be identical.

**Fix, applied:** `return null` on a parse failure, like its two neighbours.

## Not findings, checked and cleared

- **The dev dependency does not leak into the purity gate.** `check.sh` reads
  the block between `dependencies:` and the next top-level key, and
  `dev_dependencies:` matches its `^[a-z_]+:` terminator. Verified by running
  the gate's own awk: both pure packages still report `[]`.
- **No opponent can be paired with itself.** `_pairsFor` draws cross-tier
  representatives only from tiers other than the subject's, and neighbours are
  `index ± 1`.
- **The catalogue invariants survive the Casual-tier rewrite.** Blunder rate is
  still non-increasing with rating (0.15 / 0.13 / 0.11 / 0.10 / 0.08), Finch's
  centre bias is still above 0.5, Kestrel's corner bias and aggression are
  still above it, Willow's aggression still below, and Ember's blunder rate is
  still exactly 0.08. The roster test asserts every one of these and passes.
- **The swept-pair bound directions are right.** For a pair swept by `a`, `a`'s
  estimate is a floor and `b`'s a ceiling, because the clamped gap understates
  the sweeper. Traced through both branches.
- **The inversion report now names the winner from the measurement**, not from
  the catalogue. The first full run printed all three inversions backwards —
  "kestrel beats finch" on a line reading `finch vs kestrel 19-11`. Fixed
  before the second run, which named all three correctly.
- **The control swap in `positional_bot_test.dart` is a strengthening.** Ember's
  zero biases were incidental; Bramble's are pinned by the roster test
  (`expect(bramble.centreBias, 0)`), so the control can no longer be
  invalidated by a tuning change without a test failing.

## What the reviewed run actually measured

Second full run, after the Casual-tier rewrite: 29 pairs, 30 games each, 6m 28s.
Sixteen of twenty opponents inside the 150-point tolerance. Four outside:
Pebble (−485, from one pair), Twig (+205), Sable (+191, one readable pair),
Quadrim Prime (−224, one readable pair and the opponent the reduced budget hits
hardest). Two inversions remain and are a roster conflict rather than a
configuration defect — see D210 and the note on the ticket.

**A caution about the recorded runtime.** The first full run took 43m 55s and
the second 6m 28s, same settings. The likeliest cause is that an Android
emulator was running during the first. The figure in CLAUDE.md is the idle-machine
one and is stated as such; anyone repeating the run on a busy machine should
expect the larger number.

### Outcome

Shipped. The ordering criterion carries two named exceptions, accepted by
explicit decision (D211) rather than by shrugging: the Casual-tier inversions
are a roster conflict that no configuration change closes, so they are owned by
the 1.0 roster revision. Gate: `ALL CHECKS PASSED`. Engine 120 tests, rating 29,
app 212, linegen 8.

---

# Ticket 027 — Rating against the computer

> Reviewed: working tree against `eded7c2` on `main`.
> New: `app/test/rating_fold_test.dart`.
> Changed: `tool/check.sh` (release-manifest network guard),
> `doc/idea-v1-decisions.md` (D212), the ticket.
>
> A **verification** ticket: the implementation shipped incidentally with 013,
> so what was reviewed is whether each criterion is actually met and actually
> pinned — not new production code.

## Summary

| Severity | Count |
|---|---|
| critical | 0 |
| major | 1 |
| minor | 0 |
| nit | 0 |

## Findings

### [MAJOR] Every rating rule the ticket names was unproven — `test-coverage`

**File:** `app/lib/data/rating_fold.dart:42`

**Evidence** — the entire coverage of the fold before this ticket, both
assertions in `test/home_summary_test.dart`:

```dart
expect(summary.computerRating, kSeedRating);          // line 48, empty history
expect(HomeSummary.from(games).computerRating,
       greaterThan(kSeedRating));                     // line 167, two wins
```

**Problem:** `greaterThan(kSeedRating)` after two wins passes on almost any
monotonic function of the game list. Nothing checked that the fold uses the
**stored anchor** rather than the current catalogue rating — the one property
that keeps a recalibration from silently rewriting a player's history, and the
property most at risk this session, since ticket 014 had just changed four
opponent configurations. Nothing checked the K step, the draw score, the floor,
the player's seat, or that the fold depends on completion order at all.

**Fix, applied:** `app/test/rating_fold_test.dart`, eleven tests at the
document level, one per rule the ticket names.

## Not findings, checked and cleared

- **Criterion 12 has no code to test, so it is mechanised instead.** The
  release manifest declares no `INTERNET` permission, so Android refuses a
  network call whatever the code asks for. `check.sh` now fails if that
  changes (D212). The guard was verified by adding the permission and watching
  the gate fail, then reverting — a check nobody has seen fail is a check
  nobody knows works.
- **The app has nothing to make a call with.** Runtime dependencies are
  `intl`, `path_provider`, `quadrim_engine`, `quadrim_rating`. That is a fact
  about today's pubspec, which is why the guard is on the manifest.
- **Criteria 10, 11, 13, 14 were already pinned.** The rating on the main
  screen, its "against the computer, on this device only" note, the screen
  reader announcement, and the result-screen delta are covered by
  `home_screen_test.dart:78`, `:86`, `:238` and `result_screen_test.dart:88`.
  Dutch strings for all four keys exist in `app_nl.arb`.
- **Criterion 8 is covered twice**, once at the fold and once at the UI:
  `result_screen_test.dart:122` asserts a pass-and-play result says plainly
  that no rating changed.
- **The ordering contract is not duplicated.** `repository_test.dart:158`
  already pins that `loadCompletedGames` returns newest-first by `completedAt`;
  the new test pins only that the fold *depends* on it.

## One thing the new tests got wrong first

The order-sensitivity control asserted that reversing two games changes the
rating. It failed: a loss to 600 and a win over 2000 give **1201 either way**,
because the two deltas very nearly cancel whichever order they fall in. The
fixture could not serve as its own control. Replaced with twenty-one games,
where the K change at the twentieth puts one result on the far side of the
boundary and the order genuinely decides the answer.

Worth recording because the failure mode is invisible when a control passes:
had the two-game fixture happened to differ by a point, the test would have
"passed" while proving nothing about order.

### Outcome

Shipped. All 14 acceptance criteria met. Gate: `ALL CHECKS PASSED`.
App 223 tests, engine 120, rating 29, linegen 8.

---

# Rating bars under the opponent breakdown

> Reviewed: working tree against `051ec3c` on `main`. Not a ticket — a
> requested change to the main screen.
> Changed: `app/lib/home/home_screen.dart` (`_OpponentSection`, new
> `_RatingBar`), `app/lib/l10n/app_{en,nl}.arb`,
> `app/test/home_screen_test.dart`, `doc/idea-v1-decisions.md` (D214).

## Summary

| Severity | Count |
|---|---|
| critical | 0 |
| major | 0 |
| minor | 0 |
| nit | 0 |

## Findings

None surviving. Two were found and fixed while writing it, both in the new
code and both caught before the first build.

## Fixed in place

- **A dead parameter with a comment that described something else.**
  `LinearProgressIndicator(semanticsLabel: null)` is the default, and the
  comment above it explained why the unfilled track is meaningful — a true
  statement attached to a line that did not implement it. The parameter is
  gone and the comment now sits on `backgroundColor`, which is what actually
  draws the track.
- **The bar would have been decorative to a screen reader.** A length is
  invisible, so the row now carries `opponentRowSemantics` (name, rating,
  record) with the visual children excluded. Without it the row would be
  strictly less informative to a non-sighted player than to a sighted one.

## Not findings, checked and cleared

- **The scale cannot drift from the roster.** `opponentCatalogue.last.rating`
  rather than a literal 2400, and `strategic_bot_test.dart:39` already pins
  that the catalogue is ordered weakest first — so the ceiling follows a new
  opponent instead of needing to be updated alongside one.
- **A stored anchor above today's ceiling cannot overflow the bar.** `value`
  is clamped to `0.0..1.0`. Reachable in principle, because the anchor comes
  from the game it was played in and a recalibration could lower the
  catalogue's top.
- **A null rating draws no bar rather than an empty one**, matching the
  existing `_weakestFirst` reasoning that an unknown number is not a low one.
- **The row's other assertions still hold.** `ExcludeSemantics` covers the
  avatar, and the four existing by-opponent tests (avatars, shared left edge,
  smaller avatar than the selection screen, unknown opponent) pass unchanged.
- **Proportions verified on the device, not just in the widget tree.**
  Measured off an emulator screenshot: Bramble's fill ends at 41.6% of the
  track against a predicted 1000/2400 = 41.7%, Basalt's at 58.2% against
  1400/2400 = 58.3%.

### Outcome

Shipped. Gate: `ALL CHECKS PASSED`. App 226 tests, engine 120, rating 29,
linegen 8.

---

# A rating pill beside each opponent name

> Reviewed: working tree against `38a30c0` on `main`. A follow-on to the
> rating bars, same section of the same screen.
> Changed: `app/lib/home/home_screen.dart` (new `_RatingPill`, the name slot),
> `app/test/home_screen_test.dart`, `doc/idea-v1-decisions.md` (D215).

## Summary

| Severity | Count |
|---|---|
| critical | 0 |
| major | 0 |
| minor | 0 |
| nit | 0 |

## Findings

None surviving. Two were caught before the first build, both in the new code.

## Fixed in place

- **`l10n_of(context)` does not exist.** Written from muscle memory for a
  helper this project does not have; the pattern here is
  `AppLocalizations.of(context)!`. Caught by `flutter analyze`.
- **`FontFeature.tabularFigures()` needed an import it did not earn.**
  Tabular figures only align digits within the same digit count, and these
  ratings are three and four digits, so it bought nothing. Removed rather
  than imported for.

## Not findings, checked and cleared

- **The number is not announced twice.** The row's `Semantics` already carries
  it and `ExcludeSemantics` covers the pill. Pinned by asserting the bare
  number is absent as a standalone label — without that assertion, "announced
  once" and "announced twice" look identical from a passing test.
- **A long name cannot push the pill off the row.** The name is `Flexible`
  with `TextOverflow.ellipsis` inside the `Expanded` slot. This is not
  hypothetical: names are localised and the Dutch build is not obliged to
  match English widths.
- **A missing anchor draws no pill**, on the same `if (rating != null)` as the
  bar, so the two presentations can never disagree about whether a rating is
  known.
- **The test scopes through the pill, not the name.** An opponent's name
  appears twice on this screen — the breakdown and the finished game — and the
  first version of the test failed on exactly that ambiguity. Asking which row
  holds the *rating* is unambiguous and is also the claim being made.

### Outcome

Shipped. Gate: `ALL CHECKS PASSED`. App 228 tests, engine 120, rating 29,
linegen 8.

---

# The rating pill in every section, and a flake it uncovered

> Reviewed: working tree against `925395a` on `main`.
> Changed: `app/lib/home/home_screen.dart` (`_GameRow`),
> `app/lib/l10n/app_en.arb` (description only),
> `app/test/home_screen_test.dart`, `doc/idea-v1-decisions.md` (D215, D216).

## Summary

| Severity | Count |
|---|---|
| critical | 0 |
| major | 1 |
| minor | 0 |
| nit | 0 |

## Findings

### [MAJOR] A test guarding the rating's ordering failed one run in three — `flaky-test`

**File:** `app/test/home_screen_test.dart:16` (`_repository`, as it stood)

**Evidence** — the default the fixture was taking:

```dart
now ?? () => DateTime.now().toUtc(),
newId ?? _randomId,
```

and the rule those two feed, `local_game_repository.dart:111`:

```dart
final byTime = (b.completedAt ?? b.updatedAt).compareTo(a.completedAt ?? a.updatedAt);
return byTime != 0 ? byTime : b.id.compareTo(a.id);
```

**Problem:** two fixture games created back to back routinely complete inside
the same millisecond, so `byTime` is 0 and the **random** id decides. Measured
before the fix: 2 failures in 6 runs of the file, always
`lists finished games most recent first`, with no source change between a pass
and a fail.

This is the ordering the computer rating is folded in (spec §8.3) — the
contract `repository_test.dart:158` pins and `rating_fold_test.dart` builds
on. A guard that fails a third of the time trains everyone to re-run instead
of read.

**Fix, applied:** the fixture injects a clock advancing one second per call.
The repository is untouched: its rule is deterministic given distinct
timestamps, and real games do not finish in the same millisecond. Verified
with 8 consecutive clean runs against the previous 2-in-6.

## Not findings, checked and cleared

- **One change, three sections.** The in-progress and finished lists share
  `_GameRow`, so the pill went in once. A test creates an *active* game
  specifically to prove the shared row is what changed rather than one caller.
- **A game row shows the anchor it was played against**, `game.opponentRating`,
  not the catalogue's current value — the same rule as the rating fold, so a
  recalibration cannot rewrite what a finished game says it was worth.
- **Pass-and-play draws no pill**, on the same null check as the bar, so the
  two presentations cannot disagree about whether a rating is known. Pinned by
  asserting no stadium-shaped container exists on such a screen.
- **The layout test got stronger, not weaker.** It now asserts the
  name-then-pill relationship for *every* occurrence rather than one, which
  covers each section without a fixture per section.
- **Four existing tests changed because the labels genuinely changed**
  (`Ember. Won` → `Ember. Rating 1300. Won`, and two rows now announce a
  rating where one did). Each was updated to the new truth rather than
  loosened.

### Outcome

Shipped. Gate: `ALL CHECKS PASSED`. App 230 tests, engine 120, rating 29,
linegen 8.

---

# The rating change on each finished game

> Reviewed: working tree against `1a477e5` on `main`.
> New maths: `quadrim_rating` `ratingSteps`, `rating_fold.dart` `ratingDeltas`.
> Changed: `app/lib/home/home_screen.dart` (`_GameRow`, new `_RatingDelta`),
> tests in all three, `doc/idea-v1-decisions.md` (D217).

## Summary

| Severity | Count |
|---|---|
| critical | 0 |
| major | 0 |
| minor | 0 |
| nit | 0 |

## Findings

None surviving. One assumption of mine was wrong and the code was right.

## What the tests corrected

- **"A win always gains points" is false.** A first draft asserted
  `greaterThan(0)` for every win and failed on `beating 100`: from the seed
  that is `32 x 0.0018`, which rounds to **zero**. The assertion was wrong,
  not the fold. It now pins the true property — a win never *costs* and a loss
  never *pays* — plus a test that a rounded-away step is reachable, because
  the UI branches on it and an unexercised branch rots.

## Not findings, checked and cleared

- **Not quadratic.** `computerRatingAround` re-folds the prefix per game;
  drawing a hundred rows that way is five thousand fold steps. `ratingSteps`
  walks once and the screen calls it alongside the summary, not per row.
- **The two folds cannot drift.** A test pins
  `sum(ratingSteps) == ratingFrom(games) - kSeedRating` across the K boundary,
  and another checks step-for-step against `ratingAround`. Confirmed on the
  device too: the four rows read -24, +9, +25, +11, summing to +21 against a
  card showing 1221 from a 1200 seed.
- **Colour is not the only signal.** Arrow direction and the sign each carry
  the meaning independently, so red/green is confirmation. That matters more
  here than elsewhere in the app: red-versus-green is the worst pair for the
  most common colour vision deficiency, where D124's light-versus-dark is the
  best.
- **A zero step draws no arrow**, and 0 is reachable rather than theoretical.
- **Pass-and-play draws nothing** — absent from the delta map rather than
  mapped to zero, so "no change" and "no rating" stay distinguishable.
- **The floor truncates a step rather than being ignored by it**: at 100 a
  loss reports 0, pinned in the rating package.

### Outcome

Shipped. Gate: `ALL CHECKS PASSED`. App 233 tests, engine 120, rating 35,
linegen 8.

---

# Ticket 030 — Main screen decomposition

Reviewed against `4ba67ad`. Working tree, six new files under `app/lib/home/` plus
`home_screen.dart`. The `doc/` and `README.md` changes in the same tree belong to
the specification and ticket-breakdown work and were out of scope.

## Summary

| Severity | Count |
|---|---|
| critical | 0 |
| major | 0 |
| minor | 0 |
| nit | 2 |

The ticket's central claim is that the diff is **a move**. That is the thing worth
verifying mechanically rather than by reading, so it was: every extracted class
body was pulled from `HEAD:app/lib/home/home_screen.dart` and from its new file,
whitespace-normalised, and compared after substituting the privacy prefix and the
`super.key` insertion.

| Extracted | Result |
|---|---|
| `RatingCard`, `OpponentSection`, `ActiveGameTile`, `FinishedGameTile` | identical |
| `OpponentAvatarSlot`, `GameRow`, `RatingDelta` | identical |
| `RatingPill`, `RatingBar`, `SectionHeading` | identical |
| `signedDelta`, `opponentLabel`, `resultLabel` | identical |
| `_gameSection` → `gameSectionSlivers` | identical apart from `_SectionHeading` → `SectionHeading` |
| `_HomeScreenState` | identical once the helper moves out |

`home_screen.dart` 769 → 280 lines. All 237 app tests pass with **no test file
touched** (`git status --short app/test/` is empty), which is the criterion that
actually distinguishes a move from a rewrite.

## Findings

### [NIT] Nine widgets gained `super.key`, which is not strictly "a move" — `style`

**File:** `app/lib/home/rating_card.dart:16`

**Evidence:**
```dart
class RatingCard extends StatelessWidget {
  const RatingCard({super.key, required this.summary});
```
against the original `const _RatingCard({required this.summary});`

**Problem:** The ticket says each body is unchanged "apart from imports and its
privacy modifier". `super.key` is a third change, on nine widgets.

**Fix:** None — it is forced rather than chosen. `flutter_lints` enables
`use_key_in_widget_constructors`, which applies to public widgets and not to
private ones, so making these public without a key parameter fails
`flutter analyze`. It is behaviour-neutral: no call site passes a key, so every
`key` stays null exactly as before. Recorded so the deviation is on the record
rather than discovered by someone re-running the same comparison.

### [NIT] `game_row.dart` is 218 lines against a stated ceiling of roughly 200 — `style`

**File:** `app/lib/home/game_row.dart:1`

**Evidence:** `wc -l app/lib/home/game_row.dart` → 218.

**Problem:** The ticket asks that no new file exceed roughly 200 lines, on the
grounds that a section wanting more is a sign it needs splitting further.

**Fix:** Leave it. The file holds `GameRow`, `OpponentAvatarSlot`, `RatingDelta`
and three label helpers, and roughly half its length is the doc comments that came
with them — the reasoning about the 48 dp constraint (D189) and about the arrow's
direction carrying meaning independently of colour (D124) is exactly the kind of
comment this repository keeps. Splitting it further would separate `GameRow` from
the helper functions only it calls. "Roughly" covers 9%.

## Not findings, checked and cleared

- **Import cycles.** None. The graph is a DAG with two leaves: `section_widgets` and
  `rating_card` import nothing local; `game_row` → `section_widgets`;
  `active_games`, `finished_games`, `opponent_section` → `game_row`; `home_screen`
  imports the five sections. Verified by parsing the `import '<local>.dart'` edges.
- **Localisation drift.** The set of `l10n.<key>` references across the six new
  files plus `home_screen.dart` is exactly the set the original file had — nothing
  added, nothing removed. That is criterion 5 of the ticket, mechanically.
- **Semantics labels.** Unchanged, and this matters more than it looks: the
  `Semantics(container: true, label: …)` / `ExcludeSemantics` pairing in
  `RatingCard`, `OpponentSection` and `GameRow` is what keeps each row a single
  announced node. All three came through the body comparison identical.
- **Element identity and state preservation.** The extracted widgets' `runtimeType`
  changed (`_RatingCard` → `RatingCard`), which `Widget.canUpdate` does compare.
  No risk here: all ten are `StatelessWidget` with no state to preserve, and the
  types change together across the whole tree in one build rather than one old and
  one new type meeting at the same position.
- **`OpponentAvatarSlot.size` and the label helpers became public.** A widening of
  the API surface — `signedDelta`, `opponentLabel` and `resultLabel` are now
  importable top-level functions rather than file-private. Unavoidable once the
  callers moved to other files, and `resultLabel` in particular is one that ticket
  035 will need from `finished_games.dart` anyway.
- **`_OpponentSection` was extracted, not deleted.** Deliberate, per D277 — Your
  Path replaces it in ticket 032, and deleting it here would leave the main screen
  with a hole for two tickets in the one ticket whose whole discipline is that it
  changes nothing.

## Functional Validation

No Jira issue key is present in the branch name (`main`) or in the commits since
the merge base, and this repository tracks work in `doc/tickets/` rather than Jira.
Validated against `doc/tickets/030-main-screen-decomposition.md` instead: all ten
acceptance criteria pass, the last of them — `tool/check.sh` — green end to end
(`ALL CHECKS PASSED`, exit 0), against a baseline run on the same tree before the
change that was also green.

---

# Ticket 031 — The progression package, and points that accumulate

Reviewed against `6306f5d`. New package `packages/quadrim_progression`, a new
app-side fold, the balance on the rating card, and the build gate taught about
both.

## Summary

| Severity | Count |
|---|---|
| critical | 0 |
| major | 0 |
| minor | 1 |
| nit | 1 |

Two defects were found and fixed during the ticket rather than after it, and
both are recorded below because each was caught by something rather than by
reading.

## Findings

### [MINOR] Two of the ticket's own claims were wrong, and its tests said so — `bug`

**File:** `packages/quadrim_progression/test/points_test.dart:139`

**Evidence:** the test as first written asserted

```dart
final games = List.filled(1000, const ScoredGame(rosterIndex: 0, won: true));
expect(pointsEarned(games), lessThan(unlockCost(5)));   // failed: 1000 vs 64
expect(unlockCost(19) ~/ winValue(17), 4);              // failed: got 8
```

**Problem:** Both were overclaims about the economy, not implementation bugs.
A thousand Pebble wins is 1,000 points and Willow costs **64**, so grinding the
bottom for the *first* rung works fine. And `unlockCost(i)` is four wins against
`i − 1`, so measured against index 17 rather than 18 the ratio is eight.

**Fix:** applied. The test now states the true shape — sixty-four Pebble wins
really does buy Willow, and what the doubling prices out is grinding the bottom
for the *top*, at 1,048,576 games for Quadrim Prime against four from the rung
below. Worth keeping as a finding because idea-v3.md §7.3's sentence "grinding
downward is self-defeating" is true of the ladder as a whole and **not** of its
first rung, and an exhaustive test is what made the difference visible.

### [NIT] A localised value interpolated into a quoted literal trips the gate — `style`

**File:** `app/lib/home/rating_card.dart:56`

**Evidence:** the first version of the points row read

```dart
Text('${l10n.pointsHeading} ', style: theme.textTheme.labelLarge),
```

which `tool/check.sh`'s `Text\(\s*['"][^'"]*[A-Za-z]` matched, failing the
build with `FAIL: hardcoded user-facing string(s)`.

**Problem:** The grep cannot distinguish an interpolated localised value inside
a quoted literal from a hardcoded one — correctly, since both are a quoted
literal containing letters. The trailing space was also a translatable
character sitting outside the `.arb`.

**Fix:** applied. The label is `Text(l10n.pointsHeading)` and the gap is a
`SizedBox(width: 8)`. The comment explaining this had to be reworded too — its
first version quoted the offending pattern and tripped the same grep, which is
a fair demonstration that the check is a text search rather than a parser.

## Not findings, checked and cleared

- **The purity allowance is tight.** `check.sh` now permits exactly one runtime
  dependency, for one package, by name. Verified by injecting `http: ^1.0.0`
  into `packages/quadrim_progression/pubspec.yaml` and confirming the filter
  still reports it (`correctly FAILS on: http: ^1.0.0`), then removing it. An
  allowance that let anything through would be worse than no check.
- **The edge is a direction, not a coupling.** A second gate check greps
  `packages/quadrim_engine/lib` and `packages/quadrim_rating/lib` for
  `package:quadrim_progression` and fails if either imports it. This is what
  keeps spec §7.1 true — the catalogue carries no `locked` field because the
  strength harness has no business holding an entitlement, and an engine that
  imported progression would be the first step back towards exactly that.
- **`pointsEarned` reads no unlock record.** Verified by signature: the whole
  public surface is `winValue(int)`, `unlockCost(int)`, `isFree(BotConfig)`,
  `rosterIndexOf(String)`, `fullRosterCost` and
  `pointsEarned(Iterable<ScoredGame>)`, and `ScoredGame` carries a roster index
  and a bool. Nothing can reach an unlock or a rating from there. That is D270
  carried by the type system rather than by a comment.
- **Pricing keys on the ordinal, not the rating.** Asserted over the whole
  catalogue: prices rise monotonically with the index, which they would not do
  if derived from the rating — the Casual tier's measured strengths run the
  opposite way to its published ratings (idea-v3.md §14).
- **The player seat, not seat zero.** `points_fold_test.dart:74` pins a win from
  seat 1. Reading seat zero would have scored every such game a loss and halved
  the points of anyone playing second — and the seat alternates on rematch
  (§3.1), so that is about half of all games. The rating fold had the same trap
  and the same test.
- **The import prefix collision.** `home_summary.dart` gained a `points` field
  and an import prefixed `points`, which shadowed the field at the one line that
  sets it — caught by `flutter analyze`, not at runtime. Renamed to
  `points_fold`, and the file's existing comment about why `fold` is prefixed
  was extended to say that a prefix may not be a field's name.
- **The gate's exit code.** A run that printed `FAIL:` appeared to exit 0. That
  was the invocation, not the gate: `bash tool/check.sh | tail` reports `tail`'s
  status. Confirmed by re-running with the code captured directly — `EXITCODE=1`
  on the failing tree, `EXITCODE=0` and `ALL CHECKS PASSED` on the fixed one.
  No defect, but worth recording: **anything monitoring this gate should key on
  the `ALL CHECKS PASSED` line**, which only the final statement prints.

## Functional Validation

Validated against `doc/tickets/031-progression-package-and-points.md`. All
fourteen acceptance criteria pass. The package's tests are exhaustive over the
catalogue rather than sampled, as the ticket asks: every roster index is checked
for `winValue`, `unlockCost`, the four-wins equality and `isFree`, and the
round-trip through `rosterIndexOf`. `fullRosterCost` is pinned at 2,097,088 and
separately at sixty wins. `tool/check.sh` is green end to end with a captured
exit code of 0.

---

# Ticket 032 — Unlocks, and Your Path

Reviewed against `6b12b7f`. The unlock record and its store, `UnlockRepository`,
the purchase flow, Your Path, lock state in opponent selection, and the
by-opponent breakdown's removal.

## Summary

| Severity | Count |
|---|---|
| critical | 0 |
| major | 0 |
| minor | 1 |
| nit | 1 |

## Findings

### [MINOR] The rating seed is 1200 in code and 800 in the specification, and no ticket owns the gap — `correctness`

**File:** `packages/quadrim_rating/lib/quadrim_rating.dart:22`

**Evidence:**
```dart
const int kSeedRating = 1200;
```
against spec §7.2 — "from the **800** seed" — and criterion F9 ▲, "A new player
with no history … it is **800**".

**Problem:** D226 moved the computer seed to 800 and the human seed to 1000.
Ticket 027 shipped 1200 before that decision existed, and the ticket breakdown
in D269 did not cut a ticket for the change — so the specification and the code
disagree with nothing scheduled to reconcile them. Found here because Your Path
put Vireo's 1200 rating on the main screen beside the card's seed of 1200 and
made a test finder ambiguous.

**Fix:** not applied — it is outside this ticket, and it is not a one-line
change: D227 records that altering the seed **silently rewrites every existing
rating**, because the rating is a fold with nothing stored. It needs its own
ticket with the rewrite stated. Raised to the user rather than absorbed.

### [NIT] `RatingBar` was deleted rather than left unused — `simplification`

**File:** `app/lib/home/section_widgets.dart:50`

**Evidence:** its only caller was `OpponentSection`, which this ticket removes.
After that, `grep -rn "RatingBar" app/lib` returns nothing.

**Problem:** none, but the deletion is worth recording because spec criterion
U16 still says "Any rating shown as a bar is zero-based against the top of the
catalogue", and after this ticket no rating is shown as a bar at all.

**Fix:** deleted, with the reason in the file's header comment. U16 is
vacuously satisfied rather than violated, and ticket 035 can restore it from
git if the trend work wants a bar back. Three tests that covered only the bar
went with it.

## Not findings, checked and cleared

- **Sequential purchase is enforced where it is written, not only in the UI.**
  `LocalGameRepository.purchase` refuses anything but the lowest-indexed locked
  opponent and refuses a free one, both proven. That matters because the
  repository is the only writer, and "four wins buys the *next* opponent" stops
  being a promise the moment another path can skip ahead (D229).
- **`pricePaid` is what was charged, not what the table says.** The test buys
  Willow at 40 rather than at `unlockCost(5)`, so a re-tune of the table cannot
  make the assertion pass by accident.
- **The record inherits the backup allowlist with no manifest change.** It is
  written under `files/quadrim/unlocks/`, inside the `quadrim/` path the
  allowlist committed in ticket 001 already covers. Reopening the same store
  returns the unlock, which is the closest a unit test gets to a device restore.
- **Double-buy is idempotent at two layers.** The opponent id is the document
  id, so a second write would overwrite rather than duplicate; and `purchase`
  refuses outright before reaching the store. The UI adds a third guard — an
  `_unlocking` flag that nulls the callback while a write is in flight.
- **The Master warning is keyed on configuration, not on two ids.**
  `unlock_confirmation.dart` branches on `bot.usesBook`, so a third book
  opponent could not ship without the sentence spec §6.6 requires.
- **Nineteen existing tests changed, and every change is a consequence of the
  breakdown going.** They asserted counts that assumed opponent names appear
  twice on the main screen. Your Path shows the window around the *next unlock*
  rather than around what has been played, so on a fresh fixture that is
  Bramble, Willow and Vireo and every other opponent appears once. A
  `_inGameRows` finder now scopes the assertions that mean "in the list of
  games", which is stricter than the index-based finders it replaced.
- **Locked rows cannot start a game.** `onTap` is null when locked, so tapping
  one cannot return a `BotConfig` the player has not earned. Existing opponent
  tests pass an all-unlocked set so that a test about tiers or match balance is
  not silently also a test about the ladder.

## Functional Validation

Validated against `doc/tickets/032-unlocks-and-your-path.md`: all twenty-two
acceptance criteria pass. `tool/check.sh` green end to end with a captured exit
code of 0; 259 app tests and 43 progression tests.

---

# Ticket 036 — The computer ladder seeds at 800

Reviewed against `2ec9992`. One constant, its doc comment, and fourteen tests.

## Summary

| Severity | Count |
|---|---|
| critical | 0 |
| major | 0 |
| minor | 0 |
| nit | 0 |

No findings. Recorded anyway, because what this ticket did to the test suite is
the interesting part and is worth being able to find again.

## What the tests said when the seed moved

Fourteen tests failed, **none of them broken**. Each had encoded a fact that was
true at 1200 and is false at 800, which is what a good test does when a premise
moves. Grouped by what they were really asserting:

| What changed | Tests | Why |
|---|---|---|
| Where a new player stands | 6 | The accordion opens at the tier nearest the player. At 800 that is **Novice** — Mote is rated 800 exactly — where it used to be Casual. Four of these tapped a tier heading to open a section that is now already open, and so shut the list they were about to inspect |
| What counts as a fair match | 2 | 1250 used to read "even" to a seeded player; it now reads "above your level", and 900 reads even |
| What a win is worth | 4 | Beating a 600 from 800 pays 8 rather than 1; an even match still pays half of K, but "an even opponent" is now 800 rather than 1200 |
| Whether a zero step is reachable | 1 | From 1200, one win over a 100-rated opponent rounded away. From 800 the same win pays 1 |
| Hard-coded seed literals | 1 | `expect(computerRating(const []), 1200)` |

The zero-step case is the one worth keeping in mind. The UI branches on it — a
step of zero gets no arrow rather than one claiming a movement that did not
happen — so a test that stopped producing zeroes would have quietly rotted that
branch. It is still reachable, and the rewritten test reaches it the way a
player actually does: climb past the twentieth game where K halves, then beat
the weakest opponent on the roster from far above it.

Where a test's *meaning* changed rather than its arithmetic, the new meaning is
stated in the test rather than left to be re-derived — that a seeded player's
fair-match band moved with them is the change working, not a regression.

## Not findings, checked and cleared

- **No migration, and none needed.** `git grep` finds no stored rating anywhere;
  the fold in `rating_fold.dart` is still the only source, and `HomeSummary`
  still derives it per change.
- **Nothing else moved.** K is 32/16 at twenty games, the floor is 100, a draw
  scores one half — all unchanged and all still covered.
- **The human seed was not introduced.** Adding an unused 1000 now would be
  speculative, and spec §7.2 says the human rating is not this fold at all.

## Functional Validation

Six acceptance criteria in `doc/tickets/036-computer-ladder-seeds-at-800.md`,
all passing. Spec criterion F9 ▲ now matches the code. `tool/check.sh` green
with a captured exit code of 0; 259 app tests, 35 rating tests.

---

# Ticket 033 — Quests

> Reviewed: 2026-08-14 · Base: `5402944` on `main` · Working-tree changes
> Scope: the quest work only. Earlier ticket sections above are untouched.

New: `packages/quadrim_progression/lib/src/quests.dart`,
`packages/quadrim_progression/test/quests_test.dart`,
`app/lib/home/quests_section.dart`, `app/test/quests_test.dart`.
Modified: `points.dart`, `quadrim_progression.dart`, `points_test.dart`,
`app/lib/data/points_fold.dart`, `app/lib/home/home_screen.dart`,
`app/lib/game/game_screen.dart`, both `.arb` files,
`app/test/home_screen_test.dart`.

## Summary

| Severity | Count |
|---|---|
| critical | 0 |
| major | 2 |
| minor | 0 |
| nit | 1 |

Both major findings were in code written for this ticket and both are fixed
here; the nit is recorded and left.

---

### [MAJOR] Every game of a qualifying day claimed the same volume quest — `bug`

**File:** `app/lib/game/game_screen.dart:169` (as written before the fix)

**Evidence, as it stood:**

```dart
final without = [
  for (final game in completed)
    if (game.id != widget.gameId) game,
];
_achieved = newlyAchieved(
  points_fold.questsFrom(without, today),
  points_fold.questsFrom(completed, today),
);
```

**Problem:** "Everything except this game" asks *would this quest still stand
without you*, and for a day of exactly five games all five answer no —
removing any one of them drops the day to four. So each of the five, opened
from the history list, announced that it had achieved the five-game rung.

The per-opponent families hid the bug: a first win is achieved by exactly one
game, so removing any other game changes nothing and the wrong question
happens to give the right answer. Only the volume family, where a set of games
earns one quest between them, exposes it.

**Fix applied:** the **prefix ending at this game**, which is the distinction
`computerRatingAround` already makes three functions away and for the same
stated reason. `loadCompletedGames` returns most recent first, so the
chronological prefix is the suffix starting at the game:

```dart
final index = completed.indexWhere((game) => game.id == widget.gameId);
final upTo = index < 0 ? completed : completed.sublist(index);
final before = index < 0 ? completed : completed.sublist(index + 1);
```

Nothing about the points changes — they are folded from the games once, so the
old behaviour over-announced rather than over-paid. What it fixes is a
statement to the player that was not true.

Pinned by `app/test/quests_test.dart`, *only the game that completed a rung
claims it*: the third of five announces nothing, the fifth announces the rung
and its one point.

---

### [MAJOR] The largest-font-scale test was moved onto a viewport taller than any phone — `test-integrity`

**File:** `app/test/home_screen_test.dart:49`

**Evidence:**

```dart
void _phone(WidgetTester tester, {double textScale = 1, double height = 3600}) {
  tester.view.physicalSize = Size(1080, height);
```

**Problem:** the quests section pushed the game rows below the fold, and a
sliver list builds only what fits — eighteen tests began matching nothing
because their rows were unbuilt rather than merely off screen. Raising the
fixture viewport to 1440 dp fixed all eighteen and silently took *is readable
at the largest system font scale* with it. That test exists to apply vertical
pressure at 2× scale (criterion 23); a taller screen is precisely what
relieves it, so the criterion would have stayed asserted and unproven.

**Fix applied:** the height is a parameter, and the font-scale test asks for a
real one:

```dart
_phone(tester, textScale: 2, height: 2400);
```

It passes on the real phone height with the quests section present. The tall
default keeps its justification in a comment naming what it does not prove and
which tickets do (035's six-section test, 021's audit).

---

### [NIT] Quest progress is folded with the wall clock captured at fold time — `style`

**File:** `app/lib/home/home_screen.dart:112`

**Evidence:**

```dart
_quests = closestQuests(
    points_fold.questsFrom(games, (widget.now ?? DateTime.now)()));
```

**Problem:** the fold re-runs when a game finishes, so an app left open across
midnight shows yesterday's day boundary until the next game.

**Not fixed, deliberately.** Nothing 033 implements reads `today` — the volume
family asks for the best day ever and the streak family is ticket 034's. The
parameter exists now so that ticket adds a body rather than a signature. If
034 needs the boundary to move without a game finishing, it owns that.

---

## Checked and clear

- **A quest cannot fire twice or pay differently by when it is claimed.** A
  per-opponent quest's award is `_award(4, quest.rosterIndex)` — a constant of
  the quest, with no game and no history in it. `packages/…/test/quests_test.dart`
  pins the failure D261 records: the four cheapest banked to rung 19 are worth
  15 points, not 4,194,304.
- **The volume family's qualifying games are deterministic.** `_volume` returns
  at the *earliest* day reaching the target and takes that day's first `target`
  games in completion order. Later games — on that day or any other — append
  after them and cannot change the set. Pinned by *a day of a hundred games
  does not price the five-game rung by its best games*.
- **Reversing `scoredGamesFrom` broke no caller.** The two callers are
  `pointsFrom`, a sum, and `questsFrom`, which needs exactly the new order.
  `app/test/points_fold_test.dart:128` already asserted the sum is
  order-independent and still passes.
- **Day bucketing cannot mis-assign across UTC.** `points_fold.dart` converts
  with `completedAt?.toLocal()` before the package sees it, and `_byDay` keys on
  the local `year/month/day`. The package reads no clock and guesses no zone,
  which is the rule it is under; the app is the only thing that knows the
  player's day.
- **The type-level rule holds.** No signature in `quadrim_progression` accepts a
  rating or a rung. `ScoredGame`'s two new fields are **required** rather than
  defaulted, so a forgotten mapping in the app is a compile error and not two
  quest families that silently never fire.

---

# Ticket 034 — Streaks

> Reviewed: 2026-08-14 · Base: `4bc155b` on `main` · Working-tree changes
> Scope: the streak work only.

New: `packages/quadrim_progression/lib/src/streaks.dart`,
`packages/quadrim_progression/test/streaks_test.dart`.
Modified: `quests.dart` (the family is evaluated instead of stubbed),
`quadrim_progression.dart`, `app/lib/data/points_fold.dart`,
`app/lib/home/{home_screen,rating_card}.dart`, both `.arb` files,
`app/test/quests_test.dart`.

## Summary

| Severity | Count |
|---|---|
| critical | 0 |
| major | 0 |
| minor | 1 |
| nit | 0 |

---

### [MINOR] An exported function nothing called — `dead-code`

**File:** `packages/quadrim_progression/lib/src/streaks.dart` (as written, before the fix)

**Evidence, as it stood:**

```dart
StreakRun? firstRunReaching(Iterable<ScoredGame> games, int days) {
  for (final run in streakRuns(games)) {
    if (run.length >= days) return run;
  }
  return null;
}
```

**Problem:** `_streak` in `quests.dart` walks the runs it was already handed
rather than calling this, because calling it would recompute every run once per
rung — eight times over the whole history. So the function was exported,
untested, and would have recomputed the thing its only plausible caller already
had.

**Fix applied:** deleted. `_streak` keeps the inline walk, which is the version
with the right complexity, and the package's surface no longer offers a second
way to ask the same question.

---

## Checked and clear

- **No clock is read in the package.** `currentStreak` and `streakRuns` take
  their boundary as a parameter; `check.sh`'s purity scan passes unchanged.
- **Calendar boundaries.** Day arithmetic goes through an ordinal computed with
  `DateTime.utc(year, month, day)`, which does month ends, year ends and leap
  days without a special case. UTC and not local, deliberately: a local midnight
  that daylight saving deleted would make one day of the year 23 hours long and
  the subtraction wrong. Tests cross a month, a year, 29 February 2028 and its
  absence in 2027.
- **A rung cannot be re-priced.** `_streak` returns at the *earliest* run
  reaching the target, and `qualifyingGames` takes only the first `target`
  calendar days of it. Pinned by *fire exactly once, and stay fired when the
  streak later breaks*: a later twelve-day run of Quadrim Prime games leaves the
  ten-day rung at the 2 points its Pebble days earned.
- **The 48-hour bridge cannot forgive a real miss.** Two games less than 48
  hours apart cannot span a day the player was absent for. A sixty-hour gap
  breaks the streak, and a gap of two calendar days is never bridged whatever
  the clocks say.
- **A backwards clock does not punish the player.** `currentStreak` returns 0
  only when *more* than one day has passed; a "today" earlier than the last game
  leaves the streak standing, because that is a broken device rather than a
  missed day.
- **Pass-and-play and the practice game keep nothing alive.** They never become
  a `ScoredGame` at all, which `points_fold.dart` established in 033 and a
  widget test re-checks through the rating card.

---

# Ticket 035 — The main screen and the end of a game, finished

> Reviewed: 2026-08-15 · Base: `761b490` on `main` · Working-tree changes
> Scope: the 035 work only.

New: `app/lib/home/trend_graph.dart`, `app/lib/home/history_screen.dart`,
`app/test/main_screen_test.dart`.
Modified: `game_row.dart`, `finished_games.dart`, `rating_card.dart`,
`home_screen.dart`, `game_screen.dart`, `rating_fold.dart`, `main.dart`,
`AndroidManifest.xml`, both `.arb` files, `app/test/home_screen_test.dart`.

## Summary

| Severity | Count |
|---|---|
| critical | 0 |
| major | 1 |
| minor | 1 |
| nit | 0 |

Both were in code written for this ticket and both are fixed here.

---

### [MAJOR] A semantics node declared inside an ExcludeSemantics, which says nothing — `accessibility`

**File:** `app/lib/home/trend_graph.dart:57` (as written, before the fix)

**Evidence, as it stood:**

```dart
return Semantics(
  container: true,
  // The line says nothing out loud; the change does. One node, said once.
  label: l10n.trendSemantics(signedDelta(change)),
  child: ExcludeSemantics(
```

**Problem:** `RatingCard` wraps its whole body in an `ExcludeSemantics` and
re-says its facts once in a single label (D192). The graph lands inside that
exclusion, so the node above was swallowed and the trend was announced to
nobody — the element ticket 035 exists to make readable without colour was
the one element on the card a screen reader could not read.

It renders correctly and looks right, which is what makes it worth a finding
rather than a note: the only symptom is a missing announcement.

**Fix applied:** the graph declares nothing and the card's label carries the
change, which is the same signed number drawn beside the line. Recorded as
**D285**, including the general trap — several containers in this codebase
announce themselves and exclude their children, so any new widget landing
inside one must be given a line in the container's label rather than declaring
its own.

Pinned by *says its change out loud, once* in `app/test/main_screen_test.dart`.

---

### [MINOR] The trend window was computed twice, in two places that could drift — `duplication`

**File:** `app/lib/home/trend_graph.dart:37`

**Evidence, as it stood:** `build` sliced the last ten and computed the change
inline; `changeIn`, added so the card could announce the same number, repeated
both the slice and the arithmetic. Two copies of "what the last ten games did"
is exactly the sort of pair that drifts, and it would drift *silently* — the
drawn number and the spoken one would simply stop matching.

**Fix applied:** one `_window` helper and one `changeIn`; `build` calls both.
The doc comment explaining that the change is measured against the point
*before* the window now lives in one place instead of being half-stated twice.

---

## Checked and clear

- **The rating changes are computed in one pass.** `ratingDeltas` walks the
  list once and returns every row's answer; `computerRatingSeries` does the
  same for the graph. `FinishedGameTile` takes a precomputed `delta`, so there
  is no per-row fold to be quadratic. A test builds three hundred games, takes
  every delta in one call, and checks six against the per-game fold.
- **A change that rounds to zero shows no arrow.** `RatingDelta` has carried
  that since ticket 027 and this ticket did not disturb it; the reachable case
  is beating an opponent far below you.
- **Colour is confirmation, never information.** The arrow's direction and the
  number's sign each carry the meaning on the rows; on the graph the number
  does, and the same number is in the card's announcement.
- **The challenge button is its own node.** It sits outside `GameRow` rather
  than inside it, so the row's `ExcludeSemantics` cannot swallow it and tapping
  it cannot also open the game underneath. It is absent where there is nobody
  to challenge — pass and play, an unknown opponent, or a locked one.
- **The offer cannot repeat or fire out of time.** Two clauses, both tested:
  the balance must cross the price *with this game*, and this must be the most
  recent finished game (D286).
- **The relative date counts calendar days, not elapsed hours.** A game
  finished at 23:50 is "yesterday" at 00:10 rather than "today", which is the
  reading that is hardest to argue with.
- **Portrait is pinned in both halves** — manifest and framework — and a test
  asserts the manifest half, which is the one a foldable obeys.

---

# Ticket 037 — Your Path scrolls, and every opponent gets a page

> Reviewed: 2026-08-15 · Base: `e6bc64d` on `main` · Working-tree changes

New: `app/lib/home/opponent_detail.dart`, `app/test/opponent_detail_test.dart`.
Modified: `your_path.dart` (rewritten), `home_screen.dart`, both `.arb` files,
`app/test/{unlocks,home_screen}_test.dart`, and the three v3 documents.

## Summary

| Severity | Count |
|---|---|
| critical | 0 |
| major | 1 |
| minor | 1 |
| nit | 0 |

---

### [MAJOR] The row's height was a guess, and it was wrong twice — `layout`

**File:** `app/lib/home/your_path.dart` (as written, before the fix)

**Evidence, as it stood:**

```dart
return SizedBox(
  // Tall enough for the tallest tile — a locked one, which carries
  // a price, a progress line and a button under the avatar.
  height: tile + 132,
```

**Problem:** a horizontal `ListView` needs a bounded height, so the first
version predicted one. It overflowed by 18 pixels at the largest font scale.
The second attempt scaled the allowance with the text scaler and overflowed by
28 on a different phone. The number could not be right, because the avatar is
sized by the tile width and does not grow with the font while everything under
it does — so the correct height depends on a ratio that changes with both the
screen and the font setting.

**Fix applied:** stop predicting and measure. `SingleChildScrollView` +
`IntrinsicHeight` + a stretched `Row` sizes the row to its tallest tile at
whatever scale it is rendered.

That means building all twenty tiles eagerly, which is worth stating rather
than sliding past: **the roster is exactly twenty and cannot grow without a
code change**, so this is a bounded list — unlike the finished-games list
below it, which has no upper bound and stays lazy. It also removed a whole
class of test friction, since a tile can now be found before it is scrolled to.

Two consequences had to be chased down, and both were real bugs the change
exposed rather than caused:

- **`LayoutBuilder` cannot report intrinsic dimensions.** The tile sized its
  avatar from one, which put a LayoutBuilder inside the intrinsic pass and
  threw. The avatar size is now handed down from the row, which is where the
  width is known anyway.
- **Every rating in the catalogue is now on screen.** Two ticket-027 tests
  looked for a rating with a bare finder and started matching twice — once in
  a game row, once on a tile. They are scoped to the game rows.

---

### [MINOR] The resting rule was nearly added to the pure package — `architecture`

**File:** `app/lib/home/your_path.dart:restingIndex`

**Problem:** `pathWindow` lives in `quadrim_progression` and the obvious move
was to put `restingIndex` beside it. That package's library doc promises **no
function takes the player's rating or their current rung**, and a test asserts
it — the promise is what makes it impossible to price a reward by how high the
player has climbed (D261, D270).

A presentation rule that reads the rating is not a reward, so the invariant
would not have been *violated* in spirit. It would have been violated in fact,
and the test would have had to be weakened to let it through — which is how an
invariant stops being one.

**Fix applied:** `restingIndex` lives in the app, beside `tierNearest`, which
is the app's other rating-to-catalogue question. The doc comment says why, so
the next person to reach for the package finds the reasoning rather than
rediscovering it.

---

## Checked and clear

- **The resting rule is exhaustive, not sampled.** A test walks every rating
  from 500 to 2500 in steps of 25 and checks both halves of the definition:
  the opponent landed on really is rated above the player, and no opponent
  before it is. The boundary cases — below the whole roster, above it, and
  exactly equal to Mote's 800 — are named individually.
- **The row does not snap.** The resting position is recomputed only when the
  rating changes, so a finished game elsewhere on the screen rebuilds the
  section without undoing what the player scrolled to. A test scrolls to
  Quadrim Prime, finishes a game, and checks it is still there.
- **Opponent selection is untouched**, and a test asserts it: tapping a row
  there still starts a game rather than opening the page (D288).
- **The page adds no source of truth.** It is handed the catalogue entry, the
  record from `HomeSummary` and the balance the main screen already folded;
  it reads no repository.
- **One action, never none.** Unlocked it starts a game and pops itself first,
  so returning from the game lands on the main screen. Locked it shows the
  price, the progress and an unlock button reaching the same `runUnlock` the
  other two routes reach — including the Oracle warning, which the page also
  states in its own body so a player deciding whether to spend does not have
  to press Unlock to be told.
- **D262's tests were rewritten, not deleted**, as the ticket required. The
  test that pinned "the middle one is the next unlock" is now the test that
  pins "rests on the first opponent above the player", with a comment naming
  both decisions and the reason the premise changed.

---

# Ticket 035 follow-up — the trend graph's baseline

> Reviewed: 2026-08-15 · Defect found by the owner on the running app.

### [MAJOR] The stated change dropped the first game of the window — `bug`

**File:** `app/lib/home/trend_graph.dart:changeIn` (as shipped in ticket 035)

**Evidence, as it stood:**

```dart
final before = series.length <= kTrendGames
    ? null
    : series[series.length - kTrendGames - 1];
return window.last - (before ?? window.first);
```

**Problem:** `computerRatingSeries` holds the rating **after** each game, so
`window.first` already contains the first game's result. Subtracting it removes
that game from the total. A player with two wins was shown the second one only;
a player with a single win was shown `+0`.

Two distinct cases, one cause:

- **Fewer than ten games** — the baseline should be the seed, 800.
- **Exactly ten games** — `<=` sent it down the same path, because there is no
  eleventh entry to reach back to. `>` is correct.

And above ten games, the baseline was subtracted but never drawn, so the rise
visible on the line disagreed with the printed number by exactly the first game
in the window — the same defect wearing a different hat.

**Fix applied:** `baselineOf` is always a real number (the pre-window rating,
or the seed), `changeIn` measures from it, and `pointsOf` plots it as the
line's first point so the picture and the number agree.

**Why the ticket-035 tests missed it:** they asserted that a signed number was
present and that its sign was right, never its value. The three tests added
here compute the expected figure independently from the series and the seed,
and one asserts that the correct answer and the old incorrect one are different
numbers — so the case cannot pass by accident if the baseline is dropped again.

---

# Ticket 038 — The forest design

> Reviewed against `cca56a1` on `main`. Working tree, 52 files.
> Scope: the design work only. Generated binaries under `app/assets/` were not
> read byte by byte; `art_assets_test.dart` is what checks them.

| Severity | Count |
|---|---|
| critical | 0 |
| major | 2 |
| minor | 2 |
| nit | 1 |

---

## [MAJOR] Text drawn straight onto the background photograph has no guaranteed contrast — `accessibility`

**Files:** `app/lib/design/forest.dart:30`, `app/lib/game/game_screen.dart:479`,
`app/lib/theme.dart:158`, `app/lib/home/home_screen.dart:445`,
`app/lib/game/opponent_screen.dart:115`

**Evidence.** `ForestScaffold` paints the picture and nothing over it:

```dart
return DecoratedBox(
  decoration: const BoxDecoration(
    color: QuadrimPalette.canopy,
    image: DecorationImage(image: AssetImage(Art.background), fit: BoxFit.cover, …),
```

Measured against the shipped `background.webp` (WCAG relative luminance):

| Text | Where | vs background median | vs its brightest fifth |
|---|---|---|---|
| `cream` #F4EFDC | app-bar title, every screen | 3.45 | **1.01** |
| `cream` #F4EFDC | "Show more" | 3.75 | **1.43** |
| `ink` #2A2314 | game-screen turn banner and first-move caption | **2.90** | 11.2 |
| `goldDeep` #6B4E12 | the `Resign` TextButton in the app bar | **2.06** | 7.1 |

The picture is a forest: it has a near-white clearing at the top — exactly
where the app bar sits — and dark trunks lower down. No single ink colour works
over both, so *every* piece of text on it is illegible somewhere. Every other
surface in the design is fine: ink on parchment is 11.44, cream on the panel
11.94, the rating pill 7.47, the trend colours 8.33 and 5.18, the bark button
5.08, and the worst pairing on any card is disabled `inkSoft` on
`parchmentDeep` at 4.79 — all above AA.

The game screen is the worst case and the one that matters most: its turn
banner ("Your turn", "Kestrel is thinking") is a `liveRegion` that a player
reads on every move, and it is ink over trees at 2.90.

**Fix.** Two changes, both in one place each:

1. A scrim in `ForestScaffold`, between the picture and the scaffold, so cream
   on the forest is always legible and nothing has to know where the bright
   part of the photograph is.
2. The game screen's status strip onto parchment, like the result panel below
   it already is; and the app bar's `Resign` button to cream, since
   `textButtonTheme`'s bronze is chosen for parchment and this is the one
   `TextButton` that is not on any.

---

## [MAJOR] `Plaque` still permits the zero-height bug it was written to prevent — `bug`

**File:** `app/lib/design/art.dart:124`

**Evidence:**

```dart
  final VoidCallback? onPressed;
  final double? height;
  final double? width;
…
            child: SizedBox(
              height: height,
              width: width,
              child: Image.asset(asset, fit: BoxFit.contain, …),
```

Both dimensions are optional, and `SizedBox(height: null, width: null)` sizes
to its child — an `Image` that reports zero until it has decoded. A caller who
omits `height` gets a 316×0 button that cannot be tapped, which is the exact
defect this widget's own comment says it exists to prevent, and which cost this
ticket a debugging session.

Today's two call sites both pass `height`, so nothing is broken. The API is
what is wrong: it invites the bug back and the comment above it is the only
guard.

**Fix.** `required this.height` — one word, and the class stops being able to
express the broken state.

---

## [MINOR] Three l10n keys are now rendered nowhere — `dead code`

**File:** `app/lib/l10n/app_en.arb:487`

**Evidence:**

```json
  "settingsTheme": "Theme",
  "themeLight": "Light",
  "themeDark": "Dark",
```

`grep -rn 'settingsTheme\|themeLight\|themeDark' app/lib --include='*.dart'`
returns only generated files under `lib/l10n/`. D293 removed the picker that was
their only caller. They are carried in both `.arb` files and both generated
locale classes, and `check.sh`'s completeness check will keep demanding a Dutch
translation for strings nothing can display.

Precedent: the ticket-034 review deleted `firstRunReaching` for exactly this,
rather than leaving an unused export in place.

**Fix.** Delete the three keys and `@themeLight` from `app_en.arb` and
`app_nl.arb`, then `flutter gen-l10n`. `SettingsDocument.theme` stays — D293
keeps the stored field on purpose, and that is a different thing from a string
nobody renders.

---

## [MINOR] D294 overstates what the lazy sliver did — `documentation`

**File:** `doc/idea-v3-decisions.md:772`

**Evidence:**

> a rating panel taller than the viewport meant Your Path, the quests and the
> game lists were **never built at all**, so the failure did not look like an
> overflow — it looked like four sections vanishing.

That is what the *test* saw, and it is not what a player sees. `SliverList.list`
not building children below the fold is correct lazy behaviour; scrolling builds
them, and criterion U21 ("reaches its last row … with all six sections present")
was satisfiable the whole time by scrolling. What was actually wrong was a
rating panel taller than the whole screen at 200%.

The decision and the fix are both right. The sentence describing the symptom is
not, and this log is the project's memory — a future reader would go looking for
a sliver bug that never existed.

**Fix.** Reword the symptom to what it was: a panel that filled the viewport on
its own, found by a test that could not see past it.

---

## [NIT] Two unused imports in the art pipeline — `dead code`

**File:** `tools/artgen/artgen.py:34`

**Evidence:**

```python
import shutil
import subprocess
```

Neither name appears again in the file; an earlier draft shelled out to `cwebp`
before Pillow turned out to encode WebP directly.

**Fix.** Delete both lines.

---

## Functional validation

No Jira issue key in the branch name or in `git log cca56a1..HEAD` — this
repository tracks work in `doc/tickets/`, so the acceptance criteria of
`doc/tickets/038-the-forest-design.md` are used instead.

| # | Criterion | Status | Evidence |
|---|---|---|---|
| 1 | `bash tool/check.sh` passes | ✅ | `ALL CHECKS PASSED`, 322 app tests |
| 2 | Every screen on the forest; no undesigned surface | ⚠️ | All seven `Scaffold`s are `ForestScaffold` (`grep -c 'return ForestScaffold' lib` = 8), but see the contrast finding — "on the forest" is achieved and legibility is not |
| 3 | Twenty portraits, locked ones as silhouettes | ✅ | `art_assets_test.dart:22`; `art.dart:32` `_silhouette` |
| 4 | Art + fonts under 3 MB | ✅ | `art_assets_test.dart:76`; measured 2.22 MB |
| 5 | Plaques are buttons with a localised accessible name | ✅ | `art.dart:140`; `test/plaques.dart`; `settings_test.dart` taps `plaqueLabelled('Nieuwe partij')` |
| 6 | Your Path's sign is still a semantic heading in both languages | ✅ | `forest.dart:177`; `home_screen_test.dart` asserts `isHeader` on `find.bySemanticsLabel('Your path')` and `findsOneWidget` on `'Jouw pad'` |
| 7 | Main screen survives 200% on the smallest phone | ✅ | `main_screen_test.dart:484`; `rating_card.dart:105` stands the cube down |
| 8 | No string leaves l10n; both locales complete | ✅ | `check.sh` string grep and `untranslated.json` both clean — though see the orphaned-keys finding for the reverse problem |
| 9 | Adaptive launcher icon with a monochrome layer | ✅ | `mipmap-anydpi-v26/ic_launcher.xml`, five densities, `values/ic_launcher_background.xml` |

### Gaps

Criterion 2 is the only one not fully met, and the contrast finding above is
what closes it.

---

## Ticket 038 follow-up — three more contrast bugs, found on the device

The review above measured the palette against the surfaces it *intended*, and
all five findings were real. It still missed three, because it checked which
colours were chosen and not which ones actually arrived. Screenshots of the
running app found them in minutes.

**All three are the same mistake**: a `Text` that passes
`theme.textTheme.something` gets the ink colour meant for parchment, and no
ancestor can override it. `DefaultTextStyle` is consulted only for text that has
no style at all, and a `Theme` override does not help either — the caller
resolved `Theme.of(context)` *above* the widget that would do the overriding, so
the colour is baked into the `TextStyle` before the override exists. Both were
tried; neither worked; the fix is at the call site.

| What | Where | Was | Measured |
|---|---|---|---|
| `1 won · 2 lost · 0 drawn` | `rating_card.dart` inside `DarkPanel` | ink on dark green | 1.04 |
| `1 day in a row` | `rating_card.dart` inside `DarkPanel` | ink on dark green | 1.04 |
| `Layer 1`…`Layer 4` | `board_view.dart`, drawn straight on the forest | ink on the photograph | 2.90 at the top, worse on the lit path where Layer 4 lands |

The layer captions are the worst of the three: Layer 4's sits over the bright
path at the bottom of the picture, and on a screenshot it is not there at all.

**Fixed** by naming `QuadrimPalette.cream` at each of the three call sites, and
`DarkPanel`'s doc comment now says plainly that it cannot rescue a caller who
passes an explicit style — which is every caller it has.

**What this says about the review.** A static pass over a design change can
confirm the palette and cannot confirm the rendering; `flutter analyze` and 322
green tests said nothing about any of these, because a widget test asserts that
text exists, not that it can be seen. Screenshots of the running app are part of
reviewing a design ticket, not a nicety after it.

---

# Ticket 045 — The meter

> Reviewed 2026-08-16 against `main` (working tree, uncommitted).
> Scope: `packages/quadrim_progression/lib/src/meter.dart` (new), its export,
> `packages/quadrim_progression/test/meter_test.dart` (new),
> `app/lib/data/meter_fold.dart` (new), `app/test/meter_fold_test.dart` (new),
> and the changes to `app/lib/data/documents.dart` and
> `app/lib/data/local_game_repository.dart`.
> `bash tool/check.sh`: **ALL CHECKS PASSED** before the review.

| Severity | Count |
|---|---|
| major | 2 |
| minor | 2 |
| nit | 1 |

Both majors are in the eight lines added to `LocalGameRepository.open`, not in
the meter arithmetic. The arithmetic is the part that had tests written against
it; the repository change is the part that looked too small to need any.

## [MAJOR] The first-launch write can stop the app from starting — `bug`

**File:** `app/lib/data/local_game_repository.dart:76`

```dart
if (settings.freeMonthStartedAt == null) {
  settings = settings.copyWith(freeMonthStartedAt: clock());
  await store.writeSettings(settings.toJson());
}
```

**Problem:** `open()` performed no writes before this ticket, and `main.dart:35`
calls it with no `try`/`catch`. `FileDocumentStore.writeSettings` is
`_writeAtomically`, which throws on a full disk, a permission failure or a
read-only volume — so a condition that used to degrade into "settings do not
save" now degrades into "the app does not launch".

**Fix:** Attempt the write, keep the stamp in memory whatever happens. A failed
stamp costs the player nothing — the next launch re-stamps, which restarts the
free month in the player's favour, the direction §4.2's failure rule already
points.

```dart
try {
  await store.writeSettings(settings.toJson());
} on Exception {
  // Not fatal. The month is stamped in memory for this session and the next
  // launch tries again; a disk that cannot be written is not a reason to
  // refuse to start.
}
```

## [MAJOR] The stamp overwrites a settings document written by a newer build — `bug`

**File:** `app/lib/data/local_game_repository.dart:59`

```dart
var settings =
    SettingsDocument.fromJson(await store.readSettings() ?? {}) ??
        const SettingsDocument();
```

**Problem:** `SettingsDocument.fromJson` returns null for **two** different
situations — an absent document, and one whose `schemaVersion` is greater than
this build understands — and this code cannot tell them apart, so it treats
both as "fresh install: stamp and write". Spec §8.7 says a document from a
newer build is *skipped by the reader*, and skipping has until now meant the
file survived on disk until the player deliberately changed a setting. It is
now overwritten with defaults at the next launch, taking the player's locale,
theme and tutorial state with it.

Reachable by installing an older build over a newer one: a TestFlight
downgrade, or a branch switch during development.

**Fix:** Read once, and stamp only when the document was absent or readable —
never when it was rejected for being too new.

```dart
final storedSettings = await store.readSettings();
var settings = SettingsDocument.fromJson(storedSettings ?? {});
final rejectedAsNewer = storedSettings != null && settings == null;
settings ??= const SettingsDocument();
if (settings.freeMonthStartedAt == null && !rejectedAsNewer) { … }
```

## [MINOR] `weekOrdinal` puts two different weeks together before 1970 — `bug`

**File:** `packages/quadrim_progression/lib/src/meter.dart:139`

```dart
int weekOrdinal(Day day) =>
    (day.ordinal + (DateTime.thursday - kWeekStartsOn) % 7) ~/ 7;
```

**Problem:** `~/` truncates toward zero rather than flooring, so the arithmetic
is wrong for negative ordinals. Verified by running it:

```
1969-12-28 weekday=7 (Sun) ordinal=-4 week=0
1969-12-29 weekday=1 (Mon) ordinal=-3 week=0   <- should start a new week
1970-01-01 weekday=4 (Thu) ordinal= 0 week=0
```

Sunday the 28th closes one week and Monday the 29th opens the next; both land
in week 0, so a week straddling the epoch is counted as two weeks' allowance.
Only reachable with a device clock set before 1970 — but it is a date function
that is wrong for some dates, and the same one-line fix removes the question.

**Fix:** Floor rather than truncate.

```dart
int weekOrdinal(Day day) {
  final shifted = day.ordinal + (DateTime.thursday - kWeekStartsOn) % 7;
  return shifted >= 0 ? shifted ~/ 7 : ((shifted + 1) ~/ 7) - 1;
}
```

*(`Day.ordinal` in `streaks.dart:39` has the same truncation and is out of this
diff's scope. Worth its own look — it would mean streak runs joining across the
epoch — but nothing in this ticket made it worse.)*

## [MINOR] A test that fails in the first three minutes of every day — `test-coverage`

**File:** `app/test/meter_fold_test.dart:66`

```dart
final now = DateTime.now();
final games = [
  for (var i = 0; i < 3; i++)
    game(mode: GameMode.vsComputer,
        createdAt: now.toUtc().subtract(Duration(minutes: i + 1))),
];
```

**Problem:** Run between 00:00 and 00:03 local, one or more of the three games
falls on the previous calendar day, `startedToday` is under three and the
`MeterLimit.daily` assertion fails. Every other test in both files injects its
times; this one reaches for the wall clock in a suite whose entire subject is
day boundaries.

**Fix:** Inject `now`, as the sibling tests do.

```dart
final now = DateTime(2026, 8, 12, 15);
… createdAt: now.subtract(Duration(minutes: i + 1)).toUtc()
```

## [NIT] Dead clause in `FreeMonth.covers`, and the test for it proves nothing — `simplification`

**File:** `packages/quadrim_progression/lib/src/meter.dart:97`

```dart
bool covers(DateTime now) => now.isBefore(endsAt) || now.isBefore(startedAt);
```

**Problem:** `endsAt` is always after `startedAt`, so `now.isBefore(startedAt)`
is only evaluated when `now >= endsAt`, at which point it is necessarily false.
The clause can never change the result. The test at `meter_test.dart:171`
("a clock that moved backwards gives the month rather than taking it") passes
through the *first* clause and would pass with the second deleted, so it does
not test what it says it tests — the comment above the method describes
behaviour that is real but is produced by different code than it claims.

**Fix:** Delete the clause and keep the comment, which is still true:
`now.isBefore(endsAt)` already gives a backwards clock the month.

---

## Not findings, checked and cleared

- **Purity.** No clock or random source is read in `meter.dart`; `now` and
  `freeMonth` are parameters throughout, and `check.sh`'s scan passes. The
  local-time `DateTime(...)` constructors in `endsAt` use the ambient zone to
  build an instant from components, which is what "one calendar month later at
  the same wall-clock time" means and is not a clock read.
- **Free-month calendar arithmetic.** `DateTime(year, month + 1, 0).day` is
  correct for all twelve months including the December roll, and clamps 31
  January to 28 or 29 February. Tested at `meter_test.dart:154`.
- **Month, year and leap boundaries in the week arithmetic.** Correct for all
  post-epoch dates, tested at `meter_test.dart:105` and `:112`.
- **A missing or damaged free-month record cannot wall a player out.** Null
  means unmetered in both the package (`meter.dart:170`) and the fold
  (`meter_fold.dart:44`), and there is a test for it.
- **Started, not completed.** `startedGamesFrom` filters on `GameMode` alone
  and reads `createdAt`, so an abandoned or in-progress game counts (F17).

## Resolution

All five fixed in the same ticket, before the commit.

| # | Finding | Outcome |
|---|---|---|
| 1 | First-launch write can stop the app starting | Fixed — the write is attempted and its failure swallowed; the stamp stands in memory |
| 2 | Stamp overwrites a newer settings document | Fixed — `rejectedAsNewer` distinguishes "absent" from "written by a newer build", and only the first is stamped |
| 3 | `weekOrdinal` wrong before 1970 | Fixed — floors instead of truncating |
| 4 | Test flaky in the first three minutes of a day | Fixed — `now` injected, like every sibling test |
| 5 | Dead clause in `covers`, and a test that proved nothing | Fixed — clause deleted; the comment was right about the behaviour and wrong about which line produced it |

Two regression tests were added for the majors, because neither had one and
neither would have been caught by the suite as it stood:
`meter_fold_test.dart` — *"a document from a newer build is left alone, not
stamped"* and *"a store that cannot be written still opens"*.

`bash tool/check.sh`: **ALL CHECKS PASSED**, 334 app tests, 113 progression
tests.

**What this review is worth noting for.** The meter arithmetic — the part that
looked hard, got a decision entry and 18 tests — had one real defect, and it was
unreachable. The eight lines added to `LocalGameRepository.open` — the part that
looked like plumbing — had two, one of which crashes the app on a full disk and
one of which destroys a downgraded player's settings. The tests were written
where the thinking was, not where the risk was.

---

# Ticket 044 — The Casual-tier inversion

> Reviewed 2026-08-16 against `main` (working tree, uncommitted).
> Scope: `packages/quadrim_engine/lib/src/bot.dart`,
> `packages/quadrim_engine/tool/calibrate.dart`,
> `packages/quadrim_engine/test/strategic_bot_test.dart`, the two `.arb` files
> and their generated localisations, and the three documents.
> `bash tool/check.sh`: **ALL CHECKS PASSED**.

| Severity | Count |
|---|---|
| major | 0 |
| minor | 1 |
| nit | 1 |

The functional diff is **two deleted lines** — `aggression: 0.67` from Vireo and
`aggression: 0.30` from Finch. Everything else is the instrument, the tests,
the blurbs and the record.

## [MINOR] `--only` now costs four times what its documentation implies — `efficiency`

**File:** `packages/quadrim_engine/tool/calibrate.dart:135`

```dart
for (final other in opponentCatalogue)
  if (other.tier == subject.tier && other.id != subject.id) other,
```

**Problem:** The header comment still advertises `--only` as the cheap
re-measure — *"one opponent, resettled"* — and it was 5 pairs. For a member of
a five-strong tier it is now 8, and the tool's own docstring for `_pairsFor`
("its neighbours … plus one opponent from each other tier") describes
behaviour the function no longer has. The tuning loop this exists for is now
noticeably slower, and nothing says so.

**Fix:** Update the docstring, which is the part that is now false. The cost
itself is the point of the change — the narrow sample is what hid the cycle —
so it stays.

*Applied: `_pairsFor`'s docstring rewritten to say it plays the subject's whole
tier and why.*

## [NIT] `indexOf` inside a nested loop to answer a question the loop already knows — `simplification`

**File:** `packages/quadrim_engine/tool/calibrate.dart:110`

```dart
final adjacent = opponentCatalogue.indexOf(members[j]) -
        opponentCatalogue.indexOf(members[i]) ==
    1;
```

**Problem:** Two O(n) scans per pair to recover positions that could have been
carried through the loop. Irrelevant at twenty opponents — the duels take
minutes and this takes microseconds — but it reads as if the position were
unavailable, and it is not.

**Fix:** Collect `(index, config)` when building `members`. Left as-is: this is
a measurement tool, the cost is unmeasurable, and the clearer diff at this size
is the one that changes least.

---

## Not findings, checked and cleared

- **Only two behavioural lines changed.** `git diff` over `bot.dart` shows the
  two `aggression` removals and nothing else; every other line in that file is
  comment. Willow, Bramble and Kestrel were already at the 0.5 default and are
  untouched.
- **No rating moved.** D144 holds — the fix is entirely in configurations, and
  the published anchors 1000/1100/1200/1250/1300 are unchanged.
- **No roster index moved**, so every unlock price and win payout is exactly
  what it was. D309 predicted this fix would need a reorder; it did not, so
  there is no migration and no price change (D315).
- **The blunder-rate monotonicity test still passes**, which is what would have
  caught a naive attempt to space the tier by that lever instead.
- **The two stale assertions were replaced, not deleted.**
  `vireo.aggression > 0.5` and `finch.aggression < 0.5` asserted the design
  this ticket removed; the new test asserts the tier's new invariant, so the
  removal cannot be silently undone.
- **Both blurbs were rewritten in both languages** and no longer describe
  behaviour the bots lack. Finch's first draft ended "rarely slips", echoing
  Kestrel's "rarely gives anything away" two rows below it; changed to "plays a
  tidy game".
- **The `--budget 1` caveat is unchanged.** Sable/Corvus is still reported as
  unreadable at 10% budgets, as before this ticket.
