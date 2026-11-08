import 'package:borj/app/design/design.dart';
import 'package:borj/features/today/presentation/today_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';

void main() {
  testWidgets(
    'one content scope, one panel glass of radius 26, child on glass',
    (tester) async {
      var onGlass = false;
      await tester.pumpWidget(
        glassTestApp(
          TodayCard(
            child: Builder(
              builder: (context) {
                onGlass = GlassContext.isOnGlass(context);
                return const SizedBox(
                  key: ValueKey('child'),
                  width: 50,
                  height: 50,
                );
              },
            ),
          ),
        ),
      );
      final scope = find.byWidgetPredicate(
        (w) => w is GlassScope && w.kind == GlassLayerKind.content,
      );
      expect(scope, findsOneWidget);
      final glass = find.byType(AppGlass);
      expect(glass, findsOneWidget);
      final w = tester.widget<AppGlass>(glass);
      expect(w.role, GlassRole.panel);
      expect(w.shape.kind, AppleGlassShapeKind.rounded);
      expect(w.shape.radius, 26);
      expect(
        find.descendant(
          of: glass,
          matching: find.byKey(const ValueKey('child')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: glass, matching: find.byType(AppGlass)),
        findsNothing,
      );
      expect(onGlass, isTrue);
    },
  );

  testWidgets('semanticLabel wraps the card in a labelled container', (
    tester,
  ) async {
    await tester.pumpWidget(
      glassTestApp(
        const TodayCard(semanticLabel: 'برنامهٔ امروز', child: SizedBox()),
      ),
    );
    expect(find.bySemanticsLabel('برنامهٔ امروز'), findsOneWidget);
  });

  for (final v in glassTestVariants) {
    testWidgets('renders (${v.name})', (tester) async {
      await tester.pumpWidget(
        glassTestApp(
          const SizedBox(
            width: 200,
            height: 164,
            child: TodayCard(child: AppText('برنامهٔ امروز')),
          ),
          brightness: v.brightness,
          textScale: v.textScale,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('برنامهٔ امروز'), findsOneWidget);
    });
  }
}
