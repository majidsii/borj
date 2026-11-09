import 'dart:async';

import 'package:borj/app/design/design.dart';
import 'package:borj/app/router/app_router.dart';
import 'package:borj/app/shell/window_class.dart';
import 'package:borj/app/theme/app_motion.dart';
import 'package:borj/app/theme/motion_scope.dart';
import 'package:borj/features/legacy_import/presentation/legacy_import_banner.dart';
import 'package:borj/features/today/application/today_providers.dart';
import 'package:borj/features/today/presentation/installment_card.dart';
import 'package:borj/features/today/presentation/timeline_card.dart';
import 'package:borj/features/today/presentation/today_grid.dart';
import 'package:borj/features/today/presentation/today_header.dart';
import 'package:borj/features/today/presentation/today_onboarding.dart';
import 'package:borj/features/today/presentation/today_tasks_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Today's cold start plays once per process (motion spec §4).
abstract final class TodayEntrance {
  static bool _played = false;

  static bool get played => _played;

  static void markPlayed() => _played = true;

  @visibleForTesting
  static void reset() => _played = false;
}

class TodayPage extends ConsumerStatefulWidget {
  const TodayPage({super.key});

  @override
  ConsumerState<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends ConsumerState<TodayPage> {
  /// True until the first build that shows content (grid or onboarding) has
  /// been laid out. The page state outlives tab switches, so the entrance must
  /// not replay when onboarding turns into the grid or a card appears later.
  late bool _entrancePending;
  bool _clearScheduled = false;

  @override
  void initState() {
    super.initState();
    _entrancePending = !TodayEntrance.played;
  }

  void _clearEntranceAfterFrame() {
    if (!_entrancePending || _clearScheduled) return;
    _clearScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _entrancePending = false;
      TodayEntrance.markPlayed();
    });
  }

  @override
  Widget build(BuildContext context) {
    final nowAsync = ref.watch(todayNowProvider);
    final compact = WindowClass.of(context) == WindowClass.compact;
    final padding = MediaQuery.paddingOf(context);
    final side = compact
        ? const EdgeInsets.symmetric(horizontal: 16)
        : const EdgeInsetsDirectional.fromSTEB(
            28,
            0,
            28,
            28,
          ).resolve(Directionality.of(context));

    final now = nowAsync.valueOrNull;
    Widget body = const SizedBox.shrink();
    if (nowAsync.hasError) {
      body = const EmptyState(
        icon: Icons.error_outline,
        title: 'امروز بارگذاری نشد',
      );
    } else if (now != null) {
      final newUser = ref.watch(todayIsNewUserProvider);
      final agenda = ref.watch(todayAgendaProvider);
      final installment = ref.watch(todayInstallmentProvider);
      final play = _entrancePending;
      if (newUser.hasError || agenda.hasError || installment.hasError) {
        body = const EmptyState(
          icon: Icons.error_outline,
          title: 'امروز بارگذاری نشد',
        );
      } else if (newUser.hasValue && agenda.hasValue && installment.hasValue) {
        _clearEntranceAfterFrame();
        if (newUser.requireValue) {
          body = KeyedSubtree(
            key: const ValueKey('today-onboarding'),
            child: _Enter(
              index: 0,
              play: play,
              child: TodayOnboarding(
                onAddTask: () => context.go(AppRoutes.tasks),
              ),
            ),
          );
        } else {
          final a = agenda.requireValue;
          final plan = installment.requireValue;
          final items = <TodayGridItem>[
            TodayGridItem(
              id: 'timeline',
              size: TodayCardSize.wide,
              child: TimelineCard(agenda: a, now: now),
            ),
            TodayGridItem(
              id: 'tasks',
              size: TodayCardSize.large,
              child: TodayTasksCard(
                agenda: a,
                now: now,
                onToggle: ref.read(todayCompletionProvider).toggle,
                onShowAll: () => context.go(AppRoutes.tasks),
              ),
            ),
            if (plan != null)
              TodayGridItem(
                id: 'installment',
                size: TodayCardSize.wide,
                child: InstallmentCard(
                  installment: plan,
                  animateIn: play,
                  onOpen: () => context.go('/finance'),
                ),
              ),
          ];
          body = KeyedSubtree(
            key: const ValueKey('today-grid'),
            child: TodayGrid(
              items: [
                for (var i = 0; i < items.length; i++)
                  TodayGridItem(
                    id: items[i].id,
                    size: items[i].size,
                    child: _Enter(index: i, play: play, child: items[i].child),
                  ),
              ],
            ),
          );
        }
      }
    }

    return ListView(
      key: const ValueKey('today-page'),
      padding: padding + side,
      children: [
        if (now != null)
          TodayHeader(
            now: now,
            onTitleLongPress: kDebugMode
                ? () => context.push(AppRoutes.glassReview)
                : null,
          ),
        const LegacyImportBanner(),
        const SizedBox(height: 20),
        body,
      ],
    );
  }
}

/// Rises 8 px and fades one item in on cold start. One controller spans the
/// stagger delay plus the fade, so no timer is needed; the glass fades only
/// through [GlassVisibility].
class _Enter extends StatefulWidget {
  const _Enter({required this.index, required this.play, required this.child});

  final int index;
  final bool play;
  final Widget child;

  @override
  State<_Enter> createState() => _EnterState();
}

class _EnterState extends State<_Enter> with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  CurvedAnimation? _t;
  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.play || _controller != null) return;
    _reduced = MotionScope.reducedOf(context);
    final m = _reduced ? AppMotion.reduced : AppMotion.quick;
    final stagger = AppMotion.staggerAt(widget.index);
    final total = stagger + m.duration;
    final controller = _controller = AnimationController(
      vsync: this,
      duration: total,
      // The reduced fade keeps its own duration (AppMotion.reduced); the
      // default behaviour would shrink it 20x under disableAnimations.
      animationBehavior: AnimationBehavior.preserve,
    );
    _t = CurvedAnimation(
      parent: controller,
      curve: Interval(
        stagger.inMicroseconds / total.inMicroseconds,
        1,
        curve: m.curve,
      ),
    );
    controller.addListener(() => setState(() {}));
    unawaited(controller.forward());
  }

  @override
  void dispose() {
    _t?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _t?.value ?? 1.0;
    Widget child = GlassVisibility(value: t, child: widget.child);
    if (!_reduced && t < 1) {
      child = Transform.translate(offset: Offset(0, 8 * (1 - t)), child: child);
    }
    return child;
  }
}
