
import 'package:equatable/equatable.dart';

enum MovementType {
  inStock,
  outStock,
  saleDeduction,
  waste
}

class StockMovement extends Equatable {
  final String id;
  final String inventoryItemId;
  final MovementType type;
  final double amount;
  final DateTime timestamp;
  final String? note;

  const StockMovement({
    required this.id,
    required this.inventoryItemId,
    required this.type,
    required this.amount,
    required this.timestamp,
    this.note,
  });

  @override
  List<Object?> get props =>
      [id, inventoryItemId, type, amount, timestamp, note];
}
