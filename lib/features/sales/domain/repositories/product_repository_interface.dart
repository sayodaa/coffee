import '../entities/product_entity.dart';

/// Repository interface for product operations
abstract class ProductRepository {
  /// Get product by ID
  Future<Product?> getById(String id);

  /// Get all products
  Future<List<Product>> getAll();

  /// Get active products
  Future<List<Product>> getActiveProducts();

  /// Get products by category
  Future<List<Product>> getByCategory(String categoryId);

  /// Save new product
  Future<void> save(Product product);

  /// Update existing product
  Future<void> update(Product product);

  /// Delete product
  Future<void> delete(String id);

  /// Search products by name
  Future<List<Product>> searchByName(String query);

  /// Get all categories
  Future<List<ProductCategory>> getAllCategories();

  /// Save category
  Future<void> saveCategory(ProductCategory category);
}
