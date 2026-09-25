// ─────────────────────────────────────────────────────────────────────────────
// AppSpacing & AppRadius — Layout dimension tokens
// ─────────────────────────────────────────────────────────────────────────────

/// Consistent spacing scale used across the entire app.
class AppSpacing {
  AppSpacing._(); // Prevent instantiation

  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 16;
  static const double lg  = 24;
  static const double xl  = 32;
  static const double xxl = 48;
}

/// Consistent border-radius scale.
class AppRadius {
  AppRadius._(); // Prevent instantiation

  static const double sm   = 12;
  static const double md   = 16;
  static const double lg   = 20;
  static const double xl   = 24;
  static const double pill = 28;
  static const double full = 50;
}
