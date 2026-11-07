// test/app/design/glass_text_field_test.dart
import 'package:borj/app/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';

void main() {
  for (final v in glassTestVariants) {
    testWidgets('renders with label and hint (${v.name})', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        glassTestApp(
          SizedBox(
            width: 300,
            child: GlassTextField(
              controller: controller,
              label: 'عنوان',
              hint: 'مثلاً خرید نان',
            ),
          ),
          brightness: v.brightness,
          textScale: v.textScale,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('عنوان'), findsOneWidget);
      expect(find.text('مثلاً خرید نان'), findsOneWidget);
    });
  }

  testWidgets('typing updates the controller; focus shows the ring', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      glassTestApp(
        SizedBox(
          width: 300,
          child: GlassTextField(controller: controller, hint: 'h'),
        ),
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.enterText(find.byType(TextField), 'نان');
    expect(controller.text, 'نان');
    expect(
      find.byKey(const ValueKey('glass-field-focus-ring')),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 250));
    final ring = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('glass-field-focus-ring')),
    );
    final border = (ring.decoration as BoxDecoration).border! as Border;
    expect(border.top.color.a, 1);
    expect(border.top.width, 1.5);
  });

  testWidgets('off glass is a row glass; on glass is flat', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      glassTestApp(
        SizedBox(width: 300, child: GlassTextField(controller: controller)),
      ),
    );
    expect(tester.widget<AppGlass>(find.byType(AppGlass)).role, GlassRole.row);
    await tester.pumpWidget(
      glassTestApp(
        AppGlass(
          role: GlassRole.sheet,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: 300,
              child: GlassTextField(controller: controller),
            ),
          ),
        ),
      ),
    );
    expect(find.byType(AppGlass), findsOneWidget);
    expect(find.byType(GlassInner), findsOneWidget);
  });
}
