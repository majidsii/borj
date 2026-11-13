import 'package:borj/app/design/design.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:borj/core/money/money.dart';
import 'package:borj/features/tasks/application/task_list_query.dart';
import 'package:flutter/material.dart';

const double _gap = 10;
const double _tileHeight = 56;
const double _tileRadius = 22;

/// The 2 × 2 smart filter tiles of the Tasks list: one content scope holds
/// the four row-glass tiles; the selected tile shows a flat lens.
class TaskSmartTiles extends StatelessWidget {
  const TaskSmartTiles({
    required this.counts,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final TaskSmartCounts counts;
  final TaskSmartFilter selected;
  final ValueChanged<TaskSmartFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context).colors;
    Widget tile(
      TaskSmartFilter filter,
      String label,
      IconData icon,
      Color color,
      int count, {
      bool dangerCount = false,
    }) {
      return Expanded(
        child: _Tile(
          key: ValueKey('task-tile-${filter.name}'),
          label: label,
          icon: icon,
          color: color,
          count: count,
          dangerCount: dangerCount,
          selected: selected == filter,
          onTap: () => onSelected(filter),
        ),
      );
    }

    // In RTL the first child of a Row sits at the right edge.
    return GlassScope(
      kind: GlassLayerKind.content,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              tile(
                TaskSmartFilter.today,
                'امروز',
                Icons.today_rounded,
                colors.accent,
                counts.today,
              ),
              const SizedBox(width: _gap),
              tile(
                TaskSmartFilter.timed,
                'زمان‌دار',
                Icons.schedule_rounded,
                colors.warn,
                counts.timed,
              ),
            ],
          ),
          const SizedBox(height: _gap),
          Row(
            children: [
              tile(
                TaskSmartFilter.overdue,
                'عقب‌افتاده',
                Icons.warning_amber_rounded,
                colors.danger,
                counts.overdue,
                dangerCount: true,
              ),
              const SizedBox(width: _gap),
              tile(
                TaskSmartFilter.all,
                'همه',
                Icons.inbox_rounded,
                colors.textSecondary,
                counts.all,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.icon,
    required this.color,
    required this.count,
    required this.dangerCount,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color color;
  final int count;
  final bool dangerCount;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const shape = AppleGlassShape.rounded(_tileRadius);
    final digits = Money.toPersianDigits('$count');
    final body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: SizedBox(
              width: 32,
              height: 32,
              child: Center(child: Icon(icon, size: 18, color: color)),
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: AppText(
              label,
              role: AppTextRole.subheadline,
              weight: FontWeight.w700,
              maxLines: 1,
            ),
          ),
          AppText(
            digits,
            role: AppTextRole.title,
            weight: FontWeight.w900,
            tabular: true,
            tone: dangerCount ? AppTextTone.danger : AppTextTone.primary,
            maxLines: 1,
          ),
        ],
      ),
    );
    return Pressable(
      onPressed: onTap,
      semanticLabel: '$label، $digits',
      selected: selected,
      hoverRadius: BorderRadius.circular(_tileRadius),
      dimsGlass: true,
      child: SizedBox(
        height: _tileHeight,
        child: AppGlass(
          role: GlassRole.row,
          shape: shape,
          child: Stack(
            children: [
              if (selected)
                const Positioned.fill(
                  child: GlassInner(shape: shape, child: SizedBox.expand()),
                ),
              Positioned.fill(child: body),
            ],
          ),
        ),
      ),
    );
  }
}
