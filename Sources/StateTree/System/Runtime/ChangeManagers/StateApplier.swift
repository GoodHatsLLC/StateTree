// MARK: - StateApplier

@TreeActor
final class StateApplier: ChangeManager {

  // MARK: Lifecycle

  nonisolated init(
    state: StateStorage,
    scopes: ScopeStorage
  ) {
    self.state = state
    self.scopes = scopes
  }

  // MARK: Internal

  private(set) var isFlushing: Bool = false

  /// Directly apply a previous state to the active tree.
  ///
  /// The state is directly swapped and the active tree reconciled.
  /// Lifecycle rules like ``OnStart`` and ``OnChange`` are
  /// not triggered.
  ///
  /// This method is used when:
  /// - reverting state changes triggering circular updates
  /// - applying time-travel-debugging `StateFrames`
  func apply(state newState: TreeStateRecord) throws -> [NodeChange] {
    guard newState.isValidInitialState
    else {
      throw InvalidInitialStateError()
    }
    guard !isFlushing
    else {
      throw UnfinishedFlushError()
    }

    let oldState = state.snapshot()
    let oldNodeIDs = Set(state.nodeIDs)
    state.apply(state: newState)
    let newNodeIDs = Set(state.nodeIDs)

    let removedNodeIDs = Array(oldNodeIDs.subtracting(newNodeIDs))
    let addedNodeIDs = Array(newNodeIDs.subtracting(oldNodeIDs))
    let maintainedNodeIDs = newNodeIDs.intersection(oldNodeIDs)

    // 'rerouting' scopes are scopes maintained from the old
    // tree that will host scopes that need to be added.
    // They're the scopes which need to be updated in order
    // to rebuild the tree.
    let reroutingNodeIDs = addedNodeIDs
      .compactMap { id in
        state.getRecord(id)
      }
      .map(\.origin.nodeID)
      .filter { maintainedNodeIDs.contains($0) }

    let oldMaintainedValues = Set(oldState.values(on: maintainedNodeIDs))
    let newMaintainedValues = Set(state.values(on: maintainedNodeIDs))
    let updatedMaintainedValues = newMaintainedValues.subtracting(oldMaintainedValues)
    let updatedValueIDs = updatedMaintainedValues.map(\.id)

    let changes = TreeChanges(
      removedScopes: removedNodeIDs,
      dirtyScopes: reroutingNodeIDs,
      updatedValues: updatedValueIDs
    )

    stagedChanges = changes

    return try flush()
  }

  func flush(dependentChanges changes: TreeChanges) {
    assert(isFlushing)
    stagedChanges.put(changes)
  }

  // MARK: Private

  private let state: StateStorage
  private let scopes: ScopeStorage
  private var stagedChanges: TreeChanges = .none

  private func flush() throws -> [NodeChange] {
    guard !isFlushing
    else {
      assertionFailure("flush should never be called when another flush is in progress")
      throw UnfinishedFlushError()
    }
    isFlushing = true
    defer { isFlushing = false }

    // Create a priority queue to hold the scopes that require updates.
    //
    // The queue is ordered based on the scopes's depth within the tree,
    // where the root node's scope is the minimum depth, zero, and all
    // sub-scopes have a depth value one greater than their parents.
    //
    // The queue enforces that a scope can only be added once by matching
    // scopes based on their NodeID id field.
    //
    // Scopes leave the queue when they are either fully stopped and
    // deallocated or no longer have pending updates.
    //
    // - Scopes are stopped and deallocated in order of max() depth—so
    //   before their ancestors.
    // - Scopes are started and updated in order of min() depth—before
    //   any of their descendants and before other deeper nodes.
    // - Scopes with the same depth are ordered deterministically,
    //   ranking newly added scopes as deeper than previously added ones.
    //   (i.e. min() is FIFO within a same-depth group and max() is FILO.)
    var priorityQueue = PriorityQueue(
      type: AnyScope.self,
      prioritizeBy: \.depth,
      uniqueBy: \.nid
    )

    var updateCollector = UpdateCollector()

    // Handle changes made as part of a full tree state application.
    //
    // As with `handleUpdateChanges` this function is called
    // repeatedly if the effect of updating scopes based on these
    // changes then triggers more changes.
    func handle(changes: TreeChanges) throws {
      // [N.B. 1.] Nodes present in the pre-application TreeStateRecord
      // but not in the post-application record must be stopped and removed.
      // Unlike in regular change management where removed scopes fire
      // ending lifecycle events, scopes torn down in rebuild do not.
      // (When updating, the full next state is not known a priori but must
      // be worked out based partially on lifecycle events. When rebuilding,
      // the full next state is already defined and lifecycle events could
      // corrupt it.)
      for nodeID in changes.removedScopes {
        updateCollector.stopped(id: nodeID, depth: nil)
        scopes.remove(id: nodeID)
      }

      // [N.B. 2.a.] Node records added by apply(state:) don't initially
      // have associated scopes—and so can't be directly updated.
      // These newly added nodes are not tracked as updates when calling
      // flushChanges(rebuildScopeTree: true).
      //
      // However, the 'rerouting' scopes that route to these new nodes
      // already exist (the root at least is guaranteed to) and can
      // create the scopes corresponding to the records.
      //
      // The following logic is triggered only once rerouting scopes
      // have created the new scopes.
      for nodeID in changes.routedScopes {
        guard let scope = scopes.getScope(for: nodeID)
        else {
          assertionFailure("a reported routed scope should always exist")
          continue
        }
        updateCollector.started(id: nodeID, depth: scope.depth)
        scope.markDirty(pending: .rebuild)
        _ = priorityQueue.insert(scope)
      }

      // [N.B. 2.b.] Updated nodes are 'Rerouting', they:
      // 1. Exist across the state change
      // 2. Have child nodes added in the change
      //
      // These are the nodes whose update() calls create
      // new scopes.
      for nodeID in changes.dirtyScopes {
        guard let scope = scopes.getScope(for: nodeID)
        else {
          assertionFailure("a reported dirty scope should always exist")
          continue
        }
        scope.markDirty(pending: .rebuild)
        _ = priorityQueue.insert(scope)
      }

      // Existing scopes may have values updated without also
      // being removed or being the scopes hosting removed ones.
      //
      // Scopes known to be dependent on a value field that
      // has changed need to be checked for updates.
      let valueChangeDirtiedScopes = changes
        .updatedValues
        .flatMap { field in
          scopes.dependentScopesForValue(id: field)
        }
      for scope in valueChangeDirtiedScopes {
        scope.markDirty(pending: .rebuild)
        _ = priorityQueue.insert(scope)
      }
    }

    // Take the updates that were in place when flushChanges was
    // called, resetting `updates` to empty in the process.
    let initialChanges = stagedChanges.take()

    // When rebuilding the scope tree to match a newly applied state,
    // the initial changes we receive should contain no 'added'
    // scopes. (Adding the scopes is the purpose of rebuilding!)
    assert(initialChanges.addedScopes.isEmpty)

    try handle(changes: initialChanges)

    while !priorityQueue.isEmpty {
      // Check if the deepest scope requires 'finalization'
      // actions to progress it further towards stopping.
      if
        let scope = priorityQueue.max,
        scope.requiresFinishing
      {
        // Remove the scope if fully finished.
        if scope.isFinished {
          priorityQueue.popMax()
          // add to record for external consumers
          updateCollector.stopped(id: scope.nid, depth: scope.depth)
          continue
        }
        // Take the next finalization action to
        // progress towards removal.
        try scope.stepTowardsFinished()
      }
      // If there was no scope to finalize check for
      // if the least deep node can be forwarded towards
      // being clean.
      else if
        let scope = priorityQueue.min,
        scope.requiresReadying
      {
        // If already clean remove.
        if scope.isClean, let scope = priorityQueue.popMin() {
          // add to record for external consumers
          // avoid overwriting '.start' — as that's more informative.
          updateCollector.updated(id: scope.nid, depth: scope.depth)
          continue
        }
        // Forward if required.
        try scope.stepTowardsReady()
      }
      // If the deepest scope needs forwarding, not finalizing,
      // and the scope closest to the root can't be forwarded
      // we must break the impasse.
      //
      // A scope can only be in the queue if it needs progress
      // towards either being fully updated or removed.
      //
      // Remove or further finalize the root-most node if possible.
      else if
        let scope = priorityQueue.min,
        scope.requiresFinishing
      {
        if scope.isFinished {
          priorityQueue.popMin()
          updateCollector.stopped(id: scope.nid, depth: scope.depth)
          continue
        }
        try scope.stepTowardsFinished()
      }
      // No change to the queue was possible.
      // The queue must be empty.
      else {
        assert(priorityQueue.isEmpty)
      }

      // Before looking at the queue for actions again, handle any
      // changes that were made based on the last actions taken.
      // This may add new scopes to the queue or change the states
      // of nodes already in the queue.
      try handle(changes: stagedChanges.take())
    }
    // Return the list of updated nodes to fire notifications
    // to the UI layer for.
    return updateCollector.collectChanges()
  }

}

// MARK: - UnexpectedApplyPendingError

struct UnexpectedApplyPendingError: Error { }

// MARK: - UnfinishedFlushError

struct UnfinishedFlushError: Error { }
