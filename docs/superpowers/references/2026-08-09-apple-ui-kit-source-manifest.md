# Apple UI Kit Source Manifest — Visual Foundation 2.A

Date: 2026-08-09 (revised 2026-11-06: current revision below)
Status: **SOURCE-LOCKED**
Purpose: identify the exact external Apple UI reference files that define the visual target for `dashboard-shakhsi-v2-integration`.

## Source precedence

For Visual Foundation 2.A, the supplied Apple Sketch references are the visual source of truth.

If any of the following conflict:

1. supplied Apple Sketch reference;
2. existing application styling;
3. an earlier mockup;
4. framework defaults;
5. Material, Fluent, Windows/Linux native conventions;
6. developer/designer preference;

the supplied Apple reference wins unless the user explicitly changes the frozen fidelity contract.

## Current revision (2026-11-06)

Owner approval: 2026-11-06 («آره هر دو رو انجام بده»), recorded in
`docs/superpowers/plans/2026-11-06-adopt-apple-kit-revision.md`. Research:
`docs/superpowers/references/2026-11-06-apple-glass-from-sketch-kits.md`.
Files are kept outside the repository in `~/projects/personal/borj/apple-kits/`.
Generated data keeps the canonical names `Apple iOS 27 UI Kit.sketch` /
`Apple macOS 27 UI Kit.sketch`.

### iOS (current)

- File on disk: `Apple_iOS_27_UI_Kit.sketch` (canonical `Apple iOS 27 UI Kit.sketch`)
- SHA-256: `839ecf260025264db9000a4ce23ef2804c33c8d62642a6373ed310858ca64171`
- Size: 207,834,444 bytes; Sketch 2026.3.1
- Sketch share: https://www.sketch.com/s/04c24d8b-38fb-4afb-8836-36617e022f02
- Structure: 36 pages; 42 shared layer styles; 105 shared text styles; 107 shared swatches.

### macOS (current)

- File on disk: `Apple_macOS_27_UI_Kit.sketch` (canonical `Apple macOS 27 UI Kit.sketch`)
- SHA-256: `f5aa2f4f319eae66b5eab0bbc0faacb10ce16656457cff528f9810d57ff1354d`
- Size: 115,181,873 bytes; Sketch 2026.3.1
- Sketch share: https://sketch.com/s/57153a31-3379-4737-8ac6-dbfd6525f052
- Structure: 38 pages; 285 shared layer styles; 67 shared text styles; 110 shared swatches.

### macOS companion asset bundle (unchanged)

The asset bundle `4bbbb036…` (below) is unchanged. Its zip is no longer on disk, so the
extractor is run with `--reuse-assets-from <previous apple_ui_kit_reference.json>`, which
copies the `macosAssets` section unchanged.

### Impact of the revision (measured 2026-11-06/07)

Re-extraction is deterministic: re-running the extractor on the files above reproduces
`generated/apple_ui_kit_reference.json` and `apple_ui_kit_component_map.md` byte for byte,
and the generated Dart matches its generators. The extractor and generator logic did not
change; only the hash constants did. Every difference below is therefore a change in the kits.

- **Unchanged:** the 20 Liquid Glass recipes, shared layer styles, text styles, materials and
  typography outputs.
- **Pages:** iOS 34 → 36 (`Color Wells and Pickers` becomes `Color Pickers`; new `Layout Guides`,
  `Product Bezels`); macOS 37 → 38 (new `Product Bezels`).
- **Colors:** 4 kit-scaffolding swatches change (`x. Kit/Symbol BG Light|Dark`,
  `x. Kit/Nested Symbol BG Light|Dark`, now 60 % alpha); no system color changes.
- **Metrics, existing values that change:**
  - 160 macOS `Titlebars and Toolbars/…/Segmented Control` symbols (Medium 24 pt and XL 36 pt,
    2–6 items) get narrower by exactly 1 pt per separator (for example 6 items 163 → 158,
    3 items 82 → 80); heights are unchanged. In the new kit the separators are 2 pt wide
    (for example Medium 6 items = 2 + 6×24 + 5×2 + 2 = 158).
  - 4 iOS rows at 71 pt height disappear (`Buttons` 218, `Toggle` 192, `Segmented Controls` 568,
    `Text Fields` 299). These were page-title **text** layers at y = −200 that the generator
    classified by name. The new kit replaces them with a `_Header` symbol instance, so their
    removal fixes an earlier misclassification. No app widget reads metric variants directly,
    so no app size changes.
- **Metrics, new variants:** iOS toolbar `Vertical Group - Symbol 2|3` buttons (48×110, 48×164);
  the iOS `Close Button` (34×34) symbols join the 34×34 button variant after Apple renamed them
  under `Toolbars/…/Buttons/34pt/…` (same IDs and size). No new macOS metric source IDs.
  Outside the metric classes, the component layers grow from 1,623 to 1,976 on iOS (new pages)
  and go from 5,049 to 5,048 on macOS.
- **Metrics, provenance:** toolbar symbols renamed under the same source IDs
  (`Toolbars/Top (44pt)/Dark/Active/Buttons/…` → `Toolbars/Dark/Buttons/44pt/Active/…`,
  `Bottom (48pt)` → `48pt`).

## Previous revision (2026-08-09)

The files below were the source lock from 2026-08-09 until 2026-11-06. They are kept for
history; the current revision above replaces them.

### macOS

File name:

`Apple macOS 27 UI Kit(1).sketch`

SHA-256:

`8f83805217d979dc560d008fce66c1c77014f631cccff8978f31baf1d7ef3b28`

Verified Sketch structure:

- 37 page JSON files;
- 285 shared layer styles;
- 67 shared text styles;
- 110 shared swatches.

Human-readable page/component families include:

- Library Preview
- Colors
- Materials
- Alerts
- Buttons
- Color Wells
- Combo Boxes
- Dialogs
- Disclosure Controls
- Forms
- Group Boxes
- Image Wells
- Menu Bar and Dock
- Menus
- Notifications
- Pointers
- Pop-up and Pull-down Buttons
- Popovers
- Progress Indicators
- Scrollbars
- Search Fields
- Segmented Controls
- Sidebars
- Sliders
- Steppers
- Text Fields
- Titlebars and Toolbars
- Toggles — Checkboxes
- Toggles — Radio Buttons
- Toggles — Switches
- Tooltips
- Windows
- Change Log
- Kit

### iOS

File name:

`Apple iOS 27 UI Kit.sketch`

SHA-256:

`5941547509b49a3756667905f18492dfdf4e59a977de1deacccfcf7ff94ac295`

Verified Sketch structure:

- 34 page JSON files;
- 42 shared layer styles;
- 105 shared text styles;
- 107 shared swatches.

Human-readable page/component families include:

- Library Preview
- Colors
- Materials
- Text Styles and Dynamic Type
- System
- Activity Views
- Action Sheets
- Alerts
- Buttons
- Color Wells and Pickers
- Date and Time Pickers
- Empty States
- FaceID
- Keyboards
- Lists
- Menus
- Page Controls
- Popovers
- Progress Indicators
- Segmented Controls
- Sheets
- Sidebars
- Sliders
- Steppers
- Tab Bars
- Text Fields
- Toggles
- Toolbars
- Change Log
- Kit

### macOS companion asset bundle

File name:

`apple-macos-27-ui-kit_assets_2026-06-23_v12(1).zip`

SHA-256:

`4bbbb036ce008f2213803ad05d7591ed4c0ac009f677a2e1d3d3b315ceb1ce31`

Verified bundle:

- 23 files total;
- `Library Preview.png`;
- pointer SVG references for default, grabbing/open/pointing hand, move, text cursor,
  zoom, directional resizing, cross and beachball states.

## Availability rule

The binary Sketch/asset files are external visual references and are not silently replaced by screenshots, memory, generic Apple documentation, framework samples or hand-tuned guesses.

A future assistant/session that cannot access the exact source files may:

- read this manifest;
- read the frozen contract and canonical design;
- continue documentation/governance work that does not require new visual measurements.

It must **not** invent missing visual values.

Before extracting new component values or claiming pixel/source fidelity, the exact source files above must be available and their SHA-256 values must match this manifest, or the user must explicitly approve a replacement source revision.

## Revision rule

A newer Apple kit does not automatically replace these files.

Changing any source file or source hash is a design-contract change and requires:

1. explicit user approval;
2. manifest update;
3. impact review against existing extracted tokens/components;
4. Roadmap/spec update before implementation continues.

## Generated reference outputs

Gate A deterministically derives repository-safe metadata/reference data from the
source-locked binaries without copying the Sketch binaries or font binaries into
the repository:

- `docs/superpowers/references/generated/apple_ui_kit_reference.json`
- `docs/superpowers/references/generated/apple_ui_kit_component_map.md`
- extractor: `tool/apple_ui_kit_reference_extractor.py`
- verifier: `tool/verify_visual_foundation_2a_sources.py`

The generated JSON is not an authority independent of the Sketch sources. Its
source hashes must match this manifest on every regeneration.

The supplied Sketch archives contain font references/PostScript names but no
embedded `.ttf`, `.otf`, `.woff`, or `.woff2` binaries. Therefore cross-platform
exact typography packaging remains an explicit fidelity blocker until resolved;
a substitute font must not be silently treated as exact.

## Current exactness blocker

Gate A extraction is green, but exact runtime typography and symbol rendering
for Android/Windows/Linux remain blocked. Read:

`docs/superpowers/references/2026-08-09-apple-typography-symbol-fidelity-blocker.md`

This blocker must be resolved by valid exact runtime assets/rights or by an
explicit user-approved change to the frozen fidelity contract. It must not be
silently replaced by approximate fonts or icons.
