import 'package:borj/app/bootstrap/app_bootstrap.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:borj/features/today/application/today_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import '../../support/test_database.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  testWidgets('app starts in Persian with RTL directionality', (tester) async {
    final database = openTestDatabase();
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          minuteTickProvider.overrideWith(
            (ref) => Stream.value(DateTime.utc(2026, 11, 4, 11)),
          ),
          taskCalendarTimeZoneProvider.overrideWith((ref) => 'Asia/Tehran'),
        ],
        child: const BorjApp(),
      ),
    );
    await tester.pump();

    final title = find.byKey(const ValueKey('today-title'));

    expect(title, findsOneWidget);
    expect(Directionality.of(tester.element(title)), TextDirection.rtl);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
