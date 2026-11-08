import 'package:borj/app/design/design.dart';
import 'package:borj/app/shell/window_class.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:borj/core/formatting/persian_number.dart';
import 'package:borj/features/today/application/today_agenda_builder.dart';
import 'package:borj/features/today/presentation/today_card.dart';
import 'package:borj/features/today/presentation/today_format.dart';
import 'package:borj/features/today/presentation/today_grid.dart';
import 'package:flutter/material.dart';

/// The board's today's-tasks card.
class TodayTasksCard extends StatelessWidget {
  const TodayTasksCard({
    required this.agenda,
    required this.now,
    required this.onToggle,
    required this.onShowAll,
    this.size = TodayCardSize.large,
    super.key,
  });

  final TodayAgenda agenda;
  final DateTime now;
  final ValueChanged<TodayEntry> onToggle;
  final VoidCallback onShowAll;
  final TodayCardSize size;

  static const double _rowHeight = 54;
  static const double _headerHeight = 28;

  @override
  Widget build(BuildContext context) {
    final grouped = WindowClass.of(context) != WindowClass.compact;
    final next = agenda.nextAfter(now);
    final entries = [...agenda.timed, ...agenda.untimed];
    if (entries.isEmpty) {
      return const TodayCard(
        semanticLabel: 'کارهای امروز',
        child: Center(
          child: AppText(
            'امروز کاری نداری',
            role: AppTextRole.subheadline,
            tone: AppTextTone.secondary,
          ),
        ),
      );
    }
    return TodayCard(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      semanticLabel: 'کارهای امروز',
      child: LayoutBuilder(
        builder: (context, c) {
          final rows = <Widget>[];
          var used = 0.0;
          String? group;
          var shown = 0;
          for (final e in entries) {
            final g = !e.timed
                ? 'بی‌زمان'
                : (e.localStart!.hour < 12 ? 'صبح' : 'بعدازظهر');
            final needsHeader = grouped && g != group;
            final cost = _rowHeight + (needsHeader ? _headerHeight : 0);
            final remainingAfter = entries.length - shown - 1;
            final reserve = remainingAfter > 0 ? _rowHeight : 0;
            if (used + cost + reserve > c.maxHeight) break;
            if (needsHeader) {
              rows.add(
                SizedBox(
                  height: _headerHeight,
                  child: Align(
                    alignment: AlignmentDirectional.bottomStart,
                    child: AppText(
                      g,
                      role: AppTextRole.caption,
                      tone: AppTextTone.secondary,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              );
              group = g;
            }
            rows.add(
              _Row(
                entry: e,
                isNext: identical(e, next) || e == next,
                onToggle: onToggle,
                divider: shown > 0 && !needsHeader,
              ),
            );
            used += cost;
            shown++;
          }
          final hidden = entries.length - shown;
          if (hidden > 0) {
            rows.add(
              Pressable(
                key: const ValueKey('today-tasks-more'),
                onPressed: onShowAll,
                semanticLabel: 'و ${formatPersianInteger(hidden)} کار دیگر',
                child: SizedBox(
                  height: _rowHeight,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: AppText(
                      'و ${formatPersianInteger(hidden)} کار دیگر',
                      role: AppTextRole.subheadline,
                      tone: AppTextTone.link,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: rows,
          );
        },
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.entry,
    required this.isNext,
    required this.onToggle,
    required this.divider,
  });

  final TodayEntry entry;
  final bool isNext;
  final ValueChanged<TodayEntry> onToggle;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context).colors;
    final time = entry.timed ? formatClock(entry.localStart!) : null;
    return DecoratedBox(
      key: ValueKey('today-task-${entry.taskId}'),
      decoration: BoxDecoration(
        border: divider
            ? Border(top: BorderSide(color: colors.hairline, width: 0.5))
            : null,
      ),
      child: SizedBox(
        height: TodayTasksCard._rowHeight,
        child: Row(
          children: [
            RoundCheck(
              checked: entry.done,
              onChanged: (_) => onToggle(entry),
              semanticLabel: entry.title,
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Pressable(
                onPressed: () => onToggle(entry),
                semanticLabel: entry.title,
                child: Row(
                  children: [
                    Expanded(
                      child: AppText(
                        entry.title,
                        maxLines: 1,
                        tone: entry.done
                            ? AppTextTone.tertiary
                            : AppTextTone.primary,
                        weight: isNext ? FontWeight.w700 : null,
                        decoration: entry.done
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (time != null)
                      AppText(
                        time,
                        role: AppTextRole.footnote,
                        tabular: true,
                        tone: isNext ? AppTextTone.link : AppTextTone.secondary,
                        weight: isNext ? FontWeight.w800 : null,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
