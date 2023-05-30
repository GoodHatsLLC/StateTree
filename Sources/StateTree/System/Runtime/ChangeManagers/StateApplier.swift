import Behavior
import TreeActor
import Utilities

// MARK: - StateApplier

@TreeActor
final class StateApplier {

  // MARK: Lifecycle

  nonisolated init(
    newState: TreeStateRecord,
    stateStorage: StateStorage,
    scopeStorage: ScopeStorage
  ) {
    self.stateStorage = stateStorage
    self.scopeStorage = scopeStorage
    self.newState = newState
  }

  // MARK: Internal

  private(set) var isFlushing: Bool = false

  func flush() throws -> (events: [NodeEvent], stats: UpdateStats) {
    assert(!isFlushing, "flush should never be called when another flush is in progress")
    if isFlushing {
      throw UnfinishedFlushError()
    }
    isFlushing = true
    defer { isFlushing = false }
    return try updateScopes()
  }

  // MARK: Private

  private let stateStorage: StateStorage
  private let scopeStorage: ScopeStorage
  private let newState: TreeStateRecord

  private func updateScopes() throws -> (events: [NodeEvent], stats: UpdateStats) {
    // Prepare event & stats collection.
    var updateCollector = UpdateEffectInfoCollector()
    let timer = updateCollector.stats.startedTimer()

    guard
      let rootID = newState.root,
      let rootScope = scopeStorage.getScope(for: rootID)
    else {
      throw RootNodeMissingError()
    }

    // Store the initial state, and overwrite it.
    let oldState: TreeStateRecord = stateStorage.snapshot()
    stateStorage.apply(state: newState)

    // Find the state changes: started, stopped, and updated nodes.
    let oldRecordIDs = oldState.nodes.keys
    let newRecordIDs = newState.nodes.keys
    let maintainedNodeIDs = oldRecordIDs.intersection(newRecordIDs)
    let potentiallyUnchangedRecords = maintainedNodeIDs
      .reduce(into: Set<NodeRecord>()) { partialResult, nodeID in
        let oldRecord: NodeRecord = oldState.nodes[nodeID]!
        partialResult.insert(oldRecord)
      }
    let unchangedNodeIDs = maintainedNodeIDs
      .reduce(into: Set<NodeID>()) { partialResult, nodeID in
        let newRecord: NodeRecord = newState.nodes[nodeID]!
        if potentiallyUnchangedRecords.contains(newRecord) {
          partialResult.insert(nodeID)
        }
      }
    let stoppedNodeIDs = oldRecordIDs.subtracting(newRecordIDs)
    let startedNodeIDs = newRecordIDs.subtracting(oldRecordIDs)
    let updatedNodeIDs = maintainedNodeIDs.subtracting(unchangedNodeIDs)
    let syncSources = updatedNodeIDs.isEmpty && newState != oldState
      ? [rootScope.nid]
      : updatedNodeIDs

    // Stop scopes for removed nodes.
    //
    // N.B.: Updates sent to the UI layer should be ordered by depth, so
    // we can't yet disconnect these scopes from the runtime or notify consumers.
    for id in stoppedNodeIDs {
      if let scope = scopeStorage.getScope(for: id) {
        try scope.underlying.stop()
        updateCollector.stopped(id: id, depth: scope.depth)
      } else {
        assertionFailure("scopes to stop should be present in runtime")
      }
    }

    // Build a depth ordered queue of scopes to sync or start.
    var queue = PriorityQueue(type: AnyScope.self, orderBy: \.depth, uniqueBy: \.nid)
    queue.insert(contentsOf: scopeStorage.getScopes(for: syncSources))

    // Sync updated nodes from root to leaves.
    // When syncing creates a new scope, insert it into the queue.
    while let scope = queue.popMin() {
      let newScopes = try scope.syncToStateReportingCreatedScopes()
      let id = scope.nid
      if updatedNodeIDs.contains(id) {
        updateCollector.updated(id: id, depth: scope.depth)
      }
      if startedNodeIDs.contains(id) {
        updateCollector.started(id: id, depth: scope.depth)
      }
      queue.insert(contentsOf: newScopes)
    }
    assert(
      newState == stateStorage.snapshot(),
      "state should not mutate during its application"
    )

    // Return node update details and stats, allowing our consumer
    // to message the UI layer and to disconnect any stopped scopes
    // from the runtime.
    updateCollector.stats.recordTimeElapsed(from: timer)
    return updateCollector.collectChanges()
  }

}
