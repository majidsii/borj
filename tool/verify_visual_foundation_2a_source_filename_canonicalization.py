#!/usr/bin/env python3
from __future__ import annotations
import importlib.util
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXTRACTOR = ROOT / "tool" / "apple_ui_kit_reference_extractor.py"
IOS_SHA = "839ecf260025264db9000a4ce23ef2804c33c8d62642a6373ed310858ca64171"
MAC_SHA = "f5aa2f4f319eae66b5eab0bbc0faacb10ce16656457cff528f9810d57ff1354d"
ASSETS_SHA = "4bbbb036ce008f2213803ad05d7591ed4c0ac009f677a2e1d3d3b315ceb1ce31"

def need(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(message)

def load_extractor():
    spec = importlib.util.spec_from_file_location("apple_ui_kit_reference_extractor", EXTRACTOR)
    need(spec is not None and spec.loader is not None, "cannot load extractor")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module

def main() -> None:
    module = load_extractor()
    resolver = getattr(module, "_canonical_source_file_name", None)
    need(callable(resolver), "RED_EXPECTED: canonical source filename resolver is missing")

    cases = (
        (IOS_SHA, "Apple iOS 27 UI Kit.sketch", "Apple iOS 27 UI Kit.sketch"),
        (MAC_SHA, "Apple macOS 27 UI Kit(1).sketch", "Apple macOS 27 UI Kit.sketch"),
        (ASSETS_SHA, "apple-macos-27-ui-kit_assets_2026-06-23_v12(1).zip",
         "apple-macos-27-ui-kit_assets_2026-06-23_v12.zip"),
    )
    for digest, local_name, expected in cases:
        actual = resolver(digest, local_name)
        need(actual == expected, f"canonical name mismatch: {actual!r} != {expected!r}")

    need(
        resolver("unknown-sha", "local-copy.sketch") == "local-copy.sketch",
        "unknown hashes must preserve supplied filename",
    )

    print("APPLE_UI_KIT_CANONICAL_SOURCE_FILENAME=PASS")
    print("KNOWN_HASHES_CANONICALIZED=PASS")
    print("UNKNOWN_HASH_FALLBACK=PRESERVE_LOCAL_NAME")

if __name__ == "__main__":
    main()
