# 📋 QUICK REFERENCE - DEBUG & TROUBLESHOOTING GUIDE

## 🔍 How to Read Debug Logs

### Filter Log Types in Flutter Console

```bash
# Show only debug messages
flutter run | grep "\[DEBUG\]"

# Show only errors
flutter run | grep "\[ERROR\]"

# Show warnings
flutter run | grep "\[WARNING\]"

# Show all app logs (filter out system noise)
flutter run | grep -E "\[(DEBUG|ERROR|WARNING)\]"
```

---

## 📊 Feature Flow with Logging

### Adding an Inventory Item

**User Action:** Click "Add Item" → Fill form → Submit

**Console Output (Expected):**
```
[DEBUG] InventoryCubit: Adding item - Coffee Beans
[DEBUG] HiveInventoryRepository: Adding item to Hive - Coffee Beans (ID: 1708876543210)
[DEBUG] HiveInventoryRepository: Item stored. Box now has 4 items
[DEBUG] InventoryCubit: Item added successfully to Hive
[DEBUG] InventoryCubit: Starting to load inventory...
[DEBUG] InventoryCubit: Received 4 items from repository stream
✅ SUCCESS: Form closes, item appears in list
```

**If You See This:** Something is wrong
```
[DEBUG] InventoryCubit: Adding item - Coffee Beans
❌ MISSING: Item added log
❌ MISSING: Reload log
```

### Recording a Stock Movement

**User Action:** Click item → "Stock In 5kg" → Confirm

**Console Output (Expected):**
```
[DEBUG] InventoryCubit: Adjusting stock - ID: 1, Amount: 5.0, Type: inStock
[DEBUG] HiveInventoryRepository: Updated quantity from 50 to 55
[DEBUG] HiveInventoryRepository: Recording stock movement - Item: 1, Type: inStock, Amount: 5.0
[DEBUG] HiveInventoryRepository: Movement recorded. Box now has 3 movements
[DEBUG] InventoryCubit: Stock movement recorded successfully
[DEBUG] InventoryCubit: Starting to load inventory...
✅ SUCCESS: Quantity updated, page closes
```

### Adding a Sale

**User Action:** Click "Add Sale" → Select drink → Confirm

**Console Output (Expected):**
```
[DEBUG] SalesCubit: Adding sale - Drink: Mojito, Qty: 3, Price: 12.0
[DEBUG] HiveSalesRepository: Adding sale to Hive - Drink: Mojito, Qty: 3, Price: 12.0, ID: 1708876543
[DEBUG] HiveSalesRepository: Sale stored. Box now has 1 sales
[DEBUG] SalesCubit: Sale saved successfully to Hive
[DEBUG] SalesCubit: Deducting inventory for drink - Mojito x 3
[DEBUG] SalesCubit: Recipe found - 1 ingredients
[DEBUG] SalesCubit: Deducting 0.15 from item 3
[DEBUG] InventoryCubit: Adjusting stock - ID: 3, Amount: -0.15, Type: saleDeduction
[DEBUG] HiveInventoryRepository: Updated quantity from 15 to 14.85
[DEBUG] SalesCubit: Reloading sales after successful add
✅ SUCCESS: Sale added, inventory deducted, UI updated
```

---

## 🚨 Troubleshooting Common Issues

### Problem: Page shows "No items" but you added items

**Steps:**
1. Check logs for add operation:
   ```
   [DEBUG] InventoryCubit: Adding item - [name]
   ```
2. If you see the add log but no reload:
   ```
   ❌ MISSING: [DEBUG] InventoryCubit: Starting to load inventory...
   ```
3. **Fix:** Check `loadInventory()` is called after operation

### Problem: Added an item but it disappeared after restart

**Diagnosis:**
1. Add item
2. Check Hive log:
   ```
   [DEBUG] HiveInventoryRepository: Item stored. Box now has 4 items
   ```
3. Close app immediately
4. Reopen and check:
   ```
   [DEBUG] InventoryCubit: Received 4 items from repository stream
   ```

**If step 4 shows fewer items:**
- Hive initialization didn't happen
- Check `main()` logs:
  ```
  [DEBUG] main: Opened inventoryBox
  [DEBUG] main: Opened movementsBox
  ```

### Problem: Stock doesn't update after sale

**Check Recipe:**
```dart
// Go to sales_cubit.dart line ~50
if (recipe == null) {
  // Recipe must exist or fallback must be defined
  print('[WARNING] No recipe found for Mojito');
}
```

**Verify Recipe in Hive:**
1. Add this to ReportsCubit:
   ```dart
   print('[DEBUG] Available recipes: ${_recipes.map((r) => r.drinkName).toList()}');
   ```
2. Run and check console

### Problem: Dashboard shows incorrect total value

**Check logs:**
```
[DEBUG] DashboardMainStatCard: Calculating total for 0 items = $0.00
```

**If count is wrong:**
1. Verify inventory loaded:
   ```
   [DEBUG] InventoryCubit: Received X items from repository stream
   ```
2. Check BlocBuilder is listening:
   ```dart
   BlocBuilder<InventoryCubit, InventoryState>(
     builder: (context, state) {
       if (state is InventoryLoaded) {
         // This code should run
       }
     },
   )
   ```

---

## 🔧 Manual Testing Checklist

Run through these manually to verify everything works:

### [ ] Hive Initialization
```
1. Fresh install/uninstall app
2. Launch app
3. Check console for:
   ✅ [DEBUG] main: Hive initialized at [path]
   ✅ [DEBUG] main: All adapters registered
   ✅ [DEBUG] main: Opened inventoryBox
4. ✅ Dashboard loads (not stuck)
```

### [ ] Add Material
```
1. Tap "Add Item" button
2. Fill form:
   - Name: Test Coffee
   - SKU: SKU-TEST
   - Category: Raw Material
   - Qty: 10
   - Min: 5
   - Unit: kg
   - Price: 15.00
3. Tap "Save"
4. ✅ Form closes
5. ✅ Item appears in list
6. ✅ Check log: "[DEBUG] InventoryCubit: Item added successfully"
```

### [ ] Stock In
```
1. Tap item in list
2. Tap "Stock In" button
3. Enter "5"
4. Tap "Confirm Stock In"
5. ✅ Page closes
6. ✅ Quantity increased by 5
7. ✅ Check log: "[DEBUG] Stock movement recorded successfully"
```

### [ ] Add Sale
```
1. Go to Sales page
2. Tap "Add Sale" button
3. Select "Mojito"
4. Qty: 2
5. Tap "Complete Sale"
6. ✅ Modal closes
7. ✅ Snackbar shows "Sale added"
8. ✅ Sale appears in list
9. ✅ Check inventory decreased
10. ✅ Check log: "[DEBUG] Deducting inventory for drink - Mojito x 2"
```

### [ ] Reports
```
1. Go to Reports page
2. ✅ Loading skeleton shows briefly
3. ✅ Data loads (within 2 seconds)
4. ✅ Summary cards show numbers
5. Apply date filter
6. ✅ Data recalculates
7. Check log: "[DEBUG] ReportsCubit: Filtered to X movements in date range"
```

---

## 📝 Adding Custom Debug Output

### In Cubits
```dart
print('[DEBUG] MyFeatureCubit: Starting operation...');
```

### In Repositories
```dart
print('[DEBUG] HiveRepository: Writing to box');
await box.put(key, value);
print('[DEBUG] HiveRepository: Write complete');
```

### In Pages/Widgets
```dart
print('[DEBUG] MyPage: Build called with state: ${state.runtimeType}');
```

**Output Format:**
```
[LEVEL] ComponentName: Message
```

**Levels:**
- `[DEBUG]` - Information/flow tracking
- `[ERROR]` - Errors and exceptions
- `[WARNING]` - Non-critical issues

---

## 🐛 Quick Debug Commands

### Check if Hive boxes are open
Add this in `main()` after opening boxes:
```dart
print('inventoryBox items: ${Hive.box<InventoryItem>('inventoryBox').length}');
print('movementsBox items: ${Hive.box<StockMovement>('movementsBox').length}');
print('recipesBox items: ${Hive.box<Recipe>('recipesBox').length}');
print('salesBox items: ${Hive.box<SalesItem>('salesBox').length}');
```

### Check Hive data in production
Add this button to debug screen:
```dart
ElevatedButton(
  onPressed: () {
    final items = Hive.box<InventoryItem>('inventoryBox').values.toList();
    final sales = Hive.box<SalesItem>('salesBox').values.toList();
    final movements = Hive.box<StockMovement>('movementsBox').values.toList();
    print('Inventory: ${items.length} items');
    print('Sales: ${sales.length} sales');
    print('Movements: ${movements.length} movements');
    items.forEach((item) => print('  - ${item.name}: ${item.quantity}${item.unit}'));
  },
  child: const Text('Debug: Show Hive Data'),
),
```

### Force reload a Cubit
```dart
// In a button or manually via console
context.read<InventoryCubit>().loadInventory();
context.read<SalesCubit>().loadSales();
context.read<ReportsCubit>().loadReportsData();
```

---

## 📊 Expected Hive Structure

After initialization with mock data:

```
inventoryBox (4 items):
  ├─ 1: Coffee Beans (50kg @ $15/kg)
  ├─ 2: Milk (20L @ $2.50/L)
  ├─ 3: Sugar (15kg @ $1.00/kg)
  └─ [user-added items]

movementsBox (0+ items):
  ├─ [timestamp]: Coffee Beans → inStock +5kg
  ├─ [timestamp]: Sugar → saleDeduction -0.05kg (Mojito x1)
  └─ [more movements...]

recipesBox (2 items):
  ├─ r1: Espresso (0.018kg Coffee)
  └─ r2: Latte (0.018kg Coffee + 0.2L Milk)

salesBox (0+ items):
  ├─ [timestamp]: Mojito x3 @ $12.00 = $36.00
  └─ [more sales...]
```

---

## ✅ Acceptance Criteria

Before declaring the app production-ready:

- [ ] No [ERROR] logs on normal operations
- [ ] All [DEBUG] logs follow expected flow
- [ ] Data persists after app restart
- [ ] No stuck loading states (max 3 seconds load)
- [ ] All buttons have functional onPressed
- [ ] No hardcoded values in production UI
- [ ] Error messages display to users
- [ ] Snackbars confirm operations
- [ ] Forms close after successful save
- [ ] Lists refresh after CRUD operations

---

## 🚀 Performance Tips

1. **Minimize Hive reads:** Use watch streams, not repeated calls
2. **Batch operations:** Record multiple movements in single transaction if possible
3. **Limit list rebuilds:** Use BlocBuilder strategically, not on every change
4. **Delay reload:** Use `Future.delayed(300ms)` to allow Hive write to complete

---

## 📞 Support

**If the app crashes:**
1. Check console for [ERROR] logs
2. Note the full error message
3. Check this guide's troubleshooting section
4. If not found, add print statements to narrow down issue

**If data is missing:**
1. Check Hive initialization logs
2. Verify box is opened in main()
3. Use debug button to inspect Hive contents
4. Check last write operation completed

**If UI doesn't update:**
1. Verify BlocBuilder is listening to correct Cubit
2. Check state is being emitted
3. Ensure reload() is called after write operations
4. Look for stuck OperationInProgress state

