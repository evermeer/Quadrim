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
