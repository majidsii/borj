#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path

RELEASE_ID = "app.borj"
DEBUG_ID = f"{RELEASE_ID}.dev"


def replace_required(path: Path, pattern: str, replacement: str) -> None:
    content = path.read_text(encoding="utf-8")
    updated, count = re.subn(pattern, replacement, content)
    if count == 0:
        raise RuntimeError(f"Expected identifier pattern was not found in {path}")
    path.write_text(updated, encoding="utf-8")


def configure_android(app_dir: Path) -> None:
    gradle = app_dir / "android/app/build.gradle.kts"
    replace_required(
        gradle,
        r'namespace\s*=\s*"[^"]+"',
        f'namespace = "{RELEASE_ID}"',
    )
    replace_required(
        gradle,
        r'applicationId\s*=\s*"[^"]+"',
        f'applicationId = "{RELEASE_ID}"',
    )
    content = gradle.read_text(encoding="utf-8")
    debug_block = '''\n        getByName("debug") {\n            applicationIdSuffix = ".dev"\n        }'''
    marker = "buildTypes {"
    if "applicationIdSuffix" not in content:
        content = content.replace(marker, marker + debug_block, 1)
        gradle.write_text(content, encoding="utf-8")


def configure_apple(app_dir: Path) -> None:
    for relative in (
        "ios/Runner.xcodeproj/project.pbxproj",
        "macos/Runner.xcodeproj/project.pbxproj",
    ):
        path = app_dir / relative
        content = path.read_text(encoding="utf-8")
        content = re.sub(
            r"PRODUCT_BUNDLE_IDENTIFIER = [^;]+;",
            f"PRODUCT_BUNDLE_IDENTIFIER = {RELEASE_ID};",
            content,
        )
        path.write_text(content, encoding="utf-8")

    config = app_dir / "macos/Runner/Configs/AppInfo.xcconfig"
    if config.exists():
        content = config.read_text(encoding="utf-8")
        content = re.sub(
            r"PRODUCT_BUNDLE_IDENTIFIER\s*=.*",
            f"PRODUCT_BUNDLE_IDENTIFIER = {RELEASE_ID}",
            content,
        )
        config.write_text(content, encoding="utf-8")


def main() -> int:
    app_dir = Path(sys.argv[1]).resolve()
    configure_android(app_dir)
    configure_apple(app_dir)
    print(f"Configured native release identifier: {RELEASE_ID}")
    print(f"Configured Android debug identifier: {DEBUG_ID}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
