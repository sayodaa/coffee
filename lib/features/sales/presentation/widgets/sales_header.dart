import 'package:coffee_app/core/localization/json_localizations.dart';
import 'package:coffee_app/core/localization/lang_keys.dart';
import 'package:coffee_app/core/services/pdf_report_service.dart';
import 'package:coffee_app/features/reports/domain/report_models.dart';
import 'package:coffee_app/features/sales/presentation/bloc/sales_cubit.dart';
import 'package:coffee_app/features/sales/presentation/bloc/sales_state.dart';
import 'package:coffee_app/features/sales/presentation/pages/hidden_sales_page.dart';
import 'package:coffee_app/features/sales/presentation/widgets/sales_stat_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SalesHeader extends StatelessWidget {
  const SalesHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final horizontalPadding = screenSize.width * 0.05;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          16,
          horizontalPadding,
          24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr(LangKeys.nav_sales),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                  tooltip: 'Export Sales Report',
                  onPressed: () {
                    final state = context.read<SalesCubit>().state;
                    if (state is SalesLoaded) {
                      final salesItems = state.sales.expand((tx) {
                        return tx.items.map((item) => SalesItem(
                              timestamp: tx.timestamp,
                              drinkName: item.productName,
                              quantity: item.quantity.toInt(),
                              price: item.unitPrice.amount,
                              totalPrice: item.totalPrice.amount,
                            ));
                      }).toList();

                      PdfReportService.generateSalesReport(
                        salesItems,
                        DateTime.now().subtract(const Duration(days: 1)),
                        DateTime.now(),
                        'Daily Sales Report',
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.visibility_off, color: Colors.white),
                  tooltip: 'Hidden Sales',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (c) => const HiddenSalesPage()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            BlocBuilder<SalesCubit, SalesState>(
              builder: (context, state) {
                final todaySales = state is SalesLoaded
                    ? '\$${state.todaySales.toStringAsFixed(0)}'
                    : '\$0';
                final drinksSold =
                    state is SalesLoaded ? state.drinksSold.toString() : '0';

                return Row(
                  children: [
                    Expanded(
                      child: SalesStatCard(
                        title: context.tr(LangKeys.today_sales),
                        value: todaySales,
                        icon: Icons.attach_money,
                      ),
                    ),
                    SizedBox(width: horizontalPadding * 0.5),
                    Expanded(
                      child: SalesStatCard(
                        title: context.tr(LangKeys.drinks_sold),
                        value: drinksSold,
                        icon: Icons.local_bar,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
