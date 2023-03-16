import Behaviors
import TreeActor
import Utilities

// MARK: - StateUpdater

@TreeActor
final class StateUpdater: ChangeManager {

  // MARK: Lifecycle

  nonisolated init(
    changes: TreeChanges,
    state: StateStorage,
    scopes: ScopeStorage,
    lastValidState: TreeStateRecord,
    userError: RuntimeConfiguration.ErrorHandler
  ) {
    self.state = state
    self.scopes = scopes
    self.stagedChanges = changes
    self.lastValidState = lastValidState
    self.userError = userError
  }

  // MARK: Internal

  private(set) var isFlushing: Bool = false

  /// Flush changes in ``StateStorage`` into ``ScopeStorage``.
  ///
  /// > Important: The changes in `StateStorage` must be described in the `changes`
  /// parameter to be flushed.
  func flush() throws -> [NodeChange] {
    guard !isFlushing
    else {
      assertionFailure("flush should never be called when another flush is in progress")
      throw UnfinishedFlushError()
    }

    isFlushing = true
    defer { isFlushing = false }
    do {
      return try updateScopes()
    } catch let error as CycleError {
      runtimeWarning("A circular dependency between Nodes was found")
      let applier = StateApplier(state: state, scopes: scopes)
      self.revertApplier = applier
      defer { revertApplier = nil }
      userError.handle(error: error)
      return try applier.apply(state: lastValidState)
    } catch {
      throw error
    }
  }

  func flush(dependentChanges changes: TreeChanges) {
    assert(isFlushing)
    if let revertApplier {
      revertApplier.flush(dependentChanges: changes)
    } else {
      stagedChanges.put(changes)
    }
  }

  // MARK: Private

  private let lastValidState: TreeStateRecord
  private let userError: RuntimeConfiguration.ErrorHandler
  private let state: StateStorage
  private let scopes: ScopeStorage

  private var revertApplier: StateApplier?
  private var stagedChanges: TreeChanges = .none
  private var changeEventsInFlushCycle: [StateChangeMetadata] = []

  private func updateScopes() throws -> [NodeChange] {
    var updateCollector = UpdateCollector()
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

    // Handle changes made as part of regular value updates.
    //
    // [N.B.] This function may be called repeatedly within a flush.
    // While updating, scopes might change their routing or update
    // system state. Dependent changes like these are caught in
    // future calls to this function methods.
    func addChangesToQueue(_ changes: TreeChanges) throws {
      // Added scopes have been built by a router rule and registered
      // with the manager via `updateRoutedNodes(at:to:)`.
      // The scopes have not yet been started or reacted to their
      // initial state.
      //
      // Before returning control to the consumer any dependent Scopes
      // go through appropriate lifecycle events which may trigger
      // further state changes.
      //
      // Add the new scopes to the priority queue to track progress.
      for id in changes.addedScopes {
        guard let scope = scopes.getScope(for: id)
        else {
          assertionFailure("a reported added scope should always exist")
          continue
        }
        updateCollector.started(id: id, depth: scope.depth)
        scope.markDirty(pending: .update)
        _ = priorityQueue.insert(scope)
      }

      // When a state update leads to nodes being torn down their
      // scopes must fire the appropriate lifecycle events and
      // stop and removed their own sub-scopes.
      // Once this is done the scope can be deallocated.
      //
      // Add the scopes to remove to the priority queue to track
      // progress.
      for id in changes.removedScopes {
        guard let scope = scopes.getScope(for: id)
        else {
          assertionFailure("a reported removed node should should always have a scope exist")
          continue
        }
        scope.markDirty(pending: .stop)
        _ = priorityQueue.insert(scope)
      }

      // Scopes known to be dependent on a value field that
      // has changed need to be checked for updates.
      //
      // (Both the scopes containing changed @Value fields
      // and scopes containing @Projection fields derived
      // from them may be affected by the change.)
      let valueChangeDirtiedScopes = changes
        .updatedValues
        .flatMap { field in
          // N.B. This casts a wide net and triggers needless checks.
          scopes.dependentScopesForValue(id: field)
        }
      // If the source of the change has directly highlighted
      // scopes that are dirtied we also want to check them.
      let knownDirtyScopes = changes
        .dirtyScopes
        .map { id in
          scopes.getScope(for: id)
        }
        .compactMap { maybeScope in
          assert(maybeScope != nil)
          return maybeScope
        }

      // To find downstream changes caused by dirtying these scopes
      // we mark them as needing updates and track progress in the
      // priority queue.
      for scope in Set(valueChangeDirtiedScopes + knownDirtyScopes) {
        scope.markDirty(pending: .update)
        _ = priorityQueue.insert(scope)
      }
    }

    // Take the updates that were in place when flushChanges was
    // called, resetting `updates` to empty in the process.
    let initialChanges = stagedChanges.take()
    // Call the selected handler implementation with the changes
    // to add the initial changes to the priority queue.
    try addChangesToQueue(initialChanges)

    while !priorityQueue.isEmpty {
      // Forward the root-most node.
      if
        let scope = priorityQueue.min,
        scope.requiresReadying
      {
        // if true, the node is now clean
        if
          try scope.stepTowardsReady(),
          let scope = priorityQueue.popMin()
        {
          updateCollector.updated(id: scope.nid, depth: scope.depth)
        }
      }
      // Check if the deepest scope requires 'finalization'
      // actions to progress it further towards stopping.
      else if
        let scope = priorityQueue.max,
        scope.requiresFinishing
      {
        // Act, and remove the scope if fully finished.
        if
          try scope.stepTowardsFinished(),
          let scope = priorityQueue.popMax()
        {
          updateCollector.stopped(id: scope.nid, depth: scope.depth)
          continue
        }
      }
      // When the deepest changed scope needs to be forwarded and
      // the changed scope closest to the root needs to be finished
      // neither scope has yet been removed from the queue.
      //
      // Since a scope can only be in the queue if it still needs progress
      // towards either being fully updated or removed we can finalize
      // the root-most scope to avoid an impasse.
      else if
        let scope = priorityQueue.min,
        scope.requiresFinishing
      {
        // if true, the node is now clean
        if
          try scope.stepTowardsFinished(),
          let scope = priorityQueue.popMin()
        {
          updateCollector.stopped(id: scope.nid, depth: scope.depth)
        }
      }
      // If no change to the queue are possible the queue must be empty.
      else {
        assert(priorityQueue.isEmpty)
      }

      // Add changes caused by this iteration to the queue.
      try addChangesToQueue(stagedChanges.take())
    }

    // Return the list of updated nodes to fire notifications
    // to the UI layer for.
    return updateCollector.collectChanges()
  }

}
