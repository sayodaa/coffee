import 'package:coffee_app/auth/providers/auth_provider.dart';
import 'package:coffee_app/auth/services/auth_service.dart';
import 'package:coffee_app/core/di/service_locator.dart';
import 'package:coffee_app/core/localization/json_localizations.dart';
import 'package:coffee_app/core/localization/lang_keys.dart';
import 'package:coffee_app/core/theme/app_colors.dart';
import 'package:coffee_app/core/widgets/magical_theme_switcher.dart';
import 'package:coffee_app/features/notifications/presentation/cubit/notification_cubit.dart';
import 'package:coffee_app/features/settings/domain/settings_models.dart';
import 'package:coffee_app/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:coffee_app/features/settings/presentation/cubit/theme_cubit.dart';
import 'package:coffee_app/features/settings/presentation/pages/edit_profile_page.dart';
import 'package:coffee_app/features/settings/presentation/pages/inventory_config_page.dart';
import 'package:coffee_app/features/settings/presentation/widgets/profile_header.dart';
import 'package:coffee_app/features/settings/presentation/widgets/settings_category.dart';
import 'package:coffee_app/presentation/widgets/shimmers/settings_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ─── Local theme constants (kept consistent with the other pages) ────────────
const _kCaramel = Color(0xFFC68E52);
const _kWhite = Colors.white;
const _kBgDark = Color(0xFF1B1512);

/// Settings page with magical theme toggle and user preferences.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth * 0.05;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Lets the body (and our background image) draw behind the app bar,
      // so the photo covers the whole screen, top to bottom.
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      // appBar: CustomAppBar(
      //   title: context.tr(LangKeys.nav_settings),
      //   showNotificationDot: true,
      // ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Full-screen background image (behind the app bar too) ──
          const _SettingsBackground(),

          // ── Page content on top of the image ──
          SafeArea(
            child: BlocBuilder<SettingsCubit, SettingsState>(
              builder: (context, state) {
                if (state.status == SettingsStatus.loading) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.all(padding),
                    child: const SettingsShimmer(),
                  );
                }

                if (state.status == SettingsStatus.failure) {
                  return Center(
                    child: Text(
                      state.message ?? context.tr(LangKeys.retry),
                      style: const TextStyle(color: _kWhite),
                    ),
                  );
                }

                final settings = state.settings;
                if (settings == null) {
                  return const SizedBox.shrink();
                }

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Header
                      ProfileHeader(
                        userProfile: UserProfile(
                          name: 'Saied Reda',
                          role: context.watch<AuthProvider>().isAdmin
                              ? 'Administrator'
                              : 'Barista',
                          email: context.watch<AuthProvider>().isAdmin
                              ? 'admin@coffeeshop.com'
                              : 'barista@coffeeshop.com',
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Account Settings
                      SettingsCategory(
                        title: context.tr(LangKeys.general),
                        items: [
                          SettingsItem(
                            icon: Icons.person_outline,
                            iconColor: AppColors.chartPrimary,
                            title: context.tr(LangKeys.edit_profile),
                            showChevron: true,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EditProfilePage(),
                                ),
                              );
                            },
                          ),
                          SettingsItem(
                            icon: Icons.store_outlined,
                            iconColor: Colors.brown,
                            title: context.tr(LangKeys.shop_name),
                            showChevron: true,
                            onTap: () =>
                                _showShopNameDialog(context, settings.shopName),
                          ),
                          SettingsItem(
                            icon: Icons.language,
                            iconColor: Colors.purple,
                            title: context.tr(LangKeys.language),
                            showChevron: true,
                            onTap: () => _showLanguageDialog(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Notifications
                      SettingsCategory(
                        title: context.tr(LangKeys.notifications),
                        items: [
                          SettingsItem(
                            icon: Icons.notifications_outlined,
                            iconColor: AppColors.warning,
                            title: context.tr(LangKeys.notifications),
                            isSwitch: true,
                            switchValue: settings.notificationsEnabled,
                            onSwitchChanged: (value) async {
                              if (value) {
                                await context
                                    .read<NotificationCubit>()
                                    .enableNotifications();
                              } else {
                                await context
                                    .read<NotificationCubit>()
                                    .disableNotifications();
                              }
                            },
                          ),
                          SettingsItem(
                            icon: Icons.inventory_2_outlined,
                            iconColor: AppColors.error,
                            title: context.tr(LangKeys.low_stock),
                            isSwitch: true,
                            switchValue: settings.lowStockAlertsEnabled,
                            onSwitchChanged: (value) {
                              context
                                  .read<SettingsCubit>()
                                  .setLowStockAlertsEnabled(value);
                            },
                          ),
                          SettingsItem(
                            icon: Icons.today_outlined,
                            iconColor: Colors.teal,
                            title: context.tr(LangKeys.daily_sales_summary),
                            isSwitch: true,
                            switchValue: settings.dailySalesSummaryEnabled,
                            onSwitchChanged: (value) async {
                              await context
                                  .read<SettingsCubit>()
                                  .setDailySalesSummaryEnabled(value);
                              if (value) {
                                await context
                                    .read<NotificationCubit>()
                                    .scheduleDailySummary();
                              } else {
                                await context
                                    .read<NotificationCubit>()
                                    .cancelDailySummary();
                              }
                            },
                          ),
                          SettingsItem(
                            icon: Icons.receipt_long_outlined,
                            iconColor: Colors.indigo,
                            title: context.tr(LangKeys.sale_completed_notif),
                            isSwitch: true,
                            switchValue:
                                settings.saleCompletedNotificationsEnabled,
                            onSwitchChanged: (value) {
                              context
                                  .read<SettingsCubit>()
                                  .setSaleCompletedNotificationsEnabled(value);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Inventory Rules
                      SettingsCategory(
                        title: context.tr(LangKeys.categories),
                        items: [
                          SettingsItem(
                            icon: Icons.backup_outlined,
                            iconColor: AppColors.info,
                            title: context.tr(LangKeys.general),
                            isSwitch: true,
                            switchValue: settings.dataBackupEnabled,
                            onSwitchChanged: (value) {
                              context
                                  .read<SettingsCubit>()
                                  .setDataBackupEnabled(value);
                            },
                          ),
                          SettingsItem(
                            icon: Icons.refresh,
                            iconColor: AppColors.info,
                            title: context.tr(LangKeys.nav_reports),
                            isSwitch: true,
                            switchValue: settings.autoRefreshReportsEnabled,
                            onSwitchChanged: (value) {
                              context
                                  .read<SettingsCubit>()
                                  .setAutoRefreshReportsEnabled(value);
                            },
                          ),
                          SettingsItem(
                            icon: Icons.analytics_outlined,
                            iconColor: AppColors.success,
                            title: context.tr(LangKeys.nav_stock),
                            showChevron: true,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const InventoryConfigPage()),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Support
                      SettingsCategory(
                        title: context.tr(LangKeys.help_support),
                        items: [
                          SettingsItem(
                            icon: Icons.help_outline,
                            iconColor: AppColors.info,
                            title: context.tr(LangKeys.help_support),
                            showChevron: true,
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title:
                                      Text(context.tr(LangKeys.help_support)),
                                  content: const Text(
                                      'For support, please contact admin@coffeeshop.com'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(context.tr(LangKeys.ok)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          SettingsItem(
                            icon: Icons.info_outline,
                            iconColor: Theme.of(context).primaryColor,
                            title: context.tr(LangKeys.about),
                            showChevron: true,
                            onTap: () {
                              showAboutDialog(
                                context: context,
                                applicationName: context.tr(LangKeys.app_title),
                                applicationVersion: '1.0.0',
                                applicationIcon:
                                    const Icon(Icons.coffee, size: 48),
                                applicationLegalese: ' 2026 Coffee Shop Inc.',
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      if (context.watch<AuthProvider>().isAdmin) ...[
                        const AdminPasswordSection(),
                        const SizedBox(height: 24),
                      ],

                      // ═══════════════════════════════════════════════════
                      // MAGICAL THEME TOGGLE SECTION
                      // ═══════════════════════════════════════════════════
                      _buildThemeSection(context, isDark),
                      const SizedBox(height: 48),

                      // App Version and Logout
                      _buildFooterSection(context, isDark),

                      // Bottom padding for nav bar
                      const SizedBox(height: 120),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the magical theme toggle section
  Widget _buildThemeSection(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // Semi-transparent dark tint instead of a solid theme color, so the
        // section reads clearly on top of the photo background.
        color: Colors.black.withOpacity(0.42),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: -5,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(LangKeys.appearance),
            style: const TextStyle(
              color: _kWhite,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),

          // Theme Toggle Row
          // NOTE: driven by ThemeCubit now (the cubit MaterialApp actually
          // reads `themeMode` from), not SettingsCubit. SettingsCubit is
          // still updated alongside it so the stored app settings stay
          // consistent, but it is no longer the source of truth for the
          // app's visible theme.
          BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, themeState) {
              final isThemeDark = themeState.themeMode == ThemeMode.dark;
              return Row(
                children: [
                  // Icon with glow
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isThemeDark
                          ? const Color(0xFF6366F1).withOpacity(0.15)
                          : Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: isThemeDark
                              ? const Color(0xFF6366F1).withOpacity(0.2)
                              : Colors.amber.withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return RotationTransition(
                          turns: animation,
                          child:
                              ScaleTransition(scale: animation, child: child),
                        );
                      },
                      child: Icon(
                        isThemeDark ? Icons.dark_mode : Icons.light_mode,
                        key: ValueKey(isThemeDark),
                        color: isThemeDark
                            ? const Color(0xFF6366F1)
                            : Colors.amber.shade700,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isThemeDark
                              ? context.tr(LangKeys.dark_mode)
                              : context.tr(LangKeys.appearance),
                          style: const TextStyle(
                            color: _kWhite,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            isThemeDark
                                ? context.tr(LangKeys.theme_luxury_obsidian)
                                : context.tr(LangKeys.theme_clean_pearl),
                            key: ValueKey(isThemeDark),
                            style: TextStyle(color: _kWhite.withOpacity(0.75)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Magical Toggle Switch
                  MagicalThemeToggle(
                    isDarkMode: isThemeDark,
                    onChanged: (isDarkMode) {
                      final mode =
                          isDarkMode ? ThemeMode.dark : ThemeMode.light;
                      // Source of truth for the app's actual appearance.
                      context.read<ThemeCubit>().setThemeMode(mode);
                      // Keep the stored settings in sync too.
                      context.read<SettingsCubit>().setThemeMode(mode);
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Builds footer with version and logout
  Widget _buildFooterSection(
    BuildContext context,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.42),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: Column(
        children: [
          Text(
            '${context.tr(LangKeys.app_version)} 1.0.0',
            style: TextStyle(color: _kWhite.withOpacity(0.75)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                _logout(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.redAccent,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(context.tr(LangKeys.logout)),
            ),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    context.read<AuthProvider>().logout();

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/role-selection',
      (route) => false,
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.tr(LangKeys.language)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(context.tr(LangKeys.english)),
                onTap: () {
                  context.read<SettingsCubit>().setLanguageCode('en');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text(context.tr(LangKeys.arabic)),
                onTap: () {
                  context.read<SettingsCubit>().setLanguageCode('ar');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showShopNameDialog(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(context.tr(LangKeys.shop_name)),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: context.tr(LangKeys.shop_name_hint),
              border: const OutlineInputBorder(),
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.tr(LangKeys.cancel)),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<SettingsCubit>().setShopName(controller.text);
                Navigator.pop(ctx);
              },
              child: Text(context.tr(LangKeys.save)),
            ),
          ],
        );
      },
    );
  }
}

// ─── Background (full-screen photo, extends behind the app bar) ──────────────
//
// Same treatment as the Reports/Recipes pages: base photo, a warm caramel
// color wash, then a vertical scrim (darker at top/bottom, lighter in the
// middle) so text and icons stay legible everywhere, including behind the
// app bar.

class _SettingsBackground extends StatelessWidget {
  const _SettingsBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/barista1.jpg',
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _kBgDark.withOpacity(0.55),
                _kCaramel.withOpacity(0.12),
                _kBgDark.withOpacity(0.55),
              ],
            ),
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xCC1B1512),
                Color(0x661B1512),
                Color(0x331B1512),
                Color(0xDD1B1512),
              ],
              stops: [0.0, 0.28, 0.62, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

class AdminPasswordSection extends StatefulWidget {
  const AdminPasswordSection({super.key});

  @override
  State<AdminPasswordSection> createState() => _AdminPasswordSectionState();
}

class _AdminPasswordSectionState extends State<AdminPasswordSection> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _oldPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final oldPass = _oldPasswordCtrl.text;
    final newPass = _newPasswordCtrl.text;

    final authService = sl<AuthService>();
    final success = await authService.changeAdminPassword(oldPass, newPass);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin password updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _oldPasswordCtrl.clear();
      _newPasswordCtrl.clear();
      _confirmPasswordCtrl.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Old password is incorrect'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Security Settings',
            style: TextStyle(
              color: _kWhite,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.42),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: Colors.white.withOpacity(0.08), width: 1),
            ),
            child: Theme(
              // Forces the text fields' labels/icons/underlines to read
              // clearly over the photo instead of the app's base theme
              // colors (which assume a plain surface).
              data: Theme.of(context).copyWith(
                inputDecorationTheme: InputDecorationTheme(
                  labelStyle: TextStyle(color: _kWhite.withOpacity(0.85)),
                  hintStyle: TextStyle(color: _kWhite.withOpacity(0.55)),
                  iconColor: _kWhite,
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.white.withOpacity(0.35)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: _kCaramel, width: 2),
                  ),
                ),
                textSelectionTheme: const TextSelectionThemeData(
                  cursorColor: _kWhite,
                ),
              ),
              child: Column(
                children: [
                  TextFormField(
                    controller: _oldPasswordCtrl,
                    obscureText: _obscureOld,
                    style: const TextStyle(color: _kWhite),
                    decoration: InputDecoration(
                      labelText: 'Old Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureOld
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () =>
                            setState(() => _obscureOld = !_obscureOld),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Old password is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _newPasswordCtrl,
                    obscureText: _obscureNew,
                    style: const TextStyle(color: _kWhite),
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.vpn_key_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureNew
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () =>
                            setState(() => _obscureNew = !_obscureNew),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'New password is required';
                      }
                      if (val.length < 6) {
                        return 'New password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordCtrl,
                    obscureText: _obscureConfirm,
                    style: const TextStyle(color: _kWhite),
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.check_circle_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Please confirm your new password';
                      }
                      if (val != _newPasswordCtrl.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _updatePassword,
                      child: const Text('Update Password'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
