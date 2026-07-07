import 'package:coffee_app/features/sales/presentation/bloc/sales_cubit.dart';
import 'package:coffee_app/features/sales/presentation/widgets/add_sale_button.dart';
import 'package:coffee_app/features/sales/presentation/widgets/sales_header.dart';
import 'package:coffee_app/features/sales/presentation/widgets/sales_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// SalesPage intentionally does NOT create its own SalesCubit.
/// The SalesCubit is provided globally by main.dart via MultiBlocProvider.
/// Creating it here again would result in a second isolated instance whose
/// stream is disconnected from inventory changes.
class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  @override
  void initState() {
    super.initState();
    // Ensure stream subscription is active (no-op if already subscribed)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SalesCubit>().loadSales();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => context.read<SalesCubit>().refreshSales(),
        color: theme.colorScheme.primary,
        backgroundColor: theme.cardColor,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/barista1.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Forces any Container/Card/Material inside SalesHeader
                  // that reads theme colors to become transparent, so the
                  // image behind it can actually show through.
                  const SalesHeader(),
                  const Positioned(bottom: -28, child: AddSaleButton()),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
            const SalesList(),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }
}
