#!/usr/bin/env bash
# The one command that gates every commit and every CI run (ticket 001).
# Analyze + test every package, plus the two structural checks the spec
# demands: package purity (9.2) and no hardcoded user-facing strings (9.9).
set -euo pipefail
cd "$(dirname "$0")/.."

# **A silent death is the expensive kind.** `set -e` aborts on any unguarded
# non-zero exit, and when that happens inside a command substitution the script
# stops without reaching whatever it was going to print — CI reported "exit code
# 1" under a section heading three builds running, which reads as a real finding
# and is not one. This names the line instead.
trap 'echo "check.sh: stopped at line $LINENO (exit $?) - read the output above; a bare stop here with nothing above it is an unguarded command rather than a finding" >&2' ERR

fail=0

echo "== purity: pure packages must not depend on Flutter, Firebase, or IO =="
for pkg in packages/quadrim_engine packages/quadrim_rating packages/quadrim_progression; do
  # Runtime dependencies: the section between 'dependencies:' and the next top-level key.
  deps=$(awk '/^dependencies:/{f=1;next} /^[a-z_]+:/{f=0} f' "$pkg/pubspec.yaml" | sed 's/#.*//' | grep -v '^\s*$' || true)
  # The one allowed edge in the repository: progression prices the roster, and
  # the roster's *order* lives in the engine (D263). Allowed by name so that
  # any other dependency still fails, and only in this direction — the reverse
  # check below is what keeps it a direction rather than a coupling.
  if [ "$pkg" = packages/quadrim_progression ]; then
    deps=$(echo "$deps" | grep -vE '^[[:space:]]*(quadrim_engine:|path:[[:space:]]*\.\./quadrim_engine)[[:space:]]*$' || true)
  fi
  if [ -n "$deps" ]; then
    echo "FAIL: $pkg declares runtime dependencies:"; echo "$deps"; fail=1
  fi
  # `package:http` and `games_services` joined the list at ticket 050. The app
  # layer may now talk to Play Games and Game Center; the pure packages may not,
  # and that is the half of the old offline guarantee which is still absolute
  # (D376). F13 and S1 stay reviewable because a network call during computer
  # play would have to be added to the app layer, in a diff, on purpose.
  if grep -rnE "import [\"']dart:(io|html)[\"']|package:(flutter|firebase|http)|games_services" "$pkg/lib" 2>/dev/null; then
    echo "FAIL: $pkg imports a forbidden library (above)"; fail=1
  fi
done

# The edge runs one way only. spec §7.1 says the catalogue carries no `locked`
# field, because the strength harness plays all twenty opponents against each
# other and has no business holding an entitlement. An engine that imported
# progression would be the first step back towards exactly that.
if grep -rn "package:quadrim_progression" packages/quadrim_engine/lib packages/quadrim_rating/lib 2>/dev/null; then
  echo "FAIL: a pure package imports quadrim_progression (above)."
  echo "      Progression depends on the engine, never the reverse (D263)."
  fail=1
fi

echo "== strings: no user-facing literals outside l10n =="
# Text('...') / Text("...") with letters in app code. Generated l10n lives in
# lib/l10n and is excluded. ponytail: grep, not an analyzer plugin — upgrade
# if it ever misses something that mattered.
if grep -rnE "Text\(\s*['\"][^'\"]*[A-Za-z]" app/lib --include='*.dart' | grep -v 'app/lib/l10n/'; then
  echo "FAIL: hardcoded user-facing string(s) above - route them through l10n"; fail=1
fi

echo "== the network permission is declared on purpose =="
# **This check changed shape at ticket 050, and D376 is why.**
#
# From D93 until then it asserted that the shipped bundle could not reach the
# network at all: INTERNET was stripped from the merge with tools:node="remove"
# and the merged release manifest was read to prove it. Play Games Services
# cannot work without the permission, and Android grants it per application
# rather than per screen, so that guarantee could not survive a leaderboard.
#
# **Spec F13 and S1 did survive**, because both are scoped to a game against a
# computer opponent and both are still true: nothing reports a score during a
# game, and the engine still has no network dependency. They are now reviewed
# rather than enforced on Android -- the status iOS has carried since S20/D306.
#
# What is still worth checking is the thing that actually went wrong once. D356
# happened because transport-backend-cct, a telemetry library Play Billing pulls
# in transitively, declared INTERNET and shipped it while a source-manifest grep
# passed. The permission arriving *unnoticed* was the defect; the permission
# existing is now a decision. So this asserts it is declared deliberately, in
# our own manifest, without the removal directive -- which means a diff that
# introduces network use has to touch a line with D376 written next to it.
MAIN=app/android/app/src/main/AndroidManifest.xml

if ! grep -qE 'uses-permission[^>]*android\.permission\.INTERNET' "$MAIN"; then
  echo "FAIL: $MAIN no longer declares INTERNET."
  echo "      Play Games Services needs it (D376). If network use is being"
  echo "      removed again, that is a spec change and this check should go"
  echo "      back to the ban it replaced, not be deleted."
  fail=1
fi

if grep -E 'uses-permission[^>]*android\.permission\.INTERNET' "$MAIN" | grep -q 'tools:node="remove"'; then
  echo "FAIL: $MAIN still strips INTERNET from the merge."
  echo "      That directive and Play Games Services cannot both be right."
  fail=1
fi

echo "== keystore credentials are not in version control =="
# Ticket 015 asks for a check rather than a habit. .gitignore already covers
# these, but a rule is not a check: `git add -f` beats it, and so does a rule
# edited by accident. This asks git what is actually tracked.
tracked=$(git ls-files -- 'key.properties' '**/key.properties' '*.jks' '*.keystore')
if [ -n "$tracked" ]; then
  echo "FAIL: signing material is tracked by git:"; echo "$tracked"
  echo "      Remove it from history, then rotate the upload key through"
  echo "      Play Console - a published key that has ever been public is"
  echo "      not made private again by deleting the file."
  fail=1
fi

echo "== the iOS privacy manifest parses =="
# ITMS-91056, and Apple was right (D364). The manifest is XML, XML forbids `--`
# inside a comment, and a reasoning comment written with a double hyphen made
# the file unparseable. **Nothing about the privacy keys was wrong**, which is
# exactly why the rejection was hard to read: it names the manifest, so the
# manifest's *contents* are where you look.
#
# A file that must parse should be parsed by the gate rather than eyeballed.
# `|| true` on the find for the reason in D363.
MANIFESTS=$(find app/ios -name '*.xcprivacy' 2>/dev/null || true)
if [ -z "$MANIFESTS" ]; then
  echo "FAIL: no *.xcprivacy found under app/ios - iOS builds need one."
  fail=1
elif command -v python3 >/dev/null 2>&1; then
  for m in $MANIFESTS; do
    if ! python3 -c "import plistlib,sys; plistlib.load(open(sys.argv[1],'rb'))" "$m" >/dev/null 2>&1; then
      echo "FAIL: $m is not a valid plist:"
      python3 -c "import plistlib,sys; plistlib.load(open(sys.argv[1],'rb'))" "$m" 2>&1 | tail -1
      fail=1
    fi
  done
else
  # Said out loud rather than skipped quietly, which is the whole lesson of D363.
  echo "   (python3 absent - the privacy manifest was NOT parsed)"
fi

echo "== the store catalogue's diff engine =="
# Ticket 050's audit (tools/storegen/store_audit.py) is what catches a store and
# doc/store/achievements.json drifting apart, and an id typed wrong is permanent
# (D213, D365). Its two network adapters cannot be tested here and are not; the
# diff itself is pure and is, because a report nobody trusts is a report nobody
# reads.
#
# Guarded on python3 like the privacy manifest above, and it says so when it
# skips rather than passing silently -- the whole lesson of D363.
#
# The Dart half of the same seam is app/test/store_catalogue_test.dart, which
# runs in the app suite below and needs no guard.
if command -v python3 >/dev/null 2>&1; then
  if ! (cd tools/storegen && python3 test_store_audit.py); then
    echo "FAIL: the store audit's diff engine is broken (above)"; fail=1
  fi
else
  echo "   (python3 absent - the store audit's tests did NOT run)"
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

# gen-l10n reports untranslated messages and still exits 0, so without this a
# string can ship in English to a Dutch player and nothing objects. The file is
# written by the run above; `[]` or `{}` means every locale is complete.
echo "== every user-facing string exists in both languages =="
if [ -s app/untranslated.json ] && grep -q '"' app/untranslated.json; then
  echo "FAIL: strings missing a Dutch translation:"
  cat app/untranslated.json
  exit 1
fi
for pkg in packages/quadrim_engine packages/quadrim_rating packages/quadrim_progression tools/linegen; do
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
