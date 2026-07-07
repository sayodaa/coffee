import 'package:coffee_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ══════════════════════════════════════════════════════════════════
/// PREMIUM COFFEE BAR — App Theme
/// Dark Mode: "Luxury Espresso" — deep blacks, caramel gold accents
/// Light Mode: "Warm Latte" — soft cream, warm brown accents
/// ══════════════════════════════════════════════════════════════════
class AppTheme {
  AppTheme._();

  // ─── Input Decoration ────────────────────────────────────────────────────

  static InputDecorationTheme _inputDecorationTheme({required bool isDark}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.caramel, width: 1.5),
    );
    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
    );

    return InputDecorationTheme(
      filled: true,
      fillColor: isDark
          ? AppColors.darkSurfaceElevated.withOpacity(0.7)
          : AppColors.lightSurface,
      border: border,
      enabledBorder: border,
      focusedBorder: focusedBorder,
      errorBorder: errorBorder,
      focusedErrorBorder: errorBorder,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      hintStyle: TextStyle(
        color: isDark
            ? AppColors.textSecondaryDark.withOpacity(0.5)
            : AppColors.textSecondaryLight.withOpacity(0.5),
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      labelStyle: TextStyle(
        color:
            isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        fontSize: 14,
      ),
      prefixIconColor: AppColors.caramel,
      suffixIconColor: AppColors.caramel.withOpacity(0.7),
    );
  }

  // ─── Elevated Button Theme ────────────────────────────────────────────────

  static ElevatedButtonThemeData _elevatedButtonTheme({required bool isDark}) {
    return ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return isDark ? AppColors.darkBorder : AppColors.lightBorder;
          }
          return AppColors.caramel;
        }),
        foregroundColor: WidgetStateProperty.all(AppColors.cream),
        overlayColor: WidgetStateProperty.all(Colors.white.withOpacity(0.12)),
        elevation: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return 2;
          return 6;
        }),
        shadowColor:
            WidgetStateProperty.all(AppColors.caramel.withOpacity(0.4)),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        minimumSize: WidgetStateProperty.all(const Size(double.infinity, 52)),
        textStyle: WidgetStateProperty.all(
          GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.3),
        ),
      ),
    );
  }

  // ─── Text Button Theme ────────────────────────────────────────────────────

  static TextButtonThemeData _textButtonTheme({required bool isDark}) {
    return TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(AppColors.caramel),
        overlayColor:
            WidgetStateProperty.all(AppColors.caramel.withOpacity(0.1)),
        textStyle: WidgetStateProperty.all(
          GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // ─── Dialog Theme ─────────────────────────────────────────────────────────

  static DialogThemeData _dialogTheme({required bool isDark}) {
    return DialogThemeData(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      elevation: 24,
      shadowColor: Colors.black54,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: GoogleFonts.inter(
        color: isDark ? AppColors.cream : AppColors.textPrimaryLight,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: GoogleFonts.inter(
        color:
            isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        fontSize: 14,
        height: 1.5,
      ),
    );
  }

  // ─── Snack Bar Theme ──────────────────────────────────────────────────────

  static SnackBarThemeData _snackBarTheme({required bool isDark}) {
    return SnackBarThemeData(
      backgroundColor: isDark ? AppColors.darkBrown : AppColors.warmBrown,
      contentTextStyle: GoogleFonts.inter(color: AppColors.cream, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      behavior: SnackBarBehavior.floating,
      elevation: 8,
    );
  }

  // ─── Chip Theme ──────────────────────────────────────────────────────────

  static ChipThemeData _chipTheme({required bool isDark}) {
    return ChipThemeData(
      backgroundColor:
          isDark ? AppColors.darkSurfaceElevated : AppColors.softBeige,
      selectedColor: AppColors.caramel,
      labelStyle: GoogleFonts.inter(
        color: isDark ? AppColors.latte : AppColors.textPrimaryLight,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      side: BorderSide(
        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        width: 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // LIGHT THEME — "Warm Latte"
  // ═══════════════════════════════════════════════════════════════════

  static ThemeData get lightTheme {
    const isDark = false;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primaryRoyalBlue,
      scaffoldBackgroundColor: AppColors.lightBackground,
      cardColor: AppColors.lightSurface,
      dividerColor: AppColors.lightBorder,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryRoyalBlue,
        secondary: AppColors.secondarySkyBlue,
        surface: AppColors.lightSurface,
        onSurface: AppColors.textPrimaryLight,
        error: AppColors.error,
        onPrimary: AppColors.cream,
        tertiary: AppColors.caramel,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.05),
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.textPrimaryLight,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(
            color: AppColors.textPrimaryLight,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.5),
        displayMedium: GoogleFonts.inter(
            color: AppColors.textPrimaryLight,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.0),
        headlineLarge: GoogleFonts.inter(
            color: AppColors.textPrimaryLight,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5),
        headlineMedium: GoogleFonts.inter(
            color: AppColors.textPrimaryLight,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3),
        titleLarge: GoogleFonts.inter(
            color: AppColors.textPrimaryLight,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2),
        titleMedium: GoogleFonts.inter(
            color: AppColors.textPrimaryLight, fontWeight: FontWeight.w500),
        titleSmall: GoogleFonts.inter(
            color: AppColors.textPrimaryLight, fontWeight: FontWeight.w500),
        bodyLarge: GoogleFonts.inter(
            color: AppColors.textPrimaryLight, fontSize: 16, height: 1.5),
        bodyMedium: GoogleFonts.inter(
            color: AppColors.textSecondaryLight, fontSize: 14, height: 1.5),
        bodySmall: GoogleFonts.inter(
            color: AppColors.textSecondaryLight, fontSize: 12, height: 1.4),
        labelLarge: GoogleFonts.inter(
            color: AppColors.textSecondaryLight,
            fontWeight: FontWeight.w600,
            fontSize: 14),
        labelMedium: GoogleFonts.inter(
            color: AppColors.textSecondaryLight,
            fontWeight: FontWeight.w500,
            fontSize: 12),
        labelSmall: GoogleFonts.inter(
            color: AppColors.textSecondaryLight,
            fontWeight: FontWeight.w500,
            fontSize: 11,
            letterSpacing: 0.5),
      ),
      iconTheme:
          const IconThemeData(color: AppColors.primaryRoyalBlue, size: 24),
      inputDecorationTheme: _inputDecorationTheme(isDark: isDark),
      elevatedButtonTheme: _elevatedButtonTheme(isDark: isDark),
      textButtonTheme: _textButtonTheme(isDark: isDark),
      dialogTheme: _dialogTheme(isDark: isDark),
      snackBarTheme: _snackBarTheme(isDark: isDark),
      chipTheme: _chipTheme(isDark: isDark),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.caramel;
          return Colors.grey.shade400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected))
            return AppColors.caramel.withOpacity(0.4);
          return Colors.grey.shade300;
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface.withOpacity(0.95),
        selectedItemColor: AppColors.caramel,
        unselectedItemColor: Colors.grey,
        elevation: 8,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.caramel,
        foregroundColor: AppColors.cream,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.caramel,
        linearTrackColor: AppColors.lightBorder,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // DARK THEME — "Luxury Espresso"
  // ═══════════════════════════════════════════════════════════════════

  static ThemeData get darkTheme {
    const isDark = true;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.caramel,
      scaffoldBackgroundColor: AppColors.darkBackground,
      cardColor: AppColors.darkSurface,
      dividerColor: AppColors.darkBorder,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.caramel,
        secondary: AppColors.latte,
        surface: AppColors.darkSurface,
        onSurface: AppColors.cream,
        error: AppColors.error,
        onPrimary: AppColors.espresso,
        tertiary: AppColors.caramel,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.cream,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.cream,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(
            color: AppColors.cream,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.5),
        displayMedium: GoogleFonts.inter(
            color: AppColors.cream,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.0),
        headlineLarge: GoogleFonts.inter(
            color: AppColors.cream,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5),
        headlineMedium: GoogleFonts.inter(
            color: AppColors.cream,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3),
        titleLarge: GoogleFonts.inter(
            color: AppColors.cream,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2),
        titleMedium: GoogleFonts.inter(
            color: AppColors.cream, fontWeight: FontWeight.w500),
        titleSmall: GoogleFonts.inter(
            color: AppColors.cream, fontWeight: FontWeight.w500),
        bodyLarge: GoogleFonts.inter(
            color: AppColors.cream, fontSize: 16, height: 1.5),
        bodyMedium: GoogleFonts.inter(
            color: AppColors.textSecondaryDark, fontSize: 14, height: 1.5),
        bodySmall: GoogleFonts.inter(
            color: AppColors.textSecondaryDark, fontSize: 12, height: 1.4),
        labelLarge: GoogleFonts.inter(
            color: AppColors.textSecondaryDark,
            fontWeight: FontWeight.w600,
            fontSize: 14),
        labelMedium: GoogleFonts.inter(
            color: AppColors.textSecondaryDark,
            fontWeight: FontWeight.w500,
            fontSize: 12),
        labelSmall: GoogleFonts.inter(
            color: AppColors.textSecondaryDark,
            fontWeight: FontWeight.w500,
            fontSize: 11,
            letterSpacing: 0.5),
      ),
      iconTheme: const IconThemeData(color: AppColors.caramel, size: 24),
      inputDecorationTheme: _inputDecorationTheme(isDark: isDark),
      elevatedButtonTheme: _elevatedButtonTheme(isDark: isDark),
      textButtonTheme: _textButtonTheme(isDark: isDark),
      dialogTheme: _dialogTheme(isDark: isDark),
      snackBarTheme: _snackBarTheme(isDark: isDark),
      chipTheme: _chipTheme(isDark: isDark),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.caramel;
          return Colors.grey.shade600;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected))
            return AppColors.caramel.withOpacity(0.4);
          return Colors.grey.shade800;
        }),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.caramel,
        unselectedItemColor: Color(0xFF6B635B),
        elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.caramel,
        foregroundColor: AppColors.espresso,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.caramel,
        linearTrackColor: AppColors.darkBorder,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      ),
    );
  }
}
