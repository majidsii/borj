import 'package:borj/app/apple_visual/glass.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opacity-like widgets between every [AppGlass] below [boundary] and
/// [boundary] itself. A glass must fade through [GlassVisibility], so this must
/// be empty: such a widget only fades the glass's children, not the glass.
List<Widget> bareFadesAboveGlass(WidgetTester tester, Finder boundary) {
  final top = tester.element(boundary.first);
  final found = <Widget>[];
  for (final glass in find.byType(AppGlass).evaluate()) {
    glass.visitAncestorElements((ancestor) {
      if (identical(ancestor, top)) return false;
      final w = ancestor.widget;
      if (w is Opacity || w is FadeTransition || w is AnimatedOpacity) {
        found.add(w);
      }
      return true;
    });
  }
  return found;
}
