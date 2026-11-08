import 'dart:math' as math;

import 'package:borj/app/design/design.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:borj/core/formatting/persian_number.dart';
import 'package:borj/features/today/application/today_agenda_builder.dart';
import 'package:borj/features/today/presentation/today_card.dart';
import 'package:borj/features/today/presentation/today_format.dart';
import 'package:borj/features/today/presentation/today_grid.dart';
import 'package:flutter/material.dart';

/// Whole even hours covering 8–20 and every block, clamped to 0–24.
(int, int) timelineRange(List<TodayEntry> timed) {
  var start = 8;
  var end = 20;
  for (final e in timed) {
    final s = e.localStart!;
    final endAt = s.add(Duration(minutes: e.durationMinutes ?? 30));
    final sh = s.hour;
    final eh = endAt.day != s.day
        ? 24
        : (endAt.minute > 0 ? endAt.hour + 1 : endAt.hour);
    start = math.min(start, sh - sh % 2);
    end = math.max(end, eh + eh % 2);
  }
  return (math.max(0, start), math.min(24, end));
}

/// The board's «برنامهٔ امروز» card: blocks on an hour scale with a now-line.
class TimelineCard extends StatelessWidget {
  const TimelineCard({
    required this.agenda,
    required this.now,
    this.size = TodayCardSize.wide,
    super.key,
  });

  final TodayAgenda agenda;
  final DateTime now;
  final TodayCardSize size;

  @override
  Widget build(BuildContext context) {
    final next = agenda.nextAfter(now);
    return TodayCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      semanticLabel: 'برنامهٔ امروز',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Flexible(
                child: AppText(
                  'برنامهٔ امروز',
                  role: AppTextRole.footnote,
                  weight: FontWeight.w800,
                  maxLines: 1,
                ),
              ),
              if (next != null) ...[
                const SizedBox(width: AppSpacing.s8),
                const AppText(
                  'بعدی:',
                  role: AppTextRole.footnote,
                  tone: AppTextTone.secondary,
                  maxLines: 1,
                ),
                const SizedBox(width: AppSpacing.s4),
                Flexible(
                  child: AppText(
                    next.title,
                    role: AppTextRole.footnote,
                    weight: FontWeight.w700,
                    maxLines: 1,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          Expanded(
            child: _Scale(
              agenda: agenda,
              now: now,
              lanes: size == TodayCardSize.large ? 2 : 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _Scale extends StatelessWidget {
  const _Scale({required this.agenda, required this.now, required this.lanes});

  final TodayAgenda agenda;
  final DateTime now;
  final int lanes;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context).colors;
    final (startHour, endHour) = timelineRange(agenda.timed);
    final span = (endHour - startHour) * 60.0;
    double fraction(DateTime t) {
      // Wall-clock arithmetic only (no DateTime.difference between naive
      // values, which a device-zone DST shift would skew).
      final days = DateTime.utc(t.year, t.month, t.day)
          .difference(
            DateTime.utc(agenda.day.year, agenda.day.month, agenda.day.day),
          )
          .inDays;
      final minutes = days * 1440 + t.hour * 60 + t.minute - startHour * 60;
      return (minutes / span).clamp(0.0, 1.0);
    }

    final laneOf = <String, int>{};
    final laneEnds = List<DateTime?>.filled(lanes, null);
    for (final e in agenda.timed) {
      final s = e.localStart!;
      var lane = 0;
      while (lane < lanes - 1 &&
          laneEnds[lane] != null &&
          s.isBefore(laneEnds[lane]!)) {
        lane++;
      }
      laneOf[e.taskId] = lane;
      laneEnds[lane] = s.add(Duration(minutes: e.durationMinutes ?? 30));
    }

    final nowInDay =
        now.year == agenda.day.year &&
        now.month == agenda.day.month &&
        now.day == agenda.day.day;
    final nowMinutes = now.hour * 60 + now.minute;
    final showNow =
        nowInDay && nowMinutes >= startHour * 60 && nowMinutes <= endHour * 60;

    return LayoutBuilder(
      builder: (context, c) {
        final width = c.maxWidth;
        const laneHeight = 50.0;
        final children = <Widget>[];
        if (agenda.timed.isEmpty) {
          children.add(
            const Positioned.fill(
              bottom: 18,
              child: Center(
                child: AppText(
                  'برای امروز برنامهٔ زمان‌داری نداری',
                  role: AppTextRole.footnote,
                  tone: AppTextTone.secondary,
                ),
              ),
            ),
          );
        }
        if (showNow) {
          children.add(
            PositionedDirectional(
              key: const ValueKey('timeline-elapsed'),
              start: 0,
              top: 0,
              width: fraction(now) * width,
              height: laneHeight * lanes,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.selection.withValues(
                      alpha: colors.selection.a * 0.5,
                    ),
                    borderRadius: BorderRadius.circular(AppRadii.small),
                  ),
                ),
              ),
            ),
          );
        }
        for (final e in agenda.timed) {
          final s = e.localStart!;
          final f0 = fraction(s);
          final f1 = fraction(
            s.add(Duration(minutes: e.durationMinutes ?? 30)),
          );
          final minW = 30 / span;
          final blockWidth = math.min(math.max(f1 - f0, minW) * width, width);
          final past =
              showNow &&
              s.add(Duration(minutes: e.durationMinutes ?? 30)).isBefore(now);
          final lane = laneOf[e.taskId]!;
          children.add(
            PositionedDirectional(
              key: ValueKey('timeline-block-${e.taskId}'),
              start: math.min(f0 * width, width - blockWidth),
              top: 4 + lane * laneHeight,
              width: blockWidth,
              height: 42,
              child: Opacity(
                opacity: past ? 0.55 : 1,
                child: GlassInner(
                  shape: const AppleGlassShape.rounded(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 5,
                      horizontal: 3,
                    ),
                    child: AppText(
                      e.done ? '${e.title} ✓' : e.title,
                      role: AppTextRole.caption2,
                      weight: FontWeight.w700,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        if (showNow) {
          final x = fraction(now) * width;
          children.add(
            PositionedDirectional(
              key: const ValueKey('timeline-now'),
              start: x - 1,
              top: -4,
              width: 2,
              height: laneHeight * lanes + 8,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.danger,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          );
        }
        final labels = <Widget>[
          for (var h = startHour; h <= endHour; h += 2)
            PositionedDirectional(
              start:
                  fraction(
                        DateTime(
                          agenda.day.year,
                          agenda.day.month,
                          agenda.day.day,
                          h,
                        ),
                      ) *
                      width -
                  12,
              width: 24,
              top: 0,
              child: AppText(
                formatPersianInteger(h),
                role: AppTextRole.caption2,
                tone: AppTextTone.secondary,
                textAlign: TextAlign.center,
              ),
            ),
          if (showNow)
            PositionedDirectional(
              key: const ValueKey('timeline-now-pill'),
              start: (fraction(now) * width - 22).clamp(
                0.0,
                math.max(0.0, width - 44),
              ),
              width: 44,
              top: -2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.danger,
                  borderRadius: BorderRadius.circular(AppRadii.capsule),
                ),
                child: AppText(
                  formatClock(now),
                  role: AppTextRole.caption2,
                  tone: AppTextTone.inverse,
                  weight: FontWeight.w800,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ];
        return Column(
          children: [
            SizedBox(
              key: const ValueKey('timeline-scale'),
              height: laneHeight * lanes,
              child: Stack(clipBehavior: Clip.none, children: children),
            ),
            const SizedBox(height: AppSpacing.s4),
            SizedBox(
              height: 18,
              child: Stack(clipBehavior: Clip.none, children: labels),
            ),
          ],
        );
      },
    );
  }
}
