import 'package:coffee_app/core/widgets/premium_card.dart';
import 'package:coffee_app/features/inventory/presentation/bloc/inventory_cubit.dart';
import 'package:coffee_app/features/inventory/presentation/bloc/inventory_state.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardStockChart extends StatelessWidget {
  const DashboardStockChart({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'Stock Health',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        PremiumCard(
          height: 240,
          child: BlocBuilder<InventoryCubit, InventoryState>(
            builder: (context, state) {
              int optimalCount = 0;
              int lowCount = 0;
              int criticalCount = 0;
              int total = 0;

              final items = state is InventoryLoaded
                  ? state.items
                  : context.read<InventoryCubit>().cachedItems;

              if (items.isNotEmpty) {
                total = items.length;
                for (var item in items) {
                  if (item.quantity == 0 ||
                      item.quantity <= item.minThreshold * 0.2) {
                    criticalCount++;
                  } else if (item.quantity < item.minThreshold) {
                    lowCount++;
                  } else {
                    optimalCount++;
                  }
                }
              }

              final optimalPct =
                  total == 0 ? 0.0 : (optimalCount / total * 100);
              final lowPct = total == 0 ? 0.0 : (lowCount / total * 100);
              final criticalPct =
                  total == 0 ? 0.0 : (criticalCount / total * 100);

              return Row(
                children: [
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sections: total == 0
                                ? [
                                    PieChartSectionData(
                                        value: 100,
                                        color: Colors.grey.withOpacity(0.2),
                                        radius: 30,
                                        showTitle: false)
                                  ]
                                : [
                                    if (optimalCount > 0)
                                      PieChartSectionData(
                                          value: optimalPct,
                                          color: Colors.green,
                                          radius: 30,
                                          showTitle: false),
                                    if (lowCount > 0)
                                      PieChartSectionData(
                                          value: lowPct,
                                          color: Colors.orange,
                                          radius: 30,
                                          showTitle: false),
                                    if (criticalCount > 0)
                                      PieChartSectionData(
                                          value: criticalPct,
                                          color: theme.colorScheme.error,
                                          radius: 30,
                                          showTitle: false),
                                  ],
                            centerSpaceRadius: 50, // Donut Hole
                            sectionsSpace: 4,
                            startDegreeOffset: -90,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${optimalPct.toInt()}%',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Optimal',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color
                                    ?.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem(context, 'In Stock', Colors.green,
                          '${optimalPct.toInt()}%'),
                      const SizedBox(height: 12),
                      _buildLegendItem(context, 'Low Stock', Colors.orange,
                          '${lowPct.toInt()}%'),
                      const SizedBox(height: 12),
                      _buildLegendItem(context, 'Critical',
                          theme.colorScheme.error, '${criticalPct.toInt()}%'),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(
    BuildContext context,
    String label,
    Color color,
    String value,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(fontSize: 13)),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
