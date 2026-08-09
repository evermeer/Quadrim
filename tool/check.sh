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

echo "== the strategy dictionary's attribution is still in the app =="
# Its terms permit use only "as long as its source is credited", and it is the
# built app that reaches people. A grep, because the alternative is trusting
# that nobody deletes a line (D174).
if ! grep -rq 'l10n\.strategyCredit' app/lib --include='*.dart'; then
  echo "FAIL: nothing in app/lib renders l10n.strategyCredit."
  echo "      Patashnik's dictionary may only be used if its source is"
  echo "      credited in the shipped app - see third_party/patashnik/NOTICE.md"
  fail=1
fi

[ $fail -ne 0 ] && exit 1

echo "== generated sources are not stale =="
(cd tools/linegen && dart pub get >/dev/null 2>&1 && dart run bin/linegen.dart >/dev/null)
if ! git diff --exit-code -- \
    packages/quadrim_engine/lib/src/winning_lines.g.dart \
    packages/quadrim_engine/test/fixtures/corpus.json; then
  echo "FAIL: generated files are stale - commit the output of tools/linegen"
  exit 1
fi

# Regenerating the strategy book also verifies the vendored dictionary's
# SHA-256, which is how "its moves are unchanged" stops being a promise and
# starts being a check (third_party/patashnik/NOTICE.md).
echo "== the strategy book matches the dictionary it came from =="
(cd packages/quadrim_engine && dart pub get --offline >/dev/null 2>&1 || dart pub get >/dev/null
 dart run tool/bookgen.dart >/dev/null)
if ! git diff --exit-code -- packages/quadrim_engine/lib/src/strategy_book.g.dart; then
  echo "FAIL: the strategy book is stale - commit the output of tool/bookgen.dart"
  exit 1
fi

echo "== analyze + test =="
(cd app && flutter gen-l10n && flutter analyze && flutter test)
for pkg in packages/quadrim_engine packages/quadrim_rating tools/linegen; do
  echo "-- $pkg"
  (cd "$pkg" && dart pub get --offline >/dev/null 2>&1 || dart pub get >/dev/null
   dart analyze --fatal-infos
   if compgen -G 'test/**/*_test.dart' >/dev/null || compgen -G 'test/*_test.dart' >/dev/null; then
     dart test
   else
     echo "(no tests yet)"
   fi)
done

echo "ALL CHECKS PASSED"
