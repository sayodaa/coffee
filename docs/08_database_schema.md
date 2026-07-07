# 8. DATABASE SCHEMA SUGGESTION

## 8.1 SQLite Schema (Single Store)

```sql
-- ═══════════════════════════════════════════════════════════════════════════
-- CORE TABLES
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE inventory_items (
    id              TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    unit            TEXT NOT NULL CHECK (unit IN ('gram', 'milliliter', 'piece', 'liter', 'kilogram')),
    current_quantity REAL NOT NULL DEFAULT 0 CHECK (current_quantity >= 0),
    minimum_threshold REAL NOT NULL DEFAULT 0,
    cost_per_unit   REAL,
    status          TEXT NOT NULL DEFAULT 'normal' CHECK (status IN ('normal', 'low_stock', 'critical', 'out_of_stock')),
    last_updated    INTEGER NOT NULL,
    created_at      INTEGER NOT NULL,
    notes           TEXT,
    version         INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE categories (
    id              TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    description     TEXT,
    display_order   INTEGER DEFAULT 0,
    is_active       INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE products (
    id              TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    description     TEXT,
    category_id     TEXT NOT NULL REFERENCES categories(id),
    recipe_id       TEXT,
    is_active       INTEGER NOT NULL DEFAULT 1,
    created_at      INTEGER NOT NULL,
    updated_at      INTEGER NOT NULL
);

CREATE TABLE product_prices (
    product_id      TEXT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    size            TEXT NOT NULL CHECK (size IN ('small', 'medium', 'large')),
    price           REAL NOT NULL CHECK (price >= 0),
    currency        TEXT NOT NULL DEFAULT 'USD',
    PRIMARY KEY (product_id, size)
);

-- ═══════════════════════════════════════════════════════════════════════════
-- RECIPE TABLES
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE recipes (
    id              TEXT PRIMARY KEY,
    product_id      TEXT NOT NULL UNIQUE REFERENCES products(id),
    name            TEXT NOT NULL,
    version         INTEGER NOT NULL DEFAULT 1,
    is_active       INTEGER NOT NULL DEFAULT 1,
    created_at      INTEGER NOT NULL,
    updated_at      INTEGER NOT NULL
);

CREATE TABLE recipe_size_multipliers (
    recipe_id       TEXT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    size            TEXT NOT NULL CHECK (size IN ('small', 'medium', 'large')),
    multiplier      REAL NOT NULL CHECK (multiplier > 0),
    PRIMARY KEY (recipe_id, size)
);

CREATE TABLE recipe_ingredients (
    id              TEXT PRIMARY KEY,
    recipe_id       TEXT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    inventory_item_id TEXT NOT NULL REFERENCES inventory_items(id),
    quantity_required_per_unit REAL NOT NULL CHECK (quantity_required_per_unit > 0),
    is_optional     INTEGER NOT NULL DEFAULT 0,
    notes           TEXT
);

-- ═══════════════════════════════════════════════════════════════════════════
-- TRANSACTION TABLES
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE sale_transactions (
    id              TEXT PRIMARY KEY,
    total_amount    REAL NOT NULL,
    currency        TEXT NOT NULL DEFAULT 'USD',
    cashier_id      TEXT NOT NULL,
    customer_id     TEXT,
    status          TEXT NOT NULL CHECK (status IN ('pending', 'validated', 'completed', 'cancelled', 'refunded')),
    timestamp       INTEGER NOT NULL,
    notes           TEXT,
    synced_at       INTEGER
);

CREATE TABLE sale_items (
    id              TEXT PRIMARY KEY,
    transaction_id  TEXT NOT NULL REFERENCES sale_transactions(id) ON DELETE CASCADE,
    product_id      TEXT NOT NULL REFERENCES products(id),
    product_name    TEXT NOT NULL,
    quantity        INTEGER NOT NULL CHECK (quantity > 0),
    size            TEXT NOT NULL,
    sugar_level     TEXT CHECK (sugar_level IN ('none', 'low', 'normal', 'extra', 'double')),
    unit_price      REAL NOT NULL,
    total_price     REAL NOT NULL,
    customizations  TEXT
);

CREATE TABLE inventory_consumption_logs (
    id              TEXT PRIMARY KEY,
    transaction_id  TEXT NOT NULL UNIQUE REFERENCES sale_transactions(id),
    timestamp       INTEGER NOT NULL,
    total_cost      REAL,
    notes           TEXT
);

CREATE TABLE consumed_ingredients (
    id              TEXT PRIMARY KEY,
    consumption_log_id TEXT NOT NULL REFERENCES inventory_consumption_logs(id) ON DELETE CASCADE,
    inventory_item_id  TEXT NOT NULL REFERENCES inventory_items(id),
    inventory_item_name TEXT NOT NULL,
    quantity_consumed    REAL NOT NULL,
    unit            TEXT NOT NULL,
    cost_per_unit   REAL,
    total_cost      REAL,
    notes           TEXT
);

-- ═══════════════════════════════════════════════════════════════════════════
-- SUPPORTING TABLES
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE stock_receive_logs (
    id              TEXT PRIMARY KEY,
    inventory_item_id TEXT NOT NULL REFERENCES inventory_items(id),
    quantity_received REAL NOT NULL,
    unit_cost       REAL,
    supplier_id     TEXT,
    supplier_name   TEXT,
    received_at     INTEGER NOT NULL,
    received_by     TEXT NOT NULL,
    notes           TEXT
);

CREATE TABLE stock_adjustment_logs (
    id              TEXT PRIMARY KEY,
    inventory_item_id TEXT NOT NULL REFERENCES inventory_items(id),
    adjustment_quantity REAL NOT NULL,
    reason          TEXT NOT NULL,
    previous_quantity REAL NOT NULL,
    new_quantity    REAL NOT NULL,
    adjusted_at     INTEGER NOT NULL,
    adjusted_by     TEXT NOT NULL,
    notes           TEXT
);

-- ═══════════════════════════════════════════════════════════════════════════
-- INDEXES
-- ═══════════════════════════════════════════════════════════════════════════

CREATE INDEX idx_inventory_status ON inventory_items(status);
CREATE INDEX idx_inventory_low_stock ON inventory_items(current_quantity, minimum_threshold);
CREATE INDEX idx_recipes_product ON recipes(product_id);
CREATE INDEX idx_recipe_ingredients_recipe ON recipe_ingredients(recipe_id);
CREATE INDEX idx_recipe_ingredients_item ON recipe_ingredients(inventory_item_id);
CREATE INDEX idx_sale_transactions_timestamp ON sale_transactions(timestamp);
CREATE INDEX idx_sale_transactions_status ON sale_transactions(status);
CREATE INDEX idx_sale_items_transaction ON sale_items(transaction_id);
CREATE INDEX idx_consumption_logs_transaction ON inventory_consumption_logs(transaction_id);
CREATE INDEX idx_consumption_logs_timestamp ON inventory_consumption_logs(timestamp);
CREATE INDEX idx_consumed_ingredients_log ON consumed_ingredients(consumption_log_id);
CREATE INDEX idx_consumed_ingredients_item ON consumed_ingredients(inventory_item_id);
CREATE INDEX idx_stock_logs_item ON stock_receive_logs(inventory_item_id);
CREATE INDEX idx_stock_logs_received ON stock_receive_logs(received_at);

-- ═══════════════════════════════════════════════════════════════════════════
-- VIEWS
-- ═══════════════════════════════════════════════════════════════════════════

CREATE VIEW inventory_status AS
SELECT
    id,
    name,
    unit,
    current_quantity,
    minimum_threshold,
    cost_per_unit,
    CASE
        WHEN current_quantity <= 0 THEN 'out_of_stock'
        WHEN current_quantity <= minimum_threshold * 0.5 THEN 'critical'
        WHEN current_quantity <= minimum_threshold THEN 'low_stock'
        ELSE 'normal'
    END as calculated_status,
    last_updated
FROM inventory_items;

CREATE VIEW daily_consumption AS
SELECT
    date(ci.timestamp, 'unixepoch', 'localtime') as date,
    ci.inventory_item_id,
    ii.name as item_name,
    SUM(ci.quantity_consumed) as total_consumed,
    SUM(ci.total_cost) as total_cost,
    COUNT(DISTINCT ci.consumption_log_id) as transaction_count
FROM consumed_ingredients ci
JOIN inventory_items ii ON ci.inventory_item_id = ii.id
GROUP BY date, ci.inventory_item_id;
```

## 8.2 NoSQL Schema (Firebase/Future Scale)

```javascript
// Collection: inventory_items
{
  "coffee_beans_001": {
    name: "Arabica Coffee Beans",
    unit: "gram",
    currentQuantity: 5000,
    minimumThreshold: 1000,
    costPerUnit: 0.05,
    status: "normal",
    lastUpdated: Timestamp,
    metadata: {
      supplier: "Colombian Farms Co.",
      sku: "CF-ARA-001",
      expiryDate: Timestamp
    },
    stock_movements: {
      "movement_001": {
        type: "received",
        quantity: 10000,
        timestamp: Timestamp,
        reference: "PO-2024-001",
        balanceAfter: 10000
      }
    }
  }
}

// Collection: recipes
{
  "turkish_coffee_recipe": {
    productId: "turkish_coffee_001",
    name: "Turkish Coffee",
    version: 3,
    isActive: true,
    ingredients: [
      {
        inventoryItemId: "coffee_beans_001",
        quantityRequiredPerUnit: 8,
        isOptional: false
      },
      {
        inventoryItemId: "sugar_001",
        quantityRequiredPerUnit: 10,
        isOptional: true
      }
    ],
    sizeMultipliers: {
      small: 0.8,
      medium: 1.0,
      large: 1.3
    },
    createdAt: Timestamp,
    updatedAt: Timestamp
  }
}

// Collection: sales (sharded by date)
{
  "txn_123456": {
    items: [
      {
        productId: "turkish_coffee_001",
        productName: "Turkish Coffee",
        quantity: 2,
        size: "medium",
        sugarLevel: "normal",
        unitPrice: 3.50,
        totalPrice: 7.00,
        consumedIngredients: [
          { itemId: "coffee_beans_001", quantity: 16, unitCost: 0.80 },
          { itemId: "sugar_001", quantity: 20, unitCost: 0.20 }
        ]
      }
    ],
    totalAmount: 7.00,
    cashierId: "cashier_001",
    customerId: null,
    status: "completed",
    timestamp: Timestamp,
    consumptionLog: {
      totalIngredientCost: 1.00,
      margin: 6.00
    }
  }
}

// Collection: consumption_analytics (aggregated data)
{
  "daily_2024_02_25": {
    date: "2024-02-25",
    storeId: "store_001",
    totalSales: 150,
    totalRevenue: 450.00,
    ingredientCosts: 120.00,
    consumptionByItem: {
      "coffee_beans_001": { quantity: 1200, cost: 60.00 },
      "sugar_001": { quantity: 1500, cost: 15.00 }
    }
  }
}

// Security Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /inventory_items/{itemId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin() || isCloudFunction();
    }

    match /sales/{date}/sales/{transactionId} {
      allow create: if isCashier() && validTransaction(request.resource);
      allow read: if isAuthenticated();
      allow update: if isAdmin();
    }
  }
}
```

## 8.3 Data Migration Strategy

```dart
// lib/infrastructure/migration/data_migration.dart

class DataMigration {
  Future<void> migrateToFirebase() async {
    final sqlite = await _getSQLiteDb();
    final firebase = FirebaseFirestore.instance;

    final inventoryItems = await sqlite.query('inventory_items');
    final batch = firebase.batch();

    for (final item in inventoryItems) {
      final docRef = firebase.collection('inventory_items').doc(item['id']);
      batch.set(docRef, _convertInventoryItem(item));
    }

    await batch.commit();
  }

  Future<void> _migrateSalesInChunks(Database sqlite, FirebaseFirestore firebase) async {
    const chunkSize = 500;
    int offset = 0;

    while (true) {
      final sales = await sqlite.query(
        'sale_transactions',
        limit: chunkSize,
        offset: offset,
        orderBy: 'timestamp',
      );

      if (sales.isEmpty) break;

      await _uploadSalesChunk(sales, firebase);
      offset += chunkSize;

      emit(MigrationProgress(
        processedSales: offset,
        totalSales: await _getTotalSalesCount(sqlite),
      ));
    }
  }
}
```
