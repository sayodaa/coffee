import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:coffee_app/features/inventory/domain/entities/inventory_item.dart';
import 'package:coffee_app/features/inventory/domain/entities/stock_movement.dart';
import 'package:coffee_app/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:coffee_app/features/notifications/presentation/cubit/notification_cubit.dart';

import 'inventory_state.dart';

class InventoryCubit extends Cubit<InventoryState> {
  final InventoryRepository _repository;
  final NotificationCubit _notificationCubit;

  StreamSubscription? _inventorySubscription;
  StreamSubscription? _movementsSubscription;

  List<StockMovement> _movements = [];

  InventoryCubit({
    required InventoryRepository repository,
    required NotificationCubit notificationCubit,
  })  : _repository = repository,
        _notificationCubit = notificationCubit,
        super(const InventoryInitial()) {
    // Eagerly populate from synchronous cache
    final cachedItems = repository.currentInventory;
    _movements = List.from(repository.currentMovements)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (cachedItems.isNotEmpty) {
      emit(InventoryLoaded(List.from(cachedItems)));
      _triggerLowStockNotifications(cachedItems);
    } else {
      // If no cached items, trigger stream loading
      loadInventory();
    }
  }

  // ─── Stream management ───────────────────────────────────────────────────

  /// Call once from the root widget's initState.
  /// Subsequent calls are no-ops (deduplication guard).
  void loadInventory() {
    if (_inventorySubscription != null) return; // already subscribed

    // emit(const InventoryLoading());

    _inventorySubscription = _repository.watchInventory().listen(
      (items) {
        if (items.isEmpty) {
          emit(const InventoryEmpty());
        } else {
          emit(InventoryLoaded(List.from(items)));
        }
        _triggerLowStockNotifications(items);
      },
      onError: (Object e) {
        emit(InventoryError('Failed to load inventory: $e'));
      },
    );

    _movementsSubscription = _repository.watchMovements().listen(
      (movements) {
        _movements = List.from(movements)
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      },
    );
  }

  // ─── CRUD actions ────────────────────────────────────────────────────────

  Future<void> addInventoryItem(InventoryItem item) => _runAction(
        action: () => _repository.addItem(item),
        successMessage: 'Item added',
        errorPrefix: 'Failed to add item',
      );

  Future<void> updateInventoryItem(InventoryItem item) => _runAction(
        action: () => _repository.updateItem(item),
        successMessage: 'Item updated',
        errorPrefix: 'Failed to update item',
      );

  Future<void> deleteInventoryItem(String id) => _runAction(
        action: () => _repository.deleteItem(id),
        successMessage: 'Item deleted',
        errorPrefix: 'Failed to delete item',
      );

  Future<void> refreshInventory() async {
    try {
      emit(const InventoryLoading());
      final items = await _repository.getInventory();
      if (items.isEmpty) {
        emit(const InventoryEmpty());
      } else {
        emit(InventoryLoaded(items));
      }
    } catch (e) {
      emit(InventoryError('Failed to refresh: $e'));
    }
  }

  // ─── Stock adjustment ────────────────────────────────────────────────────

  Future<void> adjustStock(
    String inventoryItemId,
    double amount,
    String? explanation, {
    MovementType type = MovementType.inStock,
  }) async {
    try {
      // Use a loading state while performing adjustment
      emit(const InventoryLoading());

      final item = await _repository.getItemById(inventoryItemId);
      if (item == null) {
        emit(const InventoryError('Item not found for adjustment'));
        return;
      }

      final newQuantity = (item.quantity + amount);
      if (newQuantity < 0) {
        emit(const InventoryError('Insufficient stock for adjustment'));
        return;
      }

      final updatedItem = item.copyWith(quantity: newQuantity);
      await _repository.updateItem(updatedItem);

      final movementType = amount < 0 && type == MovementType.inStock
          ? MovementType.outStock
          : type;

      await _repository.addMovement(StockMovement(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        inventoryItemId: inventoryItemId,
        type: movementType,
        amount: amount,
        timestamp: DateTime.now(),
        note: explanation,
      ));

      // Reload latest inventory snapshot from repository to ensure consistency
      final latest = await _repository.getInventory();
      if (latest.isEmpty) {
        emit(const InventoryEmpty());
      } else {
        emit(InventoryLoaded(latest));
      }
    } catch (e) {
      emit(InventoryError('Failed to adjust stock: $e'));
    }
  }

  // ─── UI helpers ──────────────────────────────────────────────────────────

  /// Call this in the BlocConsumer listener AFTER showing the action snackbar.
  /// Prevents the same success message from re-appearing on the next rebuild.
  void clearActionResult() {
    // No-op with new state model - caller can refresh or react to specific states
    // Keep for API compatibility
    return;
  }

  // ─── Getters ─────────────────────────────────────────────────────────────

  List<StockMovement> get movements => _movements;

  /// Convenience accessor — same as state.items.
  /// Kept for backward compatibility with ReportsCubit.
  List<InventoryItem> get cachedItems {
    final s = state;
    if (s is InventoryLoaded) return s.items;
    return _repository.currentInventory;
  }

  // ─── Private helpers ─────────────────────────────────────────────────────

  Future<void> _runAction({
    required Future<void> Function() action,
    required String successMessage,
    required String errorPrefix,
  }) async {
    try {
      emit(const InventoryLoading());
      await action();

      // Reload inventory snapshot to reflect changes
      final latest = await _repository.getInventory();
      if (latest.isEmpty) {
        emit(const InventoryEmpty());
      } else {
        emit(InventoryLoaded(latest));
      }
    } catch (e) {
      emit(InventoryError('$errorPrefix: $e'));
    }
  }

  void _triggerLowStockNotifications(List<InventoryItem> items) {
    for (final item in items) {
      _notificationCubit.triggerLowStock(item);
    }
  }

  @override
  Future<void> close() {
    _inventorySubscription?.cancel();
    _movementsSubscription?.cancel();
    return super.close();
  }
}
