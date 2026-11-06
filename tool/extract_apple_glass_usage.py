#!/usr/bin/env python3
"""Extract every Liquid Glass style and every place it is used from Apple's iOS/macOS UI kit .sketch files.

    python3 tool/extract_apple_glass_usage.py <iOS kit.sketch> <macOS kit.sketch> <out.json>

The kits are downloaded from Apple Design Resources (sketch.com shares) and kept outside the repository
(~/projects/personal/borj/apple-kits/). Output: shared glass styles (full summarized style) and per-layer
usages (page, layer path, size, corner radii, style name) for both families.
"""
import hashlib
import json
import sys
import zipfile

BLEND = {0: "normal", 1: "darken", 2: "multiply", 3: "colorBurn", 4: "lighten", 5: "screen", 6: "colorDodge", 7: "overlay",
         8: "softLight", 9: "hardLight", 10: "difference", 11: "exclusion", 12: "hue", 13: "saturation", 14: "color",
         15: "luminosity", 16: "plusDarker", 17: "plusLighter"}
CAPSULE = 3.0e38  # Sketch stores "fully rounded" as FLT_MAX


def color(c):
    if not c:
        return None
    rgb = [round(c.get(k, 0) * 255) for k in ("red", "green", "blue")]
    a = c.get("alpha", 1)
    return "#%02X%02X%02X" % tuple(rgb) + ("" if a == 1 else "@%g" % round(a, 4))


def blend(v):
    cs = v.get("contextSettings") or {}
    return BLEND.get(cs.get("blendMode", 0), cs.get("blendMode")), cs.get("opacity", 1)


def radii(rs):
    return ["capsule" if (r or 0) > CAPSULE else r for r in rs] if rs else rs


def glass_of(st):
    for b in st.get("blurs") or ([st["blur"]] if st.get("blur") else []):
        if b and b.get("isEnabled") and b.get("type") == 4:
            return b
    return None


def summarize(st):
    g = glass_of(st)
    if not g:
        return None
    out = {"glass": {k: g.get(k) for k in ("radius", "depth", "distortion", "chromaticAberrationMultiplier", "brightness",
                                           "saturation", "isCustomGlass", "skipLightingEffects", "hasTint", "center") if k in g}}
    fills = []
    for f in st.get("fills") or []:
        if not f.get("isEnabled"):
            continue
        bm, op = blend(f)
        if f.get("fillType", 0) == 0:
            fills.append({"color": color(f.get("color")), "blend": bm, "opacity": op})
        else:
            gr = f.get("gradient") or {}
            fills.append({"gradient": [[s.get("position"), color(s.get("color"))] for s in gr.get("stops", [])],
                          "from": gr.get("from"), "to": gr.get("to"), "gradientType": gr.get("gradientType"), "blend": bm, "opacity": op})
    out["fills"] = fills
    out["borders"] = [{"color": color(b.get("color")), "thickness": b.get("thickness"), "position": b.get("position"), "blend": blend(b)[0]}
                      for b in st.get("borders") or [] if b.get("isEnabled")]
    for key in ("shadows", "innerShadows"):
        out[key] = [{"color": color(s.get("color")), "x": s.get("offsetX"), "y": s.get("offsetY"), "blur": s.get("blurRadius"),
                     "spread": s.get("spread"), "blend": blend(s)[0]} for s in st.get(key) or [] if s.get("isEnabled")]
    co = st.get("corners") or {}
    if co:
        out["corners"] = {"radii": radii(co.get("radii")), "smoothing": co.get("smoothing"), "concentric": co.get("prefersConcentric")}
    out["layerBlend"], out["layerOpacity"] = blend(st)
    return out


def extract(path):
    data = open(path, "rb").read()
    z = zipfile.ZipFile(path)
    meta = json.loads(z.read("meta.json"))
    doc = json.loads(z.read("document.json"))
    shared = {s["do_objectID"]: s for s in (doc.get("layerStyles") or {}).get("objects", [])}
    styles = {s["name"]: summarize(s["value"]) for s in shared.values() if summarize(s["value"])}
    usages = []

    def walk(layer, page, trail):
        here = trail + [layer.get("name", "")]
        s = summarize(layer.get("style") or {})
        if s:
            f = layer.get("frame") or {}
            sid = layer.get("sharedStyleID")
            r = (s.get("corners") or {}).get("radii")
            if not r and layer.get("_class") == "rectangle":
                r = radii([p.get("cornerRadius") for p in layer.get("points") or []])
            usages.append({"page": page.lstrip("\U00100000\U0010ffff").strip(), "path": " / ".join(here), "class": layer.get("_class"),
                           "w": round(f.get("width", 0), 2), "h": round(f.get("height", 0), 2), "radii": r,
                           "style": shared[sid]["name"] if sid in shared else None,
                           "glass": s["glass"] if sid not in shared else None})
        for ch in layer.get("layers") or []:
            walk(ch, page, here)

    for name in sorted(n for n in z.namelist() if n.startswith("pages/")):
        pj = json.loads(z.read(name))
        clean = "".join(ch for ch in pj.get("name", "") if ord(ch) < 0xF0000).strip()
        for l in pj.get("layers") or []:
            walk(l, clean, [])
    return {"source": {"fileName": path.rsplit("/", 1)[-1], "sha256": hashlib.sha256(data).hexdigest(), "sizeBytes": len(data),
                       "sketchApp": meta.get("appVersion")},
            "styles": dict(sorted(styles.items())), "usages": usages}


if __name__ == "__main__":
    ios, mac, out = sys.argv[1:4]
    res = {"schemaVersion": 1, "ios27": extract(ios), "macos27": extract(mac)}
    json.dump(res, open(out, "w", encoding="utf-8"), ensure_ascii=False, indent=1, sort_keys=False)
    for k in ("ios27", "macos27"):
        print(k, len(res[k]["styles"]), "glass styles,", len(res[k]["usages"]), "usages,", res[k]["source"]["sha256"][:16])
