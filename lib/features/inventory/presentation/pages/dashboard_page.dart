import 'package:coffee_app/auth/providers/auth_provider.dart';
import 'package:coffee_app/core/utils/navigation_helper.dart';
import 'package:coffee_app/core/widgets/glass_nav_bar.dart';
import 'package:coffee_app/features/ai_assistant/view/ai_history_page.dart';
import 'package:coffee_app/features/inventory/presentation/bloc/inventory_cubit.dart';
import 'package:coffee_app/features/inventory/presentation/bloc/inventory_state.dart';
import 'package:coffee_app/features/inventory/presentation/pages/inventory_list_page.dart';
import 'package:coffee_app/features/inventory/presentation/widgets/dashboard_app_bar.dart';
import 'package:coffee_app/features/inventory/presentation/widgets/dashboard_greeting.dart';
import 'package:coffee_app/features/inventory/presentation/widgets/dashboard_main_stat_card.dart';
import 'package:coffee_app/features/inventory/presentation/widgets/dashboard_skeleton.dart';
import 'package:coffee_app/features/inventory/presentation/widgets/dashboard_stats_grid.dart';
import 'package:coffee_app/features/inventory/presentation/widgets/dashboard_stock_chart.dart';
import 'package:coffee_app/features/inventory/presentation/widgets/dashboard_weekly_chart.dart';
import 'package:coffee_app/features/reports/presentation/pages/reports_page.dart';
import 'package:coffee_app/features/sales/presentation/pages/recipes_page.dart';
import 'package:coffee_app/features/sales/presentation/pages/sales_page.dart';
import 'package:coffee_app/features/settings/presentation/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PremiumDashboardPage extends StatefulWidget {
  const PremiumDashboardPage({super.key});
  @override
  State<PremiumDashboardPage> createState() => _PremiumDashboardPageState();
}

class _PremiumDashboardPageState extends State<PremiumDashboardPage>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  late AnimationController _ac;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fade = CurvedAnimation(parent: _ac, curve: Curves.easeInOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));
    _ac.forward();
  }

  @override
  void dispose() {
    _ac.dispose();
    _pageController.dispose();
    super.dispose();
  }

  List<Widget> _buildPages(String? role) {
    final destinations = NavigationHelper.getDestinationsForRole(role);
    final pages = <Widget>[];

    for (final destination in destinations) {
      if (destination.adminOnly && role?.toLowerCase() != 'admin') {
        continue;
      }

      // Build page based on destination
      if (destination.icon == Icons.dashboard_rounded) {
        pages.add(_buildDashboard());
      } else if (destination.icon == Icons.inventory_2_rounded) {
        pages.add(const InventoryListPage());
      } else if (destination.icon == Icons.point_of_sale_rounded) {
        pages.add(const SalesPage());
      } else if (destination.icon == Icons.analytics_rounded) {
        pages.add(const ReportsPage());
      } else if (destination.icon == Icons.menu_book_rounded) {
        pages.add(const RecipesPage());
      } else if (destination.icon == Icons.settings_rounded) {
        pages.add(const SettingsPage());
      }
    }

    return pages;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final role = authProvider.role ?? 'barista';

    // Build pages synchronized with navigation items
    _pages = _buildPages(role);

    // Ensure current index is valid for the role
    if (!NavigationHelper.isValidIndex(_currentIndex, role)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _currentIndex = NavigationHelper.getDefaultIndex(role);
          _pageController.jumpToPage(_currentIndex);
        });
      });
    }

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.miniStartFloat,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: _currentIndex == 0 && authProvider.isAdmin
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AiHistoryPage()),
                );
              },
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(Icons.smart_toy,
                  color: Theme.of(context).colorScheme.onPrimary),
            )
          : null,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (i) => setState(() => _currentIndex = i),
            children: _pages,
          ),
          GlassNavBar(
            currentIndex: _currentIndex,
            onTap: (i) {
              if (NavigationHelper.isValidIndex(i, role)) {
                _pageController.animateToPage(
                  i,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const DashboardAppBar(),
        DashboardGreeting(fadeAnimation: _fade),
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: BlocBuilder<InventoryCubit, InventoryState>(
            builder: (context, state) {
              if (state is InventoryLoading) return const DashboardSkeleton();
              if (state is InventoryLoaded || state is InventoryEmpty) {
                return SliverList(
                  delegate: SliverChildListDelegate([
                    Hero(
                      tag: 'main-stat',
                      child: SlideTransition(
                        position: _slide,
                        child: FadeTransition(
                          opacity: _fade,
                          child: const DashboardMainStatCard(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    DashboardStatsGrid(
                      onNavigate: (index) {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    const DashboardStockChart(),
                    const SizedBox(height: 32),
                    const DashboardWeeklyChart(),
                    const SizedBox(height: 120),
                  ]),
                );
              }
              if (state is InventoryError) {
                return SliverToBoxAdapter(
                  child: Center(child: Text(state.message)),
                );
              }
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            },
          ),
        ),
      ],
    );
  }
}
