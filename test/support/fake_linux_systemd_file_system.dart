import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:borj/core/notifications/linux_systemd_file_system.dart';

final class FakeLinuxSystemdEntry {
  FakeLinuxSystemdEntry._({
    required this.type,
    List<int> bytes = const <int>[],
    this.mode,
    this.linkTarget,
  }) : bytes = List<int>.unmodifiable(bytes);

  factory FakeLinuxSystemdEntry.file(List<int> bytes, {required int mode}) {
    return FakeLinuxSystemdEntry._(
      type: LinuxSystemdEntryType.regularFile,
      bytes: bytes,
      mode: mode,
    );
  }

  factory FakeLinuxSystemdEntry.directory() {
    return FakeLinuxSystemdEntry._(type: LinuxSystemdEntryType.directory);
  }

  factory FakeLinuxSystemdEntry.symbolicLink(String target) {
    return FakeLinuxSystemdEntry._(
      type: LinuxSystemdEntryType.symbolicLink,
      linkTarget: target,
    );
  }

  factory FakeLinuxSystemdEntry.other() {
    return FakeLinuxSystemdEntry._(type: LinuxSystemdEntryType.other);
  }

  final LinuxSystemdEntryType type;
  final List<int> bytes;
  final int? mode;
  final String? linkTarget;

  FakeLinuxSystemdEntry withMode(int value) {
    return FakeLinuxSystemdEntry._(
      type: type,
      bytes: bytes,
      mode: value,
      linkTarget: linkTarget,
    );
  }
}

final class FakeLinuxSystemdFileSystem implements LinuxSystemdFileSystem {
  final Map<String, FakeLinuxSystemdEntry> _entries =
      <String, FakeLinuxSystemdEntry>{};
  final Map<String, Queue<Object>> _failures = <String, Queue<Object>>{};

  final List<String> operations = <String>[];

  void seedFile(String path, List<int> bytes, {int mode = 0x1A4}) {
    _entries[path] = FakeLinuxSystemdEntry.file(
      List<int>.from(bytes),
      mode: mode,
    );
  }

  void seedDirectory(String path) {
    _entries[path] = FakeLinuxSystemdEntry.directory();
  }

  void seedSymlink(String path, String target) {
    _entries[path] = FakeLinuxSystemdEntry.symbolicLink(target);
  }

  void seedOther(String path) {
    _entries[path] = FakeLinuxSystemdEntry.other();
  }

  void failNext(String operation, {Object? error}) {
    final failures = _failures.putIfAbsent(operation, Queue<Object>.new);
    failures.add(error ?? StateError('Injected failure: $operation'));
  }

  bool containsPath(String path) => _entries.containsKey(path);

  List<int> bytesOf(String path) {
    final entry = _requireFile(path, operation: 'read');
    return List<int>.from(entry.bytes);
  }

  String textOf(String path) => utf8.decode(bytesOf(path));

  int? modeOf(String path) => _entries[path]?.mode;

  String? linkTargetOf(String path) {
    return _entries[path]?.linkTarget;
  }

  List<String> pathsWhere(bool Function(String path) predicate) {
    return _entries.keys.where(predicate).toList(growable: false);
  }

  @override
  Future<void> createDirectory(String path) async {
    final operation = 'createDirectory:$path';
    _recordAndMaybeFail(operation);

    final existing = _entries[path];
    if (existing == null) {
      _entries[path] = FakeLinuxSystemdEntry.directory();
      return;
    }

    if (existing.type != LinuxSystemdEntryType.directory) {
      throw LinuxSystemdUnsafeEntryException(
        path: path,
        entryType: existing.type,
        operation: 'create directory over',
      );
    }
  }

  @override
  Future<LinuxSystemdEntryType> typeOf(String path) async {
    _recordAndMaybeFail('typeOf:$path');
    return _entries[path]?.type ?? LinuxSystemdEntryType.missing;
  }

  @override
  Future<int> fileLength(String path) async {
    _recordAndMaybeFail('fileLength:$path');

    final entry = _entries[path];
    if (entry == null) {
      throw LinuxSystemdUnsafeEntryException(
        path: path,
        entryType: LinuxSystemdEntryType.missing,
        operation: 'read length from',
      );
    }

    if (entry.type != LinuxSystemdEntryType.regularFile) {
      throw LinuxSystemdUnsafeEntryException(
        path: path,
        entryType: entry.type,
        operation: 'read length from',
      );
    }

    return entry.bytes.length;
  }

  @override
  Future<List<String>> listNames(String directoryPath) async {
    _recordAndMaybeFail('listNames:$directoryPath');

    final entry = _entries[directoryPath];
    if (entry == null) {
      return const <String>[];
    }

    if (entry.type != LinuxSystemdEntryType.directory) {
      throw LinuxSystemdUnsafeEntryException(
        path: directoryPath,
        entryType: entry.type,
        operation: 'list',
      );
    }

    final prefix = directoryPath.endsWith('/')
        ? directoryPath
        : '$directoryPath/';
    final names = <String>{};

    for (final path in _entries.keys) {
      if (!path.startsWith(prefix)) {
        continue;
      }

      final remainder = path.substring(prefix.length);
      if (remainder.isEmpty || remainder.contains('/')) {
        continue;
      }

      names.add(remainder);
    }

    final sorted = names.toList()..sort();
    return List<String>.unmodifiable(sorted);
  }

  @override
  Future<List<int>> readBytes(String path) async {
    _recordAndMaybeFail('read:$path');
    return List<int>.from(_requireFile(path, operation: 'read').bytes);
  }

  @override
  Future<int> readMode(String path) async {
    _recordAndMaybeFail('readMode:$path');
    final mode = _requireFile(path, operation: 'read mode from').mode;

    if (mode == null) {
      throw StateError('Regular file has no stored mode: $path');
    }

    return mode;
  }

  @override
  Future<void> writeBytes(String path, List<int> bytes) async {
    _recordAndMaybeFail('write:$path');
    _entries[path] = FakeLinuxSystemdEntry.file(
      List<int>.from(bytes),
      mode: 0x180,
    );
  }

  @override
  Future<void> rename(String sourcePath, String destinationPath) async {
    _recordAndMaybeFail('rename:$sourcePath->$destinationPath');

    final source = _entries.remove(sourcePath);
    if (source == null) {
      throw FileSystemException('Source path does not exist.', sourcePath);
    }

    if (source.type != LinuxSystemdEntryType.regularFile) {
      _entries[sourcePath] = source;
      throw LinuxSystemdUnsafeEntryException(
        path: sourcePath,
        entryType: source.type,
        operation: 'rename',
      );
    }

    _entries[destinationPath] = source;
  }

  @override
  Future<void> deleteFile(String path) async {
    _recordAndMaybeFail('delete:$path');

    final entry = _entries[path];
    if (entry == null) {
      return;
    }

    if (entry.type != LinuxSystemdEntryType.regularFile) {
      throw LinuxSystemdUnsafeEntryException(
        path: path,
        entryType: entry.type,
        operation: 'delete',
      );
    }

    _entries.remove(path);
  }

  @override
  Future<void> chmod(String path, int mode) async {
    _recordAndMaybeFail('chmod:$path:$mode');

    if (mode < 0 || mode > 0x1FF) {
      throw ArgumentError.value(
        mode,
        'mode',
        'must contain only POSIX permission bits',
      );
    }

    final entry = _requireFile(path, operation: 'chmod');
    _entries[path] = entry.withMode(mode);
  }

  FakeLinuxSystemdEntry _requireFile(String path, {required String operation}) {
    final entry = _entries[path];
    if (entry == null) {
      throw FileSystemException('Path does not exist.', path);
    }

    if (entry.type != LinuxSystemdEntryType.regularFile) {
      throw LinuxSystemdUnsafeEntryException(
        path: path,
        entryType: entry.type,
        operation: operation,
      );
    }

    return entry;
  }

  void _recordAndMaybeFail(String operation) {
    operations.add(operation);

    final failures = _failures[operation];
    if (failures == null || failures.isEmpty) {
      return;
    }

    final error = failures.removeFirst();
    if (failures.isEmpty) {
      _failures.remove(operation);
    }

    throw error;
  }
}
