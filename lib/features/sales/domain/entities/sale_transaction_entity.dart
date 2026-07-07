import 'package:equatable/equatable.dart';

import '../../../../core/domain/value_objects/money.dart';
import 'sale_item_entity.dart';

/// Sale transaction entity
class SaleTransaction extends Equatable {
  final String id;
  final List<SaleItem> items;
  final DateTime timestamp;
  final Money totalAmount;
  final Money totalCost;
  final Money profit;
  final String? customerId;
  final String cashierId;
  final SaleStatus status;
  final String? notes;
  final bool isHidden;

  const SaleTransaction({
    required this.id,
    required this.items,
    required this.timestamp,
    required this.totalAmount,
    this.totalCost = const Money(0),
    this.profit = const Money(0),
    this.customerId,
    required this.cashierId,
    this.status = SaleStatus.pending,
    this.notes,
    this.isHidden = false,
  });

  /// Calculate total quantity of items
  int get totalItemCount => items.fold(0, (sum, item) => sum + item.quantity);

  // Legacy compatibility getters for UI expecting single-item transactions
  String get drinkName => items.isNotEmpty ? items.first.productName : '';
  int get quantity => totalItemCount;
  double get price => items.isNotEmpty ? items.first.unitPrice.amount : 0.0;
  double get totalPrice => totalAmount.amount;

  /// Check if transaction can be completed
  bool get canComplete => status == SaleStatus.pending || status == SaleStatus.validated;

  /// Get all unique product IDs
  List<String> get productIds => items.map((i) => i.productId).toSet().toList();

  SaleTransaction copyWith({
    String? id,
    List<SaleItem>? items,
    DateTime? timestamp,
    Money? totalAmount,
    Money? totalCost,
    Money? profit,
    String? customerId,
    String? cashierId,
    SaleStatus? status,
    String? notes,
    bool? isHidden,
  }) {
    return SaleTransaction(
      id: id ?? this.id,
      items: items ?? this.items,
      timestamp: timestamp ?? this.timestamp,
      totalAmount: totalAmount ?? this.totalAmount,
      totalCost: totalCost ?? this.totalCost,
      profit: profit ?? this.profit,
      customerId: customerId ?? this.customerId,
      cashierId: cashierId ?? this.cashierId,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      isHidden: isHidden ?? this.isHidden,
    );
  }

  @override
  List<Object?> get props => [
        id,
        items,
        timestamp,
        totalAmount,
        totalCost,
        profit,
        customerId,
        cashierId,
        status,
        notes,
        isHidden,
      ];
}
