import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────
/// VANGUARDE THEME
/// All color tokens and extensions for the Vanguarde system.
/// Change a value here and both light and dark modes update.
/// ─────────────────────────────────────────────────────────

/// Extra colors that don't map to Flutter's built-in ColorScheme
/// roles (e.g. status dots, muted kicker text, custom borders).
/// Accessed anywhere via: Theme.of(context).extension<VanguardeColors>()!
@immutable
class VanguardeColors extends ThemeExtension<VanguardeColors> {
  final Color statusDot;
  final Color kickerText;
  final Color fieldBackground;
  final Color fieldBorder;
  final Color fieldHint;
  final Color smallLabel;
  final Color subtitle;

  const VanguardeColors({
    required this.statusDot,
    required this.kickerText,
    required this.fieldBackground,
    required this.fieldBorder,
    required this.fieldHint,
    required this.smallLabel,
    required this.subtitle,
  });

  static const light = VanguardeColors(
    statusDot: Color(0xFF0F6B52),
    kickerText: Color(0xFF5B6B66),
    fieldBackground: Color(0xFFF4F7F5),
    fieldBorder: Color(0xFFE2E8E5),
    fieldHint: Color(0xFFA7B3AE),
    smallLabel: Color(0xFF9AA8A3),
    subtitle: Color(0xFF65756F),
  );

  static const dark = VanguardeColors(
    statusDot: Color(0xFF3EE8B8),
    kickerText: Color(0xFF7FA89B),
    fieldBackground: Color(0xFF101C18),
    fieldBorder: Color(0xFF1C2E28),
    fieldHint: Color(0xFF3F5750),
    smallLabel: Color(0xFF4D6A61),
    subtitle: Color(0xFF7FA89B),
  );

  @override
  VanguardeColors copyWith({
    Color? statusDot,
    Color? kickerText,
    Color? fieldBackground,
    Color? fieldBorder,
    Color? fieldHint,
    Color? smallLabel,
    Color? subtitle,
  }) {
    return VanguardeColors(
      statusDot: statusDot ?? this.statusDot,
      kickerText: kickerText ?? this.kickerText,
      fieldBackground: fieldBackground ?? this.fieldBackground,
      fieldBorder: fieldBorder ?? this.fieldBorder,
      fieldHint: fieldHint ?? this.fieldHint,
      smallLabel: smallLabel ?? this.smallLabel,
      subtitle: subtitle ?? this.subtitle,
    );
  }

  @override
  VanguardeColors lerp(ThemeExtension<VanguardeColors>? other, double t) {
    if (other is! VanguardeColors) return this;
    return VanguardeColors(
      statusDot: Color.lerp(statusDot, other.statusDot, t)!,
      kickerText: Color.lerp(kickerText, other.kickerText, t)!,
      fieldBackground: Color.lerp(fieldBackground, other.fieldBackground, t)!,
      fieldBorder: Color.lerp(fieldBorder, other.fieldBorder, t)!,
      fieldHint: Color.lerp(fieldHint, other.fieldHint, t)!,
      smallLabel: Color.lerp(smallLabel, other.smallLabel, t)!,
      subtitle: Color.lerp(subtitle, other.subtitle, t)!,
    );
  }
}

class VanguardeTheme {
  // Core brand + surface tokens
  static const _primaryLight = Color(0xFF0F6B52);
  static const _primaryDark = Color(0xFF3EE8B8);

  static const _backgroundLight = Color(0xFFFFFFFF);
  static const _backgroundDark = Color(0xFF0B1210);

  static const _textLight = Color(0xFF0D1A16);
  static const _textDark = Color(0xFFEAFAF4);

  static const _onPrimaryLight = Color(0xFFFFFFFF);
  static const _onPrimaryDark = Color(0xFF062018);

  static ThemeData light = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: _backgroundLight,
    fontFamily: 'Sora',
    colorScheme: const ColorScheme.light(
      primary: _primaryLight,
      onPrimary: _onPrimaryLight,
      surface: _backgroundLight,
      onSurface: _textLight,
    ),
    textTheme: _textTheme(_textLight),
    extensions: const [VanguardeColors.light],
  );

  static ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _backgroundDark,
    fontFamily: 'Sora',
    colorScheme: const ColorScheme.dark(
      primary: _primaryDark,
      onPrimary: _onPrimaryDark,
      surface: _backgroundDark,
      onSurface: _textDark,
    ),
    textTheme: _textTheme(_textDark),
    extensions: const [VanguardeColors.dark],
  );

  static TextTheme _textTheme(Color baseColor) {
    return TextTheme(
      headlineSmall: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 24,
        letterSpacing: -0.2,
        color: baseColor,
      ),
      bodyMedium: TextStyle(fontSize: 13, color: baseColor),
      labelLarge: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 11,
        color: baseColor,
      ),
    );
  }
}