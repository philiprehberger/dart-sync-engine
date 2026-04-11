/// A single error that occurred during sync for a specific record.
class SyncError {
  /// The ID of the record that failed.
  final String recordId;

  /// A description of the error.
  final String message;

  /// When the error occurred.
  final DateTime timestamp;

  /// Creates a [SyncError].
  SyncError({
    required this.recordId,
    required this.message,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Serialize this error to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'recordId': recordId,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Deserialize a [SyncError] from a JSON-compatible map.
  factory SyncError.fromJson(Map<String, dynamic> json) {
    return SyncError(
      recordId: json['recordId'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  String toString() => 'SyncError($recordId: $message)';
}

/// The result of a sync operation.
///
/// Tracks how many records were pushed, pulled, conflicted, and retried,
/// along with any errors that occurred.
class SyncResult {
  /// Number of records successfully pushed to the remote.
  final int pushed;

  /// Number of records pulled from the remote.
  final int pulled;

  /// Number of conflicts resolved during sync.
  final int conflicts;

  /// Number of records retried from the retry queue.
  final int retried;

  /// Errors encountered during sync.
  final List<SyncError> errors;

  /// Create a new [SyncResult].
  const SyncResult({
    this.pushed = 0,
    this.pulled = 0,
    this.conflicts = 0,
    this.retried = 0,
    this.errors = const [],
  });

  /// Whether any errors occurred during sync.
  bool get hasErrors => errors.isNotEmpty;

  /// Total number of records processed during sync.
  int get total => pushed + pulled + conflicts + retried;

  /// Serialize this result to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'pushed': pushed,
      'pulled': pulled,
      'conflicts': conflicts,
      'retried': retried,
      'errors': errors.map((e) => e.toJson()).toList(),
    };
  }

  /// Deserialize a [SyncResult] from a JSON-compatible map.
  factory SyncResult.fromJson(Map<String, dynamic> json) {
    return SyncResult(
      pushed: json['pushed'] as int? ?? 0,
      pulled: json['pulled'] as int? ?? 0,
      conflicts: json['conflicts'] as int? ?? 0,
      retried: json['retried'] as int? ?? 0,
      errors: (json['errors'] as List?)
              ?.map((e) => SyncError.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  @override
  String toString() => 'SyncResult(pushed: $pushed, pulled: $pulled, '
      'conflicts: $conflicts, retried: $retried, errors: ${errors.length})';
}
