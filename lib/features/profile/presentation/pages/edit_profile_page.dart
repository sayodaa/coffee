import 'package:coffee_app/core/theme/app_colors.dart';
import 'package:coffee_app/features/profile/domain/entities/profile_entity.dart';
import 'package:coffee_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:coffee_app/features/profile/presentation/cubit/profile_state.dart';
import 'package:coffee_app/features/profile/presentation/widgets/profile_avatar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

/// Full edit profile form with validation, unsaved-changes detection,
/// and premium coffee-themed styling.
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _roleCtrl;

  late ProfileEntity _original;
  bool _hasChanges = false;
  bool _showSuccess = false;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);

    final state = context.read<ProfileCubit>().state;
    _original = _extractProfile(state);

    _nameCtrl = TextEditingController(text: _original.fullName);
    _emailCtrl = TextEditingController(text: _original.email);
    _phoneCtrl = TextEditingController(text: _original.phone);
    _bioCtrl = TextEditingController(text: _original.bio);
    _roleCtrl = TextEditingController(text: _original.role);

    _nameCtrl.addListener(_checkChanges);
    _emailCtrl.addListener(_checkChanges);
    _phoneCtrl.addListener(_checkChanges);
    _bioCtrl.addListener(_checkChanges);
    _roleCtrl.addListener(_checkChanges);

    _animCtrl.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    _roleCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  ProfileEntity _extractProfile(ProfileState state) {
    if (state is ProfileLoaded) return state.profile;
    if (state is ProfileSaving) return state.profile;
    if (state is ProfileSaved) return state.profile;
    if (state is ProfileImagePicking) return state.profile;
    if (state is ProfileError) return state.profile ?? ProfileEntity.empty();
    return ProfileEntity.empty();
  }

  void _checkChanges() {
    final changed = _nameCtrl.text != _original.fullName ||
        _emailCtrl.text != _original.email ||
        _phoneCtrl.text != _original.phone ||
        _bioCtrl.text != _original.bio ||
        _roleCtrl.text != _original.role;
    if (changed != _hasChanges) {
      setState(() => _hasChanges = changed);
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to leave?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final cubit = context.read<ProfileCubit>();
    final current = _extractProfile(cubit.state);

    final updated = current.copyWith(
      fullName: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
      role: _roleCtrl.text.trim(),
      createdAt:
          current.createdAt.year <= 1970 ? DateTime.now() : current.createdAt,
    );

    await cubit.saveProfile(updated);

    if (!mounted) return;

    setState(() => _showSuccess = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Edit Profile',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
          ),
          centerTitle: true,
          leading: IconButton(
            onPressed: () async {
              if (_hasChanges) {
                final shouldPop = await _onWillPop();
                if (shouldPop && mounted) Navigator.pop(context);
              } else {
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.arrow_back_ios_rounded),
          ),
          actions: [
            BlocBuilder<ProfileCubit, ProfileState>(
              builder: (context, state) {
                final isSaving = state is ProfileSaving;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TextButton(
                    onPressed: isSaving ? null : _save,
                    child: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.caramel,
                            ),
                          )
                        : Text(
                            'Save',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              color: AppColors.caramel,
                              fontSize: 15,
                            ),
                          ),
                  ),
                );
              },
            ),
          ],
        ),
        body: AnimatedCrossFade(
          duration: const Duration(milliseconds: 400),
          crossFadeState: _showSuccess
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          secondChild: _buildSuccessView(),
          firstChild: FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Avatar
                    BlocBuilder<ProfileCubit, ProfileState>(
                      builder: (context, state) {
                        final profile = _extractProfile(state);
                        return ProfileAvatar(
                          radius: 55,
                          editable: true,
                          imagePath: profile.imagePath,
                          initials: _nameCtrl.text.isNotEmpty
                              ? _getInitials(_nameCtrl.text)
                              : profile.initials,
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // Form Fields
                    _buildField(
                      controller: _nameCtrl,
                      label: 'Full Name',
                      hint: 'Enter your full name',
                      icon: Icons.person_outline_rounded,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Name is required';
                        }
                        if (v.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _buildField(
                      controller: _emailCtrl,
                      label: 'Email',
                      hint: 'you@example.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Email is required';
                        }
                        final emailRegex = RegExp(
                            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                        if (!emailRegex.hasMatch(v.trim())) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _buildField(
                      controller: _phoneCtrl,
                      label: 'Phone Number',
                      hint: '+1 (555) 123-4567',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v != null && v.trim().isNotEmpty) {
                          final phoneRegex =
                              RegExp(r'^[\+]?[\d\s\-\(\)]{7,20}$');
                          if (!phoneRegex.hasMatch(v.trim())) {
                            return 'Enter a valid phone number';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _buildField(
                      controller: _roleCtrl,
                      label: 'Role',
                      hint: 'e.g. Barista, Manager',
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 16),

                    _buildField(
                      controller: _bioCtrl,
                      label: 'Bio',
                      hint: 'Tell us about yourself...',
                      icon: Icons.info_outline_rounded,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    BlocBuilder<ProfileCubit, ProfileState>(
                      builder: (context, state) {
                        final isSaving = state is ProfileSaving;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: isSaving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.caramel,
                              foregroundColor: AppColors.cream,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                              shadowColor: AppColors.caramel.withOpacity(0.4),
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: AppColors.cream,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    'Save Changes',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Cancel Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: TextButton(
                        onPressed: () async {
                          if (_hasChanges) {
                            final shouldPop = await _onWillPop();
                            if (shouldPop && mounted) Navigator.pop(context);
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).textTheme.bodyMedium?.color,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (_, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.success,
                size: 56,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Profile Updated!',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your changes have been saved.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }
}
