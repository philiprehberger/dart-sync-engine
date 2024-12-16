import 'sync_record.dart';

/// Statistics about the contents of a [LocalStore].
class StoreStatistics {
  /// Total number of records.
  final int total;

  /// Number of records with [SyncStatus.pending].
  final int pending;

  /// Number of records with [SyncStatus.synced].
  final int synced;

  /// Number of records with [SyncStatus.modified].
  final int modified;

  /// Create a new [StoreStatistics].
  const StoreStatistics({
    required this.total,
    required this.pending,
    required this.synced,
    required this.modified,
  });

  @override
  String toString() => 'StoreStatistics(total: $total, pending: $pending, '
      'synced: $synced, modified: $modified)';
}

/// An in-memory store for [SyncRecord] instances.
///
/// Provides CRUD operations, filtering by status, and aggregate statistics.
class LocalStore {
  final Map<String, SyncRecord> _records = {};

  /// The total number of records in the store.
  int get count => _records.length;

  /// Store a [record], replacing any existing record with the same id.
  void put(SyncRecord record) {
    _records[record.id] = record;
  }

  /// Store multiple [records] at once.
  void putAll(List<SyncRecord> records) {
    for (final record in records) {
      _records[record.id] = record;
    }
  }

  /// Retrieve a record by [id], or `null` if not found.
  SyncRecord? get(String id) {
    return _records[id];
  }

  /// Remove the record with the given [id].
  ///
  /// Returns `true` if a record was removed, `false` if no record existed.
  bool remove(String id) {
    return _records.remove(id) != null;
  }

  /// Return all records in the store.
  List<SyncRecord> all() {
    return List.unmodifiable(_records.values.toList());
  }

  /// Return all records with [SyncStatus.pending] or [SyncStatus.modified].
  List<SyncRecord> pending() {
    return _records.values
        .where((r) =>
            r.status == SyncStatus.pending ||
            r.status == SyncStatus.modified)
        .toList();
  }

  /// Mark the record with [id] as [SyncStatus.synced].
  ///
  /// Does nothing if the record does not exist.
  void markSynced(String id) {
    final record = _records[id];
    if (record != null) {
      _records[id] = record.withStatus(SyncStatus.synced);
    }
  }

  /// Mark the record with [id] as [SyncStatus.modified].
  ///
  /// Does nothing if the record does not exist.
  void markModified(String id) {
    final record = _records[id];
    if (record != null) {
      _records[id] = record.withStatus(SyncStatus.modified);
    }
  }

  /// Remove all records from the store.
  void clear() {
    _records.clear();
  }

  /// Query records using a [where] predicate.
  List<SyncRecord> query({required bool Function(SyncRecord) where}) {
    return _records.values.where(where).toList();
  }

  /// Return all records that contain the given [tag].
  List<SyncRecord> queryByTag(String tag) {
    return _records.values.where((r) => r.tags.contains(tag)).toList();
  }

  /// Return aggregate statistics about the store contents.
  StoreStatistics statistics() {
    var pendingCount = 0;
    var syncedCount = 0;
    var modifiedCount = 0;

    for (final record in _records.values) {
      switch (record.status) {
        case SyncStatus.pending:
          pendingCount++;
        case SyncStatus.synced:
          syncedCount++;
        case SyncStatus.modified:
          modifiedCount++;
        case SyncStatus.conflicted:
        case SyncStatus.deleted:
          break;
      }
    }

    return StoreStatistics(
      total: _records.length,
      pending: pendingCount,
      synced: syncedCount,
      modified: modifiedCount,
    );
  }
}
