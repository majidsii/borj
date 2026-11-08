import 'package:borj/app/design/design.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:borj/features/today/presentation/today_card.dart';
import 'package:flutter/material.dart';

/// The board `PhoneEmptyToday`, with only the steps whose feature exists
/// (plan Decision 2).
class TodayOnboarding extends StatelessWidget {
  const TodayOnboarding({required this.onAddTask, super.key});

  final VoidCallback onAddTask;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TodayCard(
          padding: EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                'روز تازه‌ای است',
                role: AppTextRole.headline,
                weight: FontWeight.w900,
              ),
              SizedBox(height: AppSpacing.s4),
              AppText(
                'چند قدم کوچک، و داشبوردت زنده می‌شود.',
                role: AppTextRole.footnote,
                tone: AppTextTone.secondary,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        TodayCard(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText(
                      'اولین کار را بنویس',
                      role: AppTextRole.subheadline,
                      weight: FontWeight.w800,
                    ),
                    SizedBox(height: AppSpacing.s4),
                    AppText(
                      'مثلاً «ورزش صبح» با ساعت و یادآور.',
                      role: AppTextRole.footnote,
                      tone: AppTextTone.secondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Pressable(
                key: const ValueKey('onboarding-add-task'),
                onPressed: onAddTask,
                semanticLabel: 'افزودن کار',
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Center(
                    child: GlassInner(
                      child: SizedBox(
                        height: 36,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Center(
                            child: AppText(
                              'افزودن کار',
                              role: AppTextRole.footnote,
                              tone: AppTextTone.link,
                              weight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.s8),
          child: AppText(
            'هر وقت خواستی، با دکمهٔ مثبت بالا چیزی اضافه کن.',
            role: AppTextRole.footnote,
            tone: AppTextTone.secondary,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
