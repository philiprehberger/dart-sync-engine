import 'package:philiprehberger_sync_engine/sync_engine.dart';

Future<void> main() async {
  // Create the local store, conflict resolver, and sync engine
  final store = LocalStore();
  final resolver = ConflictResolver(strategy: ConflictStrategy.latestWins);
  final engine = SyncEngine(store: store, resolver: resolver);

  // Add some local records
  store.put(SyncRecord(
    id: 'user-1',
    data: {'name': 'Alice', 'email': 'alice@example.com'},
    updatedAt: DateTime.now(),
  ));

  store.put(SyncRecord(
    id: 'user-2',
    data: {'name': 'Bob', 'email': 'bob@example.com'},
    updatedAt: DateTime.now(),
  ));

  print('Local records: ${store.count}');
  print('Pending: ${store.pending().length}');

  // Run a sync cycle
  final result = await engine.sync(
    push: (records) async {
      // Simulate pushing to a remote API
      print('Pushing ${records.length} records...');
      return records.map((r) => r.id).toList();
    },
    pull: () async {
      // Simulate pulling from a remote API
      print('Pulling remote records...');
      return [
        SyncRecord(
          id: 'user-3',
          data: {'name': 'Charlie', 'email': 'charlie@example.com'},
          updatedAt: DateTime.now(),
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
  print('  Conflicts: ${result.conflicts}');

  // Check statistics
  final stats = store.statistics();
  print('Store: ${stats.total} total, ${stats.synced} synced');
}
