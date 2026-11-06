import 'dart:io';

import 'package:borj/core/database/legacy_database_file_migration.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// Opens the persistent, cross-platform dashboard database.
///
/// On native Flutter platforms, drift_flutter stores this connection in a
/// file named `borj.sqlite` in the application documents folder. Files left by
/// the pre-Borj name (`dashboard_shakhsi.sqlite`) are renamed first.
DatabaseConnection openDashboardDatabase() {
  return driftDatabase(
    name: 'borj',
    native: DriftNativeOptions(
      databaseDirectory: () async {
        final directory = await getApplicationDocumentsDirectory();
        moveLegacyDatabaseFiles(Directory(directory.path));
        return directory;
      },
    ),
  );
}
