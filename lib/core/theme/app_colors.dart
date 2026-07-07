import 'package:flutter/material.dart';

/// ══════════════════════════════════════════════════════════════════
/// PREMIUM COFFEE BAR — Design Tokens
/// A curated coffee-inspired palette. Variable names are preserved
/// to avoid breaking existing code.
/// ══════════════════════════════════════════════════════════════════
class AppColors {
  AppColors._();

  // ─── Coffee Palette ─────────────────────────────────────────────────────────

  static const Color espresso = Color(0xFF0E0A07); // Deepest dark
  static const Color mocha = Color(0xFF1B0F0A); // Rich dark brown
  static const Color darkBrown = Color(0xFF2D1B12); // Deep surface
  static const Color warmBrown = Color(0xFF3E2723); // Roast brown
  static const Color coffeeBrown = Color(0xFF5C3621); // Medium roast
  static const Color caramel = Color(0xFFC68E52); // Caramel accent
  static const Color latte = Color(0xFFE6CCB2); // Latte
  static const Color cream = Color(0xFFFFF8F3); // Soft cream
  static const Color softBeige = Color(0xFFF5EDE3); // Light beige
  static const Color darkChocolate = Color(0xFF1C0F08); // Dark choc

  // ─── Mapped to existing names (no breaking changes) ──────────────────────

  // Backgrounds (Dark)
  static const Color darkBackground = espresso;
  static const Color darkSurface = Color(0xFF1B1512);
  static const Color darkSurfaceElevated = Color(0xFF2A1E18);
  static const Color darkBorder = Color(0xFF3A2F29);

  // Backgrounds (Light)
  static const Color lightBackground = Color(0xFFF8F4F0);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE8DED5);

  // Accent (mapped to old names)
  static const Color primaryRoyalBlue = coffeeBrown; // Coffee Brown
  static const Color primaryIndigo = warmBrown; // Espresso / Roast
  static const Color secondarySkyBlue = latte;
  static const Color secondaryViolet = caramel;
  static const Color accent = caramel;

  // ─── Gradients ───────────────────────────────────────────────────────────

  static const LinearGradient coffeeGradient = LinearGradient(
    colors: [Color(0xFFC68E52), Color(0xFF7A4A2A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradientDark = LinearGradient(
    colors: [warmBrown, caramel],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradientLight = LinearGradient(
    colors: [coffeeBrown, caramel],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Cinematic image overlay — hero screens
  static const LinearGradient cinematicOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x33000000), // 20% top
      Color(0x88110800), // 53% mid
      Color(0xFF0A0500), // 100% bottom
    ],
    stops: [0.0, 0.55, 1.0],
  );

  /// Cinematic overlay — lighter (for partial headers)
  static const LinearGradient headerOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x22000000),
      Color(0xCC0A0500),
    ],
  );

  // ─── Text Colors ─────────────────────────────────────────────────────────

  static const Color textPrimaryDark = cream;
  static const Color textSecondaryDark = Color(0xFFC8B6A6);
  static const Color textPrimaryLight = Color(0xFF2D1F18);
  static const Color textSecondaryLight = Color(0xFF7B6657);

  // ─── Status Colors ───────────────────────────────────────────────────────

  static const Color success = Color(0xFF4E8B5F);
  static const Color warning = Color(0xFFE0A458);
  static const Color error = Color(0xFFB24040);
  static const Color info = Color(0xFF8D6E63);

  // ─── Chart Colors ────────────────────────────────────────────────────────

  static const Color chartPrimary = coffeeBrown;
  static const Color chartSecondary = caramel;
  static const Color chartTertiary = latte;
  static const Color chartCyan = Color(0xFFA1887F);
  static const Color chartAmber = warning;
  static const Color chartEmerald = Color(0xFF6A8F70);
  static const Color chartRoyalBlue = Color(0xFF8D6E63);

  // ─── Nav Bar ─────────────────────────────────────────────────────────────

  static const Color navActive = caramel;
  static Color get navInactive => const Color(0xFF8B8178);

  // ─── Glass / Surface Overlays ────────────────────────────────────────────

  static Color glass(double opacity) =>
      const Color(0xFF1B1512).withOpacity(opacity);
  static Color glassLight(double opacity) =>
      const Color(0xFFFFF8F3).withOpacity(opacity);
}
