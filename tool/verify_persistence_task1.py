#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]

required_files = [
    ROOT / 'lib/core/database/database_connection.dart',
    ROOT / 'lib/core/database/app_database.dart',
    ROOT / 'test/support/test_database.dart',
    ROOT / 'test/core/database/app_database_test.dart',
    ROOT / 'pubspec.yaml',
]

missing = [str(path.relative_to(ROOT)) for path in required_files if not path.is_file()]
if missing:
    raise SystemExit('Missing Task 1 files:\n- ' + '\n- '.join(missing))

pubspec = (ROOT / 'pubspec.yaml').read_text(encoding='utf-8')
for marker in (
    'drift: ^2.34.2',
    'drift_flutter: ^0.3.1',
    'drift_dev: ^2.34.2',
    'sqlite3: ^3.1.6',
):
    if marker not in pubspec:
        raise SystemExit(f'Missing pubspec marker: {marker}')

database = (ROOT / 'lib/core/database/app_database.dart').read_text(encoding='utf-8')
for marker in (
    "part 'app_database.g.dart';",
    "String get tableName => 'tasks';",
    "String get tableName => 'finance_transactions';",
    "String get tableName => 'debts';",
    "String get tableName => 'debt_payments';",
    "String get tableName => 'installment_plans';",
    "String get tableName => 'installment_payments';",
    'onDelete: KeyAction.cascade',
    'planId, installmentNumber',
    'int get schemaVersion => 1;',
    "PRAGMA foreign_keys = ON",
):
    if marker not in database:
        raise SystemExit(f'Missing database contract marker: {marker}')

if 'double' in database:
    raise SystemExit('Database schema must not store finance values as double.')

connection = (ROOT / 'lib/core/database/database_connection.dart').read_text(
    encoding='utf-8'
)
if "driftDatabase(name: 'borj')" not in connection:
    raise SystemExit('Persistent database name is not borj.')

if '--generated' in sys.argv:
    generated = ROOT / 'lib/core/database/app_database.g.dart'
    if not generated.is_file() or generated.stat().st_size == 0:
        raise SystemExit(
            'Generated Drift file is missing. Run build_runner before verification.'
        )
    print('Persistence Task 1 source and generated contract verified.')
else:
    print('Persistence Task 1 source contract verified.')
