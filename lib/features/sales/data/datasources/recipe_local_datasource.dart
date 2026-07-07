import 'package:hive/hive.dart';

import '../models/recipe_model.dart';

/// Hive data source for Recipe operations
class RecipeLocalDataSource {
  static const String _boxName = 'recipes';
  Box<RecipeModel>? _box;

  /// Initialize and open the box
  Future<void> init() async {
    _box = await Hive.openBox<RecipeModel>(_boxName);
    // Run lightweight migration to normalize existing entries
    try {
      final box = _box!;
      await _migrateIfNeeded(box);
    } catch (e, st) {
      print('[RecipeLocalDataSource] migration failed: $e\n$st');
    }
  }

  Future<void> _migrateIfNeeded(Box<RecipeModel> box) async {
    print('[RecipeLocalDataSource] _migrateIfNeeded: start');
    try {
      final entries = box.values.toList();
      for (final entry in entries) {
        try {
          // Normalize by round-tripping through the domain entity
          final entity = entry.toEntity();
          final normalized = RecipeModel.fromEntity(entity);
          if (normalized.id.isNotEmpty) {
            await box.put(normalized.id, normalized);
          }
        } catch (e) {
          print('[RecipeLocalDataSource] normalize entry failed: $e');
        }
      }
      print('[RecipeLocalDataSource] _migrateIfNeeded: completed, entries=${entries.length}');
    } catch (e, st) {
      print('[RecipeLocalDataSource] migration outer error: $e\n$st');
    }
  }

  /// Ensure box is open
  Future<Box<RecipeModel>> _getBox() async {
    _box ??= await Hive.openBox<RecipeModel>(_boxName);
    return _box!;
  }

  /// Get recipe by ID
  Future<RecipeModel?> getById(String id) async {
    final box = await _getBox();
    return box.get(id);
  }

  /// Get recipe by product ID
  Future<RecipeModel?> getByProductId(String productId) async {
    final box = await _getBox();
    try {
      return box.values.firstWhere(
        (recipe) => recipe.productId == productId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get all recipes
  Future<List<RecipeModel>> getAll() async {
    final box = await _getBox();
    return box.values.toList();
  }

  /// Get active recipes
  Future<List<RecipeModel>> getActiveRecipes() async {
    final all = await getAll();
    return all; // All recipes in Hive are considered active
  }

  /// Save recipe
  Future<void> save(RecipeModel recipe) async {
    final box = await _getBox();
    await box.put(recipe.id, recipe);
  }

  /// Update recipe
  Future<void> update(RecipeModel recipe) async {
    final box = await _getBox();
    await box.put(recipe.id, recipe);
  }

  /// Delete recipe
  Future<void> delete(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }

  /// Check if exists for product
  Future<bool> existsForProduct(String productId) async {
    final recipe = await getByProductId(productId);
    return recipe != null;
  }

  /// Get recipes by category
  Future<List<RecipeModel>> getByCategory(String categoryId) async {
    // This would require looking up products in category first
    // For now, return all
    return getAll();
  }

  /// Watch recipes for real-time updates
  Stream<List<RecipeModel>> watchRecipes() async* {
    final box = await _getBox();
    // Yield initial value
    yield box.values.toList();
    // Listen to box changes
    yield* box.watch().map((_) => box.values.toList());
  }

  /// Close box
  Future<void> close() async {
    if (_box != null && _box!.isOpen) {
      await _box!.close();
    }
  }
}
