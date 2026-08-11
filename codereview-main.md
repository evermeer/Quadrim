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

---

# Code Review: ticket 013 (working tree) → main @ 8e3f06f

> Generated: 2026-08-08
> Base: HEAD (8e3f06f), work uncommitted
> Changed files: 13 — `app/lib/home/home_screen.dart` (new), `app/lib/data/home_summary.dart` (new), `app/lib/game/opponent_name.dart` (new), `app/lib/main.dart`, `app/lib/game/game_screen.dart`, both `.arb` files and their generated output, `app/test/home_screen_test.dart` (new), `app/test/home_summary_test.dart` (new), `app/test/{smoke,game_screen,bot_game}_test.dart`, `doc/idea-decisions.md`

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

**File:** `doc/idea-decisions.md:1071`

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

- **Ticket 026 is half done.** The evaluation rewrite landed; the two Master opponents did not. D167 records why: the fork term changed the chosen move in **0 of 84** positions from real games, so the evaluation is not the lever. Reaching 2300+ needs the strategy-book route, which starts with the Idea-final §14 licensing question — a decision that is the owner's, not the reviewer's.
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

⚠️ No Jira issue key detected — this project tracks work in `doc/tickets/`. Validated against `doc/tickets/026-master-tier.md` and Idea-final §14.

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
> `app/test/home_screen_test.dart` (step count), `doc/idea-decisions.md` (D196–D198).

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
> files (+ generated), `doc/idea-decisions.md` (D199–D201).

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
> `app/test/game_screen_test.dart`, `doc/idea-decisions.md` (D203).

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
> `app/test/review_test.dart` (new), `doc/idea-decisions.md` (D204).

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
> (+ generated), `app/test/home_screen_test.dart`, `doc/idea-decisions.md` (D205).

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
> `doc/idea-decisions.md` (D206).

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
> `doc/idea-decisions.md` (D207).

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
> `CLAUDE.md`, `doc/idea-decisions.md` (D208–D210), the ticket.

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
