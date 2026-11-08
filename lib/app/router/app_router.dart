import 'dart:math' as math;

import 'package:borj/app/apple_visual/review/glass_review_screen.dart';
import 'package:borj/app/design/design.dart';
import 'package:borj/app/shell/app_shell.dart';
import 'package:borj/app/shell/pending_screen.dart';
import 'package:borj/app/shell/search_shell.dart';
import 'package:borj/app/shell/window_class.dart';
import 'package:borj/features/dashboard/presentation/widgets/finance_panel.dart';
import 'package:borj/features/dashboard/presentation/widgets/tasks_panel.dart';
import 'package:borj/features/settings/presentation/settings_screen.dart';
import 'package:borj/features/today/presentation/today_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

abstract final class AppRoutes {
  static const dashboard = '/';
  static const tasks = '/tasks';
  static const search = '/search';
  static const habits = '/habits';
  static const goals = '/goals';
  static const challenges = '/challenges';
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

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

void _quickEntryPlaceholder(BuildContext c) {
  showGlassSheet<void>(
    c,
    builder: (_) => const Padding(
      padding: EdgeInsets.all(16),
      child: EmptyState(
        icon: Icons.bolt_outlined,
        title: 'ورود سریع',
        message: 'در مرحلهٔ کارها ساخته می‌شود',
      ),
    ),
  );
}

List<ShellAction> _actionsFor(
  BuildContext context,
  WindowClass windowClass,
  int branch,
) {
  if (windowClass != WindowClass.compact) {
    return [
      const ShellAction(
        icon: Icons.add,
        label: 'افزودن',
        primary: true,
        onPressed: _quickEntryPlaceholder,
      ),
    ];
  }
  if (branch != 0) return const [];
  return [
    ShellAction(
      icon: Icons.calendar_month_outlined,
      label: 'تقویم',
      leading: true,
      onPressed: (c) => c.go('/tasks?view=calendar'),
    ),
    ShellAction(
      icon: Icons.settings_outlined,
      label: 'تنظیمات',
      leading: true,
      onPressed: (c) => c.push(AppRoutes.settings),
    ),
    const ShellAction(
      icon: Icons.add,
      label: 'ورود سریع',
      primary: true,
      onPressed: _quickEntryPlaceholder,
    ),
  ];
}

GoRoute _pending(
  String path,
  String title, {
  List<RouteBase> routes = const [],
  GlobalKey<NavigatorState>? parentNavigatorKey,
}) => GoRoute(
  path: path,
  parentNavigatorKey: parentNavigatorKey,
  pageBuilder: (context, state) => GlassPushPage(
    key: state.pageKey,
    child: PendingScreen(title: title),
  ),
  routes: routes,
);

final appRouterProvider = Provider<GoRouter>((ref) {
  late final GoRouter router;
  router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.dashboard,
    errorPageBuilder: (context, state) =>
        NoTransitionPage(key: state.pageKey, child: const RouteErrorScreen()),
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        pageBuilder: (context, state, navigationShell) => NoTransitionPage(
          key: state.pageKey,
          child: AppShell(
            navigationShell: navigationShell,
            location: state.uri.toString(),
            actionsFor: (c, wc) =>
                _actionsFor(c, wc, navigationShell.currentIndex),
            onSettings: () => router.push(AppRoutes.settings),
            onSearch: () {
              if (WindowClass.of(context) == WindowClass.compact) {
                router.push(AppRoutes.search);
              } else {
                showSearchOverlay(rootNavigatorKey.currentContext!);
              }
            },
          ),
        ),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.dashboard,
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const TodayPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.tasks,
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const _BranchPage(child: TasksPanel()),
                ),
                routes: <RouteBase>[_pending(':taskId', 'جزئیات کار')],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.finance,
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const _BranchPage(child: FinancePanel()),
                ),
                routes: <RouteBase>[
                  _pending(
                    'transactions',
                    'تراکنش‌ها',
                    routes: [_pending(':transactionId', 'جزئیات تراکنش')],
                  ),
                  _pending('calendar', 'تقویم مالی'),
                  _pending(
                    'debts',
                    'بدهی‌ها و طلب‌ها',
                    routes: [_pending(':debtId', 'جزئیات بدهی')],
                  ),
                  _pending(
                    'installments',
                    'اقساط',
                    routes: [_pending(':installmentId', 'جزئیات قسط')],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.settings,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => GlassPushPage(
          key: state.pageKey,
          child: SettingsScreen(
            onBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.dashboard);
              }
            },
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.search,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) =>
            GlassPushPage(key: state.pageKey, child: const SearchShellScreen()),
      ),
      _pending(
        '${AppRoutes.habits}/:habitId',
        'عادت‌ها',
        parentNavigatorKey: rootNavigatorKey,
      ),
      _pending(
        '${AppRoutes.goals}/:goalId',
        'هدف‌ها',
        parentNavigatorKey: rootNavigatorKey,
      ),
      _pending(
        '${AppRoutes.challenges}/:challengeId',
        'چالش‌ها',
        parentNavigatorKey: rootNavigatorKey,
      ),
      _pending(
        AppRoutes.backup,
        'پشتیبان‌گیری',
        parentNavigatorKey: rootNavigatorKey,
      ),
      _pending(
        AppRoutes.migration,
        'انتقال اطلاعات',
        parentNavigatorKey: rootNavigatorKey,
      ),
      if (kDebugMode)
        GoRoute(
          path: AppRoutes.glassReview,
          parentNavigatorKey: rootNavigatorKey,
          pageBuilder: (context, state) => GlassPushPage(
            key: state.pageKey,
            child: const GlassReviewScreen(referenceDir: glassReferenceDir),
          ),
        ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});

/// A scrolling branch root for the legacy panels: safe-area padding, no
/// max-width cap. The shell's bottom padding (tab bar) is part of the scroll
/// extent, so Flutter's own reveal can leave a focused field under the tab
/// bar; this page nudges it above the padding zone.
final class _BranchPage extends StatefulWidget {
  const _BranchPage({required this.child});

  final Widget child;

  @override
  State<_BranchPage> createState() => _BranchPageState();
}

final class _BranchPageState extends State<_BranchPage> {
  final ScrollController _controller = ScrollController();
  double _bottomPadding = 0;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_scheduleReveal);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_scheduleReveal);
    _controller.dispose();
    super.dispose();
  }

  void _scheduleReveal() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
  }

  void _reveal() {
    if (!mounted || !_controller.hasClients) return;
    final focus = FocusManager.instance.primaryFocus;
    final focusBox = focus?.context?.findRenderObject();
    final viewBox = context.findRenderObject();
    if (focusBox is! RenderBox ||
        viewBox is! RenderBox ||
        !focusBox.attached ||
        !focusBox.hasSize ||
        !viewBox.hasSize) {
      return;
    }
    if (!(focus!.context!.findAncestorStateOfType<_BranchPageState>() ==
        this)) {
      return;
    }
    final fieldBottom = focusBox
        .localToGlobal(Offset(0, focusBox.size.height))
        .dy;
    final limit =
        viewBox.localToGlobal(Offset(0, viewBox.size.height)).dy -
        _bottomPadding;
    final overlap = fieldBottom + 8 - limit;
    if (overlap <= 0) return;
    final position = _controller.position;
    final target = math.min(
      position.pixels + overlap,
      position.maxScrollExtent,
    );
    if (target > position.pixels) position.jumpTo(target);
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    if (_bottomPadding != padding.bottom) {
      _bottomPadding = padding.bottom;
      _scheduleReveal();
    }
    return SingleChildScrollView(
      controller: _controller,
      padding: padding + const EdgeInsets.symmetric(horizontal: 16),
      child: widget.child,
    );
  }
}
