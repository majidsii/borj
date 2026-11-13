import 'package:borj/app/router/app_router.dart';
import 'package:borj/app/router/notification_route_location_mapper.dart';
import 'package:borj/core/notifications/notification_route_intent.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/borj_test_app.dart';

void main() {
  const mapper = NotificationRouteLocationMapper();
  final intents = <NotificationRouteIntent>[
    const NotificationTaskRouteIntent('t1'),
    const NotificationHabitRouteIntent('h1'),
    const NotificationChallengeRouteIntent('c1'),
    const NotificationGoalRouteIntent('g1'),
    const NotificationDebtRouteIntent('d1'),
    const NotificationInstallmentRouteIntent('i1'),
    const NotificationTransactionRouteIntent('x1'),
    for (final s in NotificationSection.values)
      NotificationSectionRouteIntent(s),
  ];

  for (final intent in intents) {
    final location = mapper.locationFor(intent)!;
    testWidgets('$location resolves', (tester) async {
      useWindowSize(tester, const Size(390, 844));
      // /tasks/<id> opens that task's edit dialog, so the task must exist (a
      // missing one returns to /tasks, covered in tasks_routes_test).
      final container = await pumpBorjTestApp(
        tester,
        seed: (c) => c
            .read(taskRepositoryProvider)
            .create(
              TaskItem(
                id: 't1',
                displayNumber: 1,
                title: 'کار',
                priority: 0,
                status: TaskStatus.planned,
                positionInStatus: 0,
                createdAtUtc: DateTime.utc(2026, 11, 1),
                updatedAtUtc: DateTime.utc(2026, 11, 1),
              ),
            ),
      );
      final router = container.read(appRouterProvider);
      router.go(location);
      await pumpPage(tester);
      expect(
        find.byKey(const ValueKey('route-error')),
        findsNothing,
        reason: location,
      );
      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        location,
      );
    });
  }
}
