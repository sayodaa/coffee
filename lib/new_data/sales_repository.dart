import 'sales_record.dart';

/// Domain-facing contract for retrieving raw sales records.
///
/// The domain layer only knows about [SalesRecord]s; it has no idea whether
/// they come from an asset, an API, or a database.
abstract class SalesRepository {
  /// Returns all sales records.
  ///
  /// [forceRefresh] bypasses any in-memory cache and re-reads/re-parses the
  /// source (use this for the dashboard's manual "Refresh" action).
  Future<List<SalesRecord>> getSalesRecords({bool forceRefresh = false});
}
