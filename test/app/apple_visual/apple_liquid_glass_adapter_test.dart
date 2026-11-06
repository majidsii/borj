import 'package:borj/app/apple_visual/foundation/apple_glass_shape.dart';
import 'package:borj/app/apple_visual/foundation/apple_liquid_glass_recipe.dart';
import 'package:borj/app/apple_visual/widgets/apple_liquid_glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dark and light settings differ for the same role', () {
    expect(
      AppleLiquidGlass.settingsFor(
        AppleGlassRole.smallControl,
        Brightness.light,
      ),
      isNot(
        AppleLiquidGlass.settingsFor(
          AppleGlassRole.smallControl,
          Brightness.dark,
        ),
      ),
    );
  });

  testWidgets('renders its child for every role', (tester) async {
    for (final role in AppleGlassRole.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: AppleLiquidGlass(
              role: role,
              shape: const AppleGlassShape.rounded(20),
              child: Text('child-${role.name}'),
            ),
          ),
        ),
      );
      expect(find.text('child-${role.name}'), findsOneWidget);
    }
  });
}
