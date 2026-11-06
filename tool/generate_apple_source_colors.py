#!/usr/bin/env python3
import argparse, json, sys
from pathlib import Path

IOS_SHA = "839ecf260025264db9000a4ce23ef2804c33c8d62642a6373ed310858ca64171"
MAC_SHA = "f5aa2f4f319eae66b5eab0bbc0faacb10ce16656457cff528f9810d57ff1354d"

def die(msg):
    raise SystemExit(f"ERROR: {msg}")

def find_rgba(value):
    if isinstance(value, dict):
        if all(k in value for k in ("red","green","blue","alpha")):
            vals = [value[k] for k in ("red","green","blue","alpha")]
            if all(isinstance(v, (int,float)) and not isinstance(v, bool) for v in vals):
                return tuple(float(v) for v in vals)
        for key in sorted(value):
            hit = find_rgba(value[key])
            if hit is not None:
                return hit
    elif isinstance(value, list):
        for item in value:
            hit = find_rgba(item)
            if hit is not None:
                return hit
    return None

def q(s):
    return "'" + s.replace("\\","\\\\").replace("'","\\'").replace("$","\\$") + "'"

def num(v):
    return "0.0" if v == 0 else "1.0" if v == 1 else repr(float(v))

def read_family(data, key, expected_sha):
    fam = data[key]
    sha = fam["source"]["sha256"]
    if sha != expected_sha:
        die(f"{key} source hash mismatch: {sha}")
    out = []
    for i, item in enumerate(fam["swatches"]):
        sid = item.get("sourceId")
        name = item.get("name")
        if not sid or not name:
            die(f"{key}.swatches[{i}] missing sourceId/name")
        rgba = find_rgba(item)
        if rgba is None:
            die(f"{key} swatch {name!r} missing RGBA")
        out.append((sid, name, *rgba))
    return sorted(out, key=lambda x: (x[1].casefold(), x[0]))

def emit(name, rows):
    lines = [f"  static const List<AppleGeneratedSourceColor> {name} = ["]
    for sid, label, r, g, b, a in rows:
        lines += [
            "    AppleGeneratedSourceColor(",
            f"      sourceId: {q(sid)},",
            f"      name: {q(label)},",
            f"      red: {num(r)},",
            f"      green: {num(g)},",
            f"      blue: {num(b)},",
            f"      alpha: {num(a)},",
            "    ),",
        ]
    lines.append("  ];")
    return lines

def render(data):
    ios = read_family(data, "ios", IOS_SHA)
    mac = read_family(data, "macos", MAC_SHA)
    lines = [
        "// GENERATED FILE — DO NOT EDIT.",
        "// Source: docs/superpowers/references/generated/apple_ui_kit_reference.json",
        "",
        "class AppleGeneratedSourceColor {",
        "  const AppleGeneratedSourceColor({",
        "    required this.sourceId, required this.name,",
        "    required this.red, required this.green,",
        "    required this.blue, required this.alpha,",
        "  });",
        "  final String sourceId;",
        "  final String name;",
        "  final double red;",
        "  final double green;",
        "  final double blue;",
        "  final double alpha;",
        "}",
        "",
        "abstract final class AppleSourceColorReference {",
    ]
    lines += emit("iosSwatches", ios)
    lines.append("")
    lines += emit("macosSwatches", mac)
    lines += ["}", ""]
    return "\n".join(lines)

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--input", required=True, type=Path)
    p.add_argument("--output", required=True, type=Path)
    p.add_argument("--check", action="store_true")
    a = p.parse_args()
    rendered = render(json.loads(a.input.read_text()))
    if a.check:
        if not a.output.is_file() or a.output.read_text() != rendered:
            print("ERROR: generated color reference is stale", file=sys.stderr)
            return 1
        print("GENERATED_COLOR_CHECK=PASS")
        return 0
    a.output.parent.mkdir(parents=True, exist_ok=True)
    a.output.write_text(rendered)
    print(f"GENERATED_COLOR_DART={a.output}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
