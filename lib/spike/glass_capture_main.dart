// SPIKE: entry point of the real-glass screenshot harness (tool/capture_glass.sh).
import 'package:dashboard_shakhsi/app/apple_visual/prototype/capture/capture_registry.dart';
import 'package:dashboard_shakhsi/app/apple_visual/prototype/capture/glass_capture_app.dart';
import 'package:flutter/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(GlassCaptureApp(entries: captureRegistry));
}
