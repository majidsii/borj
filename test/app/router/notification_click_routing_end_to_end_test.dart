import 'dart:async';

import 'package:borj/core/notifications/notification_response_source.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/notification_routing_test_harness.dart';

void main() {
  group('notification click routing end to end', () {
    testWidgets('routes a cold-start task payload after router readiness', (
      tester,
    ) async {
      final harness = NotificationRoutingTestHarness(
        launchDetailsLoader: () async => const NotificationLaunchDetails(
          didLaunchFromNotification: true,
          payload: '{"version":1,"route":"/tasks/task-cold-start"}',
        ),
      );
      addTearDown(harness.dispose);

      await tester.pumpWidget(harness.buildApp());
      await tester.pumpAndSettle();

      expect(find.text('/tasks/task-cold-start'), findsOneWidget);
      expect(harness.queue.pendingCount, 0);
      expect(harness.queue.isRouterReady, isTrue);
    });

    testWidgets('routes a runtime transaction payload', (tester) async {
      final harness = NotificationRoutingTestHarness();
      addTearDown(harness.dispose);

      await tester.pumpWidget(harness.buildApp());
      await tester.pumpAndSettle();

      harness.publishRuntimePayload(
        '{"version":1,'
        '"route":"/finance/transactions/transaction-runtime"}',
      );
      await tester.pumpAndSettle();

      expect(
        find.text('/finance/transactions/transaction-runtime'),
        findsOneWidget,
      );
      expect(harness.queue.pendingCount, 0);
    });

    testWidgets('preserves cold-start ordering before a buffered runtime tap', (
      tester,
    ) async {
      final launchCompleter = Completer<NotificationLaunchDetails>();
      final harness = NotificationRoutingTestHarness(
        launchDetailsLoader: () => launchCompleter.future,
      );
      addTearDown(harness.dispose);

      await tester.pumpWidget(harness.buildApp());

      harness.publishRuntimePayload('{"version":1,"route":"/settings"}');
      launchCompleter.complete(
        const NotificationLaunchDetails(
          didLaunchFromNotification: true,
          payload: '{"version":1,"route":"/tasks/cold-first"}',
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      // The final route proves ordering: if the buffered runtime tap had
      // been handled first, the cold-start task route would be visible last.
      expect(find.text('/settings'), findsOneWidget);
      expect(find.text('/tasks/cold-first'), findsNothing);
      expect(harness.queue.pendingCount, 0);
    });

    testWidgets('ignores malformed runtime payload without leaving root', (
      tester,
    ) async {
      final harness = NotificationRoutingTestHarness();
      addTearDown(harness.dispose);

      await tester.pumpWidget(harness.buildApp());
      await tester.pumpAndSettle();

      harness.publishRuntimePayload('{bad-json');
      await tester.pumpAndSettle();

      expect(find.text('/'), findsOneWidget);
      expect(harness.visitedLocations, isEmpty);
    });

    testWidgets('ignores an unknown notification route', (tester) async {
      final harness = NotificationRoutingTestHarness();
      addTearDown(harness.dispose);

      await tester.pumpWidget(harness.buildApp());
      await tester.pumpAndSettle();

      harness.publishRuntimePayload('{"version":1,"route":"/admin/unsafe"}');
      await tester.pumpAndSettle();

      expect(find.text('/'), findsOneWidget);
      expect(harness.visitedLocations, isEmpty);
    });

    testWidgets('routes an allow-listed section payload', (tester) async {
      final harness = NotificationRoutingTestHarness();
      addTearDown(harness.dispose);

      await tester.pumpWidget(harness.buildApp());
      await tester.pumpAndSettle();

      harness.publishRuntimePayload('{"version":1,"route":"/finance"}');
      await tester.pumpAndSettle();

      expect(find.text('/finance'), findsOneWidget);
    });

    testWidgets('does not replay a consumed cold-start payload on rebuild', (
      tester,
    ) async {
      var launchLoadCount = 0;
      final harness = NotificationRoutingTestHarness(
        launchDetailsLoader: () async {
          launchLoadCount += 1;
          return const NotificationLaunchDetails(
            didLaunchFromNotification: true,
            payload: '{"version":1,"route":"/goals/goal-once"}',
          );
        },
      );
      addTearDown(harness.dispose);

      await tester.pumpWidget(harness.buildApp());
      await tester.pumpAndSettle();

      expect(find.text('/goals/goal-once'), findsOneWidget);
      expect(launchLoadCount, 1);
      expect(
        harness.visitedLocations.where(
          (location) => location == '/goals/goal-once',
        ),
        hasLength(1),
      );

      await tester.pumpWidget(harness.buildApp());
      await tester.pumpAndSettle();

      expect(launchLoadCount, 1);
      expect(
        harness.visitedLocations.where(
          (location) => location == '/goals/goal-once',
        ),
        hasLength(1),
      );
    });

    testWidgets('keeps the application visible when launch loading fails', (
      tester,
    ) async {
      final harness = NotificationRoutingTestHarness(
        launchDetailsLoader: () async {
          throw StateError('launch details unavailable');
        },
      );
      addTearDown(harness.dispose);

      await tester.pumpWidget(harness.buildApp());
      await tester.pump();

      expect(find.text('/'), findsOneWidget);
      expect(harness.visitedLocations, isEmpty);
    });

    testWidgets('stops routing after the application host is unmounted', (
      tester,
    ) async {
      final harness = NotificationRoutingTestHarness();
      addTearDown(harness.dispose);

      await tester.pumpWidget(harness.buildApp());
      await tester.pumpAndSettle();

      await tester.pumpWidget(const TestAppPlaceholder());
      expect(harness.queue.isRouterReady, isFalse);

      harness.publishRuntimePayload(
        '{"version":1,"route":"/tasks/after-unmount"}',
      );
      await tester.pump();

      expect(harness.visitedLocations, isEmpty);
      expect(harness.queue.pendingCount, 1);
    });
  });
}
