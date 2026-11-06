import 'package:borj/core/notifications/linux_systemd_notification_unit.dart';
import 'package:borj/core/notifications/linux_systemd_schedule_registry.dart';
import 'package:borj/core/notifications/linux_systemd_schedule_registry_exception.dart';
import 'package:borj/core/notifications/linux_systemd_timer_name.dart';
import 'package:borj/core/notifications/notification_owner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LinuxSystemdScheduleRegistryEntry', () {
    test('stores one canonical immutable registry entry', () {
      final entry = _entry(
        scheduleId: 'task-42-reminder',
        owner: NotificationOwner(
          type: NotificationOwnerType.task,
          id: 'task-42',
        ),
        scheduledAtUtc: DateTime.parse('2026-07-30T05:30:00.000Z'),
      );

      expect(entry.scheduleId, 'task-42-reminder');
      expect(entry.owner.toString(), 'task:task-42');
      expect(entry.scheduledAtUtc, DateTime.parse('2026-07-30T05:30:00.000Z'));
      expect(entry.requestFingerprint, _fingerprint('a'));
      expect(
        entry.timerName.value,
        LinuxSystemdUnitNames.forScheduleKey('task-42-reminder').timerFileName,
      );
      expect(
        entry.serviceFileName,
        LinuxSystemdUnitNames.forScheduleKey(
          'task-42-reminder',
        ).serviceFileName,
      );
    });

    test('supports value equality and stable hashing', () {
      final first = _entry(scheduleId: 'task-42-reminder');
      final second = _entry(scheduleId: 'task-42-reminder');
      final different = _entry(scheduleId: 'task-43-reminder');

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first, isNot(different));
    });

    for (final invalid in <String>[
      '',
      '   ',
      ' task-42-reminder',
      'task-42-reminder ',
      '\ttask-42-reminder',
      'task-42-reminder\n',
    ]) {
      test('rejects non-canonical schedule id: $invalid', () {
        _expectFailure(
          () => _entry(scheduleId: invalid),
          LinuxSystemdScheduleRegistryFailure.invalidScheduleId,
          field: 'scheduleId',
        );
      });
    }

    test('rejects a non-UTC scheduled timestamp', () {
      _expectFailure(
        () => _entry(scheduledAtUtc: DateTime(2026, 7, 30, 9)),
        LinuxSystemdScheduleRegistryFailure.invalidTimestamp,
        field: 'scheduledAtUtc',
      );
    });

    for (final invalid in <String>[
      '',
      _repeat('a', 63),
      _repeat('a', 65),
      _repeat('A', 64),
      _repeat('g', 64),
      '${_repeat('a', 63)} ',
    ]) {
      test('rejects invalid request fingerprint: $invalid', () {
        _expectFailure(
          () => _entry(requestFingerprint: invalid),
          LinuxSystemdScheduleRegistryFailure.invalidFingerprint,
          field: 'requestFingerprint',
        );
      });
    }

    test('rejects a timer derived from another schedule id', () {
      final otherNames = LinuxSystemdUnitNames.forScheduleKey(
        'another-schedule',
      );

      _expectFailure(
        () => _entry(
          timerName: LinuxSystemdTimerName.parse(otherNames.timerFileName),
        ),
        LinuxSystemdScheduleRegistryFailure.invalidUnitIdentity,
        field: 'timerName',
      );
    });

    test('rejects a service derived from another schedule id', () {
      final otherNames = LinuxSystemdUnitNames.forScheduleKey(
        'another-schedule',
      );

      _expectFailure(
        () => _entry(serviceFileName: otherNames.serviceFileName),
        LinuxSystemdScheduleRegistryFailure.invalidUnitIdentity,
        field: 'serviceFileName',
      );
    });

    test('rejects a timer and service that agree with each other only', () {
      final otherNames = LinuxSystemdUnitNames.forScheduleKey(
        'another-schedule',
      );

      _expectFailure(
        () => _entry(
          timerName: LinuxSystemdTimerName.parse(otherNames.timerFileName),
          serviceFileName: otherNames.serviceFileName,
        ),
        LinuxSystemdScheduleRegistryFailure.invalidUnitIdentity,
      );
    });
  });

  group('LinuxSystemdScheduleRegistry', () {
    test('sorts entries by schedule id and exposes immutable lookup', () {
      final registry = LinuxSystemdScheduleRegistry(
        schemaVersion: 1,
        generation: 7,
        entries: <LinuxSystemdScheduleRegistryEntry>[
          _entry(scheduleId: 'z-reminder'),
          _entry(scheduleId: 'a-reminder'),
          _entry(scheduleId: 'm-reminder'),
        ],
      );

      expect(registry.schemaVersion, 1);
      expect(registry.generation, 7);
      expect(
        registry.entries.map((item) => item.scheduleId),
        orderedEquals(<String>['a-reminder', 'm-reminder', 'z-reminder']),
      );
      expect(
        registry.entryForScheduleId('m-reminder'),
        _entry(scheduleId: 'm-reminder'),
      );
      expect(registry.entryForScheduleId('missing'), isNull);
      expect(
        () => registry.entries.add(_entry(scheduleId: 'new-reminder')),
        throwsUnsupportedError,
      );
    });

    test('creates the exact empty version-one registry', () {
      final registry = LinuxSystemdScheduleRegistry.empty();

      expect(
        registry.schemaVersion,
        LinuxSystemdScheduleRegistry.currentSchemaVersion,
      );
      expect(registry.schemaVersion, 1);
      expect(registry.generation, 0);
      expect(registry.entries, isEmpty);
    });

    test('supports value equality and stable hashing', () {
      final first = LinuxSystemdScheduleRegistry(
        schemaVersion: 1,
        generation: 3,
        entries: <LinuxSystemdScheduleRegistryEntry>[
          _entry(scheduleId: 'b-reminder'),
          _entry(scheduleId: 'a-reminder'),
        ],
      );
      final second = LinuxSystemdScheduleRegistry(
        schemaVersion: 1,
        generation: 3,
        entries: <LinuxSystemdScheduleRegistryEntry>[
          _entry(scheduleId: 'a-reminder'),
          _entry(scheduleId: 'b-reminder'),
        ],
      );
      final different = LinuxSystemdScheduleRegistry(
        schemaVersion: 1,
        generation: 4,
        entries: <LinuxSystemdScheduleRegistryEntry>[
          _entry(scheduleId: 'a-reminder'),
          _entry(scheduleId: 'b-reminder'),
        ],
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first, isNot(different));
    });

    test('rejects an unsupported schema version', () {
      _expectFailure(
        () => LinuxSystemdScheduleRegistry(
          schemaVersion: 2,
          generation: 0,
          entries: const <LinuxSystemdScheduleRegistryEntry>[],
        ),
        LinuxSystemdScheduleRegistryFailure.unsupportedSchemaVersion,
        field: 'schemaVersion',
      );
    });

    test('rejects a negative generation', () {
      _expectFailure(
        () => LinuxSystemdScheduleRegistry(
          schemaVersion: 1,
          generation: -1,
          entries: const <LinuxSystemdScheduleRegistryEntry>[],
        ),
        LinuxSystemdScheduleRegistryFailure.invalidGeneration,
        field: 'generation',
      );
    });

    test('rejects a duplicate schedule id', () {
      final first = _entry(scheduleId: 'same-schedule');
      final duplicate = _entry(
        scheduleId: 'same-schedule',
        owner: NotificationOwner(
          type: NotificationOwnerType.habit,
          id: 'habit-1',
        ),
      );

      _expectFailure(
        () => LinuxSystemdScheduleRegistry(
          schemaVersion: 1,
          generation: 1,
          entries: <LinuxSystemdScheduleRegistryEntry>[first, duplicate],
        ),
        LinuxSystemdScheduleRegistryFailure.duplicateScheduleId,
        field: 'scheduleId',
      );
    });
  });

  group('LinuxSystemdUnitNames.parseBaseName', () {
    test('parses one exact app-owned base name', () {
      final names = LinuxSystemdUnitNames.parseBaseName(
        'borj-notification-0123456789abcdef',
      );

      expect(names.baseName, 'borj-notification-0123456789abcdef');
      expect(
        names.serviceFileName,
        'borj-notification-0123456789abcdef.service',
      );
      expect(names.timerFileName, 'borj-notification-0123456789abcdef.timer');
      expect(names, LinuxSystemdUnitNames.parseBaseName(names.baseName));
    });

    for (final invalid in <String>[
      '',
      'borj-notification-0123456789abcde',
      'borj-notification-0123456789abcdef0',
      'borj-notification-0123456789ABCDEf',
      'borj-notification-0123456789abcdef.timer',
      ' borj-notification-0123456789abcdef',
      'borj-notification-0123456789abcdef ',
      '../borj-notification-0123456789abcdef',
      'other-notification-0123456789abcdef',
      'borj-notification-0123456789abcdef\n',
      'borj-notification-0123456789abcdef\u0000',
    ]) {
      test('rejects invalid app-owned base name: $invalid', () {
        _expectFailure(
          () => LinuxSystemdUnitNames.parseBaseName(invalid),
          LinuxSystemdScheduleRegistryFailure.invalidUnitIdentity,
          field: 'baseName',
        );
      });
    }
  });

  group('LinuxSystemdUnitDiscovery', () {
    test('stores sorted immutable complete and partial pairs', () {
      final namesA = LinuxSystemdUnitNames.parseBaseName(
        'borj-notification-aaaaaaaaaaaaaaaa',
      );
      final namesB = LinuxSystemdUnitNames.parseBaseName(
        'borj-notification-bbbbbbbbbbbbbbbb',
      );
      final partialA = LinuxSystemdPartialUnitPair(
        baseName: 'borj-notification-cccccccccccccccc',
        hasService: true,
        hasTimer: false,
      );
      final partialB = LinuxSystemdPartialUnitPair(
        baseName: 'borj-notification-dddddddddddddddd',
        hasService: false,
        hasTimer: true,
      );

      final discovery = LinuxSystemdUnitDiscovery(
        completePairs: <LinuxSystemdUnitNames>[namesB, namesA, namesA],
        partialPairs: <LinuxSystemdPartialUnitPair>[
          partialB,
          partialA,
          partialA,
        ],
      );

      expect(
        discovery.completePairs.map((item) => item.baseName),
        orderedEquals(<String>[namesA.baseName, namesB.baseName]),
      );
      expect(
        discovery.partialPairs.map((item) => item.baseName),
        orderedEquals(<String>[partialA.baseName, partialB.baseName]),
      );
      expect(discovery.completePairs.length, 2);
      expect(discovery.partialPairs.length, 2);
      expect(() => discovery.completePairs.add(namesA), throwsUnsupportedError);
      expect(
        () => discovery.partialPairs.add(partialA),
        throwsUnsupportedError,
      );
    });

    test('supports value equality and stable hashing', () {
      final names = LinuxSystemdUnitNames.parseBaseName(
        'borj-notification-aaaaaaaaaaaaaaaa',
      );
      final partial = LinuxSystemdPartialUnitPair(
        baseName: 'borj-notification-bbbbbbbbbbbbbbbb',
        hasService: true,
        hasTimer: false,
      );
      final first = LinuxSystemdUnitDiscovery(
        completePairs: <LinuxSystemdUnitNames>[names],
        partialPairs: <LinuxSystemdPartialUnitPair>[partial],
      );
      final second = LinuxSystemdUnitDiscovery(
        completePairs: <LinuxSystemdUnitNames>[names],
        partialPairs: <LinuxSystemdPartialUnitPair>[partial],
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    for (final invalid in <LinuxSystemdPartialUnitPair Function()>[
      () => LinuxSystemdPartialUnitPair(
        baseName: 'borj-notification-aaaaaaaaaaaaaaaa',
        hasService: true,
        hasTimer: true,
      ),
      () => LinuxSystemdPartialUnitPair(
        baseName: 'borj-notification-aaaaaaaaaaaaaaaa',
        hasService: false,
        hasTimer: false,
      ),
      () => LinuxSystemdPartialUnitPair(
        baseName: 'unsafe',
        hasService: true,
        hasTimer: false,
      ),
    ]) {
      test('rejects an invalid partial unit pair', () {
        _expectFailure(
          invalid,
          LinuxSystemdScheduleRegistryFailure.invalidUnitIdentity,
        );
      });
    }
  });

  group('LinuxSystemdScheduleRegistryException', () {
    test('keeps rollback failures immutable and diagnostics safe', () {
      final cause = StateError('TOP_SECRET');
      final rollback = LinuxSystemdRegistryRollbackFailure(
        step: 'restore-registry-backup',
        error: StateError('ROLLBACK_SECRET'),
        stackTrace: StackTrace.current,
      );
      final exception = LinuxSystemdScheduleRegistryException(
        operation: LinuxSystemdScheduleRegistryOperation.replace,
        failure: LinuxSystemdScheduleRegistryFailure.atomicReplacementFailed,
        path: '/safe/registry.json',
        field: 'generation',
        cause: cause,
        causeStackTrace: StackTrace.current,
        rollbackFailures: <LinuxSystemdRegistryRollbackFailure>[rollback],
      );

      expect(exception.cause, same(cause));
      expect(exception.rollbackFailures.single, same(rollback));
      expect(
        () => exception.rollbackFailures.add(rollback),
        throwsUnsupportedError,
      );
      expect(exception.toString(), contains('replace'));
      expect(exception.toString(), contains('atomicReplacementFailed'));
      expect(exception.toString(), contains('/safe/registry.json'));
      expect(exception.toString(), contains('rollbackFailures=1'));
      expect(exception.toString(), isNot(contains('TOP_SECRET')));
      expect(exception.toString(), isNot(contains('ROLLBACK_SECRET')));
    });
  });
}

LinuxSystemdScheduleRegistryEntry _entry({
  String scheduleId = 'task-42-reminder',
  NotificationOwner? owner,
  DateTime? scheduledAtUtc,
  String? requestFingerprint,
  LinuxSystemdTimerName? timerName,
  String? serviceFileName,
}) {
  final normalizedScheduleId = scheduleId.trim();
  final names = LinuxSystemdUnitNames.forScheduleKey(
    normalizedScheduleId.isEmpty ? 'fallback-schedule' : normalizedScheduleId,
  );

  return LinuxSystemdScheduleRegistryEntry(
    scheduleId: scheduleId,
    owner:
        owner ??
        NotificationOwner(type: NotificationOwnerType.task, id: 'task-42'),
    timerName: timerName ?? LinuxSystemdTimerName.parse(names.timerFileName),
    serviceFileName: serviceFileName ?? names.serviceFileName,
    scheduledAtUtc:
        scheduledAtUtc ?? DateTime.parse('2026-07-30T05:30:00.000Z'),
    requestFingerprint: requestFingerprint ?? _fingerprint('a'),
  );
}

String _fingerprint(String value) => _repeat(value, 64);

String _repeat(String value, int count) {
  return List<String>.filled(count, value).join();
}

void _expectFailure(
  Object? Function() action,
  LinuxSystemdScheduleRegistryFailure failure, {
  String? field,
}) {
  var matcher = isA<LinuxSystemdScheduleRegistryException>().having(
    (error) => error.failure,
    'failure',
    failure,
  );

  if (field != null) {
    matcher = matcher.having((error) => error.field, 'field', field);
  }

  expect(action, throwsA(matcher));
}
