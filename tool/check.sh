#!/usr/bin/env bash
# The one command that gates every commit and every CI run (ticket 001).
# Analyze + test every package, plus the two structural checks the spec
# demands: package purity (9.2) and no hardcoded user-facing strings (9.9).
set -euo pipefail
cd "$(dirname "$0")/.."

fail=0

echo "== purity: pure packages must not depend on Flutter, Firebase, or IO =="
for pkg in packages/quadrim_engine packages/quadrim_rating; do
  # Runtime dependencies: the section between 'dependencies:' and the next top-level key.
  deps=$(awk '/^dependencies:/{f=1;next} /^[a-z_]+:/{f=0} f' "$pkg/pubspec.yaml" | sed 's/#.*//' | grep -v '^\s*$' || true)
  if [ -n "$deps" ]; then
    echo "FAIL: $pkg declares runtime dependencies:"; echo "$deps"; fail=1
  fi
  if grep -rnE "import [\"']dart:(io|html)[\"']|package:flutter|package:firebase" "$pkg/lib" 2>/dev/null; then
    echo "FAIL: $pkg imports a forbidden library (above)"; fail=1
  fi
done

echo "== strings: no user-facing literals outside l10n =="
# Text('...') / Text("...") with letters in app code. Generated l10n lives in
# lib/l10n and is excluded. ponytail: grep, not an analyzer plugin — upgrade
# if it ever misses something that mattered.
if grep -rnE "Text\(\s*['\"][^'\"]*[A-Za-z]" app/lib --include='*.dart' | grep -v 'app/lib/l10n/'; then
  echo "FAIL: hardcoded user-facing string(s) above - route them through l10n"; fail=1
fi

[ $fail -ne 0 ] && exit 1

echo "== analyze + test =="
(cd app && flutter gen-l10n && flutter analyze && flutter test)
for pkg in packages/quadrim_engine packages/quadrim_rating tools/linegen; do
  echo "-- $pkg"
  (cd "$pkg" && dart pub get --offline >/dev/null 2>&1 || dart pub get >/dev/null
   dart analyze --fatal-infos
   if [ -d test ]; then dart test; else echo "(no tests yet)"; fi)
done

echo "ALL CHECKS PASSED"
