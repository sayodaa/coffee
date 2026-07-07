import 'package:coffee_app/core/localization/json_localizations.dart';
import 'package:coffee_app/core/localization/lang_keys.dart';
import 'package:coffee_app/core/widgets/premium_card.dart';
import 'package:coffee_app/features/inventory/presentation/bloc/inventory_cubit.dart';
import 'package:coffee_app/features/inventory/presentation/bloc/inventory_state.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardMainStatCard extends StatelessWidget {
  const DashboardMainStatCard({super.key});

  double _calculateTotalInventoryValue(List items) {
    double total = 0;
    for (var item in items) {
      total += (item.quantity * item.price);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<InventoryCubit, InventoryState>(
      builder: (context, state) {
        double totalValue = 0;
        List sparklineData = [5.0, 8.0, 12.0, 10.0, 15.0, 18.0, 20.0];

        final items = state is InventoryLoaded
            ? state.items
            : context.read<InventoryCubit>().cachedItems;

        if (items.isNotEmpty) {
          totalValue = _calculateTotalInventoryValue(items);
          // Generate sparkline from quantities
          sparklineData = items.map((item) => (item.quantity * 1.0).clamp(0, 20)).toList();
          if (sparklineData.isEmpty) {
            sparklineData = [5.0, 8.0, 12.0, 10.0, 15.0, 18.0, 20.0];
          }
        }

        return PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr(LangKeys.total_inventory_value),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.trending_up,
                          color: Colors.green,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          totalValue > 0 ? '+${(totalValue % 100).toStringAsFixed(1)}%' : '0%',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '\$${totalValue.toStringAsFixed(2)}',
                style: theme.textTheme.displayMedium?.copyWith(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 60,
                child: LineChart(
                  LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        spots: sparklineData.asMap().entries.map((e) {
                          final v = e.value;
                          double val;
                          if (v is num) {
                            val = v.toDouble();
                          } else if (v is String) {
                            val = double.tryParse(v) ?? 0.0;
                          } else {
                            val = 0.0;
                          }
                          return FlSpot(e.key.toDouble(), val);
                        }).toList(),
                        isCurved: true,
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                        ),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary.withOpacity(0.3),
                              theme.colorScheme.secondary.withOpacity(0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
