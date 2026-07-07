import 'package:coffee_app/features/reports/domain/report_models.dart';
import 'package:flutter/material.dart';

class LossBreakdownList extends StatelessWidget {
  final List<LossItem> lossData;

  const LossBreakdownList({super.key, required this.lossData});

  @override
  Widget build(BuildContext context) {
    if (lossData.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor, width: 1),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: lossData.length,
        separatorBuilder: (context, index) =>
            Divider(color: theme.dividerColor),
        itemBuilder: (context, index) {
          final item = lossData[index];
          final isAbnormal = item.isAbnormal;

          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              item.itemName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
                'Expected: ${item.expected.toStringAsFixed(1)} | Actual: ${item.actual.toStringAsFixed(1)}'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isAbnormal
                    ? theme.colorScheme.error.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isAbnormal
                    ? Border.all(
                        color: theme.colorScheme.error.withOpacity(0.5))
                    : null,
              ),
              child: Text(
                '${item.difference > 0 ? '+' : ''}${item.difference.toStringAsFixed(1)} loss',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isAbnormal
                      ? theme.colorScheme.error
                      : (item.difference > 0 ? Colors.orange : Colors.green),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
