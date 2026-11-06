#!/usr/bin/env python3
"""Builds the Apple glass lab page from the extracted Sketch styles.
   python3 build_lab.py <out.html>
Reads ../generated/apple_glass_usage_2026-11.json (tool/extract_apple_glass_usage.py) and lab_template.html."""
import json
import os
import sys

D = os.path.dirname(os.path.abspath(__file__))
d = json.load(open(os.path.join(D, "..", "generated", "apple_glass_usage_2026-11.json"), encoding="utf-8"))
ios = d["ios27"]
out = {}
for mode in ("Light", "Dark"):
    for n in ("Regular - Small", "Regular - Small - Tinted", "Regular - Medium", "Regular - Large"):
        out[f"{mode}/{n}"] = ios["styles"][f"Liquid Glass/{mode}/{n}"]
out["Clear"] = ios["styles"]["Liquid Glass/Clear"]
knobs = [u for u in ios["usages"] if u["page"] == "Toggles"]
for mode in ("Light", "Dark"):
    out[f"Knob/{mode}"] = {"glass": next(u for u in knobs if f"/{mode}/" in u["path"])["glass"], "fills": [], "shadows": []}
page = open(os.path.join(D, "lab_template.html"), encoding="utf-8").read().replace("/*@STYLES@*/", json.dumps(out, ensure_ascii=False))
open(sys.argv[1] if len(sys.argv) > 1 else os.path.join(D, "glass-lab.html"), "w", encoding="utf-8").write(page)
