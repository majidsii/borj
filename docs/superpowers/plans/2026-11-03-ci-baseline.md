# CI Baseline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Every push and pull request runs format, generated-code, analyzer, test and Linux release-build checks on GitHub Actions, through one script that also runs locally.

**Architecture:** `tool/ci.sh` holds the checks; `.github/workflows/ci.yml` only installs the toolchain and calls the script. Superseded pixel goldens are removed and the tree is formatted once so the suite starts green.

**Tech Stack:** GitHub Actions (`ubuntu-24.04`), `actions/checkout` v7.0.1, `subosito/flutter-action` v2.23.0, Flutter from `.flutter-version` (3.44.6), bash.

**Spec:** `docs/superpowers/specs/2026-11-03-ci-baseline-design.md`

## Global Constraints

- Third-party actions are pinned by full commit SHA:
  - `actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1`
  - `subosito/flutter-action@1a449444c387b1966244ae4d4f8c696479add0b2 # v2.23.0`
- Workflow permissions: `contents: read` only.
- `.flutter-version` is the only source of the Flutter version.
- `pubspec.lock` resolves every package from `https://pub.flutter-io.cn`. CI sets `PUB_HOSTED_URL=https://pub.flutter-io.cn` so `--enforce-lockfile` holds.
- Do not stage the existing uncommitted Gate C WIP: `lib/app/apple_visual/rendering/compositor/apple_custom_glass_filter.dart`, `test/app/apple_visual/apple_custom_glass_impeller_test.dart`, `test/app/apple_visual/apple_glass_shader_identity_visual_test.dart`, `integration_test/`. Always `git add` explicit paths.
- No new `tool/verify_*` scripts.
- Push only with the owner's go-ahead (Task 4 asks).

---

### Task 1: Remove the superseded Apple pixel-golden group

The group compares against design-tool exports, a rule superseded by `2026-11-02-liquid-glass-renderer-adoption-design.md` §3. Its 10 tests fail by construction (61 % pixel diff). The PNGs and `manifest.json` stay as reference images.

**Files:**
- Modify: `test/app/apple_visual/apple_liquid_glass_test.dart` (as of `7dd3dcd`: the golden group is lines 109–241, `_GoldenCase` 244–258, `_manifestFixture` 260–270, `dart:convert` import line 1)

**Interfaces:**
- Produces: a test file with only the `AppleLiquidGlass source-consumption contract` group; `_resolvedTheme` stays (that group uses it).

- [ ] **Step 1: Confirm the current failures**

```bash
flutter test test/app/apple_visual/apple_liquid_glass_test.dart 2>&1 | tail -3
```

Expected: `Some tests failed.` with 10 failures, all named `... matches locked Apple source`.

- [ ] **Step 2: Delete the golden group and its helpers**

In `test/app/apple_visual/apple_liquid_glass_test.dart`:
- delete the whole `group('AppleLiquidGlass source goldens', () { ... });` block (starts `group('AppleLiquidGlass source goldens'`, ends at the `});` before the closing `}` of `main`);
- delete `final class _GoldenCase { ... }`;
- delete `Map<String, dynamic> _manifestFixture(String path) { ... }`;
- delete `import 'dart:convert';` (only `_manifestFixture` used it).

Keep `import 'dart:io';` (the contract group reads a source file with `File`) and `_resolvedTheme`.

- [ ] **Step 3: Run the file**

```bash
flutter test test/app/apple_visual/apple_liquid_glass_test.dart 2>&1 | tail -2
flutter analyze test/app/apple_visual/apple_liquid_glass_test.dart
```

Expected: `All tests passed!` and `No issues found!`.

- [ ] **Step 4: Commit**

```bash
git add test/app/apple_visual/apple_liquid_glass_test.dart
git commit -m "test: remove superseded apple pixel-golden comparisons

The 2026-11-02 Liquid Glass spec replaces pixel identity with design-tool
exports by perceptual side-by-side acceptance. Reference PNGs stay.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: One-time format

**Files:**
- Modify: the 24 files `dart format` reports under `lib/` and `test/`.

- [ ] **Step 1: List what needs formatting, minus the WIP files**

```bash
mkdir -p build
dart format --output=none --set-exit-if-changed lib test 2>&1 \
  | sed -n 's/^Changed //p' \
  | grep -v -x -e lib/app/apple_visual/rendering/compositor/apple_custom_glass_filter.dart \
               -e test/app/apple_visual/apple_custom_glass_impeller_test.dart \
               -e test/app/apple_visual/apple_glass_shader_identity_visual_test.dart \
  > build/format-changes.txt
wc -l < build/format-changes.txt
```

Expected: about `24`. Record the number. (`build/` is git-ignored.)

- [ ] **Step 2: Format exactly those files**

```bash
xargs dart format < build/format-changes.txt
```

- [ ] **Step 3: Verify**

```bash
flutter analyze
xargs dart format --output=none --set-exit-if-changed < build/format-changes.txt
```

Expected: `No issues found!` and exit code 0.

- [ ] **Step 4: Commit only the formatted files**

```bash
xargs git add -- < build/format-changes.txt
git commit -m "style: apply dart format

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
git status --short
```

Expected: `git status --short` shows only the WIP entries from Global Constraints. If a WIP file still needs formatting, CI never sees it (it is uncommitted); it gets formatted when that work is committed or deleted.

---

### Task 3: `tool/ci.sh` and `dart_test.yaml`, green locally

**Files:**
- Create: `tool/ci.sh`
- Create: `dart_test.yaml`

**Interfaces:**
- Produces: `tool/ci.sh` (no args = CI checks; `--device` = only tests tagged `device`). Task 4's workflow calls `tool/ci.sh` with no args.

- [ ] **Step 1: Declare the `device` tag**

Create `dart_test.yaml`:

```yaml
tags:
  device:
    # Needs a real desktop session or GPU. Excluded from CI; run with
    # tool/ci.sh --device.
```

- [ ] **Step 2: Write the script**

Create `tool/ci.sh`:

```bash
#!/usr/bin/env bash
# Runs the same checks as .github/workflows/ci.yml.
#   tool/ci.sh           CI checks
#   tool/ci.sh --device  only tests tagged 'device' (desktop session / GPU)
set -euo pipefail
cd "$(dirname "$0")/.."

step() { printf '\n==> %s\n' "$*"; }

expected="$(tr -d '[:space:]' < .flutter-version)"
actual="$(flutter --version --machine | sed -n 's/.*"frameworkVersion": *"\([^"]*\)".*/\1/p')"
step "Flutter ${actual} (.flutter-version: ${expected})"
if [[ "${actual}" != "${expected}" ]]; then
  echo "warning: local Flutter ${actual} differs from .flutter-version ${expected}" >&2
fi

if [[ "${1:-}" == "--device" ]]; then
  step "flutter test --tags device"
  flutter test --tags device
  exit 0
fi

step "flutter pub get --enforce-lockfile"
flutter pub get --enforce-lockfile

step "dart format"
format_paths=(lib test)
if [[ -d integration_test ]]; then format_paths+=(integration_test); fi
dart format --output=none --set-exit-if-changed "${format_paths[@]}"

step "generated code is current"
dart run build_runner build --delete-conflicting-outputs
git diff --exit-code -- '*.g.dart'

step "flutter analyze"
flutter analyze

step "flutter test"
flutter test --exclude-tags device

step "flutter build linux --release"
flutter build linux --release

step "all checks passed"
```

```bash
chmod +x tool/ci.sh
```

- [ ] **Step 3: Run it locally**

The local tree has an untracked `integration_test/` and an untracked failing test (Gate C WIP). Run the script from a clean checkout of HEAD so it sees exactly what CI sees:

```bash
CHECK=/home/shabin/projects/personal/dashboard-shakhsi-ci-check
git worktree add --detach "$CHECK" HEAD
cp dart_test.yaml "$CHECK"/          # not committed yet
cp tool/ci.sh "$CHECK"/tool/
cd "$CHECK" && time tool/ci.sh 2>&1 | tail -25
```

(The copied files show as untracked in `$CHECK`; `git diff --exit-code -- '*.g.dart'` ignores them.)

Expected: ends with `==> all checks passed`. Record the wall time. If `flutter test` fails, stop and debug per roadmap §3.5 before continuing. Do not tag a failing test `device` unless it truly needs a desktop session or GPU.

- [ ] **Step 4: Remove the check worktree**

```bash
cd /home/shabin/projects/personal/dashboard-shakhsi-v2-integration
git worktree remove --force /home/shabin/projects/personal/dashboard-shakhsi-ci-check
```

- [ ] **Step 5: Commit**

```bash
git add tool/ci.sh dart_test.yaml
git commit -m "build: add local CI script

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: GitHub Actions workflow, green on GitHub

**Files:**
- Create: `.github/workflows/ci.yml`

**Interfaces:**
- Consumes: `tool/ci.sh` from Task 3.

- [ ] **Step 1: Write the workflow**

Create `.github/workflows/ci.yml`:

```yaml
name: CI

on:
  push:
  pull_request:
  workflow_dispatch:

permissions:
  contents: read

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

jobs:
  verify:
    runs-on: ubuntu-24.04
    timeout-minutes: 45
    env:
      PUB_HOSTED_URL: https://pub.flutter-io.cn
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1

      - name: Install Linux build dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y clang cmake ninja-build pkg-config \
            libgtk-3-dev liblzma-dev libstdc++-12-dev libsecret-1-dev

      - name: Read Flutter version
        id: flutter-version
        run: echo "version=$(tr -d '[:space:]' < .flutter-version)" >> "$GITHUB_OUTPUT"

      - uses: subosito/flutter-action@1a449444c387b1966244ae4d4f8c696479add0b2 # v2.23.0
        with:
          channel: stable
          flutter-version: ${{ steps.flutter-version.outputs.version }}
          cache: true
          pub-cache: true

      - name: Run CI checks
        run: tool/ci.sh
```

- [ ] **Step 2: Validate the YAML locally**

```bash
python3 -I -c "import sys,yaml; yaml.safe_load(open(sys.argv[1])); print('ok')" .github/workflows/ci.yml
```

Expected: `ok`.

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "ci: run checks on every push and pull request

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

- [ ] **Step 4: Ask the owner before pushing**

The branch is ahead of `origin/feat/v2-complete-dashboard`. Ask: "Push `feat/v2-complete-dashboard` to GitHub so CI runs?" Continue only on yes.

- [ ] **Step 5: Push and watch**

```bash
git push origin feat/v2-complete-dashboard
gh run watch --exit-status "$(gh run list --branch feat/v2-complete-dashboard --workflow CI --limit 1 --json databaseId --jq '.[0].databaseId')"
```

Expected: run succeeds. If a build dependency is missing, add the package named in the CMake/pkg-config error to the `apt-get install` line, commit (`ci: add <pkg> build dependency`), push, and watch again. If a test fails only on CI, find out why before tagging it `device`.

- [ ] **Step 6: Prove each check can fail**

On a throwaway branch, make one breaking commit per check and confirm each run turns red at the expected step:

```bash
git switch -c ci/negative-checks
# 1. format: add trailing spaces inside a Dart expression in lib/main.dart
# 2. analyzer: add `final unused = 1;` inside a function in lib/main.dart
# 3. test: change one `expect` value in test/core/money/*_test.dart
# 4. generated code: add a column to a Drift table in lib/core/database/app_database.dart without regenerating
```

Do them one at a time: commit, `git push -u origin ci/negative-checks`, wait for red, `git revert --no-edit HEAD`, then the next. Then clean up:

```bash
git switch feat/v2-complete-dashboard
git push origin --delete ci/negative-checks
git branch -D ci/negative-checks
```

Record the four red run URLs.

---

### Task 5: Process update and checkpoint

**Files:**
- Modify: `PROJECT_ROADMAP.md` §3.3 (steps 6–10, 13) and §0 item 1
- Create: `docs/superpowers/checkpoints/2026-11-DD-ci-baseline-checkpoint.md` (DD = completion day)

- [ ] **Step 1: Update §3.3**

In `PROJECT_ROADMAP.md` §3.3, replace steps 6–10:

```markdown
6. Run focused verification.
7. Run `tool/ci.sh` locally until green.
8. Push; the CI run on the pushed commit must be green.
```

and replace step 13 `Create/update task checkpoint and semantic verifier.` with `Create/update task checkpoint citing the green CI run URL and commit SHA.` Renumber the remaining steps.

- [ ] **Step 2: Mark §0 item 1 done**

Append to item 1: ` — **DONE** (<date>, checkpoint: docs/superpowers/checkpoints/<file>)`.

- [ ] **Step 3: Write the checkpoint**

```markdown
# CI Baseline — Checkpoint

**Date:** <date>
**Implementation commits:** <sha list from Tasks 1–4>
**Green CI run:** <url> on <sha>, <duration>

## Evidence
- Local `tool/ci.sh`: passed, <wall time>
- Tests: <passed>/<skipped>/<failed> on CI
- Negative checks (each red at the expected step): format <url>, analyze <url>, test <url>, generated code <url>
- Tests tagged `device`: <list or "none">

## Invariants
- `.flutter-version` drives the CI Flutter version.
- Actions pinned by SHA; workflow permissions `contents: read`.
- Checkpoints cite CI runs; no new `tool/verify_*` scripts.
```

- [ ] **Step 4: Commit and push (owner already approved pushing in Task 4)**

```bash
git add PROJECT_ROADMAP.md docs/superpowers/checkpoints/*-ci-baseline-checkpoint.md
git commit -m "docs: checkpoint CI baseline

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
git push origin feat/v2-complete-dashboard
```

Expected: the CI run for this commit is green.
