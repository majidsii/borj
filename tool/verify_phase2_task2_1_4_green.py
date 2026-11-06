#!/usr/bin/env python3
from pathlib import Path
import re
import subprocess
import sys

interface_path = Path('lib/features/tasks/domain/task_repository.dart')
repository_path = Path('lib/features/tasks/data/drift_task_repository.dart')
test_path = Path('test/features/tasks/data/drift_task_repository_test.dart')
panel_test_path = Path(
    'test/features/dashboard/tasks_panel_persistence_test.dart'
)
database_path = Path('lib/core/database/app_database.dart')

for label, path in (
    ('repository interface', interface_path),
    ('Drift repository', repository_path),
    ('repository test', test_path),
    ('panel repository fake', panel_test_path),
    ('database schema', database_path),
):
    if not path.is_file():
        print(f'ERROR: missing Gate 2.1.4 {label}: {path}')
        sys.exit(1)

interface = interface_path.read_text(encoding='utf-8')
repository = repository_path.read_text(encoding='utf-8')
test = test_path.read_text(encoding='utf-8')
panel_test = panel_test_path.read_text(encoding='utf-8')
database = database_path.read_text(encoding='utf-8')

required_interface = (
    "import 'package:borj/features/tasks/domain/task_status.dart';",
    'Stream<List<TaskItem>> watchByStatus(TaskStatus status);',
    'Future<TaskItem?> getById(String id);',
)
missing = [token for token in required_interface if token not in interface]
if missing:
    print(f'ERROR: repository interface contract incomplete: {missing}')
    sys.exit(1)

required_repository = (
    'Stream<List<TaskItem>> watchByStatus(TaskStatus status)',
    'row.status.equals(status.storageValue)',
    'OrderingTerm.asc(row.positionInStatus)',
    'Future<TaskItem?> getById(String id)',
    'getSingleOrNull()',
    'return row == null ? null : _taskFromRow(row);',
    'return _database.transaction(() async {',
    'COALESCE(MAX(display_number), 0) + 1 AS next_display_number',
    'SELECT COUNT(*)',
    'WHERE status = ?',
    'Variable<String>(task.status.storageValue)',
    "'next_display_number'",
    "allocation.read<int>('next_position')",
    'displayNumber: nextDisplayNumber',
    'positionInStatus: nextPosition',
    'TaskStatus.parseStorage(row.status)',
    'displayNumber: row.displayNumber',
    'positionInStatus: row.positionInStatus',
    'canceledAtUtc: row.canceledAtUtc?.toUtc()',
)
missing = [token for token in required_repository if token not in repository]
if missing:
    print(f'ERROR: Drift repository Gate 2.1.4 contract incomplete: {missing}')
    sys.exit(1)

create_match = re.search(
    r'Future<void> create\(TaskItem task\).*?\n  }\n\n  @override',
    repository,
    flags=re.DOTALL,
)
if create_match is None:
    print('ERROR: create implementation could not be isolated.')
    sys.exit(1)
create_block = create_match.group(0)
if 'insert(_companionFromTask(task))' in create_block:
    print('ERROR: create still trusts caller display number and position.')
    sys.exit(1)

update_match = re.search(
    r'Future<void> update\(TaskItem task\).*?\n  }\n\n  @override',
    repository,
    flags=re.DOTALL,
)
if update_match is None:
    print('ERROR: update implementation could not be isolated.')
    sys.exit(1)
update_block = update_match.group(0)
for forbidden in ('displayNumber:', 'createdAtUtc:'):
    if forbidden in update_block:
        print(f'ERROR: update mutates immutable task field: {forbidden}')
        sys.exit(1)

required_tests = (
    'watchAll orders workflow status then status-local position',
    'watchByStatus filters and orders one status',
    'getById returns an exact task and null for a missing id',
    'create allocates display numbers and status positions',
    'expect(items.map((item) => item.displayNumber).toList(), <int>[1, 2])',
    'delete then create advances the display number',
    'expect(created!.displayNumber, 3)',
    'update persists editable fields and preserves display number',
    'reorder changes positions without changing display numbers',
    'file restart preserves and advances display numbers',
)
missing = [token for token in required_tests if token not in test]
if missing:
    print(f'ERROR: repository test coverage incomplete: {missing}')
    sys.exit(1)

required_fake = (
    'Stream<List<TaskItem>> watchByStatus(TaskStatus status)',
    'Future<TaskItem?> getById(String id)',
    'final nextPosition = _items',
    'displayNumber: nextDisplayNumber',
    'positionInStatus: nextPosition',
)
missing = [token for token in required_fake if token not in panel_test]
if missing:
    print(f'ERROR: panel TaskRepository fake is incomplete: {missing}')
    sys.exit(1)

if re.search(
    r'final\s+nextDisplayNumber\s*=\s*_items\.fold<int>\s*\(',
    panel_test,
) is None:
    print(
        'ERROR: panel TaskRepository fake does not derive the next '
        'display number from existing items.'
    )
    sys.exit(1)

if 'int get schemaVersion => 3;' not in database:
    print('ERROR: Gate 2.1.4 must remain on schema version 3.')
    sys.exit(1)

result = subprocess.run(
    ('git', 'diff', '--check'),
    check=False,
    text=True,
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
)
if result.returncode != 0:
    print(f'ERROR: git diff --check failed:\n{result.stdout.rstrip()}')
    sys.exit(1)

print(
    'OK: Gate 2.1.4 GREEN adds status-filtered streams and exact lookup, '
    'maps every schema-v3 task field, allocates display numbers and '
    'status-local positions inside one transaction, ignores caller numbering '
    'on create, preserves immutable numbering on update/reorder/restart, '
    'updates the current panel repository fake, and keeps schema version 3.'
)
