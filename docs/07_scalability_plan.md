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

  Future<InventoryItem> getCurrentState(String inventoryItemId) async {
    var snapshot = await _snapshotStore.getLatest(inventoryItemId);
    var startVersion = snapshot?.version ?? 0;

    final events = await _eventStore.getEvents(
      inventoryItemId: inventoryItemId,
      afterVersion: startVersion,
    );

    var current = snapshot?.state;
    for (final event in events) {
      current = _applyEvent(current, event);
    }

    return current!;
  }

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

class InventoryQueryHandler {
  final ReadModelDatabase _readDb;

  Future<InventoryReadModel> getCurrentStock(String inventoryItemId) async {
    return await _readDb.inventoryItems.getById(inventoryItemId);
  }

  Future<List<LowStockAlert>> getLowStockAlerts() async {
    return await _readDb.inventoryItems
        .where((i) => i.currentQuantity <= i.minimumThreshold)
        .toList();
  }
}

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
  final String? warehouseId;
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
  retail,
  kiosk,
  warehouse,
  mobile,
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
