import 'dart:io';

import 'package:borj/app/apple_visual/foundation/apple_visual_scope.dart';
import 'package:borj/app/apple_visual/foundation/glass_preferences_scope.dart';
import 'package:borj/app/apple_visual/review/design_review_samples.dart';
import 'package:borj/app/apple_visual/review/glass_review_samples.dart';
import 'package:borj/app/theme/app_background.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:borj/app/theme/motion_scope.dart';
import 'package:flutter/material.dart';

/// Directory with reference captures, supplied at run time. Never committed.
const String glassReferenceDir = String.fromEnvironment('GLASS_REFERENCE_DIR');

/// Debug-only page that shows our glass chrome in light and dark next to the
/// owner's reference captures for side-by-side perceptual review.
///
/// The "Design" section renders each [designReviewSamples] entry in light and
/// dark over [AppBackground] and pairs it with its board PNG
/// (`<dir>/<board>.png` and `<dir>/<board>Dark.png`). Shoot the boards with
/// `python3 docs/superpowers/references/2026-11-05-glass-mockups/source/shoot.py /tmp/borj-boards PhoneTasks PhoneTasksDark ...`
/// and run with `--dart-define=GLASS_REFERENCE_DIR=/tmp/borj-boards`.
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
          Text('Design', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          for (final sample in designReviewSamples)
            _DesignSampleCard(sample: sample, referenceDir: referenceDir),
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

class _DesignSampleCard extends StatelessWidget {
  const _DesignSampleCard({required this.sample, required this.referenceDir});

  final DesignReviewSample sample;
  final String? referenceDir;

  File? _board(String name) {
    final dir = referenceDir;
    if (dir == null || dir.isEmpty) {
      return null;
    }
    final file = File('$dir/$name.png');
    return file.existsSync() ? file : null;
  }

  @override
  Widget build(BuildContext context) {
    final light = _board(sample.board);
    final dark = _board('${sample.board}Dark');
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(sample.label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _DesignSide(
                  brightness: Brightness.light,
                  sample: sample,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DesignSide(brightness: Brightness.dark, sample: sample),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (light == null && dark == null)
            Text('board: ${sample.board}')
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: _boardImage(light)),
                const SizedBox(width: 12),
                Expanded(child: _boardImage(dark)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _boardImage(File? file) => file == null
      ? const SizedBox.shrink()
      : Image.file(file, errorBuilder: (_, _, _) => const Text('Unreadable'));
}

/// One side of a pair: its own theme, motion and glass preferences, so each
/// side is a single surface.
class _DesignSide extends StatelessWidget {
  const _DesignSide({required this.brightness, required this.sample});

  final Brightness brightness;
  final DesignReviewSample sample;

  @override
  Widget build(BuildContext context) {
    final dark = brightness == Brightness.dark;
    return Theme(
      data: ThemeData(
        brightness: brightness,
        extensions: <ThemeExtension<dynamic>>[
          dark ? AppTheme.dark : AppTheme.light,
        ],
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: MotionScope(
          reduceMotionSetting: false,
          child: GlassPreferencesScope(
            intensity: 0.5,
            reduceTransparency: false,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AppBackground(
                kind: AppBackgroundKind.phone,
                child: Material(
                  type: MaterialType.transparency,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 80),
                      child: SizedBox(
                        width: double.infinity,
                        child: sample.darkOnly && !dark
                            ? const Center(child: Text('dark only'))
                            : Builder(builder: sample.build),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
