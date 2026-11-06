#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import sys
import tempfile
import zipfile
from pathlib import Path

IOS_SHA256 = "839ecf260025264db9000a4ce23ef2804c33c8d62642a6373ed310858ca64171"
MACOS_SHA256 = "f5aa2f4f319eae66b5eab0bbc0faacb10ce16656457cff528f9810d57ff1354d"
MACOS_ASSETS_SHA256 = "4bbbb036ce008f2213803ad05d7591ed4c0ac009f677a2e1d3d3b315ceb1ce31"

ROOT = Path(__file__).resolve().parents[1]
EXTRACTOR = ROOT / "tool" / "apple_ui_kit_reference_extractor.py"
GENERATED = (
    ROOT
    / "docs"
    / "superpowers"
    / "references"
    / "generated"
    / "apple_ui_kit_reference.json"
)


def need(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def _load_extractor():
    need(
        EXTRACTOR.is_file(),
        "RED_EXPECTED: apple_ui_kit_reference_extractor.py does not exist yet",
    )
    spec = importlib.util.spec_from_file_location(
        "apple_ui_kit_reference_extractor", EXTRACTOR
    )
    need(spec is not None and spec.loader is not None, "cannot load extractor module")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def run_self_test() -> None:
    module = _load_extractor()

    need(hasattr(module, "SourceFile"), "SourceFile API missing")
    need(hasattr(module, "verify_sha256"), "verify_sha256 API missing")
    need(
        hasattr(module, "extract_sketch_reference"),
        "extract_sketch_reference API missing",
    )
    need(
        hasattr(module, "write_deterministic_json"),
        "write_deterministic_json API missing",
    )

    with tempfile.TemporaryDirectory() as raw_tmp:
        tmp = Path(raw_tmp)
        sketch = tmp / "fixture.sketch"

        document = {
            "_class": "document",
            "foreignSymbols": [],
            "layerStyles": {"objects": []},
            "layerTextStyles": {"objects": []},
        }
        page = {
            "_class": "page",
            "do_objectID": "PAGE-1",
            "name": "Colors",
            "layers": [
                {
                    "_class": "rectangle",
                    "do_objectID": "LAYER-1",
                    "name": "Primary",
                    "frame": {
                        "_class": "rect",
                        "x": 1,
                        "y": 2,
                        "width": 100,
                        "height": 44,
                    },
                    "style": {
                        "_class": "style",
                        "fills": [
                            {
                                "_class": "fill",
                                "isEnabled": True,
                                "fillType": 0,
                                "color": {
                                    "_class": "color",
                                    "alpha": 1,
                                    "red": 0,
                                    "green": 0.5,
                                    "blue": 1,
                                },
                            }
                        ],
                    },
                }
            ],
        }

        with zipfile.ZipFile(sketch, "w", compression=zipfile.ZIP_DEFLATED) as archive:
            archive.writestr("document.json", json.dumps(document))
            archive.writestr("pages/PAGE-1.json", json.dumps(page))
            archive.writestr(
                "meta.json",
                json.dumps(
                    {
                        "app": "com.bohemiancoding.sketch3",
                        "version": 150,
                        "pagesAndArtboards": {
                            "PAGE-1": {"name": "Colors", "artboards": {}}
                        },
                    }
                ),
            )

        digest = hashlib.sha256(sketch.read_bytes()).hexdigest()
        source = module.SourceFile(path=sketch, expected_sha256=digest)
        module.verify_sha256(source)
        extracted = module.extract_sketch_reference(source)

        need(extracted["source"]["sha256"] == digest, "source hash not preserved")
        need(extracted["pages"][0]["name"] == "Colors", "page name not extracted")
        need(
            extracted["componentLayers"][0]["sourceId"] == "LAYER-1",
            "layer source id not preserved",
        )
        need(
            extracted["componentLayers"][0]["pageName"] == "Colors",
            "layer page provenance missing",
        )
        need(
            extracted["componentLayers"][0]["frame"]["width"] == 100,
            "layer frame width not extracted",
        )

        output = tmp / "out.json"
        module.write_deterministic_json(extracted, output)
        first = output.read_bytes()
        module.write_deterministic_json(extracted, output)
        second = output.read_bytes()
        need(first == second, "JSON output is not deterministic")

    print("SELF_TEST=PASS")


def run_generated_reference_check() -> None:
    _load_extractor()
    need(
        GENERATED.is_file(),
        "RED_EXPECTED: generated apple_ui_kit_reference.json does not exist yet",
    )
    data = json.loads(GENERATED.read_text())
    need(data["ios"]["source"]["sha256"] == IOS_SHA256, "iOS source hash mismatch")
    need(data["macos"]["source"]["sha256"] == MACOS_SHA256, "macOS source hash mismatch")
    need(
        data["macosAssets"]["source"]["sha256"] == MACOS_ASSETS_SHA256,
        "macOS asset source hash mismatch",
    )
    print("GENERATED_REFERENCE_CHECK=PASS")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()

    try:
        if args.self_test:
            run_self_test()
        else:
            run_generated_reference_check()
    except AssertionError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
