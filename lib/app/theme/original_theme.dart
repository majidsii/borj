import 'package:borj/app/theme/app_theme.dart';
import 'package:borj/app/theme/original_design_tokens.dart';
import 'package:flutter/material.dart';

abstract final class OriginalTheme {
  static ThemeData light() => _build(Brightness.light, OriginalPalette.light());

  static ThemeData dark() => _build(Brightness.dark, OriginalPalette.dark());

  static ThemeData _build(Brightness brightness, OriginalPalette palette) {
    final base = ThemeData(
      brightness: brightness,
      useMaterial3: false,
      visualDensity: VisualDensity.standard,
      scaffoldBackgroundColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      colorScheme: ColorScheme.fromSeed(
        seedColor: palette.accent,
        brightness: brightness,
      ),
    );

    return base.copyWith(
      extensions: <ThemeExtension<dynamic>>[
        palette,
        if (brightness == Brightness.dark) AppTheme.dark else AppTheme.light,
      ],
      textTheme: base.textTheme.apply(
        fontFamily: 'Vazirmatn',
        bodyColor: palette.ink,
        displayColor: palette.ink,
      ),
      iconTheme: IconThemeData(color: palette.ink),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.field,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OriginalDesignTokens.fieldRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OriginalDesignTokens.fieldRadius),
          borderSide: BorderSide(color: palette.hair, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OriginalDesignTokens.fieldRadius),
          borderSide: BorderSide(color: palette.accent, width: 1.4),
        ),
        hintStyle: TextStyle(
          color: palette.faint,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 11,
        ),
      ),
      dividerColor: palette.line,
    );
  }
}
