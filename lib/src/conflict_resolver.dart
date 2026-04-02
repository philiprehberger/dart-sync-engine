import 'sync_record.dart';

/// Strategy used to resolve conflicts between local and remote records.
enum ConflictStrategy {
  /// Remote record always wins.
  remoteWins,

  /// Local record always wins.
  localWins,

  /// The record with the latest [SyncRecord.updatedAt] wins.
  latestWins,

  /// Use a custom resolver function.
  custom,
}

/// Resolves conflicts between local and remote [SyncRecord] instances.
///
/// Configure with a [ConflictStrategy] and optionally a custom resolver
/// function for the [ConflictStrategy.custom] strategy.
class ConflictResolver {
  /// The strategy used to resolve conflicts.
  final ConflictStrategy strategy;

  /// Custom resolver function, required when [strategy] is
  /// [ConflictStrategy.custom].
  final SyncRecord Function(SyncRecord local, SyncRecord remote)?
      customResolver;

  int _resolvedCount = 0;

  /// The number of conflicts resolved by this instance.
  int get resolvedCount => _resolvedCount;

  /// Create a new [ConflictResolver] with the given [strategy].
  ///
  /// When [strategy] is [ConflictStrategy.custom], a [customResolver]
  /// function must be provided.
  ConflictResolver({
    required this.strategy,
    this.customResolver,
  }) : assert(
          strategy != ConflictStrategy.custom || customResolver != null,
          'customResolver is required when strategy is custom',
        );

  /// Resolve a conflict between a [local] and [remote] record.
  ///
  /// Returns the winning record with its status set to [SyncStatus.synced].
  SyncRecord resolve(SyncRecord local, SyncRecord remote) {
    final SyncRecord winner;

    switch (strategy) {
      case ConflictStrategy.remoteWins:
        winner = remote;
      case ConflictStrategy.localWins:
        winner = local;
      case ConflictStrategy.latestWins:
        winner = local.updatedAt.isAfter(remote.updatedAt) ? local : remote;
      case ConflictStrategy.custom:
        winner = customResolver!(local, remote);
    }

    _resolvedCount++;
    return winner.withStatus(SyncStatus.synced);
  }
}
