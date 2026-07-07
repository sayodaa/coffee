import 'package:coffee_app/core/localization/json_localizations.dart';
import 'package:coffee_app/core/localization/lang_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/recipe_entity.dart';
import '../bloc/sales_cubit.dart';
import '../bloc/sales_state.dart';

/// Demo Sales Page showing the consumption system
class ConsumptionDemoPage extends StatelessWidget {
  const ConsumptionDemoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<SalesCubit>(),
      child: const ConsumptionDemoView(),
    );
  }
}

class ConsumptionDemoView extends StatelessWidget {
  const ConsumptionDemoView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(LangKeys.sales_consumption_title)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<SalesCubit>().loadSales();
            },
          ),
        ],
      ),
      body: BlocBuilder<SalesCubit, SalesState>(
        builder: (context, state) {
          // We can show a loading indicator or cart here if needed
          // For now, just the product grid
          return Column(
            children: [
              Expanded(
                child: _ProductGrid(
                  onProductSelected: (productId, name, price) {
                    _showProductOptionsDialog(
                      context,
                      productId: productId,
                      productName: name,
                      basePrice: price,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showProductOptionsDialog(
    BuildContext context, {
    required String productId,
    required String productName,
    required double basePrice,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(productName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.tr(LangKeys.select_size)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _SizeButton(
                    label: context.tr(LangKeys.size_small),
                    price: basePrice * 0.8,
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      _showSugarLevelDialog(
                        context,
                        productName,
                        SizeVariant.small,
                        basePrice * 0.8,
                      );
                    },
                  ),
                  _SizeButton(
                    label: context.tr(LangKeys.size_medium),
                    price: basePrice,
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      _confirmAddSale(
                        context,
                        productName: productName,
                        price: basePrice,
                      );
                    },
                  ),
                  _SizeButton(
                    label: context.tr(LangKeys.size_large),
                    price: basePrice * 1.3,
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      _confirmAddSale(
                        context,
                        productName: productName,
                        price: basePrice * 1.3,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSugarLevelDialog(
    BuildContext context,
    String productName,
    SizeVariant size,
    double price,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(context.tr(LangKeys.sugar_level_title)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(context.tr(LangKeys.sugar_none)),
                onTap: () {
                  Navigator.pop(dialogContext);
                  _confirmAddSale(
                    context,
                    productName: productName,
                    price: price,
                  );
                },
              ),
              ListTile(
                title: Text(context.tr(LangKeys.sugar_low)),
                onTap: () {
                  Navigator.pop(dialogContext);
                  _confirmAddSale(
                    context,
                    productName: productName,
                    price: price,
                  );
                },
              ),
              ListTile(
                title: Text(context.tr(LangKeys.sugar_normal)),
                onTap: () {
                  Navigator.pop(dialogContext);
                  _confirmAddSale(
                    context,
                    productName: productName,
                    price: price,
                  );
                },
              ),
              ListTile(
                title: Text(context.tr(LangKeys.sugar_extra)),
                onTap: () {
                  Navigator.pop(dialogContext);
                  _confirmAddSale(
                    context,
                    productName: productName,
                    price: price,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmAddSale(
    BuildContext context, {
    required String productName,
    required double price,
  }) async {
    // Note: The bloc SalesCubit.addSale signature is (String drinkName, int quantity, double price)
    await context.read<SalesCubit>().addSale(productName, 1, price);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.tr(LangKeys.add_item)}: $productName')),
      );
    }
  }
}

class _ProductGrid extends StatelessWidget {
  final Function(String productId, String name, double basePrice) onProductSelected;

  const _ProductGrid({required this.onProductSelected});

  @override
  Widget build(BuildContext context) {
    // Sample products for demo
    final products = [
      {'id': 'turkish_coffee_001', 'name': 'Turkish Coffee', 'price': 3.50, 'icon': Icons.coffee},
      {'id': 'espresso_001', 'name': 'Espresso', 'price': 2.50, 'icon': Icons.coffee_maker},
      {'id': 'latte_001', 'name': 'Caffe Latte', 'price': 4.00, 'icon': Icons.local_cafe},
      {'id': 'black_tea_001', 'name': 'Black Tea', 'price': 2.50, 'icon': Icons.emoji_food_beverage},
      {'id': 'orange_juice_001', 'name': 'Orange Juice', 'price': 4.00, 'icon': Icons.local_drink},
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          elevation: 4,
          child: InkWell(
            onTap: () => onProductSelected(
              product['id'] as String,
              product['name'] as String,
              product['price'] as double,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  product['icon'] as IconData,
                  size: 48,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 8),
                Text(
                  product['name'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${(product['price'] as double).toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SizeButton extends StatelessWidget {
  final String label;
  final double price;
  final VoidCallback onPressed;

  const _SizeButton({
    required this.label,
    required this.price,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text('$label\n\$${price.toStringAsFixed(2)}'),
    );
  }
}
