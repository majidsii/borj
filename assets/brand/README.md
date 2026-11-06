# Borj (برج) — logo kit and usage

Approved by the owner 2026-11-06 (concept "Banna'i").

## The idea

The mark is the word **برج** written in *Banna'i*, the square Kufic brick script laid
into the walls of Iranian buildings. Every stroke is one cell wide and every gap is
one cell, so the name is literally built from bricks: a tower rises brick by brick,
the way a life is built one day at a time. The two dots are the glazed bricks
(turquoise), the rest is fired brick.

## Construction

- One grid cell = one brick. Stroke = 1 cell, gap = 1 cell, no curves, no rotation.
- **Master mark**: 9 × 7 cells (`source/build.py`, `WIDE`).
- **Small-size cut**: 7 × 7 cells with a shorter ب (`SQUARE`); use it at 32 px and below.
- **Latin name**: "Borj" in Vazirmatn ExtraBold (wght 800), the app's own typeface,
  converted to outlines (`source/latin_outline.py`). Cap height 3.5 cells; its baseline
  sits on the bottom of ج. Vazirmatn is under the SIL Open Font License.

## Colours

| Token | HEX | RGB | Use | Contrast |
|---|---|---|---|---|
| Brick | `#A5492C` | 165 73 44 | mark body on light | 5.85:1 on white |
| Glaze | `#1E8783` | 30 135 131 | dots on light | 4.33:1 on white |
| Brick light | `#E59A72` | 229 154 114 | mark body on dark | 7.46:1 on `#1B1C20` |
| Glaze light | `#5CC8C2` | 92 200 194 | dots on dark | 8.51:1 on `#1B1C20` |
| Charcoal | `#1B1C20` | 27 28 32 | Latin name on light, one-colour mark, dark app tile | — |
| Cream | `#F5EFE7` | 245 239 231 | Latin name on dark | 14.9:1 on `#1B1C20` |

Two colours only, and only for a reason: brick for the structure, glaze for the dots.
The one-colour versions (black, white) must always be accepted.

## Files

| File | Use |
|---|---|
| `borj-symbol-{color,black,white,color-on-dark}.svg` | mark on a 256 canvas (avatars, in-app brand island) |
| `borj-symbol-small-*.svg` | same, small-size cut (≤ 32 px) |
| `borj-wordmark-fa-*.svg` | mark cropped tight, for headers |
| `borj-lockup-horizontal-*.svg` | Latin "Borj" + mark (Persian reads from the right) |
| `borj-lockup-stacked-*.svg` | mark over "Borj" |
| `borj-app-icon-light.svg`, `borj-app-icon-dark.svg` | 1024 app icon masters |
| `borj-app-icon-small-light.svg` | app icon for 16–32 px |
| `borj-android-foreground.svg`, `borj-android-monochrome.svg` | Android adaptive and themed icon layers (mark inside the 66 dp safe circle) |
| `png/borj-app-icon-{16…1024}.png`, `png/borj.ico` | rendered icons (16 and 32 use the small cut; the `.ico` currently uses the master at all sizes) |
| `png/borj-lockup-*.png` | 1200 px wide lockups for README and stores |

Regenerate the SVGs with `python3 source/build.py .`. Re-extracting the Latin outlines needs
fonttools: `python -m venv v && v/bin/pip install fonttools && v/bin/python source/extract_latin.py ../fonts/vazirmatn/Vazirmatn-Variable.ttf 800`.
PNGs were rendered with the logo-design skill's `render_png.py` (headless Chrome).

## Rules

- **Clear space**: one cell of the mark on every side (1/9 of the mark's width).
- **Minimum size**: master mark 40 px wide; below that use the small cut (down to 16 px).
  Horizontal lockup at least 120 px wide.
- **Backgrounds**: white or light glass → colour version; charcoal or dark glass →
  `color-on-dark`; photos or busy colour → one-colour white or black on a solid plate.
- **Never**: round the cells, add a gradient or shadow to the mark, recolour the body
  turquoise, rotate or mirror it (mirroring breaks the letters), set the Latin name in
  another typeface, put the mark on glass that sits on glass.
- Trademark clearance has not been checked; do a professional search before registering.
