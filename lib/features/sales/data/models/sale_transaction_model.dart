import 'package:hive/hive.dart';

import '../../../../core/domain/value_objects/money.dart';
import '../../domain/entities/sale_item_entity.dart';
import '../../domain/entities/sale_transaction_entity.dart';
import 'sale_item_model.dart';

/// Hive model for SaleTransaction
@HiveType(typeId: 15)
class SaleTransactionModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  List<SaleItemModel> items;

  @HiveField(2)
  DateTime timestamp;

  @HiveField(3)
  double totalAmount;

  @HiveField(8)
  double totalCost;

  @HiveField(9)
  double profit;

  @HiveField(10)
  bool isHidden;

  @HiveField(4)
  String? customerId;

  @HiveField(5)
  String cashierId;

  @HiveField(6)
  String status; // 'pending', 'validated', 'completed', 'cancelled', 'refunded'

  @HiveField(7)
  String? notes;

  SaleTransactionModel({
    required this.id,
    required this.items,
    required this.timestamp,
    required this.totalAmount,
    this.totalCost = 0,
    this.profit = 0,
    this.isHidden = false,
    this.customerId,
    required this.cashierId,
    required this.status,
    this.notes,
  });

  factory SaleTransactionModel.fromEntity(SaleTransaction entity) {
    return SaleTransactionModel(
      id: entity.id,
      items: entity.items.map((i) => SaleItemModel.fromEntity(i)).toList(),
      timestamp: entity.timestamp,
      totalAmount: entity.totalAmount.amount,
      totalCost: entity.totalCost.amount,
      profit: entity.profit.amount,
      isHidden: entity.isHidden,
      customerId: entity.customerId,
      cashierId: entity.cashierId,
      status: entity.status.name,
      notes: entity.notes,
    );
  }

  SaleTransaction toEntity() {
    return SaleTransaction(
      id: id,
      items: items.map((i) => i.toEntity()).toList(),
      timestamp: timestamp,
      totalAmount: Money(totalAmount),
      totalCost: Money(totalCost),
      profit: Money(profit),
      isHidden: isHidden,
      customerId: customerId,
      cashierId: cashierId,
      status: _parseStatus(status),
      notes: notes,
    );
  }

  SaleStatus _parseStatus(String value) {
    return SaleStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SaleStatus.pending,
    );
  }
}

class SaleTransactionModelAdapter extends TypeAdapter<SaleTransactionModel> {
  @override
  final int typeId = 15;

  @override
  SaleTransactionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    DateTime toDateTime(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is DateTime) return v;
      if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
      if (v is String) {
        final parsed = int.tryParse(v);
        if (parsed != null) return DateTime.fromMillisecondsSinceEpoch(parsed);
        try {
          return DateTime.parse(v);
        } catch (_) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return SaleTransactionModel(
      id: fields[0] as String,
      items: (fields[1] as List).cast<SaleItemModel>(),
      timestamp: toDateTime(fields[2]),
      totalAmount: toDouble(fields[3]),
      totalCost: toDouble(fields[8]),
      profit: toDouble(fields[9]),
      isHidden: (fields[10] as bool?) ?? false,
      customerId: fields[4] as String?,
      cashierId: fields[5] as String,
      status: fields[6] as String,
      notes: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SaleTransactionModel obj) {
    writer
      ..writeByte(11) // 11 fields: indices 0-10
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.items)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.totalAmount)
      ..writeByte(4)
      ..write(obj.customerId)
      ..writeByte(5)
      ..write(obj.cashierId)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.totalCost)
      ..writeByte(9)
      ..write(obj.profit)
      ..writeByte(10)
      ..write(obj.isHidden);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaleTransactionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
