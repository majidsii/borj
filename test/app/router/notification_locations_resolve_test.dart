import 'package:borj/app/router/app_router.dart';
import 'package:borj/app/router/notification_route_location_mapper.dart';
import 'package:borj/core/notifications/notification_route_intent.dart';
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
      final container = await pumpBorjTestApp(tester);
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
