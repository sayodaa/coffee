
import 'package:hive/hive.dart';

import '../../domain/entities/stock_movement.dart';

@HiveType(typeId: 2)
enum MovementTypeModel {
  @HiveField(0)
  inStock,
  @HiveField(1)
  outStock,
  @HiveField(2)
  saleDeduction,
  @HiveField(3)
  waste;

  MovementType toEntity() {
    switch (this) {
      case MovementTypeModel.inStock:
        return MovementType.inStock;
      case MovementTypeModel.outStock:
        return MovementType.outStock;
      case MovementTypeModel.saleDeduction:
        return MovementType.saleDeduction;
      case MovementTypeModel.waste:
        return MovementType.waste;
    }
  }

  static MovementTypeModel fromEntity(MovementType type) {
    switch (type) {
      case MovementType.inStock:
        return MovementTypeModel.inStock;
      case MovementType.outStock:
        return MovementTypeModel.outStock;
      case MovementType.saleDeduction:
        return MovementTypeModel.saleDeduction;
      case MovementType.waste:
        return MovementTypeModel.waste;
    }
  }
}

class MovementTypeModelAdapter extends TypeAdapter<MovementTypeModel> {
  @override
  final int typeId = 2;

  @override
  MovementTypeModel read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MovementTypeModel.inStock;
      case 1:
        return MovementTypeModel.outStock;
      case 2:
        return MovementTypeModel.saleDeduction;
      case 3:
        return MovementTypeModel.waste;
      default:
        return MovementTypeModel.inStock;
    }
  }

  @override
  void write(BinaryWriter writer, MovementTypeModel obj) {
    switch (obj) {
      case MovementTypeModel.inStock:
        writer.writeByte(0);
        break;
      case MovementTypeModel.outStock:
        writer.writeByte(1);
        break;
      case MovementTypeModel.saleDeduction:
        writer.writeByte(2);
        break;
      case MovementTypeModel.waste:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MovementTypeModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

@HiveType(typeId: 1)
class StockMovementModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String inventoryItemId;

  @HiveField(2)
  late MovementTypeModel type;

  @HiveField(3)
  late double amount;

  @HiveField(4)
  late DateTime timestamp;

  @HiveField(5)
  late String? note;

  StockMovementModel({
    required this.id,
    required this.inventoryItemId,
    required this.type,
    required this.amount,
    required this.timestamp,
    this.note,
  });

  factory StockMovementModel.fromEntity(StockMovement entity) {
    return StockMovementModel(
      id: entity.id,
      inventoryItemId: entity.inventoryItemId,
      type: MovementTypeModel.fromEntity(entity.type),
      amount: entity.amount,
      timestamp: entity.timestamp,
      note: entity.note,
    );
  }

  StockMovement toEntity() {
    return StockMovement(
      id: id,
      inventoryItemId: inventoryItemId,
      type: type.toEntity(),
      amount: amount,
      timestamp: timestamp,
      note: note,
    );
  }
}

class StockMovementModelAdapter extends TypeAdapter<StockMovementModel> {
  @override
  final int typeId = 1;

  @override
  StockMovementModel read(BinaryReader reader) {
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

    return StockMovementModel(
      id: fields[0] as String,
      inventoryItemId: fields[1] as String,
      type: fields[2] as MovementTypeModel,
      amount: toDouble(fields[3]),
      timestamp: toDateTime(fields[4]),
      note: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, StockMovementModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.inventoryItemId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockMovementModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
