import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppColors
// ─────────────────────────────────────────────────────────────────────────────
class AppColors {
  // Brand Colors (Terracotta, Emerald & Copper)
  static const Color primary = Color(0xFFC96A4F); // Brushed Copper / Terracotta
  static const Color secondary = Color(0xFF1A3A2A); // Deep Emerald Green
  static const Color accent = Color(0xFFE07A5F); // Lighter Copper Accent

  static const Color emeraldLight = Color(0xFF2C553D);
  static const Color emeraldDark = Color(0xFF0D2518);

  // Backgrounds
  static const Color background = Color(0xFFF5F5F5); // Clean off-white/light warm grey
  static const Color surface = Colors.white;

  // Text
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF7A869A); // Softer grey for premium feel

  // States
  static const Color error = Color(0xFFE07A5F);
  static const Color success = Color(0xFF2C553D); // Re-using emerald
  static const Color warning = Color(0xFFF5A623);
  static const Color info = Color(0xFF4A90E2);

  // Dividers & Borders
  static const Color divider = Color(0xFFEDEAE5);
}

// ─────────────────────────────────────────────────────────────────────────────
// AppGradients
// ─────────────────────────────────────────────────────────────────────────────
class AppGradients {
  static const LinearGradient primary = LinearGradient(
    colors: [
      Color(0xFFE07A5F),
      Color(0xFFC96A4F),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emerald = LinearGradient(
    colors: [
      AppColors.secondary, // Deep Emerald
      AppColors.emeraldDark,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient scanButton = LinearGradient(
    colors: [
      Color(0xFF1A3A2A), // Emerald
      Color(0xFF2C553D), // Lighter Emerald
      Color(0xFFC96A4F), // Brushed Copper edge
    ],
    stops: [0.0, 0.7, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glass = LinearGradient(
    colors: [
      Colors.white,
      Colors.white,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// AppTextStyles (Using Poppins)
// ─────────────────────────────────────────────────────────────────────────────
class AppTextStyles {
  // Headlines
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  // Titles
  static const TextStyle titleMedium = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Body
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ThemeData
// ─────────────────────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Poppins',
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: AppTextStyles.titleMedium,
      ),
    );
  }
}
