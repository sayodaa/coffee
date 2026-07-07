import 'package:coffee_app/features/sales/domain/entities/recipe_entity.dart';
import 'package:equatable/equatable.dart';

abstract class RecipesState extends Equatable {
  const RecipesState();

  @override
  List<Object> get props => [];
}

/// Initial state
class RecipesInitial extends RecipesState {
  const RecipesInitial();
}

/// Loading recipes
class RecipesLoading extends RecipesState {
  const RecipesLoading();
}

/// Recipes loaded successfully
class RecipesLoaded extends RecipesState {
  final List<Recipe> recipes;

  const RecipesLoaded(this.recipes);

  @override
  List<Object> get props => [recipes];
}

/// No recipes available
class RecipesEmpty extends RecipesState {
  const RecipesEmpty();
}

/// Error loading recipes
class RecipesError extends RecipesState {
  final String message;

  const RecipesError(this.message);

  @override
  List<Object> get props => [message];
}

/// Success after add/delete operation
class RecipesOperationSuccess extends RecipesState {
  final String message;
  final List<Recipe> recipes;

  const RecipesOperationSuccess({
    required this.message,
    required this.recipes,
  });

  @override
  List<Object> get props => [message, recipes];
}
