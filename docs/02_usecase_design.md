# 2. USECASE DESIGN

## 2.1 Main Consumption UseCase

```dart
// lib/domain/consumption/usecases/process_sale_consumption_usecase.dart

abstract class ProcessSaleConsumptionUseCase {
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

    if (item.sugarLevel != null) {
      modifications['sugar'] = item.sugarLevel!.multiplier;
    }

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

## 2.2 Supporting UseCases

```dart
// lib/domain/consumption/usecases/check_stock_availability_usecase.dart
abstract class CheckStockAvailabilityUseCase {
  Future<StockAvailabilityResult> checkAvailability({
    required String productId,
    required int quantity,
    required SizeVariant size,
    Map<String, dynamic>? customizations,
  });
}

// lib/domain/consumption/usecases/forecast_consumption_usecase.dart
abstract class ForecastConsumptionUseCase {
  Future<ConsumptionForecast> forecast({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? inventoryItemIds,
  });
}

// lib/domain/inventory/usecases/check_low_stock_usecase.dart
abstract class CheckLowStockUseCase {
  Future<List<InventoryItem>> getLowStockItems();
  Future<List<InventoryItem>> checkItemsAfterConsumption(List<String> inventoryItemIds);
}

// lib/domain/inventory/usecases/receive_stock_usecase.dart
abstract class ReceiveStockUseCase {
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
  Future<void> runInTransaction(Future<void> Function() operations);
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
  Future<TransactionLock> acquireLocks(Set<String> inventoryItemIds);
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
