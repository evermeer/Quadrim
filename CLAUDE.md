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

**The Android build needs `JAVA_TOOL_OPTIONS` on this machine.** Gradle dies at
once with `java.io.IOException: Unable to establish loopback connection`, which
names the wrong layer: TCP loopback is fine, and so is the `afunix` driver. What
fails is an **AF_UNIX `connect` under `%LOCALAPPDATA%\Temp`**, which returns
`Invalid argument` there and succeeds in every other directory tested. The JDK
places every `Selector`'s internal socket pair in that directory, so
`Selector.open()` fails 100% of the time and the Gradle client cannot talk to
the daemon it has just started. Moving only the socket directory fixes it:

```bash
export JAVA_TOOL_OPTIONS='-Djdk.net.unixdomain.tmpdir=C:\Users\EdwinVermeer\.gradle\unixsock'
```

It is set as a user environment variable, so a **new** shell needs no export; a
shell that was already open when it was set does. Both the Gradle client and its
daemon need it, which is why it is `JAVA_TOOL_OPTIONS` and not `GRADLE_OPTS` —
the client reads `GRADLE_OPTS`, the daemon does not.

This is a machine condition rather than a project one: nothing in the repo
caused it and nothing in the repo fixes it, which is why no path is committed
and CI is untouched. The likely culprit is a security filter driver on the temp
path. If AF_UNIX ever works under `%TEMP%` again the variable becomes a no-op.

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

The art pipeline is the exception: its output is committed like theirs, but
`check.sh` does **not** verify it, because the same picture re-encoded by a
different Pillow build is different bytes and a gate that fails on a library
upgrade is a gate people learn to skip (D290). Run it by hand when the source
art in `doc/designs/` changes. `art_assets_test.dart` is what checks the result.

```bash
python -m pip install pillow fonttools brotli
python tools/artgen/artgen.py
```

Measurement tools (not shipped; `tool/` is outside the purity scan, so these may use a clock):

```bash
cd packages/quadrim_engine && dart run tool/duel.dart onyx onyx+d9 120
cd packages/quadrim_engine && dart run tool/calibrate.dart --games 100
cd packages/quadrim_engine && dart run tool/calibrate.dart --only oracle
```

`duel.dart` is the instrument for one pairing. Every claim that one opponent is stronger than another should come from a run of it, not from an argument about the code. Names take `+dN` (defence depth), `+tN` (own forcing depth), `+bN` (forcing budget, thousands).

`calibrate.dart` is the instrument for the whole ladder: **every opponent against the five rungs above it — 140 pairs, budgets at 10%** (D339). A pair plays 50 games, or **200 where neither side searches** (D344): below Lynx the rungs are forty points apart and fifty games leaves 49 points of noise, so a correct ladder reported two or three spurious inversions a run. Those pairs cost microseconds, so the resolution is free. Budget half an hour. It replaced a chain of adjacent pairs plus a few cross-tier braces, which measured each tier well and the joins between them through a single pair, and so let two adjacent opponents that draw with each other be reported 259 points apart. It only ever **reports** — when measurement disagrees with a published rating, the configuration changes and the rating does not (D144). `--only <id>` re-measures one opponent against the same window, five above and five below.

**An opponent's measured rating is the *median* of its per-pair estimates, not the mean** (D341). Each estimate is a partner's published rating plus a measured gap, so it carries that partner's anchor error in full; the mean let one wrong anchor move every rung within five of it, which is how a run once reported Sorrel above three opponents that beat it two-to-one. When a number still looks wrong, read the head-to-head scores and the inversion list — both are computed without the anchors — before believing the estimate column.

**A 10% budget does not blur a Master-tier result — it can invert it.** Measured both ways: Quartz reads +83 against Titan at 10% and **−115** at full budget; Flint reads +95 and **−241**. The tier's strength lives in a handful of expensive positions a game (median move 0 ms, mean ~900 ms, worst ~12 s), and those are exactly what the reduction truncates. **Any 10% result involving a node-budgeted opponent is evidence of nothing** — settle them with `duel.dart`, which never scales, before changing a configuration (D338, D342).

## Layout

```
app/                        Flutter app (UI + persistence). The only place Flutter exists.
packages/quadrim_engine/    Rules, search, opponents, strategy book. Pure Dart.
packages/quadrim_rating/    ELO maths. Pure Dart.
tools/linegen/              Build-time generator for the 76 winning lines.
tools/artgen/               Art and font pipeline: doc/designs/ -> app/assets/ (D290).
doc/designs/                Source art. Large, and what makes artgen re-runnable.
third_party/patashnik/      Vendored strategy dictionary + NOTICE.md.
doc/tickets/                The 7 tickets still open; the unit of work and of commits.
doc/tickets/done/           The 22 finished ones. A ticket moves here once it is
                            committed AND its review section is in codereview-main.md.
doc/idea-v1-decisions.md    D01–D217. Every non-obvious choice, with its cost.
```

## Architecture

**Purity is mechanised, not aspirational.** `quadrim_engine` and `quadrim_rating` may not import Flutter, Firebase, `dart:io`, an ambient clock, or an ambient random source, and may declare no runtime dependencies at all. `check.sh` greps for each. Randomness is injected (`Random(seed)`) so a position and a seed always give the same move — that is what makes the self-play harness and the tests reproducible.

**Everything derives from the move list.** `GameState` holds moves plus win state; `outcome()`, statistics, and the computer rating are folds over what is already stored, never a second copy that can drift (spec §7.2, §9.5).

**Bots are data, not classes** (spec §9.4). One `chooseMove` serves all thirty-one opponents, parameterised by a `BotConfig` in the catalogue in `bot.dart`. Adding an opponent is a catalogue entry. `BotConfig.rating` is an *anchor* that is fixed — when measurement disagrees, the configuration changes, not the rating (D144).

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
- **No user-facing string outside l10n**, and none inside the artwork either. `check.sh` rejects `Text('...')` with letters in `app/lib`; the wooden signs ship blank and the app letters them, so they are localised too (D297). D292's exception is gone.
- **Every image is drawn in a box the layout already knows** — both dimensions, before decode. An `Image` with an unknown dimension reports zero until its bytes arrive, which is a layout that jumps once on first launch and is permanently broken in a widget test. This cost three bugs in one ticket (D295).
- **Nothing but cream sits on the background photograph**, and the photograph is darkened under everything so that cream always works. Ink over the bare picture measured 2.9:1 (D296).
- **The application ids differ by platform, and neither can change now** (D213, D359). Android is `nl.evict.quadrim`,
  which is on Play internal testing; iOS is `nl.evict.quadrim2`, which is the App Store Connect record that exists.
  The two StoreKit product ids follow the **iOS** id on both platforms — `nl.evict.quadrim2.unlock_all` and
  `nl.evict.quadrim2.unlimited` (D365), which is what App Store Connect would accept. `storekit_config_test.dart`
  asserts the prefix. A product id can never be reused after deletion on either store, so these are now fixed too.
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

- **Do not space a tier by which squares an opponent prefers** (D315, D336). Corners-first and centre-first beat each other in a ring, so alternating them up the ladder builds a cycle rather than an order — twice now. D314 removed `aggression` from the Casual tier for the same reason; D336 removed corner ranking from everything between Bramble and Marlin. What orders that stretch is how many of the sixteen seven-line cells it prefers, then `lineBias`, then the blunder rate, all monotone by construction. An inversion among those three is a real defect; check it with `calibrate.dart --only <id>`.
- Calibration puts Oracle at 2323 against a published 2300 — the earlier ~2100 estimate does not survive a measured run. Quadrim Prime measures 2176 from a single readable pair, and it is the opponent the reduced budget hits hardest, so that number is a floor rather than a verdict; re-run `--only quadrim_prime --budget 1` before believing it.
- `canonicalPlies` is 0 on every shipped bot; canonical transposition entries carry an orientation-dependent `bestMove`. Both deferred from the ticket 025 review.
- **`check.sh` fails if the *merged* release manifest declares `INTERNET`** (D212, D356, D357). That is how "computer play makes no network call" is enforced — by the permission, not by reading the code. Two things to know before touching it:
  - **It used to grep `src/main/AndroidManifest.xml`, which is not what determines the shipped permission.** Play Billing pulls in `transport-backend-cct`, a telemetry transport that declares `INTERNET`, and a bundle shipped with it while the check passed. The permission is now stripped from the merge with `tools:node="remove"` in the main manifest — **deleting that directive silently ships the permission**.
  - The merged manifest only exists after `flutter build appbundle --release`, so the check is authoritative when a build is on disk and asserts steps 1 and 2 otherwise. It prints which. Firebase work will trip it; narrow it to computer play then rather than deleting it — but note that narrowing also re-enables the telemetry library, which is not the same trade it was before.
- Tickets that need the user's Google account or decisions and cannot be done by an agent: 015, 016, 024, parts of 022.
