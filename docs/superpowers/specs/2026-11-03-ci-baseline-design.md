# CI Baseline — Design

**Date:** 2026-11-03
**Status:** PROPOSED (2026-11-03) — awaiting owner review
**Program order:** item 1 of `PROJECT_ROADMAP.md` §0

## 1. Problem

- v1 had a GitHub Actions workflow (`.github/workflows/build.yml` on `main`)
  that tested and packaged every push. The v2 baseline commit `9f0573d`
  deleted it. v2 has had no CI for 148 commits.
- Verification today is manual: the roadmap's 16-step checklist plus 165
  Python `tool/verify_*` scripts, most of which assert file contents that
  tests and the analyzer should cover.
- 24 Dart files are not `dart format`-clean.

## 2. Goal

Every push and pull request is verified automatically, with the same commands
the developer can run locally with one script. A green CI run becomes the
evidence a checkpoint cites.

## 3. Scope

In scope:

- one workflow, `.github/workflows/ci.yml`;
- one local script, `tool/ci.sh`, that runs the same checks in the same order;
- a one-time `dart format` commit so the format check can be enforced;
- a check that committed generated code is current.

Out of scope (release-readiness sub-project): packaging (`.deb`, `.rpm`,
Windows, macOS, Android), signing, tag-triggered releases, Android and
Windows CI builds.

## 4. Workflow

```
on: push (all branches), pull_request, workflow_dispatch
concurrency: one run per ref, cancel in progress

job verify (ubuntu-24.04, timeout 45 min)
  1. checkout
  2. install Linux build deps (clang, cmake, ninja-build, pkg-config,
     libgtk-3-dev, liblzma-dev, libsecret-1-dev, plus whatever the first
     Linux build reports missing)
  3. set up Flutter at the exact version in .flutter-version
     (subosito/flutter-action, pinned by commit SHA, with cache)
  4. tool/ci.sh
```

`tool/ci.sh` runs, failing on the first error:

1. `flutter --version` (printed for the log);
2. `flutter pub get --enforce-lockfile`;
3. `dart format --output=none --set-exit-if-changed lib test integration_test`;
4. `dart run build_runner build --delete-conflicting-outputs`, then
   `git diff --exit-code` on generated files: committed code must match the
   generator;
5. `flutter analyze`;
6. `flutter test`;
7. `flutter build linux --release`.

Third-party actions are pinned to a full commit SHA with the tag in a comment.
The workflow gets `permissions: contents: read` only.

## 5. Flutter version source

`.flutter-version` is the single source of the SDK version. The workflow reads
it; `tool/ci.sh` warns when the local `flutter --version` differs. When the
Liquid Glass work moves the project to 3.47.x, changing that one file moves CI
too.

## 6. Local baseline (2026-11-03, Flutter 3.44.6)

`flutter test` on the owner's machine: **1345 passed, 1 skipped, 11 failed**,
5 m 10 s wall time.

- 10 failures are the `AppleLiquidGlass source goldens` group in
  `test/app/apple_visual/apple_liquid_glass_test.dart`. It compares against
  design-tool exports, a rule the 2026-11-02 Liquid Glass spec superseded
  regardless of the spike outcome. CI removes that group. The PNGs and
  `test/goldens/apple/manifest.json` stay as reference images for the
  side-by-side review page.
- 1 failure is the uncommitted, untracked
  `test/app/apple_visual/apple_glass_shader_identity_visual_test.dart` (Gate C
  WIP). It is not in git, so CI never sees it.
- The 1 skip is `apple_custom_glass_impeller_test.dart`, skipped where shader
  filters are unsupported. It is removed with `rendering/**` by the Liquid
  Glass adoption plan.

## 7. Tests that can't pass on CI

Any test that depends on the developer's machine (GPU, desktop session,
installed fonts, systemd user session) must not run silently skipped and must
not fail CI for environment reasons. Rules:

- the baseline run lists every such test with its failure reason;
- each one is either fixed to be hermetic, or tagged (`@Tags(['device'])`) and
  excluded from `flutter test` in CI with `--exclude-tags device`;
- device-tagged tests run through `tool/ci.sh --device` locally;

## 8. Process change

- New work does not add `tool/verify_*` scripts. A checkpoint cites the green
  CI run (URL and commit SHA) instead of a semantic verifier.
- Existing verifiers stay untouched for now. Retiring them is a separate
  cleanup.
- `PROJECT_ROADMAP.md` §3.3 is updated to match: steps 6–10 become
  "`tool/ci.sh` green locally; CI green on the pushed commit".

## 9. Acceptance

- A push to `feat/v2-complete-dashboard` produces a green `verify` run.
- A deliberately broken commit (format, analyzer, failing test, stale
  generated code) turns the run red. Check each on a throwaway branch and
  delete the branch afterwards.
- `tool/ci.sh` passes locally on the owner's machine.
- Total CI time is recorded in the checkpoint.

## 10. Pushing

The workflow only runs once pushed. The branch is currently ahead of origin.
Pushing happens only with the owner's go-ahead.
