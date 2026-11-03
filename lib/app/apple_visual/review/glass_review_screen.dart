import 'dart:io';

import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_visual_scope.dart';
import 'package:dashboard_shakhsi/app/apple_visual/review/glass_review_samples.dart';
import 'package:flutter/material.dart';

/// Directory with reference captures, supplied at run time. Never committed.
const String glassReferenceDir = String.fromEnvironment('GLASS_REFERENCE_DIR');

/// Debug-only page that shows our glass chrome in light and dark next to the
/// owner's reference captures for side-by-side perceptual review.
final class GlassReviewScreen extends StatelessWidget {
  const GlassReviewScreen({required this.referenceDir, super.key});

  final String? referenceDir;

  static List<File> _referenceImages(String? dir) {
    if (dir == null || dir.isEmpty) {
      return const <File>[];
    }
    try {
      final files =
          Directory(dir)
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.toLowerCase().endsWith('.png'))
              .toList()
            ..sort((a, b) => a.path.compareTo(b.path));
      return files;
    } on Object {
      return const <File>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    final light = AppleVisualScope.resolve(
      brightness: Brightness.light,
      platform: Theme.of(context).platform,
    );
    final dark = AppleVisualScope.resolve(
      brightness: Brightness.dark,
      platform: Theme.of(context).platform,
    );
    final images = _referenceImages(referenceDir);
    return Scaffold(
      appBar: AppBar(title: const Text('Liquid Glass review')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          for (final sample in glassReviewSamples) ...<Widget>[
            Text(sample.label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: GlassReviewBackdrop(
                    dark: false,
                    child: sample.build(light),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlassReviewBackdrop(
                    dark: true,
                    child: sample.build(dark),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
          Text('Reference', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (images.isEmpty)
            const Text('No reference images')
          else
            for (final file in images) ...<Widget>[
              Text(file.uri.pathSegments.last),
              Image.file(
                file,
                errorBuilder: (_, _, _) => const Text('Unreadable'),
              ),
              const SizedBox(height: 16),
            ],
        ],
      ),
    );
  }
}
