#!/usr/bin/env python3
from pathlib import Path

path = Path(
    "lib/features/dashboard/presentation/widgets/"
    "finance_charts.dart"
)
source = path.read_text(encoding="utf-8")

old = (
    "import 'package:borj/features/dashboard/"
    "presentation/widgets/finance_preview_models.dart';\n"
)
new = (
    "import 'package:borj/features/dashboard/"
    "presentation/widgets/finance_preview_models.dart' "
    "show FinancePreviewMath;\n"
    "import 'package:borj/features/finance/"
    "application/finance_summary.dart';\n"
)

if new in source:
    print("Finance chart imports already updated.")
elif old in source:
    path.write_text(
        source.replace(old, new, 1),
        encoding="utf-8",
    )
    print("Finance chart imports updated.")
else:
    raise SystemExit(
        "Expected finance_charts.dart import was not found."
    )
