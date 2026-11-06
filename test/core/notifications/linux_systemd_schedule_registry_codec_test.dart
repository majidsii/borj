import 'dart:convert';

import 'package:borj/core/notifications/linux_systemd_notification_unit.dart';
import 'package:borj/core/notifications/linux_systemd_schedule_registry.dart';
import 'package:borj/core/notifications/linux_systemd_schedule_registry_codec.dart';
import 'package:borj/core/notifications/linux_systemd_schedule_registry_exception.dart';
import 'package:borj/core/notifications/linux_systemd_timer_name.dart';
import 'package:borj/core/notifications/notification_owner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LinuxSystemdScheduleRegistryCodec encoding', () {
    const codec = LinuxSystemdScheduleRegistryCodec();

    test('encodes canonical version-one JSON with exact field order', () {
      final first = _entry(
        scheduleId: 'z-reminder',
        ownerType: NotificationOwnerType.habit,
        ownerId: 'habit-z',
        scheduledAtUtc: '2026-07-30T06:30:00.000Z',
        fingerprintCharacter: 'b',
      );
      final second = _entry(
        scheduleId: 'a-reminder',
        ownerType: NotificationOwnerType.task,
        ownerId: 'task-a',
        scheduledAtUtc: '2026-07-30T05:30:00.000Z',
        fingerprintCharacter: 'a',
      );
      final registry = LinuxSystemdScheduleRegistry(
        schemaVersion: 1,
        generation: 7,
        entries: <LinuxSystemdScheduleRegistryEntry>[first, second],
      );
      final firstNames = LinuxSystemdUnitNames.forScheduleKey('a-reminder');
      final secondNames = LinuxSystemdUnitNames.forScheduleKey('z-reminder');

      final encoded = utf8.decode(codec.encodeBytes(registry));

      expect(
        encoded,
        '{"schemaVersion":1,"generation":7,"entries":['
        '{"scheduleId":"a-reminder","ownerType":"task",'
        '"ownerId":"task-a",'
        '"timerName":"${firstNames.timerFileName}",'
        '"serviceFileName":"${firstNames.serviceFileName}",'
        '"scheduledAtUtc":"2026-07-30T05:30:00.000Z",'
        '"requestFingerprint":"${_fingerprint('a')}"},'
        '{"scheduleId":"z-reminder","ownerType":"habit",'
        '"ownerId":"habit-z",'
        '"timerName":"${secondNames.timerFileName}",'
        '"serviceFileName":"${secondNames.serviceFileName}",'
        '"scheduledAtUtc":"2026-07-30T06:30:00.000Z",'
        '"requestFingerprint":"${_fingerprint('b')}"}]}\n',
      );
      expect(encoded.endsWith('\n'), isTrue);
      expect(encoded.endsWith('\n\n'), isFalse);
    });

    test('round-trips an immutable registry exactly', () {
      final registry = LinuxSystemdScheduleRegistry(
        schemaVersion: 1,
        generation: 3,
        entries: <LinuxSystemdScheduleRegistryEntry>[
          _entry(scheduleId: 'b-reminder'),
          _entry(scheduleId: 'a-reminder'),
        ],
      );

      expect(codec.decodeBytes(codec.encodeBytes(registry)), registry);
    });

    test('encodes an empty registry canonically', () {
      expect(
        utf8.decode(codec.encodeBytes(LinuxSystemdScheduleRegistry.empty())),
        '{"schemaVersion":1,"generation":0,"entries":[]}\n',
      );
    });
  });

  group('LinuxSystemdScheduleRegistryCodec decoding', () {
    const codec = LinuxSystemdScheduleRegistryCodec();

    test('decodes a canonical registry', () {
      final registry = LinuxSystemdScheduleRegistry(
        schemaVersion: 1,
        generation: 4,
        entries: <LinuxSystemdScheduleRegistryEntry>[
          _entry(scheduleId: 'task-42-reminder'),
        ],
      );

      expect(codec.decodeBytes(codec.encodeBytes(registry)), registry);
    });

    test('accepts a valid registry padded to exactly one MiB', () {
      final canonical = codec.encodeBytes(LinuxSystemdScheduleRegistry.empty());
      final padded = <int>[
        ...canonical,
        ...List<int>.filled(
          LinuxSystemdScheduleRegistryCodec.maximumFileBytes - canonical.length,
          0x20,
        ),
      ];

      expect(padded.length, LinuxSystemdScheduleRegistryCodec.maximumFileBytes);
      expect(codec.decodeBytes(padded), LinuxSystemdScheduleRegistry.empty());
    });

    test('rejects input larger than one MiB before JSON parsing', () {
      final bytes = List<int>.filled(
        LinuxSystemdScheduleRegistryCodec.maximumFileBytes + 1,
        0x20,
      );

      _expectFailure(
        () => codec.decodeBytes(bytes),
        LinuxSystemdScheduleRegistryFailure.oversizedRegistry,
      );
    });

    test('rejects malformed UTF-8 distinctly', () {
      _expectFailure(
        () => codec.decodeBytes(const <int>[
          0x7b,
          0x22,
          0x78,
          0x22,
          0x3a,
          0xff,
          0x7d,
        ]),
        LinuxSystemdScheduleRegistryFailure.malformedUtf8,
      );
    });

    for (final source in <String>[
      '',
      '   ',
      '[]',
      'null',
      '{"schemaVersion":1,"generation":0}',
      '{"schemaVersion":1,"generation":0,"entries":[],"future":1}',
      '{"schemaVersion":1,"schemaVersion":1,"generation":0,"entries":[]}',
      '{"schemaVersion":1.0,"generation":0,"entries":[]}',
      '{"schemaVersion":"1","generation":0,"entries":[]}',
      '{"schemaVersion":1,"generation":0.0,"entries":[]}',
      '{"schemaVersion":1,"generation":"0","entries":[]}',
      '{"schemaVersion":1,"generation":0,"entries":{}}',
    ]) {
      test('rejects malformed registry schema: $source', () {
        _expectFailure(
          () => codec.decodeBytes(utf8.encode(source)),
          LinuxSystemdScheduleRegistryFailure.malformedJson,
        );
      });
    }

    test('rejects an unsupported integer schema version', () {
      _expectFailure(
        () => codec.decodeBytes(
          utf8.encode('{"schemaVersion":2,"generation":0,"entries":[]}'),
        ),
        LinuxSystemdScheduleRegistryFailure.unsupportedSchemaVersion,
        field: 'schemaVersion',
      );
    });

    test('rejects a negative generation', () {
      _expectFailure(
        () => codec.decodeBytes(
          utf8.encode('{"schemaVersion":1,"generation":-1,"entries":[]}'),
        ),
        LinuxSystemdScheduleRegistryFailure.invalidGeneration,
        field: 'generation',
      );
    });

    test('rejects more than ten thousand entries before entry decoding', () {
      final entries = List<String>.filled(
        LinuxSystemdScheduleRegistryCodec.maximumEntries + 1,
        '{}',
      ).join(',');

      _expectFailure(
        () => codec.decodeBytes(
          utf8.encode(
            '{"schemaVersion":1,"generation":0,'
            '"entries":[$entries]}',
          ),
        ),
        LinuxSystemdScheduleRegistryFailure.excessiveEntryCount,
        field: 'entries',
      );
    });

    test('allows exactly ten thousand entries past the count guard', () {
      final entries = List<String>.filled(
        LinuxSystemdScheduleRegistryCodec.maximumEntries,
        '{}',
      ).join(',');

      _expectFailure(
        () => codec.decodeBytes(
          utf8.encode(
            '{"schemaVersion":1,"generation":0,'
            '"entries":[$entries]}',
          ),
        ),
        LinuxSystemdScheduleRegistryFailure.malformedJson,
      );
    });

    test('rejects an entry with an unknown key', () {
      final json = _entryJson(
        scheduleId: 'task-42-reminder',
        additionalField: ',"future":true',
      );

      _expectFailure(
        () => codec.decodeBytes(
          utf8.encode('{"schemaVersion":1,"generation":0,"entries":[$json]}'),
        ),
        LinuxSystemdScheduleRegistryFailure.malformedJson,
      );
    });

    test('rejects an entry with a missing key', () {
      final names = LinuxSystemdUnitNames.forScheduleKey('task-42-reminder');
      final json =
          '{"scheduleId":"task-42-reminder",'
          '"ownerType":"task",'
          '"ownerId":"task-42",'
          '"timerName":"${names.timerFileName}",'
          '"serviceFileName":"${names.serviceFileName}",'
          '"scheduledAtUtc":"2026-07-30T05:30:00.000Z"}';

      _expectFailure(
        () => codec.decodeBytes(
          utf8.encode('{"schemaVersion":1,"generation":0,"entries":[$json]}'),
        ),
        LinuxSystemdScheduleRegistryFailure.malformedJson,
      );
    });

    test('rejects a duplicate entry key', () {
      final names = LinuxSystemdUnitNames.forScheduleKey('task-42-reminder');
      final json =
          '{"scheduleId":"task-42-reminder",'
          '"scheduleId":"task-42-reminder",'
          '"ownerType":"task",'
          '"ownerId":"task-42",'
          '"timerName":"${names.timerFileName}",'
          '"serviceFileName":"${names.serviceFileName}",'
          '"scheduledAtUtc":"2026-07-30T05:30:00.000Z",'
          '"requestFingerprint":"${_fingerprint('a')}"}';

      _expectFailure(
        () => codec.decodeBytes(
          utf8.encode('{"schemaVersion":1,"generation":0,"entries":[$json]}'),
        ),
        LinuxSystemdScheduleRegistryFailure.malformedJson,
      );
    });

    for (final ownerType in <String>['', 'Task', 'unknown', 'task ']) {
      test('rejects invalid owner type: $ownerType', () {
        final json = _entryJson(
          scheduleId: 'task-42-reminder',
          ownerType: ownerType,
        );

        _expectFailure(
          () => codec.decodeBytes(
            utf8.encode(
              '{"schemaVersion":1,"generation":0,'
              '"entries":[$json]}',
            ),
          ),
          LinuxSystemdScheduleRegistryFailure.invalidOwner,
          field: 'ownerType',
        );
      });
    }

    for (final ownerId in <String>['', ' ', ' task-42', 'task-42 ']) {
      test('rejects invalid owner id: $ownerId', () {
        final json = _entryJson(
          scheduleId: 'task-42-reminder',
          ownerId: ownerId,
        );

        _expectFailure(
          () => codec.decodeBytes(
            utf8.encode(
              '{"schemaVersion":1,"generation":0,'
              '"entries":[$json]}',
            ),
          ),
          LinuxSystemdScheduleRegistryFailure.invalidOwner,
          field: 'ownerId',
        );
      });
    }

    for (final timestamp in <String>[
      '2026-07-30T05:30:00',
      '2026-07-30T05:30:00+00:00',
      '2026-07-30T05:30:00Z',
      '2026-07-30T05:30:00.000000Z',
      'not-a-time',
    ]) {
      test('rejects non-canonical UTC timestamp: $timestamp', () {
        final json = _entryJson(
          scheduleId: 'task-42-reminder',
          scheduledAtUtc: timestamp,
        );

        _expectFailure(
          () => codec.decodeBytes(
            utf8.encode(
              '{"schemaVersion":1,"generation":0,'
              '"entries":[$json]}',
            ),
          ),
          LinuxSystemdScheduleRegistryFailure.invalidTimestamp,
          field: 'scheduledAtUtc',
        );
      });
    }

    test('rejects an invalid timer name with a typed identity error', () {
      final json = _entryJson(
        scheduleId: 'task-42-reminder',
        timerName: 'unsafe.timer',
      );

      _expectFailure(
        () => codec.decodeBytes(
          utf8.encode('{"schemaVersion":1,"generation":0,"entries":[$json]}'),
        ),
        LinuxSystemdScheduleRegistryFailure.invalidUnitIdentity,
        field: 'timerName',
      );
    });

    test('rejects a fingerprint through the validated entry model', () {
      final json = _entryJson(
        scheduleId: 'task-42-reminder',
        fingerprint: _fingerprint('A'),
      );

      _expectFailure(
        () => codec.decodeBytes(
          utf8.encode('{"schemaVersion":1,"generation":0,"entries":[$json]}'),
        ),
        LinuxSystemdScheduleRegistryFailure.invalidFingerprint,
        field: 'requestFingerprint',
      );
    });

    test('safe diagnostics never contain registry content', () {
      const secret = 'TOP_SECRET_OWNER';

      try {
        codec.decodeBytes(
          utf8.encode(
            '{"schemaVersion":1,"generation":0,"entries":['
            '{"scheduleId":"task-42-reminder",'
            '"ownerType":"unknown","ownerId":"$secret",'
            '"timerName":"unsafe.timer",'
            '"serviceFileName":"unsafe.service",'
            '"scheduledAtUtc":"not-a-time",'
            '"requestFingerprint":"bad"}]}',
          ),
        );
        fail('Expected invalid owner.');
      } on LinuxSystemdScheduleRegistryException catch (error) {
        expect(error.toString(), isNot(contains(secret)));
      }
    });
  });
}

LinuxSystemdScheduleRegistryEntry _entry({
  required String scheduleId,
  NotificationOwnerType ownerType = NotificationOwnerType.task,
  String ownerId = 'task-42',
  String scheduledAtUtc = '2026-07-30T05:30:00.000Z',
  String fingerprintCharacter = 'a',
}) {
  final names = LinuxSystemdUnitNames.forScheduleKey(scheduleId);

  return LinuxSystemdScheduleRegistryEntry(
    scheduleId: scheduleId,
    owner: NotificationOwner(type: ownerType, id: ownerId),
    timerName: LinuxSystemdTimerName.parse(names.timerFileName),
    serviceFileName: names.serviceFileName,
    scheduledAtUtc: DateTime.parse(scheduledAtUtc),
    requestFingerprint: _fingerprint(fingerprintCharacter),
  );
}

String _entryJson({
  required String scheduleId,
  String ownerType = 'task',
  String ownerId = 'task-42',
  String? timerName,
  String? serviceFileName,
  String scheduledAtUtc = '2026-07-30T05:30:00.000Z',
  String fingerprint = '',
  String additionalField = '',
}) {
  final names = LinuxSystemdUnitNames.forScheduleKey(scheduleId);

  return '{"scheduleId":"$scheduleId",'
      '"ownerType":"$ownerType",'
      '"ownerId":"$ownerId",'
      '"timerName":"${timerName ?? names.timerFileName}",'
      '"serviceFileName":"${serviceFileName ?? names.serviceFileName}",'
      '"scheduledAtUtc":"$scheduledAtUtc",'
      '"requestFingerprint":"${fingerprint.isEmpty ? _fingerprint('a') : fingerprint}"'
      '$additionalField}';
}

void _expectFailure(
  Object? Function() action,
  LinuxSystemdScheduleRegistryFailure failure, {
  String? field,
}) {
  var matcher = isA<LinuxSystemdScheduleRegistryException>()
      .having(
        (error) => error.operation,
        'operation',
        LinuxSystemdScheduleRegistryOperation.decode,
      )
      .having((error) => error.failure, 'failure', failure);

  if (field != null) {
    matcher = matcher.having((error) => error.field, 'field', field);
  }

  expect(action, throwsA(matcher));
}

String _fingerprint(String character) {
  return List<String>.filled(64, character).join();
}
