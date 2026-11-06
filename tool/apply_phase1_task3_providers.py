#!/usr/bin/env python3

from pathlib import Path

path = Path("lib/core/providers/persistence_providers.dart")

if not path.is_file():
    raise SystemExit(f"File not found: {path}")

source = path.read_text(encoding="utf-8")
lines = source.splitlines()

required_imports = [
    "import 'package:borj/core/notifications/noop_notification_scheduler.dart';",
    "import 'package:borj/core/notifications/notification_coordinator.dart';",
    "import 'package:borj/core/notifications/notification_scheduler.dart';",
]

existing_imports = {
    line.strip()
    for line in lines
    if line.strip().startswith("import ")
}

missing_imports = [
    import_line
    for import_line in required_imports
    if import_line not in existing_imports
]

if missing_imports:
    import_indexes = [
        index
        for index, line in enumerate(lines)
        if line.strip().startswith("import ")
    ]

    if not import_indexes:
        raise SystemExit("No Dart import section was found.")

    insertion_index = import_indexes[-1] + 1
    lines[insertion_index:insertion_index] = missing_imports

source = "\n".join(lines).rstrip() + "\n"

scheduler_provider = """
final notificationSchedulerProvider =
    Provider<NotificationScheduler>((ref) {
  return const NoopNotificationScheduler();
});
"""

coordinator_provider = """
final notificationCoordinatorProvider =
    Provider<NotificationCoordinator>((ref) {
  return NotificationCoordinator(
    repository: ref.watch(notificationScheduleRepositoryProvider),
    scheduler: ref.watch(notificationSchedulerProvider),
  );
});
"""

if "final notificationSchedulerProvider" not in source:
    source += "\n" + scheduler_provider.strip() + "\n"

if "final notificationCoordinatorProvider" not in source:
    source += "\n" + coordinator_provider.strip() + "\n"

path.write_text(source, encoding="utf-8")

print("Phase 1 Task 3 providers applied successfully.")
