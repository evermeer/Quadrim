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
