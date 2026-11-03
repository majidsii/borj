# Liquid Glass Spike Report

**Date:** 2026-11-04  **SDK:** Flutter 3.47.5 / Dart 3.13.4  **Package:** liquid_glass_renderer 1.0.0-dev.2
**Spike branch:** spike/liquid-glass @ bb3e79e
**Spec:** `docs/superpowers/specs/2026-11-02-liquid-glass-renderer-adoption-design.md`

## Verdict
**GO.** Full Liquid Glass renders on Linux and Android with Flutter 3.47.5, the native
build hooks work, and performance is far inside the limit. Windows is unverified and
does not block the decision (spec Go threshold: Linux YES, Android YES or not blocking, perf under limit).

## Answers
- **Q1 Linux full glass, release, no CLI flags: YES.** Needs only the runner flag below.
  Origin-(0,0) capture probe: `edges=[44, 64]` (full) in debug, profile and release.
  Fallback signature is `[48, 56, 64]`. The owner also saw bent stripes on screen.
- **Q2 Android full glass: YES (visual evidence).** Samsung Galaxy A34 5G (SM-A346E),
  Android 16, Impeller backend Vulkan (logcat: "Using the Impeller rendering backend (Vulkan)").
  Release APK from GitHub run https://github.com/majidsii/dashboard-shakhsi/actions/runs/41623961625
  at bb3e79e. The screenshot shows strong refraction (bent and mirrored stripes at the
  pill's rounded ends, lens-like buttons).
  - Limitation: the in-app `toImage` probe printed `edges=[48, 56, 64]` (fallback) on the
    same build, contradicting the screenshot. It is unreliable on Android
    (devicePixelRatio 2.8125) and is not trusted there. Android is judged visually.
- **Q3 native hooks build (Linux, Android): YES.** Linux release build succeeded (212 s first run,
  `liquid_glass_renderer.shaderbundle` present in the bundle). Android release APK built on GitHub.
- **Q4 Windows: UNVERIFIED.** Runner change prepared, never built or run (no Windows machine).
- **Q5 performance: PASS.**
  - Linux profile, dashboard-shaped screen, 20 s auto-scroll: raster p90 3.30 / 2.60 / 2.69 ms,
    median 2.69 ms; no-glass baseline 2.14 ms; limit 8 ms. These runs were first thought to be
    fallback; the Task 5 investigation showed they measure the full path.
  - Android (A34): `n=2292 build_p50_ms=0.78 build_p90_ms=1.33 raster_p50_ms=3.83 raster_p90_ms=5.03`.

## 3.47.5 regressions in the existing project
- Analyze clean; full suite 1345 pass / 1 skip / 0 fail.
- Formatter drift in 1 file (`test/app/apple_visual/apple_custom_glass_impeller_test.dart`).
- `pub get` bumps intl 0.20.3, matcher 0.12.20, meta 1.19.0, test_api 0.7.12, vector_math 2.4.4,
  and adds an `analyzer.exclude` block (build, android, windows, macos, linux) to `analysis_options.yaml`.
- `file_picker` 11.0.2 fails to build on 3.47 (Android plugin registration, Kotlin Gradle Plugin).
  It is unused in `lib/`, `test/` and `integration_test/` since 9f0573d.
- `flutter_timezone` emits a KGP warning.

## Android launch crash (unrelated to glass)
The owner's APK crashed on launch. Root cause was two v2 bugs dating back to 9f0573d:
1. `MainActivity.kt` was declared in package `ir.dashboard.dashboard_shakhsi`, while the
   namespace and manifest resolve `ir.dashboard.shakhsi.MainActivity`.
2. The Kotlin activity was not compiled into the dex.

Fixed on `feat/v2-complete-dashboard` by replacing it with a Java activity: `9872ff8` (cherry-picked to the spike branch as `bb3e79e`).
Earlier partial attempts: `5a0b240` (rename; the package edit was not staged, a controller
mistake) and `62262ff` (applies the Kotlin plugin to the app module; spike branch `ce4227c`). Nothing Kotlin remains
in the app module, so the adoption plan should decide whether to keep or revert `62262ff`.

## Mechanisms confirmed
- Linux: `fl_dart_project_set_enable_flutter_gpu(project, TRUE)` in `linux/runner/my_application.cc`
- Android: `io.flutter.embedding.android.EnableFlutterGPU` meta-data
- Windows: `project.set_enable_flutter_gpu(true)` in `windows/runner/main.cpp` (prepared, unverified)

## Findings
- `RenderRepaintBoundary.toImage` of a nested boundary at a non-zero screen offset drops the glass
  refraction. Probes must capture an origin-(0,0) ancestor (desktop). Details:
  `.superpowers/sdd/2026-11-03-liquid-glass-spike/task-5-investigation.md`.
- Glass brightness was taken from the platform (dark) on a light page, giving grey glass. It must
  follow the app theme.
- `flutter test` has no `--profile` or `--release`.
- Owner iOS 26.1 reference captures are kept outside the repo (personal data):
  `/home/shabin/projects/personal/dashboard-shakhsi-reference-captures/`. Never copy them in.

## Next step
GO: write the adoption implementation plan. Requirements for that plan:
- glass brightness follows the app theme, not the platform;
- `file_picker` is unused: remove it, or use 13.3.2 (supports Flutter >= 3.38); 11.0.2 breaks on 3.47;
- resolve the `flutter_timezone` KGP warning;
- implement Apple's scroll edge effect (progressive fade under bars);
- delete the Gate C `rendering/**` and its uncommitted WIP;
- move `.flutter-version` to 3.47.5 and update CI accordingly;
- automated full-glass detection must use an origin-(0,0) capture on desktop, and a visual or owner check on Android;
- apply the three runner changes (Linux, Android meta-data, Windows) and decide on `ce4227c`;
- Windows still needs verification on a real machine.

Keep `spike/liquid-glass` and its worktree; the adoption plan reuses its runner and manifest changes.
