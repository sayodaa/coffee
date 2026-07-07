
import 'package:coffee_app/features/inventory/data/models/inventory_item_model.dart';
import 'package:coffee_app/features/inventory/data/models/stock_movement_model.dart';
import 'package:coffee_app/features/inventory/domain/entities/inventory_item.dart';
import 'package:coffee_app/features/inventory/domain/entities/stock_movement.dart';
import 'package:coffee_app/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveInventoryRepository implements InventoryRepository {
  static const String _inventoryBoxName = 'inventory_v2';
  static const String _movementsBoxName = 'movements_v2';

  late Box<InventoryItemModel> _inventoryBox;
  late Box<StockMovementModel> _movementsBox;

  HiveInventoryRepository() {
    _inventoryBox = Hive.box<InventoryItemModel>(_inventoryBoxName);
    _movementsBox = Hive.box<StockMovementModel>(_movementsBoxName);
  }

  @override
  Stream<List<InventoryItem>> watchInventory() {
    // Yield initial data, then listen to changes
    return Stream.value(_inventoryBox.values.map((e) => e.toEntity()).toList()).asyncExpand((initial) {
      return _inventoryBox
          .watch()
          .map((event) => _inventoryBox.values.map((e) => e.toEntity()).toList());
    });
  }

  @override
  Future<List<InventoryItem>> getInventory() async {
    return _inventoryBox.values.map((e) => e.toEntity()).toList();
  }

  @override
  Future<InventoryItem?> getItemById(String id) async {
    try {
      final model = _inventoryBox.values.firstWhere((item) => item.id == id);
      return model.toEntity();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> addItem(InventoryItem item) async {
    final model = InventoryItemModel.fromEntity(item);
    await _inventoryBox.put(item.id, model);
  }

  @override
  Future<void> updateItem(InventoryItem item) async {
    final model = InventoryItemModel.fromEntity(item);
    await _inventoryBox.put(item.id, model);
  }

  @override
  Future<void> deleteItem(String id) async {
    await _inventoryBox.delete(id);
  }

  @override
  Stream<List<StockMovement>> watchMovements() {
    return Stream.value(_movementsBox.values.map((e) => e.toEntity()).toList()).asyncExpand((initial) {
      return _movementsBox
          .watch()
          .map((event) => _movementsBox.values.map((e) => e.toEntity()).toList());
    });
  }

  @override
  Future<List<StockMovement>> getMovements() async {
    return _movementsBox.values.map((e) => e.toEntity()).toList();
  }

  @override
  Future<void> addMovement(StockMovement movement) async {
    final model = StockMovementModel.fromEntity(movement);
    await _movementsBox.put(movement.id, model);
  }

  @override
  Future<void> initMockDataIfEmpty() async {
    // Removed demo data seeding as per requirements
  }

  @override
  Future<void> resetDatabase() async {
    await _inventoryBox.clear();
    await _movementsBox.clear();
  }

  @override
  List<InventoryItem> get currentInventory => _inventoryBox.values.map((e) => e.toEntity()).toList();

  @override
  List<StockMovement> get currentMovements => _movementsBox.values.map((e) => e.toEntity()).toList();
}
