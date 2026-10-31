import 'package:flutter/material.dart';
import 'package:sales_management/core/services/theme/theme_service.dart';

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


// ... (VanguardeColors and other existing code)

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

  // ── HELPER: BUILDER FOR CONSISTENT COMPONENT STYLING ──
  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color primary,
    required Color onPrimary,
    required Color surface,
    required Color surfaceContainerLow,
    required Color onSurface,
    required VanguardeColors colors,
  }) {
    final isDark = brightness == Brightness.dark;
    
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: surface,
      fontFamily: 'Sora',
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
        primary: primary,
        onPrimary: onPrimary,
        surface: surface,
        onSurface: onSurface,
        surfaceContainerLow: surfaceContainerLow,
        primaryContainer: primary.withOpacity(isDark ? 0.2 : 0.1),
        onPrimaryContainer: primary,
      ),
      extensions: [colors],
      textTheme: _textTheme(onSurface),
      
      // Minimal, premium bottom navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        elevation: 0,
        selectedItemColor: primary,
        unselectedItemColor: colors.subtitle,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
      ),
    );
  }

  // ── OPTION 1: VANGUARDE SIGNATURE (Your Original Minimal Look) ──
  static final ThemeData vanguardeLight = _buildTheme(
    brightness: Brightness.light,
    primary: _primaryLight,
    onPrimary: _onPrimaryLight,
    surface: _backgroundLight,
    surfaceContainerLow: Colors.white,
    onSurface: _textLight,
    colors: VanguardeColors.light,
  );

  static final ThemeData vanguardeDark = _buildTheme(
    brightness: Brightness.dark,
    primary: _primaryDark,
    onPrimary: _onPrimaryDark,
    surface: _backgroundDark,
    surfaceContainerLow: const Color(0xFF101C18), // Slightly elevated
    onSurface: _textDark,
    colors: VanguardeColors.dark,
  );

  // ── OPTION 2: EXECUTIVE SLATE (Corporate Indigo & Midnight) ──
  static final ThemeData slateLight = _buildTheme(
    brightness: Brightness.light,
    primary: const Color(0xFF4F46E5), // Electric Indigo
    onPrimary: Colors.white,
    surface: const Color(0xFFF8FAFC), // Cool Gray
    surfaceContainerLow: Colors.white,
    onSurface: const Color(0xFF0F172A),
    colors: const VanguardeColors(
      statusDot: Color(0xFF4F46E5),
      kickerText: Color(0xFF64748B),
      fieldBackground: Color(0xFFF1F5F9),
      fieldBorder: Color(0xFFE2E8F0),
      fieldHint: Color(0xFF94A3B8),
      smallLabel: Color(0xFF64748B),
      subtitle: Color(0xFF475569),
    ),
  );

  static final ThemeData slateDark = _buildTheme(
    brightness: Brightness.dark,
    primary: const Color(0xFF6366F1), // Bright Indigo
    onPrimary: Colors.white,
    surface: const Color(0xFF020617), // Deep Slate
    surfaceContainerLow: const Color(0xFF0F172A), // Elevated Slate
    onSurface: const Color(0xFFF8FAFC),
    colors: const VanguardeColors(
      statusDot: Color(0xFF6366F1),
      kickerText: Color(0xFF94A3B8),
      fieldBackground: Color(0xFF0F172A),
      fieldBorder: Color(0xFF1E293B),
      fieldHint: Color(0xFF475569),
      smallLabel: Color(0xFF64748B),
      subtitle: Color(0xFF94A3B8),
    ),
  );

  // ── OPTION 3: NORDIC MINIMAL (Rust/Orange & Pure Black OLED) ──
  static final ThemeData nordicLight = _buildTheme(
    brightness: Brightness.light,
    primary: const Color(0xFFDD6B20), // Burnt Orange
    onPrimary: Colors.white,
    surface: const Color(0xFFF2F2F7), // Apple Alabaster
    surfaceContainerLow: Colors.white,
    onSurface: const Color(0xFF1C1C1E),
    colors: const VanguardeColors(
      statusDot: Color(0xFFDD6B20),
      kickerText: Color(0xFF8E8E93),
      fieldBackground: Color(0xFFE5E5EA),
      fieldBorder: Color(0xFFD1D1D6),
      fieldHint: Color(0xFFAEAEC2),
      smallLabel: Color(0xFF8E8E93),
      subtitle: Color(0xFF3A3A3C),
    ),
  );

  static final ThemeData nordicDark = _buildTheme(
    brightness: Brightness.dark,
    primary: const Color(0xFFF6AD55), // Bright Rust
    onPrimary: Colors.black,
    surface: const Color(0xFF000000), // Pure OLED Black
    surfaceContainerLow: const Color(0xFF1C1C1E), // Dark Iron
    onSurface: Colors.white,
    colors: VanguardeColors(
      statusDot: const Color(0xFFF6AD55),
      kickerText: const Color(0xFF8E8E93),
      fieldBackground: const Color(0xFF1C1C1E),
      fieldBorder: const Color(0xFF2C2C2E),
      fieldHint: const Color(0xFF48484A),
      smallLabel: const Color(0xFF636366),
      subtitle: const Color(0xFF8E8E93),
    ),
  );

  // ── DYNAMIC THEME RESOLVER ──
  static ThemeData getTheme(ThemeStyle style, Brightness brightness) {
    if (brightness == Brightness.light) {
      switch (style) {
        case ThemeStyle.vanguarde: return vanguardeLight;
        case ThemeStyle.slate: return slateLight;
        case ThemeStyle.nordic: return nordicLight;
      }
    } else {
      switch (style) {
        case ThemeStyle.vanguarde: return vanguardeDark;
        case ThemeStyle.slate: return slateDark;
        case ThemeStyle.nordic: return nordicDark;
      }
    }
  }

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