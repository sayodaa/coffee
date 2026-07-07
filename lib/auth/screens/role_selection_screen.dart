import 'dart:ui';

import 'package:coffee_app/auth/providers/auth_provider.dart';
import 'package:coffee_app/auth/services/auth_service.dart';
import 'package:coffee_app/core/di/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ─── Constants ────────────────────────────────────────────────────────────────

const _kEspresso = Color(0xFF1B0F0A);
const _kMocha = Color(0xFF3E2723);
const _kCaramel = Color(0xFFC68E52);
const _kLatte = Color(0xFFE6CCB2);
const _kCream = Color(0xFFFFF8F3);

const _kOverlayGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0x22000000),
    Color(0x99110800),
    Color(0xFF0E0500),
  ],
  stops: [0.0, 0.55, 1.0],
);

const _kCoffeeGradient = LinearGradient(
  colors: [Color(0xFFC68E52), Color(0xFF8B5E3C)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// ─── Background images (randomly chosen pairs) ────────────────────────────────

const _kBgImages = [
  'assets/images/coffee1.jpg',
  'assets/images/barista1.jpg',
  'assets/images/coffee4.jpg',
  'assets/images/coffee3.jpg',
  'assets/images/coffee2.jpg',
  'assets/images/barista2.jpg',
  'assets/images/auth.jpg',
];

// ─── RoleSelectionScreen ──────────────────────────────────────────────────────

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  final int _bgIndex = 1;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _selectBarista() async {
    final provider = context.read<AuthProvider>();
    final token = 'barista_${DateTime.now().millisecondsSinceEpoch}';
    final ok = await provider.login(token, 'barista');
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      _showSnack('Session error — please try again.', isError: true);
    }
  }

  void _openAdminDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Admin Auth',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 350),
      transitionBuilder: (ctx, anim, _, child) {
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: child,
          ),
        );
      },
      pageBuilder: (ctx, _, __) => _AdminPasswordDialog(
        onSuccess: () async {
          final provider = context.read<AuthProvider>();
          final token = 'admin_${DateTime.now().millisecondsSinceEpoch}';
          final ok = await provider.login(token, 'admin');
          if (!mounted) return;
          if (ok) {
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            _showSnack('Session error — please try again.', isError: true);
          }
        },
        onWrongPassword: () =>
            _showSnack('Incorrect password.  Please try again.', isError: true),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(
                color: _kCream, fontSize: 14, fontWeight: FontWeight.w500)),
        backgroundColor: isError ? const Color(0xFF7B2D2D) : _kMocha,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    return Scaffold(
      backgroundColor: _kEspresso,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _CinematicBackground(imageAsset: _kBgImages[_bgIndex]),
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: isLandscape
                    ? _LandscapeLayout(
                        onBarista: _selectBarista,
                        onAdmin: _openAdminDialog,
                      )
                    : _PortraitLayout(
                        onBarista: _selectBarista,
                        onAdmin: _openAdminDialog,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Cinematic Background ─────────────────────────────────────────────────────

class _CinematicBackground extends StatelessWidget {
  final String imageAsset;
  const _CinematicBackground({required this.imageAsset});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(imageAsset, fit: BoxFit.cover),
        Container(decoration: const BoxDecoration(gradient: _kOverlayGradient)),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 300,
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Portrait Layout ──────────────────────────────────────────────────────────

class _PortraitLayout extends StatelessWidget {
  final VoidCallback onBarista;
  final VoidCallback onAdmin;

  const _PortraitLayout({required this.onBarista, required this.onAdmin});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final h = constraints.maxHeight;
      final isTall = h > 700;
      return SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: constraints.maxWidth * 0.07,
                vertical: isTall ? 32 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: isTall ? h * 0.08 : 12),
                const _LogoBadge(),
                SizedBox(height: isTall ? 32 : 16),
                const _HeroText(),
                const SizedBox(height: 40),
                _GlassCard(
                  child: Column(
                    children: [
                      _CoffeeRoleButton(
                        label: 'I\'m a Barista',
                        subtitle: 'Manage orders & inventory',
                        icon: Icons.coffee_maker_outlined,
                        isPrimary: true,
                        onTap: onBarista,
                      ),
                      const SizedBox(height: 16),
                      _CoffeeRoleButton(
                        label: 'I\'m an Admin',
                        subtitle: 'Full access & reports',
                        icon: Icons.shield_outlined,
                        isPrimary: false,
                        onTap: onAdmin,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isTall ? 40 : 20),
                const _FooterTagline(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      );
    });
  }
}

// ─── Landscape Layout ─────────────────────────────────────────────────────────

class _LandscapeLayout extends StatelessWidget {
  final VoidCallback onBarista;
  final VoidCallback onAdmin;
  const _LandscapeLayout({required this.onBarista, required this.onAdmin});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _LogoBadge(),
                SizedBox(height: 24),
                _HeroText(textAlign: TextAlign.left),
              ],
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _GlassCard(
                child: Column(
                  children: [
                    _CoffeeRoleButton(
                      label: 'I\'m a Barista',
                      subtitle: 'Manage orders & inventory',
                      icon: Icons.coffee_maker_outlined,
                      isPrimary: true,
                      onTap: onBarista,
                    ),
                    const SizedBox(height: 16),
                    _CoffeeRoleButton(
                      label: 'I\'m an Admin',
                      subtitle: 'Full access & reports',
                      icon: Icons.shield_outlined,
                      isPrimary: false,
                      onTap: onAdmin,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Logo Badge ───────────────────────────────────────────────────────────────

class _LogoBadge extends StatelessWidget {
  const _LogoBadge();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: _kCoffeeGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: _kCaramel.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: const Icon(Icons.coffee, color: _kCream, size: 26),
        ),
        const SizedBox(width: 12),
        const Text(
          'Coffee Bar',
          style: TextStyle(
            color: _kCream,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ─── Hero Text ────────────────────────────────────────────────────────────────

class _HeroText extends StatelessWidget {
  final TextAlign textAlign;
  const _HeroText({this.textAlign = TextAlign.center});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: textAlign == TextAlign.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome\nBack.',
          textAlign: textAlign,
          style: const TextStyle(
            color: _kCream,
            fontSize: 52,
            fontWeight: FontWeight.w800,
            height: 1.05,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Select your role to continue\nyour shift.',
          textAlign: textAlign,
          style: TextStyle(
            color: _kLatte.withOpacity(0.85),
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.5,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}

// ─── Glass Card ───────────────────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF1B1512).withOpacity(0.72),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: _kCaramel.withOpacity(0.25),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─── Role Button ─────────────────────────────────────────────────────────────

class _CoffeeRoleButton extends StatefulWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  const _CoffeeRoleButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  State<_CoffeeRoleButton> createState() => _CoffeeRoleButtonState();
}

class _CoffeeRoleButtonState extends State<_CoffeeRoleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120), value: 1);
    _scale = Tween<double>(begin: 0.97, end: 1.0)
        .animate(CurvedAnimation(parent: _press, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _press.reverse(),
        onTapUp: (_) {
          _press.forward();
          widget.onTap();
        },
        onTapCancel: () => _press.forward(),
        child: widget.isPrimary
            ? _PrimaryButton(
                label: widget.label,
                subtitle: widget.subtitle,
                icon: widget.icon)
            : _SecondaryButton(
                label: widget.label,
                subtitle: widget.subtitle,
                icon: widget.icon),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  const _PrimaryButton(
      {required this.label, required this.subtitle, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        gradient: _kCoffeeGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: _kCaramel.withOpacity(0.45),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _kCream, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: _kCream,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          color: _kCream.withOpacity(0.75),
                          fontSize: 12,
                          fontWeight: FontWeight.w400)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: _kCream.withOpacity(0.8), size: 16),
          ],
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  const _SecondaryButton(
      {required this.label, required this.subtitle, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFF2A1E18).withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kCaramel.withOpacity(0.35), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: _kCaramel.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _kCaramel, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: _kLatte,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          color: _kLatte.withOpacity(0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w400)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: _kCaramel.withOpacity(0.7), size: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Footer Tagline ───────────────────────────────────────────────────────────

class _FooterTagline extends StatelessWidget {
  const _FooterTagline();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Crafted with care • Every cup matters',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: _kLatte.withOpacity(0.45),
        fontSize: 12,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

// ─── Admin Password Dialog ────────────────────────────────────────────────────

class _AdminPasswordDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onWrongPassword;

  const _AdminPasswordDialog(
      {required this.onSuccess, required this.onWrongPassword});

  @override
  State<_AdminPasswordDialog> createState() => _AdminPasswordDialogState();
}

class _AdminPasswordDialogState extends State<_AdminPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _ctrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final authService = sl<AuthService>();
    final ok = authService.verifyAdminPassword(_ctrl.text);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.pop(context);
    if (ok) {
      widget.onSuccess();
    } else {
      widget.onWrongPassword();
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── Material wrapper is required here because showGeneralDialog's
    // pageBuilder does not provide one automatically, and it also gives
    // this subtree a bounded/finite layout box (fixes the huge overflow).
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
              maxWidth: 420,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1512).withOpacity(0.92),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                        color: _kCaramel.withOpacity(0.2), width: 1.2),
                  ),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: _kCoffeeGradient,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      color: _kCaramel.withOpacity(0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 6)),
                                ],
                              ),
                              child: const Icon(Icons.shield_outlined,
                                  color: _kCream, size: 26),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Admin Access',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _kCream,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Enter your administrator password\nto unlock full access.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _kLatte.withOpacity(0.7),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 28),
                          _CoffeeTextField(
                            controller: _ctrl,
                            hint: 'Admin password',
                            icon: Icons.lock_outline_rounded,
                            obscureText: _obscure,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: _kCaramel.withOpacity(0.7),
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Password is required'
                                : null,
                          ),
                          const SizedBox(height: 24),
                          _loading
                              ? const Center(
                                  child: SizedBox(
                                    height: 28,
                                    width: 28,
                                    child: CircularProgressIndicator(
                                        color: _kCaramel, strokeWidth: 2.5),
                                  ),
                                )
                              : _GradientButton(
                                  label: 'Verify & Enter',
                                  onTap: _verify,
                                ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                  color: _kLatte.withOpacity(0.55),
                                  fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _CoffeeTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _CoffeeTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(
          color: _kCream, fontSize: 15, fontWeight: FontWeight.w500),
      cursorColor: _kCaramel,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: _kLatte.withOpacity(0.45),
            fontSize: 14,
            fontWeight: FontWeight.w400),
        prefixIcon: Icon(icon, color: _kCaramel.withOpacity(0.8), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF2A1E18).withOpacity(0.7),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              BorderSide(color: _kCaramel.withOpacity(0.18), width: 1.1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _kCaramel, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD9534F), width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD9534F), width: 1.5),
        ),
        errorStyle: const TextStyle(color: Color(0xFFE57373), fontSize: 12),
      ),
    );
  }
}

class _GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _GradientButton({required this.label, required this.onTap});

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100), value: 1);
    _scale = Tween<double>(begin: 0.97, end: 1.0)
        .animate(CurvedAnimation(parent: _press, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _press.reverse(),
        onTapUp: (_) {
          _press.forward();
          widget.onTap();
        },
        onTapCancel: () => _press.forward(),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: _kCoffeeGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: _kCaramel.withOpacity(0.4),
                  blurRadius: 18,
                  offset: const Offset(0, 7)),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: const TextStyle(
              color: _kCream,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}
