#!/usr/bin/env python3
"""Draws Quadrim's placeholder app icon at every size the Play Store needs.

    python tool/icongen.py

Run by hand, not from tool/check.sh. The other generators in this repo are
checked for staleness on every CI run, but they are Dart and run on the
toolchain CI already installs; this one needs Python and Pillow, and making the
gate depend on them would trade a real check for a new way for CI to fail.
The output is committed, and it changes only when somebody decides the icon
should change.

Ticket 029 asks for a plain icon and says so twice: real art, a real icon and
store graphics are explicit scope in 0.2. This draws what the game is — a 4x4
grid with four in a row — and nothing more.
"""

from pathlib import Path

from PIL import Image, ImageDraw

# Resolved from this file, not from the caller's working directory: every path
# below is fixed relative to the repository, and `cd tool && python icongen.py`
# otherwise died inside Pillow's save with a traceback that named neither the
# missing directory nor the reason.
ROOT = Path(__file__).resolve().parent.parent

# Nocturne tokens, matching app/lib/theme.dart.
BACKGROUND = (22, 24, 38)
DORMANT = (58, 61, 82)
ACCENT = (145, 132, 217)

# Android launcher densities, plus the Play Store listing icon.
ANDROID = {
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192,
}
PLAY_STORE = 512

# Drawn large and downsampled: circles this small alias badly otherwise.
SUPERSAMPLE = 8

# The winning line the icon shows: a diagonal across the 4x4 face.
WINNING_LINE = [(0, 0), (1, 1), (2, 2), (3, 3)]

# Fraction of the icon the grid occupies, leaving margin for launcher masking.
CONTENT = 0.72


def draw(size: int) -> Image.Image:
    big = size * SUPERSAMPLE
    image = Image.new("RGB", (big, big), BACKGROUND)
    canvas = ImageDraw.Draw(image)

    span = big * CONTENT
    origin = (big - span) / 2
    step = span / 4
    radius = step * 0.30

    for row in range(4):
        for col in range(4):
            cx = origin + step * (col + 0.5)
            cy = origin + step * (row + 0.5)
            on_line = (col, row) in WINNING_LINE
            colour = ACCENT if on_line else DORMANT
            # The four on the line are drawn larger as well as brighter, so the
            # icon still reads as "four in a row" in greyscale.
            r = radius * (1.25 if on_line else 1.0)
            canvas.ellipse((cx - r, cy - r, cx + r, cy + r), fill=colour)

    return image.resize((size, size), Image.Resampling.LANCZOS)


def main() -> None:
    res = ROOT / "app/android/app/src/main/res"
    if not res.is_dir():
        raise SystemExit(f"not found: {res}\nis this still the Quadrim repository?")

    for density, size in ANDROID.items():
        path = res / f"mipmap-{density}/ic_launcher.png"
        draw(size).save(path)
        print(f"{path.relative_to(ROOT)}  {size}x{size}")

    listing = ROOT / "doc/design_reference/play-store-icon-512.png"
    draw(PLAY_STORE).save(listing)
    print(f"{listing.relative_to(ROOT)}  {PLAY_STORE}x{PLAY_STORE}")


if __name__ == "__main__":
    main()
