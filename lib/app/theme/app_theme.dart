// lib/app/theme/app_theme.dart
import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
}

/// Radii from the boards (`screens/*.html`) and the 2026-11-06 Apple size alignment.
abstract final class AppRadii {
  static const double capsule = 999;
  static const double cardLarge = 26;
  static const double card = 24;
  static const double inner = 16;
  static const double innerSmall = 14;
  static const double sheet = 34;
  static const double small = 8;
}

@immutable
final class AppColors {
  const AppColors({
    required this.background,
    required this.window,
    required this.text,
    required this.textSecondary,
    required this.textSecondaryStrong,
    required this.textTertiary,
    required this.link,
    required this.accent,
    required this.teal,
    required this.success,
    required this.warn,
    required this.danger,
    required this.purple,
    required this.checkBorder,
    required this.hairline,
    required this.selection,
    required this.innerTop,
    required this.innerBottom,
    required this.innerEdge,
    required this.innerShadow,
    required this.backdropTop,
    required this.backdropBottom,
    required this.warmGlow,
    required this.switchOn,
    required this.switchOff,
    required this.thumbSurface,
    required this.thumbText,
    required this.pressShadow,
    required this.knobShadow,
    required this.scrim,
    required this.glassTextStops,
  });

  static const light = AppColors(
    background: Color(0xFFFFFFFF),
    window: Color(0xFFFFFFFF),
    text: Color(0xFF1B2236),
    textSecondary: Color(0xFF38425E),
    textSecondaryStrong: Color(0xFF2C3550),
    textTertiary: Color(0xFF5A6482),
    link: Color(0xFF1F5FD0),
    accent: Color(0xFF2F6FDB),
    teal: Color(0xFF0B857A),
    success: Color(0xFF07665D),
    warn: Color(0xFF8F5400),
    danger: Color(0xFFB02440),
    purple: Color(0xFF6B4BC0),
    checkBorder: Color(0xFF6F7896),
    hairline: Color(0x1F1B2236), // rgba(27,34,54,.12)
    selection: Color(0x242F6FDB), // rgba(47,111,219,.14)
    innerTop: Color(0xFFFFFFFF),
    innerBottom: Color(0xEBECF2FF), // rgba(236,242,255,.92)
    innerEdge: Color(0x3832488C), // rgba(50,72,140,.22)
    innerShadow: Color(0x421E3278), // rgba(30,50,120,.26)
    backdropTop: Color(0xFFFFFFFF),
    backdropBottom: Color(0xFFFFFFFF),
    warmGlow: Color(0x00FFAA5F),
    switchOn: Color(0xFF1FB5A8),
    switchOff: Color(0x1F1B2236),
    thumbSurface: Color(0xFFFFFFFF),
    thumbText: Color(0xFF1F5FD0),
    pressShadow: Color(0x33141E50), // rgba(20,30,80,.20)
    knobShadow: Color(0x59141E50), // rgba(20,30,80,.35)
    scrim: Color(0x400A0E1E),
    glassTextStops: <Color>[
      Color(0xD6FFFFFF), // rgba(255,255,255,.84)
      Color(0xB3F2F6FF), // rgba(242,246,255,.70)
      Color(0xBDE4ECFE), // rgba(228,236,254,.74)
    ],
  );

  static const dark = AppColors(
    background: Color(0xFF1B1C20),
    window: Color(0xFF24262B),
    text: Color(0xFFF4F6FC),
    textSecondary: Color(0xFFC5CCE0),
    textSecondaryStrong: Color(0xFFE1E6F5),
    textTertiary: Color(0xFF98A2C0),
    link: Color(0xFFACC9FF), // kit #8DB5FF, lightened (Decision 4)
    accent: Color(0xFF5B93F0),
    teal: Color(0xFF3FD1C2),
    success: Color(0xFF66DBB0), // kit #4FD6A4, lightened
    warn: Color(0xFFF2BE71), // kit #F0B35A, lightened
    danger: Color(0xFFFFB3BE), // kit #FF8A9B, lightened
    purple: Color(0xFFD1BFFF), // kit #B79BFF, lightened
    checkBorder: Color(0xFFAEB8D6),
    hairline: Color(0x1FFFFFFF),
    selection: Color(0x24FFFFFF),
    innerTop: Color(0x42FFFFFF), // rgba(255,255,255,.26)
    innerBottom: Color(0x1FFFFFFF), // rgba(255,255,255,.12)
    innerEdge: Color(0x66000000), // rgba(0,0,0,.4)
    innerShadow: Color(0x73000000), // rgba(0,0,0,.45)
    backdropTop: Color(0xFF232427),
    backdropBottom: Color(0xFF18191C),
    warmGlow: Color(0x57FFAA5F), // rgba(255,170,95,.34)
    switchOn: Color(0xFF1FB5A8),
    switchOff: Color(0x29FFFFFF),
    thumbSurface: Color(0xFFFFFFFF),
    thumbText: Color(0xFF1F5FD0),
    pressShadow: Color(0x33141E50), // rgba(20,30,80,.20)
    knobShadow: Color(0x59141E50), // rgba(20,30,80,.35)
    scrim: Color(0x73000000),
    glassTextStops: <Color>[
      Color(0x80787C96), // rgba(120,124,150,.50)
      Color(0x8056596E), // rgba(86,89,110,.50)
      Color(0x8C424456), // rgba(66,68,86,.55)
    ],
  );

  final Color background;
  final Color window;
  final Color text;
  final Color textSecondary;
  final Color textSecondaryStrong;

  /// Finished/disabled text. Intentionally below 4.5:1 (kit rule 5).
  final Color textTertiary;
  final Color link;
  final Color accent;
  final Color teal;
  final Color success;
  final Color warn;
  final Color danger;
  final Color purple;
  final Color checkBorder;
  final Color hairline;
  final Color selection;
  final Color innerTop;
  final Color innerBottom;
  final Color innerEdge;
  final Color innerShadow;
  final Color backdropTop;
  final Color backdropBottom;
  final Color warmGlow;
  final Color switchOn;
  final Color switchOff;
  final Color thumbSurface;
  final Color thumbText;
  final Color pressShadow;
  final Color knobShadow;
  final Color scrim;

  /// The kit's `--g-bg-text` stops: the reference surfaces for text contrast.
  final List<Color> glassTextStops;

  Color get moneyIncome => success;
  Color get moneyExpense => text;
  Color get moneyOverBudget => danger;

  Color byName(String name) => switch (name) {
    'text' => text,
    'textSecondary' => textSecondary,
    'textSecondaryStrong' => textSecondaryStrong,
    'textTertiary' => textTertiary,
    'link' => link,
    'accent' => accent,
    'teal' => teal,
    'success' => success,
    'warn' => warn,
    'danger' => danger,
    'purple' => purple,
    _ => throw ArgumentError.value(name, 'name'),
  };

  AppColors lerp(AppColors other, double t) {
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      background: c(background, other.background),
      window: c(window, other.window),
      text: c(text, other.text),
      textSecondary: c(textSecondary, other.textSecondary),
      textSecondaryStrong: c(textSecondaryStrong, other.textSecondaryStrong),
      textTertiary: c(textTertiary, other.textTertiary),
      link: c(link, other.link),
      accent: c(accent, other.accent),
      teal: c(teal, other.teal),
      success: c(success, other.success),
      warn: c(warn, other.warn),
      danger: c(danger, other.danger),
      purple: c(purple, other.purple),
      checkBorder: c(checkBorder, other.checkBorder),
      hairline: c(hairline, other.hairline),
      selection: c(selection, other.selection),
      innerTop: c(innerTop, other.innerTop),
      innerBottom: c(innerBottom, other.innerBottom),
      innerEdge: c(innerEdge, other.innerEdge),
      innerShadow: c(innerShadow, other.innerShadow),
      backdropTop: c(backdropTop, other.backdropTop),
      backdropBottom: c(backdropBottom, other.backdropBottom),
      warmGlow: c(warmGlow, other.warmGlow),
      switchOn: c(switchOn, other.switchOn),
      switchOff: c(switchOff, other.switchOff),
      thumbSurface: c(thumbSurface, other.thumbSurface),
      thumbText: c(thumbText, other.thumbText),
      pressShadow: c(pressShadow, other.pressShadow),
      knobShadow: c(knobShadow, other.knobShadow),
      scrim: c(scrim, other.scrim),
      glassTextStops: <Color>[
        for (var i = 0; i < glassTextStops.length; i++)
          c(glassTextStops[i], other.glassTextStops[i]),
      ],
    );
  }
}

@immutable
final class AppTextRoles {
  const AppTextRoles({
    required this.largeTitle,
    required this.title,
    required this.headline,
    required this.body,
    required this.callout,
    required this.subheadline,
    required this.footnote,
    required this.caption,
    required this.caption2,
  });

  factory AppTextRoles.forColor(Color color) {
    TextStyle s(double size, FontWeight weight, double height) => TextStyle(
      fontFamily: 'Vazirmatn',
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: 0,
      color: color,
    );
    return AppTextRoles(
      largeTitle: s(34, FontWeight.w800, 1.25),
      title: s(23, FontWeight.w700, 1.3),
      headline: s(17, FontWeight.w700, 1.45),
      body: s(15, FontWeight.w400, 1.6),
      callout: s(14, FontWeight.w400, 1.55),
      subheadline: s(13, FontWeight.w500, 1.5),
      footnote: s(12, FontWeight.w400, 1.5),
      caption: s(11, FontWeight.w500, 1.45),
      caption2: s(10, FontWeight.w500, 1.4),
    );
  }

  final TextStyle largeTitle;
  final TextStyle title;
  final TextStyle headline;
  final TextStyle body;
  final TextStyle callout;
  final TextStyle subheadline;
  final TextStyle footnote;
  final TextStyle caption;
  final TextStyle caption2;

  /// Equal-width digits (Vazirmatn `tnum`: every Persian digit 0.659 em).
  TextStyle tabular(TextStyle style) => style.copyWith(
    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
  );

  AppTextRoles lerp(AppTextRoles other, double t) {
    TextStyle l(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return AppTextRoles(
      largeTitle: l(largeTitle, other.largeTitle),
      title: l(title, other.title),
      headline: l(headline, other.headline),
      body: l(body, other.body),
      callout: l(callout, other.callout),
      subheadline: l(subheadline, other.subheadline),
      footnote: l(footnote, other.footnote),
      caption: l(caption, other.caption),
      caption2: l(caption2, other.caption2),
    );
  }
}

@immutable
final class AppTheme extends ThemeExtension<AppTheme> {
  const AppTheme({required this.colors, required this.text});

  static final AppTheme light = AppTheme(
    colors: AppColors.light,
    text: AppTextRoles.forColor(AppColors.light.text),
  );

  static final AppTheme dark = AppTheme(
    colors: AppColors.dark,
    text: AppTextRoles.forColor(AppColors.dark.text),
  );

  final AppColors colors;
  final AppTextRoles text;

  static AppTheme of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AppTheme>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  @override
  AppTheme copyWith({AppColors? colors, AppTextRoles? text}) =>
      AppTheme(colors: colors ?? this.colors, text: text ?? this.text);

  @override
  AppTheme lerp(covariant AppTheme? other, double t) {
    if (other == null) {
      return this;
    }
    return AppTheme(
      colors: colors.lerp(other.colors, t),
      text: text.lerp(other.text, t),
    );
  }
}
