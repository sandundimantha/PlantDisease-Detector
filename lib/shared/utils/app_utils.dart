import 'package:flutter/material.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Utility helpers used across the ML module
/// ─────────────────────────────────────────────────────────────────────────────

class AppUtils {
  AppUtils._();

  /// Confidence score → display color
  static Color confidenceColor(double score) {
    if (score > 0.8) return AppColors.success;
    if (score >= 0.5) return AppColors.warning;
    return AppColors.error;
  }

  /// Confidence score → human-readable label
  static String confidenceLabel(double score) {
    if (score > 0.8) return 'High Confidence';
    if (score >= 0.5) return 'Moderate Confidence';
    return 'Low Confidence';
  }

  /// Formats a date like "15 Aug 2026"
  static String formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  /// Shows a styled error snackbar
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTextStyles.bodyMedium),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Shows a styled success snackbar
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
                child: Text(message, style: AppTextStyles.bodyMedium)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
