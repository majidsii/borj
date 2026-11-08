import 'package:borj/app/design/design.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:borj/core/formatting/persian_number.dart';
import 'package:borj/features/today/application/today_providers.dart';
import 'package:borj/features/today/presentation/today_card.dart';
import 'package:borj/features/today/presentation/today_grid.dart';
import 'package:flutter/material.dart';

/// The board's upcoming-installment card (no due date: plan Decision 1).
class InstallmentCard extends StatelessWidget {
  const InstallmentCard({
    required this.installment,
    required this.onOpen,
    this.size = TodayCardSize.wide,
    this.animateIn = false,
    super.key,
  });

  final TodayInstallment installment;
  final VoidCallback onOpen;
  final TodayCardSize size;
  final bool animateIn;

  @override
  Widget build(BuildContext context) {
    final i = installment;
    final progressText =
        'قسط ${formatPersianInteger(i.nextNumber)} از ${formatPersianInteger(i.count)}';
    final amount = AppText(
      i.amount.formatMajorUnits(),
      weight: FontWeight.w900,
      tabular: true,
    );
    final title = AppText(i.title, weight: FontWeight.w700, maxLines: 1);
    final sub = AppText(
      progressText,
      role: AppTextRole.footnote,
      tone: AppTextTone.secondary,
      maxLines: 1,
    );
    final content = size == TodayCardSize.small
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              title,
              const SizedBox(height: AppSpacing.s4),
              sub,
              const SizedBox(height: AppSpacing.s8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: amount,
              ),
            ],
          )
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        title,
                        const SizedBox(height: AppSpacing.s4),
                        sub,
                      ],
                    ),
                  ),
                  amount,
                ],
              ),
              const SizedBox(height: AppSpacing.s12),
              ProgressTrack(
                value: i.progress,
                animateIn: animateIn,
                semanticLabel:
                    '${formatPersianInteger(i.nextNumber - 1)} از ${formatPersianInteger(i.count)} قسط پرداخت شده',
              ),
            ],
          );
    return TodayCard(
      child: Pressable(
        onPressed: onOpen,
        semanticLabel: 'قسط ${i.title}',
        child: SizedBox.expand(child: content),
      ),
    );
  }
}
