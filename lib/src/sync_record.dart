/// Status of a sync record in the local store.
enum SyncStatus {
  /// Newly created, not yet synced.
  pending,

  /// Modified locally since last sync.
  modified,

  /// Successfully synced with remote.
  synced,

  /// Conflict detected between local and remote versions.
  conflicted,

  /// Marked for deletion.
  deleted,
}

/// A record tracked by the sync engine.
///
/// Each record has a unique [id], arbitrary [data], a [status] indicating
/// its sync state, an [updatedAt] timestamp, and a [version] for conflict
/// detection.
class SyncRecord {
  /// The unique identifier for this record.
  final String id;

  /// The record payload as key-value pairs.
  final Map<String, String> data;

  /// The current sync status.
  final SyncStatus status;

  /// When this record was last updated.
  final DateTime updatedAt;

  /// The version number, incremented on each local change.
  final int version;

  /// Create a new [SyncRecord].
  const SyncRecord({
    required this.id,
    required this.data,
    this.status = SyncStatus.pending,
    required this.updatedAt,
    this.version = 1,
  });

  /// Return a copy of this record with a new [status].
  SyncRecord withStatus(SyncStatus status) {
    return SyncRecord(
      id: id,
      data: data,
      status: status,
      updatedAt: updatedAt,
      version: version,
    );
  }

  /// Return a copy of this record with [version] incremented by one
  /// and [updatedAt] set to the current time.
  SyncRecord incrementVersion() {
    return SyncRecord(
      id: id,
      data: data,
      status: status,
      updatedAt: DateTime.now(),
      version: version + 1,
    );
  }

  @override
  String toString() =>
      'SyncRecord(id: $id, status: $status, version: $version)';
}
