import 'package:borj/app/apple_visual/widgets/apple_liquid_glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/backdrop_capture_log.dart';

void main() {
  testWidgets('five ungrouped glass shapes are counted as five captures', (
    tester,
  ) async {
    final record = await BackdropCaptureLog.record(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              for (var i = 0; i < 5; i++)
                const AppGlass(
                  role: GlassRole.chrome,
                  child: SizedBox(width: 40, height: 40),
                ),
            ],
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    });
    // ignore: avoid_print
    print('SANITY_COUNT ${record.maxCaptures}');
    expect(
      record.maxCaptures,
      greaterThanOrEqualTo(5),
      reason:
          'the debug counter is not observable; the budget tests are invalid',
    );
  });
}
