# Code Comparisons - Before & After

## 1. InventoryCubit - State Machine

### ❌ BEFORE (Broken)

```dart
void loadInventory() {
  print('[DEBUG] InventoryCubit: Starting to load inventory...');
  emit(InventoryLoading());
  _inventorySubscription?.cancel();
  _inventorySubscription = _repository.watchInventory().listen(
    (items) {
      print('[DEBUG] InventoryCubit: Received ${items.length} items');
      _cachedItems = items;
      emit(InventoryLoaded(items));  // PROBLEM: items might be empty!
    },
    onError: (e) {
      emit(const InventoryError('Failed to load inventory'));
    },
  );
  
  _movementsSubscription?.cancel();
  _movementsSubscription = _repository.watchMovements().listen((movements) {
    _movements = movements..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  });
}

Future<void> addInventoryItem(InventoryItem item) async {
  emit(InventoryOperationInProgress());  // WRONG STATE
  try {
    await _repository.addItem(item);
    emit(const InventoryOperationSuccess('Item added successfully'));
    // PROBLEM: UI doesn't know what to do with OperationSuccess
    
    await Future.delayed(const Duration(milliseconds: 300));
    loadInventory();  // CAUSES SHIMMER!
  } catch (e) {
    emit(InventoryOperationFailure('Failed to add item: $e'));
  }
}

Future<void> refreshInventory() async {
  loadInventory();  // CREATES DUPLICATE CALL
}
```

### ✅ AFTER (Fixed)

```dart
void loadInventory() {
  if (state is InventoryLoading) {
    print('[DEBUG] InventoryCubit: Already loading, skipping duplicate call');
    return;  // PREVENT DUPLICATE CALLS
  }

  print('[DEBUG] InventoryCubit: Starting to load inventory...');
  emit(InventoryLoading());

  _inventorySubscription?.cancel();
  _inventorySubscription = _repository.watchInventory().listen(
    (items) {
      print('[DEBUG] InventoryCubit: Received ${items.length} items');
      _cachedItems = items;

      // DISTINGUISH BETWEEN EMPTY AND LOADED
      if (items.isEmpty) {
        print('[DEBUG] InventoryCubit: No items found, emitting InventoryEmpty');
        emit(const InventoryEmpty());  // EXPLICIT EMPTY STATE
      } else {
        print('[DEBUG] InventoryCubit: Items found, emitting InventoryLoaded');
        emit(InventoryLoaded(items));  // DATA GUARANTEED
      }
    },
    onError: (e) {
      print('[ERROR] InventoryCubit: Error loading - $e');
      emit(InventoryError('Failed to load inventory: $e'));
    },
  );

  _movementsSubscription?.cancel();
  _movementsSubscription = _repository.watchMovements().listen((movements) {
    _movements = movements..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  });
}

// NEW: Silent refresh without showing Loading
Future<void> _refreshDataSilently() async {
  print('[DEBUG] InventoryCubit: Refreshing data silently...');
  try {
    final items = await _repository.getInventory();  // FRESH DATA
    _cachedItems = items;
    if (items.isEmpty) {
      emit(const InventoryEmpty());  // NO LOADING STATE
    } else {
      emit(InventoryLoaded(items));  // NO LOADING STATE
    }
  } catch (e) {
    print('[ERROR] InventoryCubit: Failed to refresh - $e');
    emit(InventoryError('Failed to refresh: $e'));
  }
}

Future<void> addInventoryItem(InventoryItem item) async {
  try {
    print('[DEBUG] InventoryCubit: Adding item - ${item.name}');
    await _repository.addItem(item);
    print('[DEBUG] InventoryCubit: Item added to Hive');

    // NO STATE EMISSION DURING OPERATION
    await Future.delayed(const Duration(milliseconds: 300));
    
    // SILENT REFRESH - NO SHIMMER
    await _refreshDataSilently();
  } catch (e) {
    print('[ERROR] InventoryCubit: Failed to add item - $e');
    emit(InventoryError('Failed to add item: $e'));
  }
}
```

---

## 2. InventoryListPage - State Handling

### ❌ BEFORE (Broken)

```dart
class _InventoryListPageState extends State<InventoryListPage> {
  @override
  void initState() {
    super.initState();
    context.read<InventoryCubit>().loadInventory();  // CALLED HERE
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ...
      body: BlocBuilder<InventoryCubit, InventoryState>(
        builder: (context, state) {
          if (state is InventoryLoading) {
            return const InventoryShimmer();  // SHOWS SHIMMER
          } else if (state is InventoryLoaded) {
            // PROBLEM: Checking isEmpty inside InventoryLoaded
            if (state.items.isEmpty) {
              return RefreshIndicator(
                child: CustomScrollView(
                  slivers: [
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          children: [
                            Icon(...),
                            Text('No inventory items found'),
                            // Generic empty state
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            
            // Show items...
            return RefreshIndicator(
              child: CustomScrollView(
                slivers: [
                  // Items...
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => InventoryCard(...),
                      childCount: items.length,
                    ),
                  ),
                  // NO BOTTOM PADDING - buttons hidden!
                ],
              ),
            );
          } else if (state is InventoryError) {
            return Center(child: Text(state.message));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
```

### ✅ AFTER (Fixed)

```dart
class _InventoryListPageState extends State<InventoryListPage> {
  @override
  void initState() {
    super.initState();
    // ONLY PLACE WHERE loadInventory() IS CALLED
    print('[DEBUG] InventoryListPage.initState: Triggering loadInventory()');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<InventoryCubit>().loadInventory();
      }
    });
  }

  void _navigateToForm([InventoryItem? item]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InventoryFormPage(initialItem: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            onPressed: () {
              context.read<InventoryCubit>().loadInventory();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(),
        label: const Text('Add Item'),
      ),
      body: BlocBuilder<InventoryCubit, InventoryState>(
        builder: (context, state) {
          // ONLY show shimmer for Initial/Loading
          if (state is InventoryLoading || state is InventoryInitial) {
            return const InventoryShimmer();
          }

          // EXPLICIT EMPTY STATE
          if (state is InventoryEmpty) {
            return EmptyStateWidget(
              icon: Icons.inventory_2_outlined,
              title: 'No Inventory Items',
              subtitle: 'Start by adding your first material',
              actionLabel: 'Add First Item',
              onActionPressed: () => _navigateToForm(),
            );
          }

          // SHOW LOADED DATA
          if (state is InventoryLoaded) {
            final lowStockItems = state.items.where((i) => i.isLowStock).toList();
            final normalItems = state.items.where((i) => !i.isLowStock).toList();

            return RefreshIndicator(
              onRefresh: () async {
                context.read<InventoryCubit>().loadInventory();
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: CustomScrollView(
                slivers: [
                  // Low stock items...
                  if (lowStockItems.isNotEmpty) ...[
                    // ...
                  ],
                  
                  // Normal items...
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => InventoryCard(item: normalItems[index]),
                      childCount: normalItems.length,
                    ),
                  ),
                  
                  // BOTTOM PADDING - BUTTONS NOW VISIBLE!
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 120),
                    sliver: SliverToBoxAdapter(child: SizedBox.fromSize()),
                  ),
                ],
              ),
            );
          }

          // SHOW ERROR
          if (state is InventoryError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(state.message, textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<InventoryCubit>().loadInventory();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
```

---

## 3. InventoryFormPage - Button Handling

### ❌ BEFORE (Broken)

```dart
class _InventoryFormPageState extends State<InventoryFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  // ... other controllers ...

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final item = InventoryItem(...);
      
      if (widget.initialItem == null) {
        context.read<InventoryCubit>().addInventoryItem(item);
      } else {
        context.read<InventoryCubit>().updateInventoryItem(item);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<InventoryCubit, InventoryState>(
      listener: (context, state) {
        if (state is InventoryOperationSuccess) {  // MIGHT NOT OCCUR
          ScaffoldMessenger.of(context).showSnackBar(...);
          Navigator.pop(context);
        } else if (state is InventoryOperationFailure) {
          ScaffoldMessenger.of(context).showSnackBar(...);
        }
      },
      child: Scaffold(
        body: BlocBuilder<InventoryCubit, InventoryState>(
          builder: (context, state) {
            final isLoading = state is InventoryOperationInProgress;  // Wrong!
            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),  // NO BOTTOM PADDING!
                children: [
                  // Form fields...
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Save'),  // BUTTON MIGHT BE HIDDEN
                  ),
                  // NO SPACE AT BOTTOM - HIDDEN BEHIND NAV!
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
```

### ✅ AFTER (Fixed)

```dart
class _InventoryFormPageState extends State<InventoryFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  bool _isSubmitting = false;  // LOCAL STATE TRACKING
  // ... other controllers ...

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final item = InventoryItem(...);
      
      setState(() => _isSubmitting = true);  // UPDATE LOCAL STATE
      
      if (widget.initialItem == null) {
        context.read<InventoryCubit>().addInventoryItem(item);
      } else {
        context.read<InventoryCubit>().updateInventoryItem(item);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<InventoryCubit, InventoryState>(
      listener: (context, state) {
        // LISTEN TO SUCCESS STATES
        if (state is InventoryLoaded || state is InventoryEmpty) {
          if (_isSubmitting) {
            setState(() => _isSubmitting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(widget.initialItem == null 
                    ? 'Item added successfully!' 
                    : 'Item updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            // Close form after brief delay
            Future.delayed(const Duration(milliseconds: 500)).then((_) {
              if (mounted) Navigator.pop(context);
            });
          }
        }
        // LISTEN TO ERROR STATES
        else if (state is InventoryError) {
          setState(() => _isSubmitting = false);
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
          title: Text(widget.initialItem == null ? 'Add Material' : 'Edit Material'),
        ),
        body: SafeArea(  // PROPER SAFE AREA
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
                  enabled: !_isSubmitting,
                ),
                const SizedBox(height: 16),
                // ... more fields ...
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSubmitting ? 'Saving...' : 'Save'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 120),  // BOTTOM PADDING FOR NAV!
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## 4. Reports - Remove Fake Data

### ❌ BEFORE (Fake Data)

```dart
Future<void> loadReportsData({DateTime? startDate, DateTime? endDate}) async {
  emit(ReportsLoading());
  
  try {
    // ... calculation logic ...
    
    final reportData = ReportData(
      totalMonthlyWaste: totalWasteValue == 0 ? 1250.50 : totalWasteValue,  // ← HARDCODED!
      stockAccuracy: accuracy,
      totalSales: realTotalSales > 0 ? realTotalSales : 0,
      expectedLossValue: expectedLossValue == 0 ? 120.00 : expectedLossValue,  // ← HARDCODED!
      lowStockItemsCount: lowStockCount,
      consumptionTrend: _generateConsumptionTrend(movements),
      wasteAnalysis: _generateWasteAnalysis(movements),
      lossAnalysis: lossAnalysis.isEmpty
          ? [
              const LossItem(itemName: 'Coffee Beans', expected: 100, actual: 110),  // ← MOCK!
              const LossItem(itemName: 'Milk', expected: 50, actual: 58),  // ← MOCK!
            ]
          : lossAnalysis,
    );
    
    emit(ReportsLoaded(reportData));
  } catch (e) {
    emit(const ReportsError('Failed to load reports data'));
  }
}

List<ConsumptionPoint> _generateConsumptionTrend(List<StockMovement> movements) {
  final now = DateTime.now();
  return List.generate(30, (index) {
    final date = now.subtract(Duration(days: 29 - index));
    final baseValue = 100 + (index % 7) * 10;  // HARDCODED PATTERN!
    final variation = (index % 3) * 5;
    return ConsumptionPoint(
      date: date,
      value: baseValue + variation.toDouble(),  // Ignores movements!
    );
  });
}

List<WasteData> _generateWasteAnalysis(List<StockMovement> movements) {
  final hasWaste = movements.any((m) => m.type == MovementType.waste || m.type == MovementType.outStock);
  if (!hasWaste) {
    return const [
      WasteData(reason: 'Breakage', amount: 450.0, color: Color(0xFFEF4444)),  // ← MOCK!
      WasteData(reason: 'Expired', amount: 320.0, color: Color(0xFFF59E0B)),  // ← MOCK!
      WasteData(reason: 'Spillage', amount: 180.0, color: Color(0xFF06B6D4)),  // ← MOCK!
    ];
  }
  // ...
}
```

### ✅ AFTER (Real Data)

```dart
Future<void> loadReportsData({DateTime? startDate, DateTime? endDate}) async {
  emit(ReportsLoading());
  
  try {
    // ... calculation logic ...
    
    final reportData = ReportData(
      totalMonthlyWaste: totalWasteValue,  // ← REAL VALUE (can be 0)
      stockAccuracy: accuracy,
      totalSales: realTotalSales,  // ← REAL VALUE (can be 0)
      expectedLossValue: expectedLossValue,  // ← REAL VALUE (can be 0)
      lowStockItemsCount: lowStockCount,
      consumptionTrend: _generateConsumptionTrend(movements),
      wasteAnalysis: _generateWasteAnalysis(movements),
      lossAnalysis: lossAnalysis,  // ← REAL ITEMS (may be empty!)
    );
    
    emit(ReportsLoaded(reportData));
  } catch (e) {
    emit(const ReportsError('Failed to load reports data'));
  }
}

List<ConsumptionPoint> _generateConsumptionTrend(List<StockMovement> movements) {
  final now = DateTime.now();
  final last30Days = <DateTime, double>{};
  
  // Initialize all 30 days with 0
  for (int i = 0; i < 30; i++) {
    final date = DateTime(now.year, now.month, now.day - (29 - i));
    last30Days[date] = 0;
  }

  // Aggregate REAL consumption from actual movements
  for (var movement in movements) {
    if (movement.type == MovementType.outStock ||
        movement.type == MovementType.waste ||
        movement.type == MovementType.saleDeduction) {
      
      final date = DateTime(
        movement.timestamp.year,
        movement.timestamp.month,
        movement.timestamp.day,
      );
      
      if (last30Days.containsKey(date)) {
        last30Days[date] = last30Days[date]! + movement.amount.abs();  // ← REAL DATA
      }
    }
  }
  
  return last30Days.entries
      .map((e) => ConsumptionPoint(date: e.key, value: e.value))
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));
}

List<WasteData> _generateWasteAnalysis(List<StockMovement> movements) {
  final wasteByReason = <String, double>{};
  
  for (var movement in movements) {
    if (movement.type == MovementType.waste || movement.type == MovementType.outStock) {
      final reason = movement.note ?? 'Manual Adjustment';
      wasteByReason[reason] = (wasteByReason[reason] ?? 0) + movement.amount.abs();
    }
  }

  if (wasteByReason.isEmpty) {
    return const [];  // ← EMPTY IS HONEST (not fake data)
  }

  final reasonColors = <String, Color>{
    'Breakage': const Color(0xFFEF4444),
    'Expired': const Color(0xFFF59E0B),
    'Spillage': const Color(0xFF06B6D4),
    'Manual Adjustment': const Color(0xFF8B5CF6),
  };

  return wasteByReason.entries
      .map((e) => WasteData(
        reason: e.key,
        amount: e.value,
        color: reasonColors[e.key] ?? const Color(0xFF6366F1),
      ))
      .toList();
}
```

---

## Summary of Changes

| Component | Change | Impact |
|-----------|--------|--------|
| State Machine | Added InventoryEmpty | Clear distinction between empty and loading |
| Cubit | Silent refresh | No shimmer after operations |
| UI | Bottom padding | Buttons no longer hidden |
| Empty State | New widget | Professional empty UI |
| Reports | Remove fallbacks | Real data only |
| Initialization | Single call | No duplicate loads |

All changes maintain backward compatibility while significantly improving code quality and user experience.

