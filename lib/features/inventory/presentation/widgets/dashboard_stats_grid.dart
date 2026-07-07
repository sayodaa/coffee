import 'package:coffee_app/auth/providers/auth_provider.dart';
import 'package:coffee_app/core/utils/navigation_helper.dart';
import 'package:coffee_app/core/widgets/premium_card.dart';
import 'package:coffee_app/features/inventory/presentation/bloc/inventory_cubit.dart';
import 'package:coffee_app/features/inventory/presentation/bloc/inventory_state.dart';
import 'package:coffee_app/features/reports/presentation/bloc/reports_cubit.dart';
import 'package:coffee_app/features/sales/presentation/bloc/sales_cubit.dart';
import 'package:coffee_app/features/sales/presentation/bloc/sales_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardStatsGrid extends StatelessWidget {
  final Function(int) onNavigate;

  const DashboardStatsGrid({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final role = authProvider.role ?? 'barista';

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildInventoryStatCard(role),
        _buildLowStockCard(role),
        _buildSalesCard(role),
        if (role?.toLowerCase() == 'admin') _buildLossCard(role),
      ],
    );
  }

  Widget _buildInventoryStatCard(String? role) {
    return BlocBuilder<InventoryCubit, InventoryState>(
      builder: (context, state) {
        final items = state is InventoryLoaded
            ? state.items
            : context.read<InventoryCubit>().cachedItems;
        final count = items.isNotEmpty ? items.length.toString() : '-';
        // Inventory is at index 1 in allDestinations
        final targetIndex = NavigationHelper.getFilteredIndex(1, role);
        return _buildStatCard(
            context, 'Total Items', count, Icons.inventory_2_outlined,
            color: Colors.blueAccent, onTap: () => onNavigate(targetIndex!));
      },
    );
  }

  Widget _buildLowStockCard(String? role) {
    return BlocBuilder<InventoryCubit, InventoryState>(
      builder: (context, state) {
        final items = state is InventoryLoaded
            ? state.items
            : context.read<InventoryCubit>().cachedItems;
        final count = items.isNotEmpty
            ? items.where((i) => i.isLowStock).length.toString()
            : '-';
        // Inventory is at index 1 in allDestinations
        final targetIndex = NavigationHelper.getFilteredIndex(1, role);
        return _buildStatCard(
            context, 'Low Stock', count, Icons.warning_amber_outlined,
            color: Theme.of(context).colorScheme.error,
            onTap: () => onNavigate(targetIndex!));
      },
    );
  }

  Widget _buildSalesCard(String? role) {
    return BlocBuilder<SalesCubit, SalesState>(
      builder: (context, state) {
        final sales = state is SalesLoaded
            ? '\$${state.todaySales.toStringAsFixed(1)}'
            : '-';
        // Sales is at index 2 in allDestinations
        final targetIndex = NavigationHelper.getFilteredIndex(2, role);
        return _buildStatCard(
            context, 'Today\'s Sales', sales, Icons.attach_money_outlined,
            color: Colors.green, onTap: () => onNavigate(targetIndex!));
      },
    );
  }

  Widget _buildLossCard(String? role) {
    return BlocBuilder<ReportsCubit, ReportsState>(
      builder: (context, state) {
        final loss = state is ReportsLoaded
            ? '${(100 - state.data.stockAccuracy).toStringAsFixed(1)}%'
            : '-';
        // Reports is at index 3 in allDestinations
        final targetIndex = NavigationHelper.getFilteredIndex(3, role);
        return _buildStatCard(
            context, 'Est. Loss', loss, Icons.trending_down_outlined,
            color: Colors.redAccent, onTap: () => onNavigate(targetIndex!));
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon, {
    Color color = Colors.blueAccent,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
