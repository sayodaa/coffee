# 1. ENTITY DESIGN

## 1.1 Core Domain Entities

### Inventory Domain

```dart
// lib/domain/inventory/entities/inventory_item.dart
class InventoryItem {
  final String id;
  final String name;
  final MeasurementUnit unit;
  final double currentQuantity;
  final double minimumThreshold;
  final double? costPerUnit;
  final DateTime lastUpdated;
  final InventoryStatus status;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.currentQuantity,
    required this.minimumThreshold,
    this.costPerUnit,
    required this.lastUpdated,
    this.status = InventoryStatus.normal,
  });

  bool get isLowStock => currentQuantity <= minimumThreshold;
  bool get isOutOfStock => currentQuantity <= 0;
  bool get canFulfill(double required) => currentQuantity >= required;

  InventoryItem copyWith({
    String? id,
    String? name,
    MeasurementUnit? unit,
    double? currentQuantity,
    double? minimumThreshold,
    double? costPerUnit,
    DateTime? lastUpdated,
    InventoryStatus? status,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      currentQuantity: currentQuantity ?? this.currentQuantity,
      minimumThreshold: minimumThreshold ?? this.minimumThreshold,
      costPerUnit: costPerUnit ?? this.costPerUnit,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      status: status ?? this.status,
    );
  }
}

enum MeasurementUnit {
  gram,
  milliliter,
  piece,
  liter,
  kilogram,
}

enum InventoryStatus {
  normal,
  lowStock,
  critical,
  outOfStock,
}
```

### Recipe Domain

```dart
// lib/domain/recipe/entities/recipe.dart
class Recipe {
  final String id;
  final String productId;
  final String productName;
  final List<RecipeIngredient> ingredients;
  final Map<SizeVariant, double> sizeMultipliers;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Recipe({
    required this.id,
    required this.productId,
    required this.productName,
    required this.ingredients,
    this.sizeMultipliers = const {
      SizeVariant.small: 0.8,
      SizeVariant.medium: 1.0,
      SizeVariant.large: 1.3,
    },
    required this.createdAt,
    required this.updatedAt,
  });

  List<RecipeIngredient> getScaledIngredients(SizeVariant size) {
    final multiplier = sizeMultipliers[size] ?? 1.0;
    return ingredients
        .map((i) => i.copyWith(
              quantityRequiredPerUnit: i.quantityRequiredPerUnit * multiplier,
            ))
        .toList();
  }

  List<RecipeIngredient> getModifiedIngredients({
    required SizeVariant size,
    Map<String, double>? ingredientModifications,
  }) {
    final scaled = getScaledIngredients(size);
    if (ingredientModifications == null) return scaled;

    return scaled.map((ingredient) {
      final modification = ingredientModifications[ingredient.inventoryItemId];
      if (modification != null) {
        return ingredient.copyWith(
          quantityRequiredPerUnit: ingredient.quantityRequiredPerUnit * modification,
        );
      }
      return ingredient;
    }).toList();
  }
}

class RecipeIngredient {
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

  RecipeIngredient copyWith({
    String? inventoryItemId,
    double? quantityRequiredPerUnit,
    bool? isOptional,
    String? notes,
  }) {
    return RecipeIngredient(
      inventoryItemId: inventoryItemId ?? this.inventoryItemId,
      quantityRequiredPerUnit: quantityRequiredPerUnit ?? this.quantityRequiredPerUnit,
      isOptional: isOptional ?? this.isOptional,
      notes: notes ?? this.notes,
    );
  }

  double calculateRequiredQuantity(int saleQuantity) {
    return quantityRequiredPerUnit * saleQuantity;
  }
}

enum SizeVariant {
  small,
  medium,
  large,
}

enum SugarLevel {
  none(0.0),
  low(0.5),
  normal(1.0),
  extra(1.5),
  double_(2.0);

  final double multiplier;
  const SugarLevel(this.multiplier);
}
```

### Sales Domain

```dart
// lib/domain/sales/entities/product.dart
class Product {
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

  Money getPrice(SizeVariant size) {
    return prices[size] ?? prices[SizeVariant.medium]!;
  }
}

// lib/domain/sales/entities/sale_item.dart
class SaleItem {
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

  double get sugarMultiplier => sugarLevel?.multiplier ?? 1.0;
}

// lib/domain/sales/entities/sale_transaction.dart
class SaleTransaction {
  final String id;
  final List<SaleItem> items;
  final DateTime timestamp;
  final Money totalAmount;
  final String? customerId;
  final String cashierId;
  final SaleStatus status;
  final InventoryConsumptionLog? consumptionLog;

  const SaleTransaction({
    required this.id,
    required this.items,
    required this.timestamp,
    required this.totalAmount,
    this.customerId,
    required this.cashierId,
    this.status = SaleStatus.completed,
    this.consumptionLog,
  });
}

enum SaleStatus {
  pending,
  validated,
  completed,
  cancelled,
  refunded,
}
```

### Consumption Log Domain

```dart
// lib/domain/consumption/entities/inventory_consumption_log.dart
class InventoryConsumptionLog {
  final String id;
  final String saleTransactionId;
  final List<ConsumedIngredient> ingredientsConsumed;
  final DateTime timestamp;
  final Money? totalCostOfIngredients;
  final String? notes;

  const InventoryConsumptionLog({
    required this.id,
    required this.saleTransactionId,
    required this.ingredientsConsumed,
    required this.timestamp,
    this.totalCostOfIngredients,
    this.notes,
  });

  Map<String, double> getAggregatedConsumption() {
    final Map<String, double> aggregated = {};
    for (final ingredient in ingredientsConsumed) {
      aggregated[ingredient.inventoryItemId] =
          (aggregated[ingredient.inventoryItemId] ?? 0) + ingredient.quantityConsumed;
    }
    return aggregated;
  }
}

class ConsumedIngredient {
  final String inventoryItemId;
  final String inventoryItemName;
  final double quantityConsumed;
  final MeasurementUnit unit;
  final double? costPerUnit;
  final double? totalCost;
  final String? notes;

  const ConsumedIngredient({
    required this.inventoryItemId,
    required this.inventoryItemName,
    required this.quantityConsumed,
    required this.unit,
    this.costPerUnit,
    this.totalCost,
    this.notes,
  });

  double calculateTotalCost() {
    if (costPerUnit == null) return 0.0;
    return costPerUnit! * quantityConsumed;
  }
}
```

## 1.2 Value Objects

```dart
// lib/domain/core/value_objects/money.dart
class Money {
  final double amount;
  final String currency;

  const Money(this.amount, {this.currency = 'USD'});

  Money operator +(Money other) {
    if (currency != other.currency) {
      throw ArgumentError('Cannot add different currencies');
    }
    return Money(amount + other.amount, currency: currency);
  }

  Money operator *(int multiplier) {
    return Money(amount * multiplier, currency: currency);
  }

  @override
  String toString() => '${amount.toStringAsFixed(2)} $currency';
}

// lib/domain/core/value_objects/result.dart
abstract class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get value => isSuccess ? (this as Success<T>).value : null;
  DomainException? get error => isFailure ? (this as Failure<T>).error : null;
}

class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

class Failure<T> extends Result<T> {
  final DomainException error;
  const Failure(this.error);
}

// lib/domain/core/exceptions/domain_exceptions.dart
abstract class DomainException implements Exception {
  final String message;
  final String? code;

  const DomainException(this.message, {this.code});

  @override
  String toString() => 'DomainException: $message (code: $code)';
}

class InsufficientStockException extends DomainException {
  final String inventoryItemId;
  final double required;
  final double available;

  InsufficientStockException({
    required this.inventoryItemId,
    required this.required,
    required this.available,
  }) : super(
          'Insufficient stock for item $inventoryItemId: required $required, available $available',
          code: 'INSUFFICIENT_STOCK',
        );
}

class InventoryItemNotFoundException extends DomainException {
  final String inventoryItemId;

  InventoryItemNotFoundException(this.inventoryItemId)
      : super(
          'Inventory item not found: $inventoryItemId',
          code: 'INVENTORY_NOT_FOUND',
        );
}

class RecipeNotFoundException extends DomainException {
  final String productId;

  RecipeNotFoundException(this.productId)
      : super(
          'Recipe not found for product: $productId',
          code: 'RECIPE_NOT_FOUND',
        );
}

class ConcurrentModificationException extends DomainException {
  const ConcurrentModificationException()
      : super(
          'Inventory was modified by another transaction. Please retry.',
          code: 'CONCURRENT_MODIFICATION',
        );
}
```
