import 'dart:convert';
import 'dart:io';

import 'package:borj/core/notifications/dart_io_linux_systemd_file_system.dart';
import 'package:borj/core/notifications/linux_notification_request_fingerprint.dart';
import 'package:borj/core/notifications/linux_systemd_environment.dart';
import 'package:borj/core/notifications/linux_systemd_file_system.dart';
import 'package:borj/core/notifications/linux_systemd_notification_unit.dart';
import 'package:borj/core/notifications/linux_systemd_schedule_registry.dart';
import 'package:borj/core/notifications/linux_systemd_schedule_registry_codec.dart';
import 'package:borj/core/notifications/linux_systemd_schedule_registry_exception.dart';
import 'package:borj/core/notifications/linux_systemd_schedule_registry_file_store.dart';
import 'package:borj/core/notifications/linux_systemd_timer_name.dart';
import 'package:borj/core/notifications/linux_systemd_user_unit_path_resolver.dart';
import 'package:borj/core/notifications/notification_owner.dart';
import 'package:borj/core/notifications/notification_request.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_linux_systemd_file_system.dart';

void main() {
  group('Task 10.4 final registry checkpoint', () {
    test('runs the complete fake-filesystem registry lifecycle', () async {
      const directory = '/config/systemd/user';
      const registryPath = '$directory/borj-notification-registry.json';
      const quarantinePath =
          '$directory/.borj-notification-registry.'
          'txn-lifecycle.corrupt';
      const title = 'TOP_SECRET_TITLE';
      const firstBody = 'TOP_SECRET_BODY_ONE';
      const secondBody = 'TOP_SECRET_BODY_TWO';
      const payloadKey = 'TOP_SECRET_PAYLOAD_KEY';
      const firstPayloadValue = 'TOP_SECRET_PAYLOAD_ONE';
      const secondPayloadValue = 'TOP_SECRET_PAYLOAD_TWO';

      final fileSystem = FakeLinuxSystemdFileSystem();
      final store = _store(
        fileSystem: fileSystem,
        xdgConfigHome: '/config',
        transactionIdFactory: () => 'txn-lifecycle',
      );
      final fingerprint = LinuxNotificationRequestFingerprint();

      expect(await store.load(), LinuxSystemdScheduleRegistry.empty());

      final firstRequest = _request(
        title: title,
        body: firstBody,
        payload: const <String, String>{payloadKey: firstPayloadValue},
      );
      final firstRegistry = _registry(
        generation: 1,
        fingerprint: await fingerprint.compute(firstRequest),
      );

      await store.replace(firstRegistry);

      expect(await store.load(), firstRegistry);
      _expectNoSensitiveRegistryText(
        fileSystem.bytesOf(registryPath),
        const <String>[title, firstBody, payloadKey, firstPayloadValue],
      );

      final secondRequest = _request(
        title: title,
        body: secondBody,
        payload: const <String, String>{payloadKey: secondPayloadValue},
      );
      final secondRegistry = _registry(
        generation: 2,
        fingerprint: await fingerprint.compute(secondRequest),
      );

      await store.replace(secondRegistry);

      expect(await store.load(), secondRegistry);
      _expectNoSensitiveRegistryText(
        fileSystem.bytesOf(registryPath),
        const <String>[title, secondBody, payloadKey, secondPayloadValue],
      );

      const completeBaseName = 'borj-notification-aaaaaaaaaaaaaaaa';
      const partialBaseName = 'borj-notification-bbbbbbbbbbbbbbbb';

      fileSystem.seedFile(
        '$directory/$completeBaseName.service',
        utf8.encode('[Service]\n'),
        mode: 0x1A4,
      );
      fileSystem.seedFile(
        '$directory/$completeBaseName.timer',
        utf8.encode('[Timer]\n'),
        mode: 0x1A4,
      );
      fileSystem.seedFile(
        '$directory/$partialBaseName.timer',
        utf8.encode('[Timer]\n'),
        mode: 0x1A4,
      );

      final discovery = await store.discoverAppUnitPairs();

      expect(
        discovery.completePairs.map((pair) => pair.baseName),
        orderedEquals(const <String>[completeBaseName]),
      );
      expect(
        discovery.partialPairs,
        orderedEquals(<LinuxSystemdPartialUnitPair>[
          LinuxSystemdPartialUnitPair(
            baseName: partialBaseName,
            hasService: false,
            hasTimer: true,
          ),
        ]),
      );

      final corruptBytes = utf8.encode(
        '{"schemaVersion":1,"generation":2,'
        '"entries":[{"corrupt":true}],}',
      );
      fileSystem.seedFile(registryPath, corruptBytes, mode: 0x1A4);

      await store.quarantineCorruptRegistry();

      expect(fileSystem.containsPath(registryPath), isFalse);
      expect(fileSystem.bytesOf(quarantinePath), corruptBytes);
      expect(await store.load(), LinuxSystemdScheduleRegistry.empty());
    });

    test(
      'verifies the real Linux temporary-directory adapter',
      () async {
        final root = await Directory.systemTemp.createTemp(
          'dashboard-task10-4-checkpoint-',
        );

        try {
          final fileSystem = const DartIoLinuxSystemdFileSystem();
          final store = _store(
            fileSystem: fileSystem,
            xdgConfigHome: root.path,
            transactionIdFactory: () => 'txn-real',
          );
          final registry = _registry(generation: 1, fingerprint: 'c' * 64);
          final directory = '${root.path}/systemd/user';
          final registryPath =
              '$directory/'
              'borj-notification-registry.json';

          await store.replace(registry);

          expect(
            await fileSystem.readMode(registryPath),
            LinuxSystemdScheduleRegistryFileStore.registryFileMode,
          );
          expect(await store.load(), registry);

          const completeBaseName = 'borj-notification-cccccccccccccccc';
          final servicePath = '$directory/$completeBaseName.service';
          final timerPath = '$directory/$completeBaseName.timer';

          await File(servicePath).writeAsString('[Service]\n');
          await File(timerPath).writeAsString('[Timer]\n');

          expect(
            await fileSystem.listNames(directory),
            orderedEquals(<String>[
              '$completeBaseName.service',
              '$completeBaseName.timer',
              LinuxSystemdScheduleRegistryFileStore.registryFileName,
            ]),
          );

          final discovery = await store.discoverAppUnitPairs();
          expect(
            discovery.completePairs.map((pair) => pair.baseName),
            orderedEquals(const <String>[completeBaseName]),
          );
          expect(discovery.partialPairs, isEmpty);

          const symlinkBaseName = 'borj-notification-dddddddddddddddd';
          final target = '${root.path}/outside.timer';
          final symlinkPath = '$directory/$symlinkBaseName.timer';
          await File(target).writeAsString('[Timer]\n');
          await Link(symlinkPath).create(target);

          await expectLater(
            store.discoverAppUnitPairs(),
            throwsA(
              isA<LinuxSystemdScheduleRegistryException>()
                  .having(
                    (error) => error.operation,
                    'operation',
                    LinuxSystemdScheduleRegistryOperation.discover,
                  )
                  .having(
                    (error) => error.failure,
                    'failure',
                    LinuxSystemdScheduleRegistryFailure.unsafeAppUnitPath,
                  )
                  .having((error) => error.path, 'path', symlinkPath),
            ),
          );
        } finally {
          if (await root.exists()) {
            await root.delete(recursive: true);
          }
        }
      },
      skip: Platform.isLinux
          ? false
          : 'Requires Linux POSIX permissions and symlinks.',
    );
  });
}

LinuxSystemdScheduleRegistryFileStore _store({
  required LinuxSystemdFileSystem fileSystem,
  required String xdgConfigHome,
  required String Function() transactionIdFactory,
}) {
  return LinuxSystemdScheduleRegistryFileStore(
    pathResolver: LinuxSystemdUserUnitPathResolver(
      _MapEnvironment(<String, String>{'XDG_CONFIG_HOME': xdgConfigHome}),
    ),
    fileSystem: fileSystem,
    codec: const LinuxSystemdScheduleRegistryCodec(),
    transactionIdFactory: transactionIdFactory,
  );
}

LinuxSystemdScheduleRegistry _registry({
  required int generation,
  required String fingerprint,
}) {
  const scheduleId = 'task-42-reminder';
  final names = LinuxSystemdUnitNames.forScheduleKey(scheduleId);

  return LinuxSystemdScheduleRegistry(
    schemaVersion: LinuxSystemdScheduleRegistry.currentSchemaVersion,
    generation: generation,
    entries: <LinuxSystemdScheduleRegistryEntry>[
      LinuxSystemdScheduleRegistryEntry(
        scheduleId: scheduleId,
        owner: NotificationOwner(
          type: NotificationOwnerType.task,
          id: 'task-42',
        ),
        timerName: LinuxSystemdTimerName.parse(names.timerFileName),
        serviceFileName: names.serviceFileName,
        scheduledAtUtc: DateTime.parse('2026-07-30T05:30:00.000Z'),
        requestFingerprint: fingerprint,
      ),
    ],
  );
}

NotificationRequest _request({
  required String title,
  required String body,
  required Map<String, String> payload,
}) {
  return NotificationRequest(
    scheduleId: 'task-42-reminder',
    owner: NotificationOwner(type: NotificationOwnerType.task, id: 'task-42'),
    title: title,
    body: body,
    scheduledAtUtc: DateTime.parse('2026-07-30T05:30:00.000Z'),
    payload: payload,
  );
}

void _expectNoSensitiveRegistryText(List<int> bytes, Iterable<String> secrets) {
  final text = utf8.decode(bytes);

  for (final secret in secrets) {
    expect(text, isNot(contains(secret)));
  }
}

final class _MapEnvironment implements LinuxSystemdEnvironment {
  const _MapEnvironment(this.values);

  final Map<String, String> values;

  @override
  String? value(String name) => values[name];
}
