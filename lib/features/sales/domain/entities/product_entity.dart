import 'package:equatable/equatable.dart';
import '../../../../core/domain/value_objects/money.dart';
import 'recipe_entity.dart';

/// Product entity representing sellable items
class Product extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String categoryId;
  final Map<SizeVariant, Money> prices;
  final String? recipeId;
  final bool isActive;
  final DateTime createdAt;

  const Product({
    required this.id,
    required this.name,
    this.description,
    required this.categoryId,
    required this.prices,
    this.recipeId,
    this.isActive = true,
    required this.createdAt,
  });

  /// Get price for a specific size
  Money getPrice(SizeVariant size) {
    return prices[size] ?? prices[SizeVariant.medium] ?? Money.zero;
  }

  /// Get all available sizes
  List<SizeVariant> get availableSizes =>
      prices.entries.where((e) => e.value.isPositive).map((e) => e.key).toList();

  Product copyWith({
    String? id,
    String? name,
    String? description,
    String? categoryId,
    Map<SizeVariant, Money>? prices,
    String? recipeId,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      prices: prices ?? this.prices,
      recipeId: recipeId ?? this.recipeId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        categoryId,
        prices,
        recipeId,
        isActive,
        createdAt,
      ];
}

/// Category for grouping products
class ProductCategory extends Equatable {
  final String id;
  final String name;
  final String? description;
  final int displayOrder;
  final bool isActive;

  const ProductCategory({
    required this.id,
    required this.name,
    this.description,
    this.displayOrder = 0,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id, name, description, displayOrder, isActive];
}
