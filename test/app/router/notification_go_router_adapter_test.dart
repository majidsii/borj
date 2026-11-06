import 'package:borj/app/router/go_router_notification_adapter.dart';
import 'package:borj/app/router/notification_route_location_mapper.dart';
import 'package:borj/app/router/notification_router_binding.dart';
import 'package:borj/core/notifications/notification_navigation_queue.dart';
import 'package:borj/core/notifications/notification_route_intent.dart';
import 'package:borj/core/notifications/notification_routing_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('NotificationRouteLocationMapper', () {
    const mapper = NotificationRouteLocationMapper();

    test('maps task intent', () {
      expect(
        mapper.locationFor(const NotificationTaskRouteIntent('task_1')),
        '/tasks/task_1',
      );
    });

    test('maps habit intent', () {
      expect(
        mapper.locationFor(const NotificationHabitRouteIntent('habit-1')),
        '/habits/habit-1',
      );
    });

    test('maps challenge intent', () {
      expect(
        mapper.locationFor(
          const NotificationChallengeRouteIntent('challenge_1'),
        ),
        '/challenges/challenge_1',
      );
    });

    test('maps goal intent', () {
      expect(
        mapper.locationFor(const NotificationGoalRouteIntent('goal-1')),
        '/goals/goal-1',
      );
    });

    test('maps debt intent', () {
      expect(
        mapper.locationFor(const NotificationDebtRouteIntent('debt_1')),
        '/finance/debts/debt_1',
      );
    });

    test('maps installment intent', () {
      expect(
        mapper.locationFor(
          const NotificationInstallmentRouteIntent('installment-1'),
        ),
        '/finance/installments/installment-1',
      );
    });

    test('maps transaction intent', () {
      expect(
        mapper.locationFor(
          const NotificationTransactionRouteIntent('transaction_1'),
        ),
        '/finance/transactions/transaction_1',
      );
    });

    test('maps tasks section', () {
      expect(
        mapper.locationFor(
          const NotificationSectionRouteIntent(NotificationSection.tasks),
        ),
        '/tasks',
      );
    });

    test('maps finance section', () {
      expect(
        mapper.locationFor(
          const NotificationSectionRouteIntent(NotificationSection.finance),
        ),
        '/finance',
      );
    });

    test('maps settings section', () {
      expect(
        mapper.locationFor(
          const NotificationSectionRouteIntent(NotificationSection.settings),
        ),
        '/settings',
      );
    });

    test('rejects an empty entity id created outside the parser', () {
      expect(mapper.locationFor(const NotificationTaskRouteIntent('')), isNull);
    });

    test('rejects traversal, query, and fragment characters defensively', () {
      const invalidIds = <String>[
        '../settings',
        'task?tab=done',
        'task#history',
        'task/extra',
        r'task\extra',
        'task value',
      ];

      for (final id in invalidIds) {
        expect(
          mapper.locationFor(NotificationTaskRouteIntent(id)),
          isNull,
          reason: 'ID must be rejected: $id',
        );
      }
    });

    test('rejects entity ids longer than 128 characters', () {
      expect(
        mapper.locationFor(NotificationTaskRouteIntent('a' * 129)),
        isNull,
      );
    });
  });

  group('GoRouterNotificationAdapter', () {
    testWidgets('navigates a typed intent through GoRouter.go', (tester) async {
      final router = _buildRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      final adapter = GoRouterNotificationAdapter(router);
      adapter.navigate(const NotificationTaskRouteIntent('task-adapter'));
      await tester.pumpAndSettle();

      expect(find.text('/tasks/task-adapter'), findsOneWidget);
    });

    testWidgets('ignores an invalid direct intent without changing route', (
      tester,
    ) async {
      final router = _buildRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      final adapter = GoRouterNotificationAdapter(router);
      adapter.navigate(const NotificationTaskRouteIntent('../settings'));
      await tester.pumpAndSettle();

      expect(find.text('/'), findsOneWidget);
      expect(find.text('/settings'), findsNothing);
    });
  });

  group('NotificationRouterBinding', () {
    testWidgets('drains queued intents after the router first frame', (
      tester,
    ) async {
      final queue = NotificationNavigationQueue()
        ..enqueue(const NotificationTaskRouteIntent('queued-task'));
      final router = _buildRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            notificationNavigationQueueProvider.overrideWithValue(queue),
          ],
          child: NotificationRouterBinding(
            router: router,
            child: MaterialApp.router(routerConfig: router),
          ),
        ),
      );

      // pumpWidget completes the first frame and its post-frame callbacks.
      await tester.pumpAndSettle();

      expect(queue.isRouterReady, isTrue);
      expect(queue.pendingCount, 0);
      expect(find.text('/tasks/queued-task'), findsOneWidget);
    });

    testWidgets('routes runtime queue entries while mounted', (tester) async {
      final queue = NotificationNavigationQueue();
      final router = _buildRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            notificationNavigationQueueProvider.overrideWithValue(queue),
          ],
          child: NotificationRouterBinding(
            router: router,
            child: MaterialApp.router(routerConfig: router),
          ),
        ),
      );
      await tester.pump();

      queue.enqueue(
        const NotificationTransactionRouteIntent('transaction-runtime'),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('/finance/transactions/transaction-runtime'),
        findsOneWidget,
      );
    });

    testWidgets('marks the queue unavailable when unmounted', (tester) async {
      final queue = NotificationNavigationQueue();
      final router = _buildRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            notificationNavigationQueueProvider.overrideWithValue(queue),
          ],
          child: NotificationRouterBinding(
            router: router,
            child: MaterialApp.router(routerConfig: router),
          ),
        ),
      );
      await tester.pump();

      expect(queue.isRouterReady, isTrue);

      await tester.pumpWidget(const SizedBox.shrink());

      expect(queue.isRouterReady, isFalse);
    });

    testWidgets('rebinds future navigation to a replacement router', (
      tester,
    ) async {
      final queue = NotificationNavigationQueue();
      final firstRouter = _buildRouter();
      final secondRouter = _buildRouter();
      addTearDown(firstRouter.dispose);
      addTearDown(secondRouter.dispose);

      Widget buildHost(GoRouter router) {
        return ProviderScope(
          overrides: <Override>[
            notificationNavigationQueueProvider.overrideWithValue(queue),
          ],
          child: NotificationRouterBinding(
            router: router,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
      }

      await tester.pumpWidget(buildHost(firstRouter));
      await tester.pump();

      await tester.pumpWidget(buildHost(secondRouter));

      // The replacement binding becomes ready in the frame completed by
      // pumpWidget. Future entries must now use the second router.
      expect(queue.isRouterReady, isTrue);
      queue.enqueue(const NotificationGoalRouteIntent('replacement-goal'));
      await tester.pumpAndSettle();

      expect(find.text('/goals/replacement-goal'), findsOneWidget);
    });

    testWidgets('starts the routing bootstrap without blocking its child', (
      tester,
    ) async {
      final router = _buildRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          child: NotificationRouterBinding(
            router: router,
            child: MaterialApp.router(routerConfig: router),
          ),
        ),
      );

      expect(find.text('/'), findsOneWidget);
    });
  });
}

GoRouter _buildRouter() {
  Widget page(BuildContext context, GoRouterState state) {
    return Scaffold(body: Text(state.uri.path));
  }

  return GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(path: '/', builder: page),
      GoRoute(path: '/tasks', builder: page),
      GoRoute(path: '/tasks/:id', builder: page),
      GoRoute(path: '/habits/:id', builder: page),
      GoRoute(path: '/challenges/:id', builder: page),
      GoRoute(path: '/goals/:id', builder: page),
      GoRoute(path: '/finance', builder: page),
      GoRoute(path: '/finance/debts/:id', builder: page),
      GoRoute(path: '/finance/installments/:id', builder: page),
      GoRoute(path: '/finance/transactions/:id', builder: page),
      GoRoute(path: '/settings', builder: page),
    ],
  );
}
