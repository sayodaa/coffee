
import 'package:coffee_app/features/sales/data/models/recipe_model.dart';
import 'package:coffee_app/features/sales/data/models/sale_transaction_model.dart';
import 'package:coffee_app/features/sales/domain/entities/recipe_entity.dart';
import 'package:coffee_app/features/sales/domain/entities/sale_transaction_entity.dart';
import 'package:coffee_app/features/sales/domain/repositories/sales_repository.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveSalesRepository implements SalesRepository {
  static const String _salesBoxName = 'sales_transactions';
  static const String _recipesBoxName = 'recipes';

  late Box<SaleTransactionModel> _salesBox;
  late Box<RecipeModel> _recipesBox;

  HiveSalesRepository() {
    _salesBox = Hive.box<SaleTransactionModel>(_salesBoxName);
    _recipesBox = Hive.box<RecipeModel>(_recipesBoxName);
  }

  @override
  Stream<List<SaleTransaction>> watchSales() {
    return Stream.value(_salesBox.values.map((e) => e.toEntity()).toList()).asyncExpand((initial) {
      return _salesBox
          .watch()
          .map((event) => _salesBox.values.map((e) => e.toEntity()).toList());
    });
  }

  @override
  Future<List<SaleTransaction>> getSales() async {
    return _salesBox.values.map((e) => e.toEntity()).toList();
  }

  @override
  Future<List<SaleTransaction>> getSalesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final endExclusive =
        DateTime(endDate.year, endDate.month, endDate.day).add(
      const Duration(days: 1),
    );

    return _salesBox.values
        .map((e) => e.toEntity())
        .where((s) => !s.timestamp.isBefore(start) && s.timestamp.isBefore(endExclusive))
        .toList();
  }

  @override
  Future<void> addSale(SaleTransaction sale) async {
    final model = SaleTransactionModel.fromEntity(sale);
    await _salesBox.put(sale.id, model);
  }

  @override
  Future<void> updateSale(SaleTransaction sale) async {
    final model = SaleTransactionModel.fromEntity(sale);
    await _salesBox.put(sale.id, model);
  }

  @override
  Future<void> deleteSale(String saleId) async {
    await _salesBox.delete(saleId);
  }

  @override
  Stream<List<Recipe>> watchRecipes() {
    return Stream.value(_recipesBox.values.map((e) => e.toEntity()).toList()).asyncExpand((initial) {
      return _recipesBox
          .watch()
          .map((event) => _recipesBox.values.map((e) => e.toEntity()).toList());
    });
  }

  @override
  Future<List<Recipe>> getRecipes() async {
    return _recipesBox.values.map((e) => e.toEntity()).toList();
  }

  @override
  Future<Recipe?> getRecipeById(String id) async {
    try {
      final model = _recipesBox.values.firstWhere((r) => r.id == id);
      return model.toEntity();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> addRecipe(Recipe recipe) async {
    final model = RecipeModel.fromEntity(recipe);
    await _recipesBox.put(recipe.id, model);
  }

  @override
  Future<void> updateRecipe(Recipe recipe) async {
    final model = RecipeModel.fromEntity(recipe);
    await _recipesBox.put(recipe.id, model);
  }

  @override
  Future<void> deleteRecipe(String id) async {
    await _recipesBox.delete(id);
  }

  @override
  Future<void> initMockDataIfEmpty() async {
    // Removed demo data seeding
  }

  @override
  Future<void> resetDatabase() async {
    await _salesBox.clear();
    await _recipesBox.clear();
  }

  @override
  List<SaleTransaction> get currentSales => _salesBox.values.map((e) => e.toEntity()).toList();

  @override
  List<Recipe> get currentRecipes => _recipesBox.values.map((e) => e.toEntity()).toList();
}
