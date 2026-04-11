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
/// its sync state, an [updatedAt] timestamp, a [version] for conflict
/// detection, and optional [tags] for categorization.
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

  /// Tags for categorizing this record.
  final Set<String> tags;

  /// Create a new [SyncRecord].
  const SyncRecord({
    required this.id,
    required this.data,
    this.status = SyncStatus.pending,
    required this.updatedAt,
    this.version = 1,
    this.tags = const {},
  });

  /// Return a copy of this record with a new [status].
  SyncRecord withStatus(SyncStatus status) {
    return SyncRecord(
      id: id,
      data: data,
      status: status,
      updatedAt: updatedAt,
      version: version,
      tags: tags,
    );
  }

  /// Return a copy of this record with the given [tags].
  SyncRecord withTags(Set<String> tags) {
    return SyncRecord(
      id: id,
      data: data,
      status: status,
      updatedAt: updatedAt,
      version: version,
      tags: tags,
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
      tags: tags,
    );
  }

  /// Return a copy of this record with the given [data].
  SyncRecord withData(Map<String, String> data) {
    return SyncRecord(
      id: id,
      data: data,
      status: status,
      updatedAt: updatedAt,
      version: version,
      tags: tags,
    );
  }

  /// Serialize this record to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'data': data,
      'status': status.name,
      'updatedAt': updatedAt.toIso8601String(),
      'version': version,
      'tags': tags.toList(),
    };
  }

  /// Deserialize a [SyncRecord] from a JSON-compatible map.
  factory SyncRecord.fromJson(Map<String, dynamic> json) {
    return SyncRecord(
      id: json['id'] as String,
      data: Map<String, String>.from(json['data'] as Map),
      status: SyncStatus.values.byName(json['status'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      version: json['version'] as int? ?? 1,
      tags: json['tags'] != null
          ? Set<String>.from(json['tags'] as List)
          : const {},
    );
  }

  @override
  String toString() =>
      'SyncRecord(id: $id, status: $status, version: $version)';
}
