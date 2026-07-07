import 'package:coffee_app/core/notifications/inventory_low_stock_observer.dart';
import 'package:coffee_app/core/notifications/sales_completed_observer.dart';
import 'package:coffee_app/features/inventory/presentation/bloc/inventory_cubit.dart';
import 'package:coffee_app/features/notifications/presentation/cubit/notification_cubit.dart';
import 'package:coffee_app/features/sales/presentation/bloc/sales_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppRoot extends StatefulWidget {
  final Widget child;

  const AppRoot({super.key, required this.child});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  InventoryLowStockObserver? _lowStockObserver;
  SalesCompletedObserver? _salesCompletedObserver;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final notificationCubit = context.read<NotificationCubit>();

    final inventoryCubit = context.read<InventoryCubit>();
    _lowStockObserver ??= InventoryLowStockObserver(
      inventoryCubit: inventoryCubit,
      notificationCubit: notificationCubit,
    )..start();

    final salesCubit = context.read<SalesCubit>();
    _salesCompletedObserver ??= SalesCompletedObserver(
      salesCubit: salesCubit,
      notificationCubit: notificationCubit,
    )..start();
  }

  @override
  void dispose() {
    _lowStockObserver?.dispose();
    _salesCompletedObserver?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
