import 'package:borj/app/design/app_text.dart';
import 'package:flutter/material.dart';

/// The large title block of the phone boards: a date line, then the 34 pt
/// title. Not glass.
class LargeTitleHeader extends StatelessWidget {
  const LargeTitleHeader({
    required this.title,
    this.subtitle,
    this.onTitleLongPress,
    super.key,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onTitleLongPress;

  @override
  Widget build(BuildContext context) {
    Widget titleText = AppText(
      title,
      role: AppTextRole.largeTitle,
      weight: FontWeight.w900,
    );
    if (onTitleLongPress != null) {
      titleText = GestureDetector(
        onLongPress: onTitleLongPress,
        child: titleText,
      );
    }
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (subtitle != null)
            AppText(
              subtitle!,
              role: AppTextRole.subheadline,
              weight: FontWeight.w600,
            ),
          titleText,
        ],
      ),
    );
  }
}
