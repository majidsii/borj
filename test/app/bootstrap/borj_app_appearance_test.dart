import 'package:borj/app/apple_visual/foundation/glass_preferences_scope.dart';
import 'package:borj/app/bootstrap/app_bootstrap.dart';
import 'package:borj/app/theme/motion_scope.dart';
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

  Future<void> pumpApp(
    WidgetTester tester,
    AppearancePreferences preferences,
  ) async {
    final database = openTestDatabase();
    addTearDown(database.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          initialAppearancePreferencesProvider.overrideWithValue(preferences),
        ],
        child: const BorjApp(),
      ),
    );
    await tester.pump();
  }

  Future<void> disposeApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  testWidgets('stored glass and motion preferences reach the scopes', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const AppearancePreferences(
        glassIntensity: 0.8,
        reduceMotion: true,
        reduceTransparency: true,
      ),
    );

    final context = tester.element(find.byKey(const ValueKey('today-title')));
    final glass = GlassPreferencesScope.of(context);
    expect(glass.intensity, 0.8);
    expect(glass.reduceTransparency, isTrue);
    expect(MotionScope.reducedOf(context), isTrue);

    await disposeApp(tester);
  });

  testWidgets('a glass intensity change does not rebuild MaterialApp', (
    tester,
  ) async {
    await pumpApp(tester, AppearancePreferences.defaults);
    final before = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(
      GlassPreferencesScope.of(
        tester.element(find.byKey(const ValueKey('today-title'))),
      ).intensity,
      0.5,
    );

    final container = ProviderScope.containerOf(
      tester.element(find.byType(BorjApp)),
    );
    await container
        .read(appearancePreferencesProvider.notifier)
        .setGlassIntensity(0.3);
    await tester.pump();

    expect(
      GlassPreferencesScope.of(
        tester.element(find.byKey(const ValueKey('today-title'))),
      ).intensity,
      0.3,
    );
    expect(
      identical(tester.widget<MaterialApp>(find.byType(MaterialApp)), before),
      isTrue,
    );

    await disposeApp(tester);
  });
}
