/// Cumulative statistics about sync operations.
///
/// Tracks timing and counts for push, pull, and conflict resolution
/// across all sync cycles.
class SyncMetadata {
  /// When the last sync completed, or `null` if no sync has run.
  final DateTime? lastSyncAt;

  /// How long the last sync took, or `null` if no sync has run.
  final Duration? lastDuration;

  /// Total number of records pushed across all syncs.
  final int totalPushes;

  /// Total number of records pulled across all syncs.
  final int totalPulls;

  /// Total number of conflicts resolved across all syncs.
  final int totalConflicts;

  /// Create a new [SyncMetadata].
  const SyncMetadata({
    this.lastSyncAt,
    this.lastDuration,
    this.totalPushes = 0,
    this.totalPulls = 0,
    this.totalConflicts = 0,
  });

  /// Return a copy of this metadata with the given fields replaced.
  SyncMetadata copyWith({
    DateTime? lastSyncAt,
    Duration? lastDuration,
    int? totalPushes,
    int? totalPulls,
    int? totalConflicts,
  }) {
    return SyncMetadata(
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastDuration: lastDuration ?? this.lastDuration,
      totalPushes: totalPushes ?? this.totalPushes,
      totalPulls: totalPulls ?? this.totalPulls,
      totalConflicts: totalConflicts ?? this.totalConflicts,
    );
  }

  /// Serialize this metadata to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'lastSyncAt': lastSyncAt?.toIso8601String(),
      'lastDuration': lastDuration?.inMilliseconds,
      'totalPushes': totalPushes,
      'totalPulls': totalPulls,
      'totalConflicts': totalConflicts,
    };
  }

  /// Deserialize a [SyncMetadata] from a JSON-compatible map.
  static SyncMetadata fromJson(Map<String, dynamic> json) {
    return SyncMetadata(
      lastSyncAt: json['lastSyncAt'] != null
          ? DateTime.parse(json['lastSyncAt'] as String)
          : null,
      lastDuration: json['lastDuration'] != null
          ? Duration(milliseconds: json['lastDuration'] as int)
          : null,
      totalPushes: json['totalPushes'] as int? ?? 0,
      totalPulls: json['totalPulls'] as int? ?? 0,
      totalConflicts: json['totalConflicts'] as int? ?? 0,
    );
  }

  @override
  String toString() => 'SyncMetadata(totalPushes: $totalPushes, '
      'totalPulls: $totalPulls, totalConflicts: $totalConflicts)';
}
