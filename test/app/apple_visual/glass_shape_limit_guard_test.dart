import 'package:borj/app/apple_visual/glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_shape_limit.dart';
import '../../support/glass_test_app.dart';

Widget _scope(int shapes) => glassTestApp(
  GlassScope(
    kind: GlassLayerKind.content,
    child: Wrap(
      children: [
        for (var i = 0; i < shapes; i++)
          const AppGlass(
            role: GlassRole.row,
            child: SizedBox(width: 8, height: 8),
          ),
      ],
    ),
  ),
);

void main() {
  testWidgets('a scope with 17 shapes fails the guard', (tester) async {
    await tester.pumpWidget(_scope(17));
    expect(
      () => expectScopesWithinShapeLimit(tester),
      throwsA(isA<TestFailure>()),
    );
  });

  testWidgets('a scope with 16 shapes passes the guard', (tester) async {
    await tester.pumpWidget(_scope(16));
    expectScopesWithinShapeLimit(tester);
  });
}
