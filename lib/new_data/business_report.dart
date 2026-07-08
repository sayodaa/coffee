/// Aggregated statistics for a single product.
///
/// Already de-duplicated per `sale_item_id` — [quantitySold], [revenue] and
/// [cost] each reflect real sold-item totals, never inflated by repeated
/// ingredient rows.
class ProductStat {
  final String productName;
  final String categoryName;
  final int quantitySold;
  final double revenue;
  final double cost;
  final double profit;

  const ProductStat({
    required this.productName,
    required this.categoryName,
    required this.quantitySold,
    required this.revenue,
    required this.cost,
    required this.profit,
  });

  double get profitMargin => revenue == 0 ? 0 : (profit / revenue) * 100;

  Map<String, dynamic> toCompactJson() => {
        'product': productName,
        'category': categoryName,
        'qty_sold': quantitySold,
        'revenue': revenue.roundTo2(),
        'profit': profit.roundTo2(),
        'profit_margin_pct': profitMargin.roundTo2(),
      };
}

/// Aggregated statistics for a product category.
class CategoryStat {
  final String categoryName;
  final double revenue;
  final int orders;
  final double profit;

  const CategoryStat({
    required this.categoryName,
    required this.revenue,
    required this.orders,
    required this.profit,
  });

  Map<String, dynamic> toCompactJson() => {
        'category': categoryName,
        'revenue': revenue.roundTo2(),
        'orders': orders,
        'profit': profit.roundTo2(),
      };
}

/// Aggregated statistics for a raw material / ingredient.
class MaterialStat {
  final String materialName;
  final String categoryName;
  final String unit;
  final double quantityConsumed;
  final double totalCost;

  const MaterialStat({
    required this.materialName,
    required this.categoryName,
    required this.unit,
    required this.quantityConsumed,
    required this.totalCost,
  });

  Map<String, dynamic> toCompactJson() => {
        'material': materialName,
        'category': categoryName,
        'unit': unit,
        'consumed': quantityConsumed.roundTo2(),
        'cost': totalCost.roundTo2(),
      };
}

/// Revenue/order distribution across a part of the day.
class PeakHourBucket {
  final String label;
  final int orders;
  final double revenue;

  const PeakHourBucket({
    required this.label,
    required this.orders,
    required this.revenue,
  });

  Map<String, dynamic> toCompactJson() => {
        'period': label,
        'orders': orders,
        'revenue': revenue.roundTo2(),
      };
}

enum AlertSeverity { info, warning, critical }

/// A single actionable business alert (e.g. "Low profit product").
///
/// [category] is a stable machine-readable key (`profit`, `material`,
/// `demand`, `revenue`, `inventory`) so the presentation layer can map it to
/// an icon/color without the domain layer knowing anything about Flutter.
class SmartAlert {
  final String title;
  final String message;
  final AlertSeverity severity;
  final String category;

  const SmartAlert({
    required this.title,
    required this.message,
    required this.severity,
    required this.category,
  });

  Map<String, dynamic> toCompactJson() => {
        'title': title,
        'message': message,
        'severity': severity.name,
        'category': category,
      };
}

/// Compact, fully-aggregated business intelligence snapshot.
///
/// This is the single object the entire dashboard renders from, and the
/// **only** thing ever sent to the AI assistant — raw sales rows are never
/// forwarded to any AI call.
class BusinessReport {
  // Core KPIs
  final double totalRevenue;
  final int totalOrders;
  final int productsSold;
  final double averageOrderValue;
  final double totalProfit;
  final double profitMargin;
  final double averageProductCost;

  // Headline single-entity KPIs
  final ProductStat? bestSellingProduct;
  final ProductStat? leastSellingProduct;
  final ProductStat? mostProfitableProduct;
  final ProductStat? leastProfitableProduct;
  final MaterialStat? mostUsedMaterial;
  final MaterialStat? highestCostMaterial;

  // Ranked lists
  final List<ProductStat> topSellingProducts;
  final List<ProductStat> leastSellingProducts;
  final List<ProductStat> mostProfitableProducts;
  final List<ProductStat> leastProfitableProducts;
  final List<CategoryStat> categoryStats;
  final List<MaterialStat> topConsumedMaterials;
  final List<MaterialStat> highestCostMaterials;

  // Time series (keys pre-sorted chronologically)
  final Map<String, double> revenueByMonth;
  final Map<String, double> revenueByDay;
  final List<PeakHourBucket> peakHours;

  // Generated intelligence
  final List<SmartAlert> alerts;
  final List<String> insights;
  final List<String> recommendations;

  const BusinessReport({
    required this.totalRevenue,
    required this.totalOrders,
    required this.productsSold,
    required this.averageOrderValue,
    required this.totalProfit,
    required this.profitMargin,
    required this.averageProductCost,
    required this.bestSellingProduct,
    required this.leastSellingProduct,
    required this.mostProfitableProduct,
    required this.leastProfitableProduct,
    required this.mostUsedMaterial,
    required this.highestCostMaterial,
    required this.topSellingProducts,
    required this.leastSellingProducts,
    required this.mostProfitableProducts,
    required this.leastProfitableProducts,
    required this.categoryStats,
    required this.topConsumedMaterials,
    required this.highestCostMaterials,
    required this.revenueByMonth,
    required this.revenueByDay,
    required this.peakHours,
    required this.alerts,
    required this.insights,
    required this.recommendations,
  });

  factory BusinessReport.empty() => const BusinessReport(
        totalRevenue: 0,
        totalOrders: 0,
        productsSold: 0,
        averageOrderValue: 0,
        totalProfit: 0,
        profitMargin: 0,
        averageProductCost: 0,
        bestSellingProduct: null,
        leastSellingProduct: null,
        mostProfitableProduct: null,
        leastProfitableProduct: null,
        mostUsedMaterial: null,
        highestCostMaterial: null,
        topSellingProducts: [],
        leastSellingProducts: [],
        mostProfitableProducts: [],
        leastProfitableProducts: [],
        categoryStats: [],
        topConsumedMaterials: [],
        highestCostMaterials: [],
        revenueByMonth: {},
        revenueByDay: {},
        peakHours: [],
        alerts: [],
        insights: [],
        recommendations: [],
      );

  /// Compact JSON summary — this, and only this, is what gets sent to the AI
  /// assistant. Thousands of raw rows are never forwarded; the whole point
  /// of this object is that it stays small regardless of dataset size.
  Map<String, dynamic> toCompactJson() => {
        'kpis': {
          'total_revenue': totalRevenue.roundTo2(),
          'total_orders': totalOrders,
          'products_sold': productsSold,
          'average_order_value': averageOrderValue.roundTo2(),
          'total_profit': totalProfit.roundTo2(),
          'profit_margin_pct': profitMargin.roundTo2(),
          'average_product_cost': averageProductCost.roundTo2(),
        },
        'best_selling_product': bestSellingProduct?.toCompactJson(),
        'least_selling_product': leastSellingProduct?.toCompactJson(),
        'most_profitable_product': mostProfitableProduct?.toCompactJson(),
        'least_profitable_product': leastProfitableProduct?.toCompactJson(),
        'most_used_material': mostUsedMaterial?.toCompactJson(),
        'highest_cost_material': highestCostMaterial?.toCompactJson(),
        'top_selling_products':
            topSellingProducts.map((e) => e.toCompactJson()).toList(),
        'least_selling_products':
            leastSellingProducts.map((e) => e.toCompactJson()).toList(),
        'most_profitable_products':
            mostProfitableProducts.map((e) => e.toCompactJson()).toList(),
        'least_profitable_products':
            leastProfitableProducts.map((e) => e.toCompactJson()).toList(),
        'category_breakdown':
            categoryStats.map((e) => e.toCompactJson()).toList(),
        'top_consumed_materials':
            topConsumedMaterials.map((e) => e.toCompactJson()).toList(),
        'highest_cost_materials':
            highestCostMaterials.map((e) => e.toCompactJson()).toList(),
        'revenue_by_month': revenueByMonth,
        'peak_hours': peakHours.map((e) => e.toCompactJson()).toList(),
        'alerts': alerts.map((e) => e.toCompactJson()).toList(),
        'insights': insights,
        'recommendations': recommendations,
      };
}

extension RoundTo2 on double {
  double roundTo2() => (this * 100).round() / 100;
}
