import 'package:coffee_app/core/widgets/premium_card.dart';
import 'package:coffee_app/features/reports/domain/report_models.dart';
import 'package:flutter/material.dart';

class ReportsSummaryGrid extends StatelessWidget {
  final ReportData data;

  const ReportsSummaryGrid({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(
          context,
          'Total Estimated Sales',
          '\$${data.totalSales.toStringAsFixed(2)}',
          Icons.point_of_sale_outlined,
          color: Colors.green,
        ),
        _buildStatCard(
          context,
          'Estimated Loss Value',
          '\$${data.expectedLossValue.toStringAsFixed(2)}',
          Icons.money_off_csred_outlined,
          color: Theme.of(context).colorScheme.error,
        ),
        _buildStatCard(
          context,
          'Stock Loss %',
          '${(100 - data.stockAccuracy).toStringAsFixed(1)}%',
          Icons.trending_down_outlined,
          color: Colors.orange,
        ),
        _buildStatCard(
          context,
          'Low Stock Items',
          data.lowStockItemsCount.toString(),
          Icons.inventory_2_outlined,
          color: Colors.blueAccent,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon, {
    Color color = Colors.blueAccent,
  }) {
    final theme = Theme.of(context);
    return PremiumCard(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
