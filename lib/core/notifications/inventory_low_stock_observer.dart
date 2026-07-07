import 'dart:async';

import 'package:coffee_app/features/inventory/presentation/bloc/inventory_cubit.dart';
import 'package:coffee_app/features/inventory/presentation/bloc/inventory_state.dart';
import 'package:coffee_app/features/notifications/presentation/cubit/notification_cubit.dart';

class InventoryLowStockObserver {
  final InventoryCubit _inventoryCubit;
  final NotificationCubit _notificationCubit;

  StreamSubscription? _sub;

  final Set<String> _alreadyNotifiedItemIds = <String>{};

  InventoryLowStockObserver({
    required InventoryCubit inventoryCubit,
    required NotificationCubit notificationCubit,
  })  : _inventoryCubit = inventoryCubit,
        _notificationCubit = notificationCubit;

  Future<void> _handleState(InventoryState state) async {
    final items = state is InventoryLoaded
        ? state.items
        : _inventoryCubit.cachedItems;

    for (final item in items) {
      if (_alreadyNotifiedItemIds.contains(item.id)) continue;

      await _notificationCubit.triggerLowStock(item);

      if (item.isLowStock) {
        _alreadyNotifiedItemIds.add(item.id);
      }
    }

    final currentLow = items.where((e) => e.isLowStock).map((e) => e.id).toSet();
    _alreadyNotifiedItemIds.removeWhere((id) => !currentLow.contains(id));
  }

  void start() {
    _handleState(_inventoryCubit.state);
    _sub ??= _inventoryCubit.stream.listen(_handleState);
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}
