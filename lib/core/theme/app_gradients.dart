import 'package:flutter/material.dart';
import 'package:plant_disease_detector/core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppGradients — Single Source of Truth for every gradient in the app
// ─────────────────────────────────────────────────────────────────────────────
class AppGradients {
  AppGradients._(); // Prevent instantiation

  // ── Primary Emerald ───────────────────────────────────────────────────────
  static const LinearGradient primary = LinearGradient(
    colors: [AppColors.primary, AppColors.primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldHeader = LinearGradient(
    colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Brushed Copper Metallic ───────────────────────────────────────────────
  static const LinearGradient copper = LinearGradient(
    colors: [AppColors.copperLight, AppColors.copper, AppColors.copperDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Scan Button ───────────────────────────────────────────────────────────
  static const LinearGradient scanButton = LinearGradient(
    colors: [AppColors.primaryLight, AppColors.primary, AppColors.primaryDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Glass (neutral white) ─────────────────────────────────────────────────
  static const LinearGradient glass = LinearGradient(
    colors: [Colors.white, Colors.white],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Profile Card ──────────────────────────────────────────────────────────
  static const LinearGradient profileCard = LinearGradient(
    colors: [AppColors.profileGradStart, AppColors.profileGradEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Profile Avatar Fallback ───────────────────────────────────────────────
  static const LinearGradient profileAvatar = LinearGradient(
    colors: [AppColors.avatarGradStart, AppColors.avatarGradEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Pro Upgrade Banner ────────────────────────────────────────────────────
  static const LinearGradient proUpgradeBanner = LinearGradient(
    colors: [AppColors.bannerWarmStart, AppColors.bannerWarmEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Officer Screen Overlay ────────────────────────────────────────────────
  static const LinearGradient officerOverlay = LinearGradient(
    colors: [AppColors.officerOverlayStart, AppColors.officerOverlayEnd],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Onboarding Slide Backgrounds ──────────────────────────────────────────
  static const List<LinearGradient> onboardingSlides = [
    LinearGradient(
      colors: [AppColors.onboardSlide1Start, AppColors.onboardSlide1End],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    LinearGradient(
      colors: [AppColors.onboardSlide2Start, AppColors.onboardSlide2End],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    LinearGradient(
      colors: [AppColors.onboardSlide3Start, AppColors.onboardSlide3End],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  ];

  // ── Saved Items Icon Gradients ────────────────────────────────────────────
  static const LinearGradient savedChemical = LinearGradient(
    colors: [AppColors.savedChemicalStart, AppColors.savedChemicalEnd],
  );

  static const LinearGradient savedOrganic = LinearGradient(
    colors: [AppColors.savedOrganicStart, AppColors.savedOrganicEnd],
  );

  static const LinearGradient savedWarning = LinearGradient(
    colors: [AppColors.savedWarningStart, AppColors.savedWarningEnd],
  );

  static const LinearGradient savedInfo = LinearGradient(
    colors: [AppColors.savedInfoStart, AppColors.savedInfoEnd],
  );

  // ── Weather ───────────────────────────────────────────────────────────────
  static const LinearGradient weatherSky = LinearGradient(
    colors: [AppColors.skyBlue, AppColors.skyLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
