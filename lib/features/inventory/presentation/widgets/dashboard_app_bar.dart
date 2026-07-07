import 'dart:ui';

import 'package:coffee_app/auth/providers/auth_provider.dart';
import 'package:coffee_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// Cinematic SliverAppBar for the Dashboard home screen.
/// Uses coffee1.jpg as a full-bleed hero image with a dark gradient overlay.
/// Collapses to a glass blur bar when the user scrolls.
class DashboardAppBar extends StatelessWidget {
  const DashboardAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    return SliverAppBar(
      expandedHeight: 220 + topPadding,
      pinned: true,
      floating: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: _CinematicFlexibleSpace(
        isAdmin: isAdmin,
        topPadding: topPadding,
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: _GradientDivider(),
      ),
    );
  }
}

// ── Flexible space ────────────────────────────────────────────────────────────

class _CinematicFlexibleSpace extends StatelessWidget {
  final bool isAdmin;
  final double topPadding;
  const _CinematicFlexibleSpace({
    required this.isAdmin,
    required this.topPadding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final expandRatio =
          ((constraints.maxHeight - kToolbarHeight - topPadding) / (220))
              .clamp(0.0, 1.0);
      final isCollapsed = expandRatio < 0.1;

      return Stack(
        fit: StackFit.expand,
        children: [
          // ── Hero image ─────────────────────────────────────────────────
          Image.asset('assets/images/coffee1.jpg', fit: BoxFit.cover),

          // ── Gradient overlay ───────────────────────────────────────────
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x44000000),
                  Color(0xBB0A0500),
                ],
                stops: [0.0, 1.0],
              ),
            ),
          ),

          // ── Glass collapse layer ───────────────────────────────────────
          AnimatedOpacity(
            opacity: isCollapsed ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  color: AppColors.darkBackground.withOpacity(0.75),
                ),
              ),
            ),
          ),

          // ── Content ────────────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 20, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Expanded-only branding
                        AnimatedOpacity(
                          opacity: expandRatio,
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            'Coffee Bar',
                            style: GoogleFonts.inter(
                              color: AppColors.caramel,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Welcome back,',
                          style: GoogleFonts.inter(
                            color: AppColors.latte.withOpacity(0.75),
                            fontSize: isCollapsed ? 11 : 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          isAdmin ? 'Administrator' : 'Barista',
                          style: GoogleFonts.inter(
                            color: AppColors.cream,
                            fontSize: isCollapsed ? 18 : 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Expanded-only: role badge + notification
                  AnimatedOpacity(
                    opacity: expandRatio,
                    duration: const Duration(milliseconds: 200),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _RoleBadge(isAdmin: isAdmin),
                        const SizedBox(height: 8),
                        _NotificationButton(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }
}

// ── Role badge ────────────────────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  final bool isAdmin;
  const _RoleBadge({required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        gradient: isAdmin ? AppColors.coffeeGradient : null,
        color: isAdmin ? null : AppColors.darkSurfaceElevated.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.caramel.withOpacity(isAdmin ? 0.0 : 0.3),
          width: 1,
        ),
        boxShadow: [
          if (isAdmin)
            BoxShadow(
              color: AppColors.caramel.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAdmin ? Icons.shield_rounded : Icons.coffee_maker_outlined,
            color: AppColors.cream,
            size: 12,
          ),
          const SizedBox(width: 5),
          Text(
            isAdmin ? 'Admin' : 'Barista',
            style: GoogleFonts.inter(
              color: AppColors.cream,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Notification button ───────────────────────────────────────────────────────

class _NotificationButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.darkBackground.withOpacity(0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.caramel.withOpacity(0.25)),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_outlined,
                color: AppColors.cream,
                size: 22,
              ),
              Positioned(
                top: -3,
                right: -3,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.caramel,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.caramel.withOpacity(0.6),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Gradient divider ──────────────────────────────────────────────────────────

class _GradientDivider extends StatelessWidget {
  const _GradientDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.caramel.withOpacity(0.4),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
