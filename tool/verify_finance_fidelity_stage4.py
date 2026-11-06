#!/usr/bin/env python3
from __future__ import annotations

import re
from pathlib import Path

APP = Path(__file__).resolve().parents[1]

required_files = [
    APP / "lib/features/dashboard/presentation/widgets/finance_panel.dart",
    APP / "lib/features/dashboard/presentation/widgets/finance_charts.dart",
    APP / "lib/features/dashboard/presentation/widgets/finance_preview_models.dart",
    APP / "test/features/dashboard/finance_panel_test.dart",
]

for path in required_files:
    if not path.is_file() or path.stat().st_size == 0:
        raise SystemExit(f"Missing or empty Stage 4 file: {path.relative_to(APP)}")

panel = required_files[0].read_text(encoding="utf-8")
charts = required_files[1].read_text(encoding="utf-8")
models = required_files[2].read_text(encoding="utf-8")
tests = required_files[3].read_text(encoding="utf-8")

markers = {
    "finance panel title": "'مالی من'",
    "four summary cards": "finance-summary-debt",
    "expense type": "finance-type-expense",
    "income type": "finance-type-income",
    "debt type": "finance-type-debt",
    "installment type": "finance-type-installment",
    "submit action": "finance-submit",
    "debts and installments": "'بدهی‌ها و اقساط'",
    "recent transactions": "'تراکنش‌های اخیر'",
}
for description, marker in markers.items():
    if marker not in panel:
        raise SystemExit(f"Missing Stage 4 marker for {description}: {marker}")

for marker in [
    "finance-trend-chart",
    "finance-donut-chart",
    "finance-week-chart",
    "CustomPainter",
]:
    if marker not in charts:
        raise SystemExit(f"Missing finance chart marker: {marker}")

for marker in [
    "FinancePreviewTotals",
    "FinancePreviewDebt",
    "FinancePreviewInstallment",
    "Jalali.fromDateTime",
    "parseAmount",
]:
    if marker not in models:
        raise SystemExit(f"Missing finance model marker: {marker}")

for marker in [
    "adds an expense",
    "partially paid debt",
    "installment plan",
    "original three finance chart surfaces",
]:
    if marker not in tests:
        raise SystemExit(f"Missing finance test marker: {marker}")

package_import = re.compile(
    r"import\s+'package:borj/([^']+)';"
)
for source in required_files:
    text = source.read_text(encoding="utf-8")
    for relative in package_import.findall(text):
        target = APP / "lib" / relative
        if not target.is_file():
            raise SystemExit(
                "Missing internal import "
                f"{relative} referenced by {source.relative_to(APP)}"
            )

print("Finance fidelity stage 4 contract verified.")
