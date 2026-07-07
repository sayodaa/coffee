
import 'package:coffee_app/features/sales/domain/entities/recipe_entity.dart';
import 'package:hive/hive.dart';

import '../../../../core/domain/value_objects/money.dart';
import '../../domain/entities/sale_item_entity.dart';

/// Hive model for SaleItem
@HiveType(typeId: 14)
class SaleItemModel extends HiveObject {
  @HiveField(0)
  String productId;

  @HiveField(1)
  String productName;

  @HiveField(2)
  int quantity;

  @HiveField(3)
  String size; // 'small', 'medium', 'large'

  @HiveField(4)
  String? sugarLevel; // 'none', 'low', 'normal', 'extra', 'double'

  @HiveField(5)
  Map<String, dynamic>? customizations;

  @HiveField(6)
  double unitPrice;

  @HiveField(7)
  double totalPrice;

  SaleItemModel({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.size,
    this.sugarLevel,
    this.customizations,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory SaleItemModel.fromEntity(SaleItem entity) {
    return SaleItemModel(
      productId: entity.productId,
      productName: entity.productName,
      quantity: entity.quantity,
      size: entity.size.name,
      sugarLevel: entity.sugarLevel?.name,
      customizations: entity.customizations,
      unitPrice: entity.unitPrice.amount,
      totalPrice: entity.totalPrice.amount,
    );
  }

  SaleItem toEntity() {
    return SaleItem(
      productId: productId,
      productName: productName,
      quantity: quantity,
      size: _parseSize(size),
      sugarLevel: sugarLevel != null ? _parseSugarLevel(sugarLevel!) : null,
      customizations: customizations,
      unitPrice: Money(unitPrice),
      totalPrice: Money(totalPrice),
    );
  }

  SizeVariant _parseSize(String value) {
    return SizeVariant.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SizeVariant.medium,
    );
  }

  SugarLevel _parseSugarLevel(String value) {
    return SugarLevel.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SugarLevel.normal,
    );
  }
}

class SaleItemModelAdapter extends TypeAdapter<SaleItemModel> {
  @override
  final int typeId = 14;

  @override
  SaleItemModel read(BinaryReader reader) {
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

    return SaleItemModel(
      productId: fields[0] as String,
      productName: fields[1] as String,
      quantity: fields[2] as int,
      size: fields[3] as String,
      sugarLevel: fields[4] as String?,
      customizations: (fields[5] as Map?)?.cast<String, dynamic>(),
      unitPrice: toDouble(fields[6]),
      totalPrice: toDouble(fields[7]),
    );
  }

  @override
  void write(BinaryWriter writer, SaleItemModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.productId)
      ..writeByte(1)
      ..write(obj.productName)
      ..writeByte(2)
      ..write(obj.quantity)
      ..writeByte(3)
      ..write(obj.size)
      ..writeByte(4)
      ..write(obj.sugarLevel)
      ..writeByte(5)
      ..write(obj.customizations)
      ..writeByte(6)
      ..write(obj.unitPrice)
      ..writeByte(7)
      ..write(obj.totalPrice);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaleItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
