#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

IOS_SHA256 = "839ecf260025264db9000a4ce23ef2804c33c8d62642a6373ed310858ca64171"
MACOS_SHA256 = "f5aa2f4f319eae66b5eab0bbc0faacb10ce16656457cff528f9810d57ff1354d"
MACOS_ASSETS_SHA256 = "4bbbb036ce008f2213803ad05d7591ed4c0ac009f677a2e1d3d3b315ceb1ce31"

EXPECTED_COUNTS = {
    "ios": {
        "pageCount": 36,
        "swatches": 107,
        "textStyles": 105,
        "layerStyles": 42,
    },
    "macos": {
        "pageCount": 38,
        "swatches": 110,
        "textStyles": 67,
        "layerStyles": 285,
    },
}


def fail(message: str) -> "NoReturn":
    raise SystemExit(f"ERROR: {message}")


def require_map(value: Any, path: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        fail(f"{path} must be a JSON object")
    return value


def require_list(value: Any, path: str) -> list[Any]:
    if not isinstance(value, list):
        fail(f"{path} must be a JSON array")
    return value


def require_str(value: Any, path: str) -> str:
    if not isinstance(value, str) or not value:
        fail(f"{path} must be a non-empty string")
    return value


def require_int(value: Any, path: str) -> int:
    if not isinstance(value, int):
        fail(f"{path} must be an integer")
    return value


def dart_string(value: str) -> str:
    escaped = (
        value.replace("\\", "\\\\")
        .replace("'", "\\'")
        .replace("$", "\\$")
        .replace("\r", "\\r")
        .replace("\n", "\\n")
        .replace("\t", "\\t")
    )
    return f"'{escaped}'"


def source_sha(family: dict[str, Any], path: str) -> str:
    source = require_map(family.get("source"), f"{path}.source")
    return require_str(source.get("sha256"), f"{path}.source.sha256")


def records(
    family: dict[str, Any],
    key: str,
    family_name: str,
) -> list[tuple[str, str]]:
    raw = require_list(family.get(key), f"{family_name}.{key}")
    result: list[tuple[str, str]] = []
    for index, value in enumerate(raw):
        item = require_map(value, f"{family_name}.{key}[{index}]")
        source_id = require_str(
            item.get("sourceId"),
            f"{family_name}.{key}[{index}].sourceId",
        )
        name = require_str(
            item.get("name"),
            f"{family_name}.{key}[{index}].name",
        )
        result.append((source_id, name))

    # Stable ordering independent of incidental JSON collection ordering.
    return sorted(result, key=lambda entry: (entry[1].casefold(), entry[0]))


def emit_entries(name: str, entries: list[tuple[str, str]]) -> list[str]:
    lines = [f"  static const List<AppleSourceEntry> {name} = ["]
    for source_id, label in entries:
        lines.append(
            "    AppleSourceEntry("
            f"sourceId: {dart_string(source_id)}, "
            f"name: {dart_string(label)}"
            "),"
        )
    lines.append("  ];")
    return lines


def build(data: dict[str, Any]) -> str:
    ios = require_map(data.get("ios"), "ios")
    macos = require_map(data.get("macos"), "macos")
    assets = require_map(data.get("macosAssets"), "macosAssets")

    ios_sha = source_sha(ios, "ios")
    macos_sha = source_sha(macos, "macos")
    assets_sha = source_sha(assets, "macosAssets")

    if ios_sha != IOS_SHA256:
        fail(f"iOS source hash mismatch: {ios_sha}")
    if macos_sha != MACOS_SHA256:
        fail(f"macOS source hash mismatch: {macos_sha}")
    if assets_sha != MACOS_ASSETS_SHA256:
        fail(f"macOS assets source hash mismatch: {assets_sha}")

    families = {"ios": ios, "macos": macos}
    extracted: dict[str, dict[str, list[tuple[str, str]]]] = {}

    for family_name, family in families.items():
        expected = EXPECTED_COUNTS[family_name]
        page_count = require_int(
            family.get("pageCount"),
            f"{family_name}.pageCount",
        )
        if page_count != expected["pageCount"]:
            fail(
                f"{family_name}.pageCount mismatch: "
                f"{page_count} != {expected['pageCount']}"
            )

        extracted[family_name] = {}
        for key in ("swatches", "textStyles", "layerStyles"):
            values = records(family, key, family_name)
            if len(values) != expected[key]:
                fail(
                    f"{family_name}.{key} count mismatch: "
                    f"{len(values)} != {expected[key]}"
                )
            extracted[family_name][key] = values

    lines = [
        "// GENERATED FILE — DO NOT EDIT.",
        "// Source: docs/superpowers/references/generated/apple_ui_kit_reference.json",
        "// Generator: tool/generate_apple_source_reference.py",
        "",
        "class AppleSourceEntry {",
        "  const AppleSourceEntry({required this.sourceId, required this.name});",
        "",
        "  final String sourceId;",
        "  final String name;",
        "}",
        "",
        "abstract final class AppleSourceReference {",
        f"  static const String iosSha256 = {dart_string(ios_sha)};",
        f"  static const String macosSha256 = {dart_string(macos_sha)};",
        f"  static const String macosAssetsSha256 = {dart_string(assets_sha)};",
        "",
        f"  static const int iosPageCount = {EXPECTED_COUNTS['ios']['pageCount']};",
        f"  static const int macosPageCount = {EXPECTED_COUNTS['macos']['pageCount']};",
        "",
    ]

    lines += emit_entries("iosSwatches", extracted["ios"]["swatches"])
    lines.append("")
    lines += emit_entries("macosSwatches", extracted["macos"]["swatches"])
    lines.append("")
    lines += emit_entries("iosTextStyles", extracted["ios"]["textStyles"])
    lines.append("")
    lines += emit_entries("macosTextStyles", extracted["macos"]["textStyles"])
    lines.append("")
    lines += emit_entries("iosLayerStyles", extracted["ios"]["layerStyles"])
    lines.append("")
    lines += emit_entries("macosLayerStyles", extracted["macos"]["layerStyles"])
    lines.append("}")
    lines.append("")

    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    data = require_map(json.loads(args.input.read_text()), "root")
    rendered = build(data)

    if args.check:
        if not args.output.is_file():
            print(f"ERROR: generated file missing: {args.output}", file=sys.stderr)
            return 1
        actual = args.output.read_text()
        if actual != rendered:
            print(
                "ERROR: generated Dart reference is stale or non-deterministic",
                file=sys.stderr,
            )
            return 1
        print("GENERATED_DART_CHECK=PASS")
        return 0

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(rendered)
    print(f"GENERATED_DART={args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
