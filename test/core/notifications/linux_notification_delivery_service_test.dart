// Public test doubles keep readable dependency parameter names.
// ignore_for_file: prefer_initializing_formals

import 'package:borj/core/notifications/linux_notification_delivery_exception.dart';
import 'package:borj/core/notifications/linux_notification_delivery_result.dart';
import 'package:borj/core/notifications/linux_notification_delivery_service.dart';
import 'package:borj/core/notifications/native_notification_gateway.dart';
import 'package:borj/core/notifications/notification_owner.dart';
import 'package:borj/core/notifications/notification_payload_codec.dart';
import 'package:borj/core/notifications/notification_request.dart';
import 'package:borj/core/notifications/notification_schedule_repository.dart';
import 'package:borj/core/notifications/stable_notification_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LinuxNotificationDeliveryService', () {
    test(
      'loads the exact request, displays it, and closes resources',
      () async {
        final harness = _Harness(request: _request());

        final result = await harness.service.deliver('task-exact');

        expect(result.kind, LinuxNotificationDeliveryExitKind.delivered);
        expect(result.exitCode, 0);
        expect(result.cause, isNull);
        expect(result.closeFailures, isEmpty);
        expect(harness.repository.lookups, <String>['task-exact']);
        expect(harness.gateway.displays, hasLength(1));
        expect(harness.resources.closeCalls, 1);
        expect(harness.operations, <String>[
          'resources.open',
          'repository.getById:task-exact',
          'gateway.showNow',
          'resources.close',
        ]);
      },
    );

    test('missing request succeeds without displaying', () async {
      final harness = _Harness(request: null);

      final result = await harness.service.deliver('stale-timer');

      expect(result.kind, LinuxNotificationDeliveryExitKind.missingRequest);
      expect(result.exitCode, 0);
      expect(harness.repository.lookups, <String>['stale-timer']);
      expect(harness.gateway.displays, isEmpty);
      expect(harness.resources.closeCalls, 1);
      expect(harness.operations, <String>[
        'resources.open',
        'repository.getById:stale-timer',
        'resources.close',
      ]);
    });

    test('private mode uses policy-safe content', () async {
      final request = _request(
        title: 'PRIVATE_TITLE',
        body: 'PRIVATE_BODY',
        privacyMode: NotificationPrivacyMode.private,
      );
      final harness = _Harness(request: request);

      final result = await harness.service.deliver(request.scheduleId);

      expect(result.kind, LinuxNotificationDeliveryExitKind.delivered);
      final display = harness.gateway.displays.single;
      expect(display.title, 'برج');
      expect(display.body, 'یک یادآور جدید دارید.');
      expect(display.title, isNot(contains('PRIVATE_TITLE')));
      expect(display.body, isNot(contains('PRIVATE_BODY')));
    });

    test('full mode preserves title and body', () async {
      final request = _request(title: 'Public title', body: 'Public body');
      final harness = _Harness(request: request);

      await harness.service.deliver(request.scheduleId);

      final display = harness.gateway.displays.single;
      expect(display.title, request.title);
      expect(display.body, request.body);
    });

    test('uses stable ID and canonical navigation payload', () async {
      final request = _request(
        payload: const <String, String>{
          'z': 'last',
          'route': '/tasks/task-exact',
          'a': 'first',
        },
      );
      final harness = _Harness(request: request);

      await harness.service.deliver(request.scheduleId);

      final display = harness.gateway.displays.single;
      expect(
        display.id,
        StableNotificationId.fromScheduleId(request.scheduleId),
      );
      expect(display.payload, NotificationPayloadCodec.encode(request));

      final decoded = NotificationPayloadCodec.decode(display.payload);
      expect(decoded.scheduleId, request.scheduleId);
      expect(decoded.owner, request.owner);
      expect(decoded.values, request.payload);
    });

    test('initialization failure returns typed non-zero result', () async {
      final cause = StateError('PRIVATE_INITIALIZATION_FAILURE');
      final stackTrace = StackTrace.fromString('initialization-stack-marker');
      final harness = _Harness.openFailure(cause, stackTrace);

      final result = await harness.service.deliver('private-schedule-id');

      expect(
        result.kind,
        LinuxNotificationDeliveryExitKind.initializationFailed,
      );
      expect(result.exitCode, isNot(0));
      expect(result.cause, same(cause));
      expect(
        result.causeStackTrace.toString(),
        contains('initialization-stack-marker'),
      );
      expect(harness.resources.closeCalls, 0);
      expect(
        result.toString(),
        isNot(contains('PRIVATE_INITIALIZATION_FAILURE')),
      );
      expect(result.toString(), isNot(contains('private-schedule-id')));
    });

    test('lookup failure returns typed result and still closes', () async {
      final cause = StateError('PRIVATE_LOOKUP_FAILURE');
      final stackTrace = StackTrace.fromString('lookup-stack-marker');
      final harness = _Harness(
        request: _request(),
        lookupError: cause,
        lookupStackTrace: stackTrace,
      );

      final result = await harness.service.deliver('task-exact');

      expect(result.kind, LinuxNotificationDeliveryExitKind.lookupFailed);
      expect(result.exitCode, isNot(0));
      expect(result.cause, same(cause));
      expect(
        result.causeStackTrace.toString(),
        contains('lookup-stack-marker'),
      );
      expect(harness.gateway.displays, isEmpty);
      expect(harness.resources.closeCalls, 1);
    });

    test('display failure returns typed result and still closes', () async {
      final cause = StateError('PRIVATE_DISPLAY_FAILURE');
      final stackTrace = StackTrace.fromString('display-stack-marker');
      final harness = _Harness(
        request: _request(),
        displayError: cause,
        displayStackTrace: stackTrace,
      );

      final result = await harness.service.deliver('task-exact');

      expect(result.kind, LinuxNotificationDeliveryExitKind.displayFailed);
      expect(result.exitCode, isNot(0));
      expect(result.cause, same(cause));
      expect(
        result.causeStackTrace.toString(),
        contains('display-stack-marker'),
      );
      expect(harness.resources.closeCalls, 1);
    });

    test('close failure is appended after successful delivery', () async {
      final closeCause = StateError('PRIVATE_CLOSE_FAILURE');
      final closeStack = StackTrace.fromString('close-stack-marker');
      final harness = _Harness(
        request: _request(),
        closeError: closeCause,
        closeStackTrace: closeStack,
      );

      final result = await harness.service.deliver('task-exact');

      expect(result.kind, LinuxNotificationDeliveryExitKind.delivered);
      expect(result.exitCode, 0);
      expect(result.cause, isNull);
      expect(result.closeFailures, hasLength(1));
      expect(result.closeFailures.single.error, same(closeCause));
      expect(
        result.closeFailures.single.stackTrace.toString(),
        contains('close-stack-marker'),
      );
      expect(result.toString(), isNot(contains('PRIVATE_CLOSE_FAILURE')));
    });

    test('close failure does not replace primary display failure', () async {
      final displayCause = StateError('PRIVATE_DISPLAY_FAILURE');
      final displayStack = StackTrace.fromString('display-stack-marker');
      final closeCause = ArgumentError('PRIVATE_CLOSE_FAILURE');
      final closeStack = StackTrace.fromString('close-stack-marker');
      final harness = _Harness(
        request: _request(),
        displayError: displayCause,
        displayStackTrace: displayStack,
        closeError: closeCause,
        closeStackTrace: closeStack,
      );

      final result = await harness.service.deliver('task-exact');

      expect(result.kind, LinuxNotificationDeliveryExitKind.displayFailed);
      expect(result.cause, same(displayCause));
      expect(
        result.causeStackTrace.toString(),
        contains('display-stack-marker'),
      );
      expect(result.closeFailures, hasLength(1));
      expect(result.closeFailures.single.error, same(closeCause));
      expect(
        result.closeFailures.single.stackTrace.toString(),
        contains('close-stack-marker'),
      );
    });

    test('delivery exception string is privacy-safe', () {
      final exception = LinuxNotificationDeliveryException.forOperation(
        operation: LinuxNotificationDeliveryOperation.display,
        cause: StateError('PRIVATE_TITLE PRIVATE_BODY PRIVATE_PAYLOAD'),
        causeStackTrace: StackTrace.current,
      );

      final description = exception.toString();

      expect(description, contains('operation=display'));
      expect(description, contains('failure=displayFailed'));
      expect(description, contains('causeType=StateError'));
      expect(description, isNot(contains('PRIVATE_TITLE')));
      expect(description, isNot(contains('PRIVATE_BODY')));
      expect(description, isNot(contains('PRIVATE_PAYLOAD')));
    });

    test('delivery never mutates desired-state repository methods', () async {
      final harness = _Harness(request: _request());

      await harness.service.deliver('task-exact');

      expect(harness.repository.mutations, isEmpty);
    });
  });
}

NotificationRequest _request({
  String scheduleId = 'task-exact',
  String title = 'Task reminder',
  String body = 'Task body',
  Map<String, String> payload = const <String, String>{
    'route': '/tasks/task-exact',
  },
  NotificationPrivacyMode privacyMode = NotificationPrivacyMode.full,
}) {
  return NotificationRequest(
    scheduleId: scheduleId,
    owner: NotificationOwner(
      type: NotificationOwnerType.task,
      id: 'task-owner-42',
    ),
    title: title,
    body: body,
    scheduledAtUtc: DateTime.utc(2026, 8, 2, 12),
    payload: payload,
    privacyMode: privacyMode,
  );
}

final class _Harness {
  _Harness({
    required NotificationRequest? request,
    Object? lookupError,
    StackTrace? lookupStackTrace,
    Object? displayError,
    StackTrace? displayStackTrace,
    Object? closeError,
    StackTrace? closeStackTrace,
  }) : operations = <String>[] {
    repository = _Repository(
      operations: operations,
      request: request,
      lookupError: lookupError,
      lookupStackTrace: lookupStackTrace,
    );
    gateway = _Gateway(
      operations: operations,
      displayError: displayError,
      displayStackTrace: displayStackTrace,
    );
    resources = _Resources(
      operations: operations,
      repository: repository,
      gateway: gateway,
      closeError: closeError,
      closeStackTrace: closeStackTrace,
    );
    resourcesFactory = _ResourcesFactory(
      operations: operations,
      resources: resources,
    );
    service = LinuxNotificationDeliveryService(
      resourcesFactory: resourcesFactory,
    );
  }

  _Harness.openFailure(Object error, StackTrace stackTrace)
    : operations = <String>[] {
    repository = _Repository(operations: operations, request: null);
    gateway = _Gateway(operations: operations);
    resources = _Resources(
      operations: operations,
      repository: repository,
      gateway: gateway,
    );
    resourcesFactory = _ResourcesFactory.failure(
      operations: operations,
      error: error,
      stackTrace: stackTrace,
    );
    service = LinuxNotificationDeliveryService(
      resourcesFactory: resourcesFactory,
    );
  }

  final List<String> operations;
  late final _Repository repository;
  late final _Gateway gateway;
  late final _Resources resources;
  late final _ResourcesFactory resourcesFactory;
  late final LinuxNotificationDeliveryService service;
}

final class _ResourcesFactory
    implements LinuxNotificationDeliveryResourcesFactory {
  _ResourcesFactory({
    required this.operations,
    required LinuxNotificationDeliveryResources resources,
  }) : _resources = resources,
       _error = null,
       _stackTrace = null;

  _ResourcesFactory.failure({
    required this.operations,
    required Object error,
    required StackTrace stackTrace,
  }) : _resources = null,
       _error = error,
       _stackTrace = stackTrace;

  final List<String> operations;
  final LinuxNotificationDeliveryResources? _resources;
  final Object? _error;
  final StackTrace? _stackTrace;

  @override
  Future<LinuxNotificationDeliveryResources> open() async {
    operations.add('resources.open');

    final error = _error;
    if (error != null) {
      Error.throwWithStackTrace(error, _stackTrace!);
    }

    return _resources!;
  }
}

final class _Resources implements LinuxNotificationDeliveryResources {
  _Resources({
    required this.operations,
    required this.repository,
    required this.gateway,
    this.closeError,
    this.closeStackTrace,
  });

  final List<String> operations;

  @override
  final NotificationScheduleRepository repository;

  @override
  final NativeNotificationGateway gateway;

  final Object? closeError;
  final StackTrace? closeStackTrace;
  int closeCalls = 0;

  @override
  Future<void> close() async {
    closeCalls += 1;
    operations.add('resources.close');

    final error = closeError;
    if (error != null) {
      Error.throwWithStackTrace(error, closeStackTrace ?? StackTrace.current);
    }
  }
}

final class _Repository implements NotificationScheduleRepository {
  _Repository({
    required this.operations,
    required this.request,
    this.lookupError,
    this.lookupStackTrace,
  });

  final List<String> operations;
  final NotificationRequest? request;
  final Object? lookupError;
  final StackTrace? lookupStackTrace;
  final List<String> lookups = <String>[];
  final List<String> mutations = <String>[];

  @override
  Future<NotificationRequest?> getById(String scheduleId) async {
    lookups.add(scheduleId);
    operations.add('repository.getById:$scheduleId');

    final error = lookupError;
    if (error != null) {
      Error.throwWithStackTrace(error, lookupStackTrace ?? StackTrace.current);
    }

    return request;
  }

  @override
  Future<List<NotificationRequest>> getAll() async {
    throw UnsupportedError('getAll is outside this delivery test.');
  }

  @override
  Stream<List<NotificationRequest>> watchAll() {
    throw UnsupportedError('watchAll is outside this delivery test.');
  }

  @override
  Future<void> upsert(NotificationRequest request) async {
    mutations.add('upsert');
  }

  @override
  Future<void> delete(String scheduleId) async {
    mutations.add('delete');
  }

  @override
  Future<void> deleteByOwner(NotificationOwner owner) async {
    mutations.add('deleteByOwner');
  }

  @override
  Future<void> replaceAll(List<NotificationRequest> expected) async {
    mutations.add('replaceAll');
  }
}

final class _Display {
  const _Display({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final String title;
  final String body;
  final String payload;
}

final class _Gateway implements NativeNotificationGateway {
  _Gateway({
    required this.operations,
    this.displayError,
    this.displayStackTrace,
  });

  final List<String> operations;
  final Object? displayError;
  final StackTrace? displayStackTrace;
  final List<_Display> displays = <_Display>[];

  @override
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    operations.add('gateway.showNow');

    final error = displayError;
    if (error != null) {
      Error.throwWithStackTrace(error, displayStackTrace ?? StackTrace.current);
    }

    displays.add(_Display(id: id, title: title, body: body, payload: payload));
  }

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAtUtc,
    required String payload,
  }) async {
    throw UnsupportedError('schedule is outside this delivery test.');
  }

  @override
  Future<void> cancel(int id) async {
    throw UnsupportedError('cancel is outside this delivery test.');
  }

  @override
  Future<List<NativePendingNotification>> pending() async {
    throw UnsupportedError('pending is outside this delivery test.');
  }
}
