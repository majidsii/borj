import 'dart:io';

import 'package:borj/core/notifications/dart_io_linux_systemd_file_system.dart';
import 'package:borj/core/notifications/linux_systemd_file_system.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_linux_systemd_file_system.dart';

void main() {
  group('DartIoLinuxSystemdFileSystem registry extensions', () {
    late Directory root;
    late DartIoLinuxSystemdFileSystem fileSystem;

    setUp(() async {
      root = await Directory.systemTemp.createTemp(
        'dashboard-systemd-registry-fs-',
      );
      fileSystem = const DartIoLinuxSystemdFileSystem();
    });

    tearDown(() async {
      if (await root.exists()) {
        await root.delete(recursive: true);
      }
    });

    test('fileLength returns the exact regular-file byte count', () async {
      final path = '${root.path}/registry.json';
      await File(path).writeAsBytes(const <int>[0, 1, 2, 127, 128, 255]);

      expect(await fileSystem.fileLength(path), 6);
    });

    test(
      'fileLength observes replacements instead of cached metadata',
      () async {
        final path = '${root.path}/registry.json';
        await File(path).writeAsBytes(const <int>[1]);

        expect(await fileSystem.fileLength(path), 1);

        await File(path).writeAsBytes(List<int>.filled(37, 7), flush: true);

        expect(await fileSystem.fileLength(path), 37);
      },
    );

    test('fileLength rejects a missing path', () async {
      await _expectUnsafe(
        () => fileSystem.fileLength('${root.path}/missing.json'),
        LinuxSystemdEntryType.missing,
      );
    });

    test('fileLength rejects a directory', () async {
      final path = '${root.path}/registry.json';
      await Directory(path).create();

      await _expectUnsafe(
        () => fileSystem.fileLength(path),
        LinuxSystemdEntryType.directory,
      );
    });

    test('fileLength rejects a symbolic link without following it', () async {
      final target = '${root.path}/target.json';
      final link = '${root.path}/registry.json';
      await File(target).writeAsBytes(List<int>.filled(19, 1));
      await Link(link).create(target);

      await _expectUnsafe(
        () => fileSystem.fileLength(link),
        LinuxSystemdEntryType.symbolicLink,
      );

      expect(await File(target).length(), 19);
    });

    test('listNames returns sorted direct child basenames only', () async {
      final directory = '${root.path}/user';
      await Directory('$directory/nested').create(recursive: true);
      await File('$directory/z.timer').writeAsString('z');
      await File('$directory/a.service').writeAsString('a');
      await File('$directory/nested/hidden.timer').writeAsString('hidden');

      expect(
        await fileSystem.listNames(directory),
        orderedEquals(<String>['a.service', 'nested', 'z.timer']),
      );
    });

    test(
      'listNames does not follow a direct child directory symlink',
      () async {
        final directory = '${root.path}/user';
        final outside = '${root.path}/outside';
        await Directory(directory).create();
        await Directory(outside).create();
        await File('$outside/hidden.timer').writeAsString('hidden');
        await Link('$directory/linked-directory').create(outside);
        await File('$directory/a.service').writeAsString('a');

        expect(
          await fileSystem.listNames(directory),
          orderedEquals(<String>['a.service', 'linked-directory']),
        );
      },
    );

    test(
      'listNames returns an empty immutable list for a missing directory',
      () async {
        final names = await fileSystem.listNames('${root.path}/missing');

        expect(names, isEmpty);
        expect(() => names.add('unsafe'), throwsUnsupportedError);
      },
    );

    test('listNames returns an immutable sorted list', () async {
      final directory = '${root.path}/user';
      await Directory(directory).create();
      await File('$directory/b.timer').writeAsString('b');
      await File('$directory/a.timer').writeAsString('a');

      final names = await fileSystem.listNames(directory);

      expect(names, orderedEquals(<String>['a.timer', 'b.timer']));
      expect(() => names.add('c.timer'), throwsUnsupportedError);
    });

    test('listNames rejects a regular file as the root', () async {
      final path = '${root.path}/user';
      await File(path).writeAsString('not a directory');

      await _expectUnsafe(
        () => fileSystem.listNames(path),
        LinuxSystemdEntryType.regularFile,
      );
    });

    test(
      'listNames rejects a symbolic-link root without following it',
      () async {
        final target = '${root.path}/target';
        final link = '${root.path}/user';
        await Directory(target).create();
        await File('$target/hidden.timer').writeAsString('hidden');
        await Link(link).create(target);

        await _expectUnsafe(
          () => fileSystem.listNames(link),
          LinuxSystemdEntryType.symbolicLink,
        );

        expect(await File('$target/hidden.timer').readAsString(), 'hidden');
      },
    );
  });

  group('FakeLinuxSystemdFileSystem registry extensions', () {
    const directory = '/config/systemd/user';
    late FakeLinuxSystemdFileSystem fileSystem;

    setUp(() {
      fileSystem = FakeLinuxSystemdFileSystem();
    });

    test('fileLength records and returns exact bytes', () async {
      const path = '$directory/registry.json';
      fileSystem.seedFile(path, const <int>[0, 1, 2, 3, 255], mode: 0x180);

      expect(await fileSystem.fileLength(path), 5);
      expect(fileSystem.operations, <String>['fileLength:$path']);
    });

    for (final entry in <({String name, LinuxSystemdEntryType type})>[
      (name: 'missing', type: LinuxSystemdEntryType.missing),
      (name: 'directory', type: LinuxSystemdEntryType.directory),
      (name: 'symbolic-link', type: LinuxSystemdEntryType.symbolicLink),
      (name: 'other', type: LinuxSystemdEntryType.other),
    ]) {
      test('fileLength rejects fake ${entry.name} entries', () async {
        final path = '$directory/${entry.name}';

        switch (entry.type) {
          case LinuxSystemdEntryType.missing:
            break;
          case LinuxSystemdEntryType.directory:
            fileSystem.seedDirectory(path);
          case LinuxSystemdEntryType.symbolicLink:
            fileSystem.seedSymlink(path, '$directory/target');
          case LinuxSystemdEntryType.other:
            fileSystem.seedOther(path);
          case LinuxSystemdEntryType.regularFile:
            fail('The table must contain only unsafe entry types.');
        }

        await _expectUnsafe(() => fileSystem.fileLength(path), entry.type);
      });
    }

    test('fileLength supports deterministic injected failures', () async {
      const path = '$directory/registry.json';
      final error = StateError('file-length-failure');
      fileSystem.seedFile(path, const <int>[1], mode: 0x180);
      fileSystem.failNext('fileLength:$path', error: error);

      await expectLater(fileSystem.fileLength(path), throwsA(same(error)));
      expect(fileSystem.operations, <String>['fileLength:$path']);
    });

    test('listNames derives sorted unique direct children only', () async {
      fileSystem.seedDirectory(directory);
      fileSystem.seedFile('$directory/b.timer', const <int>[1], mode: 0x180);
      fileSystem.seedFile('$directory/a.service', const <int>[1], mode: 0x180);
      fileSystem.seedDirectory('$directory/nested');
      fileSystem.seedFile('$directory/nested/hidden.timer', const <int>[
        1,
      ], mode: 0x180);

      expect(
        await fileSystem.listNames(directory),
        orderedEquals(<String>['a.service', 'b.timer', 'nested']),
      );
      expect(fileSystem.operations, <String>['listNames:$directory']);
    });

    test(
      'listNames includes child symlink names without following them',
      () async {
        fileSystem.seedDirectory(directory);
        fileSystem.seedSymlink('$directory/linked-directory', '/outside');
        fileSystem.seedFile('/outside/hidden.timer', const <int>[
          1,
        ], mode: 0x180);

        expect(await fileSystem.listNames(directory), <String>[
          'linked-directory',
        ]);
      },
    );

    test(
      'listNames returns an immutable empty list for missing root',
      () async {
        final names = await fileSystem.listNames(directory);

        expect(names, isEmpty);
        expect(() => names.add('unsafe'), throwsUnsupportedError);
        expect(fileSystem.operations, <String>['listNames:$directory']);
      },
    );

    for (final entry in <({String name, LinuxSystemdEntryType type})>[
      (name: 'regular-file', type: LinuxSystemdEntryType.regularFile),
      (name: 'symbolic-link', type: LinuxSystemdEntryType.symbolicLink),
      (name: 'other', type: LinuxSystemdEntryType.other),
    ]) {
      test('listNames rejects fake ${entry.name} roots', () async {
        switch (entry.type) {
          case LinuxSystemdEntryType.regularFile:
            fileSystem.seedFile(directory, const <int>[1], mode: 0x180);
          case LinuxSystemdEntryType.symbolicLink:
            fileSystem.seedSymlink(directory, '/target');
          case LinuxSystemdEntryType.other:
            fileSystem.seedOther(directory);
          case LinuxSystemdEntryType.missing:
          case LinuxSystemdEntryType.directory:
            fail('The table must contain only unsafe root types.');
        }

        await _expectUnsafe(() => fileSystem.listNames(directory), entry.type);
      });
    }

    test('listNames supports deterministic injected failures', () async {
      final error = StateError('list-names-failure');
      fileSystem.seedDirectory(directory);
      fileSystem.failNext('listNames:$directory', error: error);

      await expectLater(fileSystem.listNames(directory), throwsA(same(error)));
      expect(fileSystem.operations, <String>['listNames:$directory']);
    });
  });
}

Future<void> _expectUnsafe(
  Future<Object?> Function() action,
  LinuxSystemdEntryType expectedType,
) async {
  await expectLater(
    action(),
    throwsA(
      isA<LinuxSystemdUnsafeEntryException>()
          .having((error) => error.entryType, 'entryType', expectedType)
          .having((error) => error.path, 'path', isNotEmpty),
    ),
  );
}
