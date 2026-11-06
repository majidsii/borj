import 'package:borj/core/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

AppDatabase openTestDatabase() {
  return AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
}
