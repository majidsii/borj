import 'package:borj/app/design/design.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:borj/core/formatting/persian_number.dart';
import 'package:borj/features/settings/application/appearance_preferences_controller.dart';
import 'package:borj/features/settings/domain/appearance_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The «ظاهر» section of Settings: one panel glass, everything inside flat.
class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(appearancePreferencesProvider);
    final controller = ref.read(appearancePreferencesProvider.notifier);
    final colors = AppTheme.of(context).colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 12, 6),
          child: AppText(
            'ظاهر',
            role: AppTextRole.footnote,
            weight: FontWeight.w800,
          ),
        ),
        AppGlass(
          role: GlassRole.panel,
          shape: const AppleGlassShape.rounded(AppRadii.card),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 10),
                  child: GlassSegmented<AppearanceMode>(
                    semanticLabel: 'حالت ظاهری',
                    selected: prefs.mode,
                    onChanged: controller.setMode,
                    segments: const [
                      GlassSegment(value: AppearanceMode.light, label: 'روشن'),
                      GlassSegment(value: AppearanceMode.dark, label: 'تیره'),
                      GlassSegment(
                        value: AppearanceMode.system,
                        label: 'خودکار',
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Expanded(
                      child: AppText(
                        'شدت شیشه',
                        role: AppTextRole.callout,
                        weight: FontWeight.w600,
                      ),
                    ),
                    AppText(
                      formatPersianPercent(prefs.glassIntensity),
                      role: AppTextRole.callout,
                      tone: AppTextTone.secondary,
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      const AppIcon(Icons.blur_on, tone: AppTextTone.secondary),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: colors.accent,
                            inactiveTrackColor: colors.switchOff,
                            thumbColor: colors.thumbSurface,
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 12,
                            ),
                            overlayColor: Colors.transparent,
                          ),
                          child: Slider(
                            value: prefs.glassIntensity,
                            onChanged: controller.previewGlassIntensity,
                            onChangeEnd: (_) =>
                                controller.commitGlassIntensity(),
                            semanticFormatterCallback: formatPersianPercent,
                          ),
                        ),
                      ),
                      const AppIcon(
                        Icons.blur_off,
                        tone: AppTextTone.secondary,
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 4, bottom: 12),
                  child: AppText(
                    'کم‌شدت‌تر یعنی شفاف‌تر و ساده‌تر؛ پرشدت‌تر یعنی خواناتر.',
                    role: AppTextRole.footnote,
                    tone: AppTextTone.secondary,
                  ),
                ),
                _SwitchRow(
                  title: 'کاهش حرکت',
                  subtitle: 'حرکت‌ها به محو شدن ساده تبدیل می‌شوند',
                  value: prefs.reduceMotion,
                  onChanged: controller.setReduceMotion,
                ),
                _SwitchRow(
                  title: 'کاهش شفافیت',
                  subtitle:
                      'کارت‌ها و ردیف‌ها مات می‌شوند؛ نوارها شیشه می‌مانند',
                  value: prefs.reduceTransparency,
                  onChanged: controller.setReduceTransparency,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context).colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.hairline, width: 0.5)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText(
                      title,
                      role: AppTextRole.callout,
                      weight: FontWeight.w700,
                    ),
                    AppText(
                      subtitle,
                      role: AppTextRole.footnote,
                      tone: AppTextTone.secondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GlassToggle(
                value: value,
                onChanged: onChanged,
                semanticLabel: title,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
