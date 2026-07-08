import 'package:flutter/services.dart' show rootBundle;

import 'sales_record.dart';

/// Loads raw sales data for the Business Intelligence feature.
///
/// Kept as its own abstraction (rather than reading the asset directly in
/// the repository) so it can later be swapped for a network or database
/// source without touching anything above it.
abstract class SalesAssetDataSource {
  Future<List<SalesRecord>> loadSalesRecords();
}

class SalesAssetDataSourceImpl implements SalesAssetDataSource {
  final String assetPath;

  const SalesAssetDataSourceImpl({
    this.assetPath = 'assets/data/sales.json',
  });

  @override
  Future<List<SalesRecord>> loadSalesRecords() async {
    final raw = await rootBundle.loadString(assetPath);
    // Parsing is synchronous CPU work; for very large files this could be
    // moved to `compute()` to avoid a UI-thread hitch. Left as a direct call
    // for now since JSON decode + a single list pass is fast even at 100k+
    // rows, but this is the spot to reach for `compute(parseSalesRecords, raw)`
    // if profiling shows a jank frame on lower-end devices.
    return parseSalesRecords(raw);
  }
}
