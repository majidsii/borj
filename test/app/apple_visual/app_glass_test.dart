import 'package:borj/app/apple_visual/foundation/apple_glass_shape.dart';
import 'package:borj/app/apple_visual/foundation/glass_preferences_scope.dart';
import 'package:borj/app/apple_visual/widgets/apple_liquid_glass.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

Widget _app(
  Widget child, {
  bool reduceTransparency = false,
  Brightness b = Brightness.light,
}) => MaterialApp(
  theme: ThemeData(
    brightness: b,
    extensions: [b == Brightness.dark ? AppTheme.dark : AppTheme.light],
  ),
  home: GlassPreferencesScope(
    intensity: 0.5,
    reduceTransparency: reduceTransparency,
    child: Center(child: child),
  ),
);

Widget _contentScope() => const GlassScope(
  kind: GlassLayerKind.content,
  child: Column(
    children: [
      AppGlass(
        role: GlassRole.panel,
        shape: AppleGlassShape.rounded(24),
        child: SizedBox(width: 100, height: 40),
      ),
      AppGlass(role: GlassRole.row, child: SizedBox(width: 100, height: 40)),
    ],
  ),
);

void main() {
  test('layer settings per kind follow the intensity slider', () {
    expect(
      AppGlass.settingsFor(GlassLayerKind.content, Brightness.light, 0.5),
      LiquidGlassSettings.ios27Regular(
        brightness: Brightness.light,
        tintAmount: 0.5,
      ),
    );
    expect(
      AppGlass.settingsFor(GlassLayerKind.sheet, Brightness.dark, 0.9),
      LiquidGlassSettings.ios27Regular(
        brightness: Brightness.dark,
        tintAmount: 1.0,
      ),
    );
    expect(
      AppGlass.settingsFor(GlassLayerKind.clear, Brightness.light, 0.2),
      LiquidGlassSettings.ios27Clear(tintAmount: 0.2),
    );
  });

  testWidgets('a scope is one layer for all its shapes', (tester) async {
    await tester.pumpWidget(_app(_contentScope()));
    expect(find.byType(LiquidGlassLayer), findsOneWidget);
    expect(find.byType(AppGlass), findsNWidgets(2));
  });

  testWidgets('standalone glass gets its own layer', (tester) async {
    await tester.pumpWidget(
      _app(
        const AppGlass(
          role: GlassRole.chrome,
          child: SizedBox(width: 40, height: 40),
        ),
      ),
    );
    expect(find.byType(LiquidGlassLayer), findsOneWidget);
  });

  testWidgets('reduce transparency fakes content layers only', (tester) async {
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            _contentScope(),
            const GlassScope(
              kind: GlassLayerKind.chrome,
              child: AppGlass(
                role: GlassRole.chrome,
                child: SizedBox(width: 40, height: 40),
              ),
            ),
          ],
        ),
        reduceTransparency: true,
      ),
    );
    final layers = tester
        .widgetList<LiquidGlassLayer>(find.byType(LiquidGlassLayer))
        .toList();
    expect(layers.map((l) => l.fake), [true, false]);
  });

  testWidgets('scopes under a backdrop group share the backdrop', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        GlassBackdropGroup(
          child: Column(children: [_contentScope(), _contentScope()]),
        ),
      ),
    );
    final layers = tester.widgetList<LiquidGlassLayer>(
      find.byType(LiquidGlassLayer),
    );
    expect(layers.every((l) => l.useBackdropGroup), isTrue);
  });

  testWidgets('a role that does not belong to the scope kind asserts', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const GlassScope(
          kind: GlassLayerKind.content,
          child: AppGlass(role: GlassRole.chrome, child: SizedBox()),
        ),
      ),
    );
    expect(tester.takeException(), isA<AssertionError>());
  });

  test('concentric inner radius', () {
    expect(const AppleGlassShape.rounded(24).concentricInner(8).radius, 16);
    expect(const AppleGlassShape.rounded(6).concentricInner(8).radius, 0);
    expect(
      const AppleGlassShape.capsule().concentricInner(8).kind,
      AppleGlassShapeKind.capsule,
    );
  });
}
