class InventoryItem {
  final String id;
  final String sku;
  final String name;
  final double quantity;
  final int minThreshold;
  final String unit;
  final double price;

  const InventoryItem({
    required this.id,
    required this.sku,
    required this.name,
    required this.quantity,
    required this.minThreshold,
    required this.unit,
    required this.price,
  });

  bool get isLowStock => quantity < minThreshold;

  InventoryItem copyWith({
    String? id,
    String? sku,
    String? name,
    String? category,
    double? quantity,
    int? minThreshold,
    String? unit,
    double? price,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      minThreshold: minThreshold ?? this.minThreshold,
      unit: unit ?? this.unit,
      price: price ?? this.price,
    );
  }

  /// Identity check — use this when you only need to know whether two
  /// references point to the "same" inventory record (e.g. matching by id
  /// in a list), regardless of whether their field values differ.
  bool hasSameId(InventoryItem other) => other.id == id;

  /// Full value equality — ANY field change (quantity, price, unit, etc.)
  /// produces an unequal object. This is required so that Flutter/Bloc
  /// widgets comparing old vs. new `InventoryItem` instances (e.g. in
  /// `didUpdateWidget`, `ValueKey`, or list diffing) correctly detect
  /// updates like stock adjustments and trigger a rebuild without needing
  /// an app restart.
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is InventoryItem &&
            other.id == id &&
            other.sku == sku &&
            other.name == name &&
            other.quantity == quantity &&
            other.minThreshold == minThreshold &&
            other.unit == unit &&
            other.price == price);
  }

  @override
  int get hashCode => Object.hash(
        id,
        sku,
        name,
        quantity,
        minThreshold,
        unit,
        price,
      );

  @override
  String toString() =>
      'InventoryItem(id: $id, name: $name, quantity: $quantity, unit: $unit)';
}
