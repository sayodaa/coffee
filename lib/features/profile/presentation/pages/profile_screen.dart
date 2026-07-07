import 'dart:io';
import 'dart:ui';

import 'package:coffee_app/auth/providers/auth_provider.dart';
import 'package:coffee_app/core/theme/app_colors.dart';
import 'package:coffee_app/features/profile/domain/entities/profile_entity.dart';
import 'package:coffee_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:coffee_app/features/profile/presentation/cubit/profile_state.dart';
import 'package:coffee_app/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:coffee_app/features/profile/presentation/widgets/profile_avatar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium Profile screen with coffee-themed design.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocConsumer<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final profile = _extractProfile(state);

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Hero Header ──────────────────────────────────────────
              _buildHeroHeader(context, profile, isDark, size),

              // ── Content ──────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: Column(
                          children: [
                            const SizedBox(height: 24),
                            _buildStatsSection(context, profile, isDark),
                            const SizedBox(height: 24),
                            _buildInfoCards(context, profile, isDark),
                            const SizedBox(height: 24),
                            _buildQuickActions(context, isDark),
                            const SizedBox(height: 32),
                            _buildLogoutButton(context, isDark),
                          ],
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  ProfileEntity _extractProfile(ProfileState state) {
    if (state is ProfileLoaded) return state.profile;
    if (state is ProfileSaving) return state.profile;
    if (state is ProfileSaved) return state.profile;
    if (state is ProfileImagePicking) return state.profile;
    if (state is ProfileError) return state.profile ?? ProfileEntity.empty();
    return ProfileEntity.empty();
  }

  // ── Hero Header ──────────────────────────────────────────────────────────

  Widget _buildHeroHeader(
    BuildContext context,
    ProfileEntity profile,
    bool isDark,
    Size size,
  ) {
    final headerHeight = size.height * 0.42;

    return SliverToBoxAdapter(
      child: SizedBox(
        height: headerHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          AppColors.darkChocolate,
                          AppColors.espresso,
                          AppColors.mocha,
                        ]
                      : [
                          AppColors.coffeeBrown,
                          AppColors.warmBrown,
                          AppColors.darkBrown,
                        ],
                ),
              ),
            ),

            // Decorative circles
            Positioned(
              top: -60,
              right: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.caramel.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -50,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.caramel.withOpacity(0.06),
                ),
              ),
            ),

            // Glassmorphism card
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ProfileAvatar(
                          radius: 48,
                          editable: false,
                          imagePath: profile.imagePath,
                          initials: profile.initials,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          profile.hasName ? profile.fullName : 'Coffee Artisan',
                          style: GoogleFonts.inter(
                            color: AppColors.cream,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.role.isNotEmpty
                              ? profile.role
                              : (context.watch<AuthProvider>().isAdmin
                                  ? 'Administrator'
                                  : 'Barista'),
                          style: GoogleFonts.inter(
                            color: AppColors.caramel,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (profile.bio.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            profile.bio,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: AppColors.latte.withOpacity(0.7),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Back & Edit buttons
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              child: IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_ios_rounded,
                    color: AppColors.cream, size: 22),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 12,
              child: IconButton(
                onPressed: () => _navigateToEdit(context),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.caramel.withOpacity(0.2),
                ),
                icon: const Icon(Icons.edit_rounded,
                    color: AppColors.cream, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Stats Section ────────────────────────────────────────────────────────

  Widget _buildStatsSection(
    BuildContext context,
    ProfileEntity profile,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _StatItem(
            icon: Icons.coffee_rounded,
            label: 'Role',
            value: profile.role.isNotEmpty
                ? profile.role
                : (context.watch<AuthProvider>().isAdmin ? 'Admin' : 'Barista'),
          ),
          _divider(isDark),
          _StatItem(
            icon: Icons.calendar_today_rounded,
            label: 'Joined',
            value: _formatDate(profile.createdAt),
          ),
          _divider(isDark),
          _StatItem(
            icon: Icons.update_rounded,
            label: 'Updated',
            value: _formatDate(profile.updatedAt),
          ),
        ],
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Container(
      width: 1,
      height: 40,
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  // ── Info Cards ───────────────────────────────────────────────────────────

  Widget _buildInfoCards(
    BuildContext context,
    ProfileEntity profile,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        _InfoCard(
          icon: Icons.person_outline_rounded,
          label: 'Full Name',
          value: profile.fullName.isNotEmpty ? profile.fullName : 'Not set',
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        _InfoCard(
          icon: Icons.email_outlined,
          label: 'Email',
          value: profile.email.isNotEmpty ? profile.email : 'Not set',
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        _InfoCard(
          icon: Icons.phone_outlined,
          label: 'Phone',
          value: profile.phone.isNotEmpty ? profile.phone : 'Not set',
          isDark: isDark,
        ),
        if (profile.bio.isNotEmpty) ...[
          const SizedBox(height: 8),
          _InfoCard(
            icon: Icons.info_outline_rounded,
            label: 'Bio',
            value: profile.bio,
            isDark: isDark,
          ),
        ],
      ],
    );
  }

  // ── Quick Actions ────────────────────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.edit_rounded,
                label: 'Edit Profile',
                color: AppColors.caramel,
                onTap: () => _navigateToEdit(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.camera_alt_rounded,
                label: 'Change Photo',
                color: AppColors.coffeeBrown,
                onTap: () {
                  final cubit = context.read<ProfileCubit>();
                  final s = cubit.state;
                  ProfileEntity p = ProfileEntity.empty();
                  if (s is ProfileLoaded) p = s.profile;

                  // Show image picker options
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => _buildImagePickerSheet(ctx, cubit, p),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImagePickerSheet(
    BuildContext ctx,
    ProfileCubit cubit,
    ProfileEntity profile,
  ) {
    return ProfileAvatar(
      radius: 0,
      editable: true,
      imagePath: profile.imagePath,
      initials: profile.initials,
    );
  }

  // ── Logout ───────────────────────────────────────────────────────────────

  Widget _buildLogoutButton(BuildContext context, bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () => _logout(context),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.error,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.error.withOpacity(0.3)),
          ),
        ),
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: const Text(
          'Log Out',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _navigateToEdit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfilePage()),
    );
  }

  void _logout(BuildContext context) {
    context.read<AuthProvider>().logout();
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/role-selection',
      (route) => false,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SUB-WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.caramel, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withOpacity(0.6),
                ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.caramel.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.caramel, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withOpacity(0.6),
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                      fontSize: 13,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
