import 'package:coffee_app/new_data/business_report.dart';
import 'package:flutter/material.dart';

import 'bi_kpi_card.dart';
import 'bi_theme.dart';

/// Responsive grid of KPI cards summarizing the whole [report].
///
/// Column count adapts to width: 2 on phones, 3 on tablets, 4 on wide/
/// desktop layouts.
class BiKpiGrid extends StatelessWidget {
  final BusinessReport report;

  const BiKpiGrid({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1000 ? 4 : (width >= 700 ? 3 : 2);

    final cards = <Widget>[
      BiKpiCard(
        icon: Icons.payments_rounded,
        label: 'Total Revenue',
        value: report.totalRevenue.toMoney(),
        accentColor: BiColors.caramel,
      ),
      BiKpiCard(
        icon: Icons.receipt_long_rounded,
        label: 'Total Orders',
        value: report.totalOrders.toCompactNumber(),
        accentColor: BiColors.info,
        animationDelay: const Duration(milliseconds: 40),
      ),
      BiKpiCard(
        icon: Icons.local_cafe_rounded,
        label: 'Products Sold',
        value: report.productsSold.toCompactNumber(),
        accentColor: BiColors.caramelLight,
        animationDelay: const Duration(milliseconds: 80),
      ),
      BiKpiCard(
        icon: Icons.shopping_bag_rounded,
        label: 'Average Order Value',
        value: report.averageOrderValue.toMoney(),
        accentColor: BiColors.info,
        animationDelay: const Duration(milliseconds: 120),
      ),
      BiKpiCard(
        icon: Icons.trending_up_rounded,
        label: 'Total Profit',
        value: report.totalProfit.toMoney(),
        accentColor: BiColors.success,
        animationDelay: const Duration(milliseconds: 160),
      ),
      BiKpiCard(
        icon: Icons.percent_rounded,
        label: 'Profit Margin',
        value: '${report.profitMargin.toStringAsFixed(1)}%',
        accentColor:
            report.profitMargin >= 20 ? BiColors.success : BiColors.warning,
        animationDelay: const Duration(milliseconds: 200),
      ),
      BiKpiCard(
        icon: Icons.star_rounded,
        label: 'Best Selling Product',
        value: report.bestSellingProduct?.productName ?? '—',
        subtitle: report.bestSellingProduct != null
            ? '${report.bestSellingProduct!.quantitySold} sold'
            : null,
        accentColor: BiColors.success,
        animationDelay: const Duration(milliseconds: 240),
      ),
      BiKpiCard(
        icon: Icons.trending_down_rounded,
        label: 'Least Selling Product',
        value: report.leastSellingProduct?.productName ?? '—',
        subtitle: report.leastSellingProduct != null
            ? '${report.leastSellingProduct!.quantitySold} sold'
            : null,
        accentColor: BiColors.warning,
        animationDelay: const Duration(milliseconds: 280),
      ),
      BiKpiCard(
        icon: Icons.inventory_2_rounded,
        label: 'Most Used Material',
        value: report.mostUsedMaterial?.materialName ?? '—',
        subtitle: report.mostUsedMaterial != null
            ? '${report.mostUsedMaterial!.quantityConsumed.toStringAsFixed(0)} ${report.mostUsedMaterial!.unit}'
            : null,
        accentColor: BiColors.caramel,
        animationDelay: const Duration(milliseconds: 320),
      ),
      BiKpiCard(
        icon: Icons.emoji_events_rounded,
        label: 'Most Profitable Product',
        value: report.mostProfitableProduct?.productName ?? '—',
        subtitle: report.mostProfitableProduct != null
            ? report.mostProfitableProduct!.profit.toMoney()
            : null,
        accentColor: BiColors.success,
        animationDelay: const Duration(milliseconds: 360),
      ),
      BiKpiCard(
        icon: Icons.warning_amber_rounded,
        label: 'Highest Cost Material',
        value: report.highestCostMaterial?.materialName ?? '—',
        subtitle: report.highestCostMaterial != null
            ? report.highestCostMaterial!.totalCost.toMoney()
            : null,
        accentColor: BiColors.critical,
        animationDelay: const Duration(milliseconds: 400),
      ),
      BiKpiCard(
        icon: Icons.calculate_rounded,
        label: 'Average Product Cost',
        value: report.averageProductCost.toMoney(),
        accentColor: BiColors.caramelLight,
        animationDelay: const Duration(milliseconds: 440),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (context, index) => cards[index],
    );
  }
}
