#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import sys
from collections import defaultdict
from pathlib import Path
from typing import Any, NoReturn

IOS_SHA256 = "839ecf260025264db9000a4ce23ef2804c33c8d62642a6373ed310858ca64171"
MACOS_SHA256 = "f5aa2f4f319eae66b5eab0bbc0faacb10ce16656457cff528f9810d57ff1354d"

SIZE_CODE_RE = re.compile(r"^\d+\s+(Mn|Sm|Rg|Lg|XL)(?:\b|$)")
EXPLICIT_SIZE_LABELS = {"Small", "Large"}
APPEARANCES = {"Light", "Dark"}
STATE_LABELS = {
    "Idle",
    "Clicked",
    "Disabled",
    "Enabled",
    "On",
    "Off",
    "Active",
    "Inactive",
    "Empty",
    "Value",
    "Typing",
}

DIRECT_GEOMETRY_KEYS = {
    "cornerRadius",
    "fixedRadius",
    "spacing",
    "padding",
    "inset",
    "horizontalInset",
    "verticalInset",
    "topInset",
    "bottomInset",
    "leftInset",
    "rightInset",
}

FORBIDDEN_EFFECT_RE = re.compile(
    r"(blur|shadow|saturat|bright|distort|depth|opacity|glass|"
    r"fill|color|border|stroke)",
    re.I,
)

COMPONENT_ORDER = {
    "button": 0,
    "searchField": 1,
    "textField": 2,
    "segmentedControl": 3,
    "toggle": 4,
}


def fail(message: str) -> NoReturn:
    raise SystemExit(f"ERROR: {message}")


def is_number(value: Any) -> bool:
    return isinstance(value, (int, float)) and not isinstance(value, bool)


def source_hash(family: dict[str, Any], family_name: str) -> str:
    source = family.get("source")
    if not isinstance(source, dict):
        fail(f"{family_name}.source missing")

    value = source.get("sha256")
    if not isinstance(value, str) or not value:
        fail(f"{family_name}.source.sha256 missing")

    return value


def classify_component(source_name: str) -> str | None:
    segments = [segment.strip() for segment in source_name.split("/")]

    if "Segmented Controls" in segments or "Segmented Control" in segments:
        return "segmentedControl"

    if "Search Fields" in segments or "Search Field" in segments:
        return "searchField"

    if (
        "Text Fields" in segments
        or "Text Field" in segments
        or any(segment.startswith("Input Field") for segment in segments)
    ):
        return "textField"

    if "Toggle" in segments:
        return "toggle"

    if "Buttons" in segments:
        return "button"

    return None


def parse_size_label(segments: list[str]) -> str | None:
    for segment in segments:
        match = SIZE_CODE_RE.match(segment)
        if match:
            return match.group(1)

        if segment in EXPLICIT_SIZE_LABELS:
            return segment

    return None


def parse_appearance(segments: list[str]) -> str | None:
    matches = [segment for segment in segments if segment in APPEARANCES]

    if not matches:
        return None

    unique = sorted(set(matches))
    if len(unique) != 1:
        fail(f"ambiguous appearance labels in source path: {segments!r}")

    return unique[0]


def parse_state_labels(segments: list[str]) -> list[str]:
    labels = set()

    for segment in segments:
        for label in STATE_LABELS:
            if re.search(rf"(?<![A-Za-z]){re.escape(label)}(?![A-Za-z])", segment):
                labels.add(label)

    return sorted(labels)


def extract_geometry(item: dict[str, Any]) -> dict[str, float]:
    geometry: dict[str, float] = {}

    frame = item.get("frame")
    if isinstance(frame, dict):
        width = frame.get("width")
        height = frame.get("height")

        if is_number(width):
            geometry["frame.width"] = float(width)

        if is_number(height):
            geometry["frame.height"] = float(height)

    for key in sorted(DIRECT_GEOMETRY_KEYS):
        value = item.get(key)
        if is_number(value):
            geometry[key] = float(value)

    for key in geometry:
        if FORBIDDEN_EFFECT_RE.search(key):
            fail(f"forbidden effect value classified as metric geometry: {key}")

    return geometry


def geometry_key(geometry: dict[str, float]) -> tuple[tuple[str, float], ...]:
    return tuple(sorted(geometry.items()))


def provenance_sort_key(entry: dict[str, Any]) -> tuple[str, str]:
    return (
        entry["sourceName"].casefold(),
        entry["sourceId"],
    )


def collect_source_records(
    data: dict[str, Any],
    family_name: str,
    expected_sha256: str,
) -> list[dict[str, Any]]:
    family = data.get(family_name)
    if not isinstance(family, dict):
        fail(f"missing family: {family_name}")

    actual_hash = source_hash(family, family_name)
    if actual_hash != expected_sha256:
        fail(
            f"{family_name} source hash mismatch: "
            f"expected={expected_sha256} actual={actual_hash}"
        )

    component_layers = family.get("componentLayers")
    if not isinstance(component_layers, list):
        fail(f"{family_name}.componentLayers missing")

    records: list[dict[str, Any]] = []

    for item in component_layers:
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

        component = classify_component(source_name)
        if component is None:
            continue

        geometry = extract_geometry(item)
        if not geometry:
            continue

        segments = [segment.strip() for segment in source_name.split("/")]

        records.append(
            {
                "component": component,
                "sizeLabel": parse_size_label(segments),
                "geometry": geometry,
                "provenance": {
                    "sourceId": source_id,
                    "sourceName": source_name,
                    "appearance": parse_appearance(segments),
                    "stateLabels": parse_state_labels(segments),
                },
            }
        )

    if not records:
        fail(f"no metric source records classified for {family_name}")

    return records


def deduplicate(records: list[dict[str, Any]]) -> list[dict[str, Any]]:
    groups: dict[
        tuple[str, str | None, tuple[tuple[str, float], ...]],
        list[dict[str, Any]],
    ] = defaultdict(list)

    for record in records:
        key = (
            record["component"],
            record["sizeLabel"],
            geometry_key(record["geometry"]),
        )
        groups[key].append(record["provenance"])

    variants: list[dict[str, Any]] = []

    for (component, size_label, geometry_items), provenance in groups.items():
        unique_by_id: dict[str, dict[str, Any]] = {}

        for entry in provenance:
            source_id = entry["sourceId"]
            existing = unique_by_id.get(source_id)

            if existing is not None and existing != entry:
                fail(f"conflicting provenance for sourceId={source_id}")

            unique_by_id[source_id] = entry

        retained = sorted(unique_by_id.values(), key=provenance_sort_key)

        variants.append(
            {
                "component": component,
                "sizeLabel": size_label,
                "geometry": dict(geometry_items),
                "provenance": retained,
            }
        )

    variants.sort(
        key=lambda row: (
            COMPONENT_ORDER[row["component"]],
            "" if row["sizeLabel"] is None else row["sizeLabel"],
            tuple(sorted(row["geometry"].items())),
            tuple(
                (entry["sourceName"].casefold(), entry["sourceId"])
                for entry in row["provenance"]
            ),
        )
    )

    return variants


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


def dart_nullable_string(value: str | None) -> str:
    if value is None:
        return "null"
    return dart_string(value)


def dart_number(value: float) -> str:
    if value == 0:
        return "0.0"
    if value == 1:
        return "1.0"
    return repr(float(value))


def emit_provenance(entry: dict[str, Any], indent: str) -> list[str]:
    lines = [
        f"{indent}AppleGeneratedMetricProvenance(",
        f"{indent}  sourceId: {dart_string(entry['sourceId'])},",
        f"{indent}  sourceName: {dart_string(entry['sourceName'])},",
        f"{indent}  appearance: {dart_nullable_string(entry['appearance'])},",
        f"{indent}  stateLabels: [",
    ]

    for label in entry["stateLabels"]:
        lines.append(f"{indent}    {dart_string(label)},")

    lines.extend(
        [
            f"{indent}  ],",
            f"{indent}),",
        ]
    )

    return lines


def emit_variants(
    field_name: str,
    variants: list[dict[str, Any]],
) -> list[str]:
    lines = [
        f"  static const List<AppleGeneratedMetricVariant> {field_name} = ["
    ]

    for variant in variants:
        lines.extend(
            [
                "    AppleGeneratedMetricVariant(",
                f"      component: {dart_string(variant['component'])},",
                f"      sizeLabel: {dart_nullable_string(variant['sizeLabel'])},",
                "      geometry: {",
            ]
        )

        for key, value in sorted(variant["geometry"].items()):
            lines.append(
                f"        {dart_string(key)}: {dart_number(value)},"
            )

        lines.extend(
            [
                "      },",
                "      provenance: [",
            ]
        )

        for entry in variant["provenance"]:
            lines.extend(emit_provenance(entry, "        "))

        lines.extend(
            [
                "      ],",
                "    ),",
            ]
        )

    lines.append("  ];")
    return lines


def render(data: dict[str, Any]) -> str:
    ios_records = collect_source_records(data, "ios", IOS_SHA256)
    macos_records = collect_source_records(data, "macos", MACOS_SHA256)

    ios_variants = deduplicate(ios_records)
    macos_variants = deduplicate(macos_records)

    lines = [
        "// GENERATED FILE — DO NOT EDIT.",
        "// Source: docs/superpowers/references/generated/apple_ui_kit_reference.json",
        "// Generator: tool/generate_apple_source_metrics.py",
        "",
        "class AppleGeneratedMetricProvenance {",
        "  const AppleGeneratedMetricProvenance({",
        "    required this.sourceId,",
        "    required this.sourceName,",
        "    required this.appearance,",
        "    required this.stateLabels,",
        "  });",
        "",
        "  final String sourceId;",
        "  final String sourceName;",
        "  final String? appearance;",
        "  final List<String> stateLabels;",
        "}",
        "",
        "class AppleGeneratedMetricVariant {",
        "  const AppleGeneratedMetricVariant({",
        "    required this.component,",
        "    required this.sizeLabel,",
        "    required this.geometry,",
        "    required this.provenance,",
        "  });",
        "",
        "  final String component;",
        "  final String? sizeLabel;",
        "  final Map<String, double> geometry;",
        "  final List<AppleGeneratedMetricProvenance> provenance;",
        "}",
        "",
        "abstract final class AppleSourceMetricReference {",
    ]

    lines.extend(emit_variants("iosVariants", ios_variants))
    lines.append("")
    lines.extend(emit_variants("macosVariants", macos_variants))
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
        if not args.output.is_file():
            print(
                f"ERROR: generated metric reference missing: {args.output}",
                file=sys.stderr,
            )
            return 1

        if args.output.read_text() != rendered:
            print(
                "ERROR: generated metric reference is stale",
                file=sys.stderr,
            )
            return 1

        print("GENERATED_METRIC_CHECK=PASS")
        return 0

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(rendered)
    print(f"GENERATED_METRIC_DART={args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
