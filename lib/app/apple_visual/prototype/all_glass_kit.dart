// SPIKE EXCEPTION: files in lib/app/apple_visual/prototype/ may import
// liquid_glass_renderer directly (normally only apple_liquid_glass.dart and
// app_bootstrap.dart may). This is a throw-away design prototype.
import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// Persian-tile palette used by the wallpaper and accents.
abstract final class GlassPalette {
  static const lapis = Color(0xFF1F3A93);
  static const turquoise = Color(0xFF1FB5A8);
  static const saffron = Color(0xFFF4A300);
  static const pomegranate = Color(0xFFC8324B);
  static const violet = Color(0xFF7B4FD1);
  static const mint = Color(0xFF7CF0D2);
  static const amber = Color(0xFFFFD36B);
}

const String kGlassFont = 'Vazirmatn';

const List<Shadow> kTextShadow = <Shadow>[
  Shadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 1)),
];

/// White-on-glass text style with a soft shadow for legibility.
TextStyle glassText(
  double size, {
  FontWeight weight = FontWeight.w500,
  double opacity = 1,
  double? height,
}) {
  return TextStyle(
    fontFamily: kGlassFont,
    fontSize: size,
    fontWeight: weight,
    height: height,
    color: Colors.white.withValues(alpha: opacity),
    shadows: kTextShadow,
    decoration: TextDecoration.none,
  );
}

const String _faDigits = '۰۱۲۳۴۵۶۷۸۹';

/// Converts ASCII digits to Persian digits.
String fa(String input) {
  final out = StringBuffer();
  for (final unit in input.runes) {
    if (unit >= 0x30 && unit <= 0x39) {
      out.write(_faDigits[unit - 0x30]);
    } else {
      out.write(String.fromCharCode(unit));
    }
  }
  return out.toString();
}

/// Glass material shared by every layer of the prototype: iOS 27 regular glass
/// with dark appearance, a crisp rim, moderate frost and a faint dark tint so
/// white text stays readable over saffron and turquoise.
LiquidGlassSettings allGlassSettings() {
  return LiquidGlassSettings.ios27RegularDark(
    frost: 4,
  ).copyWith(refractionHeight: 26, refractionAmount: 70, highlight: 0.8);
}

const LiquidGlassAppearance kAllGlassAppearance =
    LiquidGlassAppearance.ios27RegularDark(tint: Color(0x330A1030));

/// One backdrop-sharing glass layer holding up to 16 blended shapes.
///
/// [backdropGroup] makes the layer join the nearest BackdropGroup so layers
/// over the same content plane share one backdrop capture.
class GlassSection extends StatelessWidget {
  const GlassSection({
    required this.child,
    this.fake = false,
    this.backdropGroup = true,
    this.blend = 6,
    this.settings,
    super.key,
  });

  final Widget child;
  final bool fake;
  final bool backdropGroup;
  final double blend;
  final LiquidGlassSettings? settings;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassLayer(
      settings: settings ?? allGlassSettings(),
      defaultAppearance: kAllGlassAppearance,
      fake: fake,
      useBackdropGroup: backdropGroup,
      child: LiquidGlassBlendGroup(blend: blend, child: child),
    );
  }
}

/// A glass shape inside a [GlassSection].
class GlassPiece extends StatelessWidget {
  const GlassPiece({
    required this.child,
    this.radius = 28,
    this.circle = false,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final Widget child;
  final double radius;
  final bool circle;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return LiquidGlass.grouped(
      shape: circle
          ? const LiquidOval()
          : LiquidRoundedSuperellipse(borderRadius: radius),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Round glass icon button (use inside a [GlassSection]).
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    required this.icon,
    required this.onTap,
    required this.label,
    this.size = 46,
    super.key,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: size,
          height: size,
          child: GlassPiece(
            circle: true,
            child: Center(
              child: Icon(
                icon,
                size: size * 0.46,
                color: Colors.white,
                shadows: kTextShadow,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A non-glass progress track drawn inside a glass shape.
class GlassProgressTrack extends StatelessWidget {
  const GlassProgressTrack({
    required this.value,
    required this.color,
    this.height = 8,
    super.key,
  });

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        color: Colors.white.withValues(alpha: 0.22),
        alignment: AlignmentDirectional.centerStart,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0.0, 1.0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(height),
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

/// Vertical gap between sections.
const SizedBox kGap10 = SizedBox(height: 10);
const SizedBox kGap16 = SizedBox(height: 16);
