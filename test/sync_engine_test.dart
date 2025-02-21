import 'package:philiprehberger_sync_engine/sync_engine.dart';
import 'package:test/test.dart';

void main() {
  // ── SyncRecord ──────────────────────────────────────────────────────

  group('SyncRecord', () {
    test('creates with default values', () {
      final record = SyncRecord(
        id: '1',
        data: {'key': 'value'},
        updatedAt: DateTime(2026),
      );

      expect(record.id, '1');
      expect(record.data, {'key': 'value'});
      expect(record.status, SyncStatus.pending);
      expect(record.version, 1);
    });

    test('creates with explicit status and version', () {
      final record = SyncRecord(
        id: '2',
        data: {'a': 'b'},
        status: SyncStatus.synced,
        updatedAt: DateTime(2026),
        version: 5,
      );

      expect(record.status, SyncStatus.synced);
      expect(record.version, 5);
    });

    test('withStatus returns copy with new status', () {
      final record = SyncRecord(
        id: '1',
        data: {'key': 'value'},
        updatedAt: DateTime(2026),
      );

      final modified = record.withStatus(SyncStatus.synced);

      expect(modified.status, SyncStatus.synced);
      expect(modified.id, record.id);
      expect(modified.data, record.data);
      expect(modified.version, record.version);
    });

    test('incrementVersion returns copy with version + 1', () {
      final record = SyncRecord(
        id: '1',
        data: {'key': 'value'},
        updatedAt: DateTime(2026),
        version: 3,
      );

      final incremented = record.incrementVersion();

      expect(incremented.version, 4);
      expect(incremented.id, record.id);
      expect(incremented.updatedAt.isAfter(record.updatedAt), isTrue);
    });

    test('toString includes id, status, and version', () {
      final record = SyncRecord(
        id: 'abc',
        data: {},
        updatedAt: DateTime(2026),
      );

      expect(record.toString(), contains('abc'));
      expect(record.toString(), contains('pending'));
    });

    test('creates with default empty tags', () {
      final record = SyncRecord(
        id: '1',
        data: {'key': 'value'},
        updatedAt: DateTime(2026),
      );

      expect(record.tags, isEmpty);
    });

    test('creates with explicit tags', () {
      final record = SyncRecord(
        id: '1',
        data: {'key': 'value'},
        updatedAt: DateTime(2026),
        tags: {'urgent', 'user-data'},
      );

      expect(record.tags, {'urgent', 'user-data'});
    });

    test('withTags returns copy with new tags', () {
      final record = SyncRecord(
        id: '1',
        data: {'key': 'value'},
        updatedAt: DateTime(2026),
        tags: {'old'},
      );

      final updated = record.withTags({'new', 'fresh'});

      expect(updated.tags, {'new', 'fresh'});
      expect(updated.id, record.id);
      expect(updated.data, record.data);
      expect(updated.status, record.status);
      expect(updated.version, record.version);
    });

    test('withStatus preserves tags', () {
      final record = SyncRecord(
        id: '1',
        data: {},
        updatedAt: DateTime(2026),
        tags: {'important'},
      );

      final modified = record.withStatus(SyncStatus.synced);

      expect(modified.tags, {'important'});
    });

    test('incrementVersion preserves tags', () {
      final record = SyncRecord(
        id: '1',
        data: {},
        updatedAt: DateTime(2026),
        tags: {'important'},
      );

      final incremented = record.incrementVersion();

      expect(incremented.tags, {'important'});
    });
  });

  // ── LocalStore ──────────────────────────────────────────────────────

  group('LocalStore', () {
    late LocalStore store;

    setUp(() {
      store = LocalStore();
    });

    test('starts empty', () {
      expect(store.count, 0);
      expect(store.all(), isEmpty);
    });

    test('put and get a record', () {
      final record = SyncRecord(
        id: '1',
        data: {'name': 'test'},
        updatedAt: DateTime(2026),
      );

      store.put(record);

      expect(store.count, 1);
      expect(store.get('1'), isNotNull);
      expect(store.get('1')!.data, {'name': 'test'});
    });

    test('get returns null for missing id', () {
      expect(store.get('nonexistent'), isNull);
    });

    test('put replaces existing record', () {
      final r1 = SyncRecord(
        id: '1',
        data: {'v': '1'},
        updatedAt: DateTime(2026),
      );
      final r2 = SyncRecord(
        id: '1',
        data: {'v': '2'},
        updatedAt: DateTime(2026),
      );

      store.put(r1);
      store.put(r2);

      expect(store.count, 1);
      expect(store.get('1')!.data['v'], '2');
    });

    test('remove deletes record and returns true', () {
      store.put(SyncRecord(
        id: '1',
        data: {},
        updatedAt: DateTime(2026),
      ));

      expect(store.remove('1'), isTrue);
      expect(store.count, 0);
      expect(store.get('1'), isNull);
    });

    test('remove returns false for missing id', () {
      expect(store.remove('missing'), isFalse);
    });

    test('all returns all records', () {
      store.put(SyncRecord(id: '1', data: {}, updatedAt: DateTime(2026)));
      store.put(SyncRecord(id: '2', data: {}, updatedAt: DateTime(2026)));

      expect(store.all(), hasLength(2));
    });

    test('pending returns pending and modified records', () {
      store.put(SyncRecord(
        id: '1',
        data: {},
        status: SyncStatus.pending,
        updatedAt: DateTime(2026),
      ));
      store.put(SyncRecord(
        id: '2',
        data: {},
        status: SyncStatus.modified,
        updatedAt: DateTime(2026),
      ));
      store.put(SyncRecord(
        id: '3',
        data: {},
        status: SyncStatus.synced,
        updatedAt: DateTime(2026),
      ));

      final pendingRecords = store.pending();

      expect(pendingRecords, hasLength(2));
      expect(pendingRecords.map((r) => r.id), containsAll(['1', '2']));
    });

    test('markSynced updates record status', () {
      store.put(SyncRecord(
        id: '1',
        data: {},
        updatedAt: DateTime(2026),
      ));

      store.markSynced('1');

      expect(store.get('1')!.status, SyncStatus.synced);
    });

    test('markModified updates record status', () {
      store.put(SyncRecord(
        id: '1',
        data: {},
        status: SyncStatus.synced,
        updatedAt: DateTime(2026),
      ));

      store.markModified('1');

      expect(store.get('1')!.status, SyncStatus.modified);
    });

    test('clear removes all records', () {
      store.put(SyncRecord(id: '1', data: {}, updatedAt: DateTime(2026)));
      store.put(SyncRecord(id: '2', data: {}, updatedAt: DateTime(2026)));

      store.clear();

      expect(store.count, 0);
      expect(store.all(), isEmpty);
    });

    test('query filters records with predicate', () {
      store.put(SyncRecord(
        id: '1',
        data: {'type': 'a'},
        updatedAt: DateTime(2026),
      ));
      store.put(SyncRecord(
        id: '2',
        data: {'type': 'b'},
        updatedAt: DateTime(2026),
      ));
      store.put(SyncRecord(
        id: '3',
        data: {'type': 'a'},
        updatedAt: DateTime(2026),
      ));

      final results = store.query(where: (r) => r.data['type'] == 'a');

      expect(results, hasLength(2));
    });

    test('putAll stores multiple records', () {
      final records = [
        SyncRecord(id: '1', data: {}, updatedAt: DateTime(2026)),
        SyncRecord(id: '2', data: {}, updatedAt: DateTime(2026)),
        SyncRecord(id: '3', data: {}, updatedAt: DateTime(2026)),
      ];

      store.putAll(records);

      expect(store.count, 3);
    });

    test('queryByTag returns records with matching tag', () {
      store.put(SyncRecord(
        id: '1',
        data: {'name': 'a'},
        updatedAt: DateTime(2026),
        tags: {'user', 'active'},
      ));
      store.put(SyncRecord(
        id: '2',
        data: {'name': 'b'},
        updatedAt: DateTime(2026),
        tags: {'user'},
      ));
      store.put(SyncRecord(
        id: '3',
        data: {'name': 'c'},
        updatedAt: DateTime(2026),
        tags: {'config'},
      ));

      final userRecords = store.queryByTag('user');
      final activeRecords = store.queryByTag('active');
      final missingRecords = store.queryByTag('missing');

      expect(userRecords, hasLength(2));
      expect(activeRecords, hasLength(1));
      expect(activeRecords.first.id, '1');
      expect(missingRecords, isEmpty);
    });

    test('statistics returns correct counts', () {
      store.put(SyncRecord(
        id: '1',
        data: {},
        status: SyncStatus.pending,
        updatedAt: DateTime(2026),
      ));
      store.put(SyncRecord(
        id: '2',
        data: {},
        status: SyncStatus.synced,
        updatedAt: DateTime(2026),
      ));
      store.put(SyncRecord(
        id: '3',
        data: {},
        status: SyncStatus.modified,
        updatedAt: DateTime(2026),
      ));
      store.put(SyncRecord(
        id: '4',
        data: {},
        status: SyncStatus.synced,
        updatedAt: DateTime(2026),
      ));

      final stats = store.statistics();

      expect(stats.total, 4);
      expect(stats.pending, 1);
      expect(stats.synced, 2);
      expect(stats.modified, 1);
    });
  });

  // ── ConflictResolver ────────────────────────────────────────────────

  group('ConflictResolver', () {
    final local = SyncRecord(
      id: '1',
      data: {'source': 'local'},
      status: SyncStatus.modified,
      updatedAt: DateTime(2026, 1, 2),
      version: 2,
    );

    final remote = SyncRecord(
      id: '1',
      data: {'source': 'remote'},
      status: SyncStatus.synced,
      updatedAt: DateTime(2026, 1, 1),
      version: 3,
    );

    test('remoteWins strategy picks remote', () {
      final resolver =
          ConflictResolver(strategy: ConflictStrategy.remoteWins);

      final result = resolver.resolve(local, remote);

      expect(result.data['source'], 'remote');
      expect(result.status, SyncStatus.synced);
    });

    test('localWins strategy picks local', () {
      final resolver =
          ConflictResolver(strategy: ConflictStrategy.localWins);

      final result = resolver.resolve(local, remote);

      expect(result.data['source'], 'local');
      expect(result.status, SyncStatus.synced);
    });

    test('latestWins strategy picks record with later updatedAt', () {
      final resolver =
          ConflictResolver(strategy: ConflictStrategy.latestWins);

      final result = resolver.resolve(local, remote);

      // local has updatedAt Jan 2, remote has Jan 1
      expect(result.data['source'], 'local');
      expect(result.status, SyncStatus.synced);
    });

    test('custom strategy uses provided function', () {
      final resolver = ConflictResolver(
        strategy: ConflictStrategy.custom,
        customResolver: (l, r) => r.version > l.version ? r : l,
      );

      final result = resolver.resolve(local, remote);

      // remote has version 3, local has version 2
      expect(result.data['source'], 'remote');
    });

    test('resolvedCount tracks number of resolutions', () {
      final resolver =
          ConflictResolver(strategy: ConflictStrategy.remoteWins);

      expect(resolver.resolvedCount, 0);

      resolver.resolve(local, remote);
      resolver.resolve(local, remote);

      expect(resolver.resolvedCount, 2);
    });
  });

  // ── RetryQueue ──────────────────────────────────────────────────────

  group('RetryQueue', () {
    late RetryQueue queue;

    setUp(() {
      queue = RetryQueue(maxAttempts: 3);
    });

    test('starts empty', () {
      expect(queue.count, 0);
      expect(queue.pending(), isEmpty);
    });

    test('enqueue adds a record', () {
      final record = SyncRecord(
        id: '1',
        data: {},
        updatedAt: DateTime(2026),
      );

      queue.enqueue(record);

      expect(queue.count, 1);
    });

    test('dequeueAll returns and clears records', () {
      queue.enqueue(SyncRecord(
        id: '1',
        data: {},
        updatedAt: DateTime(2026),
      ));
      queue.enqueue(SyncRecord(
        id: '2',
        data: {},
        updatedAt: DateTime(2026),
      ));

      final records = queue.dequeueAll();

      expect(records, hasLength(2));
      expect(queue.count, 0);
    });

    test('enqueue increments attempts for existing record', () {
      final record = SyncRecord(
        id: '1',
        data: {},
        updatedAt: DateTime(2026),
      );

      queue.enqueue(record);
      queue.enqueue(record);
      queue.enqueue(record);

      expect(queue.count, 1);

      // Fourth enqueue exceeds maxAttempts (3), record is dropped
      queue.enqueue(record);

      expect(queue.count, 0);
    });

    test('clear removes all entries', () {
      queue.enqueue(SyncRecord(
        id: '1',
        data: {},
        updatedAt: DateTime(2026),
      ));

      queue.clear();

      expect(queue.count, 0);
    });

    test('pending returns records without removing them', () {
      queue.enqueue(SyncRecord(
        id: '1',
        data: {},
        updatedAt: DateTime(2026),
      ));

      final pending = queue.pending();

      expect(pending, hasLength(1));
      expect(queue.count, 1);
    });

    test('nextDelay calculates exponential backoff', () {
      final q = RetryQueue(
        backoffBase: const Duration(seconds: 1),
        backoffMultiplier: 2.0,
      );

      expect(q.nextDelay(0), const Duration(seconds: 1)); // 1 * 2^0 = 1
      expect(q.nextDelay(1), const Duration(seconds: 2)); // 1 * 2^1 = 2
      expect(q.nextDelay(2), const Duration(seconds: 4)); // 1 * 2^2 = 4
      expect(q.nextDelay(3), const Duration(seconds: 8)); // 1 * 2^3 = 8
    });

    test('nextDelay respects custom base and multiplier', () {
      final q = RetryQueue(
        backoffBase: const Duration(milliseconds: 500),
        backoffMultiplier: 3.0,
      );

      expect(q.nextDelay(0), const Duration(milliseconds: 500));
      expect(q.nextDelay(1), const Duration(milliseconds: 1500));
      expect(q.nextDelay(2), const Duration(milliseconds: 4500));
    });
  });

  // ── SyncEngine ──────────────────────────────────────────────────────

  group('SyncEngine', () {
    late LocalStore store;
    late ConflictResolver resolver;
    late SyncEngine engine;

    setUp(() {
      store = LocalStore();
      resolver = ConflictResolver(strategy: ConflictStrategy.remoteWins);
      engine = SyncEngine(store: store, resolver: resolver);
    });

    test('sync pushes pending records', () async {
      store.put(SyncRecord(
        id: '1',
        data: {'name': 'test'},
        status: SyncStatus.pending,
        updatedAt: DateTime(2026),
      ));

      final result = await engine.sync(
        push: (records) async => records.map((r) => r.id).toList(),
        pull: () async => [],
      );

      expect(result.pushed, 1);
      expect(store.get('1')!.status, SyncStatus.synced);
    });

    test('sync pulls remote records', () async {
      final result = await engine.sync(
        push: (records) async => [],
        pull: () async => [
          SyncRecord(
            id: 'r1',
            data: {'from': 'remote'},
            updatedAt: DateTime(2026),
          ),
        ],
      );

      expect(result.pulled, 1);
      expect(store.get('r1'), isNotNull);
      expect(store.get('r1')!.status, SyncStatus.synced);
    });

    test('sync resolves conflicts between local and remote', () async {
      store.put(SyncRecord(
        id: '1',
        data: {'source': 'local'},
        status: SyncStatus.modified,
        updatedAt: DateTime(2026),
      ));

      final result = await engine.sync(
        push: (records) async => [],
        pull: () async => [
          SyncRecord(
            id: '1',
            data: {'source': 'remote'},
            status: SyncStatus.synced,
            updatedAt: DateTime(2026, 1, 2),
          ),
        ],
      );

      expect(result.conflicts, 1);
      // remoteWins strategy
      expect(store.get('1')!.data['source'], 'remote');
    });

    test('sync queues failed pushes for retry', () async {
      store.put(SyncRecord(
        id: '1',
        data: {},
        status: SyncStatus.pending,
        updatedAt: DateTime(2026),
      ));

      await engine.sync(
        push: (records) async => throw Exception('network error'),
        pull: () async => [],
      );

      expect(engine.retryQueue.count, 1);
    });

    test('lastSyncResult is updated after sync', () async {
      expect(engine.lastSyncResult, isNull);

      await engine.sync(
        push: (records) async => [],
        pull: () async => [],
      );

      expect(engine.lastSyncResult, isNotNull);
    });

    test('isSyncing is false when not syncing', () {
      expect(engine.isSyncing, isFalse);
    });

    test('sync calls onProgress callback', () async {
      store.put(SyncRecord(
        id: '1',
        data: {},
        status: SyncStatus.pending,
        updatedAt: DateTime(2026),
      ));

      final progressUpdates = <List<int>>[];

      await engine.sync(
        push: (records) async => records.map((r) => r.id).toList(),
        pull: () async => [],
        onProgress: (completed, total) {
          progressUpdates.add([completed, total]);
        },
      );

      expect(progressUpdates, isNotEmpty);
      // Last progress update should have completed == total
      expect(progressUpdates.last[0], progressUpdates.last[1]);
    });

    test('metadata tracks cumulative sync stats', () async {
      store.put(SyncRecord(
        id: '1',
        data: {'name': 'a'},
        status: SyncStatus.pending,
        updatedAt: DateTime(2026),
      ));

      expect(engine.metadata.totalPushes, 0);
      expect(engine.metadata.lastSyncAt, isNull);

      await engine.sync(
        push: (records) async => records.map((r) => r.id).toList(),
        pull: () async => [
          SyncRecord(
            id: 'r1',
            data: {'from': 'remote'},
            updatedAt: DateTime(2026),
          ),
        ],
      );

      expect(engine.metadata.totalPushes, 1);
      expect(engine.metadata.totalPulls, 1);
      expect(engine.metadata.totalConflicts, 0);
      expect(engine.metadata.lastSyncAt, isNotNull);
      expect(engine.metadata.lastDuration, isNotNull);

      // Run a second sync to verify cumulative tracking
      store.put(SyncRecord(
        id: '2',
        data: {'name': 'b'},
        status: SyncStatus.pending,
        updatedAt: DateTime(2026),
      ));

      await engine.sync(
        push: (records) async => records.map((r) => r.id).toList(),
        pull: () async => [],
      );

      expect(engine.metadata.totalPushes, 2);
    });

    test('syncWhere only pushes matching records', () async {
      store.put(SyncRecord(
        id: '1',
        data: {'type': 'user'},
        status: SyncStatus.pending,
        updatedAt: DateTime(2026),
        tags: {'user'},
      ));
      store.put(SyncRecord(
        id: '2',
        data: {'type': 'config'},
        status: SyncStatus.pending,
        updatedAt: DateTime(2026),
        tags: {'config'},
      ));

      final pushedRecords = <SyncRecord>[];
      final result = await engine.syncWhere(
        (r) => r.tags.contains('user'),
        push: (records) async {
          pushedRecords.addAll(records);
          return records.map((r) => r.id).toList();
        },
        pull: () async => [],
      );

      expect(result.pushed, 1);
      expect(pushedRecords, hasLength(1));
      expect(pushedRecords.first.id, '1');
      // Record '1' should be synced, record '2' should still be pending
      expect(store.get('1')!.status, SyncStatus.synced);
      expect(store.get('2')!.status, SyncStatus.pending);
    });

    test('syncWhere updates metadata', () async {
      store.put(SyncRecord(
        id: '1',
        data: {'type': 'user'},
        status: SyncStatus.pending,
        updatedAt: DateTime(2026),
        tags: {'user'},
      ));

      await engine.syncWhere(
        (r) => r.tags.contains('user'),
        push: (records) async => records.map((r) => r.id).toList(),
        pull: () async => [],
      );

      expect(engine.metadata.totalPushes, 1);
      expect(engine.metadata.lastSyncAt, isNotNull);
    });
  });

  // ── SyncMetadata ────────────────────────────────────────────────────

  group('SyncMetadata', () {
    test('creates with default values', () {
      const meta = SyncMetadata();

      expect(meta.lastSyncAt, isNull);
      expect(meta.lastDuration, isNull);
      expect(meta.totalPushes, 0);
      expect(meta.totalPulls, 0);
      expect(meta.totalConflicts, 0);
    });

    test('copyWith replaces specified fields', () {
      final now = DateTime(2026, 4, 2);
      const meta = SyncMetadata(totalPushes: 5, totalPulls: 3);

      final updated = meta.copyWith(
        lastSyncAt: now,
        lastDuration: const Duration(seconds: 2),
        totalPushes: 6,
      );

      expect(updated.lastSyncAt, now);
      expect(updated.lastDuration, const Duration(seconds: 2));
      expect(updated.totalPushes, 6);
      expect(updated.totalPulls, 3); // unchanged
      expect(updated.totalConflicts, 0); // unchanged
    });

    test('toJson and fromJson round-trip', () {
      final now = DateTime(2026, 4, 2, 10, 30);
      final meta = SyncMetadata(
        lastSyncAt: now,
        lastDuration: const Duration(milliseconds: 1500),
        totalPushes: 10,
        totalPulls: 8,
        totalConflicts: 2,
      );

      final json = meta.toJson();
      final restored = SyncMetadata.fromJson(json);

      expect(restored.lastSyncAt, now);
      expect(restored.lastDuration, const Duration(milliseconds: 1500));
      expect(restored.totalPushes, 10);
      expect(restored.totalPulls, 8);
      expect(restored.totalConflicts, 2);
    });

    test('fromJson handles null optional fields', () {
      final meta = SyncMetadata.fromJson({
        'lastSyncAt': null,
        'lastDuration': null,
        'totalPushes': 5,
        'totalPulls': 3,
        'totalConflicts': 1,
      });

      expect(meta.lastSyncAt, isNull);
      expect(meta.lastDuration, isNull);
      expect(meta.totalPushes, 5);
    });

    test('toString includes totals', () {
      const meta = SyncMetadata(totalPushes: 1, totalPulls: 2);

      expect(meta.toString(), contains('totalPushes: 1'));
      expect(meta.toString(), contains('totalPulls: 2'));
    });
  });

  // ── SyncResult ──────────────────────────────────────────────────────

  group('SyncResult', () {
    test('total sums all counts', () {
      const result = SyncResult(
        pushed: 3,
        pulled: 5,
        conflicts: 1,
        retried: 2,
      );

      expect(result.total, 11);
    });

    test('defaults to zero counts', () {
      const result = SyncResult();

      expect(result.pushed, 0);
      expect(result.pulled, 0);
      expect(result.conflicts, 0);
      expect(result.retried, 0);
      expect(result.total, 0);
    });

    test('toString includes all fields', () {
      const result = SyncResult(pushed: 1, pulled: 2);

      expect(result.toString(), contains('pushed: 1'));
      expect(result.toString(), contains('pulled: 2'));
    });
  });

  // ── Sync Hooks ───────────────────────────────────────────────────────

  group('sync hooks', () {
    test('onBeforeSync fires with pending records', () async {
      final store = LocalStore();
      store.put(SyncRecord(id: '1', data: {'a': 1}, status: SyncStatus.pending, updatedAt: DateTime(2026)));
      final engine = SyncEngine(
        store: store,
        resolver: ConflictResolver(strategy: ConflictStrategy.remoteWins),
      );

      List<SyncRecord>? captured;
      engine.onBeforeSync = (records) {
        captured = records;
        return true;
      };

      await engine.sync(
        push: (records) async => records.map((r) => r.id).toList(),
        pull: () async => [],
      );

      expect(captured, isNotNull);
      expect(captured!.length, 1);
      expect(captured!.first.id, '1');
    });

    test('onBeforeSync returning false cancels sync', () async {
      final store = LocalStore();
      store.put(SyncRecord(id: '1', data: {'a': 1}, status: SyncStatus.pending, updatedAt: DateTime(2026)));
      final engine = SyncEngine(
        store: store,
        resolver: ConflictResolver(strategy: ConflictStrategy.remoteWins),
      );

      engine.onBeforeSync = (_) => false;

      final result = await engine.sync(
        push: (records) async => throw StateError('should not be called'),
        pull: () async => throw StateError('should not be called'),
      );

      expect(result.pushed, 0);
      expect(result.pulled, 0);
    });

    test('onAfterSync fires with result', () async {
      final store = LocalStore();
      store.put(SyncRecord(id: '1', data: {'a': 1}, status: SyncStatus.pending, updatedAt: DateTime(2026)));
      final engine = SyncEngine(
        store: store,
        resolver: ConflictResolver(strategy: ConflictStrategy.remoteWins),
      );

      SyncResult? captured;
      engine.onAfterSync = (result) => captured = result;

      await engine.sync(
        push: (records) async => ['1'],
        pull: () async => [],
      );

      expect(captured, isNotNull);
      expect(captured!.pushed, 1);
    });

    test('onConflict fires during conflict', () async {
      final store = LocalStore();
      store.put(SyncRecord(id: '1', data: {'a': 1}, status: SyncStatus.modified, updatedAt: DateTime(2026)));
      final engine = SyncEngine(
        store: store,
        resolver: ConflictResolver(strategy: ConflictStrategy.remoteWins),
      );

      final conflicts = <String>[];
      engine.onConflict = (local, remote) => conflicts.add(local.id);

      await engine.sync(
        push: (records) async => [],
        pull: () async => [SyncRecord(id: '1', data: {'a': 2}, status: SyncStatus.synced, updatedAt: DateTime(2026, 1, 2))],
      );

      expect(conflicts, ['1']);
    });
  });

  // ── SyncResult errors ──────────────────────────────────────────────

  group('SyncResult errors', () {
    test('captures push errors', () async {
      final store = LocalStore();
      store.put(SyncRecord(id: '1', data: {'a': 1}, status: SyncStatus.pending, updatedAt: DateTime(2026)));
      final engine = SyncEngine(
        store: store,
        resolver: ConflictResolver(strategy: ConflictStrategy.remoteWins),
      );

      final result = await engine.sync(
        push: (records) async => throw Exception('network error'),
        pull: () async => [],
      );

      expect(result.hasErrors, isTrue);
      expect(result.errors.length, 1);
      expect(result.errors.first.recordId, '1');
      expect(result.errors.first.message, contains('Push failed'));
    });

    test('SyncError has timestamp', () {
      final error = SyncError(recordId: 'x', message: 'test');
      expect(error.timestamp, isNotNull);
    });

    test('result with no errors has hasErrors false', () {
      const result = SyncResult(pushed: 1);
      expect(result.hasErrors, isFalse);
    });
  });
}
