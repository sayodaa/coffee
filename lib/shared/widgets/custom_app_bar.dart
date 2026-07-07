import 'dart:ui';

import 'package:coffee_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium glassmorphism AppBar used across all inner pages.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showNotificationDot;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showNotificationDot = false,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkBackground.withOpacity(0.85)
                : AppColors.lightSurface.withOpacity(0.90),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? AppColors.caramel.withOpacity(0.12)
                    : AppColors.caramel.withOpacity(0.18),
                width: 1,
              ),
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
            title: Text(
              title,
              style: GoogleFonts.inter(
                color: isDark ? AppColors.cream : AppColors.textPrimaryLight,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            actions: [
              _AvatarBadge(showDot: showNotificationDot),
              if (actions != null) ...actions!,
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// ── Avatar badge ──────────────────────────────────────────────────────────────

class _AvatarBadge extends StatelessWidget {
  final bool showDot;
  const _AvatarBadge({required this.showDot});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppColors.coffeeGradient,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? AppColors.caramel.withOpacity(0.4)
                    : AppColors.caramel.withOpacity(0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.caramel.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.person, color: AppColors.cream, size: 18),
          ),
          if (showDot)
            Positioned(
              top: 1,
              right: 1,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBackground
                        : AppColors.lightSurface,
                    width: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
