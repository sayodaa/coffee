import 'package:coffee_app/core/domain/value_objects/money.dart';
import 'package:equatable/equatable.dart';

import 'recipe_entity.dart';

/// Sales suggestion model that combines recipe and pricing information
class SaleSuggestion extends Equatable {
  final String id;
  final String name;
  final String recipeId;
  final Money price;
  final Money cost;
  final Recipe recipe;
  final SizeVariant defaultSize;

  const SaleSuggestion({
    required this.id,
    required this.name,
    required this.recipeId,
    required this.price,
    required this.cost,
    required this.recipe,
    this.defaultSize = SizeVariant.medium,
  });

  /// Calculate profit for a given quantity
  Money calculateProfit(int quantity) {
    final totalRevenue = Money(price.amount * quantity);
    final totalCost = Money(cost.amount * quantity);
    return Money(totalRevenue.amount - totalCost.amount);
  }

  /// Calculate total price for quantity
  Money calculateTotalPrice(int quantity) {
    return Money(price.amount * quantity);
  }

  /// Calculate average cost (should already be per unit)
  double get costPerUnit => cost.amount;

  /// Calculate average price
  double get pricePerUnit => price.amount;

  /// Calculate profit margin percentage
  double get profitMarginPercent {
    if (price.amount == 0) return 0;
    return ((price.amount - cost.amount) / price.amount) * 100;
  }

  SaleSuggestion copyWith({
    String? id,
    String? name,
    String? recipeId,
    Money? price,
    Money? cost,
    Recipe? recipe,
    SizeVariant? defaultSize,
  }) {
    return SaleSuggestion(
      id: id ?? this.id,
      name: name ?? this.name,
      recipeId: recipeId ?? this.recipeId,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      recipe: recipe ?? this.recipe,
      defaultSize: defaultSize ?? this.defaultSize,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        recipeId,
        price,
        cost,
        recipe,
        defaultSize,
      ];
}
