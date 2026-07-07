# Coffee Shop Inventory & Sales Management System
## Comprehensive Architecture Design

---

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
  final String productId; // Links to Product
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

  /// Get scaled ingredient quantities for a specific size
  List<RecipeIngredient> getScaledIngredients(SizeVariant size) {
    final multiplier = sizeMultipliers[size] ?? 1.0;
    return ingredients
        .map((i) => i.copyWith(
              quantityRequiredPerUnit: i.quantityRequiredPerUnit * multiplier,
            ))
        .toList();
  }

  /// Get ingredient with dynamic modification (e.g., sugar level)
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

  /// Calculate total required for a sale quantity
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

  /// Get sugar multiplier for inventory consumption
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

  /// Group consumed ingredients by inventory item for aggregation
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

---

# 2. USECASE DESIGN

## 2.1 Consumption UseCases

```dart
// lib/domain/consumption/usecases/process_sale_consumption_usecase.dart

abstract class ProcessSaleConsumptionUseCase {
  /// Process inventory consumption for a sale transaction
  /// Returns the consumption log if successful
  Future<Result<InventoryConsumptionLog>> execute({
    required SaleTransaction transaction,
    required List<SaleItem> items,
  });
}

class ProcessSaleConsumptionUseCaseImpl implements ProcessSaleConsumptionUseCase {
  final InventoryRepository _inventoryRepository;
  final RecipeRepository _recipeRepository;
  final ConsumptionLogRepository _consumptionLogRepository;
  final TransactionLockManager _lockManager;

  ProcessSaleConsumptionUseCaseImpl({
    required InventoryRepository inventoryRepository,
    required RecipeRepository recipeRepository,
    required ConsumptionLogRepository consumptionLogRepository,
    required TransactionLockManager lockManager,
  })  : _inventoryRepository = inventoryRepository,
        _recipeRepository = recipeRepository,
        _consumptionLogRepository = consumptionLogRepository,
        _lockManager = lockManager;

  @override
  Future<Result<InventoryConsumptionLog>> execute({
    required SaleTransaction transaction,
    required List<SaleItem> items,
  }) async {
    try {
      // Step 1: Acquire locks for all required inventory items
      final requiredInventoryIds = await _getRequiredInventoryIds(items);
      final lock = await _lockManager.acquireLocks(requiredInventoryIds);

      try {
        // Step 2: Validate stock availability
        final validationResult = await _validateStockAvailability(items);
        if (validationResult.isFailure) {
          return Failure(validationResult.error!);
        }

        // Step 3: Calculate consumption requirements
        final consumptionRequirements = validationResult.value!;

        // Step 4: Atomically deduct inventory
        final deductionResult = await _deductInventoryAtomically(consumptionRequirements);
        if (deductionResult.isFailure) {
          return Failure(deductionResult.error!);
        }

        // Step 5: Create consumption log
        final consumptionLog = await _createConsumptionLog(
          transactionId: transaction.id,
          requirements: consumptionRequirements,
        );

        // Step 6: Save consumption log
        await _consumptionLogRepository.save(consumptionLog);

        return Success(consumptionLog);
      } finally {
        // Always release locks
        await _lockManager.releaseLocks(lock);
      }
    } on DomainException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(DomainException('Unexpected error: $e', code: 'UNKNOWN_ERROR'));
    }
  }

  Future<Set<String>> _getRequiredInventoryIds(List<SaleItem> items) async {
    final Set<String> inventoryIds = {};

    for (final item in items) {
      final recipe = await _recipeRepository.getByProductId(item.productId);
      if (recipe == null) continue;

      final modifiedIngredients = recipe.getModifiedIngredients(
        size: item.size,
        ingredientModifications: _buildIngredientModifications(item),
      );

      for (final ingredient in modifiedIngredients) {
        inventoryIds.add(ingredient.inventoryItemId);
      }
    }

    return inventoryIds;
  }

  Map<String, double>? _buildIngredientModifications(SaleItem item) {
    final modifications = <String, double>{};

    // Apply sugar level modifications
    if (item.sugarLevel != null) {
      modifications['sugar'] = item.sugarLevel!.multiplier;
      // Alternative: use actual inventory item ID for sugar
    }

    // Apply customizations
    item.customizations?.forEach((key, value) {
      if (value is double) {
        modifications[key] = value;
      }
    });

    return modifications.isEmpty ? null : modifications;
  }

  Future<Result<Map<String, ConsumptionRequirement>>> _validateStockAvailability(
    List<SaleItem> items,
  ) async {
    final Map<String, ConsumptionRequirement> requirements = {};
    final List<DomainException> validationErrors = [];

    for (final item in items) {
      final recipe = await _recipeRepository.getByProductId(item.productId);
      if (recipe == null) {
        validationErrors.add(RecipeNotFoundException(item.productId));
        continue;
      }

      final ingredients = recipe.getModifiedIngredients(
        size: item.size,
        ingredientModifications: _buildIngredientModifications(item),
      );

      for (final ingredient in ingredients) {
        final inventoryItem = await _inventoryRepository.getById(ingredient.inventoryItemId);
        if (inventoryItem == null) {
          validationErrors.add(InventoryItemNotFoundException(ingredient.inventoryItemId));
          continue;
        }

        final requiredQuantity = ingredient.calculateRequiredQuantity(item.quantity);
        final existingRequirement = requirements[ingredient.inventoryItemId];

        if (existingRequirement != null) {
          // Accumulate requirements for same item
          requirements[ingredient.inventoryItemId] = existingRequirement.copyWith(
            totalQuantityRequired: existingRequirement.totalQuantityRequired + requiredQuantity,
          );
        } else {
          requirements[ingredient.inventoryItemId] = ConsumptionRequirement(
            inventoryItemId: ingredient.inventoryItemId,
            inventoryItemName: inventoryItem.name,
            unit: inventoryItem.unit,
            totalQuantityRequired: requiredQuantity,
            costPerUnit: inventoryItem.costPerUnit,
          );
        }

        // Validate stock
        final totalRequired = requirements[ingredient.inventoryItemId]!.totalQuantityRequired;
        if (!inventoryItem.canFulfill(totalRequired)) {
          validationErrors.add(InsufficientStockException(
            inventoryItemId: ingredient.inventoryItemId,
            required: totalRequired,
            available: inventoryItem.currentQuantity,
          ));
        }
      }
    }

    if (validationErrors.isNotEmpty) {
      return Failure(ValidationException(validationErrors));
    }

    return Success(requirements);
  }

  Future<Result<void>> _deductInventoryAtomically(
    Map<String, ConsumptionRequirement> requirements,
  ) async {
    try {
      // Use transaction to ensure atomicity
      await _inventoryRepository.runInTransaction(() async {
        for (final entry in requirements.entries) {
          final inventoryItem = await _inventoryRepository.getById(entry.key);
          if (inventoryItem == null) {
            throw InventoryItemNotFoundException(entry.key);
          }

          final newQuantity = inventoryItem.currentQuantity - entry.value.totalQuantityRequired;
          if (newQuantity < 0) {
            throw InsufficientStockException(
              inventoryItemId: entry.key,
              required: entry.value.totalQuantityRequired,
              available: inventoryItem.currentQuantity,
            );
          }

          final updatedItem = inventoryItem.copyWith(
            currentQuantity: newQuantity,
            lastUpdated: DateTime.now(),
            status: _determineStockStatus(newQuantity, inventoryItem.minimumThreshold),
          );

          await _inventoryRepository.update(updatedItem);
        }
      });

      return const Success(null);
    } on DomainException {
      rethrow;
    } catch (e) {
      return Failure(ConcurrentModificationException());
    }
  }

  InventoryStatus _determineStockStatus(double quantity, double threshold) {
    if (quantity <= 0) return InventoryStatus.outOfStock;
    if (quantity <= threshold * 0.5) return InventoryStatus.critical;
    if (quantity <= threshold) return InventoryStatus.lowStock;
    return InventoryStatus.normal;
  }

  Future<InventoryConsumptionLog> _createConsumptionLog({
    required String transactionId,
    required Map<String, ConsumptionRequirement> requirements,
  }) async {
    final consumedIngredients = requirements.values.map((req) {
      final totalCost = req.costPerUnit != null ? req.costPerUnit! * req.totalQuantityRequired : null;

      return ConsumedIngredient(
        inventoryItemId: req.inventoryItemId,
        inventoryItemName: req.inventoryItemName,
        quantityConsumed: req.totalQuantityRequired,
        unit: req.unit,
        costPerUnit: req.costPerUnit,
        totalCost: totalCost,
      );
    }).toList();

    final totalIngredientCost = consumedIngredients
        .where((i) => i.totalCost != null)
        .fold<double>(0, (sum, i) => sum + i.totalCost!);

    return InventoryConsumptionLog(
      id: _generateId(),
      saleTransactionId: transactionId,
      ingredientsConsumed: consumedIngredients,
      timestamp: DateTime.now(),
      totalCostOfIngredients: Money(totalIngredientCost),
    );
  }

  String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${UniqueKey().hashCode}';
  }
}

// Supporting classes
class ConsumptionRequirement {
  final String inventoryItemId;
  final String inventoryItemName;
  final MeasurementUnit unit;
  final double totalQuantityRequired;
  final double? costPerUnit;

  ConsumptionRequirement({
    required this.inventoryItemId,
    required this.inventoryItemName,
    required this.unit,
    required this.totalQuantityRequired,
    this.costPerUnit,
  });

  ConsumptionRequirement copyWith({
    String? inventoryItemId,
    String? inventoryItemName,
    MeasurementUnit? unit,
    double? totalQuantityRequired,
    double? costPerUnit,
  }) {
    return ConsumptionRequirement(
      inventoryItemId: inventoryItemId ?? this.inventoryItemId,
      inventoryItemName: inventoryItemName ?? this.inventoryItemName,
      unit: unit ?? this.unit,
      totalQuantityRequired: totalQuantityRequired ?? this.totalQuantityRequired,
      costPerUnit: costPerUnit ?? this.costPerUnit,
    );
  }
}

class ValidationException extends DomainException {
  final List<DomainException> errors;

  ValidationException(this.errors)
      : super(
          'Validation failed with ${errors.length} errors',
          code: 'VALIDATION_ERROR',
        );
}
```

## 2.2 Additional UseCases

```dart
// lib/domain/consumption/usecases/check_stock_availability_usecase.dart
abstract class CheckStockAvailabilityUseCase {
  /// Check if stock is available for a potential sale without consuming
  Future<StockAvailabilityResult> checkAvailability({
    required String productId,
    required int quantity,
    required SizeVariant size,
    Map<String, dynamic>? customizations,
  });
}

// lib/domain/consumption/usecases/forecast_consumption_usecase.dart
abstract class ForecastConsumptionUseCase {
  /// Forecast inventory needs based on historical data
  Future<ConsumptionForecast> forecast({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? inventoryItemIds,
  });
}

// lib/domain/inventory/usecases/check_low_stock_usecase.dart
abstract class CheckLowStockUseCase {
  /// Get all inventory items with low stock
  Future<List<InventoryItem>> getLowStockItems();

  /// Check specific items after a transaction
  Future<List<InventoryItem>> checkItemsAfterConsumption(List<String> inventoryItemIds);
}

// lib/domain/inventory/usecases/receive_stock_usecase.dart
abstract class ReceiveStockUseCase {
  /// Add stock to inventory (e.g., new shipment received)
  Future<Result<InventoryItem>> execute({
    required String inventoryItemId,
    required double quantityReceived,
    required double unitCost,
    String? supplierId,
    String? notes,
  });
}
```

## 2.3 Repository Interfaces

```dart
// lib/domain/inventory/repositories/inventory_repository.dart
abstract class InventoryRepository {
  Future<InventoryItem?> getById(String id);
  Future<List<InventoryItem>> getAll();
  Future<List<InventoryItem>> getByStatus(InventoryStatus status);
  Future<List<InventoryItem>> getLowStockItems();
  Future<void> save(InventoryItem item);
  Future<void> update(InventoryItem item);
  Future<void> delete(String id);

  /// Run operations in a transaction (atomic)
  Future<void> runInTransaction(Future<void> Function() operations);

  /// Optimistic locking - update with version check
  Future<bool> updateWithVersionCheck(InventoryItem item, int expectedVersion);
}

// lib/domain/recipe/repositories/recipe_repository.dart
abstract class RecipeRepository {
  Future<Recipe?> getById(String id);
  Future<Recipe?> getByProductId(String productId);
  Future<List<Recipe>> getAll();
  Future<List<Recipe>> getByCategory(String categoryId);
  Future<void> save(Recipe recipe);
  Future<void> update(Recipe recipe);
  Future<void> delete(String id);
}

// lib/domain/consumption/repositories/consumption_log_repository.dart
abstract class ConsumptionLogRepository {
  Future<void> save(InventoryConsumptionLog log);
  Future<InventoryConsumptionLog?> getById(String id);
  Future<InventoryConsumptionLog?> getByTransactionId(String transactionId);
  Future<List<InventoryConsumptionLog>> getByDateRange(DateTime start, DateTime end);
  Future<List<InventoryConsumptionLog>> getByInventoryItem(String inventoryItemId);
  Future<Map<String, double>> getAggregatedConsumptionByItem({
    required DateTime start,
    required DateTime end,
  });
}

// lib/domain/core/interfaces/transaction_lock_manager.dart
abstract class TransactionLockManager {
  /// Acquire locks for multiple inventory items
  Future<TransactionLock> acquireLocks(Set<String> inventoryItemIds);

  /// Release acquired locks
  Future<void> releaseLocks(TransactionLock lock);
}

class TransactionLock {
  final String lockId;
  final Set<String> inventoryItemIds;
  final DateTime acquiredAt;

  TransactionLock({
    required this.lockId,
    required this.inventoryItemIds,
    required this.acquiredAt,
  });
}
```

---

# 3. DATA FLOW BETWEEN CUBITS

## 3.1 Cubit Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              PRESENTATION LAYER                              │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐           │
│  │   SalesCubit    │  │ InventoryCubit  │  │   RecipeCubit   │           │
│  │                 │  │                 │  │                 │           │
│  │ - Create sale   │  │ - Load items    │  │ - Load recipes  │           │
│  │ - Add items     │  │ - Stock alerts  │  │ - CRUD recipes  │           │
│  │ - Checkout      │  │ - Receive stock │  │                 │           │
│  └────────┬────────┘  └─────────────────┘  └─────────────────┘           │
│           │                                                                  │
│           │  ┌──────────────────────────────────────────────────┐          │
│           └──┤    ProcessSaleConsumptionUseCase.execute()       │          │
│              │    (Domain Layer - Business Logic)               │          │
│              └──────────────────────────────────────────────────┘          │
├─────────────────────────────────────────────────────────────────────────────┤
│                              DATA LAYER                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐           │
│  │InventoryRepository│ │RecipeRepository│ │ConsumptionLog │           │
│  │   (Implementation) │ │ (Implementation)│ │  Repository    │           │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘           │
│           │                    │                    │                      │
│           └────────────────────┴────────────────────┘                      │
│                              │                                               │
│                              ▼                                               │
│  ┌─────────────────────────────────────────────────────────┐              │
│  │              Local Database (SQLite/Hive)                │              │
│  │  - inventory_items  │  recipes  │  consumption_logs     │              │
│  └─────────────────────────────────────────────────────────┘              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 3.2 State Design

```dart
// lib/presentation/sales/cubit/sales_cubit.dart
class SalesState {
  final List<SaleItem> currentItems;
  final bool isProcessing;
  final SaleResult? lastResult;
  final List<StockAlert>? stockAlerts;

  const SalesState({
    this.currentItems = const [],
    this.isProcessing = false,
    this.lastResult,
    this.stockAlerts,
  });

  SalesState copyWith({
    List<SaleItem>? currentItems,
    bool? isProcessing,
    SaleResult? lastResult,
    List<StockAlert>? stockAlerts,
  }) {
    return SalesState(
      currentItems: currentItems ?? this.currentItems,
      isProcessing: isProcessing ?? this.isProcessing,
      lastResult: lastResult ?? this.lastResult,
      stockAlerts: stockAlerts ?? this.stockAlerts,
    );
  }
}

class SaleResult {
  final bool success;
  final SaleTransaction? transaction;
  final List<DomainException>? errors;
  final List<StockAlert>? lowStockAlerts;

  SaleResult({
    required this.success,
    this.transaction,
    this.errors,
    this.lowStockAlerts,
  });
}

class StockAlert {
  final String inventoryItemId;
  final String itemName;
  final double currentQuantity;
  final double threshold;
  final InventoryStatus status;

  StockAlert({
    required this.inventoryItemId,
    required this.itemName,
    required this.currentQuantity,
    required this.threshold,
    required this.status,
  });
}

class SalesCubit extends Cubit<SalesState> {
  final ProcessSaleConsumptionUseCase _consumptionUseCase;
  final CheckLowStockUseCase _lowStockUseCase;

  SalesCubit({
    required ProcessSaleConsumptionUseCase consumptionUseCase,
    required CheckLowStockUseCase lowStockUseCase,
  })  : _consumptionUseCase = consumptionUseCase,
        _lowStockUseCase = lowStockUseCase,
        super(const SalesState());

  void addItemToSale(SaleItem item) {
    emit(state.copyWith(
      currentItems: [...state.currentItems, item],
    ));
  }

  void removeItemFromSale(String productId, SizeVariant size) {
    emit(state.copyWith(
      currentItems: state.currentItems
          .where((i) => !(i.productId == productId && i.size == size))
          .toList(),
    ));
  }

  Future<void> completeSale({
    required String cashierId,
    String? customerId,
  }) async {
    if (state.currentItems.isEmpty) return;

    emit(state.copyWith(isProcessing: true, lastResult: null));

    // Build transaction
    final transaction = SaleTransaction(
      id: _generateTransactionId(),
      items: state.currentItems,
      timestamp: DateTime.now(),
      totalAmount: _calculateTotal(),
      cashierId: cashierId,
      customerId: customerId,
    );

    // Execute consumption usecase
    final result = await _consumptionUseCase.execute(
      transaction: transaction,
      items: state.currentItems,
    );

    if (result.isSuccess) {
      // Check for low stock after sale
      final consumedItemIds = result.value!.ingredientsConsumed
          .map((i) => i.inventoryItemId)
          .toSet()
          .toList();
      final lowStockItems = await _lowStockUseCase.checkItemsAfterConsumption(consumedItemIds);

      final stockAlerts = lowStockItems
          .map((item) => StockAlert(
                inventoryItemId: item.id,
                itemName: item.name,
                currentQuantity: item.currentQuantity,
                threshold: item.minimumThreshold,
                status: item.status,
              ))
          .toList();

      emit(SalesState(
        lastResult: SaleResult(
          success: true,
          transaction: transaction.copyWith(consumptionLog: result.value),
          lowStockAlerts: stockAlerts.isEmpty ? null : stockAlerts,
        ),
      ));
    } else {
      emit(state.copyWith(
        isProcessing: false,
        lastResult: SaleResult(
          success: false,
          errors: _extractErrors(result.error!),
        ),
      ));
    }
  }

  List<DomainException> _extractErrors(DomainException error) {
    if (error is ValidationException) {
      return error.errors;
    }
    return [error];
  }

  Money _calculateTotal() {
    return state.currentItems.fold(
      const Money(0),
      (sum, item) => sum + item.totalPrice,
    );
  }

  String _generateTransactionId() {
    return 'TXN_${DateTime.now().millisecondsSinceEpoch}';
  }
}
```

## 3.3 Inventory Cubit

```dart
// lib/presentation/inventory/cubit/inventory_cubit.dart
class InventoryState {
  final List<InventoryItem> items;
  final List<InventoryItem> lowStockItems;
  final bool isLoading;
  final String? error;

  const InventoryState({
    this.items = const [],
    this.lowStockItems = const [],
    this.isLoading = false,
    this.error,
  });

  InventoryState copyWith({
    List<InventoryItem>? items,
    List<InventoryItem>? lowStockItems,
    bool? isLoading,
    String? error,
  }) {
    return InventoryState(
      items: items ?? this.items,
      lowStockItems: lowStockItems ?? this.lowStockItems,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class InventoryCubit extends Cubit<InventoryState> {
  final InventoryRepository _repository;
  final CheckLowStockUseCase _lowStockUseCase;
  final ReceiveStockUseCase _receiveStockUseCase;

  InventoryCubit({
    required InventoryRepository repository,
    required CheckLowStockUseCase lowStockUseCase,
    required ReceiveStockUseCase receiveStockUseCase,
  })  : _repository = repository,
        _lowStockUseCase = lowStockUseCase,
        _receiveStockUseCase = receiveStockUseCase,
        super(const InventoryState());

  Future<void> loadInventory() async {
    emit(state.copyWith(isLoading: true));
    try {
      final items = await _repository.getAll();
      final lowStock = await _lowStockUseCase.getLowStockItems();
      emit(state.copyWith(
        items: items,
        lowStockItems: lowStock,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> checkLowStock() async {
    final lowStock = await _lowStockUseCase.getLowStockItems();
    emit(state.copyWith(lowStockItems: lowStock));
  }

  Future<Result<void>> receiveStock({
    required String inventoryItemId,
    required double quantity,
    required double unitCost,
  }) async {
    final result = await _receiveStockUseCase.execute(
      inventoryItemId: inventoryItemId,
      quantityReceived: quantity,
      unitCost: unitCost,
    );

    if (result.isSuccess) {
      await loadInventory(); // Refresh list
    }

    return result;
  }
}
```

## 3.4 Inter-Cubit Communication Pattern

```dart
// lib/presentation/core/services/domain_event_bus.dart

/// Domain events for cross-cubit communication
abstract class DomainEvent {
  final DateTime timestamp;
  DomainEvent() : timestamp = DateTime.now();
}

class InventoryConsumedEvent extends DomainEvent {
  final String saleTransactionId;
  final List<ConsumedIngredient> consumedIngredients;

  InventoryConsumedEvent({
    required this.saleTransactionId,
    required this.consumedIngredients,
  });
}

class LowStockDetectedEvent extends DomainEvent {
  final List<InventoryItem> lowStockItems;

  LowStockDetectedEvent(this.lowStockItems);
}

class StockReceivedEvent extends DomainEvent {
  final String inventoryItemId;
  final double quantityReceived;
  final double newTotal;

  StockReceivedEvent({
    required this.inventoryItemId,
    required this.quantityReceived,
    required this.newTotal,
  });
}

/// Simple event bus for loose coupling between cubits
class DomainEventBus {
  final _controller = StreamController<DomainEvent>.broadcast();

  Stream<T> on<T extends DomainEvent>() {
    return _controller.stream.where((event) => event is T).cast<T>();
  }

  void emit(DomainEvent event) {
    _controller.add(event);
  }

  void dispose() {
    _controller.close();
  }
}
```

## 3.5 Updated Cubits with Event Bus

```dart
// SalesCubit updated to emit events
class SalesCubit extends Cubit<SalesState> {
  final ProcessSaleConsumptionUseCase _consumptionUseCase;
  final CheckLowStockUseCase _lowStockUseCase;
  final DomainEventBus _eventBus;

  // ... constructor

  Future<void> completeSale({...}) async {
    // ... validation logic ...

    final result = await _consumptionUseCase.execute(...);

    if (result.isSuccess) {
      // Emit domain event for other cubits to react
      _eventBus.emit(InventoryConsumedEvent(
        saleTransactionId: transaction.id,
        consumedIngredients: result.value!.ingredientsConsumed,
      ));

      // Check and emit low stock event if needed
      final lowStockItems = await _lowStockUseCase.checkItemsAfterConsumption(...);
      if (lowStockItems.isNotEmpty) {
        _eventBus.emit(LowStockDetectedEvent(lowStockItems));
      }
    }
  }
}

// InventoryCubit listening to events
class InventoryCubit extends Cubit<InventoryState> {
  final DomainEventBus _eventBus;
  StreamSubscription? _subscription;

  InventoryCubit({..., required DomainEventBus eventBus})
      : _eventBus = eventBus,
        super(const InventoryState()) {
    _subscribeToEvents();
  }

  void _subscribeToEvents() {
    _subscription = _eventBus.on<InventoryConsumedEvent>().listen((event) {
      // Refresh inventory when items are consumed
      loadInventory();
    });

    _eventBus.on<StockReceivedEvent>().listen((event) {
      loadInventory();
    });
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
```

---

# 4. VALIDATION STRATEGY

## 4.1 Validation Layers

```
┌─────────────────────────────────────────────────────────────────┐
│                    VALIDATION LAYERS                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Layer 1: UI Input Validation                                    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ - Quantity must be positive integer                     │    │
│  │ - Size variant must be valid                            │    │
│  │ - Customizations within allowed ranges                  │    │
│  │ - Customer info format (if provided)                  │    │
│  └─────────────────────────────────────────────────────────┘    │
│                            ↓                                     │
│  Layer 2: Domain Validation (Entity level)                        │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ - Product must exist and be active                     │    │
│  │ - Recipe must exist for product                        │    │
│  │ - All ingredients must exist in inventory            │    │
│  │ - Units must be compatible                             │    │
│  └─────────────────────────────────────────────────────────┘    │
│                            ↓                                     │
│  Layer 3: Business Rule Validation (UseCase level)              │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ - Sufficient stock for ALL ingredients                 │    │
│  │ - No negative stock allowed (prevent oversell)          │    │
│  │ - Concurrent transaction check                         │    │
│  │ - Pricing validity                                     │    │
│  └─────────────────────────────────────────────────────────┘    │
│                            ↓                                     │
│  Layer 4: Database Constraint Validation                         │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ - Foreign key constraints                               │    │
│  │ - Quantity >= 0 (DB-level check)                      │    │
│  │ - Unique transaction ID                                 │    │
│  │ - Optimistic locking version check                      │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## 4.2 Validation Implementation

```dart
// lib/domain/core/validators/validators.dart

abstract class Validator<T> {
  ValidationResult validate(T input);
}

class ValidationResult {
  final bool isValid;
  final List<ValidationError> errors;

  ValidationResult({required this.isValid, required this.errors});

  factory ValidationResult.success() =>
      ValidationResult(isValid: true, errors: []);

  factory ValidationResult.failure(List<ValidationError> errors) =>
      ValidationResult(isValid: false, errors: errors);
}

class ValidationError {
  final String field;
  final String message;
  final String? code;

  ValidationError({required this.field, required this.message, this.code});
}

// Layer 1: Input Validator
class SaleItemInputValidator implements Validator<SaleItem> {
  @override
  ValidationResult validate(SaleItem item) {
    final errors = <ValidationError>[];

    if (item.quantity <= 0) {
      errors.add(ValidationError(
        field: 'quantity',
        message: 'Quantity must be greater than 0',
        code: 'INVALID_QUANTITY',
      ));
    }

    if (item.quantity > 1000) {
      errors.add(ValidationError(
        field: 'quantity',
        message: 'Quantity exceeds maximum allowed (1000)',
        code: 'QUANTITY_TOO_LARGE',
      ));
    }

    // Sugar level validation
    if (item.sugarLevel == SugarLevel.double_ && item.quantity > 10) {
      errors.add(ValidationError(
        field: 'sugarLevel',
        message: 'Double sugar not allowed for large quantity orders',
        code: 'SUGAR_LIMIT_EXCEEDED',
      ));
    }

    return errors.isEmpty
        ? ValidationResult.success()
        : ValidationResult.failure(errors);
  }
}

// Layer 2: Domain Validator
class SaleDomainValidator {
  final ProductRepository _productRepo;
  final RecipeRepository _recipeRepo;
  final InventoryRepository _inventoryRepo;

  SaleDomainValidator({
    required ProductRepository productRepo,
    required RecipeRepository recipeRepo,
    required InventoryRepository inventoryRepo,
  })  : _productRepo = productRepo,
        _recipeRepo = recipeRepo,
        _inventoryRepo = inventoryRepo;

  Future<ValidationResult> validate(SaleItem item) async {
    final errors = <ValidationError>[];

    // Validate product exists and is active
    final product = await _productRepo.getById(item.productId);
    if (product == null) {
      errors.add(ValidationError(
        field: 'productId',
        message: 'Product not found: ${item.productId}',
        code: 'PRODUCT_NOT_FOUND',
      ));
    } else if (!product.isActive) {
      errors.add(ValidationError(
        field: 'productId',
        message: 'Product is not active: ${product.name}',
        code: 'PRODUCT_INACTIVE',
      ));
    }

    // Validate recipe exists
    final recipe = await _recipeRepo.getByProductId(item.productId);
    if (recipe == null) {
      errors.add(ValidationError(
        field: 'recipe',
        message: 'No recipe found for product: ${item.productId}',
        code: 'RECIPE_NOT_FOUND',
      ));
    } else {
      // Validate all ingredients exist
      final ingredients = recipe.getModifiedIngredients(
        size: item.size,
        ingredientModifications: {},
      );

      for (final ingredient in ingredients) {
        final inventoryItem = await _inventoryRepo.getById(ingredient.inventoryItemId);
        if (inventoryItem == null) {
          errors.add(ValidationError(
            field: 'ingredient.${ingredient.inventoryItemId}',
            message: 'Inventory item not found: ${ingredient.inventoryItemId}',
            code: 'INGREDIENT_NOT_FOUND',
          ));
        }
      }
    }

    return errors.isEmpty
        ? ValidationResult.success()
        : ValidationResult.failure(errors);
  }
}

// Layer 3: Business Rule Validator
class StockAvailabilityValidator {
  final InventoryRepository _inventoryRepo;
  final RecipeRepository _recipeRepo;

  StockAvailabilityValidator({
    required InventoryRepository inventoryRepo,
    required RecipeRepository recipeRepo,
  })  : _inventoryRepo = inventoryRepo,
        _recipeRepo = recipeRepo;

  Future<StockValidationResult> validateStockForItems(List<SaleItem> items) async {
    final requirements = <String, double>{};
    final failures = <StockValidationFailure>[];

    // Aggregate all requirements
    for (final item in items) {
      final recipe = await _recipeRepo.getByProductId(item.productId);
      if (recipe == null) continue;

      final ingredients = recipe.getModifiedIngredients(
        size: item.size,
        ingredientModifications: _getModifications(item),
      );

      for (final ingredient in ingredients) {
        final required = ingredient.calculateRequiredQuantity(item.quantity);
        requirements[ingredient.inventoryItemId] =
            (requirements[ingredient.inventoryItemId] ?? 0) + required;
      }
    }

    // Validate against available stock
    for (final entry in requirements.entries) {
      final inventoryItem = await _inventoryRepo.getById(entry.key);
      if (inventoryItem == null) {
        failures.add(StockValidationFailure(
          inventoryItemId: entry.key,
          required: entry.value,
          available: 0,
          reason: FailureReason.itemNotFound,
        ));
      } else if (inventoryItem.currentQuantity < entry.value) {
        failures.add(StockValidationFailure(
          inventoryItemId: entry.key,
          inventoryItemName: inventoryItem.name,
          required: entry.value,
          available: inventoryItem.currentQuantity,
          unit: inventoryItem.unit,
          reason: FailureReason.insufficientStock,
        ));
      }
    }

    return failures.isEmpty
        ? StockValidationResult.success()
        : StockValidationResult.failure(failures);
  }

  Map<String, double>? _getModifications(SaleItem item) {
    if (item.sugarLevel != null) {
      return {'sugar': item.sugarLevel!.multiplier};
    }
    return null;
  }
}

class StockValidationResult {
  final bool isAvailable;
  final List<StockValidationFailure>? failures;

  StockValidationResult({required this.isAvailable, this.failures});

  factory StockValidationResult.success() =>
      StockValidationResult(isAvailable: true);

  factory StockValidationResult.failure(List<StockValidationFailure> failures) =>
      StockValidationResult(isAvailable: false, failures: failures);
}

class StockValidationFailure {
  final String inventoryItemId;
  final String? inventoryItemName;
  final double required;
  final double available;
  final MeasurementUnit? unit;
  final FailureReason reason;

  StockValidationFailure({
    required this.inventoryItemId,
    this.inventoryItemName,
    required this.required,
    required this.available,
    this.unit,
    required this.reason,
  });
}

enum FailureReason {
  itemNotFound,
  insufficientStock,
  itemInactive,
}
```

## 4.3 Validation Orchestrator

```dart
// lib/domain/sales/usecases/validate_sale_usecase.dart
class ValidateSaleUseCase {
  final SaleItemInputValidator _inputValidator;
  final SaleDomainValidator _domainValidator;
  final StockAvailabilityValidator _stockValidator;

  ValidateSaleUseCase({
    required SaleItemInputValidator inputValidator,
    required SaleDomainValidator domainValidator,
    required StockAvailabilityValidator stockValidator,
  })  : _inputValidator = inputValidator,
        _domainValidator = domainValidator,
        _stockValidator = stockValidator;

  /// Full validation pipeline
  Future<ComprehensiveValidationResult> validate({
    required List<SaleItem> items,
    bool skipStockCheck = false,
  }) async {
    final allErrors = <ValidationLayerError>[];

    // Layer 1: Input validation
    for (final item in items) {
      final result = _inputValidator.validate(item);
      if (!result.isValid) {
        allErrors.addAll(result.errors.map((e) => ValidationLayerError(
              layer: ValidationLayer.input,
              error: e,
            )));
      }
    }

    // Early return if input validation fails
    if (allErrors.isNotEmpty) {
      return ComprehensiveValidationResult.failures(allErrors);
    }

    // Layer 2: Domain validation
    for (final item in items) {
      final result = await _domainValidator.validate(item);
      if (!result.isValid) {
        allErrors.addAll(result.errors.map((e) => ValidationLayerError(
              layer: ValidationLayer.domain,
              error: e,
            )));
      }
    }

    if (allErrors.isNotEmpty) {
      return ComprehensiveValidationResult.failures(allErrors);
    }

    // Layer 3: Stock validation (optional for pre-check)
    if (!skipStockCheck) {
      final stockResult = await _stockValidator.validateStockForItems(items);
      if (!stockResult.isAvailable) {
        allErrors.addAll(stockResult.failures!.map((f) => ValidationLayerError(
              layer: ValidationLayer.businessRule,
              error: ValidationError(
                field: 'stock.${f.inventoryItemId}',
                message: 'Insufficient stock for ${f.inventoryItemName ?? f.inventoryItemId}: '
                    'need ${f.required}${f.unit?.name ?? ''}, '
                    'have ${f.available}${f.unit?.name ?? ''}',
                code: 'INSUFFICIENT_STOCK',
              ),
            )));
      }
    }

    return allErrors.isEmpty
        ? ComprehensiveValidationResult.success()
        : ComprehensiveValidationResult.failures(allErrors);
  }
}

class ComprehensiveValidationResult {
  final bool isValid;
  final List<ValidationLayerError>? errors;

  ComprehensiveValidationResult({required this.isValid, this.errors});

  factory ComprehensiveValidationResult.success() =>
      ComprehensiveValidationResult(isValid: true);

  factory ComprehensiveValidationResult.failures(List<ValidationLayerError> errors) =>
      ComprehensiveValidationResult(isValid: false, errors: errors);
}

class ValidationLayerError {
  final ValidationLayer layer;
  final ValidationError error;

  ValidationLayerError({required this.layer, required this.error});
}

enum ValidationLayer {
  input,
  domain,
  businessRule,
  database,
}
```

---

# 5. SAMPLE PSEUDO-CODE FOR SALE TRANSACTION

## 5.1 Complete Sale Flow

```dart
// lib/presentation/sales/screens/sale_screen.dart (Pseudo-code)

class SaleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SalesCubit>(),
      child: BlocConsumer<SalesCubit, SalesState>(
        listener: (context, state) {
          if (state.lastResult != null) {
            if (state.lastResult!.success) {
              // Show success
              showSuccessDialog(
                transactionId: state.lastResult!.transaction!.id,
                total: state.lastResult!.transaction!.totalAmount,
              );

              // Show low stock warnings if any
              if (state.lastResult!.lowStockAlerts?.isNotEmpty ?? false) {
                showLowStockWarnings(state.lastResult!.lowStockAlerts!);
              }

              // Print receipt
              context.read<ReceiptPrinter>().print(state.lastResult!.transaction!);
            } else {
              // Show errors
              showErrorDialog(errors: state.lastResult!.errors!);
            }
          }
        },
        builder: (context, state) {
          return Scaffold(
            body: Row(
              children: [
                // Left: Product catalog with categories
                Expanded(
                  flex: 2,
                  child: ProductCatalog(
                    onProductSelected: (product) {
                      // Show size/customization dialog
                      showSaleItemDialog(
                        product: product,
                        onConfirm: (saleItem) {
                          context.read<SalesCubit>().addItemToSale(saleItem);
                        },
                      );
                    },
                  ),
                ),

                // Right: Current sale items
                Expanded(
                  flex: 1,
                  child: SaleSummary(
                    items: state.currentItems,
                    onCheckout: () => context.read<SalesCubit>().completeSale(
                      cashierId: currentUser.id,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

## 5.2 Sale Transaction Execution (Detailed)

```dart
// Complete execution flow with comments

Future<void> executeSaleTransaction() async {
  // ═══════════════════════════════════════════════════════════════
  // PHASE 1: GATHER & PREPARE
  // ═══════════════════════════════════════════════════════════════

  // 1. Collect all sale items from cart
  final cartItems = [
    SaleItem(
      productId: 'turkish_coffee_001',
      productName: 'Turkish Coffee',
      quantity: 2,
      size: SizeVariant.medium,
      sugarLevel: SugarLevel.normal,
      unitPrice: Money(3.50),
      totalPrice: Money(7.00),
    ),
    SaleItem(
      productId: 'orange_juice_001',
      productName: 'Orange Juice',
      quantity: 1,
      size: SizeVariant.large,
      customizations: {'extra_syrup': 1.5}, // 50% more syrup
      unitPrice: Money(5.00),
      totalPrice: Money(5.00),
    ),
  ];

  // ═══════════════════════════════════════════════════════════════
  // PHASE 2: VALIDATION (Multi-layer)
  // ═══════════════════════════════════════════════════════════════

  // 2. Run comprehensive validation
  final validationResult = await validateSaleUseCase.validate(
    items: cartItems,
    skipStockCheck: false,
  );

  if (!validationResult.isValid) {
    // Handle validation errors
    for (final error in validationResult.errors!) {
      log('Validation Error [${error.layer}]: ${error.error.message}');
    }
    throw SaleValidationException(validationResult.errors!);
  }

  // ═══════════════════════════════════════════════════════════════
  // PHASE 3: STOCK LOCKING (Concurrency Safety)
  // ═══════════════════════════════════════════════════════════════

  // 3. Determine all inventory items needed
  final requiredInventoryIds = <String>{};
  for (final item in cartItems) {
    final recipe = await recipeRepo.getByProductId(item.productId);
    for (final ingredient in recipe!.ingredients) {
      requiredInventoryIds.add(ingredient.inventoryItemId);
    }
  }
  // Result: {'coffee_beans_001', 'sugar_001', 'water_001', 'juice_syrup_001', 'cups_001'}

  // 4. Acquire distributed locks
  final lock = await lockManager.acquireLocks(requiredInventoryIds);
  log('Acquired locks for ${lock.inventoryItemIds.length} items');

  try {
    // ═════════════════════════════════════════════════════════════
    // PHASE 4: STOCK VALIDATION (Double-check after locking)
    // ═════════════════════════════════════════════════════════════

    // 5. Re-verify stock availability (prevent race conditions)
    final stockCheck = await stockValidator.validateStockForItems(cartItems);
    if (!stockCheck.isAvailable) {
      throw InsufficientStockException(
        details: stockCheck.failures!,
      );
    }

    // ═════════════════════════════════════════════════════════════
    // PHASE 5: CALCULATE CONSUMPTION
    // ═════════════════════════════════════════════════════════════

    // 6. Calculate precise consumption requirements
    final consumptionPlan = <String, ConsumptionDetail>{};

    for (final saleItem in cartItems) {
      final recipe = await recipeRepo.getByProductId(saleItem.productId);

      // Apply size multiplier
      final scaledIngredients = recipe!.getScaledIngredients(saleItem.size);

      // Apply customizations (sugar level, etc.)
      for (final ingredient in scaledIngredients) {
        var quantity = ingredient.quantityRequiredPerUnit * saleItem.quantity;

        // Apply sugar multiplier if this is sugar
        if (ingredient.inventoryItemId == 'sugar_001' && saleItem.sugarLevel != null) {
          quantity *= saleItem.sugarLevel!.multiplier;
        }

        // Apply custom modifications
        saleItem.customizations?.forEach((key, value) {
          if (ingredient.inventoryItemId == key && value is double) {
            quantity *= value;
          }
        });

        // Aggregate by inventory item
        final existing = consumptionPlan[ingredient.inventoryItemId];
        if (existing != null) {
          consumptionPlan[ingredient.inventoryItemId] = existing.copyWith(
            quantityRequired: existing.quantityRequired + quantity,
          );
        } else {
          final inventoryItem = await inventoryRepo.getById(ingredient.inventoryItemId);
          consumptionPlan[ingredient.inventoryItemId] = ConsumptionDetail(
            inventoryItemId: ingredient.inventoryItemId,
            itemName: inventoryItem!.name,
            unit: inventoryItem.unit,
            quantityRequired: quantity,
            costPerUnit: inventoryItem.costPerUnit,
          );
        }
      }
    }

    // Consumption Plan Summary:
    // coffee_beans_001: 16g (8g × 2 medium coffees)
    // sugar_001: 20g (10g × 2 × 1.0 normal sugar)
    // water_001: 200ml (100ml × 2)
    // juice_syrup_001: 58.5ml (30ml × 1.3 large × 1.5 extra syrup)
    // water_001: 150ml (150ml × 1 large)
    // cups_001: 3 pieces

    // ═════════════════════════════════════════════════════════════
    // PHASE 6: ATOMIC DEDUCTION
    // ═════════════════════════════════════════════════════════════

    // 7. Execute atomic inventory deduction
    await inventoryRepo.runInTransaction(() async {
      for (final entry in consumptionPlan.entries) {
        final item = await inventoryRepo.getById(entry.key);
        final newQuantity = item!.currentQuantity - entry.value.quantityRequired;

        // Critical: Prevent negative stock
        if (newQuantity < 0) {
          throw InsufficientStockException(
            inventoryItemId: entry.key,
            required: entry.value.quantityRequired,
            available: item.currentQuantity,
          );
        }

        // Update with new status
        await inventoryRepo.update(item.copyWith(
          currentQuantity: newQuantity,
          lastUpdated: DateTime.now(),
          status: newQuantity <= item.minimumThreshold
              ? InventoryStatus.lowStock
              : InventoryStatus.normal,
        ));
      }
    });

    // ═════════════════════════════════════════════════════════════
    // PHASE 7: LOG & COMPLETE
    // ═════════════════════════════════════════════════════════════

    // 8. Create transaction record
    final transaction = SaleTransaction(
      id: generateTransactionId(),
      items: cartItems,
      timestamp: DateTime.now(),
      totalAmount: cartItems.fold(
        Money(0),
        (sum, item) => sum + item.totalPrice,
      ),
      cashierId: currentUser.id,
      status: SaleStatus.completed,
    );

    // 9. Create consumption log
    final consumptionLog = InventoryConsumptionLog(
      id: generateLogId(),
      saleTransactionId: transaction.id,
      ingredientsConsumed: consumptionPlan.values.map((d) => ConsumedIngredient(
        inventoryItemId: d.inventoryItemId,
        inventoryItemName: d.itemName,
        quantityConsumed: d.quantityRequired,
        unit: d.unit,
        costPerUnit: d.costPerUnit,
        totalCost: d.costPerUnit != null
            ? d.costPerUnit! * d.quantityRequired
            : null,
      )).toList(),
      timestamp: DateTime.now(),
      totalCostOfIngredients: Money(
        consumptionPlan.values.fold(
          0,
          (sum, d) => sum + (d.costPerUnit ?? 0) * d.quantityRequired,
        ),
      ),
    );

    // 10. Persist records
    await Future.wait([
      saleRepo.save(transaction),
      consumptionLogRepo.save(consumptionLog),
    ]);

    // 11. Emit success event
    eventBus.emit(InventoryConsumedEvent(
      saleTransactionId: transaction.id,
      consumedIngredients: consumptionLog.ingredientsConsumed,
    ));

    // ═════════════════════════════════════════════════════════════
    // PHASE 8: POST-SALE ACTIONS
    // ═════════════════════════════════════════════════════════════

    // 12. Check for low stock and notify
    final potentiallyLowStock = consumptionPlan.keys.toList();
    final lowStockItems = await checkLowStockUseCase.checkItemsAfterConsumption(
      potentiallyLowStock,
    );

    if (lowStockItems.isNotEmpty) {
      eventBus.emit(LowStockDetectedEvent(lowStockItems));

      // Send notifications
      for (final item in lowStockItems) {
        await notificationService.sendLowStockAlert(
          itemId: item.id,
          itemName: item.name,
          currentLevel: item.currentQuantity,
          threshold: item.minimumThreshold,
        );
      }
    }

    log('✓ Sale transaction completed successfully');
    log('  Transaction ID: ${transaction.id}');
    log('  Total: ${transaction.totalAmount}');
    log('  Items consumed: ${consumptionLog.ingredientsConsumed.length}');

    return SaleResult.success(
      transaction: transaction,
      consumptionLog: consumptionLog,
      lowStockAlerts: lowStockItems,
    );

  } finally {
    // ═════════════════════════════════════════════════════════════
    // CLEANUP: Always release locks
    // ═════════════════════════════════════════════════════════════
    await lockManager.releaseLocks(lock);
    log('Released locks for transaction');
  }
}
```

---

# 6. EDGE CASE HANDLING

## 6.1 Edge Cases Matrix

| Edge Case | Scenario | Handling Strategy | Implementation |
|-----------|----------|-------------------|----------------|
| **Concurrent Sales** | Two cashiers sell same item simultaneously | Distributed locking with timeout | `TransactionLockManager` |
| **Partial Stock** | Enough for item A, not for item B in same sale | All-or-nothing transaction | Atomic DB transaction with rollback |
| **Zero Stock** | Inventory shows 0 but sale attempted | Pre-validation rejection | `canFulfill()` check before lock |
| **Decimal Precision** | 100ml juice ÷ 3 sales = 33.333... | Fixed decimal precision (2-4 places) | Use `Decimal` type or `double` with rounding |
| **Unit Conversion** | Recipe uses 'ml' but inventory in 'liters' | Unit conversion layer | `MeasurementUnit` with conversion factors |
| **Recipe Change Mid-sale** | Recipe updated while sale in progress | Immutable recipe versions | Versioned recipes with effective dates |
| **Negative Adjustment** | Return/refund scenario | Reverse consumption | Separate `ProcessReturnUseCase` |
| **Network/DB Failure** | Crash during transaction | Atomic operations + retry logic | Transaction wrapper with idempotency |
| **Expired Inventory** | Ingredient past expiration | Pre-sale validation flag | `expiryDate` field with validation |
| **Bulk Sale** | 1000+ items in single sale | Batch processing with progress | Chunked processing with progress Cubit |

## 6.2 Edge Case Implementation Examples

```dart
// lib/domain/core/utils/decimal_precision.dart

class PrecisionUtils {
  static const int DEFAULT_PRECISION = 2;

  /// Round to specified decimal places
  static double round(double value, {int places = DEFAULT_PRECISION}) {
    final mod = pow(10.0, places);
    return (value * mod).round() / mod;
  }

  /// Ensure non-negative with precision
  static double ensureNonNegative(double value) {
    return max(0, round(value));
  }

  /// Safe subtraction with precision
  static double subtract(double from, double amount) {
    return ensureNonNegative(round(from - amount));
  }
}

// lib/domain/core/utils/unit_converter.dart

class UnitConverter {
  static double convert(double value, MeasurementUnit from, MeasurementUnit to) {
    if (from == to) return value;

    // Convert to base unit first
    final inBase = _toBaseUnit(value, from);
    // Then to target unit
    return _fromBaseUnit(inBase, to);
  }

  static double _toBaseUnit(double value, MeasurementUnit unit) {
    switch (unit) {
      case MeasurementUnit.gram:
        return value; // base
      case MeasurementUnit.kilogram:
        return value * 1000;
      case MeasurementUnit.milliliter:
        return value; // base
      case MeasurementUnit.liter:
        return value * 1000;
      case MeasurementUnit.piece:
        return value; // no conversion
    }
  }

  static double _fromBaseUnit(double value, MeasurementUnit unit) {
    switch (unit) {
      case MeasurementUnit.gram:
        return value;
      case MeasurementUnit.kilogram:
        return value / 1000;
      case MeasurementUnit.milliliter:
        return value;
      case MeasurementUnit.liter:
        return value / 1000;
      case MeasurementUnit.piece:
        return value;
    }
  }
}

// lib/domain/consumption/usecases/process_return_usecase.dart

class ProcessReturnUseCase {
  final InventoryRepository _inventoryRepo;
  final ConsumptionLogRepository _logRepo;

  ProcessReturnUseCase({
    required InventoryRepository inventoryRepo,
    required ConsumptionLogRepository logRepo,
  })  : _inventoryRepo = inventoryRepo,
        _logRepo = logRepo;

  /// Reverse inventory consumption for a return
  Future<Result<InventoryReturnLog>> execute({
    required String originalTransactionId,
    required List<ReturnItem> itemsToReturn,
    String? reason,
  }) async {
    try {
      // 1. Find original consumption log
      final originalLog = await _logRepo.getByTransactionId(originalTransactionId);
      if (originalLog == null) {
        return Failure(TransactionNotFoundException(originalTransactionId));
      }

      // 2. Validate return quantities don't exceed original
      for (final returnItem in itemsToReturn) {
        final originalQuantity = originalLog.ingredientsConsumed
            .where((i) => i.inventoryItemId == returnItem.inventoryItemId)
            .fold<double>(0, (sum, i) => sum + i.quantityConsumed);

        if (returnItem.quantity > originalQuantity) {
          return Failure(InvalidReturnQuantityException(
            inventoryItemId: returnItem.inventoryItemId,
            requested: returnItem.quantity,
            available: originalQuantity,
          ));
        }
      }

      // 3. Restore inventory atomically
      await _inventoryRepo.runInTransaction(() async {
        for (final returnItem in itemsToReturn) {
          final inventoryItem = await _inventoryRepo.getById(returnItem.inventoryItemId);
          if (inventoryItem == null) continue;

          final restoredQuantity = inventoryItem.currentQuantity + returnItem.quantity;

          await _inventoryRepo.update(inventoryItem.copyWith(
            currentQuantity: restoredQuantity,
            lastUpdated: DateTime.now(),
            status: restoredQuantity > inventoryItem.minimumThreshold
                ? InventoryStatus.normal
                : inventoryItem.status,
          ));
        }
      });

      // 4. Create return log
      final returnLog = InventoryReturnLog(
        id: generateId(),
        originalTransactionId: originalTransactionId,
        returnedItems: itemsToReturn,
        reason: reason,
        timestamp: DateTime.now(),
      );

      return Success(returnLog);
    } catch (e) {
      return Failure(DomainException('Return processing failed: $e'));
    }
  }
}

// lib/domain/consumption/utils/concurrent_transaction_handler.dart

class ConcurrentTransactionHandler {
  final TransactionLockManager _lockManager;
  static const int MAX_RETRIES = 3;
  static const Duration RETRY_DELAY = Duration(milliseconds: 100);

  ConcurrentTransactionHandler(this._lockManager);

  /// Execute operation with automatic retry on concurrent modification
  Future<T> executeWithRetry<T>({
    required Set<String> resourceIds,
    required Future<T> Function() operation,
  }) async {
    int attempts = 0;

    while (attempts < MAX_RETRIES) {
      attempts++;
      TransactionLock? lock;

      try {
        // Try to acquire locks
        lock = await _lockManager.acquireLocks(resourceIds);

        // Execute operation
        return await operation();
      } on ConcurrentModificationException {
        if (attempts >= MAX_RETRIES) {
          throw const ConcurrentModificationException();
        }
        // Wait before retry with exponential backoff
        await Future.delayed(RETRY_DELAY * attempts);
      } finally {
        if (lock != null) {
          await _lockManager.releaseLocks(lock);
        }
      }
    }

    throw const ConcurrentModificationException();
  }
}

// lib/presentation/core/widgets/bulk_sale_progress.dart

class BulkSaleProgressCubit extends Cubit<BulkSaleState> {
  BulkSaleProgressCubit() : super(const BulkSaleState());

  Future<void> processBulkSale(List<SaleItem> items) async {
    const batchSize = 50;
    final batches = _chunk(items, batchSize);

    emit(BulkSaleState(
      totalItems: items.length,
      processedItems: 0,
      status: BulkSaleStatus.processing,
    ));

    final results = <SaleResult>[];
    final failedItems = <SaleItem>[];

    for (var i = 0; i < batches.length; i++) {
      try {
        final result = await _processBatch(batches[i]);
        results.add(result);

        emit(state.copyWith(
          processedItems: (i + 1) * batchSize,
          currentBatch: i + 1,
          totalBatches: batches.length,
        ));
      } catch (e) {
        failedItems.addAll(batches[i]);
      }

      // Small delay to allow UI updates
      await Future.delayed(const Duration(milliseconds: 16));
    }

    emit(BulkSaleState(
      totalItems: items.length,
      processedItems: items.length - failedItems.length,
      failedItems: failedItems.isEmpty ? null : failedItems,
      status: failedItems.isEmpty ? BulkSaleStatus.completed : BulkSaleStatus.partial,
    ));
  }

  List<List<SaleItem>> _chunk(List<SaleItem> list, int size) {
    return List.generate(
      (list.length / size).ceil(),
      (i) => list.sublist(
        i * size,
        (i + 1) * size > list.length ? list.length : (i + 1) * size,
      ),
    );
  }
}
```

## 6.3 Error Recovery Flow

```dart
// lib/domain/core/recovery/transaction_recovery.dart

class TransactionRecovery {
  final InventoryRepository _inventoryRepo;
  final ConsumptionLogRepository _logRepo;

  /// Attempt to recover from a failed transaction
  Future<RecoveryResult> attemptRecovery(String transactionId) async {
    // 1. Check if transaction exists
    final log = await _logRepo.getByTransactionId(transactionId);
    if (log == null) {
      // Transaction never completed - safe to retry
      return RecoveryResult.canRetry();
    }

    // 2. Verify inventory state consistency
    final inconsistencies = <InventoryInconsistency>[];

    for (final consumed in log.ingredientsConsumed) {
      final current = await _inventoryRepo.getById(consumed.inventoryItemId);
      if (current == null) continue;

      // Check if consumption was actually applied
      final expectedMin = consumed.quantityConsumed * 0.9; // Allow 10% tolerance
      // This requires historical data - simplified check
    }

    if (inconsistencies.isEmpty) {
      return RecoveryResult.alreadyConsistent();
    }

    // 3. Attempt to fix inconsistencies
    return await _reconcile(inconsistencies);
  }
}
```

---

# 7. FUTURE SCALABILITY PLAN

## 7.1 Scalability Roadmap

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        SCALABILITY ROADMAP                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  PHASE 1: Single Store (Current)                                            │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ • SQLite/Hive local database                                       │   │
│  │ • In-memory locking                                                │   │
│  │ • Single device operation                                          │   │
│  │ • Local backup to cloud                                            │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  PHASE 2: Multi-Terminal (3-6 months)                                       │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ • Centralized database (PostgreSQL/Firebase)                       │   │
│  │ • Redis for distributed locking                                    │   │
│  │ • Real-time sync between terminals                               │   │
│  │ • Conflict resolution for offline sales                            │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  PHASE 3: Multi-Store (6-12 months)                                         │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ • Store-level inventory with central warehouse                    │   │
│  │ • Inter-store stock transfers                                      │   │
│  │ • Centralized recipe management                                    │   │
│  │ • Cross-store reporting                                            │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  PHASE 4: Enterprise (12-24 months)                                         │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │ • Microservices architecture                                 │   │   │
│  │  │ • Kubernetes orchestration                                   │   │   │
│  │  │ • Event sourcing for inventory events                        │   │   │
│  │  │ • ML-based demand forecasting                                │   │   │
│  │  │ • Supplier integration (auto-ordering)                       │   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 7.2 Scalability Patterns

```dart
// lib/infrastructure/scalability/event_sourcing.dart

/// Event Sourcing for inventory changes
abstract class InventoryEvent {
  final String eventId;
  final String inventoryItemId;
  final DateTime timestamp;
  final int version;

  InventoryEvent({
    required this.eventId,
    required this.inventoryItemId,
    required this.timestamp,
    required this.version,
  });
}

class StockReceivedEvent implements InventoryEvent {
  final double quantityReceived;
  final double unitCost;
  final String? supplierId;

  @override
  final String eventId;
  @override
  final String inventoryItemId;
  @override
  final DateTime timestamp;
  @override
  final int version;

  StockReceivedEvent({
    required this.eventId,
    required this.inventoryItemId,
    required this.timestamp,
    required this.version,
    required this.quantityReceived,
    required this.unitCost,
    this.supplierId,
  });
}

class StockConsumedEvent implements InventoryEvent {
  final double quantityConsumed;
  final String saleTransactionId;
  final String? recipeId;

  @override
  final String eventId;
  @override
  final String inventoryItemId;
  @override
  final DateTime timestamp;
  @override
  final int version;

  StockConsumedEvent({
    required this.eventId,
    required this.inventoryItemId,
    required this.timestamp,
    required this.version,
    required this.quantityConsumed,
    required this.saleTransactionId,
    this.recipeId,
  });
}

class EventSourcedInventoryRepository {
  final EventStore _eventStore;
  final SnapshotStore _snapshotStore;

  /// Rebuild current state from events
  Future<InventoryItem> getCurrentState(String inventoryItemId) async {
    // 1. Try to get snapshot
    var snapshot = await _snapshotStore.getLatest(inventoryItemId);
    var startVersion = snapshot?.version ?? 0;

    // 2. Get events after snapshot
    final events = await _eventStore.getEvents(
      inventoryItemId: inventoryItemId,
      afterVersion: startVersion,
    );

    // 3. Apply events to rebuild state
    var current = snapshot?.state;
    for (final event in events) {
      current = _applyEvent(current, event);
    }

    return current!;
  }

  /// Apply event to state
  InventoryItem? _applyEvent(InventoryItem? current, InventoryEvent event) {
    if (event is StockReceivedEvent) {
      return (current ?? InventoryItem.initial(event.inventoryItemId)).copyWith(
        currentQuantity: (current?.currentQuantity ?? 0) + event.quantityReceived,
        lastUpdated: event.timestamp,
      );
    }

    if (event is StockConsumedEvent) {
      return current!.copyWith(
        currentQuantity: current.currentQuantity - event.quantityConsumed,
        lastUpdated: event.timestamp,
      );
    }

    return current;
  }
}

// lib/infrastructure/scalability/cqrs.dart

/// CQRS Pattern: Separate read and write models

// Write Model (Command Side)
class InventoryCommandHandler {
  final EventStore _eventStore;

  Future<void> handleReceiveStock(ReceiveStockCommand command) async {
    final currentVersion = await _eventStore.getLatestVersion(command.inventoryItemId);

    final event = StockReceivedEvent(
      eventId: generateId(),
      inventoryItemId: command.inventoryItemId,
      timestamp: DateTime.now(),
      version: currentVersion + 1,
      quantityReceived: command.quantity,
      unitCost: command.unitCost,
    );

    await _eventStore.append(event);
  }
}

// Read Model (Query Side) - Optimized for reads
class InventoryQueryHandler {
  final ReadModelDatabase _readDb;

  Future<InventoryReadModel> getCurrentStock(String inventoryItemId) async {
    // Direct DB query - no event replay needed
    return await _readDb.inventoryItems.getById(inventoryItemId);
  }

  Future<List<LowStockAlert>> getLowStockAlerts() async {
    return await _readDb.inventoryItems
        .where((i) => i.currentQuantity <= i.minimumThreshold)
        .toList();
  }
}

// Projection: Updates read model from events
class InventoryProjection {
  final ReadModelDatabase _readDb;

  void project(InventoryEvent event) async {
    if (event is StockReceivedEvent) {
      await _readDb.inventoryItems.updateQuantity(
        event.inventoryItemId,
        delta: event.quantityReceived,
      );
    }

    if (event is StockConsumedEvent) {
      await _readDb.inventoryItems.updateQuantity(
        event.inventoryItemId,
        delta: -event.quantityConsumed,
      );

      // Update projections
      await _readDb.consumptionStats.increment(
        itemId: event.inventoryItemId,
        date: DateTime.now(),
        quantity: event.quantityConsumed,
      );
    }
  }
}
```

## 7.3 Multi-Store Architecture

```dart
// lib/domain/multi_store/entities/store.dart
class Store {
  final String id;
  final String name;
  final String? warehouseId; // Link to central warehouse
  final StoreType type;
  final Map<String, double> localStockLevels;

  const Store({
    required this.id,
    required this.name,
    this.warehouseId,
    required this.type,
    this.localStockLevels = const {},
  });
}

enum StoreType {
  retail,      // Regular coffee shop
  kiosk,       // Small location
  warehouse,   // Central storage
  mobile,      // Food truck/pop-up
}

// lib/domain/multi_store/usecases/transfer_stock_usecase.dart
class TransferStockUseCase {
  Future<Result<StockTransfer>> execute({
    required String fromStoreId,
    required String toStoreId,
    required List<TransferItem> items,
    required TransferPriority priority,
  }) async {
    // 1. Validate transfer feasibility
    // 2. Reserve stock at source
    // 3. Create transfer record
    // 4. Notify receiving store
    // 5. Track delivery
    // 6. Confirm receipt and update both stores
  }
}
```

---

# 8. DATABASE SCHEMA SUGGESTION

## 8.1 SQLite Schema (Current - Single Store)

```sql
-- ═══════════════════════════════════════════════════════════════════════════
-- CORE TABLES
-- ═══════════════════════════════════════════════════════════════════════════

-- Inventory Items (Raw Materials)
CREATE TABLE inventory_items (
    id              TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    unit            TEXT NOT NULL CHECK (unit IN ('gram', 'milliliter', 'piece', 'liter', 'kilogram')),
    current_quantity REAL NOT NULL DEFAULT 0 CHECK (current_quantity >= 0),
    minimum_threshold REAL NOT NULL DEFAULT 0,
    cost_per_unit   REAL,
    status          TEXT NOT NULL DEFAULT 'normal' CHECK (status IN ('normal', 'low_stock', 'critical', 'out_of_stock')),
    last_updated    INTEGER NOT NULL, -- Unix timestamp
    created_at      INTEGER NOT NULL,
    notes           TEXT,
    version         INTEGER NOT NULL DEFAULT 1  -- Optimistic locking
);

-- Categories for products
CREATE TABLE categories (
    id              TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    description     TEXT,
    display_order   INTEGER DEFAULT 0,
    is_active       INTEGER NOT NULL DEFAULT 1
);

-- Products (Sellable items)
CREATE TABLE products (
    id              TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    description     TEXT,
    category_id     TEXT NOT NULL REFERENCES categories(id),
    recipe_id       TEXT, -- Optional link to recipe
    is_active       INTEGER NOT NULL DEFAULT 1,
    created_at      INTEGER NOT NULL,
    updated_at      INTEGER NOT NULL
);

-- Product Prices by Size
CREATE TABLE product_prices (
    product_id      TEXT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    size            TEXT NOT NULL CHECK (size IN ('small', 'medium', 'large')),
    price           REAL NOT NULL CHECK (price >= 0),
    currency        TEXT NOT NULL DEFAULT 'USD',
    PRIMARY KEY (product_id, size)
);

-- ═══════════════════════════════════════════════════════════════════════════
-- RECIPE TABLES
-- ═══════════════════════════════════════════════════════════════════════════

-- Recipes
CREATE TABLE recipes (
    id              TEXT PRIMARY KEY,
    product_id      TEXT NOT NULL UNIQUE REFERENCES products(id),
    name            TEXT NOT NULL,
    version         INTEGER NOT NULL DEFAULT 1,
    is_active       INTEGER NOT NULL DEFAULT 1,
    created_at      INTEGER NOT NULL,
    updated_at      INTEGER NOT NULL
);

-- Size multipliers for recipes
CREATE TABLE recipe_size_multipliers (
    recipe_id       TEXT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    size            TEXT NOT NULL CHECK (size IN ('small', 'medium', 'large')),
    multiplier      REAL NOT NULL CHECK (multiplier > 0),
    PRIMARY KEY (recipe_id, size)
);

-- Recipe Ingredients
CREATE TABLE recipe_ingredients (
    id              TEXT PRIMARY KEY,
    recipe_id       TEXT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    inventory_item_id TEXT NOT NULL REFERENCES inventory_items(id),
    quantity_required_per_unit REAL NOT NULL CHECK (quantity_required_per_unit > 0),
    is_optional     INTEGER NOT NULL DEFAULT 0,
    notes           TEXT
);

-- ═══════════════════════════════════════════════════════════════════════════
-- TRANSACTION TABLES
-- ═══════════════════════════════════════════════════════════════════════════

-- Sale Transactions
CREATE TABLE sale_transactions (
    id              TEXT PRIMARY KEY,
    total_amount    REAL NOT NULL,
    currency        TEXT NOT NULL DEFAULT 'USD',
    cashier_id      TEXT NOT NULL,
    customer_id     TEXT,
    status          TEXT NOT NULL CHECK (status IN ('pending', 'validated', 'completed', 'cancelled', 'refunded')),
    timestamp       INTEGER NOT NULL,
    notes           TEXT,
    synced_at       INTEGER  -- For cloud sync tracking
);

-- Sale Items (line items)
CREATE TABLE sale_items (
    id              TEXT PRIMARY KEY,
    transaction_id  TEXT NOT NULL REFERENCES sale_transactions(id) ON DELETE CASCADE,
    product_id      TEXT NOT NULL REFERENCES products(id),
    product_name    TEXT NOT NULL, -- Denormalized for historical accuracy
    quantity        INTEGER NOT NULL CHECK (quantity > 0),
    size            TEXT NOT NULL,
    sugar_level     TEXT CHECK (sugar_level IN ('none', 'low', 'normal', 'extra', 'double')),
    unit_price      REAL NOT NULL,
    total_price     REAL NOT NULL,
    customizations  TEXT  -- JSON string for flexibility
);

-- Inventory Consumption Logs
CREATE TABLE inventory_consumption_logs (
    id              TEXT PRIMARY KEY,
    transaction_id  TEXT NOT NULL UNIQUE REFERENCES sale_transactions(id),
    timestamp       INTEGER NOT NULL,
    total_cost      REAL,
    notes           TEXT
);

-- Consumed Ingredients Detail
CREATE TABLE consumed_ingredients (
    id              TEXT PRIMARY KEY,
    consumption_log_id TEXT NOT NULL REFERENCES inventory_consumption_logs(id) ON DELETE CASCADE,
    inventory_item_id  TEXT NOT NULL REFERENCES inventory_items(id),
    inventory_item_name TEXT NOT NULL, -- Denormalized
    quantity_consumed    REAL NOT NULL,
    unit            TEXT NOT NULL,
    cost_per_unit   REAL,
    total_cost      REAL,
    notes           TEXT
);

-- ═══════════════════════════════════════════════════════════════════════════
-- SUPPORTING TABLES
-- ═══════════════════════════════════════════════════════════════════════════

-- Stock Receive Logs (for tracking purchases/receipts)
CREATE TABLE stock_receive_logs (
    id              TEXT PRIMARY KEY,
    inventory_item_id TEXT NOT NULL REFERENCES inventory_items(id),
    quantity_received REAL NOT NULL,
    unit_cost       REAL,
    supplier_id     TEXT,
    supplier_name   TEXT,
    received_at     INTEGER NOT NULL,
    received_by     TEXT NOT NULL,
    notes           TEXT
);

-- Stock Adjustment Logs (for corrections, waste, etc.)
CREATE TABLE stock_adjustment_logs (
    id              TEXT PRIMARY KEY,
    inventory_item_id TEXT NOT NULL REFERENCES inventory_items(id),
    adjustment_quantity REAL NOT NULL, -- Positive or negative
    reason          TEXT NOT NULL,
    previous_quantity REAL NOT NULL,
    new_quantity    REAL NOT NULL,
    adjusted_at     INTEGER NOT NULL,
    adjusted_by     TEXT NOT NULL,
    notes           TEXT
);

-- ═══════════════════════════════════════════════════════════════════════════
-- INDEXES
-- ═══════════════════════════════════════════════════════════════════════════

CREATE INDEX idx_inventory_status ON inventory_items(status);
CREATE INDEX idx_inventory_low_stock ON inventory_items(current_quantity, minimum_threshold);

CREATE INDEX idx_recipes_product ON recipes(product_id);
CREATE INDEX idx_recipe_ingredients_recipe ON recipe_ingredients(recipe_id);
CREATE INDEX idx_recipe_ingredients_item ON recipe_ingredients(inventory_item_id);

CREATE INDEX idx_sale_transactions_timestamp ON sale_transactions(timestamp);
CREATE INDEX idx_sale_transactions_status ON sale_transactions(status);
CREATE INDEX idx_sale_items_transaction ON sale_items(transaction_id);

CREATE INDEX idx_consumption_logs_transaction ON inventory_consumption_logs(transaction_id);
CREATE INDEX idx_consumption_logs_timestamp ON inventory_consumption_logs(timestamp);
CREATE INDEX idx_consumed_ingredients_log ON consumed_ingredients(consumption_log_id);
CREATE INDEX idx_consumed_ingredients_item ON consumed_ingredients(inventory_item_id);

CREATE INDEX idx_stock_logs_item ON stock_receive_logs(inventory_item_id);
CREATE INDEX idx_stock_logs_received ON stock_receive_logs(received_at);

-- ═══════════════════════════════════════════════════════════════════════════
-- VIEWS (for common queries)
-- ═══════════════════════════════════════════════════════════════════════════

-- Current inventory status view
CREATE VIEW inventory_status AS
SELECT
    id,
    name,
    unit,
    current_quantity,
    minimum_threshold,
    cost_per_unit,
    CASE
        WHEN current_quantity <= 0 THEN 'out_of_stock'
        WHEN current_quantity <= minimum_threshold * 0.5 THEN 'critical'
        WHEN current_quantity <= minimum_threshold THEN 'low_stock'
        ELSE 'normal'
    END as calculated_status,
    last_updated
FROM inventory_items;

-- Daily consumption summary
CREATE VIEW daily_consumption AS
SELECT
    date(ci.timestamp, 'unixepoch', 'localtime') as date,
    ci.inventory_item_id,
    ii.name as item_name,
    SUM(ci.quantity_consumed) as total_consumed,
    SUM(ci.total_cost) as total_cost,
    COUNT(DISTINCT ci.consumption_log_id) as transaction_count
FROM consumed_ingredients ci
JOIN inventory_items ii ON ci.inventory_item_id = ii.id
GROUP BY date, ci.inventory_item_id;

-- Product profitability view
CREATE VIEW product_profitability AS
SELECT
    p.id as product_id,
    p.name as product_name,
    si.size,
    COUNT(*) as times_sold,
    SUM(si.total_price) as total_revenue,
    SUM(
        (SELECT SUM(ci.total_cost)
         FROM consumed_ingredients ci
         JOIN inventory_consumption_logs icl ON ci.consumption_log_id = icl.id
         WHERE icl.transaction_id = si.transaction_id
         AND ci.notes LIKE '%' || p.id || '%') -- Link via notes or add product_id to consumed_ingredients
    ) as estimated_cost
FROM products p
JOIN sale_items si ON p.id = si.product_id
GROUP BY p.id, si.size;
```

## 8.2 NoSQL Schema (Firebase/Future Scale)

```javascript
// Firebase Firestore Schema Structure

// Collection: inventory_items
{
  "coffee_beans_001": {
    name: "Arabica Coffee Beans",
    unit: "gram",
    currentQuantity: 5000,
    minimumThreshold: 1000,
    costPerUnit: 0.05,
    status: "normal",
    lastUpdated: Timestamp,
    metadata: {
      supplier: "Colombian Farms Co.",
      sku: "CF-ARA-001",
      expiryDate: Timestamp
    },
    // Subcollection: stock_movements
    stock_movements: {
      "movement_001": {
        type: "received", // received, consumed, adjusted
        quantity: 10000,
        timestamp: Timestamp,
        reference: "PO-2024-001", // Purchase order or sale transaction
        balanceAfter: 10000
      }
    }
  }
}

// Collection: recipes
{
  "turkish_coffee_recipe": {
    productId: "turkish_coffee_001",
    name: "Turkish Coffee",
    version: 3,
    isActive: true,
    ingredients: [
      {
        inventoryItemId: "coffee_beans_001",
        quantityRequiredPerUnit: 8,
        isOptional: false
      },
      {
        inventoryItemId: "sugar_001",
        quantityRequiredPerUnit: 10,
        isOptional: true
      }
    ],
    sizeMultipliers: {
      small: 0.8,
      medium: 1.0,
      large: 1.3
    },
    createdAt: Timestamp,
    updatedAt: Timestamp
  }
}

// Collection: sales (sharded by date for performance)
// Path: sales/2024-02/sales/{transactionId}
{
  "txn_123456": {
    items: [
      {
        productId: "turkish_coffee_001",
        productName: "Turkish Coffee",
        quantity: 2,
        size: "medium",
        sugarLevel: "normal",
        unitPrice: 3.50,
        totalPrice: 7.00,
        consumedIngredients: [
          { itemId: "coffee_beans_001", quantity: 16, unitCost: 0.80 },
          { itemId: "sugar_001", quantity: 20, unitCost: 0.20 }
        ]
      }
    ],
    totalAmount: 7.00,
    cashierId: "cashier_001",
    customerId: null,
    status: "completed",
    timestamp: Timestamp,
    consumptionLog: {
      totalIngredientCost: 1.00,
      margin: 6.00
    }
  }
}

// Collection: consumption_analytics (aggregated data)
{
  "daily_2024_02_25": {
    date: "2024-02-25",
    storeId: "store_001",
    totalSales: 150,
    totalRevenue: 450.00,
    ingredientCosts: 120.00,
    consumptionByItem: {
      "coffee_beans_001": { quantity: 1200, cost: 60.00 },
      "sugar_001": { quantity: 1500, cost: 15.00 }
    }
  }
}

// Real-time listeners for multi-terminal sync
// Terminal A:
//   - Listen to: inventory_items/{itemId} for stock updates
//   - Listen to: sales/{date}/sales for new transactions
//   - Update local cache on change

// Security Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Only allow inventory updates through Cloud Functions (for atomicity)
    match /inventory_items/{itemId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin() || isCloudFunction();
    }

    // Sales can be created by cashiers
    match /sales/{date}/sales/{transactionId} {
      allow create: if isCashier() && validTransaction(request.resource);
      allow read: if isAuthenticated();
      allow update: if isAdmin();
    }
  }
}
```

## 8.3 Data Migration Strategy

```dart
// lib/infrastructure/migration/data_migration.dart

class DataMigration {
  /// Migration from SQLite to Firebase
  Future<void> migrateToFirebase() async {
    final sqlite = await _getSQLiteDb();
    final firebase = FirebaseFirestore.instance;

    // 1. Migrate inventory items
    final inventoryItems = await sqlite.query('inventory_items');
    final batch = firebase.batch();

    for (final item in inventoryItems) {
      final docRef = firebase.collection('inventory_items').doc(item['id']);
      batch.set(docRef, _convertInventoryItem(item));
    }

    await batch.commit();

    // 2. Migrate recipes
    // ... similar pattern

    // 3. Historical sales (in chunks)
    await _migrateSalesInChunks(sqlite, firebase);
  }

  Future<void> _migrateSalesInChunks(
    Database sqlite,
    FirebaseFirestore firebase,
  ) async {
    const chunkSize = 500;
    int offset = 0;

    while (true) {
      final sales = await sqlite.query(
        'sale_transactions',
        limit: chunkSize,
        offset: offset,
        orderBy: 'timestamp',
      );

      if (sales.isEmpty) break;

      await _uploadSalesChunk(sales, firebase);
      offset += chunkSize;

      // Progress indicator
      emit(MigrationProgress(
        processedSales: offset,
        totalSales: await _getTotalSalesCount(sqlite),
      ));
    }
  }
}
```

---

## Summary

This architecture provides:

- **Clean Separation**: Domain, UseCase, and Presentation layers are clearly separated
- **Scalability**: Ready for single-store to multi-store expansion
- **Testability**: All business logic is isolated in UseCases
- **Concurrency Safety**: Distributed locking and atomic transactions
- **Extensibility**: Easy to add new features (modifiers, bundles, promotions)
- **Data Integrity**: Event sourcing and CQRS patterns for large-scale deployments

The system handles complex scenarios like sugar level adjustments, size variations, concurrent sales, and returns while maintaining data consistency and providing clear audit trails.

Key files to create:
- `lib/domain/` - Entities, repositories, usecases
- `lib/presentation/cubits/` - State management
- `lib/data/repositories/` - Data layer implementations
- `lib/infrastructure/database/` - Schema and migrations
