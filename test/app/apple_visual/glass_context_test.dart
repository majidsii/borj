import 'package:borj/app/apple_visual/glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../support/glass_test_app.dart';

void main() {
  testWidgets('AppGlass marks its subtree as on glass', (tester) async {
    late bool inside;
    late bool outside;
    await tester.pumpWidget(
      glassTestApp(
        Column(
          children: [
            Builder(
              builder: (context) {
                outside = GlassContext.isOnGlass(context);
                return const SizedBox();
              },
            ),
            AppGlass(
              role: GlassRole.panel,
              child: Builder(
                builder: (context) {
                  inside = GlassContext.isOnGlass(context);
                  return const SizedBox(width: 10, height: 10);
                },
              ),
            ),
          ],
        ),
      ),
    );
    expect(outside, isFalse);
    expect(inside, isTrue);
  });

  testWidgets('a GlassScope alone does not mark its subtree', (tester) async {
    late bool value;
    await tester.pumpWidget(
      glassTestApp(
        GlassScope(
          kind: GlassLayerKind.content,
          child: Builder(
            builder: (context) {
              value = GlassContext.isOnGlass(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    expect(value, isFalse);
  });

  testWidgets('glass inside glass asserts', (tester) async {
    await tester.pumpWidget(
      glassTestApp(
        const AppGlass(
          role: GlassRole.panel,
          child: AppGlass(
            role: GlassRole.row,
            child: SizedBox(width: 10, height: 10),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isA<AssertionError>());
  });

  testWidgets('a bare Flutter BackdropGroup does not enlist screen glass', (
    tester,
  ) async {
    await tester.pumpWidget(
      glassTestApp(
        const GlassScope(
          kind: GlassLayerKind.chrome,
          child: AppGlass(
            role: GlassRole.chrome,
            child: SizedBox(width: 10, height: 10),
          ),
        ),
        overlayBackdrop: true,
      ),
    );
    final layer = tester.widget<LiquidGlassLayer>(
      find.byType(LiquidGlassLayer),
    );
    expect(layer.useBackdropGroup, isFalse);
  });

  testWidgets('GlassOverlayContent joins the root group', (tester) async {
    await tester.pumpWidget(
      glassTestApp(
        const GlassOverlayContent(
          child: AppGlass(
            role: GlassRole.sheet,
            child: SizedBox(width: 10, height: 10),
          ),
        ),
        overlayBackdrop: true,
      ),
    );
    final layer = tester.widget<LiquidGlassLayer>(
      find.byType(LiquidGlassLayer),
    );
    expect(layer.useBackdropGroup, isTrue);
  });
}
