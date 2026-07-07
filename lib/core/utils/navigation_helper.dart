import 'package:coffee_app/core/localization/json_localizations.dart';
import 'package:coffee_app/core/localization/lang_keys.dart';
import 'package:flutter/material.dart';

/// Represents a single navigation destination.
class NavDestination {
  final IconData icon;
  final String Function(BuildContext) label;
  final bool adminOnly;

  const NavDestination({
    required this.icon,
    required this.label,
    this.adminOnly = false,
  });
}

/// Single source of truth for navigation.
class NavigationHelper {
  NavigationHelper._();

  /// All destinations in their original order.
  static final List<NavDestination> allDestinations = [
    NavDestination(
      icon: Icons.dashboard_rounded,
      label: (c) => c.tr(LangKeys.nav_dashboard),
      adminOnly: true,
    ),
    NavDestination(
      icon: Icons.inventory_2_rounded,
      label: (c) => c.tr(LangKeys.nav_stock),
    ),
    NavDestination(
      icon: Icons.point_of_sale_rounded,
      label: (c) => c.tr(LangKeys.nav_sales),
    ),
    NavDestination(
      icon: Icons.analytics_rounded,
      label: (c) => c.tr(LangKeys.nav_reports),
      adminOnly: true,
    ),
    NavDestination(
      icon: Icons.menu_book_rounded,
      label: (c) => c.tr(LangKeys.recipes),
    ),
    NavDestination(
      icon: Icons.settings_rounded,
      label: (c) => c.tr(LangKeys.nav_settings),
    ),
  ];

  /// Returns true if current role is admin.
  static bool isAdmin(String? role) {
    return (role ?? '').trim().toLowerCase() == 'admin';
  }

  /// Returns destinations available for the current role.
  static List<NavDestination> getDestinationsForRole(String? role) {
    if (isAdmin(role)) {
      return allDestinations;
    }

    return allDestinations.where((d) => !d.adminOnly).toList();
  }

  /// Returns icons for BottomNavigationBar.
  static List<IconData> getIconsForRole(String? role) {
    return getDestinationsForRole(role)
        .map((destination) => destination.icon)
        .toList();
  }

  /// Returns labels for BottomNavigationBar.
  static List<String Function(BuildContext)> getLabelsForRole(String? role) {
    return getDestinationsForRole(role)
        .map((destination) => destination.label)
        .toList();
  }

  /// Number of navigation items.
  static int getNavItemCount(String? role) {
    return getDestinationsForRole(role).length;
  }

  /// Checks whether an index is valid.
  static bool isValidIndex(int index, String? role) {
    return index >= 0 && index < getNavItemCount(role);
  }

  /// Default selected index.
  static int getDefaultIndex(String? role) {
    return 0;
  }

  /// Maps original index to filtered index.
  /// Returns null if the destination is hidden.
  static int? getFilteredIndex(int originalIndex, String? role) {
    if (originalIndex < 0 || originalIndex >= allDestinations.length) {
      return null;
    }

    if (isAdmin(role)) {
      return originalIndex;
    }

    if (allDestinations[originalIndex].adminOnly) {
      return null;
    }

    int filteredIndex = 0;

    for (int i = 0; i < originalIndex; i++) {
      if (!allDestinations[i].adminOnly) {
        filteredIndex++;
      }
    }

    return filteredIndex;
  }

  /// Maps filtered index back to original index.
  /// Useful when using PageView.
  static int? getOriginalIndex(int filteredIndex, String? role) {
    final destinations = getDestinationsForRole(role);

    if (filteredIndex < 0 || filteredIndex >= destinations.length) {
      return null;
    }

    final destination = destinations[filteredIndex];

    return allDestinations.indexOf(destination);
  }
}
