# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-04-01

### Added
- Initial release
- SyncRecord model with status tracking and versioning
- In-memory LocalStore with CRUD, query, and statistics
- ConflictResolver with remoteWins, localWins, latestWins, and custom strategies
- RetryQueue with configurable max attempts
- SyncEngine coordinator with push, pull, conflict resolution, and progress callbacks
- SyncResult for tracking sync operation outcomes
