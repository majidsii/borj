import 'dart:io';

import 'package:borj/core/notifications/dart_io_linux_systemd_file_system.dart';
import 'package:borj/core/notifications/linux_systemd_file_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DartIoLinuxSystemdFileSystem', () {
    late Directory root;
    late DartIoLinuxSystemdFileSystem fileSystem;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('dashboard-systemd-fs-');
      fileSystem = const DartIoLinuxSystemdFileSystem();
    });

    tearDown(() async {
      if (await root.exists()) {
        await root.delete(recursive: true);
      }
    });

    test('creates nested directories recursively', () async {
      final nested = '${root.path}/a/b/c';

      await fileSystem.createDirectory(nested);

      expect(await Directory(nested).exists(), isTrue);
    });

    test('typeOf returns missing for an absent path', () async {
      expect(
        await fileSystem.typeOf('${root.path}/missing.service'),
        LinuxSystemdEntryType.missing,
      );
    });

    test('typeOf returns regularFile for a file', () async {
      final path = '${root.path}/unit.service';
      await File(path).writeAsString('unit');

      expect(await fileSystem.typeOf(path), LinuxSystemdEntryType.regularFile);
    });

    test('typeOf returns directory for a directory', () async {
      final path = '${root.path}/nested';
      await Directory(path).create();

      expect(await fileSystem.typeOf(path), LinuxSystemdEntryType.directory);
    });

    test('typeOf detects a symbolic link without following it', () async {
      final target = '${root.path}/target.service';
      final link = '${root.path}/link.service';
      await File(target).writeAsString('target');
      await Link(link).create(target);

      expect(await fileSystem.typeOf(link), LinuxSystemdEntryType.symbolicLink);
    });

    test('writes and reads bytes exactly', () async {
      final path = '${root.path}/unit.service';
      final bytes = <int>[0, 1, 2, 127, 128, 255];

      await fileSystem.writeBytes(path, bytes);

      expect(await fileSystem.readBytes(path), bytes);
    });

    test('writeBytes replaces existing contents', () async {
      final path = '${root.path}/unit.service';
      await File(path).writeAsString('old');

      await fileSystem.writeBytes(path, <int>[110, 101, 119]);

      expect(await File(path).readAsString(), 'new');
    });

    test('rename moves bytes to the destination', () async {
      final source = '${root.path}/source.tmp';
      final destination = '${root.path}/unit.service';
      await File(source).writeAsBytes(<int>[1, 2, 3]);

      await fileSystem.rename(source, destination);

      expect(await File(source).exists(), isFalse);
      expect(await File(destination).readAsBytes(), <int>[1, 2, 3]);
    });

    test('deleteFile removes a regular file', () async {
      final path = '${root.path}/unit.service';
      await File(path).writeAsString('unit');

      await fileSystem.deleteFile(path);

      expect(await File(path).exists(), isFalse);
    });

    test('deleteFile succeeds when the path is missing', () async {
      await expectLater(
        fileSystem.deleteFile('${root.path}/missing.service'),
        completes,
      );
    });

    test('deleteFile rejects a symbolic link', () async {
      final target = '${root.path}/target.service';
      final link = '${root.path}/link.service';
      await File(target).writeAsString('target');
      await Link(link).create(target);

      await expectLater(
        fileSystem.deleteFile(link),
        throwsA(isA<LinuxSystemdUnsafeEntryException>()),
      );

      expect(await Link(link).exists(), isTrue);
      expect(await File(target).readAsString(), 'target');
    });

    test('deleteFile rejects a directory', () async {
      final path = '${root.path}/unit.service';
      await Directory(path).create();

      await expectLater(
        fileSystem.deleteFile(path),
        throwsA(isA<LinuxSystemdUnsafeEntryException>()),
      );

      expect(await Directory(path).exists(), isTrue);
    });

    test('readMode returns exact POSIX permission bits', () async {
      final path = '${root.path}/unit.service';
      await File(path).writeAsString('unit');
      await fileSystem.chmod(path, 0x180);

      expect(await fileSystem.readMode(path), 0x180);
    });

    test('readMode rejects a symbolic link', () async {
      final target = '${root.path}/target.service';
      final link = '${root.path}/link.service';
      await File(target).writeAsString('target');
      await Link(link).create(target);

      await expectLater(
        fileSystem.readMode(link),
        throwsA(isA<LinuxSystemdUnsafeEntryException>()),
      );
    });

    test('chmod applies exact 0644 permissions', () async {
      final path = '${root.path}/unit.service';
      await File(path).writeAsString('unit');

      await fileSystem.chmod(path, 0x1A4);

      final stat = await FileStat.stat(path);
      expect(stat.mode & 0x1FF, 0x1A4);
    });

    test('chmod rejects unsupported permission bits', () async {
      final path = '${root.path}/unit.service';
      await File(path).writeAsString('unit');

      await expectLater(fileSystem.chmod(path, 0x1000), throwsArgumentError);
    });
  });
}
