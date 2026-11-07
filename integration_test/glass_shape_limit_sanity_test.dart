import 'dart:ui' as ui;

import 'package:borj/app/apple_visual/glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/backdrop_capture_log.dart';
import '../test/support/glass_test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('17 shapes in one scope are reported on real glass', (
    tester,
  ) async {
    expect(
      ui.ImageFilter.isShaderFilterSupported,
      isTrue,
      reason:
          'shader filters unavailable: real glass is not active, the renderer would not warn',
    );
    final record = await BackdropCaptureLog.record(() async {
      await tester.pumpWidget(
        glassTestApp(
          GlassScope(
            kind: GlassLayerKind.content,
            child: Wrap(
              children: [
                for (var i = 0; i < 17; i++)
                  const AppGlass(
                    role: GlassRole.row,
                    child: SizedBox(width: 8, height: 8),
                  ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    });
    expect(record.shapeLimitExceeded, isTrue);
  });
}
