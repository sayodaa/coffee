import 'package:coffee_app/core/localization/json_localizations.dart';
import 'package:coffee_app/core/localization/lang_keys.dart';
import 'package:coffee_app/core/theme/app_colors.dart';
import 'package:coffee_app/features/sales/presentation/bloc/sales_cubit.dart';
import 'package:coffee_app/features/sales/presentation/bloc/sales_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddSaleBottomSheet extends StatefulWidget {
  const AddSaleBottomSheet({super.key});

  @override
  State<AddSaleBottomSheet> createState() => _AddSaleBottomSheetState();
}

class _AddSaleBottomSheetState extends State<AddSaleBottomSheet> {
  String? _selectedRecipeId;
  int _quantity = 1;
  bool _isLoading = false;

  Future<void> _submitSale() async {
    if (_selectedRecipeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr(LangKeys.select_drink)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final suggestions = context.read<SalesCubit>().cachedSuggestions;
      final suggestion = suggestions.firstWhere(
        (s) => s.recipeId == _selectedRecipeId,
        orElse: () => throw Exception('Suggestion not found'),
      );

      print(
          '[DEBUG] AddSaleBottomSheet: Submitting sale - ${suggestion.name} x $_quantity @ \$${suggestion.price.amount}');
      
      await context.read<SalesCubit>().addSale(
            suggestion.name,
            _quantity,
            suggestion.price.amount,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${context.tr(LangKeys.sale_added)}: $_quantity x ${suggestion.name}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('[ERROR] AddSaleBottomSheet: Exception during sale - $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr(LangKeys.error)}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SalesCubit, SalesState>(
      listener: (context, state) {
        print(
            '[DEBUG] AddSaleBottomSheet: SalesState changed - ${state.runtimeType}');
        if (state is SalesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${context.tr(LangKeys.sale_failed)}: ${state.message}',
              ),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoading = false);
        }
      },
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 24,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: BlocBuilder<SalesCubit, SalesState>(
          builder: (context, state) {
            final suggestions = context.read<SalesCubit>().cachedSuggestions;
            late final selectedSuggestion;
            try {
              selectedSuggestion = _selectedRecipeId != null
                  ? suggestions.firstWhere(
                      (s) => s.recipeId == _selectedRecipeId,
                    )
                  : null;
            } catch (e) {
              selectedSuggestion = null;
            }

            if (suggestions.isEmpty) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.tr(LangKeys.no_recipes_subtitle),
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primaryIndigo,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(context.tr(LangKeys.dismiss)),
                  ),
                ],
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.tr(LangKeys.new_sale),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  value: _selectedRecipeId,
                  decoration: InputDecoration(
                    labelText: context.tr(LangKeys.select_drink),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.local_bar),
                  ),
                  items: suggestions.map((suggestion) {
                    return DropdownMenuItem<String>(
                      value: suggestion.recipeId,
                      child: Text(
                        '${suggestion.name} (\$${suggestion.price.amount.toStringAsFixed(2)})',
                      ),
                    );
                  }).toList(),
                  onChanged: _isLoading
                      ? null
                      : (String? newValue) {
                          if (newValue != null) {
                            setState(() => _selectedRecipeId = newValue);
                          }
                        },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.tr(LangKeys.quantity),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: _isLoading || _quantity <= 1
                          ? null
                          : () => setState(() => _quantity--),
                    ),
                    Text(
                      '$_quantity',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: _isLoading
                          ? null
                          : () => setState(() => _quantity++),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitSale,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primaryIndigo,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          '${context.tr(LangKeys.complete_sale)} - \$${(selectedSuggestion?.calculateTotalPrice(_quantity).amount ?? 0).toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
