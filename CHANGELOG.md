# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.0] - 2026-04-11

### Added
- `SyncRecord.toJson()` and `SyncRecord.fromJson()` for JSON serialization
- `SyncRecord.withData()` copy method for updating the data payload
- `StoreStatistics.toJson()` and `StoreStatistics.fromJson()` for JSON serialization
- `SyncError.toJson()` and `SyncError.fromJson()` for JSON serialization
- `SyncResult.toJson()` and `SyncResult.fromJson()` for JSON serialization

### Fixed
- Barrel file structure: primary barrel is now `lib/philiprehberger_sync_engine.dart`
- README requirements version corrected from 3.5 to 3.6

## [0.3.0] - 2026-04-03

### Added
- `SyncEngine.onBeforeSync` hook — fires before sync, return `false` to cancel
- `SyncEngine.onAfterSync` hook — fires after sync with `SyncResult`
- `SyncEngine.onConflict` hook — fires when a conflict is detected
- `SyncError` class for structured error reporting
- `SyncResult.errors` list of `SyncError` objects
- `SyncResult.hasErrors` convenience getter

## [0.2.0] - 2026-04-02

### Added
- `SyncRecord.tags` for categorizing records
- `LocalStore.queryByTag()` for filtering by tag
- Exponential backoff in `RetryQueue` with configurable base and multiplier
- `RetryQueue.nextDelay()` to calculate backoff delay
- `SyncMetadata` class for tracking sync statistics
- `SyncEngine.syncWhere()` for selective sync by predicate
- `SyncEngine.metadata` for cumulative sync stats

## [0.1.0] - 2026-04-01

### Added
- Initial release
- SyncRecord model with status tracking and versioning
- In-memory LocalStore with CRUD, query, and statistics
- ConflictResolver with remoteWins, localWins, latestWins, and custom strategies
- RetryQueue with configurable max attempts
- SyncEngine coordinator with push, pull, conflict resolution, and progress callbacks
- SyncResult for tracking sync operation outcomes
