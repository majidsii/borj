import 'dart:io';

import 'package:borj/core/database/legacy_database_file_migration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('borj-db-file-move-');
  });

  tearDown(() {
    directory.deleteSync(recursive: true);
  });

  File file(String name) => File('${directory.path}/$name');

  const suffixes = <String>['', '-wal', '-shm', '-journal'];

  test('moves the legacy file and its siblings when borj.sqlite is absent', () {
    for (final suffix in suffixes) {
      file('dashboard_shakhsi.sqlite$suffix').writeAsStringSync('old$suffix');
    }

    moveLegacyDatabaseFiles(directory);

    for (final suffix in suffixes) {
      expect(file('dashboard_shakhsi.sqlite$suffix').existsSync(), isFalse);
      expect(file('borj.sqlite$suffix').readAsStringSync(), 'old$suffix');
    }
  });

  test('moves only the siblings that exist', () {
    file('dashboard_shakhsi.sqlite').writeAsStringSync('old');
    file('dashboard_shakhsi.sqlite-wal').writeAsStringSync('wal');

    moveLegacyDatabaseFiles(directory);

    expect(file('borj.sqlite').readAsStringSync(), 'old');
    expect(file('borj.sqlite-wal').readAsStringSync(), 'wal');
    expect(file('borj.sqlite-shm').existsSync(), isFalse);
    expect(file('borj.sqlite-journal').existsSync(), isFalse);
  });

  test('moves nothing and deletes nothing when both databases exist', () {
    file('dashboard_shakhsi.sqlite').writeAsStringSync('old');
    file('dashboard_shakhsi.sqlite-wal').writeAsStringSync('old-wal');
    file('borj.sqlite').writeAsStringSync('new');

    moveLegacyDatabaseFiles(directory);

    expect(file('dashboard_shakhsi.sqlite').readAsStringSync(), 'old');
    expect(file('dashboard_shakhsi.sqlite-wal').readAsStringSync(), 'old-wal');
    expect(file('borj.sqlite').readAsStringSync(), 'new');
    expect(file('borj.sqlite-wal').existsSync(), isFalse);
  });

  test('does nothing when neither database exists', () {
    moveLegacyDatabaseFiles(directory);

    expect(directory.listSync(), isEmpty);
  });

  test('does nothing when only borj.sqlite exists', () {
    file('borj.sqlite').writeAsStringSync('new');

    moveLegacyDatabaseFiles(directory);

    expect(file('borj.sqlite').readAsStringSync(), 'new');
    expect(directory.listSync(), hasLength(1));
  });
}
