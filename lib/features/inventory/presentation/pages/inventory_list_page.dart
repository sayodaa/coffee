import 'dart:ui';

import 'package:coffee_app/core/localization/json_localizations.dart';
import 'package:coffee_app/core/localization/lang_keys.dart';
import 'package:coffee_app/core/services/pdf_report_service.dart';
import 'package:coffee_app/core/theme/app_colors.dart';
import 'package:coffee_app/features/inventory/domain/entities/inventory_item.dart';
import 'package:coffee_app/features/inventory/presentation/bloc/inventory_cubit.dart';
import 'package:coffee_app/features/inventory/presentation/bloc/inventory_state.dart';
import 'package:coffee_app/features/inventory/presentation/pages/inventory_form_page.dart';
import 'package:coffee_app/features/inventory/presentation/widgets/inventory_card.dart';
import 'package:coffee_app/presentation/widgets/shimmers/inventory_shimmer.dart';
import 'package:coffee_app/shared/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class InventoryListPage extends StatefulWidget {
  const InventoryListPage({super.key});

  @override
  State<InventoryListPage> createState() => _InventoryListPageState();
}

class _InventoryListPageState extends State<InventoryListPage> {
  @override
  void initState() {
    super.initState();
    debugPrint(
        '[DEBUG] InventoryListPage.initState: Triggering loadInventory()');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<InventoryCubit>().loadInventory();
      }
    });
  }

  void _navigateToForm([InventoryItem? item]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InventoryFormPage(initialItem: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // ── Main content ─────────────────────────────────────────────
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Cinematic SliverAppBar ──────────────────────────────
              _InventorySliverAppBar(isDark: isDark),

              // ── Body ────────────────────────────────────────────────
              BlocBuilder<InventoryCubit, InventoryState>(
                builder: (context, state) {
                  if (state is InventoryLoading) {
                    return const SliverFillRemaining(
                      child: Center(child: InventoryShimmer()),
                    );
                  }

                  if (state is InventoryEmpty) {
                    return SliverFillRemaining(
                      child: EmptyStateWidget(
                        icon: Icons.inventory_2_outlined,
                        title: 'Your Shelves Are Empty',
                        subtitle:
                            'Start stocking your premium coffee bar — add your first item.',
                        actionLabel: context.tr(LangKeys.add_item),
                        onActionPressed: () => _navigateToForm(),
                      ),
                    );
                  }

                  if (state is InventoryLoaded) {
                    final lowStockItems =
                        state.items.where((i) => i.isLowStock).toList();
                    final normalItems =
                        state.items.where((i) => !i.isLowStock).toList();

                    return SliverList(
                      delegate: SliverChildListDelegate([
                        // Low stock alert banner
                        if (lowStockItems.isNotEmpty)
                          _LowStockBanner(
                            count: lowStockItems.length,
                            isDark: isDark,
                          ),

                        // Low stock items
                        ...lowStockItems
                            .map((item) => InventoryCard(item: item)),

                        // Section divider
                        if (lowStockItems.isNotEmpty && normalItems.isNotEmpty)
                          _SectionHeader(
                            label: context.tr(LangKeys.other_items),
                            isDark: isDark,
                          ),

                        // Normal items
                        ...normalItems.map((item) => InventoryCard(item: item)),

                        // Bottom padding for nav bar
                        const SizedBox(height: 120),
                      ]),
                    );
                  }

                  if (state is InventoryError) {
                    return SliverFillRemaining(
                      child: _ErrorState(
                        message: state.message,
                        onRetry: () =>
                            context.read<InventoryCubit>().refreshInventory(),
                      ),
                    );
                  }

                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                },
              ),
            ],
          ),

          // ── FAB ──────────────────────────────────────────────────────
          Positioned(
            right: 20,
            bottom: 120,
            child: _PremiumFab(
              onTap: () => _navigateToForm(),
              label: context.tr(LangKeys.add_item),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cinematic SliverAppBar ────────────────────────────────────────────────────

class _InventorySliverAppBar extends StatelessWidget {
  final bool isDark;
  const _InventorySliverAppBar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return SliverAppBar(
      expandedHeight: 180 + topPadding,
      pinned: true,
      floating: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: LayoutBuilder(builder: (context, constraints) {
        final expandRatio =
            ((constraints.maxHeight - kToolbarHeight - topPadding) / 180)
                .clamp(0.0, 1.0);
        final isCollapsed = expandRatio < 0.15;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            Image.asset('assets/images/coffee3.jpg', fit: BoxFit.cover),
            // Dark gradient
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x44000000), Color(0xCC0A0500)],
                ),
              ),
            ),
            // Glass collapse overlay
            AnimatedOpacity(
              opacity: isCollapsed ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                      color: AppColors.darkBackground.withOpacity(0.8)),
                ),
              ),
            ),
            // Title
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedOpacity(
                            opacity: expandRatio,
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              'INVENTORY',
                              style: GoogleFonts.inter(
                                color: AppColors.caramel,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.8,
                              ),
                            ),
                          ),
                          Text(
                            context.tr(LangKeys.nav_stock),
                            style: GoogleFonts.inter(
                              color: AppColors.cream,
                              fontSize: isCollapsed ? 18 : 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Action buttons
                    _AppBarAction(
                      icon: Icons.picture_as_pdf_outlined,
                      tooltip: context.tr(LangKeys.export_inventory_pdf),
                      onTap: () {
                        final items =
                            context.read<InventoryCubit>().cachedItems;
                        if (items.isNotEmpty)
                          PdfReportService.generateInventoryReport(
                              items, false);
                      },
                    ),
                    const SizedBox(width: 8),
                    _AppBarAction(
                      icon: Icons.warning_amber_rounded,
                      tooltip: context.tr(LangKeys.export_low_stock_pdf),
                      onTap: () {
                        final items =
                            context.read<InventoryCubit>().cachedItems;
                        if (items.isNotEmpty)
                          PdfReportService.generateInventoryReport(items, true);
                      },
                    ),
                    const SizedBox(width: 8),
                    // _AppBarAction(
                    //   icon: Icons.refresh_rounded,
                    //   tooltip: context.tr(LangKeys.refresh_inventory),
                    //   onTap: () {
                    //     debugPrint(
                    //         '[DEBUG] InventoryListPage: Refresh button pressed');
                    //     context.read<InventoryCubit>().refreshInventory();
                    //   },
                    // ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ── App bar action ────────────────────────────────────────────────────────────

class _AppBarAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _AppBarAction(
      {required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 100, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.darkBackground.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.caramel.withOpacity(0.2)),
              ),
              child: Icon(icon, color: AppColors.cream, size: 26),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Low stock banner ──────────────────────────────────────────────────────────

class _LowStockBanner extends StatelessWidget {
  final int count;
  final bool isDark;
  const _LowStockBanner({required this.count, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$count ${context.tr(LangKeys.items_low_stock)}',
                style: GoogleFonts.inter(
                  color: AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionHeader({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          color: isDark ? AppColors.caramel : AppColors.coffeeBrown,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

// ── Premium FAB ───────────────────────────────────────────────────────────────

class _PremiumFab extends StatefulWidget {
  final VoidCallback onTap;
  final String label;
  const _PremiumFab({required this.onTap, required this.label});

  @override
  State<_PremiumFab> createState() => _PremiumFabState();
}

class _PremiumFabState extends State<_PremiumFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100), value: 1);
    _scale = Tween<double>(begin: 0.94, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.reverse(),
        onTapUp: (_) {
          _ctrl.forward();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.forward(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: AppColors.coffeeGradient,
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: AppColors.caramel.withOpacity(0.45),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, color: AppColors.cream, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  color: AppColors.cream,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 56, color: AppColors.error.withOpacity(0.8)),
            const SizedBox(height: 16),
            Text(
              'Something Went Wrong',
              style: GoogleFonts.inter(
                color: isDark ? AppColors.cream : AppColors.textPrimaryLight,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.tr(LangKeys.retry)),
            ),
          ],
        ),
      ),
    );
  }
}
