#!/usr/bin/env python3
"""Reads a store's achievement set back and diffs it against the catalogue.

**This is the half that keeps paying.** Creating forty-five achievements is one
afternoon; a wrong id is permanent, because neither store lets an achievement be
renamed or deleted once published (D213, D365). The creation happens once and is
checkable by eye. The drift — a Dutch string edited in the console and not here,
a points value nudged, an id that never matched — is what nobody notices.

    # works today, no credentials: diff an export you saved by hand
    python tools/storegen/store_audit.py --export doc/store/exported.json

    # live (see "The two adapters" below before trusting these)
    python tools/storegen/store_audit.py --google --application-id 1234567890
    python tools/storegen/store_audit.py --apple --app-id 6478123456

Exit code is 1 when anything differs, so this can gate a release.

## The two adapters are the unverified part, and they are deliberately thin

Everything above `fetch_*` is pure and tested in `test_store_audit.py`. The two
network functions are not tested and could not be verified when written:

- **Google** — `games/v1configuration` is alive and documented, and
  `achievementConfigurations.list` is the call. The scope and the exact response
  shape were not exercised against a real project.
- **Apple** — the App Store Connect API has a Game Center section (its
  documentation page resolves where other Apple URLs 404), but the pages render
  client-side and the endpoint list could not be read. The path below is a
  best guess and is the first thing to check if this returns nothing.

So: **run `--export` first.** Paste what the console shows into a JSON file, diff
that, and only then wire the live calls. The diff is the valuable part and it
does not need either API to work.
"""
from __future__ import annotations

import argparse
import io
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
STORE = ROOT / "doc" / "store"

GOOGLE_BASE = "https://www.googleapis.com/games/v1configuration"
APPLE_BASE = "https://api.appstoreconnect.apple.com/v1"


# --------------------------------------------------------------------------
# The catalogue, flattened to what a store can actually be asked about.
# --------------------------------------------------------------------------

def expected(platform: str) -> dict[str, dict[str, object]]:
    """What the store should hold, keyed by the id *that store* uses.

    Keyed by store id rather than by Quadrim key because that is all a store
    knows: the audit's whole job is to answer "is the thing under this id the
    thing we meant", and a store that has never heard of `beat:pebble` cannot be
    asked about it.
    """
    with io.open(STORE / "achievements.json", encoding="utf-8") as f:
        doc = json.load(f)

    field = "gameCenterId" if platform == "apple" else "playGamesId"
    out: dict[str, dict[str, object]] = {}
    for r in doc["achievements"]:
        store_id = r[field]
        if store_id is None:
            continue
        out[store_id] = {
            "key": r["key"],
            "points": r["points"],
            "en_name": r["en"]["name"],
            "nl_name": r["nl"]["name"],
            "en_locked": r["en"]["locked"],
            "nl_locked": r["nl"]["locked"],
        }
    return out


# --------------------------------------------------------------------------
# The diff. Pure, and the only part worth trusting without a live run.
# --------------------------------------------------------------------------

def diff(
    want: dict[str, dict[str, object]],
    got: dict[str, dict[str, object]],
    *,
    compare: list[str] | None = None,
) -> list[str]:
    """Every way the store and the catalogue disagree, worst first.

    Ordered rather than grouped by id: a missing achievement is a different kind
    of problem from a renamed one, and reading forty-five ids to discover that
    one is absent is how a report gets skimmed.

    `compare` narrows the fields checked, because a store that does not return a
    given field should not be reported as disagreeing about it — an audit that
    cries wolf about data it never received is one that gets muted.
    """
    fields = compare or ["points", "en_name", "nl_name", "en_locked", "nl_locked"]
    problems: list[str] = []

    missing = sorted(set(want) - set(got))
    for i in missing:
        problems.append(f"MISSING   {i}  ({want[i]['key']}) is not in the store")

    extra = sorted(set(got) - set(want))
    for i in extra:
        problems.append(
            f"UNKNOWN   {i}  is in the store and not in the catalogue"
        )

    for i in sorted(set(want) & set(got)):
        for f in fields:
            if f not in got[i]:
                continue
            if got[i][f] != want[i][f]:
                problems.append(
                    f"DIFFERS   {i}  {f}:\n"
                    f"             catalogue: {want[i][f]!r}\n"
                    f"             store:     {got[i][f]!r}"
                )
    return problems


def report(platform: str, problems: list[str]) -> int:
    if not problems:
        print(f"{platform}: catalogue and store agree")
        return 0
    print(f"{platform}: {len(problems)} problem(s)\n")
    for p in problems:
        print(f"  {p}")
    print(
        "\nAn id that DIFFERS can be edited in the console. An id that is "
        "MISSING or UNKNOWN usually cannot be fixed by editing:\n"
        "achievements are permanent once published (D213, D365), so check "
        "whether the catalogue is what should change."
    )
    return 1


# --------------------------------------------------------------------------
# Adapters. Unverified — see the module docstring.
# --------------------------------------------------------------------------

def fetch_export(path: str) -> dict[str, dict[str, object]]:
    """A JSON file in the same shape `expected` produces.

    The escape hatch, and the one input that works today. Saving what a console
    shows into this shape is tedious once and beats trusting an unexercised API.
    """
    with io.open(path, encoding="utf-8") as f:
        return json.load(f)


def fetch_google(application_id: str, token: str) -> dict[str, dict[str, object]]:
    """`achievementConfigurations.list`. UNVERIFIED."""
    import urllib.request

    url = f"{GOOGLE_BASE}/applications/{application_id}/achievements?maxResults=200"
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}"})
    with urllib.request.urlopen(req) as r:  # noqa: S310 - fixed https host
        payload = json.load(r)

    out: dict[str, dict[str, object]] = {}
    for item in payload.get("items", []):
        # Play returns per-locale lists; English is the "primary" translation
        # and the rest sit under translations. Shapes not verified against a
        # real project -- if this comes back empty, print `payload` first.
        name = item.get("achievementType")
        del name
        out[item["id"]] = {
            "points": item.get("stepsToUnlock") or item.get("experiencePoints"),
            "en_name": _google_text(item.get("name"), "en-US"),
            "nl_name": _google_text(item.get("name"), "nl-NL"),
            "en_locked": _google_text(item.get("description"), "en-US"),
            "nl_locked": _google_text(item.get("description"), "nl-NL"),
        }
    return out


def _google_text(bundle: dict[str, object] | None, locale: str) -> str | None:
    if not bundle:
        return None
    if bundle.get("primaryLang") == locale:
        return bundle.get("primaryValue")  # type: ignore[return-value]
    for t in bundle.get("translations", []) or []:  # type: ignore[union-attr]
        if t.get("locale") == locale:
            return t.get("value")
    return None


def fetch_apple(app_id: str, token: str) -> dict[str, dict[str, object]]:
    """Game Center achievements for an app. UNVERIFIED — see the docstring."""
    import urllib.request

    url = (f"{APPLE_BASE}/apps/{app_id}/gameCenterDetail"
           f"?include=gameCenterAchievements&limit=200")
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}"})
    with urllib.request.urlopen(req) as r:  # noqa: S310 - fixed https host
        payload = json.load(r)

    out: dict[str, dict[str, object]] = {}
    for item in payload.get("included", []):
        if item.get("type") != "gameCenterAchievements":
            continue
        attrs = item.get("attributes", {})
        out[attrs.get("referenceName") or item["id"]] = {
            "points": attrs.get("points"),
        }
    return out


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--export", help="diff a saved JSON export (no credentials)")
    ap.add_argument("--google", action="store_true")
    ap.add_argument("--apple", action="store_true")
    ap.add_argument("--application-id", help="Play Games application id")
    ap.add_argument("--app-id", help="App Store Connect app id")
    ap.add_argument("--token", help="bearer token for the chosen store")
    ap.add_argument("--platform", choices=["apple", "google"], default="apple",
                    help="which id column to compare an --export against")
    args = ap.parse_args(argv)

    if args.export:
        return report(args.platform,
                      diff(expected(args.platform), fetch_export(args.export)))

    if args.google:
        if not (args.application_id and args.token):
            ap.error("--google needs --application-id and --token")
        want = expected("google")
        if not want:
            print("google: no Play Games ids in the catalogue yet - nothing to "
                  "audit. Fill them in after creating the achievements.")
            return 0
        return report("google", diff(want, fetch_google(args.application_id,
                                                        args.token)))

    if args.apple:
        if not (args.app_id and args.token):
            ap.error("--apple needs --app-id and --token")
        # Only the fields the adapter actually returns, for the reason in `diff`.
        return report("apple", diff(expected("apple"),
                                    fetch_apple(args.app_id, args.token),
                                    compare=["points"]))

    ap.error("choose one of --export, --google, --apple")
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
