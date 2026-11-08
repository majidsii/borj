# Redesign Phase 2 Part A — App Shell and Navigation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the dashboard's panel switch and 780 px cap with a real app shell: go_router branches, a floating glass tab bar on phones, a glass sidebar on desktop (icon rail on medium), fixed glass chrome, push and inspector motion, a search shell, and every notification location resolving.

**Architecture:** `StatefulShellRoute.indexedStack` with three visible branches (Today, Tasks, Finance). `AppShell` lays the branch navigator out per window class and paints all chrome of a window class in ONE chrome `GlassScope`, painted after the content. The branch navigator sits under ONE shell-level content `GlassBackdropGroup`, so all content glass shares one capture. Pages never add their own `GlassBackdropGroup`. The existing `TasksPanel` and `FinancePanel` are mounted unchanged in their branches; Phases 3 and 4 rebuild them. Today is an interim page until Part B.

**Tech Stack:** Flutter 3.47.5, go_router (`StatefulShellRoute`), Riverpod, liquid_glass_renderer 1.0.0-dev.2 via `lib/app/apple_visual/glass.dart`, the Phase 1 primitives in `lib/app/design/`.

**Phase 2 split** (this plan is Part A):
- Part A (this plan): shell, navigation, push/inspector/tab-lens motion, search shell, notification routes, app icon wiring.
- Part B: Today rebuilt to the `Main` / `MacToday` / `PhoneEmptyToday` boards, cold-start choreography.
- Part C: Today customization (motion spec §5, schema 10) and the edit-mode perf probe.
Owner sign-off on the review page and the A34 profile run happen at the end of Part C (the Phase 2 checkpoint), not after Part A.

## Global Constraints

Copied verbatim from the Phase 1 Part B plan (`docs/superpowers/plans/2026-11-07-redesign-phase-1b-primitives.md`): ("Task N" inside these lines means a Part B task; those tasks are done).

- Flutter 3.47.5: put `/home/shabin/develop/flutter-3.47.5/bin` first on `PATH`. In a fresh worktree, run `flutter pub get` once.
- Only `lib/app/apple_visual/widgets/apple_liquid_glass.dart` and `lib/app/bootstrap/app_bootstrap.dart` may import `package:liquid_glass_renderer`. `test/app/apple_visual/renderer_import_boundary_test.dart` enforces this.
- New UI code imports `package:borj/app/design/design.dart`, which re-exports `package:borj/app/apple_visual/glass.dart`. Neither barrel re-exports the renderer.
- No glass on glass. Inside an `AppGlass` subtree (`GlassContext.isOnGlass(context)` is true), primitives use `GlassInner` or a flat fill. `AppGlass` asserts when it is built inside another `AppGlass`. There is no lens exception.
- Colours come only from `AppTheme.of(context).colors`. Brightness comes from `Theme.of(context).brightness`. Text styles come from `AppTheme.of(context).text`. Spacing and radii come from `AppSpacing` and `AppRadii`. No literal colours appear in `lib/app/design/**` except the ones listed here.
- New colour tokens, added in Task 1:
  - `switchOn` `#1FB5A8` (board, both modes)
  - `switchOff`: light `rgba(27,34,54,.12)` = `0x1F1B2236`, dark `rgba(255,255,255,.16)` = `0x29FFFFFF`
  - `thumbSurface` `#FFFFFF` (both)
  - `thumbText` `#1F5FD0` (both modes; it sits on the white thumb, so the light link colour is the readable one)
  - `pressShadow` `rgba(20,30,80,.20)` = `0x33141E50`
  - `knobShadow` `rgba(20,30,80,.35)` = `0x59141E50`
  - `scrim`: light `rgba(10,14,30,.25)` = `0x400A0E1E`, dark `rgba(0,0,0,.45)` = `0x73000000`
- Motion uses only `AppMotion` (`lib/app/theme/app_motion.dart`): `press` (120 ms), `quick` (200 ms), `standard`, `snappy`, `soft`, `dataUpdate` (350 ms), `dataEnter` (450 ms), `exitFactor` 0.7, `reduced` (200 ms `Curves.easeOut`). Never use ease-in curves.
- Under Reduce Motion (`MotionScope.reducedOf(context)`), patterns produce no translation, scale or size animation. Only opacity changes over `AppMotion.reduced`, and moving parts jump to their end position. Every pattern test proves this with `test/support/reduced_motion_expectations.dart` (Task 1).
- Every primitive and pattern test runs the matrix from `test/support/glass_test_app.dart` (Task 1): RTL × light/dark × text scale 1.0 and 1.3, with no exceptions and no overflow.
- Press feedback appears on pointer-down: scale 0.97 with `AppMotion.press`. Hover highlight is for mouse pointers only.
- Minimum hit target: 44 × 44 logical px.
- Persian digits, grouping separator `٬` (U+066C), percent sign `٪` (U+066A). Numbers use tabular figures (`AppTextRoles.tabular`).
- Capture budget per frame, measured during interaction and not only at settle: ≤ 3 on phone, ≤ 4 on desktop. The capture log fails on the renderer's 16-shape warning.
- Glass-intensity slider: `onChanged` calls `previewGlassIntensity`, `onChangeEnd` calls `commitGlassIntensity`. Flutter 3.47.5's `Slider` calls `onChangeEnd` on drag end, on drag cancel (`_endInteraction`) and on keyboard and semantics increase/decrease (`slider.dart:1634`, `:2008–2023`).
- Lints that bite: `require_trailing_commas`, `sort_constructors_first`, `directives_ordering`, `prefer_final_locals`, `unawaited_futures`, `avoid_print` (use `// ignore: avoid_print` in probes only), `avoid_dynamic_calls`.
- Before every commit:
  - `dart format` the changed files;
  - `dart format --output=none --set-exit-if-changed lib test integration_test` exits 0;
  - `flutter analyze` is clean;
  - run the full `flutter test --exclude-tags device` once.
- Stage explicit paths; never `git add -A`; never use bare `git stash`; do not push. Commit messages end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Do not add new `tool/verify_*` scripts.
- `matchesSemantics(...)` in this Flutter version may require extra flags, such as `hasFocusAction` or `isFocusable`. Add only the flags the widget really has. Never remove the flag the test is about (`isButton`, `isToggled`, `isChecked`, `isSelected`, `isLiveRegion`, the label).
- If a test in this plan cannot pass as written for a reason outside your code, for example a framework API that differs, change it minimally so it still asserts the same behaviour, and report the change. Never weaken what it asserts.
- Report every command you ran with its real result, and any failure verbatim.

Added for Phase 2 Part A:

- Window classes (redesign spec §5): compact `< 600`, medium `600–1023`, expanded `≥ 1024` logical px of window width. Tests cover the widths 599, 600, 1023 and 1024.
- Phone shell (boards `Main`, `PhoneTasks`, `PhoneMoney`): tab bar capsule 62 tall (items 54 + padding 4), `bottom: 24`, `inset-inline: 16`, gap 10, search circle 62 × 62 to its leading side (left in RTL); toolbar circles 44 × 44, side padding 16, at `top: 58` when the top safe-area padding is 0 (the board's frame) and at `MediaQuery.paddingOf(context).top + 14` otherwise.
- Desktop shell (board `MacToday`): sidebar on the RIGHT, width 236 (min 210), margin 8, radius 20, padding `14 vertical / 10 horizontal`, section header 12 pt bold `textSecondary` with padding `6 10 4`, item height 36, item radius 12, gap 2, selected item is `GlassInner`. Toolbar row padding `14 16 0 20`, controls 36 tall, search capsule 230 wide. The OS draws window controls: the board's traffic-light dots are not drawn. The window fills the OS window (no desk margin); its background is `AppBackground(kind: AppBackgroundKind.phone)` painted edge to edge on every class (the desk kind belongs to the boards' screenshot frame).
- Medium shell: an icon rail of width 72 on the right with the same items (icons only, tooltips with the label), settings at the bottom.
- Visible sections (decision `docs/superpowers/decisions/2026-11-08-shell-settings-entry-and-unbuilt-sections.md`): tabs امروز / کارها / مالی; sidebar groups برنامه (امروز, همهٔ کارها, تقویم) and پول (تراکنش‌ها, قسط و بدهی). عادت‌ها, هدف‌ها and بودجه are hidden behind `ShellFeatures` flags (all `false`); the زندگی header is hidden while all its items are. Settings: a glass circle in the Today toolbar on compact (next to the calendar circle); a «تنظیمات» row at the bottom of the sidebar or rail; `Ctrl+,` everywhere.
- Capture budget per window class: compact = content 1 + chrome 1 + overlays 1 = 3; medium = content 1 + chrome 1 + overlays 1 = 3; expanded = content 1 + chrome 1 + inspector 1 + overlays 1 = 4. All chrome shapes of a window class live in one `GlassScope(kind: GlassLayerKind.chrome)` (compact ≤ 5 shapes, expanded ≤ 6). Pages inside the shell never create a `GlassBackdropGroup`; the shell's content group covers the branch navigator.
- Tab / section switch: content swaps instantly (no animation on the content); only the tab bar's `GlassInner` lens slides with `AppMotion.snappy` and stretches at most 12 % along the travel axis mid-way. The sidebar's selection jumps (macOS convention; motion spec "frequency rule").
- Push (compact only, routes with `GlassPushPage`): Flutter's Cupertino page transition and back gesture (direction-aware: in RTL the new page enters from the left, the back swipe starts at the right edge), plus a `scrim` over the outgoing page that grows with the secondary animation. The dim is a colour overlay, never `Opacity` / `ColorFiltered` / `FadeTransition` over glass (Phase 1 ruling D3). Under Reduce Motion the push is instant (`Duration.zero`): a page holds glass, and a page cross-fade would bare-fade it (D3). On medium and expanded the same pages use `NoTransitionPage` semantics (instant).
- `GlassInspector` (expanded only): slides in from the LEADING edge (left in RTL) with `AppMotion.standard`; closes with `standard` × `AppMotion.exitFactor`; Reduce Motion: appears and disappears through `GlassVisibility` over `AppMotion.reduced`, no slide. Its glass is one `GlassScope(kind: GlassLayerKind.sheet)`. Width 360.
- Every location produced by `NotificationRouteLocationMapper` resolves to a page that is not the error page. The mapper is completed foundation work and is not changed.
- The debug glass-review page opens by long-pressing the Today large title (debug builds only), replacing the removed brand island.
- Pattern tests of this plan run the `glassTestVariants` matrix like the Part B ones. Where a test file shown below has no matrix loop (`glass_push_page_test.dart`, `glass_inspector_test.dart`, `app_shell_test.dart`), add one: `for (final v in glassTestVariants) testWidgets('renders (${v.name})', …)` that pumps the subject with `brightness: v.brightness, textScale: v.textScale` (for the router-based tests, pass them through `glassTestTheme(v.brightness)` and a `MediaQuery` text scaler) and asserts `tester.takeException()` is null.
- `lib/features/**` may import `package:borj/app/shell/...` and `package:borj/app/design/design.dart`; no colours or sizes in `lib/features/**` for new code.

## Decisions recorded by this plan

1. **Settings and unbuilt sections:** see the decision file above (owner, 2026-11-08).
2. **Chrome paints after content in one scope.** Members that share a backdrop key read the snapshot taken at the first member in paint order (`backdrop_seed.dart` `_decideSeedKey`). Chrome in its own `GlassScope` painted last therefore sees the scrolling content under it. Screens hand their toolbar actions to the shell as data (`ShellDestination.actions`), and the shell renders them; screens never paint chrome.
3. **Adaptive detail presentation is deferred to Phase 3.** The boards present details differently per screen (task detail is a sheet on phone, an inspector on Mac), and no real detail screen exists yet. Part A builds `GlassInspector` and `GlassPushPage` as patterns, and the detail URLs (`/tasks/:taskId`, `/finance/debts/:debtId`, …) resolve to `PendingScreen` pages pushed inside their branch. Phase 3 replaces the task detail with the adaptive presentation (push or sheet on compact, inspector on expanded, same URL) and tests the 599/600/1023/1024 widths and live resizing with a detail open.
4. **Settings stays a root push in Part A** on every window class. Phase 5 rebuilds Settings to `MacSettings` (sidebar sections in the window).
5. **Reduced-motion push is instant**, not a cross-fade (constraint above; spec motion §8 "Reduce Motion cross-fades" is satisfied for patterns whose glass fades through `GlassVisibility`; a whole page cannot).
6. **The theme island is removed.** Appearance (روشن / تیره / خودکار) lives in Settings (Phase 1 Task 9).
7. **Legacy panels may exceed the budget.** `TasksPanel` and `FinancePanel` still use the legacy glass; the device probe asserts the budget on the interim Today and Settings and only reports the counts on the Tasks and Finance branches. Phases 3 and 4 bring them under budget.

## File structure

```
lib/app/shell/window_class.dart              WindowClass (compact/medium/expanded) + of(context)        (Task 1)
lib/app/shell/shell_destinations.dart        ShellFeatures, ShellSection, ShellDestination, SidebarGroup/Item, shellDestinations, sidebarGroups (Task 1)
lib/app/design/patterns/sliding_lens.dart    SlidingLens: animated GlassInner pill between rects          (Task 2)
lib/app/design/patterns/glass_tab_bar.dart   GlassTabBar + search circle (compact)                        (Task 2)
lib/app/design/patterns/glass_sidebar.dart   GlassSidebar (expanded) and rail (medium)                    (Task 3)
lib/app/design/patterns/shell_toolbar.dart   ShellAction, ShellToolbar                                    (Task 4)
lib/app/design/patterns/large_title_header.dart LargeTitleHeader                                        (Task 4)
lib/app/design/patterns/empty_state.dart     EmptyState                                                   (Task 4)
lib/app/design/patterns/glass_push_page.dart GlassPushPage (go_router Page)                               (Task 5)
lib/app/design/patterns/glass_inspector.dart GlassInspector                                               (Task 5)
lib/app/shell/app_shell.dart                 AppShell (layouts per window class, chrome scope, shortcuts) (Task 6)
lib/app/shell/pending_screen.dart            PendingScreen, RouteErrorScreen                             (Task 7)
lib/app/shell/today_interim_page.dart        interim Today page (until Part B)                           (Task 7)
lib/app/router/app_router.dart               StatefulShellRoute + branches + root routes                  (Task 7)
lib/app/shell/search_shell.dart              SearchShellScreen (/search) + showSearchOverlay (Ctrl+K)    (Task 8)
lib/app/apple_visual/review/design_review_samples.dart  + shell pattern samples                         (Task 9)
integration_test/glass_shell_probe_test.dart device probe on the real shell                              (Task 10)
linux/runner/my_application.cc, windows/runner/resources/app_icon.ico, macos/.../AppIcon.appiconset, android/.../mipmap-*  icons (Task 11)
Deleted: lib/features/dashboard/presentation/dashboard_screen.dart, test/features/dashboard/original_dashboard_screen_test.dart, test/features/dashboard/dashboard_chrome_glass_test.dart (Task 7; their assertions move, see Task 7)
```

`lib/app/design/design.dart` exports every new pattern (each task adds its line).

---

### Task 1: Window classes and shell destinations

**Files:**
- Create: `lib/app/shell/window_class.dart`
- Create: `lib/app/shell/shell_destinations.dart`
- Test: `test/app/shell/window_class_test.dart`, `test/app/shell/shell_destinations_test.dart`

**Interfaces:**
- Produces:
  - `enum WindowClass { compact, medium, expanded }` with `static WindowClass forWidth(double width)` and `static WindowClass of(BuildContext context)` (reads `MediaQuery.sizeOf(context).width`).
  - `abstract final class ShellFeatures { static const bool habits = false; static const bool goals = false; static const bool budgets = false; }`
  - `enum ShellSection { today, tasks, finance }` (branch index = `index`).
  - `final class ShellDestination { const ShellDestination({required this.section, required this.label, required this.icon, required this.location}); }`
  - `const List<ShellDestination> shellDestinations` (3 entries, in tab order).
  - `final class SidebarItem { const SidebarItem({required this.label, required this.icon, required this.location, required this.section}); }`
  - `final class SidebarGroup { const SidebarGroup({required this.label, required this.items}); }`
  - `List<SidebarGroup> sidebarGroups()` — groups with no visible item are dropped.
  - `String sectionLocation(ShellSection section)`.

- [ ] **Step 1: Write the failing tests**

`test/app/shell/window_class_test.dart`:
```dart
import 'package:borj/app/shell/window_class.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('breakpoints at 600 and 1024', () {
    expect(WindowClass.forWidth(320), WindowClass.compact);
    expect(WindowClass.forWidth(599), WindowClass.compact);
    expect(WindowClass.forWidth(599.9), WindowClass.compact);
    expect(WindowClass.forWidth(600), WindowClass.medium);
    expect(WindowClass.forWidth(1023), WindowClass.medium);
    expect(WindowClass.forWidth(1023.9), WindowClass.medium);
    expect(WindowClass.forWidth(1024), WindowClass.expanded);
    expect(WindowClass.forWidth(1440), WindowClass.expanded);
  });

  testWidgets('of(context) follows the window width', (tester) async {
    WindowClass? seen;
    Future<void> pumpAt(double width) async {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: Size(width, 800)),
          child: Builder(
            builder: (context) {
              seen = WindowClass.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
    }

    await pumpAt(599);
    expect(seen, WindowClass.compact);
    await pumpAt(1024);
    expect(seen, WindowClass.expanded);
  });
}
```

`test/app/shell/shell_destinations_test.dart`:
```dart
import 'package:borj/app/shell/shell_destinations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('three visible tabs in board order', () {
    expect(shellDestinations.map((d) => d.label), ['امروز', 'کارها', 'مالی']);
    expect(shellDestinations.map((d) => d.section), ShellSection.values);
    expect(shellDestinations.map((d) => d.location), ['/', '/tasks', '/finance']);
  });

  test('sidebar shows برنامه and پول; زندگی and بودجه stay hidden', () {
    final groups = sidebarGroups();
    expect(groups.map((g) => g.label), ['برنامه', 'پول']);
    expect(groups[0].items.map((i) => i.label), ['امروز', 'همهٔ کارها', 'تقویم']);
    expect(groups[1].items.map((i) => i.label), ['تراکنش‌ها', 'قسط و بدهی']);
    expect(
      groups.expand((g) => g.items).map((i) => i.location),
      ['/', '/tasks', '/tasks?view=calendar', '/finance/transactions', '/finance/debts'],
    );
  });

  test('hidden features are off until they ship', () {
    expect(ShellFeatures.habits, isFalse);
    expect(ShellFeatures.goals, isFalse);
    expect(ShellFeatures.budgets, isFalse);
  });

  test('sectionLocation', () {
    expect(sectionLocation(ShellSection.today), '/');
    expect(sectionLocation(ShellSection.tasks), '/tasks');
    expect(sectionLocation(ShellSection.finance), '/finance');
  });
}
```

- [ ] **Step 2: Run** `flutter test test/app/shell`. Expected: FAIL (files missing).

- [ ] **Step 3: Implement**

`lib/app/shell/window_class.dart`:
```dart
import 'package:flutter/widgets.dart';

/// Window classes of redesign spec §5: compact < 600, medium 600–1023,
/// expanded ≥ 1024 logical px of window width.
enum WindowClass {
  compact,
  medium,
  expanded;

  static WindowClass forWidth(double width) {
    if (width < 600) return WindowClass.compact;
    if (width < 1024) return WindowClass.medium;
    return WindowClass.expanded;
  }

  static WindowClass of(BuildContext context) =>
      forWidth(MediaQuery.sizeOf(context).width);
}
```

`lib/app/shell/shell_destinations.dart`:
```dart
import 'package:flutter/material.dart';

/// Sections whose feature does not exist yet stay hidden until it ships
/// (decision 2026-11-08-shell-settings-entry-and-unbuilt-sections).
abstract final class ShellFeatures {
  static const bool habits = false;
  static const bool goals = false;
  static const bool budgets = false;
}

/// The shell's branches, in tab order. The branch index is [index].
enum ShellSection { today, tasks, finance }

final class ShellDestination {
  const ShellDestination({
    required this.section,
    required this.label,
    required this.icon,
    required this.location,
  });

  final ShellSection section;
  final String label;
  final IconData icon;
  final String location;
}

const List<ShellDestination> shellDestinations = <ShellDestination>[
  ShellDestination(
    section: ShellSection.today,
    label: 'امروز',
    icon: Icons.wb_sunny_outlined,
    location: '/',
  ),
  ShellDestination(
    section: ShellSection.tasks,
    label: 'کارها',
    icon: Icons.check_circle_outline,
    location: '/tasks',
  ),
  ShellDestination(
    section: ShellSection.finance,
    label: 'مالی',
    icon: Icons.account_balance_wallet_outlined,
    location: '/finance',
  ),
];

String sectionLocation(ShellSection section) =>
    shellDestinations[section.index].location;

final class SidebarItem {
  const SidebarItem({
    required this.label,
    required this.icon,
    required this.location,
    required this.section,
  });

  final String label;
  final IconData icon;
  final String location;
  final ShellSection section;
}

final class SidebarGroup {
  const SidebarGroup({required this.label, required this.items});

  final String label;
  final List<SidebarItem> items;
}

/// The sidebar of the `MacToday` board, without the hidden features. A group
/// whose items are all hidden is dropped (its header too).
List<SidebarGroup> sidebarGroups() {
  final groups = <SidebarGroup>[
    const SidebarGroup(
      label: 'برنامه',
      items: <SidebarItem>[
        SidebarItem(
          label: 'امروز',
          icon: Icons.wb_sunny_outlined,
          location: '/',
          section: ShellSection.today,
        ),
        SidebarItem(
          label: 'همهٔ کارها',
          icon: Icons.check_circle_outline,
          location: '/tasks',
          section: ShellSection.tasks,
        ),
        SidebarItem(
          label: 'تقویم',
          icon: Icons.calendar_month_outlined,
          location: '/tasks?view=calendar',
          section: ShellSection.tasks,
        ),
      ],
    ),
    SidebarGroup(
      label: 'پول',
      items: <SidebarItem>[
        const SidebarItem(
          label: 'تراکنش‌ها',
          icon: Icons.receipt_long_outlined,
          location: '/finance/transactions',
          section: ShellSection.finance,
        ),
        if (ShellFeatures.budgets)
          const SidebarItem(
            label: 'بودجه',
            icon: Icons.pie_chart_outline,
            location: '/finance/budgets',
            section: ShellSection.finance,
          ),
        const SidebarItem(
          label: 'قسط و بدهی',
          icon: Icons.handshake_outlined,
          location: '/finance/debts',
          section: ShellSection.finance,
        ),
      ],
    ),
    const SidebarGroup(
      label: 'زندگی',
      items: <SidebarItem>[
        // عادت‌ها and هدف‌ها return here when ShellFeatures.habits / goals
        // turn on (with their own ShellSection and branch).
      ],
    ),
  ];
  return [for (final g in groups) if (g.items.isNotEmpty) g];
}
```
`if (ShellFeatures.budgets)` on a `const false` is `dead_code` for the analyzer, which is an error in this repo. If `flutter analyze` reports it, replace the collection-`if` with a runtime list filter instead: give `SidebarItem` a `final bool visible` field (default `true`, `visible: ShellFeatures.budgets` on بودجه) and filter `items.where((i) => i.visible)` in `sidebarGroups()`. Update the test expectations only if they would change (they do not).

- [ ] **Step 4: Run** `flutter test test/app/shell`. Expected: PASS. Run `flutter analyze`.
- [ ] **Step 5: Commit** `feat(shell): window classes and shell destinations`.

---

### Task 2: SlidingLens and GlassTabBar

**Files:**
- Create: `lib/app/design/patterns/sliding_lens.dart`, `lib/app/design/patterns/glass_tab_bar.dart`
- Modify: `lib/app/design/design.dart` (export both)
- Test: `test/app/design/sliding_lens_test.dart`, `test/app/design/glass_tab_bar_test.dart`

**Interfaces:**
- Consumes: `ShellDestination` (Task 1), `AppGlass`, `GlassInner`, `GlassScope`, `AppIcon`, `AppText`, `Pressable`, `MotionScope`, `AppMotion.snappy`.
- Produces:
  - `class SlidingLens extends StatefulWidget { const SlidingLens({required Rect target, required Axis axis, required AppleGlassShape shape, Key? key}); }` — paints a `GlassInner` at `target` (in its parent `Stack`'s coordinates). When `target` changes it animates from the rect it currently paints to the new one with `AppMotion.snappy` (a `SpringSimulation` on a 0→1 progress), stretching the length along [axis] by `1 + 0.12 * sin(pi * progress.clamp(0, 1))` (≤ 12 %, centred on the interpolated rect). Reduce Motion: jumps. Interruptions start from the painted rect.
  - `class GlassTabBar extends StatelessWidget { const GlassTabBar({required List<ShellDestination> destinations, required int selectedIndex, required ValueChanged<int> onSelected, required VoidCallback onSearch, Key? key}); }` — must be built inside a chrome `GlassScope` (the shell's). Keys: `ValueKey('tab-bar')` on the capsule, `ValueKey('tab-${section.name}')` on each tab, `ValueKey('tab-search')` on the circle, `ValueKey('tab-lens')` on the lens.

- [ ] **Step 1: Write the failing tests**

`test/app/design/sliding_lens_test.dart`:
```dart
import 'dart:math' as math;

import 'package:borj/app/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';

Widget _lens(Rect target, {bool reduceMotion = false}) => glassTestApp(
  reduceMotion: reduceMotion,
  SizedBox(
    width: 400,
    height: 100,
    child: Stack(
      children: [
        SlidingLens(
          key: const ValueKey('lens'),
          target: target,
          axis: Axis.horizontal,
          shape: const AppleGlassShape.capsule(),
        ),
      ],
    ),
  ),
);

void main() {
  const a = Rect.fromLTWH(0, 4, 100, 54);
  const b = Rect.fromLTWH(200, 4, 100, 54);
  final lens = find.byKey(const ValueKey('lens'));
  Rect painted(WidgetTester tester) =>
      tester.getRect(find.descendant(of: lens, matching: find.byType(GlassInner)));

  testWidgets('sits on its target', (tester) async {
    await tester.pumpWidget(_lens(a));
    expect(painted(tester).size, a.size);
  });

  testWidgets('slides to a new target, stretching at most 12 % mid-way', (
    tester,
  ) async {
    await tester.pumpWidget(_lens(a));
    final origin = painted(tester).topLeft;
    await tester.pumpWidget(_lens(b));
    var maxWidth = 0.0;
    var sawMiddle = false;
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      final r = painted(tester);
      maxWidth = math.max(maxWidth, r.width);
      if (r.left > origin.dx + 40 && r.left < origin.dx + 160) sawMiddle = true;
    }
    expect(sawMiddle, isTrue, reason: 'the lens must travel, not jump');
    expect(maxWidth, greaterThan(100.5));
    expect(maxWidth, lessThanOrEqualTo(112.0 + 0.01));
    await tester.pumpAndSettle();
    expect(painted(tester).width, closeTo(100, 0.01));
    expect(painted(tester).left - origin.dx, closeTo(200, 0.01));
  });

  testWidgets('reduce motion: jumps', (tester) async {
    await tester.pumpWidget(_lens(a, reduceMotion: true));
    final origin = painted(tester).topLeft;
    await tester.pumpWidget(_lens(b, reduceMotion: true));
    await tester.pump();
    expect(painted(tester).left - origin.dx, closeTo(200, 0.01));
    expect(painted(tester).width, closeTo(100, 0.01));
  });

  testWidgets('interrupted mid-way continues from the painted rect', (
    tester,
  ) async {
    await tester.pumpWidget(_lens(a));
    await tester.pumpWidget(_lens(b));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final before = painted(tester);
    await tester.pumpWidget(_lens(a));
    await tester.pump(const Duration(milliseconds: 16));
    final after = painted(tester);
    expect((after.center.dx - before.center.dx).abs(), lessThan(30));
  });
}
```

`test/app/design/glass_tab_bar_test.dart`:
```dart
import 'package:borj/app/design/design.dart';
import 'package:borj/app/shell/shell_destinations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';
import '../../support/reduced_motion_expectations.dart';

Widget _bar({
  int selected = 0,
  ValueChanged<int>? onSelected,
  VoidCallback? onSearch,
  Brightness brightness = Brightness.light,
  double textScale = 1.0,
  bool reduceMotion = false,
}) => glassTestApp(
  brightness: brightness,
  textScale: textScale,
  reduceMotion: reduceMotion,
  SizedBox(
    width: 390,
    child: GlassScope(
      kind: GlassLayerKind.chrome,
      child: GlassTabBar(
        destinations: shellDestinations,
        selectedIndex: selected,
        onSelected: onSelected ?? (_) {},
        onSearch: onSearch ?? () {},
      ),
    ),
  ),
);

void main() {
  for (final v in glassTestVariants) {
    testWidgets('renders without overflow (${v.name})', (tester) async {
      await tester.pumpWidget(_bar(brightness: v.brightness, textScale: v.textScale));
      expect(tester.takeException(), isNull);
      expect(find.text('امروز'), findsOneWidget);
      expect(find.text('کارها'), findsOneWidget);
      expect(find.text('مالی'), findsOneWidget);
    });
  }

  testWidgets('board geometry: capsule 62 tall, search circle 62', (tester) async {
    await tester.pumpWidget(_bar());
    expect(tester.getSize(find.byKey(const ValueKey('tab-bar'))).height, 62);
    expect(tester.getSize(find.byKey(const ValueKey('tab-search'))), const Size(62, 62));
  });

  testWidgets('RTL: امروز is right-most, search circle on the left', (tester) async {
    await tester.pumpWidget(_bar());
    final today = tester.getCenter(find.byKey(const ValueKey('tab-today')));
    final finance = tester.getCenter(find.byKey(const ValueKey('tab-finance')));
    final search = tester.getCenter(find.byKey(const ValueKey('tab-search')));
    expect(today.dx, greaterThan(finance.dx));
    expect(search.dx, lessThan(finance.dx));
  });

  testWidgets('tapping a tab reports its index; search reports', (tester) async {
    int? picked;
    var searched = false;
    await tester.pumpWidget(_bar(onSelected: (i) => picked = i, onSearch: () => searched = true));
    await tester.tap(find.byKey(const ValueKey('tab-finance')));
    expect(picked, 2);
    await tester.tap(find.byKey(const ValueKey('tab-search')));
    expect(searched, isTrue);
  });

  testWidgets('selected tab semantics and 44 pt targets', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_bar(selected: 1));
    expect(
      tester.getSemantics(find.byKey(const ValueKey('tab-tasks'))),
      matchesSemantics(label: 'کارها', isButton: true, isSelected: true, hasTapAction: true, isFocusable: true, hasFocusAction: true),
    );
    for (final s in ShellSection.values) {
      final size = tester.getSize(find.byKey(ValueKey('tab-${s.name}')));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    }
    handle.dispose();
  });

  testWidgets('the lens is flat GlassInner, never glass on glass', (tester) async {
    await tester.pumpWidget(_bar());
    expect(
      find.descendant(of: find.byKey(const ValueKey('tab-lens')), matching: find.byType(GlassInner)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byKey(const ValueKey('tab-lens')), matching: find.byType(AppGlass)),
      findsNothing,
    );
  });

  testWidgets('reduce motion: switching tabs moves nothing', (tester) async {
    await tester.pumpWidget(_bar(reduceMotion: true));
    await expectNoMovement(
      tester,
      within: find.byKey(const ValueKey('tab-bar')),
      trigger: () async => tester.pumpWidget(_bar(selected: 2, reduceMotion: true)),
    );
  });
}
```
The `matchesSemantics` flags above follow the Global Constraint on this Flutter version: keep `label`, `isButton` and `isSelected`; add or drop only the focus flags the widget really has.

- [ ] **Step 2: Run** `flutter test test/app/design/sliding_lens_test.dart test/app/design/glass_tab_bar_test.dart`. Expected: FAIL (missing).

- [ ] **Step 3: Implement**

`lib/app/design/patterns/sliding_lens.dart`:
```dart
import 'dart:math' as math;

import 'package:borj/app/apple_visual/glass.dart';
import 'package:borj/app/theme/app_motion.dart';
import 'package:borj/app/theme/motion_scope.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

/// A flat `GlassInner` pill that marks the selected item and slides between
/// targets with `AppMotion.snappy`, stretching ≤ 12 % along [axis] mid-way
/// (motion spec §3, tab switch). Reduce Motion: it jumps. Must be a child of
/// a `Stack`.
class SlidingLens extends StatefulWidget {
  const SlidingLens({
    required this.target,
    required this.axis,
    required this.shape,
    super.key,
  });

  final Rect target;
  final Axis axis;
  final AppleGlassShape shape;

  @override
  State<SlidingLens> createState() => _SlidingLensState();
}

class _SlidingLensState extends State<SlidingLens>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController.unbounded(
    vsync: this,
    value: 1,
  )..addListener(() => setState(() {}));
  late Rect _from = widget.target;
  late Rect _to = widget.target;

  Rect get _painted {
    final p = _progress.value;
    final base = Rect.lerp(_from, _to, p)!;
    final stretch = 1 + 0.12 * math.sin(math.pi * p.clamp(0.0, 1.0));
    return widget.axis == Axis.horizontal
        ? Rect.fromCenter(
            center: base.center,
            width: base.width * stretch,
            height: base.height,
          )
        : Rect.fromCenter(
            center: base.center,
            width: base.width,
            height: base.height * stretch,
          );
  }

  @override
  void didUpdateWidget(SlidingLens oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.target == _to) return;
    if (MotionScope.reducedOf(context)) {
      _progress.stop();
      _from = _to = widget.target;
      _progress.value = 1;
      return;
    }
    // Start from what is painted now, without the stretch.
    _from = Rect.lerp(_from, _to, _progress.value)!;
    _to = widget.target;
    _progress
      ..value = 0
      ..animateWith(SpringSimulation(AppMotion.snappy.description, 0, 1, 0));
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = _painted;
    return Positioned.fromRect(
      rect: r,
      child: IgnorePointer(child: GlassInner(shape: widget.shape, child: const SizedBox.expand())),
    );
  }
}
```
`Positioned.fromRect` is in absolute (left/top) coordinates, which is right for a lens because callers compute targets from the laid-out geometry (Task 2 tab bar, Task 3 sidebar). The test above reads `getRect` and works in either direction.

`lib/app/design/patterns/glass_tab_bar.dart`:
```dart
import 'package:borj/app/apple_visual/glass.dart';
import 'package:borj/app/design/app_icon.dart';
import 'package:borj/app/design/app_text.dart';
import 'package:borj/app/design/patterns/sliding_lens.dart';
import 'package:borj/app/design/pressable.dart';
import 'package:borj/app/shell/shell_destinations.dart';
import 'package:flutter/material.dart';

/// The phone's floating tab bar (boards `Main`, `PhoneTasks`, `PhoneMoney`):
/// a glass capsule 62 tall with one item per destination and a flat lens on
/// the selected one, plus a 62 pt glass search circle on its leading side
/// (left in RTL). Build it inside the shell's chrome `GlassScope`.
class GlassTabBar extends StatelessWidget {
  const GlassTabBar({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.onSearch,
    super.key,
  });

  final List<ShellDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onSearch;

  static const double height = 62;
  static const double _padding = 4;
  static const double _gap = 10;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Row(
      children: [
        Expanded(
          child: AppGlass(
            key: const ValueKey('tab-bar'),
            role: GlassRole.chrome,
            child: SizedBox(
              height: height,
              child: Padding(
                padding: const EdgeInsets.all(_padding),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = constraints.maxWidth / destinations.length;
                    final logical = isRtl
                        ? constraints.maxWidth - (selectedIndex + 1) * itemWidth
                        : selectedIndex * itemWidth;
                    return Stack(
                      children: [
                        SlidingLens(
                          key: const ValueKey('tab-lens'),
                          target: Rect.fromLTWH(logical, 0, itemWidth, height - 2 * _padding),
                          axis: Axis.horizontal,
                          shape: const AppleGlassShape.capsule(),
                        ),
                        Row(
                          children: [
                            for (var i = 0; i < destinations.length; i++)
                              Expanded(child: _Tab(destination: destinations[i], selected: i == selectedIndex, onTap: () => onSelected(i))),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: _gap),
        SizedBox(
          key: const ValueKey('tab-search'),
          width: height,
          height: height,
          child: Pressable(
            onPressed: onSearch,
            semanticLabel: 'جست‌وجو',
            dimsGlass: true,
            child: const AppGlass(
              role: GlassRole.chrome,
              shape: AppleGlassShape.circle(),
              child: Center(child: AppIcon(Icons.search, size: 24)),
            ),
          ),
        ),
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.destination, required this.selected, required this.onTap});

  final ShellDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tone = selected ? AppTextTone.link : AppTextTone.primary;
    return Semantics(
      selected: selected,
      child: Pressable(
        key: ValueKey('tab-${destination.section.name}'),
        onPressed: onTap,
        semanticLabel: destination.label,
        child: SizedBox(
          height: GlassTabBar.height - 8,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(destination.icon, size: 24, tone: tone),
              const SizedBox(height: 1),
              AppText(destination.label, role: AppTextRole.caption2, tone: tone, weight: FontWeight.w800, maxLines: 1),
            ],
          ),
        ),
      ),
    );
  }
}
```
Check `Pressable`'s constructor in `lib/app/design/pressable.dart` before using it: use its real parameter names (`onPressed`, `semanticLabel`, `dimsGlass`, `child`). If `Pressable` already exposes a `selected` semantics flag, use it instead of the outer `Semantics(selected:)`. `AppText`'s `weight` parameter exists (`app_text.dart`). The lens target is computed in absolute left coordinates (`logical`) so the RTL order puts index 0 on the right.

Add to `design.dart`: `export 'patterns/glass_tab_bar.dart';` and `export 'patterns/sliding_lens.dart';`.

- [ ] **Step 4: Run** the two test files. Expected: PASS. `flutter analyze`.
- [ ] **Step 5: Commit** `feat(design): sliding lens and glass tab bar`.

---

### Task 3: GlassSidebar (expanded) and rail (medium)

**Files:**
- Create: `lib/app/design/patterns/glass_sidebar.dart`
- Modify: `lib/app/design/design.dart`
- Test: `test/app/design/glass_sidebar_test.dart`

**Interfaces:**
- Consumes: `SidebarGroup`, `SidebarItem` (Task 1), `AppGlass`, `GlassInner`, `AppText`, `AppIcon`, `Pressable`.
- Produces: `class GlassSidebar extends StatelessWidget { const GlassSidebar({required List<SidebarGroup> groups, required String selectedLocation, required ValueChanged<SidebarItem> onSelected, required VoidCallback onSettings, bool rail = false, String? statusLine, Key? key}); static const double width = 236; static const double railWidth = 72; }`. Build it inside the shell's chrome `GlassScope`. Keys: `ValueKey('sidebar')` on the glass, `ValueKey('sidebar-item-${item.location}')` on each item, `ValueKey('sidebar-settings')` on the settings row. The selected item is the one whose `location` equals `selectedLocation`; if none equals it, the first item whose location is a path prefix of `selectedLocation` (ignoring the query) and whose section matches wins (so `/finance/debts/42` selects قسط و بدهی and `/tasks?view=board` selects همهٔ کارها).

- [ ] **Step 1: Write the failing test** `test/app/design/glass_sidebar_test.dart`:
```dart
import 'package:borj/app/design/design.dart';
import 'package:borj/app/shell/shell_destinations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';

Widget _sidebar({
  String selected = '/',
  bool rail = false,
  ValueChanged<SidebarItem>? onSelected,
  VoidCallback? onSettings,
  Brightness brightness = Brightness.light,
  double textScale = 1.0,
}) => glassTestApp(
  brightness: brightness,
  textScale: textScale,
  SizedBox(
    height: 800,
    child: GlassScope(
      kind: GlassLayerKind.chrome,
      child: GlassSidebar(
        groups: sidebarGroups(),
        selectedLocation: selected,
        rail: rail,
        onSelected: onSelected ?? (_) {},
        onSettings: onSettings ?? () {},
      ),
    ),
  ),
);

Finder _innerOf(String location) => find.descendant(
  of: find.byKey(ValueKey('sidebar-item-$location')),
  matching: find.byType(GlassInner),
);

void main() {
  for (final v in glassTestVariants) {
    for (final rail in [false, true]) {
      testWidgets('renders (${v.name}, rail=$rail)', (tester) async {
        await tester.pumpWidget(_sidebar(rail: rail, brightness: v.brightness, textScale: v.textScale));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('board geometry: width 236, items 36 tall', (tester) async {
    await tester.pumpWidget(_sidebar());
    expect(tester.getSize(find.byKey(const ValueKey('sidebar'))).width, 236);
    expect(tester.getSize(find.byKey(const ValueKey('sidebar-item-/'))).height, 36);
    expect(find.text('برنامه'), findsOneWidget);
    expect(find.text('پول'), findsOneWidget);
    expect(find.text('زندگی'), findsNothing);
    expect(find.text('بودجه'), findsNothing);
  });

  testWidgets('selection by location, prefix and query', (tester) async {
    await tester.pumpWidget(_sidebar(selected: '/finance/debts/42'));
    expect(_innerOf('/finance/debts'), findsOneWidget);
    expect(_innerOf('/'), findsNothing);
    await tester.pumpWidget(_sidebar(selected: '/tasks?view=board'));
    expect(_innerOf('/tasks'), findsOneWidget);
    await tester.pumpWidget(_sidebar(selected: '/tasks?view=calendar'));
    expect(_innerOf('/tasks?view=calendar'), findsOneWidget);
    expect(_innerOf('/tasks'), findsNothing);
  });

  testWidgets('tap reports the item; settings row at the bottom', (tester) async {
    SidebarItem? picked;
    var settings = false;
    await tester.pumpWidget(_sidebar(onSelected: (i) => picked = i, onSettings: () => settings = true));
    await tester.tap(find.byKey(const ValueKey('sidebar-item-/finance/transactions')));
    expect(picked?.label, 'تراکنش‌ها');
    final settingsRow = find.byKey(const ValueKey('sidebar-settings'));
    expect(tester.getBottomLeft(settingsRow).dy, greaterThan(700));
    await tester.tap(settingsRow);
    expect(settings, isTrue);
    expect(find.text('تنظیمات'), findsOneWidget);
  });

  testWidgets('rail: 72 wide, icons only with tooltips', (tester) async {
    await tester.pumpWidget(_sidebar(rail: true));
    expect(tester.getSize(find.byKey(const ValueKey('sidebar'))).width, 72);
    expect(find.text('تراکنش‌ها'), findsNothing);
    expect(find.byTooltip('تراکنش‌ها'), findsOneWidget);
    expect(find.byTooltip('تنظیمات'), findsOneWidget);
  });

  testWidgets('RTL: labels right-aligned in the panel', (tester) async {
    await tester.pumpWidget(_sidebar());
    final item = tester.getRect(find.byKey(const ValueKey('sidebar-item-/')));
    final label = tester.getRect(find.text('امروز'));
    expect(label.right, greaterThan(item.center.dx));
  });
}
```

- [ ] **Step 2: Run** it. Expected: FAIL.

- [ ] **Step 3: Implement** `lib/app/design/patterns/glass_sidebar.dart`:
```dart
import 'package:borj/app/apple_visual/glass.dart';
import 'package:borj/app/design/app_icon.dart';
import 'package:borj/app/design/app_text.dart';
import 'package:borj/app/design/pressable.dart';
import 'package:borj/app/shell/shell_destinations.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// The desktop sidebar of the `MacToday` board (glass panel on the right in
/// RTL, flat `GlassInner` on the selected row) or, with [rail], the medium
/// window's 72 pt icon rail. Build it inside the shell's chrome `GlassScope`.
/// Selection jumps (macOS convention).
class GlassSidebar extends StatelessWidget {
  const GlassSidebar({
    required this.groups,
    required this.selectedLocation,
    required this.onSelected,
    required this.onSettings,
    this.rail = false,
    this.statusLine,
    super.key,
  });

  final List<SidebarGroup> groups;
  final String selectedLocation;
  final ValueChanged<SidebarItem> onSelected;
  final VoidCallback onSettings;
  final bool rail;
  final String? statusLine;

  static const double width = 236;
  static const double railWidth = 72;

  SidebarItem? _selected() {
    final items = [for (final g in groups) ...g.items];
    for (final i in items) {
      if (i.location == selectedLocation) return i;
    }
    final path = Uri.parse(selectedLocation).path;
    SidebarItem? best;
    for (final i in items) {
      final p = Uri.parse(i.location);
      if (p.hasQuery) continue;
      final matches = p.path == '/' ? path == '/' : path == p.path || path.startsWith('${p.path}/');
      if (matches && (best == null || p.path.length > Uri.parse(best.location).path.length)) best = i;
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected();
    final rows = <Widget>[];
    for (final g in groups) {
      if (!rail) {
        rows.add(Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 10, 4),
          child: AppText(g.label, role: AppTextRole.caption, tone: AppTextTone.secondary, weight: FontWeight.w700),
        ));
      } else if (rows.isNotEmpty) {
        rows.add(const SizedBox(height: AppSpacing.s12));
      }
      for (final item in g.items) {
        rows.add(_Row(
          key: ValueKey('sidebar-item-${item.location}'),
          label: item.label,
          icon: item.icon,
          selected: identical(item, selected),
          rail: rail,
          onTap: () => onSelected(item),
        ));
        rows.add(const SizedBox(height: 2));
      }
    }
    return AppGlass(
      key: const ValueKey('sidebar'),
      role: GlassRole.chrome,
      shape: const AppleGlassShape.rounded(20),
      child: SizedBox(
        width: rail ? railWidth : width,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...rows,
              const Spacer(),
              _Row(
                key: const ValueKey('sidebar-settings'),
                label: 'تنظیمات',
                icon: Icons.settings_outlined,
                selected: Uri.parse(selectedLocation).path == '/settings',
                rail: rail,
                onTap: onSettings,
              ),
              if (!rail && statusLine != null)
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(10, 18, 10, 2),
                  child: AppText(statusLine!, role: AppTextRole.caption, tone: AppTextTone.secondary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.icon, required this.selected, required this.rail, required this.onTap, super.key});

  final String label;
  final IconData icon;
  final bool selected;
  final bool rail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final content = SizedBox(
      height: 36,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: rail
            ? Center(child: AppIcon(icon, size: 20))
            : Row(children: [
                AppIcon(icon, size: 18),
                const SizedBox(width: 10),
                Expanded(child: AppText(label, role: AppTextRole.subheadline, weight: FontWeight.w700, maxLines: 1)),
              ]),
      ),
    );
    final row = Semantics(
      selected: selected,
      child: Pressable(
        onPressed: onTap,
        semanticLabel: label,
        child: selected ? GlassInner(shape: const AppleGlassShape.rounded(12), child: content) : content,
      ),
    );
    return rail ? Tooltip(message: label, child: row) : row;
  }
}
```
Item rows must keep a 44 pt hit target: `Pressable` already enforces its minimum (check its constraints); if the 36 pt row is shorter than its hit box, the 2 pt gap still leaves the rows' hit boxes non-overlapping only if `Pressable` grows the hit area outward — verify with a tap test at the row edge and, if needed, wrap the row in a 38 pt `SizedBox` whose taps reach the `Pressable` (document what you did in the report).

Add `export 'patterns/glass_sidebar.dart';` to `design.dart`.

- [ ] **Step 4: Run** the test. Expected: PASS. `flutter analyze`.
- [ ] **Step 5: Commit** `feat(design): glass sidebar and rail`.

---

### Task 4: ShellToolbar, LargeTitleHeader and EmptyState

**Files:**
- Create: `lib/app/design/patterns/shell_toolbar.dart`, `lib/app/design/patterns/large_title_header.dart`, `lib/app/design/patterns/empty_state.dart`
- Modify: `lib/app/design/design.dart`
- Test: `test/app/design/shell_toolbar_test.dart`, `test/app/design/large_title_header_test.dart`, `test/app/design/empty_state_test.dart`

**Interfaces:**
- Consumes: `GlassButton` (`onPressed`, `icon`, `label`, `variant`, `shape`, `semanticLabel`), `AppText`, `AppIcon`, `GlassVisibility`, `MotionScope`, `AppMotion.quick`, `AppMotion.reduced`.
- Produces:
  - `final class ShellAction { const ShellAction({required this.icon, required this.label, required this.onPressed, this.primary = false, this.leading = false}); final IconData icon; final String label; final void Function(BuildContext context) onPressed; final bool primary; final bool leading; }` — `primary` = tinted; `leading` = sits at the leading end (right in RTL) of the phone toolbar row, otherwise at the trailing end.
  - `class ShellToolbar extends StatelessWidget { const ShellToolbar({required List<ShellAction> actions, required double buttonSize, Key? key}); }` — a row of circle `GlassButton`s, leading group then a `Spacer` then trailing group. Build inside the chrome scope. Keys `ValueKey('toolbar-${action.label}')`.
  - `class LargeTitleHeader extends StatelessWidget { const LargeTitleHeader({required String title, String? subtitle, VoidCallback? onTitleLongPress, Key? key}); }` — subtitle 15 pt w600 above a 34 pt w900 title (board `Main`), padding `14 20 0` on compact, the `largeTitle` role. No glass. `onTitleLongPress` wraps the title in a `GestureDetector`.
  - `class EmptyState extends StatefulWidget { const EmptyState({required IconData icon, required String title, String? message, String? actionLabel, VoidCallback? onAction, Key? key}); }` — centred icon, title, message and an optional tinted `GlassButton`. Appears with a `quick` fade: the non-glass parts through an `Opacity` driven by the animation, the button through `GlassVisibility` (never an `Opacity` above glass). Reduce Motion: fades over `AppMotion.reduced`.

- [ ] **Step 1: Write the failing tests**

`test/app/design/shell_toolbar_test.dart`:
```dart
import 'package:borj/app/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';

void main() {
  final calls = <String>[];
  List<ShellAction> actions() => [
    ShellAction(icon: Icons.calendar_month_outlined, label: 'تقویم', leading: true, onPressed: (_) => calls.add('cal')),
    ShellAction(icon: Icons.settings_outlined, label: 'تنظیمات', leading: true, onPressed: (_) => calls.add('set')),
    ShellAction(icon: Icons.add, label: 'ورود سریع', primary: true, onPressed: (_) => calls.add('add')),
  ];
  Widget bar({Brightness b = Brightness.light, double s = 1.0}) => glassTestApp(
    brightness: b,
    textScale: s,
    SizedBox(width: 358, child: GlassScope(kind: GlassLayerKind.chrome, child: ShellToolbar(actions: actions(), buttonSize: 44))),
  );

  for (final v in glassTestVariants) {
    testWidgets('renders (${v.name})', (tester) async {
      await tester.pumpWidget(bar(b: v.brightness, s: v.textScale));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('leading group on the right in RTL, primary on the left', (tester) async {
    await tester.pumpWidget(bar());
    final cal = tester.getCenter(find.byKey(const ValueKey('toolbar-تقویم')));
    final set = tester.getCenter(find.byKey(const ValueKey('toolbar-تنظیمات')));
    final add = tester.getCenter(find.byKey(const ValueKey('toolbar-ورود سریع')));
    expect(cal.dx, greaterThan(set.dx));
    expect(set.dx, greaterThan(add.dx));
    expect(tester.getSize(find.byKey(const ValueKey('toolbar-تقویم'))), const Size(44, 44));
  });

  testWidgets('taps call the action with a context; labels are semantic', (tester) async {
    calls.clear();
    await tester.pumpWidget(bar());
    await tester.tap(find.byKey(const ValueKey('toolbar-ورود سریع')));
    await tester.tap(find.byKey(const ValueKey('toolbar-تنظیمات')));
    expect(calls, ['add', 'set']);
    expect(find.bySemanticsLabel('تقویم'), findsOneWidget);
  });
}
```

`test/app/design/large_title_header_test.dart`:
```dart
import 'package:borj/app/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';

void main() {
  for (final v in glassTestVariants) {
    testWidgets('title under subtitle (${v.name})', (tester) async {
      await tester.pumpWidget(glassTestApp(
        brightness: v.brightness,
        textScale: v.textScale,
        const SizedBox(width: 390, child: LargeTitleHeader(title: 'امروز', subtitle: 'چهارشنبه ۱۳ آبان')),
      ));
      expect(tester.takeException(), isNull);
      expect(tester.getTopLeft(find.text('امروز')).dy, greaterThan(tester.getTopLeft(find.text('چهارشنبه ۱۳ آبان')).dy));
      expect(find.byType(AppGlass), findsNothing);
    });
  }

  testWidgets('long-press on the title', (tester) async {
    var pressed = false;
    await tester.pumpWidget(glassTestApp(LargeTitleHeader(title: 'امروز', onTitleLongPress: () => pressed = true)));
    await tester.longPress(find.text('امروز'));
    expect(pressed, isTrue);
  });
}
```

`test/app/design/empty_state_test.dart`:
```dart
import 'package:borj/app/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_fade_expectations.dart';
import '../../support/glass_test_app.dart';

void main() {
  Widget state({bool reduce = false, VoidCallback? onAction, Brightness b = Brightness.light, double s = 1.0}) => glassTestApp(
    reduceMotion: reduce,
    brightness: b,
    textScale: s,
    EmptyState(icon: Icons.inbox_outlined, title: 'هنوز چیزی نیست', message: 'به‌زودی', actionLabel: 'افزودن', onAction: onAction ?? () {}),
  );

  for (final v in glassTestVariants) {
    testWidgets('renders (${v.name})', (tester) async {
      await tester.pumpWidget(state(b: v.brightness, s: v.textScale));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('هنوز چیزی نیست'), findsOneWidget);
    });
  }

  testWidgets('fades in with quick; the button fades through GlassVisibility', (tester) async {
    await tester.pumpWidget(state());
    await tester.pump(const Duration(milliseconds: 100));
    final vis = tester.widget<GlassVisibility>(find.ancestor(of: find.byType(GlassButton), matching: find.byType(GlassVisibility)).first);
    expect(vis.value, inExclusiveRange(0.0, 1.0));
    expect(bareFadesAboveGlass(tester), isEmpty);
    await tester.pumpAndSettle();
    expect(tester.widget<GlassVisibility>(find.ancestor(of: find.byType(GlassButton), matching: find.byType(GlassVisibility)).first).value, 1.0);
  });

  testWidgets('action', (tester) async {
    var tapped = false;
    await tester.pumpWidget(state(onAction: () => tapped = true));
    await tester.pumpAndSettle();
    await tester.tap(find.text('افزودن'));
    expect(tapped, isTrue);
  });
}
```
Read `test/support/glass_fade_expectations.dart` (added in Phase 1) for the exact name and signature of `bareFadesAboveGlass`; use its real signature. `GlassVisibility`'s value field: read its class in `apple_liquid_glass.dart` and use the real field name.

- [ ] **Step 2: Run** the three files. Expected: FAIL.

- [ ] **Step 3: Implement**

`lib/app/design/patterns/shell_toolbar.dart`:
```dart
import 'package:borj/app/apple_visual/glass.dart';
import 'package:borj/app/design/app_icon.dart';
import 'package:borj/app/design/glass_button.dart';
import 'package:flutter/material.dart';

/// One toolbar action a screen hands to the shell (the shell renders it in its
/// chrome scope; screens never paint chrome).
final class ShellAction {
  const ShellAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.leading = false,
  });

  final IconData icon;
  final String label;
  final void Function(BuildContext context) onPressed;

  /// The tinted primary action (one per screen).
  final bool primary;

  /// Sits at the leading end (right in RTL); others at the trailing end.
  final bool leading;
}

/// A row of glass circle buttons: leading actions, a gap, trailing actions.
class ShellToolbar extends StatelessWidget {
  const ShellToolbar({required this.actions, required this.buttonSize, super.key});

  final List<ShellAction> actions;
  final double buttonSize;

  Widget _button(BuildContext context, ShellAction a) => SizedBox(
    key: ValueKey('toolbar-${a.label}'),
    width: buttonSize,
    height: buttonSize,
    child: GlassButton(
      onPressed: () => a.onPressed(context),
      icon: a.icon,
      semanticLabel: a.label,
      variant: a.primary ? GlassButtonVariant.tinted : GlassButtonVariant.chrome,
      shape: const AppleGlassShape.circle(),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final leading = [for (final a in actions) if (a.leading) a];
    final trailing = [for (final a in actions) if (!a.leading) a];
    List<Widget> spaced(List<ShellAction> list) => [
      for (var i = 0; i < list.length; i++) ...[
        if (i > 0) const SizedBox(width: 8),
        _button(context, list[i]),
      ],
    ];
    return Row(children: [...spaced(leading), const Spacer(), ...spaced(trailing)]);
  }
}
```
`AppIcon` is not needed here if `GlassButton` takes `icon` as `IconData`; check `glass_button.dart` (it has `final IconData? icon`) and drop the unused import. The `GlassButton` circle must render exactly `buttonSize`: its minimum is 44, so on desktop (36) the shell gives `ShellToolbar` a 36 size only if `GlassButton` allows smaller constraints — read `glass_button.dart:54` (`BoxConstraints(minWidth: 44, minHeight: 44)`). If it does not allow 36, desktop toolbar buttons stay 44 visually-36: add a `compact` flag to `GlassButton` ONLY if needed, with a test, and report it; otherwise use 44 on desktop too and note the deviation from the board's 36 in your report (the controller rules).

`lib/app/design/patterns/large_title_header.dart`:
```dart
import 'package:borj/app/design/app_text.dart';
import 'package:flutter/material.dart';

/// The large title block of the phone boards: a date line, then the 34 pt
/// title. Not glass.
class LargeTitleHeader extends StatelessWidget {
  const LargeTitleHeader({required this.title, this.subtitle, this.onTitleLongPress, super.key});

  final String title;
  final String? subtitle;
  final VoidCallback? onTitleLongPress;

  @override
  Widget build(BuildContext context) {
    Widget titleText = AppText(title, role: AppTextRole.largeTitle, weight: FontWeight.w900);
    if (onTitleLongPress != null) {
      titleText = GestureDetector(onLongPress: onTitleLongPress, child: titleText);
    }
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (subtitle != null) AppText(subtitle!, role: AppTextRole.subheadline, weight: FontWeight.w600),
          titleText,
        ],
      ),
    );
  }
}
```

`lib/app/design/patterns/empty_state.dart`:
```dart
import 'package:borj/app/apple_visual/glass.dart';
import 'package:borj/app/design/app_icon.dart';
import 'package:borj/app/design/app_text.dart';
import 'package:borj/app/design/glass_button.dart';
import 'package:borj/app/theme/app_motion.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:borj/app/theme/motion_scope.dart';
import 'package:flutter/material.dart';

/// A calm empty state: icon, title, message, optional primary action. It
/// appears with a `quick` fade; the glass button fades through
/// [GlassVisibility], the flat parts through [Opacity].
class EmptyState extends StatefulWidget {
  const EmptyState({required this.icon, required this.title, this.message, this.actionLabel, this.onAction, super.key});

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState> with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(vsync: this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_fade.value == 0 && !_fade.isAnimating) {
      final m = MotionScope.reducedOf(context) ? AppMotion.reduced : AppMotion.quick;
      _fade.animateTo(1, duration: m.duration, curve: m.curve);
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fade,
      builder: (context, _) {
        final t = _fade.value.clamp(0.0, 1.0);
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: t,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  AppIcon(widget.icon, size: 40, tone: AppTextTone.secondary),
                  const SizedBox(height: AppSpacing.s12),
                  AppText(widget.title, role: AppTextRole.headline, textAlign: TextAlign.center),
                  if (widget.message != null) ...[
                    const SizedBox(height: AppSpacing.s4),
                    AppText(widget.message!, role: AppTextRole.subheadline, tone: AppTextTone.secondary, textAlign: TextAlign.center),
                  ],
                ]),
              ),
              if (widget.actionLabel != null && widget.onAction != null) ...[
                const SizedBox(height: AppSpacing.s16),
                GlassVisibility(
                  value: t,
                  child: GlassButton(onPressed: widget.onAction, label: widget.actionLabel, variant: GlassButtonVariant.tinted),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
```
`GlassVisibility`'s constructor parameter name: read it in `apple_liquid_glass.dart` (Phase 1 uses `GlassVisibility(value: …, child: …)`). `AppMotion.reduced` and `AppMotion.quick` are `AppCurveMotion` with `.duration` and `.curve`.

Add the three exports to `design.dart`.

- [ ] **Step 4: Run** the three test files. Expected: PASS. `flutter analyze`.
- [ ] **Step 5: Commit** `feat(design): shell toolbar, large title header, empty state`.

---

### Task 5: GlassPushPage and GlassInspector

**Files:**
- Create: `lib/app/design/patterns/glass_push_page.dart`, `lib/app/design/patterns/glass_inspector.dart`
- Modify: `lib/app/design/design.dart`
- Test: `test/app/design/glass_push_page_test.dart`, `test/app/design/glass_inspector_test.dart`

**Interfaces:**
- Consumes: `WindowClass` (Task 1), `MotionScope`, `AppMotion.standard`, `AppMotion.reduced`, `AppMotion.exitFactor`, `SpringCurve`, `AppTheme.of(context).colors.scrim`, `GlassScope`, `AppGlass`, `GlassVisibility`, `AppBackground`.
- Produces:
  - `class GlassPushPage<T> extends Page<T> { const GlassPushPage({required Widget child, LocalKey? key, String? name, Object? arguments, String? restorationId}); }` — `createRoute` returns a `PageRoute<T>` that:
    - on compact (`WindowClass.of(context) == compact`) and without Reduce Motion: uses `CupertinoRouteTransitionMixin` transitions (direction-aware slide, parallax of the outgoing page, back gesture from the leading-side edge — right in RTL), and draws `colors.scrim` over this route's page with alpha `secondaryAnimation.value` while another route covers it;
    - on medium/expanded or with Reduce Motion: no transition (`Duration.zero`), and the back gesture is disabled;
    - paints `AppBackground(kind: AppBackgroundKind.phone)` behind its child (pages are opaque).
    Read `WindowClass` and Reduce Motion from the navigator's context at push time (`navigator!.context`) for `transitionDuration` / `reverseTransitionDuration`, and from the build context inside `buildTransitions`.
  - `class GlassInspector extends StatefulWidget { const GlassInspector({required bool open, required Widget child, VoidCallback? onClose, Key? key}); static const double width = 360; }` — positioned by its parent at the leading edge. Slides in from the leading edge (left in RTL) with `SpringCurve(AppMotion.standard)` over its settle time, closes with `AppMotion.standard` over `duration × AppMotion.exitFactor` (curve `Curves.easeOut`); Reduce Motion: no translation, `GlassVisibility` 0→1 over `AppMotion.reduced` (closing uses the flipped curve as a `CurvedAnimation` `reverseCurve`, like `glass_sheet.dart`). Its glass is `GlassScope(kind: GlassLayerKind.sheet)` + `AppGlass(role: GlassRole.sheet, shape: AppleGlassShape.rounded(20))`. When closed and settled it builds nothing (no glass, no capture). Key `ValueKey('inspector')` on the glass.

- [ ] **Step 1: Write the failing tests**

`test/app/design/glass_push_page_test.dart`:
```dart
import 'package:borj/app/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/glass_fade_expectations.dart';
import '../../support/glass_test_app.dart';

GoRouter _router() => GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const Center(child: Text('home', key: ValueKey('home'))),
      routes: [
        GoRoute(
          path: 'detail',
          pageBuilder: (context, state) => GlassPushPage<void>(
            key: state.pageKey,
            child: const Center(child: Text('detail', key: ValueKey('detail'))),
          ),
        ),
      ],
    ),
  ],
);

Widget _app(GoRouter router, {double width = 390, bool reduceMotion = false}) {
  return MediaQuery(
    data: MediaQueryData(size: Size(width, 844), disableAnimations: reduceMotion),
    child: MaterialApp.router(
      routerConfig: router,
      theme: glassTestTheme(Brightness.light),
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
    ),
  );
}

void main() {
  testWidgets('compact RTL: the new page enters from the left', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = _router();
    await tester.pumpWidget(_app(router));
    router.go('/detail');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final x = tester.getCenter(find.byKey(const ValueKey('detail'))).dx;
    expect(x, lessThan(195), reason: 'mid-push the page is still left of centre');
    await tester.pumpAndSettle();
    expect(tester.getCenter(find.byKey(const ValueKey('detail'))).dx, closeTo(195, 0.5));
  });

  testWidgets('compact: the outgoing page dims with a scrim, not an opacity', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = _router();
    await tester.pumpWidget(_app(router));
    router.go('/detail');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byKey(const ValueKey('push-scrim')), findsWidgets);
    expect(bareFadesAboveGlass(tester), isEmpty);
    await tester.pumpAndSettle();
  });

  testWidgets('compact RTL: back swipe from the right edge pops', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = _router();
    await tester.pumpWidget(_app(router));
    router.go('/detail');
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(const Offset(388, 400));
    await gesture.moveBy(const Offset(-300, 0));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home')), findsOneWidget);
    expect(find.byKey(const ValueKey('detail')), findsNothing);
  });

  for (final (name, width, reduce) in [('expanded', 1440.0, false), ('medium', 800.0, false), ('compact reduced', 390.0, true)]) {
    testWidgets('$name: instant', (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final router = _router();
      await tester.pumpWidget(_app(router, width: width, reduceMotion: reduce));
      router.go('/detail');
      await tester.pump();
      await tester.pump();
      expect(tester.getCenter(find.byKey(const ValueKey('detail'))).dx, closeTo(width / 2, 0.5));
      expect(find.byKey(const ValueKey('home')), findsNothing);
    });
  }
}
```
`glassTestTheme` does not exist yet: add to `test/support/glass_test_app.dart` a small exported helper `ThemeData glassTestTheme(Brightness brightness)` returning the same `ThemeData` `glassTestApp` builds, and make `glassTestApp` use it (no behaviour change). Go_router's `go('/detail')` from `/` pushes the child page onto the same navigator, so `home` stays underneath; `find.byKey('home')` is offstage after an opaque route settles (`findsNothing` with default `skipOffstage`).

`test/app/design/glass_inspector_test.dart`:
```dart
import 'package:borj/app/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';
import '../../support/reduced_motion_expectations.dart';

Widget _host({required bool open, bool reduce = false}) => glassTestApp(
  reduceMotion: reduce,
  SizedBox(
    width: 1200,
    height: 800,
    child: Stack(children: [
      PositionedDirectional(
        end: 8, top: 8, bottom: 8, width: GlassInspector.width,
        child: GlassInspector(open: open, child: const Center(child: Text('جزئیات'))),
      ),
    ]),
  ),
);

void main() {
  testWidgets('closed builds no glass', (tester) async {
    await tester.pumpWidget(_host(open: false));
    expect(find.byKey(const ValueKey('inspector')), findsNothing);
    expect(find.byType(AppGlass), findsNothing);
  });

  testWidgets('RTL: slides in from the left edge', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_host(open: false));
    await tester.pumpWidget(_host(open: true));
    await tester.pump(const Duration(milliseconds: 48));
    final mid = tester.getRect(find.byKey(const ValueKey('inspector')));
    await tester.pumpAndSettle();
    final rest = tester.getRect(find.byKey(const ValueKey('inspector')));
    expect(mid.left, lessThan(rest.left), reason: 'comes from the left in RTL');
    expect(rest.width, GlassInspector.width);
  });

  testWidgets('closes faster than it opens and then builds nothing', (tester) async {
    await tester.pumpWidget(_host(open: true));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_host(open: false));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('inspector')), findsNothing);
  });

  testWidgets('reduce motion: no movement, visibility fades', (tester) async {
    await tester.pumpWidget(_host(open: false, reduce: true));
    await expectNoMovement(
      tester,
      within: find.byType(GlassInspector),
      trigger: () async {
        await tester.pumpWidget(_host(open: true, reduce: true));
        await tester.pump();
      },
    );
    await tester.pumpAndSettle();
    expect(find.text('جزئیات'), findsOneWidget);
  });
}
```
`PositionedDirectional(end: 8)` puts the inspector at the left in RTL (the leading edge of the window content in the board is the LEFT, which is `end` in RTL). Note the board term "leading" in the spec means the side opposite the sidebar; in RTL that is the left = `end`. The slide therefore starts further left (off the left edge) and moves right into place.

- [ ] **Step 2: Run** both files. Expected: FAIL.

- [ ] **Step 3: Implement**

`lib/app/design/patterns/glass_push_page.dart`:
```dart
import 'package:borj/app/shell/window_class.dart';
import 'package:borj/app/theme/app_background.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:borj/app/theme/motion_scope.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A pushed page: Cupertino slide and back gesture on compact (direction
/// aware), a scrim over the covered page, instant on medium/expanded and
/// under Reduce Motion (a page holds glass, so it never cross-fades).
class GlassPushPage<T> extends Page<T> {
  const GlassPushPage({required this.child, super.key, super.name, super.arguments, super.restorationId});

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) => _GlassPushRoute<T>(this);
}

class _GlassPushRoute<T> extends PageRoute<T> with CupertinoRouteTransitionMixin<T> {
  _GlassPushRoute(GlassPushPage<T> page) : super(settings: page);

  GlassPushPage<T> get _page => settings as GlassPushPage<T>;

  bool _animated(BuildContext context) =>
      WindowClass.of(context) == WindowClass.compact && !MotionScope.reducedOf(context);

  bool get _animatedNow {
    final ctx = navigator?.context;
    return ctx != null && _animated(ctx);
  }

  @override
  String? get title => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => _animatedNow ? super.transitionDuration : Duration.zero;

  @override
  Duration get reverseTransitionDuration => _animatedNow ? super.reverseTransitionDuration : Duration.zero;

  @override
  bool get popGestureEnabled => _animatedNow && super.popGestureEnabled;

  @override
  Widget buildContent(BuildContext context) => AppBackground(
    kind: AppBackgroundKind.phone,
    child: Material(type: MaterialType.transparency, child: _page.child),
  );

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    if (!_animated(context)) return child;
    final scrim = AppTheme.of(context).colors.scrim;
    // The incoming route dims what it covers: a full-screen scrim BEHIND the
    // sliding page (only the page slides), so pages built with a plain
    // `builder:` are dimmed too. The route stays opaque; Flutter keeps
    // painting the covered route until the transition completes.
    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, _) => animation.value == 0
                ? const SizedBox.shrink()
                : ColoredBox(
                    key: const ValueKey('push-scrim'),
                    color: scrim.withValues(alpha: scrim.a * animation.value),
                  ),
          ),
        ),
        super.buildTransitions(context, animation, secondaryAnimation, child),
      ],
    );
  }
}
```
`CupertinoRouteTransitionMixin` in Flutter 3.47.5: read `/home/shabin/develop/flutter-3.47.5/packages/flutter/lib/src/cupertino/route.dart` for the exact members (`buildContent`, `title`, and how the pop gesture is enabled — a `popGestureEnabled` getter or a static `isPopGestureEnabled(route)` helper). Adapt the overrides to the real API without changing the behaviour above, and report the adaptation. If the opaque route hides the covered page before the scrim test samples it, make the scrim test sample at 120 ms (mid-transition) as written; do not make the route non-opaque.

`lib/app/design/patterns/glass_inspector.dart`:
```dart
import 'package:borj/app/apple_visual/glass.dart';
import 'package:borj/app/design/patterns/spring_curve.dart';
import 'package:borj/app/theme/app_motion.dart';
import 'package:borj/app/theme/motion_scope.dart';
import 'package:flutter/material.dart';

/// The desktop inspector (`MacTasks`, `MacMoney`): a sheet-glass panel at the
/// leading edge of the content (left in RTL). Slides in with `standard`, out
/// with `standard` × exitFactor; Reduce Motion fades it through the renderer.
class GlassInspector extends StatefulWidget {
  const GlassInspector({required this.open, required this.child, this.onClose, super.key});

  final bool open;
  final Widget child;
  final VoidCallback? onClose;

  static const double width = 360;

  @override
  State<GlassInspector> createState() => _GlassInspectorState();
}

class _GlassInspectorState extends State<GlassInspector> with SingleTickerProviderStateMixin {
  static final SpringCurve _spring = SpringCurve(AppMotion.standard);
  late final AnimationController _c = AnimationController(
    vsync: this,
    value: widget.open ? 1 : 0,
    duration: _spring.duration,
    reverseDuration: _spring.duration * AppMotion.exitFactor,
  )..addStatusListener((_) => setState(() {}));
  late final CurvedAnimation _reducedFade = CurvedAnimation(
    parent: _c,
    curve: AppMotion.reduced.curve,
    reverseCurve: AppMotion.reduced.curve.flipped,
  );
  late final CurvedAnimation _slide = CurvedAnimation(parent: _c, curve: _spring, reverseCurve: Curves.easeOut.flipped);

  @override
  void didUpdateWidget(GlassInspector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.open == oldWidget.open) return;
    final reduced = MotionScope.reducedOf(context);
    _c
      ..duration = reduced ? AppMotion.reduced.duration : _spring.duration
      ..reverseDuration = reduced ? AppMotion.reduced.duration : _spring.duration * AppMotion.exitFactor;
    if (widget.open) {
      _c.forward();
    } else {
      _c.reverse();
    }
  }

  @override
  void dispose() {
    _reducedFade.dispose();
    _slide.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_c.isDismissed) return const SizedBox.shrink();
    final reduced = MotionScope.reducedOf(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final glass = GlassScope(
      kind: GlassLayerKind.sheet,
      child: AppGlass(
        key: const ValueKey('inspector'),
        role: GlassRole.sheet,
        shape: const AppleGlassShape.rounded(20),
        child: SizedBox(width: GlassInspector.width, child: widget.child),
      ),
    );
    return AnimatedBuilder(
      animation: _c,
      child: glass,
      builder: (context, child) {
        if (reduced) return GlassVisibility(value: _reducedFade.value.clamp(0.0, 1.0), child: child!);
        // Off-screen side: left in RTL (the content's end edge), right in LTR.
        final dx = (1 - _slide.value) * (GlassInspector.width + 16) * (isRtl ? -1 : 1);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );
  }
}
```
`AppMotion.standard` is an `AppSpring`; `SpringCurve(AppMotion.standard).duration` is its settle time (`spring_curve.dart`). If the analyzer flags `Curves.easeOut.flipped` on the slide close as the wrong direction, re-derive: the close runs the controller 1→0 and the reverse curve maps values on the way back; `Curves.easeOut.flipped` as `reverseCurve` makes the close ease-out in time (same reasoning as `glass_sheet.dart`). Keep it and add a test assertion: at 25 % of the close time the inspector has moved more than 25 % of its travel.

Add the two exports to `design.dart`.

- [ ] **Step 4: Run** both test files. Expected: PASS. `flutter analyze`.
- [ ] **Step 5: Commit** `feat(design): glass push page and inspector`.

---

### Task 6: AppShell

**Files:**
- Create: `lib/app/shell/app_shell.dart`
- Test: `test/app/shell/app_shell_test.dart`, `test/app/shell/app_shell_budget_test.dart`

**Interfaces:**
- Consumes: Tasks 1–5; `StatefulNavigationShell` (go_router); `GlassBackdropGroup`, `GlassScope`, `AppBackground`; `countCompositedBackdrops` (`test/support/backdrop_layer_count.dart`).
- Produces: `class AppShell extends StatelessWidget { const AppShell({required StatefulNavigationShell navigationShell, required String location, required List<ShellAction> Function(BuildContext context, WindowClass windowClass) actionsFor, required VoidCallback onSettings, required VoidCallback onSearch, Key? key}); }`
  - compact: `Stack[ GlassBackdropGroup(navigator), GlassScope(chrome)[ toolbar row (Positioned top: max(MediaQuery.paddingOf.top + 14, 58) − 58 + 58 … see below), tab bar row (Positioned bottom 24, inset 16) ] ]`. Toolbar top = `MediaQuery.paddingOf(context).top` + 14, but at least 58 when the top padding is 0 (the board's 390 × 844 frame has no safe area and puts the circles at 58). Content gets `MediaQuery` padding top += 58 + 44 − existing, bottom += 24 + 62 + 16 so pages can pad themselves with `MediaQuery.paddingOf`.
  - medium: `Row(textDirection RTL)[ GlassSidebar(rail) area (72 + 16 margins) | content ]` with the chrome scope painted after the content: implement as a `Stack` with the content `Positioned` (right inset 72 + 16) under `GlassBackdropGroup`, then the chrome `GlassScope` holding a `PositionedDirectional(start: 8, top: 8, bottom: 8)` rail. No tab bar; the toolbar row (desktop style: trailing search capsule + primary add) sits in the chrome scope at the top of the content area.
  - expanded: same as medium with the full `GlassSidebar` (236 + 16).
  - one `GlassScope(kind: GlassLayerKind.chrome)` per layout holding every chrome shape; the content under one `GlassBackdropGroup` keyed `ValueKey('shell-content')`; the navigator wrapped in a `KeyedSubtree(key: GlobalObjectKey(navigationShell.route))` … use one `GlobalKey` field held by a `StatefulWidget` wrapper so branch state survives a window-class change (make `AppShell` a `StatefulWidget` holding `final _navigatorKey = GlobalKey()`).
  - shortcuts: `Ctrl+,` → `onSettings`, `Ctrl+K` → `onSearch` (`CallbackShortcuts` + `Focus(autofocus: true)` around the shell).
  - tab/sidebar selection calls `navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex)`; sidebar items with a query or sub-path call `GoRouter.of(context).go(item.location)`.
  - keys: `ValueKey('shell-compact')`, `ValueKey('shell-medium')`, `ValueKey('shell-expanded')` on the layout roots.

- [ ] **Step 1: Write the failing tests**

`test/app/shell/app_shell_test.dart`:
```dart
import 'package:borj/app/design/design.dart';
import 'package:borj/app/shell/app_shell.dart';
import 'package:borj/app/shell/shell_destinations.dart';
import 'package:borj/app/shell/window_class.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/glass_test_app.dart';

final class _Counter extends StatefulWidget {
  const _Counter(this.name);
  final String name;
  @override
  State<_Counter> createState() => _CounterState();
}

final class _CounterState extends State<_Counter> {
  int n = 0;
  @override
  Widget build(BuildContext context) => Center(
    child: TextButton(onPressed: () => setState(() => n++), child: Text('${widget.name} $n')),
  );
}

({GoRouter router, List<String> log}) _setup() {
  final log = <String>[];
  late final GoRouter router;
  router = GoRouter(
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(
          navigationShell: shell,
          location: state.uri.toString(),
          actionsFor: (context, wc) => [
            if (wc == WindowClass.compact)
              ShellAction(icon: Icons.settings_outlined, label: 'تنظیمات', leading: true, onPressed: (_) => log.add('settings')),
            ShellAction(icon: Icons.add, label: 'ورود سریع', primary: true, onPressed: (_) => log.add('add')),
          ],
          onSettings: () => log.add('settings'),
          onSearch: () => log.add('search'),
        ),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/', builder: (c, s) => const _Counter('today'))]),
          StatefulShellBranch(routes: [GoRoute(path: '/tasks', builder: (c, s) => const _Counter('tasks'))]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/finance', builder: (c, s) => const _Counter('finance'), routes: [
              GoRoute(path: 'debts', builder: (c, s) => const _Counter('debts')),
            ]),
          ]),
        ],
      ),
    ],
  );
  return (router: router, log: log);
}

Future<void> _pump(WidgetTester tester, GoRouter router, Size size) async {
  await tester.binding.setSurfaceSize(size);
  await tester.pumpWidget(MaterialApp.router(
    routerConfig: router,
    theme: glassTestTheme(Brightness.light),
    builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
  ));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() async {
    TestWidgetsFlutterBinding.instance.platformDispatcher.clearAllTestValues();
  });

  for (final (w, key) in [(599.0, 'shell-compact'), (600.0, 'shell-medium'), (1023.0, 'shell-medium'), (1024.0, 'shell-expanded')]) {
    testWidgets('width $w uses $key', (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final s = _setup();
      await _pump(tester, s.router, Size(w, 844));
      expect(find.byKey(ValueKey(key)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('compact: tab switch swaps content on the next frame, no animation', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final s = _setup();
    await _pump(tester, s.router, const Size(390, 844));
    expect(find.text('today 0'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tab-finance')));
    await tester.pump();
    expect(find.text('finance 0'), findsOneWidget);
    expect(find.text('today 0'), findsNothing);
  });

  testWidgets('branch state survives tab switches and a window-class change', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final s = _setup();
    await _pump(tester, s.router, const Size(390, 844));
    await tester.tap(find.text('today 0'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('tab-tasks')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('tab-today')));
    await tester.pump();
    expect(find.text('today 1'), findsOneWidget);
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('shell-expanded')), findsOneWidget);
    expect(find.text('today 1'), findsOneWidget);
  });

  testWidgets('expanded: sidebar item with a sub-path navigates there', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final s = _setup();
    await _pump(tester, s.router, const Size(1440, 900));
    await tester.tap(find.byKey(const ValueKey('sidebar-item-/finance/debts')));
    await tester.pumpAndSettle();
    expect(find.text('debts 0'), findsOneWidget);
    expect(
      find.descendant(of: find.byKey(const ValueKey('sidebar-item-/finance/debts')), matching: find.byType(GlassInner)),
      findsOneWidget,
    );
  });

  testWidgets('shortcuts: Ctrl+, and Ctrl+K', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final s = _setup();
    await _pump(tester, s.router, const Size(1440, 900));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.comma);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(s.log, ['settings', 'search']);
  });

  testWidgets('compact: toolbar actions render in the chrome; RTL order', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final s = _setup();
    await _pump(tester, s.router, const Size(390, 844));
    final settings = tester.getCenter(find.byKey(const ValueKey('toolbar-تنظیمات')));
    final add = tester.getCenter(find.byKey(const ValueKey('toolbar-ورود سریع')));
    expect(settings.dx, greaterThan(add.dx));
    expect(tester.getTopLeft(find.byKey(const ValueKey('toolbar-تنظیمات'))).dy, 58);
    await tester.tap(find.byKey(const ValueKey('toolbar-ورود سریع')));
    expect(s.log, ['add']);
  });

  testWidgets('all chrome is in one GlassScope painted after the content', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final size in [const Size(390, 844), const Size(800, 844), const Size(1440, 900)]) {
      final s = _setup();
      await _pump(tester, s.router, size);
      final chromeScopes = find.byWidgetPredicate((w) => w is GlassScope && w.kind == GlassLayerKind.chrome);
      expect(chromeScopes, findsOneWidget, reason: '$size');
      expect(find.byKey(const ValueKey('shell-content')), findsOneWidget);
      // Paint order: children of one Stack paint in order, so the child that
      // holds the content group must come before the one with the chrome.
      final stack = tester.widget<Stack>(find.byKey(const ValueKey('shell-stack')));
      int indexOf(Finder target) => stack.children.indexWhere(
        (child) => find.descendant(of: find.byWidget(child), matching: target).evaluate().isNotEmpty,
      );
      final contentIndex = indexOf(find.byKey(const ValueKey('shell-content')));
      final chromeIndex = indexOf(chromeScopes);
      expect(contentIndex, greaterThanOrEqualTo(0), reason: '$size');
      expect(chromeIndex, greaterThan(contentIndex), reason: '$size');
    }
  });
}
```
`find.descendant(of: find.byWidget(child), …)` does not match the `of` widget itself; the chrome `GlassScope` is the child's own descendant (it sits inside `Positioned.fill`), so this works with the Step 3 layout.

`test/app/shell/app_shell_budget_test.dart`:
```dart
import 'package:borj/app/design/design.dart';
import 'package:borj/app/shell/app_shell.dart';
import 'package:borj/app/shell/window_class.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/backdrop_layer_count.dart';
import '../../support/glass_test_app.dart';

/// A branch page like the real ones will be: one content scope, 4 panels,
/// optionally an inspector (expanded only).
final class _Page extends StatelessWidget {
  const _Page({this.inspector = false});
  final bool inspector;
  @override
  Widget build(BuildContext context) => Stack(children: [
    Positioned.fill(
      child: Padding(
        padding: MediaQuery.paddingOf(context),
        child: GlassScope(
          kind: GlassLayerKind.content,
          child: Column(children: [
            for (var i = 0; i < 4; i++)
              const Padding(
                padding: EdgeInsets.all(8),
                child: AppGlass(role: GlassRole.panel, shape: AppleGlassShape.rounded(24), child: SizedBox(height: 80, width: double.infinity)),
              ),
          ]),
        ),
      ),
    ),
    if (inspector)
      const PositionedDirectional(end: 8, top: 8, bottom: 8, width: GlassInspector.width, child: GlassInspector(open: true, child: SizedBox())),
  ]);
}

GoRouter _router({bool inspector = false}) => GoRouter(routes: [
  StatefulShellRoute.indexedStack(
    builder: (context, state, shell) => AppShell(
      navigationShell: shell,
      location: state.uri.toString(),
      actionsFor: (context, wc) => [
        if (wc == WindowClass.compact) ShellAction(icon: Icons.settings_outlined, label: 'تنظیمات', leading: true, onPressed: (_) {}),
        ShellAction(icon: Icons.add, label: 'ورود سریع', primary: true, onPressed: (_) {}),
      ],
      onSettings: () {},
      onSearch: () {},
    ),
    branches: [
      StatefulShellBranch(routes: [GoRoute(path: '/', builder: (c, s) => _Page(inspector: inspector))]),
      StatefulShellBranch(routes: [GoRoute(path: '/tasks', builder: (c, s) => const _Page())]),
      StatefulShellBranch(routes: [GoRoute(path: '/finance', builder: (c, s) => const _Page())]),
    ],
  ),
]);

Future<int> _worst(WidgetTester tester, int frames) async {
  var worst = countCompositedBackdrops(tester);
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    final n = countCompositedBackdrops(tester);
    if (n > worst) worst = n;
  }
  return worst;
}

Future<void> _pump(WidgetTester tester, GoRouter router, Size size) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp.router(
    routerConfig: router,
    theme: glassTestTheme(Brightness.light),
    builder: (context, child) => Directionality(
      textDirection: TextDirection.rtl,
      child: GlassOverlayBackdrop(child: child!),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('compact: idle and during a tab switch ≤ 3', (tester) async {
    await _pump(tester, _router(), const Size(390, 844));
    expect(await _worst(tester, 5), lessThanOrEqualTo(3));
    await tester.tap(find.byKey(const ValueKey('tab-finance')));
    expect(await _worst(tester, 20), lessThanOrEqualTo(3));
  });

  testWidgets('medium idle ≤ 3', (tester) async {
    await _pump(tester, _router(), const Size(800, 844));
    expect(await _worst(tester, 5), lessThanOrEqualTo(3));
  });

  testWidgets('expanded idle ≤ 4, with the inspector open ≤ 4', (tester) async {
    await _pump(tester, _router(), const Size(1440, 900));
    expect(await _worst(tester, 5), lessThanOrEqualTo(4));
    await _pump(tester, _router(inspector: true), const Size(1440, 900));
    expect(await _worst(tester, 30), lessThanOrEqualTo(4));
  });

  testWidgets('a page inside the shell creates no backdrop group of its own', (tester) async {
    await _pump(tester, _router(), const Size(390, 844));
    expect(
      find.descendant(of: find.byKey(const ValueKey('shell-content')), matching: find.byType(GlassBackdropGroup)),
      findsNothing,
    );
  });
}
```
The counter treats each distinct backdrop key once and each keyless filter on its own (`backdrop_layer_count.dart`); under `flutter test` seeds are off, so these are the plain counts.

- [ ] **Step 2: Run** `flutter test test/app/shell/app_shell_test.dart test/app/shell/app_shell_budget_test.dart`. Expected: FAIL.

- [ ] **Step 3: Implement** `lib/app/shell/app_shell.dart`:
```dart
import 'package:borj/app/apple_visual/glass.dart';
import 'package:borj/app/design/design.dart';
import 'package:borj/app/shell/shell_destinations.dart';
import 'package:borj/app/shell/window_class.dart';
import 'package:borj/app/theme/app_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// The app shell (redesign spec §5). Content first under one backdrop group,
/// then every chrome shape of the window class in one chrome scope, so chrome
/// refracts the content scrolling under it (plan Decision 2).
class AppShell extends StatefulWidget {
  const AppShell({
    required this.navigationShell,
    required this.location,
    required this.actionsFor,
    required this.onSettings,
    required this.onSearch,
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final String location;
  final List<ShellAction> Function(BuildContext context, WindowClass windowClass) actionsFor;
  final VoidCallback onSettings;
  final VoidCallback onSearch;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final GlobalKey _navigatorKey = GlobalKey(debugLabel: 'shell-navigator');

  static const double _phoneToolbarTop = 58;
  static const double _phoneButton = 44;
  static const double _tabBottom = 24;
  static const double _side = 16;

  void _goBranch(int index) => widget.navigationShell.goBranch(
    index,
    initialLocation: index == widget.navigationShell.currentIndex,
  );

  void _goItem(SidebarItem item) {
    final uri = Uri.parse(item.location);
    if (uri.hasQuery || uri.path != sectionLocation(item.section)) {
      GoRouter.of(context).go(item.location);
    } else {
      _goBranch(item.section.index);
    }
  }

  Widget _content(EdgeInsets extraPadding) {
    final media = MediaQuery.of(context);
    return GlassBackdropGroup(
      key: const ValueKey('shell-content'),
      child: MediaQuery(
        data: media.copyWith(padding: media.padding + extraPadding),
        child: KeyedSubtree(key: _navigatorKey, child: widget.navigationShell),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wc = WindowClass.of(context);
    final actions = widget.actionsFor(context, wc);
    final layout = switch (wc) {
      WindowClass.compact => _compact(context, actions),
      WindowClass.medium => _desktop(context, actions, rail: true),
      WindowClass.expanded => _desktop(context, actions, rail: false),
    };
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.comma, control: true): widget.onSettings,
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): widget.onSearch,
      },
      child: Focus(
        autofocus: true,
        child: AppBackground(kind: AppBackgroundKind.phone, child: Material(type: MaterialType.transparency, child: layout)),
      ),
    );
  }

  Widget _compact(BuildContext context, List<ShellAction> actions) {
    final top = MediaQuery.paddingOf(context).top;
    final toolbarTop = top == 0 ? _phoneToolbarTop : top + 14;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Stack(
      key: const ValueKey('shell-stack'),
      children: [
        Positioned.fill(
          child: _content(EdgeInsets.only(
            top: toolbarTop + _phoneButton - top,
            bottom: _tabBottom + GlassTabBar.height + _side,
          )),
        ),
        Positioned.fill(
          child: GlassScope(
            key: const ValueKey('shell-compact'),
            kind: GlassLayerKind.chrome,
            child: Stack(children: [
              Positioned(top: toolbarTop, left: _side, right: _side, child: ShellToolbar(actions: actions, buttonSize: _phoneButton)),
              Positioned(
                bottom: _tabBottom + bottom,
                left: _side,
                right: _side,
                child: GlassTabBar(
                  destinations: shellDestinations,
                  selectedIndex: widget.navigationShell.currentIndex,
                  onSelected: _goBranch,
                  onSearch: widget.onSearch,
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _desktop(BuildContext context, List<ShellAction> actions, {required bool rail}) {
    final sideWidth = (rail ? GlassSidebar.railWidth : GlassSidebar.width) + 16;
    const toolbarHeight = 14.0 + 44;
    return Stack(
      key: const ValueKey('shell-stack'),
      children: [
        PositionedDirectional(
          start: sideWidth,
          end: 0,
          top: 0,
          bottom: 0,
          child: _content(const EdgeInsets.only(top: toolbarHeight)),
        ),
        Positioned.fill(
          child: GlassScope(
            key: ValueKey(rail ? 'shell-medium' : 'shell-expanded'),
            kind: GlassLayerKind.chrome,
            child: Stack(children: [
              PositionedDirectional(
                start: 8,
                top: 8,
                bottom: 8,
                child: GlassSidebar(
                  groups: sidebarGroups(),
                  selectedLocation: widget.location,
                  rail: rail,
                  onSelected: _goItem,
                  onSettings: widget.onSettings,
                ),
              ),
              PositionedDirectional(
                start: sideWidth + 16,
                end: 20,
                top: 14,
                child: ShellToolbar(actions: actions, buttonSize: 44),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}
```
`PositionedDirectional(start: …)` puts the sidebar on the RIGHT in RTL (start = right). The desktop toolbar search capsule is added in Task 8 as a `ShellAction`-independent widget: leave `ShellToolbar` here and let Task 8 extend the desktop toolbar row. If `GlassScope` does not take a `key` parameter, put the key on a `KeyedSubtree` around it.

- [ ] **Step 4: Run** both test files. Expected: PASS. `flutter analyze`.
- [ ] **Step 5: Commit** `feat(shell): app shell with one chrome scope per window class`.

---

### Task 7: Router, interim Today, pending routes, notification locations

**Files:**
- Modify: `lib/app/router/app_router.dart`
- Create: `lib/app/shell/pending_screen.dart`, `lib/app/shell/today_interim_page.dart`
- Delete: `lib/features/dashboard/presentation/dashboard_screen.dart`, `test/features/dashboard/original_dashboard_screen_test.dart`, `test/features/dashboard/dashboard_chrome_glass_test.dart`
- Modify: `CLAUDE.md` (review page entry: "long-press the Today large title")
- Test: `test/app/router/app_router_test.dart`, `test/app/router/notification_locations_resolve_test.dart`

**Interfaces:**
- Consumes: `AppShell` (Task 6), `GlassPushPage`, `EmptyState`, `LargeTitleHeader`, `ShellAction`, `TasksPanel` (`lib/features/dashboard/presentation/widgets/tasks_panel.dart`), `FinancePanel` (`.../finance_panel.dart`), `SettingsScreen`, `GlassReviewScreen`, `LegacyImportBanner`, `NotificationRouteLocationMapper`, `PersianDateLabel.full`, `appClockProvider`.
- Produces:
  - `AppRoutes` gains: `tasks = '/tasks'`, `search = '/search'`, `habits = '/habits'`, `goals = '/goals'`, `challenges = '/challenges'` (keep every existing constant).
  - `final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');` exported from `app_router.dart`.
  - `class PendingScreen extends StatelessWidget { const PendingScreen({required String title, String? message, Key? key}); }` — a page with a back button (`GlassButton`, `Icons.arrow_back`, semantic «بازگشت») and an `EmptyState(icon: Icons.construction_outlined, title: title, message: message ?? 'این بخش در مرحله‌های بعدی ساخته می‌شود')`. Key `ValueKey('pending-screen')`.
  - `class RouteErrorScreen extends StatelessWidget { const RouteErrorScreen({Key? key}); }` — `EmptyState(icon: Icons.explore_off_outlined, title: 'این صفحه پیدا نشد', actionLabel: 'رفتن به امروز', onAction: () => context.go('/'))`. Key `ValueKey('route-error')`.
  - `class TodayInterimPage extends ConsumerWidget` — `ListView` padded with `MediaQuery.paddingOf(context)`: `LargeTitleHeader(key: const ValueKey('today-title'), title: 'امروز', subtitle: PersianDateLabel.full(ref.watch(appClockProvider).nowLocal()), onTitleLongPress: kDebugMode ? () => context.go(AppRoutes.glassReview) : null)`, then `LegacyImportBanner()`, then `EmptyState(icon: Icons.wb_sunny_outlined, title: 'صفحهٔ امروز در حال ساخت است', message: 'به‌زودی کارها و پول امروز اینجا می‌آیند')`.

Routes (all under `GoRouter(navigatorKey: rootNavigatorKey, initialLocation: '/', errorBuilder: (c, s) => const RouteErrorScreen())`):
```
StatefulShellRoute.indexedStack(builder: AppShell(...))
  branch today:   GoRoute('/')                     -> TodayInterimPage
  branch tasks:   GoRoute('/tasks')                -> _BranchPage(TasksPanel)
                    GoRoute(':taskId')             -> GlassPushPage(PendingScreen('جزئیات کار'))
  branch finance: GoRoute('/finance')              -> _BranchPage(FinancePanel)
                    GoRoute('transactions')        -> GlassPushPage(PendingScreen('تراکنش‌ها'))
                      GoRoute(':transactionId')    -> GlassPushPage(PendingScreen('جزئیات تراکنش'))
                    GoRoute('calendar')            -> GlassPushPage(PendingScreen('تقویم مالی'))
                    GoRoute('debts')               -> GlassPushPage(PendingScreen('بدهی‌ها و طلب‌ها'))
                      GoRoute(':debtId')           -> GlassPushPage(PendingScreen('جزئیات بدهی'))
                    GoRoute('installments')        -> GlassPushPage(PendingScreen('اقساط'))
                      GoRoute(':installmentId')    -> GlassPushPage(PendingScreen('جزئیات قسط'))
root (parentNavigatorKey: rootNavigatorKey, all GlassPushPage):
  /settings  -> SettingsScreen(onBack: pop or go('/'))
  /search    -> Task 8 (in this task: PendingScreen('جست‌وجو'))
  /habits/:habitId, /goals/:goalId, /challenges/:challengeId -> PendingScreen('عادت‌ها' | 'هدف‌ها' | 'چالش‌ها')
  /backup    -> PendingScreen('پشتیبان‌گیری')
  /migration -> PendingScreen('انتقال اطلاعات')
  /debug/glass-review (kDebugMode) -> GlassReviewScreen(referenceDir: glassReferenceDir)
```
`_BranchPage(child)` (private in `app_router.dart`): `SingleChildScrollView(padding: MediaQuery.paddingOf(context) + const EdgeInsets.symmetric(horizontal: 16), child: child)` — no max-width cap. The shell's `actionsFor`:
- Today, compact: `[ShellAction(icon: Icons.calendar_month_outlined, label: 'تقویم', leading: true, onPressed: (c) => c.go('/tasks?view=calendar')), ShellAction(icon: Icons.settings_outlined, label: 'تنظیمات', leading: true, onPressed: (c) => c.push(AppRoutes.settings)), ShellAction(icon: Icons.add, label: 'ورود سریع', primary: true, onPressed: _quickEntryPlaceholder)]`
- every other branch on compact: `[]`
- medium/expanded (all branches): `[ShellAction(icon: Icons.add, label: 'افزودن', primary: true, onPressed: _quickEntryPlaceholder)]`
`_quickEntryPlaceholder(BuildContext c)` calls `showGlassSheet<void>(c, builder: (_) => const Padding(padding: EdgeInsets.all(16), child: EmptyState(icon: Icons.bolt_outlined, title: 'ورود سریع', message: 'در مرحلهٔ کارها ساخته می‌شود')))`.
`onSettings: () => router.push(AppRoutes.settings)`, `onSearch: () => router.push(AppRoutes.search)` (Task 8 replaces the desktop path with the overlay).

- [ ] **Step 1: Write the failing tests**

`test/app/router/notification_locations_resolve_test.dart`:
```dart
import 'package:borj/app/router/app_router.dart';
import 'package:borj/app/router/notification_route_location_mapper.dart';
import 'package:borj/core/notifications/notification_route_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/borj_test_app.dart';

void main() {
  const mapper = NotificationRouteLocationMapper();
  final intents = <NotificationRouteIntent>[
    const NotificationTaskRouteIntent('t1'),
    const NotificationHabitRouteIntent('h1'),
    const NotificationChallengeRouteIntent('c1'),
    const NotificationGoalRouteIntent('g1'),
    const NotificationDebtRouteIntent('d1'),
    const NotificationInstallmentRouteIntent('i1'),
    const NotificationTransactionRouteIntent('x1'),
    for (final s in NotificationSection.values) NotificationSectionRouteIntent(s),
  ];

  for (final intent in intents) {
    testWidgets('${mapper.locationFor(intent)} resolves', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final container = await pumpBorjTestApp(tester);
      final router = container.read(appRouterProvider);
      router.go(mapper.locationFor(intent)!);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('route-error')), findsNothing, reason: mapper.locationFor(intent));
      expect(router.routerDelegate.currentConfiguration.uri.toString(), mapper.locationFor(intent));
    });
  }
}
```
`test/support/borj_test_app.dart` (new helper):
```dart
import 'package:borj/app/bootstrap/app_bootstrap.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:borj/features/legacy_import/data/legacy_v1_source_locator.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_database.dart';

/// Pumps the real [BorjApp] over an in-memory database, with no v1 data and
/// no file IO for preferences. Tears everything down after the test.
Future<ProviderContainer> pumpBorjTestApp(
  WidgetTester tester, {
  List<Override> overrides = const <Override>[],
}) async {
  final database = openTestDatabase();
  final container = ProviderContainer(
    overrides: <Override>[
      appDatabaseProvider.overrideWithValue(database),
      legacyV1SourceLocatorProvider.overrideWithValue(
        const LegacyV1SourceLocator(operatingSystem: 'android', environment: <String, String>{}),
      ),
      ...overrides,
    ],
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await database.close();
  });
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const BorjApp()));
  await tester.pumpAndSettle();
  return container;
}
```
Before using it, read `lib/app/bootstrap/app_bootstrap.dart` and the Phase 1 settings tests (`test/features/settings/**`) for the provider that loads `borj-preferences.json` (`appearancePreferencesProvider` or its store). If `BorjApp` would touch the real file system or a platform channel in a widget test, add the same override those tests use to the list above (in-memory store) and say so in the report. `openTestDatabase` is in `test/support/test_database.dart`.

Notification section values: read `NotificationSection` in `lib/core/notifications/notification_route_intent.dart` and use its real enum name.

`test/app/router/app_router_test.dart`:
```dart
import 'package:borj/app/apple_visual/review/glass_review_screen.dart';
import 'package:borj/app/router/app_router.dart';
import 'package:borj/app/shell/today_interim_page.dart';
import 'package:borj/features/dashboard/presentation/widgets/tasks_panel.dart';
import 'package:borj/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/borj_test_app.dart';

Future<void> _size(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  testWidgets('opens on the interim Today', (tester) async {
    await _size(tester, const Size(390, 844));
    await pumpBorjTestApp(tester);
    expect(find.byType(TodayInterimPage), findsOneWidget);
    expect(find.text('صفحهٔ امروز در حال ساخت است'), findsOneWidget);
    expect(find.byKey(const ValueKey('shell-compact')), findsOneWidget);
  });

  testWidgets('tabs show the tasks and finance panels', (tester) async {
    await _size(tester, const Size(390, 844));
    await pumpBorjTestApp(tester);
    await tester.tap(find.byKey(const ValueKey('tab-tasks')));
    await tester.pumpAndSettle();
    expect(find.text('کارهای من'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tab-finance')));
    await tester.pumpAndSettle();
    expect(find.text('مالی من'), findsOneWidget);
    expect(find.text('کارهای من'), findsNothing);
  });

  testWidgets('compact: the Today settings circle pushes Settings; back returns', (tester) async {
    await _size(tester, const Size(390, 844));
    await pumpBorjTestApp(tester);
    await tester.tap(find.byKey(const ValueKey('toolbar-تنظیمات')));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    GoRouter.of(tester.element(find.byType(SettingsScreen))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(TodayInterimPage), findsOneWidget);
  });

  testWidgets('expanded: the sidebar settings row opens Settings', (tester) async {
    await _size(tester, const Size(1440, 900));
    await pumpBorjTestApp(tester);
    expect(find.byKey(const ValueKey('toolbar-تنظیمات')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('sidebar-settings')));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testWidgets('debug: long-press the Today title opens the glass review', (tester) async {
    await _size(tester, const Size(390, 844));
    await pumpBorjTestApp(tester);
    await tester.longPress(
      find.descendant(of: find.byKey(const ValueKey('today-title')), matching: find.text('امروز')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(GlassReviewScreen), findsOneWidget);
  });

  testWidgets('unknown location shows the error page; its action goes home', (tester) async {
    await _size(tester, const Size(390, 844));
    final container = await pumpBorjTestApp(tester);
    container.read(appRouterProvider).go('/nope');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('route-error')), findsOneWidget);
    await tester.tap(find.text('رفتن به امروز'));
    await tester.pumpAndSettle();
    expect(find.byType(TodayInterimPage), findsOneWidget);
  });

  testWidgets('expanded: no 780 px cap on the panels', (tester) async {
    await _size(tester, const Size(1440, 900));
    final container = await pumpBorjTestApp(tester);
    container.read(appRouterProvider).go('/tasks');
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(TasksPanel)).width, greaterThan(1000));
  });
}
```
Add `import 'package:go_router/go_router.dart';` to this test. `TodayInterimPage` passes `key: const ValueKey('today-title')` to its `LargeTitleHeader` (the tab bar also shows «امروز», so the test finds the title through that key).

- [ ] **Step 2: Run** both files on HEAD before changing the router. Expected: FAIL — `/tasks`, `/tasks/t1`, `/habits/h1`, `/goals/g1`, `/challenges/c1`, `/finance/debts/d1`, `/finance/installments/i1`, `/finance/transactions/x1` hit the error page. Paste the failing list into the report (RED).

- [ ] **Step 3: Implement** the router as specified, `PendingScreen`, `RouteErrorScreen`, `TodayInterimPage`. Delete `dashboard_screen.dart` and the two dashboard tests (their assertions now live in `app_router_test.dart` 2–5 and in `app_shell_test.dart`; the chrome-is-glass check is `app_shell_test.dart`'s "one GlassScope" test). Remove now-unused imports. Update `CLAUDE.md` Visual system paragraph: replace "long-press the brand island" with "long-press the Today large title".

- [ ] **Step 4: Run** `flutter test test/app/router test/app/shell` and `grep -rn "DashboardScreen\|_selectedPanel\|contentMaxWidth" lib test` (expect no hits except `OriginalDesignTokens.contentMaxWidth`'s definition if other code still uses it). Expected: PASS. `flutter analyze`. Then the full `flutter test --exclude-tags device`; fix any test that depended on the old dashboard (report each).
- [ ] **Step 5: Commit** `feat(shell): router branches, interim Today, every notification location resolves`.

---

### Task 8: Search shell

**Files:**
- Create: `lib/app/shell/search_shell.dart`
- Modify: `lib/app/router/app_router.dart` (`/search` route, desktop `onSearch`), `lib/app/shell/app_shell.dart` (desktop search capsule in the toolbar row)
- Test: `test/app/shell/search_shell_test.dart`

**Interfaces:**
- Produces:
  - `class SearchShellScreen extends StatefulWidget` — compact page for `/search` (pushed as a `GlassPushPage`): a back circle, an autofocused `GlassTextField(hint: 'جست‌وجو')`, and `EmptyState(icon: Icons.search, title: 'جست‌وجو به‌زودی', message: 'جست‌وجوی کارها و تراکنش‌ها در مرحلهٔ خودش ساخته می‌شود')`.
  - `Future<void> showSearchOverlay(BuildContext context)` — desktop (Ctrl+K, toolbar capsule): `showGeneralDialog` on the root navigator with `transitionDuration: Duration.zero` (motion spec: no animation), `barrierDismissible: true`, `barrierColor: colors.scrim`, content: `GlassOverlayContent(child: Align(alignment: Alignment.topCenter, child: Padding(padding: EdgeInsets.only(top: 96), child: SizedBox(width: 560, child: AppGlass(role: GlassRole.sheet, shape: AppleGlassShape.rounded(20), child: …field + EmptyState…)))))`. `Escape` closes (dialogs already pop on Escape; verify).
  - `AppShell` desktop toolbar row: a 230 × 44 glass capsule button «جست‌وجو» with a search icon at the trailing side before the actions (key `ValueKey('toolbar-search')`), calling `widget.onSearch`.
  - Router: compact `onSearch` → `router.push('/search')`; medium/expanded `onSearch` → `showSearchOverlay(rootNavigatorKey.currentContext!)`. The phone search circle always pushes `/search`.

- [ ] **Step 1: Write the failing tests** `test/app/shell/search_shell_test.dart`:
```dart
import 'package:borj/app/shell/search_shell.dart';
import 'package:borj/app/shell/today_interim_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/backdrop_layer_count.dart';
import '../../support/borj_test_app.dart';

Future<void> _size(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Future<void> _ctrlK(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
}

void main() {
  testWidgets('compact: the search circle pushes the search page with a focused field', (tester) async {
    await _size(tester, const Size(390, 844));
    await pumpBorjTestApp(tester);
    await tester.tap(find.byKey(const ValueKey('tab-search')));
    await tester.pumpAndSettle();
    expect(find.byType(SearchShellScreen), findsOneWidget);
    expect(find.text('جست‌وجو به‌زودی'), findsOneWidget);
    expect(tester.testTextInput.hasAnyClients, isTrue);
    GoRouter.of(tester.element(find.byType(SearchShellScreen))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(TodayInterimPage), findsOneWidget);
  });

  testWidgets('expanded: Ctrl+K opens the overlay on the next frame; Escape closes', (tester) async {
    await _size(tester, const Size(1440, 900));
    await pumpBorjTestApp(tester);
    await _ctrlK(tester);
    await tester.pump();
    expect(find.text('جست‌وجو به‌زودی'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.text('جست‌وجو به‌زودی'), findsNothing);
  });

  testWidgets('expanded: the toolbar search capsule opens the same overlay', (tester) async {
    await _size(tester, const Size(1440, 900));
    await pumpBorjTestApp(tester);
    expect(tester.getSize(find.byKey(const ValueKey('toolbar-search'))), const Size(230, 44));
    await tester.tap(find.byKey(const ValueKey('toolbar-search')));
    await tester.pump();
    expect(find.text('جست‌وجو به‌زودی'), findsOneWidget);
  });

  testWidgets('expanded: overlay open stays within 4 captures', (tester) async {
    await _size(tester, const Size(1440, 900));
    await pumpBorjTestApp(tester);
    await _ctrlK(tester);
    await tester.pump();
    expect(countCompositedBackdrops(tester), lessThanOrEqualTo(4));
  });
}
```
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement** as specified.
- [ ] **Step 4: Run** the file and `test/app/shell`. Expected: PASS. `flutter analyze`.
- [ ] **Step 5: Commit** `feat(shell): search shell (phone page, desktop Ctrl+K overlay)`.

---

### Task 9: Review page samples for the shell patterns

**Files:**
- Modify: `lib/app/apple_visual/review/design_review_samples.dart`
- Test: the existing review test (`test/app/apple_visual/review/*`) iterates all samples; extend nothing else.

Add samples (same structure as the existing entries; each builds inside the sample frame, chrome samples wrap their widget in `GlassScope(kind: GlassLayerKind.chrome)`):
- `GlassTabBar` — `board: 'Main'`: the tab bar with `selectedIndex` cycling 0→1→2 every 1.5 s (a small `StatefulWidget` with a `Timer.periodic`, cancelled in `dispose`).
- `GlassSidebar` — `board: 'MacToday'`: 236 × 560 sidebar, selected `/`.
- `GlassSidebar rail` — 72 × 560.
- `ShellToolbar` — `board: 'Main'`: the Today compact actions.
- `LargeTitleHeader` — `board: 'Main'`: title امروز with a date line.
- `EmptyState` — `board: 'PhoneEmptyToday'`.
- `GlassInspector` — `board: 'MacTasks'`: a toggle button opening and closing the inspector.
Read the existing `GlassReviewSample`/`designReviewSamples` entries for the exact fields (label, board name, builder signature) and follow them.

- [ ] **Step 1:** Add the samples.
- [ ] **Step 2: Run** `flutter test test/app/apple_visual` (the review test pumps every sample). Expected: PASS, no exceptions.
- [ ] **Step 3: Commit** `feat(review): shell pattern samples`.

---

### Task 10: Device probe on the real shell

**Files:**
- Create: `integration_test/glass_shell_probe_test.dart`

Phone (390 × 844) runs before desktop (1440 × 900). Tasks and Finance are printed, not asserted (plan Decision 7). `integration_test/glass_perf_probe_test.dart` already imports `../test/support/…`, so this file does too.

```dart
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:borj/app/router/app_router.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../test/support/backdrop_layer_count.dart';
import '../test/support/borj_test_app.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(LiquidGlass.precache);

  Future<({int worst, int passes})> sample(WidgetTester tester, int frames) async {
    var worst = 0;
    var passes = 0;
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      final n = countCompositedBackdropsDetailed(tester);
      worst = math.max(worst, n.captures);
      passes = math.max(passes, n.activeSeededPasses);
    }
    return (worst: worst, passes: passes);
  }

  void reportPerf(String scene, String key) {
    final summary = binding.reportData![key]! as Map<String, dynamic>;
    final p90 = (summary['90th_percentile_frame_rasterizer_time_millis'] as num).toDouble();
    // ignore: avoid_print
    print('LG_PERF scene=$scene mode=${kProfileMode ? 'profile' : 'debug'} raster_p90_ms=$p90');
    if (kProfileMode) expect(p90, lessThanOrEqualTo(8.0));
  }

  testWidgets('phoneShell within budget on real glass', (tester) async {
    expect(ui.ImageFilter.isShaderFilterSupported, isTrue, reason: 'real glass is not active');
    await binding.setSurfaceSize(const Size(390, 844));
    final container = await pumpBorjTestApp(tester);
    final today = await sample(tester, 30);
    await tester.tap(find.byKey(const ValueKey('tab-tasks')));
    final tasks = await sample(tester, 30);
    await tester.tap(find.byKey(const ValueKey('tab-finance')));
    final finance = await sample(tester, 30);
    await tester.tap(find.byKey(const ValueKey('tab-today')));
    await tester.pumpAndSettle();
    unawaited(container.read(appRouterProvider).push(AppRoutes.settings));
    final push = await sample(tester, 30);
    await tester.pumpAndSettle();
    // ignore: avoid_print
    print('LG_COMPOSITED scene=phoneShell today=${today.worst} tasks=${tasks.worst} finance=${finance.worst} settingsPush=${push.worst} active_seeded_passes=${math.max(today.passes, push.passes)}');
    final worst = math.max(today.worst, push.worst);
    // ignore: avoid_print
    print('LG_CAPTURES scene=phoneShell path=real max=$worst');
    if (!kProfileMode) {
      expect(worst, lessThanOrEqualTo(3));
      expect(math.max(today.passes, push.passes), greaterThan(0), reason: 'no active seeded pass seen');
      expect(worst, greaterThanOrEqualTo(1));
    }
    container.read(appRouterProvider).pop();
    await tester.pumpAndSettle();
    await binding.watchPerformance(() async {
      final watch = Stopwatch()..start();
      var finance = true;
      while (watch.elapsed < const Duration(seconds: 3)) {
        await tester.tap(find.byKey(ValueKey(finance ? 'tab-finance' : 'tab-today')));
        await tester.pump(const Duration(milliseconds: 300));
        finance = !finance;
      }
    }, reportKey: 'glass_shell_phone');
    reportPerf('phoneShell', 'glass_shell_phone');
  });

  testWidgets('desktopShell within budget on real glass', (tester) async {
    expect(ui.ImageFilter.isShaderFilterSupported, isTrue, reason: 'real glass is not active');
    await binding.setSurfaceSize(const Size(1440, 900));
    await pumpBorjTestApp(tester);
    final today = await sample(tester, 30);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    final overlay = await sample(tester, 30);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    final worst = math.max(today.worst, overlay.worst);
    // ignore: avoid_print
    print('LG_COMPOSITED scene=desktopShell today=${today.worst} search=${overlay.worst} active_seeded_passes=${math.max(today.passes, overlay.passes)}');
    // ignore: avoid_print
    print('LG_CAPTURES scene=desktopShell path=real max=$worst');
    if (!kProfileMode) {
      expect(worst, lessThanOrEqualTo(4));
      expect(math.max(today.passes, overlay.passes), greaterThan(0), reason: 'no active seeded pass seen');
      expect(overlay.worst, greaterThan(today.worst), reason: 'the overlay glass must be counted');
    }
    await binding.watchPerformance(() async {
      final watch = Stopwatch()..start();
      var money = true;
      while (watch.elapsed < const Duration(seconds: 3)) {
        await tester.tap(find.byKey(ValueKey(money ? 'sidebar-item-/finance/transactions' : 'sidebar-item-/')));
        await tester.pump(const Duration(milliseconds: 300));
        money = !money;
      }
    }, reportKey: 'glass_shell_desktop');
    reportPerf('desktopShell', 'glass_shell_desktop');
  });
}
```
`pumpBorjTestApp` registers its teardown with `addTearDown`, which works under `IntegrationTestWidgetsFlutterBinding`. The interim Today has no content glass, so phone idle may read 1 (chrome only); the floor is therefore ≥ 1 plus an active seeded pass.

- [ ] **Step 1: Implement** the file above.
- [ ] **Step 2: Run** `tool/ci.sh --device`. Expected: PASS; report every `LG_*` line.
- [ ] **Step 3: Run** `flutter drive --profile -d linux --driver=test_driver/integration_test.dart --target=integration_test/glass_shell_probe_test.dart`. Expected: every profile `raster_p90_ms` ≤ 8.
- [ ] **Step 4: Commit** `test(glass): device probe on the real shell`.

---

### Task 11: App icon wiring

**Files:**
- Modify: `windows/runner/resources/app_icon.ico` (← `assets/brand/png/borj.ico`)
- Modify: `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_{16,32,64,128,256,512,1024}.png` (← `assets/brand/png/borj-app-icon-{16,…,1024}.png`, same sizes)
- Modify: `android/app/src/main/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png` (48, 72, 96, 144, 192 px, resized from `borj-app-icon-1024.png` with Pillow `Image.LANCZOS`; check the existing file names in each folder and keep them)
- Modify: `linux/runner/my_application.cc` (window icon) and `linux/CMakeLists.txt` (install the icon next to the binary)
- Test: `test/app/brand/platform_icons_test.dart`

Steps:
- [ ] **Step 1: Write the failing test** `test/app/brand/platform_icons_test.dart` (pure Dart file checks, no Flutter widgets):
```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('windows icon is the brand ico', () {
    expect(File('windows/runner/resources/app_icon.ico').readAsBytesSync(), File('assets/brand/png/borj.ico').readAsBytesSync());
  });
  test('macOS app icons are the brand PNGs', () {
    for (final s in [16, 32, 64, 128, 256, 512, 1024]) {
      expect(
        File('macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_$s.png').readAsBytesSync(),
        File('assets/brand/png/borj-app-icon-$s.png').readAsBytesSync(),
        reason: '$s',
      );
    }
  });
  test('linux runner sets the window icon', () {
    expect(File('linux/runner/my_application.cc').readAsStringSync(), contains('gtk_window_set_icon_from_file'));
  });
}
```
For Android, add a test that each `mipmap-*/ic_launcher.png` exists, is a PNG (bytes start with `0x89 0x50 0x4E 0x47`) and has the expected width (read bytes 16–19 big-endian of the IHDR chunk): mdpi 48, hdpi 72, xhdpi 96, xxhdpi 144, xxxhdpi 192.
- [ ] **Step 2: Run** it. Expected: FAIL.
- [ ] **Step 3: Copy and resize.** Copies with `cp`; Android with a one-off Python command run from the repo root (do not add a script file): `python3 -c "from PIL import Image; im=Image.open('assets/brand/png/borj-app-icon-1024.png'); [im.resize((s,s), Image.LANCZOS).save(f'android/app/src/main/res/mipmap-{d}/ic_launcher.png') for d,s in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]]"`. Linux: in `my_application.cc` after the window is created, `gtk_window_set_icon_from_file(window, icon_path, nullptr);` where `icon_path` is `<executable dir>/data/borj-app-icon-256.png` (build the path from `/proc/self/exe` with `g_file_read_link` and `g_path_get_dirname`, freeing both); in `linux/CMakeLists.txt` add `install(FILES "${PROJECT_SOURCE_DIR}/../assets/brand/png/borj-app-icon-256.png" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}" COMPONENT Runtime)`. Read both files first and follow their existing style.
- [ ] **Step 4: Run** the test, then `flutter build linux --release` and check that `build/linux/x64/release/bundle/data/borj-app-icon-256.png` exists. Expected: PASS.
- [ ] **Step 5: Commit** `feat(brand): platform app icons from the logo kit`.

---

### Task 12 (controller): Part A checkpoint

Done by the main session.
- [ ] Final whole-branch review (opus) and fix wave, as in Phase 1.
- [ ] `docs/superpowers/checkpoints/2026-11-XX-redesign-phase-2a-checkpoint.md`: delivered, commits, test counts, analyze/format/`tool/ci.sh --device`, every `LG_*` line, decisions, deferred minors.
- [ ] WORKLOG entry, roadmap update; no owner sign-off request (Phase 2 sign-off after Part C). Tell the owner in Persian what changed and how to try it (the app now opens on the shell).
