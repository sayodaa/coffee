import 'dart:convert';

/// Strongly-typed representation of a single row from `assets/data/sales.json`.
///
/// IMPORTANT — read before touching any aggregation code:
/// One JSON row represents **one ingredient/material consumed by one sold
/// item**. A product with 3 ingredients therefore produces 3 rows that all
/// share the same [saleItemId], [quantitySold] and [saleItemSubtotal].
///
/// Rules enforced everywhere this model is consumed:
///  * [quantitySold] / [saleItemSubtotal] must be counted **once per
///    [saleItemId]** — never summed across ingredient rows.
///  * [ingredientCost] must be **summed across every row** that shares a
///    [saleItemId] (to get the true cost of one sold item) or a
///    [materialId] (to get total material consumption/cost).
///  * [saleId] identifies the parent order/transaction — one order can
///    contain multiple sale items (products).
class SalesRecord {
  final int saleId;
  final DateTime saleDate;
  final String saleTime; // "HH:mm:ss"
  final double saleTotalAmount;
  final int saleItemId;
  final int productId;
  final String productName;
  final String productCategoryName;
  final double productSellingPrice;
  final int quantitySold;
  final double saleUnitPrice;
  final double saleItemSubtotal;
  final int materialId;
  final String materialName;
  final String materialCategoryName;
  final double quantityRequired;
  final String materialUnit;
  final double quantityConsumed;
  final double materialUnitCost;
  final double ingredientCost;

  const SalesRecord({
    required this.saleId,
    required this.saleDate,
    required this.saleTime,
    required this.saleTotalAmount,
    required this.saleItemId,
    required this.productId,
    required this.productName,
    required this.productCategoryName,
    required this.productSellingPrice,
    required this.quantitySold,
    required this.saleUnitPrice,
    required this.saleItemSubtotal,
    required this.materialId,
    required this.materialName,
    required this.materialCategoryName,
    required this.quantityRequired,
    required this.materialUnit,
    required this.quantityConsumed,
    required this.materialUnitCost,
    required this.ingredientCost,
  });

  /// Hour of day (0-23), parsed from [saleTime] ("HH:mm:ss").
  int get hour {
    final colonIndex = saleTime.indexOf(':');
    if (colonIndex <= 0) return 0;
    return int.tryParse(saleTime.substring(0, colonIndex)) ?? 0;
  }

  /// ISO weekday, 1 = Monday .. 7 = Sunday.
  int get weekday => saleDate.weekday;

  bool get isWeekend => weekday == DateTime.saturday || weekday == DateTime.sunday;

  factory SalesRecord.fromJson(Map<String, dynamic> json) {
    return SalesRecord(
      saleId: _asInt(json['sale_id']),
      saleDate: _asDate(json['sale_date']),
      saleTime: json['sale_time']?.toString() ?? '00:00:00',
      saleTotalAmount: _asDouble(json['sale_total_amount']),
      saleItemId: _asInt(json['sale_item_id']),
      productId: _asInt(json['product_id']),
      productName: json['product_name']?.toString() ?? 'Unknown Product',
      productCategoryName:
          json['product_category_name']?.toString() ?? 'Uncategorized',
      productSellingPrice: _asDouble(json['product_selling_price']),
      quantitySold: _asInt(json['quantity_sold']),
      saleUnitPrice: _asDouble(json['sale_unit_price']),
      saleItemSubtotal: _asDouble(json['sale_item_subtotal']),
      materialId: _asInt(json['material_id']),
      materialName: json['material_name']?.toString() ?? 'Unknown Material',
      materialCategoryName:
          json['material_category_name']?.toString() ?? 'Uncategorized',
      quantityRequired: _asDouble(json['quantity_required']),
      materialUnit: json['material_unit']?.toString() ?? '',
      quantityConsumed: _asDouble(json['quantity_consumed']),
      materialUnitCost: _asDouble(json['material_unit_cost']),
      ingredientCost: _asDouble(json['ingredient_cost']),
    );
  }

  Map<String, dynamic> toJson() => {
        'sale_id': saleId,
        'sale_date':
            '${saleDate.year.toString().padLeft(4, '0')}-${saleDate.month.toString().padLeft(2, '0')}-${saleDate.day.toString().padLeft(2, '0')}',
        'sale_time': saleTime,
        'sale_total_amount': saleTotalAmount,
        'sale_item_id': saleItemId,
        'product_id': productId,
        'product_name': productName,
        'product_category_name': productCategoryName,
        'product_selling_price': productSellingPrice,
        'quantity_sold': quantitySold,
        'sale_unit_price': saleUnitPrice,
        'sale_item_subtotal': saleItemSubtotal,
        'material_id': materialId,
        'material_name': materialName,
        'material_category_name': materialCategoryName,
        'quantity_required': quantityRequired,
        'material_unit': materialUnit,
        'quantity_consumed': quantityConsumed,
        'material_unit_cost': materialUnitCost,
        'ingredient_cost': ingredientCost,
      };

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static double _asDouble(dynamic v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
  }

  static DateTime _asDate(dynamic v) {
    final raw = v?.toString();
    if (raw == null || raw.isEmpty) return DateTime(1970, 1, 1);
    return DateTime.tryParse(raw) ?? DateTime(1970, 1, 1);
  }
}

/// Parses the full `assets/data/sales.json` payload into [SalesRecord]s.
///
/// Runs in O(n) and is safe to call with 100,000+ rows.
List<SalesRecord> parseSalesRecords(String rawJson) {
  final decoded = jsonDecode(rawJson);
  final List<dynamic> list =
      decoded is List ? decoded : (decoded['data'] as List? ?? const []);
  final records = <SalesRecord>[];
  for (final e in list) {
    records.add(SalesRecord.fromJson(e as Map<String, dynamic>));
  }
  return records;
}
