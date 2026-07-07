import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme Cubit for managing app theme with persistence.
///
/// Features:
/// - Supports Light, Dark, and System modes
/// - Persists theme choice using SharedPreferences
/// - Smooth animated theme transitions
class ThemeCubit extends Cubit<ThemeState> {
  static const String _themeKey = 'theme_mode';

  ThemeCubit() : super(ThemeState(ThemeMode.dark, isLoading: true)) {
    _loadTheme();
  }

  /// Load saved theme from SharedPreferences
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeKey);

      ThemeMode mode;
      if (themeIndex == null) {
        // Default to dark mode (Luxury Dark Obsidian)
        mode = ThemeMode.dark;
      } else {
        mode = ThemeMode.values[themeIndex];
      }

      emit(ThemeState(mode));
    } catch (e) {
      // Fallback to dark mode on error
      emit(ThemeState(ThemeMode.dark));
    }
  }

  /// Set theme mode and persist to SharedPreferences
  Future<void> setThemeMode(ThemeMode mode) async {
    emit(ThemeState(mode));

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, mode.index);
    } catch (e) {
      // Silently fail persistence - theme still applied in memory
    }
  }

  /// Toggle between light and dark modes
  Future<void> toggleTheme() async {
    final newMode = state.themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    await setThemeMode(newMode);
  }

  /// Check if current theme is dark
  bool get isDarkMode => state.themeMode == ThemeMode.dark;
}

/// Theme state with loading indicator
class ThemeState {
  final ThemeMode themeMode;
  final bool isLoading;

  ThemeState(this.themeMode, {this.isLoading = false});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThemeState &&
        other.themeMode == themeMode &&
        other.isLoading == isLoading;
  }

  @override
  int get hashCode => themeMode.hashCode ^ isLoading.hashCode;
}
