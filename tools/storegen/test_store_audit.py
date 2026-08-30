#!/usr/bin/env python3
"""Tests for the diff engine, which is the part of the audit worth trusting.

The two network adapters cannot be tested here and are not: they were written
against documentation that could not be fully read, and a test built on the same
guess would only confirm the guess. What *is* tested is everything the report
rests on — that a missing achievement is found, that an extra one is found, that
a changed string is found, and that a field the store never sent is not reported
as a disagreement.

    python tools/storegen/test_store_audit.py
"""
from __future__ import annotations

import sys

from store_audit import diff

WANT = {
    "a.one": {"key": "beat:pebble", "points": 5,
              "en_name": "Pebble defeated", "nl_name": "Pebble verslagen",
              "en_locked": "Win a game against Pebble.",
              "nl_locked": "Win een partij tegen Pebble."},
    "a.two": {"key": "days_in_row:5", "points": 5,
              "en_name": "Five days running", "nl_name": "Vijf dagen op rij",
              "en_locked": "Play on 5 consecutive days.",
              "nl_locked": "Speel 5 dagen achter elkaar."},
}


def same_as(entry: dict[str, object], **changes: object) -> dict[str, object]:
    out = {k: v for k, v in entry.items() if k != "key"}
    out.update(changes)
    return out


def check(name: str, got: bool) -> bool:
    print(f"  {'ok  ' if got else 'FAIL'}  {name}")
    return got


def main() -> int:
    ok = True

    got = {k: same_as(v) for k, v in WANT.items()}
    ok &= check("an exact match reports nothing", diff(WANT, got) == [])

    # The case the audit exists for: an id in the catalogue that the store has
    # never heard of, which usually means it was typed wrong on one side.
    partial = {"a.one": same_as(WANT["a.one"])}
    problems = diff(WANT, partial)
    ok &= check("a missing achievement is reported",
                len(problems) == 1 and problems[0].startswith("MISSING"))
    ok &= check("the missing report names the Quadrim key",
                "days_in_row:5" in problems[0])

    # The mirror image, and the more alarming one: something is live in the
    # store that nothing will ever unlock.
    surplus = {**{k: same_as(v) for k, v in WANT.items()},
               "a.three": {"points": 5, "en_name": "?", "nl_name": "?",
                           "en_locked": "?", "nl_locked": "?"}}
    problems = diff(WANT, surplus)
    ok &= check("an unknown achievement is reported",
                len(problems) == 1 and problems[0].startswith("UNKNOWN"))

    changed = {k: same_as(v) for k, v in WANT.items()}
    changed["a.two"]["nl_name"] = "Vijf dagen achtereen"
    problems = diff(WANT, changed)
    ok &= check("an edited Dutch name is reported",
                len(problems) == 1 and "nl_name" in problems[0])
    ok &= check("the report shows both sides",
                "Vijf dagen op rij" in problems[0]
                and "Vijf dagen achtereen" in problems[0])

    repriced = {k: same_as(v) for k, v in WANT.items()}
    repriced["a.one"]["points"] = 10
    ok &= check("a changed points value is reported",
                len(diff(WANT, repriced)) == 1)

    # A store that returns only some fields must not be reported as disagreeing
    # about the rest -- an audit that cries wolf is one that gets muted.
    sparse = {k: {"points": v["points"]} for k, v in WANT.items()}
    ok &= check("fields the store did not send are not reported",
                diff(WANT, sparse) == [])
    ok &= check("a narrowed comparison still catches its own field",
                len(diff(WANT, {**sparse, "a.one": {"points": 99}},
                         compare=["points"])) == 1)

    # Several at once, because the report is meant to be read in one pass.
    messy = {"a.one": same_as(WANT["a.one"], points=99),
             "a.three": {"points": 1}}
    problems = diff(WANT, messy)
    kinds = [p.split()[0] for p in problems]
    ok &= check("missing, unknown and differing are reported together",
                kinds == ["MISSING", "UNKNOWN", "DIFFERS"])

    print("\nall good" if ok else "\nFAILURES above")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
