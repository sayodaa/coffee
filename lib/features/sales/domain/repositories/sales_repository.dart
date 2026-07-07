
import 'package:coffee_app/features/sales/domain/entities/recipe_entity.dart';
import 'package:coffee_app/features/sales/domain/entities/sale_transaction_entity.dart';

abstract class SalesRepository {
  Stream<List<SaleTransaction>> watchSales();
  Future<List<SaleTransaction>> getSales();
  Future<List<SaleTransaction>> getSalesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  });
  Future<void> addSale(SaleTransaction sale);
  Future<void> updateSale(SaleTransaction sale);
  Future<void> deleteSale(String saleId);

  Stream<List<Recipe>> watchRecipes();
  Future<List<Recipe>> getRecipes();
  Future<Recipe?> getRecipeById(String id);
  Future<void> addRecipe(Recipe recipe);
  Future<void> updateRecipe(Recipe recipe);
  Future<void> deleteRecipe(String id);

  Future<void> initMockDataIfEmpty();
  Future<void> resetDatabase();

  List<SaleTransaction> get currentSales;
  List<Recipe> get currentRecipes;
}
