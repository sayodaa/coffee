import '../entities/recipe_entity.dart';

/// Repository interface for recipe operations
abstract class RecipeRepository {
  /// Get recipe by ID
  Future<Recipe?> getById(String id);

  /// Get recipe by product ID
  Future<Recipe?> getByProductId(String productId);

  /// Get all recipes
  Future<List<Recipe>> getAll();

  /// Get active recipes only
  Future<List<Recipe>> getActiveRecipes();

  /// Save new recipe
  Future<void> save(Recipe recipe);

  /// Update existing recipe
  Future<void> update(Recipe recipe);

  /// Delete recipe
  Future<void> delete(String id);

  /// Check if recipe exists for product
  Future<bool> existsForProduct(String productId);

  /// Get recipes by category
  Future<List<Recipe>> getByCategory(String categoryId);

  /// Watch recipes for real-time updates
  Stream<List<Recipe>> watchRecipes();
}
