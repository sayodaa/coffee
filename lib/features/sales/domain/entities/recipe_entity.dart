import 'package:coffee_app/core/domain/value_objects/money.dart';
import 'package:coffee_app/features/inventory/domain/entities/inventory_item.dart';
import 'package:equatable/equatable.dart';

/// Size variants for products
enum SizeVariant {
  small,
  medium,
  large,
}

/// Sugar levels affecting ingredient quantities
enum SugarLevel {
  none(0.0),
  low(0.5),
  normal(1.0),
  extra(1.5),
  doubleSugar(2.0);

  final double multiplier;
  const SugarLevel(this.multiplier);
}

/// Recipe ingredient definition
class RecipeIngredient extends Equatable {
  final String inventoryItemId;
  final double quantityRequiredPerUnit;
  final bool isOptional;
  final String? notes;

  const RecipeIngredient({
    required this.inventoryItemId,
    required this.quantityRequiredPerUnit,
    this.isOptional = false,
    this.notes,
  });

  /// Calculate total required quantity for a sale
  double calculateRequiredQuantity(int saleQuantity) {
    return quantityRequiredPerUnit * saleQuantity;
  }

  RecipeIngredient copyWith({
    String? inventoryItemId,
    double? quantityRequiredPerUnit,
    bool? isOptional,
    String? notes,
  }) {
    return RecipeIngredient(
      inventoryItemId: inventoryItemId ?? this.inventoryItemId,
      quantityRequiredPerUnit:
          quantityRequiredPerUnit ?? this.quantityRequiredPerUnit,
      isOptional: isOptional ?? this.isOptional,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        inventoryItemId,
        quantityRequiredPerUnit,
        isOptional,
        notes,
      ];
}

/// Recipe entity defining ingredients for a product
class Recipe extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final List<RecipeIngredient> ingredients;
  final Money price; // price set by user
  final Money cost; // calculated from ingredients (per unit)
  final Map<SizeVariant, double> sizeMultipliers;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Recipe({
    required this.id,
    required this.productId,
    required this.productName,
    required this.ingredients,
    required this.price,
    this.cost = const Money(0),
    this.sizeMultipliers = const {
      SizeVariant.small: 0.8,
      SizeVariant.medium: 1.0,
      SizeVariant.large: 1.3,
    },
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get ingredients scaled for a specific size
  List<RecipeIngredient> getScaledIngredients(SizeVariant size) {
    final multiplier = sizeMultipliers[size] ?? 1.0;
    return ingredients
        .map((i) => i.copyWith(
              quantityRequiredPerUnit: i.quantityRequiredPerUnit * multiplier,
            ))
        .toList();
  }

  /// Get ingredients with dynamic modifications (sugar level, etc.)
  List<RecipeIngredient> getModifiedIngredients({
    required SizeVariant size,
    Map<String, double>? ingredientModifications,
  }) {
    final scaled = getScaledIngredients(size);
    if (ingredientModifications == null || ingredientModifications.isEmpty) {
      return scaled;
    }

    return scaled.map((ingredient) {
      final modification = ingredientModifications[ingredient.inventoryItemId];
      if (modification != null) {
        return ingredient.copyWith(
          quantityRequiredPerUnit:
              ingredient.quantityRequiredPerUnit * modification,
        );
      }
      return ingredient;
    }).toList();
  }

  Recipe copyWith({
    String? id,
    String? productId,
    String? productName,
    List<RecipeIngredient>? ingredients,
    Money? price,
    Money? cost,
    Map<SizeVariant, double>? sizeMultipliers,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Recipe(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      ingredients: ingredients ?? this.ingredients,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      sizeMultipliers: sizeMultipliers ?? this.sizeMultipliers,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Calculate cost per unit using provided inventory items price mapping.
  Money calculateCostFromInventory(List<InventoryItem> inventoryItems,
      {SizeVariant size = SizeVariant.medium}) {
    final scaled = getScaledIngredients(size);
    double total = 0.0;
    for (var ing in scaled) {
      final inv = inventoryItems.firstWhere(
        (i) => i.id == ing.inventoryItemId,
        orElse: () => InventoryItem(
            id: '',
            sku: '',
            name: '',
            quantity: 0,
            minThreshold: 0,
            unit: '',
            price: 0),
      );
      total += ing.quantityRequiredPerUnit * inv.price;
    }
    return Money(total);
  }

  @override
  List<Object?> get props => [
        id,
        productId,
        productName,
        ingredients,
        price,
        cost,
        sizeMultipliers,
        createdAt,
        updatedAt,
      ];
}
