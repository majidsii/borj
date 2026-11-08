import 'package:borj/app/theme/app_theme.dart';
import 'package:flutter/material.dart';

enum AppTextRole {
  largeTitle,
  title,
  headline,
  body,
  callout,
  subheadline,
  footnote,
  caption,
  caption2,
}

enum AppTextTone {
  primary,
  secondary,
  secondaryStrong,
  tertiary,
  link,
  success,
  warn,
  danger,
  onTint,
}

extension AppTextToneColor on AppTextTone {
  Color resolve(AppColors colors) => switch (this) {
    AppTextTone.primary => colors.text,
    AppTextTone.secondary => colors.textSecondary,
    AppTextTone.secondaryStrong => colors.textSecondaryStrong,
    AppTextTone.tertiary => colors.textTertiary,
    AppTextTone.link => colors.link,
    AppTextTone.success => colors.success,
    AppTextTone.warn => colors.warn,
    AppTextTone.danger => colors.danger,
    // Content on an accent fill is white in both modes (brief: "onTint is white").
    AppTextTone.onTint => const Color(0xFFFFFFFF),
  };
}

/// Text in one of the design roles and tones, styled from [AppTheme].
class AppText extends StatelessWidget {
  const AppText(
    this.data, {
    this.role = AppTextRole.body,
    this.tone = AppTextTone.primary,
    this.weight,
    this.textAlign,
    this.maxLines,
    this.tabular = false,
    this.decoration,
    super.key,
  });

  final String data;
  final AppTextRole role;
  final AppTextTone tone;
  final FontWeight? weight;
  final TextAlign? textAlign;
  final int? maxLines;
  final bool tabular;
  final TextDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final base = switch (role) {
      AppTextRole.largeTitle => theme.text.largeTitle,
      AppTextRole.title => theme.text.title,
      AppTextRole.headline => theme.text.headline,
      AppTextRole.body => theme.text.body,
      AppTextRole.callout => theme.text.callout,
      AppTextRole.subheadline => theme.text.subheadline,
      AppTextRole.footnote => theme.text.footnote,
      AppTextRole.caption => theme.text.caption,
      AppTextRole.caption2 => theme.text.caption2,
    };
    var style = base.copyWith(
      color: tone.resolve(theme.colors),
      fontWeight: weight,
      decoration: decoration,
    );
    if (tabular) {
      style = theme.text.tabular(style);
    }
    return Text(
      data,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
    );
  }
}
