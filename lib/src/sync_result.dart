/// The result of a sync operation.
///
/// Tracks how many records were pushed, pulled, conflicted, and retried.
class SyncResult {
  /// Number of records successfully pushed to the remote.
  final int pushed;

  /// Number of records pulled from the remote.
  final int pulled;

  /// Number of conflicts resolved during sync.
  final int conflicts;

  /// Number of records retried from the retry queue.
  final int retried;

  /// Create a new [SyncResult].
  const SyncResult({
    this.pushed = 0,
    this.pulled = 0,
    this.conflicts = 0,
    this.retried = 0,
  });

  /// Total number of records processed during sync.
  int get total => pushed + pulled + conflicts + retried;

  @override
  String toString() => 'SyncResult(pushed: $pushed, pulled: $pulled, '
      'conflicts: $conflicts, retried: $retried)';
}
