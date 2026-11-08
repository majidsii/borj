import 'package:borj/app/design/design.dart';
import 'package:borj/app/theme/motion_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/backdrop_layer_count.dart';
import '../../support/glass_fade_expectations.dart';
import '../../support/glass_test_app.dart';
import '../../support/reduced_motion_expectations.dart';

class _GlassPage extends StatelessWidget {
  const _GlassPage({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => GlassScope(
    kind: GlassLayerKind.content,
    child: Center(
      child: AppGlass(
        role: GlassRole.panel,
        shape: const AppleGlassShape.rounded(20),
        child: SizedBox(
          width: 120,
          height: 60,
          child: Center(child: Text(label, key: ValueKey(label))),
        ),
      ),
    ),
  );
}

GoRouter _router({bool materialHome = false}) => GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: materialHome
          ? (context, state) => const _GlassPage(label: 'home')
          : null,
      pageBuilder: materialHome
          ? null
          : (context, state) =>
                const NoTransitionPage<void>(child: _GlassPage(label: 'home')),
      routes: [
        GoRoute(
          path: 'detail',
          pageBuilder: (context, state) => GlassPushPage<void>(
            key: state.pageKey,
            child: const _GlassPage(label: 'detail'),
          ),
        ),
      ],
    ),
  ],
);

Widget _app(
  GoRouter router, {
  double width = 390,
  bool reduceMotion = false,
  Brightness brightness = Brightness.light,
  double textScale = 1.0,
}) {
  return MediaQuery(
    data: MediaQueryData(
      size: Size(width, 844),
      disableAnimations: reduceMotion,
      textScaler: TextScaler.linear(textScale),
    ),
    child: MaterialApp.router(
      routerConfig: router,
      theme: glassTestTheme(brightness),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: MotionScope(
          reduceMotionSetting: false,
          child: GlassPreferencesScope(
            intensity: 0.5,
            reduceTransparency: false,
            child: child!,
          ),
        ),
      ),
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
    expect(
      x,
      lessThan(195),
      reason: 'mid-push the page is still left of centre',
    );
    await tester.pumpAndSettle();
    expect(
      tester.getCenter(find.byKey(const ValueKey('detail'))).dx,
      closeTo(195, 0.5),
    );
  });

  testWidgets('compact: the outgoing page dims with a scrim, not an opacity', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = _router();
    await tester.pumpWidget(_app(router));
    router.go('/detail');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byKey(const ValueKey('push-scrim')), findsWidgets);
    expect(find.byType(AppGlass), findsWidgets);
    expect(bareFadesAboveGlass(tester, find.byType(Navigator)), isEmpty);
    await tester.pumpAndSettle();
  });

  testWidgets('compact RTL: back swipe from the right edge pops', (
    tester,
  ) async {
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

  for (final (name, width, reduce) in [
    ('expanded', 1440.0, false),
    ('medium', 800.0, false),
    ('compact reduced', 390.0, true),
  ]) {
    testWidgets('$name: instant', (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final router = _router();
      await tester.pumpWidget(_app(router, width: width, reduceMotion: reduce));
      router.go('/detail');
      await tester.pump();
      await tester.pump();
      expect(
        tester.getCenter(find.byKey(const ValueKey('detail'))).dx,
        closeTo(width / 2, 0.5),
      );
      expect(find.byKey(const ValueKey('home')), findsNothing);
    });
  }

  testWidgets('compact RTL: the outgoing page drifts right (parallax)', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = _router(materialHome: true);
    await tester.pumpWidget(_app(router));
    router.go('/detail');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final x = tester.getCenter(find.byKey(const ValueKey('home'))).dx;
    expect(x, greaterThan(195));
    await tester.pumpAndSettle();
  });

  testWidgets('no framework barrier colour stacks under the token scrim', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = _router();
    await tester.pumpWidget(_app(router));
    router.go('/detail');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    for (final b in tester.widgetList<ModalBarrier>(
      find.byType(ModalBarrier),
    )) {
      expect(b.color == null || b.color == Colors.transparent, isTrue);
    }
    await tester.pumpAndSettle();
  });

  testWidgets('a push on compact then widening, then pop, is not frozen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = _router();
    await tester.pumpWidget(_app(router));
    router.go('/detail');
    await tester.pumpAndSettle();
    await tester.binding.setSurfaceSize(const Size(1440, 844));
    await tester.pumpWidget(_app(router, width: 1440));
    router.pop();
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('home')), findsOneWidget);
    expect(find.byKey(const ValueKey('detail')), findsNothing);
  });

  for (final (name, width, reduce) in [
    ('expanded', 1440.0, false),
    ('medium', 800.0, false),
    ('compact reduced', 390.0, true),
  ]) {
    testWidgets('$name: no back swipe, no parallax, no movement', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final router = _router();
      await tester.pumpWidget(_app(router, width: width, reduceMotion: reduce));
      final homeX = tester.getCenter(find.byKey(const ValueKey('home'))).dx;
      await expectNoMovement(
        tester,
        within: find.byType(Navigator),
        trigger: () async {
          router.go('/detail');
          await tester.pump();
        },
      );
      await tester.pumpAndSettle();
      expect(homeX, closeTo(width / 2, 0.5));
      final gesture = await tester.startGesture(Offset(width - 2, 400));
      await gesture.moveBy(const Offset(-300, 0));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('detail')), findsOneWidget);
    });
  }

  for (final v in glassTestVariants) {
    testWidgets('renders (${v.name})', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final router = _router();
      await tester.pumpWidget(
        _app(router, brightness: v.brightness, textScale: v.textScale),
      );
      router.go('/detail');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('detail')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a pushed page shares one backdrop group for all its glass', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    Widget shapes(int n) => Column(
      children: [
        for (var i = 0; i < n; i++)
          GlassScope(
            kind: GlassLayerKind.content,
            child: AppGlass(
              role: GlassRole.panel,
              shape: const AppleGlassShape.rounded(20),
              child: const SizedBox(width: 100, height: 40),
            ),
          ),
      ],
    );
    Future<int> countFor(int n) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) =>
                const NoTransitionPage<void>(child: SizedBox()),
            routes: [
              GoRoute(
                path: 'p',
                pageBuilder: (context, state) =>
                    GlassPushPage<void>(key: state.pageKey, child: shapes(n)),
              ),
            ],
          ),
        ],
      );
      await tester.pumpWidget(_app(router));
      router.go('/p');
      await tester.pumpAndSettle();
      expect(
        find
            .ancestor(
              of: find.byType(AppGlass),
              matching: find.byType(GlassBackdropGroup),
            )
            .evaluate()
            .toSet(),
        hasLength(1),
      );
      return countCompositedBackdrops(tester);
    }

    final one = await countFor(1);
    await tester.pumpWidget(const SizedBox.shrink());
    final three = await countFor(3);
    expect(three, one);
  });
}
