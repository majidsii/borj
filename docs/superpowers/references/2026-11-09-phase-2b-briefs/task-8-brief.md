### Task 8: TodayPage, entrance and router

**Files:**
- Create: `lib/features/today/presentation/today_page.dart`
- Modify: `lib/app/router/app_router.dart` (`/` builds `TodayPage`), delete `lib/app/shell/today_interim_page.dart`, update tests that reference `TodayInterimPage` (`grep -rn TodayInterimPage lib test integration_test`)
- Test: `test/features/today/today_page_test.dart`, `test/features/today/today_budget_test.dart`

**Interfaces:**
- Consumes: Tasks 1–7; `LegacyImportBanner`; `AppRoutes.glassReview`, `AppRoutes.tasks`; `GlassVisibility`; `AppMotion.quick`, `AppMotion.reduced`, `AppMotion.staggerAt`; `MotionScope`; `WindowClass`.
- Produces:
  - `abstract final class TodayEntrance { static bool get played; static void markPlayed(); @visibleForTesting static void reset(); }` — process-wide cold-start flag.
  - `class TodayPage extends ConsumerStatefulWidget { const TodayPage({super.key}); }` — a `ListView` padded with `MediaQuery.paddingOf(context)` plus `EdgeInsets.symmetric(horizontal: 16)` on compact and `EdgeInsetsDirectional.fromSTEB(28, 0, 28, 28)` on medium/expanded: `TodayHeader(now:, onTitleLongPress: kDebugMode ? () => context.push(AppRoutes.glassReview) : null)`, `LegacyImportBanner()`, then either `TodayOnboarding(onAddTask: () => context.go(AppRoutes.tasks))` when `todayIsNewUserProvider` is true, or a `TodayGrid` of: `timeline` (wide) `TimelineCard`, `tasks` (large) `TodayTasksCard(onToggle: ref.read(todayCompletionProvider).toggle, onShowAll: () => context.go(AppRoutes.tasks))`, and `installment` (wide) `InstallmentCard(onOpen: () => context.go('/finance'))` when `todayInstallmentProvider` has a plan. Loading: an empty `SizedBox` for the grid area (no spinner flash); error: `EmptyState(icon: Icons.error_outline, title: 'امروز بارگذاری نشد')`.
  - Entrance: each grid item and the onboarding cards are wrapped in `_Enter(index:)`: on cold start (`!TodayEntrance.played`, read once in `initState`), a controller per item runs after `AppMotion.staggerAt(index)` for `AppMotion.quick.duration` (`reduced` under Reduce Motion); the child is `Transform.translate(offset: Offset(0, 8 × (1 − t)))` (skipped when reduced) around `GlassVisibility(value: t)`. `TodayEntrance.markPlayed()` is called in the first post-frame callback. Later builds use `t = 1` with no controller. `animateIn` on `InstallmentCard` is true only on cold start.
  - Keys: `ValueKey('today-page')` on the ListView, `ValueKey('today-onboarding')`, `ValueKey('today-grid')`.

- [ ] **Step 1: Write the failing tests**

`test/features/today/today_page_test.dart` — pump the real app with `pumpBorjTestApp` (`test/support/borj_test_app.dart`, with `useWindowSize` for 390×844 and 1440×900) and a `FixedAppClock` override at 2026-11-04 14:30 local plus `taskCalendarTimeZoneProvider` overridden to `'Asia/Tehran'`; call `TodayEntrance.reset()` in `setUp`:
```dart
// 1. empty database → TodayOnboarding shown; tap `onboarding-add-task` → the Tasks branch (TasksPanel) is visible.
// 2. with one planned task due today 15:00 local → `today-grid` shown with timeline + tasks cards, no installment card,
//    the timeline header reads «بعدی:» + the task title, and the tasks card row `today-task-<id>` exists.
// 3. toggling the row's RoundCheck marks the task completed in the repository (read it back); toggling again → planned.
// 4. with an active InstallmentPlan → the installment card appears; tapping it goes to /finance (FinancePanel visible).
// 5. compact header shows «چهارشنبه ۱۳ آبان»; expanded shows the date chip «۱۳ آبان ۱۴۰۵».
// 6. debug long-press on `today-title` pushes the glass review; pop returns to Today.
// 7. entrance: on the first build cards start invisible (GlassVisibility value 0 on the first frame) and reach 1 within
//    300 ms + the last stagger; a second TodayPage build (switch to Tasks and back) has no entrance (value 1 on the first frame).
// 8. reduce motion: the first build moves nothing (expectNoMovement on `today-grid`) and still fades (value < 1 then 1).
// 9. the agenda follows the clock: advance the overridden minuteTickProvider to the next day → the task due today disappears.
```
Write each as a concrete `testWidgets` (create data through the real repositories from the container: `container.read(taskRepositoryProvider).create(...)` then `transition(...)`, `container.read(financeRepositoryProvider)` for an installment plan — read `finance_repository.dart` for the create method).

`test/features/today/today_budget_test.dart`:
```dart
// With the populated Today (task + installment) in BorjApp at 390×844 and 1440×900:
// countCompositedBackdrops == 2 at idle (content group 1 + chrome 1) on both, sampled over 20 frames,
// and during the cold-start entrance (sample the first 30 frames) max == 2; no bare fade above any card glass
// (bareFadesAboveGlass over the today-page) during the entrance.
```
Write it concretely (pattern: `test/app/shell/app_shell_budget_test.dart`).

- [ ] **Step 2: Run.** Expected: FAIL.

- [ ] **Step 3: Implement** `lib/features/today/presentation/today_page.dart`:
```dart
import 'dart:async';

import 'package:borj/app/design/design.dart';
import 'package:borj/app/router/app_router.dart';
import 'package:borj/app/shell/window_class.dart';
import 'package:borj/app/theme/app_motion.dart';
import 'package:borj/app/theme/motion_scope.dart';
import 'package:borj/core/providers/persistence_providers.dart';
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
  late final bool _coldStart = !TodayEntrance.played;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => TodayEntrance.markPlayed());
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(minuteTickProvider).valueOrNull ?? ref.read(appClockProvider).nowLocal();
    final compact = WindowClass.of(context) == WindowClass.compact;
    final newUser = ref.watch(todayIsNewUserProvider);
    final agenda = ref.watch(todayAgendaProvider);
    final installment = ref.watch(todayInstallmentProvider);

    Widget body;
    if (newUser.hasError || agenda.hasError) {
      body = const EmptyState(icon: Icons.error_outline, title: 'امروز بارگذاری نشد');
    } else if (!newUser.hasValue || !agenda.hasValue || !installment.hasValue) {
      body = const SizedBox.shrink();
    } else if (newUser.requireValue) {
      body = KeyedSubtree(
        key: const ValueKey('today-onboarding'),
        child: _Enter(index: 0, play: _coldStart, child: TodayOnboarding(onAddTask: () => context.go(AppRoutes.tasks))),
      );
    } else {
      final a = agenda.requireValue;
      final plan = installment.requireValue;
      final items = <TodayGridItem>[
        TodayGridItem(id: 'timeline', size: TodayCardSize.wide, child: TimelineCard(agenda: a, now: now)),
        TodayGridItem(
          id: 'tasks',
          size: TodayCardSize.large,
          child: TodayTasksCard(agenda: a, now: now, onToggle: ref.read(todayCompletionProvider).toggle, onShowAll: () => context.go(AppRoutes.tasks)),
        ),
        if (plan != null)
          TodayGridItem(id: 'installment', size: TodayCardSize.wide, child: InstallmentCard(installment: plan, animateIn: _coldStart, onOpen: () => context.go('/finance'))),
      ];
      body = KeyedSubtree(
        key: const ValueKey('today-grid'),
        child: TodayGrid(items: [
          for (var i = 0; i < items.length; i++)
            TodayGridItem(id: items[i].id, size: items[i].size, child: _Enter(index: i, play: _coldStart, child: items[i].child)),
        ]),
      );
    }

    final media = MediaQuery.paddingOf(context);
    final side = compact ? const EdgeInsets.symmetric(horizontal: 16) : const EdgeInsetsDirectional.fromSTEB(28, 0, 28, 28).resolve(Directionality.of(context));
    return ListView(
      key: const ValueKey('today-page'),
      padding: media + side,
      children: [
        TodayHeader(now: now, onTitleLongPress: kDebugMode ? () => context.push(AppRoutes.glassReview) : null),
        const LegacyImportBanner(),
        const SizedBox(height: 20),
        body,
      ],
    );
  }
}

class _Enter extends StatefulWidget {
  const _Enter({required this.index, required this.play, required this.child});

  final int index;
  final bool play;
  final Widget child;

  @override
  State<_Enter> createState() => _EnterState();
}

class _EnterState extends State<_Enter> with SingleTickerProviderStateMixin {
  AnimationController? _c;
  Timer? _delay;
  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.play || _c != null) return;
    _reduced = MotionScope.reducedOf(context);
    final m = _reduced ? AppMotion.reduced : AppMotion.quick;
    final c = _c = AnimationController(vsync: this, duration: m.duration);
    final curved = CurvedAnimation(parent: c, curve: m.curve);
    c.addListener(() => setState(() {}));
    _curved = curved;
    _delay = Timer(AppMotion.staggerAt(widget.index), () {
      if (mounted) unawaited(c.forward());
    });
  }

  CurvedAnimation? _curved;

  @override
  void dispose() {
    _delay?.cancel();
    _curved?.dispose();
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _curved?.value ?? 1.0;
    Widget child = GlassVisibility(value: t, child: widget.child);
    if (!_reduced && t < 1) child = Transform.translate(offset: Offset(0, 8 * (1 - t)), child: child);
    return child;
  }
}
```
`GlassVisibility` dims the glass and its children (Phase 1), so the cards' text fades with the glass; the header is not wrapped (static). Timers in widget tests: the stagger uses `Timer`, so tests must `pump` past the last stagger (`AppMotion.staggerAt(2)` + the duration) before ending, or the test framework reports a pending timer — keep that in the tests.

Router: in `lib/app/router/app_router.dart`, the `/` branch root builds `const TodayPage()` (keep `NoTransitionPage`); delete `today_interim_page.dart` and its import; update `test/app/router/app_router_test.dart` and any test that finds `TodayInterimPage` to find `TodayPage` (the «صفحهٔ امروز در حال ساخت است» assertion becomes the onboarding check on an empty database). Keep the `today-title` key working on both classes.

- [ ] **Step 4: Run** `flutter test test/features/today test/app/router test/app/shell`, then the full `flutter test --exclude-tags device`. Expected: PASS. `flutter analyze`.
- [ ] **Step 5: Commit** `feat(today): today page with cold-start entrance`.

---

