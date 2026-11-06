import 'package:borj/core/notifications/linux_notification_delivery_invocation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LinuxNotificationDeliveryInvocation.parse', () {
    test('uses normal startup when the hidden flag is absent', () {
      expect(
        LinuxNotificationDeliveryInvocation.parse(const <String>[]),
        isA<LinuxNormalApplicationInvocation>(),
      );
      expect(
        LinuxNotificationDeliveryInvocation.parse(const <String>[
          '--route',
          '/dashboard',
        ]),
        isA<LinuxNormalApplicationInvocation>(),
      );
      expect(
        LinuxNotificationDeliveryInvocation.parse(const <String>[
          '--deliver-notification-other',
          'task-42',
        ]),
        isA<LinuxNormalApplicationInvocation>(),
      );
    });

    test('parses the exact hidden delivery command', () {
      final invocation = LinuxNotificationDeliveryInvocation.parse(
        const <String>['--deliver-notification', 'task-42'],
      );

      expect(invocation, isA<LinuxHiddenNotificationDeliveryInvocation>());
      expect(
        (invocation as LinuxHiddenNotificationDeliveryInvocation).scheduleId,
        'task-42',
      );
    });

    test('preserves valid Unicode and punctuation in one argument', () {
      const scheduleId = 'یادآور-42:alpha_β.v2/@home';

      final invocation = LinuxNotificationDeliveryInvocation.parse(
        const <String>['--deliver-notification', scheduleId],
      );

      expect(
        (invocation as LinuxHiddenNotificationDeliveryInvocation).scheduleId,
        scheduleId,
      );
    });

    for (final arguments in <List<String>>[
      const <String>['--deliver-notification'],
      const <String>['--deliver-notification', 'task-42', 'extra'],
      const <String>['prefix', '--deliver-notification', 'task-42'],
      const <String>['--deliver-notification', '--deliver-notification'],
    ]) {
      test('rejects invalid hidden command shape: $arguments', () {
        expect(
          () => LinuxNotificationDeliveryInvocation.parse(arguments),
          throwsA(
            isA<LinuxNotificationDeliveryArgumentException>().having(
              (error) => error.failure,
              'failure',
              LinuxNotificationDeliveryArgumentFailure.invalidShape,
            ),
          ),
        );
      });
    }

    for (final scheduleId in <String>[
      '',
      ' ',
      ' task-42',
      'task-42 ',
      '\ttask-42',
      'task\n42',
      'task\r42',
      'task\u000042',
      'task\u001f42',
      'task\u007f42',
      'task\u008542',
      'task\u009f42',
    ]) {
      test(
        'rejects unsafe schedule ID code units: ${scheduleId.codeUnits}',
        () {
          expect(
            () => LinuxNotificationDeliveryInvocation.parse(<String>[
              '--deliver-notification',
              scheduleId,
            ]),
            throwsA(
              isA<LinuxNotificationDeliveryArgumentException>().having(
                (error) => error.failure,
                'failure',
                LinuxNotificationDeliveryArgumentFailure.invalidScheduleId,
              ),
            ),
          );
        },
      );
    }

    test('argument exception string does not expose raw arguments', () {
      const secret = 'private-schedule-id';
      Object? actual;

      try {
        LinuxNotificationDeliveryInvocation.parse(const <String>[
          '--deliver-notification',
          '$secret\n',
        ]);
      } catch (error) {
        actual = error;
      }

      expect(actual, isA<LinuxNotificationDeliveryArgumentException>());
      expect(actual.toString(), contains('invalidScheduleId'));
      expect(actual.toString(), isNot(contains(secret)));
    });
  });
}
