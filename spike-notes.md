# Liquid Glass spike — raw notes

## SDK
- 3.47.5 (`/home/shabin/develop/flutter-3.47.5/bin/flutter --version`):
  ```
  Flutter 3.47.5 • channel [user-branch] • /home/shabin/develop/flutter
  Framework • revision 6a19cca564 (7 weeks ago) • 2026-09-17 14:13:22 -0400
  Engine • hash ab598368592da0064197e2bc15c7f5b0a2c6bb1f (revision af7e796e16) (1 months ago) • 2026-09-16 18:35:09.000Z
  Tools • Dart 3.13.4 • DevTools 2.60.0
  ```
  Note: the `/home/shabin/develop/flutter` in the version line is the clone's `origin` remote URL, not the SDK root. Harmless.
- 3.44.6 (`/home/shabin/develop/flutter/bin/flutter --version | head -1`):
  ```
  Flutter 3.44.6 • channel stable • https://github.com/flutter/flutter.git
  ```
- Spike worktree HEAD at baseline: 752e885 (`fix: resolve analyzer warnings in apple glass rendering`). `main` moved because of the CI plan.

## Pub get side effects (3.47.5)
Commit 54bc638 `spike: apply Flutter 3.47.5 pub get changes` holds these, applied by `pub get` on 3.47.5.
- Changed dependencies (5):
  - intl 0.20.2 → 0.20.3
  - matcher 0.12.19 → 0.12.20
  - meta 1.18.0 → 1.19.0
  - test_api 0.7.11 → 0.7.12
  - vector_math 2.2.0 → 2.4.4
- `analysis_options.yaml` gained an `analyzer.exclude` block:
  ```
  exclude:
    - build/**
    - android/**
    - windows/**
    - macos/**
    - linux/**
  ```

## 3.47.5 baseline (existing project)
- analyze: 0 issues (`No issues found! (ran in 53.4s)`, exit 0)
- format: 1 file would change (formatter drift between 3.44.6 and 3.47.5: 1 file). `test/app/apple_visual/apple_custom_glass_impeller_test.dart`. The 3.44.6 formatter is clean on it.
  - Command: `dart format --output=none --set-exit-if-changed lib test` (the brief's `flutter format` is not a Flutter command; `dart format` is the plan's intent). Output: `Changed test/app/apple_visual/apple_custom_glass_impeller_test.dart`, `Formatted 444 files (1 changed)`.
- tests: `flutter test --reporter=failures-only` exit 0. `+1345 ~1: All other tests passed!`. Passed 1345, skipped 1, failed 0. Failing: none.
  - Full log: `build/baseline-test.log` (git-ignored). The log has drift debug warnings (`AppDatabase created multiple times`) and their stack traces. These are warnings, not failures.

## Q3 native hooks build

- Pinned `liquid_glass_renderer: 1.0.0-dev.2` (no caret) in pubspec.yaml.
- `flutter pub get`: resolved on first try via the mirror (`https://pub.flutter-io.cn`, per pubspec.lock). No fallback retry needed.
- `flutter build linux --release` (Flutter 3.47.5, mirror env kept): SUCCESS, exit 0.
  Output: `✓ Built build/linux/x64/release/bundle/dashboard_shakhsi`
  Bundle: `build/linux/x64/release/bundle/` (contains dashboard_shakhsi, data, lib).
- Wall time: 212 s (includes first-time Linux engine artifact downloads of ~73 s from the mirror).
- No hook errors. Result: Q3 = yes, native build hooks work in a Linux release build.

## Q1 Linux full glass (release, no flags)
- Corrected release probe (ancestor boundary at origin, per task-5 investigation): `SPIKE_RELEASE_PROBE edges=[44, 64] offgrid=[4, 0]` = full glass.
- Probe, debug run (`flutter test integration_test/liquid_glass_full_glass_probe_test.dart -d linux`, builds the real Linux debug app; file analyzes clean):
  - No flags: `LG_PROBE negative edges=[48, 56, 64]` PASS; `LG_PROBE full edges=[48, 56, 64]` FAIL ("Expected: true", no displaced stripe edge). Probe detects the fallback.
  - `--enable-impeller` only: same as no flags (negative PASS, full FAIL, full edges=[48, 56, 64]).
  - `--enable-impeller --enable-flutter-gpu`: flag ACCEPTED by `flutter test`. `LG_PROBE negative edges=[48, 56, 64]` PASS; `LG_PROBE full edges=[44, 64]` PASS (44 is 4 px off the 8 px grid). All tests passed.
  - Caveat: a debug-mode test run, not release. Q1 is decided in Task 4.
- runner flag, debug run, no CLI flags: `fl_dart_project_set_enable_flutter_gpu(project, TRUE);` added in `linux/runner/my_application.cc`. `flutter test integration_test/liquid_glass_full_glass_probe_test.dart -d linux` (no flags):
  - `LG_PROBE negative edges=[48, 56, 64]` PASS
  - `LG_PROBE full edges=[44, 64]` PASS
  - `+2: All tests passed!` exit 0.
- release bundle, no flags (`flutter build linux --release -t lib/spike/liquid_glass_spike_main.dart`, run `./build/linux/x64/release/bundle/dashboard_shakhsi`, in-app pixel probe 3 s after first frame, no screenshot):
  `SPIKE_RELEASE_PROBE edges=[48, 56, 64] offgrid=[0, 0, 0]` -> FALLBACK, not full glass (all edges on the 8 px grid, same as the debug fallback). Runner has `fl_dart_project_set_enable_flutter_gpu(project, TRUE)`.
  - The same probe in `flutter run --profile` (with and without `--enable-impeller --enable-flutter-gpu`) also gives `edges=[48, 56, 64]`. Log shows `Using the Impeller rendering backend (OpenGLESSDF)`.
  - Diagnostic: release with pill `refractionAmount: 60, refractionHeight: 20` (the debug probe's settings) still `edges=[48, 56, 64]`. So the spike's default pill settings are not the cause. (That edit was reverted.)
  - Unexplained: the debug integration probe shows full glass ([44, 64]) with the same runner flag. Release/profile do not.

### Q1 investigation (release/profile "fallback")
- Investigation:
  - Debug run of the spike app also prints `edges=[48, 56, 64]`, so build mode is not the cause. Full path is active in every mode: `lgr.render: Painting glass with 1 shapes` / `lgr.geometry: Rebuilding geometry` in debug and profile alike, no FakeGlass log.
  - `flutter test integration_test/... --profile` is rejected ("Could not find an option named --profile").
  - Probe-only app (`lib/spike/probe_offset_main.dart`), glass 60/20: boundary at screen x=0 gives `[44, 64]` (full) in debug, profile. Boundary at screen x=296 (`V=geom`) gives `[48, 56, 64]` from `boundary.toImage`, but a `toImage` of an ancestor boundary at origin 0 gives `[44, 64]` for the same pixels, in profile AND release.
  - Root cause: probe artifact. `RenderRepaintBoundary.toImage` of a nested boundary with a non-zero screen offset drops the glass refraction. Glass is rendered; the Q1/Q5 probe in the spike app was wrong. Q5 profile numbers therefore measured full glass (the ancestor capture proves the full path), not the fallback.
  - The `LgrLogs.initAllLogs()` call is kept in the spike main.

## Q5 performance
Screen: `lib/spike/liquid_glass_spike_main.dart`, Linux profile (`flutter run --profile -d linux`), 20 s auto-scroll, no flags.
IMPORTANT: in profile mode the Linux app renders the FALLBACK glass (probe edges on grid), so these numbers measure the fallback path, not full Liquid Glass.
- glass run 1: `SPIKE_FRAMES n=1190 build_p50_ms=0.67 build_p90_ms=1.00 raster_p50_ms=2.76 raster_p90_ms=3.30`
- glass run 2: `SPIKE_FRAMES n=1189 build_p50_ms=0.54 build_p90_ms=0.80 raster_p50_ms=2.28 raster_p90_ms=2.60`
- glass run 3: `SPIKE_FRAMES n=1191 build_p50_ms=0.53 build_p90_ms=0.78 raster_p50_ms=2.29 raster_p90_ms=2.69`
- median raster_p90_ms = 2.69 (<= 8.00: threshold met, but on fallback rendering)
- no-glass baseline (3 LiquidGlassLayer -> SizedBox.shrink): `SPIKE_FRAMES n=1189 build_p50_ms=0.45 build_p90_ms=0.71 raster_p50_ms=1.80 raster_p90_ms=2.14`
- extra: profile with `--enable-impeller --enable-flutter-gpu`: `raster_p90_ms=3.27` (still fallback).
- extra: release bundle (refraction 60/20 diagnostic): `raster_p90_ms=2.37`.

## Q2 Android
- APK built on GitHub run https://github.com/majidsii/dashboard-shakhsi/actions/runs/41547867854; awaiting owner's on-device reading (screen shows GLASS: FULL/FALLBACK and frame stats). Package suffix .lgspike; CI removes file_picker (Kotlin plugin class not visible to Java compile under Flutter 3.47).

## Q4 Windows
Runner change prepared; not built or run (no Windows machine). Status: unverified.
