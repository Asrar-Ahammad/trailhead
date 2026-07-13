import 'package:flutter/material.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';

class AppThemes {
  static ThemeData get lightTheme => _buildTheme(AppColors.light, Brightness.light);
  static ThemeData get darkTheme => _buildTheme(AppColors.dark, Brightness.dark);

  static ThemeData _buildTheme(AppColors colors, Brightness brightness) {
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: colors.background,
      primaryColor: colors.accent,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.accent,
        onPrimary: const Color(0xFFFFFFFF),
        secondary: colors.accentMuted,
        onSecondary: const Color(0xFFFFFFFF),
        surface: colors.surface,
        onSurface: colors.textPrimary,
        error: colors.error,
        onError: const Color(0xFFFFFFFF),
      ),
      extensions: [colors],
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        shape: CircleBorder(),
      ),
      appBarTheme: const AppBarTheme(
        scrolledUnderElevation: 0.0,
      ),
    );
  }
}
