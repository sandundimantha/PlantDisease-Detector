import 'package:flutter/material.dart';
import 'package:plant_disease_detector/core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppShadows — Reusable box shadow tokens
// ─────────────────────────────────────────────────────────────────────────────
class AppShadows {
  AppShadows._(); // Prevent instantiation

  /// Subtle card shadow — used for standard white cards
  static final BoxShadow cardSoft = BoxShadow(
    color: Colors.black.withOpacity(0.04),
    blurRadius: 8,
    offset: const Offset(0, 2),
  );

  /// Medium-elevation shadow — used for nav bars, modals
  static final BoxShadow elevated = BoxShadow(
    color: Colors.black.withOpacity(0.10),
    blurRadius: 24,
    offset: const Offset(0, 8),
  );

  /// Card with slightly more lift
  static final BoxShadow cardMedium = BoxShadow(
    color: Colors.black.withOpacity(0.06),
    blurRadius: 16,
    offset: const Offset(0, 6),
  );

  /// Glassmorphic card shadow
  static final BoxShadow glassDark = BoxShadow(
    color: Colors.black.withOpacity(0.15),
    blurRadius: 16,
    offset: const Offset(0, 4),
  );

  /// Copper glow — used on primary action buttons
  static final BoxShadow copperGlow = BoxShadow(
    color: AppColors.copper.withOpacity(0.3),
    blurRadius: 10,
    spreadRadius: 1,
  );

  /// Primary glow — used on scan button
  static final BoxShadow primaryGlow = BoxShadow(
    color: AppColors.primary.withOpacity(0.5),
    blurRadius: 18,
    offset: const Offset(0, 8),
  );

  /// Profile card shadow
  static final BoxShadow profileCard = BoxShadow(
    color: AppColors.severityHigh.withOpacity(0.35),
    blurRadius: 24,
    offset: const Offset(0, 12),
  );
}
