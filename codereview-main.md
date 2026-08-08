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

**Problem:** A double-completing move exists in Qubic; the recorded/highlighted line is the lexicographically first. Deterministic and spec-compatible (Idea-final rule 4 speaks of "the completed line", singular), but undocumented.

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
> Changed files: 4 — `packages/quadrim_engine/lib/src/bot.dart`, `packages/quadrim_engine/test/positional_bot_test.dart` (new), `packages/quadrim_engine/test/strategic_bot_test.dart`, `doc/idea-decisions.md`

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
| Basalt exists with the specified configuration | ✅ | `bot.dart:200` — 1400, all four rules, 6% blunder, matching Idea-final §6.4; asserted at `positional_bot_test.dart:90` |
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
> Changed files: 10 — `packages/quadrim_engine/lib/src/search.dart` (new), `.../lib/src/bot.dart`, `.../lib/quadrim_engine.dart`, `.../test/search_test.dart` (new), `.../test/bot_test.dart`, `.../test/strategic_bot_test.dart`, `app/lib/game/game_screen.dart`, `app/test/bot_game_test.dart`, `app/test/result_screen_test.dart`, `doc/idea-decisions.md`

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

None blocking. Two deviations from Idea-final §6.4's *prose*, both deliberate, measured and recorded as D154:

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
