# Apple Liquid Glass from the official Sketch kits (2026-11-06 revision)

Owner request (2026-11-06): use Apple's own Sketch files for the glass so it can be reproduced exactly.

## Sources

Downloaded from Apple Design Resources (https://developer.apple.com/design/resources/), which links the
UI kits as Sketch shares. Files kept outside the repository in `~/projects/personal/borj/apple-kits/`.

| Kit | Sketch share | Sketch app | Size | SHA-256 |
|---|---|---|---|---|
| Apple iOS 27 UI Kit | https://www.sketch.com/s/04c24d8b-38fb-4afb-8836-36617e022f02 | 2026.3.1 | 207,834,444 | `839ecf260025264db9000a4ce23ef2804c33c8d62642a6373ed310858ca64171` |
| Apple macOS 27 UI Kit | https://sketch.com/s/57153a31-3379-4737-8ac6-dbfd6525f052 | 2026.3.1 | 115,181,873 | `f5aa2f4f319eae66b5eab0bbc0faacb10ce16656457cff528f9810d57ff1354d` |

Extraction: `python3 tool/extract_apple_glass_usage.py <iOS.sketch> <macOS.sketch> docs/superpowers/references/generated/apple_glass_usage_2026-11.json`
(all shared glass styles with fills, borders, shadows, corners; every layer that uses glass with its page,
path, size and corner radii; iOS 17 styles / 367 usages, macOS 18 styles / 291 usages).

### Relation to the source-locked revision

`2026-08-09-apple-ui-kit-source-manifest.md` locks older files (iOS `5941547…`, macOS `8f83805…`). The new
files have different hashes, but every value of the 20 locked glass recipes
(`generated/apple_liquid_glass_recipe_reference.json`, 5 roles × light/dark × iOS/macOS) is identical in the
new kits: same glass parameters, fills, blend modes, all 9–13 edge shadows, corner smoothing. The only
"differences" are usage-instance geometry recorded next to the old recipes. Adopting the new revision as the
locked source needs the owner's approval (manifest revision rule); nothing in the app has to change for it.

## What Sketch's glass parameters are

A Sketch glass effect is a blur of type 4 on the layer. Its fields:

- `radius` — backdrop blur radius in points (0 = clear lens, no frost).
- `depth` — how far in from the edge the bevel (refraction band) reaches, as a fraction of the shape's
  half-size; 0.8–0.9 for UI glass, 0.3–0.5 for lenses and widgets.
- `distortion` — strength of the refraction in the bevel (how much the background bends).
- `chromaticAberrationMultiplier` — colour fringing at the rim (0 for UI glass, 0.4–0.8 for knob lenses).
- `saturation` — backdrop saturation multiplier (light glass 1.4–2, dark 1–1.2).
- `brightness` — backdrop brightness multiplier (1 everywhere).
- `skipLightingEffects` — true on UI glass: the specular rim comes from the layer's own shadows, not from the
  effect.

Corners use Sketch's smooth corners (`smoothing 0.6`, i.e. continuous/squircle corners). Radius values of
FLT_MAX mean "capsule".

## Style catalogue

Values: blur radius / depth / distortion / saturation / chromatic aberration; then fills (blend) and the
number of edge shadows. All have brightness 1.

### Shared by iOS and macOS

| Style | Glass | Fills | Shadows |
|---|---|---|---|
| Light/Regular - Small (controls, tab bars, toolbars, buttons) | 6 / 0.8 / 0.4 / 2 / 0 | 4 fills (see JSON) | 13 |
| Dark/Regular - Small | 6 / 0.8 / 0.4 / 1 / 0 | black screen + #999999 17% | 12 |
| Light/Regular - Small - Tinted (primary action) | 6 / 0.8 / 0.4 / 1 / 0 | 1 (tint) | 11 |
| Dark/Regular - Small - Tinted | 6 / 0.8 / 0.4 / 1 / 0 | 1 | 11 |
| Light/Regular - Large (alerts, action sheets, pickers) | 30 / 0.9 / 0.3 / 1.4 / 0 | white 70% lighten + #BFBFBF 10% darken | 9 |
| Dark/Regular - Large | 30 / 0.9 / 0.3 / 1.2 / 0 | #1A1A1A 50% + 90% luminosity + lighten | 9 |
| Light/Regular - Medium (sheets, menus, popovers) | iOS 15, macOS 30 / 0.9 / 0.3 / 1.4 / 0 | as Large | 9 |
| Dark/Regular - Medium | 30 / 0.9 / 0.3 / 1.2 / 0 | as Large | 9 |
| Lock Screen Time | 3 / 0.5 / 0.2 / 1.4 / 0 | 2 | 10 |

### iOS only

| Style | Glass | Used by |
|---|---|---|
| Clear | 3 / 0.5 / 0.2 / 1 / 0, capsule | Lock Screen / Control Center style tiles (142×142 r28, 66×66 r34) |
| Light/Dark Dock | 3 / 0.5 / 0.2 / 1 / 0, r36 | iPad dock |
| Light/Dark App Library | 5 / 0.5 / 0.2 / 1.3 / 0, r17 | folders |
| Keyboard Background | light 4 / 0.8 / 0.3, dark 8 / 0.8 / 0.4; r27 (iPhone r 27,27,62,62) | keyboard |
| Widget Glass | 3 / 0.5 / 0.2 / 1 / 0, r27.88 | widgets |

### macOS only

| Style | Glass | Used by |
|---|---|---|
| Light/Dark Menus | 20 / 0.9 / 0.3 / light 0.8, dark 1.2 / 0, r12 | menus, menu bar menus |
| Light/Dark Notification | light 15, dark 10 / 0.9 / 0.1 / 1 / 0, r20 (stacked r22) | notifications |
| Light/Dark Dock | 1 / 0.9 / 0.08 / 1 / 0, r15 | Dock |
| Knobs - Toggle / Clicked | 0 / 0.3 / 0.12 / 1 / 0.4, r50 | pressed switch knob |

### Knob lenses (inline, not shared styles)

The moving thumb of switches, sliders and segmented controls is a clear lens: no blur, shallow bevel,
small distortion, often chromatic aberration.

- iOS Toggles / Segmented Controls knob 59×37: light 0 / 0.4 / 0.075 / ca 0, dark 0 / 0.4 / 0.08 / ca 0.4.
- iOS Slider knob (pressed) 57×38: same as the toggle knob.
- macOS switch knob: 0 / 0.30–0.46 / 0.08–0.15 / ca 0.4, sizes 33×20 … 73×45 by control size.
- macOS slider knob: 0 / 0.4 / 0.04 / ca 0.8, 10×20 … 30×25.

## Component geometry (light mode; dark mirrors it)

### iOS 27

- Tab bar (iPhone): one Regular-Small capsule 62 pt tall + a separate 62×62 glass circle for search. With
  search: 2 tabs 118, 3 tabs 202, 4–5 tabs 276 wide; without search: 202 / 276 / 346. Search selected while
  typing: 330×48 field + 48×48 button. iPad tab bar 44 pt capsule. iPhone Duo: vertical 48 pt bar.
- Toolbar buttons: capsules 44 pt (symbol 44×44, text 67×44, back 80×44, groups 104–180), close 34×34;
  primary action = Regular-Small-Tinted 44×44.
- Buttons: capsules 28 (small), 34 (regular), 46 (large), 50 (extra large).
- Sheets (iPhone): medium detent 386 wide (8 pt inset), Regular-Medium, corner 34; inspector sheet
  Regular-Large, corner 34. iPhone Duo: corner 40 (48 at device corners), small detent is an 80 pt capsule,
  sheet buttons 48×48 capsules.
- Alerts: Regular-Large 300 wide, corner 34. Action sheets 260 wide, corner 34.
- Menus: Regular-Medium, corner 32; edit menu 44 pt capsule (Regular-Small).
- Date picker: Regular-Large, corner 13. Color picker: Regular-Large, corners 32/58.
- Activity view buttons: 36 pt capsules.
- Keyboard accessory toolbar: 48 pt capsules.

### macOS 27

- Toolbar items: capsules 36 pt (XL), 24 pt (small): buttons, segmented controls, search fields.
- Window navigation group: 73×36, corner 100 (capsule).
- Popovers: Regular-Medium 230 wide.
- Menus: Menus style, corner 12.
- Alerts: Regular-Large 300×300, corner 26.
- Notifications: Notification style, corner 20 (stacked 22).
- Dock: Dock style 58 pt tall, corner 15.

## Consequences for Borj

1. Our roles map onto Apple styles: `chrome` → Regular-Small (capsule), `tinted` → Regular-Small-Tinted,
   `panel`/`sheet` → Regular-Medium, `row` → Regular-Small, `clear` → Clear; dialogs → Regular-Large.
2. Sizes to follow: phone tab bar 62 pt capsule (276 wide for 4 tabs) + 62 pt search circle; toolbar
   circles 44; phone sheet 8 pt inset, corner 34; alert corner 34; menus 32 (iOS) / 12 (macOS); macOS toolbar items 36.
3. Segmented thumbs, switch knobs and slider thumbs are clear lenses (blur 0) — the one sanctioned "glass
   on glass" exception in Apple's own kit; our redesign spec's flat-inner rule should allow this lens.
4. The web prototype's CSS kit approximates these values; the Flutter renderer settings are derived from the
   locked recipes already in `lib/app/apple_visual/foundation/apple_liquid_glass_recipe*.dart`.
