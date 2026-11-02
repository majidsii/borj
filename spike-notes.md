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

## Q1 Linux full glass (release, no flags)

## Q5 performance

## Q2 Android

## Q4 Windows
