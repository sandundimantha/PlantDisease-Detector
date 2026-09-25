import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppColors — Single Source of Truth for every color in the app
// ─────────────────────────────────────────────────────────────────────────────
class AppColors {
  AppColors._(); // Prevent instantiation

  // ── Brand: Deep Emerald ──────────────────────────────────────────────────
  static const Color primary       = Color(0xFF0B3C2D);
  static const Color primaryDark   = Color(0xFF07271D);
  static const Color primaryLight  = Color(0xFF165A45);
  static const Color emeraldLeaf   = Color(0xFF2E7D32);

  // ── Brand: Brushed Copper & Terracotta ────────────────────────────────────
  static const Color copper        = Color(0xFFC87D55);
  static const Color copperLight   = Color(0xFFD98A5F);
  static const Color copperDark    = Color(0xFFA65B34);
  static const Color secondary     = copper;
  static const Color accent        = copperLight;

  // ── Backgrounds & Surfaces ────────────────────────────────────────────────
  static const Color background    = Color(0xFFF4F6F4);
  static const Color surface       = Colors.white;
  static const Color cardBg        = Colors.white;
  static const Color mintLight     = Color(0xFFE8F5E9);
  static const Color webOuterBg    = Color(0xFF131524); // Dark bg for web wrapper

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF0F241C);
  static const Color textSecondary = Color(0xFF6B7C75);
  static const Color textMuted     = Color(0xFF8A9A93);
  static const Color textOnDark    = Colors.white;

  // ── Semantic States ───────────────────────────────────────────────────────
  static const Color error         = Color(0xFFD94E4E);
  static const Color success       = Color(0xFF2E7D32);
  static const Color warning       = Color(0xFFC87D55);
  static const Color info          = Color(0xFF1976D2);

  // ── Severity Colors ───────────────────────────────────────────────────────
  static const Color severityHigh    = Color(0xFFE07A5F);
  static const Color severityMedium  = Color(0xFFF5A623);
  static const Color severityLow     = Color(0xFFA8B4C0);
  static const Color severityDefault = Color(0xFF81B29A); // Healthy / None

  // ── Outbreak / Radar Colors ───────────────────────────────────────────────
  static const Color outbreakHigh    = Color(0xFFE07A5F);
  static const Color outbreakMedium  = Color(0xFFF2A34A);
  static const Color outbreakLow     = Color(0xFF81B29A);

  // ── Functional / Action Colors ────────────────────────────────────────────
  static const Color whatsapp        = Color(0xFF25D366);
  static const Color callAction      = Color(0xFF81B29A);
  static const Color skyBlue         = Color(0xFF4A90E2);
  static const Color skyLight        = Color(0xFF87CEFA);

  // ── Dividers & Borders ────────────────────────────────────────────────────
  static const Color divider         = Color(0xFFE2E8E4);
  static const Color border          = Color(0xFFE0E7E2);
  static const Color cardBorder      = Color(0xFFE0E7E2);
  static const Color dividerSubtle   = Color(0x0F2D3748);

  // ── Profile & Settings ────────────────────────────────────────────────────
  static const Color settingsIcon       = Color(0xFF9AA5B4);
  static const Color settingsChevron    = Color(0xFFC8D0DA);
  static const Color settingsToggleOff  = Color(0xFFEDEAE5);
  static const Color signOutBg          = Color(0xFFFFF5F2);
  static const Color signOutText        = Color(0xFFE07A5F);
  static const Color achievementBadge   = Color(0xFF81B29A);
  static const Color achievementInactive= Color(0xFFF5F3F0);
  static const Color navInactive        = Color(0xFF8A9A93);
  static const Color tabInactiveBg      = Color(0xFFEDEAE5);

  // ── Header & Accent Tints ─────────────────────────────────────────────────
  static const Color emeraldMist        = Color(0xFFB5D5C5);

  // ── Tile Surfaces ─────────────────────────────────────────────────────────
  static const Color selectedTileBg     = Color(0xFFFAF4F0);
  static const Color officerCardBg      = Color(0xFFF8F5F0);

  // ── Smart Image Placeholders ──────────────────────────────────────────────
  static const Color imagePlaceholder   = Color(0xFF1A3A2A);
  static const Color imageIcon          = Color(0xFF81B29A);
  static const Color imageLoadingBg     = Color(0xFFF0EDE8);
  static const Color imageLoadingSpinner= Color(0xFFE07A5F);

  // ── Dark UI Backgrounds (Disease Radar) ───────────────────────────────────
  static const Color radarDarkBg        = Color(0xFF0A0F1E);
  static const Color radarChipBg        = Color(0xFF1A2340);

  // ── Social Auth ───────────────────────────────────────────────────────────
  static const Color facebook           = Color(0xFF1877F2);

  // ── Health / Progress Bar ─────────────────────────────────────────────────
  static const Color healthBarLight     = Color(0xFFA8D5BE);

  // ── Misc Neutrals ─────────────────────────────────────────────────────────
  static const Color overlayDark        = Color(0xFF2D3748);
  static const Color cardSurface        = Color(0xFFFAFAF8);
  static const Color starActive         = Color(0xFFF5A623);
  static const Color darkResultBg       = Color(0xFF0D2518);
  static const Color emeraldDeep        = Color(0xFF5A9E7C);

  // ── Gradient Endpoints (used by AppGradients) ─────────────────────────────
  static const Color profileGradStart   = Color(0xFFE07A5F);
  static const Color profileGradEnd     = Color(0xFFC96A4F);
  static const Color avatarGradStart    = Color(0xFFE07A5F);
  static const Color avatarGradEnd      = Color(0xFFF2A98A);
  static const Color bannerWarmStart    = Color(0xFFEDE5DF);
  static const Color bannerWarmEnd      = Color(0xFFF7F2EE);
  static const Color officerOverlayStart= Color(0x80000000);
  static const Color officerOverlayEnd  = Color(0xFF0D1F15);

  // ── Onboarding Gradient Endpoints ─────────────────────────────────────────
  static const Color onboardSlide1Start = Color(0xFF2D5016);
  static const Color onboardSlide1End   = Color(0xFF4A7C2F);
  static const Color onboardSlide2Start = Color(0xFF1A3A2A);
  static const Color onboardSlide2End   = Color(0xFF2E6B4F);
  static const Color onboardSlide3Start = Color(0xFF3B2506);
  static const Color onboardSlide3End   = Color(0xFF7A5C2E);

  // ── Saved Items Icon Gradients ────────────────────────────────────────────
  static const Color savedChemicalStart = Color(0xFFE07A5F);
  static const Color savedChemicalEnd   = Color(0xFFC96A4F);
  static const Color savedOrganicStart  = Color(0xFF81B29A);
  static const Color savedOrganicEnd    = Color(0xFF5A9E7C);
  static const Color savedWarningStart  = Color(0xFFF5A623);
  static const Color savedWarningEnd    = Color(0xFFD38B1B);
  static const Color savedInfoStart     = Color(0xFF4A90E2);
  static const Color savedInfoEnd       = Color(0xFF357ABD);
}
