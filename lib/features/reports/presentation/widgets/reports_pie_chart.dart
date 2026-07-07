import 'package:coffee_app/core/widgets/premium_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ReportsPieChart extends StatelessWidget {
  const ReportsPieChart({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Hardcoded categories mapping for display on reports page
    final List<Map<String, dynamic>> categories = [
      {'name': 'Beans', 'value': 40.0, 'color': Colors.brown.shade400},
      {'name': 'Dairy', 'value': 30.0, 'color': Colors.grey.shade300},
      {'name': 'Syrups', 'value': 15.0, 'color': Colors.amber.shade400},
      {'name': 'Cups/Lids', 'value': 15.0, 'color': Colors.teal.shade300},
    ];

    return PremiumCard(
      height: 250,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: categories.map((cat) {
                  return PieChartSectionData(
                    color: cat['color'],
                    value: cat['value'],
                    title: '${cat['value'].toInt()}%',
                    radius: 35,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: categories.map((cat) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: cat['color'],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        cat['name'],
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
