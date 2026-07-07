import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository_interface.dart';
import '../datasources/product_local_datasource.dart';
import '../models/product_model.dart';

/// Repository implementation for Product
class ProductRepositoryImpl implements ProductRepository {
  final ProductLocalDataSource _localDataSource;

  ProductRepositoryImpl(this._localDataSource);

  @override
  Future<Product?> getById(String id) async {
    final model = await _localDataSource.getById(id);
    return model?.toEntity();
  }

  @override
  Future<List<Product>> getAll() async {
    final models = await _localDataSource.getAll();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Product>> getActiveProducts() async {
    final models = await _localDataSource.getActiveProducts();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Product>> getByCategory(String categoryId) async {
    final models = await _localDataSource.getByCategory(categoryId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> save(Product product) async {
    final model = ProductModel.fromEntity(product);
    await _localDataSource.save(model);
  }

  @override
  Future<void> update(Product product) async {
    final model = ProductModel.fromEntity(product);
    await _localDataSource.update(model);
  }

  @override
  Future<void> delete(String id) async {
    await _localDataSource.delete(id);
  }

  @override
  Future<List<Product>> searchByName(String query) async {
    final models = await _localDataSource.searchByName(query);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<ProductCategory>> getAllCategories() async {
    final models = await _localDataSource.getAllCategories();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> saveCategory(ProductCategory category) async {
    final model = ProductCategoryModel.fromEntity(category);
    await _localDataSource.saveCategory(model);
  }
}
