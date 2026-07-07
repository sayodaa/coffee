import 'package:equatable/equatable.dart';
import '../../../../core/domain/value_objects/money.dart';
import 'recipe_entity.dart';

/// Sale item representing a line item in a transaction
class SaleItem extends Equatable {
  final String productId;
  final String productName;
  final int quantity;
  final SizeVariant size;
  final SugarLevel? sugarLevel;
  final Map<String, dynamic>? customizations;
  final Money unitPrice;
  final Money totalPrice;

  const SaleItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.size,
    this.sugarLevel,
    this.customizations,
    required this.unitPrice,
    required this.totalPrice,
  });

  /// Get sugar multiplier for inventory consumption
  double get sugarMultiplier => sugarLevel?.multiplier ?? 1.0;

  /// Get customization modifier for a specific ingredient
  double getCustomizationMultiplier(String inventoryItemId) {
    if (customizations == null) return 1.0;
    final value = customizations![inventoryItemId];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return 1.0;
  }

  SaleItem copyWith({
    String? productId,
    String? productName,
    int? quantity,
    SizeVariant? size,
    SugarLevel? sugarLevel,
    Map<String, dynamic>? customizations,
    Money? unitPrice,
    Money? totalPrice,
  }) {
    return SaleItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      size: size ?? this.size,
      sugarLevel: sugarLevel ?? this.sugarLevel,
      customizations: customizations ?? this.customizations,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }

  @override
  List<Object?> get props => [
        productId,
        productName,
        quantity,
        size,
        sugarLevel,
        customizations,
        unitPrice,
        totalPrice,
      ];
}

/// Sale transaction status
enum SaleStatus {
  pending,
  validated,
  completed,
  cancelled,
  refunded,
}
