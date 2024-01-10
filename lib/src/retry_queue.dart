import 'sync_record.dart';

/// A queue for records that failed to sync and need to be retried.
///
/// Each record tracks how many attempts have been made. Records that
/// exceed [maxAttempts] are dropped on dequeue.
class RetryQueue {
  /// Maximum number of retry attempts before a record is dropped.
  final int maxAttempts;

  final Map<String, _RetryEntry> _entries = {};

  /// Create a new [RetryQueue] with the given [maxAttempts].
  RetryQueue({this.maxAttempts = 3});

  /// The number of records currently in the queue.
  int get count => _entries.length;

  /// Add a [record] to the retry queue.
  ///
  /// If the record is already in the queue, its attempt count is incremented.
  /// Records that have exceeded [maxAttempts] are not re-enqueued.
  void enqueue(SyncRecord record) {
    final existing = _entries[record.id];
    if (existing != null) {
      final newAttempts = existing.attempts + 1;
      if (newAttempts > maxAttempts) {
        _entries.remove(record.id);
        return;
      }
      _entries[record.id] = _RetryEntry(record: record, attempts: newAttempts);
    } else {
      _entries[record.id] = _RetryEntry(record: record, attempts: 1);
    }
  }

  /// Remove and return all records from the queue that have not exceeded
  /// [maxAttempts].
  List<SyncRecord> dequeueAll() {
    final records = _entries.values
        .where((e) => e.attempts <= maxAttempts)
        .map((e) => e.record)
        .toList();
    _entries.clear();
    return records;
  }

  /// Return all records currently in the queue without removing them.
  List<SyncRecord> pending() {
    return _entries.values.map((e) => e.record).toList();
  }

  /// Remove all records from the queue.
  void clear() {
    _entries.clear();
  }
}

class _RetryEntry {
  final SyncRecord record;
  final int attempts;

  const _RetryEntry({required this.record, required this.attempts});
}
