import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A luxury glassmorphic floating navigation bar.
class LuxuryFloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const LuxuryFloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const List<_NavItem> _items = [
    _NavItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
    ),
    _NavItem(
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2,
      label: 'Materials',
    ),
    _NavItem(
      icon: Icons.point_of_sale_outlined,
      activeIcon: Icons.point_of_sale,
      label: 'Sales',
    ),
    _NavItem(
      icon: Icons.analytics_outlined,
      activeIcon: Icons.analytics,
      label: 'Reports',
    ),
    _NavItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = (screenWidth - 32 - 48) / _items.length;

    // Define colors dynamically
    final surfaceColor = theme.cardColor.withOpacity(isDark ? 0.7 : 0.85);
    final borderColor = theme.dividerColor.withOpacity(0.5);
    final shadowColor = theme.shadowColor.withOpacity(0.05);
    final activeColor = theme.colorScheme.primary;
    final inactiveColor =
        theme.iconTheme.color?.withOpacity(0.5) ?? Colors.grey;

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          height: 72,
          child: Stack(
            children: [
              // Frosted glass background
              ClipRRect(
                borderRadius: BorderRadius.circular(36),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(36),
                      border: Border.all(width: 1.5, color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: shadowColor,
                          spreadRadius: 2,
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Animated glow indicator
              AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: Alignment(
                  -1 + (currentIndex * 2 / (_items.length - 1)),
                  0,
                ),
                child: Container(
                  width: itemWidth,
                  alignment: Alignment.center,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: activeColor.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Navigation items
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(_items.length, (index) {
                    final isActive = index == currentIndex;
                    final item = _items[index];

                    return _NavItemWidget(
                      item: item,
                      isActive: isActive,
                      width: itemWidth,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onTap(index);
                      },
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _NavItemWidget extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final double width;
  final VoidCallback onTap;
  final Color activeColor;
  final Color inactiveColor;

  const _NavItemWidget({
    required this.item,
    required this.isActive,
    required this.width,
    required this.onTap,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive
                    ? activeColor.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isActive ? item.activeIcon : item.icon,
                color: isActive ? activeColor : inactiveColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isActive ? activeColor : inactiveColor,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                fontFamily: Theme.of(context).textTheme.bodySmall?.fontFamily,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}
