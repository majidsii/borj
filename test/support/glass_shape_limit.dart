import 'package:borj/app/apple_visual/glass.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const int _maxShapesPerScope = 16;

/// Fails if any [GlassScope] in the tree holds more than 16 [AppGlass] shapes
/// (the renderer's per-layer cap). Counts only shapes whose nearest scope is
/// that scope. The FakeGlass path never prints the renderer's own warning, so
/// this structural check guards ordinary `flutter test`.
void expectScopesWithinShapeLimit(WidgetTester tester) {
  for (final element in find.byType(GlassScope).evaluate()) {
    var count = 0;
    void visit(Element e) {
      if (e.widget is GlassScope) return;
      if (e.widget is AppGlass) count++;
      e.visitChildren(visit);
    }

    element.visitChildren(visit);
    if (count > _maxShapesPerScope) {
      final kind = (element.widget as GlassScope).kind.name;
      fail('a GlassScope holds more than 16 shapes: $kind scope has $count');
    }
  }
}
