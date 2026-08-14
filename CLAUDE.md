# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Quadrim — four in a row in a 4×4×4 cube (the game is publicly known as Qubic). Flutter 3.44.9 / Dart 3.12.2, Android-only for release 0.1. Built ticket by ticket from `doc/tickets/`, driven by a spec (`doc/idea-v1-spec.md`) and a numbered decision log (`doc/idea-v1-decisions.md`). `doc/idea-v2.md` is the brief rewritten to include everything those two settled — the document to hand someone rebuilding this from scratch.

## Commands

`tool/check.sh` is the gate. It is what CI runs, and nothing is committed without it passing.

```bash
bash tool/check.sh
```

On Windows the Bash tool does not have Dart on its PATH — export it first, or the script dies at exit 127 while still printing plausible output:

```bash
export PATH="/c/D/flutter/bin:$PATH" && timeout 2400 bash tool/check.sh
```

Always give long runs a hard `timeout`. A hung suite is indistinguishable from a slow one, and this repo has already lost days to that (D178).

Individual pieces:

```bash
cd packages/quadrim_engine && dart test                      # engine suite (~20s)
cd packages/quadrim_engine && dart test test/search_test.dart # one file
cd packages/quadrim_engine && dart test -n "forcing"          # one test by name
cd app && flutter test && flutter analyze
cd app && flutter gen-l10n                                    # after editing any .arb
```

Regenerators — their output is committed, and `check.sh` fails if it is stale:

```bash
cd tools/linegen && dart run bin/linegen.dart          # winning_lines.g.dart + test corpus
cd packages/quadrim_engine && dart run tool/bookgen.dart  # strategy_book.g.dart
```

Measurement tools (not shipped; `tool/` is outside the purity scan, so these may use a clock):

```bash
cd packages/quadrim_engine && dart run tool/duel.dart onyx onyx+d9 120
cd packages/quadrim_engine && dart run tool/calibrate.dart --games 30
cd packages/quadrim_engine && dart run tool/calibrate.dart --only oracle
```

`duel.dart` is the instrument for one pairing. Every claim that one opponent is stronger than another should come from a run of it, not from an argument about the code. Names take `+dN` (defence depth), `+tN` (own forcing depth), `+bN` (forcing budget, thousands).

`calibrate.dart` is the instrument for the whole ladder: 19 adjacent pairs plus 10 cross-tier braces, budgets at 10%, about 6 minutes on an idle machine (D208). It only ever **reports** — when measurement disagrees with a published rating, the configuration changes and the rating does not (D144). `--only <id>` re-measures one opponent against the settled rest, which is what a tuning pass uses.

## Layout

```
app/                        Flutter app (UI + persistence). The only place Flutter exists.
packages/quadrim_engine/    Rules, search, opponents, strategy book. Pure Dart.
packages/quadrim_rating/    ELO maths. Pure Dart.
tools/linegen/              Build-time generator for the 76 winning lines.
third_party/patashnik/      Vendored strategy dictionary + NOTICE.md.
doc/tickets/                The 7 tickets still open; the unit of work and of commits.
doc/tickets/done/           The 22 finished ones. A ticket moves here once it is
                            committed AND its review section is in codereview-main.md.
doc/idea-v1-decisions.md    D01–D217. Every non-obvious choice, with its cost.
```

## Architecture

**Purity is mechanised, not aspirational.** `quadrim_engine` and `quadrim_rating` may not import Flutter, Firebase, `dart:io`, an ambient clock, or an ambient random source, and may declare no runtime dependencies at all. `check.sh` greps for each. Randomness is injected (`Random(seed)`) so a position and a seed always give the same move — that is what makes the self-play harness and the tests reproducible.

**Everything derives from the move list.** `GameState` holds moves plus win state; `outcome()`, statistics, and the computer rating are folds over what is already stored, never a second copy that can drift (spec §7.2, §9.5).

**Bots are data, not classes** (spec §9.4). One `chooseMove` serves all twenty opponents, parameterised by a `BotConfig` in the catalogue in `bot.dart`. Adding an opponent is a catalogue entry. `BotConfig.rating` is an *anchor* that is fixed — when measurement disagrees, the configuration changes, not the rating (D144).

Move selection order in `chooseMove`: book → forced win → strategic rules → `_safeCandidates` (drop moves that hand the opponent a forced win) → search. The defensive forcing search added at `_safeCandidates` is the largest single strength lever measured in this project, ~300 Elo (D169).

**Search budgets are counted in nodes, never milliseconds** (spec E7). That is what keeps an opponent the same opponent on a fast phone and a slow one, in debug and release. `SearchLimits.exactEmpties` asserts ≤ 16 — above that an exact solve has no horizon and never returns.

**Symmetry.** Qubic has 192 automorphisms. `canonicalise()` returns both the canonical key and the automorphism that produced it, because the strategy book stores moves in canonical orientation and they must be mapped back onto the real board (`CanonicalForm.cellFromCanonical`).

**App layering.** `DocumentStore` (bytes: file or memory) sits under `GameRepository` (rules: completion, validation, ordering). Widget tests must use `MemoryDocumentStore` — `testWidgets` runs in a fake-async zone that never completes real file I/O, so a widget test over `FileDocumentStore` hangs. The repository is stream-based rather than future-based so 0.3a's Firestore implementation can satisfy the same contract without a UI rewrite.

## Hard constraints

These are not style preferences. Several are enforced by `check.sh`; all of them come from the spec or the decision log.

- **No device identifier** may be generated, stored, or transmitted anywhere (D90, spec D2/S2).
- **Computer play makes no network call, in any release** (D93, spec S1/F13).
- **The Android backup allowlist is explicit, never the platform default**, and must exclude Firebase auth material and FCM/Installations state when 0.3a adds them (D72, spec §9.12).
- **"No data leaves the device" must never appear** in any privacy text — backup is enabled, so it is false (D72, ticket 022).
- **`l10n.strategyCredit` must be rendered somewhere in `app/lib`.** Patashnik's dictionary may be used only if credited in the shipped app; `check.sh` greps for it (D174). Ticket 028 (settings screen) inherits this.
- **The dictionary is vendored byte-for-byte and its SHA-256 is verified** on every check run. Never edit `third_party/patashnik/qubic.dictionary`. Only the dictionary was taken — the GPL-2.0 C++ from the same repository is deliberately untouched (D172).
- **No user-facing string outside l10n.** `check.sh` rejects `Text('...')` with letters in `app/lib`.
- **The application id is `nl.evict.quadrim` and is permanent** once published to any track, including closed testing (D213). Nothing has been uploaded yet, so today it is still changeable; the moment a closed test goes out it is not.
- Keystore credentials stay out of version control (ticket 015).

## Working conventions

The standing instruction for this repo:

> Continue implementing the game according to the tickets in `./doc/tickets`. Ask clarifying questions if anything is unclear and add the decisions to `doc/idea-v1-decisions.md`. After each ticket run the skill `code-review-expert`. Commit to `main` after each ticket is completed and reviewed.

- One ticket per commit, subject `Ticket NNN: <what it did>`.
- Every non-obvious choice gets a numbered `D` entry in `doc/idea-v1-decisions.md` recording the question, the decision, and what it costs. Currently at D217.
- Review findings are appended to `codereview-main.md`; earlier ticket sections are never rewritten.
- Comments here carry reasoning, not restatement — they explain why a thing is the way it is, and often cite the D-number. Match that when editing.
- `ponytail:` marks a deliberate simplification and names its ceiling.

## Known open items

- **Two Casual-tier inversions are accepted for 0.1 and owned by the 1.0 roster revision** (D210, D211). Finch plays ~33 points above Kestrel and Kestrel ~50 above Willow. The cause is measured: `aggression` is worth about 78 points and the roster pins its direction — Kestrel "would rather build than block" (the stronger setting) is rated below Willow "shuts your threats down first" (the weaker one). No configuration change closes it, so the fix is a roster change, not a tuning pass. Do not "fix" this by editing a bot config; check it with `calibrate.dart --only kestrel`.
- Calibration puts Oracle at 2323 against a published 2300 — the earlier ~2100 estimate does not survive a measured run. Quadrim Prime measures 2176 from a single readable pair, and it is the opponent the reduced budget hits hardest, so that number is a floor rather than a verdict; re-run `--only quadrim_prime --budget 1` before believing it.
- `canonicalPlies` is 0 on every shipped bot; canonical transposition entries carry an orientation-dependent `bestMove`. Both deferred from the ticket 025 review.
- **`check.sh` fails if the release manifest declares `INTERNET`** (D212). That is how "computer play makes no network call" is enforced — by the permission, not by reading the code. 0.3a's Firebase work will trip it; narrow the check to computer play then rather than deleting it.
- Tickets that need the user's Google account or decisions and cannot be done by an agent: 015, 016, 024, parts of 022.
