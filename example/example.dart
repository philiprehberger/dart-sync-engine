import 'package:philiprehberger_sync_engine/sync_engine.dart';

Future<void> main() async {
  // Create the local store, conflict resolver, and sync engine
  final store = LocalStore();
  final resolver = ConflictResolver(strategy: ConflictStrategy.latestWins);
  final retryQueue = RetryQueue(
    maxAttempts: 5,
    backoffBase: Duration(seconds: 1),
    backoffMultiplier: 2.0,
  );
  final engine = SyncEngine(
    store: store,
    resolver: resolver,
    retryQueue: retryQueue,
  );

  // Add records with tags
  store.put(SyncRecord(
    id: 'user-1',
    data: {'name': 'Alice', 'email': 'alice@example.com'},
    updatedAt: DateTime.now(),
    tags: {'user', 'priority'},
  ));

  store.put(SyncRecord(
    id: 'user-2',
    data: {'name': 'Bob', 'email': 'bob@example.com'},
    updatedAt: DateTime.now(),
    tags: {'user'},
  ));

  store.put(SyncRecord(
    id: 'config-1',
    data: {'theme': 'dark'},
    updatedAt: DateTime.now(),
    tags: {'config'},
  ));

  print('Local records: ${store.count}');
  print('User records: ${store.queryByTag('user').length}');
  print('Priority records: ${store.queryByTag('priority').length}');

  // Selective sync — only push priority records
  final result = await engine.syncWhere(
    (record) => record.tags.contains('priority'),
    push: (records) async {
      print('Pushing ${records.length} priority records...');
      return records.map((r) => r.id).toList();
    },
    pull: () async {
      print('Pulling remote records...');
      return [
        SyncRecord(
          id: 'user-3',
          data: {'name': 'Charlie', 'email': 'charlie@example.com'},
          updatedAt: DateTime.now(),
          tags: {'user'},
        ),
      ];
    },
    onProgress: (completed, total) {
      print('Progress: $completed/$total');
    },
  );

  print('Sync complete: ${result.total} records processed');
  print('  Pushed: ${result.pushed}');
  print('  Pulled: ${result.pulled}');

  // Check sync metadata
  final meta = engine.metadata;
  print('Last sync: ${meta.lastSyncAt}');
  print('Duration: ${meta.lastDuration}');
  print('Total pushes: ${meta.totalPushes}');
  print('Total pulls: ${meta.totalPulls}');

  // Exponential backoff delay calculation
  print('Retry delay attempt 0: ${retryQueue.nextDelay(0)}');
  print('Retry delay attempt 1: ${retryQueue.nextDelay(1)}');
  print('Retry delay attempt 2: ${retryQueue.nextDelay(2)}');

  // Serialize metadata for persistence
  final json = meta.toJson();
  print('Metadata JSON: $json');

  final restored = SyncMetadata.fromJson(json);
  print('Restored pushes: ${restored.totalPushes}');

  // Full sync — push all remaining pending records
  final fullResult = await engine.sync(
    push: (records) async {
      print('Pushing ${records.length} remaining records...');
      return records.map((r) => r.id).toList();
    },
    pull: () async => [],
  );

  print('Full sync pushed: ${fullResult.pushed}');

  // Check statistics
  final stats = store.statistics();
  print('Store: ${stats.total} total, ${stats.synced} synced');
}
