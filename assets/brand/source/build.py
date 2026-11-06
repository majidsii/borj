#!/usr/bin/env python3
"""Builds the Borj (برج) logo kit from cell grids. Run: python3 build.py <out_dir>.

The mark is the word برج in Banna'i (square Kufic brick script): every stroke is
one cell wide, every gap one cell, so the word is literally laid in bricks.
Dots are the glazed (turquoise) bricks; the rest is fired brick.
"""
import sys
from pathlib import Path

BRICK = "#A5492C"        # fired brick, light backgrounds
BRICK_LIGHT = "#E59A72"  # fired brick, dark backgrounds
GLAZE = "#1E8783"        # turquoise glaze (dots), light backgrounds
GLAZE_LIGHT = "#5CC8C2"  # turquoise glaze, dark backgrounds
INK = "#1B1C20"          # charcoal (app dark background, one-colour mark)
PAPER = "#FFFFFF"
CREAM = "#F5EFE7"

# (col, row) cells. Rows grow downward. body = brick, dots = glaze.
WIDE = {  # 9 x 7, for lockups
    "body": [(8, 1), (8, 2)] + [(c, 2) for c in range(4, 8)] + [(4, r) for r in range(3, 7)]
            + [(c, 0) for c in range(0, 3)] + [(0, r) for r in range(1, 4)] + [(c, 4) for c in range(0, 3)],
    "dots": [(6, 4), (2, 2)],
    "size": (9, 7),
}
SQUARE = {  # 7 x 7, symbol / app icon / small sizes
    "body": [(6, 1), (6, 2)] + [(c, 2) for c in range(4, 6)] + [(4, r) for r in range(3, 7)]
            + [(c, 0) for c in range(0, 3)] + [(0, r) for r in range(1, 4)] + [(c, 4) for c in range(0, 3)],
    "dots": [(6, 4), (2, 2)],
    "size": (7, 7),
}
# Latin "Borj": Vazirmatn ExtraBold outlines (the app's own typeface).
from latin_outline import ADVANCE, CAP, PATH as LATIN_PATH  # noqa: E402


def merge_rows(cells):
    """Merge horizontally adjacent cells into runs: [(col, row, length)]."""
    runs, s = [], sorted(set(cells), key=lambda p: (p[1], p[0]))
    for c, r in s:
        if runs and runs[-1][1] == r and runs[-1][0] + runs[-1][2] == c:
            runs[-1] = (runs[-1][0], r, runs[-1][2] + 1)
        else:
            runs.append((c, r, 1))
    return runs


def path(cells, u, ox=0, oy=0):
    d = []
    for c, r, n in merge_rows(cells):
        x, y = ox + c * u, oy + r * u
        d.append(f"M{x:g} {y:g}h{n * u:g}v{u:g}h{-n * u:g}z")
    return "".join(d)


def svg(view_w, view_h, body, title, w=None, h=None):
    w = w or view_w
    h = h or view_h
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {view_w:g} {view_h:g}" width="{w:g}" height="{h:g}" '
            f'role="img" aria-labelledby="title"><title id="title">{title}</title>{body}</svg>\n')


def mark_group(m, u, ox, oy, body_fill, dot_fill):
    return (f'<path fill="{body_fill}" d="{path(m["body"], u, ox, oy)}"/>'
            f'<path fill="{dot_fill}" d="{path(m["dots"], u, ox, oy)}"/>')


LATIN_CAP_CELLS = 3.5  # cap height in mark cells; the mark stays the hero


def latin_group(u, ox, oy, fill, _dot_fill=None):
    """Latin name with cap height LATIN_CAP_CELLS * u, top of caps at oy. Returns (svg, width)."""
    s = LATIN_CAP_CELLS * u / CAP
    return (f'<path fill="{fill}" transform="translate({ox:g} {oy:g}) scale({s:.6g})" d="{LATIN_PATH}"/>',
            ADVANCE * s)


def build(out: Path):
    out.mkdir(parents=True, exist_ok=True)
    files = {}
    # Symbol = the word mark (9 x 7 cells of 24 = 216 x 168) centred on a 256 canvas.
    u, m = 32, 16
    su = 24
    for name, b, d in (("color", BRICK, GLAZE), ("black", INK, INK), ("white", PAPER, PAPER),
                       ("color-on-dark", BRICK_LIGHT, GLAZE_LIGHT)):
        files[f"borj-symbol-{name}.svg"] = svg(256, 256, mark_group(WIDE, su, 20, 44, b, d), "Borj symbol")
        # Small-size cut (<= 32 px): square 7 x 7 grid, shorter ب.
        files[f"borj-symbol-small-{name}.svg"] = svg(256, 256, mark_group(SQUARE, u, m, m, b, d), "Borj symbol (small sizes)")
        # Tight word mark for lockups and headers.
        files[f"borj-wordmark-fa-{name}.svg"] = svg(9 * u + 2 * m, 256, mark_group(WIDE, u, m, m, b, d), "برج")
    # Horizontal lockup: Latin Borj (left) + mark (right; Persian reads from the right).
    # Latin baseline = bottom of ج (row 4); cap height LATIN_CAP_CELLS cells.
    for name, b, d, lat in (("color", BRICK, GLAZE, INK), ("black", INK, INK, INK), ("white", PAPER, PAPER, PAPER),
                            ("color-on-dark", BRICK_LIGHT, GLAZE_LIGHT, CREAM)):
        lat_g, lat_w = latin_group(u, m, m + (5 - LATIN_CAP_CELLS) * u, lat, d)  # baseline = bottom of ج
        mx = m + lat_w + 2 * u
        w = mx + 9 * u + m
        files[f"borj-lockup-horizontal-{name}.svg"] = svg(w, 256, lat_g + mark_group(WIDE, u, mx, m, b, d), "Borj برج")
        sw = max(9 * u, lat_w) + 2 * m
        sh = m + 7 * u + u + round(LATIN_CAP_CELLS * 1.3 * u) + m  # 1.3 = room for the j descender
        lat_g2, _ = latin_group(u, (sw - lat_w) / 2, m + 8 * u, lat, d)
        files[f"borj-lockup-stacked-{name}.svg"] = svg(sw, sh, mark_group(WIDE, u, (sw - 9 * u) / 2, m, b, d) + lat_g2, "برج Borj")
    # App icons (1024 masters): rounded tile + symbol at 62% width.
    t = 1024
    iu = round(t * 0.64 / 9)
    off = (t - 9 * iu) / 2
    offy = (t - 7 * iu) / 2
    rx = 0.2237 * t
    files["borj-app-icon-light.svg"] = svg(t, t, (
        '<defs><linearGradient id="g" x1="0" y1="0" x2="0.4" y2="1"><stop offset="0" stop-color="#FFFFFF"/>'
        '<stop offset="1" stop-color="#ECEEF2"/></linearGradient></defs>'
        f'<rect width="{t}" height="{t}" rx="{rx:g}" fill="url(#g)"/>' + mark_group(WIDE, iu, off, offy, BRICK, GLAZE)),
        "Borj app icon")
    files["borj-app-icon-dark.svg"] = svg(t, t, (
        '<defs><radialGradient id="w" cx="0.85" cy="0.1" r="0.75"><stop offset="0" stop-color="#FFB36B" stop-opacity="0.38"/>'
        '<stop offset="1" stop-color="#FFB36B" stop-opacity="0"/></radialGradient></defs>'
        f'<rect width="{t}" height="{t}" rx="{rx:g}" fill="{INK}"/><rect width="{t}" height="{t}" rx="{rx:g}" fill="url(#w)"/>'
        + mark_group(WIDE, iu, off, offy, BRICK_LIGHT, GLAZE_LIGHT)), "Borj app icon (dark)")
    # Small app icon (<= 32 px): square cut fills more of the tile.
    su2 = round(t * 0.70 / 7)
    so = (t - 7 * su2) / 2
    files["borj-app-icon-small-light.svg"] = svg(t, t, (
        f'<rect width="{t}" height="{t}" rx="{rx:g}" fill="#F4F5F7"/>' + mark_group(SQUARE, su2, so, so, BRICK, GLAZE)),
        "Borj app icon (small sizes)")
    # Android adaptive foreground: symbol inside the 66% safe zone of a 108dp canvas (432 px master).
    a = 432
    au = round(a * 0.46 / 9)  # mark diagonal stays inside the 66dp safe circle
    aoff = (a - 9 * au) / 2
    aoffy = (a - 7 * au) / 2
    files["borj-android-foreground.svg"] = svg(a, a, mark_group(WIDE, au, aoff, aoffy, BRICK, GLAZE), "Borj adaptive icon foreground")
    files["borj-android-monochrome.svg"] = svg(a, a, mark_group(WIDE, au, aoff, aoffy, INK, INK), "Borj themed icon")
    for k, v in files.items():
        (out / k).write_text(v, encoding="utf-8")
    return sorted(files)


if __name__ == "__main__":
    for f in build(Path(sys.argv[1] if len(sys.argv) > 1 else ".")):
        print(f)
