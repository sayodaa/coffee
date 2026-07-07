# Integration Guide - Consumption System

## Overview
The Coffee Shop Inventory Consumption System has been fully implemented using Clean Architecture with the following structure:

```
lib/
├── core/
│   ├── database/
│   │   └── database_seeder.dart          # Sample data initialization
│   ├── domain/
│   │   ├── exceptions/
│   │   │   └── domain_exceptions.dart    # All domain exceptions
│   │   └── value_objects/
│   │       ├── money.dart                # Money value object
│   │       └── result.dart               # Result<T> type
│   └── services/
│       └── domain_event_bus.dart         # Cross-cubit communication
├── features/
│   ├── inventory/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── inventory_local_datasource.dart
│   │   │   ├── models/
│   │   │   │   └── inventory_item_model.dart
│   │   │   └── repositories/
│   │   │       └── inventory_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── inventory_item_entity.dart
│   │   │   ├── repositories/
│   │   │   │   └── inventory_repository_interface.dart
│   │   │   └── usecases/
│   │   │       └── inventory_usecases.dart
│   │   └── presentation/
│   │       ├── cubit/
│   │       │   └── inventory_cubit.dart
│   │       └── pages/
│   │           └── inventory_demo_page.dart
│   └── sales/
│       ├── data/
│       │   ├── datasources/
│       │   │   ├── consumption_log_local_datasource.dart
│       │   │   ├── product_local_datasource.dart
│       │   │   └── recipe_local_datasource.dart
│       │   ├── models/
│       │   │   ├── consumption_log_model.dart
│       │   │   ├── product_model.dart
│       │   │   ├── recipe_model.dart
│       │   │   ├── sale_item_model.dart
│       │   │   └── sale_transaction_model.dart
│       │   └── repositories/
│       │       ├── consumption_log_repository_impl.dart
│       │       ├── product_repository_impl.dart
│       │       └── recipe_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── consumption_log_entity.dart
│       │   │   ├── product_entity.dart
│       │   │   ├── recipe_entity.dart
│       │   │   ├── sale_item_entity.dart
│       │   │   └── sale_transaction_entity.dart
│       │   ├── repositories/
│       │   │   ├── consumption_log_repository_interface.dart
│       │   │   ├── product_repository_interface.dart
│       │   │   └── recipe_repository_interface.dart
│       │   ├── services/
│       │   │   └── transaction_lock_manager.dart
│       │   └── usecases/
│       │       ├── check_stock_availability_usecase.dart
│       │       └── process_sale_consumption_usecase.dart
│       └── presentation/
│           ├── cubit/
│           │   ├── recipe_cubit.dart
│           │   └── sales_cubit.dart
│           └── pages/
│               └── consumption_demo_page.dart
└── injection_consumption.dart              # DI container
```

## Integration Steps

### 1. Register Hive Adapters in main.dart

Add these adapter registrations to your `main.dart` before `runApp()`:

```dart
import 'package:hive/hive.dart';
import 'features/sales/data/models/recipe_model.dart';
import 'features/sales/data/models/product_model.dart';
import 'features/sales/data/models/consumption_log_model.dart';
import 'features/inventory/data/models/inventory_item_model.dart';
import 'injection_consumption.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive (existing code)
  final appDocumentDirectory = await getApplicationDocumentsDirectory();
  Hive.init(appDocumentDirectory.path);
  
  // Register existing adapters (your current code)
  Hive.registerAdapter(InventoryItemAdapter());  // Your existing adapter
  Hive.registerAdapter(StockMovementAdapter());   // Your existing adapter
  Hive.registerAdapter(MovementTypeAdapter());    // Your existing adapter
  
  // Register NEW adapters for consumption system
  Hive.registerAdapter(RecipeIngredientModelAdapter());
  Hive.registerAdapter(RecipeModelAdapter());
  Hive.registerAdapter(ProductCategoryModelAdapter());
  Hive.registerAdapter(ProductModelAdapter());
  Hive.registerAdapter(SaleItemModelAdapter());
  Hive.registerAdapter(SaleTransactionModelAdapter());
  Hive.registerAdapter(ConsumedIngredientModelAdapter());
  Hive.registerAdapter(InventoryConsumptionLogModelAdapter());
  Hive.registerAdapter(ReturnedIngredientModelAdapter());
  Hive.registerAdapter(InventoryReturnLogModelAdapter());
  
  // Initialize dependencies (NEW)
  await initDependencies();
  
  runApp(MyApp());
}
```

### 2. Generate Hive Adapters

Run the build runner to generate the `.g.dart` files:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Add Navigation Routes

Add routes to your navigation system:

```dart
// In your router/navigator
define routes:
- '/consumption-demo' -> ConsumptionDemoPage()
- '/inventory-demo' -> InventoryDemoPage()
```

### 4. Using the System

#### Making a Sale with Consumption:

```dart
// Get the SalesCubit
final salesCubit = getIt<SalesCubit>();

// Create a sale item
final saleItem = SaleItem(
  productId: 'turkish_coffee_001',
  productName: 'Turkish Coffee (Medium)',
  quantity: 2,
  size: SizeVariant.medium,
  sugarLevel: SugarLevel.normal,
  unitPrice: Money(3.50),
  totalPrice: Money(7.00),
);

// Add to cart (automatically validates stock)
final success = await salesCubit.addItemToSale(saleItem);

// Complete sale (automatically deducts inventory)
await salesCubit.completeSale(cashierId: 'cashier_001');

// Listen to results
BlocListener<SalesCubit, SalesState>(
  listener: (context, state) {
    if (state.lastResult?.success == true) {
      // Show success, print receipt
    }
    if (state.stockAlerts.isNotEmpty) {
      // Show low stock warnings
    }
  },
)
```

#### Managing Inventory:

```dart
// Get the InventoryCubit
final inventoryCubit = getIt<InventoryCubit>();

// Receive stock
await inventoryCubit.receiveStock(
  inventoryItemId: 'coffee_beans_001',
  quantity: 1000,
  unitCost: 0.05,
);

// Adjust stock (for waste, corrections)
await inventoryCubit.adjustStock(
  inventoryItemId: 'milk_001',
  adjustment: -50,  // negative for removal
  reason: 'Expired product',
);

// Check low stock
final lowStockItems = await inventoryCubit.state.lowStockItems;
```

### 5. Sample Data

The system automatically seeds sample data on first run:
- **Inventory Items**: Coffee beans, sugar, milk, water, cups, tea leaves, juice syrup
- **Products**: Turkish Coffee, Espresso, Latte, Black Tea, Orange Juice
- **Recipes**: Complete ingredient mappings for each product

## Key Features Implemented

### Consumption Logic
1. ✅ **Lock Management** - Prevents concurrent sales conflicts
2. ✅ **Stock Validation** - Checks availability before sale
3. ✅ **Size Scaling** - 0.8x (small), 1.0x (medium), 1.3x (large)
4. ✅ **Sugar Level Modification** - 0x to 2x multiplier
5. ✅ **Atomic Deduction** - All-or-nothing transaction
6. ✅ **Consumption Logging** - Full audit trail with costs
7. ✅ **Low Stock Detection** - Automatic alerts after sales
8. ✅ **Event Bus** - Cross-feature communication

### Validation Layers
1. ✅ Input Validation
2. ✅ Domain Validation (product/recipe exists)
3. ✅ Business Rule Validation (sufficient stock)
4. ✅ Concurrency Protection

### Return/Refund Support
```dart
final processReturn = getIt<ProcessReturnUseCase>();
final result = await processReturn(
  originalTransactionId: 'TXN_123',
  itemsToReturn: [
    ReturnedIngredient(
      inventoryItemId: 'coffee_beans_001',
      quantityReturned: 16,
    ),
  ],
  reason: 'Customer complaint',
);
```

## Testing

### Unit Tests
Test each layer independently:
- Domain: Entities, value objects
- UseCases: With mocked repositories
- Data: Repository implementations

### Integration Test
```dart
void main() {
  test('complete sale flow', () async {
    // Arrange
    final salesCubit = getIt<SalesCubit>();
    final initialStock = await getIt<InventoryRepository>()
        .getById('coffee_beans_001');
    
    // Act
    await salesCubit.addItemToSale(saleItem);
    await salesCubit.completeSale(cashierId: 'test');
    
    // Assert
    final finalStock = await getIt<InventoryRepository>()
        .getById('coffee_beans_001');
    expect(finalStock!.currentQuantity, 
           initialStock!.currentQuantity - 8);
  });
}
```

## Troubleshooting

### Hive Adapter Not Found
Run code generation:
```bash
flutter pub run build_runner build
```

### Database Locked
The `TransactionLockManager` handles concurrent access. If you see lock errors, wait 30 seconds for timeout.

### Stock Not Updating
Check that:
1. Recipe exists for the product
2. All ingredients exist in inventory
3. Sufficient stock is available

## Next Steps

1. ✅ **Code Generation** - Run build_runner
2. ✅ **Testing** - Write unit/integration tests
3. 🔄 **UI Polish** - Customize demo pages for production
4. 🔄 **Receipt Printing** - Integrate printer service
5. 🔄 **Reporting** - Add consumption reports

## Architecture Compliance

This implementation follows:
- ✅ **Clean Architecture** - Clear layer separation
- ✅ **SOLID Principles** - Dependency inversion, single responsibility
- ✅ **Cubit Pattern** - Predictable state management
- ✅ **Repository Pattern** - Abstract data access
- ✅ **UseCase Pattern** - Business logic isolation
- ✅ **Dependency Injection** - GetIt container
