import 'package:coffee_app/features/sales/domain/entities/sale_transaction_entity.dart';
import 'package:coffee_app/features/sales/presentation/bloc/sales_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HiddenSalesPage extends StatefulWidget {
  const HiddenSalesPage({super.key});

  @override
  State<HiddenSalesPage> createState() => _HiddenSalesPageState();
}

class _HiddenSalesPageState extends State<HiddenSalesPage> {
  late Future<List<SaleTransaction>> _hiddenFuture;

  @override
  void initState() {
    super.initState();
    _hiddenFuture = context.read<SalesCubit>().loadHiddenSales();
  }

  Future<void> _refresh() async {
    setState(() {
      _hiddenFuture = context.read<SalesCubit>().loadHiddenSales();
    });
    await _hiddenFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hidden Sales (المخفيات)'),
      ),
      body: FutureBuilder<List<SaleTransaction>>(
        future: _hiddenFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: \\${snapshot.error}'));
          }
          final hidden = snapshot.data ?? [];
          if (hidden.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('No hidden sales')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: hidden.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final sale = hidden[index];
                return Card(
                  child: ListTile(
                    title: Text(sale.items.isNotEmpty ? sale.items.first.productName : 'Sale'),
                    subtitle: Text('${sale.totalItemCount} items • \${sale.totalAmount.amount.toStringAsFixed(2)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Restore',
                          icon: const Icon(Icons.restore, color: Colors.green),
                          onPressed: () async {
                            await context.read<SalesCubit>().restoreSale(sale.id);
                            await _refresh();
                          },
                        ),
                        IconButton(
                          tooltip: 'Delete permanently',
                          icon: const Icon(Icons.delete_forever, color: Colors.red),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete permanently'),
                                content: const Text('Are you sure you want to permanently delete this sale?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await context.read<SalesCubit>().deleteSale(sale.id);
                              await _refresh();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
