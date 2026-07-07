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

    final transaction = SaleTransaction(
      id: _generateTransactionId(),
      items: state.currentItems,
      timestamp: DateTime.now(),
      totalAmount: _calculateTotal(),
      cashierId: cashierId,
      customerId: customerId,
    );

    final result = await _consumptionUseCase.execute(
      transaction: transaction,
      items: state.currentItems,
    );

    if (result.isSuccess) {
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
      await loadInventory();
    }

    return result;
  }
}
```

## 3.4 Inter-Cubit Communication Pattern

```dart
// lib/presentation/core/services/domain_event_bus.dart

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

  SalesCubit({
    required ProcessSaleConsumptionUseCase consumptionUseCase,
    required CheckLowStockUseCase lowStockUseCase,
    required DomainEventBus eventBus,
  })  : _consumptionUseCase = consumptionUseCase,
        _lowStockUseCase = lowStockUseCase,
        _eventBus = eventBus,
        super(const SalesState());

  Future<void> completeSale({
    required String cashierId,
    String? customerId,
  }) async {
    // ... validation logic ...

    final result = await _consumptionUseCase.execute(...);

    if (result.isSuccess) {
      _eventBus.emit(InventoryConsumedEvent(
        saleTransactionId: transaction.id,
        consumedIngredients: result.value!.ingredientsConsumed,
      ));

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

  InventoryCubit({
    required InventoryRepository repository,
    required DomainEventBus eventBus,
  })  : _eventBus = eventBus,
        super(const InventoryState()) {
    _subscribeToEvents();
  }

  void _subscribeToEvents() {
    _subscription = _eventBus.on<InventoryConsumedEvent>().listen((event) {
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
