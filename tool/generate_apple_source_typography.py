#!/usr/bin/env python3
import argparse
import json
import re
import sys
from pathlib import Path

IOS_SHA = "839ecf260025264db9000a4ce23ef2804c33c8d62642a6373ed310858ca64171"
MAC_SHA = "f5aa2f4f319eae66b5eab0bbc0faacb10ce16656457cff528f9810d57ff1354d"

PATTERNS = {
    "body": [r"(^|/)Body($|/)", r"\bBody\b"],
    "headline": [r"(^|/)Headline($|/)", r"\bHeadline\b"],
    "title1": [r"(^|/)Title ?1($|/)", r"\bTitle ?1\b"],
}


def walk(obj):
    if isinstance(obj, dict):
        yield obj
        for value in obj.values():
            yield from walk(value)
    elif isinstance(obj, list):
        for value in obj:
            yield from walk(value)


def number_from_names(item, names):
    for obj in walk(item):
        if not isinstance(obj, dict):
            continue
        for name in names:
            value = obj.get(name)
            if isinstance(value, (int, float)) and not isinstance(value, bool):
                return float(value)
    return None


def string_from_names(item, names):
    for obj in walk(item):
        if not isinstance(obj, dict):
            continue
        for name in names:
            value = obj.get(name)
            if isinstance(value, str) and value:
                return value
    return None


def q(value):
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


def nullable_number(value):
    if value is None:
        return "null"
    if value == 0:
        return "0.0"
    if value == 1:
        return "1.0"
    return repr(float(value))


def nullable_string(value):
    return "null" if value is None else q(value)


def pick_style(data, family, role):
    family_data = data[family]
    expected_sha = IOS_SHA if family == "ios" else MAC_SHA

    if family_data["source"]["sha256"] != expected_sha:
        raise SystemExit(f"ERROR: {family} source hash mismatch")

    candidates = []
    for item in family_data["textStyles"]:
        name = item.get("name") or ""
        if not any(re.search(pattern, name, re.I) for pattern in PATTERNS[role]):
            continue

        lowered = name.lower()
        penalty = 0
        for marker in ("italic", "loose", "tight", "bold italic"):
            if marker in lowered:
                penalty += 10
        if "default" not in lowered:
            penalty += 1

        candidates.append((penalty, len(name), name, item))

    if not candidates:
        raise SystemExit(f"ERROR: no {family}/{role} source text style")

    candidates.sort(key=lambda row: (row[0], row[1], row[2]))
    item = candidates[0][3]

    source_id = item.get("sourceId")
    source_name = item.get("name")
    font_size = number_from_names(item, ["fontSize", "size", "font_size"])

    if not source_id or not source_name or font_size is None:
        raise SystemExit(f"ERROR: incomplete {family}/{role} source record")

    return {
        "sourceId": source_id,
        "sourceName": source_name,
        "fontSize": font_size,
        "lineHeight": number_from_names(
            item,
            ["lineHeight", "maximumLineHeight", "minimumLineHeight", "line_height"],
        ),
        "sourcePostScriptName": string_from_names(
            item,
            ["postscriptName", "fontPostscriptName", "fontName"],
        ),
        "sourceWeight": number_from_names(item, ["fontWeight", "weight"]),
    }


def emit(field, record):
    return [
        f"  static const AppleGeneratedTypographyRecord {field} =",
        "      AppleGeneratedTypographyRecord(",
        f"        sourceId: {q(record['sourceId'])},",
        f"        sourceName: {q(record['sourceName'])},",
        f"        fontSize: {nullable_number(record['fontSize'])},",
        f"        lineHeight: {nullable_number(record['lineHeight'])},",
        "        sourcePostScriptName: "
        f"{nullable_string(record['sourcePostScriptName'])},",
        f"        sourceWeight: {nullable_number(record['sourceWeight'])},",
        "      );",
    ]


def render(data):
    records = {}
    for family in ("ios", "macos"):
        for role in ("body", "headline", "title1"):
            records[(family, role)] = pick_style(data, family, role)

    lines = [
        "// GENERATED FILE — DO NOT EDIT.",
        "// Source: docs/superpowers/references/generated/apple_ui_kit_reference.json",
        "// Generator: tool/generate_apple_source_typography.py",
        "",
        "class AppleGeneratedTypographyRecord {",
        "  const AppleGeneratedTypographyRecord({",
        "    required this.sourceId,",
        "    required this.sourceName,",
        "    required this.fontSize,",
        "    required this.lineHeight,",
        "    required this.sourcePostScriptName,",
        "    required this.sourceWeight,",
        "  });",
        "",
        "  final String sourceId;",
        "  final String sourceName;",
        "  final double fontSize;",
        "  final double? lineHeight;",
        "  final String? sourcePostScriptName;",
        "  final double? sourceWeight;",
        "}",
        "",
        "abstract final class AppleSourceTypographyReference {",
    ]

    for family in ("ios", "macos"):
        for role in ("body", "headline", "title1"):
            field = family + role[0].upper() + role[1:]
            lines.extend(emit(field, records[(family, role)]))
            lines.append("")

    lines.extend(["}", ""])
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    rendered = render(json.loads(args.input.read_text()))

    if args.check:
        if not args.output.is_file() or args.output.read_text() != rendered:
            print("ERROR: generated typography reference is stale", file=sys.stderr)
            return 1
        print("GENERATED_TYPOGRAPHY_CHECK=PASS")
        return 0

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(rendered)
    print(f"GENERATED_TYPOGRAPHY_DART={args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
