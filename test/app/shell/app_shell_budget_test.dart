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
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: Padding(
          padding: MediaQuery.paddingOf(context),
          child: GlassScope(
            kind: GlassLayerKind.content,
            child: Column(
              children: [
                for (var i = 0; i < 4; i++)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: AppGlass(
                      role: GlassRole.panel,
                      shape: AppleGlassShape.rounded(24),
                      child: SizedBox(height: 80, width: double.infinity),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      if (inspector)
        const PositionedDirectional(
          end: 8,
          top: 8,
          bottom: 8,
          width: GlassInspector.width,
          child: GlassInspector(open: true, child: SizedBox()),
        ),
    ],
  );
}

GoRouter _router({bool inspector = false}) => GoRouter(
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
              onPressed: (_) {},
            ),
          ShellAction(
            icon: Icons.add,
            label: 'ورود سریع',
            primary: true,
            onPressed: (_) {},
          ),
        ],
        onSettings: () {},
        onSearch: () {},
      ),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (c, s) => _Page(inspector: inspector),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/tasks', builder: (c, s) => const _Page())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/finance', builder: (c, s) => const _Page())],
        ),
      ],
    ),
  ],
);

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
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      theme: glassTestTheme(Brightness.light),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: GlassOverlayBackdrop(child: child!),
      ),
    ),
  );
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

  testWidgets('a page inside the shell creates no backdrop group of its own', (
    tester,
  ) async {
    await _pump(tester, _router(), const Size(390, 844));
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('shell-content')),
        matching: find.byType(GlassBackdropGroup),
      ),
      findsNothing,
    );
  });
}
