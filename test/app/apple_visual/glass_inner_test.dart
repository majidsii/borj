import 'package:borj/app/apple_visual/foundation/apple_glass_shape.dart';
import 'package:borj/app/apple_visual/widgets/glass_inner.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

void main() {
  testWidgets('inner material is flat: no glass layer, kit fill and edge', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [AppTheme.light]),
        home: const GlassInner(
          shape: AppleGlassShape.rounded(16),
          child: Text('in'),
        ),
      ),
    );
    expect(find.byType(LiquidGlassLayer), findsNothing);
    final box = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(GlassInner),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final d = box.decoration as BoxDecoration;
    final g = d.gradient! as LinearGradient;
    expect(g.colors, [
      AppTheme.light.colors.innerTop,
      AppTheme.light.colors.innerBottom,
    ]);
    expect((d.border! as Border).top.color, AppTheme.light.colors.innerEdge);
    expect(d.borderRadius, BorderRadius.circular(16));
  });
}
