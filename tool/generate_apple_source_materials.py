#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any, NoReturn

IOS_SHA = "839ecf260025264db9000a4ce23ef2804c33c8d62642a6373ed310858ca64171"
MAC_SHA = "f5aa2f4f319eae66b5eab0bbc0faacb10ce16656457cff528f9810d57ff1354d"


def fail(message: str) -> NoReturn:
    raise SystemExit(f"ERROR: {message}")


def is_custom_glass(value: Any) -> bool:
    if value is True:
        return True
    return type(value) in (int, float) and value == 1


def numeric_values(obj: Any, prefix: str = "") -> dict[str, float]:
    out: dict[str, float] = {}

    if isinstance(obj, dict):
        for key in sorted(obj):
            value = obj[key]
            path = f"{prefix}.{key}" if prefix else key

            if key == "isCustomGlass":
                continue

            if isinstance(value, (int, float)) and not isinstance(value, bool):
                out[path] = float(value)
            elif isinstance(value, (dict, list)):
                out.update(numeric_values(value, path))

    elif isinstance(obj, list):
        for index, value in enumerate(obj):
            path = f"{prefix}[{index}]"
            if isinstance(value, (dict, list)):
                out.update(numeric_values(value, path))

    return out


def dart_string(value: str) -> str:
    return (
        "'"
        + value.replace("\\", "\\\\")
        .replace("'", "\\'")
        .replace("$", "\\$")
        .replace("\r", "\\r")
        .replace("\n", "\\n")
        .replace("\t", "\\t")
        + "'"
    )


def dart_number(value: float) -> str:
    if value == 0:
        return "0.0"
    if value == 1:
        return "1.0"
    return repr(float(value))


def collect_family(
    data: dict[str, Any],
    family_name: str,
    expected_sha: str,
) -> list[dict[str, Any]]:
    family = data.get(family_name)
    if not isinstance(family, dict):
        fail(f"{family_name} missing")

    source = family.get("source")
    if not isinstance(source, dict) or source.get("sha256") != expected_sha:
        fail(f"{family_name} source hash mismatch")

    layer_styles = family.get("layerStyles")
    if not isinstance(layer_styles, list):
        fail(f"{family_name}.layerStyles missing")

    rows: list[dict[str, Any]] = []

    for item_index, item in enumerate(layer_styles):
        if not isinstance(item, dict):
            continue

        source_id = item.get("sourceId")
        source_name = item.get("name")
        if not (
            isinstance(source_id, str)
            and source_id
            and isinstance(source_name, str)
            and source_name
        ):
            continue

        style = item.get("style")
        if not isinstance(style, dict):
            continue

        blurs = style.get("blurs")
        if not isinstance(blurs, list):
            continue

        enabled_blurs = [
            blur
            for blur in blurs
            if isinstance(blur, dict)
            and is_custom_glass(blur.get("isCustomGlass"))
        ]

        if not enabled_blurs:
            continue

        values: dict[str, float] = {}
        for enabled_index, blur in enumerate(enabled_blurs):
            extracted = numeric_values(blur)
            for key, value in extracted.items():
                values[f"style.blurs[{enabled_index}].{key}"] = value

        if not values:
            fail(
                f"{family_name}.layerStyles[{item_index}] "
                f"{source_name!r} is custom glass but has no numeric payload"
            )

        rows.append(
            {
                "sourceId": source_id,
                "sourceName": source_name,
                "sourceValues": values,
            }
        )

    rows.sort(
        key=lambda row: (
            row["sourceName"].casefold(),
            row["sourceId"],
        )
    )

    if not rows:
        fail(f"no enabled custom-glass styles found for {family_name}")

    return rows


def emit_records(field: str, rows: list[dict[str, Any]]) -> list[str]:
    lines = [f"  static const List<AppleGeneratedMaterialStyle> {field} = ["]

    for row in rows:
        lines.extend(
            [
                "    AppleGeneratedMaterialStyle(",
                f"      sourceId: {dart_string(row['sourceId'])},",
                f"      sourceName: {dart_string(row['sourceName'])},",
                "      sourceValues: {",
            ]
        )

        for key, value in sorted(row["sourceValues"].items()):
            lines.append(
                f"        {dart_string(key)}: {dart_number(value)},"
            )

        lines.extend(
            [
                "      },",
                "    ),",
            ]
        )

    lines.append("  ];")
    return lines


def render(data: dict[str, Any]) -> str:
    ios = collect_family(data, "ios", IOS_SHA)
    macos = collect_family(data, "macos", MAC_SHA)

    lines = [
        "// GENERATED FILE — DO NOT EDIT.",
        "// Source: docs/superpowers/references/generated/apple_ui_kit_reference.json",
        "// Generator: tool/generate_apple_source_materials.py",
        "",
        "class AppleGeneratedMaterialStyle {",
        "  const AppleGeneratedMaterialStyle({",
        "    required this.sourceId,",
        "    required this.sourceName,",
        "    required this.sourceValues,",
        "  });",
        "",
        "  final String sourceId;",
        "  final String sourceName;",
        "  final Map<String, double> sourceValues;",
        "}",
        "",
        "abstract final class AppleSourceMaterialReference {",
    ]

    lines.extend(emit_records("iosCustomGlassStyles", ios))
    lines.append("")
    lines.extend(emit_records("macosCustomGlassStyles", macos))
    lines.extend(["}", ""])

    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    data = json.loads(args.input.read_text())
    if not isinstance(data, dict):
        fail("root JSON must be an object")

    rendered = render(data)

    if args.check:
        if not args.output.is_file() or args.output.read_text() != rendered:
            print("ERROR: generated material reference is stale", file=sys.stderr)
            return 1
        print("GENERATED_MATERIAL_CHECK=PASS")
        return 0

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(rendered)
    print(f"GENERATED_MATERIAL_DART={args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
