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
