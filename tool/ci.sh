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
  flutter test --tags device || [ $? -eq 79 ]

  # One app launch per file: a second launch in the same flutter test call
  # fails to start on Linux ("log reader stopped unexpectedly").
  failed=()
  for f in $(printf '%s\n' integration_test/*_test.dart | LC_ALL=C sort); do
    step "flutter test $f -d linux"
    flutter test "$f" -d linux || failed+=("$f")
  done
  if [ "${#failed[@]}" -gt 0 ]; then
    printf '\nFAILED:\n'
    printf '  %s\n' "${failed[@]}"
    exit 1
  fi
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
