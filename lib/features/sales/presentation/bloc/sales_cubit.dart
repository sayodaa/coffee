
import 'dart:async';

import 'package:coffee_app/core/domain/value_objects/money.dart';
import 'package:coffee_app/features/inventory/domain/entities/stock_movement.dart';
import 'package:coffee_app/features/inventory/presentation/bloc/inventory_cubit.dart';
import 'package:coffee_app/features/notifications/presentation/cubit/notification_cubit.dart';
import 'package:coffee_app/features/sales/domain/entities/recipe_entity.dart';
import 'package:coffee_app/features/sales/domain/entities/sale_item_entity.dart';
import 'package:coffee_app/features/sales/domain/entities/sale_suggestion.dart';
import 'package:coffee_app/features/sales/domain/entities/sale_transaction_entity.dart';
import 'package:coffee_app/features/sales/domain/repositories/sales_repository.dart';
import 'package:coffee_app/features/sales/presentation/bloc/sales_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SalesCubit extends Cubit<SalesState> {
  final SalesRepository _salesRepository;
  final InventoryCubit inventoryCubit;
  final NotificationCubit _notificationCubit;

  StreamSubscription? _salesSubscription;
  StreamSubscription? _recipesSubscription;

  List<Recipe> _recipes = [];
  List<SaleSuggestion> _suggestions = [];

  SalesCubit({
    required SalesRepository salesRepository,
    required this.inventoryCubit,
    required NotificationCubit notificationCubit,
  })  : _salesRepository = salesRepository,
        _notificationCubit = notificationCubit,
        super(const SalesLoading()) {
    _initialize();
  }

  /// Initialize sales and recipes on creation
  Future<void> _initialize() async {
    try {
      _recipes = _salesRepository.currentRecipes;
      final currentSales = _salesRepository.currentSales
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      // Only expose non-hidden sales by default
      final visibleSales = currentSales.where((s) => !s.isHidden).toList();
      
      _suggestions = _generateSuggestions(_recipes);
      
      emit(SalesLoaded(
        sales: visibleSales,
        recipes: _recipes,
        suggestions: _suggestions,
        todaySales: _calculateTodaySales(currentSales),
        drinksSold: _calculateDrinksSold(currentSales),
      ));
    } catch (e) {
      emit(SalesError('Failed to initialize sales: $e'));
    }
  }

  /// Load and watch sales with subscriptions
  void loadSales() {
    if (_salesSubscription != null || _recipesSubscription != null) {
      print('[DEBUG] SalesCubit: Already listening, skipping duplicate call');
      return;
    }

    print('[DEBUG] SalesCubit: Starting to load sales...');

    // Watch recipes
    _recipesSubscription?.cancel();
    _recipesSubscription = _salesRepository.watchRecipes().listen(
      (recipes) {
        print(
            '[DEBUG] SalesCubit: Received ${recipes.length} recipes from repository stream');
        _recipes = recipes;
        _suggestions = _generateSuggestions(recipes);
        
        // Update state if already loaded
        if (state is SalesLoaded) {
          final loaded = state as SalesLoaded;
          emit(SalesLoaded(
            sales: loaded.sales,
            recipes: recipes,
            suggestions: _suggestions,
            todaySales: loaded.todaySales,
            drinksSold: loaded.drinksSold,
          ));
        }
      },
      onError: (e) {
        print('[ERROR] SalesCubit: Error watching recipes - $e');
      },
    );

    // Watch sales
    _salesSubscription?.cancel();
    _salesSubscription = _salesRepository.watchSales().listen(
        (sales) {
        print(
            '[DEBUG] SalesCubit: Received ${sales.length} sales from repository stream');
        sales.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        final visible = sales.where((s) => !s.isHidden).toList();
        final todaySales = _calculateTodaySales(visible);
        final drinksSold = _calculateDrinksSold(visible);
        print(
            '[DEBUG] SalesCubit: Today sales = $todaySales, Drinks sold = $drinksSold');
        emit(SalesLoaded(
          sales: visible,
          recipes: _recipes,
          suggestions: _suggestions,
          todaySales: todaySales,
          drinksSold: drinksSold,
        ));
      },
      onError: (e) {
        print('[ERROR] SalesCubit: Error watching sales - $e');
        emit(SalesError('Failed to load sales: $e'));
      },
    );
  }

  /// Refresh sales and recipes from database
  Future<void> refreshSales() async {
    try {
      final freshSales = await _salesRepository.getSales()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final visible = freshSales.where((s) => !s.isHidden).toList();
      final freshRecipes = await _salesRepository.getRecipes();
      _recipes = freshRecipes;
      _suggestions = _generateSuggestions(freshRecipes);
      
      emit(SalesLoaded(
        sales: visible,
        recipes: freshRecipes,
        suggestions: _suggestions,
        todaySales: _calculateTodaySales(freshSales),
        drinksSold: _calculateDrinksSold(freshSales),
      ));
    } catch (e) {
      emit(SalesError('Failed to refresh: $e'));
    }
  }

  /// Generate sales suggestions from recipes
  List<SaleSuggestion> _generateSuggestions(List<Recipe> recipes) {
    return recipes.map((recipe) {
      return SaleSuggestion(
        id: recipe.id,
        name: recipe.productName,
        recipeId: recipe.id,
        price: recipe.price,
        cost: recipe.cost,
        recipe: recipe,
      );
    }).toList();
  }

  /// Soft delete (hide) a sale for analytics while keeping record
  Future<void> softDeleteSale(String saleId) async {
    try {
      final current = await _salesRepository.getSales();
      final target = current.firstWhere((s) => s.id == saleId);
      final updated = target.copyWith(isHidden: true);
      await _salesRepository.updateSale(updated);
      await refreshSales();
    } catch (e) {
      emit(SalesError('Failed to hide sale: $e'));
    }
  }

  /// Alias for soft delete - kept for API clarity
  Future<void> hideSale(String saleId) async => softDeleteSale(saleId);

  /// Hard delete - permanently remove sale
  Future<void> hardDeleteSale(String saleId) async {
    try {
      await _salesRepository.deleteSale(saleId);
      await refreshSales();
    } catch (e) {
      emit(SalesError('Failed to delete sale: $e'));
    }
  }

  /// Alias for hard delete
  Future<void> deleteSale(String saleId) async => hardDeleteSale(saleId);

  /// Restore a hidden sale (un-hide)
  Future<void> restoreSale(String saleId) async {
    try {
      final current = await _salesRepository.getSales();
      final target = current.firstWhere((s) => s.id == saleId);
      final updated = target.copyWith(isHidden: false);
      await _salesRepository.updateSale(updated);
      await refreshSales();
    } catch (e) {
      emit(SalesError('Failed to restore sale: $e'));
    }
  }

  /// Return hidden sales only
  Future<List<SaleTransaction>> loadHiddenSales() async {
    final all = await _salesRepository.getSales();
    final hidden = all.where((s) => s.isHidden).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return hidden;
  }

  /// Add a sale transaction
  Future<void> addSale(String drinkName, int quantity, double price) async {
    try {
      print(
          '[DEBUG] SalesCubit: Adding sale - Drink: $drinkName, Qty: $quantity, Price: $price');

      if (state is! SalesLoaded) {
        print('[ERROR] SalesCubit: Cannot add sale - state is not SalesLoaded');
        return;
      }

      // 1. Find Recipe
      final recipe = _recipes.firstWhere(
        (r) => r.productName == drinkName,
        orElse: () => throw Exception("Recipe not found for $drinkName"),
      );

      // 2. Calculate Ingredients cost, check stock & deduct
      double totalCost = 0.0;
      for (var ingredient in recipe.ingredients) {
        final amountToDeduct = ingredient.quantityRequiredPerUnit * quantity;

        // get inventory item to check cost and availability
        final invItem = inventoryCubit.cachedItems.firstWhere(
          (i) => i.id == ingredient.inventoryItemId,
          orElse: () => throw Exception('Inventory item ${ingredient.inventoryItemId} not found'),
        );

        if (invItem.quantity < amountToDeduct) {
          throw Exception('Insufficient stock for ${invItem.name}');
        }

        totalCost += amountToDeduct * invItem.price;

        // Deduct stock
        await inventoryCubit.adjustStock(
          ingredient.inventoryItemId,
          -amountToDeduct,
          "Sale: $drinkName x$quantity",
          type: MovementType.saleDeduction,
        );
      }

      // 3. Create SaleTransaction with cost/profit
      final totalPrice = price * quantity;
      final profit = totalPrice - totalCost;

      final transaction = SaleTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        items: [
          SaleItem(
            productId: recipe.productId,
            productName: drinkName,
            quantity: quantity,
            unitPrice: Money(price),
            totalPrice: Money(price * quantity),
            size: SizeVariant.medium, // Defaulting to medium
          )
        ],
        timestamp: DateTime.now(),
        totalAmount: Money(totalPrice),
        totalCost: Money(totalCost),
        profit: Money(profit),
        cashierId: 'default',
        status: SaleStatus.completed,
      );

      print('[DEBUG] SalesCubit: Saving sale to Hive - Sale ID: ${transaction.id}');
      await _salesRepository.addSale(transaction);
      print('[DEBUG] SalesCubit: Sale saved successfully');
    } catch (e) {
      print('[ERROR] SalesCubit: Failed to add sale - $e');
      emit(SalesError('Failed to add sale: $e'));
      // Reload sales to restore state
      await refreshSales();
    }
  }

  /// Get cached recipes list
  List<Recipe> get cachedRecipes => _recipes;

  /// Get cached suggestions
  List<SaleSuggestion> get cachedSuggestions => _suggestions;

  /// Add a new recipe
  Future<void> addRecipe(Recipe recipe) async {
    try {
      await _salesRepository.addRecipe(recipe);
    } catch (e) {
      emit(SalesError('Failed to add recipe: $e'));
    }
  }

  /// Update an existing recipe
  Future<void> updateRecipe(Recipe recipe) async {
    try {
      await _salesRepository.updateRecipe(recipe);
    } catch (e) {
      emit(SalesError('Failed to update recipe: $e'));
    }
  }

  /// Delete a recipe
  Future<void> deleteRecipe(String id) async {
    try {
      await _salesRepository.deleteRecipe(id);
    } catch (e) {
      emit(SalesError('Failed to delete recipe: $e'));
    }
  }

  /// Calculate today's total sales
  double _calculateTodaySales(List<SaleTransaction> sales) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return sales
        .where((s) => !s.timestamp.isBefore(today))
        .fold(0.0, (sum, s) => sum + s.totalAmount.amount);
  }

  /// Calculate drinks sold today
  int _calculateDrinksSold(List<SaleTransaction> sales) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return sales
        .where((s) => !s.timestamp.isBefore(today))
        .fold(0, (sum, s) => sum + s.totalItemCount);
  }

  @override
  Future<void> close() {
    _salesSubscription?.cancel();
    _recipesSubscription?.cancel();
    return super.close();
  }
}
