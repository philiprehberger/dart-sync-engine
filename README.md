# philiprehberger_sync_engine

[![Tests](https://github.com/philiprehberger/dart-sync-engine/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/dart-sync-engine/actions/workflows/ci.yml)
[![pub package](https://img.shields.io/pub/v/philiprehberger_sync_engine.svg)](https://pub.dev/packages/philiprehberger_sync_engine)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/dart-sync-engine)](https://github.com/philiprehberger/dart-sync-engine/commits/main)

Offline-first data sync with conflict resolution, retry queues, and local caching

## Requirements

- Dart >= 3.5

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  philiprehberger_sync_engine: ^0.3.0
```

Then run:

```bash
dart pub get
```

## Usage

```dart
import 'package:philiprehberger_sync_engine/sync_engine.dart';

final store = LocalStore();
final resolver = ConflictResolver(strategy: ConflictStrategy.latestWins);
final engine = SyncEngine(store: store, resolver: resolver);
```

### Adding Records

```dart
store.put(SyncRecord(
  id: 'user-1',
  data: {'name': 'Alice', 'email': 'alice@example.com'},
  updatedAt: DateTime.now(),
));
```

### Running a Sync

```dart
final result = await engine.sync(
  push: (records) async {
    // Send records to your API, return ids of successfully pushed records
    final response = await api.push(records);
    return response.successIds;
  },
  pull: () async {
    // Fetch records from your API
    return await api.fetchAll();
  },
);

print('Pushed: ${result.pushed}, Pulled: ${result.pulled}');
```

### Conflict Resolution

```dart
// Remote always wins
final resolver = ConflictResolver(strategy: ConflictStrategy.remoteWins);

// Local always wins
final resolver = ConflictResolver(strategy: ConflictStrategy.localWins);

// Latest timestamp wins
final resolver = ConflictResolver(strategy: ConflictStrategy.latestWins);

// Custom logic
final resolver = ConflictResolver(
  strategy: ConflictStrategy.custom,
  customResolver: (local, remote) => remote.version > local.version ? remote : local,
);
```

### Progress Tracking

```dart
await engine.sync(
  push: pushFn,
  pull: pullFn,
  onProgress: (completed, total) {
    print('$completed / $total');
  },
);
```

### Tagging Records

```dart
store.put(SyncRecord(
  id: 'user-1',
  data: {'name': 'Alice'},
  updatedAt: DateTime.now(),
  tags: {'user', 'priority'},
));

// Query by tag
final userRecords = store.queryByTag('user');

// Update tags on an existing record
final updated = record.withTags({'user', 'priority', 'reviewed'});
store.put(updated);
```

### Selective Sync

```dart
// Only push records tagged with 'priority'
final result = await engine.syncWhere(
  (record) => record.tags.contains('priority'),
  push: (records) async {
    final response = await api.push(records);
    return response.successIds;
  },
  pull: () async => await api.fetchAll(),
);
```

### Exponential Backoff

```dart
final retryQueue = RetryQueue(
  maxAttempts: 5,
  backoffBase: Duration(seconds: 1),
  backoffMultiplier: 2.0,
);

// Calculate delay for a given attempt
final delay = retryQueue.nextDelay(2); // 4 seconds (1 * 2^2)
```

### Sync Metadata

```dart
await engine.sync(push: pushFn, pull: pullFn);

final meta = engine.metadata;
print('Last sync: ${meta.lastSyncAt}');
print('Duration: ${meta.lastDuration}');
print('Total pushes: ${meta.totalPushes}');
print('Total pulls: ${meta.totalPulls}');
print('Total conflicts: ${meta.totalConflicts}');

// Serialize for persistence
final json = meta.toJson();
final restored = SyncMetadata.fromJson(json);
```

### Sync Hooks

```dart
engine.onBeforeSync = (pendingRecords) {
  print('About to sync ${pendingRecords.length} records');
  return true; // return false to cancel
};

engine.onAfterSync = (result) {
  print('Synced: ${result.pushed} pushed, ${result.pulled} pulled');
};

engine.onConflict = (local, remote) {
  print('Conflict on ${local.id}');
};
```

### Error Handling

```dart
final result = await engine.sync(push: pushFn, pull: pullFn);

if (result.hasErrors) {
  for (final error in result.errors) {
    print('${error.recordId}: ${error.message}');
  }
}
```

### Querying Records

```dart
final active = store.query(where: (r) => r.status == SyncStatus.synced);
final stats = store.statistics();
print('Total: ${stats.total}, Synced: ${stats.synced}');
```

## API

| Class | Method / Property | Description |
|-------|-------------------|-------------|
| `SyncRecord` | `SyncRecord(id:, data:, updatedAt:)` | Create a sync record |
| `SyncRecord` | `withStatus(status)` | Copy with new status |
| `SyncRecord` | `withTags(tags)` | Copy with new tags |
| `SyncRecord` | `incrementVersion()` | Copy with version + 1 |
| `SyncRecord` | `tags` | Tags for categorizing the record |
| `LocalStore` | `put(record)` | Store a record |
| `LocalStore` | `putAll(records)` | Store multiple records |
| `LocalStore` | `get(id)` | Retrieve a record by id |
| `LocalStore` | `remove(id)` | Remove a record |
| `LocalStore` | `all()` | Get all records |
| `LocalStore` | `pending()` | Get pending and modified records |
| `LocalStore` | `markSynced(id)` | Mark record as synced |
| `LocalStore` | `markModified(id)` | Mark record as modified |
| `LocalStore` | `query(where:)` | Filter records with a predicate |
| `LocalStore` | `queryByTag(tag)` | Filter records by tag |
| `LocalStore` | `statistics()` | Get aggregate counts |
| `LocalStore` | `count` | Total record count |
| `LocalStore` | `clear()` | Remove all records |
| `ConflictResolver` | `resolve(local, remote)` | Resolve a conflict |
| `ConflictResolver` | `resolvedCount` | Number of conflicts resolved |
| `RetryQueue` | `enqueue(record)` | Add a record to retry |
| `RetryQueue` | `dequeueAll()` | Get and clear all retryable records |
| `RetryQueue` | `pending()` | View queued records |
| `RetryQueue` | `nextDelay(attempt)` | Calculate backoff delay for attempt |
| `RetryQueue` | `count` | Number of queued records |
| `RetryQueue` | `clear()` | Clear the queue |
| `SyncEngine` | `sync(push:, pull:, onProgress:)` | Run a sync cycle |
| `SyncEngine` | `syncWhere(predicate, push:, pull:, onProgress:)` | Selective sync by predicate |
| `SyncEngine` | `metadata` | Cumulative sync statistics |
| `SyncEngine` | `lastSyncResult` | Result of the last sync |
| `SyncEngine` | `isSyncing` | Whether a sync is in progress |
| `SyncMetadata` | `lastSyncAt`, `lastDuration` | Timing of last sync |
| `SyncMetadata` | `totalPushes`, `totalPulls`, `totalConflicts` | Cumulative counts |
| `SyncMetadata` | `copyWith(...)` | Copy with updated fields |
| `SyncMetadata` | `toJson()` / `fromJson(map)` | JSON serialization |
| `SyncEngine` | `onBeforeSync` | Hook called before sync starts |
| `SyncEngine` | `onAfterSync` | Hook called after sync completes |
| `SyncEngine` | `onConflict` | Hook called on conflict detection |
| `SyncError` | `recordId`, `message`, `timestamp` | Error details for a failed record |
| `SyncResult` | `pushed`, `pulled`, `conflicts`, `retried` | Individual counts |
| `SyncResult` | `errors` | List of errors from the sync cycle |
| `SyncResult` | `hasErrors` | Whether any errors occurred |
| `SyncResult` | `total` | Sum of all counts |

## Development

```bash
dart pub get
dart analyze --fatal-infos
dart test
```

## Support

If you find this project useful:

⭐ [Star the repo](https://github.com/philiprehberger/dart-sync-engine)

🐛 [Report issues](https://github.com/philiprehberger/dart-sync-engine/issues?q=is%3Aissue+is%3Aopen+label%3Abug)

💡 [Suggest features](https://github.com/philiprehberger/dart-sync-engine/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)

❤️ [Sponsor development](https://github.com/sponsors/philiprehberger)

🌐 [All Open Source Projects](https://philiprehberger.com/open-source-packages)

💻 [GitHub Profile](https://github.com/philiprehberger)

🔗 [LinkedIn Profile](https://www.linkedin.com/in/philiprehberger)

## License

[MIT](LICENSE)
