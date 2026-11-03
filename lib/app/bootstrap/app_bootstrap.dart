import 'dart:ui';

import 'package:dashboard_shakhsi/app/bootstrap/notification_startup_bootstrap.dart';
import 'package:dashboard_shakhsi/app/router/app_router.dart';
import 'package:dashboard_shakhsi/app/theme/original_theme.dart';
import 'package:dashboard_shakhsi/app/theme/theme_mode_controller.dart';
import 'package:dashboard_shakhsi/core/providers/persistence_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

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

  final container = ProviderContainer();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: NotificationStartupBootstrap(
        startupProvider: notificationStartupProvider,
        child: const DashboardShakhsiApp(),
      ),
    ),
  );
}

@visibleForTesting
Future<void> initializeNotificationsForApp(ProviderContainer container) {
  return container.read(notificationStartupProvider).initialize();
}

final class DashboardShakhsiApp extends ConsumerWidget {
  const DashboardShakhsiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(taskTemplateStartupProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      locale: const Locale('fa', 'IR'),
      supportedLocales: const <Locale>[Locale('fa', 'IR'), Locale('en', 'US')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      onGenerateTitle: (context) => 'داشبورد شخصی',
      theme: OriginalTheme.light(),
      darkTheme: OriginalTheme.dark(),
      themeMode: ref.watch(dashboardThemeModeProvider),
      themeAnimationDuration: const Duration(milliseconds: 400),
      themeAnimationCurve: Curves.easeOutCubic,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
