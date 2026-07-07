import 'package:coffee_app/features/sales/domain/entities/sale_item_entity.dart';

import '../entities/sale_transaction_entity.dart';

/// Repository interface for sale transaction operations
abstract class SaleTransactionRepository {
  /// Get transaction by ID
  Future<SaleTransaction?> getById(String id);

  /// Get all transactions
  Future<List<SaleTransaction>> getAll();

  /// Get transactions by date range
  Future<List<SaleTransaction>> getByDateRange(DateTime start, DateTime end);

  /// Get transactions by status
  Future<List<SaleTransaction>> getByStatus(SaleStatus status);

  /// Save new transaction
  Future<void> save(SaleTransaction transaction);

  /// Update existing transaction
  Future<void> update(SaleTransaction transaction);

  /// Get today's transactions
  Future<List<SaleTransaction>> getTodayTransactions();

  /// Get pending transactions
  Future<List<SaleTransaction>> getPendingTransactions();
}
