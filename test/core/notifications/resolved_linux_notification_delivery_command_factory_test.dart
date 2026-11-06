import 'dart:async';

import 'package:borj/core/notifications/linux_executable_path_source.dart';
import 'package:borj/core/notifications/linux_notification_delivery_invocation.dart';
import 'package:borj/core/notifications/notification_owner.dart';
import 'package:borj/core/notifications/notification_request.dart';
import 'package:borj/core/notifications/resolved_linux_notification_delivery_command_factory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResolvedLinuxNotificationDeliveryCommandFactory', () {
    test('creates the exact shell-free hidden delivery command', () async {
      final source = _Source('/opt/borj/borj');
      final factory = ResolvedLinuxNotificationDeliveryCommandFactory(
        executablePathSource: source,
      );
      final request = _request('task-42');

      final unit = await factory.create(request);

      expect(unit.scheduleKey, request.scheduleId);
      expect(unit.scheduledAtUtc, request.scheduledAtUtc);
      expect(unit.executablePath, '/opt/borj/borj');
      expect(
        unit.arguments,
        orderedEquals(<String>[
          linuxNotificationDeliveryFlag,
          request.scheduleId,
        ]),
      );
    });

    test('resolves and validates the executable only once', () async {
      final source = _Source('/opt/borj/borj');
      final factory = ResolvedLinuxNotificationDeliveryCommandFactory(
        executablePathSource: source,
      );

      final first = await factory.create(_request('task-alpha'));
      final second = await factory.create(_request('task-beta'));

      expect(source.resolveCount, 1);
      expect(first.executablePath, second.executablePath);
      expect(first.arguments.last, 'task-alpha');
      expect(second.arguments.last, 'task-beta');
    });

    test('shares one in-flight executable resolution', () async {
      final source = _ControlledSource();
      final factory = ResolvedLinuxNotificationDeliveryCommandFactory(
        executablePathSource: source,
      );

      final firstFuture = factory.create(_request('task-alpha'));
      final secondFuture = factory.create(_request('task-beta'));

      expect(source.resolveCount, 1);

      source.complete('/opt/borj/borj');

      final units = await Future.wait(<Future<Object>>[
        firstFuture,
        secondFuture,
      ]);
      expect(units, hasLength(2));
      expect(source.resolveCount, 1);
    });

    test('does not embed private request content in command fields', () async {
      const secretTitle = 'PRIVATE_TITLE';
      const secretBody = 'PRIVATE_BODY';
      const secretPayload = 'PRIVATE_PAYLOAD';
      const secretOwner = 'PRIVATE_OWNER';
      final factory = ResolvedLinuxNotificationDeliveryCommandFactory(
        executablePathSource: _Source('/opt/borj/app'),
      );
      final request = NotificationRequest(
        scheduleId: 'task-private',
        owner: NotificationOwner(
          type: NotificationOwnerType.task,
          id: secretOwner,
        ),
        title: secretTitle,
        body: secretBody,
        scheduledAtUtc: DateTime.utc(2026, 8, 2, 12),
        payload: const <String, String>{'secret': secretPayload},
        privacyMode: NotificationPrivacyMode.private,
      );

      final unit = await factory.create(request);
      final commandText = <String>[
        unit.executablePath,
        ...unit.arguments,
      ].join(' ');

      expect(commandText, isNot(contains(secretTitle)));
      expect(commandText, isNot(contains(secretBody)));
      expect(commandText, isNot(contains(secretPayload)));
      expect(commandText, isNot(contains(secretOwner)));
      expect(commandText, contains(request.scheduleId));
    });

    test('preserves executable source failure and stack trace', () async {
      final cause = StateError('PRIVATE_RESOLUTION_FAILURE');
      final stackTrace = StackTrace.fromString('resolution-stack-marker');
      final factory = ResolvedLinuxNotificationDeliveryCommandFactory(
        executablePathSource: _Source.failure(cause, stackTrace),
      );

      Object? actualError;
      StackTrace? actualStackTrace;
      try {
        await factory.create(_request('task-failure'));
      } catch (error, caughtStackTrace) {
        actualError = error;
        actualStackTrace = caughtStackTrace;
      }

      expect(actualError, same(cause));
      expect(actualStackTrace.toString(), contains('resolution-stack-marker'));
    });
  });
}

NotificationRequest _request(String scheduleId) {
  return NotificationRequest(
    scheduleId: scheduleId,
    owner: NotificationOwner(
      type: NotificationOwnerType.task,
      id: 'owner-$scheduleId',
    ),
    title: 'Reminder',
    body: 'Body',
    scheduledAtUtc: DateTime.utc(2026, 8, 2, 12),
    payload: const <String, String>{'route': '/tasks'},
  );
}

final class _Source implements LinuxExecutablePathSource {
  _Source(this.path) : error = null, errorStackTrace = null;

  _Source.failure(this.error, this.errorStackTrace) : path = null;

  final String? path;
  final Object? error;
  final StackTrace? errorStackTrace;
  int resolveCount = 0;

  @override
  Future<String> resolve() async {
    resolveCount += 1;
    final configuredError = error;
    if (configuredError != null) {
      Error.throwWithStackTrace(
        configuredError,
        errorStackTrace ?? StackTrace.current,
      );
    }
    return path!;
  }
}

final class _ControlledSource implements LinuxExecutablePathSource {
  final _completer = Completer<String>();
  int resolveCount = 0;

  void complete(String path) => _completer.complete(path);

  @override
  Future<String> resolve() {
    resolveCount += 1;
    return _completer.future;
  }
}
