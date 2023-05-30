import Intents
import TreeActor
import Utilities

// MARK: - StateSyncableScope

/// This protocol collects methods used to update the ``Tree``'s  ``NodeScope``s
/// to properly represent a known new ``State``.  This happens when jumping between states during
/// time-travel debugging playback, and is managed by a ``StateApplier`` instance.
protocol StateSyncableScope {
  /// Sync this scope to the passed record.
  @TreeActor
  func syncToStateReportingCreatedScopes() throws -> [AnyScope]
  @TreeActor
  func stop() throws
  @TreeActor
  func disconnectSendingNotification()
}

// MARK: - MissingNodeRecordError

struct MissingNodeRecordError: Error { }

// MARK: - NodeScope + StateSyncableScope

extension NodeScope: StateSyncableScope {

  @TreeActor
  func syncToStateReportingCreatedScopes() throws -> [AnyScope] {
    activeRules = activeRules ?? node.rules
    try activeRules?.syncToState(with: context)
    return try routerSet.syncToState()
  }
}
