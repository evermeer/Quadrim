#!/usr/bin/env python3
"""doc/store/achievements.json -> the two consoles' worth of paste-ready data.

**One source, three outputs.** The catalogue used to live in three places at
once: derived in `achievements.dart`, typed into a markdown table, and typed
again into two web consoles. The JSON is now the hand-authored half and
everything below is generated from it, so a name is edited once.

What this does NOT do is create anything in a store. Google's configuration API
can insert achievements but its image upload is deprecated and errors; Apple's
Game Center endpoints exist but were not verified. `store_audit.py` is the other
half — it reads a store back and diffs it against this same JSON, which is the
check that matters, because an id typed wrong is permanent (D213, D365).

    python tools/storegen/storegen.py            # tables + CSVs
    python tools/storegen/storegen.py --icons    # also the 512x512 store icons

`--icons` lives here rather than in `tools/artgen` on purpose: artgen's contract
is `doc/designs` -> `app/assets` (D290), and a store icon never enters the
bundle. Refreshing one should not mean running the whole art pipeline.
"""
from __future__ import annotations

import csv
import io
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
STORE = ROOT / "doc" / "store"
DESIGNS = ROOT / "doc" / "designs"
GUIDE = ROOT / "doc" / "store-game-services-setup.md"
ICONS = STORE / "icons"

# Both consoles ask for 512x512. The sources are 1254x1254, which is not an
# integer ratio down, so this is a real resample rather than a crop.
ICON_SIZE = 512

# The markers in the setup guide. Only what is between them is generated; the
# prose around them is written by hand and must survive a regeneration.
BEGIN = "<!-- storegen:begin {} -->"
END = "<!-- storegen:end {} -->"


def load() -> dict[str, object]:
    with io.open(STORE / "achievements.json", encoding="utf-8") as f:
        return json.load(f)


def _rows(doc: dict[str, object]) -> list[dict[str, object]]:
    return doc["achievements"]  # type: ignore[return-value]


def table(doc: dict[str, object]) -> str:
    """The at-a-glance table: what to create, in order, with its icon."""
    out = [
        "| # | Quadrim key | Game Center ID | Image | Points | Name (EN) | Name (NL) |",
        "|---|---|---|---|---|---|---|",
    ]
    for n, r in enumerate(_rows(doc), 1):
        out.append(
            f"| {n} | `{r['key']}` | `{r['gameCenterId']}` | `{r['icon']}` | "
            f"{r['points']} | {r['en']['name']} | {r['nl']['name']} |"
        )
    return "\n".join(out)


def descriptions(doc: dict[str, object]) -> str:
    """Play takes one description per language; Game Center takes two."""
    out = [
        "| Quadrim key | Pre-earned (EN) | Earned (EN) | Pre-earned (NL) | Earned (NL) |",
        "|---|---|---|---|---|",
    ]
    for r in _rows(doc):
        out.append(
            f"| `{r['key']}` | {r['en']['locked']} | {r['en']['earned']} | "
            f"{r['nl']['locked']} | {r['nl']['earned']} |"
        )
    return "\n".join(out)


def _splice(text: str, name: str, body: str) -> str:
    """Replaces one marked block, and fails loudly if the markers are gone.

    A generator that silently appends when it cannot find its own markers is how
    a document ends up with two of everything.
    """
    begin, end = BEGIN.format(name), END.format(name)
    i, j = text.find(begin), text.find(end)
    if i < 0 or j < 0:
        raise SystemExit(f"{GUIDE.name}: missing storegen markers for '{name}'")
    return text[: i + len(begin)] + "\n\n" + body + "\n\n" + text[j:]


def guide(doc: dict[str, object]) -> None:
    text = io.open(GUIDE, encoding="utf-8").read()
    text = _splice(text, "table", table(doc))
    text = _splice(text, "descriptions", descriptions(doc))
    io.open(GUIDE, "w", encoding="utf-8", newline="\n").write(text)
    print(f"  {GUIDE.relative_to(ROOT)}")


def csvs(doc: dict[str, object]) -> None:
    """One row per achievement, both languages side by side.

    Neither console imports a CSV — these are a paste source and a tick-list, so
    the column order follows the order the console's form asks for things rather
    than the order the JSON stores them.
    """
    total = sum(r["points"] for r in _rows(doc))

    play = STORE / "play-achievements.csv"
    with io.open(play, "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["quadrim_key", "name_en", "description_en", "name_nl",
                    "description_nl", "xp", "icon", "type", "initial_state"])
        for r in _rows(doc):
            w.writerow([r["key"], r["en"]["name"], r["en"]["locked"],
                        r["nl"]["name"], r["nl"]["locked"], r["points"],
                        r["icon"], "standard", "revealed"])
    print(f"  {play.relative_to(ROOT)}")

    gc = STORE / "gamecenter-achievements.csv"
    with io.open(gc, "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["reference_name", "achievement_id", "points", "hidden",
                    "repeatable", "title_en", "prearned_en", "earned_en",
                    "title_nl", "prearned_nl", "earned_nl", "icon"])
        for r in _rows(doc):
            w.writerow([r["key"], r["gameCenterId"], r["points"], "No", "No",
                        r["en"]["name"], r["en"]["locked"], r["en"]["earned"],
                        r["nl"]["name"], r["nl"]["locked"], r["nl"]["earned"],
                        r["icon"]])
    print(f"  {gc.relative_to(ROOT)}  ({len(_rows(doc))} rows, {total} points)")


def icons(doc: dict[str, object]) -> None:
    try:
        from PIL import Image
    except ImportError:
        raise SystemExit("--icons needs Pillow: python -m pip install pillow")

    ICONS.mkdir(parents=True, exist_ok=True)
    for r in _rows(doc):
        src = DESIGNS / r["icon"]
        if not src.exists():
            raise SystemExit(f"missing source art: {src}")
        im = Image.open(src).convert("RGB")
        # **Square, not circle-cut.** `artgen` masks the avatars to a disc for
        # the app; a store icon must not be, because Game Center renders a
        # rounded square and a pre-cut circle inside one reads as a mistake.
        im = im.resize((ICON_SIZE, ICON_SIZE), Image.LANCZOS)
        out = ICONS / f"{r['key'].replace(':', '_')}.png"
        im.save(out, "PNG", optimize=True)
    print(f"  {ICONS.relative_to(ROOT)}/  ({len(_rows(doc))} icons at "
          f"{ICON_SIZE}x{ICON_SIZE})")


def main(argv: list[str]) -> int:
    doc = load()
    print(f"{len(_rows(doc))} achievements from doc/store/achievements.json")
    guide(doc)
    csvs(doc)
    if "--icons" in argv:
        icons(doc)
    else:
        print("  (skipped icons; pass --icons)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
