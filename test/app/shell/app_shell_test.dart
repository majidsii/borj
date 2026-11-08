import 'package:borj/app/design/design.dart';
import 'package:borj/app/shell/app_shell.dart';
import 'package:borj/app/shell/window_class.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/glass_test_app.dart';

/// The padding the last built branch page saw.
EdgeInsets _pagePadding = EdgeInsets.zero;

final class _Counter extends StatefulWidget {
  const _Counter(this.name);
  final String name;
  @override
  State<_Counter> createState() => _CounterState();
}

final class _CounterState extends State<_Counter> {
  int n = 0;
  @override
  Widget build(BuildContext context) {
    _pagePadding = MediaQuery.paddingOf(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () => setState(() => n++),
            child: Text('${widget.name} $n'),
          ),
          if (widget.name == 'today')
            const SizedBox(
              width: 200,
              child: TextField(key: ValueKey('field')),
            ),
        ],
      ),
    );
  }
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
              ShellAction(
                icon: Icons.settings_outlined,
                label: 'تنظیمات',
                leading: true,
                onPressed: (_) => log.add('settings'),
              ),
            ShellAction(
              icon: Icons.add,
              label: 'ورود سریع',
              primary: true,
              onPressed: (_) => log.add('add'),
            ),
          ],
          onSettings: () => log.add('settings'),
          onSearch: () => log.add('search'),
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/', builder: (c, s) => const _Counter('today')),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tasks',
                builder: (c, s) => const _Counter('tasks'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/finance',
                builder: (c, s) => const _Counter('finance'),
                routes: [
                  GoRoute(
                    path: 'debts',
                    builder: (c, s) => const _Counter('debts'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
  return (router: router, log: log);
}

Future<void> _pump(
  WidgetTester tester,
  GoRouter router,
  Size size, {
  Brightness brightness = Brightness.light,
  double textScale = 1.0,
}) async {
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      theme: glassTestTheme(brightness),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: Directionality(textDirection: TextDirection.rtl, child: child!),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() async {
    TestWidgetsFlutterBinding.instance.platformDispatcher.clearAllTestValues();
  });

  for (final (w, key) in [
    (599.0, 'shell-compact'),
    (600.0, 'shell-medium'),
    (1023.0, 'shell-medium'),
    (1024.0, 'shell-expanded'),
  ]) {
    testWidgets('width $w uses $key', (tester) async {
      final s = _setup();
      await _pump(tester, s.router, Size(w, 844));
      expect(find.byKey(ValueKey(key)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final v in glassTestVariants) {
    for (final size in const [
      Size(390, 844),
      Size(800, 844),
      Size(1440, 900),
    ]) {
      testWidgets('renders ${size.width} (${v.name})', (tester) async {
        final s = _setup();
        await _pump(
          tester,
          s.router,
          size,
          brightness: v.brightness,
          textScale: v.textScale,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'compact: tab switch swaps content on the next frame, no animation',
    (tester) async {
      final s = _setup();
      await _pump(tester, s.router, const Size(390, 844));
      expect(find.text('today 0'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('tab-finance')));
      await tester.pump();
      expect(find.text('finance 0'), findsOneWidget);
      expect(find.text('today 0'), findsNothing);
    },
  );

  testWidgets('branch state survives tab switches and a window-class change', (
    tester,
  ) async {
    final s = _setup();
    await _pump(tester, s.router, const Size(390, 844));
    await tester.tap(find.text('today 0'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('tab-tasks')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('tab-today')));
    await tester.pump();
    expect(find.text('today 1'), findsOneWidget);
    tester.view.physicalSize = const Size(1440, 900);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('shell-expanded')), findsOneWidget);
    expect(find.text('today 1'), findsOneWidget);
  });

  testWidgets('expanded: sidebar item with a sub-path navigates there', (
    tester,
  ) async {
    final s = _setup();
    await _pump(tester, s.router, const Size(1440, 900));
    await tester.tap(find.byKey(const ValueKey('sidebar-item-/finance/debts')));
    await tester.pumpAndSettle();
    expect(find.text('debts 0'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('sidebar-item-/finance/debts')),
        matching: find.byType(GlassInner),
      ),
      findsOneWidget,
    );
  });

  testWidgets('shortcuts: Ctrl+, and Ctrl+K', (tester) async {
    final s = _setup();
    await _pump(tester, s.router, const Size(1440, 900));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.comma);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(s.log, ['settings', 'search']);
  });

  testWidgets('compact: toolbar actions render in the chrome; RTL order', (
    tester,
  ) async {
    final s = _setup();
    await _pump(tester, s.router, const Size(390, 844));
    final settings = tester.getCenter(
      find.byKey(const ValueKey('toolbar-تنظیمات')),
    );
    final add = tester.getCenter(
      find.byKey(const ValueKey('toolbar-ورود سریع')),
    );
    expect(settings.dx, greaterThan(add.dx));
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('toolbar-تنظیمات'))).dy,
      58,
    );
    await tester.tap(find.byKey(const ValueKey('toolbar-ورود سریع')));
    expect(s.log, ['add']);
  });

  testWidgets('all chrome is in one GlassScope painted after the content', (
    tester,
  ) async {
    for (final size in [
      const Size(390, 844),
      const Size(800, 844),
      const Size(1440, 900),
    ]) {
      final s = _setup();
      await _pump(tester, s.router, size);
      final chromeScopes = find.byWidgetPredicate(
        (w) => w is GlassScope && w.kind == GlassLayerKind.chrome,
      );
      expect(chromeScopes, findsOneWidget, reason: '$size');
      expect(find.byKey(const ValueKey('shell-content')), findsOneWidget);
      // Paint order: children of one Stack paint in order, so the child that
      // holds the content group must come before the one with the chrome.
      final stack = tester.widget<Stack>(
        find.byKey(const ValueKey('shell-stack')),
      );
      int indexOf(Finder target) => stack.children.indexWhere(
        (child) => find
            .descendant(of: find.byWidget(child), matching: target)
            .evaluate()
            .isNotEmpty,
      );
      final contentIndex = indexOf(find.byKey(const ValueKey('shell-content')));
      final chromeIndex = indexOf(chromeScopes);
      expect(contentIndex, greaterThanOrEqualTo(0), reason: '$size');
      expect(chromeIndex, greaterThan(contentIndex), reason: '$size');
    }
  });

  for (final (from, to, toKey) in [
    (const Size(390, 844), const Size(800, 844), 'shell-medium'),
    (const Size(1440, 900), const Size(390, 844), 'shell-compact'),
    (const Size(800, 844), const Size(1440, 900), 'shell-expanded'),
  ]) {
    testWidgets('branch state survives ${from.width} -> ${to.width}', (
      tester,
    ) async {
      final s = _setup();
      await _pump(tester, s.router, from);
      await tester.tap(find.text('today 0'));
      await tester.pump();
      expect(find.text('today 1'), findsOneWidget);
      tester.view.physicalSize = to;
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey(toKey)), findsOneWidget);
      expect(find.text('today 1'), findsOneWidget);
    });
  }

  testWidgets('compact: safe area moves the toolbar and pads the page', (
    tester,
  ) async {
    tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
    addTearDown(tester.view.resetPadding);
    final s = _setup();
    await _pump(tester, s.router, const Size(390, 844));
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('toolbar-تنظیمات'))).dy,
      61,
    );
    expect(_pagePadding.top, 105);
    expect(_pagePadding.bottom, 34 + 24 + 62 + 16);
  });

  testWidgets('medium: rail and toolbar respect the safe area', (tester) async {
    tester.view.padding = const FakeViewPadding(top: 24);
    addTearDown(tester.view.resetPadding);
    final s = _setup();
    await _pump(tester, s.router, const Size(800, 844));
    expect(tester.getTopLeft(find.byKey(const ValueKey('sidebar'))).dy, 8 + 24);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('toolbar-ورود سریع'))).dy,
      14 + 24,
    );
  });

  testWidgets('Ctrl+K survives text focus and a tab switch', (tester) async {
    final s = _setup();
    await _pump(tester, s.router, const Size(390, 844));
    Future<void> ctrlK() async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    }

    await tester.tap(find.byKey(const ValueKey('field')));
    await tester.pump();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await ctrlK();
    expect(s.log, ['search']);
    await tester.tap(find.byKey(const ValueKey('tab-tasks')));
    await tester.pump();
    await ctrlK();
    expect(s.log, ['search', 'search']);
  });
}
