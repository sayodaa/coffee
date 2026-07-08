import 'package:coffee_app/new_data/sales_record.dart';

import 'business_report.dart';

/// Turns raw [SalesRecord] rows into a compact [BusinessReport].
///
/// Pure Dart, no Flutter/UI imports — this is domain logic and must stay
/// independently testable.
///
/// Performance notes (dataset can be 100,000+ rows):
///  * The raw rows are walked exactly **once** to build every grouping map
///    (`sale_item_id`, `material_id`). No nested loops over the raw list.
///  * Everything after that operates on the much smaller aggregated sets
///    (distinct products/materials/categories/months), where sorting is
///    cheap even with a naive O(n log n) sort.
class SalesAnalyticsService {
  const SalesAnalyticsService();

  /// Analyzes the full dataset and returns a ready-to-render [BusinessReport].
  BusinessReport analyze(List<SalesRecord> records) {
    if (records.isEmpty) return BusinessReport.empty();

    // ── Pass 1: single walk over every raw row ────────────────────────────
    final Map<int, _SaleItemAgg> itemsById = {};
    final Map<int, _MaterialAgg> materialsById = {};
    final Set<int> saleIds = {};

    for (final r in records) {
      saleIds.add(r.saleId);

      final item = itemsById.putIfAbsent(
        r.saleItemId,
        () => _SaleItemAgg(
          productName: r.productName,
          categoryName: r.productCategoryName,
          quantitySold: r.quantitySold,
          subtotal: r.saleItemSubtotal,
          saleDate: r.saleDate,
          hour: r.hour,
          isWeekend: r.isWeekend,
        ),
      );
      item.ingredientCost += r.ingredientCost;

      final material = materialsById.putIfAbsent(
        r.materialId,
        () => _MaterialAgg(
          name: r.materialName,
          categoryName: r.materialCategoryName,
          unit: r.materialUnit,
        ),
      );
      material.quantityConsumed += r.quantityConsumed;
      material.totalCost += r.ingredientCost;
    }

    final items = itemsById.values.toList(growable: false);

    // ── Core KPIs (one pass over the much smaller de-duplicated item list) ─
    double totalRevenue = 0;
    double totalCost = 0;
    int productsSold = 0;
    for (final it in items) {
      totalRevenue += it.subtotal;
      totalCost += it.ingredientCost;
      productsSold += it.quantitySold;
    }
    final totalOrders = saleIds.length;
    final totalProfit = totalRevenue - totalCost;
    final profitMargin =
        totalRevenue == 0 ? 0.0 : (totalProfit / totalRevenue) * 100;
    final averageOrderValue =
        totalOrders == 0 ? 0.0 : totalRevenue / totalOrders;
    final averageProductCost = items.isEmpty ? 0.0 : totalCost / items.length;

    // ── Per-product aggregation ─────────────────────────────────────────
    final Map<String, _ProductAgg> byProduct = {};
    for (final it in items) {
      final p = byProduct.putIfAbsent(
        it.productName,
        () => _ProductAgg(categoryName: it.categoryName),
      );
      p.quantitySold += it.quantitySold;
      p.revenue += it.subtotal;
      p.cost += it.ingredientCost;
    }

    final productStats = byProduct.entries
        .map((e) => ProductStat(
              productName: e.key,
              categoryName: e.value.categoryName,
              quantitySold: e.value.quantitySold,
              revenue: e.value.revenue,
              cost: e.value.cost,
              profit: e.value.revenue - e.value.cost,
            ))
        .toList();

    final byQtyDesc = [...productStats]
      ..sort((a, b) => b.quantitySold.compareTo(a.quantitySold));
    final byQtyAsc = [...productStats]
      ..sort((a, b) => a.quantitySold.compareTo(b.quantitySold));
    final byProfitDesc = [...productStats]
      ..sort((a, b) => b.profit.compareTo(a.profit));
    final byProfitAsc = [...productStats]
      ..sort((a, b) => a.profit.compareTo(b.profit));

    // ── Category aggregation ────────────────────────────────────────────
    final Map<String, _CategoryAgg> byCategory = {};
    for (final it in items) {
      final c = byCategory.putIfAbsent(it.categoryName, () => _CategoryAgg());
      c.revenue += it.subtotal;
      c.cost += it.ingredientCost;
      c.orders += 1;
    }
    final categoryStats = byCategory.entries
        .map((e) => CategoryStat(
              categoryName: e.key,
              revenue: e.value.revenue,
              orders: e.value.orders,
              profit: e.value.revenue - e.value.cost,
            ))
        .toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));

    // ── Material aggregation ────────────────────────────────────────────
    final materialStats = materialsById.values
        .map((m) => MaterialStat(
              materialName: m.name,
              categoryName: m.categoryName,
              unit: m.unit,
              quantityConsumed: m.quantityConsumed,
              totalCost: m.totalCost,
            ))
        .toList();
    final byConsumptionDesc = [...materialStats]
      ..sort((a, b) => b.quantityConsumed.compareTo(a.quantityConsumed));
    final byCostDesc = [...materialStats]
      ..sort((a, b) => b.totalCost.compareTo(a.totalCost));

    // ── Revenue by month / day ───────────────────────────────────────────
    final Map<String, double> revenueByMonth = {};
    final Map<String, double> revenueByDay = {};
    for (final it in items) {
      final monthKey =
          '${it.saleDate.year}-${it.saleDate.month.toString().padLeft(2, '0')}';
      final dayKey =
          '${it.saleDate.year}-${it.saleDate.month.toString().padLeft(2, '0')}-${it.saleDate.day.toString().padLeft(2, '0')}';
      revenueByMonth.update(monthKey, (v) => v + it.subtotal,
          ifAbsent: () => it.subtotal);
      revenueByDay.update(dayKey, (v) => v + it.subtotal,
          ifAbsent: () => it.subtotal);
    }
    final sortedMonthMap = _sortedByKey(revenueByMonth);
    final sortedDayMap = _sortedByKey(revenueByDay);

    // ── Peak hours ───────────────────────────────────────────────────────
    final Map<String, _PeakBucket> hourBuckets = {
      'Morning (6–12)': _PeakBucket(),
      'Afternoon (12–17)': _PeakBucket(),
      'Evening (17–21)': _PeakBucket(),
      'Night (21–6)': _PeakBucket(),
    };
    for (final it in items) {
      hourBuckets[_hourLabel(it.hour)]!
        ..orders += 1
        ..revenue += it.subtotal;
    }
    final peakHours = hourBuckets.entries
        .map((e) => PeakHourBucket(
              label: e.key,
              orders: e.value.orders,
              revenue: e.value.revenue,
            ))
        .toList();

    // ── Weekend vs weekday (used by insights) ───────────────────────────
    double weekendRevenue = 0, weekdayRevenue = 0;
    int weekendOrders = 0, weekdayOrders = 0;
    for (final it in items) {
      if (it.isWeekend) {
        weekendRevenue += it.subtotal;
        weekendOrders += 1;
      } else {
        weekdayRevenue += it.subtotal;
        weekdayOrders += 1;
      }
    }
    final weekendAvg =
        weekendOrders == 0 ? 0.0 : weekendRevenue / weekendOrders;
    final weekdayAvg =
        weekdayOrders == 0 ? 0.0 : weekdayRevenue / weekdayOrders;

    final bestSelling = byQtyDesc.isNotEmpty ? byQtyDesc.first : null;
    final leastSelling = byQtyAsc.isNotEmpty ? byQtyAsc.first : null;
    final mostProfitable = byProfitDesc.isNotEmpty ? byProfitDesc.first : null;
    final leastProfitable = byProfitAsc.isNotEmpty ? byProfitAsc.first : null;
    final mostUsedMaterial =
        byConsumptionDesc.isNotEmpty ? byConsumptionDesc.first : null;
    final highestCostMaterial = byCostDesc.isNotEmpty ? byCostDesc.first : null;

    final alerts = _generateAlerts(
      productStats: productStats,
      materialStats: materialStats,
      totalCost: totalCost,
      revenueByMonth: sortedMonthMap,
      overallMargin: profitMargin,
    );

    final insights = _generateInsights(
      categoryStats: categoryStats,
      revenueByMonth: sortedMonthMap,
      totalRevenue: totalRevenue,
      weekendAvg: weekendAvg,
      weekdayAvg: weekdayAvg,
      mostUsedMaterial: mostUsedMaterial,
    );

    final recommendations = _generateRecommendations(
      bestSelling: bestSelling,
      leastSelling: leastSellingList(byQtyAsc),
      leastProfitable: byProfitAsc,
      highestCostMaterial: highestCostMaterial,
    );

    return BusinessReport(
      totalRevenue: totalRevenue,
      totalOrders: totalOrders,
      productsSold: productsSold,
      averageOrderValue: averageOrderValue,
      totalProfit: totalProfit,
      profitMargin: profitMargin,
      averageProductCost: averageProductCost,
      bestSellingProduct: bestSelling,
      leastSellingProduct: leastSelling,
      mostProfitableProduct: mostProfitable,
      leastProfitableProduct: leastProfitable,
      mostUsedMaterial: mostUsedMaterial,
      highestCostMaterial: highestCostMaterial,
      topSellingProducts: byQtyDesc.take(10).toList(),
      leastSellingProducts: byQtyAsc.take(10).toList(),
      mostProfitableProducts: byProfitDesc.take(10).toList(),
      leastProfitableProducts: byProfitAsc.take(10).toList(),
      categoryStats: categoryStats,
      topConsumedMaterials: byConsumptionDesc.take(10).toList(),
      highestCostMaterials: byCostDesc.take(10).toList(),
      revenueByMonth: sortedMonthMap,
      revenueByDay: sortedDayMap,
      peakHours: peakHours,
      alerts: alerts,
      insights: insights,
      recommendations: recommendations,
    );
  }

  List<ProductStat> leastSellingList(List<ProductStat> byQtyAsc) =>
      byQtyAsc.take(10).toList();

  static Map<String, double> _sortedByKey(Map<String, double> map) {
    final keys = map.keys.toList()..sort();
    return {for (final k in keys) k: map[k]!};
  }

  static String _hourLabel(int hour) {
    if (hour >= 6 && hour < 12) return 'Morning (6–12)';
    if (hour >= 12 && hour < 17) return 'Afternoon (12–17)';
    if (hour >= 17 && hour < 21) return 'Evening (17–21)';
    return 'Night (21–6)';
  }

  // ── Smart alerts ─────────────────────────────────────────────────────────

  List<SmartAlert> _generateAlerts({
    required List<ProductStat> productStats,
    required List<MaterialStat> materialStats,
    required double totalCost,
    required Map<String, double> revenueByMonth,
    required double overallMargin,
  }) {
    final alerts = <SmartAlert>[];
    if (productStats.isEmpty) return alerts;

    // Low profit / negative margin products.
    for (final p in productStats) {
      if (p.revenue <= 0) continue;
      if (p.profitMargin < 0) {
        alerts.add(SmartAlert(
          title: 'Product losing money',
          message:
              '${p.productName} costs more in ingredients than it earns (margin ${p.profitMargin.toStringAsFixed(1)}%).',
          severity: AlertSeverity.critical,
          category: 'profit',
        ));
      } else if (p.profitMargin < 15) {
        alerts.add(SmartAlert(
          title: 'Low profit margin',
          message:
              '${p.productName} has a thin margin of ${p.profitMargin.toStringAsFixed(1)}% — consider a price review.',
          severity: AlertSeverity.warning,
          category: 'profit',
        ));
      }
    }

    // High-cost materials — flag anything consuming an outsized share of
    // total ingredient spend.
    if (totalCost > 0) {
      for (final m in materialStats) {
        final share = (m.totalCost / totalCost) * 100;
        if (share >= 12) {
          alerts.add(SmartAlert(
            title: 'High cost material',
            message:
                '${m.materialName} accounts for ${share.toStringAsFixed(1)}% of total ingredient cost.',
            severity:
                share >= 20 ? AlertSeverity.critical : AlertSeverity.warning,
            category: 'material',
          ));
        }
      }
    }

    // Demand outliers.
    if (productStats.length >= 2) {
      final avgQty =
          productStats.map((p) => p.quantitySold).reduce((a, b) => a + b) /
              productStats.length;
      final sortedByQty = [...productStats]
        ..sort((a, b) => b.quantitySold.compareTo(a.quantitySold));
      final top = sortedByQty.first;
      final bottom = sortedByQty.last;
      if (top.quantitySold > avgQty * 2) {
        alerts.add(SmartAlert(
          title: 'High demand product',
          message:
              '${top.productName} is selling far above average (${top.quantitySold} units) — watch for stockouts.',
          severity: AlertSeverity.info,
          category: 'demand',
        ));
      }
      if (bottom.quantitySold < avgQty * 0.25) {
        alerts.add(SmartAlert(
          title: 'Low demand product',
          message:
              '${bottom.productName} is selling well below average (${bottom.quantitySold} units) — consider a promotion.',
          severity: AlertSeverity.warning,
          category: 'demand',
        ));
      }
    }

    // Revenue trend (month-over-month).
    final months = revenueByMonth.keys.toList();
    if (months.length >= 2) {
      final last = revenueByMonth[months.last]!;
      final prev = revenueByMonth[months[months.length - 2]]!;
      if (prev > 0) {
        final changePct = ((last - prev) / prev) * 100;
        if (changePct <= -10) {
          alerts.add(SmartAlert(
            title: 'Revenue drop',
            message:
                'Revenue fell ${changePct.abs().toStringAsFixed(1)}% from ${months[months.length - 2]} to ${months.last}.',
            severity: AlertSeverity.critical,
            category: 'revenue',
          ));
        }
      }
    }

    // Overall margin threshold.
    if (overallMargin < 20) {
      alerts.add(SmartAlert(
        title: 'Overall profit margin below target',
        message:
            'Store-wide profit margin is ${overallMargin.toStringAsFixed(1)}%, below the healthy 20% benchmark.',
        severity: AlertSeverity.warning,
        category: 'profit',
      ));
    }

    return alerts;
  }

  // ── AI-style insights (rule-based, computed from the data itself) ───────

  List<String> _generateInsights({
    required List<CategoryStat> categoryStats,
    required Map<String, double> revenueByMonth,
    required double totalRevenue,
    required double weekendAvg,
    required double weekdayAvg,
    required MaterialStat? mostUsedMaterial,
  }) {
    final insights = <String>[];

    if (categoryStats.isNotEmpty && totalRevenue > 0) {
      final top = categoryStats.first;
      final share = (top.revenue / totalRevenue) * 100;
      insights.add(
          '${top.categoryName} is the top category, contributing ${share.toStringAsFixed(0)}% of total revenue.');
    }

    final months = revenueByMonth.keys.toList();
    if (months.length >= 2) {
      final last = revenueByMonth[months.last]!;
      final prev = revenueByMonth[months[months.length - 2]]!;
      if (prev > 0) {
        final changePct = ((last - prev) / prev) * 100;
        if (changePct.abs() >= 2) {
          insights.add(changePct >= 0
              ? 'Revenue is growing — up ${changePct.toStringAsFixed(1)}% versus the previous month.'
              : 'Revenue declined ${changePct.abs().toStringAsFixed(1)}% versus the previous month.');
        }
      }
    }

    if (weekendAvg > 0 && weekdayAvg > 0) {
      if (weekendAvg > weekdayAvg * 1.05) {
        insights.add(
            'Weekend orders average ${(((weekendAvg / weekdayAvg) - 1) * 100).toStringAsFixed(0)}% more revenue per order than weekdays.');
      } else if (weekdayAvg > weekendAvg * 1.05) {
        insights.add(
            'Weekday orders outperform weekends by ${(((weekdayAvg / weekendAvg) - 1) * 100).toStringAsFixed(0)}% in average order value.');
      }
    }

    if (mostUsedMaterial != null) {
      insights.add(
          '${mostUsedMaterial.materialName} is the most consumed material (${mostUsedMaterial.quantityConsumed.toStringAsFixed(0)} ${mostUsedMaterial.unit}).');
    }

    return insights;
  }

  // ── Recommendations ─────────────────────────────────────────────────────

  List<String> _generateRecommendations({
    required ProductStat? bestSelling,
    required List<ProductStat> leastSelling,
    required List<ProductStat> leastProfitable,
    required MaterialStat? highestCostMaterial,
  }) {
    final recs = <String>[];

    if (bestSelling != null) {
      recs.add(
          'Keep ${bestSelling.productName} well stocked — it is your best seller by volume.');
    }
    for (final p in leastSelling.take(2)) {
      recs.add(
          'Consider a promotion or bundle for ${p.productName} to lift its low demand.');
    }
    for (final p in leastProfitable.take(2)) {
      if (p.profitMargin < 15) {
        recs.add(
            'Review pricing or portion size for ${p.productName} — its margin is only ${p.profitMargin.toStringAsFixed(1)}%.');
      }
    }
    if (highestCostMaterial != null) {
      recs.add(
          'Look into supplier pricing for ${highestCostMaterial.materialName} — it is your highest ingredient cost driver.');
    }

    return recs;
  }
}

// ── Internal aggregation helpers (not exported) ─────────────────────────────

class _SaleItemAgg {
  final String productName;
  final String categoryName;
  final int quantitySold;
  final double subtotal;
  final DateTime saleDate;
  final int hour;
  final bool isWeekend;
  double ingredientCost = 0;

  _SaleItemAgg({
    required this.productName,
    required this.categoryName,
    required this.quantitySold,
    required this.subtotal,
    required this.saleDate,
    required this.hour,
    required this.isWeekend,
  });
}

class _ProductAgg {
  final String categoryName;
  int quantitySold = 0;
  double revenue = 0;
  double cost = 0;

  _ProductAgg({required this.categoryName});
}

class _CategoryAgg {
  double revenue = 0;
  double cost = 0;
  int orders = 0;
}

class _MaterialAgg {
  final String name;
  final String categoryName;
  final String unit;
  double quantityConsumed = 0;
  double totalCost = 0;

  _MaterialAgg({
    required this.name,
    required this.categoryName,
    required this.unit,
  });
}

class _PeakBucket {
  int orders = 0;
  double revenue = 0;
}
