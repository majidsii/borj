import 'package:dashboard_shakhsi/app/theme/original_theme.dart';
import 'package:dashboard_shakhsi/core/providers/persistence_providers.dart';
import 'package:dashboard_shakhsi/features/dashboard/presentation/dashboard_screen.dart';
import 'package:dashboard_shakhsi/features/legacy_import/data/legacy_v1_source_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';

void main() {
  testWidgets('starts on the original tasks panel and switches to finance', (
    tester,
  ) async {
    final database = openTestDatabase();
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          appDatabaseProvider.overrideWithValue(database),
          legacyV1SourceLocatorProvider.overrideWithValue(
            const LegacyV1SourceLocator(
              operatingSystem: 'android',
              environment: <String, String>{},
            ),
          ),
        ],
        child: MaterialApp(
          theme: OriginalTheme.light(),
          home: const Directionality(
            textDirection: TextDirection.rtl,
            child: DashboardScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('داشبورد شخصی'), findsOneWidget);
    expect(find.text('کارهای من'), findsOneWidget);
    expect(find.text('مالی من'), findsNothing);

    await tester.tap(find.text('مالی'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('مالی من'), findsOneWidget);
    expect(find.text('کارهای من'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('the top bar has a settings button', (tester) async {
    final database = openTestDatabase();
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          appDatabaseProvider.overrideWithValue(database),
          legacyV1SourceLocatorProvider.overrideWithValue(
            const LegacyV1SourceLocator(
              operatingSystem: 'android',
              environment: <String, String>{},
            ),
          ),
        ],
        child: MaterialApp(
          theme: OriginalTheme.light(),
          home: const Directionality(
            textDirection: TextDirection.rtl,
            child: DashboardScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.byKey(const ValueKey<String>('dashboard-settings-button')),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
