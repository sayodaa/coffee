import 'dart:async';

import 'package:coffee_app/features/notifications/presentation/cubit/notification_cubit.dart';
import 'package:coffee_app/features/sales/presentation/bloc/sales_cubit.dart';
import 'package:coffee_app/features/sales/presentation/bloc/sales_state.dart';

class SalesCompletedObserver {
  final SalesCubit _salesCubit;
  final NotificationCubit _notificationCubit;

  StreamSubscription? _sub;

  final Set<String> _knownSaleIds = <String>{};

  SalesCompletedObserver({
    required SalesCubit salesCubit,
    required NotificationCubit notificationCubit,
  })  : _salesCubit = salesCubit,
        _notificationCubit = notificationCubit;

  void start() {
    _handleState(_salesCubit.state);
    _sub ??= _salesCubit.stream.listen(_handleState);
  }

  void _handleState(SalesState state) {
    if (state is! SalesLoaded) return;

    for (final sale in state.sales) {
      if (_knownSaleIds.add(sale.id)) {
        _notificationCubit.triggerSaleCompleted(
          saleId: sale.id,
          drinkName: sale.items.map((i) => i.productName).join(', '),
          quantity: sale.totalItemCount,
          totalPrice: sale.totalAmount.amount,
        );
      }
    }
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}
