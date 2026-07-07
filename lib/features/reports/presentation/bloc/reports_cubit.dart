import 'package:coffee_app/features/inventory/domain/entities/stock_movement.dart';
import 'package:coffee_app/features/inventory/presentation/bloc/inventory_cubit.dart';
import 'package:coffee_app/features/reports/domain/report_models.dart';
import 'package:coffee_app/features/sales/domain/entities/sale_transaction_entity.dart';
import 'package:coffee_app/features/sales/domain/repositories/sales_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'reports_state.dart';

export 'reports_state.dart';

class ReportsCubit extends Cubit<ReportsState> {
  final InventoryCubit inventoryCubit;
  final SalesRepository salesRepository;

  int _requestSeq = 0;

  ReportsCubit({
    required this.inventoryCubit,
    required this.salesRepository,
  }) : super(
          ReportsLoading(
            startDate: DateTime.now().subtract(const Duration(days: 30)),
            endDate: DateTime.now(),
            requestId: 0,
          ),
        ) {
    fetch();
  }

  Future<void> setDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final normalizedStart =
        DateTime(startDate.year, startDate.month, startDate.day);
    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);

    final requestId = ++_requestSeq;
    emit(
      ReportsLoading(
        startDate: normalizedStart,
        endDate: normalizedEnd,
        requestId: requestId,
      ),
    );

    await _fetchInternal(
      startDate: normalizedStart,
      endDate: normalizedEnd,
      requestId: requestId,
    );
  }

  Future<void> fetch() async {
    final requestId = ++_requestSeq;
    emit(
      ReportsLoading(
        startDate: state.startDate,
        endDate: state.endDate,
        requestId: requestId,
      ),
    );

    await _fetchInternal(
      startDate: state.startDate,
      endDate: state.endDate,
      requestId: requestId,
    );
  }

  Future<void> _fetchInternal({
    required DateTime startDate,
    required DateTime endDate,
    required int requestId,
  }) async {
    print(
        '[DEBUG] ReportsCubit: Loading reports data - startDate: $startDate, endDate: $endDate, requestId: $requestId');

    try {
      final allMovements = inventoryCubit.movements;
      print(
          '[DEBUG] ReportsCubit: Retrieved ${allMovements.length} total movements');

      final movements = allMovements.where((m) {
        if (m.timestamp.isBefore(startDate)) return false;
        if (m.timestamp.isAfter(endDate.add(const Duration(days: 1)))) {
          return false;
        }
        return true;
      }).toList();

      if (requestId != _requestSeq) return;

      print(
          '[DEBUG] ReportsCubit: Filtered to ${movements.length} movements in date range');

      final inventoryItems = inventoryCubit.cachedItems;
      print(
          '[DEBUG] ReportsCubit: Working with ${inventoryItems.length} inventory items');

      double expectedConsumption = 0;
      double actualConsumption = 0;
      double totalWasteValue = 0;

      final Map<String, double> expectedByItem = {};
      final Map<String, double> actualByItem = {};

      for (var m in movements) {
        if (m.type == MovementType.saleDeduction) {
          expectedConsumption += m.amount.abs();
          actualConsumption += m.amount.abs();
          expectedByItem[m.inventoryItemId] =
              (expectedByItem[m.inventoryItemId] ?? 0) + m.amount.abs();
          actualByItem[m.inventoryItemId] =
              (actualByItem[m.inventoryItemId] ?? 0) + m.amount.abs();
        } else if (m.type == MovementType.outStock ||
            m.type == MovementType.waste) {
          actualConsumption += m.amount.abs();
          totalWasteValue += m.amount.abs() * 5.0;
          actualByItem[m.inventoryItemId] =
              (actualByItem[m.inventoryItemId] ?? 0) + m.amount.abs();
        }
      }

      double expectedLossValue = 0;
      final List<LossItem> lossAnalysis = [];
      for (var item in inventoryItems) {
        final exp = expectedByItem[item.id] ?? 0;
        final act = actualByItem[item.id] ?? 0;
        if (exp > 0 || act > 0) {
          final lossItem = LossItem(
            itemName: item.name,
            expected: exp,
            actual: act,
          );
          lossAnalysis.add(lossItem);
          if (lossItem.difference > 0) {
            expectedLossValue += lossItem.difference * item.price;
          }
        }
      }

      final lowStockCount = inventoryItems.where((i) => i.isLowStock).length;
      final accuracy = expectedConsumption == 0
          ? 100.0
          : (expectedConsumption / actualConsumption * 100).clamp(0.0, 100.0);

      final List<SaleTransaction> freshSales = await salesRepository.getSalesByDateRange(
        startDate: startDate,
        endDate: endDate,
      );

      if (requestId != _requestSeq) return;

      final realTotalSales =
          freshSales.fold<double>(0, (sum, sale) => sum + sale.totalAmount.amount);

      // Calculate profit using sale.profit (calculated at sale time). Exclude hidden sales by default.
        final realTotalProfit = freshSales
          .where((s) => s.isHidden == false)
          .fold<double>(0, (sum, sale) => sum + sale.profit.amount);

      final reportData = ReportData(
        totalMonthlyWaste: totalWasteValue,
        stockAccuracy: accuracy,
        totalSales: realTotalSales,
        totalProfit: realTotalProfit,
        expectedLossValue: expectedLossValue,
        lowStockItemsCount: lowStockCount,
        consumptionTrend: _generateConsumptionTrend(movements),
        wasteAnalysis: _generateWasteAnalysis(movements),
        lossAnalysis: lossAnalysis,
      );

      print(
          '[DEBUG] ReportsCubit: Report generated successfully. TotalSales=$realTotalSales, requestId=$requestId');

      emit(
        ReportsLoaded(
          startDate: startDate,
          endDate: endDate,
          data: reportData,
          requestId: requestId,
        ),
      );
    } catch (e) {
      print('[ERROR] ReportsCubit: Failed to load reports - $e');
      emit(
        ReportsError(
          startDate: startDate,
          endDate: endDate,
          message: 'Failed to load reports data: $e',
          requestId: requestId,
        ),
      );
    }
  }

  /// Generate consumption trend from actual movements
  /// If no movements, return a trend with zero values
  List<ConsumptionPoint> _generateConsumptionTrend(
      List<StockMovement> movements) {
    final now = DateTime.now();
    final last30Days = <DateTime, double>{};

    // Initialize all 30 days with 0
    for (int i = 0; i < 30; i++) {
      final date = DateTime(
        now.year,
        now.month,
        now.day - (29 - i),
      );
      last30Days[date] = 0;
    }

    // Aggregate actual consumption by date
    for (var movement in movements) {
      final date = DateTime(
        movement.timestamp.year,
        movement.timestamp.month,
        movement.timestamp.day,
      );

      if (last30Days.containsKey(date)) {
        // Only count consumption, not stock additions
        if (movement.type == MovementType.outStock ||
            movement.type == MovementType.waste ||
            movement.type == MovementType.saleDeduction) {
          last30Days[date] = last30Days[date]! + movement.amount.abs();
        }
      }
    }

    // Convert to ConsumptionPoint list
    return last30Days.entries
        .map((e) => ConsumptionPoint(date: e.key, value: e.value))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Generate waste analysis from actual movements
  /// Shows real waste data or empty list if no waste
  List<WasteData> _generateWasteAnalysis(List<StockMovement> movements) {
    final wasteByReason = <String, double>{};

    for (var movement in movements) {
      if (movement.type == MovementType.waste ||
          movement.type == MovementType.outStock) {
        final reason = movement.note ?? 'Manual Adjustment';
        wasteByReason[reason] =
            (wasteByReason[reason] ?? 0) + movement.amount.abs();
      }
    }

    if (wasteByReason.isEmpty) {
      // No waste recorded - return empty list (not hardcoded data)
      return const [];
    }

    // Define colors for different waste reasons
    final reasonColors = <String, Color>{
      'Breakage': const Color(0xFFEF4444),
      'Expired': const Color(0xFFF59E0B),
      'Spillage': const Color(0xFF06B6D4),
      'Manual Adjustment': const Color(0xFF8B5CF6),
    };

    return wasteByReason.entries
        .map((e) => WasteData(
              reason: e.key,
              amount: e.value,
              color: reasonColors[e.key] ?? const Color(0xFF6366F1),
            ))
        .toList();
  }
}
