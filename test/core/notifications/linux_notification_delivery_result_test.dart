import 'package:borj/core/notifications/linux_notification_delivery_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LinuxNotificationDeliveryResult', () {
    test('uses zero only for normal, delivered, and missing outcomes', () {
      expect(LinuxNotificationDeliveryResult.normalApplication().exitCode, 0);
      expect(LinuxNotificationDeliveryResult.delivered().exitCode, 0);
      expect(LinuxNotificationDeliveryResult.missingRequest().exitCode, 0);

      expect(
        LinuxNotificationDeliveryResult.invalidArguments(
          StateError('invalid arguments'),
          StackTrace.current,
        ).exitCode,
        isNot(0),
      );
      expect(
        LinuxNotificationDeliveryResult.initializationFailed(
          StateError('initialization failed'),
          StackTrace.current,
        ).exitCode,
        isNot(0),
      );
      expect(
        LinuxNotificationDeliveryResult.lookupFailed(
          StateError('lookup failed'),
          StackTrace.current,
        ).exitCode,
        isNot(0),
      );
      expect(
        LinuxNotificationDeliveryResult.displayFailed(
          StateError('display failed'),
          StackTrace.current,
        ).exitCode,
        isNot(0),
      );
    });

    test('copies and exposes close failures as an immutable list', () {
      final source = <LinuxNotificationDeliveryCloseFailure>[
        LinuxNotificationDeliveryCloseFailure(
          error: StateError('close one'),
          stackTrace: StackTrace.current,
        ),
      ];
      final result = LinuxNotificationDeliveryResult.delivered(
        closeFailures: source,
      );

      source.add(
        LinuxNotificationDeliveryCloseFailure(
          error: StateError('close two'),
          stackTrace: StackTrace.current,
        ),
      );

      expect(result.closeFailures, hasLength(1));
      expect(
        () => result.closeFailures.add(
          LinuxNotificationDeliveryCloseFailure(
            error: StateError('illegal mutation'),
            stackTrace: StackTrace.current,
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('appends close failures without replacing the primary result', () {
      final cause = StateError('private display failure');
      final stackTrace = StackTrace.current;
      final primary = LinuxNotificationDeliveryResult.displayFailed(
        cause,
        stackTrace,
      );
      final closeFailure = LinuxNotificationDeliveryCloseFailure(
        error: StateError('private close failure'),
        stackTrace: StackTrace.current,
      );

      final combined = primary.withCloseFailures(
        <LinuxNotificationDeliveryCloseFailure>[closeFailure],
      );

      expect(combined.kind, LinuxNotificationDeliveryExitKind.displayFailed);
      expect(combined.exitCode, primary.exitCode);
      expect(combined.cause, same(cause));
      expect(combined.causeStackTrace, same(stackTrace));
      expect(combined.closeFailures, orderedEquals(<Object>[closeFailure]));
      expect(primary.closeFailures, isEmpty);
    });

    test('safe string includes types and counts but not private messages', () {
      final result = LinuxNotificationDeliveryResult.lookupFailed(
        StateError('private-schedule-id and persisted title'),
        StackTrace.current,
        closeFailures: <LinuxNotificationDeliveryCloseFailure>[
          LinuxNotificationDeliveryCloseFailure(
            error: ArgumentError('private payload'),
            stackTrace: StackTrace.current,
          ),
        ],
      );

      final description = result.toString();

      expect(description, contains('kind=lookupFailed'));
      expect(description, contains('exitCode='));
      expect(description, contains('causeType=StateError'));
      expect(description, contains('closeFailures=1'));
      expect(description, isNot(contains('private-schedule-id')));
      expect(description, isNot(contains('persisted title')));
      expect(description, isNot(contains('private payload')));
    });
  });
}
