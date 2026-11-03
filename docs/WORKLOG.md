# Work Log

Append-only record of what has been implemented, reviewed, researched or decided.
Newest entries at the top. Each entry is short and links to the detail
(spec, plan, checkpoint, report, commits). Status lives in `PROJECT_ROADMAP.md`;
this file is the history behind it.

Entry template:

```markdown
## YYYY-MM-DD — <title>
- **Type:** implemented | reviewed | researched | decided | found
- **What:** one or two lines
- **Evidence / links:** commits, CI run, spec/plan/checkpoint paths
- **Follow-ups:** anything left open (or "none")
```

---

## 2026-11-03 — Liquid Glass spike (paused)
- **Type:** researched (in progress)
- **What:** Step 0 spike of `2026-11-02-liquid-glass-renderer-adoption-design.md`,
  plan `docs/superpowers/plans/2026-11-03-liquid-glass-spike.md`. Paused at the
  owner's request (end of day). Answers so far:
  - **Q1 Linux full glass, release, no CLI flags: YES.** Needs one line in
    `linux/runner/my_application.cc`: `fl_dart_project_set_enable_flutter_gpu(project, TRUE);`
    (Impeller is default-on in 3.47.5). Probe edges full `[44, 64]` vs fallback
    `[48, 56, 64]` in debug, profile and release. Owner saw bent stripes on screen.
  - **Q3 native hooks build on Linux: YES.** `liquid_glass_renderer.shaderbundle`
    is in the release bundle. Linux release build 212 s (first run).
  - **Q5 performance (Linux, profile, dashboard-shaped screen): PASS.** Median
    raster p90 2.69 ms with glass vs 2.14 ms without (limit 8 ms).
  - **Q4 Windows: UNVERIFIED.** Runner change prepared
    (`project.set_enable_flutter_gpu(true);` in `windows/runner/main.cpp`).
  - **Q2 Android: OPEN — APK crashes on launch** on the owner's Samsung Galaxy
    A34 5G ("app has a problem"), i.e. a process crash. No logs yet.
  - 3.47.5 baseline: Dart 3.13.4; existing suite 1345 pass / 1 skip / 0 fail;
    analyze clean; formatter drift in 1 file
    (`test/app/apple_visual/apple_custom_glass_impeller_test.dart`);
    `pub get` bumps intl, matcher, meta, test_api, vector_math and adds an
    `analyzer.exclude` block.
- **Findings to carry into the adoption plan:**
  - `RenderRepaintBoundary.toImage` on a nested boundary at a non-zero screen
    offset misses the glass; probes must capture an origin-(0,0) ancestor.
  - Glass brightness must follow the app theme, not `platformBrightness`
    (owner's desktop is `prefer-dark`; dark glass on a light page looked grey).
  - `file_picker` (Android plugin registration) fails to build on Flutter 3.47.
    The spike APK workflow removes it; the real app needs a fix before upgrading.
  - `flutter test` has no `--profile`/`--release`.
  - iOS 26.1 reference captures from the owner (camera controls, Settings search
    bar light/dark, passcode keypad clear glass, lock-screen notification) are
    stored OUTSIDE the public repo (they contain personal data):
    `/home/shabin/projects/personal/dashboard-shakhsi-reference-captures/`.
    Also add Apple's "scroll edge effect" (progressive fade under bars) to the
    adoption scope.
- **Evidence / links:** branch `spike/liquid-glass` (pushed; notes in
  `spike-notes.md`), worktree `/home/shabin/projects/personal/dashboard-shakhsi-spike-liquid-glass`,
  SDK `/home/shabin/develop/flutter-3.47.5`. Android build runs on GitHub
  (`.github/workflows/spike-android.yml` on the spike branch), e.g. run
  https://github.com/majidsii/dashboard-shakhsi/actions/runs/41547867854.
  APKs are on a private DRAFT release (no tag)
  https://github.com/majidsii/dashboard-shakhsi/releases/tag/untagged-710374df82c830b3cbc7 .
- **Resume steps:**
  1. Check whether the A/B/C isolation APK run finished (commit `7112e05` on
     `spike/liquid-glass`): `gh run list --branch spike/liquid-glass --limit 3`.
     If the three APKs aren't on the draft release yet, rerun/finish that.
     Variants: A plain app (GPU flag on), B glass without `EnableFlutterGPU`,
     C current build. Each has its own app id and label, so all three install
     at once.
  2. Better evidence: owner runs `sudo apt install adb`, enables USB debugging,
     connects the phone; then `adb logcat -b crash` / `adb logcat` while
     launching shows the crash cause.
  3. Fix or classify the Android crash, then write the spike report (plan Task 8)
     and the GO/NO-GO verdict.
  4. After the spike: delete the draft release; keep the spike branch for the
     adoption plan.
- **Follow-ups:** main worktree still has uncommitted Gate C WIP
  (`apple_custom_glass_filter.dart`, `apple_custom_glass_impeller_test.dart`,
  `apple_glass_shader_identity_visual_test.dart`, `integration_test/`). It is
  superseded and will be deleted with `rendering/**` after a GO.

## 2026-11-03 — CI baseline restored
- **Type:** implemented
- **What:** CI workflow plus local `tool/ci.sh` now run format, analyze, tests and generated-code checks on every push and PR. Superseded apple pixel-golden comparisons removed, tree formatted, 5 analyzer warnings fixed. Owner granted standing push permission.
- **Evidence / links:** checkpoint `docs/superpowers/checkpoints/2026-11-03-ci-baseline-checkpoint.md`; green CI run https://github.com/majidsii/dashboard-shakhsi/actions/runs/41539038228 on 7b6ec34; commits 2317824..7b6ec34
- **Follow-ups:** Confirm the 3.47.x formatter drift (1 file) when the Liquid Glass work moves `.flutter-version`.

## 2026-11-03 — Project guide and work log
- **Type:** decided
- **What:** Added `CLAUDE.md` (commands, architecture, invariants, how work is
  run) and this log. Work runs as: the main session (strongest model) plans,
  dispatches and reviews; cheaper subagents (`sonnet` by default, `haiku` for
  mechanical tasks) implement one plan task each and get review findings back
  through `SendMessage` until fixed.
- **Evidence / links:** `CLAUDE.md`, `docs/WORKLOG.md`
- **Follow-ups:** none

## 2026-11-03 — CI baseline spec and plans for CI + Liquid Glass spike
- **Type:** decided
- **What:** CI spec (one workflow calling `tool/ci.sh`: format, generated-code
  check, analyze, test, Linux release build). Plans for CI and for the Liquid
  Glass Step 0 spike (separate Flutter 3.47.5 SDK, stripe-refraction probe,
  runner flags, frame-time measurement).
- **Evidence / links:** `docs/superpowers/specs/2026-11-03-ci-baseline-design.md`,
  `docs/superpowers/plans/2026-11-03-ci-baseline.md`,
  `docs/superpowers/plans/2026-11-03-liquid-glass-spike.md`; commits `2621c94`, `4d955fc`
- **Follow-ups:** execute CI plan, then spike plan.

## 2026-11-03 — Local test baseline
- **Type:** found
- **What:** `flutter test` on Flutter 3.44.6: 1345 passed, 1 skipped, 11 failed,
  5 m 10 s. 10 failures are the superseded Apple pixel goldens in
  `test/app/apple_visual/apple_liquid_glass_test.dart`. 1 is the untracked Gate C
  WIP test `apple_glass_shader_identity_visual_test.dart`. Drift codegen is
  reproducible (no diff after `build_runner build`). 24 files not `dart format`-clean.
- **Evidence / links:** CI spec §6
- **Follow-ups:** CI plan Tasks 1–2 fix the goldens and formatting.

## 2026-11-02 — Liquid Glass direction changed; program reordered
- **Type:** decided
- **What:** Gate C custom shader renderer superseded by `liquid_glass_renderer`
  1.0.0-dev.2 (iOS 27-fitted, Apache-2.0) behind the `AppleLiquidGlass` adapter.
  Pixel-golden acceptance is replaced by perceptual side-by-side review. A spike
  decides go/no-go before any production change. Program order: CI →
  Liquid Glass → v2 release readiness → habits & goals → Tasks 2.9–2.11.
- **Evidence / links:** `docs/superpowers/specs/2026-11-02-liquid-glass-renderer-adoption-design.md`,
  `PROJECT_ROADMAP.md` §0 and §7; commit `7dd3dcd`
- **Follow-ups:** spike.

## 2026-11-02 — Project review findings
- **Type:** reviewed
- **What:**
  - Gate C shader was a passthrough after ~40 commits.
  - No feature screen uses `apple_visual`.
  - Pixel-golden gate can't pass by construction (61.33 % diff).
  - `lib/app/apple_visual/generated` is 26,735 lines.
  - 165 `tool/verify_*` scripts.
  - v2 deleted v1's CI (`9f0573d`).
  - v2 has no importer for v1 `data.json`.
  - Shader image filters work on Linux only with Impeller
    (`--enable-impeller` → supported; default → unsupported, on 3.44.6).
  - Flutter 3.47.5's Linux embedder has `fl_dart_project_set_enable_flutter_gpu()`
    and Impeller on by default. Windows has `DartProject::set_enable_flutter_gpu()`.
- **Evidence / links:** `integration_test/apple_glass_shader_backend_probe_test.dart` (untracked);
  Flutter sources `engine/src/flutter/shell/platform/linux/fl_dart_project.cc` @ 3.47.5
- **Follow-ups:** covered by program order.

## 2026-11-02 — Competitor research
- **Type:** researched
- **What:** Persian competitors are single-purpose. Finance: Holoo, Parmis Hamrah,
  Ghollak, Niv, Fanoos. Tasks/habits: Routino (~140K installs on Cafe Bazaar),
  Tiklist, Prestige, ToDoList. All-in-one apps exist but are English-only
  (Organize Your Life, Checkloop, Astryde, Notion "Life OS" templates).
  Positioning: Persian + Jalali + all-in-one + private/offline + Apple-grade
  design. Current name "داشبورد شخصی" is generic. Decide the new name before the
  v2 release, because the app ID and data paths depend on it.
- **Evidence / links:** sources listed in the 2026-11-02 conversation; Digikala Mag,
  Cafe Bazaar listings, Product Hunt.
- **Follow-ups:** naming in v2 release readiness.

## 2026-08-16 → 2026-10-18 — Visual Foundation 2.A Gate C (superseded)
- **Type:** implemented (superseded 2026-11-02)
- **What:** source recipes, render strategy/backend split, shader program cache,
  uniform contract, material layers, shadow pipeline. Shader output never went
  beyond passthrough.
- **Evidence / links:** `docs/superpowers/specs/2026-09-06-gate-c-*.md`,
  `docs/superpowers/references/2026-09-02-gate-c-renderer-compositor-blur-blocker.md`;
  commits `b33363e`…`b6afe3a`
- **Follow-ups:** delete `lib/app/apple_visual/rendering/**` after spike Go.

## 2026-08-09 → 2026-08-15 — Visual Foundation 2.A Gates A and B
- **Type:** implemented
- **What:** reproducible Apple UI kit source extraction (Gate A); platform family,
  source tokens, typography (Vazirmatn deviation), metrics, motion (Gate B).
- **Evidence / links:** `docs/superpowers/checkpoints/2026-08-15-visual-foundation-2a-gate-b-complete-checkpoint.md`,
  `docs/superpowers/decisions/`; commit `d1e101d`
- **Follow-ups:** none

## 2026-08-02 → 2026-08-09 — Phase 2 Tasks 2.1–2.8
- **Type:** implemented
- **What:** task status/display number/ordering (2.1), planning fields (2.2),
  List/Kanban (2.3), reminders (2.4), shared recurrence engine (2.5), recurring
  tasks + calendar (2.6), recoverable timer (2.7), quick-entry templates (2.8).
  Schema 8. 1245 tests at the 2.8 checkpoint.
- **Evidence / links:** `docs/superpowers/checkpoints/2026-08-0*-task-2-*.md`;
  checkpoint commits `d21be52`, `f17fc9e`, `f367922`, `2761407`, `387e046`,
  `b556ea1`, `458499d`
- **Follow-ups:** Tasks 2.9–2.11 pending.

## 2026-07-26 → 2026-08-02 — Phase 1 foundation
- **Type:** implemented
- **What:** Flutter v2 baseline (`9f0573d`). Exact money formatting. Drift
  persistence for tasks and finance. Time and notification foundation.
  Notification routing. Linux systemd notification pipeline (unit store,
  schedule registry, scheduler, delivery entrypoint wiring).
- **Evidence / links:** `docs/superpowers/checkpoints/2026-07-2*-*.md`,
  `2026-07-30-*.md`, `2026-08-02-linux-notification-delivery-platform-wiring-checkpoint.md`
- **Follow-ups:** none

## 2026-07-15 — v1 releases
- **Type:** implemented
- **What:** v1.0.0–v1.2.0 published on GitHub (Python + HTML webview; `.deb`,
  `.rpm`, Windows `.exe`, macOS `.zip`, Android `.apk`). About 27 downloads as of
  2026-11-02.
- **Evidence / links:** `main` branch, GitHub releases
- **Follow-ups:** v2 must import v1 `data.json`.
