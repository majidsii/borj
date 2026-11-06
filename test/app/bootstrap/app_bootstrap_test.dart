import 'package:borj/app/bootstrap/app_bootstrap.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';

void main() {
  testWidgets('app starts in Persian with RTL directionality', (tester) async {
    final database = openTestDatabase();
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const BorjApp(),
      ),
    );
    await tester.pump();

    final dashboard = find.text('برج');

    expect(dashboard, findsOneWidget);
    expect(Directionality.of(tester.element(dashboard)), TextDirection.rtl);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
