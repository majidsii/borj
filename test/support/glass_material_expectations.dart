import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// The `fake` flag of every glass layer in the tree: true is the flat
/// reduced-transparency material (cards and rows), false is real glass (bars).
List<bool> glassLayerFakeFlags(WidgetTester tester) => tester
    .widgetList<LiquidGlassLayer>(find.byType(LiquidGlassLayer))
    .map((l) => l.fake)
    .toList();
