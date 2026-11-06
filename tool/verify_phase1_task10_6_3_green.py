#!/usr/bin/env python3
from pathlib import Path
import re
import sys

paths = {
    "contract": Path(
        "lib/core/notifications/"
        "linux_notification_delivery_command_factory.dart"
    ),
    "path_source": Path(
        "lib/core/notifications/linux_executable_path_source.dart"
    ),
    "dart_io": Path(
        "lib/core/notifications/"
        "dart_io_linux_executable_path_source.dart"
    ),
    "factory": Path(
        "lib/core/notifications/"
        "resolved_linux_notification_delivery_command_factory.dart"
    ),
    "scheduler": Path(
        "lib/core/notifications/"
        "linux_systemd_notification_scheduler.dart"
    ),
    "path_test": Path(
        "test/core/notifications/"
        "linux_executable_path_source_test.dart"
    ),
    "factory_test": Path(
        "test/core/notifications/"
        "resolved_linux_notification_delivery_command_factory_test.dart"
    ),
    "model_test": Path(
        "test/core/notifications/"
        "linux_systemd_notification_scheduler_model_test.dart"
    ),
}

for label, path in paths.items():
    if not path.is_file():
        print(f"ERROR: missing Task 10.6.3 {label}: {path}")
        sys.exit(1)

contract = paths["contract"].read_text(encoding="utf-8")
path_source = paths["path_source"].read_text(encoding="utf-8")
dart_io = paths["dart_io"].read_text(encoding="utf-8")
factory = paths["factory"].read_text(encoding="utf-8")
scheduler = paths["scheduler"].read_text(encoding="utf-8")
tests = "\n".join(
    (
        paths["path_test"].read_text(encoding="utf-8"),
        paths["factory_test"].read_text(encoding="utf-8"),
        paths["model_test"].read_text(encoding="utf-8"),
    )
)

required_contract = (
    "Future<LinuxSystemdNotificationUnit> create(",
    "NotificationRequest request",
)
missing_contract = [token for token in required_contract if token not in contract]
if missing_contract:
    print(f"ERROR: async factory contract incomplete: {missing_contract}")
    sys.exit(1)
if re.search(
    r"(?<!Future<)LinuxSystemdNotificationUnit\s+create\(",
    contract,
):
    print("ERROR: synchronous factory signature remains in the contract.")
    sys.exit(1)

required_path_source = (
    "enum LinuxExecutablePathFailure",
    "resolutionFailed",
    "invalidPath",
    "verificationFailed",
    "notFound",
    "notRegularFile",
    "notExecutable",
    "final class LinuxExecutablePathException",
    "abstract interface class LinuxExecutablePathSource",
    "abstract interface class LinuxExecutableFileVerifier",
    "final class LinuxExecutableFileStatus",
    "final class ValidatedLinuxExecutablePathSource",
    "value.trim() == value",
    "value.startsWith('/')",
    r"!value.contains('\u0000')",
    r"!value.contains('\n')",
    r"!value.contains('\r')",
    "await verifier.status(path)",
)
missing_path = [
    token for token in required_path_source if token not in path_source
]
if missing_path:
    print(f"ERROR: executable path validation incomplete: {missing_path}")
    sys.exit(1)

required_dart_io = (
    "import 'dart:io';",
    "Platform.resolvedExecutable",
    "File(path).stat()",
    "FileSystemEntityType.file",
    "FileSystemEntityType.notFound",
    "(stat.mode & 0x49) != 0",
)
missing_dart_io = [token for token in required_dart_io if token not in dart_io]
if missing_dart_io:
    print(f"ERROR: dart:io executable adapters incomplete: {missing_dart_io}")
    sys.exit(1)

required_factory = (
    "final class ResolvedLinuxNotificationDeliveryCommandFactory",
    "implements LinuxNotificationDeliveryCommandFactory",
    "Future<LinuxSystemdNotificationUnit> create(",
    "final executablePath = await _resolveExecutablePath();",
    "linuxNotificationDeliveryFlag",
    "request.scheduleId",
    "String? _resolvedExecutablePath;",
    "Future<String>? _resolutionInFlight;",
    "if (current != null)",
    "final path = await _executablePathSource.resolve();",
    "_resolvedExecutablePath = path;",
    "_resolutionInFlight = null;",
)
missing_factory = [token for token in required_factory if token not in factory]
if missing_factory:
    print(f"ERROR: resolved factory incomplete: {missing_factory}")
    sys.exit(1)

if factory.count("request.title") or factory.count("request.body"):
    print("ERROR: resolved command factory embeds private notification content.")
    sys.exit(1)
if "request.payload" in factory or "request.owner" in factory:
    print("ERROR: resolved command factory embeds payload or owner data.")
    sys.exit(1)

# Scheduler must keep command creation inside the typed step boundary so both
# synchronous and asynchronous failures map to commandFactoryFailed.
if scheduler.count("action: () => _commandFactory.create(request)") != 2:
    print(
        "ERROR: scheduler does not route both command-factory calls through "
        "the existing typed async step boundary."
    )
    sys.exit(1)

# Scan every Dart test/support file to ensure no old synchronous implementer
# remains after the interface migration.
test_root = Path("test")
for path in test_root.rglob("*.dart"):
    text = path.read_text(encoding="utf-8")
    if "implements LinuxNotificationDeliveryCommandFactory" not in text:
        continue
    if re.search(
        r"(?<!Future<)LinuxSystemdNotificationUnit\s+create\(",
        text,
    ):
        print(f"ERROR: synchronous factory implementer remains: {path}")
        sys.exit(1)

if "final actual = await factory.create(request);" not in tests:
    print("ERROR: direct factory model test was not migrated to await.")
    sys.exit(1)
if "await factory.create(_request());" not in tests:
    print("ERROR: direct factory failure test was not migrated to await.")
    sys.exit(1)

required_tests = (
    "returns an absolute path when file verification is unavailable",
    "rejects unsafe path code units",
    "LinuxExecutablePathFailure.invalidPath",
    "LinuxExecutablePathFailure.notFound",
    "LinuxExecutablePathFailure.notRegularFile",
    "LinuxExecutablePathFailure.notExecutable",
    "wraps source failure with its original cause and stack",
    "wraps verifier failure without exposing path or message",
    "creates the exact shell-free hidden delivery command",
    "resolves and validates the executable only once",
    "shares one in-flight executable resolution",
    "does not embed private request content in command fields",
    "preserves executable source failure and stack trace",
)
missing_tests = [token for token in required_tests if token not in tests]
if missing_tests:
    print(f"ERROR: Gate 10.6.3 GREEN coverage incomplete: {missing_tests}")
    sys.exit(1)

# The pure validation and factory layers must remain independent of dart:io;
# only the dedicated production adapter introduced by this Gate imports it.
for label, text in (("path source", path_source), ("factory", factory), ("contract", contract)):
    if "import 'dart:io';" in text:
        print(f"ERROR: unexpected dart:io dependency in {label}.")
        sys.exit(1)

combined = "\n".join((contract, path_source, dart_io, factory, tests))
for forbidden in (
    "Process.start",
    "Process.run",
    "Directory.systemTemp",
    "Future.delayed(",
    "TODO",
    "FIXME",
    "UnimplementedError",
):
    if forbidden in combined:
        print(f"ERROR: Task 10.6.3 contains forbidden behavior: {forbidden}")
        sys.exit(1)


# Preserve the Task 10.5 regression fixtures that are required by the current
# cleanup and reconciliation behavior. The Gate 10.6.3 package must not
# restore stale pre-hotfix tests while migrating factories to async.
regression_paths = {
    "schedule": Path(
        "test/core/notifications/"
        "linux_systemd_notification_scheduler_schedule_test.dart"
    ),
    "inventory": Path(
        "test/core/notifications/"
        "linux_systemd_notification_scheduler_reconcile_inventory_test.dart"
    ),
    "rollback": Path(
        "test/core/notifications/"
        "linux_systemd_notification_scheduler_schedule_rollback_test.dart"
    ),
    "cancel": Path(
        "test/core/notifications/"
        "linux_systemd_notification_scheduler_cancel_test.dart"
    ),
}
for label, path in regression_paths.items():
    if not path.is_file():
        print(f"ERROR: missing Task 10.5 regression test: {path}")
        sys.exit(1)

schedule_regression = regression_paths["schedule"].read_text(encoding="utf-8")
inventory_regression = regression_paths["inventory"].read_text(encoding="utf-8")
rollback_regression = regression_paths["rollback"].read_text(encoding="utf-8")
cancel_regression = regression_paths["cancel"].read_text(encoding="utf-8")

required_due_fixture = (
    "scheduleId: 'task-due-private'",
    "final names = LinuxSystemdUnitNames.forScheduleKey(",
    "..processRunner.enqueueSuccess()",
    "..processRunner.enqueueStatus(",
    "activeState: 'inactive'",
    "subState: 'dead'",
    "unitFileState: 'disabled'",
)
missing_due = [
    token for token in required_due_fixture
    if token not in schedule_regression
]
if missing_due:
    print(f"ERROR: due-private cleanup fixture regressed: {missing_due}")
    sys.exit(1)

required_inventory = (
    "linux_systemd_notification_scheduler_exception.dart",
    "final exception = actual!;",
    "exception.failure",
    "exception.scheduleId",
)
missing_inventory = [
    token for token in required_inventory
    if token not in inventory_regression
]
if missing_inventory:
    print(f"ERROR: reconciliation inventory fixture regressed: {missing_inventory}")
    sys.exit(1)
if "actual?.failure" in inventory_regression or "actual?.scheduleId" in inventory_regression:
    print("ERROR: analyzer-unsafe nullable inventory assertions returned.")
    sys.exit(1)

def _test_block(source: str, title: str) -> str:
    title_index = source.find(title)
    if title_index < 0:
        print(f"ERROR: regression test not found: {title}")
        sys.exit(1)

    test_start = source.rfind("test(", 0, title_index)
    if test_start < 0:
        print(f"ERROR: test boundary not found for: {title}")
        sys.exit(1)

    next_test = source.find("\n    test(", title_index + len(title))
    next_group = source.find("\n  group(", title_index + len(title))
    candidates = [
        index
        for index in (next_test, next_group)
        if index >= 0
    ]
    test_end = min(candidates) if candidates else len(source)
    return source[test_start:test_end]


def _require_ordered_operation_tokens(
    source: str,
    *,
    title: str,
    tokens: tuple[str, ...],
) -> None:
    block = _test_block(source, title)

    if "harness.operations" not in block:
        print(
            "ERROR: regression test no longer checks the shared operation "
            f"trace: {title}"
        )
        sys.exit(1)

    if "orderedEquals" not in block:
        print(
            "ERROR: regression test no longer uses orderedEquals: "
            f"{title}"
        )
        sys.exit(1)

    cursor = 0
    missing: list[str] = []
    for token in tokens:
        literal = f"'{token}'"
        position = block.find(literal, cursor)
        if position < 0:
            missing.append(token)
            continue
        cursor = position + len(literal)

    if missing:
        print(
            "ERROR: regression operation trace is missing or reordered for "
            f"{title}: {missing}"
        )
        sys.exit(1)

    if "harness.operations,\n        isEmpty" in block or (
        "harness.operations, isEmpty" in block
    ):
        print(
            "ERROR: regression test incorrectly expects an empty shared "
            f"operation trace: {title}"
        )
        sys.exit(1)


_require_ordered_operation_tokens(
    rollback_regression,
    title="command factory failure does not begin or roll back units",
    tokens=(
        "registry.load",
        "factory.create",
    ),
)
_require_ordered_operation_tokens(
    rollback_regression,
    title="render identity failure does not begin or roll back units",
    tokens=(
        "registry.load",
        "factory.create",
    ),
)
_require_ordered_operation_tokens(
    rollback_regression,
    title="begin install failure does not run rollback",
    tokens=(
        "registry.load",
        "factory.create",
        "unitStore.beginInstall",
    ),
)
_require_ordered_operation_tokens(
    cancel_regression,
    title="begin remove failure performs no rollback or driver mutation",
    tokens=(
        "registry.load",
        "unitStore.beginRemove",
    ),
)

inventory_orphan_block = _test_block(
    inventory_regression,
    "removes orphan complete pair absent from registry and desired state",
)
required_orphan_assertion = "_names(orphanId).baseName"
if required_orphan_assertion not in inventory_orphan_block:
    print(
        "ERROR: orphan inventory cleanup must assert the discovered hashed "
        "baseName because no registry schedule ID exists."
    )
    sys.exit(1)
if "<String>[orphanId]" in inventory_orphan_block:
    print(
        "ERROR: orphan inventory cleanup regressed to the unavailable "
        "schedule ID."
    )
    sys.exit(1)


analyzer_cleanup_paths = {
    "path_source": Path(
        "lib/core/notifications/linux_executable_path_source.dart"
    ),
    "resolved_factory": Path(
        "lib/core/notifications/"
        "resolved_linux_notification_delivery_command_factory.dart"
    ),
    "cancel_test": Path(
        "test/core/notifications/"
        "linux_systemd_notification_scheduler_cancel_test.dart"
    ),
    "concurrency_test": Path(
        "test/core/notifications/"
        "linux_systemd_notification_scheduler_concurrency_test.dart"
    ),
    "model_test": Path(
        "test/core/notifications/"
        "linux_systemd_notification_scheduler_model_test.dart"
    ),
    "inventory_test": Path(
        "test/core/notifications/"
        "linux_systemd_notification_scheduler_reconcile_inventory_test.dart"
    ),
    "rollback_test": Path(
        "test/core/notifications/"
        "linux_systemd_notification_scheduler_schedule_rollback_test.dart"
    ),
    "schedule_test": Path(
        "test/core/notifications/"
        "linux_systemd_notification_scheduler_schedule_test.dart"
    ),
    "factory_test": Path(
        "test/core/notifications/"
        "resolved_linux_notification_delivery_command_factory_test.dart"
    ),
}
analyzer_cleanup = {
    name: path.read_text(encoding="utf-8")
    for name, path in analyzer_cleanup_paths.items()
}

for name in ("path_source", "resolved_factory"):
    if "ignore_for_file: prefer_initializing_formals" not in analyzer_cleanup[name]:
        print(
            "ERROR: intentional public-name/private-field constructor "
            f"initialization is undocumented in {name}."
        )
        sys.exit(1)

for name in ("cancel_test", "rollback_test"):
    text = analyzer_cleanup[name]
    if "this.stderr = ''" in text or "result.stderr" in text:
        print(f"ERROR: unused scripted-runner stderr remains in {name}.")
        sys.exit(1)

if "actual!.operation" in analyzer_cleanup["concurrency_test"]:
    print("ERROR: unnecessary non-null assertion remains in concurrency test.")
    sys.exit(1)

if (
    "linux_notification_delivery_command_factory.dart"
    in analyzer_cleanup["model_test"]
):
    print("ERROR: unused command-factory import remains in model test.")
    sys.exit(1)

if "final exception = actual!;" in analyzer_cleanup["inventory_test"]:
    print("ERROR: unnecessary non-null assertion remains in inventory test.")
    sys.exit(1)

if (
    "linux_systemd_notification_scheduler_exception.dart"
    in analyzer_cleanup["schedule_test"]
):
    print("ERROR: unused scheduler-exception import remains in schedule test.")
    sys.exit(1)

factory_imports = [
    line
    for line in analyzer_cleanup["factory_test"].splitlines()
    if line.startswith("import 'package:borj/")
]
if factory_imports != sorted(factory_imports):
    print("ERROR: resolved factory test package imports are not sorted.")
    sys.exit(1)


print(
    "OK: Task 10.6.3 GREEN upgrades the delivery command factory to an async "
    "contract, validates absolute trim-stable NUL/CR/LF-safe executable paths, "
    "optionally verifies regular executable files through an isolated dart:io "
    "adapter, preserves privacy-safe typed failures, caches and shares one "
    "in-flight successful resolution, emits only executable plus hidden flag "
    "and schedule ID, keeps both scheduler call sites inside typed async steps, "
    "and migrates every Task 10.5 factory fake and direct test to await."
)
