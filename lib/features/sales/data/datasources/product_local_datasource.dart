import 'package:hive/hive.dart';
import '../models/product_model.dart';

/// Hive data source for Product operations
class ProductLocalDataSource {
  static const String _productBoxName = 'products';
  static const String _categoryBoxName = 'categories';

  Box<ProductModel>? _productBox;
  Box<ProductCategoryModel>? _categoryBox;

  /// Initialize boxes
  Future<void> init() async {
    _productBox = await Hive.openBox<ProductModel>(_productBoxName);
    _categoryBox = await Hive.openBox<ProductCategoryModel>(_categoryBoxName);
  }

  Future<Box<ProductModel>> _getProductBox() async {
    _productBox ??= await Hive.openBox<ProductModel>(_productBoxName);
    return _productBox!;
  }

  Future<Box<ProductCategoryModel>> _getCategoryBox() async {
    _categoryBox ??= await Hive.openBox<ProductCategoryModel>(_categoryBoxName);
    return _categoryBox!;
  }

  /// Get product by ID
  Future<ProductModel?> getById(String id) async {
    final box = await _getProductBox();
    return box.get(id);
  }

  /// Get all products
  Future<List<ProductModel>> getAll() async {
    final box = await _getProductBox();
    return box.values.toList();
  }

  /// Get active products
  Future<List<ProductModel>> getActiveProducts() async {
    final all = await getAll();
    return all.where((p) => p.isActive).toList();
  }

  /// Get products by category
  Future<List<ProductModel>> getByCategory(String categoryId) async {
    final box = await _getProductBox();
    return box.values.where((p) => p.categoryId == categoryId).toList();
  }

  /// Save product
  Future<void> save(ProductModel product) async {
    final box = await _getProductBox();
    await box.put(product.id, product);
  }

  /// Update product
  Future<void> update(ProductModel product) async {
    final box = await _getProductBox();
    await box.put(product.id, product);
  }

  /// Delete product
  Future<void> delete(String id) async {
    final box = await _getProductBox();
    await box.delete(id);
  }

  /// Search products by name
  Future<List<ProductModel>> searchByName(String query) async {
    final box = await _getProductBox();
    return box.values.where((p) {
      return p.name.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  /// Get all categories
  Future<List<ProductCategoryModel>> getAllCategories() async {
    final box = await _getCategoryBox();
    return box.values.toList();
  }

  /// Save category
  Future<void> saveCategory(ProductCategoryModel category) async {
    final box = await _getCategoryBox();
    await box.put(category.id, category);
  }

  /// Close boxes
  Future<void> close() async {
    if (_productBox != null && _productBox!.isOpen) {
      await _productBox!.close();
    }
    if (_categoryBox != null && _categoryBox!.isOpen) {
      await _categoryBox!.close();
    }
  }
}
