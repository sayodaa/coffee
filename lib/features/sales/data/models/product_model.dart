
import 'package:coffee_app/core/domain/value_objects/money.dart';
import 'package:hive/hive.dart';

import '../../domain/entities/product_entity.dart';
import '../../domain/entities/recipe_entity.dart';

/// Hive model for ProductCategory
@HiveType(typeId: 12)
class ProductCategoryModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? description;

  @HiveField(3, defaultValue: 0)
  int displayOrder;

  @HiveField(4, defaultValue: true)
  bool isActive;

  ProductCategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.displayOrder = 0,
    this.isActive = true,
  });

  factory ProductCategoryModel.fromEntity(ProductCategory entity) {
    return ProductCategoryModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      displayOrder: entity.displayOrder,
      isActive: entity.isActive,
    );
  }

  ProductCategory toEntity() {
    return ProductCategory(
      id: id,
      name: name,
      description: description,
      displayOrder: displayOrder,
      isActive: isActive,
    );
  }
}

class ProductCategoryModelAdapter extends TypeAdapter<ProductCategoryModel> {
  @override
  final int typeId = 12;

  @override
  ProductCategoryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductCategoryModel(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String?,
      displayOrder: fields[3] as int? ?? 0,
      isActive: fields[4] as bool? ?? true,
    );
  }

  @override
  void write(BinaryWriter writer, ProductCategoryModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.displayOrder)
      ..writeByte(4)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductCategoryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

/// Hive model for Product
@HiveType(typeId: 13)
class ProductModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? description;

  @HiveField(3)
  String categoryId;

  @HiveField(4)
  Map<String, double> prices; // size -> price

  @HiveField(5)
  String? recipeId;

  @HiveField(6, defaultValue: true)
  bool isActive;

  @HiveField(7)
  DateTime createdAt;

  ProductModel({
    required this.id,
    required this.name,
    this.description,
    required this.categoryId,
    required this.prices,
    this.recipeId,
    this.isActive = true,
    required this.createdAt,
  });

  factory ProductModel.fromEntity(Product entity) {
    return ProductModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      categoryId: entity.categoryId,
      prices: {
        'small': entity.prices[SizeVariant.small]?.amount ?? 0,
        'medium': entity.prices[SizeVariant.medium]?.amount ?? 0,
        'large': entity.prices[SizeVariant.large]?.amount ?? 0,
      },
      recipeId: entity.recipeId,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
    );
  }

  Product toEntity() {
    final parsedPrices = prices.map((key, value) {
      SizeVariant variant;
      switch (key) {
        case 'small':
          variant = SizeVariant.small;
          break;
        case 'medium':
          variant = SizeVariant.medium;
          break;
        case 'large':
          variant = SizeVariant.large;
          break;
        default:
          variant = SizeVariant.medium;
      }
      return MapEntry(variant, Money(value));
    });

    return Product(
      id: id,
      name: name,
      description: description,
      categoryId: categoryId,
      prices: parsedPrices,
      recipeId: recipeId,
      isActive: isActive,
      createdAt: createdAt,
    );
  }
}

class ProductModelAdapter extends TypeAdapter<ProductModel> {
  @override
  final int typeId = 13;

  @override
  ProductModel read(BinaryReader reader) {
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

    Map<String, double> normPrices(dynamic map) {
      if (map == null) return {'small': 0.0, 'medium': 0.0, 'large': 0.0};
      try {
        return (map as Map).map((key, value) => MapEntry(key.toString(), toDouble(value)));
      } catch (_) {
        return {'small': 0.0, 'medium': 0.0, 'large': 0.0};
      }
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

    return ProductModel(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String?,
      categoryId: fields[3] as String,
      prices: normPrices(fields[4]),
      recipeId: fields[5] as String?,
      isActive: fields[6] as bool? ?? true,
      createdAt: toDateTime(fields[7]),
    );
  }

  @override
  void write(BinaryWriter writer, ProductModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.categoryId)
      ..writeByte(4)
      ..write(obj.prices)
      ..writeByte(5)
      ..write(obj.recipeId)
      ..writeByte(6)
      ..write(obj.isActive)
      ..writeByte(7)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
