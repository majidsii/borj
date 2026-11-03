import 'package:dashboard_shakhsi/app/apple_visual/review/glass_review_screen.dart';
import 'package:dashboard_shakhsi/features/dashboard/presentation/dashboard_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

abstract final class AppRoutes {
  static const dashboard = '/';
  static const finance = '/finance';
  static const transactions = '/finance/transactions';
  static const financialCalendar = '/finance/calendar';
  static const debts = '/finance/debts';
  static const installments = '/finance/installments';
  static const settings = '/settings';
  static const backup = '/backup';
  static const migration = '/migration';
  static const glassReview = '/debug/glass-review';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.dashboard,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.finance,
        builder: (context, state) => const _PlaceholderScreen(title: 'مالی'),
      ),
      GoRoute(
        path: AppRoutes.transactions,
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'تراکنش‌ها'),
      ),
      GoRoute(
        path: AppRoutes.financialCalendar,
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'تقویم مالی'),
      ),
      GoRoute(
        path: AppRoutes.debts,
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'بدهی‌ها و طلب‌ها'),
      ),
      GoRoute(
        path: AppRoutes.installments,
        builder: (context, state) => const _PlaceholderScreen(title: 'اقساط'),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const _PlaceholderScreen(title: 'تنظیمات'),
      ),
      GoRoute(
        path: AppRoutes.backup,
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'پشتیبان‌گیری'),
      ),
      GoRoute(
        path: AppRoutes.migration,
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'انتقال اطلاعات'),
      ),
      if (kDebugMode)
        GoRoute(
          path: AppRoutes.glassReview,
          builder: (context, state) =>
              const GlassReviewScreen(referenceDir: glassReferenceDir),
        ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});

final class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
        ),
      ),
    );
  }
}
