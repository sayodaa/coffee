import 'package:flutter/material.dart';

import 'business_report.dart';
import 'bi_theme.dart';

enum ProductRankingMetric { quantity, revenue, profit }

/// Reusable ranked list of [ProductStat]s — used for Top Selling, Least
/// Selling, Highest Profit, and Lowest Profit product sections so the
/// dashboard doesn't need four near-identical bespoke widgets.
class BiProductRankingList extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<ProductStat> products;
  final ProductRankingMetric metric;
  final Color accentColor;

  const BiProductRankingList({
    super.key,
    required this.title,
    required this.icon,
    required this.products,
    required this.metric,
    this.accentColor = BiColors.caramel,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return BiGlassCard(
        child: SizedBox(
          height: 80,
          child: Center(
            child: Text('No data for "$title" yet',
                style: const TextStyle(color: BiColors.white)),
          ),
        ),
      );
    }

    final maxValue = _valueFor(products.first).abs();

    return BiGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: BiColors.white,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < products.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RankingRow(
                rank: i + 1,
                product: products[i],
                value: _valueFor(products[i]),
                maxValue: maxValue == 0 ? 1 : maxValue,
                accentColor: accentColor,
                metric: metric,
              ),
            ),
        ],
      ),
    );
  }

  double _valueFor(ProductStat p) {
    switch (metric) {
      case ProductRankingMetric.quantity:
        return p.quantitySold.toDouble();
      case ProductRankingMetric.revenue:
        return p.revenue;
      case ProductRankingMetric.profit:
        return p.profit;
    }
  }
}

class _RankingRow extends StatelessWidget {
  final int rank;
  final ProductStat product;
  final double value;
  final double maxValue;
  final Color accentColor;
  final ProductRankingMetric metric;

  const _RankingRow({
    required this.rank,
    required this.product,
    required this.value,
    required this.maxValue,
    required this.accentColor,
    required this.metric,
  });

  String get _formattedValue {
    switch (metric) {
      case ProductRankingMetric.quantity:
        return '${value.toInt()} sold';
      case ProductRankingMetric.revenue:
      case ProductRankingMetric.profit:
        return value.toMoney();
    }
  }

  @override
  Widget build(BuildContext context) {
    final barFraction = (value.abs() / maxValue).clamp(0.0, 1.0);
    final isNegative = value < 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 22,
          child: Text(
            '#$rank',
            style: TextStyle(
              color: BiColors.white.withOpacity(0.5),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product.productName,
                      style: const TextStyle(
                        color: BiColors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _formattedValue,
                    style: TextStyle(
                      color: isNegative ? BiColors.critical : accentColor,
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
                  value: barFraction,
                  minHeight: 5,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  valueColor: AlwaysStoppedAnimation(
                    isNegative ? BiColors.critical : accentColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
