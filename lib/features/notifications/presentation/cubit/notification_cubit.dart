import 'package:bloc/bloc.dart';
import 'package:coffee_app/features/inventory/domain/entities/inventory_item.dart';
import 'package:coffee_app/features/notifications/data/datasources/low_stock_notified_local_datasource.dart';
import 'package:coffee_app/features/notifications/data/services/notification_service.dart';
import 'package:coffee_app/features/sales/domain/repositories/sales_repository.dart';
import 'package:coffee_app/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

part 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationService _service;
  final LowStockNotifiedLocalDataSource _lowStockNotified;
  final SalesRepository _salesRepository;
  final SettingsCubit _settingsCubit;

  NotificationCubit({
    required NotificationService service,
    required LowStockNotifiedLocalDataSource lowStockNotified,
    required SalesRepository salesRepository,
    required SettingsCubit settingsCubit,
  })  : _service = service,
        _lowStockNotified = lowStockNotified,
        _salesRepository = salesRepository,
        _settingsCubit = settingsCubit,
        super(const NotificationState.initial());

  Future<void> initialize() async {
    emit(const NotificationState.loading());

    try {
      await _service.initialize();
      await _service.requestPermissions();

      emit(const NotificationState.ready());
    } catch (e) {
      emit(NotificationState.failure(e.toString()));
    }
  }

  Future<void> enableNotifications() async {
    await _settingsCubit.setNotificationsEnabled(true);
  }

  Future<void> disableNotifications() async {
    await _settingsCubit.setNotificationsEnabled(false);
    await cancelDailySummary();
  }

  Future<void> scheduleDailySummary({TimeOfDay time = const TimeOfDay(hour: 21, minute: 0)}) async {
    final settings = _settingsCubit.state.settingsOrNull;
    if (settings == null) return;
    if (!settings.notificationsEnabled) return;
    if (!settings.dailySalesSummaryEnabled) return;

    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));
    final sales = await _salesRepository.getSalesByDateRange(
      startDate: start,
      endDate: end,
    );

    final total = sales.fold<double>(0.0, (sum, s) => sum + s.totalAmount.amount);
    final drinksSold = sales.fold<int>(0, (sum, s) => sum + s.totalItemCount);

    await _service.scheduleDaily(
      time: time,
      title: 'Daily sales summary',
      body: 'Today: $drinksSold drinks • Total $total',
      payload: const {'type': 'daily_sales_summary'},
    );
  }

  Future<void> cancelDailySummary() async {
    await _service.cancelDailySummary();
  }

  Future<void> triggerLowStock(InventoryItem product) async {
    final settings = _settingsCubit.state.settingsOrNull;
    if (settings == null) return;
    if (!settings.notificationsEnabled) return;
    if (!settings.lowStockAlertsEnabled) return;

    if (!product.isLowStock) {
      await _lowStockNotified.remove(product.id);
      return;
    }

    final notified = _lowStockNotified.getNotifiedIds();
    if (notified.contains(product.id)) return;

    await _service.showInstant(
      id: product.id.hashCode,
      title: 'Low stock: ${product.name}',
      body: 'Only ${product.quantity} ${product.unit} left (min ${product.minThreshold}).',
      payload: {
        'type': 'low_stock',
        'product_id': product.id,
      },
    );

    await markLowStockNotified(product.id);
  }

  Future<void> markLowStockNotified(String productId) async {
    await _lowStockNotified.add(productId);
  }

  Future<void> triggerSaleCompleted({
    required String saleId,
    required String drinkName,
    required int quantity,
    required double totalPrice,
  }) async {
    final settings = _settingsCubit.state.settingsOrNull;
    if (settings == null) return;
    if (!settings.notificationsEnabled) return;
    if (!settings.saleCompletedNotificationsEnabled) return;

    await _service.showInstant(
      id: saleId.hashCode,
      title: 'Sale completed',
      body: '$drinkName x$quantity — Total $totalPrice',
      payload: {
        'type': 'sale_completed',
        'sale_id': saleId,
      },
    );
  }

  @override
  Future<void> close() {
    return super.close();
  }
}
