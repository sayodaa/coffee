import 'package:coffee_app/new_data/sales_asset_data_source.dart';
import 'package:coffee_app/new_data/sales_record.dart';
import 'package:coffee_app/new_data/sales_repository.dart';

/// Asset-backed sales data source for BI/analytics screens.
///
/// The dataset can contain 100,000+ rows, so results are cached in memory
/// after the first successful load — every widget/analytics call after that
/// reuses the same parsed list instead of re-reading/re-decoding the asset.
///
/// NOTE: This is NOT related to the main [SalesRepository] domain interface.
/// It is a standalone data helper for the new_data BI feature set.
class SalesRepositoryImpl implements SalesRepository {
  final SalesAssetDataSource dataSource;

  List<SalesRecord>? _cache;

  SalesRepositoryImpl({required this.dataSource});

  @override
  Future<List<SalesRecord>> getSalesRecords({bool forceRefresh = false}) async {
    if (!forceRefresh && _cache != null) {
      return _cache!;
    }
    final records = await dataSource.loadSalesRecords();
    _cache = records;
    return records;
  }
}
