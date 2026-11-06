import 'dart:async';

import 'package:borj/app/bootstrap/notification_routing_bootstrap.dart';
import 'package:borj/core/notifications/notification_navigation_queue.dart';
import 'package:borj/core/notifications/notification_response_source.dart';
import 'package:borj/core/notifications/notification_route_intent.dart';
import 'package:borj/core/notifications/notification_routing_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('notification routing provider graph', () {
    test('shares one response source inside a provider container', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final first = container.read(notificationResponseSourceProvider);
      final second = container.read(notificationResponseSourceProvider);

      expect(identical(first, second), isTrue);
    });

    test('uses a normal launch as the safe default launch loader', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final loader = container.read(notificationLaunchDetailsLoaderProvider);
      final details = await loader();

      expect(details.didLaunchFromNotification, isFalse);
      expect(details.payload, isNull);
    });

    test('builds one shared navigation queue', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final first = container.read(notificationNavigationQueueProvider);
      final second = container.read(notificationNavigationQueueProvider);

      expect(identical(first, second), isTrue);
    });

    test('cold-start provider routes through parser and queue', () async {
      final container = ProviderContainer(
        overrides: <Override>[
          notificationLaunchDetailsLoaderProvider.overrideWithValue(
            () async => const NotificationLaunchDetails(
              didLaunchFromNotification: true,
              payload: '{"version":1,"route":"/tasks/task-provider"}',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = _RecordingNotificationRouterAdapter();
      container
          .read(notificationNavigationQueueProvider)
          .markRouterReady(router);

      await container.read(notificationRoutingStartupProvider.future);

      expect(router.navigatedIntents, const <NotificationRouteIntent>[
        NotificationTaskRouteIntent('task-provider'),
      ]);
    });

    test('runtime payloads are routed after provider startup', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = _RecordingNotificationRouterAdapter();
      container
          .read(notificationNavigationQueueProvider)
          .markRouterReady(router);

      await container.read(notificationRoutingStartupProvider.future);

      container
          .read(notificationResponseSourceProvider)
          .publishRuntimePayload(
            '{"version":1,"route":"/finance/transactions/tx-provider"}',
          );

      expect(router.navigatedIntents, const <NotificationRouteIntent>[
        NotificationTransactionRouteIntent('tx-provider'),
      ]);
    });

    test('invalid runtime payload is ignored by the provider graph', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = _RecordingNotificationRouterAdapter();
      container
          .read(notificationNavigationQueueProvider)
          .markRouterReady(router);

      await container.read(notificationRoutingStartupProvider.future);

      container
          .read(notificationResponseSourceProvider)
          .publishRuntimePayload('{bad-json');

      expect(router.navigatedIntents, isEmpty);
    });

    test('repeated startup reads share one launch-details load', () async {
      var loadCount = 0;
      final completer = Completer<NotificationLaunchDetails>();
      final container = ProviderContainer(
        overrides: <Override>[
          notificationLaunchDetailsLoaderProvider.overrideWithValue(() {
            loadCount += 1;
            return completer.future;
          }),
        ],
      );
      addTearDown(container.dispose);

      final first = container.read(notificationRoutingStartupProvider.future);
      final second = container.read(notificationRoutingStartupProvider.future);

      expect(identical(first, second), isTrue);

      // FutureProvider starts its async body on the next microtask.
      await Future<void>.delayed(Duration.zero);
      expect(loadCount, 1);

      completer.complete(
        const NotificationLaunchDetails(didLaunchFromNotification: false),
      );
      await Future.wait<void>(<Future<void>>[first, second]);

      expect(loadCount, 1);
    });

    test('container disposal closes routing-owned resources', () async {
      final container = ProviderContainer();

      final source = container.read(notificationResponseSourceProvider);
      final service = container.read(notificationRoutingStartupServiceProvider);

      await container.read(notificationRoutingStartupProvider.future);
      container.dispose();

      expect(source.isClosed, isTrue);
      expect(service.isDisposed, isTrue);
    });
  });

  group('NotificationRoutingBootstrap widget', () {
    testWidgets('renders the application while startup is pending', (
      tester,
    ) async {
      final launchCompleter = Completer<NotificationLaunchDetails>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            notificationLaunchDetailsLoaderProvider.overrideWithValue(
              () => launchCompleter.future,
            ),
          ],
          child: const NotificationRoutingBootstrap(
            child: MaterialApp(home: Scaffold(body: Text('application-ready'))),
          ),
        ),
      );

      expect(find.text('application-ready'), findsOneWidget);
    });

    testWidgets('does not replace the application when startup fails', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            notificationLaunchDetailsLoaderProvider.overrideWithValue(
              () async => throw StateError('launch details unavailable'),
            ),
          ],
          child: const NotificationRoutingBootstrap(
            child: MaterialApp(
              home: Scaffold(body: Text('application-still-ready')),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('application-still-ready'), findsOneWidget);
    });

    testWidgets('starts routing once for repeated widget rebuilds', (
      tester,
    ) async {
      var loadCount = 0;
      var generation = 0;
      late StateSetter rebuildBootstrap;

      Future<NotificationLaunchDetails> loader() async {
        loadCount += 1;
        return const NotificationLaunchDetails(
          didLaunchFromNotification: false,
        );
      }

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            notificationLaunchDetailsLoaderProvider.overrideWithValue(loader),
          ],
          child: StatefulBuilder(
            builder: (context, setState) {
              rebuildBootstrap = setState;
              return NotificationRoutingBootstrap(
                key: ValueKey<int>(generation),
                child: const MaterialApp(
                  home: Scaffold(body: Text('stable-bootstrap')),
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();
      expect(loadCount, 1);

      rebuildBootstrap(() {
        generation += 1;
      });
      await tester.pump();

      expect(find.text('stable-bootstrap'), findsOneWidget);
      expect(loadCount, 1);
    });
  });
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
