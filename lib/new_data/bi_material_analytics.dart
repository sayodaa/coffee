import 'package:coffee_app/new_data/business_report.dart';
import 'package:flutter/material.dart';

import 'bi_theme.dart';

/// Two side-by-side (or stacked, on narrow screens) rankings: materials by
/// consumption volume and materials by total ingredient cost.
class BiMaterialAnalytics extends StatelessWidget {
  final List<MaterialStat> topConsumed;
  final List<MaterialStat> highestCost;

  const BiMaterialAnalytics({
    super.key,
    required this.topConsumed,
    required this.highestCost,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 700;

    final consumption = _MaterialColumn(
      title: 'Top Consumed Materials',
      icon: Icons.scale_rounded,
      accentColor: BiColors.info,
      materials: topConsumed,
      valueBuilder: (m) => '${m.quantityConsumed.toStringAsFixed(0)} ${m.unit}',
      valueOf: (m) => m.quantityConsumed,
    );

    final cost = _MaterialColumn(
      title: 'Highest Cost Materials',
      icon: Icons.attach_money_rounded,
      accentColor: BiColors.critical,
      materials: highestCost,
      valueBuilder: (m) => m.totalCost.toMoney(),
      valueOf: (m) => m.totalCost,
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: consumption),
          const SizedBox(width: 16),
          Expanded(child: cost),
        ],
      );
    }

    return Column(
      children: [
        consumption,
        const SizedBox(height: 16),
        cost,
      ],
    );
  }
}

class _MaterialColumn extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final List<MaterialStat> materials;
  final String Function(MaterialStat) valueBuilder;
  final double Function(MaterialStat) valueOf;

  const _MaterialColumn({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.materials,
    required this.valueBuilder,
    required this.valueOf,
  });

  @override
  Widget build(BuildContext context) {
    if (materials.isEmpty) {
      return BiGlassCard(
        child: SizedBox(
          height: 80,
          child: Center(
            child: Text('No material data yet',
                style: const TextStyle(color: BiColors.white)),
          ),
        ),
      );
    }
    final maxValue = materials.map(valueOf).reduce((a, b) => a > b ? a : b);

    return BiGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: BiColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final m in materials.take(6))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          m.materialName,
                          style: const TextStyle(
                            color: BiColors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        valueBuilder(m),
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: maxValue == 0
                          ? 0
                          : (valueOf(m) / maxValue).clamp(0.0, 1.0),
                      minHeight: 5,
                      backgroundColor: Colors.white.withOpacity(0.08),
                      valueColor: AlwaysStoppedAnimation(accentColor),
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
