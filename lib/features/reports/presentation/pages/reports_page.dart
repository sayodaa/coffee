import 'dart:convert';

import 'package:coffee_app/auth/providers/auth_provider.dart';
import 'package:coffee_app/core/localization/json_localizations.dart';
import 'package:coffee_app/core/localization/lang_keys.dart';
import 'package:coffee_app/features/ai_assistant/view/ai_assistant_page.dart';
import 'package:coffee_app/features/inventory/presentation/bloc/inventory_cubit.dart';
import 'package:coffee_app/features/sales/presentation/bloc/sales_cubit.dart';
import 'package:coffee_app/features/sales/presentation/bloc/sales_state.dart';
import 'package:coffee_app/new_data/bi_ai_assistant_card.dart';
import 'package:coffee_app/new_data/bi_category_pie_chart.dart';
import 'package:coffee_app/new_data/bi_insights_recommendations.dart';
import 'package:coffee_app/new_data/bi_kpi_grid.dart';
import 'package:coffee_app/new_data/bi_material_analytics.dart';
import 'package:coffee_app/new_data/bi_peak_hours_chart.dart';
import 'package:coffee_app/new_data/bi_product_ranking_list.dart';
import 'package:coffee_app/new_data/bi_revenue_chart.dart';
import 'package:coffee_app/new_data/bi_smart_alerts.dart';
import 'package:coffee_app/new_data/bi_theme.dart';
import 'package:coffee_app/new_data/business_intelligence_cubit.dart';
import 'package:coffee_app/new_data/business_intelligence_state.dart';
import 'package:coffee_app/new_data/business_report.dart';
import 'package:coffee_app/new_data/sales_asset_data_source.dart';
import 'package:coffee_app/new_data/sales_repository_impl.dart';
import 'package:coffee_app/presentation/widgets/shimmers/reports_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ─── Local theme constants (kept consistent with the rest of the app) ────────

const _kCaramel = Color(0xFFC68E52);
const _kWhite = Colors.white;
// Solid coffee-themed background colors (replaces the photo background).
const _kBgDark = Color(0xFF1B1512);
const _kBgMid = Color(0xFF2A211C);

/// Replaces the previous consumption/loss report with a full Business
/// Intelligence dashboard, backed by `assets/data/sales.json`.
///
/// Everything around the content — background, floating header, entrance
/// animations, responsive breakpoints, and the Admin-only gate — is
/// unchanged from the original `ReportsPage`. Only `_buildBody` and its data
/// source were replaced.
class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  late final BusinessIntelligenceCubit _biCubit;

  @override
  void initState() {
    super.initState();
    // Self-contained: the cubit is created and owned by this page rather
    // than requiring a new BlocProvider registration higher up the tree.
    // Hoist this into your existing DI/provider setup if you'd rather share
    // one instance across routes.
    _biCubit = BusinessIntelligenceCubit(
      repository: SalesRepositoryImpl(
        dataSource: SalesAssetDataSourceImpl(),
      ),
    )..load();
  }

  @override
  void dispose() {
    _biCubit.close();
    super.dispose();
  }

  /// Existing "AI Analysis" header action — unchanged. This inspects the
  /// live inventory/sales cubits and opens the general AI assistant with a
  /// raw snapshot, same as before. This is separate from the "Ask Business
  /// AI" card inside the new dashboard body, which only ever sends the
  /// compact, summarized [BusinessIntelligenceCubit] report.
  void _triggerAiAnalysis() {
    final inventoryItems = context.read<InventoryCubit>().cachedItems;
    final salesCubit = context.read<SalesCubit>();
    final salesState = salesCubit.state;
    final recipes = salesCubit.cachedRecipes;

    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 30));
    final endDate = now;

    final inventoryMap = {
      for (var item in inventoryItems) item.name: item.quantity
    };

    final salesList = [];
    if (salesState is SalesLoaded) {
      final filteredSales = salesState.sales.where((s) {
        if (s.timestamp.isBefore(startDate)) return false;
        if (s.timestamp.isAfter(endDate.add(const Duration(days: 1)))) {
          return false;
        }
        return true;
      });
      for (var sale in filteredSales) {
        for (final item in sale.items) {
          salesList.add({
            "drink": item.productName,
            "quantity": item.quantity,
            "total_price": item.totalPrice.amount
          });
        }
      }
    }

    final recipesMap = {
      for (var recipe in recipes)
        recipe.productName: {
          for (var ing in recipe.ingredients)
            ing.inventoryItemId: ing.quantityRequiredPerUnit
        }
    };

    final payload = {
      "current_inventory": inventoryMap,
      "sales_in_period": salesList,
      "recipes": recipesMap,
      "report_period": {
        "start": startDate.toIso8601String(),
        "end": endDate.toIso8601String()
      }
    };

    final prompt =
        "Please analyze the following data snapshot and provide your insights according to your system instructions:\n\n${jsonEncode(payload)}";

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiAssistantPage(
          conversationId: null,
          initialPrompt: prompt,
        ),
      ),
    );
  }

  /// Opens the shared AI assistant with a prompt built from the *compact*
  /// [BusinessIntelligenceCubit] report — never raw sales rows. Wired up to
  /// [BiAiAssistantCard.onAsk].
  void _askBusinessAi(String prompt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiAssistantPage(
          conversationId: null,
          initialPrompt: prompt,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.loggedIn || auth.role == 'barista') {
      return Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            const _ReportsBackground(),
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock_outline_rounded,
                                size: 48, color: _kWhite),
                            const SizedBox(height: 16),
                            Text(
                              context.tr(LangKeys.unauthorized),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    // Responsive breakpoints: phone / tablet+ / wide desktop.
    final isTablet = width >= 700;
    final isWide = width >= 1000;
    final horizontalPadding = isWide ? 40.0 : (isTablet ? 32.0 : 20.0);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _ReportsBackground(),
          SafeArea(
            child: Column(
              children: [
                _FloatingHeader(
                  title: context.tr(LangKeys.reports_analytics_title),
                  actions: [
                    _HeaderIcon(
                      icon: Icons.analytics_outlined,
                      tooltip: context.tr(LangKeys.ai_analysis),
                      onPressed: _triggerAiAnalysis,
                    ),
                  ],
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: _kWhite,
                    backgroundColor: const Color(0xFF1B1512),
                    onRefresh: () async {
                      await _biCubit.refresh();
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                              horizontalPadding, 8, horizontalPadding, 40),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              BlocBuilder<BusinessIntelligenceCubit,
                                  BusinessIntelligenceState>(
                                bloc: _biCubit,
                                builder: (context, state) {
                                  return AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 350),
                                    switchInCurve: Curves.easeOut,
                                    switchOutCurve: Curves.easeIn,
                                    transitionBuilder: (child, animation) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      );
                                    },
                                    child: _buildBody(context, state, isTablet),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, BusinessIntelligenceState state, bool isTablet) {
    if (state is BusinessIntelligenceLoading) {
      return const KeyedSubtree(
        key: ValueKey('loading'),
        child: ReportsShimmer(),
      );
    } else if (state is BusinessIntelligenceLoaded) {
      final report = state.report;
      return KeyedSubtree(
        key: const ValueKey('loaded'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row: title + date + last refreshed ──────────────
            _FadeSlideIn(
              delay: const Duration(milliseconds: 0),
              child: _BiHeaderRow(generatedAt: state.generatedAt),
            ),
            const SizedBox(height: 28),

            // ── KPI cards ────────────────────────────────────────────────
            _FadeSlideIn(
              delay: const Duration(milliseconds: 40),
              child: BiKpiGrid(report: report),
            ),
            const SizedBox(height: 36),

            // ── Revenue charts ───────────────────────────────────────────
            _FadeSlideIn(
              delay: const Duration(milliseconds: 80),
              child: const _SectionHeader(
                icon: Icons.show_chart_rounded,
                title: 'Revenue Trends',
              ),
            ),
            const SizedBox(height: 16),
            _FadeSlideIn(
              delay: const Duration(milliseconds: 120),
              child: BiRevenueChart(revenueByMonth: report.revenueByMonth),
            ),
            const SizedBox(height: 36),

            // ── Category analytics ───────────────────────────────────────
            _FadeSlideIn(
              delay: const Duration(milliseconds: 160),
              child: const _SectionHeader(
                icon: Icons.pie_chart_rounded,
                title: 'Category Analytics',
              ),
            ),
            const SizedBox(height: 16),
            _FadeSlideIn(
              delay: const Duration(milliseconds: 200),
              child: BiCategoryPieChart(categoryStats: report.categoryStats),
            ),
            const SizedBox(height: 36),

            // ── Product analytics ────────────────────────────────────────
            _FadeSlideIn(
              delay: const Duration(milliseconds: 240),
              child: const _SectionHeader(
                icon: Icons.local_cafe_rounded,
                title: 'Product Analytics',
              ),
            ),
            const SizedBox(height: 16),
            _FadeSlideIn(
              delay: const Duration(milliseconds: 260),
              child: _ProductAnalyticsGrid(report: report, isTablet: isTablet),
            ),
            const SizedBox(height: 36),

            // ── Material analytics ───────────────────────────────────────
            _FadeSlideIn(
              delay: const Duration(milliseconds: 300),
              child: const _SectionHeader(
                icon: Icons.inventory_2_rounded,
                title: 'Material Analytics',
              ),
            ),
            const SizedBox(height: 16),
            _FadeSlideIn(
              delay: const Duration(milliseconds: 320),
              child: BiMaterialAnalytics(
                topConsumed: report.topConsumedMaterials,
                highestCost: report.highestCostMaterials,
              ),
            ),
            const SizedBox(height: 36),

            // ── Peak hours ────────────────────────────────────────────────
            _FadeSlideIn(
              delay: const Duration(milliseconds: 360),
              child: const _SectionHeader(
                icon: Icons.schedule_rounded,
                title: 'Peak Hours',
              ),
            ),
            const SizedBox(height: 16),
            _FadeSlideIn(
              delay: const Duration(milliseconds: 380),
              child: BiPeakHoursChart(peakHours: report.peakHours),
            ),
            const SizedBox(height: 36),

            // ── Smart alerts ──────────────────────────────────────────────
            _FadeSlideIn(
              delay: const Duration(milliseconds: 420),
              child: const _SectionHeader(
                icon: Icons.warning_amber_rounded,
                title: 'Smart Alerts',
              ),
            ),
            const SizedBox(height: 16),
            _FadeSlideIn(
              delay: const Duration(milliseconds: 440),
              child: BiSmartAlerts(alerts: report.alerts),
            ),
            const SizedBox(height: 36),

            // ── AI insights & recommendations ────────────────────────────
            _FadeSlideIn(
              delay: const Duration(milliseconds: 480),
              child: const _SectionHeader(
                icon: Icons.auto_awesome_rounded,
                title: 'AI Insights & Recommendations',
              ),
            ),
            const SizedBox(height: 16),
            _FadeSlideIn(
              delay: const Duration(milliseconds: 500),
              child: BiInsightsRecommendations(
                insights: report.insights,
                recommendations: report.recommendations,
              ),
            ),
            const SizedBox(height: 36),

            // ── Ask Business AI ───────────────────────────────────────────
            _FadeSlideIn(
              delay: const Duration(milliseconds: 540),
              child: BiAiAssistantCard(
                report: report,
                onAsk: _askBusinessAi,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      );
    } else if (state is BusinessIntelligenceError) {
      return KeyedSubtree(
        key: const ValueKey('error'),
        child: _buildErrorState(context, state.message),
      );
    }
    return const SizedBox.shrink(key: ValueKey('empty'));
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, size: 56, color: _kWhite),
          const SizedBox(height: 16),
          Text(
            context.tr(LangKeys.analysis_failed),
            style: theme.textTheme.titleLarge?.copyWith(
              color: _kWhite,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: _kWhite.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kCaramel,
              foregroundColor: _kWhite,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            onPressed: () => _biCubit.load(),
            icon: const Icon(Icons.refresh),
            label: Text(context.tr(LangKeys.try_again)),
          ),
        ],
      ),
    );
  }
}

// ─── BI header row: "Business Intelligence" / "Coffee Analytics" + date ──────

class _BiHeaderRow extends StatelessWidget {
  final DateTime generatedAt;

  const _BiHeaderRow({required this.generatedAt});

  @override
  Widget build(BuildContext context) {
    final dateLabel = '${_weekday(generatedAt.weekday)}, '
        '${_month(generatedAt.month)} ${generatedAt.day}, ${generatedAt.year}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Business Intelligence',
                style: TextStyle(
                  color: _kWhite,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Coffee Analytics · $dateLabel',
                style: TextStyle(
                  color: _kWhite.withOpacity(0.6),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _weekday(int w) => const [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ][w - 1];

  static String _month(int m) => const [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ][m - 1];
}

// ─── Product analytics: responsive grid of ranking lists ────────────────────

class _ProductAnalyticsGrid extends StatelessWidget {
  final BusinessReport report;
  final bool isTablet;

  const _ProductAnalyticsGrid({required this.report, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    final columns = isTablet ? 2 : 1;

    final lists = [
      BiProductRankingList(
        title: 'Top Selling Products',
        icon: Icons.trending_up_rounded,
        products: report.topSellingProducts,
        metric: ProductRankingMetric.quantity,
        accentColor: BiColors.success,
      ),
      BiProductRankingList(
        title: 'Least Selling Products',
        icon: Icons.trending_down_rounded,
        products: report.leastSellingProducts,
        metric: ProductRankingMetric.quantity,
        accentColor: BiColors.warning,
      ),
      BiProductRankingList(
        title: 'Most Profitable Products',
        icon: Icons.emoji_events_rounded,
        products: report.mostProfitableProducts,
        metric: ProductRankingMetric.profit,
        accentColor: BiColors.success,
      ),
      BiProductRankingList(
        title: 'Lowest Profit Products',
        icon: Icons.report_problem_rounded,
        products: report.leastProfitableProducts,
        metric: ProductRankingMetric.profit,
        accentColor: BiColors.critical,
      ),
    ];

    if (columns == 1) {
      return Column(
        children: [
          for (final w in lists) ...[w, const SizedBox(height: 16)],
        ],
      );
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: lists[0]),
            const SizedBox(width: 16),
            Expanded(child: lists[1]),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: lists[2]),
            const SizedBox(width: 16),
            Expanded(child: lists[3]),
          ],
        ),
      ],
    );
  }
}

// ─── Background (photo + scrim, static — no motion here) ─────────────────────

class _ReportsBackground extends StatelessWidget {
  const _ReportsBackground();

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
      ],
    );
  }
}

// ─── Fade + slide entrance animation for individual components ───────────────

class _FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _FadeSlideIn({
    required this.child,
    this.delay = Duration.zero,
  });

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

// ─── Floating header (replaces AppBar — no bar, no background) ───────────────

class _FloatingHeader extends StatelessWidget {
  final String title;
  final List<Widget> actions;

  const _FloatingHeader({
    required this.title,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final titleSize = width >= 700 ? 22.0 : (width <= 340 ? 17.0 : 19.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: _kWhite,
                fontSize: titleSize,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                shadows: const [
                  Shadow(
                    color: Colors.black45,
                    blurRadius: 6,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Wrap(
            spacing: 0,
            children: actions,
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _HeaderIcon({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: _kWhite, size: 22),
      tooltip: tooltip,
      onPressed: onPressed,
      splashRadius: 22,
    );
  }
}

// ─── Section header (icon + title, no box) ────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final fontSize = width >= 700 ? 19.0 : 17.0;

    return Row(
      children: [
        Icon(icon, size: 20, color: _kWhite),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: _kWhite,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ],
    );
  }
}

// import 'dart:convert';

// import 'package:coffee_app/auth/providers/auth_provider.dart';
// import 'package:coffee_app/core/localization/json_localizations.dart';
// import 'package:coffee_app/core/localization/lang_keys.dart';
// import 'package:coffee_app/core/services/pdf_report_service.dart';
// import 'package:coffee_app/features/ai_assistant/view/ai_assistant_page.dart';
// import 'package:coffee_app/features/inventory/presentation/bloc/inventory_cubit.dart';
// import 'package:coffee_app/features/reports/presentation/bloc/reports_cubit.dart';
// import 'package:coffee_app/features/reports/presentation/widgets/reports_bar_chart.dart';
// import 'package:coffee_app/features/reports/presentation/widgets/reports_detailed_table.dart';
// import 'package:coffee_app/features/reports/presentation/widgets/reports_pie_chart.dart';
// import 'package:coffee_app/features/reports/presentation/widgets/reports_summary_grid.dart';
// import 'package:coffee_app/features/sales/presentation/bloc/sales_cubit.dart';
// import 'package:coffee_app/features/sales/presentation/bloc/sales_state.dart';
// import 'package:coffee_app/presentation/widgets/shimmers/reports_shimmer.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// // ... other imports ...

// // ─── Local theme constants (kept consistent with the rest of the app) ────────

// const _kCaramel = Color(0xFFC68E52);
// const _kWhite = Colors.white;
// // Solid coffee-themed background colors (replaces the photo background).
// const _kBgDark = Color(0xFF1B1512);
// const _kBgMid = Color(0xFF2A211C);

// class ReportsPage extends StatefulWidget {
//   const ReportsPage({super.key});

//   @override
//   State<ReportsPage> createState() => _ReportsPageState();
// }

// class _ReportsPageState extends State<ReportsPage> {
//   void _triggerAiAnalysis() {
//     final inventoryItems = context.read<InventoryCubit>().cachedItems;
//     final salesCubit = context.read<SalesCubit>();
//     final salesState = salesCubit.state;
//     final recipes = salesCubit.cachedRecipes;

//     final reportsState = context.read<ReportsCubit>().state;
//     final startDate = reportsState.startDate;
//     final endDate = reportsState.endDate;

//     // Build Payload
//     final inventoryMap = {
//       for (var item in inventoryItems) item.name: item.quantity
//     };

//     final salesList = [];
//     if (salesState is SalesLoaded) {
//       final filteredSales = salesState.sales.where((s) {
//         if (s.timestamp.isBefore(startDate)) return false;
//         if (s.timestamp.isAfter(endDate.add(const Duration(days: 1)))) {
//           return false;
//         }
//         return true;
//       });
//       for (var sale in filteredSales) {
//         for (final item in sale.items) {
//           salesList.add({
//             "drink": item.productName,
//             "quantity": item.quantity,
//             "total_price": item.totalPrice.amount
//           });
//         }
//       }
//     }

//     final recipesMap = {
//       for (var recipe in recipes)
//         recipe.productName: {
//           for (var ing in recipe.ingredients)
//             ing.inventoryItemId: ing.quantityRequiredPerUnit
//         }
//     };

//     final payload = {
//       "current_inventory": inventoryMap,
//       "sales_in_period": salesList,
//       "recipes": recipesMap,
//       "report_period": {
//         "start": startDate.toIso8601String(),
//         "end": endDate.toIso8601String()
//       }
//     };

//     final prompt =
//         "Please analyze the following data snapshot and provide your insights according to your system instructions:\n\n${jsonEncode(payload)}";

//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => AiAssistantPage(
//           conversationId: null,
//           initialPrompt: prompt,
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final auth = context.watch<AuthProvider>();

//     if (!auth.loggedIn || auth.role == 'barista') {
//       return Scaffold(
//         body: Stack(
//           fit: StackFit.expand,
//           children: [
//             const _ReportsBackground(),
//             SafeArea(
//               child: Column(
//                 children: [
//                   // _FloatingHeader(
//                   //   title: context.tr(LangKeys.reports_analytics_title),
//                   // ),
//                   Expanded(
//                     child: Center(
//                       child: Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 32),
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             const Icon(Icons.lock_outline_rounded,
//                                 size: 48, color: _kWhite),
//                             const SizedBox(height: 16),
//                             Text(
//                               context.tr(LangKeys.unauthorized),
//                               textAlign: TextAlign.center,
//                               // style: Theme.of(context)
//                               //     .textTheme
//                               //     .titleLarge
//                               //     ?.copyWith(
//                               //       color: _kWhite,
//                               //       fontWeight: FontWeight.w700,
//                               //     ),
//                             ),
//                             const SizedBox(height: 24),
//                             // ElevatedButton(
//                             //   style: ElevatedButton.styleFrom(
//                             //     backgroundColor: _kCaramel,
//                             //     foregroundColor: _kWhite,
//                             //     padding: const EdgeInsets.symmetric(
//                             //         horizontal: 28, vertical: 14),
//                             //     shape: RoundedRectangleBorder(
//                             //       borderRadius: BorderRadius.circular(14),
//                             //     ),
//                             //     elevation: 0,
//                             //   ),
//                             //   onPressed: () {
//                             //     Navigator.of(context)
//                             //         .popUntil((route) => route.isFirst);
//                             //   },
//                             //   child: Text(context.tr(LangKeys.go_home)),
//                             // ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       );
//     }

//     final theme = Theme.of(context);
//     final width = MediaQuery.sizeOf(context).width;
//     // Responsive breakpoints: phone / tablet+ / wide desktop.
//     final isTablet = width >= 700;
//     final isWide = width >= 1000;
//     final horizontalPadding = isWide ? 40.0 : (isTablet ? 32.0 : 20.0);
//     final contentMaxWidth =
//         isWide ? 900.0 : (isTablet ? 700.0 : double.infinity);

//     return Scaffold(
//       body: Stack(
//         fit: StackFit.expand,
//         children: [
//           // ── Solid, non-animated background (photo removed) ──
//           const _ReportsBackground(),

//           // ── Content ─────────────────────────────────────────
//           SafeArea(
//             child: Column(
//               children: [
//                 // Header floats directly over the background — no bar/box.
//                 _FloatingHeader(
//                   title: context.tr(LangKeys.reports_analytics_title),
//                   actions: [
//                     _HeaderIcon(
//                       icon: Icons.picture_as_pdf,
//                       tooltip: 'Export PDF',
//                       onPressed: () {
//                         final state = context.read<ReportsCubit>().state;
//                         if (state is ReportsLoaded) {
//                           PdfReportService.generateConsumptionReport(
//                             state.data,
//                             state.startDate,
//                             state.endDate,
//                           );
//                         }
//                       },
//                     ),
//                     // _HeaderIcon(
//                     //   icon: Icons.show_chart,
//                     //   tooltip: 'Generate Forecast',
//                     //   onPressed: () {
//                     //     ScaffoldMessenger.of(context).showSnackBar(
//                     //       const SnackBar(
//                     //           content: Text('Generating Data Forecast...')),
//                     //     );
//                     //     _triggerAiAnalysis();
//                     //   },
//                     // ),
//                     // _HeaderIcon(
//                     //   icon: Icons.fastfood,
//                     //   tooltip: 'View Consumption',
//                     //   onPressed: () {
//                     //     Navigator.push(
//                     //       context,
//                     //       MaterialPageRoute(
//                     //         builder: (_) => const ConsumptionDemoPage(),
//                     //       ),
//                     //     );
//                     //   },
//                     // ),
//                     _HeaderIcon(
//                       icon: Icons.analytics_outlined,
//                       tooltip: context.tr(LangKeys.ai_analysis),
//                       onPressed: _triggerAiAnalysis,
//                     ),
//                   ],
//                 ),

//                 // Scrollable body
//                 Expanded(
//                   child: RefreshIndicator(
//                     color: _kWhite,
//                     backgroundColor: const Color(0xFF1B1512),
//                     onRefresh: () async {
//                       await context.read<ReportsCubit>().fetch();
//                     },
//                     child: SingleChildScrollView(
//                       physics: const AlwaysScrollableScrollPhysics(),
//                       child: Center(
//                         child: Padding(
//                           padding: EdgeInsets.fromLTRB(
//                               horizontalPadding, 8, horizontalPadding, 40),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               BlocBuilder<ReportsCubit, ReportsState>(
//                                 builder: (context, state) {
//                                   return AnimatedSwitcher(
//                                     duration: const Duration(milliseconds: 350),
//                                     switchInCurve: Curves.easeOut,
//                                     switchOutCurve: Curves.easeIn,
//                                     transitionBuilder: (child, animation) {
//                                       return FadeTransition(
//                                         opacity: animation,
//                                         child: child,
//                                       );
//                                     },
//                                     child: _buildBody(context, state, isTablet),
//                                   );
//                                 },
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBody(BuildContext context, ReportsState state, bool isTablet) {
//     if (state is ReportsLoading) {
//       return const KeyedSubtree(
//         key: ValueKey('loading'),
//         child: ReportsShimmer(),
//       );
//     } else if (state is ReportsLoaded) {
//       return KeyedSubtree(
//         key: const ValueKey('loaded'),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _FadeSlideIn(
//               delay: const Duration(milliseconds: 0),
//               child: ReportsSummaryGrid(data: state.data),
//             ),
//             const SizedBox(height: 36),
//             _FadeSlideIn(
//               delay: const Duration(milliseconds: 80),
//               child: _SectionHeader(
//                 icon: Icons.bar_chart_rounded,
//                 title: context.tr(LangKeys.expected_vs_actual_consumption),
//               ),
//             ),
//             const SizedBox(height: 16),
//             _FadeSlideIn(
//               delay: const Duration(milliseconds: 140),
//               child: ReportsBarChart(lossData: state.data.lossAnalysis),
//             ),
//             const SizedBox(height: 36),
//             _FadeSlideIn(
//               delay: const Duration(milliseconds: 200),
//               child: _SectionHeader(
//                 icon: Icons.pie_chart_rounded,
//                 title: context.tr(LangKeys.stock_distribution),
//               ),
//             ),
//             const SizedBox(height: 16),
//             _FadeSlideIn(
//               delay: const Duration(milliseconds: 260),
//               child: const ReportsPieChart(),
//             ),
//             const SizedBox(height: 36),
//             _FadeSlideIn(
//               delay: const Duration(milliseconds: 320),
//               child: _SectionHeader(
//                 icon: Icons.table_rows_rounded,
//                 title: context.tr(LangKeys.detailed_loss_breakdown),
//               ),
//             ),
//             const SizedBox(height: 16),
//             _FadeSlideIn(
//               delay: const Duration(milliseconds: 380),
//               child: ReportsDetailedTable(lossData: state.data.lossAnalysis),
//             ),
//             const SizedBox(height: 40),
//           ],
//         ),
//       );
//     } else if (state is ReportsError) {
//       return KeyedSubtree(
//         key: const ValueKey('error'),
//         child: _buildErrorState(context, state.message),
//       );
//     }
//     return const SizedBox.shrink(key: ValueKey('empty'));
//   }

//   Widget _buildErrorState(BuildContext context, String message) {
//     final theme = Theme.of(context);
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 48),
//       child: Column(
//         children: [
//           const Icon(Icons.error_outline_rounded, size: 56, color: _kWhite),
//           const SizedBox(height: 16),
//           Text(
//             context.tr(LangKeys.analysis_failed),
//             style: theme.textTheme.titleLarge?.copyWith(
//               color: _kWhite,
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             message,
//             textAlign: TextAlign.center,
//             style: theme.textTheme.bodyMedium?.copyWith(
//               color: _kWhite.withOpacity(0.85),
//             ),
//           ),
//           const SizedBox(height: 24),
//           ElevatedButton.icon(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: _kCaramel,
//               foregroundColor: _kWhite,
//               padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(14),
//               ),
//               elevation: 0,
//             ),
//             onPressed: () => context.read<ReportsCubit>().fetch(),
//             icon: const Icon(Icons.refresh),
//             label: Text(context.tr(LangKeys.try_again)),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ─── Background (photo + scrim, static — no motion here) ─────────────────────
// //
// // The image is back. It's layered under a top-to-bottom gradient scrim so the
// // white text/icons stay readable everywhere on the page, and a soft color
// // wash keeps it in the app's warm coffee palette instead of looking like a
// // raw, unedited photo. The background itself doesn't animate — motion lives
// // in the components (see _FadeSlideIn) so the two don't compete.

// class _ReportsBackground extends StatelessWidget {
//   const _ReportsBackground();

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       fit: StackFit.expand,
//       children: [
//         // Base photo.
//         Image.asset(
//           'assets/images/barista1.jpg',
//           fit: BoxFit.cover,
//           alignment: Alignment.topCenter,
//         ),
//         // Warm color wash to tie the photo to the caramel/brown palette.
//         // Container(
//         //   decoration: BoxDecoration(
//         //     gradient: LinearGradient(
//         //       begin: Alignment.topLeft,
//         //       end: Alignment.bottomRight,
//         //       colors: [
//         //         _kBgDark.withOpacity(0.55),
//         //         _kCaramel.withOpacity(0.12),
//         //         _kBgDark.withOpacity(0.55),
//         //       ],
//         //     ),
//         //   ),
//         // ),
//         // Vertical scrim: darker at top (behind header/icons) and bottom
//         // (behind nav bar), lighter in the middle so the photo still reads.
//         // Container(
//         //   decoration: const BoxDecoration(
//         //     gradient: LinearGradient(
//         //       begin: Alignment.topCenter,
//         //       end: Alignment.bottomCenter,
//         //       colors: [
//         //         Color(0xCC1B1512),
//         //         Color(0x661B1512),
//         //         Color(0x331B1512),
//         //         Color(0xDD1B1512),
//         //       ],
//         //       stops: [0.0, 0.28, 0.62, 1.0],
//         //     ),
//         //   ),
//         // ),
//       ],
//     );
//   }
// }

// // ─── Fade + slide entrance animation for individual components ───────────────
// //
// // This is where the "animation" now lives: each section on the page eases in
// // (fade + gentle upward slide) with a small staggered delay, instead of the
// // background carrying any motion.

// class _FadeSlideIn extends StatefulWidget {
//   final Widget child;
//   final Duration delay;

//   const _FadeSlideIn({
//     required this.child,
//     this.delay = Duration.zero,
//   });

//   @override
//   State<_FadeSlideIn> createState() => _FadeSlideInState();
// }

// class _FadeSlideInState extends State<_FadeSlideIn>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _controller;
//   late final Animation<double> _fade;
//   late final Animation<Offset> _slide;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 420),
//     );
//     _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
//     _slide = Tween<Offset>(
//       begin: const Offset(0, 0.06),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

//     Future.delayed(widget.delay, () {
//       if (mounted) _controller.forward();
//     });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FadeTransition(
//       opacity: _fade,
//       child: SlideTransition(
//         position: _slide,
//         child: widget.child,
//       ),
//     );
//   }
// }

// // ─── Floating header (replaces AppBar — no bar, no background) ───────────────

// class _FloatingHeader extends StatelessWidget {
//   final String title;
//   final List<Widget> actions;

//   const _FloatingHeader({
//     required this.title,
//     this.actions = const [],
//   });

//   @override
//   Widget build(BuildContext context) {
//     final width = MediaQuery.sizeOf(context).width;
//     final titleSize = width >= 700 ? 22.0 : (width <= 340 ? 17.0 : 19.0);

//     return Padding(
//       padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
//       child: Row(
//         children: [
//           Expanded(
//             child: Text(
//               title,
//               style: TextStyle(
//                 color: _kWhite,
//                 fontSize: titleSize,
//                 fontWeight: FontWeight.w700,
//                 letterSpacing: -0.3,
//                 shadows: const [
//                   Shadow(
//                     color: Colors.black45,
//                     blurRadius: 6,
//                     offset: Offset(0, 1),
//                   ),
//                 ],
//               ),
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//           // Wrap so action icons never overflow on very narrow screens.
//           Wrap(
//             spacing: 0,
//             children: actions,
//           ),
//           const SizedBox(width: 4),
//         ],
//       ),
//     );
//   }
// }

// class _HeaderIcon extends StatelessWidget {
//   final IconData icon;
//   final String tooltip;
//   final VoidCallback onPressed;

//   const _HeaderIcon({
//     required this.icon,
//     required this.tooltip,
//     required this.onPressed,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return IconButton(
//       icon: Icon(icon, color: _kWhite, size: 22),
//       tooltip: tooltip,
//       onPressed: onPressed,
//       splashRadius: 22,
//     );
//   }
// }

// // ─── Section header (icon + title, no box) ────────────────────────────────────

// class _SectionHeader extends StatelessWidget {
//   final IconData icon;
//   final String title;

//   const _SectionHeader({
//     required this.icon,
//     required this.title,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final width = MediaQuery.sizeOf(context).width;
//     final fontSize = width >= 700 ? 19.0 : 17.0;

//     return Row(
//       children: [
//         Icon(icon, size: 20, color: _kWhite),
//         const SizedBox(width: 10),
//         Expanded(
//           child: Text(
//             title,
//             style: TextStyle(
//               color: _kWhite,
//               fontSize: fontSize,
//               fontWeight: FontWeight.w700,
//               letterSpacing: -0.3,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// // ─── Subtle dark tint behind data components (not a card, just contrast) ─────

// // class _DataTint extends StatelessWidget {
// //   final Widget child;
// //   final EdgeInsetsGeometry padding;

// //   const _DataTint({
// //     required this.child,
// //     this.padding = const EdgeInsets.all(14),
// //   });

// //   @override
// //   Widget build(BuildContext context) {
// //     return ClipRRect(
// //       borderRadius: BorderRadius.circular(30),
// //       child: Container(
// //         width: double.infinity,
// //         padding: padding,
// //         decoration: BoxDecoration(
// //           color: Colors.black.withOpacity(0.42),
// //           border: Border.all(color: Colors.white.withOpacity(0.06)),
// //         ),
// //         child: child,
// //       ),
// //     );
// //   }
// // }
