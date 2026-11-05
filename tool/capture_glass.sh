#!/usr/bin/env bash
# Saves real-glass PNGs of the prototype screens (needs a Linux desktop session).
#   tool/capture_glass.sh /abs/out/dir [name1,name2]
# Builds a release bundle with the capture entry point, runs it, and returns
# when the app exits after writing every PNG.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="/home/shabin/develop/flutter-3.47.5/bin:$PATH"
out="${1:?usage: tool/capture_glass.sh /abs/out/dir [name1,name2]}"
mkdir -p "$out"
args=(--dart-define="CAPTURE_DIR=$out")
if [[ -n "${2:-}" ]]; then args+=(--dart-define="CAPTURE_ONLY=$2"); fi
flutter build linux --release -t lib/spike/glass_capture_main.dart "${args[@]}" >/dev/null
timeout 300 build/linux/x64/release/bundle/dashboard_shakhsi
