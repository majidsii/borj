import 'package:borj/app/bootstrap/app_bootstrap.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:borj/features/settings/application/appearance_preferences_controller.dart';
import 'package:borj/features/settings/domain/appearance_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';

void main() {
  testWidgets('the first frame already uses the stored mode', (tester) async {
    final database = openTestDatabase();
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          initialAppearancePreferencesProvider.overrideWithValue(
            const AppearancePreferences(mode: AppearanceMode.dark),
          ),
        ],
        child: const BorjApp(),
      ),
    );

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(app.themeAnimationDuration, const Duration(milliseconds: 300));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
