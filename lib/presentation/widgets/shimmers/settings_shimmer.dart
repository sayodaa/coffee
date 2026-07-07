import 'package:coffee_app/presentation/widgets/shimmers/base_shimmer.dart';
import 'package:coffee_app/core/localization/json_localizations.dart';
import 'package:coffee_app/core/localization/lang_keys.dart';
import 'package:flutter/material.dart';

class SettingsShimmer extends StatelessWidget {
  const SettingsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile Header Shimmer
        const ProfileHeaderShimmer(),
        const SizedBox(height: 32),

        // Settings Categories Shimmer
        SettingsCategoryShimmer(title: context.tr(LangKeys.account)),
        const SizedBox(height: 24),
        SettingsCategoryShimmer(title: context.tr(LangKeys.notifications)),
        const SizedBox(height: 24),
        SettingsCategoryShimmer(title: context.tr(LangKeys.inventory_rules)),
        const SizedBox(height: 24),
        SettingsCategoryShimmer(title: context.tr(LangKeys.app_theme)),
        const SizedBox(height: 48),

        // Footer Shimmer
        const SettingsFooterShimmer(),
      ],
    );
  }
}

class ProfileHeaderShimmer extends StatelessWidget {
  const ProfileHeaderShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseShimmer(
      height: 100,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            // Avatar placeholder
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            const SizedBox(width: 16),
            // Profile info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Name
                  Container(
                    width: 120,
                    height: 20,
                    color: Colors.white.withOpacity(0.1),
                  ),
                  const SizedBox(height: 6),
                  // Role
                  Container(
                    width: 80,
                    height: 14,
                    color: Colors.white.withOpacity(0.1),
                  ),
                  const SizedBox(height: 4),
                  // Email
                  Container(
                    width: 150,
                    height: 12,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ],
              ),
            ),
            // Edit button placeholder
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsCategoryShimmer extends StatelessWidget {
  final String title;

  const SettingsCategoryShimmer({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category title
        Container(
          width: 100,
          height: 16,
          color: Colors.white.withOpacity(0.1),
        ),
        const SizedBox(height: 12),
        // Category items
        BaseShimmer(
          height: 200,
          child: Column(
            children: List.generate(
              3,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 1),
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Icon placeholder
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Title placeholder
                      Expanded(
                        child: Container(
                          height: 16,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      // Trailing placeholder
                      Container(
                        width: 24,
                        height: 24,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SettingsFooterShimmer extends StatelessWidget {
  const SettingsFooterShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseShimmer(
      height: 80,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Version text
            Container(
              width: 100,
              height: 14,
              color: Colors.white.withOpacity(0.1),
            ),
            const SizedBox(height: 16),
            // Logout button
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}