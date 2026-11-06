import 'dart:async';

import 'package:borj/core/notifications/notification_navigation_queue.dart';
import 'package:borj/core/notifications/notification_response_source.dart';
import 'package:borj/core/notifications/notification_route_intent.dart';
import 'package:borj/core/notifications/notification_route_parser.dart';
import 'package:borj/core/notifications/notification_routing_startup_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationRoutingStartupService cold start', () {
    test('parses and enqueues a valid cold-start payload', () async {
      final source = NotificationResponseSource();
      final router = _RecordingNotificationRouterAdapter();
      final queue = NotificationNavigationQueue()..markRouterReady(router);
      final service = _createService(
        source: source,
        queue: queue,
        loadDetails: () async => const NotificationLaunchDetails(
          didLaunchFromNotification: true,
          payload: '{"version":1,"route":"/tasks/task-1"}',
        ),
      );

      await service.start();

      expect(service.isStarted, isTrue);
      expect(router.navigatedIntents, const <NotificationRouteIntent>[
        NotificationTaskRouteIntent('task-1'),
      ]);

      await service.dispose();
      await source.close();
    });

    test('ignores an invalid cold-start payload', () async {
      final source = NotificationResponseSource();
      final router = _RecordingNotificationRouterAdapter();
      final queue = NotificationNavigationQueue()..markRouterReady(router);
      final service = _createService(
        source: source,
        queue: queue,
        loadDetails: () async => const NotificationLaunchDetails(
          didLaunchFromNotification: true,
          payload: '{not-json',
        ),
      );

      await service.start();

      expect(service.isStarted, isTrue);
      expect(router.navigatedIntents, isEmpty);

      await service.dispose();
      await source.close();
    });

    test('does not route a normal application launch', () async {
      final source = NotificationResponseSource();
      final router = _RecordingNotificationRouterAdapter();
      final queue = NotificationNavigationQueue()..markRouterReady(router);
      final service = _createService(
        source: source,
        queue: queue,
        loadDetails: () async => const NotificationLaunchDetails(
          didLaunchFromNotification: false,
          payload: '{"version":1,"route":"/tasks/must-not-open"}',
        ),
      );

      await service.start();

      expect(router.navigatedIntents, isEmpty);

      await service.dispose();
      await source.close();
    });

    test(
      'registers runtime listening before loading cold-start details',
      () async {
        final source = NotificationResponseSource();
        final router = _RecordingNotificationRouterAdapter();
        final queue = NotificationNavigationQueue()..markRouterReady(router);
        final service = _createService(
          source: source,
          queue: queue,
          loadDetails: () async {
            source.publishRuntimePayload(
              '{"version":1,"route":"/habits/habit-1"}',
            );
            return const NotificationLaunchDetails(
              didLaunchFromNotification: true,
              payload: '{"version":1,"route":"/tasks/task-1"}',
            );
          },
        );

        await service.start();

        expect(router.navigatedIntents, const <NotificationRouteIntent>[
          NotificationTaskRouteIntent('task-1'),
          NotificationHabitRouteIntent('habit-1'),
        ]);

        await service.dispose();
        await source.close();
      },
    );
  });

  group('NotificationRoutingStartupService runtime taps', () {
    test('parses and enqueues runtime payloads after startup', () async {
      final source = NotificationResponseSource();
      final router = _RecordingNotificationRouterAdapter();
      final queue = NotificationNavigationQueue()..markRouterReady(router);
      final service = _createService(
        source: source,
        queue: queue,
        loadDetails: _normalLaunch,
      );
      await service.start();

      source.publishRuntimePayload('{"version":1,"route":"/goals/goal-1"}');

      expect(router.navigatedIntents, const <NotificationRouteIntent>[
        NotificationGoalRouteIntent('goal-1'),
      ]);

      await service.dispose();
      await source.close();
    });

    test('ignores null, malformed, and unknown runtime payloads', () async {
      final source = NotificationResponseSource();
      final router = _RecordingNotificationRouterAdapter();
      final queue = NotificationNavigationQueue()..markRouterReady(router);
      final service = _createService(
        source: source,
        queue: queue,
        loadDetails: _normalLaunch,
      );
      await service.start();

      source
        ..publishRuntimePayload(null)
        ..publishRuntimePayload('{not-json')
        ..publishRuntimePayload('{"version":1,"route":"/unknown/value"}');

      expect(router.navigatedIntents, isEmpty);

      await service.dispose();
      await source.close();
    });
  });

  group('NotificationRoutingStartupService retry safety', () {
    test(
      'shares one in-flight startup operation across concurrent calls',
      () async {
        final source = NotificationResponseSource();
        final queue = NotificationNavigationQueue();
        final loaderStarted = Completer<void>();
        final releaseLoader = Completer<void>();
        var loadCount = 0;
        final service = _createService(
          source: source,
          queue: queue,
          loadDetails: () async {
            loadCount++;
            loaderStarted.complete();
            await releaseLoader.future;
            return const NotificationLaunchDetails(
              didLaunchFromNotification: false,
            );
          },
        );

        final firstStart = service.start();
        await loaderStarted.future;
        final secondStart = service.start();
        final thirdStart = service.start();

        expect(identical(firstStart, secondStart), isTrue);
        expect(identical(firstStart, thirdStart), isTrue);

        releaseLoader.complete();
        await Future.wait(<Future<void>>[firstStart, secondStart, thirdStart]);

        expect(loadCount, 1);
        expect(service.isStarted, isTrue);

        await service.dispose();
        await source.close();
      },
    );

    test(
      'repeated successful starts do not duplicate runtime listeners',
      () async {
        final source = NotificationResponseSource();
        final router = _RecordingNotificationRouterAdapter();
        final queue = NotificationNavigationQueue()..markRouterReady(router);
        var loadCount = 0;
        final service = _createService(
          source: source,
          queue: queue,
          loadDetails: () async {
            loadCount++;
            return const NotificationLaunchDetails(
              didLaunchFromNotification: false,
            );
          },
        );

        await service.start();
        await service.start();
        await service.start();
        source.publishRuntimePayload(
          '{"version":1,"route":"/finance/debts/debt-1"}',
        );

        expect(loadCount, 1);
        expect(router.navigatedIntents, const <NotificationRouteIntent>[
          NotificationDebtRouteIntent('debt-1'),
        ]);

        await service.dispose();
        await source.close();
      },
    );

    test(
      'allows cold-start retry without duplicating runtime delivery',
      () async {
        final source = NotificationResponseSource();
        final router = _RecordingNotificationRouterAdapter();
        final queue = NotificationNavigationQueue()..markRouterReady(router);
        var loadCount = 0;
        final service = _createService(
          source: source,
          queue: queue,
          loadDetails: () async {
            loadCount++;
            if (loadCount == 1) {
              source.publishRuntimePayload('{"version":1,"route":"/settings"}');
              throw StateError('plugin unavailable');
            }
            return const NotificationLaunchDetails(
              didLaunchFromNotification: true,
              payload: '{"version":1,"route":"/challenges/challenge-1"}',
            );
          },
        );

        await expectLater(service.start(), throwsA(isA<StateError>()));
        expect(router.navigatedIntents, const <NotificationRouteIntent>[
          NotificationSectionRouteIntent(NotificationSection.settings),
        ]);

        await service.start();
        source.publishRuntimePayload(
          '{"version":1,"route":"/finance/transactions/transaction-1"}',
        );

        expect(loadCount, 2);
        expect(router.navigatedIntents, const <NotificationRouteIntent>[
          NotificationSectionRouteIntent(NotificationSection.settings),
          NotificationChallengeRouteIntent('challenge-1'),
          NotificationTransactionRouteIntent('transaction-1'),
        ]);

        await service.dispose();
        await source.close();
      },
    );
  });

  group('NotificationRoutingStartupService lifecycle', () {
    test('dispose stops later runtime routing', () async {
      final source = NotificationResponseSource();
      final router = _RecordingNotificationRouterAdapter();
      final queue = NotificationNavigationQueue()..markRouterReady(router);
      final service = _createService(
        source: source,
        queue: queue,
        loadDetails: _normalLaunch,
      );
      await service.start();

      await service.dispose();
      source.publishRuntimePayload('{"version":1,"route":"/tasks/late-task"}');

      expect(service.isDisposed, isTrue);
      expect(router.navigatedIntents, isEmpty);

      await source.close();
    });

    test('dispose is idempotent', () async {
      final source = NotificationResponseSource();
      final service = _createService(
        source: source,
        queue: NotificationNavigationQueue(),
        loadDetails: _normalLaunch,
      );
      await service.start();

      await service.dispose();
      await service.dispose();

      expect(service.isDisposed, isTrue);
      await source.close();
    });

    test('start after dispose throws', () async {
      final source = NotificationResponseSource();
      final service = _createService(
        source: source,
        queue: NotificationNavigationQueue(),
        loadDetails: _normalLaunch,
      );
      await service.dispose();

      expect(service.start, throwsA(isA<StateError>()));

      await source.close();
    });

    test(
      'dispose during cold-start loading prevents late navigation',
      () async {
        final source = NotificationResponseSource();
        final router = _RecordingNotificationRouterAdapter();
        final queue = NotificationNavigationQueue()..markRouterReady(router);
        final loaderStarted = Completer<void>();
        final releaseLoader = Completer<void>();
        final service = _createService(
          source: source,
          queue: queue,
          loadDetails: () async {
            loaderStarted.complete();
            await releaseLoader.future;
            return const NotificationLaunchDetails(
              didLaunchFromNotification: true,
              payload: '{"version":1,"route":"/tasks/late-task"}',
            );
          },
        );

        final startup = service.start();
        await loaderStarted.future;
        source.publishRuntimePayload(
          '{"version":1,"route":"/goals/late-goal"}',
        );
        await service.dispose();
        releaseLoader.complete();
        await startup;

        expect(router.navigatedIntents, isEmpty);
        expect(service.isDisposed, isTrue);

        await source.close();
      },
    );
  });
}

NotificationRoutingStartupService _createService({
  required NotificationResponseSource source,
  required NotificationNavigationQueue queue,
  required NotificationLaunchDetailsLoader loadDetails,
}) {
  return NotificationRoutingStartupService(
    responseSource: source,
    coldStartGateway: NotificationColdStartGateway(loadDetails),
    routeParser: const NotificationRouteParser(),
    navigationQueue: queue,
  );
}

Future<NotificationLaunchDetails> _normalLaunch() async {
  return const NotificationLaunchDetails(didLaunchFromNotification: false);
}

final class _RecordingNotificationRouterAdapter
    implements NotificationRouterAdapter {
  final List<NotificationRouteIntent> navigatedIntents =
      <NotificationRouteIntent>[];

  @override
  void navigate(NotificationRouteIntent intent) {
    navigatedIntents.add(intent);
  }
}
