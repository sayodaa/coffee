import 'dart:math';

import 'package:coffee_app/core/widgets/premium_card.dart';
import 'package:coffee_app/features/reports/domain/report_models.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ReportsBarChart extends StatelessWidget {
  final List<LossItem> lossData;

  const ReportsBarChart({super.key, required this.lossData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (lossData.isEmpty) {
      return const PremiumCard(
        height: 300,
        child: Center(
          child: Text('Not enough data to graph.'),
        ),
      );
    }

    // Limit to top 5 items with highest expected value to avoid crowding
    final topItems = List<LossItem>.from(lossData)
      ..sort((a, b) => b.expected.compareTo(a.expected));
    final displayItems = topItems.take(5).toList();

    double maxY = 0;
    for (var item in displayItems) {
      maxY = max(maxY, max(item.expected, item.actual));
    }
    maxY = maxY * 1.2; // Add 20% headroom

    return PremiumCard(
      height: 300,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildLegend(context, 'Expected', theme.colorScheme.secondary),
              const SizedBox(width: 16),
              _buildLegend(context, 'Actual', theme.colorScheme.primary),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: maxY <= 0 ? 10 : maxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: theme.colorScheme.surface,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final item = displayItems[group.x];
                      return BarTooltipItem(
                        '${item.itemName}\n',
                        TextStyle(
                          color: theme.textTheme.bodyLarge?.color,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          TextSpan(
                            text:
                                '${rodIndex == 0 ? 'Expected' : 'Actual'}: ${rod.toY.toStringAsFixed(1)}',
                            style: TextStyle(
                              color: rod.color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= displayItems.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _truncateText(displayItems[value.toInt()].itemName),
                            style: theme.textTheme.bodySmall
                                ?.copyWith(fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                      reservedSize: 32,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: (maxY / 4) <= 0 ? 5 : (maxY / 4),
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style:
                              theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: theme.dividerColor.withOpacity(0.5),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
                barGroups: displayItems.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barsSpace: 4,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.expected,
                        color: theme.colorScheme.secondary,
                        width: 12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: entry.value.actual,
                        color: theme.colorScheme.primary,
                        width: 12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(BuildContext context, String title, Color color) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(title, style: theme.textTheme.bodySmall),
      ],
    );
  }

  String _truncateText(String text) {
    if (text.length <= 8) return text;
    return '${text.substring(0, 7)}.';
  }
}
