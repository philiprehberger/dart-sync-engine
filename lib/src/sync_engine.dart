import 'conflict_resolver.dart';
import 'local_store.dart';
import 'retry_queue.dart';
import 'sync_metadata.dart';
import 'sync_record.dart';
import 'sync_result.dart';

/// Callback for reporting sync progress.
///
/// [completed] is the number of steps finished, [total] is the total steps.
typedef SyncProgressCallback = void Function(int completed, int total);

/// Coordinates data synchronization between a local store and a remote source.
///
/// Uses a [LocalStore] for local caching, a [ConflictResolver] for handling
/// conflicts, and a [RetryQueue] for failed push operations.
class SyncEngine {
  /// The local data store.
  final LocalStore store;

  /// The conflict resolver.
  final ConflictResolver resolver;

  /// The retry queue for failed pushes.
  final RetryQueue retryQueue;

  /// The result of the last sync operation, or `null` if no sync has run.
  SyncResult? lastSyncResult;

  SyncMetadata _metadata = const SyncMetadata();

  /// Cumulative sync statistics across all sync cycles.
  SyncMetadata get metadata => _metadata;

  bool _isSyncing = false;

  /// Whether a sync operation is currently in progress.
  bool get isSyncing => _isSyncing;

  /// Called before a sync cycle starts with the list of pending records.
  ///
  /// Return `false` to cancel the sync. Return `true` to proceed.
  bool Function(List<SyncRecord>)? onBeforeSync;

  /// Called after a sync cycle completes with the [SyncResult].
  void Function(SyncResult)? onAfterSync;

  /// Called when a conflict is detected between a local and remote record.
  void Function(SyncRecord local, SyncRecord remote)? onConflict;

  /// Create a new [SyncEngine].
  SyncEngine({
    required this.store,
    required this.resolver,
    RetryQueue? retryQueue,
  }) : retryQueue = retryQueue ?? RetryQueue();

  /// Run a sync cycle.
  ///
  /// [push] sends local records to the remote and returns successfully pushed
  /// record ids. It may throw to indicate complete failure for a record.
  ///
  /// [pull] fetches remote records. Records whose ids already exist locally
  /// with different data are treated as conflicts and resolved by the
  /// [resolver].
  ///
  /// [onProgress] is called to report progress during the sync cycle.
  Future<SyncResult> sync({
    required Future<List<String>> Function(List<SyncRecord> records) push,
    required Future<List<SyncRecord>> Function() pull,
    SyncProgressCallback? onProgress,
  }) async {
    if (_isSyncing) {
      return const SyncResult();
    }

    _isSyncing = true;
    final stopwatch = Stopwatch()..start();

    try {
      var pushedCount = 0;
      var pulledCount = 0;
      var conflictCount = 0;
      var retriedCount = 0;
      final syncErrors = <SyncError>[];

      // Total steps: push pending + retry queued + pull
      const pullSteps = 1;
      final pendingRecords = store.pending();

      // Pre-sync hook
      if (onBeforeSync != null && !onBeforeSync!(pendingRecords)) {
        _isSyncing = false;
        return const SyncResult();
      }

      final queuedRecords = retryQueue.dequeueAll();
      final totalSteps = pendingRecords.length + queuedRecords.length + pullSteps;
      var completedSteps = 0;

      // Step 1: Push pending records
      if (pendingRecords.isNotEmpty) {
        try {
          final pushedIds = await push(pendingRecords);
          for (final id in pushedIds) {
            store.markSynced(id);
          }
          pushedCount = pushedIds.length;

          // Queue any records that were not in the pushed ids
          for (final record in pendingRecords) {
            if (!pushedIds.contains(record.id)) {
              retryQueue.enqueue(record);
            }
          }
        } catch (e) {
          // Push failed entirely — queue all pending records for retry
          for (final record in pendingRecords) {
            retryQueue.enqueue(record);
            syncErrors.add(SyncError(
              recordId: record.id,
              message: 'Push failed: $e',
            ));
          }
        }
      }
      completedSteps += pendingRecords.length;
      onProgress?.call(completedSteps, totalSteps);

      // Step 2: Retry queued records
      if (queuedRecords.isNotEmpty) {
        try {
          final retriedIds = await push(queuedRecords);
          for (final id in retriedIds) {
            store.markSynced(id);
          }
          retriedCount = retriedIds.length;
        } catch (e) {
          // Retry failed — re-queue
          for (final record in queuedRecords) {
            retryQueue.enqueue(record);
            syncErrors.add(SyncError(
              recordId: record.id,
              message: 'Retry failed: $e',
            ));
          }
        }
      }
      completedSteps += queuedRecords.length;
      onProgress?.call(completedSteps, totalSteps);

      // Step 3: Pull remote records
      final remoteRecords = await pull();
      for (final remote in remoteRecords) {
        final local = store.get(remote.id);
        if (local != null &&
            local.status != SyncStatus.synced &&
            local.data.toString() != remote.data.toString()) {
          // Conflict
          onConflict?.call(local, remote);
          final resolved = resolver.resolve(local, remote);
          store.put(resolved);
          conflictCount++;
        } else {
          store.put(remote.withStatus(SyncStatus.synced));
          pulledCount++;
        }
      }
      completedSteps += pullSteps;
      onProgress?.call(completedSteps, totalSteps);

      stopwatch.stop();

      final result = SyncResult(
        pushed: pushedCount,
        pulled: pulledCount,
        conflicts: conflictCount,
        retried: retriedCount,
        errors: syncErrors,
      );

      lastSyncResult = result;
      onAfterSync?.call(result);
      _metadata = _metadata.copyWith(
        lastSyncAt: DateTime.now(),
        lastDuration: stopwatch.elapsed,
        totalPushes: _metadata.totalPushes + pushedCount,
        totalPulls: _metadata.totalPulls + pulledCount,
        totalConflicts: _metadata.totalConflicts + conflictCount,
      );
      return result;
    } finally {
      _isSyncing = false;
    }
  }

  /// Run a selective sync cycle, pushing only records that match [predicate].
  ///
  /// Works like [sync] but filters pending records through [predicate]
  /// before pushing. Pull and conflict resolution work the same way.
  Future<SyncResult> syncWhere(
    bool Function(SyncRecord) predicate, {
    required Future<List<String>> Function(List<SyncRecord> records) push,
    required Future<List<SyncRecord>> Function() pull,
    SyncProgressCallback? onProgress,
  }) async {
    if (_isSyncing) {
      return const SyncResult();
    }

    _isSyncing = true;
    final stopwatch = Stopwatch()..start();

    try {
      var pushedCount = 0;
      var pulledCount = 0;
      var conflictCount = 0;
      var retriedCount = 0;
      final syncErrors = <SyncError>[];

      // Total steps: push matching + retry queued + pull
      const pullSteps = 1;
      final pendingRecords =
          store.pending().where(predicate).toList();

      // Pre-sync hook
      if (onBeforeSync != null && !onBeforeSync!(pendingRecords)) {
        _isSyncing = false;
        return const SyncResult();
      }

      final queuedRecords = retryQueue.dequeueAll();
      final totalSteps =
          pendingRecords.length + queuedRecords.length + pullSteps;
      var completedSteps = 0;

      // Step 1: Push matching pending records
      if (pendingRecords.isNotEmpty) {
        try {
          final pushedIds = await push(pendingRecords);
          for (final id in pushedIds) {
            store.markSynced(id);
          }
          pushedCount = pushedIds.length;

          for (final record in pendingRecords) {
            if (!pushedIds.contains(record.id)) {
              retryQueue.enqueue(record);
            }
          }
        } catch (e) {
          for (final record in pendingRecords) {
            retryQueue.enqueue(record);
            syncErrors.add(SyncError(
              recordId: record.id,
              message: 'Push failed: $e',
            ));
          }
        }
      }
      completedSteps += pendingRecords.length;
      onProgress?.call(completedSteps, totalSteps);

      // Step 2: Retry queued records
      if (queuedRecords.isNotEmpty) {
        try {
          final retriedIds = await push(queuedRecords);
          for (final id in retriedIds) {
            store.markSynced(id);
          }
          retriedCount = retriedIds.length;
        } catch (e) {
          for (final record in queuedRecords) {
            retryQueue.enqueue(record);
            syncErrors.add(SyncError(
              recordId: record.id,
              message: 'Retry failed: $e',
            ));
          }
        }
      }
      completedSteps += queuedRecords.length;
      onProgress?.call(completedSteps, totalSteps);

      // Step 3: Pull remote records
      final remoteRecords = await pull();
      for (final remote in remoteRecords) {
        final local = store.get(remote.id);
        if (local != null &&
            local.status != SyncStatus.synced &&
            local.data.toString() != remote.data.toString()) {
          onConflict?.call(local, remote);
          final resolved = resolver.resolve(local, remote);
          store.put(resolved);
          conflictCount++;
        } else {
          store.put(remote.withStatus(SyncStatus.synced));
          pulledCount++;
        }
      }
      completedSteps += pullSteps;
      onProgress?.call(completedSteps, totalSteps);

      stopwatch.stop();

      final result = SyncResult(
        pushed: pushedCount,
        pulled: pulledCount,
        conflicts: conflictCount,
        retried: retriedCount,
        errors: syncErrors,
      );

      lastSyncResult = result;
      onAfterSync?.call(result);
      _metadata = _metadata.copyWith(
        lastSyncAt: DateTime.now(),
        lastDuration: stopwatch.elapsed,
        totalPushes: _metadata.totalPushes + pushedCount,
        totalPulls: _metadata.totalPulls + pulledCount,
        totalConflicts: _metadata.totalConflicts + conflictCount,
      );
      return result;
    } finally {
      _isSyncing = false;
    }
  }
}
