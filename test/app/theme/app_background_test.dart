// test/app/theme/app_background_test.dart
import 'package:borj/app/theme/app_background.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, Brightness b) => tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        brightness: b,
        extensions: [b == Brightness.dark ? AppTheme.dark : AppTheme.light],
      ),
      home: const AppBackground(
        kind: AppBackgroundKind.phone,
        child: Text('x'),
      ),
    ),
  );

  testWidgets('light is plain white', (tester) async {
    await pump(tester, Brightness.light);
    final box = tester.widget<ColoredBox>(
      find
          .descendant(
            of: find.byType(AppBackground),
            matching: find.byType(ColoredBox),
          )
          .first,
    );
    expect(box.color, const Color(0xFFFFFFFF));
    expect(find.text('x'), findsOneWidget);
  });

  testWidgets('dark has the charcoal gradient and a warm glow', (tester) async {
    await pump(tester, Brightness.dark);
    final decorations = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(AppBackground),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((d) => d.decoration)
        .whereType<BoxDecoration>()
        .toList();
    final linear = decorations
        .map((d) => d.gradient)
        .whereType<LinearGradient>()
        .single;
    expect(linear.colors, [const Color(0xFF232427), const Color(0xFF18191C)]);
    final radial = decorations
        .map((d) => d.gradient)
        .whereType<RadialGradient>()
        .single;
    expect(radial.colors.first, AppTheme.dark.colors.warmGlow);
  });
}
