import 'dart:async';

import 'package:coffee_app/features/inventory/domain/entities/inventory_item.dart';
import 'package:coffee_app/features/inventory/domain/entities/stock_movement.dart';

/// Base class for domain events
abstract class DomainEvent {
  final DateTime timestamp;

  DomainEvent() : timestamp = DateTime.now();
}

/// Event fired when inventory is consumed
class InventoryConsumedEvent extends DomainEvent {
  final String saleTransactionId;
  final List<StockMovement> consumedIngredients;

  InventoryConsumedEvent({
    required this.saleTransactionId,
    required this.consumedIngredients,
  });
}

/// Event fired when low stock is detected
class LowStockDetectedEvent extends DomainEvent {
  final List<InventoryItem> lowStockItems;

  LowStockDetectedEvent(this.lowStockItems);
}

/// Event fired when stock is received
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

/// Event fired when a sale is completed
class SaleCompletedEvent extends DomainEvent {
  final String transactionId;
  final double totalAmount;

  SaleCompletedEvent({
    required this.transactionId,
    required this.totalAmount,
  });
}

/// Simple event bus for cross-cubit communication
class DomainEventBus {
  final _controller = StreamController<DomainEvent>.broadcast();

  /// Stream of all events
  Stream<DomainEvent> get events => _controller.stream;

  /// Get stream of specific event type
  Stream<T> on<T extends DomainEvent>() {
    return _controller.stream.where((event) => event is T).cast<T>();
  }

  /// Emit an event
  void emit(DomainEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  /// Close the event bus
  void dispose() {
    _controller.close();
  }
}
