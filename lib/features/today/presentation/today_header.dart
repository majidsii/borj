import 'package:borj/app/design/design.dart';
import 'package:borj/app/shell/window_class.dart';
import 'package:borj/core/date_time/persian_date_label.dart';
import 'package:flutter/material.dart';

/// Today's header: the phone large title, or the desktop date chip
/// (board `MacToday`). [now] is the task-zone wall clock.
///
/// The chip's text uses `primary` / `secondaryStrong`, not `onTint`: the clear
/// glass is near-transparent, so white text would vanish on the light page
/// (plan Decision 6).
class TodayHeader extends StatelessWidget {
  const TodayHeader({required this.now, this.onTitleLongPress, super.key});

  final DateTime now;
  final VoidCallback? onTitleLongPress;

  @override
  Widget build(BuildContext context) {
    if (WindowClass.of(context) == WindowClass.compact) {
      return LargeTitleHeader(
        key: const ValueKey('today-title'),
        title: 'امروز',
        subtitle: PersianDateLabel.short(now),
        onTitleLongPress: onTitleLongPress,
      );
    }
    Widget title = AppText(
      PersianDateLabel.jalaliLong(now),
      role: AppTextRole.largeTitle,
      weight: FontWeight.w900,
    );
    title = KeyedSubtree(
      key: const ValueKey('today-title'),
      child: onTitleLongPress == null
          ? title
          : GestureDetector(onLongPress: onTitleLongPress, child: title),
    );
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(28, 22, 28, 0),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: GlassScope(
          kind: GlassLayerKind.clear,
          child: AppGlass(
            key: const ValueKey('today-date-chip'),
            role: GlassRole.clear,
            shape: const AppleGlassShape.rounded(26),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(26, 10, 26, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    PersianDateLabel.gregorianShort(now),
                    role: AppTextRole.subheadline,
                    weight: FontWeight.w600,
                    tone: AppTextTone.secondaryStrong,
                  ),
                  title,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
