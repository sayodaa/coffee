import 'dart:math' as math;

import 'package:coffee_app/features/settings/presentation/cubit/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A widget that provides magical theme transitions.
///
/// Features:
/// - Circular reveal animation when theme changes
/// - Smooth 600ms transitions
/// - Scales and fades content during transition
class MagicalThemeSwitcher extends StatefulWidget {
  final Widget child;

  const MagicalThemeSwitcher({super.key, required this.child});

  @override
  State<MagicalThemeSwitcher> createState() => _MagicalThemeSwitcherState();
}

class _MagicalThemeSwitcherState extends State<MagicalThemeSwitcher>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  ThemeMode? _previousThemeMode;
  bool _isAnimating = false;
  // Offset _tapPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startAnimation(ThemeMode newThemeMode) {
    if (_previousThemeMode != null && _previousThemeMode != newThemeMode) {
      setState(() {
        _isAnimating = true;
      });
      _controller.forward(from: 0).then((_) {
        setState(() {
          _isAnimating = false;
        });
      });
    }
    _previousThemeMode = newThemeMode;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ThemeCubit, ThemeState>(
      listenWhen: (previous, current) =>
          previous.themeMode != current.themeMode && !current.isLoading,
      listener: (context, state) {
        _startAnimation(state.themeMode);
      },
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          if (!_isAnimating) {
            return widget.child;
          }

          // During animation, apply scale and fade effect
          return Transform.scale(
            scale: 1.0 - (_animation.value * 0.02),
            child: Opacity(
              opacity: 1.0 - (_animation.value * 0.1),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

/// A premium animated theme toggle switch with sun/moon icons.
///
/// Features:
/// - Smooth sun to moon transition
/// - Rotating icon animation
/// - Glow effect on active state
class MagicalThemeToggle extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onChanged;

  const MagicalThemeToggle({
    super.key,
    required this.isDarkMode,
    required this.onChanged,
  });

  @override
  State<MagicalThemeToggle> createState() => _MagicalThemeToggleState();
}

class _MagicalThemeToggleState extends State<MagicalThemeToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.isDarkMode) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(MagicalThemeToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDarkMode != widget.isDarkMode) {
      if (widget.isDarkMode) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => widget.onChanged(!widget.isDarkMode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 72,
        height: 40,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isDark ? const Color(0xFF1A1D23) : const Color(0xFFE2E8F0),
          border: Border.all(
            color: isDark ? const Color(0xFF2D323C) : const Color(0xFFCBD5E1),
            width: 1,
          ),
          boxShadow: widget.isDarkMode
              ? [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: -2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Stack(
          children: [
            // Track icons (subtle background)
            Positioned(
              left: 6,
              top: 0,
              bottom: 0,
              child: Center(
                child: Icon(
                  Icons.light_mode,
                  size: 16,
                  color: isDark
                      ? Colors.grey.withOpacity(0.3)
                      : Colors.amber.withOpacity(0.5),
                ),
              ),
            ),
            Positioned(
              right: 6,
              top: 0,
              bottom: 0,
              child: Center(
                child: Icon(
                  Icons.dark_mode,
                  size: 16,
                  color: isDark
                      ? const Color(0xFF6366F1).withOpacity(0.5)
                      : Colors.grey.withOpacity(0.3),
                ),
              ),
            ),

            // Animated thumb
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Positioned(
                  left: widget.isDarkMode ? 36 : 4,
                  top: 4,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: widget.isDarkMode
                            ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                            : [Colors.amber, Colors.orange],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.isDarkMode
                              ? const Color(0xFF6366F1).withOpacity(0.5)
                              : Colors.amber.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Transform.rotate(
                        angle: _rotationAnimation.value * math.pi,
                        child: Icon(
                          widget.isDarkMode
                              ? Icons.dark_mode
                              : Icons.light_mode,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
