#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXPECTED_VERSION="$(tr -d '[:space:]' < "$APP_DIR/.flutter-version")"
ACTUAL_VERSION="$(flutter --version --machine | python3 -c 'import json,sys; print(json.load(sys.stdin)["frameworkVersion"])')"

if [[ "$ACTUAL_VERSION" != "$EXPECTED_VERSION" ]]; then
  echo "Expected Flutter $EXPECTED_VERSION, found $ACTUAL_VERSION" >&2
  exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

flutter create \
  --platforms=android,ios,linux,macos,windows \
  --org app \
  --project-name borj \
  "$tmp_dir/borj"

for platform in android ios linux macos windows; do
  rm -rf "$APP_DIR/$platform"
  cp -a "$tmp_dir/borj/$platform" "$APP_DIR/$platform"
done

python3 "$APP_DIR/tool/configure_native_ids.py" "$APP_DIR"
