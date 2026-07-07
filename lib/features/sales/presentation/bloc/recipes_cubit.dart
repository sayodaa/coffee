import 'dart:async';

import 'package:coffee_app/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:coffee_app/features/sales/domain/entities/recipe_entity.dart';
import 'package:coffee_app/features/sales/domain/repositories/recipe_repository_interface.dart';
import 'package:coffee_app/features/sales/presentation/bloc/recipes_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RecipesCubit extends Cubit<RecipesState> {
  final RecipeRepository _repository;
  final InventoryRepository _inventoryRepository;
  StreamSubscription? _recipesSubscription;

  RecipesCubit({
    required RecipeRepository repository,
    required InventoryRepository inventoryRepository,
  })  : _repository = repository,
        _inventoryRepository = inventoryRepository,
        super(const RecipesLoading()) {
    // Load initial recipes when cubit is created
    _loadInitialRecipes();
  }

  /// Load recipes on initial creation
  Future<void> _loadInitialRecipes() async {
    try {
      final recipes = await _repository.getAll();
      if (recipes.isEmpty) {
        emit(const RecipesEmpty());
      } else {
        emit(RecipesLoaded(recipes));
      }
    } catch (e) {
      emit(RecipesError('Failed to load recipes: $e'));
    }
  }

  /// Load recipes from repository
  Future<void> loadRecipes() async {
    try {
      emit(const RecipesLoading());

      final recipes = await _repository.getAll();

      if (recipes.isEmpty) {
        emit(const RecipesEmpty());
      } else {
        emit(RecipesLoaded(recipes));
      }
    } catch (e) {
      emit(RecipesError('Failed to load recipes: $e'));
    }
  }

  /// Watch recipes in real-time
  void watchRecipes() {
    _recipesSubscription?.cancel();

    try {
      // First emit loading
      emit(const RecipesLoading());

      // Then set up stream listener
      _recipesSubscription = _repository.watchRecipes().listen(
        (recipes) {
          if (recipes.isEmpty) {
            emit(const RecipesEmpty());
          } else {
            emit(RecipesLoaded(recipes));
          }
        },
        onError: (error) {
          emit(RecipesError('Stream error: $error'));
        },
      );
    } catch (e) {
      emit(RecipesError('Failed to watch recipes: $e'));
    }
  }

  /// Add a new recipe
  Future<void> addRecipe(Recipe recipe) async {
    print('[RecipesCubit] addRecipe: start for recipe=${recipe.id}');
    emit(const RecipesLoading());
    try {
      // Compute cost from latest inventory
      final inventory = await _inventoryRepository.getInventory();
      print('[RecipesCubit] addRecipe: computed inventory items=${inventory.length}');
      final computedCost = recipe.calculateCostFromInventory(inventory);
      final toSave = recipe.copyWith(cost: computedCost);

      // Persist recipe
      await _repository.save(toSave);
      print('[RecipesCubit] addRecipe: saved recipe=${recipe.id}');

      // Load latest recipes and emit loaded or empty
      final recipes = await _repository.getAll();
      print('[RecipesCubit] addRecipe: loaded recipes count=${recipes.length}');
      if (recipes.isEmpty) {
        emit(const RecipesEmpty());
      } else {
        emit(RecipesLoaded(recipes));
      }
    } catch (e, st) {
      print('[RecipesCubit] addRecipe: error=$e\n$st');
      emit(RecipesError('Failed to add recipe: $e'));
    }
  }

  /// Update an existing recipe
  Future<void> updateRecipe(Recipe recipe) async {
    print('[RecipesCubit] updateRecipe: start for recipe=${recipe.id}');
    emit(const RecipesLoading());
    try {
      final inventory = await _inventoryRepository.getInventory();
      final computedCost = recipe.calculateCostFromInventory(inventory);
      final toUpdate = recipe.copyWith(cost: computedCost);
      await _repository.update(toUpdate);
      print('[RecipesCubit] updateRecipe: updated recipe=${recipe.id}');

      final recipes = await _repository.getAll();
      if (recipes.isEmpty) {
        emit(const RecipesEmpty());
      } else {
        emit(RecipesLoaded(recipes));
      }
    } catch (e, st) {
      print('[RecipesCubit] updateRecipe: error=$e\n$st');
      emit(RecipesError('Failed to update recipe: $e'));
    }
  }

  /// Delete a recipe
  Future<void> deleteRecipe(String id) async {
    print('[RecipesCubit] deleteRecipe: start id=$id');
    emit(const RecipesLoading());
    try {
      await _repository.delete(id);
      print('[RecipesCubit] deleteRecipe: deleted id=$id');

      final recipes = await _repository.getAll();
      if (recipes.isEmpty) {
        emit(const RecipesEmpty());
      } else {
        emit(RecipesLoaded(recipes));
      }
    } catch (e, st) {
      print('[RecipesCubit] deleteRecipe: error=$e\n$st');
      emit(RecipesError('Failed to delete recipe: $e'));
    }
  }

  /// Refresh recipes from database
  Future<void> refreshRecipes() async {
    await loadRecipes();
  }

  /// Get current recipes list
  List<Recipe> get recipes {
    if (state is RecipesLoaded) {
      return (state as RecipesLoaded).recipes;
    }
    return [];
  }

  @override
  Future<void> close() {
    _recipesSubscription?.cancel();
    return super.close();
  }
}
