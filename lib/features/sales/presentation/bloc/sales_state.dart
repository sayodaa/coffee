
import 'package:coffee_app/features/sales/domain/entities/recipe_entity.dart';
import 'package:coffee_app/features/sales/domain/entities/sale_suggestion.dart';
import 'package:coffee_app/features/sales/domain/entities/sale_transaction_entity.dart';
import 'package:equatable/equatable.dart';

abstract class SalesState extends Equatable {
  const SalesState();

  @override
  List<Object> get props => [];
}

class SalesInitial extends SalesState {
  const SalesInitial();
}

class SalesLoading extends SalesState {
  const SalesLoading();
}

class SalesLoaded extends SalesState {
  final List<SaleTransaction> sales;
  final List<Recipe> recipes;
  final List<SaleSuggestion> suggestions;
  final double todaySales;
  final int drinksSold;

  const SalesLoaded({
    required this.sales,
    required this.recipes,
    required this.suggestions,
    required this.todaySales,
    required this.drinksSold,
  });

  @override
  List<Object> get props => [sales, recipes, suggestions, todaySales, drinksSold];
}

class SalesError extends SalesState {
  final String message;

  const SalesError(this.message);

  @override
  List<Object> get props => [message];
}
