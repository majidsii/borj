# Adopt the 2026-11 Apple UI kit revision — plan

Owner approval: 2026-11-06 («آره هر دو رو انجام بده») to lock the new kits as the visual source.
Research: `docs/superpowers/references/2026-11-06-apple-glass-from-sketch-kits.md`.

New source files (outside the repo, `~/projects/personal/borj/apple-kits/`):

- iOS: `Apple_iOS_27_UI_Kit.sketch`, SHA-256 `839ecf260025264db9000a4ce23ef2804c33c8d62642a6373ed310858ca64171`, 207,834,444 bytes, Sketch 2026.3.1
- macOS: `Apple_macOS_27_UI_Kit.sketch`, SHA-256 `f5aa2f4f319eae66b5eab0bbc0faacb10ce16656457cff528f9810d57ff1354d`, 115,181,873 bytes, Sketch 2026.3.1
- The macOS companion asset bundle is unchanged (`4bbbb036…`) but its zip is no longer on disk.

Old: iOS `5941547509b49a3756667905f18492dfdf4e59a977de1deacccfcf7ff94ac295`, macOS
`8f83805217d979dc560d008fce66c1c77014f631cccff8978f31baf1d7ef3b28`.

Pre-measured impact (main session, 2026-11-06): glass recipes, layer styles, text styles, materials and
typography outputs identical; iOS gains 2 pages, macOS 1; 4 kit-scaffolding swatches change
(`x. Kit/Symbol BG …`, `x. Kit/Nested Symbol BG …`); metrics gain new variants (macOS toolbar items 24/36 pt,
iPhone Duo vertical tab bar) and new provenance rows; no existing metric value changes.

## Global Constraints

- Flutter 3.47.5: `/home/shabin/develop/flutter-3.47.5/bin` first on `PATH`.
- Never edit `*.g.dart` by hand: regenerate with the `tool/generate_apple_*` scripts, then `dart format`.
- Canonical file names in generated data stay `Apple iOS 27 UI Kit.sketch` / `Apple macOS 27 UI Kit.sketch`.
- Do not add new `tool/verify_*` scripts (existing ones may get their constants updated).
- Stage explicit paths; never `git add -A`; do not push. Commit message ends with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Report every command run with its real result, and any test or analyzer failure verbatim.

## Task 1 — Regenerate the Apple source chain from the new kits

1. Replace the old iOS/macOS SHA-256 constants with the new ones in `tool/apple_ui_kit_reference_extractor.py`
   (including `_CANONICAL_SOURCE_FILE_NAMES`, keyed by the new hashes, mapping to the canonical names),
   `tool/generate_apple_source_{colors,materials,metrics,reference,typography}.py`,
   `tool/generate_apple_liquid_glass_recipes.py` if it checks hashes, and the existing
   `tool/verify_visual_foundation_2a_*.py` scripts.
2. The macOS asset zip is unavailable: add an extractor option `--reuse-assets-from <existing reference json>`
   that copies the `macosAssets` section unchanged instead of reading the zip (keep `--macos-assets` working).
3. Regenerate `docs/superpowers/references/generated/apple_ui_kit_reference.json` and
   `apple_ui_kit_component_map.md` from the new kits (paths above), then
   `apple_liquid_glass_recipe_reference.json` + `lib/app/apple_visual/generated/apple_source_liquid_glass_recipes.g.dart`,
   and every `lib/app/apple_visual/generated/apple_source_*.g.dart` whose generator reads the reference
   (colors, materials, metrics, reference, typography; motion has its own input and must stay unchanged).
   Update hard-coded expectations inside generators that now fail (e.g. `ios.pageCount 34 → 36`) to the new
   measured values, and report each one you changed.
4. `dart format` the generated Dart. Update tests that pin the hashes
   (`test/app/apple_visual/apple_reference_manifest_test.dart`, `apple_source_reference_mapping_test.dart`) and any
   test that pins counts that legitimately changed; do not loosen assertions.
5. Update `docs/superpowers/references/2026-08-09-apple-ui-kit-source-manifest.md`: a new "Current revision
   (2026-11-06)" section with file names, hashes, sizes, Sketch version, the Sketch share URLs from the research
   doc and the impact summary above; keep the old revision as "Previous revision".
6. `flutter analyze` (must be clean) and the full `flutter test` (report pass/fail counts).
7. Commit: `chore: adopt the 2026-11 Apple UI kit revision as the locked visual source`.
