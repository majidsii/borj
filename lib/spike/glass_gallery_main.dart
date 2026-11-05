// SPIKE: standalone entry point for the all-glass gallery, used only by the
// spike-glass-android workflow so the APK does not pull in file_picker.
import 'package:dashboard_shakhsi/app/apple_visual/prototype/all_glass_gallery.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlass.precache();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AllGlassGallery(),
    ),
  );
}
