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

  static double round(double value, {int places = DEFAULT_PRECISION}) {
    final mod = pow(10.0, places);
    return (value * mod).round() / mod;
  }

  static double ensureNonNegative(double value) {
    return max(0, round(value));
  }

  static double subtract(double from, double amount) {
    return ensureNonNegative(round(from - amount));
  }
}

// lib/domain/core/utils/unit_converter.dart

class UnitConverter {
  static double convert(double value, MeasurementUnit from, MeasurementUnit to) {
    if (from == to) return value;

    final inBase = _toBaseUnit(value, from);
    return _fromBaseUnit(inBase, to);
  }

  static double _toBaseUnit(double value, MeasurementUnit unit) {
    switch (unit) {
      case MeasurementUnit.gram:
        return value;
      case MeasurementUnit.kilogram:
        return value * 1000;
      case MeasurementUnit.milliliter:
        return value;
      case MeasurementUnit.liter:
        return value * 1000;
      case MeasurementUnit.piece:
        return value;
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

  Future<Result<InventoryReturnLog>> execute({
    required String originalTransactionId,
    required List<ReturnItem> itemsToReturn,
    String? reason,
  }) async {
    try {
      final originalLog = await _logRepo.getByTransactionId(originalTransactionId);
      if (originalLog == null) {
        return Failure(TransactionNotFoundException(originalTransactionId));
      }

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

  Future<T> executeWithRetry<T>({
    required Set<String> resourceIds,
    required Future<T> Function() operation,
  }) async {
    int attempts = 0;

    while (attempts < MAX_RETRIES) {
      attempts++;
      TransactionLock? lock;

      try {
        lock = await _lockManager.acquireLocks(resourceIds);
        return await operation();
      } on ConcurrentModificationException {
        if (attempts >= MAX_RETRIES) {
          throw const ConcurrentModificationException();
        }
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

  Future<RecoveryResult> attemptRecovery(String transactionId) async {
    final log = await _logRepo.getByTransactionId(transactionId);
    if (log == null) {
      return RecoveryResult.canRetry();
    }

    final inconsistencies = <InventoryInconsistency>[];

    for (final consumed in log.ingredientsConsumed) {
      final current = await _inventoryRepo.getById(consumed.inventoryItemId);
      if (current == null) continue;
    }

    if (inconsistencies.isEmpty) {
      return RecoveryResult.alreadyConsistent();
    }

    return await _reconcile(inconsistencies);
  }
}
```
