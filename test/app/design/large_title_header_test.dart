import 'package:borj/app/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';

void main() {
  for (final v in glassTestVariants) {
    testWidgets('title under subtitle (${v.name})', (tester) async {
      await tester.pumpWidget(
        glassTestApp(
          brightness: v.brightness,
          textScale: v.textScale,
          const SizedBox(
            width: 390,
            child: LargeTitleHeader(
              title: 'امروز',
              subtitle: 'چهارشنبه ۱۳ آبان',
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getTopLeft(find.text('امروز')).dy,
        greaterThan(tester.getTopLeft(find.text('چهارشنبه ۱۳ آبان')).dy),
      );
      expect(find.byType(AppGlass), findsNothing);
    });
  }

  testWidgets('long-press on the title', (tester) async {
    var pressed = false;
    await tester.pumpWidget(
      glassTestApp(
        LargeTitleHeader(
          title: 'امروز',
          onTitleLongPress: () => pressed = true,
        ),
      ),
    );
    await tester.longPress(find.text('امروز'));
    expect(pressed, isTrue);
  });
}
