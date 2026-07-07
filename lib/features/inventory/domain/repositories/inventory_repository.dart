import 'package:coffee_app/features/inventory/domain/entities/inventory_item.dart';
import 'package:coffee_app/features/inventory/domain/entities/stock_movement.dart';

abstract class InventoryRepository {
  Stream<List<InventoryItem>> watchInventory();
  Future<List<InventoryItem>> getInventory();
  Future<InventoryItem?> getItemById(String id);
  Future<void> addItem(InventoryItem item);
  Future<void> updateItem(InventoryItem item);
  Future<void> deleteItem(String id);

  Stream<List<StockMovement>> watchMovements();
  Future<List<StockMovement>> getMovements();
  Future<void> addMovement(StockMovement movement);

  Future<void> initMockDataIfEmpty();
  Future<void> resetDatabase();

  List<InventoryItem> get currentInventory;
  List<StockMovement> get currentMovements;
}
