import 'dart:async';
import 'dart:math';

/// Transaction lock for preventing concurrent modifications
class TransactionLock {
  final String lockId;
  final Set<String> inventoryItemIds;
  final DateTime acquiredAt;

  TransactionLock({
    required this.lockId,
    required this.inventoryItemIds,
    required this.acquiredAt,
  });
}

/// Simple in-memory lock manager for single-device operation
/// For multi-terminal: replace with Redis or similar distributed lock
class TransactionLockManager {
  final Map<String, TransactionLock> _activeLocks = {};
  static const Duration _lockTimeout = Duration(seconds: 30);

  /// Acquire locks for multiple inventory items
  Future<TransactionLock> acquireLocks(Set<String> inventoryItemIds) async {
    final lockId = _generateLockId();
    final sortedIds = inventoryItemIds.toList()..sort();

    // Try to acquire all locks
    for (final id in sortedIds) {
      if (_activeLocks.containsKey(id)) {
        final existingLock = _activeLocks[id]!;

        // Check if lock is expired
        if (DateTime.now().difference(existingLock.acquiredAt) > _lockTimeout) {
          _releaseLock(existingLock);
        } else {
          throw ConcurrentModificationException();
        }
      }
    }

    // All clear - acquire locks
    final lock = TransactionLock(
      lockId: lockId,
      inventoryItemIds: inventoryItemIds,
      acquiredAt: DateTime.now(),
    );

    for (final id in sortedIds) {
      _activeLocks[id] = lock;
    }

    return lock;
  }

  /// Release acquired locks
  Future<void> releaseLocks(TransactionLock lock) async {
    _releaseLock(lock);
  }

  void _releaseLock(TransactionLock lock) {
    for (final id in lock.inventoryItemIds) {
      final activeLock = _activeLocks[id];
      if (activeLock != null && activeLock.lockId == lock.lockId) {
        _activeLocks.remove(id);
      }
    }
  }

  /// Check if any items are currently locked
  bool areAnyLocked(Set<String> inventoryItemIds) {
    for (final id in inventoryItemIds) {
      if (_activeLocks.containsKey(id)) {
        final lock = _activeLocks[id]!;
        // Check if lock is expired
        if (DateTime.now().difference(lock.acquiredAt) <= _lockTimeout) {
          return true;
        }
      }
    }
    return false;
  }

  String _generateLockId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000);
    return 'lock_${timestamp}_$random';
  }
}

/// Exception thrown when lock cannot be acquired
class ConcurrentModificationException implements Exception {
  final String message;

  ConcurrentModificationException([this.message = 'Resource is locked by another transaction']);

  @override
  String toString() => 'ConcurrentModificationException: $message';
}
