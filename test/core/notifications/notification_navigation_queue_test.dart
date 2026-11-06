import 'package:borj/core/notifications/notification_navigation_queue.dart';
import 'package:borj/core/notifications/notification_route_intent.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationNavigationQueue readiness', () {
    test('keeps an intent pending until the router is ready', () {
      final queue = NotificationNavigationQueue();
      final router = _RecordingNotificationRouterAdapter();

      queue.enqueue(const NotificationTaskRouteIntent('task-1'));

      expect(queue.isRouterReady, isFalse);
      expect(queue.pendingCount, 1);
      expect(router.navigatedIntents, isEmpty);

      queue.markRouterReady(router);

      expect(queue.isRouterReady, isTrue);
      expect(queue.pendingCount, 0);
      expect(router.navigatedIntents, const <NotificationRouteIntent>[
        NotificationTaskRouteIntent('task-1'),
      ]);
    });

    test('navigates immediately when the router is already ready', () {
      final queue = NotificationNavigationQueue();
      final router = _RecordingNotificationRouterAdapter();
      queue.markRouterReady(router);

      queue.enqueue(const NotificationHabitRouteIntent('habit-1'));

      expect(queue.pendingCount, 0);
      expect(router.navigatedIntents, const <NotificationRouteIntent>[
        NotificationHabitRouteIntent('habit-1'),
      ]);
    });

    test('pauses delivery while the router is unavailable', () {
      final queue = NotificationNavigationQueue();
      final router = _RecordingNotificationRouterAdapter();
      queue.markRouterReady(router);
      queue.markRouterUnavailable();

      queue.enqueue(const NotificationGoalRouteIntent('goal-1'));

      expect(queue.isRouterReady, isFalse);
      expect(queue.pendingCount, 1);
      expect(router.navigatedIntents, isEmpty);
    });

    test('drains paused work after a router is attached again', () {
      final queue = NotificationNavigationQueue();
      final firstRouter = _RecordingNotificationRouterAdapter();
      final secondRouter = _RecordingNotificationRouterAdapter();
      queue.markRouterReady(firstRouter);
      queue.markRouterUnavailable();
      queue.enqueue(const NotificationGoalRouteIntent('goal-1'));

      queue.markRouterReady(secondRouter);

      expect(queue.pendingCount, 0);
      expect(firstRouter.navigatedIntents, isEmpty);
      expect(secondRouter.navigatedIntents, const <NotificationRouteIntent>[
        NotificationGoalRouteIntent('goal-1'),
      ]);
    });
  });

  group('NotificationNavigationQueue exactly-once delivery', () {
    test('drains pending intents in FIFO order', () {
      final queue = NotificationNavigationQueue();
      final router = _RecordingNotificationRouterAdapter();
      queue
        ..enqueue(const NotificationTaskRouteIntent('task-1'))
        ..enqueue(const NotificationHabitRouteIntent('habit-1'))
        ..enqueue(
          const NotificationSectionRouteIntent(NotificationSection.settings),
        );

      queue.markRouterReady(router);

      expect(router.navigatedIntents, const <NotificationRouteIntent>[
        NotificationTaskRouteIntent('task-1'),
        NotificationHabitRouteIntent('habit-1'),
        NotificationSectionRouteIntent(NotificationSection.settings),
      ]);
      expect(queue.pendingCount, 0);
    });

    test('does not replay delivered intents when readiness is repeated', () {
      final queue = NotificationNavigationQueue();
      final router = _RecordingNotificationRouterAdapter();
      queue.enqueue(const NotificationChallengeRouteIntent('challenge-1'));

      queue
        ..markRouterReady(router)
        ..markRouterReady(router)
        ..markRouterReady(router);

      expect(router.navigatedIntents, const <NotificationRouteIntent>[
        NotificationChallengeRouteIntent('challenge-1'),
      ]);
      expect(queue.pendingCount, 0);
    });

    test('does not replay delivered intents when the router is replaced', () {
      final queue = NotificationNavigationQueue();
      final firstRouter = _RecordingNotificationRouterAdapter();
      final secondRouter = _RecordingNotificationRouterAdapter();
      queue.enqueue(const NotificationDebtRouteIntent('debt-1'));

      queue
        ..markRouterReady(firstRouter)
        ..markRouterReady(secondRouter);

      expect(firstRouter.navigatedIntents, const <NotificationRouteIntent>[
        NotificationDebtRouteIntent('debt-1'),
      ]);
      expect(secondRouter.navigatedIntents, isEmpty);
    });

    test('treats identical enqueues as separate queue entries', () {
      final queue = NotificationNavigationQueue();
      final router = _RecordingNotificationRouterAdapter();
      queue
        ..enqueue(const NotificationTaskRouteIntent('task-1'))
        ..enqueue(const NotificationTaskRouteIntent('task-1'))
        ..markRouterReady(router);

      expect(router.navigatedIntents, const <NotificationRouteIntent>[
        NotificationTaskRouteIntent('task-1'),
        NotificationTaskRouteIntent('task-1'),
      ]);
    });

    test(
      'delivers a reentrant enqueue once without starting a second drain',
      () {
        final queue = NotificationNavigationQueue();
        final router = _RecordingNotificationRouterAdapter();
        router.onNavigate = (intent) {
          if (intent == const NotificationTaskRouteIntent('task-1')) {
            queue.enqueue(const NotificationGoalRouteIntent('goal-1'));
          }
        };
        queue.enqueue(const NotificationTaskRouteIntent('task-1'));

        queue.markRouterReady(router);

        expect(router.navigatedIntents, const <NotificationRouteIntent>[
          NotificationTaskRouteIntent('task-1'),
          NotificationGoalRouteIntent('goal-1'),
        ]);
        expect(queue.pendingCount, 0);
      },
    );

    test('stops draining when the router becomes unavailable mid-drain', () {
      final queue = NotificationNavigationQueue();
      final router = _RecordingNotificationRouterAdapter();
      router.onNavigate = (_) => queue.markRouterUnavailable();
      queue
        ..enqueue(const NotificationTaskRouteIntent('task-1'))
        ..enqueue(const NotificationGoalRouteIntent('goal-1'));

      queue.markRouterReady(router);

      expect(router.navigatedIntents, const <NotificationRouteIntent>[
        NotificationTaskRouteIntent('task-1'),
      ]);
      expect(queue.isRouterReady, isFalse);
      expect(queue.pendingCount, 1);
    });

    test('does not replay an intent whose navigation attempt throws', () {
      final queue = NotificationNavigationQueue();
      final router = _RecordingNotificationRouterAdapter()
        ..throwOnNextNavigation = true;
      queue
        ..enqueue(const NotificationTaskRouteIntent('task-1'))
        ..enqueue(const NotificationGoalRouteIntent('goal-1'));

      expect(() => queue.markRouterReady(router), throwsA(isA<StateError>()));

      expect(router.navigatedIntents, const <NotificationRouteIntent>[
        NotificationTaskRouteIntent('task-1'),
      ]);
      expect(queue.pendingCount, 1);

      queue.markRouterReady(router);

      expect(router.navigatedIntents, const <NotificationRouteIntent>[
        NotificationTaskRouteIntent('task-1'),
        NotificationGoalRouteIntent('goal-1'),
      ]);
      expect(queue.pendingCount, 0);
    });
  });
}

final class _RecordingNotificationRouterAdapter
    implements NotificationRouterAdapter {
  final List<NotificationRouteIntent> navigatedIntents =
      <NotificationRouteIntent>[];

  void Function(NotificationRouteIntent intent)? onNavigate;
  bool throwOnNextNavigation = false;

  @override
  void navigate(NotificationRouteIntent intent) {
    navigatedIntents.add(intent);
    onNavigate?.call(intent);

    if (throwOnNextNavigation) {
      throwOnNextNavigation = false;
      throw StateError('navigation failed');
    }
  }
}
