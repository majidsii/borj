import 'dart:ui';

import 'package:borj/app/apple_visual/foundation/glass_preferences_scope.dart';
import 'package:borj/app/bootstrap/notification_startup_bootstrap.dart';
import 'package:borj/app/router/app_router.dart';
import 'package:borj/app/theme/motion_scope.dart';
import 'package:borj/app/theme/original_theme.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:borj/features/settings/application/appearance_preferences_controller.dart';
import 'package:borj/features/settings/data/file_appearance_preferences_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:path_provider/path_provider.dart';

Future<void> bootstrapApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlass.precache();

  FlutterError.onError = FlutterError.presentError;
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(exception: error, stack: stackTrace),
    );
    return true;
  };

  final preferencesStore = FileAppearancePreferencesStore(
    directory: getApplicationDocumentsDirectory,
  );
  final initialPreferences = await preferencesStore.load();

  final container = ProviderContainer(
    overrides: [
      appearancePreferencesStoreProvider.overrideWithValue(preferencesStore),
      initialAppearancePreferencesProvider.overrideWithValue(
        initialPreferences,
      ),
    ],
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: NotificationStartupBootstrap(
        startupProvider: notificationStartupProvider,
        child: const BorjApp(),
      ),
    ),
  );
}

@visibleForTesting
Future<void> initializeNotificationsForApp(ProviderContainer container) {
  return container.read(notificationStartupProvider).initialize();
}

final class BorjApp extends ConsumerWidget {
  const BorjApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(taskTemplateStartupProvider);
    final preferences = ref.watch(appearancePreferencesProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      locale: const Locale('fa', 'IR'),
      supportedLocales: const <Locale>[Locale('fa', 'IR'), Locale('en', 'US')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      onGenerateTitle: (context) => 'برج',
      theme: OriginalTheme.light(),
      darkTheme: OriginalTheme.dark(),
      themeMode: preferences.mode.themeMode,
      themeAnimationDuration: const Duration(milliseconds: 300),
      themeAnimationCurve: Curves.easeOut,
      builder: (context, child) => MotionScope(
        reduceMotionSetting: preferences.reduceMotion,
        child: GlassPreferencesScope(
          intensity: preferences.glassIntensity,
          reduceTransparency: preferences.reduceTransparency,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
