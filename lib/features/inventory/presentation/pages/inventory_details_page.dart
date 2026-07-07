import 'package:coffee_app/core/localization/json_localizations.dart';
import 'package:coffee_app/core/localization/lang_keys.dart';
import 'package:coffee_app/features/inventory/domain/entities/inventory_item.dart';
import 'package:coffee_app/features/inventory/presentation/bloc/inventory_cubit.dart';
import 'package:coffee_app/features/inventory/presentation/bloc/inventory_state.dart';
import 'package:coffee_app/features/inventory/presentation/pages/inventory_form_page.dart';
import 'package:coffee_app/features/inventory/presentation/pages/stock_adjustment_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InventoryDetailsPage extends StatelessWidget {
  final InventoryItem item;

  const InventoryDetailsPage({super.key, required this.item});

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr(LangKeys.confirm_delete_title)),
        content: Text(
          '${ctx.tr(LangKeys.confirm_delete_message)} ${item.name}?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.tr(LangKeys.cancel))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<InventoryCubit>().deleteInventoryItem(item.id);
            },
            child: Text(
              ctx.tr(LangKeys.delete),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocListener<InventoryCubit, InventoryState>(
      listener: (context, state) {
        // Success: Item was deleted or updated - InventoryLoaded or InventoryEmpty emitted
        if (state is InventoryLoaded || state is InventoryEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr(LangKeys.operation_success))),
          );
          Navigator.pop(context);
        }
        // Error: Delete or update failed
        else if (state is InventoryError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr(LangKeys.material_details_title)),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          InventoryFormPage(initialItem: item)),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('SKU: ${item.sku}',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: Colors.grey)),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildDetailRow(context.tr(LangKeys.quantity),
                          '${item.quantity} ${item.unit}'),
                      const SizedBox(height: 8),
                      _buildDetailRow(context.tr(LangKeys.min_threshold),
                          '${item.minThreshold} ${item.unit}'),
                      const SizedBox(height: 8),
                      _buildDetailRow(context.tr(LangKeys.price),
                          '\$${item.price.toStringAsFixed(2)} / ${item.unit}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildStockButtons(context),
              const SizedBox(height: 16),
              if (item.isLowStock)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        context.tr(LangKeys.low_stock_warning),
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      StockAdjustmentPage(item: item, isStockIn: true),
                ),
              );
            },
            icon: const Icon(Icons.download),
            label: Text(context.tr(LangKeys.stock_in)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade800,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      StockAdjustmentPage(item: item, isStockIn: false),
                ),
              );
            },
            icon: const Icon(Icons.upload),
            label: Text(context.tr(LangKeys.stock_out)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value),
      ],
    );
  }
}
