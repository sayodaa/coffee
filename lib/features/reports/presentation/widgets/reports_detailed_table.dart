import 'package:coffee_app/features/reports/domain/report_models.dart';
import 'package:flutter/material.dart';

class ReportsDetailedTable extends StatelessWidget {
  final List<LossItem> lossData;

  const ReportsDetailedTable({super.key, required this.lossData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (lossData.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(Icons.check_circle_outline,
                  size: 64, color: Colors.green.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text('Perfect Accuracy!', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Expected and actual consumption match perfectly for the selected period.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: theme.dividerColor) : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: DataTable(
            headingTextStyle: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
            columnSpacing: 32,
            horizontalMargin: 24,
            columns: const [
              DataColumn(label: Text('Item Name')),
              DataColumn(label: Text('Expected', textAlign: TextAlign.right)),
              DataColumn(label: Text('Actual', textAlign: TextAlign.right)),
              DataColumn(label: Text('Variance', textAlign: TextAlign.right)),
              DataColumn(label: Text('Status')),
            ],
            rows: lossData.map((item) {
              final isLoss = item.difference > 0;
              final color = isLoss ? theme.colorScheme.error : Colors.green;
              final icon =
                  isLoss ? Icons.arrow_upward : Icons.check_circle_outline;
              final label = isLoss ? 'Loss' : 'Normal';

              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      item.itemName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  DataCell(Text(item.expected.toStringAsFixed(1))),
                  DataCell(Text(item.actual.toStringAsFixed(1))),
                  DataCell(
                    Text(
                      '${item.difference > 0 ? '+' : ''}${item.difference.toStringAsFixed(1)}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 14, color: color),
                          const SizedBox(width: 4),
                          Text(
                            label,
                            style: TextStyle(color: color, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
