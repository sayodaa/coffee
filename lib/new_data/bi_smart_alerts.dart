import 'package:flutter/material.dart';

import 'business_report.dart';
import 'bi_theme.dart';

/// Renders the generated [SmartAlert]s as a vertical stack of alert cards.
class BiSmartAlerts extends StatelessWidget {
  final List<SmartAlert> alerts;

  const BiSmartAlerts({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return BiGlassCard(
        child: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: BiColors.success, size: 20),
            SizedBox(width: 10),
            Text(
              'No active alerts — everything looks healthy.',
              style: TextStyle(color: BiColors.white, fontSize: 13.5),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (final alert in alerts)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _AlertCard(alert: alert),
          ),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  final SmartAlert alert;

  const _AlertCard({required this.alert});

  IconData get _icon {
    switch (alert.category) {
      case 'profit':
        return Icons.trending_down_rounded;
      case 'material':
        return Icons.inventory_2_rounded;
      case 'demand':
        return Icons.shopping_cart_rounded;
      case 'revenue':
        return Icons.show_chart_rounded;
      case 'inventory':
        return Icons.warehouse_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = BiColors.severityColor(alert.severity.name);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: const TextStyle(
                    color: BiColors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  alert.message,
                  style: TextStyle(
                    color: BiColors.white.withOpacity(0.75),
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
