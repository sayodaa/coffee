import 'package:coffee_app/features/inventory/domain/entities/inventory_item.dart';

/// Inventory states as discrete types for clearer UI handling.
abstract class InventoryState {
  const InventoryState();
}

class InventoryInitial extends InventoryState {
  const InventoryInitial();
}

class InventoryLoading extends InventoryState {
  const InventoryLoading();
}

class InventoryLoaded extends InventoryState {
  final List<InventoryItem> items;
  const InventoryLoaded(this.items);

  List<InventoryItem> get lowStockItems =>
      items.where((item) => item.isLowStock).toList();
}

class InventoryEmpty extends InventoryState {
  const InventoryEmpty();
}

class InventoryError extends InventoryState {
  final String message;
  const InventoryError(this.message);
}
