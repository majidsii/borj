import 'dart:async';

import 'package:borj/core/notifications/notification_response_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationResponseSource runtime payloads', () {
    test('emits a runtime payload to an active listener', () async {
      final source = NotificationResponseSource();
      final received = <String?>[];
      final subscription = source.payloads.listen(received.add);

      source.publishRuntimePayload('{"version":1,"route":"/tasks/task-1"}');
      await _flushEvents();

      expect(received, const <String?>[
        '{"version":1,"route":"/tasks/task-1"}',
      ]);

      await subscription.cancel();
      await source.close();
    });

    test('preserves runtime payload order', () async {
      final source = NotificationResponseSource();
      final received = <String?>[];
      final subscription = source.payloads.listen(received.add);

      source
        ..publishRuntimePayload('first')
        ..publishRuntimePayload('second')
        ..publishRuntimePayload('third');
      await _flushEvents();

      expect(received, const <String?>['first', 'second', 'third']);

      await subscription.cancel();
      await source.close();
    });

    test('broadcasts one runtime callback to all active listeners', () async {
      final source = NotificationResponseSource();
      final first = <String?>[];
      final second = <String?>[];
      final firstSubscription = source.payloads.listen(first.add);
      final secondSubscription = source.payloads.listen(second.add);

      source.publishRuntimePayload('payload');
      await _flushEvents();

      expect(first, const <String?>['payload']);
      expect(second, const <String?>['payload']);

      await firstSubscription.cancel();
      await secondSubscription.cancel();
      await source.close();
    });

    test(
      'forwards null and malformed payloads without decoding them',
      () async {
        final source = NotificationResponseSource();
        final received = <String?>[];
        final subscription = source.payloads.listen(received.add);

        source
          ..publishRuntimePayload(null)
          ..publishRuntimePayload('{not-json');
        await _flushEvents();

        expect(received, const <String?>[null, '{not-json']);

        await subscription.cancel();
        await source.close();
      },
    );

    test('ignores late runtime callbacks after close', () async {
      final source = NotificationResponseSource();
      final received = <String?>[];
      final subscription = source.payloads.listen(received.add);
      await source.close();

      source.publishRuntimePayload('late');
      await _flushEvents();

      expect(received, isEmpty);
      await subscription.cancel();
    });

    test('close is idempotent', () async {
      final source = NotificationResponseSource();

      await source.close();
      await source.close();

      expect(source.isClosed, isTrue);
    });
  });

  group('NotificationColdStartGateway', () {
    test(
      'returns the launch payload when notification opened the app',
      () async {
        var loadCount = 0;
        final gateway = NotificationColdStartGateway(() async {
          loadCount++;
          return const NotificationLaunchDetails(
            didLaunchFromNotification: true,
            payload: '{"version":1,"route":"/tasks/task-1"}',
          );
        });

        final payload = await gateway.takeInitialPayload();

        expect(payload, '{"version":1,"route":"/tasks/task-1"}');
        expect(loadCount, 1);
      },
    );

    test(
      'ignores payload when launch was not caused by a notification',
      () async {
        final gateway = NotificationColdStartGateway(
          () async => const NotificationLaunchDetails(
            didLaunchFromNotification: false,
            payload: 'must-not-be-routed',
          ),
        );

        expect(await gateway.takeInitialPayload(), isNull);
      },
    );

    test('consumes cold-start launch details only once', () async {
      var loadCount = 0;
      final gateway = NotificationColdStartGateway(() async {
        loadCount++;
        return const NotificationLaunchDetails(
          didLaunchFromNotification: true,
          payload: 'initial',
        );
      });

      expect(await gateway.takeInitialPayload(), 'initial');
      expect(await gateway.takeInitialPayload(), isNull);
      expect(await gateway.takeInitialPayload(), isNull);
      expect(loadCount, 1);
    });

    test(
      'serializes concurrent reads so only one caller receives payload',
      () async {
        var loadCount = 0;
        final loaderStarted = Completer<void>();
        final releaseLoader = Completer<void>();
        final gateway = NotificationColdStartGateway(() async {
          loadCount++;
          loaderStarted.complete();
          await releaseLoader.future;
          return const NotificationLaunchDetails(
            didLaunchFromNotification: true,
            payload: 'initial',
          );
        });

        final firstRead = gateway.takeInitialPayload();
        await loaderStarted.future;
        final secondRead = gateway.takeInitialPayload();
        final thirdRead = gateway.takeInitialPayload();
        releaseLoader.complete();

        expect(await firstRead, 'initial');
        expect(await secondRead, isNull);
        expect(await thirdRead, isNull);
        expect(loadCount, 1);
      },
    );

    test('allows a retry when reading launch details throws', () async {
      var loadCount = 0;
      final gateway = NotificationColdStartGateway(() async {
        loadCount++;
        if (loadCount == 1) {
          throw StateError('plugin unavailable');
        }
        return const NotificationLaunchDetails(
          didLaunchFromNotification: true,
          payload: 'recovered',
        );
      });

      await expectLater(
        gateway.takeInitialPayload(),
        throwsA(isA<StateError>()),
      );
      expect(await gateway.takeInitialPayload(), 'recovered');
      expect(await gateway.takeInitialPayload(), isNull);
      expect(loadCount, 2);
    });

    test(
      'treats a notification launch with null payload as consumed',
      () async {
        var loadCount = 0;
        final gateway = NotificationColdStartGateway(() async {
          loadCount++;
          return const NotificationLaunchDetails(
            didLaunchFromNotification: true,
          );
        });

        expect(await gateway.takeInitialPayload(), isNull);
        expect(await gateway.takeInitialPayload(), isNull);
        expect(loadCount, 1);
      },
    );
  });
}

Future<void> _flushEvents() => Future<void>.delayed(Duration.zero);
