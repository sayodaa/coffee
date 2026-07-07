
import 'package:hive/hive.dart';

import '../../../../core/domain/value_objects/money.dart';
import '../../domain/entities/recipe_entity.dart';

/// Hive model for RecipeIngredient
@HiveType(typeId: 10)
class RecipeIngredientModel extends HiveObject {
  @HiveField(0)
  String inventoryItemId;

  @HiveField(1)
  double quantityRequiredPerUnit;

  @HiveField(2, defaultValue: false)
  bool isOptional;

  @HiveField(3)
  String? notes;

  RecipeIngredientModel({
    required this.inventoryItemId,
    required this.quantityRequiredPerUnit,
    this.isOptional = false,
    this.notes,
  });

  /// Convert from domain entity
  factory RecipeIngredientModel.fromEntity(RecipeIngredient entity) {
    return RecipeIngredientModel(
      inventoryItemId: entity.inventoryItemId,
      quantityRequiredPerUnit: entity.quantityRequiredPerUnit,
      isOptional: entity.isOptional,
      notes: entity.notes,
    );
  }

  /// Convert to domain entity
  RecipeIngredient toEntity() {
    return RecipeIngredient(
      inventoryItemId: inventoryItemId,
      quantityRequiredPerUnit: quantityRequiredPerUnit,
      isOptional: isOptional,
      notes: notes,
    );
  }
}

class RecipeIngredientModelAdapter extends TypeAdapter<RecipeIngredientModel> {
  @override
  final int typeId = 10;

  @override
  RecipeIngredientModel read(BinaryReader reader) {
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

    return RecipeIngredientModel(
      inventoryItemId: fields[0] as String,
      quantityRequiredPerUnit: toDouble(fields[1]),
      isOptional: fields[2] as bool? ?? false,
      notes: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, RecipeIngredientModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.inventoryItemId)
      ..writeByte(1)
      ..write(obj.quantityRequiredPerUnit)
      ..writeByte(2)
      ..write(obj.isOptional)
      ..writeByte(3)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeIngredientModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

/// Hive model for Recipe
@HiveType(typeId: 11)
class RecipeModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String productId;

  @HiveField(2)
  String productName;

  @HiveField(3)
  List<RecipeIngredientModel> ingredients;

  @HiveField(4)
  Map<String, double> sizeMultipliers;
  @HiveField(5)
  double price;

  @HiveField(6)
  double cost;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  DateTime updatedAt;

  RecipeModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.ingredients,
    required this.sizeMultipliers,
    required this.price,
    required this.cost,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert from domain entity
  factory RecipeModel.fromEntity(Recipe entity) {
    return RecipeModel(
      id: entity.id,
      productId: entity.productId,
      productName: entity.productName,
      ingredients: entity.ingredients
          .map((i) => RecipeIngredientModel.fromEntity(i))
          .toList(),
      sizeMultipliers: {
        'small': entity.sizeMultipliers[SizeVariant.small] ?? 0.8,
        'medium': entity.sizeMultipliers[SizeVariant.medium] ?? 1.0,
        'large': entity.sizeMultipliers[SizeVariant.large] ?? 1.3,
      },
      price: entity.price.amount,
      cost: entity.cost.amount,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Recipe toEntity() {
    return Recipe(
      id: id,
      productId: productId,
      productName: productName,
      ingredients: ingredients.map((i) => i.toEntity()).toList(),
      sizeMultipliers: sizeMultipliers.map((key, value) {
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
        return MapEntry(variant, value);
      }),
      createdAt: createdAt,
      price: Money(price),
      cost: Money(cost),
      updatedAt: updatedAt,
    );
  }
}

class RecipeModelAdapter extends TypeAdapter<RecipeModel> {
  @override
  final int typeId = 11;

  @override
  RecipeModel read(BinaryReader reader) {
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

    // Normalize sizeMultipliers map entries to double
    Map<String, double> normalizeSizeMultipliers(dynamic map) {
      if (map == null) return {'small': 0.8, 'medium': 1.0, 'large': 1.3};
      try {
        return (map as Map).map<String, double>((k, v) => MapEntry(k.toString(), toDouble(v)));
      } catch (_) {
        return {'small': 0.8, 'medium': 1.0, 'large': 1.3};
      }
    }

    return RecipeModel(
      id: fields[0] as String,
      productId: fields[1] as String,
      productName: fields[2] as String,
      ingredients: (fields[3] as List).cast<RecipeIngredientModel>(),
      sizeMultipliers: normalizeSizeMultipliers(fields[4]),
      price: toDouble(fields[5]),
      cost: toDouble(fields[6]),
      createdAt: toDateTime(fields[7]),
      updatedAt: toDateTime(fields[8]),
    );
  }

  @override
  void write(BinaryWriter writer, RecipeModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.productId)
      ..writeByte(2)
      ..write(obj.productName)
      ..writeByte(3)
      ..write(obj.ingredients)
      ..writeByte(4)
      ..write(obj.sizeMultipliers)
      ..writeByte(5)
      ..write(obj.price)
      ..writeByte(6)
      ..write(obj.cost)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
