import 'dart:io';

import 'package:coffee_app/core/theme/app_colors.dart';
import 'package:coffee_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:coffee_app/features/profile/presentation/cubit/profile_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

/// Reusable profile avatar widget.
/// Shows the user's image if available, otherwise an animated placeholder.
/// Optionally allows tapping to pick/remove image.
class ProfileAvatar extends StatelessWidget {
  final double radius;
  final bool editable;
  final String? imagePath;
  final String initials;
  final VoidCallback? onTap;

  const ProfileAvatar({
    super.key,
    this.radius = 55,
    this.editable = false,
    this.imagePath,
    this.initials = '?',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPicking = context.select<ProfileCubit, bool>((cubit) {
      final s = cubit.state;
      return s is ProfileImagePicking;
    });

    return GestureDetector(
      onTap: editable ? () => _showImageOptions(context) : onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow ring
          Container(
            width: radius * 2 + 8,
            height: radius * 2 + 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.caramel, AppColors.coffeeBrown],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.caramel.withOpacity(0.35),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),

          // Avatar content
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              );
            },
            child:
                isPicking ? _buildLoading() : _buildAvatar(imagePath, initials),
          ),

          // Edit badge
          if (editable)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.caramel,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.caramel.withOpacity(0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: AppColors.cream,
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? path, String initials) {
    final hasValidImage =
        path != null && path.isNotEmpty && File(path).existsSync();

    if (hasValidImage) {
      return ClipOval(
        key: ValueKey('img_$path'),
        child: SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: Image.file(
            File(path!),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildPlaceholder(initials),
          ),
        ),
      );
    }
    return _buildPlaceholder(initials);
  }

  Widget _buildPlaceholder(String initials) {
    return Container(
      key: const ValueKey('placeholder'),
      width: radius * 2,
      height: radius * 2,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.warmBrown, AppColors.coffeeBrown],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: AppColors.cream,
            fontSize: radius * 0.6,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      key: const ValueKey('loading'),
      width: radius * 2,
      height: radius * 2,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.warmBrown, AppColors.coffeeBrown],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.caramel,
          strokeWidth: 2.5,
        ),
      ),
    );
  }

  void _showImageOptions(BuildContext context) {
    final cubit = context.read<ProfileCubit>();
    final hasImage = imagePath != null && imagePath!.isNotEmpty;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.caramel.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                Text(
                  'Profile Photo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 20),

                _ImageOptionTile(
                  icon: Icons.photo_library_rounded,
                  label: 'Choose from Gallery',
                  onTap: () {
                    Navigator.pop(ctx);
                    cubit.pickImage(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 8),
                _ImageOptionTile(
                  icon: Icons.camera_alt_rounded,
                  label: 'Take a Photo',
                  onTap: () {
                    Navigator.pop(ctx);
                    cubit.pickImage(ImageSource.camera);
                  },
                ),
                if (hasImage) ...[
                  const SizedBox(height: 8),
                  _ImageOptionTile(
                    icon: Icons.delete_outline_rounded,
                    label: 'Remove Photo',
                    isDestructive: true,
                    onTap: () {
                      Navigator.pop(ctx);
                      cubit.removeImage();
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ImageOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ImageOptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.caramel;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 14),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
