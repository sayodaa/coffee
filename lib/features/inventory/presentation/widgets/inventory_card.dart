import 'dart:ui';

import 'package:coffee_app/core/theme/app_colors.dart';
import 'package:coffee_app/features/inventory/domain/entities/inventory_item.dart';
import 'package:coffee_app/features/inventory/presentation/pages/stock_adjustment_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium glassmorphism inventory card with animated stock level bar.
class InventoryCard extends StatefulWidget {
  final InventoryItem item;

  const InventoryCard({super.key, required this.item});

  @override
  State<InventoryCard> createState() => _InventoryCardState();
}

class _InventoryCardState extends State<InventoryCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      value: 1,
    );
    _scale = Tween<double>(begin: 0.97, end: 1.0)
        .animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  double get _stockPercentage {
    final p = widget.item.quantity /
        (widget.item.quantity + widget.item.minThreshold);
    return p.clamp(0.0, 1.0);
  }

  _StockLevel get _stockLevel {
    final q = widget.item.quantity;
    final min = widget.item.minThreshold;
    if (q < min * 0.2) return _StockLevel.critical;
    if (q < min * 0.5) return _StockLevel.low;
    if (q < min) return _StockLevel.medium;
    return _StockLevel.good;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final level = _stockLevel;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ScaleTransition(
        scale: _scale,
        child: GestureDetector(
          // onTapDown: (_) => _pressCtrl.reverse(),
          // onTapUp: (_) {
          //   _pressCtrl.forward();
          //   Navigator.push(
          //     context,
          //     MaterialPageRoute(
          //       builder: (_) => InventoryDetailsPage(item: widget.item),
          //     ),
          //   );
          // },
          onTapCancel: () => _pressCtrl.forward(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface.withOpacity(0.75)
                      : AppColors.lightSurface.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder.withOpacity(0.8)
                        : AppColors.lightBorder,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header row ──────────────────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left: icon + name
                          Expanded(
                            child: Row(
                              children: [
                                // _CategoryIcon(
                                //   category: widget.item.category,
                                //   isDark: isDark,
                                //   stockLevel: level,
                                // ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.item.name,
                                        style: GoogleFonts.inter(
                                          color: isDark
                                              ? AppColors.cream
                                              : AppColors.textPrimaryLight,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: -0.2,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Text(
                                            widget.item.sku,
                                            style: GoogleFonts.inter(
                                              color: (isDark
                                                      ? AppColors
                                                          .textSecondaryDark
                                                      : AppColors
                                                          .textSecondaryLight)
                                                  .withOpacity(0.7),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          // _CategoryChip(
                                          //   label: widget.item.category,
                                          //   isDark: isDark,
                                          // ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Right: quantity + quick-add
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _StockBadge(level: level),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${_formatQty(widget.item.quantity)} ${widget.item.unit}',
                                    style: GoogleFonts.inter(
                                      color: isDark
                                          ? AppColors.cream
                                          : AppColors.textPrimaryLight,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  _QuickAddButton(item: widget.item),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // ── Stock level bar ─────────────────────────────────
                      _StockBar(
                        percentage: _stockPercentage,
                        level: level,
                        isDark: isDark,
                      ),

                      const SizedBox(height: 10),

                      // ── Footer row ──────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Min: ${_formatQty(widget.item.minThreshold.toDouble())} ${widget.item.unit}',
                            style: GoogleFonts.inter(
                              color: (isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight)
                                  .withOpacity(0.7),
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            '\$${widget.item.price.toStringAsFixed(2)} / ${widget.item.unit}',
                            style: GoogleFonts.inter(
                              color: isDark
                                  ? AppColors.caramel
                                  : AppColors.coffeeBrown,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _formatQty(double qty) =>
      qty == qty.truncate() ? qty.toInt().toString() : qty.toStringAsFixed(1);
}

// ── Stock level enum ──────────────────────────────────────────────────────────

enum _StockLevel { critical, low, medium, good }

extension _StockLevelX on _StockLevel {
  Color get color {
    switch (this) {
      case _StockLevel.critical:
        return AppColors.error;
      case _StockLevel.low:
        return const Color(0xFFE87B2B);
      case _StockLevel.medium:
        return AppColors.warning;
      case _StockLevel.good:
        return AppColors.success;
    }
  }

  String get label {
    switch (this) {
      case _StockLevel.critical:
        return 'Critical';
      case _StockLevel.low:
        return 'Low';
      case _StockLevel.medium:
        return 'Medium';
      case _StockLevel.good:
        return 'Good';
    }
  }
}

// ── Category icon ─────────────────────────────────────────────────────────────

class _CategoryIcon extends StatelessWidget {
  final String category;
  final bool isDark;
  final _StockLevel stockLevel;
  const _CategoryIcon({
    required this.category,
    required this.isDark,
    required this.stockLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: AppColors.coffeeGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.caramel.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(_categoryIcon(category), color: AppColors.cream, size: 20),
    );
  }

  IconData _categoryIcon(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('coffee') || c.contains('bean')) return Icons.coffee;
    if (c.contains('milk') || c.contains('dairy'))
      return Icons.water_drop_outlined;
    if (c.contains('sugar') || c.contains('sweet')) return Icons.cake_outlined;
    if (c.contains('syrup')) return Icons.local_bar;
    if (c.contains('cup') || c.contains('pack'))
      return Icons.inventory_2_outlined;
    return Icons.category_outlined;
  }
}

// ── Category chip ─────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isDark;
  const _CategoryChip({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.caramel.withOpacity(0.12)
            : AppColors.caramel.withOpacity(0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: isDark ? AppColors.caramel : AppColors.coffeeBrown,
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ── Stock badge ───────────────────────────────────────────────────────────────

class _StockBadge extends StatelessWidget {
  final _StockLevel level;
  const _StockBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: level.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: level.color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        level.label,
        style: GoogleFonts.inter(
          color: level.color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Animated stock bar ────────────────────────────────────────────────────────

class _StockBar extends StatelessWidget {
  final double percentage;
  final _StockLevel level;
  final bool isDark;
  const _StockBar({
    required this.percentage,
    required this.level,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Stock Level',
              style: GoogleFonts.inter(
                color: (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight)
                    .withOpacity(0.7),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(percentage * 100).toInt()}%',
              style: GoogleFonts.inter(
                color: level.color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 5,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: isDark
                ? AppColors.darkBorder.withOpacity(0.5)
                : AppColors.lightBorder.withOpacity(0.7),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: LinearGradient(
                  colors: [level.color, level.color.withOpacity(0.6)],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Quick add button ──────────────────────────────────────────────────────────

class _QuickAddButton extends StatelessWidget {
  final InventoryItem item;
  const _QuickAddButton({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StockAdjustmentPage(item: item, isStockIn: true),
          ),
        );
      },
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          gradient: AppColors.coffeeGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.caramel.withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: AppColors.cream, size: 16),
      ),
    );
  }
}
