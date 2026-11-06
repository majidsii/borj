#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
files = {
    "summary": root / (
        "lib/features/finance/application/finance_summary.dart"
    ),
    "service": root / (
        "lib/features/finance/application/"
        "finance_report_service.dart"
    ),
    "preview": root / (
        "lib/features/dashboard/presentation/widgets/"
        "finance_preview_models.dart"
    ),
    "charts": root / (
        "lib/features/dashboard/presentation/widgets/"
        "finance_charts.dart"
    ),
}

for label, path in files.items():
    if not path.is_file():
        raise SystemExit(f"Missing Task 5 GREEN {label}: {path}")

summary = files["summary"].read_text(encoding="utf-8")
service = files["service"].read_text(encoding="utf-8")
preview = files["preview"].read_text(encoding="utf-8")
charts = files["charts"].read_text(encoding="utf-8")

summary_markers = [
    "class FinanceSummary",
    "final class FinanceMonthPoint",
    "final class FinanceCategoryPoint",
    "final class FinanceDayPoint",
]
service_markers = [
    "final class FinanceReportService",
    "FinanceSummary summary({",
    "List<FinanceMonthPoint> trend({",
    "List<FinanceCategoryPoint> categories({",
    "List<FinanceDayPoint> week({",
    "transaction.occurredAtUtc.toLocal()",
    "Money.zeroIRT",
    "Jalali.fromDateTime",
]
preview_markers = [
    "extends FinanceSummary",
    "export 'package:borj/features/finance/"
    "application/finance_summary.dart';",
]
chart_markers = [
    "show FinancePreviewMath;",
    "application/finance_summary.dart';",
]

checks = (
    ("summary", summary, summary_markers),
    ("service", service, service_markers),
    ("preview", preview, preview_markers),
    ("charts", charts, chart_markers),
)

for label, source, markers in checks:
    missing = [marker for marker in markers if marker not in source]
    if missing:
        raise SystemExit(
            f"Missing Task 5 GREEN {label} markers: "
            + ", ".join(missing)
        )

print("Persistence Task 5 GREEN source contract verified.")
