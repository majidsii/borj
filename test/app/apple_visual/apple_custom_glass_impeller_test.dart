import 'dart:ui' as ui;

import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_liquid_glass_recipe.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_liquid_glass_recipe_resolver.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_visual_family.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_visual_state.dart';
import 'package:dashboard_shakhsi/app/apple_visual/rendering/apple_custom_glass_renderer.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('custom glass constructs an ImageFilter shader on Impeller', (
    tester,
  ) async {
    expect(
      ui.ImageFilter.isShaderFilterSupported,
      isTrue,
      reason: 'Run this test with flutter test --enable-impeller.',
    );

    final AppleLiquidGlassRecipe recipe =
        AppleLiquidGlassRecipeResolver.resolve(
          family: AppleVisualFamily.ios27,
          brightness: Brightness.light,
          role: AppleGlassRole.smallControl,
          state: AppleControlState.idle,
        );

    final glass = const AppleCustomGlassRenderer().build(
      recipe: recipe,
      child: const SizedBox.expand(),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 110,
            height: 78,
            child: Stack(
              children: [
                const Positioned.fill(
                  child: ColoredBox(color: Color(0xFF336699)),
                ),
                Positioned.fill(child: glass),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(BackdropFilter), findsOneWidget);

    final backdrop = tester.widget<BackdropFilter>(find.byType(BackdropFilter));

    expect(backdrop.filter.toString(), contains('ImageFilter.shader'));
  }, skip: !ui.ImageFilter.isShaderFilterSupported);
}
