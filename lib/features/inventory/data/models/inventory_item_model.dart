import 'package:hive/hive.dart';

import '../../domain/entities/inventory_item.dart';

@HiveType(typeId: 0)
class InventoryItemModel {
  final String id;
  final String sku;
  final String name;
  final double quantity; // ✅ Changed from num → double for consistency
  final int minThreshold;
  final String unit;
  final double price;

  InventoryItemModel({
    required this.id,
    required this.sku,
    required this.name,
    required this.quantity,
    required this.minThreshold,
    required this.unit,
    required this.price,
  });

  factory InventoryItemModel.fromMap(Map<String, dynamic> map) {
    return InventoryItemModel(
      id: _safeString(map['id']) ?? '',
      sku: _safeString(map['sku']) ?? _safeString(map['id']) ?? '',
      name: _safeString(map['name']) ?? '',
      quantity: _safeDouble(map['quantity'] ?? map['current_quantity']),
      minThreshold: _safeInt(map['minThreshold'] ?? map['minimum_threshold']),
      unit: _safeString(map['unit']) ?? 'piece',
      price: _safeDouble(map['price'] ?? map['cost_per_unit']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sku': sku,
      'name': name,
      'quantity': quantity,
      'minThreshold': minThreshold,
      'unit': unit,
      'price': price,
    };
  }

  factory InventoryItemModel.fromEntity(InventoryItem entity) {
    return InventoryItemModel(
      id: entity.id,
      sku: entity.sku,
      name: entity.name,
      quantity: entity.quantity.toDouble(),
      minThreshold: entity.minThreshold,
      unit: entity.unit,
      price: entity.price,
    );
  }

  InventoryItem toEntity() {
    return InventoryItem(
      id: id,
      sku: sku,
      name: name,
      quantity: quantity,
      minThreshold: minThreshold,
      unit: unit,
      price: price,
    );
  }

  // ─── Safe type helpers ────────────────────────────────────────────────────

  /// Converts any stored value (double, int, String) → double safely
  static double _safeDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  /// Converts any stored value → int safely
  static int _safeInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  /// Converts any stored value → String? safely
  static String? _safeString(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    return v.toString();
  }
}

// ─── Hive Adapter ─────────────────────────────────────────────────────────────

class InventoryItemModelAdapter extends TypeAdapter<InventoryItemModel> {
  @override
  final int typeId = 0;

  @override
  InventoryItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    // ✅ Use safe helpers — handles old boxes where a field might have been
    // stored as String, int, or null due to a previous schema change.
    return InventoryItemModel(
      id: InventoryItemModel._safeString(fields[0]) ?? '',
      sku: InventoryItemModel._safeString(fields[1]) ?? '',
      name: InventoryItemModel._safeString(fields[2]) ?? '',
      quantity: InventoryItemModel._safeDouble(fields[4]),
      minThreshold: InventoryItemModel._safeInt(fields[5]),
      unit: InventoryItemModel._safeString(fields[6]) ?? 'piece',
      price: InventoryItemModel._safeDouble(fields[7]),
    );
  }

  @override
  void write(BinaryWriter writer, InventoryItemModel obj) {
    writer
      ..writeByte(7) // 7 fields: indices 0,1,2,4,5,6,7 (index 3 unused)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.sku)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.quantity)
      ..writeByte(5)
      ..write(obj.minThreshold)
      ..writeByte(6)
      ..write(obj.unit)
      ..writeByte(7)
      ..write(obj.price);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
