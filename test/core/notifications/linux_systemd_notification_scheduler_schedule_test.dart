import 'package:borj/core/date_time/app_clock.dart';
import 'package:borj/core/notifications/linux_notification_delivery_command_factory.dart';
import 'package:borj/core/notifications/linux_notification_request_fingerprint.dart';
import 'package:borj/core/notifications/linux_systemd_notification_scheduler.dart';
import 'package:borj/core/notifications/linux_systemd_notification_unit.dart';
import 'package:borj/core/notifications/linux_systemd_schedule_registry.dart';
import 'package:borj/core/notifications/linux_systemd_timer_name.dart';
import 'package:borj/core/notifications/linux_systemd_unit_renderer.dart';
import 'package:borj/core/notifications/linux_systemd_user_driver.dart';
import 'package:borj/core/notifications/notification_owner.dart';
import 'package:borj/core/notifications/notification_payload_codec.dart';
import 'package:borj/core/notifications/notification_request.dart';
import 'package:borj/core/notifications/stable_notification_id.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/controlled_linux_process_runner.dart';
import '../../support/fake_linux_systemd_schedule_registry_store.dart';
import '../../support/fake_linux_systemd_unit_store.dart';
import '../../support/recording_native_notification_gateway.dart';

void main() {
  final now = DateTime.utc(2026, 8, 2, 8);

  group('future schedule flow', () {
    test('uses the exact successful component-operation order', () async {
      final operations = <String>[];
      final request = _request(
        scheduleId: 'task-future-order',
        scheduledAtUtc: now.add(const Duration(hours: 2)),
      );
      final names = LinuxSystemdUnitNames.forScheduleKey(request.scheduleId);
      final harness = _Harness(now: now, operations: operations)
        ..processRunner.enqueueSuccess()
        ..processRunner.enqueueSuccess()
        ..processRunner.enqueueStatus(names);

      await harness.scheduler.schedule(request);

      expect(
        operations,
        orderedEquals(<String>[
          'registry.load',
          'factory.create',
          'unitStore.beginInstall',
          'install.apply',
          'driver.reload',
          'driver.enable',
          'driver.status',
          'registry.replace',
          'install.finalize',
        ]),
      );

      final expectedRendered = const LinuxSystemdUnitRenderer().render(
        harness.factory.units.single,
      );
      expect(harness.unitStore.installUnits.single, expectedRendered);
    });

    test('same fingerprint plus healthy status performs no mutation', () async {
      final operations = <String>[];
      final request = _request(
        scheduleId: 'task-idempotent',
        scheduledAtUtc: now.add(const Duration(hours: 3)),
      );
      final fingerprint = await const _FingerprintHarness().compute(request);
      final registry = _registry(
        generation: 7,
        entries: <LinuxSystemdScheduleRegistryEntry>[
          _entry(request, fingerprint),
        ],
      );
      final names = LinuxSystemdUnitNames.forScheduleKey(request.scheduleId);
      final harness = _Harness(
        now: now,
        operations: operations,
        registry: registry,
      )..processRunner.enqueueStatus(names);

      await harness.scheduler.schedule(request);

      expect(
        operations,
        orderedEquals(<String>['registry.load', 'driver.status']),
      );
      expect(harness.registryStore.replacements, isEmpty);
      expect(harness.unitStore.installUnits, isEmpty);
      expect(harness.gateway.calls, isEmpty);
    });

    test('same fingerprint plus unhealthy status repairs', () async {
      final operations = <String>[];
      final request = _request(
        scheduleId: 'task-unhealthy',
        scheduledAtUtc: now.add(const Duration(hours: 4)),
      );
      final fingerprint = await const _FingerprintHarness().compute(request);
      final registry = _registry(
        generation: 4,
        entries: <LinuxSystemdScheduleRegistryEntry>[
          _entry(request, fingerprint),
        ],
      );
      final names = LinuxSystemdUnitNames.forScheduleKey(request.scheduleId);
      final harness =
          _Harness(now: now, operations: operations, registry: registry)
            ..processRunner.enqueueStatus(
              names,
              activeState: 'inactive',
              subState: 'dead',
              unitFileState: 'disabled',
            )
            ..processRunner.enqueueSuccess()
            ..processRunner.enqueueSuccess()
            ..processRunner.enqueueStatus(names);

      await harness.scheduler.schedule(request);

      expect(
        operations,
        orderedEquals(<String>[
          'registry.load',
          'driver.status',
          'factory.create',
          'unitStore.beginInstall',
          'install.apply',
          'driver.reload',
          'driver.enable',
          'driver.status',
          'registry.replace',
          'install.finalize',
        ]),
      );
      expect(harness.registryStore.current.generation, 5);
      expect(
        harness.registryStore.current.entries.single.requestFingerprint,
        fingerprint,
      );
    });

    test(
      'changed fingerprint replaces without a preliminary status check',
      () async {
        final operations = <String>[];
        final request = _request(
          scheduleId: 'task-changed',
          scheduledAtUtc: now.add(const Duration(hours: 5)),
          title: 'Changed title',
        );
        final registry = _registry(
          generation: 9,
          entries: <LinuxSystemdScheduleRegistryEntry>[
            _entry(request, _fingerprint('0')),
          ],
        );
        final names = LinuxSystemdUnitNames.forScheduleKey(request.scheduleId);
        final harness =
            _Harness(now: now, operations: operations, registry: registry)
              ..processRunner.enqueueSuccess()
              ..processRunner.enqueueSuccess()
              ..processRunner.enqueueStatus(names);

        await harness.scheduler.schedule(request);

        expect(
          operations,
          orderedEquals(<String>[
            'registry.load',
            'factory.create',
            'unitStore.beginInstall',
            'install.apply',
            'driver.reload',
            'driver.enable',
            'driver.status',
            'registry.replace',
            'install.finalize',
          ]),
        );
        expect(harness.registryStore.current.generation, 10);
        expect(
          harness.registryStore.current.entries.single.requestFingerprint,
          isNot(_fingerprint('0')),
        );
      },
    );

    test('first future schedule creates generation one', () async {
      final request = _request(
        scheduleId: 'task-first-generation',
        scheduledAtUtc: now.add(const Duration(hours: 6)),
      );
      final names = LinuxSystemdUnitNames.forScheduleKey(request.scheduleId);
      final harness = _Harness(now: now)
        ..processRunner.enqueueSuccess()
        ..processRunner.enqueueSuccess()
        ..processRunner.enqueueStatus(names);

      await harness.scheduler.schedule(request);

      expect(harness.registryStore.current.generation, 1);
      expect(harness.registryStore.current.entries, hasLength(1));
    });

    test(
      'successful entry contains exact owner time names and fingerprint',
      () async {
        final request = _request(
          scheduleId: 'task-registry-entry',
          scheduledAtUtc: now.add(const Duration(hours: 7)),
        );
        final names = LinuxSystemdUnitNames.forScheduleKey(request.scheduleId);
        final expectedFingerprint = await const _FingerprintHarness().compute(
          request,
        );
        final harness = _Harness(now: now)
          ..processRunner.enqueueSuccess()
          ..processRunner.enqueueSuccess()
          ..processRunner.enqueueStatus(names);

        await harness.scheduler.schedule(request);

        final entry = harness.registryStore.current.entries.single;
        expect(entry.scheduleId, request.scheduleId);
        expect(entry.owner, request.owner);
        expect(entry.scheduledAtUtc, request.scheduledAtUtc);
        expect(entry.timerName.value, names.timerFileName);
        expect(entry.serviceFileName, names.serviceFileName);
        expect(entry.requestFingerprint, expectedFingerprint);
      },
    );
  });

  group('due schedule flow', () {
    test('removes stale registered state completely before showNow', () async {
      final operations = <String>[];
      final request = _request(
        scheduleId: 'task-due-stale',
        scheduledAtUtc: now,
      );
      final names = LinuxSystemdUnitNames.forScheduleKey(request.scheduleId);
      final registry = _registry(
        generation: 3,
        entries: <LinuxSystemdScheduleRegistryEntry>[
          _entry(request, _fingerprint('1')),
        ],
      );
      final harness =
          _Harness(now: now, operations: operations, registry: registry)
            ..processRunner.enqueueSuccess()
            ..processRunner.enqueueStatus(
              names,
              activeState: 'inactive',
              subState: 'dead',
              unitFileState: 'disabled',
            )
            ..processRunner.enqueueSuccess();

      await harness.scheduler.schedule(request);

      expect(
        operations,
        orderedEquals(<String>[
          'registry.load',
          'unitStore.beginRemove',
          'driver.disable',
          'driver.status',
          'remove.apply',
          'driver.reload',
          'registry.replace',
          'remove.finalize',
          'gateway.showNow',
        ]),
      );
      expect(harness.registryStore.current.generation, 4);
      expect(harness.registryStore.current.entries, isEmpty);
      expect(harness.unitStore.removeNames.single, names);
      expect(harness.unitStore.installUnits, isEmpty);
    });

    test('uses privacy content and the canonical encoded payload', () async {
      final request = _request(
        scheduleId: 'task-due-private',
        scheduledAtUtc: now.subtract(const Duration(seconds: 1)),
        privacyMode: NotificationPrivacyMode.private,
        payload: const <String, String>{
          'route': '/tasks/42',
          'source': 'notification',
        },
      );
      final names = LinuxSystemdUnitNames.forScheduleKey(request.scheduleId);
      final harness = _Harness(now: now)
        ..processRunner.enqueueSuccess()
        ..processRunner.enqueueStatus(
          names,
          activeState: 'inactive',
          subState: 'dead',
          unitFileState: 'disabled',
        )
        ..processRunner.enqueueSuccess();

      await harness.scheduler.schedule(request);

      final call = harness.gateway.calls.single;
      expect(call.kind, 'showNow');
      expect(call.id, StableNotificationId.fromScheduleId(request.scheduleId));
      expect(call.title, 'برج');
      expect(call.body, 'یک یادآور جدید دارید.');
      expect(call.payload, NotificationPayloadCodec.encode(request));
      expect(
        NotificationPayloadCodec.decode(call.payload!).owner,
        request.owner,
      );
      expect(harness.unitStore.installUnits, isEmpty);
      expect(harness.registryStore.replacements, isEmpty);
    });
  });

  group('temporary non-schedule methods', () {
    test(
      'cancelByOwner is a no-op only when no registered entry matches',
      () async {
        final owner = NotificationOwner(
          type: NotificationOwnerType.task,
          id: 'missing-owner',
        );
        final harness = _Harness(now: now);

        await harness.scheduler.cancelByOwner(owner);

        expect(harness.registryStore.loadCount, 1);
        expect(harness.registryStore.replacements, isEmpty);
      },
    );

    test('reconcile accepts empty input', () async {
      final harness = _Harness(now: now);

      await harness.scheduler.reconcile(const <NotificationRequest>[]);

      expect(harness.registryStore.loadCount, 1);
      expect(harness.registryStore.discoveryCount, 1);
      expect(harness.registryStore.replacements, isEmpty);
    });
  });
}

final class _Harness {
  _Harness({
    required DateTime now,
    List<String>? operations,
    LinuxSystemdScheduleRegistry? registry,
  }) : operations = operations ?? <String>[] {
    gateway = RecordingNativeNotificationGateway(operations: this.operations);
    factory = _RecordingDeliveryFactory(this.operations);
    unitStore = FakeLinuxSystemdUnitStore(operations: this.operations);
    registryStore = FakeLinuxSystemdScheduleRegistryStore(
      initial: registry ?? LinuxSystemdScheduleRegistry.empty(),
      operations: this.operations,
    );
    processRunner = ControlledLinuxProcessRunner(operations: this.operations);

    scheduler = LinuxSystemdNotificationScheduler(
      clock: FixedAppClock(utcValue: now, localValue: now),
      gateway: gateway,
      commandFactory: factory,
      renderer: const LinuxSystemdUnitRenderer(),
      unitStore: unitStore,
      driver: LinuxSystemdUserDriver(processRunner: processRunner),
      registryStore: registryStore,
      fingerprint: LinuxNotificationRequestFingerprint(),
    );
  }

  final List<String> operations;

  late final RecordingNativeNotificationGateway gateway;
  late final _RecordingDeliveryFactory factory;
  late final FakeLinuxSystemdUnitStore unitStore;
  late final FakeLinuxSystemdScheduleRegistryStore registryStore;
  late final ControlledLinuxProcessRunner processRunner;
  late final LinuxSystemdNotificationScheduler scheduler;
}

final class _RecordingDeliveryFactory
    implements LinuxNotificationDeliveryCommandFactory {
  _RecordingDeliveryFactory(this.operations);

  final List<String> operations;
  final List<NotificationRequest> requests = <NotificationRequest>[];
  final List<LinuxSystemdNotificationUnit> units =
      <LinuxSystemdNotificationUnit>[];

  @override
  Future<LinuxSystemdNotificationUnit> create(
    NotificationRequest request,
  ) async {
    operations.add('factory.create');
    requests.add(request);

    final unit = LinuxSystemdNotificationUnit(
      scheduleKey: request.scheduleId,
      scheduledAtUtc: request.scheduledAtUtc,
      executablePath: '/opt/borj/borj',
      arguments: <String>['--deliver-notification', request.scheduleId],
    );
    units.add(unit);
    return unit;
  }
}

final class _FingerprintHarness {
  const _FingerprintHarness();

  Future<String> compute(NotificationRequest request) {
    return LinuxNotificationRequestFingerprint().compute(request);
  }
}

NotificationRequest _request({
  required String scheduleId,
  required DateTime scheduledAtUtc,
  String title = 'Reminder title',
  NotificationPrivacyMode privacyMode = NotificationPrivacyMode.full,
  Map<String, String> payload = const <String, String>{'route': '/tasks/42'},
}) {
  return NotificationRequest(
    scheduleId: scheduleId,
    owner: NotificationOwner(type: NotificationOwnerType.task, id: 'task-42'),
    title: title,
    body: 'Reminder body',
    scheduledAtUtc: scheduledAtUtc,
    privacyMode: privacyMode,
    payload: payload,
  );
}

LinuxSystemdScheduleRegistryEntry _entry(
  NotificationRequest request,
  String fingerprint,
) {
  final names = LinuxSystemdUnitNames.forScheduleKey(request.scheduleId);

  return LinuxSystemdScheduleRegistryEntry(
    scheduleId: request.scheduleId,
    owner: request.owner,
    timerName: LinuxSystemdTimerName.parse(names.timerFileName),
    serviceFileName: names.serviceFileName,
    scheduledAtUtc: request.scheduledAtUtc,
    requestFingerprint: fingerprint,
  );
}

LinuxSystemdScheduleRegistry _registry({
  required int generation,
  required Iterable<LinuxSystemdScheduleRegistryEntry> entries,
}) {
  return LinuxSystemdScheduleRegistry(
    schemaVersion: LinuxSystemdScheduleRegistry.currentSchemaVersion,
    generation: generation,
    entries: entries,
  );
}

String _fingerprint(String character) {
  if (character.length != 1) {
    throw ArgumentError.value(
      character,
      'character',
      'must contain exactly one character',
    );
  }

  return List<String>.filled(64, character).join();
}
