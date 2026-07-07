# 5. SAMPLE PSEUDO-CODE FOR SALE TRANSACTION

## 5.1 Complete Sale Flow

```dart
// lib/presentation/sales/screens/sale_screen.dart

class SaleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SalesCubit>(),
      child: BlocConsumer<SalesCubit, SalesState>(
        listener: (context, state) {
          if (state.lastResult != null) {
            if (state.lastResult!.success) {
              showSuccessDialog(
                transactionId: state.lastResult!.transaction!.id,
                total: state.lastResult!.transaction!.totalAmount,
              );

              if (state.lastResult!.lowStockAlerts?.isNotEmpty ?? false) {
                showLowStockWarnings(state.lastResult!.lowStockAlerts!);
              }

              context.read<ReceiptPrinter>().print(state.lastResult!.transaction!);
            } else {
              showErrorDialog(errors: state.lastResult!.errors!);
            }
          }
        },
        builder: (context, state) {
          return Scaffold(
            body: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ProductCatalog(
                    onProductSelected: (product) {
                      showSaleItemDialog(
                        product: product,
                        onConfirm: (saleItem) {
                          context.read<SalesCubit>().addItemToSale(saleItem);
                        },
                      );
                    },
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: SaleSummary(
                    items: state.currentItems,
                    onCheckout: () => context.read<SalesCubit>().completeSale(
                      cashierId: currentUser.id,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

## 5.2 Sale Transaction Execution (Detailed)

```dart
Future<void> executeSaleTransaction() async {
  // ═══════════════════════════════════════════════════════════════
  // PHASE 1: GATHER & PREPARE
  // ═══════════════════════════════════════════════════════════════

  final cartItems = [
    SaleItem(
      productId: 'turkish_coffee_001',
      productName: 'Turkish Coffee',
      quantity: 2,
      size: SizeVariant.medium,
      sugarLevel: SugarLevel.normal,
      unitPrice: Money(3.50),
      totalPrice: Money(7.00),
    ),
    SaleItem(
      productId: 'orange_juice_001',
      productName: 'Orange Juice',
      quantity: 1,
      size: SizeVariant.large,
      customizations: {'extra_syrup': 1.5},
      unitPrice: Money(5.00),
      totalPrice: Money(5.00),
    ),
  ];

  // ═══════════════════════════════════════════════════════════════
  // PHASE 2: VALIDATION (Multi-layer)
  // ═══════════════════════════════════════════════════════════════

  final validationResult = await validateSaleUseCase.validate(
    items: cartItems,
    skipStockCheck: false,
  );

  if (!validationResult.isValid) {
    for (final error in validationResult.errors!) {
      log('Validation Error [${error.layer}]: ${error.error.message}');
    }
    throw SaleValidationException(validationResult.errors!);
  }

  // ═══════════════════════════════════════════════════════════════
  // PHASE 3: STOCK LOCKING (Concurrency Safety)
  // ═══════════════════════════════════════════════════════════════

  final requiredInventoryIds = <String>{};
  for (final item in cartItems) {
    final recipe = await recipeRepo.getByProductId(item.productId);
    for (final ingredient in recipe!.ingredients) {
      requiredInventoryIds.add(ingredient.inventoryItemId);
    }
  }

  final lock = await lockManager.acquireLocks(requiredInventoryIds);
  log('Acquired locks for ${lock.inventoryItemIds.length} items');

  try {
    // ═════════════════════════════════════════════════════════════
    // PHASE 4: STOCK VALIDATION (Double-check after locking)
    // ═════════════════════════════════════════════════════════════

    final stockCheck = await stockValidator.validateStockForItems(cartItems);
    if (!stockCheck.isAvailable) {
      throw InsufficientStockException(details: stockCheck.failures!);
    }

    // ═════════════════════════════════════════════════════════════
    // PHASE 5: CALCULATE CONSUMPTION
    // ═════════════════════════════════════════════════════════════

    final consumptionPlan = <String, ConsumptionDetail>{};

    for (final saleItem in cartItems) {
      final recipe = await recipeRepo.getByProductId(saleItem.productId);
      final scaledIngredients = recipe!.getScaledIngredients(saleItem.size);

      for (final ingredient in scaledIngredients) {
        var quantity = ingredient.quantityRequiredPerUnit * saleItem.quantity;

        if (ingredient.inventoryItemId == 'sugar_001' && saleItem.sugarLevel != null) {
          quantity *= saleItem.sugarLevel!.multiplier;
        }

        saleItem.customizations?.forEach((key, value) {
          if (ingredient.inventoryItemId == key && value is double) {
            quantity *= value;
          }
        });

        final existing = consumptionPlan[ingredient.inventoryItemId];
        if (existing != null) {
          consumptionPlan[ingredient.inventoryItemId] = existing.copyWith(
            quantityRequired: existing.quantityRequired + quantity,
          );
        } else {
          final inventoryItem = await inventoryRepo.getById(ingredient.inventoryItemId);
          consumptionPlan[ingredient.inventoryItemId] = ConsumptionDetail(
            inventoryItemId: ingredient.inventoryItemId,
            itemName: inventoryItem!.name,
            unit: inventoryItem.unit,
            quantityRequired: quantity,
            costPerUnit: inventoryItem.costPerUnit,
          );
        }
      }
    }

    // Consumption Plan Summary:
    // coffee_beans_001: 16g (8g × 2 medium coffees)
    // sugar_001: 20g (10g × 2 × 1.0 normal sugar)
    // water_001: 200ml (100ml × 2)
    // juice_syrup_001: 58.5ml (30ml × 1.3 large × 1.5 extra syrup)
    // water_001: 150ml (150ml × 1 large)
    // cups_001: 3 pieces

    // ═════════════════════════════════════════════════════════════
    // PHASE 6: ATOMIC DEDUCTION
    // ═════════════════════════════════════════════════════════════

    await inventoryRepo.runInTransaction(() async {
      for (final entry in consumptionPlan.entries) {
        final item = await inventoryRepo.getById(entry.key);
        final newQuantity = item!.currentQuantity - entry.value.quantityRequired;

        if (newQuantity < 0) {
          throw InsufficientStockException(
            inventoryItemId: entry.key,
            required: entry.value.quantityRequired,
            available: item.currentQuantity,
          );
        }

        await inventoryRepo.update(item.copyWith(
          currentQuantity: newQuantity,
          lastUpdated: DateTime.now(),
          status: newQuantity <= item.minimumThreshold
              ? InventoryStatus.lowStock
              : InventoryStatus.normal,
        ));
      }
    });

    // ═════════════════════════════════════════════════════════════
    // PHASE 7: LOG & COMPLETE
    // ═════════════════════════════════════════════════════════════

    final transaction = SaleTransaction(
      id: generateTransactionId(),
      items: cartItems,
      timestamp: DateTime.now(),
      totalAmount: cartItems.fold(Money(0), (sum, item) => sum + item.totalPrice),
      cashierId: currentUser.id,
      status: SaleStatus.completed,
    );

    final consumptionLog = InventoryConsumptionLog(
      id: generateLogId(),
      saleTransactionId: transaction.id,
      ingredientsConsumed: consumptionPlan.values.map((d) => ConsumedIngredient(
        inventoryItemId: d.inventoryItemId,
        inventoryItemName: d.itemName,
        quantityConsumed: d.quantityRequired,
        unit: d.unit,
        costPerUnit: d.costPerUnit,
        totalCost: d.costPerUnit != null ? d.costPerUnit! * d.quantityRequired : null,
      )).toList(),
      timestamp: DateTime.now(),
      totalCostOfIngredients: Money(
        consumptionPlan.values.fold(0, (sum, d) => sum + (d.costPerUnit ?? 0) * d.quantityRequired),
      ),
    );

    await Future.wait([
      saleRepo.save(transaction),
      consumptionLogRepo.save(consumptionLog),
    ]);

    eventBus.emit(InventoryConsumedEvent(
      saleTransactionId: transaction.id,
      consumedIngredients: consumptionLog.ingredientsConsumed,
    ));

    // ═════════════════════════════════════════════════════════════
    // PHASE 8: POST-SALE ACTIONS
    // ═════════════════════════════════════════════════════════════

    final potentiallyLowStock = consumptionPlan.keys.toList();
    final lowStockItems = await checkLowStockUseCase.checkItemsAfterConsumption(potentiallyLowStock);

    if (lowStockItems.isNotEmpty) {
      eventBus.emit(LowStockDetectedEvent(lowStockItems));

      for (final item in lowStockItems) {
        await notificationService.sendLowStockAlert(
          itemId: item.id,
          itemName: item.name,
          currentLevel: item.currentQuantity,
          threshold: item.minimumThreshold,
        );
      }
    }

    log('✓ Sale transaction completed successfully');
    log('  Transaction ID: ${transaction.id}');
    log('  Total: ${transaction.totalAmount}');
    log('  Items consumed: ${consumptionLog.ingredientsConsumed.length}');

    return SaleResult.success(
      transaction: transaction,
      consumptionLog: consumptionLog,
      lowStockAlerts: lowStockItems,
    );

  } finally {
    await lockManager.releaseLocks(lock);
    log('Released locks for transaction');
  }
}
```
