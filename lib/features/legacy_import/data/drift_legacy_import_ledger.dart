import 'package:borj/core/database/app_database.dart';
import 'package:borj/features/legacy_import/domain/legacy_snapshot.dart';

abstract interface class LegacyImportLedger {
  Future<Set<String>> importedIds(LegacyEntityType type);

  Future<void> record({
    required LegacyEntityType type,
    required LegacySourceKind sourceKind,
    required String v1Id,
    required String v2Id,
    required DateTime importedAtUtc,
    required String sourceSha256,
  });

  Future<bool> hasAnyRecords();
}

final class DriftLegacyImportLedger implements LegacyImportLedger {
  const DriftLegacyImportLedger(this._database);

  final AppDatabase _database;

  @override
  Future<Set<String>> importedIds(LegacyEntityType type) async {
    final rows = await (_database.select(
      _database.legacyImportRows,
    )..where((row) => row.entityType.equals(type.storageValue))).get();
    return <String>{for (final row in rows) row.v1Id};
  }

  @override
  Future<void> record({
    required LegacyEntityType type,
    required LegacySourceKind sourceKind,
    required String v1Id,
    required String v2Id,
    required DateTime importedAtUtc,
    required String sourceSha256,
  }) async {
    await _database
        .into(_database.legacyImportRows)
        .insert(
          LegacyImportRowsCompanion.insert(
            sourceKind: sourceKind.storageValue,
            entityType: type.storageValue,
            v1Id: v1Id,
            v2Id: v2Id,
            importedAtUtc: importedAtUtc,
            sourceSha256: sourceSha256,
          ),
        );
  }

  @override
  Future<bool> hasAnyRecords() async {
    final row = await _database
        .customSelect(
          'SELECT COUNT(*) AS total FROM legacy_imports',
          readsFrom: {_database.legacyImportRows},
        )
        .getSingle();
    return row.read<int>('total') > 0;
  }
}
