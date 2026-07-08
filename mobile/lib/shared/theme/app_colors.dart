import 'package:flutter/material.dart';

/// Semantic color tokens for the Trailhead design system.
/// Reference these via `Theme.of(context).extension<AppColors>()!`
/// Never use raw hex values in widget code.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.accent,
    required this.accentMuted,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.border,
    required this.success,
    required this.warning,
    required this.error,
  });

  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color accent;
  final Color accentMuted;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;
  final Color border;
  final Color success;
  final Color warning;
  final Color error;

  // ---------------------------------------------------------------------------
  // Dark theme tokens
  // ---------------------------------------------------------------------------
  static const AppColors dark = AppColors(
    background:    Color(0xFF121212),
    surface:       Color(0xFF1C1C1E),
    surfaceRaised: Color(0xFF242426),
    accent:        Color(0xFFFF5A3C),
    accentMuted:   Color(0xFF7A2E20),
    textPrimary:   Color(0xFFFFFFFF),
    textSecondary: Color(0xFFA0A0A3),
    textDisabled:  Color(0xFF5C5C5E),
    border:        Color(0xFF2E2E30),
    success:       Color(0xFF4CD97B),
    warning:       Color(0xFFF2B84B),
    error:         Color(0xFFFF5252),
  );

  // ---------------------------------------------------------------------------
  // Light theme tokens
  // ---------------------------------------------------------------------------
  static const AppColors light = AppColors(
    background:    Color(0xFFFAFAFA),
    surface:       Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFF0F0F1),
    accent:        Color(0xFFE8492D),
    accentMuted:   Color(0xFFF5C4B8),
    textPrimary:   Color(0xFF1A1A1A),
    textSecondary: Color(0xFF6B6B6E),
    textDisabled:  Color(0xFFB8B8BA),
    border:        Color(0xFFE2E2E4),
    success:       Color(0xFF2A9D5C),
    warning:       Color(0xFFC98A2E),
    error:         Color(0xFFD4342A),
  );

  // ---------------------------------------------------------------------------
  // ThemeExtension boilerplate
  // ---------------------------------------------------------------------------
  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? accent,
    Color? accentMuted,
    Color? textPrimary,
    Color? textSecondary,
    Color? textDisabled,
    Color? border,
    Color? success,
    Color? warning,
    Color? error,
  }) {
    return AppColors(
      background:    background    ?? this.background,
      surface:       surface       ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      accent:        accent        ?? this.accent,
      accentMuted:   accentMuted   ?? this.accentMuted,
      textPrimary:   textPrimary   ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textDisabled:  textDisabled  ?? this.textDisabled,
      border:        border        ?? this.border,
      success:       success       ?? this.success,
      warning:       warning       ?? this.warning,
      error:         error         ?? this.error,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background:    Color.lerp(background,    other.background,    t)!,
      surface:       Color.lerp(surface,       other.surface,       t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      accent:        Color.lerp(accent,        other.accent,        t)!,
      accentMuted:   Color.lerp(accentMuted,   other.accentMuted,   t)!,
      textPrimary:   Color.lerp(textPrimary,   other.textPrimary,   t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textDisabled:  Color.lerp(textDisabled,  other.textDisabled,  t)!,
      border:        Color.lerp(border,        other.border,        t)!,
      success:       Color.lerp(success,       other.success,       t)!,
      warning:       Color.lerp(warning,       other.warning,       t)!,
      error:         Color.lerp(error,         other.error,         t)!,
    );
  }
}
