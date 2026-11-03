import 'package:dashboard_shakhsi/app/apple_visual/widgets/apple_liquid_glass.dart';
import 'package:dashboard_shakhsi/app/theme/original_theme.dart';
import 'package:dashboard_shakhsi/app/widgets/original_glass.dart';
import 'package:dashboard_shakhsi/core/providers/persistence_providers.dart';
import 'package:dashboard_shakhsi/features/dashboard/presentation/dashboard_screen.dart';
import 'package:dashboard_shakhsi/features/legacy_import/data/legacy_v1_source_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';

void main() {
  testWidgets('top bar islands render as Liquid Glass', (tester) async {
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

    final topBar = find.byKey(const ValueKey<String>('top-bar'));
    expect(topBar, findsOneWidget);
    expect(
      find.descendant(of: topBar, matching: find.byType(AppleLiquidGlass)),
      findsNWidgets(4),
    );
    expect(
      find.descendant(of: topBar, matching: find.byType(OriginalGlass)),
      findsNothing,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
