import 'package:borj/app/router/notification_router_binding.dart';
import 'package:borj/core/notifications/notification_navigation_queue.dart';
import 'package:borj/core/notifications/notification_response_source.dart';
import 'package:borj/core/notifications/notification_routing_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final class NotificationRoutingTestHarness {
  NotificationRoutingTestHarness({
    NotificationLaunchDetailsLoader? launchDetailsLoader,
  }) : _launchDetailsLoader =
           launchDetailsLoader ??
           (() async => const NotificationLaunchDetails(
             didLaunchFromNotification: false,
           )) {
    router = _buildRouter(visitedLocations);
    container = ProviderContainer(
      overrides: <Override>[
        notificationLaunchDetailsLoaderProvider.overrideWithValue(
          _launchDetailsLoader,
        ),
      ],
    );
  }

  final NotificationLaunchDetailsLoader _launchDetailsLoader;
  final List<String> visitedLocations = <String>[];

  late final GoRouter router;
  late final ProviderContainer container;

  NotificationNavigationQueue get queue =>
      container.read(notificationNavigationQueueProvider);

  Widget buildApp() {
    return UncontrolledProviderScope(
      container: container,
      child: NotificationRouterBinding(
        router: router,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
  }

  void publishRuntimePayload(String? payload) {
    container
        .read(notificationResponseSourceProvider)
        .publishRuntimePayload(payload);
  }

  void dispose() {
    router.dispose();
    container.dispose();
  }
}

final class TestAppPlaceholder extends StatelessWidget {
  const TestAppPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

GoRouter _buildRouter(List<String> visitedLocations) {
  Widget page(BuildContext context, GoRouterState state) {
    final path = state.uri.path;
    if (path != '/') {
      visitedLocations.add(path);
    }
    return Scaffold(body: Text(path));
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
