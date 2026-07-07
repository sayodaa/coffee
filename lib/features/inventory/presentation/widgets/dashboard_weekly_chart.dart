import 'package:coffee_app/core/widgets/premium_card.dart';
import 'package:coffee_app/features/sales/presentation/bloc/sales_cubit.dart';
import 'package:coffee_app/features/sales/presentation/bloc/sales_state.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardWeeklyChart extends StatelessWidget {
  const DashboardWeeklyChart({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'Weekly Consumption',
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
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: BlocBuilder<SalesCubit, SalesState>(
            builder: (context, state) {
              final Map<int, double> weeklySales = {
                0: 0,
                1: 0,
                2: 0,
                3: 0,
                4: 0,
                5: 0,
                6: 0
              };
              double maxVal = 20;

              if (state is SalesLoaded) {
                final now = DateTime.now();
                for (var sale in state.sales) {
                  final diff = now.difference(sale.timestamp).inDays;
                  if (diff >= 0 && diff < 7) {
                    final dayIndex =
                        (6 - diff) % 7; // Reverse order (today is 6)
                    weeklySales[dayIndex] =
                        (weeklySales[dayIndex] ?? 0) + sale.totalAmount.amount;
                    if (weeklySales[dayIndex]! > maxVal) {
                      maxVal = weeklySales[dayIndex]!;
                    }
                  }
                }
              }

              return BarChart(
                BarChartData(
                  barGroups: List.generate(
                      7,
                      (i) => _buildBarGroup(
                          i, weeklySales[i] ?? 0.0, maxVal, theme)),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (maxVal / 4) <= 0 ? 5 : (maxVal / 4),
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: theme.dividerColor.withOpacity(0.5),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final String dayAbbr = _getDayAbbr(value.toInt());
                          return Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              dayAbbr,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(fontSize: 12),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  BarChartGroupData _buildBarGroup(
      int x, double y, double maxY, ThemeData theme) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: LinearGradient(
            colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          width: 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: maxY, // Max height background dynamically matches real max
            color: theme.dividerColor.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  String _getDayAbbr(int index) {
    final now = DateTime.now();
    final date = now.subtract(Duration(days: 6 - index));
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return days[date.weekday - 1];
  }
}
