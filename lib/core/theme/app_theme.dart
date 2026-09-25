import 'package:flutter/material.dart';
import 'package:plant_disease_detector/core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Barrel exports — import this single file to get all theme tokens
// ─────────────────────────────────────────────────────────────────────────────
export 'app_colors.dart';
export 'app_gradients.dart';
export 'app_text_styles.dart';
export 'app_shadows.dart';
export 'app_spacing.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppTheme — MaterialApp ThemeData configuration
// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._(); // Prevent instantiation

  static const String _fontFamily = 'Poppins';

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: _fontFamily,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.copper,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
