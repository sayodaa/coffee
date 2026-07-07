import '../../domain/entities/recipe_entity.dart';
import '../../domain/repositories/recipe_repository_interface.dart';
import '../datasources/recipe_local_datasource.dart';
import '../models/recipe_model.dart';

/// Repository implementation for Recipe
class RecipeRepositoryImpl implements RecipeRepository {
  final RecipeLocalDataSource _localDataSource;

  RecipeRepositoryImpl(this._localDataSource);

  @override
  Future<Recipe?> getById(String id) async {
    final model = await _localDataSource.getById(id);
    return model?.toEntity();
  }

  @override
  Future<Recipe?> getByProductId(String productId) async {
    final model = await _localDataSource.getByProductId(productId);
    return model?.toEntity();
  }

  @override
  Future<List<Recipe>> getAll() async {
    final models = await _localDataSource.getAll();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Recipe>> getActiveRecipes() async {
    final models = await _localDataSource.getActiveRecipes();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> save(Recipe recipe) async {
    final model = RecipeModel.fromEntity(recipe);
    await _localDataSource.save(model);
  }

  @override
  Future<void> update(Recipe recipe) async {
    final model = RecipeModel.fromEntity(recipe);
    await _localDataSource.update(model);
  }

  @override
  Future<void> delete(String id) async {
    await _localDataSource.delete(id);
  }

  @override
  Future<bool> existsForProduct(String productId) async {
    return await _localDataSource.existsForProduct(productId);
  }

  @override
  Future<List<Recipe>> getByCategory(String categoryId) async {
    final models = await _localDataSource.getByCategory(categoryId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Stream<List<Recipe>> watchRecipes() {
    return _localDataSource.watchRecipes().map((models) {
      return models.map((m) => m.toEntity()).toList();
    });
  }
}
