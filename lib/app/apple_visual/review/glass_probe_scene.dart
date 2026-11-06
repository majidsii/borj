import 'package:flutter/material.dart';

import '../../theme/app_background.dart';
import '../../theme/app_theme.dart';
import '../foundation/apple_glass_shape.dart';
import '../widgets/apple_liquid_glass.dart';

/// Glass layout of the Today boards, used by the capture-budget tests and the
/// device perf probe. Content is placeholder; only the glass structure matters.
final class GlassProbeScene extends StatelessWidget {
  const GlassProbeScene.phone({super.key}) : desktop = false;
  const GlassProbeScene.desktop({super.key}) : desktop = true;

  static const Key scrollKey = Key('glass-probe-scroll');

  final bool desktop;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AppBackground(
        kind: desktop ? AppBackgroundKind.desk : AppBackgroundKind.phone,
        child: desktop ? const _Desktop() : const _Phone(),
      ),
    );
  }
}

Widget _section(GlassRole role, int rows) => GlassScope(
  kind: GlassLayerKind.content,
  child: Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.s16,
      vertical: AppSpacing.s8,
    ),
    child: Column(
      children: [
        for (var i = 0; i < rows; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s8),
            child: AppGlass(
              role: role,
              shape: const AppleGlassShape.rounded(AppRadii.card),
              child: const SizedBox(height: 56, width: double.infinity),
            ),
          ),
      ],
    ),
  ),
);

final class _Phone extends StatelessWidget {
  const _Phone();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GlassBackdropGroup(
            child: ListView.builder(
              key: GlassProbeScene.scrollKey,
              padding: const EdgeInsets.only(top: 60, bottom: 120),
              itemCount: 4,
              itemBuilder: (context, i) =>
                  _section(i.isEven ? GlassRole.panel : GlassRole.row, 6),
            ),
          ),
        ),
        Positioned(
          left: AppSpacing.s16,
          right: AppSpacing.s16,
          bottom: 24,
          child: GlassScope(
            kind: GlassLayerKind.chrome,
            child: Row(
              children: [
                const Expanded(
                  child: AppGlass(
                    role: GlassRole.chrome,
                    child: SizedBox(height: 62),
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                const AppGlass(
                  role: GlassRole.chrome,
                  shape: AppleGlassShape.circle(),
                  child: SizedBox.square(dimension: 62),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

final class _Desktop extends StatelessWidget {
  const _Desktop();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 260,
          child: GlassBackdropGroup(
            child: Column(
              children: [
                const GlassScope(
                  kind: GlassLayerKind.chrome,
                  child: AppGlass(
                    role: GlassRole.chrome,
                    shape: AppleGlassShape.rounded(AppRadii.card),
                    child: SizedBox(height: 600, width: 240),
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),
                GlassScope(
                  kind: GlassLayerKind.chrome,
                  child: Row(
                    children: const [
                      AppGlass(
                        role: GlassRole.chrome,
                        child: SizedBox(width: 36, height: 36),
                      ),
                      AppGlass(
                        role: GlassRole.tinted,
                        child: SizedBox(width: 72, height: 36),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: GlassBackdropGroup(
            child: ListView(
              key: GlassProbeScene.scrollKey,
              children: [
                _section(GlassRole.panel, 6),
                _section(GlassRole.row, 6),
              ],
            ),
          ),
        ),
        const SizedBox(
          width: 320,
          child: AppGlass(
            role: GlassRole.sheet,
            shape: AppleGlassShape.rounded(AppRadii.sheet),
            child: SizedBox.expand(),
          ),
        ),
      ],
    );
  }
}
