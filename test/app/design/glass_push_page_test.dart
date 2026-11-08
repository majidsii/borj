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
      builder: (context, state) =>
          const Center(child: Text('home', key: ValueKey('home'))),
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
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
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
}
