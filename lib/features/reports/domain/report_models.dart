import 'package:flutter/material.dart';

class ReportData {
  // Original properties used for old UI
  final double totalMonthlyWaste;
  final double stockAccuracy;
  final List<ConsumptionPoint> consumptionTrend;
  final List<WasteData> wasteAnalysis;

  // New properties for redesigned UI
  final double totalSales;
  final double totalProfit;
  final double expectedLossValue;
  final int lowStockItemsCount;
  final List<LossItem> lossAnalysis;

  const ReportData({
    required this.totalMonthlyWaste,
    required this.stockAccuracy,
    required this.consumptionTrend,
    required this.wasteAnalysis,
    required this.totalSales,
    required this.totalProfit,
    required this.expectedLossValue,
    required this.lowStockItemsCount,
    required this.lossAnalysis,
  });
}

class LossItem {
  final String itemName;
  final double expected;
  final double actual;
  final double difference;

  const LossItem({
    required this.itemName,
    required this.expected,
    required this.actual,
  }) : difference = actual - expected;

  bool get isAbnormal => difference > (expected * 0.1);
}

class ConsumptionPoint {
  final DateTime date;
  final double value;

  const ConsumptionPoint({
    required this.date,
    required this.value,
  });
}

class WasteData {
  final String reason;
  final double amount;
  final Color color;

  const WasteData({
    required this.reason,
    required this.amount,
    required this.color,
  });
}

/// Helper model for generating reports
class SalesItem {
  final DateTime timestamp;
  final String drinkName;
  final int quantity;
  final double price;
  final double totalPrice;

  const SalesItem({
    required this.timestamp,
    required this.drinkName,
    required this.quantity,
    required this.price,
    required this.totalPrice,
  });
}

/// Model for inventory return logs
class InventoryReturnLogModel {
  final String id;
  final String inventoryItemId;
  final double quantity;
  final String reason;
  final DateTime timestamp;

  const InventoryReturnLogModel({
    required this.id,
    required this.inventoryItemId,
    required this.quantity,
    required this.reason,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'inventoryItemId': inventoryItemId,
      'quantity': quantity,
      'reason': reason,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory InventoryReturnLogModel.fromMap(Map<String, dynamic> map) {
    return InventoryReturnLogModel(
      id: map['id'],
      inventoryItemId: map['inventoryItemId'],
      quantity: map['quantity'],
      reason: map['reason'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }
}
