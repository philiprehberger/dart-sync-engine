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
  philiprehberger_sync_engine: ^0.1.0
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
| `SyncRecord` | `incrementVersion()` | Copy with version + 1 |
| `LocalStore` | `put(record)` | Store a record |
| `LocalStore` | `putAll(records)` | Store multiple records |
| `LocalStore` | `get(id)` | Retrieve a record by id |
| `LocalStore` | `remove(id)` | Remove a record |
| `LocalStore` | `all()` | Get all records |
| `LocalStore` | `pending()` | Get pending and modified records |
| `LocalStore` | `markSynced(id)` | Mark record as synced |
| `LocalStore` | `markModified(id)` | Mark record as modified |
| `LocalStore` | `query(where:)` | Filter records with a predicate |
| `LocalStore` | `statistics()` | Get aggregate counts |
| `LocalStore` | `count` | Total record count |
| `LocalStore` | `clear()` | Remove all records |
| `ConflictResolver` | `resolve(local, remote)` | Resolve a conflict |
| `ConflictResolver` | `resolvedCount` | Number of conflicts resolved |
| `RetryQueue` | `enqueue(record)` | Add a record to retry |
| `RetryQueue` | `dequeueAll()` | Get and clear all retryable records |
| `RetryQueue` | `pending()` | View queued records |
| `RetryQueue` | `count` | Number of queued records |
| `RetryQueue` | `clear()` | Clear the queue |
| `SyncEngine` | `sync(push:, pull:, onProgress:)` | Run a sync cycle |
| `SyncEngine` | `lastSyncResult` | Result of the last sync |
| `SyncEngine` | `isSyncing` | Whether a sync is in progress |
| `SyncResult` | `pushed`, `pulled`, `conflicts`, `retried` | Individual counts |
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
