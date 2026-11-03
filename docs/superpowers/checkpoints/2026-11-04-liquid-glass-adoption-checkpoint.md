# Liquid Glass Adoption — Checkpoint

**Date:** 2026-11-04
**Status:** implemented; awaiting owner visual sign-off
**Spec:** `docs/superpowers/specs/2026-11-02-liquid-glass-renderer-adoption-design.md`
**Spike report:** `docs/superpowers/references/2026-11-04-liquid-glass-spike-report.md`

## Commits on `feat/v2-complete-dashboard`
- `bcd48f6` Flutter 3.47.5 pinned, `file_picker` dropped
- `64d9755` GPU flags on runners (merge `0deaaef`)
- `0c1e375` `AppleLiquidGlass` on `liquid_glass_renderer`, `AppleVisualScope`, `AppleGlassShape`
- `c2d76dc` Gate C removed: 32 lib files, 18 test files, 2 shader files
- `542df02` debug glass review page (merge `8900022`)
- `068a855` top bar and dialog chrome rendered as glass (merge)
- `2dc42f3` Linux full-glass integration test, `tool/ci.sh --device` (merge `19f741c`)

## Evidence
- Local `tool/ci.sh` on the merged head: all checks passed, 1310 tests.
- `tool/ci.sh --device`: `LG_PROBE negative [48,56,64]`, `full [44,64]`.
- GitHub Actions: https://github.com/majidsii/dashboard-shakhsi/actions/runs/41712548727, success, 1310 tests passed.
- The owner's uncommitted Gate C WIP was backed up to
  `/home/shabin/projects/personal/dashboard-shakhsi-gate-c-wip-backup-2026-11-04/` before it was discarded.

## Usage
- Glass: `AppleLiquidGlass(role:, shape: AppleGlassShape..., child:)`.
- Theme: `AppleVisualScope.of(context)`, driven by app brightness.
- Only `apple_liquid_glass.dart` and `app_bootstrap.dart` import `liquid_glass_renderer`.
- Content cards stay `OriginalGlass`.
- Review page: `flutter run -d linux --dart-define=GLASS_REFERENCE_DIR=/home/shabin/projects/personal/dashboard-shakhsi-reference-captures`,
  then long-press the brand island in a debug build.

## Deferred items
- Glass for buttons and pills.
- The scroll edge effect.
- macOS 27 desktop tuning.
- A `BackdropGroup` to share backdrop captures (the top bar takes 3 captures; the review page takes 8).
- The Windows run. The build is on private draft release 432096821; keep it.
- Owner visual sign-off on the review page.
- Android visual check of the real app (not just the spike).
- Decide whether to keep `62262ff` (the Kotlin plugin on the app module).
- The review route literal `'/debug/glass-review'` in `dashboard_screen.dart` should use `AppRoutes.glassReview`.
