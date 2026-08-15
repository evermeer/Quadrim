#!/usr/bin/env python3
"""Turns the source art in `doc/designs/` into the assets the app ships.

Run by hand when the art changes, never by CI (D290):

    python -m pip install pillow fonttools brotli
    python tools/artgen/artgen.py

Its output is committed, like linegen's and bookgen's. Unlike theirs it is
**not** staleness-checked by `tool/check.sh`, because an image re-encoded by a
different Pillow build is a different file byte-for-byte while being the same
picture, and a check that fails on a library upgrade teaches people to ignore
checks. What is checked is that every roster id has a file, which is the
failure that would actually reach a player (see `art_assets_test.dart`).

The three things it does that are not just resizing:

* **Avatars are cut to a circle.** The source is a 1254x1254 opaque square with
  the character inscribed in a disc; thirteen have white corners and seven have
  black. Masking the disc discards both, so twenty files that were authored two
  different ways become one uniform set, and the locked silhouette can then be
  a runtime colour filter over the alpha rather than a second set of files.
* **The cube's edges are faded.** It is a full-bleed forest scene and it has to
  sit inside the rating panel without a seam, so alpha falls off over the outer
  third.
* **Every sign's background is flood-filled away from the border.** They were
  delivered three different ways — real alpha, flat black, and a *painted*
  transparency checkerboard — and a threshold would eat the dark outlines or
  the tutorial board's cream pages. Only what touches the edge is background.
* **The logo's black is knocked out.** It is gold drawn over opaque black,
  which is exactly a premultiply, so alpha comes from luminance and the colour
  is divided back out. Thresholding alone would leave a dark fringe on every
  edge, and the mark is mostly edge.
"""

from __future__ import annotations

import sys
import tempfile
import urllib.request
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "doc" / "designs"
ART = ROOT / "app" / "assets" / "art"
FONTS = ROOT / "app" / "assets" / "fonts"
ANDROID_RES = ROOT / "app" / "android" / "app" / "src" / "main" / "res"

# The mockup's panel green, behind the launcher icon (Design-alt0.png).
ICON_BACKGROUND = (28, 50, 32)

# Source filename -> bot id. Two of the twenty were delivered misspelt and the
# id is what the catalogue says, so the mapping lives here rather than in a
# rename nobody would find later.
OPPONENTS = {
    "peble": "pebble",
    "twig": "twig",
    "mote": "mote",
    "clover": "clover",
    "bramble": "bramble",
    "willow": "willow",
    "vireo": "vireo",
    "finch": "finch",
    "kestrel": "kestrel",
    "marlin": "marlin",
    "ember": "ember",
    "basalt": "basalt",
    "onyx": "onyx",
    "sable": "sable",
    "corvus": "corvus",
    "lyra": "lyra",
    "quarts": "quartz",
    "titan": "titan",
    "oracle": "oracle",
    "quadrim_prime": "quadrim_prime",
}

# Every avatar is drawn at this size. The largest the app draws one is 200dp on
# the opponent page, so 512 covers a 2.5x phone exactly and a 3x one within a
# hair. Twenty of them is the single biggest line in the asset budget, which is
# why it is not simply 1024.
AVATAR_PX = 512

FONT_SOURCES = {
    # Display: the mockup's flared all-caps serif. Body: its text serif.
    "Cinzel": ("cinzel", "Cinzel%5Bwght%5D.ttf", [(400, "Regular"), (700, "Bold")]),
    "EBGaramond": (
        "ebgaramond",
        "EBGaramond%5Bwght%5D.ttf",
        [(400, "Regular"), (600, "SemiBold")],
    ),
}

# Latin-1 plus the punctuation the UI actually uses: the middot in "900 - Novice",
# the multiplication sign in "4x4x4", en/em dashes, curly quotes, the minus sign
# a negative trend prints. Subsetting is what keeps EB Garamond, which ships
# 851KB of Cyrillic and Greek nobody here can read, under a tenth of that.
SUBSET_UNICODES = "U+0000-00FF,U+0131,U+0152-0153,U+2000-206F,U+2074,U+20AC,U+2122,U+2212,U+2215"


def _load(name: str) -> Image.Image:
    return Image.open(SRC / f"{name}.png")


def _save(im: Image.Image, rel: str, quality: int) -> None:
    out = ART / rel
    out.parent.mkdir(parents=True, exist_ok=True)
    im.save(out, "WEBP", quality=quality, method=6)
    print(f"  {rel:38s} {im.width}x{im.height}  {out.stat().st_size / 1024:7.1f} KB")


def _radial_alpha(size: int, solid: float, edge: float) -> np.ndarray:
    """1.0 inside `solid` of the radius, falling to 0.0 at `edge`, smoothstepped."""
    y, x = np.mgrid[0:size, 0:size]
    centre = (size - 1) / 2
    r = np.sqrt((y - centre) ** 2 + (x - centre) ** 2) / centre
    t = np.clip((edge - r) / (edge - solid), 0.0, 1.0)
    return t * t * (3 - 2 * t)


def _to_rgba(im: Image.Image, alpha: np.ndarray) -> Image.Image:
    rgb = np.array(im.convert("RGB"))
    a = (np.clip(alpha, 0, 1) * 255).round().astype(np.uint8)
    return Image.fromarray(np.dstack([rgb, a]), "RGBA")


def opponents() -> None:
    print("avatars")
    for source, bot in OPPONENTS.items():
        im = _load(source)
        size = im.width
        # The disc is inscribed and antialiases out to the edge, so the mask
        # holds to 0.985 of the half-width and feathers over the last 1.5%.
        alpha = _radial_alpha(size, 0.970, 0.995)
        cut = _to_rgba(im, alpha).resize((AVATAR_PX, AVATAR_PX), Image.LANCZOS)
        _save(cut, f"opponents/{bot}.webp", 84)


def cube() -> None:
    print("cube")
    im = _load("cube")
    # Fades from two-thirds out. The panel behind it is a flat dark green, so
    # the eye only needs the corners gone, not the whole frame.
    faded = _to_rgba(im, _radial_alpha(im.width, 0.60, 1.02))
    _save(faded.resize((512, 512), Image.LANCZOS), "cube.webp", 86)


def logo() -> Image.Image:
    print("logo")
    rgb = np.array(_load("logo").convert("RGB")).astype(np.float32)
    lum = rgb.max(axis=2)
    # Gold over black is a premultiply: recover alpha from luminance, then
    # divide the colour back out so the antialiased rim stays gold rather than
    # fading through brown.
    # Floored before it is scaled: the source is a JPEG-ish black with
    # luminance wandering up to 12, and `lum / 40` would turn all of that into
    # a 5% gold haze over the whole square rather than a mark on nothing.
    alpha = np.clip((lum - 8.0) / 32.0, 0.0, 1.0)
    with np.errstate(divide="ignore", invalid="ignore"):
        straight = np.where(alpha[..., None] > 0, rgb / alpha[..., None], 0)
    out = Image.fromarray(
        np.dstack(
            [
                np.clip(straight, 0, 255).astype(np.uint8),
                (alpha * 255).round().astype(np.uint8),
            ]
        ),
        "RGBA",
    )
    # Trimmed to the mark, and square: the app draws it in a square box, and a
    # bounding box that came out slightly oblong would stretch it there.
    box = out.getbbox()
    if box is not None:
        side = max(box[2] - box[0], box[3] - box[1])
        cx, cy = (box[0] + box[2]) / 2, (box[1] + box[3]) / 2
        out = out.crop((round(cx - side / 2), round(cy - side / 2),
                        round(cx + side / 2), round(cy + side / 2)))
    _save(out.resize((512, 512), Image.LANCZOS), "logo.webp", 90)
    return out


def background() -> None:
    print("background")
    im = _load("background").convert("RGB")
    # A 1080x2400 phone at 2.5x is 432x960 logical. The picture is a soft,
    # out-of-focus forest, so it is stretched rather than kept at native size
    # and it costs nothing to look at.
    _save(im.resize((1080, 1620), Image.LANCZOS), "background.webp", 76)


def _knockout(im: Image.Image) -> Image.Image:
    """Removes the background the art was delivered on, whatever it is.

    The four signs arrived three different ways: one with a real alpha channel,
    one on flat black, and two on a *painted* light-grey transparency
    checkerboard — a picture of transparency rather than the thing itself. All
    three become the same RGBA here.

    **A flood fill from the border, not a threshold.** Every one of these signs
    has dark outlines, and the tutorial board has cream book pages; a rule that
    said "black is background" would eat the outlines and one that said "light
    and unsaturated is background" would eat the pages. Only what is connected
    to the edge of the canvas is background, which is what the eye means by it.
    """
    from scipy import ndimage

    rgb = np.array(im.convert("RGB"))
    if im.mode == "RGBA":
        existing = np.array(im)[..., 3]
        if existing.min() < 250:
            # Delivered with real alpha; snap the body to opaque and keep it.
            return Image.fromarray(
                np.dstack([rgb, np.where(existing >= 250, 255, existing)]), "RGBA"
            )

    high = rgb.max(axis=2).astype(int)
    low = rgb.min(axis=2).astype(int)
    candidate = (high < 26) | ((high > 232) & ((high - low) < 14))
    labels, _ = ndimage.label(candidate)
    edge = set(labels[0, :]) | set(labels[-1, :]) | set(labels[:, 0]) | set(labels[:, -1])
    edge.discard(0)
    background = np.isin(labels, list(edge))

    # Feathered by one pixel of blur so the cut edge is not a staircase, then
    # pushed back to full opacity inside so the body does not go translucent.
    alpha = Image.fromarray(np.where(background, 0, 255).astype(np.uint8))
    alpha = alpha.filter(ImageFilter.GaussianBlur(1.2))
    a = np.array(alpha).astype(np.float32)
    a = np.clip((a - 40) * (255 / 170), 0, 255).astype(np.uint8)
    return Image.fromarray(np.dstack([rgb, a]), "RGBA")


def signs() -> None:
    """The four wooden signs, blank — the lettering is drawn by the app.

    Delivered without text so it can be localised (D297). What ships is the
    wood; `WoodenSign` puts the words on it in Cinzel at the tilt each board
    was painted at, which is why these files must not be cropped to their own
    bounding box: the app positions text by a fraction of the image, and a crop
    that moved by a few pixels would move every caption with it.
    """
    print("signs")
    for source, name, width in (
        ("new-game-background", "new_game", 1024),
        ("tutorial-background", "tutorial", 768),
        ("title-banner-1", "banner_short", 896),
        ("title-banner-2", "banner_long", 896),
    ):
        im = _knockout(_load(source))
        height = round(im.height * width / im.width)
        _save(im.resize((width, height), Image.LANCZOS), f"{name}.webp", 88)


def launcher_icon(mark: Image.Image) -> None:
    """Adaptive foreground plus a legacy square, from the same mark."""
    print("launcher icon")
    # Adaptive icons crop to a circle inscribed in the middle two-thirds, so the
    # mark occupies 62% of the canvas and the rest is breathing room the
    # launcher may or may not eat.
    densities = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
    for density, legacy_px in densities.items():
        out = ANDROID_RES / f"mipmap-{density}"
        out.mkdir(parents=True, exist_ok=True)

        adaptive_px = round(legacy_px * 108 / 48)
        inner = round(adaptive_px * 0.62)
        foreground = Image.new("RGBA", (adaptive_px, adaptive_px), (0, 0, 0, 0))
        scaled = mark.resize((inner, inner), Image.LANCZOS)
        offset = (adaptive_px - inner) // 2
        foreground.paste(scaled, (offset, offset), scaled)
        foreground.save(out / "ic_launcher_foreground.png")

        legacy = Image.new("RGB", (legacy_px, legacy_px), ICON_BACKGROUND)
        inner = round(legacy_px * 0.70)
        scaled = mark.resize((inner, inner), Image.LANCZOS)
        offset = (legacy_px - inner) // 2
        legacy.paste(scaled, (offset, offset), scaled)
        legacy.save(out / "ic_launcher.png")
        print(f"  mipmap-{density:8s} {legacy_px}px legacy, {adaptive_px}px adaptive")

    values = ANDROID_RES / "values"
    values.mkdir(parents=True, exist_ok=True)
    red, green, blue = ICON_BACKGROUND
    (values / "ic_launcher_background.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        "<resources>\n"
        f'    <color name="ic_launcher_background">#{red:02X}{green:02X}{blue:02X}</color>\n'
        "</resources>\n",
        encoding="utf-8",
    )
    anydpi = ANDROID_RES / "mipmap-anydpi-v26"
    anydpi.mkdir(parents=True, exist_ok=True)
    adaptive = (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background"/>\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
        '    <monochrome android:drawable="@mipmap/ic_launcher_foreground"/>\n'
        "</adaptive-icon>\n"
    )
    (anydpi / "ic_launcher.xml").write_text(adaptive, encoding="utf-8")
    print("  mipmap-anydpi-v26 adaptive-icon + monochrome")


def fonts() -> None:
    """Instances each variable font at the weights used, then subsets it."""
    print("fonts")
    from fontTools import subset
    from fontTools.varLib import instancer
    from fontTools.ttLib import TTFont

    FONTS.mkdir(parents=True, exist_ok=True)
    base = "https://raw.githubusercontent.com/google/fonts/main/ofl"
    with tempfile.TemporaryDirectory() as tmp:
        for family, (directory, filename, weights) in FONT_SOURCES.items():
            source = Path(tmp) / f"{family}.ttf"
            urllib.request.urlretrieve(f"{base}/{directory}/{filename}", source)
            licence = FONTS / f"OFL-{family}.txt"
            urllib.request.urlretrieve(f"{base}/{directory}/OFL.txt", licence)

            for weight, label in weights:
                font = instancer.instantiateVariableFont(TTFont(source), {"wght": weight})
                pinned = Path(tmp) / f"{family}-{label}.ttf"
                font.save(pinned)
                out = FONTS / f"{family}-{label}.ttf"
                subset.main(
                    [
                        str(pinned),
                        f"--unicodes={SUBSET_UNICODES}",
                        "--layout-features=*",
                        f"--output-file={out}",
                    ]
                )
                print(f"  {out.name:28s} {out.stat().st_size / 1024:7.1f} KB")


def main() -> int:
    if not SRC.is_dir():
        print(f"no source art at {SRC}", file=sys.stderr)
        return 1
    ART.mkdir(parents=True, exist_ok=True)
    opponents()
    cube()
    mark = logo()
    background()
    signs()
    launcher_icon(mark)
    fonts()
    total = sum(f.stat().st_size for f in ART.rglob("*")) + sum(
        f.stat().st_size for f in FONTS.rglob("*.ttf")
    )
    print(f"\ntotal shipped art + fonts: {total / 1024 / 1024:.2f} MB")
    return 0


if __name__ == "__main__":
    sys.exit(main())
